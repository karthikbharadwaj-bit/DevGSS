trigger OpportunityTeamMember on OpportunityTeamMember (before insert, before update, before delete, after insert, after update) {
	if (Trigger.isBefore && Trigger.isInsert && !FeatureManagement.checkPermission('SE_Manager_Permission') && EventTriggerHandler.teamMemberCreationViaEvent != true && EventTriggerHandler.currentUser.Profile.Name.startsWith('Sales Engineer')) {
		for(OpportunityTeamMember otm : Trigger.new){
			otm.addError('SE Must create Opportunity Member via SE Event.');
		}
	}
}