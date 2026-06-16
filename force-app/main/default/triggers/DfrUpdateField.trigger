trigger DfrUpdateField on DFR_Update_Field__e (after insert) {
    DemandFunnelPlatEvents.updateFieldValue(trigger.new);
}