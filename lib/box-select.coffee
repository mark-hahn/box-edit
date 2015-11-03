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
                                'box-select:start': => @start()
    @subs.add atom.commands.add 'atom-text-editor', 
                                'box-select:paste': => @paste()
                                     
  start: ->
    log 'start'
    @editor = @wspace.getActiveTextEditor()
    if not @editor then return  
    @editorView = atom.views.getView @editor
    @editorComp = @editorView.component
    @buffer  = @editor.getBuffer()
    @defChrW = @editor.getDefaultCharWidth()

    @lineInfo = []
    for rowIdx in [0...@editor.getLineCount()]
      line = @editor.lineTextForBufferRow rowIdx
      @lineInfo.push {ws: line.match(/\s*$/)[0], len: line.length}

    {row: @row, column: @col} = @editor.getCursorScreenPosition()
    @selectMode = yes
           
    @editorView.onmousemove = (e) => @mouseEvent(e)
    @editorView.onmousedown = (e) => @mouseEvent(e)
    # @subs.add @editorView.onblur      = (e) => @mouseEvent(e)
       
  mouseEvent: (e) ->
    if not @selectMode then return
    {row, col} = @screenPositionForMouseEvent e

    setBox = =>
      [row1, col1, row2, col2] = [@row, @col, row, col]
      if row1 > row2 then [row2, row1] = [row1, row2]   
      if col1 > col2 then [col2, col1] = [col1, col2] 
      for r in [row1..row2]
        lineLen = @lineInfo[r].len
        if (padLen = col2 - lineLen) > 0
          @lineInfo[r].padLen = padLen
          pad = ' '; while pad.length < padLen then pad += ' '
          @editor.setTextInBufferRange [[r, lineLen], [r, lineLen+padLen]], pad
      log {row1, col1, row2, col2}
      range = [[row2, col2], [row1, col1]]
      if not @marker
         @marker = @editor.markBufferRange range, persistent:no
         @decor  = @editor.decorateMarker @marker, 
                               {type: 'highlight', class: 'box-sel-marker-class'}
      else @marker.setBufferRange range

    switch e.type
      when 'mousemove' then setBox()
      when 'mousedown' then setTimeout (=> @clear()), 1000

  clear: ->
    @selectMode = no       
    if @marker then @marker.destroy(); @marker = null

  # Stolen from https://github.com/bigfive/atom-sublime-select
  screenPositionForMouseEvent: (e) ->
    {top, left} = @editorComp.pixelPositionForMouseEvent e
    row     = Math.floor top / @editor.getLineHeightInPixels()
    lastRow = @buffer.getLastRow()
    left    = Infinity if row > lastRow
    row     = Math.max 0, Math.min row, lastRow
    col     = Math.round left / @defChrW
    {row: row, col: col}
    
  paste: ->  
    log 'paste'
    
  clear: -> 
    if @isDragging then @drop()
    @clearTimeouts()
    @active = @selected = @isDragging = no
    @marker?.destroy()
    
  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect
