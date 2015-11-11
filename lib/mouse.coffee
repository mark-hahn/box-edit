
log = (args...) -> 
  console.log.apply console, ['box-edit, mous:'].concat args

module.exports =
  mouseInit: ->
    @anchorEditX1 = @anchorEditY1 = null
    @mouseIsDown = no
    
  mouseEvent: (e) ->
    if e.target is @textEditor then return
    if not @active or not @editor or @editor.isDestroyed()
      @clear()
      return
    switch e.type
      
      when 'mousedown'
        @mouseIsDown = yes
        if not e.shiftKey
          @anchorEditX1 = e.pageX - @editorPageX
          @anchorEditY1 = e.pageY - @editorPageY
          [initX1, initY1] = @edit2textXY @anchorEditX1, @anchorEditY1, 0, 0
          @setBoxByXY initX1, initY1, 'dot'
        else
          editX2 = e.pageX - @editorPageX
          editY2 = e.pageY - @editorPageY
          @setBoxByXY @edit2textXY(@anchorEditX1, @anchorEditY1, editX2, editY2)...
      
      when 'mousemove' 
        if not @mouseIsDown then return
        @setBoxByMouse e
            
      when 'mouseup'
        if not @mouseIsDown then return
        @mouseIsDown = no
        # @setBoxByMouse e

      when 'wheel'
        @editorView.setScrollTop  @editorView.getScrollTop()  + e.deltaY
        @editorView.setScrollLeft @editorView.getScrollLeft() + e.deltaX
          
  setBoxByMouse: (e) ->
    editX2 = e.pageX - @editorPageX
    editY2 = e.pageY - @editorPageY
    @setBoxByXY @edit2textXY(@anchorEditX1, @anchorEditY1, editX2, editY2)...
      
          
          