({
    doInit : function(component, event, helper) {
        var action=component.get("c.getopprecord");
        var recid=component.get("v.recordId");
        action.setParams({
            "recordid":recid
            
        });
        action.setCallback(this, function(response){
      
            var state = response.getState();
            if(state == "SUCCESS"){
                var opprec  = response.getReturnValue();
              var createRecordEvent = $A.get("e.force:createRecord");
               createRecordEvent.setParams({
            "entityApiName": 'Marketing_Support_Request__c',
             "recordTypeId": '0122H000000YNYYQA4',
            "defaultFieldValues":{
                "Opportunity__c" : recid,
                "Account__c":opprec.AccountId,
                "Name":opprec.Name,
                "Due_Date__c":opprec.CreatedDate
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