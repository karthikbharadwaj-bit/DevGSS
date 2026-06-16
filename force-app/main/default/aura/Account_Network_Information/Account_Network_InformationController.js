({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": 'Network_Information__c',
            "defaultFieldValues":{
                "Account__c" : recId
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