({
    toggleSelectDocument: function (component, event) {
        let app = component.get('v.app');

        app.toggleSelectDocument(event.getParams().params.index);

        component.set('v.app', app);
    },

    refreshDocuments: function (component, event, helper) {
        helper.refreshDocuments(component);
    },

    refreshRecipients: function (component, event, helper) {
        helper.refreshRecipients(component);
    }
});