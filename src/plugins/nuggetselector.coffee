#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated nuggets

((jQuery) ->
  jQuery.widget 'IKS.hallonuggetselector',
    widget: null
    selectables: ''
    hyperlink: null
    options:
      editable: null
      hyperlink_class: null
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
      @widget.hide()
      @widget.append('<div id="nugget_list" style="background-color:white; margin-bottom: 4px"></div>');
      @widget.append('<button class="nugget_selector_back action_button">' + utils.tr('back') + '</button>');
      @widget.append('<button class="nugget_selector_apply action_button">' + utils.tr('apply') + '</button>');
      @hyperlink = @options.editable.element.find('.' + @options.hyperlink_class)

      @widget.css @options.default_css
      @widget.find('.nugget_selector_back').bind 'click', =>
        @hyperlink = @options.editable.element.find('.' + @options.hyperlink_class)
        if ( utils.tr('no title provided') == @hyperlink.text() )
          @hyperlink.remove()
        else
          @hyperlink.contents().unwrap().wrapAll('<span></span>')
        @back()
      @widget.find('.nugget_selector_apply').bind 'click', =>
        @apply()
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      @list = new List()
      @list.init($('#nugget_list'),omc.NuggetExtendList)
      @list.setupItemActions($('#nugget_list'),{
        'node_dblclick': (node) =>
          @select(node)
          @apply()
        'node_select': (node) =>
          @select(node)
      })
      # TODO: display filters / search
      @widget.fadeIn()
      jQuery(window).resize()

    apply:  ->
      if ( typeof @current_node == 'undefined' )
        utils.error(utils.tr('nothing selected'))
        return
      nugget_loid = @current_node.replace(/node_/,'')
      dfo = omc.getInstance(nugget_loid)
      dfo.fail (error) =>
        @back()

      #tmp_id is used to identify new sourcedescription after it has been inserted for further editing
      
      dfo.done (nugget) =>
        data = nugget.loid
        new_href = 'refeus://localhost/database/self/Variation/' + nugget.guid
        @hyperlink = @options.editable.element.find('.' + @options.hyperlink_class)
        @hyperlink.attr('href',new_href)
        if( @hyperlink.text() == utils.tr('no title provided') )
          @hyperlink.text(nugget.display_name)
        @back()


    back: ->
      @widget.fadeOut 100, =>
        @widget.remove()

      @hyperlink = @options.editable.element.find('.' + @options.hyperlink_class)
      if ( @hyperlink.length )
        @hyperlink.removeClass(@options.hyperlink_class)
        console.log(@options.editable.element.html())
        @options.editable.element.find('.nugget_select_target').removeClass('nugget_select_target')
        #cleanup old
        @options.editable.element.find('a').each (index,item) =>
          link = jQuery(item)
          link_class = link.attr('class')
          if ( typeof link_class == 'undefined' )
            return # continue
          link_class = link_class.replace(/mod_[0-9]*/,'')
          if link_class == ''
            link.removeAttr('class')
          else
            link.attr('class',link_class)
        @options.editable.setContentPosition(@hyperlink)

      jQuery('body').css({'overflow':'auto'})
      @options.editable.store()
      @options.editable.restoreContentPosition()
    select: (node) ->
      @current_node = jQuery(node).attr('id')
      @current_node_label = jQuery(node).text()

    _create: ->
      #debug.log('created');
      @

)(jQuery)
