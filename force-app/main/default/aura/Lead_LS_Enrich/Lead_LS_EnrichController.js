({
	closeModal : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	},
    handleLSEnrich : function(component, event, helper) {
        var action = component.get('c.enrichLead');
        action.setParams({"leadId" : component.get('v.recordId')});
        action.setCallback(this,function(response){
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS")
            {
                var responseReceived = response.getReturnValue(); 
                if(responseReceived != null && responseReceived != undefined)
                {
                    if(responseReceived.response == false)
                    {
                        if(!((responseReceived.l.FirstName != null || responseReceived.l.LastName != null) && responseReceived.l.Company != null))
                        {
                            //Enrichment not done.Please provide either First Name or Last Name, Email and Company Name then enrich again.
                        	var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Enrichment not done.Please provide either First Name or Last Name, Email and Company Name then enrich again.",
                                "mode":'dismissible'
                            });
                            toastEvent.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        }
                        else
                        {
                            //Unable to enrich data from LeadSpace.
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Unable to enrich data from LeadSpace.",
                                "mode":'dismissible'
                            });
                            toastEvent.fire();
                            $A.get("e.force:closeQuickAction").fire();
                        }
                    }
                    else if(responseReceived.response == true)
                    {
                        //Lead enrichment was successful. Page will be reloaded.
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "success",
                            "title": "Success!",
                            "message": "Lead enrichment was successful. Page will be reloaded.",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                }
            }
            else
            {
                //Unable to enrich data from LeadSpace.
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "Unable to enrich data from LeadSpace.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        },'SUCCESS');
        $A.enqueueAction(action,false);
	},
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        component.set('v.displayButtons',false);
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        component.set('v.displayButtons',true);
    }
})