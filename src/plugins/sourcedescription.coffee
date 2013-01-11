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
        '__quote'
      ]
      buttonCssClass: null
      citehandler: null

    _create: ->
      @options.citehandler = root.citehandler.get()
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

      for element in @options.elements
        el = @_addElement(element,containingElement)
        contentArea.append el if el
      contentArea

    _addElement: (element, containing_element, publication_type, data) ->
      #debug.log(element,containing_element,publication_type,data,@options)
      if ( element=='__quote' ) 
        element_text = utils.tr('quote')
      else
        element_text = element
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
      this_citehandler = @options.citehandler
      @options.citehandler.editable = @options.editable
      el.bind "click", (ev) =>
        if element == '__quote'
          sel = window.getSelection();
          if sel
            range = null
            #console.log(sel,sel.getRangeAt())
            if sel.rangeCount > 0
              range = sel.getRangeAt(0)
            $('body').hallopublicationselector({'editable':this_editable,'range':range});
        else
          scb = (parent, old) ->
            replacement = false
            has_block_contents = old.find('address, article, aside, audio, blockquote, canvas, dd, div, dl, fieldset, figcaption, figure, footer, form, h1, h2, h3, h4, h5, header, hgroup, hr, noscript, hr, output, p, pre, section, table, tfoot, ul, video').length > 0
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
            replacement
          #/scb
          if jQuery(@options.editable.element).find(".sourcedescription-#{data}").length
            jQuery(@options.editable.element).find(".sourcedescription-#{data}").remove()
          this_editable.replaceSelectionHTML scb
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
