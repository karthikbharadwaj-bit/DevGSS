({
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },

    showSpinner: function(component) {
        component.set("v.spinner", true);
    },

    hideSpinner : function(component) {
        component.set("v.spinner", false);
    },

    financeApprovalAction : function (component, helper, isApproveAction) {
        var action = component.get('c.handlePartnerFinanceRevenueAction');
        let rejectionComment = component.get('v.rejectionComment');
        var isVFpage = component.get('v.isVFpage');
        
        action.setParams({ 
            approvalId : component.get('v.recordId'),
            isApproveAction : isApproveAction,
            rejectionComment : rejectionComment
        });

        helper.showSpinner(component);
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                if (isApproveAction) {
                    let approveMessage = 'Bill on Behalf Approval has been successfully Approved';
                    if (isVFpage) {
                        helper.closeVFWindow(component, helper, approveMessage, 'success');
                    } else {
                        helper.showToast('success', approveMessage);
                        $A.get('e.force:refreshView').fire();
                    }
                } else {
                    let ownerName = response.getReturnValue();
                    let rejectMessage = 'Email notification was sent to ' + ownerName;
                    if (isVFpage) {
                        helper.closeVFWindow(component, helper, rejectMessage, 'success');
                    } else {
                        helper.showToast('success', rejectMessage);
                    }
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (isVFpage) {
                    helper.closeVFWindow(component, helper, errors[0].message, 'error');
                } else {
                    helper.showToast('error', errors[0].message);
                    console.error(errors);
                }
            }
            if (!isVFpage) {
                $A.get("e.force:closeQuickAction").fire();
            }
        }));
        $A.enqueueAction(action);
    },

    closeVFWindow : function (component, helper, message, type) {
        var vfMethod = component.get("v.vfCloseWindow");
        vfMethod(message, type, function(){});
    }
})