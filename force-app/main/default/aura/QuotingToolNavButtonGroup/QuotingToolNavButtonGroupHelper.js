({
    getTaxes: function () {
        $A.get("e.c:QuotingToolGetTaxesEvent").setParams({action: "getTaxes"}).fire();
    },

    removeTaxes: function () {
        $A.get("e.c:QuotingToolGetTaxesEvent").setParams({action: "removeTaxes"}).fire();
    },

    checkButtons: function (component) {
        var Wizard = component.get('v.Wizard');
        var quote = component.get('v.quote');
        var state = component.get('v.state');
        var upsellStatus = component.get('v.upsellStatus');
        var isPhasesChanged = component.get('v.isPhasesChanged');
        var isCartChanged = component.get('v.isCartChanged');
        const isCC = component.get('v.isCC');

        var upgradeButtonHidden = true;
        var cancelUpgradeButtonHidden = true;
        let discardCartButtonHidden = false;
        if (upsellStatus === 'Upsell') {
            upgradeButtonHidden = false;
            cancelUpgradeButtonHidden = true;
        } else if (upsellStatus === 'Upgrade' && (!quote || (quote && quote.Upsell_Status__c === 'Upsell'))) {
            upgradeButtonHidden = true;
            cancelUpgradeButtonHidden = false;
        }
        // CC Quote condition
        if (isCC) {
            upgradeButtonHidden = true;
            cancelUpgradeButtonHidden = true;
            discardCartButtonHidden = true;
        }

        component.set("v.getTaxesButton.disabled", state.isTaxesInCart
            || Wizard.currentQuote && Wizard.currentQuote.isInvalid);
        component.set("v.removeTaxesButton.disabled", !state.isTaxesInCart
            || Wizard.currentQuote && Wizard.currentQuote.isInvalid);

        RC.cssUtils.toggleShow(component, 'getTaxesButton', !state.isTaxesInCart);
        RC.cssUtils.toggleShow(component, 'removeTaxesButton', state.isTaxesInCart);
        RC.cssUtils.toggleShow(component, 'tierUpgradeButton', !upgradeButtonHidden);
        RC.cssUtils.toggleShow(component, 'cancelUpgradeButton', !cancelUpgradeButtonHidden);
        RC.cssUtils.toggleShow(component, 'discardCartButton', !discardCartButtonHidden);

        // Save Service Plan buttons
        component.find('saveServicePlanButton').set('v.disabled', !state.isUserSelectedDifferentServicePlan);
        component.find('discardServicePlanButton').set('v.disabled', !state.isUserSelectedDifferentServicePlan);

        // Phase Buttons
        component.find('savePhasesButton').set('v.disabled', !isPhasesChanged);
        component.find('discardPhasesButton').set('v.disabled', !isPhasesChanged);

        // Cart Buttons
        component.find('saveCartButton').set('v.disabled', !isCartChanged);
        component.find('discardCartButton').set('v.disabled', !isCartChanged);
    },

    buttonsVisibility: function (component) {
        var Tabs = component.get("v.Tabs");
        var state = component.get('v.state');
        var quote = component.get('v.quote');
        var settings = component.get('v.settings');
        var Wizard = component.get('v.Wizard');
        const isCC = component.get('v.isCC');

        var saveButtonHidden = true;
        var saveCartButtonHidden = true;
        var discardCartButtonHidden = true;
        var isGeneratePDFShown = false;
        var discardQuoteButtonHidden = true;
        var tierUpgradeButtonHidden = true;
        var cancelUpgradeButtonHidden = true;
        var getTaxesButtonHidden = true;
        var removeTaxesButtonHidden = true;
        var saveServicePlanButtonHidden = true;
        var discardServicePlanButtonHidden = true;
        var isSavePhasesButtonShown = false;
        var isDiscardPhasesButtonShown = false;

        if (Tabs.servicePlans.isOpen) {
            if (
                // Show Only on sales quotes
            // (not yet created quotes supposed to be sales by default)
            (state.isSalesQuote || !quote)
            // Check if user have permissions
            && (
                // Permission checks for Already created quotes
                (quote && state.isUserHavePermissionToEditQuote)
                // Permission checks for not yet created quotes
                || (!quote && settings.userPermissions.EditSalesQuote)
            )
            // Quote should not be read only
            && !Wizard.opportunity.isClosed
            && !state.isActiveAgreement
            && !state.isEngagementCancelled
            && (!Wizard.currentQuote || !Wizard.currentQuote.isInvalid)
            && !Wizard.opportunity.isPendingConfirmAndClose) {

                tierUpgradeButtonHidden = false;
                cancelUpgradeButtonHidden = false;
                saveServicePlanButtonHidden = false;
                discardServicePlanButtonHidden = isCC || false;

            }

        } else if (Tabs.cart.isOpen) {
            // Cart
            if (state.isUserHavePermissionToEditQuote
                && !Wizard.opportunity.isClosed
                && !state.isActiveAgreement
                && !state.isEngagementCancelled
                && Wizard.currentQuote
                && !Wizard.currentQuote.isInvalid
                && !Wizard.opportunity.isPendingConfirmAndClose) {
                saveCartButtonHidden = false;
                discardCartButtonHidden = false;
            }
            if (state.isSalesQuote
                && state.isUserHavePermissionToEditQuote
                && !Wizard.opportunity.isClosed
                && !state.isActiveAgreement
                && !state.isEngagementCancelled
                && Wizard.currentQuote
                && !Wizard.currentQuote.isInvalid
                && !Wizard.opportunity.isPendingConfirmAndClose) {
                getTaxesButtonHidden = false;
                removeTaxesButtonHidden = false;
            }

        } else if (Tabs.phases.isOpen) {
            if (state.isUserHavePermissionToEditQuote
                && !state.isActiveAgreement
                && !state.isEngagementCancelled) {
                isSavePhasesButtonShown = true;
                isDiscardPhasesButtonShown = true;
            }

        } else if (Tabs.summary.isOpen) {
            // Quote Summary
            if (Wizard.currentQuote && !Wizard.currentQuote.isInvalid
                && (settings.userPermissions.EditProServProjectManagerField
                || settings.userPermissions.EditProServSalesRepField
                || (state.isUserHavePermissionToEditQuote
                    && !Wizard.opportunity.isClosed
                    && !state.isActiveAgreement
                    && !state.isEngagementCancelled
                    && !Wizard.opportunity.isPendingConfirmAndClose)) ) {
                saveButtonHidden = false;
                discardQuoteButtonHidden = false;
            }
            isGeneratePDFShown = state.isUserHasPermissionToGeneratePDF
                && Wizard.currentQuote && !Wizard.currentQuote.isInvalid;

        }

        component.find('QuotingToolGeneratePdf').set('v.showButton', isGeneratePDFShown);
        var elements = [
            {auraId: 'saveButtonWrapper',           isHidden:  saveButtonHidden},
            {auraId: 'saveCartButtonWrapper',       isHidden:  saveCartButtonHidden},
            {auraId: 'discardCartButtonWrapper',    isHidden:  discardCartButtonHidden},
            {auraId: 'discardQuoteButtonWrapper',   isHidden:  discardQuoteButtonHidden},
            {auraId: 'tierUpgradeButton',           isHidden:  tierUpgradeButtonHidden},
            {auraId: 'cancelUpgradeButton',         isHidden:  cancelUpgradeButtonHidden},
            {auraId: 'getTaxesButton',              isHidden:  getTaxesButtonHidden},
            {auraId: 'removeTaxesButton',           isHidden:  removeTaxesButtonHidden},
            {auraId: 'saveServicePlanButton',       isHidden:  saveServicePlanButtonHidden},
            {auraId: 'discardServicePlanButton',    isHidden:  discardServicePlanButtonHidden},
            {auraId: 'savePhasesButtonWrapper',     isHidden: !isSavePhasesButtonShown},
            {auraId: 'discardPhasesButtonWrapper',  isHidden: !isDiscardPhasesButtonShown}
        ];
        elements.forEach(function (element) {
            RC.cssUtils.toggleShow(component, element.auraId, !element.isHidden, 'hidden', $A);
        });
    }
});