path = require 'path'
fs = require 'fs'

knownFiles = {}

findFile = (fullPath) ->
  sep = path.sep

  if fullPath[0] == '/'
    foundPath = '/'
    segments = fullPath.split sep
  else
    foundPath = fullPath[0].toUpperCase() + ':\\'
    segments = fullPath.split sep
  
  first = true

  for i in [1 ... segments.length]
    files = fs.readdirSync foundPath
    found = false
    for file in files
      if file.toLowerCase() == segments[i]
        if first
          foundPath += file
          first = false
        else
          foundPath += sep + file
        found = true
        break

    if found == false
      throw new Error("Could not find file #{fullPath}")

  return foundPath

module.exports =
  getCanonical: (fullPath) ->
    if knownFiles[fullPath]
      knownFiles[fullPath]
    else
      file = findFile(fullPath)
      knownFiles[fullPath] = file
      file
  