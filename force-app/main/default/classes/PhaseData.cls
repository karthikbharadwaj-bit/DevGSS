public without sharing class PhaseData {

    public Phase__c retrieveSinglePhase(Id phaseId){
        Phase__c retrievedPhase = new Phase__c();
        if(phaseId != null){ 
            retrievedPhase = [SELECT Id, BillingStatus__c, Estimated_Completion_Date__c,
                              Completion_Date__c, Phase_Start_Date__c, Name
                              FROM Phase__c
                              WHERE Id = :phaseId];
        }
        return retrievedPhase;
    }

    public List<Phase__c> retrievePhases(Set<Id> phaseIds) {
        List<Phase__c> retrievedPhaseList = [SELECT Id, BillingStatus__c, Estimated_Completion_Date__c,
                                             Completion_Date__c, Phase_Start_Date__c, Name
                                             FROM Phase__c
                                             WHERE Id IN :phaseIds];
        if(!retrievedPhaseList.isEmpty()){
            return retrievedPhaseList;
        } else {
            return null;
        }
        
    }
}