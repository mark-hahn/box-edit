
log = (args...) -> 
  console.log.apply console, ['box-select, page:'].concat args


module.exports =
  getElement:  (sel) -> @editorView.shadowRoot.querySelector sel
  getElements: (sel) -> @editorView.shadowRoot.querySelectorAll sel
  
  getPageDims: (editRect, chrWid, chrHgt) ->
    @chrWid = (chrWid ? @editor.getDefaultCharWidth()  )
    @chrHgt = (chrHgt ? @editor.getLineHeightInPixels())
    {left: @editorPageX, top: @editorPageY, width: @editorWtotal, height: @editorHtotal} =
                   (editRect ? @editorView.getBoundingClientRect())
    @hBar = @getElement '.horizontal-scrollbar'
    @vBar = @getElement '.vertical-scrollbar'
    @editorW = @editorWtotal - 
      (if (@vBarVis = (@vBar.display isnt 'none')) then @vBar.offsetWidth  else 0)
    @editorH = @editorHtotal - 
      (if (@hBarVis = (@hBar.display isnt 'none')) then @hBar.offsetHeight else 0)

  checkPageDims: ->
    if not @editorView then return
    {left, top, width, height} = (editRect = @editorView.getBoundingClientRect())
    if  @editorPageX  isnt left   or
        @editorPageY  isnt top    or
        @editorWtotal isnt width  or
        @editorHtotal isnt height or
        @chrWid       isnt (chrWid = @editor.getDefaultCharWidth()  ) or
        @chrHgt       isnt (chrHgt = @editor.getLineHeightInPixels()) or
        @vBarVis      isnt (@vBar.display isnt 'none') or
        @hbarVis      isnt (@hBar.display isnt 'none') or
        @scrollRefEle.offsetTop isnt @scrollRefEleOfs
      @getPageDims editRect, chrWid, chrHgt
      @getScrollOfs yes
      @refreshCoverPos()
      @refreshBoxPos()
      @refreshTxtEditorPos()
      setTimeout (=> @checkPageDims()), 200
      return
    setTimeout (=> @checkPageDims()), 200
  
  getScrollOfs: (update) ->
    if update or not @scrollOfs
      for @scrollRefEle in @getElements '.line'
        row = +@scrollRefEle.getAttribute 'data-screen-row'
        {left: linePageX, top: linePageY} = @scrollRefEle.getBoundingClientRect()
        if 0 <= (linePageY - @editorPageY) < 2 * @chrHgt then break
      @scrollRefEleOfs = @scrollRefEle.offsetTop
      @scrollOfs = [@editorPageX - linePageX, @editorPageY - (linePageY - row * @chrHgt)]
    @scrollOfs  
    
  edit2textXY: (x1, y1, x2, y2) ->
    [scrollOfsX, scrollOfsY] = @getScrollOfs()
    [x1 + scrollOfsX, y1 + scrollOfsY
     x2 + scrollOfsX, y2 + scrollOfsY]
       
  text2editXY: (x1, y1, x2, y2) ->
    [scrollOfsX, scrollOfsY] = @getScrollOfs()
    [x1 - scrollOfsX, y1 - scrollOfsY
     x2 - scrollOfsX, y2 - scrollOfsY]
  
  ensureScreenHgt: (scrnRows) ->
    loop
      endScrnRange = @editor.screenRangeForBufferRange [[9e9,9e9],[9e9,9e9]]
      if endScrnRange.end.row >= scrnRows - 1 then return
      @editor.setTextInBufferRange [[9e9,9e9],[9e9,9e9]], '\n'

  ensureLineWid: (bufRow, length) ->
    lineLen = @editor.lineTextForBufferRow(bufRow).length
    if lineLen < length
      pad = ' '; for i in [1...length-lineLen] then pad += ' '
      @editor.setTextInBufferRange [[bufRow,lineLen],[bufRow,length]], pad
  
  chkScrollBorders: (editX, editY) ->
    now = Date.now()
    if @chkScrlBrdrTimeout 
      clearTimeout @chkScrlBrdrTimeout
      @chkScrlBrdrTimeout = null
    else
      @chkScrollBordersStart = now
    if (not (6 * @chrWid < editX < @editorPageW - 2 * @chrWid) or
        not (2 * @chrHgt < editY < @editorPageH - 2 * @chrHgt)) and @mouseIsDown
      [ofsX, ofsY] = @getScrollOfs()
      row = (Math.round (editY + ofsY) / @chrHgt) - 1
      col =  Math.round (editX + ofsX) / @chrWid
      @editor.scrollToScreenPosition [row, col]
      @getPageDims()
      @refreshBoxPos()
      if now < @chkScrollBordersStart + 2e3
        @chkScrlBrdrTimeout = 
          setTimeout (=> @chkScrollBorders editX, editY), 100
    
