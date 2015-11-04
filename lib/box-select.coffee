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
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-select:paste': => @paste()
  
  toggle: ->
    if @selectMode then @clear 'restorePane';      return  
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
    @pane.onDidChangeActiveItem => @clear()
    @selectMode = yes
    @addBoxEle()
  
  hideAtomCursors: (destroy = no) ->
    for sel in @editor.getSelections()
      sel.clear()
    for cursor in @editor.getCursors()
      if destroy then cursor.destroy()
      else cursor.setVisible no
      
  showAtomCursors: ->
    for cursor in @editor.getCursors()
      cursor.setVisible yes
      
  addBoxEle: ->
    @hideAtomCursors()
    c = @cover = document.createElement 'div'
    c.id     = 'boxsel-cover'
    s        = c.style
    setTimeout (-> s.cursor = 'crosshair'), 50
    b = @box = document.createElement 'div'
    b.id     = 'boxsel-box'
    document.body.appendChild c
    c.appendChild b
    c.onmousedown = (e) => @mouseEvent(e)
    c.onmousemove = (e) => @mouseEvent(e)
    c.onmouseup   = (e) => @mouseEvent(e)
    document.body.onkeydown = (e) => @keyEvent e
  
  removeBoxEle: ->
    if @cover 
      @setBoxVisible no
      document.body.removeChild @cover
      @cover.removeChild @box
      @cover = @box = null
    @showAtomCursors()
      
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
    @pageOfsX = @initMouseEvent.pageX - x1
    @pageOfsY = @initMouseEvent.pageY - y1
    if x1 > x2 then [x2, x1] = [x1, x2]
    if y1 > y2 then [y2, y1] = [y1, y2]
    [row1, col1] = @getScreenRowCol x1, y1
    [row2, col2] = @getScreenRowCol x2, y2
    row2 -= 1
    [row1, col1, row2, col2]
    
  copyDelText: (copy, del)->
    if not @boxVisible then return
    @clear()
    if del then @hideAtomCursors 'destroy'
    copyText = []
    [row1, col1, row2, col2] = @getBoxRowCol()
    lastBufRow = null
    for row in [row1..row2]
      bufRange = @editor.bufferRangeForScreenRange [[row, col1], [row, col2]]
      bufRow  = bufRange.start.row
      bufCol1 = bufRange.start.column
      if bufRow is lastBufRow then continue
      lastBufRow = bufRow
      if copy
        copyText.push @editor.getTextInBufferRange bufRange
      if del 
        @editor.setTextInBufferRange bufRange, ''
        @editor.addCursorAtBufferPosition [bufRow, bufCol1]
    if copy then atom.clipboard.write copyText.join '\n'
    if del  then @editor.getCursors()[0].destroy()
    @setBoxVisible no
    @pane.activate()
    
  mouseInEditor: (e) ->
    @editorPosX <= e.pageX < @editorPosX + @editorPosW and
    @editorPosY <= e.pageY < @editorPosY + @editorPosH

  mouseEvent: (e) ->
    if not @selectMode then return
    switch e.type
      
      when 'mousedown'
        if not @mouseInEditor e
          @clear 'restorePane'
          return
        @initMouseEvent = @lastMouseEvent = e
        @cover.style.cursor = 'crosshair'
        @dragging = yes
        @initPosX = e.pageX - @editorPosX
        @initPosY = e.pageY - @editorPosY
        
      when 'mousemove' 
        if not @dragging or not @mouseInEditor(e) then return
        @setBoxVisible yes
        @lastMouseEvent = e
        @hideAtomCursors()
        @cover.style.cursor = 'crosshair'
        if not @box then @addBoxEle()

        cursPosX = e.pageX - @editorPosX
        cursPosY = e.pageY - @editorPosY
        s = @box.style
        if cursPosX >= @initPosX
          s.left   = (@initPosX + @editorPosX) + 'px'
          s.width  = (cursPosX  - @initPosX  ) + 'px'
        else
          s.left   = (cursPosX  + @editorPosX) + 'px'
          s.width  = (@initPosX - cursPosX   ) + 'px'
          
        if cursPosY >= @initPosY
          s.top    = (@initPosY + @editorPosY) + 'px'
          s.height = (cursPosY  - @initPosY  ) + 'px'
        else
          s.top    = (cursPosY  + @editorPosY) + 'px'
          s.height = (@initPosY - cursPosY   ) + 'px'
      
      when 'mouseup'
        @dragging = no
        [row1, col1, row2, col2] = @getBoxRowCol()
        rows = row2-row1 + 1
        cols = col2 - col1
        s = @box.style
        if rows is 0 or cols is 0 then @setBoxVisible no; return
        s.left   = (col1 * @chrWid + @pageOfsX) + 'px'
        s.top    = (row1 * @chrHgt + @pageOfsY) + 'px'
        s.width  = ((col2-col1)   * @chrWid)    + 'px'
        s.height = ((row2-row1+1) * @chrHgt)    + 'px'
        
  keyEvent: (e) ->
    if not @selectMode then return
    clear = no
    code = e.which + (if e.ctrlKey then 1000 else 0)
    switch code
      when 1088 then @copyDelText yes, yes # ctrl-X
      when 1067 then @copyDelText yes, no  # ctrl-C
      when 8,46 then @copyDelText no, yes  # backspace, delete
      when 27   then @clear 'restorePane'  # escape
      else
        # needs work
        if code isnt 91 and # [  (search key on chromebook)
           code < 128 then @clear()
        # log 'unknown key pressed:', code

  setBoxVisible: (@boxVisible) ->
    @box?.style.visibility = 
      (if @boxVisible then 'visible' else 'hidden')
    
  clear: (restorePane = no) -> 
    @cover?.style.cursor = 'auto'
    @dragging = @selectMode = no
    @removeBoxEle()
    # if restorePane then @pane.activate()
    @pane.activate()

  paste: ->  
    log 'paste' 
  
  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect

