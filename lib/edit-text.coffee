
log = (args...) -> 
  console.log.apply console, ['box-edit, edtTx:'].concat args

module.exports =
  
  editText: (cmd, text, addToUndo = yes) ->
    if addToUndo
      oldBufferText = @editor.getText()
      oldRowCol = [row1, col1, row2, col2] = @getBoxRowCol()
    
    clipHgt = 0
    if cmd in ['paste', 'setText']  
      clipTxt = (if cmd is 'paste' then atom.clipboard.read() else text)        
      clipLines = clipTxt.split '\n'
      if clipLines[clipLines.length-1].length is 0
        clipLines = clipLines[0..-2]
      clipHgt = clipLines.length
      clipWidth = 0
      for clipLine in clipLines 
        clipWidth = Math.max clipWidth, clipLine.length
      for clipRow in [0...clipHgt]
        while clipLines[clipRow].length < clipWidth then clipLines[clipRow] += ' '
      blankClipLine = ''
      while blankClipLine.length < clipWidth then blankClipLine += ' '
      getClipLine = (clipRow) ->
        (if clipRow < clipHgt then clipLines[clipRow] else blankClipLine)
    
    if cmd not in ['copy', 'getText']
      @ensureScreenHgt Math.max row2, row1 + clipHgt
    
    # dbg = 0
    screenRow = row1
    boxRow = 0; boxLine = ''
    if cmd is 'fill' then for i in [col1...col2] then boxLine += text
    boxHgt = row2 - row1 + 1
    copyText = ''; lastBufRow = null
    
    while boxRow <= boxHgt-1 or
          cmd in ['paste', 'setText'] and boxRow <= clipHgt-1
      bufRange = 
        @editor.bufferRangeForScreenRange [[screenRow,col1],[screenRow,col2]]
      bufRow = bufRange.start.row
      @ensureLineWid bufRow, col1
      bufRange = 
        @editor.bufferRangeForScreenRange [[screenRow,col1],[screenRow,col2]]
      screenRow++
      # if ++dbg > 100000 then log 'edit box infinite loop'; return
      if bufRow is lastBufRow then continue
      lastBufRow = bufRow
      
      if cmd in ['paste', 'setText']
        @editor.setTextInBufferRange bufRange, getClipLine boxRow
      else if boxRow <= boxHgt-1
        if cmd in ['copy', 'cut', 'getText'] 
          copyText += @editor.getTextInBufferRange(bufRange) + '\n'
        if cmd in ['cut', 'del', 'fill']
          @editor.setTextInBufferRange bufRange, boxLine
      boxRow++
    if cmd is 'copy' then atom.clipboard.write copyText
    
    newCol2 = switch cmd
      when 'paste', 'setText' then col1 + clipWidth
      when 'fill', 'copy', 'setText', 'getText' then col2
      else col1
    @setBoxByRowCol row1, col1, screenRow-1, newCol2
    
    if addToUndo then @addToUndo oldBufferText, oldRowCol
      
    copyText
    
