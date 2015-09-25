KnownFiles = require './known-files'

matchTemplate = (line) ->
  line.match ///
    ^(.+) # path 
    \((\d+), \s (\d+)\) \s template/generic \s instantiation \s from \s here///

matchWarningErrorHint = (line) ->
  line.match /^(.+?\.nim)\((\d+),\s(\d+)\)\s(Warning|Error|Hint):\s(.*)/

matchInternalError = (line) ->
  line.match /// Error:\sinternal\serror: ///

processLine = (filePath, line, state) ->
  templateMatch = matchTemplate line

  if templateMatch
    [_, sourcePath, line, col] = templateMatch
    sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
    msg = "#{sourcePath} (#{line}, #{col}) template/generic instantiation from here"
    if state.fullMsgInfo
      state.fullMsgInfo.msg = state.fullMsgInfo.msg + '<br />' + msg
    else
      state.fullMsgInfo =
        msg: msg
        line: line - 1
        col: col - 1
        filePath: sourcePath
    return

  wehMatch = matchWarningErrorHint line
  
  if wehMatch
    console.log line
    [_, sourcePath, line, col, type, msg] = wehMatch
    console.log sourcePath, "...", line, col, type, msg
    sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
    if type == 'Hint' then type = 'Info'
    line = line - 1 # convert to number
    col  = col - 1

    if state.fullMsgInfo
      col = state.fullMsgInfo.col
      line = state.fullMsgInfo.line
      msg = state.fullMsgInfo.msg + '<br />' + "#{sourcePath} (#{line}, #{col}) " + msg
      sourcePath = state.fullMsgInfo.filePath
      state.fullMsgInfo = null
 
    return {
      filePath: sourcePath
      type: type
      html: msg
      range: [[line, col],[line, col+1]]
    }

  internalErrorMatch = matchInternalError line

  if internalErrorMatch
    state.foundInternalError = true
    return

class CompilerErrorsParser
  constructor: (@options) ->

  parse: (filePath, errorLines) ->
    results = []

    state =
      foundInternalError: false

    for errorLine in errorLines
      processed = processLine filePath, errorLine, state
      if processed instanceof Array
        processed.forEach (x) -> results.push x
      else if processed?
        results.push processed
    
    if foundInternalError?
      err = "ERROR: Compiler internal error.\nCommand: #{@options.nimExe} #{args.join(' ')}\nOutput:\n#{errorLines.join('\n')}"

    return {
      err: err
      result: results
    }

module.exports = CompilerErrorsParser