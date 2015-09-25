{BufferedProcess} = require 'atom'
KnownFiles = require './known-files'
path = require 'path'
{separateLines} = require './util'

class Compiler
  constructor: (@options) ->

  check: (filePath, fileText, cb) ->
    args = ["check", "--listFullPaths", "--colors:off", "--verbosity:0", if fileText? then '-' else filePath]
    if @options.checkArgs?
      args = args.concat @options.checkArgs

    @execute path.dirname(filePath), args, fileText, cb

  build: (filePath, cb) ->
    args = ["c", "--listFullPaths", "--colors:off", "--verbosity:0", filePath]
    if @options.compileArgs?
      args = args.concat @options.compileArgs

    @execute path.dirname(filePath), args, null, cb

  execute: (cwd, args, fileText, cb) ->
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

    if fileText?
      process.process.stdin.write fileText
      process.process.stdin.end()

    process.onWillThrowError ({error,handle}) ->
      handle()
      cb "ERROR: Compiler execution failed.\nCommand: #{options.nimExe} #{args.join(' ')}\nOutput:\n#{output}"

module.exports = Compiler