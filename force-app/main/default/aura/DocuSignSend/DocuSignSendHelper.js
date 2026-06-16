({
    refreshDocuments: function (component) {
        component.set('v.isDocumentsLoading', true);
        let app = component.get('v.app');
        return RC.salesforce.request(component, 'c.getAttachments', {
                opportunityId: app.opportunityId
            })
            .then($A.getCallback(result => {
                app.setDocuments(result.data.attachmentList);
                component.set('v.app', app);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError(error)))
            .then($A.getCallback(() => component.set('v.isDocumentsLoading', false)));
    },

    refreshRecipients: function (component) {
        component.set('v.isRecipientsLoading', true);
        let app = component.get('v.app');
        return RC.salesforce.request(component, 'c.getRecipients', {
            opportunityId: app.opportunityId
        })
            .then($A.getCallback(result => {
                app.setRecipients(result.data.recipientList);
                component.set('v.app', app);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError(error)))
            .then($A.getCallback(() => component.set('v.isRecipientsLoading', false)));
    }
})