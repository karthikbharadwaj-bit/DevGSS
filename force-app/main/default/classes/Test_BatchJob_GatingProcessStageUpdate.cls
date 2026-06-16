@isTest
public class Test_BatchJob_GatingProcessStageUpdate {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGatingProcessStageUpdate() {
        Test.startTest();
        List<Lead> ldList = new List<Lead>();
        Lead testLead1 = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Email = 'test@test.com',
            Enrichment_Last_Processed_Date__c = System.now()
        );
        Lead testLead2 = new Lead(
            LastName = 'Test2',
            Company = 'Test Company2',
            Email = 'test2@test.com',
            Enrichment_Last_Processed_Date__c = System.now()
        );
        Lead testLead3 = new Lead(
            LastName = 'Test3',
            Company = 'Test Company3',
            Email = 'test3@test.com',
            LeadSource = 'ZoomInfo',
            Enrichment_Last_Processed_Date__c = System.now()
        ); 
        ldList.add(testLead1);
        ldList.add(testLead2);
        ldList.add(testLead3);
        insert ldList;   
        testLead2.Email='test22@test.com';
        testLead2.LeadSource='ZoomInfo';
        update testLead2;
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getOrgDefaults();
        processStage.Gating_Custom_SLA_Time__c='Default:2,ZoomInfo:60';
        processStage.Gating_Lead_Source__c='ZoomInfo';
        processStage.Routing_SLA_Time__c=30;
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        insert processStage;
        Id batchJobId = Database.executeBatch(new BatchJob_GatingProcessStageUpdate());
        Test.stopTest();
    }


}