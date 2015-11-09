
log = (args...) -> 
  console.log.apply console, ['box-edit, page:'].concat args


module.exports =
  getElement:  (sel) -> @editorView.shadowRoot.querySelector sel
  getElements: (sel) -> @editorView.shadowRoot.querySelectorAll sel
  
  getPageDims: (editRect, chrWid, chrHgt) ->
    @chrWid = (chrWid ? @editor.getDefaultCharWidth()  )
    @chrHgt = (chrHgt ? @editor.getLineHeightInPixels())
    {left: @editorPageX, top: @editorPageY, width: @editorWtotal, height: @editorHtotal} =
                   (editRect ? @editorView.getBoundingClientRect())
    @editorW    = @editorWtotal - (@scrollBarW = @editorView.getVerticalScrollbarWidth())
    @editorH    = @editorHtotal - (@scrollBarH = @editorView.getHorizontalScrollbarHeight())
    @textOfsX   = @editorW - @editorView.getWidth()
    @textOfsY   = @editorH - @editorView.getHeight()
    @scrollTop  = @editorView.getScrollTop()
    @scrollLeft = @editorView.getScrollLeft()

  checkPageDims: ->
    if not @editorView then return
    {left, top, width, height} = (editRect = @editorView.getBoundingClientRect())
    if  @editorPageX  isnt left                                       or
        @editorPageY  isnt top                                        or
        @editorWtotal isnt width                                      or
        @editorHtotal isnt height                                     or
        @chrWid       isnt (chrWid = @editor.getDefaultCharWidth()  ) or
        @chrHgt       isnt (chrHgt = @editor.getLineHeightInPixels()) or
        @scrollBarW   isnt @editorView.getVerticalScrollbarWidth()    or
        @scrollBarH   isnt @editorView.getHorizontalScrollbarHeight() or
        @scrollTop    isnt @editorView.getScrollTop()                 or
        @scrollLeft   isnt @editorView.getScrollLeft()
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
  
