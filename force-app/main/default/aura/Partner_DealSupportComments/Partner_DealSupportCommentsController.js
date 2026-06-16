({
    doInit : function(component, event, helper) {    
        var selectedDealSupport = component.get("v.DealSupportRecordId");
        if(selectedDealSupport != undefined && selectedDealSupport != '' && selectedDealSupport != null)
        {
            helper.getDealSupportComments(component, event, helper);
        }
             helper.getTranslations(component, event, helper);
    },
    createNewComment:function(component, event, helper) { 
        component.set("v.ShowNewComment",true);
        component.set('v.isActive', true);
    },
    
    createNewDealComment:function(component, event, helper) { 
        var comments=component.find('comments');
        var commentValue=comments.get('v.validity').valueMissing;
        if(commentValue) {
            comments.showHelpMessageIfInvalid();
            comments.focus();
        }
        else{
            helper.insertNewComment(component, event, helper);
        }
    },
    
    closeModal : function(component, event, helper) {
        component.set('v.isActive', false);
        component.set('v.ShowRecordDetail', true);
        component.set('v.ShowNewComment', false);
    },
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },    
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
})