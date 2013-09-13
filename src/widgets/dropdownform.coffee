#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
  jQuery.widget 'IKS.hallodropdownform',
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
      target.addClass 'dropdown-form'

      target.hide()
      @button = @_prepareButton() unless @button

      @button.bind 'click', =>
        jQuery('.misspelled').remove()
        if target.hasClass 'open'
          @_hideTarget()
          return
        @_showTarget()

      @options.editable.element.bind 'hallodeactivated', =>
        @_hideTarget()

      @element.append @button
    bindShowHandler: (event) ->
      @_showTarget(event.target)
    bindShow: (selector) ->
      event_name = 'click'
      if ( window._life_map && window._life_map[selector + event_name + @bindShowHandler] )
        return
      if ( typeof window._life_map == 'undefined' )
        window._life_map = {}
      window._life_map[selector + event_name + @bindShowHandler] = true;
      jQuery(selector).live event_name, =>
        @bindShowHandler(event)

    _showTarget: (select_target) ->
      jQuery(".dropdown-form:visible, .dropdown-menu:visible").each (index,item) ->
        jQuery(item).trigger('hide')

      target = jQuery @options.target
      @options.editable.storeContentPosition()
      setup_success = @options.setup(select_target) if @options.setup
      if ( ! setup_success )
        @_hideTarget()
        return
      @_updateTargetPosition()
      target.addClass 'open'
      target.show()
      if ( target.find('textarea').length )
        target.find('textarea:first').focus()
      else
        target.find('input:first').focus()
    _hideTarget: ->
      target = jQuery @options.target
      target.removeClass 'open'
      jQuery("select",target).selectBox('destroy')
      target.hide()
      @options.editable.restoreContentPosition()

    hideForm: ->
      jQuery(".dropdown-form:visible, .dropdown-menu:visible").each (index,item) ->
        jQuery(item).trigger('hide')
      @options.editable.restoreContentPosition()

    _updateTargetPosition: ->
      target = jQuery @options.target
      {top, left} = @button.position()
      top += @button.outerHeight()
      target.css 'top', top
      last_button = @options.target.closest('.hallotoolbar').find('button:last')
      if last_button.length
        last_button_pos =last_button.position().left
        last_button_pos+=last_button.width()
      if ( last_button.length && left+target.width() > last_button_pos )
        target.css 'left', left - target.width()+last_button.width()
      else
        target.css 'left', left

    _prepareButton: ->
      id = "#{@options.uuid}-#{@options.command}"
      button_str = "<button id=\"#{id}\" data-toggle=\"dropdown\""
      button_str+= " class=\"#{@options.command}_button ui-button ui-widget ui-state-default ui-corner-all\""
      button_str+= " data-target=\"##{@options.target.attr('id')}\""
      button_str+= " title=\"#{@options.label}\" rel=\"#{@options.command}\""
      button_str+= "></button>"
      buttonEl = jQuery button_str;
      buttonEl.addClass @options.cssClass if @options.cssClass
      buttonEl.addClass 'btn-large' if @options.editable.options.touchScreen

      button = buttonEl.button { "icons": { "primary": "ui-icon-#{@options.command}-p" }, "text": false }
      button.addClass @options.cssClass if @options.cssClass
      button

)(jQuery)
