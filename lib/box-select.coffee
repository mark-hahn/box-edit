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
    if @selectMode or @selectedMode
      @clear()
      return
    @editor = @wspace.getActiveTextEditor()
    if not @editor then return  
    @editorView = atom.views.getView @editor
    @editorComp = @editorView.component
    @buffer     = @editor.getBuffer()
    @chrWid     = @editor.getDefaultCharWidth()
    @chrHgt     = @editor.getLineHeightInPixels()

    for cursor in @editor.getCursors()
      cursor.setVisible no
      cursor.clearSelection()
    
    @selectMode = yes
    {left:  @editorPosX, top:    @editorPosY, \
     width: @editorPosW, height: @editorPosH} =
                  @editorView.getBoundingClientRect()
    @addBoxEle()
    
  addBoxEle: ->
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
    # c.onblur      = (e) => @mouseEvent(e)
    document.body.onkeydown = (e) => @keydown e
  
  removeBoxEle: ->
    if @cover 
      document.body.removeChild @cover
      @cover.removeChild @box
      @cover = @box = null
      
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
        if not @mouseInEditor(e) 
          @cover.style.cursor = 'auto'
          return
        if not @dragging then return
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
        
  paste: ->  
    log 'paste' 
  
  keydown: (e)->
    if not @selectedMode then return
    code = e.which + (if e.ctrlKey  then 1000 else 0) +
                     (if e.altKey   then 2000 else 0) +
                     (if e.shiftKey then 4000 else 0)
    switch code
      when 1088      # ctrl-X
        log 'ctrl-X'
        @copyText()
        @delText()
        @clear()
      when 1067      # ctrl-C
        log 'ctrl-C'
        @copyText()
        @clear()
      when 8, 46     # backspace, delete
        log 'backspace or delete'
      when 27        # escape
        log 'escape'
        @clear()
      when 91        # [  (search on chromebook)
        log 'search'
        keyNotUsed = yes
      else 
        if 32 <= code < 255 then @clear()
        keyNotUsed = yes
        log 'unknown key pressed:', code
        
    e.preventDefault()
    e.stopPropagation()

  clear: -> 
    @cover?.style.cursor = 'auto'
    for cursor in @editor.getCursors()
      cursor.setVisible yes
    @dragging = @selectMode = @selectedMode = no
    @removeBoxEle()

  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect

###
  # Stolen from https://github.com/bigfive/atom-sublime-select
  screenPositionForMouseEvent: (e) ->
    {top, left} = @editorComp.pixelPositionForMouseEvent e
    row     = Math.floor top / @editor.getLineHeightInPixels()
    lastRow = @buffer.getLastRow()
    left    = Infinity if row > lastRow
    row     = Math.max 0, Math.min row, lastRow
    col     = Math.round left / @chrWid
    {row: row, col: col}

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
