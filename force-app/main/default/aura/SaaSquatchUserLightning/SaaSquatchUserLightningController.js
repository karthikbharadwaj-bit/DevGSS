({
	doInit : function(component, event, helper) {
        
        var leadId = component.get("v.recordId");
        console.log(leadId);
        
        window.open('/apex/SaaSquatchUserCreation?id=' + leadId);
    	
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();

        
	}
})