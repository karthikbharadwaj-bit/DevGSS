trigger CampaignMemberLogCreation on Campaign_Member_Log__e (after insert) {
    System.debug('CampaignMemberLogCreation');
    CampaignMemberPlatEvents.processCampaignMemberLogCreationEvent(Trigger.new);
}