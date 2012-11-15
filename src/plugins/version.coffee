#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.halloversion",
        options:
            editable: null
            toolbar: null
            uuid: ''
            buttonCssClass: null

        populateToolbar: (toolbar) ->
            buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
            buttonize = (cmd, label) =>
                buttonElement = jQuery '<span></span>'
                buttonElement.halloactionbutton
                  uuid: @options.uuid
                  editable: @options.editable
                  label: label
                  icon: cmd
                  command: cmd
                  action: =>
                    alert(cmd)
                  queryState: false
                  cssClass: @options.buttonCssClass
                buttonset.append buttonElement
            buttonize "next_version", "Next Version"
            buttonize "prev_version", "Previous Version"

            buttonset.hallobuttonset()
            toolbar.append buttonset

        _init: ->

)(jQuery)
