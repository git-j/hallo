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
  tips: null
  constructor: (@args) ->
    @settings = {}
    @citation_data = {}
    @tips = jQuery('<span></span>')
    @overlay_id = 'cite_overlay'
    @tips.hallotipoverlay (
      'selector': '.cite'
      'tip_id': @overlay_id
      'data_cb': jQuery.proxy(@_makeTip,@)
    )
  setupSourceDescriptions: (target, editable, add_element_cb) ->
    debug.log('setup sourcedescriptions...')
    target.find('.SourceDescription').remove()
    domnugget = new DOMNugget();

    sourcedescriptions = domnugget.getSourceDescriptions(editable.element.parent('.nugget'))
    jQuery.each sourcedescriptions, (index,item) =>
      target.append(add_element_cb(item.title,null,item.type,item.loid).addClass('SourceDescription'))

  _updateSettings: ->
    @settings = JSON.parse(omc_settings.getSettings()) if omc_settings

  _updateCitationDisplay: (element) -> #element: jq-dom-node
    #debug.log('update citation')
    @footnote = ''
    @bibliography = ''
    @citation_data = {}
    @sourcedescription_loid = 0
    domnugget = new DOMNugget();
    @citation_data = domnugget.getSourceDescriptionData(element)

  _makeTip: (target, element) -> # target: jq-dom-node (tip), element: jq-dom-node (tipping element)
    @_updateSettings
    ov_data = ''
    @_updateCitationDisplay(element)
    #TODO: nicer HTML for better styling
    #debug.log(@citation_data)
    ov_data+= '<ul>'
    ov_data+= '<li>' + utils.tr('citation in') + ' ' + @citation_data.citation_style+ ': ' + @citation_data.cite + '</li>'
    ov_data+= '<li>' + utils.tr('footnote') + ': ' + @citation_data.footnote + '</li>'
    ov_data+= '<li>' + utils.tr('bibliography') + ': ' +  @citation_data.bibliography + '</li>'
    ov_data+= '</ul><ul>'
    ov_data+= '<li><button class="edit">' + utils.tr('edit') + '</button></li>'
    ov_data+= '<li><button class="remove">' + utils.tr('remove') + '</button></li>'
    ov_data+= '</ul>'

    target.append(ov_data)
    target.find('.edit').bind 'click', (ev) =>
      jQuery('body').hallosourcedescriptioneditor({'loid':@citation_data.loid,'data':@citation_data,'element':element,'tip_element':target})

    target.find('.remove').bind 'click', (ev) =>
      #debug.log(element.closest('.cite'))
      #debug.log(element.closest('.cite').prev('.citation'))

      citation = element.closest('.cite').prev('.citation')
      citation_html = ''
      if ( citation.length )
        citation_html = citation.html()
        citation.selectText()
        #TODO: start undo transaction
        document.execCommand('delete',false)
        document.execCommand('insertHTML',false,citation_html)
      if ( element.closest('.cite').length )
        element.closest('.cite').attr('contentEditable',true)
        element.closest('.cite').selectText()
        document.execCommand('delete',false)
      #TODO: stop undo transaction
      jQuery('#' + @overlay_id).remove()
    if !@citation_data.processed
      target.find('.edit').remove()
      target.find('.remove').closest('ul').prev('ul').remove();
