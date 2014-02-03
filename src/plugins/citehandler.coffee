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
    #TODO update publication_type from sourcedescription
    return domnugget.getSourceDescriptionData(element)

  _sync_editable: (element, change_focus) ->
    @editable = window.hallo_current_instance.editable
    tip_nugget = element.closest('.nugget');
    if ( @editable && @editable.closest('.nugget')[0] != tip_nugget)
      @editable = null

    if ( typeof @editable == 'undefined' || ! @editable )
      @editable = {}
      @editable.element = element.closest('[contenteditable="true"]')
      if ( !@editable.element.length )
        @editable.element = element.closest('.nugget').find('>.content').eq(0)
      @editable.is_auto_editable = true
      if ( change_focus )
        @editable.element.hallo('enable')
        @editable.element.focus()
      @editable.nugget_only = true

  _makeTip: (target, element) -> # target: jq-dom-node (tip), element: jq-dom-node (tipping element)
    @_updateSettings()
    ov_data = ''
    update_dfd = @_updateCitationDisplay(element)
    update_dfd.done (current_citation_data) =>
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
        @_sync_editable(element,false)
      if ( @editable.element )
        if ( element.closest('.cite').hasClass('auto-cite') )
          ov_data+=     '<button class="remove action_button">' + utils.tr('remove from nugget') + '</button></li>'
        else
          ov_data+=     '<button class="remove action_button">' + utils.tr('remove') + '</button></li>'
      #if ( @citation_data.URL )
      #  ov_data+='<button class="open_url action_button">' + utils.tr_action_title('FileOpenUrl') + '</button></li>'
      #if ( @citation_data.location_in_filesystem )
      #  ov_data+='<button class="open_file_path action_button">' + utils.tr_action_title('FileOpen') + '</button></li>'
      ov_data+= '</ul>'

      target.append(ov_data)
      sourcedescriptioneditor= =>
        @_sync_editable(element,true)
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
      # console.log(@citation_data)
      target.find('.edit').bind 'click', sourcedescriptioneditor
      target.find('.goto').bind 'click', (ev) =>
        occ.GotoObject(@citation_data.publication_loid)
      target.find('.open_url').bind 'click', (ev) =>
        wke.openUrlInBrowser(@citation_data.URL)
      target.find('.open_file_path').bind 'click', (ev) =>
        wke.openUrlInBrowser(@citation_data.location_in_filesystem)
      element.bind 'click', sourcedescriptioneditor
      target.find('.remove').bind 'click', (ev) =>
        #debug.log(element)
        #debug.log(element.closest('.cite'))
        #debug.log(element.closest('.cite').prev('.citation'))
        nugget = new DOMNugget();
        @_sync_editable(element,true)
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
        if ( is_auto_cite )
          sd_loid = @citation_data.loid
          nugget.removeSourceDescription(@editable.element,sd_loid)
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
        #console.log(@editable.element.html());
        if ( is_auto_cite )
          publication_loid = @citation_data.ploid
          dom_nugget = @editable.element.closest('.nugget')
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
              #console.warn('@editable.undoWaypoint()')
              if ( typeof MathJax != 'undefined' )
                MathJax.Hub.Queue(['Typeset',MathJax.Hub])

      if !@citation_data.processed
        target.find('.edit').remove()
        target.find('.remove').closest('ul').prev('ul').remove();
    update_dfd.fail () =>
      ov_data+= '<ul class="actions">'
      ov_data+= '<li>'
      if ( !@editable || (typeof @editable != 'undefined' && @editable.nugget_only) || @editable.is_auto_editable )
        @_sync_editable(element,false)
      if ( @editable.element )
        ov_data+=     '<button class="remove action_button">' + utils.tr('remove') + '</button></li>'
      ov_data+= '</ul>'

      target.append(ov_data)
      target.find('.remove').bind 'click', (ev) =>
        @_sync_editable(element,true)
        loid = element.closest('.cite').attr('class').replace(/^.*sourcedescription-(\d*).*$/,'$1')
        citation = element.closest('.cite').prev('.citation')
        if ( citation.length )
          citation_html = citation.html()
          #not that simple: citation.selectText()
          citation.contents().unwrap();
          #console.log(citation.html())
        if ( element.closest('.cite').length )
          cite =  element.closest('.cite')
          #not that simple: element.closest('.cite').selectText()
          cite.remove()
        jQuery('#' + @overlay_id).remove()
