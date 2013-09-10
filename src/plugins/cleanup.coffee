#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a table to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallocleanup',
    dropdownform: null
    tmpid: 0
    html: null
    debug: false
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
        return true
      @dropdownform = @_prepareButton setup, target
      buttonset.append @dropdownform
      toolbar.append buttonset

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
        dom = new IDOM()
        #if @domnode
        #  @domnode.removeSourceDescriptions()
        if dom
          #utils.removeBadAttributes(@options.editable.element)
          #utils.removeBadStyles(@options.editable.element)
          #utils.removeCites(@options.editable.element)
          #utils.
          dom.fixNesting(@options.editable.element)
          dom.fixDeprecated(@options.editable.element)
          dom.fixAttributes(@options.editable.element)
          dom.removeGarbage(_this.options.editable.element);
          @options.editable.element.html(@options.editable.element.html().replace(/&nbsp;/g,' '));

        #@options.editable.element.find('.cite').remove()
        @dropdownform.hallodropdownform('hideForm')
        @options.editable.store()
        nugget = new DOMNugget()
        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element)


      contentAreaUL.append addButton "clean_plain", =>
        jQuery('.misspelled').remove()
        dom = new IDOM()
        dom.plainTextParagraphs(@options.editable.element)
        @dropdownform.hallodropdownform('hideForm')
        @options.editable.store()
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
