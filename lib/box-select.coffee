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
    @chrWid = @editor.getDefaultCharWidth()
    @chrHgt = @editor.getLineHeightInPixels()
    {row: @row, column: @col} = @editor.getCursorScreenPosition()
    @selectMode = yes
    
    # @lineInfo = []
    # for rowIdx in [0...@editor.getLineCount()]
    #   line = @editor.lineTextForBufferRow rowIdx
    #   wSpace = line.match(/\s*$/)[0]
    #   @lineInfo.push {origLen: line.length, origWs: wSpace, padWs: ''}

    @editorView.onmousemove = (e) => @mouseEvent(e)
    @editorView.onmousedown = (e) => @mouseEvent(e)
    # @editorView.onblur      = (e) => @mouseEvent(e)

  addBoxEle: ->
    b = @box = document.createElement 'div'
    b.id = 'boxsel-box'
    b.style.left = b.style.right = '-100000px'
    @editorView.appendChild b
  
  removeBoxEle: ->
    if @box 
      @editorView.removeChild @box
      @box = null

  setBox: (e) ->
    {row, col} = @screenPositionForMouseEvent e
    [row1, col1, row2, col2] = [@row, @col, row, col]
    if row1 > row2 then [row2, row1] = [row1, row2]   
    if col1 > col2 then [col2, col1] = [col1, col2] 
    if not @box then @addBoxEle()
    s = @box.style
    s.top    =  row1    * @chrHgt + 'px'
    s.right  =  col2    * @chrWid + 'px'
    s.bottom = (row2+1) * @chrHgt + 'px'
    s.left   =  col1    * @chrWid + 'px'
    
    # for r in [row1..row2]
    #   info = @lineInfo[r]
    #   lineLen = info.origLen + info.padWs.length
    #   if (padLen = col2 - lineLen) > 0
    #     pad = ' '; while pad.length < padLen then pad += ' '
    #     info.padWs += pad
    #     @editor.setTextInBufferRange [[r, lineLen], [r, lineLen+padLen]], pad
    # log {row1, col1, row2, col2}
    
    # range = [[row1, col1], [row2, col2]]
    # if not @marker
    #   @marker = @editor.markBufferRange range, persistent:no
    #   @decor  = @editor.decorateMarker @marker, 
    #                          {type: 'highlight', class: 'box-sel-marker-class'}
    #   log {@marker, @decor}
    # else @marker.setBufferRange range

  mouseEvent: (e) ->
    if not @selectMode then return
    switch e.type
      when 'mousemove' then @setBox e
      when 'mousedown' then @selectMode = no # setTimeout (=> @clear()), 1000

  # Stolen from https://github.com/bigfive/atom-sublime-select
  screenPositionForMouseEvent: (e) ->
    {top, left} = @editorComp.pixelPositionForMouseEvent e
    row     = Math.floor top / @editor.getLineHeightInPixels()
    lastRow = @buffer.getLastRow()
    left    = Infinity if row > lastRow
    row     = Math.max 0, Math.min row, lastRow
    col     = Math.round left / @chrWid
    {row: row, col: col}

  paste: ->  
    log 'paste'

  clear: -> 
    @removeBoxEle()
    @selectMode = no
    @marker?.destroy()
    @marker = null

  deactivate: ->
    @clear()
    @subs.dispose()

module.exports = new BoxSelect
