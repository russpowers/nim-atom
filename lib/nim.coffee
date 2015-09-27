{BufferedProcess, Point} = require 'atom'
SubAtom = require 'sub-atom'
Config = require './config'
Linter = require './linter'
AutoCompleter = require './auto-completer'
ProjectManager = require './project-manager'
Executor = require './executor'
Runner = require './runner'
NimStatusBarView = require './nim-status-bar-view'
{CommandTypes, AutoCompleteOptions} = require './constants'
{hasExt, arrayEqual, separateSpaces, debounce} = require './util'



checkForExecutable = (executablePath, cb) ->
  if executablePath != ''
    try
      process = new BufferedProcess
        command: executablePath
        args: ['--version']
        exit: (code) =>
          cb(code == 0)
          
      process.onWillThrowError ({error,handle}) =>
        handle()
        cb false
    catch e
      cb false
  else
    cb false

fixExecutableFilename = (executablePath) ->
  if executablePath.indexOf('~') != -1
    executablePath.replace('~', process.env.HOME)
  else
    executablePath

navigateToFile = (file, line, col, sourceEditor) ->
  # This function uses Nim coordinates
  atomLine = line - 1
  atom.workspace.open(file)
    .done (ed) ->
      # This belongs to the current project, even if it may be in a different place
      if not ed.nimProject?
        ed.nimProject = sourceEditor.nimProject
      pos = new Point(atomLine, col)
      ed.scrollToBufferPosition(pos, center: true)
      ed.setCursorBufferPosition(pos)
  
