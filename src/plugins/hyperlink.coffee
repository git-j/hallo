#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a hyperlink to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallohyperlink',
    dropdownform: null
    tmpid: 0
    selected_row: null
    selected_cell: null
    html: null
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null
      edit_url: true
      edit_title: true
      use_form: false

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      toolbar.append target
      setup= =>
        return if rangy.getSelection().rangeCount == 0
        selection = rangy.getSelection()
        range = selection.getRangeAt(0)
        @options.editable.undoWaypointStart('hyperlink')
        @tmpid='mod_' + (new Date()).getTime()
        @cur_hyperlink = null
        @action = 'insert'
        @options.editable.element.find('a').each (index,item) =>
          if ( sel.containsNode(item,true) )
            @cur_hyperlink = jQuery(item)
            @cur_hyperlink.attr('id',@tmpid)
            @action = 'modify'
            return false # break
        if ( @cur_hyperlink && @cur_hyperlink.length )
          @action = 'modify'
          url = @cur_hyperlink.attr('href')
          notes = @cur_hyperlink.attr('title')
          title = @cur_hyperlink.text()
          $('#' + contentId + 'url').val(url)
          $('#' + contentId + 'notes').val(notes)
          $('#' + contentId + 'title').val(title)
          @cur_hyperlink.attr('id',@tmpid)
        else
          @action = 'insert'
          cur_selection = jQuery(range.extractContents()).text()
          if ( cur_selection == '' ) 
            cur_selection = utils.tr('no title provided')
          @cur_hyperlink = jQuery('<a href="https://refeus.de" id="' + @tmpid + '">' + cur_selection + '</a>');
          range.insertNode(@cur_hyperlink[0]);
          $('#' + contentId + 'url').val(@cur_hyperlink.attr('href'))
          $('#' + contentId + 'notes').val("")
          $('#' + contentId + 'title').val(cur_selection)
          #console.log(@cur_hyperlink)
          @updateHyperlinkHTML(contentId)
        if ( !@options.use_form )
          if ( @action == 'modify')
            @_removeAction()
          else
            @_selectAction()
          return false;
        else
          recalc = =>
            @recalcHTML()
          window.setTimeout recalc, 300
        return true
      @dropdownform = @_prepareButton setup, target
      target.bind 'hide', =>
        jQuery('a').each (index,item) =>
          if ( ! window.__start_mini_activity )
            jQuery(item).removeAttr('id')

          jQuery(item).remove() if jQuery(item).attr('href') == ''
      buttonset.append @dropdownform
      toolbar.append buttonset

    updateHyperlinkHTML: (contentId) ->
      hyperlink = $('#' + @tmpid)
      url = $('#' + contentId + 'url').val();
      notes = $('#' + contentId + 'notes').val();
      title = $('#' + contentId + 'title').val();
      #console.log(url)
      hyperlink.attr('href',url)
      hyperlink.attr('title',notes)
      hyperlink.text(title)
      return hyperlink[0].outerHTML #?

    recalcHTML: () ->
      @html = @updateHyperlinkHTML(@_content_id)
      @options.editable.store()

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul')
      @_content_id = contentId


      addInput = (type,element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><input type=\"#{type}\" id=\"#{elid}\"/></li>"
        if ( el.find('input').is('input[type="checkbox"]') && default_value=="true" )
          el.find('input').attr('checked',true);
        else if ( default_value )
          el.find('input').val(default_value)
        recalc= =>
          @recalcHTML()
        el.find('input').bind('keyup change',recalc)

        el
      addButton = (element,event_handler) =>
        el = jQuery "<li><button class=\"action_button\" id=\"" + @tmpid+element + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      if ( @options.edit_url )
        contentAreaUL.append addInput("text", "url", "")
      else
        contentAreaUL.append addInput("hidden", "url", "")
      
      contentAreaUL.append addInput("text", "notes", "")
      if ( @options.edit_title )
        contentAreaUL.append addInput("text", "title", "")
      else
        contentAreaUL.append addInput("hidden", "title", "")
      this_editable = @options.editable
      contentAreaUL.append addButton "select nugget", =>
        @_selectAction()
      contentAreaUL.append addButton "apply", =>
        @_applyAction()
      contentAreaUL.append addButton "remove", =>
        @_removeAction()
      contentArea
    _applyAction: () ->
      @recalcHTML()
      $('#' + @tmpid).removeAttr('id')
      @options.editable.undoWaypointCommit()
      @dropdownform.hallodropdownform('hideForm')
    _removeAction: () ->
      modified = false
      if ( $('#' + @tmpid).text() != utils.tr('no title provided') )
        modified = true
      if ( modified )
        $('#' + @tmpid).replaceWith($('#' + @tmpid).text())

      else
        $('#' + @tmpid).remove()

      @options.editable.undoWaypointCommit()
      @dropdownform.hallodropdownform('hideForm')
    _selectAction: () ->
      current_hyperlink = jQuery('#' + @tmpid)
      current_hyperlink.removeAttr('id')
      current_hyperlink.addClass(@tmpid)
      current_hyperlink.addClass('nugget_select_target')
      @dropdownform.hallodropdownform('hideForm')
      $('body').hallonuggetselector({'editable':@options.editable,'hyperlink_class':@tmpid});
    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'hyperlink'
      if ( window.action_list && window.action_list['hallojs_hyperlink'] != undefined )
        button_label =  window.action_list['hallojs_hyperlink'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'hyperlink'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
