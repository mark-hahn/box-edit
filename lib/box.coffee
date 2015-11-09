
log = (args...) -> 
  console.log.apply console, ['box-edit,  box:'].concat args

module.exports =
  addBoxEle: ->
    c = @cover = document.createElement 'div'
    c.id = 'boxsel-cover'
    cs = c.style
    cs.left   = @editorPageX  + 'px'
    cs.top    = @editorPageY  + 'px'
    cs.width  = @editorW      + 'px'
    cs.height = @editorH      + 'px'
    setTimeout (-> cs.cursor = 'crosshair'), 50
    b = @box = document.createElement 'div'
    b.id     = 'boxsel-box'
    document.body.appendChild c
    c.appendChild b
    c.onmousedown = (e) => @mouseEvent(e)
    c.onmousemove = (e) => @mouseEvent(e)
    c.onmouseup   = (e) => @mouseEvent(e)
  
  refreshCoverPos: ->
    cs = @cover.style
    cs.left   = @editorPageX  + 'px'
    cs.top    = @editorPageY  + 'px'
    cs.width  = @editorW      + 'px'
    cs.height = @editorH      + 'px'
      
  removeBoxEle: ->
    if @cover 
      document.body.removeChild @cover
      @cover.removeChild @box
      @cover = @box = null
      
  getBoxXY: -> 
    if not (s = @box?.style) then return [0,0,0,0]
    style2dim = (attr) -> +(s[attr].replace 'px', '')
    editX1 = style2dim 'left'; editY1 = style2dim 'top'
    editX2 = editX1 + style2dim 'width'
    editY2 = editY1 + style2dim 'height'
    @edit2textXY editX1, editY1, editX2, editY2
    
  getBoxRowCol: -> [@boxRow1, @boxCol1, @boxRow2, @boxCol2]

  setBoxVisible: (@boxVisible) ->
    @box?.style.visibility = 
      (if @boxVisible then 'visible' else 'hidden')

  setBoxByXY: (x1, y1, x2, y2, haveRowCol) ->
    if (dot = (x2 is 'dot')) then [x2, y2] = [x1, y1]
    x1 = Math.round(x1/@chrWid) * @chrWid
    y1 = Math.round(y1/@chrHgt) * @chrHgt
    x2 = Math.round(x2/@chrWid) * @chrWid
    y2 = Math.round(y2/@chrHgt) * @chrHgt
    [editX1, editY1, editX2, editY2] = @text2editXY x1, y1, x2, y2
    @initEditX1 ?= x1
    @initEditY1 ?= y1
    if editX1 > editX2 then [editX1, editX2] = [editX2, editX1]
    if editY1 > editY2 then [editY1, editY2] = [editY2, editY1]
    bs = @box.style
    bs.left = editX1 + 'px'
    bs.top  = editY1 + 'px'
    if dot or (editX2-editX1) > 0 or (editY2-editY1) > 0
      bs.width  = (editX2-editX1) + 'px'
      bs.height = (editY2-editY1) + 'px'
    else
      bs.width  = '0'
      bs.height = @chrHgt + 'px'
    if not haveRowCol
      botRow = @buffer.getLastRow()
      @boxRow1 = Math.max      0,  Math.round y1 / @chrHgt
      @boxCol1 = Math.max      0,  Math.round x1 / @chrWid
      @boxRow2 = Math.min botRow, (Math.round y2 / @chrHgt) - 1
      @boxCol2 =                   Math.round x2 / @chrWid
    @setBoxVisible yes

  setBoxByRowCol: (@boxRow1, @boxCol1, @boxRow2, @boxCol2) ->
    @setBoxByXY @boxCol1 * @chrWid,  @boxRow1    * @chrHgt, 
                @boxCol2 * @chrWid, (@boxRow2+1) * @chrHgt, yes
  
  refreshBoxPos: ->
    @setBoxByRowCol @boxRow1, @boxCol1, @boxRow2, @boxCol2
    
  createBoxWithAtomSelections: ->
    row1 = col1 = +Infinity
    row2 = col2 = -Infinity
    for sel in @editor.getSelections()
      range = sel.getBufferRange()
      row1 = Math.min row1, range.start.row,    range.end.row
      col1 = Math.min col1, range.start.column, range.end.column
      row2 = Math.max row2, range.start.row,    range.end.row
      col2 = Math.max col2, range.start.column, range.end.column
    @setBoxByRowCol row1, col1, row2, col2
    for selection in @editor.getSelections()
      selection.destroy()
    @editor.getLastCursor().setVisible no
    
  editBox: (cmd, text, addToUndo = yes) ->
    # log '@editBox', {cmd, text}
    if addToUndo
      oldBufferText = @editor.getText()
      oldRowCol = [row1, col1, row2, col2] = @getBoxRowCol()
    
    clipHgt = 0
    if cmd in ['paste', 'setText']  
      clipTxt = (if cmd is 'paste' then atom.clipboard.read() else text)        
      clipLines = clipTxt.split '\n'
      if clipLines[clipLines.length-1].length is 0
        clipLines = clipLines[0..-2]
      clipHgt = clipLines.length
      clipWidth = 0
      for clipLine in clipLines 
        clipWidth = Math.max clipWidth, clipLine.length
      for clipRow in [0...clipHgt]
        while clipLines[clipRow].length < clipWidth then clipLines[clipRow] += ' '
      blankClipLine = ''
      while blankClipLine.length < clipWidth then blankClipLine += ' '
      getClipLine = (clipRow) ->
        (if clipRow < clipHgt then clipLines[clipRow] else blankClipLine)
    
    if cmd not in ['copy', 'getText']
      @ensureScreenHgt Math.max row2, row1 + clipHgt
    
    dbg = 0
    screenRow = row1
    boxRow = 0; boxLine = ''
    if cmd is 'fill' then for i in [col1...col2] then boxLine += text
    boxHgt = row2 - row1 + 1
    copyText = ''; lastBufRow = null
    
    while boxRow <= boxHgt-1 or
          cmd in ['paste', 'setText'] and boxRow <= clipHgt-1
      bufRange = 
        @editor.bufferRangeForScreenRange [[screenRow,col1],[screenRow,col2]]
      bufRow = bufRange.start.row
      @ensureLineWid bufRow, col1
      bufRange = 
        @editor.bufferRangeForScreenRange [[screenRow,col1],[screenRow,col2]]
      screenRow++
      if ++dbg > 30 then log 'oops'; return
      if bufRow is lastBufRow then continue
      lastBufRow = bufRow
      
      if cmd in ['paste', 'setText']
        @editor.setTextInBufferRange bufRange, getClipLine boxRow
      else if boxRow <= boxHgt-1
        if cmd in ['copy', 'cut', 'getText'] 
          copyText += @editor.getTextInBufferRange(bufRange) + '\n'
        if cmd in ['cut', 'del', 'fill']
          @editor.setTextInBufferRange bufRange, boxLine
      boxRow++
    if cmd is 'copy' then atom.clipboard.write copyText
    
    newCol2 = switch cmd
      when 'paste', 'setText' then col1 + clipWidth
      when 'fill', 'copy', 'setText', 'getText' then col2
      else col1
    @setBoxByRowCol row1, col1, screenRow-1, newCol2
    
    if addToUndo then @addToUndo oldBufferText, oldRowCol
      
    copyText
    
  selectAll: ->
    allRange = @editor.screenRangeForBufferRange [[0,0],[9e9,9e9]]
    row2 = allRange.end.row
    col2 = 0
    for row in [0...@editor.getLineCount()]
      col2 = Math.max col2, @editor.lineTextForBufferRow(row).length
    @setBoxByRowCol 0, 0, row2, col2
    
  boxToAtomSelections: ->
    oldSelection = @editor.getLastSelection()
    [row1, col1, row2, col2] = @getBoxRowCol()
    for row in [row1..row2]
      @editor.addSelectionForBufferRange [[row, col1], [row, col2]]
    oldSelection.destroy()
          
