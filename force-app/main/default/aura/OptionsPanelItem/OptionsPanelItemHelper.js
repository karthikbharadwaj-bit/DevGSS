({
    checkInput: function (component, item) {
        component.set('v.error', hasErrors(component));
        component.set("v.item.error", hasErrors(component));
    },
    hasErrors: function (component) {
        const item = component.get("v.item");

        component.set("v.item", item);

        if (item.checked) {
            if (item.error) {
                return item.error;
            }
            _.forEach(item.additionalOptions, (aOption) => {
                if (aOption.error) {
                    return aOption.error;
                }
            });
        }
        return null;
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
});