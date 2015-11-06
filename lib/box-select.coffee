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
                  
    @selectMode = yes
    @addBoxEle()
    @cover.style.cursor = 'crosshair'
    @pane.onDidChangeActiveItem => @clear()
    document.body.onkeydown = (e) => @keyEvent e
    @undoBuffers = []
    @undoBoxes   = []
  
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
    
  getScreenRowCol: (x, y) ->
    row = Math.round y / @chrHgt
    row = Math.max 0, Math.min @buffer.getLastRow(), row
    col = Math.round x / @chrWid
    [row, col]

  getBoxRowCol: ->
    evt1Pos = @editorComp.pixelPositionForMouseEvent @initMouseEvent
    evt2Pos = @editorComp.pixelPositionForMouseEvent @lastMouseEvent
    {left: x1, top: y1} = evt1Pos
    {left: x2, top: y2} = evt2Pos
    @pageOfsX = @initMouseEvent.pageX - @editorPosX - x1
    @pageOfsY = @initMouseEvent.pageY - @editorPosY - y1
    if x1 > x2 then [x2, x1] = [x1, x2]
    if y1 > y2 then [y2, y1] = [y1, y2]
    [row1, col1] = @getScreenRowCol x1, y1
    [row2, col2] = @getScreenRowCol x2, y2
    row2 -= 1
    [row1, col1, row2, col2]
  
  setBoxRowCol: (rowCol) ->
    @setBoxVisible yes
    [row1, col1, row2, col2] = rowCol
    s = @box.style
    s.left = (col1 * @chrWid + @pageOfsX) + 'px'
    s.top  = (row1 * @chrHgt + @pageOfsY) + 'px'
    if (row2-row1) > 0 or (col2 - col1) > 0
      s.width  = ((col2-col1)   * @chrWid) + 'px'
      s.height = ((row2-row1+1) * @chrHgt) + 'px'
    else
      s.width  = '0'
      s.height = @chrHgt + 'px'
  
  copyDelFillPaste: (cmd, chr) ->
    [row1, col1, row2, col2] = @getBoxRowCol()
    if cmd isnt 'copy'
      @undoBuffers.push @editor.getText()
      @undoBoxes.push [row1, col1, row2, col2]
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
      @setBoxRowCol [row1, col1, row2, newCol2]
    
  mouseInEditor: (e) ->
    @editorPosX <= e.pageX < @editorPosX + @editorPosW and
    @editorPosY <= e.pageY < @editorPosY + @editorPosH

  mouseEvent: (e) ->
    if not @selectMode then return
    
    switch e.type
      
      when 'mousedown'
        @setBoxVisible no
        @initMouseEvent = @lastMouseEvent = e
        @dragging = yes
        @initPosX = e.pageX - @editorPosX
        @initPosY = e.pageY - @editorPosY
      
      when 'mousemove' 
        if not @dragging then return
        @lastMouseEvent = e
        @setBoxRowCol @getBoxRowCol()
      
      when 'mouseup'
        @dragging = no
        @lastMouseEvent = e
        @setBoxRowCol @getBoxRowCol()
        
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
          @setBoxRowCol @undoBoxes.pop()
      else log 'key not used by box-select:', codeStr
        
  clear: -> 
    @cover?.style.cursor = 'auto'
    @dragging = @selectMode = no
    @removeBoxEle()
    @pane.activate()
    @undoBuffers = @undoBoxes = null

  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect

