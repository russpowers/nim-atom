module.exports =
  nimExecutablePath:
    type: 'string'
    default: ''
    description: 'Full path to the nim executable (ex: c:\\nim\\bin\\nim).  This is not required if nim is in your PATH.'
    order: 1

  nimsuggestExecutablePath:
    type: 'string'
    default: ''
    description: 'Full path to the nimsuggest executable (ex: c:\\nimsuggest\\nimsuggest).  Get it at <a href="https://github.com/nim-lang/nimsuggest">https://github.com/nim-lang/nimsuggest</a>.'
    order: 2

  nimsuggestEnabled:
    type: 'boolean'
    default: false
    description: 'Use nimsuggest server to speed up autocomplete and jump to definition.  Only available when opening a folder where one of the Project Filenames (see below) is found.'
    order: 3

  onTheFlyChecking:
    type: 'boolean'
    default: false
    description: '<b>Note: This is broken for any projects comprised of more than one file.</b>  It enables live file-level eror checking.  If this is disabled, files will only be checked for errors on save.  You must restart Atom for this to take effect.'
    order: 4

  autocomplete:
    type: 'string'
    default: 'Always'
    enum: ['Always', 'Only after dot', 'Never']
    order: 5

  useCtrlShiftClickToJumpToDefinition:
    type: 'boolean'
    default: true
    description: 'If this is disabled, alt-g can also be used, but it is slow for some reason.'
    order: 6

  projectFilenames:
    type: 'string'
    default: '<nimble>.nim proj.nim <parent>.nim'
    description: 'Any filename that will be automatically used as the project file if found in the root of an opened folder.  The first matching filename in the opened folder will be used.  &lt;parent&gt; will substitute the parent folder\'s name.  &lt;nimble&gt; will substitute the nimble package\'s name.'
    order: 7

  autosaveBeforeBuild:
    type: 'string'
    default: 'Save all files'
    enum: ['Save all files', 'Save current file', "Don't save any files"]
    order: 8

  runCommand:
    type: 'string'
    default: ''
    description: """ The command to execute to run projects.  This command should open a command prompt window and can use the variables &lt;bin&gt; and &lt;binpath&gt;.<br />Examples:<br />
      <b>Windows:</b> start &lt;bin&gt;<br/>
      <b>OSX:</b> open -a Terminal "backtick&lt;bin&gt;backtick" (Use backticks, I can't figure out how to write them in this field)<br/> 
      <b>Linux (gnome):</b> gnome-terminal -e "&lt;bin&gt;"<br/>
      If you have more, please let me know..
      """
    order: 9