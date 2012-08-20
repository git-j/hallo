#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
  jQuery.widget 'IKS.hallodropdownbutton',
    button: null

    options:
      uuid: ''
      label: null
      icon: null
      editable: null
      target: ''    # dropdown
      setup: null
      cssClass: null

    _create: ->
      @options.icon ?= "icon-#{@options.label.toLowerCase()}"

    _init: ->
      target = jQuery @options.target
      target.css 'position', 'absolute'
      target.addClass 'dropdown-menu'

      target.hide()
      @button = @_prepareButton() unless @button

      @button.bind 'click', =>
        if target.hasClass 'open'
          @_hideTarget()
          return
        @_showTarget()

      target.bind 'click', =>
        @_hideTarget()

      @options.editable.element.bind 'hallodeactivated', =>
        @_hideTarget()

      @element.append @button

    _showTarget: ->
      target = jQuery @options.target
      @options.setup() if @options.setup
      @_updateTargetPosition()
      target.addClass 'open'
      target.show()

    _hideTarget: ->
      target = jQuery @options.target
      target.removeClass 'open'
      target.hide()

    _updateTargetPosition: ->
      target = jQuery @options.target
      {top, left} = @button.position()
      top += @button.outerHeight()
      target.css 'top', top
      target.css 'left', left - 20

    _prepareButton: ->
      id = "#{@options.uuid}-#{@options.label}"
      button_str = "<button id=\"#{id}\" data-toggle=\"dropdown\""
      button_str+= " class=\"#{@options.label}_button ui-button ui-widget ui-state-default ui-corner-all\""
      button_str+= " data-target=\"##{@options.target.attr('id')}\""
      button_str+= " title=\"#{@options.label}\" rel=\"#{@options.label}\""
      button_str+= "></button>"
      buttonEl = jQuery button_str;
      buttonEl.addClass @options.cssClass if @options.cssClass
      buttonEl.addClass 'btn-large' if @options.editable.options.touchScreen

      button = buttonEl.button { "icons": { "primary": "ui-icon-#{@options.label}-p" }, "text": false }
      button.addClass @options.cssClass if @options.cssClass
      button

)(jQuery)
