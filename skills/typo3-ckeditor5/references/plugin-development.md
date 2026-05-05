# CKEditor 5 Plugin Development for TYPO3

## Plugin Architecture

### Standard Plugin Structure

```
packages/my-plugin/
├── src/
│   ├── index.js           # Main export
│   ├── myplugin.js        # Plugin entry point
│   ├── mypluginediting.js # Schema, converters, commands
│   ├── mypluginui.js      # UI components
│   ├── myplugincommand.js # Command implementation
│   └── ui/
│       ├── mypluginview.js
│       └── mypluginformview.js
├── theme/
│   └── myplugin.css
├── lang/
│   └── translations/
│       ├── en.json
│       └── de.json
└── package.json
```

### Main Plugin Class

```javascript
// src/myplugin.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import MyPluginEditing from './mypluginediting';
import MyPluginUI from './mypluginui';

import '../theme/myplugin.css';

export default class MyPlugin extends Plugin {
    /**
     * Required plugins - instantiated before this plugin
     */
    static get requires() {
        return [MyPluginEditing, MyPluginUI];
    }

    /**
     * Plugin name for identification
     */
    static get pluginName() {
        return 'MyPlugin';
    }

    /**
     * Plugin initialization
     */
    init() {
        console.log('MyPlugin initialized');
    }

    /**
     * Called after all plugins are initialized
     */
    afterInit() {
        // Integration with other plugins
    }

    /**
     * Cleanup on destroy
     */
    destroy() {
        super.destroy();
    }
}
```

## Editing Plugin

### Schema Definition

```javascript
// src/mypluginediting.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import { Widget, toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget';
import MyPluginCommand from './myplugincommand';

export default class MyPluginEditing extends Plugin {
    static get requires() {
        return [Widget];
    }

    static get pluginName() {
        return 'MyPluginEditing';
    }

    init() {
        this._defineSchema();
        this._defineConverters();
        this._defineCommands();
    }

    /**
     * Define model schema
     */
    _defineSchema() {
        const schema = this.editor.model.schema;

        // Block element (like a content box)
        schema.register('myPluginBox', {
            inheritAllFrom: '$blockObject',
            allowAttributes: ['boxType', 'boxTitle']
        });

        // Nested editable content
        schema.register('myPluginContent', {
            isLimit: true,
            allowIn: 'myPluginBox',
            allowContentOf: '$root'
        });

        // Inline element
        schema.register('myPluginInline', {
            allowWhere: '$text',
            isInline: true,
            isObject: true,
            allowAttributes: ['data-id']
        });

        // Text attribute (like bold, italic)
        schema.extend('$text', {
            allowAttributes: 'myPluginHighlight'
        });
    }

    /**
     * Define model-view converters
     */
    _defineConverters() {
        const conversion = this.editor.conversion;

        // --- Block Element Converters ---

        // Upcast: view -> model
        // NOTE: `viewElement` is a CKE5 view element, NOT a DOM element.
        // Use `getAttribute()` here — `viewElement.dataset` does not exist
        // and SonarCloud's `javascript:S7761` is a false positive on these
        // callsites. See `ckeditor5-architecture.md` ->
        // "Pitfall: View Elements Are Not DOM Elements".
        conversion.for('upcast').elementToElement({
            view: {
                name: 'div',
                classes: 'my-plugin-box'
            },
            model: (viewElement, { writer }) => {
                return writer.createElement('myPluginBox', {
                    boxType: viewElement.getAttribute('data-type') || 'default',
                    boxTitle: viewElement.getAttribute('data-title') || ''
                });
            }
        });

        // Data downcast: model -> data view (for saving)
        conversion.for('dataDowncast').elementToElement({
            model: 'myPluginBox',
            view: (modelElement, { writer }) => {
                return writer.createContainerElement('div', {
                    class: 'my-plugin-box',
                    'data-type': modelElement.getAttribute('boxType'),
                    'data-title': modelElement.getAttribute('boxTitle')
                });
            }
        });

        // Editing downcast: model -> editing view (for editor display)
        conversion.for('editingDowncast').elementToElement({
            model: 'myPluginBox',
            view: (modelElement, { writer }) => {
                const boxType = modelElement.getAttribute('boxType');
                const boxTitle = modelElement.getAttribute('boxTitle');

                const container = writer.createContainerElement('div', {
                    class: `my-plugin-box my-plugin-box--${boxType}`
                });

                // Add title element
                if (boxTitle) {
                    const titleElement = writer.createContainerElement('div', {
                        class: 'my-plugin-box__title'
                    });
                    writer.insert(writer.createPositionAt(titleElement, 0),
                        writer.createText(boxTitle));
                    writer.insert(writer.createPositionAt(container, 0), titleElement);
                }

                return toWidget(container, writer, {
                    label: 'Content box widget',
                    hasSelectionHandle: true
                });
            }
        });

        // --- Nested Content Converters ---

        conversion.for('upcast').elementToElement({
            view: {
                name: 'div',
                classes: 'my-plugin-content'
            },
            model: 'myPluginContent'
        });

        conversion.for('dataDowncast').elementToElement({
            model: 'myPluginContent',
            view: {
                name: 'div',
                classes: 'my-plugin-content'
            }
        });

        conversion.for('editingDowncast').elementToElement({
            model: 'myPluginContent',
            view: (modelElement, { writer }) => {
                const content = writer.createEditableElement('div', {
                    class: 'my-plugin-content'
                });
                return toWidgetEditable(content, writer);
            }
        });

        // --- Attribute Converters ---

        conversion.for('downcast').attributeToAttribute({
            model: {
                name: 'myPluginBox',
                key: 'boxType'
            },
            view: modelAttributeValue => ({
                key: 'data-type',
                value: modelAttributeValue
            })
        });

        // --- Text Attribute Converters ---

        conversion.for('upcast').elementToAttribute({
            view: {
                name: 'mark',
                classes: 'my-highlight'
            },
            model: {
                key: 'myPluginHighlight',
                value: true
            }
        });

        conversion.for('downcast').attributeToElement({
            model: 'myPluginHighlight',
            view: (modelAttributeValue, { writer }) => {
                if (modelAttributeValue) {
                    return writer.createAttributeElement('mark', {
                        class: 'my-highlight'
                    });
                }
            }
        });
    }

    /**
     * Define commands
     */
    _defineCommands() {
        const editor = this.editor;

        editor.commands.add('insertMyPluginBox', new MyPluginCommand(editor));
        editor.commands.add('updateMyPluginBox', new UpdateMyPluginBoxCommand(editor));
        editor.commands.add('toggleMyPluginHighlight', new ToggleHighlightCommand(editor));
    }
}
```

