
log = (args...) -> 
  console.log.apply console, ['box-edit, edit:'].concat args
wrap = require 'wordwrap'

module.exports =
  openTextEditor: ->
    text = @editText 'getText'
    [row1, col1, row2, col2] = @getBoxRowCol()
    t = @textEditor = document.createElement 'textArea'
    t.id = 'boxsel-txtarea'
    t   .classList.add 'native-key-bindings'
    @box.classList.add 'native-key-bindings'
    t.rows = row2-row1+1; t.cols = @textEditorNumCols = col2-col1-1
    t.spellcheck = yes;   t.wrap = 'hard'
    t.autocomplete = no
    t.value = text
    [x1, y1, x2, y2] = @getBoxXY()     
    w = Math.max x2 - x1 + 30, 120     
    h = Math.max y2 - y1 + 30,  40
    ts = t.style
    bs = @box.style
    es = window.getComputedStyle @editorView
    ts.left            = bs.left
    ts.top             = bs.top
    ts.width           = w + 'px'
    ts.height          = h + 'px'
    ts.fontFamily      = es.fontFamily
    ts.backgroundColor = es.backgroundColor
    ts.color           = es.color
    ts.fontSize        = es.fontSize
    ts.lineHeight      = es.lineHeight
    @cover.appendChild t
    @setBoxVisible no
    @textEditor.focus()
    
  refreshTxtEditorPos: ->
    if @textEditor
      bs = @box.style
      ts = @textEditor.style
      ts.left = bs.left
      ts.top  = bs.top
  
  closeTextEditor: ->
    @setBoxVisible yes
    if @textEditor 
      @addToUndo @editText('getText'), @getBoxRowCol()
      @editText 'setText', wrap(@textEditorNumCols+5) @textEditor.value
      @cover.removeChild @textEditor
      @textEditor = null
