#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# tipoverlay
# provides hallo framework to display tips/overlays on special content
# requires a 'data_cb' callback function that takes the triggering element and returns html to display in the tip
# the tip is triggered on all nodes that match the selector
((jQuery) ->
  jQuery.widget 'IKS.hallotipoverlay',
    options:
      editable: null
      toolbar: null
      selector: '.cite'
      can_edit: false
      data_cb: null
    can_hide: 0
    node: null
    timeout: 0
    tip_id: '#__hallotipoverlay'
    tip_node: null

    # bind the mouseover event to the given selector
    bindEvents: (@args) ->
      show_fn = jQuery.proxy @_show,@
      jQuery(window).bind('scroll',jQuery.proxy(@_hide,@))
      can_edit = @options.can_edit
      jQuery(@options.selector).live 'mouseover', (ev) ->
        jQuery(@).attr('contenteditable',can_edit)
        show_fn(@)
      debug.log('hallotip bound events')

    _restartCheckHide: ->
      #debug.log('restartCheckHide')
      window.clearTimeout(@timeout)
      check_hide_fn = jQuery.proxy( @_checkHide,@ )
      @timeout = window.setTimeout( check_hide_fn, 2000 )

    _hide: (cb) ->
      debug.log('hide hallotip')
      if @tip_node && @tip_node.length
        @tip_node.unbind()

        @tip_node.fadeOut 100, () =>
          @tip_node.remove()
          @can_hide = 0
          @node = null
          cb() if ( cb && !cb.target )
      else
        @can_hide = 0
        @node = null
        cb() if ( cb && !cb.target )

      window.clearTimeout(@timeout)


    _checkHide: ->
      #debug.log('check hide' + @can_hide)
      if ( @can_hide == 1 )
        @_restartCheckHide()
      if ( @can_hide == 2 )
        @_hide()

    _show: (target) -> # target: dom-node
      #debug.log('show:' + @can_hide )
      element = jQuery(target)
      if @can_hide > 0 && element[0] != @node[0]
        debug.log('display other node')
        @_hide() =>
          @_show(target)
      if @can_hide == 0
        data = '[dev] no callback defined for tipoverlay.options.data_cb: ' + element.html();
        data = @options.data_cb(element) if ( @options.data_cb )
        @tip_node = jQuery('<span id="' + @tip_id + '">' + data + '</span>')
        element.append(@tip_node)
        # dont jump out of the window on the right side
        ov_width = @tip_node.width()
        ov_height = @tip_node.height()
        b_width = jQuery('body').width() - 15;
        w_height = jQuery(window).height();
        position = element.offset();
        if (position.left + ov_width > b_width )
          newleft = b_width - ov_width
          @tip_node.css('right', '20px')
        else
          @tip_node.css('left',position.left)
        # and try to position above, if the target-node is on the bottom of the viewport
        ov_top = position.top - jQuery('body').scrollTop()
        if ( ov_top + ov_height > w_height )
          @tip_node.css('top',ov_top - 20 - ov_height)
        else
          @tip_node.css('top',ov_top)

        # candy
        @tip_node.hide()
        @tip_node.fadeIn(300);

        # set state for automatic hiding
        @can_hide = 2
        @node = element
        @tip_node.bind 'mouseenter', () =>
          @can_hide = 1
          @_restartCheckHide()
          @tip_node.animate({'opacity':'1'})
        @tip_node.bind 'mouseleave', () =>
          @can_hide = 2
          @_restartCheckHide()
          @tip_node.animate({'opacity':'0.6'})
        @_restartCheckHide()
)