## Command Implementation

### Insert Command

```javascript
// src/myplugincommand.js
import { Command } from '@ckeditor/ckeditor5-core';

export default class MyPluginCommand extends Command {
    /**
     * Execute the command
     */
    execute(options = {}) {
        const editor = this.editor;
        const model = editor.model;

        model.change(writer => {
            // Create the box element
            const myPluginBox = writer.createElement('myPluginBox', {
                boxType: options.type || 'info',
                boxTitle: options.title || ''
            });

            // Create nested content
            const myPluginContent = writer.createElement('myPluginContent');
            const paragraph = writer.createElement('paragraph');

            writer.append(paragraph, myPluginContent);
            writer.append(myPluginContent, myPluginBox);

            // Insert into document
            model.insertObject(myPluginBox, null, null, {
                setSelection: 'on',
                findOptimalPosition: 'auto'
            });
        });
    }

    /**
     * Refresh command state
     */
    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;

        // Check if we can insert at current position
        const allowedIn = model.schema.findAllowedParent(
            selection.getFirstPosition(),
            'myPluginBox'
        );

        this.isEnabled = allowedIn !== null;

        // Get current value if inside a box
        const selectedElement = selection.getSelectedElement();
        if (selectedElement && selectedElement.is('element', 'myPluginBox')) {
            this.value = {
                type: selectedElement.getAttribute('boxType'),
                title: selectedElement.getAttribute('boxTitle')
            };
        } else {
            this.value = null;
        }
    }
}
```

### Update Command

