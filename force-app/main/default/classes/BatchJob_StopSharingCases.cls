global class BatchJob_StopSharingCases implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
	
	integer days;

	public BatchJob_StopSharingCases(integer days) {
		this.days = days;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(
				'SELECT Id, EndDate, LocalRecordId FROM PartnerNetworkRecordConnection WHERE LocalRecordId in' + 
				' (SELECT Id FROM Case WHERE Status = \'Resolved\' and Support_Escalate_To__c = \'inContact Support\' AND LastModifiedDate = Last_N_Days: ' + String.valueOf(days) + ')' + 
				' AND Status = \'Sent\' AND EndDate = null'
			);
	}

   	global void execute(Database.BatchableContext BC, List<PartnerNetworkRecordConnection> scope) {
		//Doesn't actually delete PartnerNetworkRecordConnection object, sets it's Status to 'Inactive' 
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

	public Void execute(SchedulableContext context)
	{
		Database.executeBatch(new BatchJob_StopSharingCases(days));
	}
}