({
    setValues: function (component) {
        let isEngageLegalButtonDisabled = false;
        let tooltipMessages = [];
        let addCheckStatusMessage = false;
        if (component.get('v.isChangeOrder')) {
            let primaryQuoteApprovedStatus = component.get('v.primaryQuote')['Approved_Status__c'];
            if (!(primaryQuoteApprovedStatus === 'Approved' || primaryQuoteApprovedStatus === 'Not Required')) {
                isEngageLegalButtonDisabled = true;
                tooltipMessages.push('The primary quote is not approved');
            }
        }

        if (component.get('v.Wizard.opportunity.isHasDocuSignActiveEnvelopes')) {
            isEngageLegalButtonDisabled = true;
            tooltipMessages.push('Quote was sent for Signature already.');
            if (component.get('v.Wizard.opportunity.isAnyEnvelopeVoidPending')) {
                tooltipMessages.push('There is an envelope void pending');
                addCheckStatusMessage = true;
            }
        }

        if (component.get('v.Wizard.opportunity.isNewEnvelopePending')) {
            isEngageLegalButtonDisabled = true;
            tooltipMessages.push('There is a new envelope creation pending');
            addCheckStatusMessage = true;
        }
        let engageLegalTooltip = '';
        if (tooltipMessages.length > 0) {
            if (addCheckStatusMessage) {
                tooltipMessages.push('You can check status with "Manage DocuSign" button');
            }
            let list = RC.htmlUtils.createList(tooltipMessages);
            list.className = 'slds-list--dotted';
            engageLegalTooltip = '<b>You can\'t Engage Legal</b>' + list.outerHTML;
        }
        component.set('v.engageLegalTooltip', engageLegalTooltip);
        component.set('v.isEngageLegalButtonDisabled', isEngageLegalButtonDisabled);
    },

    /**
     * Show/Hide buttons
     * @param component
     */
    checkDisplaying: function(component) {
        component.find('engageLegalButton').set('v.show', this.isEngageLegalButtonShown(component));
        const showManagement = component.get('v.legalApprovalId') && component.get('v.Wizard.currentQuote.isSales');
        QW.cssUtils.toggleShow(component, 'legalEngagementManagementButtonContainer', showManagement);
    },

    /**
     * Determines whether Engage Legal Button is shown
     * @param component
     */
    isEngageLegalButtonShown: function(component) {
        var Wizard = component.get('v.Wizard');
        var state = component.get('v.state');

        if (!component.get('v.quote')) {
            return false;
        }
        if (!component.get('v.settings').userPermissions.EngageLegal) {
            return false;
        }

        if (Wizard.opportunity.isClosed || state.isDowngraded) {
            return false;
        }
        if (component.get('v.legalApprovalId')) {
            return false;
        }
        if (
            Wizard.currentQuote && (Wizard.currentQuote.isInvalid
            || (!Wizard.currentQuote.isSales && !component.get('v.settings').isTelus))
        ) {
            return false;
        }
        return !component.get('v.quotes').some(function(quote) {
            return quote.QuoteType__c === 'Agreement' && quote.Status === 'Active';
        });
    }
});