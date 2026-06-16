({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var createRecordEvent = $A.get("e.force:createRecord");
        var action=component.get("c.getContact");
        action.setParams({
            "OppId":recId
            
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
            var state = response.getState();
            if(state == "SUCCESS"){
                var OppObj = response.getReturnValue();
                console.log('Inside success' + OppObj+"/"+ OppObj.Id);
                var oppid = OppObj.Id;
                createRecordEvent.setParams({
                        "entityApiName": 'Quote',
                        "defaultFieldValues":{
                            "ContactId":OppObj.OpportunityContactRoles[0].ContactId,
                            "AccountId":OppObj.AccountId,
                            "Email":OppObj.OpportunityContactRoles[0].Contact.Email,
                            "OpportunityId":oppid
                        }
                    });
                    createRecordEvent.fire();
                
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