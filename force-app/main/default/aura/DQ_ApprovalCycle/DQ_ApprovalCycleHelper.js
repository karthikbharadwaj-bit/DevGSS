({
	checkIfPermissionExist : function(component, event, helper,isApproved) {
        var approvalRecordId = event.currentTarget.getAttribute('class');
        var serverAction = component.get("c.checkApprovePermission");
        serverAction.setParams({
            approvalRecordId : approvalRecordId
        });
        
        serverAction.setCallback(this, function(response){
            console.log(response.getState());
            if(response.getState() == "SUCCESS"){
            	if(response.getReturnValue()) {
                    component.set("v.isUserHavePermission",true);
                } else {
                    component.set("v.isUserHavePermission",false);
                    //not have permission to Approve or reject
                }
                if(isApproved)
                    component.set("v.enabledApprove",true);
                else 
                    component.set("v.enabledApprove",false);

               //component.set("v.isUserHavePermission",true);
				component.set("v.approvalRecordId",approvalRecordId);    
				component.set("v.showApprovalAction",true);
                component.set("v.Spinner",false);
            }
        });
        $A.enqueueAction(serverAction);
 	},
    
    checkDQApprovalStatus : function(component, event, helper) {
        var url = new URL(location.href);
        var dqapprovalId = url.searchParams.get('dqapprovalId');
        var action = url.searchParams.get('action');
        component.set("v.isUserHavePermission",true);
        if(dqapprovalId) {
            //alert(dqapprovalId);
            var serverAction = component.get("c.checkIfDQApprovalAcceptorReject");
            serverAction.setParams({
                dqApprovalRecId : dqapprovalId
            });
            
            serverAction.setCallback(this, function(response){
                //alert(response.getReturnValue());
                console.log(response.getState());
                if(response.getState() == "SUCCESS"){
                    if(response.getReturnValue()) {
                    	component.set("v.isAlreadyApprovedOrReject",true);
                        component.set("v.currentStatus",response.getReturnValue());
                        component.set("v.showApprovalAction",true);
                    } else {
                        if(dqapprovalId && action && action == 'approve') {
                            component.set("v.enabledApprove",true);
                            component.set("v.approvalRecordId",dqapprovalId);    
                            component.set("v.showApprovalAction",true);
                        } else if(dqapprovalId && action && action == 'reject') {
                            component.set("v.enabledApprove",false);
                            component.set("v.approvalRecordId",dqapprovalId);    
                            component.set("v.showApprovalAction",true);
                        }
                    }
                }
            });
            $A.enqueueAction(serverAction);
        }
 	},
})