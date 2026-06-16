trigger AccountRelation on AccountRelation__c (
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {

    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new AccountRelationTriggerHandler.AccountRelationBefore())

            .bind(Triggers.Evt.beforeupdate, new AccountRelationTriggerHandler.AccountRelationBefore())
            
            .manage();
}