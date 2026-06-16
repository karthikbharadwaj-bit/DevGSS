({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action=component.get("c.updateCase");
        action.setParams({
            "caseId":recId,
            "userId": userId,
			"buttonName":"Edit"             
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var result = response.getReturnValue();
                if(result != null && result != '' && result != undefined){
                    if(result == 'Success')
                    {
                        var editRecordEvent = $A.get("e.force:editRecord");
                        editRecordEvent.setParams({
                            "recordId": component.get("v.recordId")
                        });
                        
                        editRecordEvent.fire();
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
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})