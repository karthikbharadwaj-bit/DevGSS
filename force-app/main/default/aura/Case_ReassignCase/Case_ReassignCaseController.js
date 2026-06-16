({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action=component.get("c.updateCase");
        action.setParams({
            "caseId":recId,
            "userId": userId,
            "buttonName":"Reassign"            
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var result = response.getReturnValue();
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
        $A.get("e.force:closeQuickAction").fire();
    },
    handleConfirmation : function(component, event, helper){
        var recId = component.get("v.recordId");
        var url = '/apex/OpsAssignCase?id=' + recId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
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