({
    spinnerEventHandler: function (component, event, helper) {
        if (!component.get('v.isGlobalSpinner')) {
            return;
        }
        helper.setSpinner(component, event.getParam('value'), event.getParam('text'));
    },

    show: function (component, event, helper) {
        helper.setSpinner(component, true, event.getParam('arguments').text);
    },

    hide: function (component, event, helper) {
        helper.setSpinner(component, false);
    }
})