KnownFiles = require './known-files'

matchTemplate = (line) ->
  line.match ///
    ^(.+) # path 
    \((\d+), \s (\d+)\) \s template/generic \s instantiation \s from \s here///

matchWarningErrorHint = (line) ->
  line.match /^(.+?\.nims?)\((\d+),\s(\d+)\)\s(Warning|Error|Hint):\s(.*)/

matchInternalError = (line) ->
  line.match /// Error:\sinternal\serror: ///

matchSigsegvError = (line) ->
  line.match /^(SIGSEGV\:.+)/

processLine = (filePath, line, state) ->
  templateMatch = matchTemplate line

  if templateMatch
    [_, sourcePath, line, col] = templateMatch
    sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
    msg = "template/generic instantiation from here"
    line = parseInt(line) - 1
    col  = parseInt(col) - 1

    return
      location:
        file: sourcePath
        position: [[line, col],[line, col+1]]
      severity: "info"
      excerpt: msg

  wehMatch = matchWarningErrorHint line
  
  if wehMatch
    [_, sourcePath, line, col, type, msg] = wehMatch
    sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
    if type == 'Hint' then type = 'info'
    type = type.toLowerCase()
    line = parseInt(line) - 1
    col  = parseInt(col) - 1

    return
      location:
        file: sourcePath
        position: [[line, col],[line, col+1]]
      severity: type
      excerpt: msg
    

  internalErrorMatch = matchInternalError line

  if internalErrorMatch
    state.foundInternalError = true
    return

  sigsegvErrorMatch = matchSigsegvError line

  if sigsegvErrorMatch
    state.foundInternalError = true
    return

class CompilerErrorsParser
  constructor: (@options) ->

  parse: (filePath, errorLines) ->
    results = []
    err = null
    state =
      foundInternalError: false

    for errorLine in errorLines
      processed = processLine filePath, errorLine, state
      if processed instanceof Array
        processed.forEach (x) -> results.push x
      else if processed?
        results.push processed
    
    if state.foundInternalError
      results.push
        location:
          file: filePath
          position: [[0, 0],[0, 0]]
        severity: 'Error'
        excerpt: 'Compiler internal error.  Details dumped to developer console.  Go to View -> Developer -> Toggle Developer Tools and open the Console to view.'
        
      console.log "ERROR: Compiler execution failed.\nOutput:\n#{errorLines.join('\n')}"

    console.log(results)

    return {
      err: err
      result: results
    }

module.exports = CompilerErrorsParser