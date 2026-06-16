({
	doInit : function(component, event, helper) {
		var action=component.get("c.getPhaseDetails");
        var recId = component.get("v.recordId");
        action.setParams({
              "phaseId":recId
        });
        action.setCallback(this, function(response){
            //$A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                console.log(retResponse);
                var regex = /admin/gi;
                var phase = retResponse.ph;
                console.log('phase>>'+phase);
                var hasError = false;
				if (!regex.test(retResponse.profileName)) 
                {
                    hasError = true;
                	var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Complete the Phase",
                    "message": "You don't have enough permissions to Complete the Phase",
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
                }
                if(phase.Completed_Date__c != null && phase.Completed_Date__c != '' && phase.RecordType.Name === 'ProServ Phase')
                {
                    hasError = true;
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "This phase is already completed",
                    "message": "Once a phase is completed no changes can be applied after that",
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
                }
                if((phase.Hardware_Line_Items__r == null || phase.Hardware_Line_Items__r == undefined) && phase.RecordType.Name === 'ProServ Phase')
                {
                    hasError = true;
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title":  "This phase can't be completed",
                    "message": "You need to have at least one Line Item on a Phase to proceed with it's completion",
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
                }
                if(hasError == false)
                {
                    component.set('v.displayConfirmMessage',true);
                }
                else
                {
                    $A.get("e.force:closeQuickAction").fire();
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
    handleConfirmation : function(component, event, helper) {
		var action=component.get("c.updatePhase");
        var recId = component.get("v.recordId");
        action.setParams({
              "phaseId":recId
        });
        action.setCallback(this, function(response){
            $A.get("e.force:closeQuickAction").fire();
            var state = response.getState();
            if(state=='SUCCESS'){
                var retResponse = response.getReturnValue();
                console.log(retResponse);
                if (retResponse == 'SUCCESS') 
                {
                	var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "success",
                    "title": "Complete Phase",
                    "message": "The Phase was completed. The page will be reloaded",
                    "mode":'dismissible'
                	});
                	toastEvent.fire();
                    setTimeout(location.reload(), 2000);
                }
				else
                {
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Locking Order was fallen",
                    "message": retResponse,
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
    closeModal : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
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