@isTest private class Test_PhaseData {
    @testSetup static void setup(){
        Map<String, Schema.RecordTypeInfo> PHASE_RECORD_TYPE_MAP = Schema.SObjectType.Phase__c.getRecordTypeInfosByName();
        Phase__c testFirstPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'testAcc',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId()
                }
            )
            .create()
            .getRecord();
        Phase__c testComparedPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'testAcc',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId()
                }
            )
            .create()
            .getRecord();
    }

    @isTest static void testRetrieveSinglePhase() {
        Id idOfFirstPhase = [SELECT Id FROM Phase__c LIMIT 1].Id;
        Test.startTest();
        PhaseData phaseData = new PhaseData();
        Phase__c comparePhase = phaseData.retrieveSinglePhase(idOfFirstPhase);
        Test.stopTest();
        System.assert(comparePhase != null, 'There should be at least one Phase with the Id');
        System.assertEquals(idOfFirstPhase, comparePhase.Id, 'Id should be the same');
    }

    @isTest static void testRetrievePhases() {
        List<Phase__c> phaseList = [SELECT Id FROM Phase__c];
        Set<Id> idsOfPhases = new Set<Id>();
        for (Phase__c phase : phaseList) {
            idsOfPhases.add(phase.id);
        }
        Test.startTest();
        PhaseData phaseData = new PhaseData();
        List<Phase__c> comparePhases = phaseData.retrievePhases(idsOfPhases);
        Test.stopTest();
        System.assert(comparePhases != null, 'Phases should have been retrieved');
        System.assertEquals(2, comparePhases.size(), '2 Phases should have been retrieved');

    }
}