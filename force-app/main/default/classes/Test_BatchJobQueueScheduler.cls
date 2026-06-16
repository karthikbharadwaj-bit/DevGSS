@isTest
private class Test_BatchJobQueueScheduler {
    @testSetup static void testSetup() {
        List<BatchJobQueue__c> testData = new List<BatchJobQueue__c>();
        List<BatchJobsConfiguration__c> bjcs = new List<BatchJobsConfiguration__c>();
        for (Integer i = 0; i < 5; i++) {
            BatchJobQueue__c batchJobQueue = new BatchJobQueue__c();
            batchJobQueue.BatchJobName__c = 'Test_BatchJob-' + i;
            batchJobQueue.Status__c = 'New';
            testData.add(batchJobQueue);

            BatchJobsConfiguration__c bjc = new BatchJobsConfiguration__c();
            bjc.Name = 'Test_BatchJob-' + i;
            bjc.ErrorEmailDistributionList__c = 'test@test.com';
            bjc.ChunkSizeLimit__c = 200 + i;
            bjcs.add(bjc);
        }

        insert testData;
        insert bjcs;
    }

    @isTest
    private static void testScheduleBatchQueueScheduler() {
        Test.startTest();
        String jobId = BatchJobQueueScheduler.scheduleBatchJobQueueScheduler();
        Test.stopTest();

        System.assert(jobId != null, 'The Scheduler should have returned a jobId successfully');
    }

    @isTest
    private static void testCreateInstance() {
        System.assert(
            BatchJobQueueScheduler.createInstance('BatchJob_Account') != null,
            'Instance should be created successfully'
        );

        try {
            BatchJobQueueScheduler.createInstance(null);
        } catch (BatchJobQueueException ex) {
            System.assert(
                ex.getMessage().contains('Class name value is required'),
                'Should throw exception, when the parameter is null'
            );
        }

        try {
            BatchJobQueueScheduler.createInstance('NameOfNonExistentClass');
        } catch (BatchJobQueueException ex) {
            System.assert(
                ex.getMessage().contains('Couldn\'t successfully instantiate an object for class '),
                'Should throw exception, when the object for class was not instantiated'
            );
        }
    }

    @isTest
    private static void testSendEmailWithFailedRecords() {
        User sysAdmin = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestAtt',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Att_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();
        BatchJobQueueSelector batchJobQueueSelector = new BatchJobQueueSelector();
        List<BatchJobQueue__c> batchJobQueues = batchJobQueueSelector.selectBatchJobQueueObjects().executeQuery();

        Boolean isSanbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;

        if (!isSanbox) {
            System.runAs(sysAdmin) {
                Integer beforeSending = Limits.getEmailInvocations();
                System.assertEquals(0, beforeSending, 'No email has been sent yet');
                BatchJobQueueScheduler.sendEmailWithFailedRecords(batchJobQueues[0], 'Some Exception message');
                Integer afterSending = Limits.getEmailInvocations();
                System.assertEquals(1, afterSending, 'An email should have been sent');
            }
        } else {
            try {
                BatchJobQueueScheduler.sendEmailWithFailedRecords(batchJobQueues[0], 'Some Exception message');
            } catch (EmailException ex) {
                System.assert(
                    ex.getMessage().contains('Single email is not enabled for your organization or profile'),
                    'Should throw email exception, when unit test is running in sandbox'
                );
            }
        }

        try {
            BatchJobQueueScheduler.sendEmailWithFailedRecords(batchJobQueues[0], null);
        } catch (BatchJobQueueException ex) {
            System.assert(
                ex.getMessage().contains('Exception message value is required'),
                'Should throw exception, when exception message is null'
            );
        }

        try {
            BatchJobQueueScheduler.sendEmailWithFailedRecords(null, 'test exception message');
        } catch (BatchJobQueueException ex) {
            System.assert(
                ex.getMessage().contains('Batch Job Queue object is required'),
                'Should throw exception, when the object is null'
            );
        }
    }

    @isTest
    private static void testBatchjobSchedulesDependingOnCustomSetting() { 
        BatchJobQueue__c bjq = (BatchJobQueue__c) new SObjectBuilder(BatchJobQueue__c.SObjectType)
                                .setField(BatchJobQueue__c.BatchJobName__c, 'BatchJob_Account')
                                .setField(BatchJobQueue__c.Status__c, 'New')
                                .create()
                                .getRecord();

        BatchJobsConfiguration__c bjc = (BatchJobsConfiguration__c) new SObjectBuilder(BatchJobsConfiguration__c.SObjectType)
                                .setField(BatchJobsConfiguration__c.Name, bjq.BatchJobName__c)
                                .setField(BatchJobsConfiguration__c.isBatchJobQueueDisabled__c, true)
                                .create()
                                .getRecord();
        Test.startTest();
        BatchJobQueueScheduler.scheduleBatchJobQueueScheduler();
        Test.stopTest();

        System.assert(!AsyncApexJobSvc.isJobRunning(bjq.BatchJobName__c), 'Batchjob should not be running');
    }
}