trigger CostCenterLineItem on Cost_Center_Line_Item__c (
    after insert,
    after update,
    before delete) {
        
    new Triggers()
        .bind(Triggers.Evt.afterinsert, new CostCenterLineItemTriggerHandler.CopyLineItemFromMasterToTechnicalQliOnInsert())
        .bind(Triggers.Evt.afterupdate, new CostCenterLineItemTriggerHandler.CopyLineItemFromMasterToTechnicalQliOnUpdate())
        .bind(Triggers.Evt.beforedelete, new CostCenterLineItemTriggerHandler.DeleteLineItemsOnTechnicalQlisOnMasterDelete())
        .manage();
}