({
    doInit : function(component, event, helper) {
        var device=$A.get("$Browser.formFactor");
        var action=component.get("c.getCase");
        var recId = component.get("v.recordId");
        action.setParams({
            "recordId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();  
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                if(retResponse != null && retResponse != undefined && retResponse != '')
                {
                    if(retResponse.Jeopardy_Code__c == null || retResponse.Jeopardy_Code__c == '')
                    {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": 'Jeopardy Code cannot be null to Complete Jeopardy section',
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                    else if(retResponse.Jeopardy_Code__c == "Completed" || retResponse.Jeopardy_Code__c == "Cancelled")
                    {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!",
                            "message": 'Jeopardy is already completed/cancelled',
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                    }
                        else if (retResponse.Status != "Work in Progress")
                        {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": 'Status should be Work in Progress',
                                "mode":'dismissible'
                            });
                            toastEvent.fire();                        
                        }
                    
                            else
                            {
                                if(device=="DESKTOP")
                                {
                                    var win = window.open('/apex/CompleteJeopardyPopup?id='+retResponse.Id, 'Popup','height=120,width=500,left=100,top=100,scrollbars=no, centerscreen=yes,toolbar=no,status=no');
                                    var timer = setInterval(function () {
                                        if (win.closed) {
                                            clearInterval(timer);
                                            window.location.reload(); // Refresh the parent page
                                        }
                                    }, 1000);
                                }
                                else
                                {
                                    var urlEvent = $A.get("e.force:navigateToURL");
                                    urlEvent.setParams({
                                        'url': '/apex/CompleteJeopardyPopup?id='+retResponse.Id
                                    });
                                    urlEvent.fire(); 
                               }


                               
                                
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