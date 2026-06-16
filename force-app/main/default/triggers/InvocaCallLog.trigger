trigger InvocaCallLog on INVOCA_FOR_SF__Invoca_Call_Log__c (after update) {
    new Triggers()
        .bind(Triggers.Evt.afterupdate, new InvocaCallLogTriggerHandler.afterUpdateInvocaCallLog())
        .manage();
}