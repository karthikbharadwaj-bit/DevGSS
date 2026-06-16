public class Atos4thlevelDealSharing implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([select Id from Deal_Registration__c where Partner_Account__r.RC_Brand__c = 'Unify Office' and Partner_Account__r.Type = 'Partner' and Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c = '0012H00001Zo8UUQAZ' and Partner_Account__r.Avaya_Partnership_Account__c = true]);
    }
    public void execute(Database.BatchableContext BC, List<sObject> objLst){
        List<Deal_Registration__c> deals = (List<Deal_Registration__c>)objLst;
        Map<Id, Deal_Registration__c> dealsmap = new Map<Id, Deal_Registration__c>(deals);
        if(!dealsmap.isEmpty()) {
        	Quote_SharingHandler.handleDealRegistrationShare(dealsmap.keySet());
        	system.debug('dealsmap: ' + dealsmap.size());
        }
    }
    public void finish(Database.BatchableContext BC){
        
    }
}