#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# citehandler
# common functions for citation/publication/sourcedescription handling
root = exports ? this

class root.citehandler
  _instance = undefined # Must be declared here to force the closure on the class
  @get: (args) -> # Must be a static method
    _instance ?= new _Citehandler args

class _Citehandler
  constructor: (@args) ->
    @_overlay_can_hide = 0
    @_overlay_node = null
    @_overlay_timeout = 0
    @settings = {}
    @bindEvents()

  bindEvents: (@args) ->
    show_overlay_fn = jQuery.proxy @_showOverlay,@
    jQuery('.cite').live 'mouseover', (ev) ->
      jQuery(@).attr('contenteditable','false')
      show_overlay_fn(@)
    debug.log('bound events')

  setupSourceDescriptions: (target, editable, add_element_cb) ->
    debug.log('setup sourcedescriptions...')
    target.find('.SourceDescription').remove()
    create_menu_item = (index,item) =>
      cindx = jQuery(item).find('.citation_index').html()
      try
        scitation_data = jQuery(item).find('.citation_data').html() 
        scitation_data = scitation_data.replace(/, \"ITEM-/,'"ITEM-');
        citation_data = JSON.parse("{#{scitation_data}}")
        rel  = citation_data["ITEM-#{cindx}"].type
        link = citation_data["ITEM-#{cindx}"].title
        target.append(add_element_cb(link,null,rel,cindx).addClass('SourceDescription'))
      catch error
        debug.log('[dev] citehandler::setupSourceDescription: invalid citation_data: ' + error )

    if editable.element.parent('.nugget').length
      editable.element.parent('.nugget').find('.SourceDescription').each create_menu_item
    else if editable.element.parent('.Text').length
      editable.element.parent('.Text').find('.SourceDescription').each create_menu_item

  _updateSettings: ->
    @settings = JSON.parse(omc_settings.getSettings()) if omc_settings

  _restartCheckHideOverlay: ->
    #debug.log('restartCheckHideOverlay')
    window.clearTimeout(@_overlay_timeout)
    check_hide_overlay_fn = jQuery.proxy( @_checkHideOverlay,@ )
    @_overlay_timeout = window.setTimeout( check_hide_overlay_fn, 2000 )

  _hideOverlay: (cb) ->
    #debug.log('hide overlay')
    overlay = jQuery ('#cite_overlay')
    overlay.unbind()
    @_formChanged({'target': jQuery('#cite_overlay #sd_pages')})
    @_formChanged({'target': jQuery('#cite_overlay #sd_meta')})
    overlay.fadeOut 100, () =>
      overlay.remove()
      @_overlay_can_hide = 0
      @_overlay_node = null
      if ( cb )
        cb()
    window.clearTimeout(@_overlay_timeout)


  _checkHideOverlay: ->
    #debug.log('check hide' + @_overlay_can_hide)
    if ( @_overlay_can_hide == 1 )
      @_restartCheckHideOverlay()
    if ( @_overlay_can_hide == 2 )
      @_hideOverlay()

  _formChanged: (event) ->
    target = jQuery(event.target)
    debug.log('form changed' + target.html())
    loid = 0
    path = ''
    data = target.val()
    if ( omc )
      omc.storePublicationDescriptionAttribute(loid,path,data)

  _showOverlay: (target) ->
    #debug.log('show overlay:' + @_overlay_can_hide )
    element = jQuery(target)
    if @_overlay_can_hide > 0 && element[0] != @_overlay_node[0]
      debug.log('display other node')
      @_hideOverlay () =>
        @_showOverlay(target)
    if @_overlay_can_hide == 0
      @_updateSettings
      ov_data = '<h1>' + element.html() + '</h1>'
      cite = 'citationTODO'
      footnote = 'footnoteTODO'
      bibliography = 'bibliographyTODO'
      #ov_data+= '<p>' + utils.tr('citation in') + ' ' + @settings.default_citation_style+ ':</p>'
      #ov_data+= '<p>' + utils.tr('citation') + ': ' + cite + '</p>'
      #ov_data+= '<p>' + utils.tr('footnote') + ': ' + footnote + '</p>'
      #ov_data+= '<p>' + utils.tr('bibliography') + ': ' +  bibliography + '</p>'
      #ov_data+= '<p>' + utils.tr('pages') + ': <input type="text" id="sd_pages"/></p>'
      #ov_data+= '<p>' + utils.tr('meta') + ': <textarea id="sd_meta"></textarea></p>'
      element.append('<span id="cite_overlay">' + ov_data + '</span>')
      overlay = jQuery('#cite_overlay')
      overlay.find('#sd_pages').bind 'blur', @_formChanged
      overlay.find('#sd_meta').bind 'blur', @_formChanged
      overlay.css {
        'position':'absolute'
        'background-color':'white'
        'margin-top': '1em'
        'padding': '4px'
        'min-height': '46px'
        'border': '1px solid black'
        'z-index': 99999
      }
      # dont jump out of the window on the right side
      ov_width = overlay.width()
      b_width = 300 #jQuery('body').width();
      position = overlay.offset();
      debug.log(overlay.offset().left)
      debug.log(ov_width)
      debug.log(b_width)
      if (position.left + ov_width > b_width )
        newleft = b_width - ov_width
        overlay.css('left', newleft + 'px')
        debug.log(overlay.offset().left)
      overlay.css('display','none')
      overlay.fadeIn(300);
      @_overlay_can_hide = 2
      @_overlay_node = element
      jQuery('#cite_overlay').bind 'mouseenter', () =>
        @_overlay_can_hide = 1
        @_restartCheckHideOverlay()
        jQuery('#cite_overlay').animate({'opacity':'1'})
      jQuery('#cite_overlay').bind 'mouseleave', () =>
        @_overlay_can_hide = 2
        @_restartCheckHideOverlay()
        jQuery('#cite_overlay').animate({'opacity':'0.6'})
      @_restartCheckHideOverlay()
