#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
# This plugin handles the selection of a publication, a nugget associated to the publication and a portion of the nugget text
# Currently Unused
((jQuery) ->
  jQuery.widget 'IKS.halloquoteselector',
    widget: null
    selectables: ''
    activity:
      step: 0
      publication: 0
      publication_label: ''
      nugget: 0
      nugget_label: ''

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
      #debug.log('quoteselector initialized',@options)
      @widget = jQuery('<div id="quote_selector"></div>')
      @widget.addClass('form_display');
      jQuery('body').css({'overflow':'hidden'})
      jQuery('body').append(@widget)
      @widget.append('<div id="informationcontainer"><div id="information"></div></div>');
      @widget.append('<div id="publication_list"></div>');
      @widget.append('<div id="nugget_list"></div>');
      @widget.append('<div id="nugget_content"></div>');
      @widget.append('<button class="quote_selector_back action_button">' + utils.tr('back') + '</button>');
      @widget.append('<button class="quote_selector_next action_button">' + utils.tr('next') + '</button>');
      @widget.append('<button class="quote_selector_apply action_button">' + utils.tr('apply') + '</button>');
      @widget.css @options.default_css
      @widget.find('.quote_selector_back').bind 'click', =>
        @back()
      @widget.find('.quote_selector_next').bind 'click', =>
        @next()
      @widget.find('.quote_selector_apply').bind 'click', =>
        @apply()
      @wigtet.css('width', jQuery('body').width()) if !@options.default_css.width
      @widget.css('height', jQuery(window).height()) if !@options.default_css.height
      jQuery.when(
          utils.getJavaScript('lib/refeus/Utilities/List.js')
      ).done =>
        @loadPublications()
      jQuery(window).resize()
      @activity.step = 0
      @updateButtons
      @updateInformation()

    updateButtons: ->
      if ( @activity.step == 2 )
        @widget.find('.quote_selector_next').hide()
        @widget.find('.quote_selector_apply').show()
      else
        @widget.find('.quote_selector_next').show()
        @widget.find('.quote_selector_apply').hide()

    updateInformation: ->
      if ( @activity.step == 0 )
        jQuery('#information').html(utils.tr('activity quote select publication'))
      if ( @activity.step == 1 )
        jQuery('#information').html(utils.tr('activity quote select nugget'))
      if ( @activity.step == 2 )
        jQuery('#information').html(utils.tr('activity quote select nugget text'))


    apply:  ->
      nugget = new DOMNugget()
      #createversion @activity.nugget,selected_html.done (new_version)
      #splitby newversion
      nugget.createNewVersion(@activity.nugget,@activity.selection).done (new_version) =>
        nugget.split(@options.editable.element,@options.editable.element.find('.selection'),new_version.loid).done (loids) =>
          console.log(loids);
          console.log('TODO: update document');
      @cleanup()

    cleanup: ->
      @widget.remove()
      jQuery('body').css({'overflow':'auto'})


    back: ->
      if ( @activity.step == 0 )
        @cleanup()
        return
      else if ( @activity.step == 1 )
        jQuery('#nugget_list').hide()
        jQuery('#publication_list').show()
        @activity.step = 0
      else if ( @activity.step == 2 )
        jQuery('#nugget_content').hide()
        jQuery('#nugget_list').show()
        @activity.step = 1

      @updateButtons()
      @updateInformation()

    next: ->
      console.log(@)
      if ( @activity.step == 0 )
        return if !@activity.publication
        @loadPublicationNuggets(@activity.publication)
        jQuery('#publication_list').hide()
        @activity.step = 1
      else if ( @activity.step == 1 )
        return if !@activity.nugget
        @loadNugget(@activity.nugget)
        jQuery('#nugget_list').hide()
        @activity.step = 2
      @updateButtons()
      @updateInformation()

    selectPublication: (node) ->
      @activity.publication = jQuery(node).attr('id').replace(/node_/,'')
      @activity.publication_label = jQuery(node).text()

    selectNugget: (node) ->
      return if jQuery(node).closest('.context').length
      @activity.nugget = jQuery(node).attr('id').replace(/node_/,'')
      @activity.nugget_label = jQuery(node).text()

    loadNugget: (loid) ->
      content = jQuery('#nugget_content')
      content.show();
      omc.NuggetContent(loid).done (node_data) =>
        if ( node_data && node_data.indexOf('<![CDATA[') >= 0 )
          node_data = utils.replaceCDATA(node_data)
        content.html(node_data);
        content.bind 'keyup keydown', (event) =>
          event.preventDefault()
          return false
        content.find('.name').hide()
        text = content.find('.content')
        text.attr('contenteditable','true');
        text.focus();
        @options.editable.execute('selectAll')

    loadPublications: (loid) ->
      list = new List();
      list.init(jQuery('#publication_list'),omc.PublicationList);
      list.setupItemActions(jQuery('#publication_list'),{
        'node_dblclick': (node) =>
          @selectPublication(node)
          @next()
        'node_select': (node) =>
          @selectPublication(node)
      })
      jQuery('#publication_list').show();


    loadPublicationNuggets: (loid) ->
      list = new List();
      data_fn = ->
        return omc.SourceDescriptionNuggetList(loid)
      list.init(jQuery('#nugget_list'),data_fn);
      list.setupItemActions(jQuery('#nugget_list'),{
        'node_dblclick': (node) =>
          @selectNugget(node)
          @next()
        'node_select': (node) =>
          @selectNugget(node)
          #return if ( jQuery(node).parents('.context').length )
          #return if ( jQuery(node).find('.context').is(':visible') )
          #citation_data = '{' + jQuery(node).find('.citation_data').text() + '}';
          #citation_data = citation_data.replace(/{,/,'{')
          #endnotes = @nugget.endnotes(citation_data);
          #endnotes = endnotes.replace(/\[1\]/,'[' + (jQuery(node).index()+1) + ']')
          #jQuery(node).find('.citation_data_processed').html(endnotes).show()
          jQuery('.context:visible').hide()
          jQuery(node).find('.context').show()
      })
      jQuery('#nugget_list').show()


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
