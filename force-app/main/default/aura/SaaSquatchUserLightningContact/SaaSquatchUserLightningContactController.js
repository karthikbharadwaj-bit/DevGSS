({
	doInit : function(component, event, helper) {
        
        var recordIds = component.get("v.recordId");

        console.log(recordIds);

        window.open('/apex/SaaSquatchUserCreationContact?id=' + recordIds); 

        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();

        
	}
})