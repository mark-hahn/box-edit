###
  lib/box-select.coffee
###

SubAtom = require 'sub-atom'

log = (args...) -> 
  console.log.apply console, ['box-select:'].concat args

class BoxSelect
  
  activate: ->
    @wspace = atom.workspace
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-select:toggle': => @toggle()
  
  toggle: ->
    if @selectMode then @clear(); return  
    if not (@editor = @wspace.getActiveTextEditor()) then @clear(); return 
    
    @pane       = @wspace.getActivePane()
    @editorView = atom.views.getView @editor
    @editorComp = @editorView.component
    @buffer     = @editor.getBuffer()
    @chrWid     = @editor.getDefaultCharWidth()
    @chrHgt     = @editor.getLineHeightInPixels()
    {left: @editorPageX, top: @editorPageY, width: @editorW, height: @editorH} =
                   @editorView.getBoundingClientRect()
    {left, top}  = @editorComp.pixelPositionForMouseEvent clientX:0, clientY:0
    @textPageX   = -left
    @textPageY   = -top
    @textOfsX    = @textPageX - @editorPageX  
    @textOfsY    = @textPageY - @editorPageY 
    
    @selectMode = yes
    @atomSelectionsToBox()
    @cover.style.cursor = 'crosshair'
    @pane.onDidChangeActiveItem => @clear()
    document.body.onkeydown = (e) => @keyEvent e
    @undoBuffers    = []
    @undoBoxRowCols = []

  atomSelectionsToBox: ->
    row1 = col1 = +Infinity
    row2 = col2 = -Infinity
    for sel in @editor.getSelections()
      range = sel.getBufferRange()
      row1 = Math.min row1, range.start.row,    range.end.row
      col1 = Math.min col1, range.start.column, range.end.column
      row2 = Math.max row2, range.start.row,    range.end.row
      col2 = Math.max col2, range.start.column, range.end.column
    @addBoxEle()
    # log 'atomSelToBox', {row1, col1, row2, col2}
    @setBoxByRowCol row1, col1, row2, col2
    for selection in @editor.getSelections()
      selection.destroy()
    @editor.getLastCursor().setVisible no
    
  bufferOperation: (cmd, chr) ->
    oldBufferText = @editor.getText()
    oldRowCol = [row1, col1, row2, col2] = @getBoxRowCol()
    log 'bufferOperation', {row1, col1, row2, col2}
    if cmd is 'paste'  
      clipTxt = atom.clipboard.read()
      clipLines = clipTxt.split '\n'
      clipWidth = 0
      for clipLine in clipLines 
        clipWidth = Math.max clipWidth, clipLine.length
    copyText = []; lastBufRow = null; fillStr = ''
    if cmd is 'fill' then for i in [col1...col2] then fillStr += chr
    rowIdx = 0
    for row in [row1..row2]
      bufRange = @editor.bufferRangeForScreenRange [[row, col1], [row, col2]]
      bufRow   = bufRange.start.row
      if bufRow is lastBufRow then continue
      lastBufRow = bufRow
      if cmd in ['copy', 'cut'] 
        copyText.push @editor.getTextInBufferRange bufRange
      if cmd is 'paste'
        fillStr = clipLines[rowIdx] ? ''
        while fillStr.length < clipWidth then fillStr += ' '
      if cmd in ['cut', 'del', 'fill', 'paste']
        @editor.setTextInBufferRange bufRange, fillStr
      rowIdx++
    if cmd is 'copy'  then atom.clipboard.write copyText.join '\n'
    
    newCol2 = col1 + (if cmd is 'paste' then clipWidth else 0)
    if cmd in ['cut', 'del', 'paste']
      @setBoxByRowCol row1, col1, row2, newCol2
    
    if @editor.getText() isnt oldBufferText
      @undoBuffers.push oldBufferText
      @undoBoxRowCols.push oldRowCol
    
  boxToAtomSelections: ->
    oldSelection = @editor.getLastSelection()
    [row1, col1, row2, col2] = @getBoxRowCol()
    for row in [row1..row2]
      @editor.addSelectionForBufferRange [[row, col1], [row, col2]]
    oldSelection.destroy()
          
  addBoxEle: ->
    c = @cover = document.createElement 'div'
    c.id = 'boxsel-cover'
    s = c.style
    s.left   = @editorPageX + 'px'
    s.top    = @editorPageY + 'px'
    s.width  = @editorW + 'px'
    s.height = @editorH + 'px'
    setTimeout (-> s.cursor = 'crosshair'), 50
    b = @box = document.createElement 'div'
    b.id     = 'boxsel-box'
    document.body.appendChild c
    c.appendChild b
    c.onmousedown = (e) => @mouseEvent(e)
    c.onmousemove = (e) => @mouseEvent(e)
    c.onmouseup   = (e) => @mouseEvent(e)
  
  removeBoxEle: ->
    if @cover 
      document.body.removeChild @cover
      @cover.removeChild @box
      @cover = @box = null
      
  setBoxVisible: (@boxVisible) ->
    @box?.style.visibility = 
      (if @boxVisible then 'visible' else 'hidden')

  setBoxByXY: (x1, y1, x2, y2, snap2grid = yes) ->
    # log 'setBoxByXY', {x1, y1, x2, y2}
    if snap2grid
      x1 = Math.round(x1/@chrWid) * @chrWid
      y1 = Math.round(y1/@chrHgt) * @chrHgt
      x2 = Math.round(x2/@chrWid) * @chrWid
      y2 = Math.round(y2/@chrHgt) * @chrHgt
    if x1 > x2 then [x1, x2] = [x2, x1]
    if y1 > y2 then [y1, y2] = [y2, y1]
    s = @box.style
    s.left = (x1 + @textOfsX) + 'px'
    s.top  = (y1 + @textOfsY) + 'px'
    if (x2-x1) > 0 or (y2-y1) > 0
      s.width  = (x2-x1) + 'px'
      s.height = (y2-y1) + 'px'
    else
      s.width  = '0'
      s.height = @chrHgt + 'px'
    @setBoxVisible yes

  setBoxByRowCol: (row1, col1, row2, col2) ->
    # log 'setBoxByRowCol', {row1, col1, row2, col2}
    @setBoxByXY col1 * @chrWid,  row1    * @chrHgt, 
                col2 * @chrWid, (row2+1) * @chrHgt, no

  getBoxRowCol: -> 
    s = @box.style
    style2dim = (attr) -> +(s[attr].replace 'px', '')
    x1 = style2dim('left') - @textOfsX
    y1 = style2dim('top')  - @textOfsY
    x2 = x1 + style2dim 'width'
    y2 = y1 + style2dim 'height'
    botRow = @buffer.getLastRow()
    row1 = Math.max      0,  Math.round y1 / @chrHgt
    col1 = Math.max      0,  Math.round x1 / @chrWid
    row2 = Math.min botRow, (Math.round y2 / @chrHgt) - 1
    col2 =                   Math.round x2 / @chrWid
    log 'getBoxRowCol', {x1, y1, x2, y2, row1, col1, row2, col2}
    [row1, col1, row2, col2]

  mouseEvent: (e) ->
    if not @selectMode then return
    
    switch e.type
      when 'mousedown'
        @mouseIsDown = yes
        @initX1 = e.pageX - @textPageX
        @initY1 = e.pageY - @textPageY
        @setBoxVisible no
      
      when 'mousemove' 
        if not @mouseIsDown then return
        x2 = e.pageX - @textPageX
        y2 = e.pageY - @textPageY
        @setBoxByXY @initX1, @initY1, x2, y2
      
      when 'mouseup'
        if not @mouseIsDown then return
        @mouseIsDown = no
        x2 = e.pageX - @textPageX
        y2 = e.pageY - @textPageY
        @setBoxByXY @initX1, @initY1, x2, y2
        
  keyEvent: (e) ->
    if not @selectMode then return
    hasModifier = (e.shiftKey or e.ctrlKey or e.altKey or e.metaKey)
    codeStr = e.keyIdentifier
    if codeStr[0..1] is 'U+'
      code = parseInt codeStr[2..5], 16
      switch code
        when   8 then codeStr = 'Backspace'
        when   9 then codeStr = 'Tab'
        when  10 then codeStr = 'LineFeed'
        when  13 then codeStr = 'Return'
        when  27 then codeStr = 'Escape'
        when 127 then codeStr = 'Delete'
        else
          asciiPrintable = (32 <= code < 127)
          if e.shiftKey  and asciiPrintable     then hasModifier = no
          if hasModifier and not asciiPrintable then return
          codeStr = String.fromCharCode code
          if not e.shiftKey then codeStr = codeStr.toLowerCase()
          if hasModifier    then codeStr = codeStr.toUpperCase()
          else @bufferOperation 'fill', codeStr; return
            
    if e.metaKey  then codeStr = 'Meta-'  + codeStr
    if e.shiftKey and hasModifier 
                       codeStr = 'Shift-' + codeStr
    if e.altKey   then codeStr = 'Alt-'   + codeStr
    if e.ctrlKey  then codeStr = 'Ctrl-'  + codeStr
    
    switch codeStr
      when 'Ctrl-X'              then @bufferOperation 'cut'
      when 'Ctrl-C'              then @bufferOperation 'copy'
      when 'Ctrl-V'              then @bufferOperation 'paste'
      when 'Backspace', 'Delete' then @bufferOperation 'del'
      when 'Escape'              then @clear()
      when 'Ctrl-Z'  
        if (oldBuf = @undoBuffers.pop())
          @editor.setText oldBuf
          @setBoxByRowCol @undoBoxRowCols.pop()...
      else 
        log 'key not used by box-select:', codeStr
        return
        
    e.stopPropagation()
    e.preventDefault()
        
  clear: -> 
    @boxToAtomSelections()
    @removeBoxEle()
    @mouseIsDown = @selectMode = no
    @undoBuffers = @undoBoxRowCols = null
    @pane.activate()

  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect

