#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
  jQuery.widget 'IKS.hallobutton',
    button: null
    isChecked: false

    options:
      uuid: ''
      label: null
      icon: null
      editable: null
      command: null
      queryState: true
      cssClass: null

    _create: ->
      # By default the icon is icon-command, but this doesn't
      # always match with <http://fortawesome.github.com/Font-Awesome/#base-icons>
      #@options.icon ?= "icon-#{@options.label.toLowerCase()}"
      @options.text = false
      @options.icons = { "primary": "ui-icon-#{@options.command}-p" }

      id = "#{@options.uuid}-#{@options.label}"
      @button = @_createButton id, @options.command, @options.label, @options.icon
      @element.append @button
      @button.button {"icons": @options.icons,"text": false}
      @button.addClass @options.cssClass if @options.cssClass
      @button.addClass 'btn-large' if @options.editable.options.touchScreen
      @button.data 'hallo-command', @options.command

      hoverclass = 'ui-state-hover'
      @button.bind 'mouseenter', (event) =>
        if @isEnabled()
          @button.addClass hoverclass
      @button.bind 'mouseleave', (event) =>
        @button.removeClass hoverclass

    _init: ->
      @button = @_prepareButton() unless @button
      @element.append @button
      queryState = (event) =>
        # console.log(@options.command,document.queryCommandState(@options.command))
        return unless @options.command
        return unless ( (event.keyCode >= 33 && event.keyCode <= 40) || event.type == 'mouseup' || event.type == 'hallomodified')
        if ( window.getSelection().anchorNode == null )
          # console.log('empty anchorNode',window.getSelection().anchorNode )
          return;
        try
          # HACK for qt-webkit
          if ( @options.command == 'subscript' || @options.command == 'superscript' )
            # broken command state for sub/sup
            range = window.getSelection().getRangeAt()
            parent = range.startContainer.parentNode
            state = false
            if parent.nodeName == 'SUB' && @options.command == 'subscript'
              state = true
            if parent.nodeName == 'SUP' && @options.command == 'superscript'
              state = true
            @checked state
          else if ( @options.command.indexOf('justify') == 0 )
            # broken justify
            range = window.getSelection().getRangeAt()
            node = range.startContainer
            state = false
            while ( node )
              break if ( node.contentEditable == 'true' )
              if ( typeof node.attributes == 'object' && node.attributes != null)
                for attribute in node.attributes
                  if attribute.nodeName == 'style' && attribute.nodeValue.indexOf('text-align') >= 0
                    style = attribute.nodeValue
                    style = style.replace(/.*text-align:([^;]*).*/,'$1').trim()
                    state = true if ( @options.command.toLowerCase() == 'justify' + style )
                    break
                break if state
              node = node.parentNode
            @checked state
          else
            @checked document.queryCommandState @options.command
        catch e
          console.error(e)
          return
      if typeof @options.command_function == 'function'
        @button.bind 'click', @options.command_function
        #command_function = () =>
        #    range = window.getSelection().getRangeAt()
        #    console.log(range)
        #    if ( range.collapsed )
        #        console.log('TODO: select entire text node')
        #        range.selectNode(range.startContainer)
        #        window.getSelection().addRange(range)
        #    widget.execute(format, false, null)
      else if typeof @options.command == 'string'
        @button.bind 'click', (event) =>
          jQuery('.misspelled').remove()
          # HACK for qt-webkit
          if ( @options.command == 'subscript' || @options.command == 'superscript' )
            range = window.getSelection().getRangeAt()
            node  = jQuery(range.startContainer)
            state = false
            if node.closest('SUB').length && @options.command == 'subscript'
              state = true
            if node.closest('SUP').length && @options.command == 'superscript'
              state = true
            if ( !state )
              @options.editable.execute @options.command
            else
              @options.editable.execute 'removeformat'
          else
            @options.editable.execute @options.command
          queryState
          return false

      return unless @options.queryState

      editableElement = @options.editable.element
      editableElement.bind 'keyup paste change mouseup hallomodified', queryState
      editableElement.bind 'halloenabled', =>
        editableElement.bind 'keyup paste change mouseup hallomodified', queryState
      editableElement.bind 'hallodisabled', =>
        editableElement.unbind 'keyup paste change mouseup hallomodified', queryState

    enable: ->
      # @button.removeAttr 'disabled'
      @button.removeClass('disabled')

    disable: ->
      # @button.attr 'disabled', 'true'
      @button.addClass('disabled')

    isEnabled: ->
      # return @button.attr('disabled') != 'true'
      return @button.hasClass('disabled') != 'true'

    refresh: ->
      if @isChecked
        @button.addClass 'ui-state-active'
      else
        @button.removeClass 'ui-state-active'

    checked: (checked) ->
      @isChecked = checked
      @refresh()

    _createButton: (id, command, label, icon) ->
      button_str = "<button for=\"#{id}\""
      button_str+= " class=\"#{command}_button ui-button ui-widget ui-state-default ui-corner-all\""
      button_str+= " title=\"#{label}\""
      button_str+= " rel=\"#{command}\""
      button_str+= ">#{label}</button>"
      jQuery button_str
      # could we switch this somehow?
      # jQuery "<button for=\"#{id}\" class=\"ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only #{command}_button\" title=\"#{label}\"><span class=\"ui-button-text\"><i class=\"#{icon}\"></i></span></button>"


  jQuery.widget 'IKS.hallobuttonset',
    buttons: null
    _create: ->
      @element.addClass 'ui-buttonset'

    _init: ->
      @refresh()

    refresh: ->
      rtl = @element.css('direction') == 'rtl'
      @buttons = @element.find '.ui-button'
      @buttons.hallobutton 'refresh'
      @buttons.removeClass 'ui-corner-all ui-corner-left ui-corner-right'
      @buttons.filter(':first').addClass if rtl then 'ui-corner-right' else 'ui-corner-left'
      @buttons.filter(':last').addClass if rtl then 'ui-corner-left' else 'ui-corner-right'
)(jQuery)