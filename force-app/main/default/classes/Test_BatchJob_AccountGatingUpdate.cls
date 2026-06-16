@isTest
public class Test_BatchJob_AccountGatingUpdate {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAccountGatingUpdate() {
        Test.startTest();
        List<Account> accList = new List<Account>();
        Account acc1 = new Account(
            Name = 'Gating',
            Website = 'gating.com'
        );
        Account acc2 = new Account(
            Name = 'Gating2',
            Website = 'gating2.com'
        );
        Account acc3 = new Account(
            Name = 'Gating3',
            Website = 'gating3.com'
        ); 
        accList.add(acc1);
        accList.add(acc2);
        accList.add(acc3);
        insert accList;   
        acc2.Website='gating33.com';
        acc3.LS_Status__c='Success';
        acc3.LS_Enrichment_Date__c=System.today();
        update acc2;
        update acc3;
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getOrgDefaults();
        processStage.Gating_Custom_SLA_Time__c='Default:2,ZoomInfo:60';
        processStage.Gating_Lead_Source__c='ZoomInfo';
        processStage.Routing_SLA_Time__c=30;
        processStage.Bypass_Gating_Process_Stage__c = false;
        processStage.Bypass_Enrichment_Process__c = false;
        insert processStage;
        Id batchJobId = Database.executeBatch(new BatchJob_AccountGatingUpdate());
        Test.stopTest();
    }

}