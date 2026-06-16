@isTest
private class Test_PostCopyQueueEmailClean {
    @isTest
    static void testEmailClean() {
        Group queue = new Group(
            Type = 'Queue',
            Name = 'Test Queue',
            Email = 'mail@example.com'
        );

        insert queue;

        PostCopyTasks__c task = new PostCopyTasks__c(
            Name = 'Clean Queue Emails',
            DeveloperName__c = 'PostCopyQueueEmailClean',
            Active__c = true,
            OrderNumber__c = 1
        );

        insert task;

        Test.startTest();
        PostCopyManager manager = new PostCopyManager();
        Test.testSandboxPostCopyScript(manager, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), 'sandbox');
        Test.stopTest();

        Group cleanedQueue = [SELECT Id, Email
                                FROM Group 
                                WHERE Id =: queue.Id];

        System.assertEquals(null, cleanedQueue.Email, 'Queue Email field should be empty');
    }
}