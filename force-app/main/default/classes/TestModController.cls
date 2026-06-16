@IsTest
public class TestModController {
    
    @TestSetup
    static void setup() {
            Case openModCase = new Case(
            Subject = 'Test Case with Open MOD',
            Status = 'New'
        );
        insert openModCase;

        // Open MOD record related to the Case
        MOD_Escalation__c openModRecord = new MOD_Escalation__c(
            MOD_Status__c = 'Open',
            Case_Number__c = openModCase.Id
        );
        insert openModRecord;

        // Case record for the Closed MOD scenario
        Case closedModCase = new Case(
            Subject = 'Test Case with Closed MOD',
            Status = 'New'
        );
        insert closedModCase;

        // Closed MOD record related to the Case
        MOD_Escalation__c closedModRecord = new MOD_Escalation__c(
            MOD_Status__c = 'Closed',
            Case_Number__c = closedModCase.Id
        );
        insert closedModRecord;
    }

    @IsTest
    static void testGetOpenChildModRecordsWithOpenMOD() {
        
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case with Open MOD' LIMIT 1];

        // Calling the Apex method to get open MOD records
        List<MOD_Escalation__c> openMods = ModController.getOpenModRecords(testCase.Id);

        // Verifying that the result contains 1 MOD record (the one with 'Open' status)
        System.assertEquals(1, openMods.size(), 'There should be 1 open MOD record.');
        System.assertEquals('Open', openMods[0].MOD_Status__c, 'The MOD status should be Open.');
    }

    @IsTest
    static void testGetOpenChildModRecordsWithClosedMOD() {
    
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case with Closed MOD' LIMIT 1];

        // Calling the Apex method to get open MOD records
        List<MOD_Escalation__c> openMods = ModController.getOpenModRecords(testCase.Id);

        // Verify that the result contains 0 MOD records, since the MOD status is 'Closed'
        System.assertEquals(0, openMods.size(), 'There should be no open MOD records.');
    }

    @IsTest
    static void testGetOpenChildModRecordsWithNoMODs() {
        // New Case with no related MOD records
        Case noModCase = new Case(
            Subject = 'Case with no MODs',
            Status = 'New'
        );
        insert noModCase;

        // Calling the Apex method to get open MOD records for the new case
        List<MOD_Escalation__c> openMods = ModController.getOpenModRecords(noModCase.Id);

        // Verifying that the result contains 0 MOD records
        System.assertEquals(0, openMods.size(), 'There should be no MOD records for this case.');
    }
}