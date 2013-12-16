#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
  jQuery.widget 'IKS.hallodropdownform',
    button: null
    debug: false

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
      target.addClass 'dropdown-form-' + @options.command

      target.hide()
      @button = @_prepareButton() unless @button

      @button.bind 'click', =>
        jQuery('.misspelled').remove()
        if target.hasClass 'open'
          @_hideTarget()
          return
        @_showTarget()
      target.bind 'bindShowTrigger', (event) =>
        # trigger handler to get correct this from live() events
        # console.log('dropdownform show handler',event,this)# if @debug
        # this should be correct
        toolbar = jQuery('.hallotoolbar').eq(0)
        return if ( !toolbar.length )
        @options.target = toolbar.find('.dropdown-form-' + @options.command)
        return if ( !@options.target.length )
        @button = toolbar.find('.' + @options.command + '_button')
        if ( window.live_target )
          @_showTarget(window.live_target)
          window.live_target = null
        else
          @_showTarget(event.target)


      @element.append @button
    bindShowHandler: (event) ->
      @_showTarget(event.target)
    bindShow: (selector) ->
      event_name = 'click'
      console.log('bindShow:',selector,event_name) if @debug
      jQuery(document).delegate selector, event_name, =>
      #jQuery(selector).live event_name, =>
        console.log(event.target) if @debug
      #   # find the toolbar and reset the button/@options.target members
      #   # they were destroyed when the user changes the editable
      #   # this is NOT as expected!
        if ( jQuery(event.target).closest('.dropdown-form-' + @options.command).length )
          return
        toolbar = jQuery('.hallotoolbar').eq(0)
        return if ( !toolbar.length )
        target = toolbar.find('.dropdown-form-' + @options.command)
      #   window.live_target = event.target # HACK
        target.trigger('bindShowTrigger')

    _showTarget: (select_target) ->
      console.log('dropdownform target show',select_target) if @debug
      jQuery(".dropdown-form:visible, .dropdown-menu:visible").each (index,item) ->
        jQuery(item).trigger('hide')

      target_id = jQuery(@options.target).attr('id')
      target = jQuery('#' + target_id)
      @options.editable.storeContentPosition()
      setup_success = @options.setup(select_target,target_id) if @options.setup
      console.log('setup success:',setup_success) if @debug
      if ( ! setup_success )
        @_hideTarget()
        return
      target.addClass 'open'
      target.show()
      # must be visible for correct positions
      @_updateTargetPosition()
      if ( target.find('textarea').length )
        target.find('textarea:first').focus()
      else
        target.find('input:first').focus()
      target.bind 'hide', =>
        @_hideTarget()
 
    _hideTarget: ->
      console.log('target remove') if @debug
      target = jQuery @options.target
      if ( target.hasClass 'open' )
        target.removeClass 'open'
        jQuery("select",target).selectBox('destroy')
        target.hide()
        @options.editable.restoreContentPosition()

    hideForm: ->
      jQuery(".dropdown-form:visible, .dropdown-menu:visible").each (index,item) ->
        console.log('index',index) if @debug
        jQuery(item).trigger('hide')
      @options.editable.restoreContentPosition()

    _updateTargetPosition: ->
      target_id = jQuery(@options.target).attr('id')
      target = jQuery('#' + target_id)
      button_id = jQuery(@button).attr('id')
      button = jQuery('#' + button_id)
      button_position = button.position()
      top = button_position.top
      left = button_position.left

      top += button.outerHeight()
      target.css 'top', top
      last_button = target.closest('.hallotoolbar').find('button:last')
      if last_button.length
        last_button_pos =last_button.position().left
        last_button_pos+=last_button.width()
      if ( last_button.length && left + target.width() > last_button_pos )
        left = left - target.width() + last_button.width()

      if ( left < 0 )
        left = 0
      target.css('left', left);
      console.log('target position:',target.position(),top,left,last_button) if @debug
      console.log(target.width(),last_button.width()) if @debug

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