```javascript
// src/updatemypluginboxcommand.js
import { Command } from '@ckeditor/ckeditor5-core';

export default class UpdateMyPluginBoxCommand extends Command {
    execute(options) {
        const editor = this.editor;
        const model = editor.model;
        const selection = model.document.selection;

        const selectedElement = selection.getSelectedElement();

        if (selectedElement && selectedElement.is('element', 'myPluginBox')) {
            model.change(writer => {
                if (options.type !== undefined) {
                    writer.setAttribute('boxType', options.type, selectedElement);
                }
                if (options.title !== undefined) {
                    writer.setAttribute('boxTitle', options.title, selectedElement);
                }
            });
        }
    }

    refresh() {
        const selection = this.editor.model.document.selection;
        const selectedElement = selection.getSelectedElement();

        this.isEnabled = selectedElement && selectedElement.is('element', 'myPluginBox');
    }
}
```

### Toggle Attribute Command

```javascript
// src/togglehighlightcommand.js
import { Command } from '@ckeditor/ckeditor5-core';

export default class ToggleHighlightCommand extends Command {
    execute() {
        const model = this.editor.model;
        const selection = model.document.selection;

        model.change(writer => {
            const ranges = model.schema.getValidRanges(
                selection.getRanges(),
                'myPluginHighlight'
            );

            for (const range of ranges) {
                if (this.value) {
                    writer.removeAttribute('myPluginHighlight', range);
                } else {
                    writer.setAttribute('myPluginHighlight', true, range);
                }
            }
        });
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;

        this.isEnabled = model.schema.checkAttributeInSelection(
            selection,
            'myPluginHighlight'
        );

        this.value = selection.hasAttribute('myPluginHighlight');
    }
}
```

## UI Plugin

### Button UI

```javascript
// src/mypluginui.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import { ButtonView } from '@ckeditor/ckeditor5-ui';

import boxIcon from '../theme/icons/box.svg';

export default class MyPluginUI extends Plugin {
    static get pluginName() {
        return 'MyPluginUI';
    }

    init() {
        const editor = this.editor;
        const t = editor.t;

        // Add button to toolbar
        editor.ui.componentFactory.add('myPluginBox', locale => {
            const command = editor.commands.get('insertMyPluginBox');
            const buttonView = new ButtonView(locale);

            buttonView.set({
                label: t('Insert Box'),
                icon: boxIcon,
                tooltip: true,
                withText: false
            });

            // Bind button state to command
            buttonView.bind('isEnabled').to(command);
            buttonView.bind('isOn').to(command, 'value', value => !!value);

            // Execute command on click
            buttonView.on('execute', () => {
                editor.execute('insertMyPluginBox', { type: 'info' });
                editor.editing.view.focus();
            });

            return buttonView;
        });

        // Add highlight button
        editor.ui.componentFactory.add('myPluginHighlight', locale => {
            const command = editor.commands.get('toggleMyPluginHighlight');
            const buttonView = new ButtonView(locale);

            buttonView.set({
                label: t('Highlight'),
                icon: '<svg>...</svg>',
                tooltip: true,
                isToggleable: true
            });

            buttonView.bind('isEnabled').to(command);
            buttonView.bind('isOn').to(command, 'value');

            buttonView.on('execute', () => {
                editor.execute('toggleMyPluginHighlight');
                editor.editing.view.focus();
            });

            return buttonView;
        });
    }
}
```

### Dropdown UI

