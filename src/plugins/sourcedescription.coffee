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
        return true
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
      console.error('unsuppored function')
      replacement = false
      dom = new IDOM()
      has_block_contents = dom.hasBlockElement(old)
      if old.html() != "" && ! has_block_contents
        replacement = "<span class=\"selection\">" + old.html() + "</span>"
      else
        replacement = "<span class=\"selection\">&nbsp;</span>"
      nr = jQuery('<span>' + replacement + '</span>');
      selection = rangy.getSelection();
      if has_block_contents
        if ( selection.rangeCount > 0 )
          range = selection.getRangeAt(0)
          range.setStartAfter(range.endContainer)
        else
          range = rangy.createRange()
          range.selectNode(@options.editable.element[0])
          range.collapse(false)
        range.insertNode(nr[0])
      else
        if ( selection.rangeCount > 0 )
          range = selection.getRangeAt(0)
          range.deleteContents()
        else
          range = rangy.createRange()
          range.selectNode(@options.editable.element[0])
          range.collapse(false)

        range.insertNode(nr[0])
      replacement = false
      replacement

    _addElement: (element, containing_element, publication_type, data) ->
      #debug.log(element,containing_element,publication_type,data,@options)
      if ( element=='__quote' )
        element_text = utils.tr('quote')
        if ( window.action_list && window.action_list['QuoteNugget'] != undefined )
          span = jQuery('<span>')
          span.html(window.action_list['QuoteNugget'].title)
          element_text = span.text()
      else if ( element=='__associate' )
        element_text = utils.tr('associate')
        if ( window.action_list && window.action_list['hallojs_sourcedescription'] != undefined )
          element_text =  window.action_list['hallojs_sourcedescription'].title
        span = jQuery('<span>')
        span.html(element_text)
        element_text = span.text()
      else
        element_text = element
      if ( element_text.length > 48 )
        element_text = element_text.substring(0,48) + '...'
      el = jQuery "<button class=\"publication-selector\"></button>"
      el.text(element_text)
      el.addClass publication_type if publication_type
      el.addClass "selected" if containing_element == element
      el.append "<span class=\"data\" style=\"display:none\">#{data}</span>" if data
      #el.addClass "disabled" if containing_element != 'div'
      has_citation = jQuery(@options.editable.element).find("[data-sourcedescriptionloid=#{data}]").length
      if has_citation
        has_auto_citation = jQuery(@options.editable.element).find("[data-sourcedescriptionloid=#{data}]").hasClass('auto-cite')
        if !has_auto_citation
          el.attr("disabled","disabled")
          el.addClass 'used'
      this_editable = @options.editable
      el.bind "click", (ev) =>
        if element == '__associate'
          window.__start_mini_activity = true
          this_editable.storeContentPosition()
          jQuery('body').hallopublicationselector({'editable':this_editable});
        #else if element == '__quote'
        #  window.__start_mini_activity = true
        #  jQuery('body').halloquoteselector({'editable':this_editable});
        else
          @options.editable.getSelectionStartNode (selection) =>
            if ( selection.length )
              dom = new IDOM()
              nugget = new DOMNugget();

              saved_selection = rangy.saveSelection()
              @options.editable.getSelectionNode (selection_common) =>
                selection_html = @options.editable.getSelectionHtml()
                has_block_contents = dom.hasBlockElement(jQuery('<span>' + selection_html + '</span>'))

                if ( selection_html != '' && ! has_block_contents )
                  replacement = "<span class=\"citation\">" + selection_html + "</span>"
                else
                  replacement = ""
                replacement+= "<span class=\"cite\"><span class=\"csl\">#{element}</span><span class=\"Z3988\" data-sourcedescriptionloid=\"#{data}\"><span style=\"display:none;\">&#160;</span></span>"
                replacement_node = jQuery('<span></span>').append(replacement)
                omc_settings.getSettings().done (settings) =>
                  nugget.getDOMSourceDescriptionsIndex(@options.editable.element,settings).done (sourcedescription_index) =>
                    z3988 = new Z3988();
                    z3988_node = jQuery('.Z3988',replacement_node)[0];
                    co = new Z3988ContextObject();
                    co.sourcedescription = sourcedescription_index.index_loid[data];
                    if ( typeof co == 'undefined' )
                      co.sourcedescription = {loid:data}
                    nugget.addDerivedSourceDescriptionAttributes(z3988_node,co.sourcedescription);
                    co.referent.setByValueMetadata(co.referent.fromCSL(nugget.getSourceDescriptionCSL(co.sourcedescription)));
                    co.referent.setPrivateData((new Z3988SourceDescription()).toPrivateData(co.sourcedescription));
                    delete co.sourcedescription;
                    z3988.setFormat(new Z3988KEV());
                    z3988.attach(z3988_node,co);
                    if ( has_block_contents )
                      utils.info(utils.tr('warning selected block contents'))
                      selection_common.append(replacement_node.contents())
                    else
                      selection = rangy.getSelection()
                      if ( selection.rangeCount > 0 )
                        range = selection.getRangeAt(0)
                        range.deleteContents()
                        range.insertNode(replacement_node[0])
                      else
                        selection_common.append(replacement_node.contents())
                    rangy.removeMarkers(saved_selection)
            else
              utils.info(utils.tr('no selection'))
          #console.log(this_editable.element)
          nugget = new DOMNugget()
          #debug.log('sdc::addElement',this_editable)
          nugget.updateSourceDescriptionData(this_editable.element).done =>
            nugget.resetCitations(@options.editable.element).done =>
              @options.editable.restoreContentPosition()

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
