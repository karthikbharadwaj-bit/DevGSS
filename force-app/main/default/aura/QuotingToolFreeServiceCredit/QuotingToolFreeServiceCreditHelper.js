({
    getTaxes : function(component, helper, selectedTerm, isCartListUpdate) {
        var Wizard = component.get('v.Wizard');

        QW.spinner.show('Getting Taxes');
        var action = component.get("c.getFreeServiceTaxes");
        action.setParams({ quoteId : Wizard.currentQuote.record.Id });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var taxAmountWrapper = response.getReturnValue();
                component.set('v.responseTaxesPerMonth', (taxAmountWrapper.fixedTaxesAmount + taxAmountWrapper.variableTaxesAmount));
                component.set('v.annualFixedTaxes', +(taxAmountWrapper.fixedTaxesAmount * 12).toFixed(2));
                component.set('v.annualVariableTaxes', +(taxAmountWrapper.variableTaxesAmount * 12).toFixed(2));
                component.set('v.jsonResponse', taxAmountWrapper.jsonResponse);
                helper.calculateOnChange(component, helper, selectedTerm);

                if (isCartListUpdate) {
                    helper.updateQuote(component, helper, isCartListUpdate, false);
                }
                QW.spinner.hide();
            } else if (state === "ERROR") {
                component.set('v.selectedTerm', component.get('v.initialTerm'));
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to get Taxes',
                    details: response.getError()[0].message,
                    defaultTimeout: false
                }).fire();
                QW.spinner.hide();
            }
        });

        $A.enqueueAction(action);
    },

    calculateOnChange : function(component, helper, selectedTerm) {
        let quote = component.get("v.Wizard.currentQuote");
        let monthlyRevenue = 0;
        let months = selectedTerm.includes('Month') ? helper.getMonths(selectedTerm) : 0;

        monthlyRevenue = quote.record.Total_MRR_New__c;

        component.set("v.creditAmount", +(monthlyRevenue * months).toFixed(2));
        component.set("v.serviceTaxes", +(component.get("v.responseTaxesPerMonth") * months).toFixed(2));
    },

    getMonths : function(term) {
        let numberOfMonths = term.match(/\d+/);
        return (numberOfMonths ? parseInt(numberOfMonths[0]) : 0);
    },

    isZeroTaxes : function(component) {
        return (!component.get('v.annualVariableTaxes') && !component.get('v.annualFixedTaxes'));
    },

    updateQuote: function (component, helper, isCartListUpdate, isRemoveFSC) {
        var isContractTermChange = component.get('v.selectedTerm') === component.get('v.initialTerm') 
                                        && component.get('v.selectedContractTerm') !== component.get('v.initialContractTerm');
        var Wizard = component.get('v.Wizard');
        component.set('v.passCreditChange', true);
        var selectedTerm = isRemoveFSC ? '' : isCartListUpdate ? Wizard.currentQuote.record.Special_Terms__c : component.get("v.selectedTerm");
        var taxesResponse = selectedTerm ? component.get("v.jsonResponse") : '';
        var updatedQuote = {
            Id: Wizard.currentQuote.record.Id,
            Annual_Contact_Center_Fixed_Taxes__c: selectedTerm ? component.get("v.annualFixedTaxes") : 0,
            Annual_Contact_Center_Variable_Taxes__c: selectedTerm ? component.get("v.annualVariableTaxes") : 0,
            Free_Service_Taxes__c: selectedTerm ? component.get("v.serviceTaxes") : 0,
            Initial_Term_months__c: isRemoveFSC ?
                                        Wizard.billingQuote ?
                                            Wizard.billingQuote.record.Initial_Term_months__c ?
                                                Wizard.billingQuote.record.Initial_Term_months__c : "24"
                                            : "24"
                                        : component.get("v.selectedContractTerm"),
            Special_Terms__c: selectedTerm
        };

        if (!isContractTermChange) {
            updatedQuote.Taxes_Response__c = selectedTerm ? taxesResponse : '';
        }

        var callMethod = isRemoveFSC ? 'c.updateQuote' 
                                        : isContractTermChange ? 'c.updateQuote' : 'c.updateCC_FSC_QuoteWithQLIs';

        if (isRemoveFSC) {
            QW.spinner.show('Removing Free Service Credit from Quote');
        } else {
            QW.spinner.show('Saving Quote');
        }

        return QW.salesforce.request(component, callMethod, { updatedQuote: updatedQuote, jsonResponse: taxesResponse })
            .catch($A.getCallback(function (error) {
                console.error(error);
                $A.get("e.c:ToastEvent").setParams({
                    theme: 'error',
                    header: 'Failed to save Quote',
                    details: QW.salesforce.getResponseError(error),
                    defaultTimeout: false
                }).fire();
            }))
            .then($A.getCallback(function(){
                QW.spinner.show('Refreshing Free Service Credit');
                return QW.salesforce.request(component, 'c.getQuotes', {
                    opportunityId: Wizard.opportunity.record.Id
                })
            }))
            .then($A.getCallback(function(quotes) {
                /*
                    temporary fix, because some places using `v.quote`,
                    but here after getting of quotes we don't set them in v.quote
                */

                Wizard.setQuotes(quotes);
                Wizard.update();
                component.set('v.Wizard', Wizard);

                var quote = component.get('v.quote');
                var currentQuote = _.find(quotes, function(q) { return q.Id === quote.Id});
                    currentQuote && component.set('v.quote', currentQuote);

                if (!isRemoveFSC) {
                    component.set('v.initialCreditAmount', component.get('v.Wizard.currentQuote.record.Credit_Amount__c'));
                }

                helper.closeModal(component);
                QW.spinner.hide();
            }));
    },

    closeModal: function(component, event, helper) {
        component.set('v.creditAmount', 0);
        component.set('v.responseTaxesPerMonth', 0);
        component.set('v.serviceTaxes', 0);
        component.set('v.annualFixedTaxes', 0);
        component.set('v.annualVariableTaxes', 0);
        component.set('v.selectedTerm', '');
        component.set('v.initialTerm', '');
        component.set('v.isModalOpen', false);
        component.set('v.passCreditChange', false);
        component.set('v.isFirstChange', true);
        component.set('v.additionalSpecialTerms', []);
    },

    showPopover: function(component, target) {
        var Wizard = component.get('v.Wizard');
        var messages = [];

        if (target.getAttribute("data-name") == 'fsc') {
            if (component.get('v.isCartChanged')) {
                messages.push({
                    header: "Can't add/modify Free Servise Credit",
                    text: 'Free Service Credit cannot be added/modified when there are unsaved changes in the Cart.',
                    iconTheme: 'info'
                });
            }
        } else {
            if (Wizard.currentQuote.isActiveAgreement) {
                messages.push({
                    header: "Can't add/modify Free Servise Credit",
                    text: 'Free Service Credit cannot be added/modified when Active Sales Agreement',
                    iconTheme: 'info'
                });
            }  else if (Wizard.opportunity.isClosed){
                messages.push({
                    header: "Can't add/modify Free Servise Credit",
                    text: 'Free Service Credit cannot be added/modified when Opportunity is Closed',
                    iconTheme: 'info'
                });
            }
        }

        // Show popover
        if (target && messages.length > 0){
            QW.popover.show(target, messages);
        }
    },

    validateContractTerm : function (component, helper) {
        let specialTerm = component.get('v.selectedTerm');
        let specialTermMonths = (specialTerm && specialTerm.includes('Month')) ? helper.getMonths(specialTerm) : 0;
        let contractTerm = component.get('v.selectedContractTerm');
        if (specialTerm && !contractTerm) {
            component.set('v.validationError', true);
            component.set('v.validationMessage', 'Contract Term must be 12 months or greater');
        } else if (specialTermMonths > contractTerm) {
            component.set('v.validationError', true);
            component.set('v.validationMessage', 'Special Terms can\'t be more than Contract Terms');
        } else {
            component.set('v.validationError', false);
            component.set('v.validationMessage', '');
        }
    },

    setAdditionalSpecialTermValues : function (component, helper, wizard) {
        let currentSpecialTerm = wizard.currentQuote.record.Special_Terms__c;
        let currentMonths = (currentSpecialTerm && currentSpecialTerm.includes('Month')) ? helper.getMonths(currentSpecialTerm) : 0;
        let defaultSpecialTermMonths = component.get('v.defaultSpecialTermMonths');

        let upTo12 = wizard.settings.userPermissions.Extended_Special_Terms;
        let upTo24 = wizard.settings.userPermissions.Extended_Special_Terms_Up_to_24;
        let freeMonths = ' Free Months of Service';
        let additionalSpecialTerms = component.get('v.additionalSpecialTerms');
        let additionalSpecialTermMonths = [];

        if (upTo12 || upTo24) {
            component.get('v.specialTermMonthsUpTo12').forEach(element => {
                additionalSpecialTerms.push({
                    label : element + freeMonths,
                    value : element + freeMonths
                });
            });
            additionalSpecialTermMonths = additionalSpecialTermMonths.concat(component.get('v.specialTermMonthsUpTo12'));
        } 
        
        if (upTo24) {
            component.get('v.specialTermMonthsUpTo24').forEach(element => {
                additionalSpecialTerms.push({
                    label : element + freeMonths,
                    value : element + freeMonths
                });
            });
            additionalSpecialTermMonths = additionalSpecialTermMonths.concat(component.get('v.specialTermMonthsUpTo24'));
        }

        if (!defaultSpecialTermMonths.includes(currentMonths) && !additionalSpecialTermMonths.includes(currentMonths) && currentSpecialTerm) {
            additionalSpecialTerms.push({
                label : currentSpecialTerm,
                value : currentSpecialTerm
            });
        }

        component.set('v.additionalSpecialTerms', additionalSpecialTerms);
    }
})