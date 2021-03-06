#     Hallo - a rich text editing jQuery UI widget
#     (c) 2013 git-j, Refeus
#     Hallo may be freely distributed under the MIT license
#     Plugin to access & modify the raw data for the editable
#     desireable for paste from oo-text

((jQuery) ->
  jQuery.widget 'IKS.halloplaintext',
    name: "plaintext"
    html: null
    editable_element: null
    stored_content_selection_marker: ''
    plain_editor: null # optional component (codeMirror)
    overlay: null
    debug: false
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null
      overlayCss:
        'position': 'fixed'
        'z-index': 100000 # over toolbar
        'background': 'white'
        'border':'2px solid silver'

    cancel: () ->
      console.log('cancel') if @debug
      @restore()
    commit: () ->
      sel_html = @textarea.val()
      sel_html = sel_html.replace(/\n<table/g,'<table')
      sel_html = sel_html.replace(/\n<ol/g,'<ol')
      sel_html = sel_html.replace(/\n<ul/g,'<ul')
      sel_html = sel_html.replace(/\n <li/g,'<li')
      sel_html = sel_html.replace(/\n <tr/g,'<tr')
      sel_html = sel_html.replace(/\n  <td/g,'<td')
      sel_html = sel_html.replace(/\n<div/g,'<div')
      sel_html = sel_html.replace(/\n<p/g,'<p')
      sel_html = sel_html.replace(/\n<br/g,'<br')
      sel_html = sel_html + @stored_content_selection_marker
      @editable_element.html(sel_html)
      @options.editable.store()
      @restore()
    execute: () ->
      jQuery('body').css
        'overflow':'hidden'
      @editable_element.css
        'opacity': '0.5'
      @options.editable.storeContentPosition()
      @options.editable.undoWaypointStart('plaintext')


      jQuery('.misspelled').remove()
      @id = "#{@options.uuid}-#{@widgetName}-area"
      @editable_element = @options.editable.element
      console.log('execute::editable html',@editable_element.html()) if @debug
      overlay = @_create_overlay(@id)
      @editable_element.parent().append overlay
      overlay.fadeIn 100, =>
        @options.editable._ignoreEvents = true
        @textarea.focus()
        sel_html = @textarea.val();
        selm_start = '<' + @options.editable.selection_marker + '>'
        selm_end = '</' + @options.editable.selection_marker + '>'
        sel_html = sel_html.replace(/<span class="rangySelectionBoundary[^>]*>[^<]*<\/span>/,selm_start)
        if ( sel_html.match(/<span class="rangySelectionBoundary[^>]*>[^<]*<\/span>/) )
          sel_html = sel_html.replace(/<span class="rangySelectionBoundary[^>]*>[^<]*<\/span>/,selm_end)
        else
          sel_html = sel_html.replace(selm_start,selm_start+selm_end);
        # 8< prepareTextForStorage
        #sel_html = sel_html.replace(/<p/g,'\n<p')
        sel_html = sel_html.replace(/<table/g,'\n<table')
        sel_html = sel_html.replace(/<ol/g,'\n<ol')
        sel_html = sel_html.replace(/<ul/g,'\n<ul')
        sel_html = sel_html.replace(/<li/g,'\n <li')
        sel_html = sel_html.replace(/<tr/g,'\n <tr')
        sel_html = sel_html.replace(/<td/g,'\n  <td')
        sel_html = sel_html.replace(/<div/g,'\n<div')
        sel_html = sel_html.replace(/<p/g,'\n<p')
        sel_html = sel_html.replace(/<br/g,'\n<br')
        selection_pos_start = sel_html.indexOf(selm_start)
        if ( selection_pos_start >= 0)
          sel_html = sel_html.replace(new RegExp(selm_start,'g'),'')
        selection_pos_end = sel_html.indexOf(selm_end)
        if ( selection_pos_end >= 0 )
          sel_html = sel_html.replace(new RegExp(selm_end,'g'),'')
        @textarea.val(sel_html)
        if ( selection_pos_start >= 0 && selection_pos_end >= 0)
          @options.editable.setSelectionRange(@textarea.get(0),selection_pos_start,selection_pos_end)
        @_setup_syntax_highlight()
        @options.editable._ignoreEvents = false

    restore: () ->
      jQuery('body').css
        'overflow':'auto'
      @editable_element.css
        'opacity': '1'
      @overlay.fadeOut 100, =>
        @overlay.remove()
        dom = new DOMNugget()
        dom.prepareTextForEdit(@editable_element)
        dom.resetCitations(@editable_element)
        if ( typeof MathJax == 'object' )
          MathJax.Hub.Queue(['Typeset',MathJax.Hub])
        @options.editable.undoWaypointCommit()
        @options.editable.restoreContentPosition()

    setup: () ->
      # on activate toolbar (focus in)
      return if ! @options.editable.element
      @editable_element = @options.editable.element

    _create_form_button: (name,event_handler) ->
      button_label = utils.tr_action_title(name);
      button_tooltip = utils.tr_action_tooltip(name);
      btn = jQuery "<button class=\"action_button\" title=\"#{button_tooltip}\">#{button_label}</button>"
      btn.bind 'click', event_handler
      btn.addClass('action_button')
      btn
    _prepare_plain_content: ->
      dom = new DOMNugget()
      citeproc = new ICiteProc()
      dom.prepareTextForStorage(@editable_element)
      @saved_selection = rangy.saveSelection()
      selection_marker = @editable_element.find(@options.editable.selection_marker)
      if selection_marker.length
        @stored_content_selection_marker = selection_marker[0].outerHTML
        selection_marker.remove()
      selection_marker = @editable_element.find('.rangySelectionBoundary')
      selection_marker.each (index,item) =>
        node = jQuery(item)
        node.removeAttr('id')
        node.removeAttr('style')
      @editable_element.find('.auto-cite').remove()

    _create_overlay: (id) ->
      @overlay = jQuery "<div id=\"#{id}\"></div>"
      @_prepare_plain_content()
      @overlay.append @_create_plain(@editable_element.html())
      @overlay.append '<div class="button_container"></div>'
      container = @overlay.find('.button_container')
      container.append @_create_form_button 'Cancel', =>
        @cancel()
      container.append @_create_form_button 'Apply', =>
        @commit()
      @_overlay_resize()
      jQuery(window).bind 'resize', =>
        @_overlay_resize()
        @_plain_resize()
      @overlay
    _create_plain: (content) ->
      @textarea = jQuery "<textarea></textarea>"
      @textarea.val(content)
      @_plain_resize()
      @textarea.bind 'blur', =>
        @textarea.focus()
      @textarea.bind 'keyup', (event)=>
        if ( event.keyCode == 27 )
          @cancel()
      @textarea
    _setup_syntax_highlight: () ->
       #return if !CodeMirror
       editor_options = 
         'mode': 'application/xml'
         'lineNumbers': true
         'lineWrapping': true
       #@plain_editor = CodeMirror.fromTextArea(@textarea[0], editor_options)
       #hlLine = editor.addLineClass(0, "background", "activeline")
       #@plain_editor.bind "cursorActivity", =>
       #  cur = editor.getLineHandle(editor.getCursor().line)
       #  if (cur != hlLine)
       #    editor.removeLineClass(hlLine, "background", "activeline")
       #    hlLine = editor.addLineClass(cur, "background", "activeline")

    _overlay_resize: () ->
      @overlay.offset(@toolbar.offset())
      dim =
        width: @editable_element.width()
        height: @editable_element.height()
      dim.height = dim.height + ( @editable_element.offset().top - @toolbar.offset().top )
      @options.overlayCss.height = $(window).height()
      @options.overlayCss.width = $(window).width()
      @options.overlayCss.top = 0
      @options.overlayCss.left = 0
      @overlay.css @options.overlayCss

    _plain_resize: () ->
      height = $(window).height() - @toolbar.offset().top
      text_dim =
        'position': 'fixed'
        'top': '5px'
        'left': '8px'
        'width': ($(window).width() - 16) + 'px'
        'height': ($(window).height() - 48) + 'px'
        'max-width':  $(window).width()
        'max-height': $(window).height()
      @textarea.css text_dim
      if ( @plain_editor )
        @plain_editor.refresh()

    # inherits? with tpl_action
    populateToolbar: (toolbar) ->
      @editable_element = @options.editable.element
      @toolbar = toolbar
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      toolbar.append @_prepareButtons contentId
    _prepareButtons: (contentId) ->
      # build buttonset with single instance
      console.log(@editable_element) if @debug
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      buttonset.append @_prepareButton =>
        console.log(@editable_element) if @debug
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
