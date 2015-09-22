fs = require 'fs'
{BufferedProcess} = require 'atom'
Caas = require './caas'
{CommandTypes} = require './constants'
{separateLines} = require './util'

class PersistentCaas extends Caas
  constructor: (folderPath, @rootFilename, @options) ->
    super(folderPath)

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
        if err?
          @onCommandDone err
        else
          @process.process.stdin.write args
    else
      args = "#{type} \"#{cmd.filePath}\":#{cmd.row}:#{cmd.col}\n"
      @process.process.stdin.write args

  processData: (data) ->
    @logOutput data
    lines = separateLines data
    newlineCount = 0
    resultsStarted = false
    for line in lines
      trimmed = line.trim()
      if trimmed.length == 0
        newlineCount = newlineCount + 1
        if newlineCount == 2
          @onCommandDone()
      else if trimmed == '>' # empty
        @onCommandDone()
      else if trimmed.startsWith '>' # results always start with a >
        newlineCount = 0
        resultsStarted = true
        @onCaasLine trimmed.substr(2)
      else if resultsStarted
        newlineCount = 0
        @onCaasLine trimmed
    true # Discard the lines

  startCaas: ->
    @process = new BufferedProcess
      command: @options.nimSuggestExe
      args: ['--stdin', @rootFilename]
      options:
        cwd: @folderPath
      stdout: (data) => @processData data

      exit: (code) =>
        return if code == 0
        # Not sure what to do here, need a way to propagate up nicely
        console.log "Nimsuggest crashed..."
        @process = null
        if @currentCb?
          @onCommandFailed()

    @process.onWillThrowError ({error,handle}) => 
      if @currentCb?
        @onCommandFailed error
      else
        throw error

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