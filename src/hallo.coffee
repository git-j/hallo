###
Hallo {{ VERSION }} - a rich text editing jQuery UI widget
(c) 2011 Henri Bergius, IKS Consortium
Hallo may be freely distributed under the MIT license
http://hallojs.org
###
((jQuery) ->
  # Hallo provides a jQuery UI widget `hallo`. Usage:
  #
  #     jQuery('p').hallo();
  #
  # Getting out of the editing state:
  #
  #     jQuery('p').hallo({editable: false});
  #
  # When content is in editable state, users can just click on
  # an editable element in order to start modifying it. This
  # relies on browser having support for the HTML5 contentEditable
  # functionality, which means that some mobile browsers are not
  # supported.
  #
  # If plugins providing toolbar buttons have been enabled for
  # Hallo, then a toolbar will be rendered when an area is active.
  #
  # ## Toolbar
  #
  # Hallo ships with different toolbar options, including:
  #
  # * `halloToolbarContextual`: a toolbar that appears as a popover
  #   dialog when user makes a selection
  # * `halloToolbarFixed`: a toolbar that is constantly visible above
  #   the editable area when the area is activated
  #
  # The toolbar can be defined by the `toolbar` configuration key,
  # which has to conform to the toolbar widget being used.
  #
  # Just like with plugins, it is possible to use Hallo with your own
  # custom toolbar implementation.
  #
  # ## Events
  #
  # The Hallo editor provides several jQuery events that web
  # applications can use for integration:
  #
  # ### Activated
  #
  # When user activates an editable (usually by clicking or tabbing
  # to an editable element), a `halloactivated` event will be fired.
  #
  #     jQuery('p').bind('halloactivated', function() {
  #         console.log("Activated");
  #     });
  #
  # ### Deactivated
  #
  # When user gets out of an editable element, a `hallodeactivated`
  # event will be fired.
  #
  #     jQuery('p').bind('hallodeactivated', function() {
  #         console.log("Deactivated");
  #     });
  #
  # ### Modified
  #
  # When contents in an editable have been modified, a
  # `hallomodified` event will be fired.
  #
  #     jQuery('p').bind('hallomodified', function(event, data) {
  #         console.log("New contents are " + data.content);
  #     });
  #
  # ### Restored
  #
  # When contents are restored through calling
  # `.hallo("restoreOriginalContent")` or the user pressing ESC while
  # the cursor is in the editable element, a 'hallorestored' event will
  # be fired.
  #
  #     jQuery('p').bind('hallorestored', function(event, data) {
  #         console.log("The thrown contents are " + data.thrown);
  #         console.log("The restored contents are " + data.content);
  #     });
  #
  jQuery.widget 'IKS.hallo',
    toolbar: null
    bound: false
    originalContent: ''
    previousContent: ''
    uuid: ''
    selection: null
    _keepActivated: false
    _ignoreEvents: false
    originalHref: null
    _undo_stack: null
    selection_marker: 'content_selection_marker'
    auto_store_timeout: 3000
    debug: false
    _key_handlers: []

    options:
      editable: true
      plugins: {}
      toolbar: 'halloToolbarContextual'
      parentElement: 'body'
      buttonCssClass: null
      toolbarCssClass: null
      toolbarPositionAbove: false
      toolbarOptions: {}
      placeholder: ''
      forceStructured: true
      checkTouch: true
      touchScreen: null
      maxUndoEntries: 10

    _create: ->
      @id = @_generateUUID()

      @checkTouch() if @options.checkTouch and @options.touchScreen is null

      for plugin, options of @options.plugins
        options = {} unless jQuery.isPlainObject options
        jQuery.extend options,
          editable: this
          uuid: @id
          buttonCssClass: @options.buttonCssClass
        jQuery(@element)[plugin] options

      @element.bind 'halloactivated', =>
        # We will populate the toolbar the first time this
        # editable is activated. This will make multiple
        # Hallo instances on same page load much faster
        @_prepareToolbar()

      @originalContent = @getContents()

    _init: ->
      if @options.editable
        @enable()
      else
        @disable()

    destroy: ->
      @disable()

      if @toolbar
        @toolbar.remove()
        @element[@options.toolbar] 'destroy'

      for plugin, options of @options.plugins
        jQuery(@element)[plugin] 'destroy'

      jQuery.Widget::destroy.call @

    # Disable an editable
    disable: ->
      @element.attr "contentEditable", false
      @element.unbind "focus", @_activated
      @element.unbind "blur", @_deactivated
      @element.unbind "keyup paste change", @_checkModified
      @element.unbind "keyup", @_keys
      @element.unbind "keydown", @_syskeys
      @element.unbind "keyup mouseup", @_checkSelection
      @element.unbind "paste", @_paste
      @element.unbind "copy", @_copy
      @element.unbind "cut", @_cut
      # toolbar activated/deactivated happens on focusin/out
      @_key_handlers = []
      @bound = false

      jQuery(@element).removeClass 'isModified'
      jQuery(@element).removeClass 'inEditMode'

      @element.parents('a').andSelf().each (idx, elem) =>
        element = jQuery elem
        return unless element.is 'a'
        return unless @originalHref
        element.attr 'href', @originalHref

      @_trigger "disabled", null

    # Enable an editable
    enable: ->
      @element.parents('a[href]').andSelf().each (idx, elem) =>
        element = jQuery elem
        return unless element.is 'a[href]'
        @originalHref = element.attr 'href'
        element.removeAttr 'href'

      @element.attr "contentEditable", true

      unless @element.html().trim()
        @element.html this.options.placeholder
        unless ( @element.is('h1,h2,h3,h4,h5,h6'))
          @element.css
            'min-width': @element.innerWidth()
            'min-height': @element.innerHeight()

      unless @bound
        @element.bind "focus", this, @_activated
        @element.bind "blur", this, @_deactivated
        @element.bind "keyup paste change", this, @_checkModified
        @element.bind "keyup", this, @_keys
        @element.bind "keydown", this, @_syskeys
        @element.bind "keyup mouseup", this, @_checkSelection
        @element.bind "paste", this, @_paste
        @element.bind "copy", this, @_copy
        @element.bind "cut", this, @_cut
        @bound = true
      if ( typeof window._live == 'undefined' )
        window._live = {}
      unless window._live['.editableclick']
        window._live['.editableclick'] = true
        if(jQuery('[contenteditable=false]').length>0)
          jQuery('[contenteditable=false]').live "click", (event) =>
            target = event.target
            if ( jQuery(target).closest('[contenteditable=true]').length == 0 )
              return
            window.getSelection().removeAllRanges()
            range = document.createRange()
            range.selectNode(target)
            window.getSelection().addRange(range)


      @_forceStructured() if @options.forceStructured

      @_trigger "enabled", null

    # Activate an editable for editing
    activate: ->
      @element.focus()

    # Checks whether the editable element contains the current selection
    containsSelection: ->
      range = @getSelection()
      return @element.has(range.startContainer).length > 0

    # Only supports one range for now (i.e. no multiselection)
    getSelection: ->
      sel = rangy.getSelection()
      range = null
      if sel.rangeCount > 0
        range = sel.getRangeAt(0)
      else
        range = rangy.createRange()
      return range

    restoreSelection: (range) ->
      sel = rangy.getSelection()
      sel.setSingleRange(range)

    setSelectionRange: (input, selection_start, selection_end) ->
      # set the selection range in a textarea/editable
      if ( input.setSelectionRange )
        input.focus();
        input.setSelectionRange(selection_start, selection_end);
      else if ( input.createTextRange )
        range = input.createTextRange();
        range.collapse(true);
        range.moveEnd('character', selection_end);
        range.moveStart('character', selection_start);
        range.select();

    setCaretToPos: (input, pos) ->
      # move the cursor, no need for a selection
      @_setSelectionRange(input, pos, pos);

    replaceSelection: (cb) ->
      if navigator.appName is 'Microsoft Internet Explorer'
        t = document.selection.createRange().text;
        r = document.selection.createRange()
        r.pasteHTML(cb(t))
      else
        sel = window.getSelection();
        range = sel.getRangeAt(0);
        newTextNode = document.createTextNode(cb(range.extractContents()));
        range.insertNode(newTextNode);
        range.setStartAfter(newTextNode);
        sel.removeAllRanges();
        sel.addRange(range);

    replaceSelectionHTML: (cb) ->
      if navigator.appName is 'Microsoft Internet Explorer'
        t = document.selection.createRange().text;
        r = document.selection.createRange()
        r.pasteHTML(cb(t))
      else
        sel = window.getSelection()
        range = sel.getRangeAt(0)
        # console.log(range)
        range_parent = range.commonAncestorContainer
        range_parent = range_parent.parentNode if range_parent.nodeType != 1
        range_content= range.cloneContents()
        range_parent_jq = jQuery ( range_parent )
        range_content_jq = jQuery "<div></div>" #needs container to hold html, as it may not start with node
        range_content_jq[0].appendChild(range_content)
        replacement = cb(range_parent_jq, range_content_jq)
        range.deleteContents()
        range.insertNode($('<span>' + replacement + '</span>')[0]) if replacement
        sel.removeAllRanges();
        sel.addRange(range);
        @storeContentPosition()

    removeAllSelections: () ->
      if navigator.appName is 'Microsoft Internet Explorer'
        range.empty()
      else
        window.getSelection().removeAllRanges()

    # Get contents of an editable as HTML string
    getContents: ->
      # clone
      contentClone = @element.clone()
      #for plugin of @options.plugins
      #  cleanup = jQuery(@element).data(plugin).cleanupContentClone
      #  continue unless jQuery.isFunction cleanup
      #  jQuery(@element)[plugin] 'cleanupContentClone', contentClone
      contentClone.html()

    # Set the contents of an editable
    setContents: (contents) ->
      @element.html contents

    # Check whether the editable has been modified
    isModified: ->
      @previousContent = @originalContent unless @previousContent
      @previousContent isnt @getContents()

    # Set the editable as unmodified
    setUnmodified: ->
      jQuery(@element).removeClass 'isModified'
      @previousContent = @getContents()

    # Set the editable as modified
    setModified: ->
      jQuery(@element).addClass 'isModified'
      @._trigger 'modified', null,
        editable: @
        content: @getContents()

    # Restore the content original
    restoreOriginalContent: () ->
      @element.html(@originalContent)

    # Execute a contentEditable command
    execute: (command, value) ->
      @undoWaypointStart()
      if ( command.indexOf('justify') == 0 )
        # when <p style="text-align:left"><span style="text-align:left">test</span></p>
        # is in the content, after aligning the content to the right, it is no longer
        # possible to align it left, as execCommand only changes the closest p/div
        # this implementation uses the current cursor position and removes all alignment
        # related style attributes from the content before executing the command
        # this action breaks the default undo
        @storeContentPosition()
        selection = @element.find(@selection_marker)
        while ( selection.length )
          if ( selection.attr('contenteditable') == 'true' )
            break
          style_attr = selection.attr('style')
          if ( typeof style_attr != 'undefined' )
            style_attr = style_attr.replace(/text-align:[^;]*/,'')
            style_attr = style_attr.trim()
            if ( style_attr == '' || style_attr == ';' )
              selection.removeAttr('style')
            else
              selection.attr('style',style_attr)
          selection = selection.parent()
      range = window.getSelection().getRangeAt()
      if ( range.collapsed )
        range.selectNode(range.startContainer)
        window.getSelection().addRange(range)

      if document.execCommand command, false, value
        @element.trigger "change"
      @undoWaypointCommit(false)

    protectFocusFrom: (el) ->
      el.bind "mousedown", (event) =>
        if ( jQuery('.dropdown-form:visible').length )
          return
        event.preventDefault()
        @_protectToolbarFocus = true
        setTimeout =>
          @_protectToolbarFocus = false
        , 300

    keepActivated: (@_keepActivated) ->

    _generateUUID: ->
      S4 = ->
        ((1 + Math.random()) * 0x10000|0).toString(16).substring 1
      "#{S4()}#{S4()}-#{S4()}-#{S4()}-#{S4()}-#{S4()}#{S4()}#{S4()}"

    _prepareToolbar: ->
      @toolbar = jQuery('<div class="hallotoolbar"></div>').hide()
      @toolbar.addClass @options.toolbarCssClass if @options.toolbarCssClass

      defaults =
        editable: @
        parentElement: @options.parentElement
        toolbar: @toolbar
        positionAbove: @options.toolbarPositionAbove

      toolbarOptions = $.extend({}, defaults, @options.toolbarOptions)
      @element[@options.toolbar] toolbarOptions

      for plugin of @options.plugins

        if ( jQuery(@element).length > 0 && typeof jQuery(@element).data(plugin) != "undefined" )
            populate = jQuery(@element).data(plugin).populateToolbar

        continue unless jQuery.isFunction populate
        @element[plugin] 'populateToolbar', @toolbar

      @element[@options.toolbar] 'setPosition'
      @protectFocusFrom @toolbar

    changeToolbar: (element, toolbar, hide = false) ->
      originalToolbar = @options.toolbar

      @options.parentElement = element
      @options.toolbar = toolbar if toolbar

      return unless @toolbar
      @element[originalToolbar] 'destroy'
      do @toolbar.remove
      do @_prepareToolbar

      @toolbar.hide() if hide

    _checkModified: (event) ->
      widget = event.data
      widget.setModified() if widget.isModified()

    _copy: (event) ->
      console.log('copy',event) if @debug
      return if ( !window.wke )
      event.preventDefault()
      range = window.getSelection().getRangeAt()
      rdata = jQuery('<div/>').append(range.cloneContents())
      dom = new IDOM()
      dom.cleanExport(rdata);

      console.log(range,rdata,rdata.html()) if @debug
      utils.storeToClipboard(rdata)

    _cut: (event) ->
      event.data.undoWaypointStart('cut')
      event.data._copy(event)
      range = window.getSelection().getRangeAt()
      range.deleteContents()
      event.data.undoWaypointCommit(false)


    _paste: (event) ->
      pdata = ''
      if jQuery.isArray(event.originalEvent.clipboardData.types)
        event.originalEvent.clipboardData.types.forEach (type) =>
          #console.log(type,pdata)
          return if ( type.indexOf('text/') != 0 )
          return if ( type == 'text/plain' && pdata != '')
          pdata = event.originalEvent.clipboardData.getData(type)
      #console.log(pdata)
      if (pdata == '' )
        pdata = event.originalEvent.clipboardData.getData('text/plain')
      if (typeof pdata == 'undefined' && pdata == '' )
        #utils.error(utils.tr('invalid clipboard data'))
        return
      event.preventDefault()
      event.data.undoWaypointStart('paste')
      pdata = pdata.replace(/<script/g,'<xscript').replace(/<\/script/,'</xscript')

      jq_temp = jQuery('<div>' + pdata + '</div>')
      dom = new IDOM()
      dom.clean(jq_temp);
      html = jq_temp.html();
      sel = window.getSelection()
      range = sel.getRangeAt()
      range.deleteContents()
      if ( pdata.indexOf('<') == 0 )
        # wrapped in element
        # console.log('wrapped',jq_temp)
        range.insertNode(jq_temp[0])
      else
        jq_temp = jq_temp.contents()
        jq_temp.unwrap()
        # console.log('unwrapped',jq_temp)
        range.insertNode(jq_temp.contents()[0])
      event.data.undoWaypointCommit(false)

      
    _ignoreKeys: (code) ->
      # cursor movements
      # This table is especially useful for those who want to capture 
      # the key press event in the browser window. These are the char codes JavaScript uses, 
      # and the keys they bind to:
      # Char
      # Key Name
      # 8 Backspace
      # 9 Tab
      # 13  Enter
      # 16  Shift
      # 17  Ctrl
      # 18  Alt
      # 19  Pause
      # 20  Caps Lock
      # 27  Escape
      # 33  Page Up
      # 34  Page Down
      # 35  End
      # 36  Home
      # 37  Arrow Left
      # 38  Arrow Up
      # 39  Arrow Right
      # 40  Arrow Down
      # 45  Insert
      # 46  Delete
      # 48  0
      # 49  1
      # 50  2
      # 51  3
      # 52  4
      # 53  5
      # 54  6
      # 55  7
      # 56  8
      # 57  9
      # 65  A
      # 66  B
      # 67  C
      # 68  D
      # 69  E
      # 70  F
      # 71  G
      # 72  H
      # 73  I
      # 74  J
      # 75  K
      # 76  L
      # 77  M
      # 78  N
      # 79  O
      # 80  P
      # 81  Q
      # 82  R
      # 83  S
      # 84  T
      # 85  U
      # 86  V
      # 87  W
      # 88  X
      # 89  Y
      # 90  Z
      # 91  Left Windows
      # 92  Right Windows
      # 93  Context Menu
      # 96  NumPad 0
      # 97  NumPad 1
      # 98  NumPad 2
      # 99  NumPad 3
      # 100 NumPad 4
      # 101 NumPad 5
      # 102 NumPad 6
      # 103 NumPad 7
      # 104 NumPad 8
      # 105 NumPad 9
      # 106 NumPad *
      # 107 NumPad +
      # 109 NumPad -
      # 110 NumPad .
      # 111 NumPad /
      # 112 F1
      # 113 F2
      # 114 F3
      # 115 F4
      # 116 F5
      # 117 F6
      # 118 F7
      # 119 F8
      # 120 F9
      # 121 F10
      # 122 F11
      # 123 F12
      # 144 Num Lock
      # 145 Scroll Lock
      # 186 ;
      # 187 =
      # 188 ,
      # 189 -
      # 190 .
      # 191 /
      # 192 `
      # 219 [
      # 220 \
      # 221 ]
      # 222 '

      return true if ( code >= 33 && code <= 40 )
      return true if ( code == 20 ) #caps

      return false
    registerKey: (modifier,keyCode,callback_fn) ->
      check_fn = (event) =>
        check_modifiers = 
          'ctrlKey': modifier.indexOf('ctrl')>=0
          'shiftKey': modifier.indexOf('shift')>=0
          'altKey': modifier.indexOf('alt')>=0
          # always true'metaKey': modifier.indexOf('meta')>=0
        mod_state = true
        jQuery.each check_modifiers, (key,value) =>
          mod_state = mod_state & event[key] == value
        if ( mod_state ) 
          if ( event.keyCode == keyCode )
            callback_fn(event)
            return true
        return false
      @_key_handlers.push(check_fn)

    checkRegisteredKeys: (event) ->
      found_handler = false
      @_key_handlers.forEach (key_handler) =>
        return if ( found_handler )
        found_handler = key_handler(event)
      return found_handler

    _keys: (event) ->
      widget = event.data
      #if event.keyCode == 27
      #    old = widget.getContents()
      #    widget.restoreOriginalContent(event)
      #    widget._trigger "restored", null,
      #        editable: widget
      #        content: widget.getContents()
      #        thrown: old
      #    widget.turnOff()
      return if widget._ignoreKeys(event.keyCode)
      if ( event.keyCode == 32 || event.keyCode == 13 || event.keyCode == 8 ) && !event.ctrlKey
        widget.undoWaypointCommit()
        widget.undoWaypointStart('text')
      if event.keyCode == 66 && event.ctrlKey #b
          widget.execute("bold")
      if event.keyCode == 73 && event.ctrlKey #i
          widget.execute("italic")
      if event.keyCode == 85 && event.ctrlKey #u
          widget.execute("underline")
      if ( !event.ctrlKey && !event.shiftKey && event.keyCode != 17 && event.keycode != 16 )
        # helps but gets _slow_ widget.element[0].blur()
        # widget.element[0].focus()
        # sel.addRange(new_range)
        if ( widget.autostore_timer )
          window.clearTimeout(widget.autostore_timer)
        widget.autostore_timer = window.setTimeout =>
          widget.storeContentPosition()
          widget.store()
          widget.restoreContentPosition()
        , widget.auto_store_timeout

    _select_cell_fn: (cell) ->
      sel = window.getSelection()
      range = document.createRange()
      range.selectNode(cell)
      sel.removeAllRanges()
      sel.addRange(range)

    _syskeys: (event) ->
      widget = event.data
      return if widget._ignoreKeys(event.keyCode)
      return if widget.checkRegisteredKeys(event)
      if event.keyCode == 9 && !event.shiftKey  #tab
        range = window.getSelection().getRangeAt()
        li = $(range.startContainer).closest('li')
        li = $(range.endContainer).closest('li') if !li.length
        if ( li.length )
          return if widget.element.closest('li').length && widget.element.closest('li')[0] == li[0]
          widget.execute("indent")
          event.preventDefault()
          return
        td = $(range.startContainer).closest('td,th')
        if ( td.length )
          table = td.closest('table')
          use_next = false
          tds = table.find('td,th')
          tds.each (index,item) =>
            if ( use_next )
              use_next = false
              widget._select_cell_fn(item)
            if ( item != td[0] )
              return # continue
            use_next = true
          if ( use_next )
            widget._select_cell_fn(tds[0])
          event.preventDefault()
      if event.keyCode == 9 && event.shiftKey  #shift+tab
        range = window.getSelection().getRangeAt()
        li = $(range.startContainer).closest('li')
        li = $(range.endContainer).closest('li') if !li.length
        if ( li.length )
          return if widget.element.closest('li').length && widget.element.closest('li')[0] == li[0]
          widget.execute("outdent")
          event.preventDefault()
          return
        td = $(range.startContainer).closest('td,th')
        if ( td.length )
          table = td.closest('table')
          use_prev = false
          tds = table.find('td,th')
          tds.each (index,item) =>
            if ( item != td[0] )
              return # continue
            if ( index > 0 )
              widget._select_cell_fn(tds[index-1])
            else
              widget._select_cell_fn(tds[tds.length-1])
          event.preventDefault()



    _rangesEqual: (r1, r2) ->
      return false unless r1.startContainer is r2.startContainer
      return false unless r1.startOffset is r2.startOffset
      return false unless r1.endContainer is r2.endContainer
      return false unless r1.endOffset is r2.endOffset
      true

    # Check if some text is selected, and if this selection has changed.
    # If it changed, trigger the "halloselected" event
    _checkSelection: (event) ->
      if event.keyCode == 27
        return

      widget = event.data

      # The mouseup event triggers before the text selection is updated.
      # I did not find a better solution than setTimeout in 0 ms
      setTimeout ->
        sel = widget.getSelection()
        if widget._isEmptySelection(sel) or widget._isEmptyRange(sel)
          if widget.selection
            widget.selection = null
            widget._trigger "unselected", null,
              editable: widget
              originalEvent: event
          return

        if !widget.selection or not widget._rangesEqual sel, widget.selection
          widget.selection = sel.cloneRange()
          widget._trigger "selected", null,
            editable: widget
            selection: widget.selection
            ranges: [widget.selection]
            originalEvent: event
      , 0

    _isEmptySelection: (selection) ->
      if selection.type is "Caret"
        return true
      return false

    _isEmptyRange: (range) ->
      if range.collapsed
        return true
      if range.isCollapsed
        return range.isCollapsed() if typeof range.isCollapsed is 'function'
        return range.isCollapsed

      return false

    turnOn: () ->
      if ( @autostore_timer )
        window.clearTimeout(@autostore_timer)
      if ( jQuery('.inEditMode').length )
        #avoid multiple instances that fail to turn of their toolbars
        jQuery('.inEditMode').hallo('turnOff')
      if this.getContents() is this.options.placeholder
        #this.setContents ' '
        force_focus = =>
          return if !jQuery(@element).hasClass 'inEditMode'
          new_range = document.createRange()
          content_node = jQuery(@element)[0] #//? is element a DOMnode?
          new_range.selectNodeContents(content_node);
          window.getSelection().removeAllRanges();
          window.getSelection().addRange(new_range);
        window.setTimeout(force_focus,1)
      jQuery(@element).addClass 'inEditMode'
      @_trigger "activated", null, @

    turnOff: () ->
      if ( @autostore_timer )
        window.clearTimeout(@autostore_timer)
      jQuery(@element).removeClass 'inEditMode'
      @_trigger "deactivated", @
      jQuery('.misspelled').remove() #TODO: move to desktop

      contents = @getContents()
      if contents == '' or contents == ' ' or contents == '<br>' or contents == @options.placeholder
        @setContents @options.placeholder

    store: () ->
      if ( @autostore_timer )
        window.clearTimeout(@autostore_timer)
      if @options.store_callback
        contents = @getContents()
        if contents == '' or contents == ' ' or contents == '<br>' or contents == @options.placeholder
          @setContents ''
        @options.store_callback(@getContents())
    _activated: (event) ->
      return if event.data._ignoreEvents
      console.log('hallo activated') if @debug
      if ( jQuery('.dropdown-form:visible').length )
        jQuery('.dropdown-form:visible').each (index,item) =>
          jQuery(item).hallodropdownform('hideForm')
        event.data.turnOff()
      event.data.turnOn()
      event.data.restoreContentPosition()

    _deactivated: (event) ->
      console.log('hallo deactivated, set window.debug_hallotoolbar true to prevent') if @debug
      return if window.debug_hallotoolbar
      return if event.data._ignoreEvents
      if ( @autostore_timer )
        window.clearTimeout(@autostore_timer)
      event.data.undoWaypointCommit(true)
      event.data.storeContentPosition()
      if event.data.options.store_callback
        contents = event.data.getContents()
        if contents == '' or contents == ' ' or contents == '<br>' or contents == event.data.options.placeholder
          event.data.setContents ''
        event.data.options.store_callback(event.data.getContents())

      return if event.data._keepActivated # always store before unfocusing

      if ( jQuery('.dropdown-form:visible').length )
        return

      unless event.data._protectToolbarFocus is true
        # console.log('hallo deactivated')
        event.data._key_handlers = []
        event.data.turnOff()
      else
        setTimeout ->
          jQuery(event.data.element).focus()
        , 300

    _forceStructured: (event) ->
      try
        document.execCommand 'styleWithCSS', 0, false
      catch e
        try
          document.execCommand 'useCSS', 0, true
        catch e
          try
            document.execCommand 'styleWithCSS', false, false
          catch e

    checkTouch: ->
      @options.touchScreen = !!('createTouch' of document)

    undoWaypointStart: (id) ->
      return if ( typeof UndoCommand == 'undefined' )
      @_current_undo_command = new UndoCommand()
      @_current_undo_command.before_data = @element.html()
      if ( typeof id != 'undefined' )
        @_current_undo_command.id = id
      @_current_undo_command

    undoWaypointCommit: (auto) ->
      return if ( typeof UndoCommand == 'undefined' )
      return if ( typeof UndoStack == 'undefined' )
      return if ( !@_current_undo_command )
      @_undo_stack = @undoWaypointLoad(@element)
      return if ( auto && @_undo_stack.canRedo() )
      undo_command = @_current_undo_command
      undo_command.after_data = @element.html()
      return if undo_command.after_data == undo_command.before_data
      undo_command.undo = () =>
        #console.log('undo command executing',undo_command.before_data,@_undo_stack.target.html())
        @_undo_stack.target.html(undo_command.before_data)
        @restoreContentPosition()
        undo_command.postdo()
        #utils.info('undone' + @_undo_stack.index() + '/' + @_undo_stack.length)
      undo_command.redo = () =>
        #console.log('redo command executing',undo_command.after_data)
        @_undo_stack.target.html(undo_command.after_data)
        @restoreContentPosition()
        undo_command.postdo()
        #utils.info('redone' + @_undo_stack.index() + '/' + @_undo_stack.length)
      if ( undo_command.id == 'text' )
        previous_command = @_undo_stack.peek()
        if ( previous_command )
          previous_command.mergeWith = (current_command) =>
            if ( previous_command.after_data == current_command.after_data || Math.abs(previous_command.after_data.length - current_command.after_data.length)< 5 )
              # make sure the latest state is stored
              previous_command.after_data = current_command.after_data
              return true

            return false
      console.log('pushing undo:',undo_command.after_data,undo_command) if @debug
      @_undo_stack.push(undo_command)
      @_current_undo_command = null
    
    undo: (target) ->
      if ( target )
        # use event trigger element
        @_undo_stack = @undoWaypointLoad(target)
      return if (!@_undo_stack)

      if !@_undo_stack.canRedo() && @_undo_stack.canUndo()
        undo_command = @_undo_stack.command(@_undo_stack.current_index)
        undo_command.after_data = @_undo_stack.target.html() 
      @_undo_stack.undo()
    
    redo: (target) ->
      if ( target )
        # use event trigger element
        @_undo_stack = @undoWaypointLoad(target)
      return if (!@_undo_stack)
      @_undo_stack.redo()

    undoWaypointIdentifier: (target) ->
      classname = target.attr('class')
      classname = classname.replace(/\s/g,'')
      classname = classname.replace(/isModified/g,'')
      classname = classname.replace(/inEditMode/g,'')
      id = target.attr('id')
      pelement = target.parent()
      while ( typeof id == 'undefined' && pelement )
        id = pelement.attr('id')
        pelement = pelement.parent()
        if ( !pelement )
          id = 'unknown'
      # console.log('wpid',classname,id)
      return classname + id


    undoWaypointLoad: (target) ->
      return if ( typeof UndoManager == 'undefined' )

      return if ( typeof UndoStack == 'undefined' )
      wpid = @undoWaypointIdentifier(target)
      @_undo_stack = (new UndoManager()).getStack(wpid)
      @_undo_stack.setUndoLimit(64) # 64x128x6editors ~ 48mb of worst case undo buffering
      @_undo_stack.target = target
      return @_undo_stack

    restoreContentPosition: ->
      console.log('restoreContentPosition') if @debug
      stored_selection = @element.find(@selection_marker)
      if ( stored_selection.length )
        console.log('selection to restore:',stored_selection) if @debug
        window.getSelection().removeAllRanges()
        @_ignoreEvents = true # avoid deactivating because of addRange
        try
        
          range = document.createRange()
          range.selectNode(stored_selection[0])
          window.getSelection().removeAllRanges()
          window.getSelection().addRange(range)
        catch e
          # ignore
        @_ignoreEvents = false # avoid deactivating because of addRange


    storeContentPosition: ->
      console.log('storeContentPosition') if @debug
      sel = window.getSelection()
      console.log('ranges to store:' + sel.rangeCount) if @debug
      if ( sel.rangeCount > 0 )
        range = sel.getRangeAt()
        tmp_id = 'range' + Date.now()
        @element.find(@selection_marker).removeAttr('id')
        remove_queue = [];
        @element.find(@selection_marker).each (index,item) =>
          marker = jQuery(item)
          if ( marker.html() == '' )
            remove_queue.push(marker)
          else
            marker.contents().unwrap()
        for marker in remove_queue
          marker.remove()
        console.log('before:' + @element.html()) if @debug & 2
        selection_identifier = jQuery('<' + @selection_marker + ' id="' + tmp_id + '"></' + @selection_marker + '>')
        @_ignoreEvents = true # avoid deactivating because of addRange
        try
          console.log(selection_identifier) if @debug
          #range.surroundContents(selection_identifier[0])
          selection_identifier[0].appendChild(range.extractContents());
          range.insertNode(selection_identifier[0])
          #range.surroundContents(selection_identifier)
          console.log('stored') if @debug
        catch e
          # deactivated - may issue in formula editor
          # utils.info(utils.tr('warning selected block contents'))
          new_range = range.cloneRange()
          new_range.collapse(false) # to end
          new_range.insertNode(selection_identifier[0])
          console.log('block contents') if @debug
          #sel.removeAllRanges()
          #sel.addRange(range)
        range.selectNode(selection_identifier[0])
        window.getSelection().removeAllRanges()
        window.getSelection().addRange(range)
        @_ignoreEvents=false
        console.log('after:' + @element.html()) if @debug & 2
        # console.log('selection added',@element.html())

    setContentPosition: (jq_node) ->
      sel = window.getSelection()
      sel.removeAllRanges()
      range = document.createRange()
      range.selectNode(jq_node[0])
      sel.addRange(range)
      @storeContentPosition()



)(jQuery)
