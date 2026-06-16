({
    refreshQuote: function(component, event, helper) {
        helper.getWizardData(component, {
            quotesLevel: true
        });
        QW.refreshQuote(component);
    },
    changeQuote: function(component, event, helper) {
        var quoteId = event.getParam("quoteId");
        helper.changeQuote(component, quoteId);
    },
    newQuote: function(component, event, helper) {
        helper.getEmptyQuote(component);
    },
    removeQuote: function(component, event, helper) {
        var quoteId = event.getParam('quoteId');
        helper.removeQuote(component, quoteId);
    },
    updateMonthlyContract: function(component, event) {
        var monthlyContractDiscount = event.getParam("monthlyContractDiscount");
        component.set("v.monthlyContractDiscount", monthlyContractDiscount);
    },
    changeRenewalTerm: function(component, event, helper) {
        helper.validateRenewalTerm(component);
    },
})