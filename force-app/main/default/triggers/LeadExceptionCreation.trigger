trigger LeadExceptionCreation on Lead_Exception__e (after insert) {
    LeadPlatEvents.processLeadCreationEventException(Trigger.new);
}