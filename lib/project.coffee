fs = require 'fs'
path = require 'path'
PersistentCaas = require './persistent-caas'
OnDemandCaas = require './on-demand-caas'
Compiler = require './compiler'
NimbleInfo = require './nimble-info'
{existsSync, separateLines, removeExt} = require './util'
{CommandTypes} = require './constants'

guessRootFilePath = (folderPath, rootFilenameGuesses) ->
  for rootFilename in rootFilenameGuesses
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

findSameNamedNim = (folderPath, extensions) ->
  files = fs.readdirSync folderPath
  for extension in extensions
    extFiles = files.filter (x) -> x.endsWith(extension) and x != extension
    for extFile in extFiles
      extFileBase = path.basename extFile, extension
      rootFilePath = path.join folderPath, (extFileBase + '.nim')
      if existsSync rootFilePath
        return rootFilePath
  return null

findFirstNimFile = (folderPath) ->
  files = fs.readdirSync folderPath
  nimFiles = files.filter (x) -> x.endsWith('.nim') and x != '.nim'
  return nimFiles[0]

class Project
  constructor: (@folderPath, @options) ->
    @compiler = new Compiler @options
    @detectInfo()

  detectInfo: () ->  
    if not @folderPath?
      @caas = new OnDemandCaas @options
    else
      # First look to see if there's a .nimble file
      @nimbleInfo = new NimbleInfo(@folderPath)
      if @nimbleInfo.hasNimbleFile
        @rootFilePath = @nimbleInfo.rootFilePath
        @binFilePath = @nimbleInfo.binFilePath
      
      # No root found in .nimble? Or no .nimble?  Ok, let's try to find .nim matching
      # the standard extensions
      if not @rootFilePath?
        @rootFilePath = findSameNamedNim @folderPath, ['.nimcfg', '.nim.cfg', '.nims']
        if @rootFilePath?
          @binFilePath = removeExt @rootFilePath

      if @binFilePath?
        @binFolderPath = path.dirname(@binFilePath)
      if @rootFilePath?
        @rootFolderPath = path.dirname(@rootFilePath)

      if @options.nimSuggestEnabled and @options.nimSuggestExists
        if @rootFilePath?
          @caas = new PersistentCaas @folderPath, @rootFilePath, @options
        else
          # We'd like to use nimsuggest even though there isn't a project, so try guessing..
          guessedProjectFile = guessRootFilePath @folderPath, ['<nimble>.nim', 'proj.nim', '<parent>.nim']
          if guessedProjectFile?
            @caas = new PersistentCaas @folderPath, guessedProjectFile, @options
          else
            @caas = new OnDemandCaas @options
      else if @options.nimExists
        @caas = new OnDemandCaas @options

  getBinFilePathFor: (filePath) ->
    if @binFilePath? then @binFilePath else removeExt(filePath)

  getBinFolderPathFor: (filePath) ->
    if @binFolderPath? then @binFolderPath else path.dirname(filePath)

  getRootFilePathFor: (filePath) ->
    if @rootFilePath? then @rootFilePath else filePath

  getRootFolderPathFor: (filePath) ->
    if @rootFolderPath? then @rootFolderPath else path.dirname(filePath)


  sendCommand: (cmd, cb) ->
    if cmd.type == CommandTypes.LINT
      # Compile at the project root, if there is one
      cmd.compiledPath = if @rootFilePath? then @rootFilePath else cmd.filePath
      if cmd.dirtyFileData?
        @compiler.checkDirty cmd.compiledPath, cmd.filePath, cmd.dirtyFileData, cb
      else
        @compiler.check cmd.compiledPath, cb
    else if cmd.type == CommandTypes.BUILD
      # Build the root, if it's available
      if @rootFilePath?
        cmd.compiledPath = @rootFilePath
      else
        cmd.compiledPath = cmd.filePath
      @compiler.build cmd.compiledPath, @binFilePath, cb
    else if @caas?
      @caas.sendCommand cmd, cb
    else
      cb "Could not find nim executable, please check nim package settings"

  destroy: ->
    @caas.destroy() if @caas?
    @compiler.destroy()

module.exports = Project