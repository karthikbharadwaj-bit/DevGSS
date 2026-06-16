({
    transmitToItem: function (component) {
        const params = {
            action: 'UpdateSelection',
            data: {
                id: component.getGlobalId(),
                itemId: component.get('v.itemId'),
                item: component.get('v.item'),
                value: component.get('v.item').checked,
            }
        };

        $A.get("e.c:OptionsPanelEvent").setParams(params).fire();
    },
    transmit: function (component) {
        const params = {
            action: 'UpdateSelection',
            data: {
                id: component.get('v.itemId'),
                panelId: component.get('v.panelId'),
                item: component.get('v.item'),
                value: component.get('v.item').checked,
            }
        };

        $A.get("e.c:OptionsPanelEvent").setParams(params).fire();
    },
    transmitToPanel: function (component) {
        const params = {
            action: 'change',
            data: {
                id: component.get('v.itemId'),
                panelId: component.get('v.panelId'),
                item: component.get('v.item'),
                value: component.get('v.item').checked,
            }
        };

        $A.get("e.c:OptionsPanelEvent").setParams(params).fire();
    },
    checkAdditionalOptions: function (component) {
        const item = component.get('v.item');
        item.error = null;

        if (!item.show) {
            return;
        }

        if (item.required && item.type === 'text') {
            if (!item.value || (item.stringLength && item.stringLength > item.value.length)) {
                item.error = 'Minimum ' + item.stringLength + ' characters required';
            }
        }
        if (item.required && item.type === 'picklist' && (!item.value || item.value === 'false')) {
            item.error = 'Please select an option';
        }

        component.set('v.item', item);
    },
});