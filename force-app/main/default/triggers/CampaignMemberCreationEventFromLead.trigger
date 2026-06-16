trigger CampaignMemberCreationEventFromLead on CampaignMemberCreation_From_Lead__e (after insert) {
    CampaignMemberPlatEvents.processCampaignMemberCreationFromLeadEvent(Trigger.new);
}