```javascript
// src/mypluginui.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import {
    createDropdown,
    addListToDropdown,
    Model,
    ViewModel
} from '@ckeditor/ckeditor5-ui';
import { Collection } from '@ckeditor/ckeditor5-utils';

export default class MyPluginUI extends Plugin {
    init() {
        const editor = this.editor;
        const t = editor.t;

        editor.ui.componentFactory.add('myPluginDropdown', locale => {
            const dropdownView = createDropdown(locale);
            const command = editor.commands.get('insertMyPluginBox');

            // Create dropdown items
            const items = new Collection();

            const boxTypes = [
                { type: 'info', label: 'Info Box', icon: '💡' },
                { type: 'warning', label: 'Warning Box', icon: '⚠️' },
                { type: 'success', label: 'Success Box', icon: '✅' },
                { type: 'error', label: 'Error Box', icon: '❌' }
            ];

            for (const boxType of boxTypes) {
                const itemModel = new Model({
                    type: boxType.type,
                    label: `${boxType.icon} ${boxType.label}`,
                    withText: true
                });

                items.add({
                    type: 'button',
                    model: itemModel
                });
            }

            addListToDropdown(dropdownView, items);

            // Configure dropdown button
            dropdownView.buttonView.set({
                label: t('Insert Box'),
                tooltip: true,
                withText: true
            });

            dropdownView.bind('isEnabled').to(command);

            // Handle item selection
            dropdownView.on('execute', evt => {
                editor.execute('insertMyPluginBox', {
                    type: evt.source.type
                });
                editor.editing.view.focus();
            });

            return dropdownView;
        });
    }
}
```

### Balloon/Contextual UI

```javascript
// src/mypluginui.js
import { Plugin } from '@ckeditor/ckeditor5-core';
import { ContextualBalloon, clickOutsideHandler } from '@ckeditor/ckeditor5-ui';
import MyPluginFormView from './ui/mypluginformview';

export default class MyPluginUI extends Plugin {
    static get requires() {
        return [ContextualBalloon];
    }

    init() {
        const editor = this.editor;

        this._balloon = editor.plugins.get(ContextualBalloon);
        this._formView = this._createFormView();

        // Add toolbar button that opens balloon
        editor.ui.componentFactory.add('myPluginEdit', () => {
            const button = new ButtonView();

            button.set({
                label: 'Edit Box',
                tooltip: true,
                withText: true
            });

            button.on('execute', () => {
                this._showUI();
            });

            return button;
        });
    }

    _createFormView() {
        const editor = this.editor;
        const formView = new MyPluginFormView(editor.locale);

        // Handle form submission
        formView.on('submit', () => {
            editor.execute('updateMyPluginBox', {
                type: formView.typeInputView.fieldView.value,
                title: formView.titleInputView.fieldView.value
            });
            this._hideUI();
        });

        // Handle cancel
        formView.on('cancel', () => {
            this._hideUI();
        });

        // Close on click outside
        clickOutsideHandler({
            emitter: formView,
            activator: () => this._balloon.visibleView === formView,
            contextElements: [this._balloon.view.element],
            callback: () => this._hideUI()
        });

        return formView;
    }

    _showUI() {
        const selection = this.editor.model.document.selection;
        const selectedElement = selection.getSelectedElement();

        if (selectedElement) {
            // Populate form with current values
            this._formView.typeInputView.fieldView.value =
                selectedElement.getAttribute('boxType') || '';
            this._formView.titleInputView.fieldView.value =
                selectedElement.getAttribute('boxTitle') || '';
        }

        this._balloon.add({
            view: this._formView,
            position: this._getBalloonPositionData()
        });

        this._formView.focus();
    }

    _hideUI() {
        this._balloon.remove(this._formView);
        this.editor.editing.view.focus();
    }

    _getBalloonPositionData() {
        const view = this.editor.editing.view;
        const viewDocument = view.document;

        return {
            target: view.domConverter.mapViewToDom(
                viewDocument.selection.getSelectedElement()
            )
        };
    }
}
```

### Form View

```javascript
// src/ui/mypluginformview.js
import {
    View,
    LabeledFieldView,
    createLabeledInputText,
    ButtonView,
    submitHandler
} from '@ckeditor/ckeditor5-ui';
import { icons } from '@ckeditor/ckeditor5-core';

export default class MyPluginFormView extends View {
    constructor(locale) {
        super(locale);

        const t = locale.t;

        // Create form fields
        this.typeInputView = this._createInput(t('Box Type'));
        this.titleInputView = this._createInput(t('Title'));

        // Create buttons
        this.saveButtonView = this._createButton(
            t('Save'),
            icons.check,
            'ck-button-save'
        );
        this.saveButtonView.type = 'submit';

        this.cancelButtonView = this._createButton(
            t('Cancel'),
            icons.cancel,
            'ck-button-cancel'
        );

        this.cancelButtonView.delegate('execute').to(this, 'cancel');

        // Define template
        this.setTemplate({
            tag: 'form',
            attributes: {
                class: ['ck', 'ck-my-plugin-form'],
                tabindex: '-1'
            },
            children: [
                this.typeInputView,
                this.titleInputView,
                this.saveButtonView,
                this.cancelButtonView
            ]
        });
    }

    render() {
        super.render();

        // Submit handler
        submitHandler({
            view: this
        });
    }

    focus() {
        this.typeInputView.focus();
    }

    _createInput(label) {
        const labeledInput = new LabeledFieldView(this.locale, createLabeledInputText);
        labeledInput.label = label;
        return labeledInput;
    }

    _createButton(label, icon, className) {
        const button = new ButtonView(this.locale);

        button.set({
            label,
            icon,
            tooltip: true,
            class: className
        });

        return button;
    }
}
```

