{BufferedProcess, Point} = require 'atom'
SubAtom = require 'sub-atom'
Config = require './config'
Linter = require './linter'
AutoCompleter = require './auto-completer'
ProjectManager = require './project-manager'
Executor = require './executor'
{CommandTypes} = require './constants'
{arrayEqual, separateSpaces, debounce} = require './util'

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

  updateProjectManager: ->
    @projectManager.update(atom.project.rootDirectories.map((x) -> x.path), @options)


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

    new BufferedProcess
      command: @options.nimExe
      args: ['--version']
      exit: (code) =>
        @options.nimExists = code == 0
        checkedNim = true
        if checkedNimSuggest
          done()

    new BufferedProcess
      command: @options.nimSuggestExe
      args: ['--version']
      exit: (code) =>
        @options.nimSuggestExists = code == 0
        console.log code
        checkedNimSuggest = true
        if checkedNim
          done()

  activate: (state) ->
    @options =
      rootFilenames: separateSpaces(atom.config.get 'nim.projectFilenames')
      nimSuggestExe: atom.config.get 'nim.nimsuggestExecutablePath' or 'nimsuggest'
      nimExe: atom.config.get('nim.nimExecutablePath') or 'nim'
      nimSuggestEnabled: atom.config.get 'nim.nimsuggestEnabled'
      lintOnFly: atom.config.get 'nim.onTheFlyChecking'

    @projectManager = new ProjectManager()
    @executor = new Executor @projectManager
    @checkForExes => @activateAfterChecks(state)

  activateAfterChecks: (state) ->
    @updateProjectManager()
    
    self = @
    atom.commands.add 'atom-text-editor',
      'nim:goto-definition': (ev) ->
        editor = @getModel()
        return if not editor
        self.executor.execute editor, CommandTypes.DEFINITION, (data) ->
          if data
            navigateToFile data.path, data.line, data.col, editor

    updateProjectManagerDebounced = debounce 2000, =>
      @checkForExes => @updateProjectManager()

    @subscriptions = new SubAtom()
    @subscriptions.add atom.config.onDidChange 'nim.nimExecutablePath', (path) =>
      @options.nimExe = path.newValue or 'nim'
      updateProjectManagerDebounced()

    @subscriptions.add atom.config.onDidChange 'nim.nimsuggestExecutablePath', (path) =>
      @options.nimSuggestExe = path.newValue or 'nimsuggest'
      nsen = atom.config.get 'nim.nimsuggestEnabled'
      if path.newValue == ''
        atom.config.set('nim.nimsuggestEnabled', false) if nsen
      else
        atom.config.set('nim.nimsuggestEnabled', true) if not nsen
      updateProjectManagerDebounced()

    @subscriptions.add atom.config.onDidChange 'nim.nimsuggestEnabled', (enabled) =>
      @options.nimSuggestEnabled = enabled.newValue
      updateProjectManagerDebounced()

    @subscriptions.add atom.config.observe 'nim.useAltClickToJumpToDefinition', (enabled) =>
      @options.altClickEnabled = enabled

    @subscriptions.add atom.config.onDidChange 'nim.projectFilenames', (filenames) =>
      @options.rootFilenames = separateSpaces filenames.newValue
      updateProjectManagerDebounced()

    @subscriptions.add atom.project.onDidChangePaths (paths) =>
      if not arrayEqual paths, @projectManager.projectPaths
        @updateProjectManager()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editorSubscriptions = new SubAtom()
      editorElement = atom.views.getView(editor)
      editorLines = editorElement.shadowRoot.querySelector '.lines'
      editorSubscriptions.add editorLines, 'mousedown', (e) =>
        return unless @options.altClickEnabled and event.altKey and event.which is 1
        setTimeout(() -> atom.commands.dispatch editorElement, 'nim:goto-definition', 0)
      editorSubscriptions.add editor.onDidDestroy =>
        editorSubscriptions.dispose()
        @subscriptions.remove(editorSubscriptions)
      @subscriptions.add(editorSubscriptions)

  deactivate: ->
    @subscriptions.dispose()
    @projectManager.destroy()

  nimLinter: -> Linter @options

  nimAutoComplete: -> AutoCompleter @executor