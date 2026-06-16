({
    /**
     * Load phases from SF and rebuild UI
     */
    getPhasesAndDiscard: function(component){
        Promise.all([
                component.find('phaseManagement').reloadPhases(),
                component.find('phaseManagement').reloadChangeOrderPhases(),
                component.find('phaseManagement').loadUserAccessInfo()
            ])
            .then($A.getCallback(function(){
                component.find('phaseManagement').discard();
            }));
    },

    /**
     * Load New Change Order Flow Feature Toggle
     */
    getIsNewChangeOrder: function(component) {
        return PM.salesforce.request(component, 'c.getIsNewChangeOrder', null, $A)
            .then($A.getCallback(function (isNewChangeOrderFlow) {
                component.set('v.isNewChangeOrder', isNewChangeOrderFlow);
            }))
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get feature toggle',
                    details: PM.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }));
    },

    /**
     * Show/Hide Phase Management tab content
     */
    restartAppOnTabOpen: function(component){
        let isTabOpen = component.get('v.Tabs.phases.isOpen');
        let isAppRunning = component.get('v.isAppRunning');

        if (!isAppRunning && isTabOpen) {
            component.find('phaseManagement').startApp();
            component.find('phaseManagement').discard();

        } else {
            component.find('phaseManagement').stopApp();

        }

        component.set('v.isAppRunning', isTabOpen);
    },
    prepareCartItems: function(component){
        var cartItems = component.get('v.cartItems');
        var Wizard = component.get('v.Wizard');

        if (!Wizard || !Wizard.currentQuote)
            return;
        var cartItemsCopy = JSON.parse(JSON.stringify(cartItems));

        var cartItemsForPhases = cartItemsCopy;

        if (Wizard.opportunity.isChangeOrderOpportunity){
            cartItemsForPhases = cartItemsCopy.map(function(qli){
                var cartItem = Wizard.currentQuote.getCartItem(qli.Id);

                var deliveredQuantity = 0;
                if (cartItem && cartItem.asset)
                    deliveredQuantity = cartItem.asset.record.Delivered_Quantity__c;

                qli.Quantity = qli.NewQuantity__c - deliveredQuantity;

                return qli;
            });
        }

        component.set('v.cartItemsForPhases',cartItemsForPhases);
    },
    changeProServStatus: function(component){
        var Wizard = component.get('v.Wizard');
        QW.spinner.show('Changing ProServ Status to "In progress"');
        QW.salesforce.request(component, 'c.updateQuote', {
                updatedQuote: {
                    sobjectType: 'Quote',
                    Id: Wizard.currentQuote.record.Id,
                    ProServ_Status__c: QW.CONSTANTS.QUOTE.PROSERV_STATUS.IN_PROGRESS
                }
            }, $A)
            .catch($A.getCallback(function(error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to update ProServ Status',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function () {
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                QW.spinner.hide();
            }));
    },
    setPhaseManagementPermissions: function(component){
        var Wizard = component.get('v.Wizard');
        var phaseManagement = component.find('phaseManagement');

        phaseManagement.set('v.isUnassignedAllowed', !Wizard.opportunity.isClosed
                                                  && !Wizard.opportunity.isPendingConfirmAndClose);

        phaseManagement.set('v.isAddPhasesAllowed', !Wizard.opportunity.isClosed
                                                 && !Wizard.opportunity.isPendingConfirmAndClose);

        phaseManagement.set('v.isCompletePhaseAllowed', Wizard.settings.userPermissions.CompletePhases);
        phaseManagement.set('v.isMoveSitesAllowed', Wizard.settings.userPermissions.MoveSites);
        phaseManagement.set('v.isMoveProductsAllowed', Wizard.settings.userPermissions.MoveProducts);
        phaseManagement.set('v.isLocationsEnabled', Wizard.settings.userPermissions.EditLocations);
        phaseManagement.set('v.isEditAllowed', !Wizard.currentQuote.isCancelled
                                            && !Wizard.currentQuote.isSoldOrOutForSignature);
        phaseManagement.set('v.isCartItemsEditAllowed', Wizard.opportunity.isClosed
                                                    && !Wizard.opportunity.isPendingConfirmAndClose);
    }
});