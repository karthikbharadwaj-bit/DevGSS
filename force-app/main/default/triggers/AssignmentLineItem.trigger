trigger AssignmentLineItem on AssignmentLineItem__c (
        after insert,
        after update,
        before delete) {

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new AssignmentLineItemTriggerHandler.CopyLineItemFromMasterToTechnicalQliOnInsert())
        .bind(Triggers.Evt.afterupdate, new AssignmentLineItemTriggerHandler.CopyLineItemFromMasterToTechnicalQliOnUpdate())
        .bind(Triggers.Evt.beforedelete, new AssignmentLineItemTriggerHandler.DeleteLineItemsOnTechnicalQlisOnMasterDelete())
        .manage();
}