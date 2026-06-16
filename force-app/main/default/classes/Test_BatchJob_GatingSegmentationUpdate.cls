@isTest
public class Test_BatchJob_GatingSegmentationUpdate {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGatingSegmentationUpdate() {
        Test.startTest();
        List<Lead> ldList = new List<Lead>();
        Segment_Master__c seg = new Segment_Master__c();
        seg.Name = 'SOHO';
        seg.Max__c = 19;
        seg.Min__c = 1;
        seg.Country__c = 'United States';
        seg.Start_Date__c = System.today();
        insert seg;
        Account testAccount1 = new Account();
        testAccount1.Name = 'Test123';
        testAccount1.SignupType__c = 'TRIAL_30NOCC';
        testAccount1.RC_Account_Status__c = 'TRIAL';
        testAccount1.SignupPlatform__c = 'WEB';
        testAccount1.RC_Service_name__c = 'office123';
        testAccount1.RC_Activation_Date__c = null;
        testAccount1.Partner_ID__c = '9852';
        testAccount1.ZI_Id__c = '12345';
        insert testAccount1;
        Lead testLead1 = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Email = 'test@test.com',
            SFDC_enriched_date_time__c = null,
            SegmentName__c = null,
            Enrichment_Last_Processed_Date__c = System.now(),
            LS_Status__c = 'Success'
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
            ZI_CDP_Account_Id__c = testAccount1.Id,
            SFDC_enriched_date_time__c = null,
            SegmentName__c = null,
            Enrichment_Last_Processed_Date__c = System.now(),
            LS_Status__c = 'Success'
        ); 
        ldList.add(testLead1);
        ldList.add(testLead2);
        ldList.add(testLead3);
        insert ldList;   
        testLead2.Email='test22@test.com';
        testLead2.LeadSource='ZoomInfo';
        update testLead2;
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        processStage.Gating_Custom_SLA_Time__c='Default:2,ZoomInfo:60';
        processStage.Gating_Lead_Source__c='ZoomInfo';
        processStage.Routing_SLA_Time__c=30;
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        insert processStage;
        Id batchJobId = Database.executeBatch(new BatchJob_GatingSegmentationUpdate());
        Test.stopTest();
    }


}