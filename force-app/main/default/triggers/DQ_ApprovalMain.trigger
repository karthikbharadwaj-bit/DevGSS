trigger DQ_ApprovalMain on DQ_Deal_Qualification_Approver__c (before insert, after insert, before update, after update, after delete) {
    if(Trigger.isBefore && Trigger.isInsert) {
        DQ_AutoApproveEngine.updateDelegateEmail(Trigger.oldMap, Trigger.new);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate){
        DQ_AutoApproveEngine.updateDelegateEmail(Trigger.oldMap, Trigger.new);
        DQ_AutoApproveEngine.autoApproveEligibleDQApprovals(Trigger.oldMap, Trigger.NewMap);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        DQ_ApprovalMainHelper.updateStatusForApprovalRecords(Trigger.NewMap);
    }

    new Triggers()
        .bind(Triggers.Evt.beforeupdate, new DealQualificationApproverHandler.SetClosedDateTime())
        .bind(Triggers.Evt.afterinsert, new DealQualificationApproverHandler.CountApprovalsOnDQ())
        .bind(Triggers.Evt.afterdelete, new DealQualificationApproverHandler.CountApprovalsOnDQ())
        .manage();
}