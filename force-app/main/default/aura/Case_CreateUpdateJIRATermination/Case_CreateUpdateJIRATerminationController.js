({
	loadRecordValues : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var action=component.get("c.loadCase");
        action.setParams({
            "caseId":recId
        });
        
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var resultMessage = response.getReturnValue();
                if(resultMessage != null && resultMessage != '' && resultMessage != undefined)
                {
                    if(resultMessage.includes("Unable")){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": resultMessage,
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "success",
                            "title": "Success!",
                            "message": resultMessage,
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