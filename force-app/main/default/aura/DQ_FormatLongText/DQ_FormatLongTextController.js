({
    handleDescriptionChange : function(component, event, helper) {
        const multiReason = component.get("v.multiReason");
        let description = component.get("v.description");
        if (!$A.util.isUndefinedOrNull(multiReason) && !$A.util.isEmpty(multiReason)) {
            const stepId = component.get("v.approvalStepId");
           let reason = multiReason.filter(reason => reason.dqApprovalTypeStep.DQ_Approval_Step__c === stepId);
            if (reason) {
                 let reasonArr = reason.map(eachReason => eachReason.approvalReason);
                 let reasons = [];
                 reasonArr.forEach(reasonVal => reasons = [...reasons, ...reasonVal.split(',')]);
                 component.set("v.descriptionValue", reasons.join('<br />'));
            }
        } 
        
        if ($A.util.isUndefinedOrNull(component.get("v.descriptionValue")) && !$A.util.isEmpty(description)) {
            description = description.split(',').join('<br />');
            component.set("v.descriptionValue", description);
        }
    }
})