#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a image to the editable
((jQuery) ->
  jQuery.widget 'IKS.halloimage',
    dropdownform: null
    dropdownsubform: null
    debug: true
    tmpid: 0
    selected_row: null
    selected_cell: null
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
      setup = (select_target,target_id) =>
        contentId = target_id
        console.log('setup image form',select_target,target_id) if @debug
        return if rangy.getSelection().rangeCount == 0 && typeof select_target == 'undefined'
        @options.editable.undoWaypointStart('image')
        @tmpid='mod_' + (new Date()).getTime()
        selection = rangy.getSelection()
        if ( selection.rangeCount > 0 )
          range = selection.getRangeAt(0)
        else
          range = rangy.createRange()
          range.selectNode(@options.editable.element[0])
          range.collapse()
        @cur_image = null
        @action = 'insert'
        @options.editable.element.find('img').each (index,item) =>
          if ( selection.containsNode(item,true) )
            @cur_image = jQuery(item)
            @cur_image.attr('id',@tmpid)
            @action = 'update'
            return false # break
        if ( @action == 'insert' )
          if ( window.live_target && jQuery(window.live_target).is('img') && jQuery(jQuery(window.live_target),@options.editable).length )
            @cur_image = jQuery(window.live_target)
            window.live_target = null
            @action = 'update'
        if ( @cur_image && @cur_image.length )
          #modify
          @cur_image.attr('id',@tmpid)
        else
          # TODO use wke env to get theme
          @cur_image = jQuery('<img src="../styles/default/icons/types/PubArtwork.png" id="' + @tmpid + '"/>');
          @options.editable.getSelectionStartNode (insert_position) =>
            if ( insert_position.length )
              if ( insert_position.closest('.image_container').length )
                insert_position = insert_position.closest('.image_container');
              @cur_image.insertBefore(insert_position)
            else
              @options.editable.append(@cur_image)
          #console.log(@cur_image)
          @updateImageHTML(contentId)
        @_setupForm()
        recalc = =>
          @recalcHTML(target.attr('id'))
        jQuery('#' + contentId).unbind 'hide', jQuery.proxy(@_destroyForm,@)
        jQuery('#' + contentId).bind 'hide', jQuery.proxy(@_destroyForm,@)
        return true
        window.setTimeout recalc, 300
      @dropdownform = @_prepareButton setup, target
      @dropdownform.hallodropdownform 'bindShow', 'img'
      buttonset.append @dropdownform
      toolbar.append buttonset

    updateImageHTML: (contentId) ->
      image = $('#' + @tmpid)
      return image[0].outerHTML #?

    recalcHTML: (contentId) ->
      @html = @updateImageHTML(contentId)
      @options.editable.store()

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
        @recalcHTML(contentId)
        image = $('#' + @tmpid)
        @options.editable.setContentPosition(image)
        image.removeAttr('id')
        @options.editable.undoWaypointCommit()
        @dropdownsubform.imageSettings('destroy')
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "remove", =>
        image = $('#' + @tmpid)
        image.closest('.image_container').remove()
        image.remove()
        @options.editable.undoWaypointCommit()
        @dropdownsubform.imageSettings('destroy')
        @dropdownform.hallodropdownform('hideForm')
      contentArea

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'image'
      if ( window.action_list && window.action_list['hallojs_image'] != undefined )
        button_label =  window.action_list['hallojs_image'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'image'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement
    _destroyForm: () ->
      @dropdownsubform.imageSettings('destroy')

    _setupForm: () ->
      plugin_options =
        image: this.cur_image
      @dropdownsubform.imageSettings('destroy')
      @dropdownsubform.imageSettings(plugin_options)
      @dropdownsubform.imageSettings('createMenu', [@tmpid]);

)(jQuery)
