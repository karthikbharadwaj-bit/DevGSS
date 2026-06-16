({
    getWizardData: function (component, userOptions) {
        let Wizard = component.get('v.Wizard');
        let defaultOptions = {
            setWizard: true,

            accountId: Wizard.opportunity.record.AccountId,
            opportunityId: Wizard.opportunity.record.Id,

            opportunityLevel: false,
            quotesLevel: false
        };
        const options = Object.assign(defaultOptions, userOptions);

        Wizard.isGettingQuotes = true;
        return RC.salesforce.request(component, 'c.getWizardDataWrapper', {options: JSON.stringify(options)})
            .then($A.getCallback((result) => {
                if (options.opportunityLevel) {
                    Wizard.setAssets(result.data.assets);
                }

                if (options.opportunityLevel) {
                    Wizard.opportunity.setIsHasDocuSignActiveEnvelopes(result.data.isOpportunityHasActiveEnvelopes);
                }

                if (options.opportunityLevel || options.quotesLevel) {
                    Wizard.setQuotes(result.data.quotes);
                    _.forEach(Wizard.quotes, (quote) => {
                        quote.setSpecialTermsValues(result.data.specialTerms[quote.record.Upsell_Status__c]);
                    });
                }
                if  (options.opportunityLevel) {
                    Wizard.setOpportunityRecord(result.data.opportunity);
                    Wizard.setBillingPackage(result.data.billingPackage);
                }

                Wizard.update();

                Wizard.isGettingQuotes = false;
                if (options.setWizard){
                    component.set('v.Wizard', Wizard);
                }
            }))
    }
});