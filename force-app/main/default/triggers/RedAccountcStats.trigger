trigger RedAccountcStats on Red_Account__c (
    before insert,
    before update,
    after insert,
    after update,
    after delete,
    after undelete) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new RedAccountTriggerHandler.RedAccountBefore())
        .bind(Triggers.Evt.beforeupdate, new RedAccountTriggerHandler.RedAccountBefore())
        .bind(Triggers.Evt.beforedelete, new RedAccountTriggerHandler.RedAccountBefore())
        .manage();
}