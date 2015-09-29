{CommandTypes, NimSymbolsTypes} = require './constants'
KnownFiles = require './known-files'
CompilerErrorsParser = require './compiler-errors-parser'

prettifyDocStr = (str) ->
  replaced = str.replace /\\x([0-9A-F]{2})/g, (match, hex) ->
        String.fromCharCode(parseInt(hex, 16))
    .replace /\`\`?([^\`]+)\`?\`/g, (match, ident) -> ident
    .replace /\\([^\\])/g, (match, escaped) -> escaped
  if replaced == '"' or replaced == '' then ' ' else replaced

class Executor
  constructor: (@projectManager, @options) ->
    @commandQueue = []
    @compilerErrorsParser = new CompilerErrorsParser(@options)

  parseSuggest: (lines) ->
    result = for ln in lines
      datums = ln.split "\t"
      continue unless datums.length >= 8
      [type, symbolType, name, sig, path, line, col, docs] = datums
      
      # Skip the name of the owning module (e.g. system.len)
      shortName = name.substr(name.indexOf(".") + 1)
      
      # Remove the enclosing string quotes ("...")
      docs = docs.slice(1, -1) if docs[0] == '"'
      
      item =
        text: shortName
        sig: sig
        type: NimSymbolsTypes[symbolType] || "tag"
        description: prettifyDocStr docs
        path: KnownFiles.getCanonical(path)
        row: line
        col: col
        rightLabelHTML: sig

      item

    return {
      result: result
    }

  parseDefinition: (lines) ->
    return {} if lines.length < 1
    firstMatch = lines[0]
    datums = firstMatch.split "\t"
    return {} unless datums.length >= 8
    [type, symbolType, name, sig, path, line, col, docs] = datums
    item =
      type: type
      symbolType: symbolType
      name: name
      sig: sig
      path: KnownFiles.getCanonical(path)
      line: parseInt(line)
      col: parseInt(col)
      docs: docs
    return {
      result: item
    }

  doError: (cmd, err) ->
    if cmd.type != CommandTypes.SUGGEST # This happens too much, don't broadcast it
      atom.notifications.addError "Nim: Error executing command: #{cmd.type}",
        detail: "Details dumped to developer console.  Go to View -> Developer -> Toggle Developer Tools and open the Console to view."
    console.log err
    @currentCommand = null
    cmd.cb err
    return

  handleParseResult: (cmd, parsedData) ->
    data = parseFn lines
    

  doNextCommand: () ->
    if @commandQueue.length > 0
      next = @commandQueue.shift()
      cb = () => 
        @doCommand next
      setTimeout cb, 0
    else
      @currentCommand = null

  doCommand: (cmd) ->
    @currentCommand = cmd
    cmd.project.sendCommand cmd, (err, result) =>
      if err?
        @doError(cmd, err)
        @doNextCommand()
        return

      parsedResult = if cmd.type == CommandTypes.BUILD
          res = @compilerErrorsParser.parse(cmd.filePath, result.lines)
          res.extra = 
            code: result.code
            filePath: cmd.filePath
          res
        else if cmd.type == CommandTypes.LINT
          @compilerErrorsParser.parse(cmd.filePath, result.lines)
        else if cmd.type == CommandTypes.SUGGEST
          @parseSuggest(result)
        else if cmd.type == CommandTypes.DEFINITION
          @parseDefinition(result)
        else if cmd.type == CommandTypes.CONTEXT
          @parseContext(result)
        else if cmd.type == CommandTypes.USAGE
          @parseUsage(result)

      if parsedResult.err?
        @doError cmd, parsedResult.err
      else
        cmd.cb null, parsedResult.result, parsedResult.extra

      @doNextCommand()

  execute: (editor, commandType, cb) ->
    cmd =
      type: commandType
    if editor.isModified()
      cmd.dirtyFileData = editor.getText()
    cursor = editor.getCursorBufferPosition()
    cmd.col = cursor.column+1
    cmd.row = cursor.row+1
    cmd.filePath = editor.getPath()
    cmd.cb = cb
    if editor.nimProject?
      cmd.project = editor.nimProject
    else
      cmd.project = @projectManager.getProjectForPath cmd.filePath
      editor.nimProject = cmd.project

    # If we can't find the project, it means the project manager is still not initialized,
    # try again in a moment
    if not cmd.project?
      setTimeout (() => @execute(editor, commandType, cb)), 1
      return

    # Make sure only one command executes at a time
    if @currentCommand?
      @commandQueue.push cmd
    else
      @doCommand cmd

module.exports = Executor