#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallosourcedescriptioneditor',
    widget: null
    options:
      editable: null
      toolbar: null
      uuid: ''
      element: null
      citehandler: null
      data: null
      loid: null
      default_css:
        'width': jQuery('body').width()
        'height': jQuery(window).height()
        'top': 0
        'left': 0
        'position': 'fixed'
        'border':'1px solid silver'
    _init: ->
      debug.log('sourcedescriptioneditor initialized')

      @options.element.hide()
      @widget = jQuery('<div id="cite_editor"></div>')
      @widget.addClass('form_display');
      jQuery('body').append(@widget)
      @widget.css @options.default_css
      nugget = new DOMNugget();
      #nugget.getAllSourceDescriptionAttributes(@options.loid)
      jQuery.each @options.data, (index, value) =>
        return if index == '__AUTOIDENT'
        return if index == 'id'
        qvalue = ''
        debug.log(value)
        if typeof(value) == 'string'
          qvalue = value.replace(/\n/g,' ').replace(/\"/g,'&quot;')
          @widget.append('<div><label for="' + index + '">' + utils.tr(index) + '</label><input id="' + index + '" type="text" value="' + qvalue + '"/></div>')

    _create: ->
      @options.citehandler = root.citehandler.get()
      debug.log('created');
      @

)(jQuery)
