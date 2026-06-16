({
    init: function(component, event, helper) {
        var config = component.get('v.config');
        component.set('v.isSandbox', (config.salesforce.origin !== 'https://rc.my.salesforce.com'));
    },

    openNewTab: function(component) {
        window.open(`/apex/QuoteWizard?id=${config.salesforce.opportunityId}`, '_blank');
    }
})