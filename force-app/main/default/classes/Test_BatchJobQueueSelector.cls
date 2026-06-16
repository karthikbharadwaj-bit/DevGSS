@isTest
private class Test_BatchJobQueueSelector {
    @testSetup static void testSetup() {
        List<BatchJobQueue__c> testStaging = new SObjectFactory()
            .create(
                BatchJobQueue__c.SObjectType,
                5,
                new Map<SObjectField, Object> {
                    BatchJobQueue__c.BatchJobName__c => ValueProviderBuilder.provideUniqueString(),
                    BatchJobQueue__c.Status__c => 'New'
                }
            );
    }

    @isTest
    private static void testSelectByStatusForSpaceCheck() {
        BatchJobQueueSelector batchJobQueueSelector = new BatchJobQueueSelector();
        List<BatchJobQueue__c> bjqsFromQuery = [SELECT Id, BatchJobName__c, Status__c FROM BatchJobQueue__c];
        List<BatchJobQueue__c> bjqsFromSelector = batchJobQueueSelector.selectBatchJobQueueObjects().executeQuery();
        System.assert(bjqsFromSelector.size() == 5, 'Size should be 5');
        System.assertEquals(
            bjqsFromQuery.size(),
            bjqsFromSelector.size(),
            'Should be 5, because 5 objects were created with \'New\' status'
        );
    }
}