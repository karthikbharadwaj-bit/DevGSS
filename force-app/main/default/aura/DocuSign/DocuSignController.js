({
    onScriptsLoaded: function (component, event, helper) {
        helper.createApp(component);
        helper.getDataOnInit(component);
    },

    validate: function (component, event, helper) {
        return helper.validateBeforeStart(component);
    },

    show: function (component, event, helper) {
        component.find('modal').setModal({
            layout: 'fullscreen'
        });
        component.find('modal').show();
    }
});