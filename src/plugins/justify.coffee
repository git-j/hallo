#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.hallojustify",
        options:
            editable: null
            toolbar: null
            uuid: ''
            buttonCssClass: null

        populateToolbar: (toolbar) ->
            buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
            buttonize = (alignment) =>
                label = alignment
                if ( window.action_list && window.action_list['hallojs_' + alignment] != undefined )
                  label =  window.action_list['hallojs_' + alignment].title
                buttonElement = jQuery '<span></span>'
                buttonElement.hallobutton
                  uuid: @options.uuid
                  editable: @options.editable
                  label: label
                  command: "justify#{alignment}"
                  icon: "icon-align-#{alignment.toLowerCase()}"
                  cssClass: @options.buttonCssClass
                buttonset.append buttonElement 
            buttonize "Left"
            buttonize "Center"
            buttonize "Right"

            buttonset.hallobuttonset()
            toolbar.append buttonset
        _init: ->

)(jQuery)
