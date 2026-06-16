({
    openModal: function(component, event, helper) {
        let wizard = component.get('v.Wizard');
        if (wizard.currentQuote.record.Special_Terms__c) {
            let creditAmount = wizard.currentQuote.record.Credit_Amount__c ? wizard.currentQuote.record.Credit_Amount__c : 0;
            let serviceTaxes = wizard.currentQuote.record.Free_Service_Taxes__c ? wizard.currentQuote.record.Free_Service_Taxes__c : 0;
            component.set('v.creditAmount', creditAmount);
            component.set('v.selectedTerm', wizard.currentQuote.record.Special_Terms__c);
            component.set('v.initialTerm', wizard.currentQuote.record.Special_Terms__c);
            component.set('v.serviceTaxes', serviceTaxes);
            component.set('v.annualFixedTaxes', wizard.currentQuote.record.Annual_Contact_Center_Fixed_Taxes__c);
            component.set('v.annualVariableTaxes', wizard.currentQuote.record.Annual_Contact_Center_Variable_Taxes__c);
            if (serviceTaxes) {
                let taxPerMonth = serviceTaxes / helper.getMonths(wizard.currentQuote.record.Special_Terms__c);
                component.set('v.responseTaxesPerMonth', taxPerMonth);
            }
        }
        component.set('v.initialContractTerm', wizard.currentQuote.record.Initial_Term_months__c);
        component.set('v.selectedContractTerm', wizard.currentQuote.record.Initial_Term_months__c);
        component.set('v.isModalOpen', true);
        helper.validateContractTerm(component, helper);
        helper.setAdditionalSpecialTermValues(component, helper, wizard);
    },
    
    closeModal: function(component, event, helper) {
        helper.closeModal(component);
    },
    
    submitChanges: function(component, event, helper) {
        helper.updateQuote(component, helper, false);
    },

    onChange: function(component, event, helper) {
        let selectedTerm = component.find('specialTermSelect').get('v.value');
        component.set('v.selectedTerm', selectedTerm);

        if (selectedTerm && component.get('v.isFirstChange') && selectedTerm !== component.get('v.initialTerm')) {
            helper.getTaxes(component, helper, selectedTerm, false);
            component.set('v.isFirstChange', false); 
        } else {
            helper.calculateOnChange(component, helper, selectedTerm);
        }
        helper.validateContractTerm(component, helper);
    },

    onChangeContractTerm: function(component, event, helper) {
        let selectedTerm = component.find('contractTermSelect').get('v.value');
        component.set('v.selectedContractTerm', selectedTerm);
        helper.validateContractTerm(component, helper);
    },

    showPopover: function(component, event, helper){
        var target = event.currentTarget;
        helper.showPopover(component, target);
    },

    hidePopover: function(){
        QW.popover.hide();
    },

    handleCreditAmountChanged: function(component, event, helper) {
        let wizard = component.get('v.Wizard');
        let initialCreditAmount = component.get('v.initialCreditAmount');

        if(!wizard.currentQuote || !wizard.currentQuote.record.Special_Terms__c) return;

        if(!component.get('v.initialCreditAmount') && wizard) {
            component.set('v.initialCreditAmount', wizard.currentQuote.record.Credit_Amount__c);
        } else if (initialCreditAmount !== wizard.currentQuote.record.Credit_Amount__c && !component.get('v.passCreditChange')) {
            helper.getTaxes(component, helper, wizard.currentQuote.record.Special_Terms__c, true);
        } else if (wizard.currentQuote.cartItems && wizard.currentQuote.cartItems.length === 0 && !component.get('v.passCreditChange')) {
            helper.updateQuote(component, helper, false, true);
        }
    }
})