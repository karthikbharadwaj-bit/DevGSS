({
    afterScriptsLoaded : function (component, event, helper) {
        helper.initApp(component);
        helper.initPage(component)
            .catch($A.getCallback((error) => {
                const app = component.get('v.app');

                app.isReadOnly = true;
                app.updateView();

                component.set('v.view', app.view);

                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Fatal Error',
                    details: error.message,
                    defaultTimeout: false,
                }).fire();
            }));
    },

    saveRangeItem: function (component, event, helper) {
        helper.saveRangeItem(component);
    },

    removeRangeItem: function(component, event, helper) {
        helper.removeRangeItem(component);
    },

    changeNewChartValue: function(component, event, helper) {
        helper.changeNewChartValues(component);
    },

    updateValue: function(component, event, helper) {
        helper.updateValues(component);
    },

    changeValue: function(component, event, helper) {
        helper.changeValues(component);
    },

    changeEngageLegalValue: function(component, event, helper) {
        helper.changeEngageLegalValue(component);
    },

    changeServiceType: function(component, event, helper) {
        helper.changeServiceType(component);
    },

    cancel: function (component, event, helper) {
        helper.cancel(component);
    },

    submit: function (component, event, helper) {
        return helper.saveSLA(component);
    }
});