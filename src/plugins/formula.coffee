#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     Plugin to minimalistic enter a nice-looking formula
# in the page head: 
# <!-- math processing -->
# <script type="text/x-mathjax-config">
#   MathJax.Hub.Config({
#     tex2jax: {
#         inlineMath: [['\\(inline_math\\(','\\)inline_math\\)']]
#       , displayMath: [['\\(math\\(','\\)math\\)']]
#       , preview:[["img",{src:"icons/throbber.gif"}]]
#       , showMathMenu: false
#       }
#   });
# </script>
# <script type="text/javascript" src="MathJax.js?config=TeX_HTML"></script>
# unpack the MathJax library into the root of you server, maybe patch
# BASE.JAX(~@666)    config: {root: "lib/mathjax"}, // URL of root directory to load from
# and something about the webfontDir was weird with my configuration
# requires utilities for wke (webkitedit):
#  openUrlInBrowser
# leaves the editable in a broken-undo-state
# requires on-store (.formula.html('') or svg transformation)
# requires on-load (.formula.html(.formula.attr('rel')))
# MathJax.Hub.Queue(['Typeset',MathJax.Hub])
# depends on the dropdownform widget plugin


((jQuery) ->
  jQuery.widget 'IKS.halloformula',
    dropdownform: null
    tmpid: 0
    html: null
    has_mathjax: typeof MathJax != 'undefined'
    debug: false
    options:
      editable: null
      toolbar: null
      uuid: ''
      rows: 6
      cols: 32
      buttonCssClass: null
      default: '\\zeta(s) = \\sum_{n=1}^\\infty {\\frac{1}{n^s}}'
      mathjax_alternative: '<a href="http://mathurl.com/">MathURL.com</a>'
      mathjax_base_alternative: '<a href="http://www.sciweavers.org/free-online-latex-equation-editor">sciweavers.org</a>'
      mathjax_delim_left: '\\(math\\('
      mathjax_delim_right: '\\)math\\)'
      mathjax_inline_delim_left: '\\(inline_math\\('
      mathjax_inline_delim_right: '\\)inline_math\\)'
      inline: true

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      toolbar.append target
      setup= (select_target,target_id) =>
        return if !window.getSelection().rangeCount
        contentId = target_id
        # target_id != parent-function:contentId
        # as the setup function is called by live()
        # and subsequent activations will lead to a different this here
        # and in the keyup/click handlers in _prepareDropdown

        @tmpid = 'mod_' + (new Date()).getTime()
        sel = window.getSelection()
        range = sel.getRangeAt()
        @cur_formula = null
        @action = 'insert'
        if ( typeof select_target == 'object' )
          selected_formula = jQuery(select_target).closest('.formula')
          if ( selected_formula.length )
            @cur_formula = selected_formula
            @cur_formula.attr('id',@tmpid)
            @action = 'update'
        if ( @action == 'insert' )
          @options.editable.element.find('.formula').each (index,item) =>
            if ( sel.containsNode(item,true) )
              @cur_formula = jQuery(item)
              @action = 'update'
              return false # break
        if ( @cur_formula && @cur_formula.length )
          #modify
          latex_formula = decodeURIComponent(@cur_formula.attr('rel'))
          title = decodeURIComponent(@cur_formula.attr('title'))
          console.log('modify',latex_formula,@cur_formula) if @debug
          $('#' + contentId + 'latex').val(latex_formula)
          $('#' + contentId + 'title').val(title)
          $('#' + contentId + 'inline').attr('checked',@cur_formula.hasClass('inline'))
          @cur_formula.attr('id',@tmpid)
          @cur_formula.html('')
        else
          @cur_formula = jQuery('<span class="formula" id="' + @tmpid + '" contenteditable="false"/>')
          @cur_formula.find('.formula').attr('rel',encodeURIComponent(@options.default))
          @cur_formula.find('.formula').attr('title','')
          if ( @options.inline )
            @cur_formula.find('.formula').addClass('inline')
          #range.insertNode(@cur_formula[0])
          @cur_formula.insertBefore(@options.editable.element.find(@options.editable.selection_marker))
          range.selectNode(@options.editable.element.find(@options.editable.selection_marker)[0])
          window.getSelection().removeAllRanges()
          window.getSelection().addRange(range)

          $('#' + contentId + 'latex').val(@options.default)
          $('#' + contentId + 'inline').attr('checked',@options.inline)
          $('#' + contentId + 'title').val()
          console.log('insert',@cur_formula) if @debug
          @updateFormulaHTML(contentId)
        recalc = =>
          @recalcHTML(contentId)
          @recalcPreview(contentId)
          @recalcMath()
        window.setTimeout recalc, 300
        return true
      @dropdownform = @_prepareButton setup, target
      @dropdownform.hallodropdownform 'bindShow', '.formula'
      buttonset.append @dropdownform
      toolbar.append buttonset


    updateFormulaHTML: (contentId) ->
      console.log('update formula',contentId,@tmpid,this) if @debug
      formula = $('#' + @tmpid)
      if ( !formula.length )
        console.error('expected identifier not found',@tmpid)
        console.error(@options.editable)
        console.error(@options.editable.element.html())
        return
      latex_formula = $('#' + contentId + 'latex').val();
      inline = $('#' + contentId + 'inline').is(':checked');
      title = $('#' + contentId + 'title').val();
      console.log(latex_formula,inline,title,formula,@tmpid) if @debug
      #if ( formula.html() == '' )
      formula.removeClass('inline')
      formula.html('')
      if ( @has_mathjax )
        if ( inline )
          formula.contents().unwrap().wrap('<span/>')
          formula.html(@options.mathjax_inline_delim_left + latex_formula + @options.mathjax_inline_delim_right)
          formula.addClass('inline')
        else
          formula.contents().unwrap().wrap('<div/>')
          formula.html(@options.mathjax_delim_left + latex_formula + @options.mathjax_delim_right)
      else
        formula.html(latex_formula)
      encoded_latex = encodeURIComponent(latex_formula)
      encoded_title = encodeURIComponent(title)
      formula.attr('id',@tmpid)
      formula.addClass('formula')
      formula.attr('rel',encoded_latex)
      formula.attr('title',encoded_title)
      formula.attr('contenteditable','false')
      # console.log(latex_formula,encoded_latex,formula[0].outerHTML)
      return formula[0].outerHTML

    recalcMath: () ->
      if ( @has_mathjax )
        MathJax.Hub.Queue(['Typeset',MathJax.Hub])

    recalcHTML: (contentId) ->
      @html = @updateFormulaHTML(contentId)
      @options.editable.store()

    recalcPreview: (contentId) ->
      preview = jQuery('#' + contentId + ' .preview')
      if ( preview.length == 0 )
        return
      latex_formula = $('#' + contentId + 'latex').val();
      inline = $('#' + contentId + 'inline').is(':checked');
      if ( inline )
        preview.html(@options.mathjax_inline_delim_left + latex_formula + @options.mathjax_inline_delim_right)
      else
        preview.html(@options.mathjax_delim_left + latex_formula + @options.mathjax_delim_right)

    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul')
      addArea = (element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><textarea id=\"#{elid}\" rows=\"#{@options.rows}\" cols=\"#{@options.cols}\"><textarea></li>"
        textarea = el.find('textarea')
        textarea.val(default_value)
        recalc= =>
          @recalcHTML(contentId)
          @recalcPreview(contentId)
          @recalcMath()
        textarea.bind('keyup change',recalc)

        el
      addInput = (type,element,default_value,recalc_preview) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><input type=\"#{type}\" id=\"#{elid}\"/></li>"
        if ( el.find('input').is('input[type="checkbox"]') && default_value=="true" )
          el.find('input').attr('checked',true);
        else if ( default_value )
          el.find('input').val(default_value)
        recalc= =>
          @recalcHTML(contentId)
          if ( recalc_preview )
            @recalcPreview(contentId)
            @recalcMath()
        el.find('input').bind('keyup change',recalc)

        el
      addButton = (element,event_handler) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><button class=\"action_button\" id=\"" + @elid + "\">" + utils.tr(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el
      contentAreaUL.append addArea("latex", @options.default)
      contentAreaUL.append addInput("checkbox","inline", @options.inline,true)
      contentAreaUL.append addInput("text","title", @options.title,false)
      if ( @has_mathjax )
        contentInfoText = jQuery '<li>' + utils.tr('compose formula') + @options.mathjax_alternative + '</li>'
      else
        contentInfoText = jQuery '<li>' + utils.tr('compose formula base') + @options.mathjax_alternative + '<br/>' +  @options.mathjax_base_alternative + '</li>'
      
      contentInfoText.find('a').each (index,item) =>
        link = jQuery(item)
        link.bind 'click', (event) =>
          event.preventDefault()
          wke.openUrlInBrowser(link.attr('href'))
      contentAreaUL.append (contentInfoText)
      if ( @has_mathjax )
        contentInfoText = jQuery '<li><span class="formula preview">' + @options.mathjax_delim_left + @options.default + @options.mathjax_delim_right + '</span></li>'
        contentAreaUL.append (contentInfoText)

      
      contentAreaUL.append addButton "apply", =>
        @recalcHTML(contentId)
        @recalcMath()
        formula = $('#' + @tmpid)
        if ( formula.length )
          if ( ! formula[0].nextSibling )
            jQuery('<br/>').insertAfter(formula)
          formula.removeAttr('id')
        else
          formulas = $('.formula').each (index,item) =>
            jQuery(item).removeAttr('id')
        @dropdownform.hallodropdownform('hideForm')
      contentAreaUL.append addButton "remove", =>
        $('#' + @tmpid).remove()
        @dropdownform.hallodropdownform('hideForm')
      contentArea

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'formula'
      if ( window.action_list && window.action_list['hallojs_formula'] != undefined )
        button_label =  window.action_list['hallojs_formula'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'formula'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement

)(jQuery)
