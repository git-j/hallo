#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallopublicationselector',
    widget: null
    selectables: ''
    citeproc: new ICiteProc()
    options:
      editable: null
      range: null
      toolbar: null
      uuid: ''
      element: null
      tip_element: null
      data: null
      loid: null
      has_changed: false
      default_css:
        'width': '100%'
        'height': '100%'
        'top': 0
        'left': 0
        'position': 'fixed'
        'z-index': 999999
    _init: ->
      #debug.log('publicationselector initialized',@options)
      @widget = jQuery('<div id="publication_selector"></div>')
      @widget.addClass('form_display');
      jQuery('body').css({'overflow':'hidden'})
      jQuery('body').append(@widget)
      @widget.append('<div id="publication_list" style="background-color:white; margin-bottom: 4px"></div>');
      @widget.append('<button class="publication_selector_back action_button">' + utils.tr('back') + '</button>');
      @widget.append('<button class="publication_selector_apply action_button">' + utils.tr('apply') + '</button>');
      @widget.css @options.default_css
      @widget.find('.publication_selector_back').bind 'click', =>
        @back()
      @widget.find('.publication_selector_apply').bind 'click', =>
        @apply()
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      @list = new List();
      @list.init($('#publication_list'),omc.PublicationList);
      @list.setupItemActions($('#publication_list'),{
        'node_dblclick': (node) =>
          @select(node)
          @apply()
        'node_select': (node) =>
          @select(node)
      })
      #TODO: show filter/sort
      jQuery(window).resize()

    apply:  ->
      if ( typeof @current_node == 'undefined' )
        utils.error(utils.tr('nothing selected'))
        return
      publication_loid = @current_node.replace(/node_/,'')
      target_loid = @options.editable.element.closest('.Text').attr('id').replace(/node/,'')
      dfo = omc.AssociatePublication(target_loid,publication_loid)
      dfo.fail (error) =>
        @back()
      #tmp_id is used to identify new sourcedescription after it has been inserted for further editing
      tmp_id = 'tmp_' + (new Date()).getTime()
      dfo.done (result) =>
        data = result.loid
        element = @current_node_label
        selection =  @options.editable.element.find(@options.editable.selection_marker)
        old = selection
        if old.html() == "" || old.html() == "&nbsp;" || old.text() == " "
          replacement = ""
        else
          replacement = "<span class=\"citation\">" + old.html() + "</span>"
        replacement+= "<span class=\"cite sourcedescription-#{data}\" contenteditable=\"false\" id=\"#{tmp_id}\">#{element}</span>"
        if ( selection.length )
          range = document.createRange()
          sel = window.getSelection()
          range.selectNode(selection[0])
          if ( selection.text() == '' )
            jQuery(replacement).insertAfter(selection.parent()) # avoid inserting _in_ hyperlinks
          else
            selection.html(replacement)
          selection_nodes =  @options.editable.element.find(@options.editable.selection_marker)
          selection_nodes.each (index,item) =>
            sel_item = jQuery(item)
            sel_item.contents().unwrap()

        nugget = new DOMNugget()
        @options.editable.element.closest('.nugget').find('.auto-cite').remove()
        occ.UpdateNuggetSourceDescriptions({loid:target_loid})
        # launch sourcedescription editor with newly created sourcedescription
        new_sd_node = jQuery('#' + tmp_id);
        new_sd_node.removeAttr('id')
        #console.log(new_sd_node)
        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element)
          #console.log(new_sd_node)
          new_sd_class = new_sd_node.attr('class')
          if new_sd_class
            sd_loid = new_sd_class.replace(/.*sourcedescription-(\d*).*/,"$1");
            nugget.getSourceDescriptionData(new_sd_node).done (citation_data) =>
              jQuery('body').hallosourcedescriptioneditor
                'loid':sd_loid
                'data':citation_data
                'element':new_sd_node
                'back':false
                'nugget_loid':target_loid
        @back()


    back: ->
      @widget.remove()
      jQuery('body').css({'overflow':'auto'})
      @options.editable.restoreContentPosition()

    select: (node) ->
      @current_node = jQuery(node).attr('id')
      @current_node_label = jQuery(node).text()
      @widget.find(".citation_data_processed").slideUp 'slow', () ->
        jQuery(this).remove()
      omc_settings.getSettings().done (settings) =>
        @citeproc.init().done =>
          loid = jQuery(node).attr('id').replace(/node_/,'')
          omc.getPublicationCitationData(loid).done (citation_data) =>
            if ( jQuery(node).find(".citation_data_processed").length == 0 )
              jQuery(node).append('<div class="citation_data_processed"></div>')
              jQuery.each citation_data, (key,value) =>
                jQuery(node).find('.citation_data_processed').append('<span class="cite" id="' + key + '"></span></div>')
            @citeproc.resetCitationData()
            @citeproc.appendCitationData(JSON.stringify(citation_data))
            @citeproc.citation_style = settings['default_citation_style']
            @citeproc.process('#node_' + loid + ' .citation_data_processed', settings.iso_language)
            endnotes = @citeproc.endnotes()
            endnotes = endnotes.replace(/\[1\]/,'')
            jQuery(node).find('.citation_data_processed').html(endnotes).slideDown()

    _createInput: (identifier, label, value) ->
      input = jQuery('<div><label for="' + identifier + '">' + label + '</label><input id="' + identifier + '" type="text" value="' + value + '"/></div>')
      input.find('input').bind 'blur', (event) =>
        @_formChanged(event,@options)
      input
    _formChanged: (event, options) ->
      target = jQuery(event.target)
      #debug.log('form changed' + target.html())
      path = target.attr('id')
      data = target.val()
      if omc && options.loid
        omc.storePublicationDescriptionAttribute(options.loid,path,data)
        #debug.log('stored',options.loid,path,data)

    _create: ->
      #debug.log('created');
      @

)(jQuery)
