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
    else if rangy.getSelection
      selection = rangy.getSelection()
      range = rangy.createRange()
      range.selectNodeContents(element)
      selection.setSingleRange(range)
