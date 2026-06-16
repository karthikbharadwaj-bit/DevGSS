({
	doInit : function(component, event, helper) {
		var recId = component.get("v.recordId");
        window.open('/apex/EntitlementsView?id='+recId);
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