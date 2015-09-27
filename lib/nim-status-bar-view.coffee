class NimStatusBarView extends HTMLElement
  init: (timeout) ->
    @timeout = timeout
    @classList.add('nim-status-bar', 'inline-block')
    @activate()

  activate: ->
    @textContext = ""
 
  destroy: ->
    clearInterval @intervalId
 
  clearClasses: ->
    @classList.remove 'success', 'info', 'error', 'warning'

  doMessage: (text, type, timeout) ->
    @clearClasses()
    @classList.add type
    @textContent = text
    if @timeoutHandle?
      clearTimeout @timeoutHandle
    hide = => @clearText()
    ms = if timeout? then timeout else @timeout
    if ms > 0
      @timeoutHandle = setTimeout hide, ms

  showError: (text, timeout) -> @doMessage text, 'error', timeout

  showSuccess: (text, timeout) -> @doMessage text, 'success', timeout

  showInfo: (text, timeout) -> @doMessage text, 'info', timeout

  showWarning: (text, timeout) -> @doMessage text, 'warning', timeout

  

  clearText: ->
    @clearClasses()
    @textContent = ''
 
module.exports = document.registerElement 'nim-status-bar',
  prototype: NimStatusBarView.prototype, extends: 'div'