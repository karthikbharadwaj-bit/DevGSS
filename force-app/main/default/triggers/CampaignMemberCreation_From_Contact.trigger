trigger CampaignMemberCreation_From_Contact on CampaignMemberCreation_From_Contact__e(
  after insert
) {
    CampaignMemberPlatEvents.processCampaignMemberCreationFromContactEvent(Trigger.new);
}