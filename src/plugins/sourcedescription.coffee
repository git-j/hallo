#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallosourcedescription',
    options:
      editable: null
      toolbar: null
      uuid: ''
      elements: [
      #  '__quote'
        '__associate'
      ]
      buttonCssClass: null

    _create: ->
      @

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      setup= =>
        root.citehandler.get().setupSourceDescriptions(target, @options.editable, jQuery.proxy(@._addElement,@))
      buttonset.append target
      buttonset.append @_prepareButton setup, target
      toolbar.append buttonset


    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"></div>"
      containingElement = @options.editable.element.get(0).tagName.toLowerCase()
      in_document = @options.editable.element.closest('.Document').length > 0

      for element in @options.elements
        continue if !in_document && element == "__quote"
        el = @_addElement(element,containingElement)
        contentArea.append el if el
      contentArea
    _keep_selection_replace_callback: (parent, old) ->
       replacement = false
       has_block_contents = utils.hasBlockElement(old)
       if old.html() != "" && ! has_block_contents
         replacement = "<span class=\"selection\">" + old.html() + "</span>"
       else
         replacement = "<span class=\"selection\">&nbsp;</span>"
       nr = $('<span>' + replacement + '</span>');
       if has_block_contents
         range = window.getSelection().getRangeAt()
         range.setStartAfter(range.endContainer)
         range.insertNode(nr[0])
       else
         range = window.getSelection().getRangeAt()
         range.deleteContents()
         range.insertNode(nr[0])
       replacement = false
       replacement

    _addElement: (element, containing_element, publication_type, data) ->
      #debug.log(element,containing_element,publication_type,data,@options)
      if ( element=='__quote' )
        element_text = utils.tr('quote')
        if ( window.action_list && window.action_list['QuoteNugget'] != undefined )
          element_text =  window.action_list['QuoteNugget'].title
      else if ( element=='__associate' )
        element_text = utils.tr('associate')
        if ( window.action_list && window.action_list['hallojs_sourcedescription'] != undefined )
          element_text =  window.action_list['hallojs_sourcedescription'].title
      else
        element_text = element
      if ( element_text.length > 48 )
        element_text = element_text.substring(0,48) + '...'
      el = jQuery "<button class=\"publication-selector\">#{element_text}</button>"
      el.addClass publication_type if publication_type
      el.addClass "selected" if containing_element == element
      el.append "<span class=\"data\" style=\"display:none\">#{data}</span>" if data
      #el.addClass "disabled" if containing_element != 'div'
      has_citation = jQuery(@options.editable.element).find(".sourcedescription-#{data}").length
      if has_citation
        has_auto_citation = jQuery(@options.editable.element).find(".sourcedescription-#{data}").hasClass('auto-cite')
        if !has_auto_citation
          el.attr("disabled","disabled")
          el.addClass 'used'
      this_editable = @options.editable
      el.on "click", (ev) =>
        if element == '__associate'
          this_editable.replaceSelectionHTML @_keep_selection_replace_callback
          window.__start_mini_activity = true
          $('body').hallopublicationselector({'editable':this_editable});
        else if element == '__quote'
          this_editable.replaceSelectionHTML @_keep_selection_replace_callback
          window.__start_mini_activity = true
          $('body').halloquoteselector({'editable':this_editable});
        else
          scb = (parent, old) ->
            replacement = false
            has_block_contents = utils.hasBlockElement(old)
            #console.log(old,has_block_contents)
            if old.html() != "" && ! has_block_contents
              replacement = "<span class=\"citation\">" + old.html() + "</span>"
            else
              replacement = ""
            replacement+= "<span class=\"cite sourcedescription-#{data}\">#{element}</span>"
            if ( has_block_contents )
              # wrong range:document.execCommand('insertHTML',false,replacement)
              utils.info(utils.tr('warning selected block contents'))
              window.getSelection().removeAllRanges()
              parent.append(replacement)
              replacement = false
            #console.log(replacement)
            replacement
          #/scb
          #modifies dom invalidates range
          #if @options.editable.element.find(".sourcedescription-#{data}").length
          #  @options.editable.element.find(".sourcedescription-#{data}").remove()
          this_editable.replaceSelectionHTML scb
          #console.log(this_editable.element)
          nugget = new DOMNugget()
          #debug.log('sdc::addElement',this_editable)
          nugget.updateSourceDescriptionData(this_editable.element).done =>
            nugget.resetCitations(@options.editable.element)

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'sourcedescription'
      if ( window.action_list && window.action_list['hallojs_sourcedescription'] != undefined )
        button_label =  window.action_list['hallojs_sourcedescription'].title
      buttonElement.hallodropdownbutton
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'sourcedescription'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
