trigger OrderCustom on Order__c (before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new OrderCustomTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.beforeupdate, new OrderCustomTriggerHandler.BrandPartnerPopulationHandler())

        .manage();
}