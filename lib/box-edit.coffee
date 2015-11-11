###
  lib/box-edit.coffee
###

SubAtom = require 'sub-atom'

log = (args...) -> 
  console.log.apply console, ['box-edit, bsel:'].concat args

class BoxEdit
  
  activate: ->
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-edit:toggle': => @toggle()
  
  toggle: ->
    if @active or
         not (@editor = atom.workspace.getActiveTextEditor()) or 
         @editor.isDestroyed()
      @clear()
      return 
      
    @active = yes
    @pane = atom.workspace.getActivePane()
    @editorView = atom.views.getView @editor
    
    @getPageDims()
    @pageInit()
    @mouseInit()
    @addBoxEle()
    @atomSelectionsToBox()
    @startUndo()
    @startCheckingPageDims()
    
    @subs.add @pane.onDidChangeActiveItem => @clear()
    @subs.add @editor.onDidDestroy        => @clear()
    document.body.onkeydown  = (e)        => @keyDown  e
    document.body.onkeypress = (e)        => @keyPress e

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
      # doesn't fix cursor not changing 
      # @editorView.classList.add    'boxsel-cursor'
      # @editorView.classList.remove 'boxsel-cursor'
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

