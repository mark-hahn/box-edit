###
  lib/box-select.coffee
###

SubAtom = require 'sub-atom'

class BoxSelect
  config:
    selectionColor:
      title: 'Mouse Hold Delay (MS)'
      type:'text'
      default: '#888'
      
  activate: ->
    @subs = new SubAtom

    
  clear: -> 
    if @isDragging then @drop()
    @clearTimeouts()
    @active = @selected = @isDragging = no
    @marker?.destroy()
    
  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect
