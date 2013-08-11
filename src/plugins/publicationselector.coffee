#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection from a list of previously associated publications

((jQuery) ->
  jQuery.widget 'IKS.hallopublicationselector',
    widget: null
    selectables: ''
    options:
      editable: null
      range: null
      toolbar: null
      uuid: ''
      element: null
      tip_element: null
      data: null
      loid: null
      has_changed: false
      default_css:
        'width': '100%'
        'height': '100%'
        'top': 0
        'left': 0
        'position': 'fixed'
        'z-index': 999999
    _init: ->
      #debug.log('publicationselector initialized',@options)
      @widget = jQuery('<div id="publication_selector"></div>')
      @widget.addClass('form_display');
      jQuery('body').css({'overflow':'hidden'})
      jQuery('body').append(@widget)
      @widget.append('<div id="publication_list" style="background-color:white; margin-bottom: 4px"></div>');
      @widget.append('<button class="publication_selector_back action_button">' + utils.tr('back') + '</button>');
      @widget.append('<button class="publication_selector_apply action_button">' + utils.tr('apply') + '</button>');
      @widget.css @options.default_css
      @widget.find('.publication_selector_back').bind 'click', =>
        @back()
      @widget.find('.publication_selector_apply').bind 'click', =>
        @apply()
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      jQuery.when(
          utils.getJavaScript('lib/refeus/Utilities/List.js')
      ).done =>
        @list = new List();
        @list.init($('#publication_list'),omc.getPublicationList);
        @list.setupItemActions($('#publication_list'),{
          'node_dblclick': (node) =>
            @select(node)
            @apply()
          'node_select': (node) =>
            @select(node)
        })
      jQuery(window).resize()

    apply:  ->
      publication_loid = @current_node.replace(/node_/,'')
      target_loid = @options.editable.element.closest('.Text').attr('id').replace(/node/,'')
      dfo = omc.associateNuggetPublication(target_loid,publication_loid)
      dfo.fail (error) =>
        @widget.remove()
        jQuery('body').css({'overflow':'auto'})
      #tmp_id is used to identify new sourcedescription after it has been inserted for further editing
      tmp_id = 'tmp_' + (new Date()).getTime()
      dfo.done (result) =>
        data = result.loid
        element = @current_node_label
        scb = (parent, old) ->
          replacement = false
          #console.log('[' + old.text() + ']' + old.html())
          if old.html() == "" || old.html() == "&nbsp;" || old.text() == " "
            replacement = ""
          else
            replacement = "<span class=\"citation\">" + old.html() + "</span>"
          replacement+= "<span class=\"cite sourcedescription-#{data}\" contenteditable=\"false\" id=\"#{tmp_id}\">#{element}</span>"
          replacement
        #/scb
        #console.log(@options.range,window.getSelection())
        #console.log(@options.range)
        selection =  @options.editable.element.find('.selection')
        if ( selection.length )
          range = document.createRange()
          range.selectNode(selection[0])
          if ( selection.hasClass('carret') )
            range.setStartAfter(range.endContainer)
          window.getSelection().removeAllRanges()
          window.getSelection().addRange(range)
          @options.editable.replaceSelectionHTML scb
          #console.log(@options.editable.element.html())
          window.__start_mini_activity = false
          @options.editable.element.find('.selection').each (index,item) =>
            $(item).replaceWith($(item).html())
            if ( $(item).text() == ' ' )
              $(item).find('.citation').remove()
        nugget = new DOMNugget()
        @options.editable.element.closest('.nugget').find('.auto-cite').remove()
        occ.UpdateNuggetSourceDescriptions({loid:target_loid})
        # launch sourcedescription editor with newly created sourcedescription
        new_sd_node=$('#' + tmp_id);
        new_sd_node.removeAttr('id')
        #console.log(new_sd_node)
        nugget.updateSourceDescriptionData(@options.editable.element).done =>
          nugget.resetCitations(@options.editable.element)
          #console.log(new_sd_node)
          new_sd_class = new_sd_node.attr('class')
          if new_sd_class
            sd_loid=new_sd_class.replace(/.*sourcedescription-(\d*).*/,"$1");
            nugget.getSourceDescriptionData(new_sd_node).done (citation_data) =>
              jQuery('body').hallosourcedescriptioneditor
                'loid':sd_loid
                'data':citation_data
                'element':new_sd_node
                'back':false
                'nugget_loid':target_loid
        @widget.remove()
        jQuery('body').css({'overflow':'auto'})


    back: ->
      @widget.remove()
      jQuery('body').css({'overflow':'auto'})

    select: (node) ->
      @current_node = jQuery(node).attr('id')
      @current_node_label = jQuery(node).text()

    _createInput: (identifier, label, value) ->
      input = jQuery('<div><label for="' + identifier + '">' + label + '</label><input id="' + identifier + '" type="text" value="' + value + '"/></div>')
      input.find('input').bind 'blur', (event) =>
        @_formChanged(event,@options)
      input
    _formChanged: (event, options) ->
      target = jQuery(event.target)
      #debug.log('form changed' + target.html())
      path = target.attr('id')
      data = target.val()
      if omc && options.loid
        omc.storePublicationDescriptionAttribute(options.loid,path,data)
        #debug.log('stored',options.loid,path,data)

    _create: ->
      #debug.log('created');
      @

)(jQuery)
