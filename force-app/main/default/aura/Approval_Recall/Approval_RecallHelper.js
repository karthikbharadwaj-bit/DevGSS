({
	showSpinner: function(component, event, helper) {        
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("mySpinner");
        component.set('v.displayButtons',true);
    }
})