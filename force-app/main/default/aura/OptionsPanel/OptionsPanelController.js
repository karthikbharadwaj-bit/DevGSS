({
    init: function (component, event, helper) {
        component.set('v.panelId', component.getGlobalId());

        helper.setParams(component);
        helper.isComplete(component);
    },

    onOptionsPanelEvent: function (component, event, helper) {
        const eData = event.getParams();

        if (eData.data.panelId !== component.get('v.panelId')) {
            return;
        }

        if (eData.action !== 'change') {
            return;
        }

        const params = helper.setParams(component);

        component.set('v.params', params);

        helper.isComplete(component);

        $A.get("e.c:OptionsPanelEvent").setParams({
            action: 'change',
            data: params,
        }).fire();
    },
});