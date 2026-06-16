({
	doInit : function(component, event, helper) {
        var action=component.get("c.shareSyncAccount");
        action.setParams({
              "accountId":component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
             var state = response.getState();  
            if(state=='SUCCESS'){
                if(response.getReturnValue() != 'Error'){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({                
                    "message": response.getReturnValue(),
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
                }
                else if(response.getReturnValue() == 'Error'){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Your session has expired. Please log in again",
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