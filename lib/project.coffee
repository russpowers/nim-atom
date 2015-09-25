fs = require 'fs'
path = require 'path'
PersistentCaas = require './persistent-caas'
OnDemandCaas = require './on-demand-caas'
Compiler = require './compiler'
NimbleInfo = require './nimble-info'
{existsSync, separateLines, removeExt} = require './util'
{CommandTypes} = require './constants'

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
    @compiler = new Compiler @options
    @detectInfo()

  detectInfo: () ->  
    if not @folderPath?
      @caas = new OnDemandCaas @options
    else
      # First look to see if there's a .nimble file...
      @nimbleInfo = new NimbleInfo(@folderPath)
      if @nimbleInfo.hasNimbleFile
        @rootFilePath = @nimbleInfo.rootFilePath
        @binFilePath = @nimbleInfo.binFilePath
      else
        # No?  Ok, let's look around and see if we can find a source root anyways..
        @rootFilePath = findRootFilePath @folderPath, @options.rootFilenames
        if @rootFilePath?
          @binFilePath = removeExt @rootFilePath

      if @binFilePath?
        @binFolderPath = path.basename(@binFilePath)

      if @rootFilePath?
        @rootFolderPath = path.basename(@rootFilePath)

      if @rootFilePath and @options.nimSuggestEnabled and @options.nimSuggestExists
        @caas = new PersistentCaas @folderPath, @rootFolderPath, @options
      else if @options.nimExists
        @caas = new OnDemandCaas @options

  sendCommand: (cmd, cb) ->
    if cmd.type == CommandTypes.LINT
      # Build the root, if it's available and the file is saved
      if @rootFilePath? and not cmd.dirtyFileData?
        cmd.filePath = @rootFilePath
      @compiler.check cmd.filePath, cmd.dirtyFileData, cb
    else if cmd.type == CommandTypes.BUILD
      # Build the root, if it's available
      if @rootFilePath?
        cmd.filePath = @rootFilePath
      @compiler.build cmd.filePath, cb
    else if @caas?
      @caas.sendCommand cmd, cb
    else
      cb "Could not find nim executable, please check nim package settings"

  destroy: ->
    @caas.destroy() if @caas?

module.exports = Project