({
    doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var action=component.get("c.getImplementationDetails");
        action.setParams({
            "recordid":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var wrapper = response.getReturnValue();
                if(wrapper != null && wrapper != '' && wrapper != undefined)
                {
                    var accid = wrapper.Account__c;
                    
                    //Creating record
                    var createRecordEvent = $A.get("e.force:createRecord");
                    createRecordEvent.setParams({
                        "entityApiName": 'Network_Information__c',
                        "defaultFieldValues":{
                            "Implementation__c" : recId,
                            "Account__c" : accid
                        }
                    });
                    createRecordEvent.fire();
                    
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