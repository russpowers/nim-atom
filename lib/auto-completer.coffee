{CommandTypes} = require './constants'
fuzzaldrin = require 'fuzzaldrin'

hasCachedResults = (editor, bufferPosition, prefix) ->
  return false if not editor.nimSuggestCache
  cachePos = editor.nimSuggestCache.pos
  return cachePos.row == bufferPosition.row and
         cachePos.column + prefix.length == bufferPosition.column

truncate = (str, maxLen) ->
  if str? and str.length > maxLen
    str.substr(0, maxLen) + "..."
  else
    str

module.exports = (executor) ->
  selector: '.source.nim'
  disableForSelector: '.source.nim .comment'

  # This will take priority over the default provider, which has a priority of 0.
  # if `excludeLowerPriority` is set to true, this will suppress any providers
  # with a lower priority (i.e. The default provider will be suppressed)
  inclusionPriority: 10
  excludeLowerPriority: true
  
  # Required: Return a promise, an array of suggestions, or null.
  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) =>
    return new Promise (resolve) =>
      buildResults = (symbols) ->
        if prefix == '.'
          for symbol in symbols
            symbol.replacementPrefix = ''
          fuzzaldrin.filter symbols, '', key: 'text'
        else
          # It should remove the prefix on insertion, but it doesn't, so we need to
          # manually set it
          for symbol in symbols
            symbol.replacementPrefix = prefix
          fuzzaldrin.filter symbols, prefix, key: 'text'

      if hasCachedResults editor, bufferPosition, prefix
        resolve buildResults(editor.nimSuggestCache.symbols)
      else if prefix.endsWith '.'
        executor.execute editor, CommandTypes.SUGGEST, (symbols) ->
          if symbols
            editor.nimSuggestCache =
              pos: bufferPosition
              symbols: symbols
          else
            editor.nimSuggestCache =
              pos: bufferPosition
              symbols: []
          resolve buildResults(editor.nimSuggestCache.symbols)
      else
        resolve []