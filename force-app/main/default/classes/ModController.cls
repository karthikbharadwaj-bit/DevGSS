public with sharing class ModController {
    @AuraEnabled(cacheable=true)
    public static List<MOD_Escalation__c> getOpenModRecords(Id caseId) {
        return [SELECT Id, Name, MOD_Status__c, CreatedBy.Name FROM MOD_Escalation__c WHERE Case_Number__c = :caseId AND MOD_Status__c = 'Open'];
    }
}