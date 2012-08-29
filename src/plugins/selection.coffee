#     Hallo - a rich text editing jQuery UI widget
#     (c) 2011 Henri Bergius, IKS Consortium
#     Hallo may be freely distributed under the MIT license
#     selectText functionality for plugins to select text
#     in order to create undoable actions

jQuery.extend jQuery.fn ,
  selectText: ->
    element = this[0]
    if document.body.createTextRange
      range = document.body.createTextRange()
      range.moveToElementText(element)
      range.select()
    else if window.getSelection
      selection = window.getSelection()
      range = document.createRange()
      range.selectNodeContents(element)
      selection.removeAllRanges()
      selection.addRange(range)
