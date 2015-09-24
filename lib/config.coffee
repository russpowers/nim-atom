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