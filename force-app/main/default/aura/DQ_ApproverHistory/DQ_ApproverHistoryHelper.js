({
	getDQHistory : function(component, event, helper) {
        //alert(component.get("v.dqId"));
		 var serverAction = component.get("c.getDQDealApprovalHistory");
        serverAction.setParams({
            dQId: component.get("v.dqId")
        });
        
        serverAction.setCallback(this, function (response) {
            if(response.getState() == "SUCCESS"){
                //alert(response.getReturnValue());
                if(response.getReturnValue()) {
                    component.set("v.approverHistoryList",response.getReturnValue().dealQualDiscountHistory);
                    component.set("v.approverHistoryRecord",response.getReturnValue().dealQualificationHistory);
                    
                }
            }
        });
        $A.enqueueAction(serverAction);
	}
})