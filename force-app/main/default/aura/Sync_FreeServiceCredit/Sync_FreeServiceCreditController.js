({
    doInit : function(component, event, helper) {
        var action = component.get('c.reSyncFSCButton');

        action.setParams({ orderId : component.get('v.recordId') });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue();
                if (result.status === 'success') {
                    helper.showToast(result.status, result.message);
                    $A.get('e.force:refreshView').fire();
                } else {
                    helper.showToast(result.status, result.message);
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