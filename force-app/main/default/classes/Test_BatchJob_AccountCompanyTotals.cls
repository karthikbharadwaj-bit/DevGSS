@isTest
private class Test_BatchJob_AccountCompanyTotals {

    private static Account_Hierarchy__c getAccountHierarchyByName(String name){
        return [SELECT Id, Name, AH_Total_DLs__c, AH_Total_MRR__c
                FROM Account_Hierarchy__c
                WHERE Name =: name][0];
    }

    @isTest
    private static void testCompanyTotalsShouldBeCalculatedAfterProcessingBatchJob(){
        Account_Hierarchy__c accountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Name => 'testAccountHierarchy'
                }
            )
            .create()
            .getRecord();

        Account account = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAccount',
                    Account.AH_Name__c => accountHierarchy.Id,
                    Account.Number_of_DL_s__c => 1
                }
            )
            .create()
            .getRecord();

        BatchJob_AccountCompanyTotals batchToTest = new BatchJob_AccountCompanyTotals();

        test.startTest();
            Id batchId = Database.executeBatch(batchToTest);
        test.stopTest();

        Account_Hierarchy__c accountHierarchyAfterProcessing = getAccountHierarchyByName(accountHierarchy.Name);

        System.assertEquals(1, accountHierarchyAfterProcessing.AH_Total_DLs__c, 
            'Number_of_DL_s__c should be calculated correctly');
    }

    @isTest
    private static void testSchedulerShouldReturnAJobIdSuccessfully(){
        String everyDayAt12Am = '0 0 12 1/1 * ? *';
        BatchJob_AccountCompanyTotals batchToTest = new BatchJob_AccountCompanyTotals();
        
        test.startTest();
            String jobId = System.schedule('Batch Job Account Company Totals Scheduler', everyDayAt12Am, batchToTest);
        test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }
}