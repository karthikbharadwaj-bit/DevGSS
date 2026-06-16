({
		doInit : function(component, event, helper) {
            var recId = component.get("v.recordId");
        	var action=component.get("c.getCase");
        	
        	action.setParams({
              	recordId:recId
        	});
        	action.setCallback(this, function(response){
                var state = response.getState();
            	if(state == "SUCCESS"){
					var caseRec = response.getReturnValue();
            		prompt('Copy to clipboard: Ctrl+C, Enter', 'Case ' + caseRec.CaseNumber + ' ' + caseRec.Subject + ' ' + location);
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error!",
                        "message": 'There is some error while processing',
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