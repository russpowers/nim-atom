cp = require 'child_process'

class Runner
  run: (fullCmd) ->
    if @process?
      @process.kill('SIGINT')
      @next = fullCmd
      return

    @process = cp.exec fullCmd, =>
      @process = null
      if @next?
        next = @next
        @next = null
        @run next

module.exports = Runner