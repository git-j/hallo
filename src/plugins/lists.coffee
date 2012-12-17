#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.hallolists",
        options:
            editable: null
            toolbar: null
            uuid: ''
            lists:
                ordered: true
                unordered: true
            buttonCssClass: null

        populateToolbar: (toolbar) ->
            buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
            buttonize = (type, label) =>
                butten_label = label
                if ( window.action_list && window.action_list['hallojs_' + label] != undefined )
                  button_label =  window.action_list['hallojs_' + label].title
                buttonElement = jQuery '<span></span>'
                buttonElement.hallobutton
                  uuid: @options.uuid
                  editable: @options.editable
                  label: button_label
                  command: "insert#{type}List"
                  icon: "icon-list-#{label.toLowerCase()}"
                  cssClass: @options.buttonCssClass
                buttonset.append buttonElement

            buttonize "Ordered", "OL" if @options.lists.ordered
            buttonize "Unordered", "UL" if @options.lists.unordered

            buttonset.hallobuttonset()
            toolbar.append buttonset

)(jQuery)
