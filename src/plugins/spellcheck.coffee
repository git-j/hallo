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
      return # disable spellcheck until further notice
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
      return if ((event.keyCode >= 33 && event.keyCode <= 40 ) || event.keyCode == 17 || event.keyCode == 18 )
      if event.keyCode == 13 || event.keyCode == 8 || event.keyCode == 46 
        # remove underline when document structure would change return, backspace, delete
        jQuery('.misspelled').remove()

      return if ( !window.spellcheck )
      return if ( !@options.editable.element[0].spellcheck )
      if ( @spellcheck_interval )
        console.log('reset interval') if @debug
        window.clearTimeout(@spellcheck_interval)

      interval_checker = =>
        console.log('interval_checker') if @debug
        check_node = _this.options.editable.element
        @options.editable.element.parent().find('.misspelled_, .spell_check_clone, .misspelled_line').remove()
        some_where_in_dom = check_node.parent()
        clone = check_node.clone()
        clone.removeClass('content').addClass('spell_check_clone')
        some_where_in_dom.append(clone)
        clone.position 
          my: 'left top'
          at: 'left top'
          of: check_node
          collision: 'none'
        dom = new IDOM()
        console.log('before',clone.html()) if @debug
        csm = clone.find('content_selection_marker')
        jQuery.each csm, () ->
          jq_this = jQuery(this)
          parent = jq_this.parent()
          if ( jq_this.html() == '' )
            jq_this.remove()
          else
            jq_this.contents().unwrap()
          parent[0].normalize()
        console.log('after',clone.html()) if @debug
        dom.getAllTextNodes(clone).wrap('<span class="word"></span>')
        # CHECK MISSPELLED
        jQuery.each jQuery('.word'), () ->
          window.spellcheck.replaceDOM this, (word) ->
            # console.log(word,jQuery('<span class="misspelled_">' + word + '</span>')) if @debug
            return '<span class="misspelled_">' + word + '</span>'
        jQuery.each jQuery('.misspelled_'), () ->
          line = jQuery('<div class="misspelled_line"></div>')
          line.width(jQuery(this).width())
          some_where_in_dom.append(line)
          line.position
            my:'left top'
            at:'left bottom'
            of: jQuery(this)
            collision: 'none'
        clone
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
