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
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null
      overlayCss:
        'position': 'fixed'
        'z-index': 100000 # over toolbar
        'background': 'white'

    cancel: () ->
      console.log('cancel')
      @restore()
    commit: () ->
      @editable_element.html(@textarea.val())
      @restore()
    execute: () ->
      jQuery('body').css
        'overflow':'hidden'
      @editable_element.css
        'opacity': '0.5'
      @id = "#{@options.uuid}-#{@widgetName}-area"
      @editable_element.parent().append @_create_overlay(@id)
      @textarea.focus()
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


    _create_form_button: (name,event_handler) ->
      button_label = name
      button_tooltip = name
      if ( window.action_list && window.action_list['hallojs_plaintext_' + name] != undefined )
        button_label = window.action_list['hallojs_plaintext_' + name].title
        button_tooltip = window.action_list['hallojs_plaintext_' + name].tooltip
      btn = jQuery "<button class=\"action-button\" title=\"#{button_tooltip}\">#{button_label}</button>"
      btn.bind 'click', event_handler
      btn.addClass('action-button')
      btn
    _create_overlay: (id) ->
      @overlay = jQuery "<div id=\"#{id}\"></div>"
      @overlay.append @_create_form_button 'Cancel', =>
        @cancel()
      @overlay.append @_create_form_button 'Apply', =>
        @commit()
      @overlay.append('<hr/>')
      @overlay.append @_create_plain(@editable_element.html())
      @_overlay_resize()
      jQuery(window).bind 'resize', =>
        @_overlay_resize()
        @_plain_resize()
      @overlay
    _create_plain: (content) ->
      @textarea = jQuery "<textarea>#{content}</textarea>"
      @_plain_resize()
      @textarea.bind 'blur', =>
        @textarea.focus()
      @textarea
    _setup_syntax_highlight: () ->
       return if !CodeMirror
       editor_options = 
         'mode': 'application/xml'
         'lineNumbers': true
         'lineWrapping': true
       @plain_editor = CodeMirror.fromTextArea(@textarea[0], editor_options)
       hlLine = editor.addLineClass(0, "background", "activeline")
       @plain_editor.on "cursorActivity", =>
         cur = editor.getLineHandle(editor.getCursor().line)
         if (cur != hlLine)
           editor.removeLineClass(hlLine, "background", "activeline")
           hlLine = editor.addLineClass(cur, "background", "activeline")

    _overlay_resize: () ->
      @overlay.offset(@toolbar.offset())
      dim =
        width: @editable_element.width()
        height: @editable_element.height()
      dim.height = dim.height + ( @editable_element.offset().top - @toolbar.offset().top )
      @options.overlayCss.height = dim.height
      @options.overlayCss.width = dim.width
      @options.overlayCss.top = @toolbar.offset().top
      @options.overlayCss.left = @editable_element.offset().left
      @overlay.css @options.overlayCss

    _plain_resize: () ->
      height = $(window).height() - @toolbar.offset().top
      text_dim =
        'position': 'fixed'
        'top': @editable_element.offset().top
        'left': @editable_element.offset().left
        'width': @editable_element.width()
        'height': @editable_element.height() # TODO:center in window, does not work with large texts
        'max-width': @editable_element.width()
        'max-height': @editable_element.height()
        'border': '1px solid black'
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
      console.log(@editable_element)
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      buttonset.append @_prepareButton =>
        console.log(@editable_element)
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
