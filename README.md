Hallo - contentEditable for jQuery UI
=====================================

Hallo is a very simple in-place rich text editor for web pages. It uses jQuery UI and the [HTML5 contentEditable functionality](https://developer.mozilla.org/en/rich-text_editing_in_mozilla) to edit web content.

The widget has been written as a simple and liberally licensed editor. It doesn't aim to replace popular editors like [Aloha](http://aloha-editor.org), but instead to provide a simpler and more reusable option.

Read the [introductory blog post](http://bergie.iki.fi/blog/hallo-editor/) for more information.

## Using the editor

You need jQuery and jQuery UI loaded. An easy way to do this is to use Google's JS service:

```html
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
<script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js"></script>
```

The editor toolbar is using jQuery UI theming, so you'll probably also want to [grab a theme](http://jqueryui.com/themeroller/) that fits your needs. Toolbar pluggins use icons from [Font Awesome](http://fortawesome.github.com/Font-Awesome/). Check these [integration instructions](http://fortawesome.github.com/Font-Awesome/#integration) for the right way to include Font Awesome depending on if/how you use Twitter Bootstrap. To style the toolbar as it appears in the demo, you'll also want to add some CSS (like background and border) to the class `hallotoolbar`.

```html
<link rel="stylesheet" href="/path/to/your/jquery-ui.css">
<link rel="stylesheet" href="/path/to/your/font-awesome.css">
```

Then include Hallo itself:

```html
<script src="hallo.js"></script>
```

Editor activation is easy:

```javascript
jQuery('p').hallo();
```

You can also deactivate the editor:

```javascript
jQuery('p').hallo({editable: false});
```

Hallo itself only makes the selected DOM elements editable and doesn't provide any formatting tools. Formatting is accomplished by loading plugins when initializing Hallo:

```javascript
jQuery('.editable').hallo({
  plugins: {
    'halloformat': {}
  }
});
```

This example would enable the simple formatting plugin that provides functionality like _bold_ and _italic_. You can include as many Hallo plugins as you want, and if necessary pass them options.

Hallo has got more options you set when instantiating. See the [hallo.coffee](https://github.com/bergie/hallo/blob/master/src/hallo.coffee) file for further documentation.

### Events

Hallo provides some events that are useful for integration. You can use [jQuery bind](http://api.jquery.com/bind/) to subscribe to them:

* `halloenabled`: Triggered when an editable is enabled (`editable` set to `true`)
* `hallodisabled`: Triggered when an editable is disabled (`editable` set to `false`)
* `hallomodified`: Triggered whenever user has changed the contents being edited. Event data key `content` contains the HTML
* `halloactivated`: Triggered when user activates an editable area (usually by clicking it)
* `hallodeactivated`: Triggered when user deactivates an editable area

## Plugins

* halloformat - Adds Bold, Italic, StrikeThrough and Underline support to the toolbar. (Enable/Disable with options: "formattings": {"bold": true, "italic": true, "strikeThough": true, "underline": false})
* halloheadings - Adds support for H1, H2, H3. You can pass a headings option key "headers" with an array of header sizes (i.e. headers: [1,2,5,6])
* hallojustify - Adds align left, center, right support
* hallolists - Adds support for ordered and unordered lists (Pick with options: "lists": {"ordered": false, "unordered": true})
* halloreundo - Adds support for undo and redo
* hallolink - Adds support to add links to a selection (currently not working)

## Licensing

Hallo is free software available under the [MIT license](http://en.wikipedia.org/wiki/MIT_License).

## Contributing

Hallo is written in [CoffeeScript](http://jashkenas.github.com/coffee-script/), a simple language that compiles into JavaScript. To generate the JavaScript code to `examples/hallo.js` from Hallo sources, run CoffeeScript's [cake command](http://coffeescript.org/#cake):

    $ cake build

If you want to also generate a minified version, run:

    $ cake min

Hallo development is coordinated using Git. Just fork the [Hallo repository on GitHub](https://github.com/bergie/hallo) and [send pull requests](http://help.github.com/pull-requests/).

To build Hallo on a otherwise uncaked system you need to install nodejs, use the npm package manager to install coffee-script globaly and add the node-module 'async' to the git source directory:

    $ sudo ${package-manager} install nodejs
    $ sudo npm install -g coffee-script
    $ npm install async
    
Then other node modules might be useful like uglify-js to use the 'min' target and 'docco-husky' that itself requires a additional dependency: pygments
    
    $ sudo ${package-manager} install pygments
    $ sudo npm install -g docco-husky
    $ sudo npm install -g uglify-js

### Writing plugins

Hallo plugins are written as regular [jQuery UI widgets](http://semantic-interaction.org/blog/2011/03/01/jquery-ui-widget-factory/).

When Hallo is loaded it will also load all the enabled plugins for the element, and pass them some additional options:

* `editable`: The main Hallo widget instance
* `toolbar`: Toolbar jQuery object for that Hallo instance
* `uuid`: unique identifier of the Hallo instance, can be used for element IDs

A simplistic plugin would look like the following:

```coffeescript
#    Formatting plugin for Hallo
#    (c) 2011 Henri Bergius, IKS Consortium
#    Hallo may be freely distributed under the MIT license
((jQuery) ->
  jQuery.widget "IKS.halloformat",
    boldElement: null

    options:
      uuid: ''
      editable: null

    _create: ->
      # Add any actions you want to run on plugin initialization
      # here

    populateToolbar: (toolbar) ->
      # Create an element for holding the button
      @boldElement = jQuery '<span></span>'

      # Use Hallo Button
      @boldElement.hallobutton
        uuid: @options.uuid
        editable: @options.editable
        label: 'Bold'
        # Icons come from Font Awesome
        icon: 'icon-bold'
        # Commands are used for execCommand and queryCommandState
        command: 'bold'

      # Append the button to toolbar
      toolbar.append @boldElement

    cleanupContentClone: (element) ->
      # Perform content clean-ups before HTML is sent out

)(jQuery)
```

### About this fork

This repository is used for a product widget. It is stuck on jQuery-1.6 (see https://github.com/git-j/hallo/commit/7fafd5f50b537c58497f7eb658c977d91667dea7) and introduces concepts that did not exist in the original (eg dropdownforms). The goal is to have a customizable editor for a Qt-Webkit based contenteditable with no consideration on how this would work in chrome/firefox or ie and any other environment than the specific widget.
You may review the plugins and fork them for your use. When you like to build 'your own' product, it is more save to fork.

The changes regarding the original code are
- consistent indentation
- introduction of dropdownforms (for images, tables and formula)
- introduction of image-buttons (instead of fontawesome)
- in-script undo management for undoing/redoing changes like $('img').addClass('highlight') that are not covered by the contenteditable commands and for undoing different contenteditables separately*
- keyboard handling for some common strokes (ctrl+b) and the possibility to change and add more
- magic for saving and restoring the current selection between multiple instances and during focus-stealing activities (eg like upload a image somehow)
- citation display (requires propetary library) or to make it simpler non-editable popups on the editable. something similar existed with the IKS.annotation plugins*
- character selection from unicode table with the smallest common character-base in win32/linux/macos
- spellchecking using bjspell (discontinued)*
- cleanup html plugin
- sup/sub handling that is buggy in webkit (not accessible with queryCommandState)
- plaintext editor that uses textarea or codewarrior
- table plugin
- version selection and creating plugin*

* requires additional infrastructure not part of this project

The additional infrastructure includes:

### utils

```
window.utils = {
  functions that wrap code like
  sanitize: function(string){return string.replace(/</g,'&lt;').replace(/>/g,'&gt;');}
}
```

### translations

translated actions and uiStrings that are loaded outside the hallo-context

```
window.action_list = {
  'hallojs_undo': {title:'Undo',tooltip:'undoes something'}
}
```

### class DOMNugget

concept for encapsulating the access to nuggets (atomic information) that are structured like this:

```
<div class="nugget">
  <div class="name"></div>
  <div class="content"></div>
  <div class="versions"></div>
  <div class="sourcedescriptions"></div>
</div>
```
DOMNugget cannot be publicly aquried and is NOT subject to MIT license yet

### class ObjectModelConnector (window.omc)

infrastructure to store data into a persistent storage system. Similar but not as powerful as Backbone models. Only useful in a [db - qt - hallojs] environment, needs reimplementation for client-server

ObjectModelConnector cannot be publicly aquried and is NOT subject to MIT license yet

### class ObjectContextConnector (window.occ)

infrastructure to signal widget parents to switch or do stuff that is not widget related. Similar but not as powerful as Backbone router

ObjectContextConnector cannot be publicly aquried and is NOT subject to MIT license yet

### class SettingsModelConnector (window.omc_settings)

infrastructure aquire application-wide settings

SettingsModelConnector cannot be publicly aquried and is NOT subject to MIT license yet

### class List

ul-li based list implementation that can display data and provide actions for the list (eg sort/filter) and for each item (eg remove)

List cannot be publicly aquried and is NOT subject to MIT license yet

### project UndoManager

qt-inspired undo handling in javascript.

UndoManager can be aquired via https://github.com/git-j/undomanager

### project Citeproc

code that uses citeproc.js to process bibliographic information into html. handles aquirement and processing of bibliographic data as well as loading of CSL and locales

List cannot be publicly aquried and is NOT subject to MIT license yet