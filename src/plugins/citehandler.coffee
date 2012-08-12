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
    @_overlay_can_hide = 0
    @_overlay_node = null
    @_overlay_timeout = 0
    @settings = {}
    @citation_data = {}
    @citeproc = null
    @citeproc = new ICiteProc() if ICiteProc
    @sourcedescription_loid = 0
    @footnote = ''
    @bibliograpy = ''
    @tips.hallotipoverlay ({'options': {'selector': '.cite','data_cb': jQuery.proxy(@_makeTip,@) }})

  setupSourceDescriptions: (target, editable, add_element_cb) ->
    debug.log('setup sourcedescriptions...')
    target.find('.SourceDescription').remove()
    domnugget = new DOMNugget();
    if editable.element.parent('.nugget').length
      sourcedescriptions = domnugget.getSourceDescriptions(editable.element.parent('.nugget'))
    else
      sourcedescriptions = domnugget.getSourceDescriptions(editable.element.parent('.Text'))
    jQuery.each sourcedescriptions, (index,item) =>
      target.append(add_element_cb(item.title,null,item.type,item.index).addClass('SourceDescription'))

  _updateSettings: ->
    @settings = JSON.parse(omc_settings.getSettings()) if omc_settings


  _formChanged: (event) ->
    target = jQuery(event.target)
    debug.log('form changed' + target.html())
    path = target.attr('id')
    data = target.val()
    if omc && @sourcedescription_loid
      omc.storePublicationDescriptionAttribute(@sourcedescription_loid,path,data)

  _updateCitationDisplay: (element) -> #element: jq-dom-node
    debug.log('update citation')
    @footnote = ''
    @bibliography = ''
    @citation_data = {}
    @sourcedescription_loid = 0
    if @citeproc
      citation = jQuery ('<span id="_temporary_citation"></span>')
      em_id = element.attr('id')
      citation_data = ''
      element.parent().parent().find('.source_descriptions .SourceDescription').each (index,item) =>
        cindx = jQuery(item).find('.citation_index').text()
        if em_id == 'ITEM-' + cindx
          citation_data = jQuery(item).find('.citation_data').text()
          citation_data = citation_data.replace(/, \"ITEM-/,'"ITEM-')
          citation.append('<span id="' + em_id + '" class="cite"></span>')
          @sourcedescription_loid = jQuery(item).attr('id')
          @citation_data = JSON.parse('{' + citation_data + '}')[em_id]
      if citation_data != ''
        @citeproc.resetCitationData()
        @citeproc.appendCitationData('{')
        @citeproc.appendCitationData(citation_data)
        @citeproc.appendCitationData('}')

        @citeproc.citation_style = @settings.citation_style # TODO: settnigs from document
        element.append(citation)
        @citeproc.process('#_temporary_citation');
        @bibliography = @citeproc.endnotes()
        @footnote = @citeproc.footnote(em_id)
        jQuery('#_temporary_citation').remove()

  _makeTip: (element) -> # target: jq-dom-node
    @_updateSettings
    ov_data = '<h1>' + element.html() + '</h1>'
    @_updateCitationDisplay(element)
    #TODO: nicer HTML for better styling
    ov_data+= '<ul>'
    ov_data+= '<li>' + utils.tr('citation in') + ' ' + @settings.default_citation_style+ ':</li>'
    ov_data+= '<li>' + utils.tr('footnote') + ': ' + @footnote + '</li>'
    ov_data+= '<li>' + utils.tr('bibliography') + ': ' +  @bibliography + '</li>'
    ov_data+= '<li><button class="edit">' + utils.tr('edit') + '</button></li>'
    ov_data+= '</ul>'
    #<div class="more_view">'
    # varies for different sourcedescription types
    #@citation_data['number_of_pages'] = '' if !@citation_data['number_of_pages']
    #ov_data+= '<p>' + utils.tr('pages') + ': <input type="text" id="number_of_pages" value="' + @citation_data['number_of_pages']+ '" class="edit_attribute"/></p>'
    #@citation_data['rights'] = '' if !@citation_data['rights']
    #ov_data+= '<p>' + utils.tr('rights') + ': <textarea id="rights" class="edit_attribute">' + @citation_data['rights'] + '</textarea></p>'

    #@citation_data['notes'] = '' if ! @citation_data['notes']
    #ov_data+= '<p>' + utils.tr('notes') + ': <textarea id="notes" class="edit_attribute">' + @citation_data['notes'] + '</textarea></p>'
    #ov_data+= '</div></div>'

    element.append(ov_data)
    element.find('.edit_attribute').bind 'blur', @_formChanged
    overlay.find('.edit').bind 'click', (ev) =>
      jQuery('body').sourceDescriptionEditor({'loid':@sourcedescription_loid,'data':@citation_data})