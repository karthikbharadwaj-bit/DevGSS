({
     //Not to set the close date to end of Quarter-This method is calles when user click No
	handleNo : function(component, event, helper) {
		component.find("overlayLib").notifyClose();	
	},
    //set the close date to end of Quarter-This method is calles when user click yes
    handleYes : function(component, event, helper) {
        component.set("v.spinner",true);
		let oppId = component.get("v.recordId");
        let action = component.get("c.opportunityEndOfQuarter");
        action.setParams({ opportunityId : oppId });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                let navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": oppId,
                  "slideDevName": "Detail"
                });
                navEvt.fire();
                component.set("v.spinner",false);
            }else {
                alert('Error!');
            }
        });
	 	$A.enqueueAction(action);
	}  
})