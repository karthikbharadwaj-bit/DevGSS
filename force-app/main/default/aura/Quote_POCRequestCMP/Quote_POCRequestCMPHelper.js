({
	submitPOCRequest : function(component, event, helper) {
        var action = component.get("c.createPOCRequest");
        action.setParams({dealSupportRecord :  component.get("v.ObjNewDealSupport"),
                         opportunityId : component.get("v.recordId")});
        action.setCallback(this, function(result) {
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                component.set("v.Spinner", false);
                component.set("v.showPOCRequest", false);
                component.set("v.isPOCRequestExists", true);
                helper.showToast('Success', 'POC request submitted successfully!', 'success');
            }
            else{
            	helper.showToast('Error', 'There is some error submitting POC Request!', 'error');    
            }
        });    
        
        $A.enqueueAction(action);
	}
})