
log = (args...) -> 
  console.log.apply console, ['box-select, mous:'].concat args


module.exports =
    mouseEvent: (e) ->
      if e.target is @textEditor then return
      if not @active or not @editor or @editor.isDestroyed()
        @clear()
        return
      switch e.type
        when 'mousedown'
          @mouseIsDown = yes
          if @initEditX1? and e.shiftKey
            editX2 = e.pageX - @editorPageX
            editY2 = e.pageY - @editorPageY
            @setBoxByXY \
              @edit2textXY @initEditX1, @initEditY1, editX2, editY2
          else
            @initEditX1 = e.pageX - @editorPageX
            @initEditY1 = e.pageY - @editorPageY
            [initX1, initY1] = 
                @edit2textXY @initEditX1, @initEditY1, 0, 0
            @setBoxByXY initX1, initY1, 'dot', null
        
        when 'mousemove' 
          if not @mouseIsDown then return
          editX2 = e.pageX - @editorPageX
          editY2 = e.pageY - @editorPageY
          [x1, y1, x2, y2] = @edit2textXY @initEditX1, @initEditY1, editX2, editY2
          @setBoxByXY x1, y1, x2, y2
          @chkScrollBorders editX2, editY2
          # if (not (6 * @chrWid < editX2 < @editorPageW - 2 * @chrWid) or
          #     not (2 * @chrHgt < editY2 < @editorPageH - 2 * @chrHgt))
          #   [ofsX, ofsY] = @getScrollOfs()
          #   row = (Math.round (y2 + ofsY) / @chrHgt) - 1
          #   col =  Math.round (x2 + ofsX) / @chrWid
          #   @editor.scrollToScreenPosition [row-2*@chrH, col]
          #   @editor.scrollToScreenPosition [row,         col-2*@chrW]
          #   @editor.scrollToScreenPosition [row+2*@chrH, col]
          #   @editor.scrollToScreenPosition [row,         col+2*@chrW]
          #   [newOfsX, newOfsY] = @getScrollOfs yes
          #   if newOfsX isnt ofsX or newOfsY isnt ofsY
          #     @refreshBoxPos()
                
        when 'mouseup'
          if not @mouseIsDown then return
          @mouseIsDown = no
          editX2 = e.pageX - @editorPageX
          editY2 = e.pageY - @editorPageY
          @setBoxByXY \
              @edit2textXY(@initEditX1, @initEditY1, editX2, editY2)...
