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
      citehandler: null
      data: null
      loid: null
      has_changed: false
      default_css:
        'width': '100%'
        'height': '100%'
        'top': 0
        'left': 0
        'position': 'fixed'
        'border':'1px solid silver'
        'overflow-y':'auto'
    _init: ->
      #debug.log('sourcedescriptioneditor initialized',@options)

      @options.tip_element.hide()
      inputs = jQuery('<div id="cite_editor_inputs"></div>')
      @widget = jQuery('<div id="cite_editor"></div>')
      @widget.addClass('form_display');
      jQuery('body').append(@widget)
      @widget.css @options.default_css
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      nugget = new DOMNugget();
      sdi = nugget.getAllSourceDescriptionAttributes(@options.loid)
      @selectables = '<option value="">' + utils.tr('more') + '</option>' ;
      jQuery.each sdi.description, (index, value) =>
        return if index == '__AUTOIDENT' || index == 'loid' || index == 'type' || index == 'tr_title'
        return if sdi.instance[index] == undefined
        return if !value.label
        qvalue = sdi.instance[index]
        if ( qvalue == '' )
          @selectables+='<option value="' + index + '">' + value.label + '</option>'
        else
          inputs.append(@_createInput(index,value.label,qvalue))
      @widget.append('<div><label>&nbsp;</label><select id="sourcedescriptioneditor_selectable">' + @selectables + '</select></div>')
      @widget.append(inputs)
      @widget.append('<div><label>&nbsp;</label><button id="sourcedescriptioneditor_back">' + utils.tr('continue') + '</button></div>')
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
      jQuery('#sourcedescriptioneditor_back').bind 'click', =>
        @widget.focus() # trigger form changed
        nugget.updateSourceDescriptionData(@options.element.closest('.nugget'))
        @widget.remove()
    _createInput: (identifier, label, value) ->
      input = jQuery('<div><label for="' + identifier + '">' + label + '</label><input id="' + identifier + '" type="text" value="' + value + '"/></div>')
      input.find('input').bind 'blur', (event) =>
        @_formChanged(event,@options)
      input
    _formChanged: (event, options) ->
      target = jQuery(event.target)
      #debug.log('form changed' + target.html())
      path = target.attr('id')
      data = target.val()
      if omc && options.loid
        omc.storePublicationDescriptionAttribute(options.loid,path,data)
        #debug.log('stored',options.loid,path,data)

    _create: ->
      @options.citehandler = root.citehandler.get()
      #debug.log('created');
      @

)(jQuery)