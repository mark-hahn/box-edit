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
    {left:  @editorPosX, top:    @editorPosY, \
     width: @editorPosW, height: @editorPosH} =
                  @editorView.getBoundingClientRect()
    {left: @pageOfsX, top: @pageOfsY} = 
      @editorComp.pixelPositionForMouseEvent clientX:0, clientY:0
    @pageOfsX += @editorPosX
    @pageOfsY += @editorPosY
    # log {@pageOfsX, @pageOfsY, @chrWid, @chrHgt, @editorPosX, @editorPosY}
    @selectMode = yes
    @atomSelToBox()
    @cover.style.cursor = 'crosshair'
    @pane.onDidChangeActiveItem => @clear()
    document.body.onkeydown = (e) => @keyEvent e
    @undoBuffers    = []
    @undoBoxRowCols = []

  hideAtomCursors: (destroy = no) ->
    for sel in @editor.getSelections()
      sel.clear()
    for cursor in @editor.getCursors()
      if destroy then cursor.destroy()
      else cursor.setVisible no
      
  showAtomCursors: ->
    for cursor in @editor.getCursors()
      cursor.setVisible yes
  
  atomSelToBox: ->
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
    @setBoxRowCol row1, col1, row2, col2
  
  addBoxEle: ->
    c = @cover = document.createElement 'div'
    c.id = 'boxsel-cover'
    s = c.style
    s.left   = @editorPosX + 'px'
    s.top    = @editorPosY + 'px'
    s.width  = @editorPosW + 'px'
    s.height = @editorPosH + 'px'
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

  xyToRowCol: (x1, y1, x2, y2) ->
    if x1 > x2 then [x2, x1] = [x1, x2]
    if y1 > y2 then [y2, y1] = [y1, y2]
    botRow = @buffer.getLastRow()
    row1 = Math.max      0, Math.round (y1+@pageOfsY) / @chrHgt
    col1 = Math.max      0, Math.round (x1+@pageOfsX) / @chrWid
    row2 = Math.min(botRow, Math.round (y2+@pageOfsY) / @chrHgt) - 1
    col2 = Math.min botRow, Math.round (x2+@pageOfsX) / @chrHgt
    [row1, col1, row2, col2]

  rowColToXY: (row1, col1, row2, col2) ->
    # log 'rowColToXY', {row1, @chrHgt, @pageOfsY, x: row1   * @chrHgt, res: row1   * @chrHgt - @pageOfsY}
    [col1 * @chrWid - @pageOfsX,  row1   * @chrHgt - @pageOfsY,
     col2 * @chrWid - @pageOfsX, (row2+1)* @chrHgt - @pageOfsY]

  getBoxRowCol: -> @xyToRowCol @boxX1, @boxY1, @boxX2, @boxY2
  
  setBoxRowCol: (row1, col1, row2, col2) ->
    # log 'setBoxRowCol', {row1, col1, row2, col2}
    [x1, y1, x2, y2] = @rowColToXY row1, col1, row2, col2
    s = @box.style
    s.left = x1 + 'px'
    s.top  = y1 + 'px'
    if (x2-x1) > 0 or (y2-y1) > 0
      s.width  = (x2-x1) + 'px'
      s.height = (y2-y1) + 'px'
    else
      s.width  = '0'
      s.height = @chrHgt + 'px'
    @setBoxVisible yes
  
  copyDelFillPaste: (cmd, chr) ->
    [row1, col1, row2, col2] = @getBoxRowCol()
    if cmd isnt 'copy'
      @undoBuffers.push @editor.getText()
      @undoBoxRowCols.push [row1, col1, row2, col2]
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
      bufRow  = bufRange.start.row
      bufCol1 = bufRange.start.column
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
      @setBoxRowCol row1, col1, row2, newCol2
    
  mouseEvent: (e) ->
    if not @selectMode then return
    
    switch e.type
      when 'mousedown'
        @setBoxVisible no
        @dragging = yes
        @boxX1 = e.pageX - @editorPosX
        @boxY1 = e.pageY - @editorPosY
      
      when 'mousemove' 
        if not @dragging then return
        @boxX2 = e.pageX - @editorPosX
        @boxY2 = e.pageY - @editorPosY
        @setBoxRowCol @getBoxRowCol()...
      
      when 'mouseup'
        @dragging = no
        @boxX2 = e.pageX - @editorPosX
        @boxY2 = e.pageY - @editorPosY
        @setBoxRowCol @getBoxRowCol()...
        
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
          else @copyDelFillPaste 'fill', codeStr; return
            
    if e.metaKey  then codeStr = 'Meta-'  + codeStr
    if e.shiftKey and hasModifier 
                       codeStr = 'Shift-' + codeStr
    if e.altKey   then codeStr = 'Alt-'   + codeStr
    if e.ctrlKey  then codeStr = 'Ctrl-'  + codeStr
    
    switch codeStr
      when 'Ctrl-X'              then @copyDelFillPaste 'cut'
      when 'Ctrl-C'              then @copyDelFillPaste 'copy'
      when 'Ctrl-V'              then @copyDelFillPaste 'paste'
      when 'Backspace', 'Delete' then @copyDelFillPaste 'del'
      when 'Escape'              then @clear()
      when 'Ctrl-Z'  
        if (oldBuf = @undoBuffers.pop())
          @editor.setText oldBuf
          @setBoxRowCol @undoBoxRowCols.pop()...
      else log 'key not used by box-select:', codeStr
        
  clear: -> 
    @cover?.style.cursor = 'auto'
    @dragging = @selectMode = no
    @removeBoxEle()
    @pane.activate()
    @undoBuffers = @undoBoxRowCols = null

  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect

