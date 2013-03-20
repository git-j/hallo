#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.hallotextselection",
    _start_container: null
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null
      current_version: null
      in_document: false

    _create: ->
      @

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      setup= =>
        # populate with available actions
        target.find('.element-selector').remove()
        selection = window.getSelection()
        return if !selection.rangeCount
        range = selection.getRangeAt()
        range_jq = $(range.cloneContents())
        range_ca = null
        @start_container = null
        @_find_start_container(@options.editable.element[0], range.startContainer)
        if ( @start_container )
          range_ca = $(@start_container).closest('.citation')
          is_citation = range_ca.hasClass('citation')
          is_direct_citation = range_ca.hasClass('direct_citation')
          is_indirect_citation = range_ca.hasClass('indirect_citation')
        else
          is_citation = false
          is_direct_citation = false
          is_indirect_citation = false
        has_selection = range_jq.text() != ''

        target.append(@_addElement('copy')) if has_selection
        target.append(@_addElement('cut')) if has_selection
        target.append(@_addElement('paste'))
        target.append(@_addElement('as_name')) if has_selection
        target.append(@_addElement('as_tag')) if has_selection
        target.append(@_addElement('indirect_citation')) if (has_selection && is_direct_citation)
        target.append(@_addElement('direct_citation')) if (has_selection && is_indirect_citation)
        target.append(@_addElement('remove_citation')) if (has_selection && is_citation)
      buttonset.append target
      buttonset.append @_prepareButton setup, target
      toolbar.append buttonset

    _find_start_container: (node,search_node) ->
      if ( @start_container ) 
        return
      if ( node == search_node )
        @start_container = node
      if ( node.childNodes )
        for child_node in node.childNodes
          @_find_start_container(child_node,search_node)

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"></div>"

      contentArea
    _elementText: (element) ->
      if ( window.action_list && window.action_list['hallojs_textselection_' + element] != undefined )
        element_text =  window.action_list['hallojs_textselection_' + element].title


    _addElement: (element) ->
      #console.log(element)
      element_text = @_elementText(element)
      el = jQuery "<button class=\"element-selector\">#{element_text}</button>"
      this_editable = @options.editable
      el.bind "click", (ev) =>
        selection = window.getSelection()
        return if !selection.rangeCount
        range = selection.getRangeAt()
        range_jq = $(range.cloneContents())
        nugget = new DOMNugget();
        if ( element == 'copy' )
          document.execCommand('copy');
        else if ( element == 'cut' )
          document.execCommand('cut');
        else if ( element == 'paste' )
          document.execCommand('paste');
        else if ( element == 'as_name' )
          console.log(element)
          if ( range_jq.text() != '' )
            nugget.rename(@options.editable.element, range_jq.text())
        else if ( element == 'as_tag' )
          if ( range_jq.text() != '' )
            nugget.createTag(@options.editable.element, range_jq.text())
        else if ( element == 'direct_citation')
          console.log('NOT IMPLEMENTED:',element)
        else if ( element == 'indirect_citation')
          console.log('NOT IMPLEMENTED:',element)
        else if ( element == 'remove_citation')
          @start_container = null
          @_find_start_container(@options.editable.element[0],range.startContainer)
          $(@start_container).closest('.citation').removeClass('citation')

        @options.editable.element.blur()
        @options.editable.element.focus()

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'textselection'
      if ( window.action_list && window.action_list['hallojs_textselection'] != undefined )
        button_label =  window.action_list['hallojs_textselection'].title
      buttonElement.hallodropdownbutton
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'textselection'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
