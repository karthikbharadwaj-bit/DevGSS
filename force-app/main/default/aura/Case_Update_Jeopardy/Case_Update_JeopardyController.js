({
	doInit : function(component, event, helper) {
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
                var device = $A.get("$Browser.formFactor");
                if(retResponse != null && retResponse != undefined && retResponse != '' && retResponse.Status == 'Work in Progress')
                {
                    if(device == 'DESKTOP')
                    {
                        var win = window.open("/apex/UpdateJeopardyPopup?id=" + retResponse.Id, 'Popup','height=350,width=600,scrollbars=no, centerscreen=yes,toolbar=no,status=no');
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
                            'url': '/apex/UpdateJeopardyPopup?id='+retResponse.Id
                        });
                        urlEvent.fire();
                    }                	
                }
                else
                {
                    var toastEvent = $A.get("e.force:showToast");
                	toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": 'Case status should be Work in Progress to add or update a Jeoapardy',
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