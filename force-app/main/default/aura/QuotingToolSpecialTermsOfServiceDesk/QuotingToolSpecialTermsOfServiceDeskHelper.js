({
    checkButtonsDisabling: function(component) {
        var quote = component.get('v.quote');
        var user = component.get('v.user');
        var quotes = component.get('v.quotes');
        var enterpriseDealRequestButton = component.find('enterpriseDealRequestButton');
        var enterpriseDealRequest = component.find('enterpriseDealRequest');
        var effectiveNoOfEmployeesRange = component.get('v.effectiveNoOfEmployeesRange');
        var stageName = component.get('v.stageName');
        var enterpriseDealRequestButtonVisible = false;
        var readOnly = false;
        var tooltipText = '';
        var enterpriseDealRequestButtonDisabled = true;
        var recallButtonVisible = false;
		
        component.set('v.readOnly', readOnly);

        if (user) {

            // "Effective No. of Employees (Range)" field on the Opportunity(Account) is "250-999" or "1000+".
            if(effectiveNoOfEmployeesRange === '250-999' || effectiveNoOfEmployeesRange === '1000+'){
                enterpriseDealRequestButtonVisible = true;
            }

            if (quote) {
                // component.set('v.typeDefined', !!quote.Special_TOS_Approval__c);
                // if(quote.Special_TOS_Approval__c){
                //     readOnly = true;
                // } else {
                //     readOnly = false;
                // }
            } else if (quotes.length === 0) {
                tooltipText = 'At least one Quote is required in order to create Enterprise Deal&nbsp;Request.';
            } else {
                tooltipText = 'Approval for an Enterprise Deal can be submitted only from the Primary&nbsp;Quote';
            }
        }

        component.set('v.readOnly', readOnly);
        component.set('v.enterpriseDealRequestButton.disabled', enterpriseDealRequestButtonDisabled);
        component.set('v.tooltipText', tooltipText);
        component.set('v.recallButtonVisible', recallButtonVisible);

        if (enterpriseDealRequestButtonVisible) {
            $A.util.removeClass(enterpriseDealRequest, 'slds-hide');
        } else {
            $A.util.addClass(enterpriseDealRequest, 'slds-hide');
        }
    },
    validate: function(component) {
        var valid = true;
        var askByCustomer = component.get('v.askByCustomer');
        if (!askByCustomer) {
            var askByCustomerContainer = component.find('askByCustomerContainer');
            var askByCustomerEl = component.find('askByCustomer');
            askByCustomerEl.set('v.errors', [{ message: "This field is required" }]);
            $A.util.addClass(askByCustomerContainer, "slds-has-error");
            valid = false;
        }

        if (!component.find('trialPeriod').get('v.validity').valid) {
            valid = false;
        }

        var legalAccountName = component.get('v.legalAccountName');
        if (!legalAccountName){
            var legalAccountNameContainer = component.find('legalAccountNameContainer');
            var legalAccountNameEl = component.find('legalAccountName');
            legalAccountNameEl.set('v.errors', [{ message: "This field is required" }]);
            $A.util.addClass(legalAccountNameContainer, "slds-has-error");
            valid = false;
        }

        var legalEngagementType = component.get('v.legalEngagementType');
        if (!legalEngagementType) {
            var legalEngagementTypeContainer = component.find('legalEngagementTypeContainer');
            var legalEngagementTypeEl = component.find('legalEngagementType');
            legalEngagementTypeEl.set('v.errors', [{ message: "This field is required" }]);
            $A.util.addClass(legalEngagementTypeContainer, "slds-has-error");
            valid = false;
        }

        return valid;
    },
    setValues: function(component) {
        var quote = component.get('v.quote');

        var addOnsValues = component.get('v.addOnsValues');
        var accomodationValues = component.get('v.accomodationValues');
        var featureAddOnsValues = component.get('v.featureAddOnsValues');
        var contractLink = component.get('v.contractLink');

        String.prototype.replaceAll = function(search, replacement) {
            var target = this;
            return target.split(search).join(replacement);
        };

        if(addOnsValues){
            addOnsValues.forEach(function (el) {
                el.value = el.value.replaceAll('&lt;', '<');
                el.label = el.label.replaceAll('&lt;', '<');
                el.value = el.value.replaceAll('&amp;', '&');
                el.label = el.label.replaceAll('&amp;', '&');
                el.value = el.value.replaceAll('&gt;', '>');
                el.label = el.label.replaceAll('&gt;', '>');
            });
        }
        if(accomodationValues){
            accomodationValues.forEach(function (el) {
                el.value = el.value.replaceAll('&lt;', '<');
                el.label = el.label.replaceAll('&lt;', '<');
                el.value = el.value.replaceAll('&amp;', '&');
                el.label = el.label.replaceAll('&amp;', '&');
                el.value = el.value.replaceAll('&gt;', '>');
                el.label = el.label.replaceAll('&gt;', '>');
            });
        }
        if(featureAddOnsValues){
            featureAddOnsValues.forEach(function (el) {
                el.value = el.value.replaceAll('&lt;', '<');
                el.label = el.label.replaceAll('&lt;', '<');
                el.value = el.value.replaceAll('&amp;', '&');
                el.label = el.label.replaceAll('&amp;', '&');
                el.value = el.value.replaceAll('&gt;', '>');
                el.label = el.label.replaceAll('&gt;', '>');
            });
        }

        // var askByCustomer = '';
        // var legalEngagementType = '';
        // var accommodations = '';
        // var addOns = '';
        // var featureAddOns = '';

        // if (quote && quote.Special_TOS_Approval__c) {
        //     askByCustomer = quote.Special_TOS_Approval__r.Ask_By_Customer__c;
        //     legalEngagementType = quote.Special_TOS_Approval__r.Type__c;
        //     accommodations = quote.Special_TOS_Approval__r.Accomodations__c;
        //     addOns = quote.Special_TOS_Approval__r.Add_ons__c;
        //     featureAddOns = quote.Special_TOS_Approval__r.Feature_Add_ons__c;
        //     contractLink = quote.Special_TOS_Approval__r.Contract_Link__c;

        //     if(accommodations){
        //         accommodations = accommodations.replaceAll('&lt;', '<');
        //         accommodations = accommodations.replaceAll('&lt;', '<');
        //         accommodations = accommodations.replaceAll('&lt;', '<');
        //     }
        //     if (addOns) {
        //         addOns = addOns.replaceAll('&amp;', '&');
        //         addOns = addOns.replaceAll('&amp;', '&');
        //         addOns = addOns.replaceAll('&amp;', '&');
        //     }
        //     if (featureAddOns) {
        //         featureAddOns = featureAddOns.replaceAll('&gt;', '>');
        //         featureAddOns = featureAddOns.replaceAll('&gt;', '>');
        //         featureAddOns = featureAddOns.replaceAll('&gt;', '>');
        //     }
        // }

        if(addOnsValues){
            component.set('v.addOnsValues', addOnsValues);
        }
        if(accomodationValues){
            component.set('v.accomodationValues', accomodationValues);
        }
        if(featureAddOnsValues){
            component.set('v.featureAddOnsValues', featureAddOnsValues);
        }
        // component.set('v.askByCustomer', askByCustomer);
        // component.set('v.legalEngagementType', legalEngagementType);
        // component.set('v.accommodations', accommodations);
        // component.set('v.addOns', addOns);
        // component.set('v.featureAddOns', featureAddOns);
        // component.set('v.contractLink', contractLink);
    },
    discardValues: function(component){
        component.set('v.legalEngagementType', '');
        component.set('v.addOns', '');
        component.set('v.accommodations', '');
        component.set('v.featureAddOns', '');
        component.set('v.legalAccountName', '');
        component.set('v.changeOrderTypes', '');
        component.set('v.contractLink', '');
        component.set('v.trialPeriod', '');
        component.set('v.askByCustomer', '');
    },

    submitForApproval: function(component) {
        var quote = component.get('v.quote');

        // var approvalId = quote.Special_TOS_Approval__c;
        var askByCustomer = component.get('v.askByCustomer') ? component.get('v.askByCustomer').toString() : '';
        var legalEngagementType = component.get('v.legalEngagementType') ? component.get('v.legalEngagementType').toString() : '';
        var legalAccountName = component.get('v.legalAccountName') ? component.get('v.legalAccountName').toString() : '';
        var trialPeriod = component.get('v.trialPeriod') ? component.get('v.trialPeriod').toString() : '';
        var addOns = component.get('v.addOns') ? component.get('v.addOns').toString() : '';
        var accommodations = component.get('v.accommodations') ? component.get('v.accommodations').toString() : '';
        var featureAddOns = component.get('v.featureAddOns') ? component.get('v.featureAddOns').toString() : '';
        var changeOrderTypes = component.get('v.changeOrderTypes') ? component.get('v.changeOrderTypes').toString() : '';
        var contractLink = component.get('v.contractLink');

        console.log('addOns >> ', addOns);
        console.log('accommodations >> ', accommodations);
        console.log('featureAddOns >> ', featureAddOns);
        console.log('changeOrderTypes >> ', changeOrderTypes);

        var params = {
            quoteId: quote.Id,
            askByCustomer: askByCustomer,
            legalEngagementType: legalEngagementType,
            legalAccountName: legalAccountName,
            trialPeriod: trialPeriod,
            addOns: addOns,
            accommodations: accommodations,
            featureAddOns: featureAddOns,
            changeOrderTypes: changeOrderTypes,
            contractLink: contractLink
        };

        var defaultTimeout = false;
        var toasters = {
            success: {
                theme: 'success',
                header: 'Your Engage Legal Request has been sent to your Manager for Approval.',
                details: 'Once Approved it will be sent to the Legal Group.',
                defaultTimeout: defaultTimeout
            },
            error: {
                theme: 'error',
                header: 'Oops! An error has occured.',
                details: '',
                defaultTimeout: defaultTimeout
            }
        };

        var action = component.get("c.submitSpecialToSApprovalRequest");
        action.setParams({ params: params });
        action.setCallback(this, function(actionResult) {
            var toast;
            if (component.isValid() && actionResult.getState() === "SUCCESS") {
                var newQuote = actionResult.getReturnValue();
                component.set('v.quote', newQuote);
                $A.get("e.c:QuoteingToolNewLegalApprovalEvent").setParams({ legalApprovalId: newQuote.Special_TOS_Approval__c }).fire();
                toast = toasters.success;
            } else {
                toast = toasters.error;
                toast.details = actionResult.getError()[0].message;
            }
            component.set('v.isBusy', false);
            this.modalClose(component);

            $A.get("e.c:ToastEvent").setParams(toast).fire();
        });
        component.set('v.isBusy', true);
        $A.enqueueAction(action);
    },
    modalOpen: function(component) {
        var modal = component.find('modal');
        var modalBg = component.find('legal-name-modal-bg');
        $A.util.addClass(modalBg, 'slds-backdrop--open');
        $A.util.addClass(modal, 'slds-fade-in-open');
        $A.util.removeClass(modal, 'slds-hide');
        // BUG: not working without timeout
        // TODO: find workaround for locker service
        setTimeout($A.getCallback(function() {
            if (component.isValid()) {
                var briefOverviewInput = component.find('askByCustomer').getElement();
                if (briefOverviewInput) {
                    briefOverviewInput.getElementsByTagName('textarea')[0].focus();
                }
            }
        }));
    },
    modalClose: function(component) {
        var modal = component.find('modal');
        var modalBg = component.find('legal-name-modal-bg');
        $A.util.removeClass(modalBg, 'slds-backdrop--open');
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-hide');
    },
    recall: function(component) {
        var quote = component.get('v.quote');
        var params = {
            action: 'Removed',
            quoteId: quote.Id,
            comment: 'Recalled from Quoting Wizard'
        };
        var action = component.get("c.setApprovalAction");
        action.setParams({ params: params });
        action.setCallback(this, function(actionResult) {
            if (component.isValid() && actionResult.getState() === "SUCCESS") {
                var newQuote = actionResult.getReturnValue();
                component.set('v.quote', newQuote);
            }
            component.set('v.isBusy', false);
            this.modalClose(component);
        });
        component.set('v.isBusy', true);
        $A.enqueueAction(action);
    },
    /**
     * Show/hide elements depending on user
     *      - B-897 Quote Wizard Changes for Relayware
     */
    checkUserAccess: function(component){
        var user = component.get('v.user');
        var enterpriseDealRequest = component.find('enterpriseDealRequest');
        if (user && user.Profile && user.Profile.Name === 'API Relayware V2') {
            $A.util.addClass(enterpriseDealRequest,'relayware--disable');
        } else {
            $A.util.removeClass(enterpriseDealRequest,'relayware--disable');
        }
    }
});