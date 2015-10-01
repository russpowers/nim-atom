fs = require 'fs'
{BufferedProcess} = require 'atom'
Caas = require './caas'
{CommandTypes} = require './constants'
{separateLines} = require './util'

class PersistentCaas extends Caas
  constructor: (@folderPath, @rootFilePath, @options) ->
    super()
    # Start Nimsuggest when project is opened, since sometimes it takes a few secs
    @ensureCaas()

  doCommand: (cmd) ->
    if cmd.type == CommandTypes.LINT
      # Lint it!
      return

    if cmd.type == CommandTypes.SUGGEST
      type = 'sug'
    else if cmd.type == CommandTypes.DEFINITION
      type = 'def'
    else if cmd.type == CommandTypes.CONTEXT
      type = 'con'
    else if cmd.type == CommandTypes.USAGE
      type = 'use'

    if cmd.dirtyFileData?
      args = "#{type} \"#{cmd.filePath}\";\"#{@tempFilePath}\":#{cmd.row}:#{cmd.col}\n"
      fs.writeFile @tempFilePath, cmd.dirtyFileData, (err) =>
        # If we are not in the original cmd, an error happened during the callback
        return if @currentCmd != cmd
        if err?
          @onCommandFailed err
        else
          @process.process.stdin.write args
    else
      args = "#{type} \"#{cmd.filePath}\":#{cmd.row}:#{cmd.col}\n"
      @process.process.stdin.write args

  processData: (data) ->
    @logOutput data
    lines = separateLines data
    newlineCount = 0 
    for line in lines
      trimmed = line.trim()
      if @initialLineCount < 4
        # Ignore help text
        @initialLineCount += 1
      else if trimmed.length == 0
        newlineCount = newlineCount + 1
        if newlineCount == 2
          @onCommandDone()
      else if trimmed == '>'
        # For Windows, '>' is an empty result, not followed by newline
        @onCommandDone()
      else if trimmed.startsWith '> '
        # The first result in Windows will start with '> '
        @onCaasLine trimmed.substr(2)
      else
        @onCaasLine trimmed
    true # Discard the lines

  startCaas: ->
    @initialLineCount = 0
    if @options.nimLibPath.length
      args = ["--lib:\"#{@options.nimLibPath}\"", '--stdin', @rootFilePath]
    else
      args = ['--stdin', @rootFilePath]

    @process = new BufferedProcess
      command: @options.nimSuggestExe
      args: ['--stdin', @rootFilePath]
      options:
        cwd: @folderPath
      stdout: (data) => @processData data

      exit: (code) =>
        return if code == 0
        console.log "Nimsuggest crashed..."
        @process = null
        if @currentCb?
          @onCommandFailed()

    @process.onWillThrowError ({error,handle}) =>
      handle()
      console.log "Nimsuggest crashed..."
      @process = null
      if @currentCb?
        @onCommandFailed error

  ensureCaas: ->
    if not @process?
      @startCaas()

  stopCaas: ->
    return if not @process?
    @process.process.stdin.end()
    @process = null

  destroy: ->
    @stopCaas()
    super()

module.exports = PersistentCaas