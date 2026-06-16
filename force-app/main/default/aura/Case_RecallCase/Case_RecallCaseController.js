({
     doInit : function(component, event, helper) {
        console.log("doInit");
        var recId = component.get("v.recordId");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action=component.get("c.recallCase");
        action.setParams({
            "caseId":recId,
            "userId": userId            
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var result = response.getReturnValue();
                console.log("result**" +result);
                if(result != null && result != '' && result != undefined){
                    if(result == 'Success')
                    {
                        component.set('v.displayConfirmMessage',true);
                        
                    }
                    else
                    {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": result,
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "There is some error while processing",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error while processing",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
    },
    closeModal : function(component, event, helper) {
        // $A.get("e.force:closeQuickAction").fire();
        var urlEvent = $A.get("e.force:navigateToURL");
        var caseId = component.get("v.recordId");
        urlEvent.setParams({
            "url": "/"+caseId
        });
        urlEvent.fire();
    },
    
    handleConfirmation : function(component, event, helper){
        var caseId = component.get("v.recordId");
        var user_Id = $A.get("$SObjectType.CurrentUser.Id");
        var action=component.get("c.updateCase");
        action.setParams({
            "caseId":caseId,
            "userId": user_Id            
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var message = response.getReturnValue();
                if(message != null && message != '' && message != undefined){
                    if(message.includes("success") )
                    {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "success",
                            "title": "Success!",
                            "message": message,
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                    else
                    {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": message,
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": "There is some error while processing",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error while processing",
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
        //component.set('v.displayConfirmMessage',false);
    }, 
	hideSpinner: function(component, event, helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        //component.set('v.displayConfirmMessage',true);
    }
})