({
    doInit : function(component, event, helper) {
        //check if DQApprovalRecord Already Approved or not.
        helper.checkDQApprovalStatus(component, event, helper);
    },
	ApproveDQ : function(component, event, helper) {
        console.log(event.currentTarget.getAttribute('class'));
        component.set("v.Spinner",true);
        var isApproved = true;
        helper.checkIfPermissionExist(component, event, helper,isApproved);
    },
    RejectDQ : function(component, event, helper) {
        component.set("v.Spinner",true);
        var isApproved = false;
        helper.checkIfPermissionExist(component, event, helper,isApproved);
	},
})