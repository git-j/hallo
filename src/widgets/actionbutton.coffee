#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
  jQuery.widget 'IKS.halloactionbutton',
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
        return unless @options.command
        try
          if ( @options.command == 'spellcheck' )
            @checked @options.editable.element[0].spellcheck
          else
            @checked document.queryCommandState @options.command
        catch e
          return

      if @options.action
        @button.bind 'click', (event) =>
          jQuery('.misspelled').remove()
          @options.action(event)
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
      @button.removeAttr 'disabled'

    disable: ->
      @button.attr 'disabled', 'true'

    isEnabled: ->
      return @button.attr('disabled') != 'true'

    refresh: ->
      if @isChecked
        @button.addClass 'ui-state-active_'
      else
        @button.removeClass 'ui-state-active_'

    checked: (checked) ->
      @isChecked = checked
      @refresh()

    _createButton: (id, command, label, icon) ->
      button_str = "<button for=\"#{id}\""
      button_str+= " class=\"#{command}_button ui-button ui-widget ui-state-default ui-corner-all\""
      button_str+= " title=\"#{label}\""
      button_str+= " rel=\"#{command}\""
      button_str+= "></button>"
      buttonEl = jQuery button_str
      buttonEl.addClass @options.cssClass if @options.cssClass
      buttonEl.addClass 'btn-large' if @options.editable.options.touchScreen

      button = buttonEl.button { "icons": { "primary": "ui-icon-#{@options.command}-p" }, "text": false }
      button.addClass @options.cssClass if @options.cssClass
      button
      # could we switch this somehow?
      # jQuery "<button for=\"#{id}\" class=\"ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only #{command}_button\" title=\"#{label}\"><span class=\"ui-button-text\"><i class=\"#{icon}\"></i></span></button>"

)(jQuery)