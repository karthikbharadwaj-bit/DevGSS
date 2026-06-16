({
	doInit : function(component, event, helper) {
        var action=component.get("c.upgradeLead");
        action.setParams({
              "LeadID":component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
             var state = response.getState();  
            if(state=='SUCCESS'){
                if(response.getReturnValue() == 'SUCCESS'){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Lead Upgraded successfully.",
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
                }
                else if(response.getReturnValue() == 'Error'){
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There was some error during lead upgrade processing",
                    "mode":'dismissible'
                	});
                toastEvent.fire();
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Cannot 'Upgrade' an active lead. Click 'Convert Lead' to create an Opportunity.",
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