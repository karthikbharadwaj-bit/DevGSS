({
    // Button Names
    ENGAGE_PROSERV:     'engageProServ',
    ENGAGE_CC_PROSERV:  'engageCCProServ',
    CANCEL_PROSERV:     'cancelProServ',
    CANCEL_CC_PROSERV:  'cancelCCProServ',
    SYNC:               'sync',
    // backend proServType
    PROSERV:    'ProServ',
    CC_PROSERV: 'CCProServ',
    // Modal
    proServIsSoldModalGUID:'proServIsSoldConfirmModal',
    proServIsOutForSignatureModalGUID:'proServIsOutForSignatureConfirmModal',
    /**
     * Open Modal window
     * Set v.modalInfo attribute with labels for current proServType
     * @param component Aura Component
     * @param auraId    Button aura Id to set Modal info for
     */
    modalOpen: function(component, auraId) {
        var modalInfo = {

            //Engage Professional Services
            engageProServButton: {
                type: this.ENGAGE_PROSERV,
                proServType: this.PROSERV,
                title: $A.get("$Label.c.QW_Title_EngageProServModal"),
                textareaLabel: $A.get("$Label.c.QW_FieldLabel_EngageProServDetails"),
                spinner: 'Engaging ProServ Team',
                toast: {
                    success: {
                        header: 'Professional Service Engagement Request has been sent',
                        details: 'Professional Service Group will get an email notification'
                    },
                    error: {
                        header: 'Professional Service Engagement Failed'
                    }
                }
            },

            //Engage CC Professional Services
            engageCCProServButton: {
                type: this.ENGAGE_CC_PROSERV,
                proServType: this.CC_PROSERV,
                title: $A.get("$Label.c.QW_Title_EngageCCProServModal"),
                textareaLabel: $A.get("$Label.c.QW_FieldLabel_EngageCCProServDetails"),
                spinner: 'Engaging CC ProServ Team',
                toast: {
                    success: {
                        header: 'CC Professional Service Engagement Request has been sent',
                        details: 'CC Professional Service Group will get an email notification'
                    },
                    error: {
                        header: 'CC Professional Service Engagement Failed'
                    }
                }
            },

            //Cancel Professional Services
            cancelProServButton: {
                type: this.CANCEL_PROSERV,
                proServType: this.PROSERV,
                title: $A.get("$Label.c.QW_Title_CancelProServModal"),
                textareaLabel: $A.get("$Label.c.QW_FieldLabel_CancelProServDetails"),
                message: 'Professional Services team is already working on your request. You can cancel their engagement for this deal',
                spinner: 'Cancelling ProServ Engagement',
                spinnerRemove: 'Removing ProServ Products from all Sales Quotes',
                spinnerUpdate: 'Updating ProServ Products on all Sales Quotes',
                toast: {
                    success: {
                        header: 'Professional Service Cancelled',
                        details: ''
                    },
                    error: {
                        header: 'Professional Service Cancellation Failed'
                    }
                }
            },

            // Cancel CC Professional Services
            cancelCCProServButton: {
                type: this.CANCEL_CC_PROSERV,
                proServType: this.CC_PROSERV,
                title: $A.get("$Label.c.QW_Title_CancelCCProServModal"),
                textareaLabel: $A.get("$Label.c.QW_FieldLabel_CancelCCProServDetails"),
                message: 'Contact Center Professional Services team is already working on your request. You can cancel their engagement for this deal',
                spinner: 'Cancelling CC ProServ Engagement',
                spinnerRemove: 'Removing CC ProServ Products from all Sales Quotes',
                spinnerUpdate: 'Updating CC ProServ Products on all Sales Quotes',
                toast: {
                    success: {
                        header: 'CC Professional Service Cancelled',
                        details: ''
                    },
                    error: {
                        header: 'CC Professional Service Cancellation Failed'
                    }
                }
            }
        };

        this.setEngageProperties(component, modalInfo);
        this.setCaseReasons(component);
        component.set('v.modalInfo', modalInfo[auraId]);

        $A.util.addClass(component.find('modal'), "slds-fade-in-open");
        $A.util.addClass(component.find('modalBg'), "slds-backdrop--open");
    },
    /**
     * Close Modal window
     */
    modalClose : function(component) {
        $A.util.removeClass(component.find('modal'), "slds-fade-in-open");
        $A.util.removeClass(component.find('modalBg'), "slds-backdrop--open");
        component.set('v.details','');
    },
    /**
     * Engage (CC) Professional Services
     * Call Server-Side Action
     */
    engageProServHelper: function(component, modalInfo) {
        var helper = this;
        var quote = component.get('v.quote');
        var details = component.get('v.details');
        var proServQuote = modalInfo.proServType === this.PROSERV ?
            component.get('v.proServQuote') :
            component.get('v.ccProServQuote');

        component.set('v.isBusy', true);
        let quoteId = '';

        QW.spinner.show(modalInfo.spinner);

        if (quote) {

            var engageProServProcess = QW.salesforce.request(component, 'c.engageProServ', {
                opportunityId: quote.OpportunityId,
                details: details,
                type: modalInfo.proServType,
                isNewBilling: false,
            });

            engageProServProcess.then($A.getCallback(function(res) {
                return QW.salesforce.request(component, 'c.enableLBOForPrimaryQuote', { opportunityId: quote.OpportunityId });
            }));

            // Add Entitlements and Case for new CC ProServ Quote
            if (!proServQuote) {
                engageProServProcess.then($A.getCallback(function(res) {
                    quoteId = res.proServQuoteId;
                    return QW.salesforce.request(component, 'c.addEntitlementsAsLineItems', { quoteId: res.proServQuoteId });
                }));
            } else {
                quoteId = proServQuote.Id;
            }

            engageProServProcess.then($A.getCallback(function() {
                const caseParams = helper.prepareCaseParams(component, quoteId, modalInfo.proServType, false);
                return QW.salesforce.request(component, 'c.createPSCase', { params: caseParams });
            }));

            // Finalise Engagement
            engageProServProcess.then($A.getCallback(function() {
                helper.modalClose(component);

                $A.get("e.c:ToastEvent").setParams({
                    theme: 'success',
                    header: modalInfo.toast.success.header,
                    details: modalInfo.toast.success.details,
                    defaultTimeout: true
                }).fire();
            }))
                .catch($A.getCallback(function(error) {
                    console.error(error);
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'error',
                        header: modalInfo.toast.error.header,
                        details: QW.salesforce.getResponseError(error),
                        defaultTimeout: false
                    }).fire();
                }))
                .then($A.getCallback(function() {
                    component.set('v.isBusy', false);
                    QW.spinner.hide();

                    // Trigger Quote refresh
                    $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                }));
        }
    },

    cancelProServHelper: function(component, modalInfo){
        var helper = this;
        var quote = component.get('v.quote');
        var details = component.get('v.details');
        const isProserv = modalInfo.proServType === this.PROSERV;
        const proServQuote = isProserv
            ? component.get('v.proServQuote')
            : component.get('v.ccProServQuote');

        if (quote) {
            component.set('v.isBusy', true);
            QW.spinner.show(modalInfo.spinnerRemove);
            // Delete ProServ Products form Sales Quotes
            QW.salesforce.request(component, 'c.removeProServProds', {
                objId: quote.OpportunityId,
                type: modalInfo.proServType,
                doDelete: true,
                doUpdate: false,
                isNewBilling: false,
            })
            // Update ProServ Products form Sales Quotes
                .then($A.getCallback(function(){
                    QW.spinner.show(modalInfo.spinnerUpdate);
                    return QW.salesforce.request(component, 'c.removeProServProds', {
                        objId: quote.OpportunityId,
                        type: modalInfo.proServType,
                        doDelete: false,
                        doUpdate: true,
                        isNewBilling: false,
                    })
                }))
                // Mark quote as cancelled
                .then($A.getCallback(function(){
                    QW.spinner.show(modalInfo.spinner);
                    return QW.salesforce.request(component, 'c.cancelProServ', {
                        opportunityId: quote.OpportunityId,
                        details: details,
                        type: modalInfo.proServType,
                        isNewBilling: false,
                    })
                }))
                //Create PS case only for Proserv quote
                .then($A.getCallback(function() {
                    if (!isProserv) {
                        return;
                    }
                    const caseParams = helper.prepareCaseParams(component, proServQuote.Id, modalInfo.proServType, true);
                    return QW.salesforce.request(component, 'c.createPSCase', { params: caseParams });
                }))
                // Finalise cancellation
                .then($A.getCallback(function() {
                    helper.modalClose(component);

                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'success',
                        header: modalInfo.toast.success.header,
                        details: modalInfo.toast.success.details,
                        defaultTimeout: true
                    }).fire();

                }))
                .catch($A.getCallback(function(error) {
                    console.error(error);
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'error',
                        header: modalInfo.toast.error.header,
                        details: QW.salesforce.getResponseError(error),
                        defaultTimeout: false
                    }).fire();
                }))
                .then($A.getCallback(function() {
                    component.set('v.isBusy', false);
                    QW.spinner.hide();

                    // Refresh quote
                    $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();

                    // Refresh cart
                    $A.get("e.c:QuotingToolRefreshCartEvent").fire();

                }));
        }
    },
    showPopover: function(component, auraId, target){
        var state = component.get('v.state');
        var Wizard = component.get('v.Wizard');
        var isBilling = Wizard.config.wizard.isBilling;

        if (!Wizard.currentQuote)
            return;

        var messages = [];

        switch (auraId){

            // Sync Button
            case 'syncButton':

                // Primary Quote is on Approval
                if (state.isPrimaryQuoteOnApproval)
                    messages.push( QW.popover.MESSAGES.cantSyncPrimaryOnApproval );

                // No Contact Center on Primary Quote
                if (!isBilling) {
                    if (state.isCCProServQuote && !state.isCCProServProductsOnPrimaryQuote) {
                        messages.push( QW.popover.MESSAGES.cantSyncCCProServNotAvailableOnPrimary );
                    }
                } else {
                    if (state.isCCProServQuote && !state.isCCProServProductsOnCCQuote) {
                        messages.push( QW.popover.MESSAGES.cantSyncCCProServNotAvailableOnCCQuote );
                    }
                }

                // ProServ Cancelled
                if (( state.isProServQuote && state.isProServCancelled ) || ( state.isCCProServQuote && state.isCCProServCancelled )){
                    messages.push( {
                        message: QW.popover.MESSAGES.engagementCancelled,
                        params: {
                            name: component.get('v.primaryQuote.LastModifiedBy.Name') || 'Primary Quote User'
                        }
                    } );
                }

                // Primary Quote is in Draft status
                if (!Wizard.primaryQuote.isDraft)
                    messages.push( QW.popover.MESSAGES.cantSyncPrimaryStatusNotDraft );

                // Primary Quote is in Agreement status
                if (Wizard.primaryQuote.isAgreement)
                    messages.push( QW.popover.MESSAGES.cantSyncPrimaryIsAgreement );

                // There are phases without any assigned items
                if (Wizard.currentQuote.isHasEmptyPhases)
                    messages.push( QW.popover.MESSAGES.cantSyncEmptyPhases );

                // There are phases without any assigned items
                if (Wizard.currentQuote.isPhaseLineItemsUnassigned)
                    messages.push( QW.popover.MESSAGES.cantSyncAssignAllPhaseLineItems );

                // You can't Sync ProServ Quote if ProServ Architect field is empty
                if (!Wizard.currentQuote.record.ProServSalesRep__c)
                    messages.push( QW.popover.MESSAGES.cantSyncProServArchitectIsEmpty );

                // You can't Sync ProServ Quote if primary quote is invalid
                if (Wizard.primaryQuote.isInvalid) {
                    messages.push( QW.popover.MESSAGES.cantSyncProServPrimaryIsInvalid );
                }

                if(Wizard.primaryQuote.isOnApproval)
                    messages.push( QW.popover.MESSAGES.cantSyncPrimaryOnApproval );

                break;

            // Engage Professional Services Button
            case 'engageProServButton':

                // Professional Services Products not available on Primary Quote
                if (!state.isProServProductsOnPrimaryQuote)
                    messages.push( QW.popover.MESSAGES.cantEngageProServNotAvailable );
                break;

            // Engage Contact Center Professional Services Button
            case 'engageCCProServButton':

                // Contact Center Products not available on Primary Quote
                if (!state.isCCProServProductsOnPrimaryQuote && !Wizard.currentQuote.isCC)
                    messages.push(QW.popover.MESSAGES.cantEngageCCProServNotAvailable);
                    break;

            // Cancel Contact Center Professional Services Button
            case 'proServIsOutForSignatureButton':
                // You can't Mark ProServ as Sold if SOW Type field is empty
                if (!Wizard.currentQuote.record.SOW_Type__c && !Wizard.currentQuote.isCC) {
                    messages.push( QW.popover.MESSAGES.cantMarkOutForSignatureSowTypeEmpty );
                }
                // There are unassigned phase line items
                if (Wizard.currentQuote.isPhaseLineItemsUnassigned) {
                    messages.push( QW.popover.MESSAGES.cantMarkOutForSignatureUnassignedPhaseLineItems );
                }
                break;
            case 'proServIsSoldButton':

                // There are phases without any assigned items
                if (Wizard.currentQuote.isPhaseLineItemsUnassigned)
                    messages.push( QW.popover.MESSAGES.cantSellAssignAllPhaseLineItems );

                // There are phases without any assigned items
                if (Wizard.currentQuote.isHasEmptyPhases)
                    messages.push( QW.popover.MESSAGES.cantSellEmptyPhases );

                // You can't Mark ProServ as Sold if ProServ Architect field is empty
                if (!Wizard.currentQuote.record.ProServSalesRep__c)
                    messages.push( QW.popover.MESSAGES.cantSoldProServArchitectIsEmpty );

                // You can't Mark ProServ as Sold if Signed SOW field is empty
                if (!Wizard.currentQuote.record.Signed_SOW__c && !QW.QuoteHelper.isVerizon(Wizard.currentQuote.record))
                    messages.push( QW.popover.MESSAGES.cantSoldSignedSOWIsEmpty );

                if ((!Wizard.currentQuote.record.Signed_SOW__c || !Wizard.currentQuote.record.UID_from_biz__c)
                    && QW.QuoteHelper.isVerizon(Wizard.currentQuote.record)) {
                    messages.push( QW.popover.MESSAGES.cantSoldSignedSOWorUIDIsEmpty );
                }
                break;

            case 'unlockButton':

                // Primary Sales Quote should be in Quote stage.
                if (!Wizard.opportunity.isChangeOrderOpportunity
                    && Wizard.primaryQuote
                    && !Wizard.primaryQuote.isQuote)
                    messages.push( QW.popover.MESSAGES.cantUnlockPrimaryNotQuote );

                break;
        }

        // Show popover
        if (target && messages.length > 0){
            QW.popover.show(target, messages);
        }
    },

    toggleDisplaying: function (component) {
        var Wizard = component.get('v.Wizard');
        var isCC = component.get('v.isCC');
        var isGSPWithoutCommercialQuoting = Wizard.config.old.settings.gspPartnerSetup !== null
        	&& Wizard.config.old.settings.gspPartnerSetup.isDisableCommercialQuoting;

        var isSyncButtonShown = false;
        var isEngageButtonShown = false;
        var isSoldButtonShown = false;
        var isOutForSignatureButtonShown = false;
        var isEngageCCButtonShown = false;
        var isSwitchButtonShown = false;
        var isCancelProServButtonShown = false;
        var isCancelCCProServButtonShown = false;
        var isUnlockButtonShown = false;

        if (Wizard.opportunity
            &&  Wizard.currentQuote
            && !Wizard.opportunity.isClosed
            && !Wizard.user.isRelayware) {

            if (!Wizard.currentQuote.isAgreement && Wizard.currentQuote.isCCorProServ && Wizard.currentQuote.isUserHavePermissionToEditQuote) {
                // Buttons on ProServ Quote
                isSwitchButtonShown = Wizard.currentQuote.isPrimaryQuotePriceBookPlanDiffers;

                isSyncButtonShown = !Wizard.opportunity.isChangeOrderOpportunity
                    && !Wizard.currentQuote.isSoldOrOutForSignature
                    && !isGSPWithoutCommercialQuoting;

                if (Wizard.settings.userPermissions.MarkProServAsSold) {

                    isOutForSignatureButtonShown = Wizard.opportunity.isChangeOrderOpportunity
                        ? !Wizard.currentQuote.isSoldOrOutForSignature
                        :  Wizard.currentQuote.isSynced || (isGSPWithoutCommercialQuoting && !Wizard.currentQuote.isSoldOrOutForSignature);

                    isSoldButtonShown = Wizard.currentQuote.isOutForSignature;
                    isUnlockButtonShown = Wizard.currentQuote.isOutForSignature;
                }

                isCancelCCProServButtonShown = Wizard.currentQuote.isCCProServ
                    && !Wizard.currentQuote.isSold
                    && !Wizard.currentQuote.isCancelled
                    && !Wizard.opportunity.isChangeOrderOpportunity;

            } else {
                // Buttons on Sales Quote
                if (Wizard.settings.userPermissions.EngageProServ) {
                    isEngageButtonShown = !Wizard.proServQuote || Wizard.proServQuote.isCancelled;
                    isCancelProServButtonShown = !isEngageButtonShown && !Wizard.proServQuote.isSold;
                }

                if (Wizard.settings.userPermissions.EngageCCProServ) {
                    isEngageCCButtonShown = !Wizard.ccProServQuote || Wizard.ccProServQuote.isCancelled;
                }
            }
        }

        QW.cssUtils.toggleShow(component, 'syncButtonContainer',                     isSyncButtonShown);
        QW.cssUtils.toggleShow(component, 'engageProServButtonContainer',            isEngageButtonShown && !isCC);
        QW.cssUtils.toggleShow(component, 'proServIsSoldButtonContainer',            isSoldButtonShown);
        QW.cssUtils.toggleShow(component, 'proServIsOutForSignatureButtonContainer', isOutForSignatureButtonShown);
        QW.cssUtils.toggleShow(component, 'engageCCProServButtonContainer',          isEngageCCButtonShown);
        QW.cssUtils.toggleShow(component, 'cancelProServButtonContainer',            isCancelProServButtonShown);
        QW.cssUtils.toggleShow(component, 'cancelCCProServButtonContainer',          isCancelCCProServButtonShown);
        QW.cssUtils.toggleShow(component, 'switchButton',                            isSwitchButtonShown);
        QW.cssUtils.toggleShow(component, 'unlockButtonContainer',                   isUnlockButtonShown);

        this.setCancelButtonLabel(component);
    },

    toggleDisabling: function(component){
        const state = component.get('v.state');
        const Wizard = component.get('v.Wizard');

        const isBilling = Wizard.config.wizard.isBilling;
        const isEngageCcProServButtonDisabled = (!state.isCCProServProductsOnPrimaryQuote && !isBilling && !Wizard.settings.isBTBusiness) || (!state.isCCProServProductsOnCCQuote && isBilling);

        if (!Wizard.currentQuote)
            return;

        component.find('engageProServButton')  .set('v.disabled', !state.isProServProductsOnPrimaryQuote
            || Wizard.currentQuote.isInvalid);

        component.find('engageCCProServButton').set('v.disabled', isEngageCcProServButtonDisabled || Wizard.currentQuote.isInvalid);

        component.find('proServIsSoldButton')  .set('v.disabled',  Wizard.currentQuote.isPhaseLineItemsUnassigned
            ||  Wizard.currentQuote.isHasEmptyPhases
            || !Wizard.currentQuote.record.ProServSalesRep__c
            || !Wizard.currentQuote.record.Signed_SOW__c
            || Wizard.currentQuote.isInvalid
            || (!Wizard.currentQuote.record.UID_from_biz__c
                && QW.QuoteHelper.isVerizon(Wizard.currentQuote.record)))

        component.find('cancelProServButton').set('v.disabled', Wizard.currentQuote.isInvalid);

        component.find('unlockButton').set('v.disabled', !Wizard.opportunity.isChangeOrderOpportunity
            && Wizard.primaryQuote
            && !Wizard.primaryQuote.isQuote);

        let isBaseCheckFails = Wizard.currentQuote.isApprovalRequired
            ||  Wizard.currentQuote.isOnApproval
            || (Wizard.currentQuote.isCCorProServ && Wizard.currentQuote.isCancelled)
            ||  Wizard.currentQuote.isHasEmptyPhases
            ||  Wizard.currentQuote.isPhaseLineItemsUnassigned
            || !Wizard.currentQuote.record.ProServSalesRep__c
            ||  Wizard.isCartItemAddedDeleted
            ||  Wizard.isGettingQuotes;

        component.find('syncButton')
            .set('v.disabled', isBaseCheckFails
                || (Wizard.primaryQuote
                    && (
                        Wizard.primaryQuote.isInvalid 
                        || Wizard.primaryQuote.isOnApproval 
                        || Wizard.primaryQuote.isAgreement 
                        || !Wizard.primaryQuote.isDraft
                    )
                )
                || (
                    Wizard.currentQuote.isCCProServ
                    && !Wizard.currentQuote.isSyncRequired
                ));

        component.find('proServIsOutForSignatureButton')
            .set('v.disabled', isBaseCheckFails
                || !Wizard.currentQuote.record.ProServSalesRep__c
                || !Wizard.currentQuote.record.SOW_Type__c
                || Wizard.currentQuote.isInvalid
                || Wizard.currentQuote.isPhaseLineItemsUnassigned);

    },

    setSyncButtonLabel: function(component) {
        var Wizard = component.get('v.Wizard');

        var isSyncToCC = false;

        if (Wizard && Wizard.quotes) {
            Wizard.quotes.forEach (quote => {
               if (Wizard.currentQuote && Wizard.currentQuote.isCCProServ && quote.isCC) {
                   isSyncToCC = true;
               };
            });
        }
        component.find('syncButton')
            .set('v.label', isSyncToCC ? 'Sync To CC Quote' : 'Sync To Primary Quote');
    },

    proServIsSold: function(component) {

        var Wizard = component.get('v.Wizard');

        if(Wizard && Wizard.currentQuote.record.Id) {
            QW.spinner.show('Set Proserv status to Sold');
            component.set('v.isBusy', true);

            QW.salesforce.request(component, 'c.soldProServQuote', {
                quoteId: Wizard.currentQuote.record.Id
            })
                .then($A.getCallback(function() {

                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'success',
                        header: 'ProServ is Sold',
                        details: 'ProServ Status set to "Sold"',
                        defaultTimeout: true
                    }).fire();

                    // Refresh quote
                    $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();

                    // Refresh cart
                    $A.get("e.c:QuotingToolRefreshCartEvent").fire();
                }))
                .catch($A.getCallback(
                    RC.salesforce.displayError.bind(this, 'Failed to mark Quote as "Sold"')
                ))
                .then($A.getCallback(function() {
                    component.set('v.isBusy', false);
                    QW.spinner.hide();
                }));
        }
    },

    proServIsOutForSignature: function(component) {

        var Wizard = component.get('v.Wizard');

        if(Wizard && Wizard.currentQuote.record.Id) {
            QW.spinner.show('Set Proserv status to Out for Signature');
            component.set('v.isBusy', true);

            QW.salesforce.request(component, 'c.outForSignatureProServQuote', {
                quoteId: Wizard.currentQuote.record.Id
            })
                .then($A.getCallback(function() {

                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'success',
                        header: 'ProServ is Out for Signature',
                        details: 'ProServ Status set to "Out for Signature"',
                        defaultTimeout: true
                    }).fire();

                    // Refresh quote
                    $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();

                    // Refresh cart
                    $A.get("e.c:QuotingToolRefreshCartEvent").fire();

                }))
                .catch($A.getCallback(
                    RC.salesforce.displayError.bind(this, 'Failed to mark Quote as "Out for Signature"')
                ))
                .then($A.getCallback(function() {
                    component.set('v.isBusy', false);
                    QW.spinner.hide();
                }));
        }
    },

    /**
     * Sync Pro Serv Quote with Sales Primary Quote
     * @param component         {object}  Aura Component
     * @param syncOnlyAvailable {boolean} If true all unavailable products will be ignored.
     */
    syncProServWithSales: function(component, syncOnlyAvailable){
        var quotes = component.get('v.quotes');
        component.set('v.isBusy', true);
        var type = component.get('v.state.isCCProServQuote') ? this.CC_PROSERV : this.PROSERV;

        QW.spinner.show('Removing old products from Primary Quote');
        // Get Primary Quote
        QW.salesforce.request(component, 'c.getPrimaryQuote', { quotes: quotes })
        // Remove old ProServ Products form Primary Quote
            .then($A.getCallback(function(primaryQuote){
                return QW.salesforce.request(component, 'c.removeProServProds', {
                    objId: primaryQuote.OpportunityId,
                    type: type,
                    doDelete: true,
                    doUpdate: false
                }).then($A.getCallback(function(){
                    return new Promise(function(resolve) {
                        resolve(primaryQuote);
                    });
                }));
            }))
            // Remove old ProServ Products form Primary Quote
            .then($A.getCallback(function(primaryQuote){
                return QW.salesforce.request(component, 'c.removeProServProds', {
                    objId: primaryQuote.OpportunityId,
                    type: type,
                    doDelete: false,
                    doUpdate: true
                });
            }))
            // Sync new ProServ Products to primary quote
            .then($A.getCallback(function() {
                QW.spinner.show('Syncing new products with Primary Quote');
                return QW.salesforce.request(component, 'c.syncProServWithSales', {
                    opportunityId: component.get('v.quote.OpportunityId'),
                    syncOnlyAvailable: syncOnlyAvailable,
                    type: type
                });
            }))
            .then($A.getCallback(function(res){

                if (res.status === 'action required' && res.unavailableProducts) {

                    // If There are unavailable products, ask User if he wish to skip them
                    var unavailableProducts = JSON.parse(res.unavailableProducts);
                    var pqUser = res.pqUser ? JSON.parse(res.pqUser) : null;
                    var pqPricebook2Name = res.pqPricebook2Name ? JSON.parse(res.pqPricebook2Name) : '';
                    $A.get("e.c:QuotingToolModalRequestEvent").setParams({
                        action: "syncProServUnavailable",
                        sourceId: 'syncProServButton',
                        params: {
                            unavailableProducts: unavailableProducts,
                            pqUser: pqUser,
                            pqPricebook2Name: pqPricebook2Name
                        }
                    }).fire();

                } else if (res.status === 'success') {
                    $A.get("e.c:ToastEvent").setParams({
                        theme: 'success',
                        header: 'Products were synced with Primary Sales Quote',
                        defaultTimeout: true
                    }).fire();
                    // refresh quote
                    $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                }

            }))
            .catch($A.getCallback(function(error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Sync failed',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();

            }))
            .then($A.getCallback(function() {
                component.set('v.isBusy', false);
                QW.spinner.hide();
            }));
    },

    switchRequest: function(component){
        try {
            var pb = this.getSwitchPB(component);

            if(pb){
                $A.get("e.c:ModalRequestEvent").setParams({
                    guid: 'switchServicePlan',
                    header: 'Changing Service Plan?',
                    content: 'Changing Service Plan will empty the Cart. Do you want to continue?',
                    params: {
                        pricebook2Id: pb.Id
                    },
                    buttons: [{
                        name: 'yes',
                        variant: 'brand',
                        label: 'Empty cart & change Service Plan'
                    }]
                }).fire();
            } else {
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Switch plan failed',
                    details: 'Can not find the appropriate pricebook',
                    defaultTimeout: false
                }).fire();
            }
        } catch (e) {
            console.log(e);
        }
    },

    getSwitchPB: function(component) {
        var Wizard          = component.get('v.Wizard');
        var oppBrandName    = Wizard.opportunity.record.Brand_Name__c;
        var tiers           = Wizard.config.old.tiers;
        var pb              = Wizard.primaryQuote.record.Pricebook2;

        if(Wizard.config.wizard.isBilling) {
            pb = this.getBillingProservPB(tiers, oppBrandName);
        }

        return pb;
    },

    getBillingProservPB: function(tiers, brandName) {
        var tier = tiers.find(tier => {
            return (tier.Pricebook2.AllowedRecordType__c.includes('Service Billing ProServ') &&
                tier.Pricebook2.Brand__r.Name === brandName);
        });

        return tier && tier.Pricebook2;
    },

    setCancelButtonLabel: function(component) {
        const Wizard = component.get('v.Wizard');
        const isEngage = QW.OpportunityHelper.isTierNameEngage(Wizard.opportunity && Wizard.opportunity.record);
        const cancelButton = component.find('cancelCCProServButton');

        if (cancelButton) {
            cancelButton.set('v.label', isEngage
                ? QW.CONSTANTS.CANCEL_BUTTONS.CANCEL_PROSERV
                : QW.CONSTANTS.CANCEL_BUTTONS.CANCEL_CCPROSERV
            );
        }
    },

    setEngageProperties: function(component, modalInfo) {
        const Wizard = component.get('v.Wizard');
        const isEngage = QW.OpportunityHelper.isTierNameEngage(Wizard.opportunity && Wizard.opportunity.record);
        const cancelProServButton = JSON.parse(JSON.stringify(modalInfo['cancelProServButton']));

        if (isEngage) {
            cancelProServButton.type = this.CANCEL_CC_PROSERV;
            cancelProServButton.proServType = this.CC_PROSERV;
            modalInfo['cancelCCProServButton'] = cancelProServButton;
        }
    },

    setCaseReasons: function(component) {
        var caseReasons = [
            {
                label: 'Implementation Services Quote / SOW',
                value: 'Implementation Services Quote / SOW'
            },
            {
                label: 'Managed Services, Recurring Services, Advanced Support',
                value: 'Managed Services, Recurring Services, Advanced Support'
            },
            {
                label: 'Aftermarket PS Support',
                value: 'Aftermarket PS Support'
            }
        ]
        component.set('v.caseReasons', caseReasons);
    },

    unlock: function (component) {
        var Wizard = component.get('v.Wizard');
        component.set('v.isBusy', true);
        QW.spinner.show('Changing ProServ Status to "In progress"');
        QW.salesforce.request(component, 'c.updateQuote', {
            updatedQuote: {
                sobjectType: 'Quote',
                Id: Wizard.currentQuote.record.Id,
                ProServ_Status__c: QW.CONSTANTS.QUOTE.PROSERV_STATUS.IN_PROGRESS
            }
        }, $A)
            .catch($A.getCallback(
                RC.salesforce.displayError.bind(this, 'Failed to change ProServ Status to "In progress"')
            ))
            .then($A.getCallback(function () {
                // refresh quote
                $A.get("e.c:QuotingToolRefreshQuoteEvent").fire();
                component.set('v.isBusy', false);
                QW.spinner.hide();
            }));

    },

    prepareCaseParams: function (component, quoteId, type, isCancelledQuote) {
        const helper = this;
        const description = isCancelledQuote
            ? 'Please remove the quote for this customer.'
            : 'Please contact customer for requested quote';
        const category = isCancelledQuote
            ? 'Cancelation'
            : component.get('v.selectedCaseReasons').join(';');

        let caseParams = {
            accountId: component.get('v.quote.AccountId'),
            opportunityId: component.get('v.quote.OpportunityId'),
            origin: 'Quoting Page',
            status: 'New',
            description: description,
            isFromProServ: true,
            subject: helper.getSubjectForCase(component, type, isCancelledQuote),
            category: category,
            quoteApprovalId: quoteId,
            opportunityOwnerEmail: component.get('v.quote.Opportunity.Owner.Email'),
            partnerContact: component.get('v.quote.Account.Partner_Contact__c'),
            caseCategory: 'ProServ Quote Request',
            segment: component.get('v.quote.Opportunity.Owner.SegmentPicklist__c')
        };

        return JSON.stringify(caseParams);
    },

    getSubjectForCase: function (component, type, isCancelledQuote) {
        const prefix = type === this.PROSERV
            ? 'UC'
            : 'CC';
        const subject = isCancelledQuote
            ? `${prefix} Quote cancellation for ${component.get('v.quote.Account.Name')}`
            : `${prefix} Quote requested for ${component.get('v.quote.Account.Name')}`;

        return subject;
    }
});