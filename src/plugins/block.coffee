#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# Blockquote Plugin
# allows to change the current selection/ current block outer element
# provides a dropdown-menu-item that highlights the current block-type if any
# beware: changing the block-type over multiple blocks may result in dissortion
((jQuery) ->
  jQuery.widget 'IKS.halloblock',
    options:
      editable: null
      toolbar: null
      uuid: ''
      # supported block elements
      elements: [
        'h1'
        'h2'
        'h3'
        'p'
#        'pre'
#        'blockquote'
#        'none'
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
        el = jQuery "<button class='blockselector'>#{element}</button>"
        
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
      # build the menu-items for all elements that are configured by options
      for element in @options.elements
        contentArea.append addElement element
      contentArea

    # prepare toolbar button
    # creates a toolbar button
    _prepareButton: (target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'block'
      if ( window.action_list && window.action_list['hallojs_block'] != undefined )
        button_label =  window.action_list['hallojs_block'].title
      buttonElement.hallodropdownbutton
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'block'
        icon: 'icon-text-height'
        target: target
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
