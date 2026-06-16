({
	getLoginDetails : function(component, event, helper) {
		var action = component.get("c.getLastLoginDetails");
        action.setCallback(this, function(result) {
            var state=action.getState();
            if(state === "SUCCESS"){
                console.log("result "+JSON.stringify(result.getReturnValue()));
                if(result.getReturnValue()){
                    component.set('v.isOpen',true);
                }
            }
        });
        $A.enqueueAction(action);
	}
})