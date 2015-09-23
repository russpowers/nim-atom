fs = require 'fs'
temp = require 'temp'
{prettyPrint} = require './util'

class Caas
  constructor: ->
    @trackedTemp = temp.track()
    tempFile = @trackedTemp.openSync 
      prefix: 'nimsuggest'
      suffix: '.nim'
    @tempFilePath = tempFile.path
    fs.close tempFile.fd
    @currentCb = null
    @lines = []
    @output = []

  sendCommand: (cmd, cb) ->
    @retries = 0
    @currentCmd = cmd
    @currentCb = cb
    @doCommandInternal cmd

  doCommandInternal: (cmd) ->
    return if @destroyed
    @lines = []
    @output.length = 0
    @ensureCaas()
    @doCommand cmd

  onCommandFailed: (error) ->
    @retries = @retries + 1
    if @retries > 3
      message = if error? 
          error.toString()
        else
          "ERROR: Command failed multiple times.\nCommand:\n#{prettyPrint(@currentCmd)}\nOutput:\n#{@output.join('\n')}"
      @currentCb message
    else
      cb = () => @doCommandInternal @currentCmd
      setTimeout cb, 100

  onCommandDone: ->
    if @currentCb?
      @currentCb null, @lines
    #cb = () => 
      
    #setTimeout cb, 0

  logOutput: (text) ->
    @output.push text

  onCaasLine: (line) ->
    # Ignore it if we don't have a current callback waiting, maybe just the initial instructions
    @lines.push(line) if @currentCb?

  destroy: ->
    @destroyed = true
    @trackedTemp.cleanupSync()

module.exports = Caas