## TYPO3 Integration

### Bundle for TYPO3

```javascript
// Resources/Public/JavaScript/Ckeditor/my-plugin-bundle.js
import MyPlugin from './Plugins/MyPlugin.js';
import MyPluginEditing from './Plugins/MyPluginEditing.js';
import MyPluginUI from './Plugins/MyPluginUI.js';
import MyPluginCommand from './Plugins/MyPluginCommand.js';

// Export all components
export { MyPlugin, MyPluginEditing, MyPluginUI, MyPluginCommand };

// Default export for TYPO3 import
export default { MyPlugin };
```

### CSS for TYPO3

```css
/* Resources/Public/Css/Ckeditor/my-plugin.css */

/* Editor styles */
.ck-editor .my-plugin-box {
    border: 2px solid #ddd;
    border-radius: 4px;
    padding: 1rem;
    margin: 1rem 0;
}

.ck-editor .my-plugin-box--info {
    border-color: #17a2b8;
    background-color: #d1ecf1;
}

.ck-editor .my-plugin-box--warning {
    border-color: #ffc107;
    background-color: #fff3cd;
}

.ck-editor .my-plugin-box--success {
    border-color: #28a745;
    background-color: #d4edda;
}

.ck-editor .my-plugin-box--error {
    border-color: #dc3545;
    background-color: #f8d7da;
}

.ck-editor .my-plugin-box__title {
    font-weight: bold;
    margin-bottom: 0.5rem;
}

.ck-editor .my-plugin-content {
    min-height: 2rem;
}

/* Widget selection handle */
.ck-editor .my-plugin-box.ck-widget {
    outline: none;
}

.ck-editor .my-plugin-box.ck-widget.ck-widget_selected {
    outline: 3px solid var(--ck-color-focus-border);
}

/* Form styles */
.ck-my-plugin-form {
    padding: 1rem;
}

.ck-my-plugin-form .ck-labeled-field-view {
    margin-bottom: 1rem;
}
```

### Registration in ext_localconf.php

```php
<?php
// ext_localconf.php

defined('TYPO3') or die();

// Register CKEditor 5 plugin
$GLOBALS['TYPO3_CONF_VARS']['RTE']['CKEditor5']['plugins']['my-plugin'] = [
    'entryPoint' => 'EXT:my_extension/Resources/Public/JavaScript/Ckeditor/my-plugin-bundle.js',
    'stylesheets' => [
        'EXT:my_extension/Resources/Public/Css/Ckeditor/my-plugin.css',
    ],
];
```

### YAML Configuration

```yaml
# Configuration/RTE/Default.yaml
editor:
  config:
    toolbar:
      items:
        - heading
        - '|'
        - bold
        - italic
        - '|'
        - myPluginBox      # Button
        - myPluginDropdown # Dropdown
        - myPluginHighlight

    importModules:
      - '@vendor/my_extension/ckeditor/my-plugin-bundle.js'

processing:
  allowTags:
    - div
    - mark
    # ... other tags

  allowAttributes:
    - { attribute: 'class', elements: ['div', 'mark'] }
    - { attribute: 'data-type', elements: 'div' }
    - { attribute: 'data-title', elements: 'div' }
```

## Testing

### Unit Tests

