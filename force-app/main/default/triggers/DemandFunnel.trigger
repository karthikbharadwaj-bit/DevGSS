trigger DemandFunnel on Demand_Funnel__c (before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_DemandFunnel_Trigger__c == true) {
        return;
    }
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new DemandFunnelTriggerHandler.FieldPopulation())
        .bind(Triggers.Evt.beforeupdate, new DemandFunnelTriggerHandler.FieldPopulation())
        .bind(Triggers.Evt.beforeinsert, new DemandFunnelTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.beforeupdate, new DemandFunnelTriggerHandler.BrandPartnerPopulationHandler())
        .bind(Triggers.Evt.afterupdate, new DemandFunnelTriggerHandler.DFRFieldTracking())
        .manage();
}