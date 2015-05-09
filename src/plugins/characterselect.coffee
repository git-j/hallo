#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a character to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallocharacterselect',
    dropdownform: null
    dropdownsubform: null
    debug: true
    tmpid: 0
    selected_row: null
    selected_cell: null
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      toolbar.append target
      setup = (select_target,target_id) =>
        contentId = target_id
        console.log('setup characterselect form',select_target,target_id) if @debug
        return if rangy.getSelection().rangeCount == 0 && typeof select_target == 'undefined'
        @options.editable.undoWaypointStart('character')
        @tmpid = 'mod_' + (new Date()).getTime()
        @selected_text = ''
        selection = rangy.getSelection()
        if ( selection.rangeCount > 0 )
          range = selection.getRangeAt(0)
          @selected_text = $(range.cloneContents()).text()
          range.deleteContents()
        else
          range = rangy.createRange()
          range.selectNode(@options.editable.element[0])
          range.collapse()
        @original_selected_text = @selected_text
        # TODO use wke env to get theme
        @cur_characters = jQuery('<span class="characters">')
        @cur_characters.attr('id',@tmpid)
        @cur_characters.text(@original_selected_text)
        @options.editable.getSelectionStartNode (insert_position) =>
          if ( insert_position.length )
            @cur_characters.insertBefore(insert_position)
          else
            @options.editable.append(@cur_characters)
        #console.log(@cur_characters)
        @_setupForm(contentId)
        jQuery('#' + contentId).unbind 'hide', jQuery.proxy(@_destroyForm,@)
        jQuery('#' + contentId).bind 'hide', jQuery.proxy(@_destroyForm,@)
        return true
      @dropdownform = @_prepareButton setup, target
      buttonset.append @dropdownform
      toolbar.append buttonset

    _prepareDropdown: (contentId) ->
      contentArea = jQuery '<div id="' + contentId + '"><div class="subform"></div><ul></ul></div>'
      contentAreaUL = contentArea.find('ul');
      @dropdownsubform = contentArea.find('.subform');

      addButton = (element,event_handler) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><button class=\"action_button\" id=\"" + @elid + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el

      contentAreaUL.append addButton "apply", =>
        @cur_characters.text(@dropdownsubform.characterSelect('value'))
        @options.editable.setContentPosition(@cur_characters)
        @cur_characters.removeAttr('id')
        @cur_characters.contents().unwrap()
        @options.editable.undoWaypointCommit()
        @dropdownsubform.characterSelect('destroy')
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "Cancel", =>
        @cur_characters.text(@original_selected_text)
        @options.editable.setContentPosition(@cur_characters)
        @cur_characters.removeAttr('id')
        @cur_characters.contents().unwrap()
        @options.editable.undoWaypointCommit()
        @dropdownsubform.characterSelect('destroy')
        @dropdownform.hallodropdownform('hideForm')
      contentArea

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'characterselect'
      if ( window.action_list && window.action_list['hallojs_characterselect'] != undefined )
        button_label =  window.action_list['hallojs_characterselect'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'characterselect'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement
    _destroyForm: () ->
      @dropdownsubform.characterSelect('destroy')

    _setupForm: (contentId) ->
      plugin_options =
        characters: @selected_text
      @dropdownsubform = $('#' + contentId + ' .subform');
      jQuery('select').selectBox('destroy')
      jQuery('.selectbox-dropdown-menu').remove()
      @dropdownsubform.characterSelect(plugin_options)
      @dropdownsubform.characterSelect('render')

)(jQuery)
