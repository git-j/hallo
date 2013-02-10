#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license

# spellcheck plugin
# requires bjspell and getStyleObject
# and is needed for older browsers or qt-webkit
#    execute on load:
#    , utils.getJavaScript("lib/hallojs/bjspell.js")
#    , utils.getJavaScript("lib/hallojs/jquery.getStyleObject.js")
#     window.spellcheck = BJSpell("lib/hallojs/" + language + ".js", function(){
#      //console.log('spellcheck loaded:' + language);
#    });


((jQuery) ->
  jQuery.widget 'IKS.hallospellcheck',
    name: 'spellcheck'      # used for icon, executed as execCommand
    spellcheck_interval: 0  # timeout_id
    spellcheck_timeout: 300 # ms after keypress the spellcheck should run
    spellcheck_proxy: null  # proxy to keep this
    initialized: false      # events are bound
    debug: false            # display spellcheck progress
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null
    _init: () ->
      @options.editable.element.bind 'halloactivated', =>
        @enable()

    enable: () ->
      if ( !@spellcheck_proxy )
        @spellcheck_proxy = jQuery.proxy(@checkSpelling,this)
      @options.editable.element.unbind('keydown click', @spellcheck_proxy)
      @options.editable.element.bind('keydown click', @spellcheck_proxy)
      @initialized = true
      console.log(@initialized) if @debug
      return

    checkSpelling: (event) ->
      #leave when navigation&control are pressed
      console.log(@options.editable.element[0].spellcheck,window.spellcheck,event.keyCode) if @debug
      return if ((event.keyCode >= 37 && event.keyCode <= 40 ) || event.keyCode == 17 || event.keyCode == 18 )
      return if ( !window.spellcheck )
      return if ( !@options.editable.element[0].spellcheck )
      if ( @spellcheck_interval )
        console.log('reset interval') if @debug
        window.clearTimeout(@spellcheck_interval)

      interval_checker = =>
        console.log('interval_checker') if @debug
        over_css = @options.editable.element.getStyleObject()
        return if ( @options.editable.element.find('pre').length )
        clone = @options.editable.element.clone()
        offset = @options.editable.element.offset()
        check_node = clone
        if ( window.getSelection().rangeCount )
          range = window.getSelection().getRangeAt()
          range.collapse()
          find_node = (node) =>
            ret_node = null
            if ( range.commonAncestorContainer.parentNode == node[0] )
              return node
            if ( node[0].nodeType == 1 )
              node.children().each (index,child_node) =>
                ret_node = find_node($(child_node))
                if ( ret_node && ret_node.length )
                  return false #break
            return ret_node
          #/find_node()
          current_block = find_node(@options.editable.element)
          if ( current_block )
            check_node = current_block
            check_node.addClass('current_block')
            clone = @options.editable.element.clone()
            check_node.removeClass('current_block')
            check_node = clone.find('.current_block')
            if ( !check_node.length )
              check_node = clone
            else
              #find child-block of clone
              while( check_node[0] != clone[0] && check_node.parent()[0] != clone[0] )
                check_node = check_node.parent();
        #/window has range
        #console.log('offset:' + offset.top + '@' + offset.left)
        @options.editable.element.parent().find('.misspelled').remove()
        window.spellcheck.replaceDOM  check_node[0], (word) ->
          return '<span class="misspelled">' + word + '</span>'
        underlay_id = 'spellcheck_underlay';
        clone = $('<div id="' + underlay_id + '">' + clone.html() + '</div>')
        over_css['position'] = 'absolute'
        over_css['z-index'] = '1000'
        over_css['top'] = offset.top + "px"
        over_css['left'] = offset.left + "px"
        # over_css['top'] = 0 + "px"
        # over_css['left'] = 0 + "px"
        over_css['bottom'] = 0 + "px"
        over_css['right'] = 0 + "px"
        # over_css['padding-left'] = 0
        # over_css['padding'] = '0'
        over_css['margin'] = '0'
        # over_css['width'] = @options.editable.element.css('width')
        @options.editable.element.css({'position':'relative'})
        clone.css(over_css)
        clone.addClass('content')
        clone.insertBefore(@options.editable.element)
        clone.find('.misspelled').each (index,item) =>
          node = $(item);
          offset = node.offset();
          node_css = {};
          orig_css = node.getStyleObject();

          node_css['position'] = 'absolute';
          node_css['top'] = (offset.top + node.height()-2 ) + 'px';
          node_css['height'] = '2px';
          node_css['left'] = (offset.left) + 'px';
          node_css['padding'] = '0';
          node_css['margin'] = '0';
          node_css['color'] = 'transparent';
          node_css['font-size'] = node.css('font-size');
          node_css['line-height'] = node.css('line-height');
          node_css['pointer-events'] = 'none';
          node.clone(true).insertAfter(@options.editable.element).css(node_css);
        #/each misspelled
        clone.remove();
      @spellcheck_interval = setTimeout( interval_checker, @spellcheck_timeout )
      console.log(@spellcheck_interval) if @debug

    execute: () ->
      # on click toolbar button
      console.log('toggle') if debug
      @options.editable.element[0].spellcheck = !@options.editable.element[0].spellcheck
      @options.editable.element.blur()
      @options.editable.element.focus()
      if ( @options.editable.element[0].spellcheck )
        console.log('check spelling') if debug
        @checkSpelling({'keycode':0})
      else
        jQuery('.misspelled').remove()
    setup: () ->
      # on activate toolbar (focus in)
      console.log(@initialized) if debug
      return if ( @initialized )
      @enable()
    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      toolbar.append @_prepareButtons contentId
    _prepareButtons: (contentId) ->
      # build buttonset with single instance
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      buttonset.append @_prepareButton =>
        @execute()
      buttonset.hallobuttonset()

    _prepareButton: (action) ->
      # build button to be displayed with halloactionbutton
      # apply translated tooltips
      buttonElement = jQuery '<span></span>'
      button_label = @name
      if ( window.action_list && window.action_list['hallojs_' + @name] != undefined )
        button_label =  window.action_list['hallojs_' + @name].title
      buttonElement.halloactionbutton
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        icon: 'icon-text-height'
        command: @name
        target: @name
        setup: @setup
        cssClass: @options.buttonCssClass
        action: action
      buttonElement

)(jQuery)
