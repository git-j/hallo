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
      try
        wke.spellcheckWord('refeus')
        @initialized = true
      catch
        @initialized = false
      console.log(@initialized) if @debug
      return

    execute: () ->
      # on click toolbar button
      return if ( !@initialized )
      console.log('toggle spellcheck') if debug
      @options.editable.element[0].spellcheck = !@options.editable.element[0].spellcheck
      @options.editable.element.blur()
      @options.editable.element.focus()

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
