({
    /**
     * Makes Quote Primary
     * @param component
     * @param quoteId
     * @param quotes
     */
    setQuotePrimary: function(component, quoteId) {

        component.set('v.primaryButtonDisabled', true);
        $A.util.addClass(component.find('primaryButton'), "button--busy");

        QW.salesforce.request(component, 'c.setQuotePrimary', {
                quoteId: quoteId,
                proServQuoteId: component.get('v.proServQuote.Id'),
                ccProServQuoteId: component.get('v.ccProServQuote.Id')
            })
            .catch($A.getCallback(function(error){

                console.error(error);

                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to set Quote Primary',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();

            }))
            .then($A.getCallback(function() {

                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();

                $A.util.removeClass(component.find('primaryButton'), "button--busy");
                component.set('v.primaryButtonDisabled', false);

            }));
    },
    initSelector: function(component, quote) {
        if (quote) {
            component.find("quoteSelector").set("v.value", quote.Id);
            component.set('v.currentQuoteId', quote.Id);
        } else {
            component.find("quoteSelector").set("v.value", null);
            component.set('v.currentQuoteId', null);
        }
    },

    changeQuote: function(component, quoteId) {
        try {
            console.log('changeQuote');
            this.updateQuoteSelectorOptions(component, component.get('v.quotes'));
            component.find('quoteSelector').set('v.value', quoteId);
            $A.get("e.c:QuotingToolGetQuoteEvent").setParams({ quoteId: quoteId }).fire();
        } catch (e) {
            console.log(e);
        }
    },
    finishDeleting: function(component) {
        const helper = this;
        this.getWizardData(component, {
                quotesLevel: true
            })
            .then($A.getCallback(() => RC.salesforce.request(component, "c.getPrimaryQuote", {
                quotes:component.get('v.Wizard').getQuotesFilteredByMode()
            })))
            .then($A.getCallback((initQuote) => {
                var quoteId = initQuote ? initQuote.Id : null;
                helper.changeQuote(component, quoteId);
            }))
            .catch($A.getCallback(error => RC.salesforce.displayError("Quote change failed", error)));

        var quote = component.get('v.quote');
        if (quote.Opportunity.Parent_Order__c != null
            && (quote.RecordType.Name === component.get('v.Wizard').settings.CC_PROSERV_QUOTE_RT_NAME
                || quote.RecordType.Name === component.get('v.Wizard').settings.PROSERV_QUOTE_RT_NAME)) {

            window.open('/' + quote.Opportunity.Parent_Order__c, '_parent');
        }
    },
    completeAction: function(component) {
        var targetAction = component.get("v.targetAction");
        component.set("v.targetAction", null);
        if (targetAction === "newQuote") {
            // this.emptyQuote(component);
        } else if (targetAction === "changeQuote") {
            this.changeQuote(component, component.get("v.targetQuoteId"));
        }
    },

    checkQuoteSelector: function(component) {
        var quote = component.get("v.quote");
        if (quote) {
            component.find("quoteSelector").set("v.value", quote.Id);
        }
    },
    /**
     * Show/hide elements depending on user
     * @see {@link https://rc.my.salesforce.com/a2034000003PA1r} B-897 Quote Wizard Changes for Relayware
     */
    checkUserAccess: function(component){
        var state = component.get('v.state');
        var engageButtons = component.find('engageButtons');
        var approvalButtons = component.find('approvalButtons');

        if (state.isUserRelayware) {
            $A.util.addClass(engageButtons,'relayware--disable');
            $A.util.addClass(approvalButtons,'relayware--disable');
        } else {
            $A.util.removeClass(engageButtons,'relayware--disable');
            $A.util.removeClass(approvalButtons,'relayware--disable');
        }
    },

    checkDisabling: function(component){
        var Wizard = component.get('v.Wizard');
        var isCC = component.get('v.isCC');

        const isBillingOpportunity = Wizard.opportunity.record.Is_Billing_Opportunity__c;
        const isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval;
        const isContactCenterQuote = Wizard.currentQuote && Wizard.currentQuote.isCC;
        const isOnCCAndPrimaryOnApproval = (isContactCenterQuote && (isBillingOpportunity && isPrimaryQuoteOnApproval));

        component.set('v.primaryButtonDisabled', !Wizard.currentQuote
            || Wizard.currentQuote.record.isPrimary__c
            || Wizard.currentQuote.isInvalid
            || Wizard.isOppHasActiveAgreements
            || isOnCCAndPrimaryOnApproval);

        component.find('newQuoteButton').set('v.disabled', !Wizard.currentQuote
            || isOnCCAndPrimaryOnApproval);

        component.find('deleteButton')
            .set('v.disabled',  !Wizard.currentQuote
                             || (Wizard.opportunity && Wizard.opportunity.isClosed)
                             ||  Wizard.opportunity.isPendingConfirmAndClose
                             ||  Wizard.currentQuote.isActiveAgreement
                             || (Wizard.currentQuote.isSales && Wizard.salesQuotes.length === 1 )
                             || isOnCCAndPrimaryOnApproval);

        component.find('cancelChangeOrderButton')
            .set('v.disabled',  !Wizard.currentQuote
                             || (Wizard.opportunity && Wizard.opportunity.isClosed)
                             ||  Wizard.opportunity.isPendingConfirmAndClose
                             ||  Wizard.currentQuote.isActiveAgreement
                             || (Wizard.currentQuote.isSales && Wizard.salesQuotes.length === 1 )
                             || isOnCCAndPrimaryOnApproval);
    },

    checkDisplaying: function(component){
        var Wizard = component.get('v.Wizard');
        const isCC = component.get('v.isCC');
        const settings = component.get('v.settings');
        const isBtCC = settings.isBTBusiness && isCC;
        const gspPartnerSetup = settings.gspPartnerSetup;
        const isPartnerOpportunity = gspPartnerSetup
            && gspPartnerSetup.gspPartnerSetupId
            && gspPartnerSetup.isDisableCommercialQuoting
            && !gspPartnerSetup.isDisableProServ;

        function hasActiveEntitlement(cartItem) {
            return cartItem.isHasActiveEntitlement ? true : false;
        }

        if (Wizard.currentQuote && Wizard.currentQuote.isCC) {
            var isHasCCActiveEntitlement = Wizard.currentQuote.cartItems.some(hasActiveEntitlement);
            component.set('v.isHasCCActiveEntitlement', isHasCCActiveEntitlement);
        }

        RC.cssUtils.toggleShow(component, 'primaryButton', Wizard.currentQuote
                                                      &&   Wizard.currentQuote.isSales
                                                      &&   Wizard.currentQuote.isUserHavePermissionToEditQuote
                                                      && !(Wizard.opportunity && Wizard.opportunity.isClosed)
                                                      &&  !Wizard.opportunity.isPendingConfirmAndClose
                                                      && !isCC);

        RC.cssUtils.toggleShow(component, 'deleteButton', Wizard.currentQuote
                                                       && Wizard.currentQuote.isUserHavePermissionToEditQuote);

        RC.cssUtils.toggleShow(component, 'cancelChangeOrderButton', Wizard.currentQuote
                                                       && Wizard.currentQuote.isUserHavePermissionToEditQuote);

        RC.cssUtils.toggleShow(component, 'newQuoteButtonWrapper', Wizard.currentQuote
                                                              && !(Wizard.opportunity && Wizard.opportunity.isClosed)
                                                              &&   Wizard. settings.userPermissions.EditSalesQuote
                                                              &&  !this.isProServDisplayMode(component)
                                                              &&  !Wizard.opportunity.isPendingConfirmAndClose
                                                              && !isCC);

        component.find('sendWithDocuSignButton').set('v.show', !isBtCC &&
                                                               Wizard.currentQuote &&
                                                              (Wizard.currentQuote == Wizard.primaryQuote) &&
                                                             !(Wizard.opportunity && Wizard.opportunity.isClosed) &&
                                                               Wizard.settings.featureToggle.DocuSignInWizard__c &&
                                                               !Wizard.opportunity.isAvaya &&
                                                               !settings.isAtos &&
                                                               !settings.isRainbow &&
                                                               !isPartnerOpportunity);
    },

    isProServDisplayMode: function(component) {
        return component.get('v.isProserv');
    },

    /**
     *  update Quote Selector options
     */
    updateQuoteSelectorOptions: function(component) {
        try {
            var quotes = component.get('v.Wizard').getQuotesFilteredByMode();

            var oldQuote = component.get('v.oldQuote');
            var quote = component.get('v.quote');

            !quote && (quote = null);

            if(!oldQuote && !quote && quotes.length) {
                var isPrimary = quotes.find( quote => quote.isPrimary__c);
                quote = isPrimary || quotes[0];
                component.set('v.quote',    JSON.parse(JSON.stringify(quote)) );
                component.set('v.oldQuote', JSON.parse(JSON.stringify(quote)) );

                $A.get("e.c:QuotingToolGetQuoteEvent").setParams({ quoteId: quote.Id }).fire();
            } else {
                component.set('v.oldQuote', JSON.parse(JSON.stringify(quote)) );
            }

            var currentQuoteId = quote && quote.Id;
            var options = [];

            quotes.forEach( quoteItem => {
                options.push(
                    this.getQuoteSelectorOption(
                        quoteItem.Id,
                        this.getQuoteOptionLabel(quoteItem),
                        this.getQuoteOptionCssClass(quoteItem),
                        quoteItem.Id === currentQuoteId
                    )
                );
            });

            if ((!options.length || !currentQuoteId) && !this.isProServDisplayMode(component)) {
                options.unshift(this.getQuoteSelectorOption(null, '--New Quote--', null, true, true));
            }

            component.find('quoteSelector').set('v.options', options);
        } catch(e) {
            console.log(e);
        }
    },

    getQuoteOptionLabel: function(quote) {
        var postfix = '';
        if(quote.isPrimary__c) postfix += ' ★';

        return quote.QuoteNumber + ' | ' + quote.Name + postfix;
    },

    getQuoteOptionCssClass: function(quote) {
        return quote.isPrimary__c ? 'quote-selector__quote--primary' : '';
    },

    getQuoteSelectorOption: function(value, label, cssClass, selected, newQuotePlaceholder) {
        return {
            value: value,
            label: label || value,
            class: 'quote-selector__quote' + (cssClass ? cssClass : ''),
            selected: selected,
            newQuotePlaceholder: newQuotePlaceholder,
        };
    },

    selectQuoteInQuoteSelector: function(component, quote, isNewQuoteMode) {
        try {
            var currentQuoteId = quote && quote.Id;
            var quoteSelector = component.find('quoteSelector');
            var options = quoteSelector.get('v.options');
            if(isNewQuoteMode) {
                var hasOption = options.find(o => o.newQuotePlaceholder);
                if(!hasOption) options.unshift(this.getQuoteSelectorOption(null, '--New Quote--', null, true, true));
            } else {
                options.forEach( o => o.selected = (o.Id === currentQuoteId));
            }

            quoteSelector.set('v.options', options);
        } catch (e) {
            console.log(e);
        }
    },

    showPopover: function(component, auraId, target) {
        var Wizard = component.get('v.Wizard');

        var isBillingOpportunity = Wizard.opportunity && Wizard.opportunity.record.Is_Billing_Opportunity__c;
        const isPrimaryQuoteOnApproval = Wizard.primaryQuote && Wizard.primaryQuote.isOnApproval;
        const isContactCenterQuote = Wizard.currentQuote && Wizard.currentQuote.isCC;
        const isOnCCAndPrimaryOnApproval = (isContactCenterQuote && (isBillingOpportunity && isPrimaryQuoteOnApproval));

        var messages = [];

        switch (auraId) {

            // Delete Button
            case 'deleteButton':

                if ((Wizard.opportunity && Wizard.opportunity.isClosed)
                    || Wizard.currentQuote
                    && (Wizard.currentQuote.isActiveAgreement
                        || (Wizard.currentQuote.isSales && Wizard.salesQuotes.length === 1))) {
                            messages.push(QW.popover.MESSAGES.cantDeleteLastQuote);
                        }else if(isOnCCAndPrimaryOnApproval) {
                            messages.push({
                                header: 'Primary Quote on Approval',
                                text: 'Contact Center Quote cannot be deleted/modified when Primary Quote is in Approval Process',
                                iconTheme: 'info'
                            });
                        }

            break;

            case 'cancelChangeOrderButton':

                if ((Wizard.opportunity && Wizard.opportunity.isClosed)
                    || Wizard.currentQuote
                    && (Wizard.currentQuote.isActiveAgreement
                        || (Wizard.currentQuote.isSales && Wizard.salesQuotes.length === 1))) {
                            messages.push(QW.popover.MESSAGES.cantDeleteLastQuote);
                        }else if(isOnCCAndPrimaryOnApproval) {
                            messages.push({
                                header: 'Primary Quote on Approval',
                                text: 'Contact Center Quote cannot be cancel/modified when Primary Quote is in Approval Process',
                                iconTheme: 'info'
                            });
                        }

            break;

            // Primary Quote button
            case 'primaryButton':
                if(!Wizard.currentQuote.record.isPrimary__c && Wizard.isOppHasActiveAgreements) {
                    messages.push(QW.popover.MESSAGES.cantSetPrimaryIfOppHasActiveAgreement);
                }else if(isOnCCAndPrimaryOnApproval) {
                    messages.push({
                        header: 'Primary Quote on Approval',
                        text: 'Cannot modify Quote during primary Quote is on Approval Process.',
                        iconTheme: 'info'
                    });
                }

            break;
        }

        // Show popover
        if (target && messages.length > 0){
            QW.popover.show(target, messages);
        }
    },

    createDocuSignComponent: function(component){
        const Wizard = component.get('v.Wizard');
        return RC.components.createOne("c:DocuSign", {
                opportunityId: Wizard.opportunity.record.Id,
                primaryQuoteId: Wizard.primaryQuote.record.Id,
                isVoidEnvelopesAllowed: Wizard.user.isOpportunityOwner ||
                    Wizard.user.isQuoteOwner ||
                    Wizard.settings.userPermissions.VoidDocuSignEnvelope
            });
    },
});