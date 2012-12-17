#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a table to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallotable',
    dropdownform: null
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
      @dropdownform = @_prepareButton target
      buttonset.append @dropdownform
      toolbar.append buttonset

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul');

      containingElement = @options.editable.element.get(0).tagName.toLowerCase()

      addInput = (type,element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><input type=\"#{type}\" id=\"#{elid}\"/></li>"
        if ( el.find('input').is('input[type="checkbox"]') && default_value=="true" )
          el.find('input').attr('checked',true);
        else if ( default_value )
          el.find('input').val(default_value)

        el
      addButton = (element) =>
        el = jQuery "<li><button class=\"action-button\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', =>
          #if el.hasClass 'disabled'
          #    return
          rows = $('#' + contentId + 'rows').val();
          cols = $('#' + contentId + 'cols').val();
          border = $('#' + contentId + 'border').is(':checked');
          heading = $('#' + contentId + 'heading').is(':checked');
          #console.log(rows,cols,border)
          if ( rows < 0 || cols < 0 ) 
            return
          if ( border )
            html = '<table border="1" class="table-border">';
          else
            html = '<table>';
          for r in[1..rows] by 1
            html+='<tr>';
            if ( r == 1 && heading)
              for c in[1..cols] by 1
                html+='<th>head</th>';
            else
              for c in[1..cols] by 1
                html+='<td>cell</td>';
            html+='</tr>';
          html+= '</table>';
          #console.log(html)
          @dropdownform.hallodropdownform('restoreContentPosition')
          document.execCommand 'insertHTML',false, html
          @dropdownform.hallodropdownform('hideForm')
        el
      contentAreaUL.append addInput("text", "rows","3")
      contentAreaUL.append addInput("text", "cols","3")
      contentAreaUL.append addInput("checkbox", "heading","true")
      contentAreaUL.append addInput("checkbox", "border","true")
      contentAreaUL.append addButton("insert")
      contentArea

    _prepareButton: (target) ->
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
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
