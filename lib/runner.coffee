cp = require 'child_process'
class Runner
  constructor: (@statusBarViewFn) ->

  run: (fullCmd, cb) ->
    if @process?
      @waitUntilFinished @process.pid
      @onKilled = () => @run(fullCmd, cb)
      return

    @onKilled = null

    @process = cp.exec fullCmd, =>
      @process = null
      if cb?
        cb()
      if @onKilled?
        @statusBarViewFn?().clearText()
        @onKilled()

  waitUntilFinished: (cb) ->
    if @process?
      @statusBarViewFn()?.showWarning 'Nim waiting for running process to close', 0
      @onKilled = cb
    else
      cb() if cb?

module.exports = Runner