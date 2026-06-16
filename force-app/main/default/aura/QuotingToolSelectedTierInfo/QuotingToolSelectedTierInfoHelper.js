({
    /**
     * Load quote(Sales Agreement) according to supplied quote Id
     */
    changeQuote: function(component, quoteId) {
        let Wizard = component.get('v.Wizard');
        let Tabs = component.get('v.Tabs');

        Wizard.setCurrentQuote(quoteId);
        Wizard.update();
        Tabs.open(Tabs.cart);

        component.set("v.selectedPriceBookEntry", null);

        // refresh product list
        $A.get("e.c:QuotingToolUpdateProductListEvent").fire();

        // refresh cart
        $A.get("e.c:QuotingToolRefreshCartEvent").fire();

        component.set('v.quote', Wizard.currentQuote.record);
        component.set('v.Tabs', Tabs);
        component.set('v.Wizard', Wizard);
    },
    /**
     * Load empty quote
     */
    getEmptyQuote: function(component) {
        var oldQuote = component.get("v.quote");
        if(!oldQuote) return;

        if (oldQuote.Upsell_Status__c == "Upsell" || oldQuote.Upsell_Status__c === "Upgrade") {

            QW.spinner.show('Updating Entitlements');
            RC.salesforce.request(component, 'c.getEntitlementsSync', {
                    accId: oldQuote.AccountId
                })
                .catch($A.getCallback(error => {
                    console.warn(RC.salesforce.getResponseError(error));
                    $A.get("e.c:ToastEvent").setParams({
                        theme: "warning",
                        header: "Error during sync from Data Warehouse. Using Existing Entitlements.",
                        defaultTimeout: false
                    }).fire();
                }))
                .then($A.getCallback(() => {
                    QW.spinner.hide();
                }));
        }

        component.set("v.selectedTier", null);
        component.set("v.quote", null);
        component.set("v.selectedTier", null);
        component.set("v.selectedPriceBookEntry", null);
        component.set("v.activePriceBookEntry", null);
        component.set('v.addingToCartProds',new Set());
        // Empty pipeline cart counter
        $A.get("e.c:QuotingToolUpdateCartEvent").fire();
    },
    /**
     * Delete quote
     */
    removeQuote: function(component, quoteId) {
        QW.spinner.show('Deleting Quote');

        QW.salesforce.request(component, 'c.deleteQuote', { params: { quoteId: quoteId } })
            .then($A.getCallback(function() {
                $A.get("e.c:QuotingToolQuoteDeletedEvent").fire();
            }))
            .catch($A.getCallback(function(error) {
                $A.get("e.c:ToastEvent").setParams({
                    theme: "error",
                    header: "Quote deletion failed",
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function() {
                QW.spinner.hide();
            }));

    }
});