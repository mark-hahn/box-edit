###
  lib/box-edit.coffee
###

SubAtom = require 'sub-atom'

log = (args...) -> 
  console.log.apply console, ['box-edit, bsel:'].concat args

class BoxEdit
  
  activate: ->
    @wspace = atom.workspace
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-edit:toggle': => @toggle()
  
  toggle: ->
    if @active or
         not (@editor = @wspace.getActiveTextEditor()) or 
         @editor.isDestroyed()
      @clear()
      return 
    @active = yes
    @pane = @wspace.getActivePane()
    @editorView = atom.views.getView @editor
    
    @mouseInit()
    @getPageDims()
    @addBoxEle()
    @atomSelectionsToBox()
    @startUndo()
    @startCheckingPageDims()
    
    @pane.onDidChangeActiveItem    => @clear()
    document.body.onkeydown  = (e) => @keyDown  e
    document.body.onkeypress = (e) => @keyPress e

  clear: ->
    if not @active then return
    @active = no
    haveEditor = (@editor and not @editor.isDestroyed() and 
                    @pane and not   @pane.isDestroyed())
    @boxToAtomSelections() if haveEditor
    @removeBoxEle()
    @endUndo()
    if haveEditor
      @pane?.activate() 
      @editorView.classList.add    'boxsel-cursor'
      @editorView.classList.remove 'boxsel-cursor'
    @pane = @editorView = @editorComp = @buffer = null

  deactivate: ->
    @clear()
    @subs.dispose()  

mix = (mixinName) ->
  mixin = require './' + mixinName
  for key in Object.keys mixin
    BoxEdit.prototype[key] = mixin[key]

mix 'box'
mix 'edit-text'
mix 'editor'
mix 'keyboard'
mix 'mouse'
mix 'page'
mix 'undo'

module.exports = new BoxEdit

