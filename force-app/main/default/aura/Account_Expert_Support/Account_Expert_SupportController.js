({
    doInit : function(component, event, helper) {
    
        var recid=component.get("v.recordId");
        var createRecordEvent = $A.get("e.force:createRecord");
               createRecordEvent.setParams({
            "entityApiName": 'Marketing_Support_Request__c',
            "defaultFieldValues":{
                 "Account__c":recid
            }
        });
        createRecordEvent.fire();
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