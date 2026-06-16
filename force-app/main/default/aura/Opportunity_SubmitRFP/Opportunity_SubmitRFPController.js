({
	doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var action=component.get("c.getOpportunityDetail");
        action.setParams({
            "opportunityId":recId            
        });
        action.setCallback(this, function(response){
            var state = response.getState();  
            if(state=='SUCCESS'){
                var res = response.getReturnValue();
                console.log('opp name - '+ res.Name);                
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Marketing_Support_Request__c",
                    "defaultFieldValues": {
                        'Opportunity__c' : recId
                    }
                });
                createRecordEvent.fire();
            }
        })
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