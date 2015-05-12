#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# citehandler
# common functions for citation/publication/sourcedescription handling
# this is a singleton class that needs to be initialized outside of hallo and does
# heavy usage of non-hallo infrastructure
# creates a tooltip when hovering a '.cite' span that displays more information about the cite
# this functions require to work even if hallo is not enabled
# uses citeproc-js to produce a full-bibliography and adds buttons for edit/remove
#     requires: DOMNugget
#               SettingsModelConnector (omc_settings)
#               hallotipoverlay (tipoverlay.coffee)
#               ObjectContextConnector (GotoObject)
#               utils.correctAndOpenFilepath
#               wke.openUrlInBrowser
#     uses ??? to s????
root = exports ? this

# singleton interface
class root.citehandler
  _instance = undefined # Must be declared here to force the closure on the class
  window.citehandler = @ # export for initialisation in edit*
  @get: (args) -> # Must be a static method
    _instance ?= new _Citehandler args

# private class
class _Citehandler
  tips: null
  editable: null
  tipping_element: null
  tip_element: null
  constructor: (@args) ->
    @settings = {}
    @citation_data = {}
    @tips = jQuery('<span></span>')
    @overlay_id = 'cite_overlay'
    @_makeTip()

  # remove all editable sourcedescription and recreate them with the current data
  # called from the toolbar
  setupSourceDescriptions: (target, editable, add_element_cb) ->
    # debug.log('setup sourcedescriptions...')
    target.find('.SourceDescription').remove()
    domnugget = new DOMNugget();

    domnugget.getSourceDescriptions(editable.element.closest('.nugget')).done (sourcedescriptions) =>
      jQuery.each sourcedescriptions, (index,item) =>
        # debug.log('setup sourcedescriptions...',index,item)
        target.append(add_element_cb(item.title,null,item.type,item.loid).addClass('SourceDescription'))

  # update settings from the current application settings
  # usualy the relevant change may be the citation-style
  _updateSettings: ->
    if ( omc_settings )
      omc_settings.getSettings().done (current_settings) =>
        @settings = current_settings

  # with multiple editables, the given element (usualy triggered by mouseover)
  # must find its parent editable in order to perform correctly
  # updates the @editable accordingly and falls back to finding the @editable
  # when hallo was never initialized
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

  # create the HTML for the hallotip by evaluating the nugget sourcedescription, the citation data
  # and creating bibliographies
  _makeTip: () -> # (target, element) -> # target: jq-dom-node (tip), element: jq-dom-node (tipping element)
    @_updateSettings()
    is_auto_cite = false
    if ( typeof @editable == 'object' && null != @editable && @editable.element )
      if ( @tipping_element.closest('.cite').hasClass('auto-cite') )
        is_auto_cite = true;
    if ( window.citeproc )
      citation_processor = window.citeproc
    else
      citation_processor = new ICiteProc()
    domnugget = new DOMNugget();
    jQuery('body').citationPopup (
      citation_processor: citation_processor
      class_name: 'hallo_sourcedescription_popup'
      goto_action: (publication_loid) =>
        occ.GotoObject(publication_loid)
        # activity_router.gotoInstance(publication_loid)
      goto_url_action: (url) =>
        wke.openUrlInBrowser(url)
      goto_file_action: (filename) =>
        utils.correctAndOpenFilePath(filename)
      edit_action: jQuery.proxy(@_sourcedescriptioneditorAction,@)
      remove_action: jQuery.proxy(@_removeAction,@)
      remove_from_nugget_action: jQuery.proxy(@_removeAction,@)
      get_source_description_data: domnugget.getSourceDescriptionData
      citation_selector: '.cite'
    )

  _sourcedescriptioneditorAction: (citation_data, tip_element, tipping_element) =>
    @_sync_editable(tipping_element,true)
    dom_nugget = tipping_element.closest('.nugget')
    if ( typeof UndoManager != 'undefined' && typeof @editable.undoWaypointIdentifier == 'function' )
      wpid = @editable.undoWaypointIdentifier(dom_nugget)
      undo_stack = (new UndoManager()).getStack(wpid)
      undo_stack.clear()
    jQuery('body').hallosourcedescriptioneditor
      'loid': citation_data.loid
      'data': citation_data
      'element': tipping_element
      'tip_element': tip_element
      'back':true
      'nugget_loid':@editable.element.closest('.Text').attr('id')

  _removeAction: (citation_data, tip_element, tipping_element) =>
    nugget = new DOMNugget();
    @_sync_editable(tipping_element,true)
    loid = tipping_element.closest('.cite').attr('class').replace(/^.*sourcedescription-(\d*).*$/,'$1')
    #console.log(loid);

    citation = tipping_element.closest('.cite').prev('.citation')
    is_auto_cite =  tipping_element.closest('.cite').hasClass('auto-cite')
    citation_html = ''
    if ( !citation_data.processed )
      loid = tipping_element.closest('.cite').attr('class').replace(/^.*sourcedescription-(\d*).*$/,'$1')
      citation = tipping_element.closest('.cite').prev('.citation')
      if ( citation.length )
        citation_html = citation.html()
        #not that simple: citation.selectText()
        citation.contents().unwrap();
        #console.log(citation.html())
      if ( tipping_element.closest('.cite').length )
        cite =  tipping_element.closest('.cite')
        #not that simple: @tipping_element.closest('.cite').selectText()
        cite.remove()
      jQuery('#' + @overlay_id).remove()
      return

    if ( citation.length )
      citation_html = citation.html()
      #not that simple: citation.selectText()
      citation.contents().unwrap();
      #console.log(citation.html())
    if ( is_auto_cite )
      sd_loid = citation_data.loid
      nugget.removeSourceDescription(@editable.element,sd_loid)
    if ( tipping_element.closest('.cite').length )
      cite = tipping_element.closest('.cite')
      #not that simple: @tipping_element.closest('.cite').selectText()
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
      publication_loid = citation_data.ploid
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