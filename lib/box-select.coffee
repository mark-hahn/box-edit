###
  lib/box-select.coffee
  wrap problems when shrinking page
  border should check against longest line contained
  scrollwheel broken
  box not updated on auto-scroll
###

SubAtom = require 'sub-atom'

log = (args...) -> 
  console.log.apply console, ['box-select, bsel:'].concat args

class BoxSelect
  
  activate: ->
    @wspace = atom.workspace
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-select:toggle': => @toggle()
  
  toggle: ->
    if @active or
         not (@editor = @wspace.getActiveTextEditor()) or 
         @editor.isDestroyed()
      @clear()
      return 
      
    @active = yes
    @getAtomReferences()
    @getPageDims()
    @addBoxEle()
    @createBoxWithAtomSelections()
    @checkPageDims()
    @pane.onDidChangeActiveItem    => @clear()
    document.body.onkeydown  = (e) => @keyDown  e
    document.body.onkeypress = (e) => @keyPress e
    @undoBuffers    = []
    @undoBoxRowCols = []
    @undoIdx = 0
    
  getAtomReferences: ->
    @pane       = @wspace.getActivePane()
    @editorView = atom.views.getView @editor
    @editorComp = @editorView.component
    @buffer     = @editor.getBuffer()
  
  clear: ->
    haveEditor = (@editor and not @editor.isDestroyed() and 
                    @pane and not   @pane.isDestroyed())
    @boxToAtomSelections() if haveEditor
    @removeBoxEle()
    @mouseIsDown = @active = no
    @undoBuffers = @undoBoxRowCols = null
    @undoIdx = 0
    @pane?.activate() if haveEditor
    @pane = @editorView = @editorComp = @buffer = null

  deactivate: ->
    @clear()
    @subs.dispose()  

mix = (mixinName) ->
  mixin = require './' + mixinName
  for key in Object.keys mixin
    BoxSelect.prototype[key] = mixin[key]

mix 'box'
mix 'editor'
mix 'keyboard'
mix 'mouse'
mix 'page'
mix 'undo'

module.exports = new BoxSelect

