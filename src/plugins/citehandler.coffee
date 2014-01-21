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
    @_updateSettings()
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
      ov_data+= '</ul><ul class="actions">'
      # TODO: rewrite to use actions
      ov_data+= '<li><button class="edit action_button">' + utils.tr('edit') + '</button></li>'
      ov_data+= '<li><button class="goto action_button">' + utils.tr('goto') + '</button></li>'
      ov_data+= '<li>'
      if ( !@editable || (typeof @editable != 'undefined' && @editable.nugget_only) || @editable.is_auto_editable )
        @editable = window.hallo_current_instance.editable
        if ( typeof @editable == 'undefined' || ! @editable )
          @editable = {}
          @editable.element = element.closest('[contenteditable="true"]')
          if ( !@editable.element.length )
            @editable.element = element.closest('.nugget').find('>.content').eq(0)
          @editable.is_auto_editable = true
          @editable.element.hallo('enable')
          @editable.element.focus()
        @editable.nugget_only = true #     console.log('TODO: find reset point for switching nuggets, otherwise wrong nugget');
      if ( @editable.element )
        if ( element.closest('.cite').hasClass('auto-cite') )
          ov_data+=     '<button class="remove action_button">' + utils.tr('remove from nugget') + '</button></li>'
        else
          ov_data+=     '<button class="remove action_button">' + utils.tr('remove') + '</button></li>'
      ov_data+= '</ul>'

      target.append(ov_data)
      sourcedescriptioneditor= =>
        dom_nugget = element.closest('.nugget')
        if ( typeof UndoManager != 'undefined' && typeof @editable.undoWaypointIdentifier == 'function' )
          wpid = @editable.undoWaypointIdentifier(dom_nugget)
          undo_stack = (new UndoManager()).getStack(wpid)
          undo_stack.clear()
        jQuery('body').hallosourcedescriptioneditor
          'loid':@citation_data.loid
          'data':@citation_data
          'element':element
          'tip_element':target
          'back':true
          'nugget_loid':@editable.element.closest('.Text').attr('id')
      target.find('.edit').bind 'click', sourcedescriptioneditor
      target.find('.goto').bind 'click', (ev) =>
        console.log(@citation_data)
        occ.GotoObject(@citation_data.publication_loid)
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
        #if ( typeof UndoCommand != 'undefined' )
        #  undo_command = new UndoCommand()
        #  undo_command.id = 'remove-publication'
        #  undo_command.before_data = @editable.element.html()
        if ( citation.length )
          citation_html = citation.html()
          #not that simple: citation.selectText()
          citation.contents().unwrap();
          #console.log(citation.html())
        if ( element.closest('.cite').length )
          cite =  element.closest('.cite')
          #not that simple: element.closest('.cite').selectText()
          cite.remove()
          $('.sourcedescription-' + loid).prev('.citation').replaceWith(citation_html)
          $('.sourcedescription-' + loid).remove()
          #console.log('citation removed')
          $('.cite').attr('contenteditable',false)
          @editable.element.hallo('enable')
          @editable.element.focus()
          @editable.element.hallo('setModified')
          @editable.element.blur()
        jQuery('#' + @overlay_id).remove()
        nugget = new DOMNugget();
        #console.log(@editable.element.html());
        if ( is_auto_cite )
          element = @editable.element
          sd_loid = @citation_data.loid
          publication_loid = @citation_data.ploid
          dom_nugget = element.closest('.nugget')
          nugget.removeSourceDescription(@editable.element,sd_loid)
          if ( typeof UndoManager != 'undefined' && typeof @editable.undoWaypointIdentifier == 'function' )
            wpid = @editable.undoWaypointIdentifier(dom_nugget)
            undo_stack = (new UndoManager()).getStack(wpid)
            undo_stack.clear()
          #undo_command.undo = (event) =>
          #  undo_command.dfd = omc.AssociatePublication(nugget_loid,publication_loid)
          #  undo_command.postdo()
          #undo_command.redo = (event) =>
          #  undo_command.dfd = nugget.removeSourceDescription(@editable.element,sd_loid)
          #  undo_command.postdo()
          #undo_command.postdo = (event) =>
            # nothing            

        if ( @editable.element )
          @editable.element.closest('.nugget').find('.auto-cite').remove()
          nugget.prepareTextForEdit(@editable.element)
          nugget.updateSourceDescriptionData(@editable.element).done =>
            nugget.resetCitations(@editable.element).done =>
              #@editable.element.hallo('disable')
              console.warn('@editable.undoWaypoint()')
              if ( typeof MathJax != 'undefined' )
                MathJax.Hub.Queue(['Typeset',MathJax.Hub])

      if !@citation_data.processed
        target.find('.edit').remove()
        target.find('.remove').closest('ul').prev('ul').remove();
