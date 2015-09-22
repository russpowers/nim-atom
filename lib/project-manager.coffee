Project = require './project'

class ProjectManager
  constructor: ->
    @projectPaths = []
    @projects = []

  destroy: ->
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
    found

  update: (projectPaths, options) ->
    @projectPaths = projectPaths
    @destroy()
    @projects = for projectPath in projectPaths
      new Project(projectPath, options)


module.exports = ProjectManager
