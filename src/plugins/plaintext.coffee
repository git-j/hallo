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
      jQuery(@selection_marker).unwrap()
      dom = new DOMNugget()
      dom.prepareTextForEdit(@editable_element)
      if ( typeof MathJax == 'object' )
        MathJax.Hub.Queue(['Typeset',MathJax.Hub])
      @restore()
    commit: () ->
      @editable_element.html(@textarea.val())
      @options.editable.store()
      dom = new DOMNugget()
      dom.prepareTextForEdit(@editable_element)
      if ( typeof MathJax == 'object' )
        MathJax.Hub.Queue(['Typeset',MathJax.Hub])
      @restore()
    execute: () ->
      jQuery('body').css
        'overflow':'hidden'
      @editable_element.css
        'opacity': '0.5'
      sel = window.getSelection()
      @selection_marker = 'content_selection_marker'
      if ( sel.rangeCount > 0 )
        range = sel.getRangeAt()
        selection_identifier = jQuery('<' + @selection_marker + '></' + @selection_marker + '>')
        selection_identifier.append(range.extractContents())
        range.deleteContents()
        range.insertNode(selection_identifier[0])

      jQuery('.misspelled').remove()
      @id = "#{@options.uuid}-#{@widgetName}-area"
      @editable_element = @options.editable.element
      console.log('execute::editable html',@editable_element.html()) if @debug
      @editable_element.parent().append @_create_overlay(@id)
      @textarea.focus()
      sel_html = @textarea.val();
      sel_html = sel_html.replace(/<p/g,'\n<p')
      sel_html = sel_html.replace(/<div/g,'\n<div')
      sel_html = sel_html.replace(/<br/g,'\n<br')
      selm_start = '<' + @selection_marker + '>'
      selm_end = '</' + @selection_marker + '>'
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

    restore: () ->
      jQuery('body').css
        'overflow':'auto'
      @editable_element.css
        'opacity': '1'
      @overlay.remove()

    setup: () ->
      # on activate toolbar (focus in)
      return if ! @options.editable.element
      @editable_element = @options.editable.element

    _setSelectionRange: (input, selection_start, selection_end) ->
      if ( input.setSelectionRange )
        input.focus();
        input.setSelectionRange(selection_start, selection_end);
      else if ( input.createTextRange )
        range = input.createTextRange();
        range.collapse(true);
        range.moveEnd('character', selection_end);
        range.moveStart('character', selection_start);
        range.select();
    _setCaretToPos: (input, pos) ->
      @_setSelectionRange(input, pos, pos);

    _create_form_button: (name,event_handler) ->
      button_label = utils.tr_action_title(name);
      button_tooltip = utils.tr_action_tooltip(name);
      btn = jQuery "<button class=\"action_button\" title=\"#{button_tooltip}\">#{button_label}</button>"
      btn.bind 'click', event_handler
      btn.addClass('action_button')
      btn
    _create_overlay: (id) ->
      @overlay = jQuery "<div id=\"#{id}\"></div>"
      dom = new DOMNugget()
      dom.prepareTextForStorage(@editable_element);
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
        'width': $(window).width()
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
