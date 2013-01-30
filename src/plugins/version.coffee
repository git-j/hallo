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
        'new version'
      ]
      buttonCssClass: null
      current_version: null
      in_document: false

    _create: ->
      @

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      @options.in_document = @options.editable.element.closest('.Document').length > 0
      return if ( @options.in_document )
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      setup= =>
        nugget = new DOMNugget()
        target.find('.version').remove()
        @options.current_version = @options.editable.element.closest('.nugget').attr('id');
        @options.in_document = @options.editable.element.closest('.Document').length > 0
        versions = nugget.getNuggetVersions(@options.editable.element)
        if versions.version
          display_name = versions.version.display_name
          target.append(@_addElement(display_name,versions.version))
        setupSubVersions = (versions) =>
          if versions.subversions && versions.subversions.length
            versions.subversions.reverse()
            for subversion in versions.subversions
              display_name = subversion.version.display_name
              target.append(@_addElement(display_name,subversion.version))
              setupSubVersions(subversion)
        setupSubVersions(versions)
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
      if ( element_text.length > 40 )
        element_text = element_text.substr(0,20) + '...' + element_text.substr(element_text.length-20,20)
      el = jQuery "<button class=\"version-selector\">#{element_text}</button>"
      el.addClass "selected" if version && @options.current_version == version.variant_loid
      el.addClass "version" if version
      this_editable = @options.editable
      el.bind "click", (ev) =>
        nugget = new DOMNugget();
        if ( element == 'new version' )
          @options.editable.element.blur()
          make_current = !@options.in_document # do not make the new version current when editable is in document
          nugget.createNewVersion(@options.editable.element.closest('.nugget').attr('id'),@options.editable.element.html(),make_current).done (new_version) =>
            nugget.loadVersion(@options.editable.element,new_version.variant.loid).done =>
              nugget.updateSourceDescriptionData(@options.editable.element).done =>
                nugget.resetCitations(@options.editable.element)
                @options.editable.element.focus()
        else
          @options.editable.element.blur()
          nugget.loadVersion(@options.editable.element,version.variant_loid).done =>
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
