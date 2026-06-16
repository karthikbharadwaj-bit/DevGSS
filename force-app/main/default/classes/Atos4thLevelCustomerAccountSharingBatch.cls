public class Atos4thLevelCustomerAccountSharingBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([select Id from Account where Partner_Account__r.RC_Brand__c = 'Unify Office' and Type = 'Customer' and Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c = '0012H00001Zo8UUQAZ' and Partner_Account__r.Avaya_Partnership_Account__c = true]);
    }
    public void execute(Database.BatchableContext BC, List<sObject> objLst){
        List<Account> acc = (List<Account>)objLst;
        Map<Id, Account> accMap = new Map<Id, Account>(acc);
        if(!accMap.isEmpty()) {
        	Sharing_AccountLeadHandler.handleAccountShare(accMap.keySet());
        	system.debug('accMap: ' + accMap.size());
        }
    }
    public void finish(Database.BatchableContext BC){
        
    }
}