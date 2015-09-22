{BufferedProcess} = require 'atom'
KnownFiles = require './known-files'
path = require 'path'
{separateLines} = require './util'


matchTemplate = (line) ->
  line.match ///
    ^(.+) # path 
    \((\d+), \s (\d+)\) \s template/generic \s instantiation \s from \s here///

matchWarningErrorHint = (line) ->
  line.match ///
    ^(.+) # path 
    \((\d+), \s (\d+)\) # line and column
    \s (Warning|Error|Hint): \s
    (.*) # message
    ///

matchInternalError = (line) ->
  line.match /// Error:\sinternal\serror: ///

module.exports = (options) ->
  grammarScopes: ['source.nim']
  scope: 'file'
  lintOnFly: options.lintOnFly
  lint: (editor) =>
    return new Promise (resolve, reject) =>
      if not options.nimExists
        resolve []

      results = []
      fullMsgInfo = null
      foundInternalError = false

      handleLine = (filePath, line) ->
        templateMatch = matchTemplate line

        if templateMatch
          [_, sourcePath, line, col] = templateMatch
          sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
          msg = "#{sourcePath} (#{line}, #{col}) template/generic instantiation from here"
          if fullMsgInfo
            fullMsgInfo.msg = fullMsgInfo.msg + '<br />' + msg
          else
            fullMsgInfo =
              msg: msg
              line: line - 1
              col: col - 1
              filePath: sourcePath
          return

        wehMatch = matchWarningErrorHint line
        
        if wehMatch
          [_, sourcePath, line, col, type, msg] = wehMatch
          sourcePath = if sourcePath.endsWith 'stdinfile.nim' then filePath else KnownFiles.getCanonical(sourcePath)
          if type == 'Hint' then type = 'Info'
          line = line - 1 # convert to number
          col  = col - 1

          if fullMsgInfo
            col = fullMsgInfo.col
            line = fullMsgInfo.line
            msg = fullMsgInfo.msg + '<br />' + "#{sourcePath} (#{line}, #{col}) " + msg
            sourcePath = fullMsgInfo.filePath
            fullMsgInfo = null
       
          results.push
            filePath: sourcePath
            type: type
            html: msg
            range: [[line, col],[line, col+1]]
          return

        internalErrorMatch = matchInternalError line

        if internalErrorMatch
          foundInternalError = true
          return

      runProcess = (filePath, fileText) ->
        output = ''
        args = ["check", "--listFullPaths", "--colors:off", "--verbosity:0", if fileText? then '-' else filePath]
        process = new BufferedProcess
          command: options.nimExe
          args: args
          options:
            cwd: path.dirname filePath
          stderr: (data) -> # Not sure if this is even used
            output += data
            separateLines(data).forEach handleLine.bind(this, filePath)
          stdout: (data) ->
            output += data
            separateLines(data).forEach handleLine.bind(this, filePath)
          exit: (code) ->
            if foundInternalError
              atom.notifications.addError "Nim: Internal error executing linter",
                detail: "Details dumped to developer console.  Go to View -> Developer -> Toggle Developer Tools and open the Console to view."
              console.log "ERROR: Linter failed.\nCommand: #{options.nimExe} #{args.join(' ')}\nOutput:\n#{output}"
              resolve []
            else
              resolve results

        if fileText
          process.process.stdin.write fileText
          process.process.stdin.end()

        process.onWillThrowError ({error,handle}) ->
          atom.notifications.addError "Failed to run #{options.nimExe}",
            detail: "#{error.message}"
            dismissable: true
          handle()
          resolve []

      if editor.isModified()
        runProcess editor.getPath(), editor.getText()
      else
        runProcess editor.getPath()