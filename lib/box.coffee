
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
    b = @box = document.createElement 'div'
    b.id     = 'boxsel-box'
    document.body.appendChild c
    c.appendChild b
    setTimeout (-> c.classList.add 'boxsel-cursor'), 200
    
    c.onmousedown = (e) => @mouseEvent(e)
    c.onmousemove = (e) => @mouseEvent(e)
    c.onmouseup   = (e) => @mouseEvent(e)
    c.onwheel     = (e) => @mouseEvent(e)
  
  atomSelectionsToBox: ->
    row1 = col1 = +Infinity
    row2 = col2 = -Infinity
    for sel in @editor.getSelections()
      range = sel.getBufferRange()
      row1 = Math.min row1, range.start.row,    range.end.row
      col1 = Math.min col1, range.start.column, range.end.column
      row2 = Math.max row2, range.start.row,    range.end.row
      col2 = Math.max col2, range.start.column, range.end.column
    [@anchorEditX1, @anchorEditY1] = 
      @text2editXY col1 * @chrWid, row1 * @chrHgt, 0, 0
    @setBoxByRowCol row1, col1, row2, col2
    scrollTop = @editorView.getScrollTop()
    lastCursorPos = @editor.getCursorScreenPosition()
    @editor.setSelectedScreenRange \
      [[lastCursorPos.row, lastCursorPos.column],
       [lastCursorPos.row, lastCursorPos.column]]
    @editor.getLastCursor().setVisible no
    @editorView.setScrollTop scrollTop

  boxToAtomSelections: ->
    scrollTop = @editorView.getScrollTop()
    [row1, col1, row2, col2] = @getBoxRowCol()
    @editor.setSelectedScreenRange [[0, 0], [0, 0]]
    dummySel = @editor.getSelections()[0]
    overlaps00 = no
    for row in [row1..row2]
      overlaps00 or= (row1 is col1 is 0)
      @editor.addSelectionForBufferRange [[row, col1], [row, col2]]
    if not overlaps00 then dummySel.destroy()
    @editorView.setScrollTop scrollTop
    
  refreshCoverPos: ->
    cs = @cover.style
    cs.left   = @editorPageX  + 'px'
    cs.top    = @editorPageY  + 'px'
    cs.width  = @editorW      + 'px'
    cs.height = @editorH      + 'px'
      
  removeBoxEle: ->
    if @cover 
      if @textEditor then @closeTextEditor()
      document.body.removeChild @cover
      @cover.removeChild @box
      @cover = @box = null
      
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
    # log 'setBoxByXY @text2editXY', {x1, y1, x2, y2, editX1, editY1, editX2, editY2}
    if editX1 > editX2 then [editX1, editX2] = [editX2, editX1]
    if editY1 > editY2 then [editY1, editY2] = [editY2, editY1]
    bs = @box.style 
    bs.left = editX1 + 'px'
    bs.top  = editY1 + 'px'
    if editX2-editX1 > 0 or editY2-editY1 > 0
      bs.width  = (editX2-editX1) + 'px'
      bs.height = (editY2-editY1) + 'px'
    else
      bs.width  = '0'
      bs.height = @chrHgt + 'px'
    # log 'setBoxByXY1', {@boxRow1, @boxCol1, @boxRow2, @boxCol2}
    if not haveRowCol
      bot = @editor.screenPositionForBufferPosition [9e9, 9e9]
      @boxRow1 = Math.max       0,  Math.round y1 / @chrHgt
      @boxCol1 = Math.max       0,  Math.round x1 / @chrWid
      @boxRow2 = Math.min bot.row, (Math.round y2 / @chrHgt) - (if dot then 0 else 1)
      @boxCol2 =                    Math.round x2 / @chrWid
    # log 'setBoxByXY2', {@boxRow1, @boxCol1, @boxRow2, @boxCol2}
    @boxBufRange = @editor.bufferRangeForScreenRange \
                [[@boxRow1, @boxCol1], [@boxRow2, @boxCol2]]
    # log 'setBoxByXY3', {@boxBufRange}
    @setBoxVisible yes

  setBoxByRowCol: (@boxRow1, @boxCol1, @boxRow2, @boxCol2) ->
    @setBoxByXY @boxCol1 * @chrWid,  @boxRow1    * @chrHgt, 
                @boxCol2 * @chrWid, (@boxRow2+1) * @chrHgt, yes
  
  refreshBoxPos: ->
    # log 'refreshBoxPos', {@boxBufRange}
    if @boxBufRange
      boxScrnRange = @editor.screenRangeForBufferRange @boxBufRange
      @boxRow1 = boxScrnRange.start.row
      @boxRow2 = boxScrnRange.end.row
    # log 'refreshBoxPos', {@boxRow1, @boxCol1, @boxRow2, @boxCol2}
    
    @setBoxByRowCol @boxRow1, @boxCol1, @boxRow2, @boxCol2
    
  getBoxXY: -> 
    if not (s = @box?.style) then return [0,0,0,0]
    style2dim = (attr) -> +(s[attr].replace 'px', '')
    editX1 = style2dim 'left'; editY1 = style2dim 'top'
    editX2 = editX1 + style2dim 'width'
    editY2 = editY1 + style2dim 'height'
    @edit2textXY editX1, editY1, editX2, editY2
    
  getBoxRowCol: -> 
    [@boxRow1, @boxCol1, @boxRow2, @boxCol2]

  selectAll: ->
    allRange = @editor.screenRangeForBufferRange [[0,0],[9e9,9e9]]
    row2 = allRange.end.row
    col2 = 0
    for row in [0...@editor.getLineCount()]
      col2 = Math.max col2, @editor.lineTextForBufferRow(row).length
    @setBoxByRowCol 0, 0, row2, col2
    
