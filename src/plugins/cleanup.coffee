#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a table to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallocleanup',
    dropdownform: null
    tmpid: 0
    html: null
    options:
      editable: null
      toolbar: null
      uuid: ''
      elements: [
        'rows'
        'cols'
        'border'
      ]
      buttonCssClass: null

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      toolbar.append target
      setup= =>
        console.log('check nugget') if @debug
        #TODO: evaluate problems and removal buttons to the form
      @dropdownform = @_prepareButton setup, target
      buttonset.append @dropdownform
      toolbar.append buttonset

    _clean_nodes: (node,context) =>
       #console.log(node) if @debug
       if ( node[0].nodeType == 1 )
         node.children().each (index,child_node) =>
           cnode = jQuery(child_node)
           #TODO: more attributes
           cnode.removeAttr('style')
           cnode.removeAttr('class')
           cnode.removeAttr('contenteditable')
           cnode.removeAttr('spellcheck')
           cnode.removeAttr('id')
           if ( cnode.is('acronym, applet, big, center, dir, font, frame, frameset, isindex, noframes, s, strike, tt, u') )
             cnode = cnode.replaceWith(cnode.html())
           context._clean_nodes(cnode,context)

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul')

      addButton = (element,event_handler) =>
        button_label = element
        button_tooltip = element
        if ( window.action_list && window.action_list['hallojs_cleanup_' + element] != undefined )
          button_label = window.action_list['hallojs_cleanup_' + element].title
          button_tooltip = window.action_list['hallojs_cleanup_' + element].tooltip
        el = jQuery "<div><button class=\"action_button\" id=\"" + @tmpid+element + "\" title=\"" + button_tooltip+ "\">" + button_label + "</button></div>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addButton "clean_html", =>
        console.log('cleanhtml') if @debug
        jQuery('.misspelled').remove()
        #if @domnode
        #  @domnode.removeSourceDescriptions()
        if utils
          utils.removeForbiddenElements(@options.editable.element)
          #utils.removeBadAttributes(@options.editable.element)
          #utils.removeBadStyles(@options.editable.element)
          #utils.removeCites(@options.editable.element)
          #utils.
          utils.fixNestedElements(@options.editable.element)

        @options.editable.element.find('.cite').remove()
        @_clean_nodes(@options.editable.element,@)
        @dropdownform.hallodropdownform('hideForm')
        nugget = new DOMNugget()
        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element)
      contentAreaUL.append addButton "clean_plain", =>
        jQuery('.misspelled').remove()
        @options.editable.element.find('p,br,div').each (index, item) =>
          jQuery(item).append('\n')
        @options.editable.element.find('.cite').remove() # avoid leftover cites
        plain = @options.editable.element.text()
        plain = plain.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
        plain = '<p>' + plain.replace(/\n/g,'</p>\n<p>') + '</p>'
        plain = plain.replace(/<p><\/p>/g,'')
        @options.editable.element.html(plain)
        @dropdownform.hallodropdownform('hideForm')
        nugget = new DOMNugget()
        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element)

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'cleanup'
      if ( window.action_list && window.action_list['hallojs_cleanup'] != undefined )
        button_label =  window.action_list['hallojs_cleanup'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'cleanup'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
