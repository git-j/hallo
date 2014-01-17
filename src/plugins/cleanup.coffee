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
        el = jQuery "<li><div><button class=\"action_button\" id=\"" + @tmpid+element + "\" title=\"" + button_tooltip+ "\">" + button_label + "</button></div></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addButton "clean_html", =>
        @options.editable.storeContentPosition()
        @options.editable.undoWaypointStart('cleanup')
        console.log('cleanhtml') if @debug
        dom = new IDOM()
        nugget = new DOMNugget()
        #if @domnode
        #  @domnode.removeSourceDescriptions()
        if dom
          #utils.removeBadAttributes(@options.editable.element)
          #utils.removeBadStyles(@options.editable.element)
          #utils.removeCites(@options.editable.element)
          #utils.
          nugget.prepareTextForEdit(@options.editable.element); # calls dom.clean
          @options.editable.element.html(@options.editable.element.html().replace(/&nbsp;/g,' '));

        #@options.editable.element.find('.cite').remove()
        @dropdownform.hallodropdownform('hideForm')
        @options.editable.store()

        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element).done =>
            @options.editable.restoreContentPosition()
            @options.editable.undoWaypointCommit()
            if ( typeof MathJax != 'undefined' )
              MathJax.Hub.Queue(['Typeset',MathJax.Hub])


      contentAreaUL.append addButton "clean_plain", =>
        @options.editable.storeContentPosition()
        @options.editable.undoWaypointStart('cleanup')
        dom = new IDOM()
        nugget = new DOMNugget()
        nugget.prepareTextForEdit(@options.editable.element); # calls dom.clean
        dom.plainTextParagraphs(@options.editable.element)
        @options.editable.store()
        nugget.prepareTextForEdit(@options.editable.element); # calls dom.clean / math prepare

        @dropdownform.hallodropdownform('hideForm')
        nugget = new DOMNugget()
        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element).done => 
            @options.editable.restoreContentPosition()
            @options.editable.undoWaypointCommit()
            if ( typeof MathJax != 'undefined' )
              MathJax.Hub.Queue(['Typeset',MathJax.Hub])

      contentArea

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
