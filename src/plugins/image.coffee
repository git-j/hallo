#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a image to the editable
((jQuery) ->
  jQuery.widget 'IKS.halloimage',
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
      setup= (select_target) =>
        return if !window.getSelection().rangeCount && typeof select_target == 'undefined'
        @tmpid='mod_' + (new Date()).getTime()
        if ( typeof select_target != 'undefined' )
          @cur_image = $(select_target)
          @cur_image.attr('id',@tmpid)
          @action = 'update'
        else
          sel = window.getSelection()
          range = sel.getRangeAt()
          @cur_image = null
          @action = 'insert'
          @options.editable.element.find('img').each (index,item) =>
            if ( sel.containsNode(item,true) )
              @cur_image = jQuery(item)
              @cur_image.attr('id',@tmpid)
              @action = 'update'
              return false # break
        if ( @cur_image && @cur_image.length )
          #modify
          url = @cur_image.attr('src')
          alt = @cur_image.attr('alt')
          title = @cur_image.attr('title')
          width = @cur_image.attr('width')
          height = @cur_image.attr('height')
          width = 'auto' if !width || width == ''
          height = 'auto' if !height || height == ''
          align = @cur_image.attr('style')
          if align
            align = align.replace(/.*align:([^;]*).*/,'$1')
          align = "center" if ! align || align == ''
          border = @cur_image.attr('border')
          if border
            border = false if border != "1"
            border = true if border == "1"
          else
            border = false
          $('#' + contentId + 'url').val(url)
          $('#' + contentId + 'alt').val(alt)
          $('#' + contentId + 'title').val(title)
          $('#' + contentId + 'width').val(width)
          $('#' + contentId + 'height').val(height)
          $('#' + contentId + 'align').val(align)
          $('#' + contentId + 'border').attr('checked',border)
        else
          @cur_image = jQuery('<img src="../icons/types/PubArtwork.png" id="' + @tmpid + '"/>');
          range.insertNode(@cur_image[0]);
          $('#' + contentId + 'url').val("")
          $('#' + contentId + 'alt').val("")
          $('#' + contentId + 'title').val("")
          $('#' + contentId + 'width').val("auto")
          $('#' + contentId + 'height').val("auto")
          $('#' + contentId + 'align').val("center")
          $('#' + contentId + 'border').attr('checked',false)
          #console.log(@cur_image)
          @updateImageHTML(contentId)
        recalc = =>
          @recalcHTML(target.attr('id'))
        return true
        window.setTimeout recalc, 300
      @dropdownform = @_prepareButton setup, target
      @dropdownform.hallodropdownform 'bindShow', 'img'
      buttonset.append @dropdownform
      toolbar.append buttonset

    updateImageHTML: (contentId) ->
      image = $('#' + @tmpid)
      url = $('#' + contentId + 'url').val();
      alt = $('#' + contentId + 'alt').val();
      title = $('#' + contentId + 'title').val();
      width = $('#' + contentId + 'width').val();
      height = $('#' + contentId + 'height').val();
      align = $('#' + contentId + 'align').val();
      border =  $('#' + contentId + 'border').is(':checked');
      width = "auto" if ( width == '' )
      height = "auto" if ( height == '' )
      align = "center" if ( align == '' )
      #console.log(url)
      if ( url == '' )
          url = '../icons/types/PubArtwork.png'
      image.attr('src',url)
      image.attr('alt',alt)
      image.attr('title',title)
      if width == 'auto'
        image.removeAttr('width')
      else
        image.attr('width',width)
      if height == 'auto'
        image.removeAttr('height')
      else
        image.attr('height',height)
      image.attr('style','align:' + align)
      if ( border )
        image.attr('border','1')
      else
        image.removeAttr('border')
      return image[0].outerHTML #?

    recalcHTML: (contentId) ->
      @html = @updateImageHTML(contentId)
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
        elid="#{contentId}#{element}"
        el = jQuery "<li><button class=\"action_button\" id=\"" + @elid + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addInput("text", "url", "")
      contentAreaUL.append addInput("text", "alt", "")
      contentAreaUL.append addInput("text", "title", "")
      contentAreaUL.append addInput("text", "width", "auto")
      contentAreaUL.append addInput("text", "height", "auto")
      contentAreaUL.append addInput("text", "align", "center")
      contentAreaUL.append addInput("checkbox", "border", false)

      contentAreaUL.append addButton "browse", =>
        wkej.instance.insert_image_dfd = new $.Deferred();
        wkej.instance.insert_image_dfd.done (path) =>
          if ( path.indexOf(':') == 1 )
            path = '/' + path
          $('#' + contentId + 'url').val('file://' + path)
          delete wkej.instance.insert_image_dfd
          @updateImageHTML(contentId)
        occ.SelectImage()
        wkej.instance.insert_image_dfd.promise()
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
      contentArea

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'image'
      if ( window.action_list && window.action_list['hallojs_image'] != undefined )
        button_label =  window.action_list['hallojs_image'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'image'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
