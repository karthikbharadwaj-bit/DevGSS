trigger CampaignMemberCheckCreation on Campaign_Member_Check__e (after insert) {
    System.debug('CampaignMemberCheckCreation');
    CampaignMemberPlatEvents.processCampaignMemberCheckCreationEvent(Trigger.new);
}