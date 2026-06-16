({
    doInit : function(component, event, helper) {
        var action=component.get("c.downgradeOpp");
        action.setParams({
            "optyId":component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire(); 
            var state = response.getState();  
            var returnValue = response.getReturnValue();
            if(state=='SUCCESS'){
                if(returnValue.responseMessage == 'Redirect'){
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/apex/DowngradeWizardV2?wizardType=Downgrade&oppId="+component.get("v.recordId")+"&validationType="+returnValue.validationType+"&requiredFields="+JSON.stringify(returnValue.missingFields),
                        "isredirect": "true"
                    });
                    urlEvent.fire();
                }
                else if(returnValue.responseMessage == 'Success'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "success",
                        "title": "Success!",
                        "message": 'Opportunity downgraded successfully!',
                        "mode":'dismissible'
                    });
                    $A.get('e.force:refreshView').fire();
                    toastEvent.fire();
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": response.getReturnValue().responseMessage,
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