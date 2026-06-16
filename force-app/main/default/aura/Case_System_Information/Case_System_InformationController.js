({
	doInit : function(component, event, helper) {
        var action=component.get("c.fetchCaseCreatedByFields");
        var recId = component.get("v.recordId");
        
        action.setParams({
            "caserecId":recId
            
        });
        action.setCallback(this, function(response){
            var state = response.getState();  
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                
                if(!retResponse || retResponse != 'null' || retResponse != 'undefined')
                {
                    
					component.set("v.caseRec" , retResponse);
                    component.set("v.createdBy" , retResponse.CreatedById);
                    component.set("v.lastModifiedby" , retResponse.LastModifiedById);
                    component.set("v.createdByDate" , retResponse.CreatedDate);
                    component.set("v.lastModifiedbyDate" , retResponse.LastModifiedDate);
                }
                else
                {
                    toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error while processing",
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
                    "title": "Error!",
                    "message": "There is some error while processing",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
    },
    
    navigateTocreatedBy: function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        console.log(component.get("v.createdBy"));
        navEvt.setParams({
            "recordId": component.get("v.createdBy")
        });
        navEvt.fire();
        
    },
    
    navigateTolastModifiedBy: function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.lastModifiedby")
        });
        navEvt.fire();
        
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