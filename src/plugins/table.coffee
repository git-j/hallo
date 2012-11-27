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
      contentArea = jQuery "<div id=\"#{contentId}\"></div>"

      containingElement = @options.editable.element.get(0).tagName.toLowerCase()

      addInput = (type,element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<label for\"#{elid}\">" + utils.tr(element) + "</label><input type=\"#{type}\" id=\"#{elid}\"/><br/>"
        if ( el.is('input[type="checkbox"]') && default_value=="true" )
          el.attr('checked',true);
        else if ( default_value )
          el.val(default_value)

        el
      addButton = (element) =>
        el = jQuery "<button class=\"action-button\">" + utils.tr(element) + "</button>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.bind 'click', =>
          #if el.hasClass 'disabled'
          #    return
          rows = $('#' + contentId + 'rows').val();
          cols = $('#' + contentId + 'cols').val();
          border = $('#' + contentId + 'border').is(':checked');
          heading = $('#' + contentId + 'heading').is(':checked');
          console.log(rows,cols,border)
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
          console.log(html)
          @dropdownform.hallodropdownform('restoreContentPosition')
          document.execCommand 'insertHTML',false, html
          @dropdownform.hallodropdownform('hideForm')
        el
      contentArea.append addInput("text", "rows","3")
      contentArea.append addInput("text", "cols","3")
      contentArea.append addInput("checkbox", "heading","true")
      contentArea.append addInput("checkbox", "border","true")
      contentArea.append addButton("insert")
      contentArea

    _prepareButton: (target) ->
      buttonElement = jQuery '<span></span>'
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: 'table'
        icon: 'icon-text-height'
        target: target
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
