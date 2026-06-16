public class Atos4thLevelLeadSharingBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([select Id from Lead where Partner_Account__r.RC_Brand__c = 'Unify Office' and Partner_Account__r.Type = 'Partner' and Partner_Account__r.Partner_Account__r.Partner_Account__r.Partner_Account__c = '0012H00001Zo8UUQAZ' and Partner_Account__r.Avaya_Partnership_Account__c = true]);
    }
    public void execute(Database.BatchableContext BC, List<sObject> objLst){
        List<Lead> leads = (List<Lead>)objLst;
        Map<Id, Lead> leadsmap = new Map<Id, Lead>(leads);
        if(!leadsmap.isEmpty()) {
        	Sharing_AccountLeadHandler.handleLeadShare(leadsmap.keySet());
        	system.debug('leadsmap: ' + leadsmap.size());
        }
    }
    public void finish(Database.BatchableContext BC){
        
    }
}