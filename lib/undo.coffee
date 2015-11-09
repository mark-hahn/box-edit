
log = (args...) -> 
  console.log.apply console, ['box-edit, undo:'].concat args

module.exports =
  
  startUndo: ->
    @undoBuffers    = []
    @undoBoxRowCols = []
    @undoIdx = 0
    @atomUndoCheckpoint = @editor.createCheckpoint()

  endUndo: ->
    @editor.groupChangesSinceCheckpoint @atomUndoCheckpoint
    @undoBuffers = @undoBoxRowCols = null
    @undoIdx = 0

  addToUndo: (txt, rowcol) ->
    if @undoIdx is 0 or txt isnt @undoBuffers[@undoIdx-1]
      @undoBuffers[@undoIdx]    = txt
      @undoBoxRowCols[@undoIdx] = rowcol
      @undoIdx++
      @undoBuffers = @undoBuffers[0...@undoIdx]
      
  undo: ->
    if @undoIdx > 0
      @undoBuffers[@undoIdx]    = @editor.getText()
      @undoBoxRowCols[@undoIdx] = @getBoxRowCol()
      --@undoIdx
      @editor.setText @undoBuffers[@undoIdx]
      @setBoxByRowCol @undoBoxRowCols[@undoIdx]...

  redo: ->
    if @undoIdx < @undoBuffers.length-1 
      @undoIdx++
      @editor.setText @undoBuffers[@undoIdx]
      @setBoxByRowCol @undoBoxRowCols[@undoIdx]...
  
