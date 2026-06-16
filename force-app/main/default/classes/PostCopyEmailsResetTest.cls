/*
* Name         : PostCopyEmailsResetTest.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Test class for the PostCopyEmailsReset. Part of the Sandbox Post Copy framework.
* Dependencies : PostCopyEmailsReset.cls, PostCopyWorker.cls
*/

@isTest
private class PostCopyEmailsResetTest {

    private static User refreshedUser;
    private static final String SANDBOX_NAME = 'box21';
    private static final String USER_NAME = 'fgzuser@aquivalabs.com';
    private static final String SECOND_USER_NAME = 'any.intesting@aquivalabs.com';
    private static final String PROFILE_NAME = 'Standard User';
    private static final String SYSTEM_PROFILE_NAME = 'System Administrator';

    //Create the custom settings with the apex classes that extends PostCopyWorker and let them run.
    @testSetup
    private static void createTestData(){
        List<PostCopyTasks__c> postCopyTaskList = new List<PostCopyTasks__c>();
        postCopyTaskList.add(createPostCopyTask('Reset User Emails', 'PostCopyEmailsReset', true, 1));
        insert postCopyTaskList;

        refreshedUser = createUser('fg');

        List<PostCopyEmailManagement__c> createPostCopyEmailChangeTaskList = new List<PostCopyEmailManagement__c>();
        createPostCopyEmailChangeTaskList.add(createPostCopyEmailChangeTask('1', SANDBOX_NAME, USER_NAME, PROFILE_NAME));
        createPostCopyEmailChangeTaskList.add(createPostCopyEmailChangeTask('2', SANDBOX_NAME, SECOND_USER_NAME, SYSTEM_PROFILE_NAME));
        insert createPostCopyEmailChangeTaskList;

    }

    private static PostCopyTasks__c createPostCopyTask(String name, String developerName, Boolean isActive, Integer orderNumber){
        return new PostCopyTasks__c(
            Name = name,
            DeveloperName__c = developerName,
            Active__c = isActive,
            OrderNumber__c = orderNumber
        );
    }

    private static PostCopyEmailManagement__c createPostCopyEmailChangeTask(String name, String sandboxes, String username, String profileName){
        return new PostCopyEmailManagement__c(
            Name = name,
            Sandboxes__c = sandboxes,
            Username__c = username,
            Profile__c = profileName
        );
    }

    private static User createUser(String name){
        User user = new User(
            isActive = true,
            Username = USER_NAME + '.' + SANDBOX_NAME,
            LastName = 'Test' + name,
            Email = name + '=aquivalabs.com@example.com', // fg=aquivalabs.com@example.com
            Alias = 'test' + name,
            PID__c = ('test' + name).capitalize(),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    //Verify that the email and the profile were changed after sandbox refresh
    @isTest static void testPostCopyEmailsResetInitials() {

        Test.startTest();
            PostCopyManager manager = new PostCopyManager();
            Test.testSandboxPostCopyScript(manager, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), SANDBOX_NAME);
        Test.stopTest();

        User testedUser = [SELECT ProfileId, Username, Email FROM User WHERE Username =: (USER_NAME + '.' + SANDBOX_NAME)];

        System.assertEquals(testedUser.Email , 'fg@aquivalabs.com');

    }

    @isTest static void testPostCopyEmailsResetCreateNewUser() {
        Test.startTest();
            PostCopyManager manager = new PostCopyManager();
            Test.testSandboxPostCopyScript(manager, UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), SANDBOX_NAME);
        Test.stopTest();

        User testedUser = [SELECT ProfileId, Username, Email FROM User WHERE Username =: (SECOND_USER_NAME + '.' + SANDBOX_NAME)];

        System.assertEquals(testedUser.Email , SECOND_USER_NAME);
    }

    @isTest static void testPostCopyEmailsResetCreateEmployee() {
        List<User> testedUser = [SELECT Id, FirstName, LastName, PID__c, Email FROM User WHERE Username =: (USER_NAME + '.' + SANDBOX_NAME)];

        Test.startTest();
            System.enqueueJob(new PostCopyEmailsReset.AsyncEmployeeCreator(testedUser, new PostCopyEmailsReset().getClassName()));
        Test.stopTest();

        Employee__c employee = [SELECT User__c FROM Employee__c LIMIT 1];

        System.assertEquals(employee.User__c , testedUser[0].Id);
    }

}