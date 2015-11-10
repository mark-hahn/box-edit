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
    @getAtomReferences()
    @mouseInit()
    @getPageDims()
    @addBoxEle()
    @atomSelectionsToBox()
    @checkPageDims()
    @startUndo()
    
    @pane.onDidChangeActiveItem    => @clear()
    document.body.onkeydown  = (e) => @keyDown  e
    document.body.onkeypress = (e) => @keyPress e
    
  getAtomReferences: ->
    @pane       = @wspace.getActivePane()
    @editorView = atom.views.getView @editor
    @buffer     = @editor.getBuffer()
  
  clear: ->
    @active = no
    haveEditor = (@editor and not @editor.isDestroyed() and 
                    @pane and not   @pane.isDestroyed())
    @boxToAtomSelections() if haveEditor
    @removeBoxEle()
    @endUndo()
    @pane?.activate() if haveEditor
    @pane = @editorView = @editorComp = @buffer = null

  deactivate: ->
    @clear()
    @subs.dispose()  

mix = (mixinName) ->
  mixin = require './' + mixinName
  for key in Object.keys mixin
    BoxEdit.prototype[key] = mixin[key]

mix 'box'
mix 'editor'
mix 'keyboard'
mix 'mouse'
mix 'page'
mix 'undo'

module.exports = new BoxEdit

