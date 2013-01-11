#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallopublicationselector',
    widget: null
    selectables: ''
    options:
      editable: null
      range: null
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
        'z-index': 999999
    _init: ->
      #debug.log('publicationselector initialized',@options)
      @widget = jQuery('<div id="publication_selector"></div>')
      @widget.addClass('form_display');
      jQuery('body').css({'overflow':'hidden'})
      jQuery('body').append(@widget)
      @widget.append('<div id="publication_list" style="background-color:white; margin-bottom: 4px"></div>');
      @widget.append('<button class="publication_selector_back view_button">' + utils.tr('back') + '</button>');
      @widget.append('<button class="publication_selector_apply action_button">' + utils.tr('apply') + '</button>');
      @widget.css @options.default_css
      @widget.find('.publication_selector_back').bind 'click', =>
        @back()
      @widget.find('.publication_selector_apply').bind 'click', =>
        @apply()
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      jQuery.when(
          utils.getJavaScript('lib/refeus/Utilities/List.js')
      ).done =>
        @list = new List();
        @list.init($('#publication_list'),omc.PublicationList);
        @list.setupItemActions($('#publication_list'),{
          'node_dblclick': (node) =>
            @select(node)
            @apply()
          'node_select': (node) =>
            @select(node)
        })
      jQuery(window).resize()

    apply:  ->
      publication_loid = @current_node.replace(/node_/,'')
      target_loid = @options.editable.element.closest('.Text').attr('id').replace(/node/,'')
      dfo = omc.AssociatePublication(target_loid,publication_loid)
      dfo.fail(debug.log)
      dfo.done (result) =>
        data = result.loid
        element = @current_node_label
        scb = (parent, old) ->
          replacement = false
          if old.html() != ""
            replacement = "<span class=\"citation\">" + old.html() + "</span>"
          else
            replacement = ""
          replacement+= "<span class=\"cite sourcedescription-#{data}\">#{element}</span>"
          replacement
        #/scb
        if ( jQuery(@options.range.cloneContents()).text() != '' )
          window.getSelection().addRange(@options.range)
          @options.editable.replaceSelectionHTML scb
          #debug.log('sdc::addElement',@options.editable)
        nugget = new DOMNugget()
        nugget.updateSourceDescriptionData(@options.editable.element)
        nugget.updateCitations(@options.editable.element)
        @widget.remove()
        jQuery('body').css({'overflow':'auto'})


    back: ->
      @widget.remove()
      jQuery('body').css({'overflow':'auto'})

    select: (node) ->
      @current_node = jQuery(node).attr('id')
      @current_node_label = jQuery(node).text()

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
