trigger DfrCreateLeadTrigger on DFR_CreateLead__e(after insert) {
    DemandFunnelPlatEvents.DfrCreateLeadTrigger(Trigger.new);
}