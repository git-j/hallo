#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic add a table to the editable
((jQuery) ->
  jQuery.widget 'IKS.hallocleanup',
    dropdownform: null
    tmpid: 0
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
        console.log('check nugget')
      @dropdownform = @_prepareButton setup, target
      buttonset.append @dropdownform
      toolbar.append buttonset

    _clean_nodes: (node,context) =>
       node.removeAttr('style')
       if ( node[0].nodeType == 1 )
         node.children().each (index,child_node) =>
           context._clean_nodes(jQuery(child_node),context);

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

        el
      addButton = (element,event_handler) =>
        button_label = element
        button_tooltip = element
        if ( window.action_list && window.action_list['hallojs_cleanup_' + element] != undefined )
          button_label = window.action_list['hallojs_cleanup_' + element].title
          button_tooltip = window.action_list['hallojs_cleanup_' + element].tooltip
        el = jQuery "<li><button class=\"action-button\" id=\"" + @tmpid+element + "\" title=\"" + button_tooltip+ "\">" + button_label + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addButton "clean_html", =>
        console.log('cleanhtml')
        utils.removeForbiddenElements(@options.editable.element)
        utils.fixNestedElements(@options.editable.element)
        @_clean_nodes(@options.editable.element,@)
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "clean_plain", =>
        @options.editable.element.html(@options.editable.element.text())
        @dropdownform.hallodropdownform('hideForm')

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'cleanup'
      if ( window.action_list && window.action_list['hallojs_cleanup'] != undefined )
        button_label =  window.action_list['hallojs_cleanup'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'cleanup'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
