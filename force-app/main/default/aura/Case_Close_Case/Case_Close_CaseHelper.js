({
	createSolRecord : function(component, event, helper, soltitle, soldetails) {
		 var action = component.get("c.createSolutionRecord");
        action.setParams({"soltitle" : soltitle,
                          "solDetails" : soldetails,
                          "caseId" : component.get("v.recordId")});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("state---->" +state);
            if (state === "SUCCESS") {
                var responseFromCntrl  = response.getReturnValue();
                console.log(responseFromCntrl);
                if(responseFromCntrl == "error"){
                 console.log("Error==>" +responseFromCntrl);
                }

                
            }
            
        });
        $A.enqueueAction(action);

	},
    // Added for ITPMO-2515
    checkPermissionSetAccess : function(component, event, helper){
        var action = component.get("c.checkAttPermissionset");
        console.log("Permissionset received");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("state---->" +state);
            if (state === "SUCCESS") {
                var isAttPermission  = response.getReturnValue();
                component.set("v.isATTPermissionPresent",isAttPermission);
                console.log(isAttPermission);
            }

        });
        $A.enqueueAction(action);

    }
     // Added for ITPMO-2515
})