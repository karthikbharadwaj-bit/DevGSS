({
    handleCloseModal: function(component, event, helper) {
        //For Close Modal, Set the "openModal" attribute to "fasle"  
        component.set("v.showApprovalAction", false);
    },
    
    saveDetails : function(component, event, helper) {
        component.set("v.Spinner",true);
    	helper.saveDetails(component,event,helper)
    }

})