({
	launchFlow : function(component, event, helper) {
		
        
        var accid = component.get("v.recordId");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
         var device = $A.get("$Browser.formFactor");
         if(device == 'DESKTOP')
                    {
        var win = window.open("/flow/RingCentral_Troubleshooting_Tool?var_initialaccountid="+accid+"&var_initialuserid="+userId);
                        var timer = setInterval(function () {
                            if (win.closed) {
                                clearInterval(timer);
                                window.location.reload(); // Refresh the parent page
                            }
                        }, 1000);
                        
                       
                    } else {
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            'url': '/flow/RingCentral_Troubleshooting_Tool?var_initialaccountid='+accid+'&var_initialuserid='+userId
                        });
                        urlEvent.fire();
                    }  
        

	},
    
     doneRendering: function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})