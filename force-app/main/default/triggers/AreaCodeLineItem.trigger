trigger AreaCodeLineItem on Area_Code_Line_Item__c (
        after insert,
        after update,
        after delete,
        before delete) {

    new Triggers()
            .bind(Triggers.Evt.afterupdate, new AreaCodeLineItemTriggerHelper.UpdateQuoteLineItemOnAreaCodeLineItemUpdate())
            .bind(Triggers.Evt.afterinsert, new AreaCodeLineItemTriggerHelper.UpdateQuoteLineItemOnAreaCodeLineItemUpdate())
            .bind(Triggers.Evt.afterdelete, new AreaCodeLineItemTriggerHelper.UpdateQuoteLineItemOnAreaCodeLineItemUpdate())
            .bind(Triggers.Evt.afterupdate, new AreaCodeLineItemTriggerHelper.CheckInvalidNumberSetups())
            .bind(Triggers.Evt.afterinsert, new AreaCodeLineItemTriggerHelper.CheckInvalidNumberSetups())
            .bind(Triggers.Evt.afterdelete, new AreaCodeLineItemTriggerHelper.CheckInvalidNumberSetups())
            .bind(Triggers.Evt.afterinsert, new AreaCodeLineItemTriggerHelper.CopyLineItemFromMasterToTechnicalQliOnInsert())
            .bind(Triggers.Evt.afterupdate, new AreaCodeLineItemTriggerHelper.CopyLineItemFromMasterToTechnicalQliOnUpdate())
            .bind(Triggers.Evt.beforedelete, new AreaCodeLineItemTriggerHelper.DeleteLineItemsOnTechnicalQlisOnMasterDelete())
            .manage();
}