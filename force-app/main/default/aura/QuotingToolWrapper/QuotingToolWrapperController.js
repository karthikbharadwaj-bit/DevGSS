/* globals QW, console */
({
    doInit: function(component, event, helper) {
        // var displayMode = component.get('v.displayMode');
            // displayMode && component.set('v.config.displayMode', displayMode);

        helper.showSpinner('Waiting for scripts to load');
        component.set('v.addingToCartProds',new Set());
    },

    /**
     * @deprecated
     * Use c:Modal (e.ModalRequestEvent) instead
     */
    showModal: function(component, event) {
        var sourceId = event.getParam("sourceId");
        if (sourceId != null) {
            var action = event.getParam("action");
            var params = event.getParam('params');
            component.set("v.modalSource", sourceId);
            component.set("v.modalAction", action);
            var msg = '';
            if (action === "SelectTier") {
                msg = "Changing Service Plan will empty the Cart. Do you want to continue?"
                component.set("v.modalText", msg);
            }
            if (action === "ApprovedQuoteUpdate") {
                msg = "This change may require new approval. Do you want to continue?"
                component.set("v.modalText", msg);
            }
            if (action === "DropLineItemsErrors") {
                msg = "Products with invalid data won't be saved. Are you sure you want to leave the Cart?"
                component.set("v.modalText", msg);
            }
            if (action === "SaveCartChanges") {
                msg = "You have unsaved items in the Cart. Do you want to save them?"
                component.set("v.modalText", msg);
            }
            if (action === "SaveQuoteChanges") {
                msg = "You have unsaved changes in the Quote. Do you want to save them?"
                component.set("v.modalText", msg);
            }
            if (action === "SwitchTierUpgradeAndSignUp") {
                component.set('v.modalParams', params);
                var tierName = params.tier.Pricebook2.Name;
                msg = "New number of DigitalLines doesn't fit the Line Range of the current Service Plan. Do you want to switch to <b>" + tierName + "</b> which has an appropriate Line Range? Your Cart will be emptied."
                component.set("v.modalText", msg);
            }
            if (action === "SwitchTierUpsell") {
                component.set('v.modalParams', params);
                var tierName = params.tier.Pricebook2.Name;
                msg = "New number of DigitalLines doesn't fit the Line Range of the current Service Plan. Do you want to upgrade to <b>" + tierName + "</b> which has an appropriate Line Range? Your Cart will be emptied and client will lose all his current discounts."
                component.set("v.modalText", msg);
            }
            if (action === "syncProServUnavailable") {
                component.set('v.modalParams', params);

                // Products list
                var unavailableProductsHtml = '<table class="slds-table slds-table--bordered slds-no-row-hover slds-m-bottom--small">';
                unavailableProductsHtml += '<tr class="slds-text-heading--label"><th>Product Name</th><th>Plan</th></tr>';
                params.unavailableProducts.forEach(function(qli, index){
                    unavailableProductsHtml += '<tr><td>'+qli.Product2.Name+'</td><td>'+qli.Product2.Charge_Term__c+'</td></tr>';
                });
                unavailableProductsHtml += '</table>';
                var verb = 'is';
                if (params.unavailableProducts.length > 1) {
                    verb = 'are';
                }

                // Quote Creator
                var pqUser = 'Primary Quote Creator';
                var pqUserHtml = '';
                if (params.pqUser){
                    pqUserHtml = '<a href="/'+params.pqUser.Id+'" target="_blank">'+params.pqUser.Name+'</a>';
                }

                // Service Plan Name
                var pqPricebook2NameHtml = '<b class="slds-truncate">"'+params.pqPricebook2Name+'"</b> ';

                msg = unavailableProductsHtml + ' '+ verb +' not available in the Service Plan which is selected on the Primary Sales Quote. Please contact '+pqUserHtml+' if you have any questions. Do you want to sync products that are available in '+ pqPricebook2NameHtml +'Service Plan to Primary Quote?"';
                component.set("v.modalText", msg);
            }
            if (action === "SaveSeatWithZeroQuantity") {
                component.set('v.modalParams', params);
                component.set("v.modalText", params.message);
            }
            if (action === "SwitchServicePlan") {
                msg = "Changing Service Plan will empty the Cart. Do you want to continue?";
                component.set("v.modalText", msg);
                component.set('v.modalParams', params);
            }
            // Final steps
            $A.util.addClass(component.find('modalBg'), 'slds-backdrop--open');
            $A.util.addClass(component.find('modal'), 'slds-fade-in-open');
            $A.util.removeClass(component.find('modal'), 'slds-hide');
        }
    },
    acceptModal: function(component, event, helper) {
        helper.hideModal(component, true);
    },
    denyModal: function(component, event, helper) {
        helper.hideModal(component, false);
    },
    /**
     * Update Opportunity Sales Aagreement Contract Days and choose service plan (B-355)
     */
    updateOpportunity: function(component, event, helper) {
        var quote = event.getParam("quote");
        var contractDays = component.get("v.contractDays");
        var paymentPlan = component.get("v.paymentPlan");
        if (quote && quote.Upsell_Status__c === "Upsell" && quote.Status === "Active" && quote.QuoteType__c === "Agreement" &&
            (paymentPlan === "Monthly" || paymentPlan === "Monthly-Contract" || paymentPlan === "Monthly - Contract")) {
            var oneDay = 24 * 60 * 60 * 1000; // hours*miinutes*seconds*milliseconds
            var stDate = new Date(quote.Start_Date__c);
            var endDate = new Date(quote.End_Date__c);
            var newContractDays = Math.abs((stDate.getTime() - endDate.getTime()) / oneDay);
            var newPaymentPlan = "Monthly";
            if (newContractDays && newContractDays > 363) {
                newPaymentPlan = "Monthly - Contract";
            }
            component.set("v.paymentPlan", newPaymentPlan);
            component.set("v.contractDays", newContractDays);
            $A.get("e.c:QuotingToolOpportunityInitEvent").setParams({
                paymentPlan: newPaymentPlan,
                contractDays: newContractDays
            }).fire();
        }
    },
    quoteChanged: function(component, event, helper){
        helper.setUpsellStatus(component);
        helper.setQuoteRecordTypeName(component);
        helper.setQuoteSpecialTerms(component);
        helper.quoteState(component);
    },
    stateChanged: function(component, event, helper){

    },
    productsChanged: function(component, event, helper){
        helper.quoteState(component);
    },
    cartItemsChanged: function(component, event, helper){
        helper.quoteState(component);
    },
    userChanged: function(component, event, helper){
        helper.quoteState(component);
    },
    upgradeClicked: function(component, event, helper){
        component.set('v.isUpgradeClicked', event.getParam("upgrade"));
    },
    isUpgradeClickedChanged: function(component, event, helper){
        helper.setUpsellStatus(component);
    },
    /**
     * Quotes (in selector) changed
     */
    quotesChanged: function(component, event, helper){
        helper.getProServQuote(component);
        helper.quoteState(component);
        helper.checkAvailability(component);
    },

    /**
     * User switches to another quote
     */
    getQuote: function(component){
        component.set('v.isUpgradeClicked', false);
    },
    /**
     * User Clicked New Quote Button
     */
    newQuote: function(component, event, helper){
        let Wizard = component.get('v.Wizard');
        let Tabs = component.get('v.Tabs');

        Wizard.currentQuote = null;
        Tabs.open(Tabs.servicePlans);
        component.set('v.isUpgradeClicked', false);

        component.set('v.Tabs', Tabs);
        component.set('v.Wizard', Wizard);

        if(component.get('v.Wizard.settings.featureToggle.Opportunity_Creation_Entitlement_Based__c'))
            helper.syncAndUpdateEntitlements(component)
                .then($A.getCallback(QW.spinner.hide));
    },
    addingToCartProdsChanged: function(component, event, helper){
        helper.quoteState(component);
    },
    /**
     * v.upsellStatus attribute changed
     */
    upsellStatusChanged: function(component, event, helper){
        helper.quoteState(component);
    },

    /**
     * v.wizard attribute changed
     */
    wizardChanged: function(component, event, helper){
        helper.pricingChanges(component);
        helper.servicePlanDeactivated(component);
        helper.quoteIsInvalid(component);
        helper.checkCriticalNotifications(component);
        helper.updateTabs(component);
    },

    qwHelperLoaded: function (component, event, helper) {
        QW.spinner.show('Initializing');

        helper.createTabs(component);

        var user = component.get("v.user");
        var opId = component.get("v.opportunityId");
        var cCode = component.get("v.currencyIsoCode");
        var sPlan = component.get("v.servicePlan");
        var rcTier = component.get("v.rcTier");
        var rcUserId = component.get("v.rcUserId");
        var paymentPlan = component.get("v.paymentPlan");
        var numberDLs = component.get("v.numberDLs");
        var contractDays = component.get("v.contractDays");
        var recordTypeName = component.get("v.recordTypeName");
        var stageName = component.get("v.stageName");
        var effectiveNoOfEmployeesRange = component.get("v.effectiveNoOfEmployeesRange");
        var tiers = component.get("v.tiers");
        var defaultUpsellStatus = component.get('v.defaultUpsellStatus');

        var Wizard = new QW.Wizard(
            component.get('v.config'),
            component.get('v.settings'),
            component.get('v.isProserv'),
            component.get('v.isCC')
        );

        Wizard.setUser( component.get('v.user') );
        Wizard.setOpportunity( component.get('v.currentOpportunity') );

        component.set('v.Wizard', Wizard);

        var loadFirst = [
            helper.getWizardData(component, {
                opportunityLevel: true
            })
        ];

        Promise.all(loadFirst)
            .then($A.getCallback(() => {
                let primaryQuote = Wizard.getQuotesFilteredByMode().find(q => q.isPrimary__c);
                if (primaryQuote) {
                    Wizard.setCurrentQuote(primaryQuote.Id);
                }

                $A.get("e.c:QuotingToolOpportunityInitEvent").setParams({
                    opportunityId: opId,
                    currencyIsoCode: cCode,
                    servicePlan: sPlan,
                    rcTier: rcTier,
                    rcUserId: rcUserId,
                    paymentPlan: paymentPlan,
                    numberDLs: numberDLs,
                    contractDays: contractDays,
                    recordTypeName: recordTypeName,
                    stageName: stageName,
                    effectiveNoOfEmployeesRange: effectiveNoOfEmployeesRange,
                    defaultUpsellStatus: defaultUpsellStatus,
                    tiers: tiers
                }).fire();

                // refresh product list
                $A.get("e.c:QuotingToolUpdateProductListEvent").fire();

                $A.get("e.c:QuotingToolPropagateUserEvent").setParams({
                    user: user
                }).fire();
                helper.quoteState(component);
                component.set('v.legalApprovalId', Wizard.opportunity.legalApprovalId);

                return Wizard.currentQuote
                    ? component.find('QuotingToolCartList').refresh()
                    : helper.syncAndUpdateEntitlements(component);
            }))
            .then($A.getCallback(() => {
                var Tabs = component.get('v.Tabs');
                Tabs.open(Wizard.currentQuote
                    ? Tabs.cart
                    : Tabs.servicePlans);

                helper.setUpsellStatus(component);
                helper.setQuoteRecordTypeName(component);

                component.set('v.Tabs', Tabs);
                component.set('v.Wizard', Wizard);

                QW.spinner.hide();
            }))
    },
    /**
     * v.selectedPriceBookEntry changed
     */
    selectedPriceBookEntryChanged: function(component, event, helper){
        helper.quoteState(component);
    },

    /**
     * User interact with Modal window result
     */
    onModalResponseEvent: function(component, event, helper){
        var response = event.getParams();

        switch (response.guid){

            // Save Cart changes before go to another tab
            case 'goFromCart':
                switch (response.buttonName){

                    // Save Cart and go to desired tab
                    case 'save':
                        var saveCartProcess = component.find('QuotingToolCartList').save();
                        if (saveCartProcess){
                            saveCartProcess.then($A.getCallback(function () {
                                helper.navigate(component, helper.targetTabName);
                            }))
                        }
                        break;

                    // Discard Cart and go to desired tab
                    case 'discard':
                        component.find('QuotingToolCartList').discard();
                        helper.navigate(component, helper.targetTabName);
                        break;
                }
                break;

            // Save Phases changes before go to another tab
            case 'goFromPhases':
                switch (response.buttonName){

                    // Save Phases and go to desired tab
                    case 'save':
                        var savePhasesProcess = component.find('QuotingToolPhaseManagement').save();
                        if (savePhasesProcess){
                            savePhasesProcess.then($A.getCallback(function () {
                                helper.navigate(component, helper.targetTabName);
                            }))
                        }
                        break;

                    // Discard Phases and go to desired tab
                    case 'discard':
                        component.find('QuotingToolPhaseManagement').discard();
                        helper.navigate(component, helper.targetTabName);
                        break;
                }
                break;

            // Save Summary changes before go to another tab
            case 'goFromSummary':
                switch (response.buttonName){

                    // Save Phases and go to desired tab
                    case 'save':
                        var saveSummaryProcess = component.find('QuotingToolQuoteSummary').save();
                        if (saveSummaryProcess){
                            saveSummaryProcess.then($A.getCallback(function () {
                                helper.navigate(component, helper.targetTabName);
                            }))
                        }
                        break;

                    // Discard Phases and go to desired tab
                    case 'discard':
                        component.find('QuotingToolQuoteSummary').discard();
                        helper.navigate(component, helper.targetTabName);
                        break;
                }
                break;

            // Delete Phase Line Items before decrease/delete Cart Item
            case 'deletePLIsBeforeCartSave':
                helper.deletePLIsBeforeCartSave(component, response.params.phaseLineItemIdsToDelete);
                break;

            // Delete Phase Line Items and delete Product from cart
            case 'deletePLIsBeforeCartItemDelete':
                helper.deletePLIsBeforeCartItemDelete(component, response.params.phaseLineItemIdsToDelete, response.params.quoteLineItemToDelete);
                break;

            // Delete phases and switch service plan
            case 'switchServicePlan':
                helper.discardPhaseManagement(component);
                helper.switchServicePlan(component, response.params.pricebook2Id);
                break;

            // Delete Phases and delete Quote
            case 'deleteQuote':
                helper.discardPhaseManagement(component);
                helper.deleteQuote(component, response.params.quoteId);
                break;

            case 'cancelQuote':
                helper.cancelChangeOrderQuote(component);
                helper.discardPhaseManagement(component);
                helper.deleteQuote(component, response.params.quoteId);
                break;

        }
    },

    onQuotingToolModalResponseEvent: function(component, event, helper) {
        var result = event.getParam("modalResult");
        var action = event.getParam("action");
        var params = event.getParam("params");
        var Wizard = component.get('v.Wizard');
        var pbe = component.get('v.selectedPriceBookEntry');
        if ( ["SwitchTierUpgradeAndSignUp", "SwitchTierUpsell"].includes(action) && result) {
            if (action === "SwitchTierUpsell") {
                $A.get("e.c:QuotingToolTierUpgradeEvent")
                .setParams({ upgrade: true })
                .fire();
            }
            if (params && params.tier && Number.isInteger(params.lines)) {
                component.find('QuotingToolTierList').saveServicePlanOnQuote(params.tier, params.lines)
                    .then($A.getCallback(()=>{
                        return component.find('QuotingToolCartList').refresh(component)
                    }));
            } else {
                console.error('not enough arguments to change service plan', params);
            }
        }
        if ((action === "SwitchServicePlan") && result) {
            if (params && params.pricebook2Id){

                // Switch Service Plan using pricebook2Id (ProServ)
                component.find('QuotingToolTierList').switchServicePlan(component, params.pricebook2Id);

            } else if (pbe){
                // Switch Service plan using Selected PriceBook Entry (User Manual change)
                var lines = pbe.Pricebook2.Line_Range_Min__c;
                component.find('QuotingToolTierList').saveServicePlanOnQuote(pbe, lines)
                    .then($A.getCallback(()=>{
                        return component.find('QuotingToolCartList').refresh(component)
                    }))
                    .then($A.getCallback(()=>{
                        // Change tab to Products
                        let Tabs = component.get('v.Tabs');
                        Tabs.open(Tabs.products);
                        component.set('v.Tabs', Tabs);
                    }));
            } else {
                console.error('Service Plan to Change is not specified');
            }

        }
    },

    /**
     * v.entitlements attribute changed
     */
    entitlementsChanged: function(component, event, helper){
        if(component.get('v.Wizard.settings.featureToggle.Opportunity_Creation_Entitlement_Based__c'))
            helper.setAccountServicePlan(component);
    },

    onDocuSignEnvelopeListRefresh: function (component, event) {
        let Wizard = component.get('v.Wizard');
        const p = event.getParams().params;
        Wizard.opportunity.setIsHasDocuSignActiveEnvelopes(p.isOpportunityHasActiveEnvelopes);
        Wizard.opportunity.setIsAnyEnvelopeVoidPending(p.isAnyEnvelopeVoidPending);
        Wizard.opportunity.setIsNewEnvelopePending(p.isNewEnvelopePending);
        component.set('v.Wizard', Wizard);
    },

    accountServicePlanEntChanged: function(component, event, helper){
        helper.setUpsellStatus(component);
    }
});