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
    originalHref: null
    undoHistory: []
    selection_marker: 'content_selection_marker'
    auto_store_timeout: 3000

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
        @bound = true
      if ( typeof window._live == 'undefined' )
        window._live = {}
      unless window._live['.editableclick']
        window._live['.editableclick'] = true
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
      @undoWaypoint()
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
      if document.execCommand command, false, value
        @element.trigger "change"

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

    _paste: (event) ->
      event.preventDefault()
      pdata = event.originalEvent.clipboardData.getData('text/html')
      if (typeof pdata == 'undefined' )
        pdata = event.originalEvent.clipboardData.getData('text/plain')
      if (typeof pdata == 'undefined' )
        utils.error(utils.tr('invalid clipboard data'))
        return
      pdata = pdata.replace(/<script/g,'<xscript').replace(/<\/script/,'</xscript')

      jq_temp = jQuery('<div>' + pdata + '</div>')
      dom = new IDOM()
      dom.clean(jq_temp);
      html = jq_temp.html();
      sel = window.getSelection()
      range = sel.getRangeAt()
      range.deleteContents()
      range.insertNode(jq_temp[0])

      
    _ignoreKeys: (code) ->
      # cursor movements
      return true if ( code >= 33 && code <= 40 )
      return true if ( code == 20 ) #caps

      return false
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
      if event.keyCode == 66 && event.ctrlKey #b
          document.execCommand("bold",false)
      if event.keyCode == 73 && event.ctrlKey #i
          document.execCommand("italic",false)
      if event.keyCode == 85 && event.ctrlKey #u
          document.execCommand("underline",false)
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

    _syskeys: (event) ->
      widget = event.data
      return if widget._ignoreKeys(event.keyCode)
      if event.keyCode == 9 && !event.shiftKey  #tab
        range = window.getSelection().getRangeAt()
        li = $(range.startContainer).closest('li')
        li = $(range.endContainer).closest('li') if !li.length
        if ( li.length )
          return if widget.element.closest('li').length && widget.element.closest('li')[0] == li[0]
          document.execCommand("indent",false)
          event.preventDefault()
      if event.keyCode == 9 && event.shiftKey  #shift+tab
        range = window.getSelection().getRangeAt()
        li = $(range.startContainer).closest('li')
        li = $(range.endContainer).closest('li') if !li.length
        if ( li.length )
          return if widget.element.closest('li').length && widget.element.closest('li')[0] == li[0]
          document.execCommand("outdent",false)
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
      if ( jQuery('.inEditMode').length )
        #avoid multiple instances that fail to turn of their toolbars
        jQuery('.inEditMode').hallo('turnOff')
      if this.getContents() is this.options.placeholder
        #this.setContents ' '
        force_focus = =>
          return if !jQuery(@element).hasClass 'inEditMode'
          #document.execCommand('selectAll',false,null);
          new_range = document.createRange()
          content_node = jQuery(@element)[0] #//? is element a DOMnode?
          new_range.selectNodeContents(content_node);
          window.getSelection().removeAllRanges();
          window.getSelection().addRange(new_range);
        window.setTimeout(force_focus,1)
      jQuery(@element).addClass 'inEditMode'
      @_trigger "activated", null, @

    turnOff: () ->
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
      # console.log('hallo activated')
      if ( jQuery('.dropdown-form:visible').length )
        jQuery('.dropdown-form:visible').each (index,item) =>
          jQuery(item).hallodropdownform('hideForm')
        event.data.turnOff()
      event.data.turnOn()
      event.data.restoreContentPosition()

    _deactivated: (event) ->
      return if window.debug_hallotoolbar
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

    undoWaypoint: ->
      waypoint = 
        'date': Date.now()
        'content': jQuery(@element).html()
      if ( @undoHistory.length )
        if ( waypoint.content == @undoHistory[@undoHistory.length - 1].content )
          return
      @undoHistory.push(waypoint)
      while @undoHistory.length > @options.maxUndoEntries
        @undoHistory.shift()
      # console.log('undo waypoint',@undoHistory)

    restoreContentPosition: ->
      console.log('restoreContentPosition')
      stored_selection = @element.find(@selection_marker)
      if ( stored_selection.length )
        # console.log('selection to restore:',stored_selection)
        window.getSelection().removeAllRanges()
        range = document.createRange()
        range.selectNode(stored_selection[0])
        window.getSelection().removeAllRanges()
        window.getSelection().addRange(range)
        @undoWaypoint()

    storeContentPosition: ->
      console.log('storeContentPosition')
      @undoWaypoint()
      sel = window.getSelection()
      # console.log('ranges to store:' + sel.rangeCount)
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
        console.log('before:' + @element.html()) if @debug
        selection_identifier = jQuery('<' + @selection_marker + ' id="' + tmp_id + '"></' + @selection_marker + '>')
        try
          range.surroundContents(selection_identifier[0])
        catch e
          # utils.info(utils.tr('warning selected block contents'))
          range.collapse(false) # to end
          range.insertNode(selection_identifier[0])
          sel.removeAllRanges()
          sel.addRange(range)
        console.log('after:' + @element.html()) if @debug
        # console.log('selection added',@element.html())

    setContentPosition: (jq_node) ->
      sel = window.getSelection()
      sel.removeAllRanges()
      range = document.createRange()
      range.selectNode(jq_node[0])
      sel.addRange(range)
      @storeContentPosition()



)(jQuery)
