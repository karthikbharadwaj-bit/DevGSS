({
    receiveInitialData : function(component){
        let action = component.get('c.getInitialData');
        action.setParams({ recordId : component.get('v.recordId'), partnerAccountId: component.get('v.partnerAccountId')});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let data = response.getReturnValue();
                component.set('v.payingContactsExists', data.payingContactsExists);
                component.set('v.partnerPayingContactsExists', data.partnerPayingContactsExists);
                component.set('v.partnerAccountId', data.partnerAccountId);
                component.set('v.payingContactId', data.payingContactId);
                component.set('v.partnerPayingContactId', data.partnerPayingContactId);
                component.set('v.isTaxExemptionAvailable', data.isTaxExemptionAvailable);
                component.set('v.isInvoiceApprovalRequestDisabled', data.isInvoiceApprovalRequestDisabled);
                component.set('v.showSEHelpText', data.showSEHelpText);
                this.redirectToConcreteApprovalType(component);
                component.set('v.recordTypesMap', data.recordTypesMap);
                this.controlRecordTypesRender(component, data.recordTypes);
            } else {
                console.log('>>>Can\'t get data');
            }
        });
        $A.enqueueAction(action);
    },

    controlRecordTypesRender: function(component, recordTypes) {
        const payingContactsExists = component.get('v.payingContactsExists');
        const partnerPayingContactsExists = component.get('v.partnerPayingContactsExists');
        const isTaxExemptionAvailable = component.get('v.isTaxExemptionAvailable');
        const isInvoiceApprovalRequestDisabled = component.get('v.isInvoiceApprovalRequestDisabled');
        const showSEHelpText= component.get('v.showSEHelpText');
        for (let option of recordTypes) {
            option.Disabled = false;
            option.Notification = '';
            if (isInvoiceApprovalRequestDisabled && option.Name === 'Invoicing Request') {
                option.Disabled = true;
                option.Notification = 'Please approve or delete KYC Approval';
            }

            if (!payingContactsExists && option.Name === 'Invoicing Request') {
                option.Disabled = true;
                option.Notification = 'Invoicing Request requires \"Accounts Payable\" Contact Role assigned on the Account';
            }
            
            if (showSEHelpText && option.Name === 'POC Account') {
                option.Disabled = true;
                option.Notification = 'This opportunity needs to have an SE log an activity/event as a Solutions Engineer (Primary) in order to access this button and initiate the GOA process with an SE Manager';
             }

            if ((!partnerPayingContactsExists || !payingContactsExists)
                && (option.Name === 'Invoice-on-behalf Request' || option.Name === 'Invoice Wholesale Request')
            ) {
                option.Disabled = true;
                option.Notification = `${option.Name} requires \"Accounts Payable\" Contact Role assigned on both, Customer's and Partner's Accounts`;
            }

            if (!isTaxExemptionAvailable && option.Name === 'Tax Exempt Approval') {
                option.Disabled = true;
                option.Notification = 'Tax Exemption is not available for this country';
            }
        }
        component.set('v.recordTypes', recordTypes);
    },

    redirectToConcreteApprovalType: function(component) {
        if (component.get('v.recTypeId') != null) {
            $A.enqueueAction(component.get('c.createApproval'));
        }
    },

})