```javascript
// tests/myplugincommand.test.js
import { Editor } from '@ckeditor/ckeditor5-core';
import { Paragraph } from '@ckeditor/ckeditor5-paragraph';
import MyPluginEditing from '../src/mypluginediting';
import MyPluginCommand from '../src/myplugincommand';

describe('MyPluginCommand', () => {
    let editor;
    let command;

    beforeEach(async () => {
        editor = await Editor.create(document.createElement('div'), {
            plugins: [Paragraph, MyPluginEditing]
        });
        command = editor.commands.get('insertMyPluginBox');
    });

    afterEach(async () => {
        await editor.destroy();
    });

    it('should be disabled in empty editor', () => {
        expect(command.isEnabled).toBe(true);
    });

    it('should insert box with default type', () => {
        command.execute();

        const root = editor.model.document.getRoot();
        const box = root.getChild(0);

        expect(box.name).toBe('myPluginBox');
        expect(box.getAttribute('boxType')).toBe('info');
    });

    it('should insert box with specified type', () => {
        command.execute({ type: 'warning', title: 'Test' });

        const root = editor.model.document.getRoot();
        const box = root.getChild(0);

        expect(box.getAttribute('boxType')).toBe('warning');
        expect(box.getAttribute('boxTitle')).toBe('Test');
    });
});
```

## Consumable API - Preventing Duplicate Processing

**Critical pattern for upcast converters** that need to prevent other converters (like GHS - General HTML Support) from processing the same element.

### The Problem: Duplicate Elements

When multiple converters can handle the same HTML element, you get duplicate output:

```html
<!-- Input: linked image -->
<a href="/page"><img src="image.jpg"></a>

<!-- Bug: GHS preserves <a> because your converter didn't consume it -->
<a href="/page"><a href="/page"><img src="image.jpg"></a></a>
```

### The Solution: test() Before consume()

**Always use `consumable.test()` before `consumable.consume()`** to prevent regressions:

```javascript
// ❌ BAD: Consume without testing - may silently fail
conversion.for('upcast').add(dispatcher => {
    dispatcher.on('element:a', (evt, data, conversionApi) => {
        const { consumable, writer } = conversionApi;
        const viewElement = data.viewItem;

        // This might fail if another converter already consumed it!
        consumable.consume(viewElement, { name: true });
        // ... rest of conversion
    });
});

// ✅ GOOD: Test first, then consume - prevents race conditions
conversion.for('upcast').add(dispatcher => {
    dispatcher.on('element:a', (evt, data, conversionApi) => {
        const { consumable, writer } = conversionApi;
        const viewElement = data.viewItem;

        // Test if element is available for conversion
        if (!consumable.test(viewElement, { name: true })) {
            return; // Another converter already handled this
        }

        // Now safe to consume
        consumable.consume(viewElement, { name: true });
        // ... rest of conversion
    });
});
```

### Why test() Matters

1. **Prevents silent failures**: `consume()` returns false if already consumed, but you might not check
2. **Enables proper converter chaining**: Multiple converters can cooperate without conflicts
3. **Avoids duplicate elements**: GHS and other catch-all converters won't process consumed elements
4. **Race condition prevention**: Between `test()` and `consume()`, another converter could consume attributes (but not name)

### Real-World Bug (Issue #565)

```javascript
// Bug: Early return without consuming caused GHS to create duplicate <a>
if (!imgElement) {
    return null; // <a> was NOT consumed - GHS preserves it!
}

// Fix: Always consume the element before returning
if (!consumable.test(viewElement, { name: true }) ||
    !consumable.test(imgElement, { name: true })) {
    return null;
}
consumable.consume(viewElement, { name: true });
consumable.consume(imgElement, { name: true });
```

### Testing for Pre-Consumed Elements

Always test that your converter correctly handles pre-consumed elements:

```javascript
it('returns null when anchor is pre-consumed', () => {
    const { anchor, img } = createLinkedImageView('https://example.com', {});

    // Simulate another converter consuming the element first
    conversionApi.consumable.consume(anchor, { name: true });

    const result = linkedImageUpcastConverter(anchor, conversionApi);

    expect(result).toBeNull();
});
```

## Native DOM Patterns for CKEditor Plugin Dialogs

