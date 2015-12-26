#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallopublicationselector',
    widget: null
    selectables: ''
    citeproc: new ICiteProc()
    list_toolbar: null
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
      toolbar_actions:
        'Filter': null
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
      @list.setupItemActions({
        'node_dblclick': (node) =>
          @select(node)
          @apply()
        'node_select': (node) =>
          @select(node)
      })
      @list.init($('#publication_list'),omc.PublicationList).done () =>
        @list_toolbar = new ToolBarBase();
        @options.toolbar_actions['Filter'] = @list_toolbar.default_actions.Filter;
        @options.toolbar_actions['FilterUnreferenced'] = @list_toolbar.default_actions.FilterUnreferenced;
        @options.toolbar_actions['FilterSystem'] = @list_toolbar.default_actions.FilterSystem;
        @options.toolbar_actions['SortAlpha'] = @list_toolbar.default_actions.SortAlpha;
        @options.toolbar_actions['SortTime'] = @list_toolbar.default_actions.SortTime;
        @options.toolbar_actions['SortType'] = @list_toolbar.default_actions.SortType;
        @options.toolbar_actions['_filter'] = @list_toolbar.default_actions._filter; # for sort
        @options.toolbar_actions['_removeFilter'] = @list_toolbar.default_actions._removeFilter;
        @list_toolbar.displayBase('body','publicationselector',@options.toolbar_actions,true,jQuery('#publication_list'))
        @list_toolbar.toolbar.stop(true,true); # otherwise z-index is cleared when animation finishes
        @list_toolbar.toolbar.css({'z-index':@options.default_css['z-index'] + 1})
        @options.toolbar_actions['Filter'](null,null,null,@list_toolbar.action_context)
        window.setTimeout () =>
          @list_toolbar.action_context.find('#filter_input').focus() # deferred, otherwise editable grabs back
          @list_toolbar.action_context.css({'padding-top':'2em'})
        , 500
      jQuery(window).resize()

    apply:  ->
      if ( typeof @current_node == 'undefined' )
        utils.error(utils.tr('nothing selected'))
        return
      jQuery('#basepublicationselectortoolbar').remove()
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
        @options.editable.restoreContentPosition()
        @options.editable.getSelectionNode (selection_common) =>
          selection_html = @options.editable.getSelectionHtml()
          if selection_html == ""
            replacement = ""
          else
            replacement = "<span class=\"citation\">" + selection_html + "</span>"
          replacement+= "<span class=\"cite\" contenteditable=\"false\" id=\"#{tmp_id}\"><span class=\"csl\">#{element}</span><span class=\"Z3988\" data-sourcedescriptionloid=\"#{data}\"><span style=\"display:none;\">&#160;</span></span>"
          replacement_node = jQuery('<span></span>').append(replacement)
          z3988 = new Z3988();
          nugget = new DOMNugget();
          z3988_node = jQuery('.Z3988',replacement_node)[0];
          co = new Z3988ContextObject();
          co.sourcedescription = {data:result};
          nugget.addDerivedSourceDescriptionAttributes(z3988_node,co.sourcedescription);
          co.referent.setByValueMetadata(co.referent.fromCSL(nugget.getSourceDescriptionCSL(co.sourcedescription)));
          co.referent.setPrivateData((new Z3988SourceDescription()).toPrivateData(co.sourcedescription));
          delete co.sourcedescription;
          z3988.setFormat(new Z3988KEV());
          z3988.attach(z3988_node,co);
          selection = rangy.getSelection()
          if ( selection.rangeCount > 0 )
            range = selection.getRangeAt(0)
            range.deleteContents()
          else
            range = rangy.createRange()
            range.selectNode(@options.editable.element[0])
            range.collapse(false) # toEnd
          if ( selection_html == '' )
            if ( selection_common.attr('contenteditable') == 'true' && !selection_common.hasClass('rangySelectionBoundary'))
              selection_common.append(replacement_node.contents())
            else
              replacement_node.insertAfter(selection_common) # avoid inserting _in_ hyperlinks
          else
            range.insertNode(replacement_node[0])

        nugget = new DOMNugget()
        @options.editable.element.closest('.nugget').find('.auto-cite').remove()
        occ.UpdateNuggetSourceDescriptions({loid:target_loid})
        # launch sourcedescription editor with newly created sourcedescription
        new_sd_node = jQuery('#' + tmp_id);
        new_sd_node.removeAttr('id')
        #console.log(new_sd_node)
        nugget.commitSourceDescriptionChanges(@options.editable.element).done =>
          #console.log(new_sd_node)
          @openSourceDescriptionEditor(nugget,target_loid,new_sd_node)
        @back()

    openSourceDescriptionEditor: (nugget,target_loid,new_sd_node) ->
      nugget.getSourceDescriptionData(new_sd_node).done (citation_data) =>
        jQuery('body').hallosourcedescriptioneditor
          'loid': citation_data.loid
          'element': new_sd_node
          'back': false
          'nugget_loid': target_loid

    back: ->
      @widget.remove()
      jQuery('#basepublicationselectortoolbar').remove()
      jQuery('body').css({'overflow':'auto'})
      @options.editable.restoreContentPosition()
      @options.editable.activate()

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
                jQuery(node).find('.citation_data_processed').append('<span class="cite"><span class="csl" id="' + key + '"></span></span></div>')
            @citeproc.resetCitationData()
            @citeproc.appendCitationData(citation_data)
            @citeproc.citation_style = settings['default_citation_style']
            @citeproc.process('#node_' + loid + ' .citation_data_processed', settings.iso_language)
            endnotes = @citeproc.endnotes()
            endnotes = endnotes.replace(/\[1\]/,'')
            jQuery(node).find('.citation_data_processed').html(endnotes).slideDown()

    _createInput: (identifier, label, value) ->
      input = jQuery('<div><label for="' + identifier + '">' + label + '</label><input id="' + identifier + '" type="text" value="<!--user-data-->"/></div>')
      input.find('input').bind 'blur', (event) =>
        @_formChanged(event,@options)
      input.find('input').val(value)
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
