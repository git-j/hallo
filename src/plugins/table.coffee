#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a table to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallotable',
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
        @tmpid='mod_' + (new Date()).getTime()
        return if !window.getSelection().rangeCount
        range = window.getSelection().getRangeAt()

        table = $(range.startContainer).closest('table')
        table = $(range.endContainer).closest('table') if !table.length
        tr    = $(range.startContainer).closest('tr')
        tr    = $(range.endContainer).closest('tr') if !tr.length
        td    = $(range.startContainer).closest('td')
        td    = $(range.endContainer).closest('td') if !td.length
        td    = $(range.startContainer).closest('th') if !td.length
        td    = $(range.endContainer).closest('th') if !td.length
        if ( table.length )
          #modify
          @options.editable.element.find('table').each (index,item) =>
            if ( table[0] == item )
              $(item).attr('id',@tmpid)
              rows = 0
              cols = 0
              border = $(item).hasClass('table-border')
              heading = false
              $(item).find('tr').each (rindx,row) =>
                @selected_row = $(row) if ( tr[0] == row )
                $(row).find('th').each (cindx,col) =>
                  @selected_cell = $(col) if ( td[0] == col )
                  cols = cindx if ( cols < cindx )
                  heading = true
                $(row).find('td').each (cindx,col) =>
                  @selected_cell = $(col) if ( td[0] == col )
                  cols = cindx if ( cols < cindx )
                rows = rindx if rows < rindx
              $('#' + contentId + 'cols').val(cols + 1)
              $('#' + contentId + 'rows').val(rows + 1)
              $('#' + contentId + 'border').attr('checked',border)
              $('#' + contentId + 'heading').attr('checked',heading)
        else
          #create
          table_placeholder='<table id="' + @tmpid + '" border="1" class="table-border"></table>'
          document.execCommand('insertHTML',false,table_placeholder)
        recalc = =>
          @recalcHTML(target.attr('id'))
        window.setTimeout recalc, 300
      @dropdownform = @_prepareButton setup, target
      target.bind 'hide', =>
        jQuery('table').each (index,item) =>
          jQuery(item).removeAttr('id')
      buttonset.append @dropdownform
      toolbar.append buttonset

    updateTableHTML: (contentId) ->
      table = $('#' + @tmpid)
      rows = $('#' + contentId + 'rows').val();
      cols = $('#' + contentId + 'cols').val();
      border = $('#' + contentId + 'border').is(':checked');
      heading = $('#' + contentId + 'heading').is(':checked');
      if ( rows=='' || cols == '' || parseInt(rows) == NaN || parseInt(cols) == NaN || rows < 0 || cols < 0 ) 
        return false
      if ( border )
        table.attr('class','table-border')
        table.attr('border','1')
      else
        table.attr('class','table-no-border')
        table.removeAttr('border')
      irow = 0
      table.find('tr').each (rindx,row) =>
        irow = rindx + 1
        if irow > rows
          $(row).remove()
          return
        icol = 0
        $(row).find('th').each (cindx,cell) =>
          icol = cindx + 1
          if icol > cols 
            $(cell).remove()
            return
          if ( !heading )
            $(cell).replaceWith('<td>' + $(cell).html() + '</td>')
        $(row).find('td').each (cindx,cell) =>
          icol = cindx + 1
          if icol > cols 
            $(cell).remove()
            return
          if heading && rindx == 0
            $(cell).replaceWith('<th>' + $(cell).html() + '</th>')

        if ( icol < cols )
          icol = icol + 1
          for c in[icol..cols] by 1
            if ( heading && irow == 1 )
              $(row).append('<th>' + utils.tr('heading') + '</th>')
            else
              $(row).append('<td>' + utils.tr('content') + '</td>')

      if ( irow < rows )
        irow = irow + 1
        for r in[irow..rows] by 1
          row = '<tr>'
          for c in[1..cols] by 1
            if ( heading && r == 1)
              row += '<th>' + utils.tr('heading') + '</th>'
            else
              row += '<td>' + utils.tr('content') + '</td>'
          row+='</tr>'
          table.append(row)
      return table[0].outerHTML #?

    recalcHTML: (contentId) ->
      @html = @updateTableHTML(contentId)

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
        el = jQuery "<li><button class=\"action-button\" id=\"" + @tmpid+element + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addInput("text", "rows","3")
      contentAreaUL.append addInput("text", "cols","3")
      contentAreaUL.append addInput("checkbox", "heading","true")
      contentAreaUL.append addInput("checkbox", "border","true")
      contentAreaUL.append addButton "apply", =>
        @recalcHTML(contentId)
        window.getSelection().removeAllRanges()
        range = document.createRange()
        range.selectNode($('#' + @tmpid)[0])
        window.getSelection().addRange(range)
        document.execCommand 'insertHTML',false, @html
        $('#' + @tmpid).removeAttr('id')
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "remove", =>
        window.getSelection().removeAllRanges()
        range = document.createRange()
        range.selectNode($('#' + @tmpid)[0])
        window.getSelection().addRange(range)
        document.execCommand 'delete',false
        @dropdownform.hallodropdownform('hideForm')
      #requires DOM-modification
      #contentAreaUL.append addButton "insertRow", =>
      #  cols = $('#' + contentId + 'cols').val();
      #  if ( cols == '' || parseInt(cols) == NaN || cols < 0 )
      #    new_row_html = '<tr>'
      #    for c in[1..cols] by 1
      #      html+='<td>' + utils.tr('content') + '</td>';
      #    new_row_html+= '</tr>'
      #    @selected_row.prepend()
      #  @dropdownform.hallodropdownform('hideForm')
      #contentAreaUL.append addButton "removeRow", =>
      #  @selected_row.remove()
      #  @dropdownform.hallodropdownform('hideForm')
      contentArea

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'table'
      if ( window.action_list && window.action_list['hallojs_table'] != undefined )
        button_label =  window.action_list['hallojs_table'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'table'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
