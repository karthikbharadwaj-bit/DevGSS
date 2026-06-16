({
    setup : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var action=component.get("c.getApproval");
        action.setParams({
            "recordId":recId
            
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS"){
                console.log("INSIDE SUCCESS");
                var appobj = response.getReturnValue();
                var rcnotify= this._rcnotify;
                if(appobj.Account__r.RC_User_ID__c == null || appobj.Account__r.RC_User_ID__c == '')
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Cannot process refunds",
                        "message": "The Enterprise Account ID on the Related Account should be populated to process refunds",
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                }
                else{
                    rcnotify.showSpinner();
                    helper.getCustomSettingValue(component, event, helper);
                    if(component.get("v.newPSRFlag") != "CUSTOMERROR"){
                        helper.processdatafunc(component, event, helper, rcnotify);
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": "Refund Management is not available",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();  
                    }
                    
                }
            }
            
        });
        $A.enqueueAction(action);
    },
    
    
    
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    hideSpinner : function(component, event, helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})