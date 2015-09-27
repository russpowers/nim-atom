path = require 'path'
fs = require 'fs'
temp = require 'temp'
{BufferedProcess} = require 'atom'
mkdirp = require 'mkdirp'
{separateLines} = require './util'
KnownFiles = require './known-files'


class Compiler
  constructor: (@options) ->
    @trackedTemp = temp.track()
    tempFile = @trackedTemp.openSync 
      prefix: 'nimcheck'
      suffix: '.nim'
    @tempFilePath = tempFile.path
    fs.close tempFile.fd

  check: (filePath, cb) ->
    args = ["check", "--listFullPaths", "--colors:off", "--verbosity:0", filePath]
    if @options.checkArgs?
      args = args.concat @options.checkArgs

    @execute path.dirname(filePath), args, cb

  checkDirty: (rootFilePath, filePath, fileText, cb) ->
    trackArg = "--trackDirty:#{@tempFilePath},#{filePath},1,1"
    args = ["check", "--listFullPaths", "--colors:off", "--verbosity:0", trackArg, rootFilePath]
    if @options.checkArgs?
      args = args.concat @options.checkArgs
    fs.writeFile @tempFilePath, fileText, (err) =>
      if err?
        cb "Error writing temp file for compiler"
      else
        @execute path.dirname(rootFilePath), args, cb

  build: (filePath, binPath, cb) ->
    if binPath?
      mkdirp path.dirname(binPath), (err) =>
        cb(err) if err?
        args = ["c", "--listFullPaths", "--colors:off", "--verbosity:0", "--out:#{binPath}", filePath]
        if @options.compileArgs?
          args = args.concat @options.compileArgs
        @execute path.dirname(filePath), args, cb
    else
      args = ["c", "--listFullPaths", "--colors:off", "--verbosity:0", filePath]
      if @options.compileArgs?
          args = args.concat @options.compileArgs
      @execute path.dirname(filePath), args, cb

  execute: (cwd, args, cb) ->
    if not @options.nimExists
      return cb "Could not find nim executable, please check nim package settings"

    results = []

    processData = (data) ->
      lines = separateLines data
      for line in lines
        results.push line
      null

    process = new BufferedProcess
      command: @options.nimExe
      args: args
      options:
        cwd: cwd
      stderr: processData
      stdout: processData
      exit: (code) ->
        cb null,
          code: code,
          lines: results

    process.onWillThrowError ({error,handle}) ->
      handle()
      cb "ERROR: Compiler execution failed.\nCommand: #{options.nimExe} #{args.join(' ')}\nOutput:\n#{output}"

  destroy: ->
    @destroyed = true
    @trackedTemp.cleanupSync()

module.exports = Compiler