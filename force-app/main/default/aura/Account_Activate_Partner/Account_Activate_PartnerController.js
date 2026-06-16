({

    handleClickYes: function(component, event, helper) {        
        var action=component.get("c.activatePartnerAccount");
        var accountId = component.get("v.recordId");
        action.setParams({
            "recordId":accountId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();  
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                if(!retResponse || retResponse.length == 0)
                {
                    
                    $A.get('e.force:refreshView').fire();

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "message": "Partner is activated",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                       
                }
                else
                {
                    var errormsg = retResponse;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
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

    closeModal: function(component, event, helper) {  
        $A.get("e.force:closeQuickAction").fire();
    },

    showSpinner: function(component) {
        component.set("v.spinner", true);
    },

    hideSpinner : function(component){ 
        component.set("v.spinner", false);
    }
})