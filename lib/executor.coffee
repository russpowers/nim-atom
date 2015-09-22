{CommandTypes, NimSymbolsTypes} = require './constants'
KnownFiles = require './known-files'

prettifyDocStr = (str) ->
  str.replace /\\x([0-9A-F]{2})/g, (match, hex) ->
        String.fromCharCode(parseInt(hex, 16))
     .replace /\`\`?([^\`]+)\`?\`/g, (match, ident) -> ident
     .replace /\\([^\\])/g, (match, escaped) -> escaped

class Executor
  constructor: (@projectManager) ->
    @commandQueue = []

  parseSuggest: (lines) ->
    for ln in lines
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

      item

  parseDefinition: (lines) ->
    return if lines.length < 1
    firstMatch = lines[0]
    datums = firstMatch.split "\t"
    return unless datums.length >= 8
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
    item

  doCommand: (cmd, cb) ->
    @currentCommand = cmd
    project = @projectManager.getProjectForPath cmd.filePath
    project.caas.sendCommand cmd, (err, lines) =>
      # Handle this better
      if err?
        atom.notifications.addError "Nim: Error executing command: #{cmd.type}",
          detail: "Details dumped to developer console.  Go to View -> Developer -> Toggle Developer Tools and open the Console to view."
        console.log err
        @currentCommand = null
        return

      if cmd.type == CommandTypes.LINT
        cb @parseLint(lines)
      else if cmd.type == CommandTypes.SUGGEST
        cb @parseSuggest(lines)
      else if cmd.type == CommandTypes.DEFINITION
        cb @parseDefinition(lines)
      else if cmd.type == CommandTypes.CONTEXT
        cb @parseContext(lines)
      else if cmd.type == CommandTypes.USAGE
        cb @parseUsage(lines)

      if @commandQueue.length > 0
        next = @commandQueue.shift()
        cb = () => 
          @doCommand next.cmd, next.cb
        setTimeout cb, 0
      else
        @currentCommand = null

  execute: (editor, commandType, cb) ->
    cmd =
      type: commandType
    if editor.isModified()
      cmd.dirtyFileData = editor.getText()
    cursor = editor.getCursorBufferPosition()
    cmd.col = cursor.column+1
    cmd.row = cursor.row+1
    cmd.filePath = editor.getPath()

    # Make sure only one command executes at a time
    if @currentCommand?
      @commandQueue.push
        cmd: cmd
        cb: cb
    else
      @doCommand cmd, cb

module.exports = Executor