module.exports =
  config: Config

  updateProjectsOnEditors: ->
    # Try to match up old and new projects
    for editor in atom.workspace.getTextEditors()
      if editor.nimProject?
        editor.nimProject = 
          if editor.nimProject.folderPath?
            @projectManager.getProjectForPath editor.nimProject.folderPath
          else
            @projectManager.getProjectForPath editor.getPath()
    null

  updateProjectManager: ->
    @projectManager.update(atom.project.rootDirectories.map((x) -> x.path), @options)
    @updateProjectsOnEditors()

  checkForExes: (cb) ->
    oldNimExists = @options.nimExists
    oldNimSuggestExists = @options.nimSuggestExists
    checkedNim = false
    checkedNimSuggest = false

    done = =>
      if not @options.nimExists
        atom.notifications.addError "Could not find nim executable, please check nim package settings"
      else if oldNimExists == false
        atom.notifications.addSuccess "Found nim executable"

      if not @options.nimSuggestExists and @options.nimSuggestEnabled
        atom.notifications.addError "Could not find nimsuggest executable, please check nim package settings"

      if @options.nimSuggestExists and oldNimSuggestExists == false
        atom.notifications.addSuccess "Found nimsuggest executable"

      cb()

    checkForExecutable @options.nimExe, (found) =>
      @options.nimExists = found
      checkedNim = true
      if checkedNimSuggest
          done()

    checkForExecutable @options.nimSuggestExe, (found) =>
      @options.nimSuggestExists = found
      checkedNimSuggest = true
      if checkedNim
          done()

  activate: (state) ->
    @options =
      nimSuggestExe: fixExecutableFilename(atom.config.get('nim.nimsuggestExecutablePath') or 'nimsuggest')
      nimExe: fixExecutableFilename(atom.config.get('nim.nimExecutablePath') or 'nim')
      nimSuggestEnabled: atom.config.get 'nim.nimsuggestEnabled'
      lintOnFly: atom.config.get 'nim.onTheFlyChecking'

    @runner = new Runner(() => @statusBarView)
    @projectManager = new ProjectManager()
    @executor = new Executor @projectManager
    @checkForExes => 
      require('atom-package-deps').install('nim', true)
        .then => @activateAfterChecks(state)
        
  save: (editor, cb) ->
    if editor.isModified()
      disposable = editor.buffer.onDidSave ->
        disposable.dispose()
        cb()
      editor.save()
    else
      cb()

  saveAllModified: (cb) ->
    savedCount = 0
    count = 0
    for editor in atom.workspace.getTextEditors()
      if editor.isModified()
        count += 1

    if count == 0
      cb()

    for editor in atom.workspace.getTextEditors()
      if editor.isModified()
        @save editor, ->
          savedCount += 1
          if savedCount == count
            cb()

    null

  gotoDefinition: (editor) ->
    @executor.execute editor, CommandTypes.DEFINITION, (err, data) ->
      if not err? and data?
        navigateToFile data.path, data.line, data.col, editor

  run: (editor, cb) ->
    runCmd = atom.config.get 'nim.runCommand'
    if runCmd == ''
      return atom.notifications.addError "Run Command not specified, please check nim package settings"

    @build editor, (success) =>
      if not success
        cb("Build failed.") if cb?
        return
        
      project = editor.nimProject
      filePath = editor.getPath()

      newRunCmd = runCmd
        .replace('<bin>', project.getBinFilePathFor(filePath))
        .replace('<binpath>', project.getBinFolderPathFor(filePath))

      @statusBarView?.showInfo "Nim run started"
      @runner.run newRunCmd

  build: (editor, cb) ->
    @statusBarView?.showInfo("Nim build started", 0)
    #atom.notifications.addInfo "Build started.."

    @runner.waitUntilFinished =>
      afterSaves = =>
        @executor.execute editor, CommandTypes.BUILD, (err, result, extra) =>
          if err?
            @statusBarView?.showError("Nim build failed")
            cb("Build failed") if cb?
          else if extra.code != 0
            @linterApi.setMessages(@linter, result)
            @statusBarView?.showError("Nim build failed")
            # atom.notifications.addError "Build failed.",
            #   detail: "Project root: #{extra.filePath}"
            cb(false) if cb?
          else
            @linterApi.setMessages(@linter, result)
            @statusBarView?.showSuccess("Nim build succeeded")
            # atom.notifications.addSuccess "Build succeeded.",
            #   detail: "Project root: #{extra.filePath}"
            #   dismissable: true
            cb(true) if cb?

      abb = atom.config.get 'nim.autosaveBeforeBuild'

      if abb == 'Save all files'
        @saveAllModified afterSaves
      else if abb == 'Save current file'
        @save editor, afterSaves

  activateAfterChecks: (state) ->
    @updateProjectManager()
    
    self = @

    atom.commands.add 'atom-text-editor',
      'nim:goto-definition': (ev) ->
        editor = @getModel()
        return if not editor
        self.gotoDefinition editor

    atom.commands.add 'atom-text-editor',
      'nim:run': (ev) ->
        editor = @getModel()
        return if not editor
        self.run editor

    atom.commands.add 'atom-text-editor',
      'nim:build': (ev) ->
        editor = @getModel()
        return if not editor
        self.build editor

    updateProjectManagerDebounced = debounce 2000, =>
      @checkForExes => @updateProjectManager()

    @subscriptions = new SubAtom()
    @subscriptions.add atom.config.onDidChange 'nim.nimExecutablePath', (path) =>
      @options.nimExe = fixExecutableFilename(path.newValue or 'nim')
      updateProjectManagerDebounced()

    @subscriptions.add atom.config.onDidChange 'nim.nimsuggestExecutablePath', (path) =>
      @options.nimSuggestExe = fixExecutableFilename(path.newValue or 'nimsuggest')
      nsen = atom.config.get 'nim.nimsuggestEnabled'
      if path.newValue == ''
        atom.config.set('nim.nimsuggestEnabled', false) if nsen
      else
        atom.config.set('nim.nimsuggestEnabled', true) if not nsen
      updateProjectManagerDebounced()

    @subscriptions.add atom.config.onDidChange 'nim.nimsuggestEnabled', (enabled) =>
      @options.nimSuggestEnabled = enabled.newValue
      updateProjectManagerDebounced()

    @subscriptions.add atom.config.observe 'nim.useCtrlShiftClickToJumpToDefinition', (enabled) =>
      @options.ctrlShiftClickEnabled = enabled

    @subscriptions.add atom.config.observe 'nim.autocomplete', (value) =>
      @options.autocomplete = if value == 'Always'
        AutoCompleteOptions.ALWAYS
      else if value == 'Only after dot'
        AutoCompleteOptions.AFTERDOT
      else if value == 'Never'
        AutoCompleteOptions.NEVER

    @subscriptions.add atom.project.onDidChangePaths (paths) =>
      if not arrayEqual paths, @projectManager.projectPaths
        @updateProjectManager()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editorPath = editor.getPath()
      return if not hasExt(editorPath, '.nim') and not hasExt(editorPath, '.nims')

      # For binding ctrl-shift-click
      editorSubscriptions = new SubAtom()
      editorElement = atom.views.getView(editor)
      editorLines = editorElement.shadowRoot.querySelector '.lines'

      editorSubscriptions.add editorLines, 'mousedown', (e) =>
        return unless @options.ctrlShiftClickEnabled 
        return unless e.which is 1 and e.shiftKey and e.ctrlKey
        screenPos = editorElement.component.screenPositionForMouseEvent(e)
        editor.setCursorScreenPosition screenPos
        @gotoDefinition editor
        return false
      editorSubscriptions.add editor.onDidDestroy =>
        editorSubscriptions.dispose()
        @subscriptions.remove(editorSubscriptions)
      @subscriptions.add(editorSubscriptions)

  deactivate: ->
    @subscriptions.dispose()
    @projectManager.destroy()
    @statusBarView?.destroy()
    @statusBarTile?.destroy()

  nimLinter: ->
    @linter = Linter @executor, @options
    @linter

  consumeLinter: (linterApi) ->
    @linterApi = linterApi

  consumeStatusBar: (statusBar) ->
    @statusBarView = new NimStatusBarView()
    @statusBarView.init 5000
    @statusBarTile = statusBar.addRightTile(item: @statusBarView, priority: 50)

  nimAutoComplete: -> AutoCompleter @executor, @options