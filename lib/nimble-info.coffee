fs = require 'fs'
path = require 'path'
{separateLines, removeExt} = require './util'

readNimbleData = (nimbleFilePath) ->

  fdata = fs.readFileSync nimbleFilePath
  lines = separateLines fdata.toString()
  data = {}
  for line in lines
    match = line.match(/^(\w+)\s*=\s*\"([^\"]*)\"/) or line.match(/^(\w+)\s*=\s*@\[\"([^\"]*)\"\]/)
    if match
      [_, key, value] = match
      data[key] = value
    
  data

getNimbleDict = (folderPath) ->
  files = fs.readdirSync folderPath
  nimbleFiles = files.filter (x) -> path.extname(x) == '.nimble' and path.basename(x) != '.nimble'
  if nimbleFiles.length # Just do the first, there shouldn't be more than one
    nimbleFilePath = path.join(folderPath, nimbleFiles[0])
    return [readNimbleData(nimbleFilePath), nimbleFilePath]
  else
    []

# A simple class to parse .nimble files and calculate where the source root
# and bin root should be.  Only uses the first bin value, multiple bins within
# a .nimble file are not supported.

class NimbleInfo
  constructor: (@folderPath) ->
    [@data, @nimbleFilePath] = getNimbleDict @folderPath
    @hasNimbleFile = @data?
    @srcDir = path.join(@folderPath, @getFirst('srcDir') || '')
    @binDir = path.join(@folderPath, @getFirst('binDir') || '')
    @bin = @getFirst('bin')
    if @bin?
      @rootFilePath = path.join(@srcDir, @bin) + '.nim'
      @binFilePath = path.join(@binDir, @bin)

  get: (key) -> @data[key]

  getFirst: (key) ->
    if @data? and @data[key]?
      @data[key].split(',')[0]
    else
      null

module.exports = NimbleInfo
