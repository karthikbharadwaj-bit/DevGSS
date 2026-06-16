global with sharing class AccountDeOwner {

	webservice static String deOwn(Id accId) {
		Account acc = [SELECT Current_Owner__c, Partner_ID__c, RC_User_ID__c, RecordType.Name, RC_Attribution_Channel__c FROM Account WHERE Id = :accId];
		String currentUserId = UserInfo.getUserId();
		String attChannel = acc.RC_Attribution_Channel__c;

		if(attChannel != '' && attChannel != null) {
			attChannel = attChannel.toUpperCase();
		}

		if(currentUserId == acc.Current_Owner__c &&
            ((acc.Partner_ID__c == null || acc.Partner_ID__c == '') ||
                (acc.Partner_ID__c != null && acc.Partner_ID__c != '' &&
                 acc.RecordTypeId != null && 
                 acc.RecordType.Name == 'Customer Account' &&
                 acc.RC_User_ID__c != '' && acc.RC_User_ID__c != null
                )
            ) && 
            attChannel != 'SALES AGENTS & RESELLERS') {

			acc.Current_Owner__c = null;
			update acc;

			//Remove user from Account Team and Opportunity Team
			delete [SELECT Id FROM AccountTeamMember WHERE AccountId = :acc.Id AND UserId = :currentUserId];
			delete [SELECT Id FROM OpportunityTeamMember WHERE Opportunity.AccountId = :acc.Id AND UserId = :currentUserId];

			//Set today as end day for Account Split
			Account_Split__c[] Splits = [SELECT End_Date__c FROM Account_Split__c WHERE Account__c = :acc.Id AND Sales_Agent__c = :currentUserId]; 
			
			for(Account_Split__c split : Splits) {
				split.End_Date__c = Date.today(); 
			}
			update Splits;
			return 'success';
		} else if(currentUserId != acc.Current_Owner__c) {
			return 'owner';
		} else {
			return 'error';
		}
	}
}