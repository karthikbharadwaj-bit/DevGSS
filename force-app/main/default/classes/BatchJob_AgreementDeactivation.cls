global class BatchJob_AgreementDeactivation implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // B-4829: Find Active Agreements with related Account.RC_Account_Status__c ==  "Canceled"
        /*String Query = 'SELECT Id, Account__c ' +
                       'FROM Quote ' +
                       'WHERE Status = \'Active\' AND Account__r.RC_Account_Status__c = \'Canceled\'';
        return Database.getQueryLocator(Query);*/

        QuoteSelector quoteSelector = new QuoteSelector();
        return quoteSelector.selectActiveQuotesWithCancelledAccountStatus().executeQueryLocator();
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        for (Sobject s : scope) {
            s.put('Status', 'Inactive');
        }
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
    }
}