({
    doInit : function(component, event, helper) {
        var action=component.get("c.readyForSignature");
        var recId = component.get("v.recordId");
        action.setParams({
            "recordId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();  
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                if(!retResponse || retResponse.length == 0)
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "message": "Legal Engagement was completed. Refreshing the page...",
                        "mode":'dismissible'
                    });
                    toastEvent.fire(); 
                    window.setTimeout(
                        $A.getCallback(function() {
                            $A.get('e.force:refreshView').fire();
                        }), 3000
                    );
                    
                }
                else
                {
                    var errormsg = retResponse;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Unable to complete Legal Engagement",
                        "message": errormsg,
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
            else if (state === "ERROR"){
                var errors = response.getError();
                var toastEvent = $A.get("e.force:showToast");
                var errormessage;
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                        errormessage =  errors[0].message;
                    }
                } else {
                    errormessage = "Unknown error";
                }
                toastEvent.setParams({
                    "type": "error",
                    "title": "Unable to complete Legal Engagement",
                    "message": errormessage,
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
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})