global class BatchJobEndDateRenewal implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext BC){
        String today = String.valueOf(System.today());
        //B-571 If Sales Agreement has Status == "Active", Quote Type != "Quote", and Auto Renewal is set to true,
        //and End Date has passed, then End Date should be re-calculated from current End Date + Renewal Term and updated.
        //If Renewal Term == null, 0 or 1 - we don't update them!

        // B-743: if RC_Account_Status__c ==  "Disabled" or "Cancelled" - we don't update them
        String Query = 'SELECT Id, End_Date__c, Status, Auto_Renewal__c, Term_months__c, Account__c FROM Quote WHERE End_Date__c <= ' + today + ' AND Status = \'Active\' AND QuoteType__c != \'Quote\' ';
        return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){

        List<String> restrictedAccountStatuses = new List<String>{'Disabled', 'Canceled'};
        List<Id> accIds = new List<Id>();

        for (SObject s: scope) {
            accIds.add(String.valueOf(s.get('Account__c')));
        }
        Map<Id,Account> accounts = new Map<Id, Account>([
                SELECT Id, RC_Account_Status__c
                FROM Account
                WHERE Id IN :accIds
        ]);

        for(Sobject s : scope){
            Integer renewalTermMonths = Integer.valueOf(s.get('Term_months__c'));
            Boolean autoRenewal = Boolean.valueOf(s.get('Auto_Renewal__c'));
            Id accId = (Id) s.get('Account__c');
            if (autoRenewal == false) {
                s.put('Status', 'Inactive');
            } else if (renewalTermMonths != null && renewalTermMonths > 1
                    && accounts.containsKey(accId) && !restrictedAccountStatuses.contains(accounts.get(accId).RC_Account_Status__c)) {
                    s.put('End_Date__c', ((Date) s.get('End_Date__c')).addMonths(renewalTermMonths));
                }
            }
        Database.update(scope, false);
    }

    global void finish(Database.BatchableContext BC){
    }
}