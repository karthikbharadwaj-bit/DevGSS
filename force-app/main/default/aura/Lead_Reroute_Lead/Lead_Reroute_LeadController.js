({
	doInit : function(component, event, helper) {
        var action=component.get("c.rerouteRecord");
        action.setParams({
              "recordId":component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
             var state = response.getState();  
            if(state=='SUCCESS'){
                if(response.getReturnValue() == 'Success'){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Rerouted Successfully.",
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
            $A.get('e.force:refreshView').fire();
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