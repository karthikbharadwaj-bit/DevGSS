({
    fetchListOfRecordTypes: function(component, event, helper) {
        var action = component.get("c.fetchRecordTypeValues");
        
        action.setCallback(this, function(response) {
            var recordtypes = response.getReturnValue();
            component.set("v.lstOfRecordType",recordtypes );
            component.find("recordTypeId").set("v.value", recordtypes[0]);
        });
        $A.enqueueAction(action);
    },
    
    
    createRecord: function(component, event, helper){      
        
        component.set("v.isOpen", false);
        var action = component.get("c.getRecTypeId");
        var recordTypeLabel = component.find("recordTypeId").get("v.value");
        action.setParams({
            "recordTypeLabel": recordTypeLabel
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var retResponse  = response.getReturnValue();
                var recordType = retResponse.recordTypeID;
                var accountId = component.get("v.pageReference").state.c__accid;
                var incontactId = component.get("v.pageReference").state.c__incontactid;
                var caseRecord = {};
                if(retResponse.accountId_access){
                    caseRecord.AccountId = accountId ? accountId : null ;
                }
                
                if(retResponse.contactId_access){
                    caseRecord.ContactId =  incontactId  ? incontactId : null;
                }
                
                
                
                var createRecordEvent = $A.get("e.force:createRecord");
                
                createRecordEvent.setParams({
                    "entityApiName": 'Case',
                    "recordTypeId": recordType,
                    'defaultFieldValues': caseRecord
                });
                createRecordEvent.fire();
                
            } else if (state == "ERROR") {
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
                    "title": "Credit Approval Error",
                    "message": errormessage,
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    },
    
    closeModal: function(component, event, helper) {
        // set "isOpen" attribute to false for hide/close model box 
        component.set("v.isOpen", false);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            'url': '/apex/GccSmartSearch'
        });
        urlEvent.fire();
        $A.get('e.force:refreshView').fire();
        
    }
    
})