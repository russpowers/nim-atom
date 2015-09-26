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
    line = parseInt(line) - 1
    col  = parseInt(col) - 1

    if not state.trace?
      state.trace = []

    state.trace.push
      filePath: sourcePath
      type: "Trace"
      text: msg
      range: [[line, col],[line, col+1]]
        
    return

  wehMatch = matchWarningErrorHint line
  
  if wehMatch
    [_, sourcePath, line, col, type, msg] = wehMatch
    sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
    if type == 'Hint' then type = 'Info'
    line = parseInt(line) - 1
    col  = parseInt(col) - 1

    item =
      filePath: sourcePath
      type: type
      text: msg
      range: [[line, col],[line, col+1]]

    if state.trace?
      item.trace = state.trace.slice().reverse()
      state.trace.length = 0

    return item
    

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