({
    closeModal : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    handleConfirmation : function(component, event, helper) {
        var action=component.get("c.deOwn");
        action.setParams({
            "accId":component.get("v.recordId")
            
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
            if(state == "SUCCESS"){
                if(response.getReturnValue() == 'success'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": "You have Unclaimed Account successfully, the page will be reloaded",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                    window.location.reload();
                }
                else if(response.getReturnValue() == 'owner'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "You are not allowed to UnClaim this Account.",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
                else if(response.getReturnValue() == 'error'){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Current owner can be removed only for sold Channel accounts.",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": response.getReturnValue(),
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
            }
            else
            {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": 'There is some error while processing',
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        component.set('v.displayConfirmMessage',false);
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        component.set('v.displayConfirmMessage',true);
    }
})