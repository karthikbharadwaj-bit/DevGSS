({
    saveApproverWithNewAssignment : function(component) {
        var action = component.get("c.updateApproverUserAssignment"),
            autoAssignmentCmp = component.find("user-record"),
            approverRec = component.get("v.approverRec");

        if (autoAssignmentCmp) {
             const selectedValueAssignment = autoAssignmentCmp.get("v.selectedOption");
             action.setParams({
                approverId: approverRec.Id,
                userOrQueueIdParam: selectedValueAssignment
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.isOpen", false);
                    component.get("v.parent").refreshApproverList();
                } else if (state === "ERROR") {
                    alert(response.getError()[0].message)
                }
            });
            $A.enqueueAction(action);
        }
    }
})