@isTest
private class Test_CalculateAccountHierarchyBatch {
    private static String BATCH_NAME = 'CalculateAccountHierarchyBatch';
    private static String RC_ACC_STATUS_PAID = 'Paid';
    private static String STATUS_NEW = 'New';
    private static String STATUS_FAILED = 'Failed';
    private static String CUSTOMER_ACCOUNT = 'Customer Account';
    private static Boolean isTestRun = false;
    private static String whereClause = ' ';

    @isTest
    private static void testSendEmailWithFailedRecords() {
        BatchJobsConfiguration__c bjc = (BatchJobsConfiguration__c) new SObjectBuilder(BatchJobsConfiguration__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    BatchJobsConfiguration__c.Name => BATCH_NAME,
                    BatchJobsConfiguration__c.ErrorEmailDistributionList__c => 'test@test.com'
                    }
                )
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Number_of_DL_s__c, 4)
            .setField(Account.RC_Account_Status__c, RC_ACC_STATUS_PAID)
            .create()
            .getRecord();
        List<sObject> scope = new List<sObject>();
        scope.add((sObject) testAcc);
        Set<String> ultimateParentIdSetToQuery = new Set<String>();
        ultimateParentIdSetToQuery.add(testAcc.id);
        Database.BatchableContext BC;

        BatchJobQueue__c batchQueue = (BatchJobQueue__c) new SObjectBuilder(BatchJobQueue__c.sObjectType)
            .setField(BatchJobQueue__c.Status__c, STATUS_FAILED)
            .setField(BatchJobQueue__c.BatchJobName__c, BATCH_NAME)
            .setField(BatchJobQueue__c.RecordIdsToBeProcessedInQueue__c, testAcc.id)
            .create()
            .getRecord();
        testAcc.Name = null;
        AccountTriggerHelperExt.calculateAccountHierarchyTotalDLS(new List<Account>{testAcc});

        List<Object> bindings = new List<Object>{batchQueue.id};
        BatchJobQueueSelector bjqSelector = new BatchJobQueueSelector();
        BatchJobQueue__c batchQueuetest = (BatchJobQueue__c) bjqSelector
            .selectBatchJobQueueExceptionById(bindings)
            .executeQuery()
            .get(0);
        Test.startTest();
        try {
            Integer beforeSending = Limits.getEmailInvocations();
            System.assertEquals(0, beforeSending, 'No email has been sent yet');
            CalculateAccountHierarchyBatch batchjob = new CalculateAccountHierarchyBatch(ultimateParentIdSetToQuery, batchQueuetest.id, isTestRun);
            batchjob.start(BC);
            batchjob.execute(BC, scope);
            batchjob.finish(BC);
            CalculateAccountHierarchyBatch.sendEmailWithFailedRecords(batchQueuetest);
            Integer afterSending = Limits.getEmailInvocations();
            Test.stopTest();
            System.assertEquals(2, afterSending, 'An email should have been sent');
        } catch (Exception ex) {
            ExceptionHelper.checkIsMassEmailException(ex);
        }
    } 

    @isTest
    private static void testEmptyConstructorSearchesForIdsToProcess() { 
        Set<String> ultimateParentIdSetToQuery = new Set<String>();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                                .create()
                                .getRecord();
        String idToProcess = Id.valueOf(acc.Id);
        ultimateParentIdSetToQuery.add(acc.Id);

        BatchJobQueue__c bjq = (BatchJobQueue__c) new SObjectBuilder(BatchJobQueue__c.SObjectType)
                                .setField(BatchJobQueue__c.BatchJobName__c, BATCH_NAME)
                                .setField(BatchJobQueue__c.Status__c, STATUS_NEW)
                                .setField(BatchJobQueue__c.RecordIdsToBeProcessedInQueue__c, idToProcess)
                                .create()
                                .getRecord();
        Test.startTest();
        CalculateAccountHierarchyBatch batchjob = new CalculateAccountHierarchyBatch();
        // constructors test
        CalculateAccountHierarchyBatch firstInstance = new CalculateAccountHierarchyBatch(isTestRun);
        CalculateAccountHierarchyBatch SecondInstance = new CalculateAccountHierarchyBatch(whereClause, isTestRun);
        CalculateAccountHierarchyBatch ThirdInstance = new CalculateAccountHierarchyBatch(ultimateParentIdSetToQuery, isTestRun);
        CalculateAccountHierarchyBatch FourthInstance = new CalculateAccountHierarchyBatch(ultimateParentIdSetToQuery, bjq.id, isTestRun);

        List<Account> accounts = Database.query(batchjob.queryString);
        Test.stopTest();

        System.assert(accounts.size() == 1, 
                            'The batchjob should query only the record to be processed');
        System.assertEquals(acc.Id, accounts[0].Id, 
                            'The batchjob didnt query the correct record');
    }
}