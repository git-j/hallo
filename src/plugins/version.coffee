#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.halloversion",
    options:
      editable: null
      toolbar: null
      uuid: ''
      elements: [
#       'new version' 
      ]
      buttonCssClass: null
      citehandler: null
      current_version: null

    _create: ->
      @options.citehandler = root.citehandler.get()
      @

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      setup= =>
        nugget = new DOMNugget()
        target.find('.version').remove()
        versions = nugget.getNuggetVersions(@options.editable.element)
        if versions.version
          target.append(@_addElement('current version',versions.version))
        if versions.subversions && versions.subversions.length
          versions.subversions.reverse()
          for subversion in versions.subversions
            target.append(@_addElement(subversion.version.display_name,subversion.version))
      buttonset.append target
      buttonset.append @_prepareButton setup, target
      toolbar.append buttonset


    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"></div>"

      for element in @options.elements
        el = @_addElement(element)
        contentArea.append el if el
      contentArea

    _addElement: (element,version) ->
      #console.log(element,version)
      element_text = element
      if ( element_text == 'new version' )
        if ( window.action_list && window.action_list['hallojs_versionnew'] != undefined )
          element_text =  window.action_list['hallojs_versionnew'].title
      if ( element_text == 'current version' )
        if ( window.action_list && window.action_list['hallojs_versioncurrent'] != undefined )
          element_text =  window.action_list['hallojs_versioncurrent'].title
      el = jQuery "<button class=\"version-selector\">#{element_text}</button>"
      el.addClass "selected" if @options.current_version == version
      el.addClass "version" if version
      this_editable = @options.editable
      this_citehandler = @options.citehandler
      @options.citehandler.editable = @options.editable
      el.bind "click", (ev) =>
        nugget = new DOMNugget();
        if ( element == 'new version' )
          nugget.createNewVersion(@options.editable.element)
        else
          @options.editable.element.blur()
          nugget.loadVersion(@options.editable.element,version.loid).done =>
            nugget.updateSourceDescriptionData(@options.editable.element).done =>
              nugget.resetCitations(@options.editable.element)
              @options.editable.element.focus()

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'version'
      if ( window.action_list && window.action_list['hallojs_version'] != undefined )
        button_label =  window.action_list['hallojs_version'].title
      buttonElement.hallodropdownbutton
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'version'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
