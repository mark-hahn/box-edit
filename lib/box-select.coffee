###
  lib/box-select.coffee
###

SubAtom = require 'sub-atom'

log = (args...) -> 
  console.log.apply console, ['box-select:'].concat args

class BoxSelect
  config:
    selectionColor:
      type: 'string'
      default: '#888'
      
  activate: ->
    log 'activate'
    @wspace = atom.workspace
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-select:toggle': => @toggle()
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-select:paste': => @paste()
  
  toggle: ->
    log 'toggle'
    if @selectMode or @selectedMode or
       not (@editor = @wspace.getActiveTextEditor()) 
      @clear()
      return  
    
    @pane       = @wspace.getActivePane()
    @editorView = atom.views.getView @editor
    @buffer     = @editor.getBuffer()
    @chrWid     = @editor.getDefaultCharWidth()
    @chrHgt     = @editor.getLineHeightInPixels()
    {left:  @editorPosX, top:    @editorPosY, \
     width: @editorPosW, height: @editorPosH} =
                  @editorView.getBoundingClientRect()
    @pane.onDidChangeActiveItem => @clear()
    @selectMode = yes
    @addBoxEle()
  
  hideAtomCursors: ->
    for cursor in @editor.getCursors()
      cursor.setVisible no
      # cursor.clearSelection()

  showAtomCursors: ->
    for cursor in @editor.getCursors()
      cursor.setVisible yes

  addBoxEle: ->
    @hideAtomCursors()
    c = @cover = document.createElement 'div'
    c.id     = 'boxsel-cover'
    s        = c.style
    s.cursor = 'crosshair'
    b = @box = document.createElement 'div'
    b.id     = 'boxsel-box'
    document.body.appendChild c
    c.appendChild b
    c.onmousedown  = (e) => @mouseEvent(e)
    c.onmousemove  = (e) => @mouseEvent(e)
    c.onmouseup    = (e) => @mouseEvent(e)
    c.onkeypress   = (e) => @keyEvent e
    document.body.onkeydown = (e) => @keyEvent e
  
  removeBoxEle: ->
    if @cover 
      document.body.removeChild @cover
      @cover.removeChild @box
      @cover = @box = null
    @showAtomCursors()
      
  getScreenRowCol: (x, y) ->
    row     = Math.round y / @editor.getLineHeightInPixels()
    lastRow = @buffer.getLastRow()
    left    = Infinity if row > lastRow
    row     = Math.max 0, Math.min row, lastRow
    col     = Math.round x / @chrWid
    {row: row, col: col}
    
  copyText: ->
    log 'copyText'
    get = (style) => +@box.style[style].replace('px', '')
    x = get 'left';  y = get 'top'
    w = get 'width'; h = get 'height'
    {row: row1, col: col1} = @getScreenRowCol x,   y
    {row: row2, col: col2} = @getScreenRowCol x+w, y+h
    log {row1, col1, row2, col2}
    
  delText : ->
    
  mouseInEditor: (e) ->
    @editorPosX <= e.pageX < @editorPosX + @editorPosW and
    @editorPosY <= e.pageY < @editorPosY + @editorPosH

  mouseEvent: (e) ->
    if not @selectMode then return
    switch e.type
      
      when 'mousedown'
        if not @mouseInEditor e
          @clear()
          return
        @cover.style.cursor = 'crosshair'
        @selectedMode = no
        @dragging = yes
        @initPosX = e.pageX - @editorPosX - @chrWid/2
        @initPosY = e.pageY - @editorPosY - @chrHgt/2
        
      when 'mousemove' 
        if not @dragging or not @mouseInEditor(e) then return
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
        @cover.style.cursor = 'auto'
        @dragging = no
        @selectedMode = yes
        
  keyEvent: (e) ->
    if not @selectMode then return
    code = e.which + (if e.ctrlKey then 1000 else 0)
    switch code
      when 1088      # ctrl-X
        @copyText()
        @delText()
      when 1067      # ctrl-C
        @copyText()
      when 8, 46     # backspace, delete
        @delText()
      # when 27        # escape
      #   log 'esc'
      when 91        # [  (search on chromebook)
        dontClear = yes
      else
        dontClear = (code > 127)
        log 'unknown key pressed:', code
    
    if not dontClear
      log 'key clear'
      @clear()
      e.preventDefault()
      e.stopPropagation()

  clear: -> 
    @cover?.style.cursor = 'auto'
    @dragging = @selectMode = @selectedMode = no
    @removeBoxEle()
    log 'cleared'

  paste: ->  
    log 'paste' 
  
  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect

###
  # Stolen from https://github.com/bigfive/atom-sublime-select

  {row: @row, column: @col} = @editor.getCursorScreenPosition()
  [row1, col1, row2, col2] = [@row, @col, row, col]
  if row1 > row2 then [row2, row1] = [row1, row2]   
  if col1 > col2 then [col2, col1] = [col1, col2] 
  s = @box.style
  s.top    =  row1    * @chrHgt + 'px'
  s.right  =  col2    * @chrWid + 'px'
  s.bottom = (row2+1) * @chrHgt + 'px'
  s.left   =  col1    * @chrWid + 'px'
###    
