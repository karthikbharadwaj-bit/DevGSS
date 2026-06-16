trigger ContactUpdateClosedWonOpp on Contact_Update_ClosedWon_Opp__e(after insert) {
    ContactUpdatePlatformEventsHelper.updateContactStatus(Trigger.new);
}