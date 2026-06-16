@istest
public class Test_Phase_Complete_PhaseController {
		
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void  CreateCase()
    {
        List<Phase__c> phase = new List<Phase__c>();
        Phase__c phs = new Phase__c();
        phs.Name = 'testPhase';
        phs.RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId();
        phase.add(phs);   
        Phase__c phs2 = new Phase__c();
        phs2.Name = 'testPhase2';
        phs2.RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('RingCentral Hardware Phase').getRecordTypeId();
        phase.add(phs2);
        
        insert phase;
        Phase_Complete_PhaseController.getPhaseDetails(phs.id);
        Phase_Complete_PhaseController.updatePhase(phs.id);
        Phase_Complete_PhaseController.updatePhase(phs2.id);
        }


}