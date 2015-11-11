
log = (args...) -> 
  console.log.apply console, ['box-edit, page:'].concat args

module.exports =
  
  pageInit: ->
    refresh = =>
      if @active
        # log 'refresh'
        @refreshBoxPos()
        @refreshTxtEditorPos()
    @subs.add @editorView.onDidChangeScrollTop  refresh
    @subs.add @editorView.onDidChangeScrollLeft refresh
    @subs.add  @editor.onDidAddGutter           refresh
    @subs.add  @editor.onDidRemoveGutter        refresh
    
  getElement:  (sel) -> @editorView.shadowRoot.querySelector sel
  getElements: (sel) -> @editorView.shadowRoot.querySelectorAll sel
  
  getPageDims: (editRect, chrWid, chrHgt) ->
    @chrWid = (chrWid ? @editor.getDefaultCharWidth()  )
    @chrHgt = (chrHgt ? @editor.getLineHeightInPixels())
    {left:  @editorPageX,  top:    @editorPageY, \
     width: @editorWtotal, height: @editorHtotal} =
                   (editRect ? @editorView.getBoundingClientRect())
    @editorW    = @editorWtotal - (@scrollBarW = @editorView.getVerticalScrollbarWidth())
    @editorH    = @editorHtotal - (@scrollBarH = @editorView.getHorizontalScrollbarHeight())
    for @scrollRefEle in @getElements '.line'
      row = +@scrollRefEle.getAttribute 'data-screen-row'
      {left: linePageX, top: linePageY} = @scrollRefEle.getBoundingClientRect()
      if 0 <= (linePageY - @editorPageY) < 2 * @chrHgt then break
    @textOfsX   = linePageX - @editorPageX
    @textOfsY   = @editorPageY - (linePageY - row * @chrHgt)

  startCheckingPageDims: ->
    if not @editorView then return
    {left, top, width, height} = (editRect = @editorView.getBoundingClientRect())
    if  @editorPageX  isnt left                                       or
        @editorPageY  isnt top                                        or
        @editorWtotal isnt width                                      or
        @editorHtotal isnt height                                     or
        @chrWid       isnt (chrWid = @editor.getDefaultCharWidth()  ) or
        @chrHgt       isnt (chrHgt = @editor.getLineHeightInPixels()) or
        @scrollBarW   isnt @editorView.getVerticalScrollbarWidth()    or
        @scrollBarH   isnt @editorView.getHorizontalScrollbarHeight()
      @getPageDims editRect, chrWid, chrHgt
      @refreshCoverPos()
    setTimeout (=> @startCheckingPageDims()), 500
  
  getScrollOfs: ->
    [@editorView.getScrollLeft()-@textOfsX, @editorView.getScrollTop()]
    
  edit2textXY: (x1, y1, x2, y2) ->
    [scrollOfsX, scrollOfsY] = @getScrollOfs()
    # log 'edit2textXY ScrollOfs', {scrollOfsX, scrollOfsY}
    [x1 + scrollOfsX, y1 + scrollOfsY
     x2 + scrollOfsX, y2 + scrollOfsY]
       
  text2editXY: (x1, y1, x2, y2) ->
    [scrollOfsX, scrollOfsY] = @getScrollOfs()
    # log 'text2editXY getScrollOfs', {scrollOfsX, scrollOfsY}
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
  
