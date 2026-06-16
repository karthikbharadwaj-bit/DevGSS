trigger CreateSupportEntitlements on CreateSupportEntitlements__e (after insert) {

    new Triggers()
        .bind(Triggers.Evt.afterinsert, new CreateSupportEntitlementsTriggerHandler.CreateSupportEntitlements())
        .manage();
}