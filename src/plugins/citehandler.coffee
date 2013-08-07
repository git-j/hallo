#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# citehandler
# common functions for citation/publication/sourcedescription handling
root = exports ? this

class root.citehandler
  _instance = undefined # Must be declared here to force the closure on the class
  window.citehandler = @ # export for initialisation in edit*
  @get: (args) -> # Must be a static method
    _instance ?= new _Citehandler args

class _Citehandler
  tips: null
  editable: null
  constructor: (@args) ->
    @settings = {}
    @citation_data = {}
    @tips = jQuery('<span></span>')
    @overlay_id = 'cite_overlay'
    @sourcedescription_loid = 0
    @tips.hallotipoverlay (
      'selector': '.cite'
      'tip_id': @overlay_id
      'data_cb': jQuery.proxy(@_makeTip,@)
    )
  setupSourceDescriptions: (target, editable, add_element_cb) ->
    # debug.log('setup sourcedescriptions...')
    target.find('.SourceDescription').remove()
    domnugget = new DOMNugget();

    domnugget.getSourceDescriptions(editable.element.closest('.nugget')).done (sourcedescriptions) =>
      jQuery.each sourcedescriptions, (index,item) =>
        # debug.log('setup sourcedescriptions...',index,item)
        target.append(add_element_cb(item.title,null,item.type,item.loid).addClass('SourceDescription'))

  _updateSettings: ->
    if ( omc_settings )
      omc_settings.getSettings().done (current_settings) =>
        @settings = current_settings

  _updateCitationDisplay: (element) -> #element: jq-dom-node
    #debug.log('update citation')
    @footnote = ''
    @bibliography = ''
    @citation_data = {}
    @sourcedescription_loid = 0
    domnugget = new DOMNugget();
    return domnugget.getSourceDescriptionData(element)
  
  _makeTip: (target, element) -> # target: jq-dom-node (tip), element: jq-dom-node (tipping element)
    @_updateSettings
    ov_data = ''
    @_updateCitationDisplay(element).done (current_citation_data) =>
      @citation_data = current_citation_data
      #TODO: nicer HTML for better styling
      ov_data+= '<ul>'
      ov_data+= '<li class="style">' + utils.tr('citation in') + ' ' + @citation_data.style_name+ '</li>'
      ov_data+= '<li class="citation">' + @citation_data.cite + '</li>'
      if ( @citation_data.creates_footnote )
        ov_data+= '<li class="footnote">' + utils.tr('footnote') + ': ' + @citation_data.footnote + '</li>'
      if ( @citation_data.creates_bibliography )
        ov_data+= '<li class="bibliography">' + utils.tr('bibliography') + ': ' +  @citation_data.bibliography + '</li>'
      ov_data+= '</ul><ul>'
      ov_data+= '<li><button class="edit action_button">' + utils.tr('edit') + '</button>'
      if ( !@editable || @editable.nugget_only )
        @editable = {}
        @editable.element = element.closest('.nugget')
        @editable.nugget_only = true #     console.log('TODO: find reset point for switching nuggets, otherwise wrong nugget');
      if ( @editable.element )
        if ( element.closest('.cite').hasClass('auto-cite') )
          ov_data+=     '<button class="remove action_button">' + utils.tr('remove from nugget') + '</button></li>'
        else
          ov_data+=     '<button class="remove action_button">' + utils.tr('remove') + '</button></li>'
      ov_data+= '</ul>'

      target.append(ov_data)
      sourcedescriptioneditor= =>
        jQuery('body').hallosourcedescriptioneditor
          'loid':@citation_data.loid
          'data':@citation_data
          'element':element
          'tip_element':target
          'back':true
          'nugget_loid':@editable.element.closest('.Text').attr('id')
      target.find('.edit').bind 'click', sourcedescriptioneditor
      element.bind 'click', sourcedescriptioneditor
      target.find('.remove').bind 'click', (ev) =>
        #debug.log(element)
        #debug.log(element.closest('.cite'))
        #debug.log(element.closest('.cite').prev('.citation'))
        loid = element.closest('.cite').attr('class').replace(/^.*sourcedescription-(\d*).*$/,'$1')
        #console.log(loid);

        citation = element.closest('.cite').prev('.citation')
        is_auto_cite =  element.closest('.cite').hasClass('auto-cite')
        citation_html = ''
        #console.log(citation.length);
        #console.log(element.closest('.cite').length);
        selection = window.getSelection()
        if ( citation.length )
          citation_html = citation.html()
          #TODO: start undo transaction
          #not that simple: citation.selectText()
          range = document.createRange()
          range.selectNodeContents(citation[0])
          selection.removeAllRanges()
          selection.addRange(range)
          #console.log('before:',@editable.element.html());
          if ( document.execCommand('delete',false) )
            document.execCommand('insertHTML',false,citation_html)
          #console.log('after::',@editable.element.html(),citation_html);
        if ( element.closest('.cite').length )
          cite =  element.closest('.cite')
          cite.attr('contenteditable',true)
          #not that simple: element.closest('.cite').selectText()
          range = document.createRange()
          range.selectNodeContents(cite[0])
          selection.removeAllRanges()
          selection.addRange(range)
          if( ! document.execCommand('delete',false) )
            #fallback in case the selection did not work
            $('.sourcedescription-' + loid).prev('.citation').replaceWith(citation_html)
            $('.sourcedescription-' + loid).remove()
          #console.log('citation removed')
          $('.cite').attr('contenteditable',false)
        jQuery('#' + @overlay_id).remove()
        nugget = new DOMNugget();
        #console.log(@editable.element.html());
        if ( is_auto_cite )
          nugget.removeSourceDescription(@editable.element,@citation_data.loid)
        if ( @editable.element )
          @editable.element.find('.auto-cite').remove()
          nugget.updateSourceDescriptionData(@editable.element).done =>
            nugget.resetCitations(@editable.element)
        #TODO: stop undo transaction
      if !@citation_data.processed
        target.find('.edit').remove()
        target.find('.remove').closest('ul').prev('ul').remove();
