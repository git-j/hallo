#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#
#     Fixed toolbar plugin
((jQuery) ->
  jQuery.widget 'Hallo.halloToolbarAbsolute',
    toolbar: null

    options:
      parentElement: 'body'
      editable: null
      toolbar: null

    _create: ->
      @toolbar = @options.toolbar
      @toolbar.show()

      jQuery(@options.parentElement).append @toolbar

      @_bindEvents()

      jQuery(window).resize (event) =>
        @_updatePosition @_getPosition event

      # Make sure the toolbar has not got the full width of the editable
      # element when floating is set to true
      if @options.parentElement is 'body' and not @options.floating
        el = jQuery(@element)
        widthToAdd = parseFloat el.css('padding-left')
        widthToAdd += parseFloat el.css('padding-right')
        widthToAdd += parseFloat el.css('border-left-width')
        widthToAdd += parseFloat el.css('border-right-width')
        widthToAdd += (parseFloat el.css('outline-width')) * 2
        widthToAdd += (parseFloat el.css('outline-offset')) * 2
        jQuery(@toolbar).css "min-width", el.width() + widthToAdd

    _getPosition: (event, selection) ->
      return unless event
      offset = parseFloat(@element.css('outline-width')) + parseFloat(@element.css('outline-offset'))
      return position =
        top: @element.offset().top - @toolbar.outerHeight() - offset
        left: @element.offset().left - offset

    _getCaretPosition: (range) ->
      tmpSpan = jQuery "<span/>"
      newRange =rangy.createRange()
      newRange.setStart range.endContainer, range.endOffset
      newRange.insertNode tmpSpan.get 0

      position =
        top: tmpSpan.offset().top
        left: tmpSpan.offset().left
      tmpSpan.remove()

      return position

    setPosition: ->
      return unless @options.parentElement is 'body'
      @toolbar.css 'position', 'fixed'
      @toolbar.css 'top', '4px'
      @toolbar.css 'left', '4px'
      @toolbar.css 'z-index', '99999'

    _updatePosition: (position) ->
      return

    _bindEvents: ->
      # catch deactivate -> remove/cleanup
      @element.bind 'hallodeactivated', (event, data) =>
        @toolbar.remove()
        @destroy()
) jQuery
