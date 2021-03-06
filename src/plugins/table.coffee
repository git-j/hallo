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
      setup= (select_target,target_id) =>
        contentId = target_id
        @tmpid='mod_' + (new Date()).getTime()
        return false if rangy.getSelection().rangeCount == 0
        range = rangy.getSelection().getRangeAt(0)

        table = $(range.startContainer).closest('table')
        table = $(range.endContainer).closest('table') if !table.length
        tr    = $(range.startContainer).closest('tr')
        tr    = $(range.endContainer).closest('tr') if !tr.length
        td    = $(range.startContainer).closest('td')
        td    = $(range.endContainer).closest('td') if !td.length
        td    = $(range.startContainer).closest('th') if !td.length
        td    = $(range.endContainer).closest('th') if !td.length
        table_selected = false
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
              if ( border )
                $('#' + contentId + 'border').addClass('active')
              else
                $('#' + contentId + 'border').removeClass('active')
              if ( heading )
                $('#' + contentId + 'heading').addClass('active')
              else
                $('#' + contentId + 'heading').removeClass('active')
              table_selected = true
        if !table_selected
          #create
          table_placeholder = '<table id="' + @tmpid + '" class="table-border"></table>'
          table_placeholder_node = jQuery(table_placeholder)
          selection_html = @options.editable.getSelectionHtml()
          if ( selection_html == '' )
            @options.editable.getSelectionNode (selection) =>
              if selection[0] == @options.editable.element[0]
                @options.editable.element.append(table_placeholder_node)
              else
                table_placeholder_node.insertAfter(selection)
          else
            selection = rangy.getSelection()
            if ( selection.rangeCount > 0 )
              range = selection.getRangeAt(0)
              range.deleteContents()
            else
              range = rangy.createRange()
              range.selectNode(@options.editable.element[0])
              range.collapse(false)
            jQuery('body').append(table_placeholder_node)
            range.insertNode(table_placeholder_node[0])

        recalc = =>
          @recalcHTML(target.attr('id'))
        window.setTimeout recalc, 300
        return true
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
      border = $('#' + contentId + 'border').hasClass('active')
      heading = $('#' + contentId + 'heading').hasClass('active');
      if ( rows=='' || cols == '' || parseInt(rows) == NaN || parseInt(cols) == NaN || rows < 0 || cols < 0 ) 
        return false
      if ( border )
        table.attr('class','table-border')
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
            $(cell).contents().unwrap().wrapAll('<td></td>').parent()
        $(row).find('td').each (cindx,cell) =>
          icol = cindx + 1
          if icol > cols 
            $(cell).remove()
            return
          if heading && rindx == 0
            $(cell).contents().unwrap().wrapAll('<th></th>').parent()
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
      @options.editable.store()

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul')


      addInput = (type,element,default_value,recalc_preview) =>
        elid = "#{contentId}#{element}"
        el = jQuery "<li></li>"
        if ( type == 'checkbox' )
          toggle_button = jQuery('<button type="button" class="toggle_button"  id="' + elid + '"/>')
          recalc= =>
            toggle_button.toggleClass('active')
            @recalcHTML(contentId)
          toggle_button.html(utils.tr(element))
          toggle_button.bind('click', recalc)
          if ( default_value == true )
            toggle_button.addClass('active')
          el.append(toggle_button)

        else
          recalc= =>
            @recalcHTML(contentId)
          el.append('<label for="' + elid + '">' + utils.tr(element) + '</label>')
          el.append('<input type="' + type + '" id="' + elid + '"/>')
          if ( default_value )
            el.find('input').val(default_value)
          el.find('input').bind('keyup change',recalc)

        el
      addButton = (element,event_handler) =>
        el = jQuery "<li><button class=\"action_button\" id=\"" + @tmpid + element + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addInput("number", "rows","3")
      contentAreaUL.append addInput("number", "cols","3")
      contentAreaUL.append addInput("checkbox", "heading", true)
      contentAreaUL.append addInput("checkbox", "border", true)

      contentAreaUL.append addButton "apply", =>
        @recalcHTML(contentId)
        table = $('#' + @tmpid)
        sel_cell = table.find('th:first')
        if ( !sel_cell.length )
          sel_cell = table.find('td:first')
        @options.editable.setContentPosition(sel_cell)
        table.removeAttr('id')
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "remove", =>
        
        @options.editable.setContentPosition($('#' + @tmpid))
        $('#' + @tmpid).remove()
        @options.editable.restoreContentPosition()
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
