
log = (args...) -> 
  console.log.apply console, ['box-edit, keyb:'].concat args

module.exports =
  unicodeChr: (e, chr) ->
    # log 'unicodeChr', chr.charCodeAt(0), '"'+chr+'"'
    if chr.charCodeAt(0) >= 32
      @editText 'fill', chr
    e.stopPropagation()
    e.preventDefault()

  keyAction: (e, codeStr) ->    
    if e.metaKey  then codeStr = 'Meta-'  + codeStr
    if e.shiftKey then codeStr = 'Shift-' + codeStr
    if e.altKey   then codeStr = 'Alt-'   + codeStr
    if e.ctrlKey  then codeStr = 'Ctrl-'  + codeStr
    # log 'keyAction', codeStr
    
    # @boxEditToggleBinding ?= 
    #   atom.keymaps.findKeyBindings(command: 'box-edit:toggle')[0]
    #       .keystrokes.toLowerCase()
    # log '@boxEditToggleBinding', @boxEditToggleBinding
    # if @boxEditToggleBinding is codeStr.toLowerCase() 
    #   codeStr = 'Alt-S'
    # 
    switch codeStr
      when 'Alt-S'               then @toggle()
      when 'Ctrl-X'              then @editText 'cut'
      when 'Ctrl-C'              then @editText 'copy'
      when 'Ctrl-V'              then @editText 'paste'
      when 'Backspace', 'Delete' then @editText 'del'
      when 'Ctrl-A'              then @selectAll()
      when 'Ctrl-Z'              then @undo()
      when 'Ctrl-Y'              then @redo()
      when 'Enter'
        if @textEditor then return
        else @openTextEditor()
      when 'Escape', 'Tab' 
        if @textEditor then @closeTextEditor()
        else @clear()
      else 
        log codeStr + ' passed on to Atom'
        return
    e.stopPropagation()
    e.preventDefault()
    
  keyDown: (e) ->
    if not @active then return
    if not @editor or @editor.isDestroyed()
      @clear()
      return
    keyId = e.keyIdentifier
    if @textEditor and keyId not in ['U+0009', 'U+001B'] then return
    if keyId[0..1] is 'U+'
      code = parseInt keyId[2..5], 16
      switch code
        when   8 then codeStr = 'Backspace'
        when   9 then codeStr = 'Tab'
        when  10 then codeStr = 'LineFeed'
        when  13 then codeStr = 'Return'
        when  27 then codeStr = 'Escape'
        when 127 then codeStr = 'Delete'
        else 
          if (e.metaKey or e.altKey or e.ctrlKey)
            if (32 <= code < 127)
              @keyAction e, String.fromCharCode code
            else
              e.stopPropagation()
              e.preventDefault()
          return
      if codeStr then @keyAction e, codeStr
      return
    @keyAction e, keyId
    
  keyPress: (e) ->
    if not @active or @textEditor then return
    if not @editor or @editor.isDestroyed()
      @clear()
      return
    chr = String.fromCharCode e.charCode
    # log 'keyPress', e.keyCode, e.charCode, '"'+chr+'"', (e.ctrlKey or e.altKey or e.metaKey)
    if e.ctrlKey or e.altKey or e.metaKey
      @keyAction e, chr.toUpperCase()
    else
      @unicodeChr e, chr
