trigger D_B_Credit_Check_Trigger on D_B_Credit_Check__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {
        new Triggers()
            .bind(Triggers.Evt.afterupdate, new D_B_Credit_CheckTriggerHandler.SendEmailIfDNBStatusIsPending())
            .bind(Triggers.Evt.afterupdate, new D_B_Credit_CheckTriggerHandler.ApproveIfDNBIUserIsApprover())
        .manage();

}