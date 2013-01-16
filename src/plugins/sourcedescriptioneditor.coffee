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
      citehandler: null
      data: null
      loid: null
      has_changed: false
      publication: {}
      values: {}
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
      return if jQuery('#cite_editor').length
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
        @widget.append('<div><label>&nbsp;</label><select id="sourcedescriptioneditor_selectable">' + @selectables + '</select></div>')
        @widget.append(inputs)
        str_html_buttons=''
        if @options.back
          str_html_buttons ='<button id="sourcedescriptioneditor_back" class="view_button">' + utils.tr('back') + '</button>'
        str_html_buttons+='<button id="sourcedescriptioneditor_apply" class="action_button">' + utils.tr('apply') + '</button>'
        @widget.append('<div>' + str_html_buttons + '</div>')
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
        jQuery('#sourcedescriptioneditor_apply').bind 'click', =>
          @widget.focus() # trigger form changed
          jQuery.each @options.values, (key, value) =>
            omc.storePublicationDescriptionAttribute(@options.loid,key,value)
          nugget.updateSourceDescriptionData(@options.element.closest('.nugget')).done =>
            nugget.resetCitations(@options.element.closest('.nugget'))
          jQuery('#sourcedescriptioneditor_selectable').selectBox('destroy')
          @widget.remove()
          jQuery('body').css({'overflow':'auto'})

        jQuery('#sourcedescriptioneditor_back').bind 'click', =>
          jQuery('#sourcedescriptioneditor_selectable').selectBox('destroy')
          jQuery('.form_display').remove();
          jQuery('body').css({'overflow':'auto'})
        window.setTimeout =>
          jQuery(window).resize()
        , 100

      jQuery(window).resize()

    _createInput: (identifier, label, value) ->
      input = jQuery('<div><label for="' + identifier + '">' + label + '</label><input id="' + identifier + '" type="text" value="' + value + '"/></div>')
      input.find('input').bind 'blur', (event) =>
        @_formChanged(event,@options)
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
      if path.indexOf("number_of_pages")==0
        try
          user_number = parseInt(data)
          if data <= options.publication.number_of_pages
            jQuery('#' + path).attr('class','valid')
          else
            utils.error(utils.tr('number_of_pages not in range'));
            jQuery('#' + path).attr('class','invalid')
        catch error
          jQuery('#' + path).attr('class','unparseable')
    _create: ->
      @options.citehandler = root.citehandler.get()
      #debug.log('created');
      @

)(jQuery)
