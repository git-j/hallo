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
        'update from manage'
        'update to manage'
      ]
      buttonCssClass: null
      current_version: null
      in_document: false

    _create: ->
      @

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      @options.in_document = @options.editable.element.closest('.Document').length > 0
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      setup= =>
        nugget = new DOMNugget()
        target.find('.version').remove()
        return if @options.in_document
        @options.current_version = @options.editable.element.closest('.nugget').attr('id');
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
        return true
      buttonset.append target
      buttonset.append @_prepareButton setup, target
      toolbar.append buttonset


    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"></div>"

      for element in @options.elements
        if !@options.in_document
          continue if element == 'update to manage'
          continue if element == 'update from manage'
        el = @_addElement(element)
        contentArea.append el if el
      contentArea

    _addElement: (element,version) ->
      #console.log(element,version)
      element_text = element
      if ( element_text == 'new version' )
        if ( window.action_list && window.action_list['hallojs_version_new_version'] != undefined )
          element_text =  window.action_list['hallojs_version_new_version'].title
      if ( element_text == 'current version' )
        if ( window.action_list && window.action_list['hallojs_version_current_version'] != undefined )
          element_text =  window.action_list['hallojs_version_current_version'].title
      if ( element_text == 'update to manage' )
        if ( window.action_list && window.action_list['hallojs_version_update_to_manage'] != undefined )
          element_text =  window.action_list['hallojs_version_update_to_manage'].title
      if ( element_text == 'update from manage' )
        if ( window.action_list && window.action_list['hallojs_version_update_from_manage'] != undefined )
          element_text =  window.action_list['hallojs_version_update_from_manage'].title
      if ( element_text.length > 40 )
        element_text = element_text.substr(0,20) + '...' + element_text.substr(element_text.length-20,20)
      el = jQuery "<button class=\"version-selector\"></button>"
      el.text(element_text)
      el.addClass "selected" if version && @options.current_version == version.variant_loid
      el.addClass "version" if version
      this_editable = @options.editable
      el.bind "click", (ev) =>
        nugget = new DOMNugget()
        if ( element == 'new version' )
          @options.editable.element.blur()
          make_current = true
          if (@options.in_document)
            @options.editable.element.blur()
            nugget.updateVersionReferenceNewVersion(@options.editable.element)
          else
            nugget.createNewVersion(@options.editable.element)

        else if ( element == 'update from manage' )
          @options.editable.element.blur()
          nugget.updateVersionReferenceFromVariation(@options.editable.element)

        else if ( element == 'update to manage' )
          @options.editable.element.blur()
          nugget.updateVariationFromVersionReference(@options.editable.element).done () =>
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
