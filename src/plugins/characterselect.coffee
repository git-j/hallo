#     Hallo - a rich text editing jQuery UI widget
#     (c) 2013 git-j, refeus
#     this plugin may be freely distributed under the MIT license
#     Plugin to minimalistic add a unicode character to the current editable
#     requires: dropdownform
#               selectBox
((jQuery) ->
  jQuery.widget 'IKS.hallocharacterselect',
    dropdownform: null
    tmpid: 0
    html: null
    options:
      editable: null
      toolbar: null
      uuid: ''
      buttonCssClass: null
      select: true
      use_form: false
      max_recent: 8

    populateToolbar: (toolbar) ->
      buttonset = jQuery "<span class=\"#{@widgetName}\"></span>"
      contentId = "#{@options.uuid}-#{@widgetName}-data"
      target = @_prepareDropdown contentId
      toolbar.append target
      setup= =>
        # return if !window.getSelection().rangeCount
        jQuery(target).find('select').each (index,item) =>
          jQuery(item).selectBox()
        target.bind 'hide', =>
          jQuery(target).find('select').each (index,item) =>
            jQuery(item).selectBox('destroy')
        @tmpid='mod_' + (new Date()).getTime()
        sel = window.getSelection()
        range = sel.getRangeAt()
        selected_character = '&#64';
        @cur_character = jQuery('<span id="' + @tmpid + '">' + selected_character + '</span>');
        #TODO: make sure this formatting is not stored
        #@cur_character.css
        #  'background-color':'blue'
        #  'color':'white'
        #  'font-size':'150%'
        range.insertNode(@cur_character[0]);

        recalc = =>
          @recalcHTML()
          selectbox = $('#' + contentId + 'group')
          if ( selectbox.length )
            if ( window._character_select_range )
              selectbox.val(window._character_select_range) #selectBox('value',window._character_select_range)
            @recalcRange selectbox.val() #selectBox('value'))
          @updateCharacterSelectRecent()
        window.setTimeout recalc, 300
        return true
      @dropdownform = @_prepareButton setup, target
      buttonset.append @dropdownform
      toolbar.append buttonset

    updateCharacterSelectRecent: (contentId) ->
      form = $('#' + @_content_id);
      recent = form.find('.character_recent');
      recent.html('')
      if ( $.isArray(window._character_select_recent) )
        $.each window._character_select_recent, (index,value) =>
          if ( index < @options.max_recent )
            pos = value.charCodeAt(0)
            recent.append('<span class="character" rel="' + pos + '">&#' + pos + ';</span>')
      @updateCharacterButtons()

    updateCharacterSelect: (contentId) ->
      form = $('#' + @_content_id);
      characters = form.find('.characters');
      characters.html('')
      column = 1
      #console.log(@selected_range_start,@selected_range_end)
      for pos in [@selected_range_start...@selected_range_end]
        characters.append('<span class="character" rel="' + pos + '">&#' + pos + ';</span>')
        if ( column % 10 == 0 )
          characters.append('<br/>')
        column = column + 1
      @updateCharacterButtons()

    updateCharacterButtons: (contentId) ->
      form = $('#' + @_content_id);
      characters = form.find('.characters');
      if ( typeof @selected_range_start == 'undefined' )
        @selected_range_start = 64;
      selected_character = '&#' + @selected_range_start + ';'
      all_chars = form.find('.character')
      all_chars.css
        'width':'32px'
        'height':'32px'
        'line-height': '32px'
        'border':'1px solid black'
        'display':'inline-block'
        'text-align':'center'
        'cursor':'pointer'
        '-webkit-user-select': 'none'
      characters.css
        'overflow-y':'auto'
        'overflow-x':'hidden'
        'padding-right': '20px'
        'max-height':'192px' # 32x6rows
        'margin-left':'-1px'
        #margin-left is a HACK for opening the dropdownform the second time
      all_chars.unbind 'click'
      all_chars.unbind 'dblclick'
      all_chars.unbind 'mouseover'
      all_chars.unbind 'mouseout'
      all_chars.bind 'click', (event) =>
        character = $('#' + @tmpid)
        target = $(event.target).closest('span')
        @selected_character_index = target.attr('rel')
        character.html('&#' + @selected_character_index + ';') 
        all_chars.removeClass('selected')
        target.addClass('selected')
        @html = character[0].outerHTML
        @options.editable.store()
      all_chars.bind 'dblclick', (event) =>
        @_insertAction()
      all_chars.bind 'mouseover', (event) =>
        target = $(event.target).closest('span')
        $('#' + @_content_id).find('.character_preview').html(target.html())
      all_chars.bind 'mouseout', (event) =>
        target = $(event.target).closest('span')
        $('#' + @_content_id).find('.character_preview').html('')

    updateCharacterHTML: (contentId) ->
      character = $('#' + @tmpid)
      if ( typeof @selected_character_index == 'undefined' )
        @selected_character_index = 64;
      selected_character = '&#' + @selected_character_index + ';'
      character.html(selected_character)
      return character[0].outerHTML #?

    recalcHTML: () ->
      @html = @updateCharacterHTML(@_content_id)
      @options.editable.store()
    recalcRange: (char_range) ->
      char_range_elements = char_range.split(/-/)
      range_start = parseInt(char_range_elements[0],16)
      range_end = parseInt(char_range_elements[1],16)
      if ( range_start < 33 )
        range_start = 33 # do not allow control characters
      @selected_range_start = range_start
      @selected_range_end = range_end
      @selected_character_index = range_start
      @updateCharacterSelect()
      @recalcHTML()



    _prepareDropdown: (contentId) ->
      contentArea = jQuery "<div id=\"#{contentId}\"><ul></ul></div>"
      contentAreaUL = contentArea.find('ul')
      @_content_id = contentId


      addSelect = (element,elements) =>
        elid="#{contentId}#{element}"
        el = jQuery "<li><label for\"#{elid}\">" + utils.tr(element) + "</label><select id=\"#{elid}\"/></li>"
        selectbox = el.find('select')
        jQuery.each elements,(label,value) =>
          selectbox.append('<option value="' + value + '">' + label + '</option>')
        recalc= =>
          char_range = selectbox.val() #selectBox('value')
          window._character_select_range = char_range
          @recalcRange(char_range)
        selectbox.bind('keyup change',recalc)
        # selectbox.selectBox()
        el

      addButton = (element,event_handler) =>
        el = jQuery "<li><button class=\"action_button\" id=\"" + @tmpid+element + "\" title=\"" + utils.tr_action_tooltip(element) + "\">" + utils.tr_action_title(element) + "</button></li>"

        #unless containingElement is 'div'
        #  el.addClass 'disabled'

        el.find('button').bind 'click', event_handler
        el

      if ( @options.select )
        contentAreaUL.append addSelect("group", @_blockNames())
      contentAreaUL.append('<li><div class="character_preview"></div><div class="character_recent"></div><div class="characters"></div></li>')
      contentAreaUL.find('.character_preview').css
        'width':'64px'
        'height':'64px'
        'line-height':'64px'
        'font-size':'400%'
        'vertical-align':'middle'
        'text-align':'center'
        #'border':'1px solid black'
        'float':'left'
      contentAreaUL.find('.character_recent').css
        'height':'32px'
        'line-height':'32px'
        'font-size':'200%'
        'vertical-align':'middle'
        'text-align':'center'
        #'border':'1px solid black'
      
      this_editable = @options.editable
      contentAreaUL.append addButton "Apply", =>
        @_applyAction()
      contentAreaUL.append addButton "Insert", =>
        @_insertAction()
      contentAreaUL.append addButton "Cancel", =>
        @_cancelAction()

      contentArea
    _applyAction: () ->
      @recalcHTML()
      character = jQuery('#' + @tmpid)

      @_addRecent(character.html())
      character.replaceWith(character.html())
      @dropdownform.hallodropdownform('hideForm')

    _insertAction: () ->
      @recalcHTML()
      character = $('#' + @tmpid)
      character_content = $('<span>' + character.html() + '</span>')
      character_content.insertBefore(character)
      @_addRecent(character.html())
      character.html('&#64;')

    _cancelAction: () ->
      $('#' + @tmpid).remove()
      @dropdownform.hallodropdownform('hideForm')

    _prepareButton: (setup, target) ->
      buttonElement = jQuery '<span></span>'
      button_label = 'characterselect'
      if ( window.action_list && window.action_list['hallojs_characterselect'] != undefined )
        button_label =  window.action_list['hallojs_characterselect'].title
      buttonElement.hallodropdownform
        uuid: @options.uuid
        editable: @options.editable
        label: button_label
        command: 'characterselect'
        icon: 'icon-text-height'
        target: target
        setup: setup
        cssClass: @options.buttonCssClass
      buttonElement
    _addRecent: (charcode) ->
      if ( ! $.isArray(window._character_select_recent) )
        window._character_select_recent = []
      already_recent = false
      while ( window._character_select_recent.length > @options.max_recent )
        window._character_select_recent.pop()
      $.each window._character_select_recent, (index,value) =>
        if ( value == charcode )
          already_recent = true
      if ( !already_recent )
        window._character_select_recent.unshift(charcode)
      @updateCharacterSelectRecent()

    _blockNames: () ->
      blocks =
        'Basic Latin': '0000-007F'
        'Latin-1 Supplement': '0080-00FF'
        'Latin Extended-A': '0100-017F'
        'Latin Extended-B': '0180-024F'
        'IPA Extensions': '0250-02AF'
        'Spacing Modifier Letters': '02B0-02FF'
        # not in win32 'Combining Diacritical Marks': '0300-036F'
        'Greek and Coptic': '0370-03FF'
        'Cyrillic': '0400-04FF'
        'Cyrillic Supplement': '0500-052F'
        'Armenian': '0530-058F'
        'Hebrew': '0590-05FF'
        'Arabic': '0600-06FF'
        #'Syriac': '0700-074F'
        #'Arabic Supplement': '0750-077F'
        #'Thaana': '0780-07BF'
        'NKo': '07C0-07FF'
        #'Samaritan': '0800-083F'
        #'Mandaic': '0840-085F'
        #'Arabic Extended-A': '08A0-08FF'
        #'Devanagari': '0900-097F'
        #'Bengali': '0980-09FF'
        #'Gurmukhi': '0A00-0A7F'
        #'Gujarati': '0A80-0AFF'
        #'Oriya': '0B00-0B7F'
        #'Tamil': '0B80-0BFF'
        #'Telugu': '0C00-0C7F'
        #'Kannada': '0C80-0CFF'
        #'Malayalam': '0D00-0D7F'
        #'Sinhala': '0D80-0DFF'
        'Thai': '0E00-0E7F'
        'Lao': '0E80-0EFF'
        #'Tibetan': '0F00-0FFF'
        #'Myanmar': '1000-109F'
        'Georgian': '10A0-10FF'
        #'Hangul Jamo': '1100-11FF'
        'Ethiopic': '1200-137F'
        #'Ethiopic Supplement': '1380-139F'
        'Cherokee': '13A0-13FF'
        'Unified Canadian Aboriginal Syllabics': '1400-167F'
        'Ogham': '1680-169F'
        'Runic': '16A0-16FF'
        #'Tagalog': '1700-171F'
        #'Hanunoo': '1720-173F'
        #'Buhid': '1740-175F'
        #'Tagbanwa': '1760-177F'
        #'Khmer': '1780-17FF'
        #'Mongolian': '1800-18AF'
        #'Unified Canadian Aboriginal Syllabics Extended': '18B0-18FF'
        #'Limbu': '1900-194F'
        #'Tai Le': '1950-197F'
        #'New Tai Lue': '1980-19DF'
        #'Khmer Symbols': '19E0-19FF'
        #'Buginese': '1A00-1A1F'
        #'Tai Tham': '1A20-1AAF'
        #'Balinese': '1B00-1B7F'
        #'Sundanese': '1B80-1BBF'
        #'Batak': '1BC0-1BFF'
        #'Lepcha': '1C00-1C4F'
        #'Ol Chiki': '1C50-1C7F'
        #'Sundanese Supplement': '1CC0-1CCF'
        #'Vedic Extensions': '1CD0-1CFF'
        'Phonetic Extensions': '1D00-1D7F'
        'Phonetic Extensions Supplement': '1D80-1DBF'
        #'Combining Diacritical Marks Supplement': '1DC0-1DFF'
        'Latin Extended Additional': '1E00-1EFF'
        'Greek Extended': '1F00-1FFF'
        # 'General Punctuation': '2000-206F'
        'Superscripts and Subscripts': '2070-209F'
        'Currency Symbols': '20A0-20CF'
        'Combining Diacritical Marks for Symbols': '20D2-20F1'
        'Letterlike Symbols': '2100-214F'
        'Number Forms': '2150-218F'
        'Arrows': '2190-21FF'
        'Mathematical Operators': '2200-22FF'
        'Miscellaneous Technical': '2300-23FF'
        'Control Pictures': '2400-243F'
        'Optical Character Recognition': '2440-245F'
        'Enclosed Alphanumerics': '2460-24FF'
        'Box Drawing': '2500-257F'
        'Block Elements': '2580-259F'
        'Geometric Shapes': '25A0-25FF'
        'Miscellaneous Symbols': '2600-26FF'
        'Dingbats': '2700-27BF'
        'Miscellaneous Mathematical Symbols-A': '27C0-27EF'
        'Supplemental Arrows-A': '27F0-27FF'
        'Braille Patterns': '2800-28FF'
        'Supplemental Arrows-B': '2900-297F'
        'Miscellaneous Mathematical Symbols-B': '2980-29FF'
        'Supplemental Mathematical Operators': '2A00-2AFF'
        'Miscellaneous Symbols and Arrows': '2B00-2BFF'
        #'Glagolitic': '2C00-2C5F'
        'Latin Extended-C': '2C60-2C7F'
        #'Coptic': '2C80-2CFF'
        'Georgian Supplement': '2D00-2D2F'
        'Tifinagh': '2D30-2D7F'
        #'Ethiopic Extended': '2D80-2DDF'
        # too much empty boxes 'Cyrillic Extended-A': '2DE0-2DFF'
        'Supplemental Punctuation': '2E00-2E7F'
        'CJK Radicals Supplement': '2E80-2EFF'
        'Kangxi Radicals': '2F00-2FDF'
        'Ideographic Description Characters': '2FF0-2FFF'
        'CJK Symbols and Punctuation': '3000-303F'
        'Hiragana': '3040-309F'
        'Katakana': '30A0-30FF'
        'Bopomofo': '3100-312F'
        'Hangul Compatibility Jamo': '3130-318F'
        #'Kanbun': '3190-319F'
        'Bopomofo Extended': '31A0-31BF'
        'CJK Strokes': '31C0-31EF'
        #'Katakana Phonetic Extensions': '31F0-31FF'
        'Enclosed CJK Letters and Months': '3200-32FF'
        #crashes webkit 'CJK Compatibility': '3300-33FF'
        #crashes webkit 'CJK Unified Ideographs Extension A': '3400-4DBF'
        'Yijing Hexagram Symbols': '4DC0-4DFF'
        #'CJK Unified Ideographs': '4E00-9FFF'
        #'Yi Syllables': 'A000-A48F'
        #'Yi Radicals': 'A490-A4CF'
        #'Lisu': 'A4D0-A4FF'
        #'Vai': 'A500-A63F'
        'Cyrillic Extended-B': 'A640-A69F'
        #'Bamum': 'A6A0-A6FF'
        'Modifier Tone Letters': 'A700-A71F'
        'Latin Extended-D': 'A720-A7FF'
        #'Syloti Nagri': 'A800-A82F'
        #'Common Indic Number Forms': 'A830-A83F'
        #'Phags-pa': 'A840-A87F'
        #'Saurashtra': 'A880-A8DF'
        #'Devanagari Extended': 'A8E0-A8FF'
        #'Kayah Li': 'A900-A92F'
        #'Rejang': 'A930-A95F'
        #'Hangul Jamo Extended-A': 'A960-A97F'
        #'Javanese': 'A980-A9DF'
        #'Cham': 'AA00-AA5F'
        #'Myanmar Extended-A': 'AA60-AA7F'
        #'Tai Viet': 'AA80-AADF'
        #'Meetei Mayek Extensions': 'AAE0-AAFF'
        #'Ethiopic Extended-A': 'AB00-AB2F'
        #'Meetei Mayek': 'ABC0-ABFF'
        #'Hangul Syllables': 'AC00-D7AF'
        #'Hangul Jamo Extended-B': 'D7B0-D7FF'
        #'High Surrogates': 'D800-DB7F'
        #'High Private Use Surrogates': 'DB80-DBFF'
        #'Low Surrogates': 'DC00-DFFF'
        #'Private Use Area': 'E000-F8FF'
        #'CJK Compatibility Ideographs': 'F900-FAFF'
        'Alphabetic Presentation Forms': 'FB00-FB4F'
        'Arabic Presentation Forms-A': 'FB50-FDFF'
        #'Variation Selectors': 'FE00-FE0F'
        'Vertical Forms': 'FE10-FE1F'
        #'Combining Half Marks': 'FE20-FE2F'
        'CJK Compatibility Forms': 'FE30-FE4F'
        'Small Form Variants': 'FE50-FE6F'
        'Arabic Presentation Forms-B': 'FE70-FEFF'
        'Halfwidth and Fullwidth Forms': 'FF00-FFEF'
        #'Specials': 'FFF0-FFFF'
        #'Linear B Syllabary': '10000-1007F'
        #'Linear B Ideograms': '10080-100FF'
        #'Aegean Numbers': '10100-1013F'
        #'Ancient Greek Numbers': '10140-1018F'
        #'Ancient Symbols': '10190-101CF'
        #'Phaistos Disc': '101D0-101FF'
        #'Lycian': '10280-1029F'
        #'Carian': '102A0-102DF'
        'Old Italic': '10300-1032F'
        #'Gothic': '10330-1034F'
        #'Ugaritic': '10380-1039F'
        #'Old Persian': '103A0-103DF'
        #'Deseret': '10400-1044F'
        #'Shavian': '10450-1047F'
        #'Osmanya': '10480-104AF'
        #'Cypriot Syllabary': '10800-1083F'
        #'Imperial Aramaic': '10840-1085F'
        #'Phoenician': '10900-1091F'
        #'Lydian': '10920-1093F'
        #'Meroitic Hieroglyphs': '10980-1099F'
        #'Meroitic Cursive': '109A0-109FF'
        #'Kharoshthi': '10A00-10A5F'
        #'Old South Arabian': '10A60-10A7F'
        #'Avestan': '10B00-10B3F'
        #'Inscriptional Parthian': '10B40-10B5F'
        #'Inscriptional Pahlavi': '10B60-10B7F'
        #'Old Turkic': '10C00-10C4F'
        #'Rumi Numeral Symbols': '10E60-10E7F'
        #'Brahmi': '11000-1107F'
        #'Kaithi': '11080-110CF'
        #'Sora Sompeng': '110D0-110FF'
        #'Chakma': '11100-1114F'
        #'Sharada': '11180-111DF'
        #'Takri': '11680-116CF'
        #'Cuneiform': '12000-123FF'
        #'Cuneiform Numbers and Punctuation': '12400-1247F'
        #'Egyptian Hieroglyphs': '13000-1342F'
        #'Bamum Supplement': '16800-16A3F'
        #'Miao': '16F00-16F9F'
        #'Kana Supplement': '1B000-1B0FF'
        #'Byzantine Musical Symbols': '1D000-1D0FF'
        #'Musical Symbols': '1D100-1D1FF'
        #'Ancient Greek Musical Notation': '1D200-1D24F'
        'Tai Xuan Jing Symbols': '1D300-1D35F'
        #'Counting Rod Numerals': '1D360-1D37F'
        'Mathematical Alphanumeric Symbols': '1D400-1D7FF'
        #'Arabic Mathematical Alphabetic Symbols': '1EE00-1EEFF'
        #'Mahjong Tiles': '1F000-1F02F'
        'Domino Tiles': '1F030-1F09F'
        'Playing Cards': '1F0A0-1F0FF'
        #'Enclosed Alphanumeric Supplement': '1F100-1F1FF'
        #'Enclosed Ideographic Supplement': '1F200-1F2FF'
        'Miscellaneous Symbols And Pictographs': '1F300-1F5FF'
        'Emoticons': '1F600-1F64F'
        #'Transport And Map Symbols': '1F680-1F6FF'
        #'Alchemical Symbols': '1F700-1F77F'
        # kills webkit: 'CJK Unified Ideographs Extension B': '20000-2A6DF'
        # kills webkit: 'CJK Unified Ideographs Extension C': '2A700-2B73F'
        # kills webkit: 'CJK Unified Ideographs Extension D': '2B740-2B81F'
        # kills webkit: 'CJK Compatibility Ideographs Supplement': '2F800-2FA1F'
        #'Tags': 'E0000-E007F'
        #'Variation Selectors Supplement': 'E0100-E01EF'
        # kills webkit: 'Supplementary Private Use Area-A': 'F0000-FFFFF'
        # kills webkit: 'Supplementary Private Use Area-B': '100000-10FFFF'
      blocks

)(jQuery)
