{Point} = require 'atom'
{CommandTypes, AutoCompleteOptions} = require './constants'
fuzzaldrin = require 'fuzzaldrin'
pragmas = require './pragmas'

DOTTED = 1
IDENT = 2
PRAGMA = 3

hasCachedResults = (editor, bufferPosition, prefixInfo) ->
  return false if not editor.nimSuggestCache
  oldPrefixInfo = editor.nimSuggestCache.prefixInfo
  oldPrefixInfo.start == prefixInfo.start and
    oldPrefixInfo.row == prefixInfo.row and
    bufferPosition.column >= oldPrefixInfo.cursorStart

isIdentifierChar = (c) ->
  (c >= 'a' and c <= 'z') or 
    (c >= 'A' and c <= 'Z') or 
    (c >= '0' and c <= '9') or 
    (c == '_') or 
    (c > 127)

class PrefixInfo
  constructor: (@type, @start, @cursorStart, searchStart, replacementStart, line, bufferPosition) ->
    # The full text, including dot
    @text = line.substring @start, bufferPosition.column
    # Does the prefix contain any relevant search data?  If it's just a dot or {. it doesn't
    @isRelevant = searchStart < bufferPosition.column
    # This will be the search and replacement prefix used
    @replacementPrefix = line.substring replacementStart, bufferPosition.column
    @row = bufferPosition.row

inPragma = (line, col) ->
  while (col > 0)
    if line[col] == '}' and line[col-1] == '.'
      return false
    if line[col] == '.' and line[col-1] == '{'
      return true
    col -= 1
  return false

getPrefixInfo = (editor, bufferPosition) ->
    line = editor.lineTextForBufferRow bufferPosition.row
    col = bufferPosition.column - 1
    while col >= 0
      c = line[col]
      if c == '.'
        if col > 0 and line[col-1] == '{'
          return new PrefixInfo PRAGMA, col-1, col, col+1, col-1, line, bufferPosition
        else if inPragma line, col-1
          return null
        else
          return new PrefixInfo DOTTED, col, col, col+1, col+1, line, bufferPosition
      if not isIdentifierChar c
        return new PrefixInfo IDENT, col+1, col+1, col+1, col+1, line, bufferPosition
      else
        col -= 1

    return new PrefixInfo IDENT, 0, 0, 0, 0, line, bufferPosition

empty = []

module.exports = (executor, options) ->
  selector: '.source.nim'
  disableForSelector: '.source.nim .comment'
  inclusionPriority: 10
  excludeLowerPriority: true

  buildResults: (symbols, prefixInfo) ->
    for symbol in symbols
      symbol.replacementPrefix = prefixInfo.replacementPrefix
    # If the relevant search text is empty, just return the unsorted symbols
    # fuzzaldrin mixes things up
    if not prefixInfo.isRelevant
      symbols
    else
      fuzzaldrin.filter symbols, prefixInfo.replacementPrefix, key: 'text'

  getSuggestions: ({editor, bufferPosition, scopeDescriptor}) ->
    if options.autocomplete == AutoCompleteOptions.NEVER || not options.autocomplete?
      return empty

    prefixInfo = getPrefixInfo editor, bufferPosition

    if prefixInfo == null
      return empty
    else if prefixInfo.type == PRAGMA
      return @buildResults pragmas, prefixInfo

    if options.autocomplete == AutoCompleteOptions.AFTERDOT
      return empty if prefixInfo.type != DOTTED

    return new Promise (resolve) =>
      if hasCachedResults editor, bufferPosition, prefixInfo
        resolve @buildResults(editor.nimSuggestCache.symbols, prefixInfo)
      else if prefixInfo.text.length > 0
        executor.execute editor, CommandTypes.SUGGEST, (err, symbols) =>
          if err
            resolve empty
          else
            editor.nimSuggestCache =
              prefixInfo: prefixInfo
              symbols: if symbols then symbols else []
            resolve @buildResults(editor.nimSuggestCache.symbols, prefixInfo)
      else
        resolve empty