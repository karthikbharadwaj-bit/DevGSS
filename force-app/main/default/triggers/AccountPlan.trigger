trigger AccountPlan on Account_Plan__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new AccountPlanTriggerHelper.EnrichWithEmployeeDetails())
        .bind(Triggers.Evt.beforeupdate, new AccountPlanTriggerHelper.EnrichWithEmployeeDetails())
        .manage();
}