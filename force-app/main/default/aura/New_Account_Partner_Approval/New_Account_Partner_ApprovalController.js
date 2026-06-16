({
    doInit : function(component, event, helper) {
        let isVFpage = component.get('v.isVFpage');
        let action = component.get('c.checkPartnerAccount');

        action.setParams({ 
            accountId : component.get('v.recordId')
        });

        helper.showSpinner(component);
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue();
                if (result.isValid) {
                    component.set('v.currencyIsoCode', result.currencyIsoCode);
                    component.set('v.selectedApprovalRecType', result.approvalRecTypeName);
                } else {
                    if(isVFpage) {
                        helper.closeVFWindow(component, helper, result.message, 'warning');
                    } else {
                        helper.showToast('warning', result.message);
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
            } else if (state === 'ERROR') {
                let errors = response.getError();
                if (isVFpage) {
                    helper.closeVFWindow(component, helper, errors[0].message, 'error');
                } else {
                    helper.showToast('error', errors[0].message);
                    console.error(errors);
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
            helper.hideSpinner(component);
        }));
        $A.enqueueAction(action);
    },

    closeModal: function(component, event, helper) {
        if (component.get('v.isVFpage')) {
            helper.closeVFWindow(component, helper, '', '');
        } else {
            $A.get("e.force:closeQuickAction").fire();
        }
    },

    createApproval: function(component, event, helper) {
        let isVFpage = component.get('v.isVFpage');
        let recType = component.get('v.selectedApprovalRecType');

        let params = {
            accountId : component.get('v.recordId'),
            partnerMRR : component.get('v.partnerMRR'),
            approvalRecTypeName : recType
        }
        
        let action = component.get('c.createPartnerApproval');
        action.setParams({ 
            params: params
        });

        helper.showSpinner(component);
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let approvalId = response.getReturnValue();
                if (approvalId) {
                    let successMessage = recType + ' has been successfully created';
                    if (isVFpage) {
                        helper.closeVFWindow(component, helper, successMessage, 'success');
                    } else {
                        helper.showToast('success', successMessage);
                        helper.openInNewTab(component, approvalId);
                        $A.get('e.force:refreshView').fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
            } else if (state === 'ERROR') {
                let errors = response.getError();
                if (isVFpage) {
                    helper.closeVFWindow(component, helper, errors[0].message, 'error');
                } else {
                    helper.showToast('error', errors[0].message);
                    console.error(errors);
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
        }));
        $A.enqueueAction(action);
    }
})