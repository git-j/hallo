#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a image to the editable
((jQuery) ->
  jQuery.widget 'IKS.halloimage',
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
      contentArea = jQuery "<div id=\"#{contentId}\" class=\"dropdownform\"></div>"

      containingElement = @options.editable.element.get(0).tagName.toLowerCase()

      addInput = (type,element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<label for\"#{elid}\">#{element}</label><input type=\"#{type}\" id=\"#{elid}\"/>"
        if ( el.is('type["checkbox"]') && default_value=="true" )
          el.attr('checked',true);
        else if ( default_value )
          el.val(default_value)

        el
      addButton = (element) =>
        el = jQuery "<button class=\"confirm action-button\">confirm</button>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.bind 'click', =>
          #if el.hasClass 'disabled'
          #    return
          url = $('#' + contentId + 'url').val();
          alt = $('#' + contentId + 'alt').val();
          width =  $('#' + contentId + 'width').val();
          height =  $('#' + contentId + 'height').val();
          align =   $('#' + contentId + 'align').val();
          border = $('#' + contentId + 'border').is(':checked');
          if ( url == '' )
            return
          html= '<img src="' + url + '" alt="' + alt + '"'
          if ( width != 'auto' )
            html+= ' width="' + width + '"'
          if ( height != 'auto' )
            html+= ' height="' + height + '"'
          if ( border )
            html+= ' border="1"'
          if ( align != '' )
            html+=' style="align:' + align + '"'
          html+='/>'
          console.log(html)
          @dropdownform.hallodropdownform('restoreContentPosition')
          document.execCommand 'insertHTML',false, html
          @dropdownform.hallodropdownform('hideForm')
        el
      contentArea.append addInput("text", "url")
      contentArea.append addInput("text", "alt")
      contentArea.append addInput("text", "width", "auto")
      contentArea.append addInput("text", "height", "auto")
      contentArea.append addInput("text", "align", "center")
      contentArea.append addInput("checkbox", "border")
      contentArea.append addButton("insert")
      contentArea

    _prepareButton: (target) ->
      buttonElement = jQuery '<span></span>'
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: 'image'
        icon: 'icon-text-height'
        target: target
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
