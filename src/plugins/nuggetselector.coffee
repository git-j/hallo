#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated nuggets

((jQuery) ->
  jQuery.widget 'IKS.hallonuggetselector',
    widget: null
    selectables: ''
    options:
      editable: null
      hyperlink_id: null
      range: null
      toolbar: null
      uuid: ''
      element: null
      tip_element: null
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
      @widget = jQuery('<div id="nugget_selector"></div>')
      @widget.addClass('form_display');
      jQuery('body').css({'overflow':'hidden'})
      jQuery('body').append(@widget)
      @widget.append('<div id="nugget_list" style="background-color:white; margin-bottom: 4px"></div>');
      @widget.append('<button class="nugget_selector_back view_button">' + utils.tr('back') + '</button>');
      @widget.append('<button class="nugget_selector_apply action_button">' + utils.tr('apply') + '</button>');
      @widget.css @options.default_css
      @widget.find('.nugget_selector_back').bind 'click', =>
        if ( utils.tr('no title provided') == jQuery('#' + @options.hyperlink_id).text() )
          jQuery('#' + @options.hyperlink_id).remove()
        else
          hyperlinked = jQuery('#' + @options.hyperlink_id).html()
          jQuery('#' + @options.hyperlink_id).replaceWith(jQuery('<span>' + hyperlinked + '</span>'))
        @back()
      @widget.find('.nugget_selector_apply').bind 'click', =>
        @apply()
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      jQuery.when(
          utils.getJavaScript('lib/refeus/Utilities/List.js')
      ).done =>
        @list = new List()
        @list.init($('#nugget_list'),omc.NuggetExtendList)
        @list.setupItemActions($('#nugget_list'),{
          'node_dblclick': (node) =>
            @select(node)
            @apply()
          'node_select': (node) =>
            @select(node)
        })
      jQuery(window).resize()

    apply:  ->
      nugget_loid = @current_node.replace(/node_/,'')
      dfo = omc.getInstance(nugget_loid)
      dfo.fail (error) =>
        @back()

      #tmp_id is used to identify new sourcedescription after it has been inserted for further editing
      
      dfo.done (nugget) =>
        data = nugget.loid
        new_href = 'refeus://localhost/database/self/Variation/' + nugget.guid
        hyperlink = jQuery('#' + @options.hyperlink_id)
        hyperlink.attr('href',new_href)
        hyperlink.removeAttr('id')
        if( hyperlink.text() == utils.tr('no title provided') )
          hyperlink.text(nugget.display_name)
        @back()


    back: ->
      @widget.remove()
      jQuery('#' + @options.hyperlink_id).removeAttr('id')
      jQuery('body').css({'overflow':'auto'})
      @options.editable.store()

    select: (node) ->
      @current_node = jQuery(node).attr('id')
      @current_node_label = jQuery(node).text()

    _create: ->
      #debug.log('created');
      @

)(jQuery)
