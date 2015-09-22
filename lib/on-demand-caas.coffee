fs = require 'fs'
{BufferedProcess} = require 'atom'
Caas = require './caas'
{CommandTypes} = require './constants'
{separateLines} = require './util'

class OnDemandCaas extends Caas
  constructor: (@options) ->
    super()

  processData: (data) ->
    @logOutput data
    lines = separateLines data
    for line in lines
      trimmed = line.trim()
      if trimmed.length > 0
        @onCaasLine line
    true # Discard the lines

  execProcess: (args) ->
    @process = new BufferedProcess
      command: @options.nimExe
      args: args
      stderr: (data) => @processData data
      stdout: (data) => @processData data
      exit: (code) =>
        @onCommandDone()
    
    @process.onWillThrowError ({error,handle}) =>
      handle()
      console.log "Nim crashed..."
      @onCommandFailed error

  ensureCaas: -> # Nothing to do, it's on demand..

  doCommand: (cmd) ->
    if cmd.type == CommandTypes.LINT
      # Lint it!
      return

    if cmd.type == CommandTypes.SUGGEST
      type = 'suggest'
    else if cmd.type == CommandTypes.DEFINITION
      type = 'def'
    else if cmd.type == CommandTypes.CONTEXT
      type = 'context'
    else if cmd.type == CommandTypes.USAGE
      type = 'usages'

    if cmd.dirtyFileData?
      trackArg = "--trackDirty:#{@tempFilePath},#{cmd.filePath},#{cmd.row},#{cmd.col}"
      args = ["idetools", "--#{type}", "--listFullPaths", "--colors:off", "--verbosity:0", trackArg, cmd.filePath]
      fs.writeFile @tempFilePath, cmd.dirtyFileData, (err) =>
        if err?
          @onCommandFailed()
        else
          @execProcess args
    else
      trackArg = "--track:#{cmd.filePath},#{cmd.row},#{cmd.col}"
      args = ["idetools", "--#{type}", "--listFullPaths", "--colors:off", "--verbosity:0", trackArg, cmd.filePath]
      @execProcess args

module.exports = OnDemandCaas