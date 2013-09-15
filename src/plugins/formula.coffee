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
      setup= =>
        return if !window.getSelection().rangeCount
        @tmpid='mod_' + (new Date()).getTime()
        sel = window.getSelection()
        range = sel.getRangeAt()
        @cur_formula = null
        @action = 'insert'
        @options.editable.element.find('.formula').each (index,item) =>
          if ( sel.containsNode(item,true) )
            @cur_formula = jQuery(item)
            @cur_formula.attr('id',@tmpid)
            @action = 'update'
            return false # break
        if ( ! @has_mathjax )
          return true
        if ( @cur_formula && @cur_formula.length )
          #modify
          latex_formula = decodeURIComponent(@cur_formula.attr('rel'))
          # console.log('modify',latex_formula,@cur_formula)
          $('#' + contentId + 'latex').val(latex_formula)
          $('#' + contentId + 'inline').attr('checked',@cur_formula.hasClass('inline'))
        else
          @cur_formula = jQuery('<span class="formula" id="' + @tmpid + '" contenteditable="false"/>')
          @cur_formula.find('.formula').attr('rel',encodeURIComponent(@options.default))
          if ( @options.inline )
            @cur_formula.find('.formula').addClass('inline')
          range.insertNode(@cur_formula[0]);
          $('#' + contentId + 'latex').val(@options.default)
          $('#' + contentId + 'inline').attr('checked',@options.inline)
          #console.log(@cur_formula)
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
      formula = $('#' + @tmpid)
      if ( !formula.length )
        console.error('expected identifier not found',@tmpid)
        console.error(@options.editable)
        console.error(@options.editable.element.html())
        return
      latex_formula = $('#' + contentId + 'latex').val();
      inline = $('#' + contentId + 'inline').is(':checked');
      #if ( formula.html() == '' )
      formula.removeClass('inline')
      if ( inline )
        formula.html(@options.mathjax_inline_delim_left + latex_formula + @options.mathjax_inline_delim_right)
        formula.addClass('inline')
      else
        formula.html(@options.mathjax_delim_left + latex_formula + @options.mathjax_delim_right)
      encoded_latex = encodeURIComponent(latex_formula)
      formula.attr('rel',encoded_latex)
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
      if ( preview.hasClass('inline') )
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
      addInput = (type,element,default_value) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><input type=\"#{type}\" id=\"#{elid}\"/></li>"
        if ( el.find('input').is('input[type="checkbox"]') && default_value=="true" )
          el.find('input').attr('checked',true);
        else if ( default_value )
          el.find('input').val(default_value)
        recalc= =>
          @recalcHTML(contentId)
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
      if ( @has_mathjax )
        contentAreaUL.append addArea("latex", @options.default)
        contentAreaUL.append addInput("checkbox","inline", @options.inline)
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
        $('#' + @tmpid).removeAttr('id')
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
