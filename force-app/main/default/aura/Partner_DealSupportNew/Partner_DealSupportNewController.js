({
    
    createDealSupport : function(component, event, helper) {
        var comments=component.find('comments');
        var commentValue=comments.get('v.validity').valueMissing;
        if(commentValue) {
            comments.showHelpMessageIfInvalid();
            comments.focus();
        }
        else{
            helper.insertDealSupport(component, event, helper);
        }
    },
    
    cancelDealSupport: function(component, event, helper) {
        
        component.set("v.ShowNewRecord", false);
        component.set("v.ShowRecordDetail", false);
        component.set("v.ShowListView", true);
        var cmpEvent = component.getEvent("cancelEvent");
        cmpEvent.setParams({
            "goBack": true});
        cmpEvent.fire(); 
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