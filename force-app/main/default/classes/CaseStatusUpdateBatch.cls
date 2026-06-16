global class CaseStatusUpdateBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status
            FROM Case
            WHERE createdby.name='Shubham Prabhakar'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
	
        System.debug('Scope::'+scope.size());
        for (Case c : scope) {
            c.Status = 'Resolved'; // change to your required status
            c.Callback_Contact_ID__c='003TH000013vtGGYAY';
            casesToUpdate.add(c);
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
              
        System.debug('SOQL Queries Used: ' + Limits.getQueries());
        System.debug('SOQL Query Limit: ' + Limits.getLimitQueries());
        
        System.debug('DML Statements Used: ' + Limits.getDmlStatements());
        System.debug('DML Limit: ' + Limits.getLimitDmlStatements());
        
        System.debug('CPU Time Used: ' + Limits.getCpuTime());
        System.debug('CPU Time Limit: ' + Limits.getLimitCpuTime());
        
        System.debug('Heap Size Used: ' + Limits.getHeapSize());
        System.debug('Heap Size Limit: ' + Limits.getLimitHeapSize());
        System.debug('Case Status Update Batch Completed');
    }
}