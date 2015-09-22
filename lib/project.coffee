fs = require 'fs'
path = require 'path'
PersistentCaas = require './persistent-caas'
OnDemandCaas = require './on-demand-caas'
{existsSync} = require './util'

findRootFilePath = (folderPath, rootFilenames) ->
  for rootFilename in rootFilenames
    if rootFilename.indexOf('<parent>') != -1
      rootFilePath = path.join folderPath, rootFilename.replace('<parent>', path.basename(folderPath))
    else if rootFilename.indexOf('<nimble>') != -1
      files = fs.readdirSync folderPath
      nimbleFiles = files.filter (x) -> path.extname(x) == '.nimble' and path.basename(x) != '.nimble'
      if nimbleFiles.length # Just do the first, there shouldn't be more than one
        rootFilePath = path.join folderPath, rootFilename.replace('<nimble>', path.basename(nimbleFiles[0], '.nimble'))
      else
        continue
    else
      rootFilePath = path.join(folderPath, rootFilename)
      
    return rootFilePath if existsSync rootFilePath
  return null

class Project
  constructor: (@folderPath, @options) ->
    if not @folderPath?
      @caas = new OnDemandCaas options
    else
      @rootFilePath = findRootFilePath folderPath, options.rootFilenames
      if @rootFilePath and @options.nimSuggestEnabled and @options.nimSuggestExists
        @caas = new PersistentCaas folderPath, path.basename(@rootFilePath), options
      else if @options.nimExists
        @caas = new OnDemandCaas options

  destroy: ->
    @caas.destroy() if @caas?

module.exports = Project