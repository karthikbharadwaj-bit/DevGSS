({
    refreshEnvelopes: function (component) {
        component.set('v.isEnvelopesLoading', true);
        let app = component.get('v.app');
        return RC.salesforce.request(component, 'c.getEnvelopes', {
                opportunityId: app.opportunityId,
                quoteId: component.get('v.primaryQuoteId')
            })
            .then($A.getCallback(result => {
                app.setEnvelopes(result.data.envelopeList);
                component.set('v.app', app);
                component.getEvent('docuSignEnvelopeListRefresh').setParams({
                    params: {
                        isOpportunityHasActiveEnvelopes: result.data.isOpportunityHasActiveEnvelopes,
                        isAnyEnvelopeVoidPending: app.isAnyEnvelopeVoidPending,
                        isNewEnvelopePending: app.isNewEnvelopePending
                    }
                }).fire();
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError(error)))
            .then($A.getCallback(() => component.set('v.isEnvelopesLoading', false)));
    }
})