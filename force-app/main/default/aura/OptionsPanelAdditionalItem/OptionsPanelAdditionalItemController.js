({
    init: function (component, event, helper) {
        if (component.get('v.item').condition) {
            component.set('v.item.show', false);
        }

        helper.checkAdditionalOptions(component);
        helper.transmitToItem(component);

        helper.transmitToPanel(component);
    },
    onChange: function (component, event, helper) {
        helper.checkAdditionalOptions(component);
        helper.transmitToItem(component);

        helper.transmitToPanel(component);
    },

    onOptionsPanelEvent: function (component, event, helper) {
        try {
            const eData = event.getParams();

            if (eData.data.itemId !== component.get('v.itemId')) {
                return;
            }

            if (eData.data.id === component.getGlobalId()) {
                return;
            }

            // logic showinf of dependent option
            const item = component.get('v.item');

            if (!item.condition) {
                return;
            }

            if (eData.data.item && eData.data.item.name === item.condition.name
                && eData.data.item.value === item.condition.value) {
                item.show = true;
            } else {
                item.show = false;
                item.value = null;
            }

            component.set('v.item', item);
            helper.checkAdditionalOptions(component);
        } catch (e) {
            console.error(e);
        }
    }
});