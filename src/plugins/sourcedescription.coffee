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
        'quote'
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
      contentArea.css {'background-color':'white'}
      containingElement = @options.editable.element.get(0).tagName.toLowerCase()

      for element in @options.elements
        contentArea.append @_addElement(element,containingElement)
      contentArea

    _addElement: (element, containing_element, publication_type, data) ->
      #debug.log(element,containing_element,publication_type,data)
      el = jQuery "<div class=\"menu-item\">#{element}</div>"
      el = jQuery "<button class=\"publication-selector\">#{element}</button>"
      el.addClass publication_type if publication_type
      el.addClass "selected" if containing_element == element
      el.append "<span class=\"data\" style=\"display:none\">#{data}</span>" if data
      el.addClass "disabled" if containing_element != 'div'
      this_editable = @options.editable
      this_citehandler = @options.citehandler
      el.bind "click", (ev) =>
        scb = (parent, old) ->
          replacement = false
          if element == "quote"
            # select which publication
            if ( !parent.attr('contenteditable') && parent.hasClass(element))
              parent.removeClass element
              replacement
            replacement = "<span class=\"#{element}\">" + old.html() + "</span>"
          else
            if old.html() != ""
              replacement = "<span class=\"citation\">" + old.html() + "</span>"
            else
              replacement = ""
            replacement+= "<span class=\"cite sourcedescription-#{data}\">#{element}</span>"
          replacement
        #/scb
        this_editable.replaceSelectionHTML scb
        nugget = new DOMNugget()
        debug.log('sdc::addElement',this_editable)
        nugget.updateSourceDescriptionData(this_editable.element)

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      buttonElement.hallodropdownbutton
        uuid: @options.uuid
        editable: @options.editable
        label: 'block'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
