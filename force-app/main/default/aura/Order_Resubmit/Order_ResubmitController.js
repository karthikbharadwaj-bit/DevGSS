({
    doInit : function(component, event, helper) {
        var action = component.get('c.resubmitOrder');

        action.setParams({ orderId : component.get('v.recordId') });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                if (response.getReturnValue()) {
                    helper.showToast('success', 'The Order has been updated successfully.');
                    $A.get('e.force:refreshView').fire();
                } else {
                    helper.showToast('warning', 'The Order is not Rejected.');
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                console.error(errors);
            }
            $A.get("e.force:closeQuickAction").fire();
        }));
        $A.enqueueAction(action);
    },

    showSpinner: function(component, event, helper) {  
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function(component,event,helper){   
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");    
    }
})