CKEditor 5 plugins that open TYPO3 backend dialogs (e.g., image manipulation, link browser) must use native DOM -- never jQuery. TYPO3's `rte_ckeditor` sysext already has zero jQuery, and backend JS can drop jQuery without deprecation notice.

### Dialog Element Access

```javascript
// jQuery (old)
const $dialog = dialog.$el;
$dialog.find('.my-class');

// Native DOM (new)
const dialogEl = dialog.el; // HTMLElement, not jQuery object
dialogEl.querySelector('.my-class');
```

### DOM Builder Helper Pattern

Replace jQuery DOM construction with a small helper:

```javascript
/**
 * Create an element, set className, optionally append to parent.
 */
function h(tag, className, parent) {
    const el = document.createElement(tag);
    if (className) el.className = className;
    if (parent) parent.appendChild(el);
    return el;
}

// Usage
const wrapper = h('div', 'image-manipulation');
const row     = h('div', 'row', wrapper);
const label   = h('label', 'form-label', row);
label.textContent = 'Width';
```

**Security:** Never use `insertAdjacentHTML` with interpolated values -- this triggers CodeQL `js/xss-through-dom` alerts. Always use `createElement` + `textContent` for user-visible strings.

### Promise Instead of $.Deferred

```javascript
// jQuery (old)
const deferred = $.Deferred();
// ... later
deferred.resolve(result);
return deferred.promise();

// Native (new) -- extract resolve/reject for later use
let resolveFn, rejectFn;
const promise = new Promise((resolve, reject) => {
    resolveFn = resolve;
    rejectFn  = reject;
});

// ... later, in a callback or async operation:
if (operationSuccessful) {
    resolveFn(result);
} else {
    rejectFn(error);
}

return promise;
```

### fetch() Instead of $.getJSON

```javascript
// jQuery (old)
$.getJSON(url).done(data => { ... }).fail(err => { ... });

// Native (new)
try {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
    }
    const data = await response.json();
    // ... do something with data
} catch (error) {
    // ... handle network errors and other issues
}
```

### Event Listeners

```javascript
// jQuery (old)
$element.on('click', handler);
$element.off('click', handler);

// Native (new)
element.addEventListener('click', handler);
element.removeEventListener('click', handler);
```

### Cross-Iframe DOM Access

CKEditor image plugins often interact with iframes (e.g., image manipulation previews):

```javascript
// jQuery (old)
const $iframe = dialog.$el.find('iframe');
const $img = $iframe.contents().find('img');
$img.data('crop-data');

// Native (new)
const iframe = dialogEl.querySelector('iframe');
const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
const img = iframeDoc.querySelector('img');
img.dataset.cropData; // .data('crop-data') → dataset.cropData (camelCase)
```

**Note:** jQuery `.data('foo-bar')` maps to `dataset.fooBar` -- jQuery auto-converts kebab-case to camelCase via the `dataset` API.

### Mousewheel Event

```javascript
// jQuery (old)
$element.on('mousewheel', function(e) {
    e.preventDefault();
    const delta = e.originalEvent.wheelDelta;
    zoom += delta > 0 ? 0.1 : -0.1;
});

// Native (new) -- 'wheel' event with inverted deltaY
element.addEventListener('wheel', (e) => {
    e.preventDefault();
    // deltaY is POSITIVE for scroll-down (opposite of old wheelDelta)
    zoom += e.deltaY < 0 ? 0.1 : -0.1;
}, { passive: false }); // passive: false required to allow preventDefault()
```

## Best Practices

1. **Separate Concerns**: Keep editing (schema, converters) and UI separate
2. **Use Commands**: All model changes should go through commands
3. **Proper Cleanup**: Implement `destroy()` methods
4. **Accessibility**: Add proper labels and keyboard navigation
5. **Performance**: Use efficient converters, avoid unnecessary re-renders
6. **Testing**: Write unit tests for commands and converters
7. **Documentation**: Document public API and configuration options
8. **Consumable API**: Always `test()` before `consume()` in upcast converters
9. **No jQuery**: Use native DOM APIs exclusively -- see "Native DOM Patterns" above
