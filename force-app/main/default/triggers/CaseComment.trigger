trigger CaseComment on CaseComment (after insert, after update, after delete, before delete) {

    new Triggers()
    .bind(Triggers.Evt.afterinsert, new CaseCommentTriggerHelper.CompleteFirstResponseMilestoneHandler())
    .bind(Triggers.Evt.afterinsert, new CaseCommentTriggerHelper.CompleteFollowUpSupportIntegrationMilestone())
    .bind(Triggers.Evt.afterinsert, new CaseCommentTriggerHelper.CaseCommentCount())
    .bind(Triggers.Evt.afterupdate, new CaseCommentTriggerHelper.CaseCommentCount())
    .bind(Triggers.Evt.afterdelete, new CaseCommentTriggerHelper.CaseCommentCount())
    .manage();
    
    //added  logic to prevent deletion of CaseComment records by any user other than sys admin
    if(Trigger.isBefore && Trigger.isDelete){
        CaseCommentTriggerHelper cchelper = new CaseCommentTriggerHelper();
        cchelper.checkDeleteAccess(trigger.old);
    }
    
    if(Trigger.isInsert){
        GenericE2CSetupHandler.sendEmailNotificationToPartner((List<CaseComment>) Trigger.new);
    }
}