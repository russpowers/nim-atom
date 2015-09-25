{BufferedProcess} = require 'atom'
KnownFiles = require './known-files'
path = require 'path'
{separateLines} = require './util'
{CommandTypes} = require './constants'

module.exports = (executor, options) ->
  grammarScopes: ['source.nim']
  scope: 'project'
  lintOnFly: options.lintOnFly
  lint: (editor) ->
    return new Promise (resolve, reject) ->
      if not options.nimExists
        resolve []

      executor.execute editor, CommandTypes.LINT, (err, results) ->
        if err?
          resolve []
        else
          resolve results