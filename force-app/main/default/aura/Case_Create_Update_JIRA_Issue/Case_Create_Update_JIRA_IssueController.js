({
    loadRecordValues : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        //Calling method to get profile and jira value
        var action=component.get("c.loadUserAndCase");
        action.setParams({
            "userId": userId,
            "recordId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var wrapper = response.getReturnValue();
                if(wrapper != null && wrapper != '' && wrapper != undefined)
                {
                    var arr = wrapper.split("/");
                    var state = arr[0];
                    var message = arr[1];
                    if(message != 'Success')
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
                    $A.get('e.force:refreshView').fire();
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