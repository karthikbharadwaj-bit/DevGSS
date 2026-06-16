trigger DfrAfterUpdateTrigger on DFR_AfterUpdate__e(after insert) {
    DemandFunnelPlatEvents.dfrAfterUpdateTrigger(Trigger.new);
}