Project = require './project'
{isDirectory} = require './util'

class ProjectManager
  constructor: ->
    @projectPaths = []
    @projects = []

  destroy: ->
    @nonProject.destroy() if @nonProject?
    for project in @projects
      project.destroy()
    @projects = []

  getProjectForPath: (filePath) ->
    found = null
    for project in @projects
      if filePath.indexOf(project.folderPath) == 0
        if found == null
          found = project
        else if found.folderPath.length > project.folderPath.length
          found = project
    if found?
      found
    else
      @nonProject

  update: (projectPaths, options) ->
    @projectPaths = projectPaths
    @destroy()
    @nonProject = new Project null, options
    projectFolders = projectPaths.filter isDirectory
    @projects = for projectPath in projectFolders
      new Project(projectPath, options)
    console.log @projects


module.exports = ProjectManager
