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

  nimLibPath:
    type: 'string'
    default: ''
    description: 'Full path to the nim standard library (ex: c:\\nim\\lib).  This is optional, only use this if nim or nimsuggest cannot find system.nim.'
    order: 3

  nimsuggestEnabled:
    type: 'boolean'
    default: false
    description: 'Use nimsuggest server to speed up autocomplete and jump to definition.  Only available when opening a folder where one of the Project Filenames (see below) is found.'
    order: 4

  onTheFlyChecking:
    type: 'boolean'
    default: false
    description: 'Enables live file-level eror checking.  If this is disabled, files will only be checked for errors on save.  You must restart Atom for this to take effect.'
    order: 5

  autocomplete:
    type: 'string'
    default: 'Always'
    enum: ['Always', 'Only after dot', 'Never']
    order: 6

  useCtrlShiftClickToJumpToDefinition:
    type: 'boolean'
    default: true
    description: 'If this is disabled, alt-g can also be used, but it is slow for some reason.'
    order: 7

  autosaveBeforeBuild:
    type: 'string'
    default: 'Save all files'
    enum: ['Save all files', 'Save current file', "Don't save any files"]
    order: 8

  runCommand:
    type: 'string'
    default: ''
    description: """ The command to execute when running projects.  This command can use the variables <code>&lt;bin&gt;</code> (absolute executable path) and <code>&lt;binpath&gt;</code> (absolute executable directory).
      Note that it executes the command as a child process, which doesn't have a terminal window unless you open one explicity in the command.  Examples (type the correct one into the box below):<br/><br/>
      <b>No terminal window, any platform:</b> <code>&lt;bin&gt;</code><br/>
      <b>Windows w/ terminal:</b> <code>start &lt;bin&gt;</code><br/>
      <b>OSX w/ terminal:</b> <code>open -a Terminal "&#96;&lt;bin&gt;&#96;"</code><br/> 
      <b>Linux w/ terminal (gnome):</b> <code>gnome-terminal -e "&lt;bin&gt;"</code><br/>
      """
    order: 9