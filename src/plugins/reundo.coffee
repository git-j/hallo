#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
((jQuery) ->
    jQuery.widget "IKS.halloreundo",
        options:
            editable: null
            toolbar: null
            uuid: ''
            buttonCssClass: null

        populateToolbar: (toolbar) ->
            buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
            buttonize = (label,cmd,cmd_fn) =>
                button_label = label
                if ( window.action_list && window.action_list['hallojs_' + cmd] != undefined )
                  button_label =  window.action_list['hallojs_' + cmd].title + ' ' + window.action_list['hallojs_' + cmd].tooltip
                buttonElement = jQuery '<span></span>'
                buttonElement.hallobutton
                  uuid: @options.uuid
                  editable: @options.editable
                  label: button_label
                  icon: if cmd is 'undo' then 'icon-undo' else 'icon-repeat'
                  command: cmd
                  command_function: cmd_fn
                  queryState: false
                  cssClass: @options.buttonCssClass
                buttonset.append buttonElement
            if ( window.wke )
              @options.editable.registerKey 'ctrl', 90, (event) =>
                event.preventDefault()
                @_undo(jQuery(event.currentTarget))
              @options.editable.registerKey 'ctrl,shift', 90, (event) =>
                event.preventDefault()
                @_redo(jQuery(event.currentTarget))

              if ( utils && utils.cur_language == 'de' )
                # german redo
                @options.editable.registerKey 'ctrl', 89, (event) =>
                  event.preventDefault()
                  @_redo(jQuery(event.currentTarget))
              buttonize "Undo", 'undo', () =>
                @_undo(@options.editable.element)
              buttonize "Redo", 'redo', () =>
                @_redo(@options.editable.element)
            else
              buttonize "Undo", "undo"
              buttonize "Redo", "redo"

            buttonset.hallobuttonset()
            toolbar.append buttonset

        _init: ->

        _undo: (target) ->
          #console.log('undo toolbar fn')
          @options.editable.undo(target)

        _redo: (target) ->
          #console.log('redo toolbar fn')
          return if ( typeof @options.editable._undo_stack != 'object' )
          @options.editable.redo(target)

)(jQuery)
