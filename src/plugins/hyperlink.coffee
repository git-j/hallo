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
      elements: [
        'rows'
        'cols'
        'border'
      ]
      buttonCssClass: null

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      toolbar.append target
      setup= =>
        return if !window.getSelection().rangeCount
        @tmpid='mod_' + (new Date()).getTime()
        sel = window.getSelection()
        range = sel.getRangeAt()
        @cur_hyperlink = null
        @action = 'insert'
        @options.editable.element.find('a').each (index,item) =>
          if ( sel.containsNode(item,true) )
            @cur_hyperlink = jQuery(item)
            @cur_hyperlink.attr('id',@tmpid)
            @action = 'update'
            return false # break
        if ( @cur_hyperlink && @cur_hyperlink.length )
          #modify
          url = @cur_hyperlink.attr('href')
          notes = @cur_hyperlink.attr('title')
          title = @cur_hyperlink.text()
          $('#' + contentId + 'url').val(url)
          $('#' + contentId + 'notes').val(notes)
          $('#' + contentId + 'title').val(title)
        else
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
        recalc = =>
          @recalcHTML(target.attr('id'))
        window.setTimeout recalc, 300
      @dropdownform = @_prepareButton setup, target
      target.bind 'hide', =>
        jQuery('a').each (index,item) =>
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

    recalcHTML: (contentId) ->
      @html = @updateHyperlinkHTML(contentId)
      @options.editable.store()

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul')


      addInput = (type,element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><input type=\"#{type}\" id=\"#{elid}\"/></li>"
        if ( el.find('input').is('input[type="checkbox"]') && default_value=="true" )
          el.find('input').attr('checked',true);
        else if ( default_value )
          el.find('input').val(default_value)
        recalc= =>
          @recalcHTML(contentId)
        el.find('input').bind('keyup change',recalc)

        el
      addButton = (element,event_handler) =>
        el = jQuery "<li><button class=\"action_button\" id=\"" + @tmpid+element + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addInput("text", "url", "")
      contentAreaUL.append addInput("text", "notes", "")
      contentAreaUL.append addInput("text", "title", "")
      this_editable = @options.editable
      contentAreaUL.append addButton "select nugget", =>
        @dropdownform.hallodropdownform('hideForm')
        window.__start_mini_activity = true
        console.log(this_editable)
        $('body').hallonuggetselector({'editable':this_editable,'hyperlink_id':@tmpid});
      contentAreaUL.append addButton "apply", =>
        @recalcHTML(contentId)
        $('#' + @tmpid).removeAttr('id')
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "remove", =>
        window.getSelection().removeAllRanges()
        modified = false
        if ( $('#' + @tmpid).text() != utils.tr('no title provided') )
            modified = true
        range = document.createRange()
        range.selectNode($('#' + @tmpid)[0])
        range_contents = jQuery(range.extractContents()).text();
        window.getSelection().addRange(range)
        range.deleteContents();
        if ( modified )
          range.insertNode($('<span>' + range_contents + '</span>')[0])
        @dropdownform.hallodropdownform('hideForm')
      contentArea

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
