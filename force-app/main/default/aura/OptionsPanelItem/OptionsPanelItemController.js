({
    init: function (component, event, helper) {
        component.set('v.itemId', component.getGlobalId());

        const item = component.get('v.item');

        if (item.checked) {
            if (!component.get('v.isShowOptions')) {
                component.set('v.isShowOptions', true);
            }
        }
    },
    showOptions: function (component, event, helper) {
        let isShowOptions = component.get('v.isShowOptions');

        isShowOptions = !isShowOptions;

        component.set('v.isShowOptions', isShowOptions);
    },

    onTextChange: function (component, event, helper) {
        helper.checkInput(component, component.get('v.item'));

        clearTimeout(helper.keyUpTimeout);

        helper.keyUpTimeout = setTimeout($A.getCallback(() => {
            helper.transmit(component);
            helper.transmitToPanel(component);
        }), 300);
    },

    onChange: function (component, event, helper) {
        component.set('v.item.inputText', null);
        component.set('v.item.picklistValue', null);
        component.set('v.error', null);

        helper.transmit(component);
        helper.transmitToPanel(component);

        // Temporary solution because event reaches panelCmp early than all panelItemCmp`s
        helper.transmit(component);
        helper.transmitToPanel(component);
    },

    onChangePicklist: function (component, event, helper) {
        helper.transmit(component);
        helper.transmitToPanel(component);
    },

    onOptionsPanelEvent: function (component, event, helper) {
        const eData = event.getParams();

        if (eData.data.panelId !== component.get('v.panelId')) return;

        if (eData.action === 'Check' && component.get('v.item').checked) {
            helper.checkInput(component, component.get('v.item'));
        }

        if (eData.action === 'UpdateSelection') {
            const id = eData.data.id;
            const parent = eData.data.item.parent;
            const value = eData.data.value;
            const currentId = component.get('v.itemId');
            const item = component.get('v.item');
            const multiple = component.get('v.multiple');

            // Multiple selection
            if (multiple && multiple !== 'false') {
                if (item.options && item.options.length) {
                    let result = false;
                    for (let i = 0; i < item.options.length; i++) {
                        if (item.options[i].checked) {
                            result = true;
                        }
                    }
                    component.set('v.item.checked', result);
                }
            }
            // Single selection
            else {
                if (currentId !== id) {
                    component.set('v.item.checked', false);
                }
                if (item.name === parent) {
                    component.set('v.item.checked', value);
                } else if (item.options && item.options.length) {
                    item.checked = false;

                    for (let i = 0; i < item.options.length; i++) {
                        item.options[i].checked = false;
                    }

                    component.set('v.item', item);
                }
            }

            // If item is unselected then all value of additional options should be null
            if (!item.checked && item.additionalOptions) {
                _.forEach(item.additionalOptions, (aOption) => {
                    aOption.value = null;
                })
            }
        }
    },
});