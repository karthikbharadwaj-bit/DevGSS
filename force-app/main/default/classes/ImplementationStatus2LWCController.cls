public with sharing class ImplementationStatus2LWCController {
    
    @AuraEnabled(cacheable = true)
    public static List<Implementation_status_definition__mdt> getImplementationStatus(){

        return [SELECT Id, MasterLabel, Definition__c FROM Implementation_status_definition__mdt];
    }
}