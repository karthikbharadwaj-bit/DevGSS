({
    doInit : function(component, event, helper) {
        var action = component.get('c.checkPartnerFinanceRevenueApproval');
        var isVFpage = component.get('v.isVFpage');

        action.setParams({ approvalId : component.get('v.recordId') });
        helper.showSpinner(component);
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                let message = response.getReturnValue();
                if (message) {
                    if (isVFpage) {
                        helper.closeVFWindow(component, helper, message, 'warning');
                    } else {
                        helper.showToast('warning', message);
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
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

    rejectAction: function(component, event, helper) {
        helper.financeApprovalAction(component, helper, false);
    },

    approveAction: function(component, event, helper) {
        helper.financeApprovalAction(component, helper, true);
    }
})