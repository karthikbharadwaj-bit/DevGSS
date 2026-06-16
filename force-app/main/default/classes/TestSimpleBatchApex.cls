global class TestSimpleBatchApex implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name FROM Account'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        System.debug('Account count in this batch: ' + scope.size());
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch Apex completed.');
    }
}