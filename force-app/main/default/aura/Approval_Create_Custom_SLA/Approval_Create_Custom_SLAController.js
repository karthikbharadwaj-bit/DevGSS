({
	doInit : function(component, event, helper) {
	    var device = $A.get("$Browser.formFactor");
        var approvalId = component.get("v.recordId");
         $A.get("e.force:closeQuickAction").fire();
         if(device == 'DESKTOP')
                    {
                        var win = window.open("/apex/SLAManagement?approvalId=" + approvalId);
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
                            'url': '/apex/SLAManagement?approvalId='+approvalId
                        });
                        urlEvent.fire();
                    }       
		
	}
})