path = require 'path'
fs = require 'fs'
os = require 'os'

nimCaseInsensitiveOS = os.platform() == 'win32'

knownFiles = {}

findFile = (fullPath) ->
  return fullPath if not nimCaseInsensitiveOS

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
    lowerSegment = segments[i].toLowerCase()
    found = false
    for file in files
      if file.toLowerCase() == lowerSegment
        if first
          foundPath += file
          first = false
        else
          foundPath += sep + file
        found = true
        break

    if found == false
      throw new Error("Could not find file #{fullPath}, #{foundPath}")

  return foundPath

module.exports =
  getCanonical: (fullPath) ->
    if knownFiles[fullPath]
      knownFiles[fullPath]
    else
      file = findFile(fullPath)
      knownFiles[fullPath] = file
      file
  