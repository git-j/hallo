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
        if target.hasClass 'open'
          @_hideTarget()
          return
        @_showTarget()

      @options.editable.element.bind 'hallodeactivated', =>
        @_hideTarget()

      @element.append @button

    _showTarget: ->
      jQuery(".dropdownform").each (index,item) ->
        jQuery(item).hide()
      target = jQuery @options.target
      @options.setup() if @options.setup
      @_updateTargetPosition()
      @storeContentPosition()
      target.addClass 'open'
      target.show()
      target.find('input:first').focus()

    _hideTarget: ->
      target = jQuery @options.target
      target.removeClass 'open'
      target.hide()
      @restoreContentPosition

    hideForm: ->
      jQuery('.dropdown-form').hide()
      jQuery('.dropdown-form').removeClass('open')
      @restoreContentPosition

    storeContentPosition: ->
      sel = window.getSelection();
      if sel.rangeCount
        @content_range = sel.getRangeAt(0);

    restoreContentPosition: ->
      sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(@content_range);
      @options.editable.element.focus()

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