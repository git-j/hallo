#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallosourcedescriptioneditor',
    widget: null
    selectables: ''
    options:
      editable: null
      toolbar: null
      uuid: ''
      element: null
      tip_element: null
      back: true
      data: null
      loid: null
      nugget_loid: null
      has_changed: false
      publication: {}
      values: {}
      orig_values: {}
      default_css:
        'width': '100%'
        'height': '100%'
        'top': 0
        'left': 0
        'position': 'fixed'
        'z-index': 999999
    _init: ->
      #debug.log('sourcedescriptioneditor initialized',@options)

      @options.tip_element.hide() if @options.tip_element
      if jQuery('.selectBox-dropdown-menu').length
        jQuery('.selectBox-dropdown-menu').remove()
      if jQuery('#cite_editor').length
        jQuery('#cite_editor').remove()
        
      inputs = jQuery('<div id="cite_editor_inputs"></div>')
      @widget = jQuery('<div id="cite_editor"></div>')
      @widget.addClass('form_display');
      jQuery('body').css({'overflow':'hidden'})
      jQuery('body').append(@widget)

      @widget.css @options.default_css
      @wigtet.css('width', jQuery(window).width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      nugget = new DOMNugget()
      nugget.getAllSourceDescriptionAttributes(@options.loid).done (sdi) =>
        @options.publication = sdi.publication
        @selectables = '<option value="">' + utils.tr('more') + '</option>'
        jQuery.each sdi.description, (index, value) =>
          return if index == '__AUTOIDENT' || index == 'loid' || index == 'type' || index == 'tr_title'
          return if sdi.instance[index] == undefined
          return if !value.label
          qvalue = sdi.instance[index].replace(/"/g,'&#34;'); #"
          if ( qvalue == '' )
            @selectables+='<option value="' + index + '">' + value.label + '</option>'
          else
            inputs.append(@_createInput(index,value.label,qvalue))
        @widget.append('<div><label>&nbsp;</label><div class="max_width"><select id="sourcedescriptioneditor_selectable">' + @selectables + '</select></div></div>')
        @widget.append(inputs)
        str_html_buttons = ''
        if @options.back
          str_html_buttons = '<button id="sourcedescriptioneditor_back" class="action_button">' + utils.tr('back') + '</button>'
        str_html_buttons+= '<button id="sourcedescriptioneditor_apply" class="action_button">' + utils.tr('apply') + '</button>'
        @widget.append('<div class="button_container">' + str_html_buttons + '</div>')
        jQuery('#sourcedescriptioneditor_selectable').selectBox() if jQuery('body').selectBox
        jQuery('#sourcedescriptioneditor_selectable').bind 'change', (ev) =>
          new_input = jQuery(ev.target).val()
          return if ( new_input == '' )
          input = @_createInput(new_input,sdi.description[new_input].label,'');
          inputs.append(input)
          input.find('input').focus()
          sels = jQuery('<select>' + @selectables + '</select>')
          sels.find('option[value="' + new_input + '"]').remove();
          @selectables = sels.html()
          jQuery('#sourcedescriptioneditor_selectable').selectBox('destroy')
          jQuery('#sourcedescriptioneditor_selectable').html(@selectables )
          jQuery('#sourcedescriptioneditor_selectable').selectBox()
          #/bind change selectable
        jQuery('#sourcedescriptioneditor_apply').bind 'click', =>
          @widget.focus() # trigger form changed
          values = jQuery.extend({},@options.values)
          orig_values = jQuery.extend({},@options.orig_values)
          @options.values = {}
          @options.orig_values = {}
          loid = @options.loid
          nugget_loid = @options.nugget_loid
          if ( typeof window.__current_undo_command != 'undefined' ) # uses global as editable is destroyed, set in sourcedescription.coffee
            undo_command = window.__current_undo_command
          else
            if ( typeof UndoCommand != 'undefined')
              undo_command = new UndoCommand()
            else
              undo_command = {}
          # console.log(num_updates,values)

          # make editing of values undoable
          undo_command.redo = (event) => # event may be undefined
            undo_command.dfd = jQuery.Deferred()
            dfdlist = []
            jQuery.each values, (key, value) =>
              dfdlist.push(omc.storePublicationDescriptionAttribute(loid,key,value))
            jQuery.when.apply(jQuery,dfdlist).done () =>
              undo_command.dfd.resolve()
            undo_command.dfd.promise()
            undo_command.postdo()

          undo_command.undo = (event) => # event may be undefined
            undo_command.dfd = jQuery.Deferred()
            dfdlist = []
            jQuery.each orig_values, (key, value) =>
              dfdlist.push(omc.storePublicationDescriptionAttribute(loid,key,value))
            jQuery.when.apply(jQuery,dfdlist).done () =>
              undo_command.dfd.resolve()
            undo_command.dfd.promise()
            undo_command.postdo()

          undo_command.postdo = () =>
            undo_command.dfd.done () =>
              if ( nugget_loid )
                update_nugget = jQuery('#' + nugget_loid )
                # console.log(update_nugget)
                nugget.updateSourceDescriptionData(update_nugget).done =>
                  nugget.resetCitations(update_nugget)
                  occ.UpdateNuggetSourceDescriptions
                    loid:nugget_loid
          # run the action
          undo_command.redo()
          undo_manager = (new UndoManager()).getStack()
          jQuery('#sourcedescriptioneditor_selectable').selectBox('destroy')
          @widget.remove()
          jQuery('body').css({'overflow':'auto'})
          @options.editable.focus() if ( @options.editable)
          #/bind click apply

        jQuery('#sourcedescriptioneditor_back').bind 'click', =>
          @options.values = {}
          @options.orig_values = {}
          jQuery('#sourcedescriptioneditor_selectable').selectBox('destroy')
          jQuery('.form_display').remove();
          jQuery('body').css({'overflow':'auto'})
          #/bind click back
        window.setTimeout =>
          jQuery(window).resize()
          if ( @widget.find('#number_of_pages').length )
            pages = @widget.find('#number_of_pages')

            pages.closest('div').find('label').append('(' + @options.publication.number_of_pages + ')')
            if ( @widget.find('#number_of_pages').val() == @options.publication.number_of_pages )
              pages.val('')
              pages[0].focus();
        , 100
      jQuery(window).resize()

    _createInput: (identifier, label, value) ->
      # tooltip = utils.tr_pub_attr(@options.publication.instance_type_definition,identifier)
      input = jQuery('<div><label for="' + identifier + '">' + label + '</label><input id="' + identifier + '" type="text" value="' + value + '"/></div>')
      # if ( tooltip )
      #  input.attr('title',tooltip)
      if ( jQuery.datepicker && (identifier == 'date' || 'identifier' == 'accessed') )
        # datepicker with issues: does not remove on control remove
        fn_dp_show = =>
          $('.ui-datepicker-month').selectBox()
          $('.ui-datepicker-year').selectBox()
        fn_update_select = () =>
          window.setTimeout fn_dp_show, 100
        dp = input.find('input').datepicker({showOn: "button", onChangeMonthYear: fn_update_select, beforeShow: fn_update_select, buttonImage: "../icons/actions/datepicker-p.png", buttonImageOnly: true, dateFormat: "yy-mm-dd", changeMonth: false, changeYear: false, constrainInput: false})
      input.find('input').bind 'blur', (event) =>
        @_formChanged(event,@options)
      @options.orig_values[identifier] = value
      input
    _formChanged: (event, options) ->
      target = jQuery(event.target)
      #debug.log('form changed' + target.html())
      path = target.attr('id')
      data = target.val().replace(/&#34/g,'"');
      if omc && options.loid
        options.values[path] = data;
        #omc.storePublicationDescriptionAttribute(options.loid,path,data)
        #debug.log('stored',options.loid,path,data)
      if path.indexOf("number_of_pages")==0 && !isNaN(data) && !isNaN(options.publication.number_of_pages)
        try
          user_number = parseInt(data)
          if user_number <= options.publication.number_of_pages
            jQuery('#' + path).attr('class','valid')
          else
            utils.info(utils.tr('number_of_pages not in range'));
            jQuery('#' + path).attr('class','invalid')
        catch error
          jQuery('#' + path).attr('class','unparseable')
    _create: ->
      #debug.log('created');
      @

)(jQuery)
