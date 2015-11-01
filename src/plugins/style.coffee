#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# Style Plugin
# Allows to change the content to predefined styles
# the styles have to be approved by DOM.cleanup and need css for correct display
((jQuery) ->
  jQuery.widget 'IKS.hallostyle',
    options:
      editable: null
      toolbar: null
      uuid: ''
      # supported style classes
      styles: [
        'large'
        'normal'
        'small'
        'unreadable'
      ]
      buttonCssClass: null
    # populate toolbar
    # creates a dropdown that is appended to the given toolbar
    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      buttonset.append target
      buttonset.append @_prepareButton target
      toolbar.append buttonset
    # prepare dropdown
    # return jq_dom_element thah will be displayed when the toolbar-icon is triggered
    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"></div>"

      containingElement = @options.editable.element.get(0).tagName.toLowerCase()  
      # add a single dropdown menu entry
      addElement = (element) =>

        el = jQuery "<button class=\"styleselector\" rel=\"#{element}\">#{element}</button>"
        button_label = element
        button_tooltip = ''

        if ( window.action_list && window.action_list['hallojs_style_' + element] != undefined )
          button_label =  window.action_list['hallojs_style_' + element].title
          button_tooltip =  window.action_list['hallojs_style_' + element].tooltip
          tr_span = jQuery('<span>')
          tr_span.html(button_label)
          button_label = tr_span.text()
          tr_span.html(button_tooltip)
          button_tooltip = tr_span.text()
        el.html(button_label)
        el.attr('title', button_tooltip)
        if containingElement is element
          el.addClass 'selected'

        unless containingElement is 'div'
          el.addClass 'disabled'

        # execute the block-formatting commands on clicking the menu-item
        el.bind 'click', =>
          if el.hasClass 'disabled'
            return
          if element == 'none'
            @options.editable.execute 'removeFormat'
            return
          if navigator.appName is 'Microsoft Internet Explorer'
            @options.editable.execute 'FormatBlock', '<'+element.toUpperCase()+'>'
          else
            @options.editable.execute 'formatBlock', element.toUpperCase()
        
        # query the state of the current cursor block and change the toolbar accordingly
        queryState = (event) =>
          block = document.queryCommandValue 'formatBlock'
          if block.toLowerCase() is element
            el.addClass 'selected'
            return
          el.removeClass 'selected'
          
          
        @options.editable.element.bind 'keyup paste change mouseup', queryState

        @options.editable.element.bind 'halloenabled', =>
          @options.editable.element.bind 'keyup paste change mouseup', queryState
        @options.editable.element.bind 'hallodisabled', =>
          @options.editable.element.unbind 'keyup paste change mouseup', queryState

        el
      # build the menu-items for all styles that are configured by options
      for style in @options.styles
        contentArea.append addElement style
      contentArea

    # prepare toolbar button
    # creates a toolbar button
    _prepareButton: (target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'style'
      if ( window.action_list && window.action_list['hallojs_style'] != undefined )
        button_label =  window.action_list['hallojs_style'].title
      buttonElement.hallodropdownbutton
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'style'
        icon: 'icon-text-height'
        target: target
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
