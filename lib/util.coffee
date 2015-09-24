fs = require 'fs'

module.exports =
  existsSync: (filePath) ->
    try
      fs.statSync(filePath);
    catch err
      if err.code == 'ENOENT' then return false else throw err
    return true
  separateLines: (data) -> data.split "\n"
  separateSpaces: (data) -> data.trim().split ' '
  prettyPrint: (obj) ->
    console.log obj
    JSON.stringify(obj, null, '  ')
  hasExt: (pathstr, ext) ->
    return false if not pathstr?
    pathstr.endsWith ext
  isDirectory: (pathstr) ->
    try
      return fs.lstatSync(pathstr).isDirectory()
    catch err
      if err.code == 'ENOENT' then return false else throw err
  debounce: (wait, func, immediate) ->
    timeout = null
    return ->
      context = this
      args = arguments
      later = ->
        timeout = null;
        func.apply(context, args) if not immediate 
      callNow = immediate and not timeout
      clearTimeout timeout
      timeout = setTimeout later, wait
      func.apply(context, args) if callNow
  arrayEqual: (a, b) ->
    if a?
      if b?
        a.length is b.length and a.every (elem, i) -> elem is b[i]
      else
        false
    else
      if b?
        false
      else
        true