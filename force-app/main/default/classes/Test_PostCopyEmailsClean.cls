/**
 * Created by : Alexander Savickiy,
 * Created date : 05.03.2018,
 * Description : Test class for the PostCopyEmailsClean. Part of the Sandbox Post Copy framework.,
 * Dependencies : PostCopyEmailsClean.cls, PostCopyWorker.cls
 */
@isTest
public with sharing class Test_PostCopyEmailsClean {
    //Create the custom settings with the apex classes that extends PostCopyWorker and let them run.
    @testSetup
    private static void createTestData() {
        List<PostCopyTasks__c> postCopyTaskList = new List<PostCopyTasks__c>();
        postCopyTaskList.add(createPostCopyTask('Clean User Emails', 'PostCopyEmailsClean', true, 3));
        insert postCopyTaskList;

        List<Emails__c> emailsCustomSetting = new List<Emails__c>();
        emailsCustomSetting.add(new Emails__c(Name = 'test', Email_Address__c = 'test@gmail.com'));
        insert emailsCustomSetting;
    }

    private static PostCopyTasks__c createPostCopyTask(String name, String developerName, Boolean isActive, Integer orderNumber){
        return new PostCopyTasks__c(
                Name = name,
                DeveloperName__c = developerName,
                Active__c = isActive,
                OrderNumber__c = orderNumber
        );
    }
    //Verify that the Email_Address__c is cleaned after sandbox refresh
    @isTest
    private static void testPostEmailsClean() {

        Test.startTest();
            Test.testSandboxPostCopyScript(new PostCopyManager(), UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        Test.stopTest();

        List<Emails__c> emailsCustomSettingAfterRefresh = Emails__c.getall().values();
        for (Emails__c settingRecord : emailsCustomSettingAfterRefresh) {
            System.assertEquals(null, settingRecord.Email_Address__c);
        }
    }
}