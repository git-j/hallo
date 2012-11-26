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
    jQuery.widget "IKS.hallo",
        toolbar: null
        bound: false
        originalContent: ""
        previousContent: ""
        uuid: ""
        selection: null
        _keepActivated: false
        originalHref: null

        options:
            editable: true
            plugins: {}
            toolbar: 'halloToolbarContextual'
            parentElement: 'body'
            buttonCssClass: null
            placeholder: ''
            forceStructured: true
            checkTouch: true
            touchScreen: null

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
                # We will populate the toolbar when the
                # editable is activated. This will make multiple
                # Hallo instances on same page load much faster
                @_prepareToolbar()
            @element.bind 'hallodeactivated', =>
                # We will remove the toolbar from dom to keep
                # the DOM clean
                @_removeToolbar()

            @originalContent = @getContents()

        _init: ->
            if @options.editable
                @enable()
            else
                @disable()

        # Disable an editable
        disable: ->
            @element.attr "contentEditable", false
            @element.unbind "focus", @_activated
            @element.unbind "blur", @_deactivated
            @element.unbind "keyup paste change", @_checkModified
            @element.unbind "keyup", @_keys
            @element.unbind "keyup mouseup", @_checkSelection
            @bound = false

            jQuery(@element).removeClass 'isModified'

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

            unless @element.html()
                @element.html this.options.placeholder

            if not @bound
                @element.bind "focus", this, @_activated
                @element.bind "blur", this, @_deactivated
                @element.bind "keyup paste change", this, @_checkModified
                @element.bind "keyup", this, @_keys
                @element.bind "keyup mouseup", this, @_checkSelection
                widget = this
                @bound = true

            @_forceStructured() if @options.forceStructured

            @_trigger "enabled", null

        # Activate an editable for editing
        activate: ->
            @element.focus()

        # Checks whether the editable element contains the current selection
        containsSelection: ->
            range=@getSelection()
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
            sel=rangy.getSelection()
            sel.setSingleRange(range)

        replaceSelection: (cb) ->
            if ( jQuery.browser.msie )
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
            if ( jQuery.browser.msie )
                t = document.selection.createRange().text;
                r = document.selection.createRange()
                r.pasteHTML(cb(t))
            else
                sel = window.getSelection();
                range = sel.getRangeAt(0);
                range_parent = range.commonAncestorContainer
                range_parent = range_parent.parentNode if range_parent.nodeType != 1
                range_content= range.cloneContents()
                range_parent_jq = jQuery ( range_parent )
                range_content_jq = jQuery "<span></span>" #needs container to hold html, as it may not start with node
                range_content_jq[0].appendChild(range_content)
                replacement = cb(range_parent_jq, range_content_jq)
                if ( range_content_jq.text() == '' )
                  range_parent_jq.append(replacement) if replacement
                else
                  document.execCommand("insertHTML",false,replacement) if replacement
                sel.removeAllRanges();
                sel.addRange(range);

        removeAllSelections: () ->
            if ( jQuery.browser.msie )
                range.empty()
            else
                window.getSelection().removeAllRanges()

        # Get contents of an editable as HTML string
        getContents: ->
          # clone
          contentClone = @element.clone()
          for plugin of @options.plugins
            continue unless jQuery.isFunction jQuery(@element).data(plugin)['cleanupContentClone']
            jQuery(@element)[plugin] 'cleanupContentClone', contentClone
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
            if document.execCommand command, false, value
                @element.trigger "change"

        protectFocusFrom: (el) ->
            widget = @
            el.bind "mousedown", (event) ->
                if ( jQuery('.dropdownform:visible').length )
                  return
                event.preventDefault()
                widget._protectToolbarFocus = true
                setTimeout ->
                  widget._protectToolbarFocus = false
                , 300

        keepActivated: (@_keepActivated) ->

        _generateUUID: ->
            S4 = ->
                ((1 + Math.random()) * 0x10000|0).toString(16).substring 1
            "#{S4()}#{S4()}-#{S4()}-#{S4()}-#{S4()}-#{S4()}#{S4()}#{S4()}"

        _prepareToolbar: ->
            @toolbar = jQuery('<div class="hallotoolbar"></div>')

            jQuery(@element)[@options.toolbar]
              editable: @
              parentElement: @options.parentElement
              toolbar: @toolbar
            jQuery(@element)[@options.toolbar]('_create') if jQuery(@element)[@options.toolbar]
            for plugin of @options.plugins
                jQuery(@element)[plugin] 'populateToolbar', @toolbar

            jQuery(@element)[@options.toolbar] 'setPosition'
            @protectFocusFrom @toolbar

        _removeToolbar: ->
            @toolbar.remove() if ( @toolbar )

        _checkModified: (event) ->
            widget = event.data
            widget.setModified() if widget.isModified()

        _keys: (event) ->
            widget = event.data
            if event.keyCode == 27
                old = widget.getContents()
                widget.restoreOriginalContent(event)
                widget._trigger "restored", null,
                    editable: widget
                    content: widget.getContents()
                    thrown: old

                widget.turnOff()

        _rangesEqual: (r1, r2) ->
            r1.startContainer is r2.startContainer and r1.startOffset is r2.startOffset and r1.endContainer is r2.endContainer and r1.endOffset is r2.endOffset

        # Check if some text is selected, and if this selection has changed. If it changed,
        # trigger the "halloselected" event
        _checkSelection: (event) ->
            if event.keyCode == 27
                return

            widget = event.data

            # The mouseup event triggers before the text selection is updated.
            # I did not find a better solution than setTimeout in 0 ms
            setTimeout ()->
                sel = widget.getSelection()
                if widget._isEmptySelection(sel) or widget._isEmptyRange(sel)
                    if widget.selection
                        widget.selection = null
                        widget._trigger "unselected", null,
                            editable: widget
                            originalEvent: event
                    return

                if !widget.selection or not widget._rangesEqual sel, widget.selection
                    widget.selection = sel.cloneRange();
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
            if this.getContents() is this.options.placeholder
                this.setContents ''

            jQuery(@element).addClass 'inEditMode'
            @_trigger "activated", @

        turnOff: () ->
            jQuery(@element).removeClass 'inEditMode'
            @_trigger "deactivated", @

            unless @getContents()
                @setContents @options.placeholder

        _activated: (event) ->
            event.data.turnOn()

        _deactivated: (event) ->
            return if window.debug_hallotoolbar
            return if event.data._keepActivated

            event.data.options.store_callback(event.data.getContents()) if event.data.options.store_callback

            if ( jQuery('.dropdownform:visible').length )
              return

            unless event.data._protectToolbarFocus is true
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

)(jQuery)
