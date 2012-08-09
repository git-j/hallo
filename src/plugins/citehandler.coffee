#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# citehandler
# common functions for citation/publication/sourcedescription handling

((jQuery) ->
    jQuery.widget "IKS.citehandler",
        options:
            uuid: ''
            label: null
            icon: null
            editable: null
            target: ''
            setup: null
            cssClass: null
            settings: null

        _create: ->
          @options.editable = @
          debug.log('citehandler created')

        _init: ->
          debug.log('citehandler initialized')
          @

        bindEvents: ->
          @options.editable.element.find('.cite').attr('contenteditable','false')
          @options.editable.element.find('.cite').unbind()
          @options.editable.element.find('.cite').bind('mouseover', @_showOverlay(@))
          debug.log('bound events')

        setupSourceDescriptions: (target, add_element_cb) ->
          debug.log('setup sourcedescriptions...')
          target.find('.SourceDescription').remove()
          create_menu_item = (index,item) =>
            cindx = jQuery(item).find('.citation_index').html()
            try
              scitation_data = jQuery(item).find('.citation_data').html() 
              scitation_data = scitation_data.replace(/, \"ITEM-/,'"ITEM-');
              citation_data = JSON.parse("{#{scitation_data}}")
              rel  = citation_data["ITEM-#{cindx}"].type
              link = citation_data["ITEM-#{cindx}"].title
              target.append(add_element_cb(link,null,rel,cindx).addClass('SourceDescription'))
            catch error
              debug.log('[dev] citehandler::setupSourceDescription: invalid citation_data: ' + error )

          if @options.editable.element.parent('.nugget').length
            @options.editable.element.parent('.nugget').find('.SourceDescription').each create_menu_item
          else if @options.editable.element.parent('.Text').length
            @options.editable.element.parent('.Text').find('.SourceDescription').each create_menu_item

        _updateSettings: ->
          @options.settings = JSON.parse(omc_settings.getSettings()) if omc_settings

        _showOverlay: (target) ->
          @
)(jQuery)
