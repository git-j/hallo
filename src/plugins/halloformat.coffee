#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.halloformat",
        options:
            editable: null
            uuid: ""
            formattings: 
                bold: true
                italic: true
                strikeThrough: false
                underline: false
                superscript: false
                subscript: false
            buttonCssClass: null

        populateToolbar: (toolbar) ->
            widget = this
            buttonset = jQuery "<span class=\"#{widget.widgetName}\"></span>"
            buttonize = (format) =>
                format_label = format
                if ( window.action_list && window.action_list['hallojs_' + format] != undefined )
                  format_label =  window.action_list['hallojs_' + format].title
                buttonHolder = jQuery '<span></span>'
                buttonHolder.hallobutton
                  label: format_label
                  editable: @options.editable
                  command: format
                  uuid: @options.uuid
                  cssClass: @options.buttonCssClass
                buttonset.append buttonHolder
            buttonize format for format, enabled of @options.formattings when enabled

            buttonset.hallobuttonset()
            toolbar.append buttonset
)(jQuery)
