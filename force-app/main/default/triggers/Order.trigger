trigger Order on Order (after insert, before insert) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Order_Trigger__c == true) {
        return;
    }

    new Triggers()
        .bind(Triggers.Evt.beforeInsert, new OrderTriggerHelper.UpdateProservProjectLookupOfChangeOrder())
        .bind(Triggers.Evt.afterInsert, new OrderTriggerHelper.CreateProservProject())
        .manage();
}