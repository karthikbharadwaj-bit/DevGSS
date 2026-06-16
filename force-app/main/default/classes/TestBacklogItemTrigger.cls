/**
 * Created by Artem Ignatov on 26.07.2016.
 */
@isTest
public class TestBacklogItemTrigger{

    @isTest
    private static void commonTest() {
        Sprints__c testSprint = new Sprints__c(Name = 'testSprint', Start_Date__c = system.today(), End_Date__c = system.today().addDays(2));
        insert testSprint;

        List<Backlog_item__c> listBli = new List<Backlog_item__c>();
        listBli.add(new Backlog_item__c(Story_Points__c = '1', Sprint__c = testSprint.Id));
        listBli.add(new Backlog_item__c(Story_Points__c = '1', Sprint__c = testSprint.Id));
        listBli.add(new Backlog_item__c(Story_Points__c = '1', Sprint__c = testSprint.Id));
        listBli.add(new Backlog_item__c(Story_Points__c = '1', Sprint__c = testSprint.Id));
        insert listBli;

        delete listBli[3];

        Backlog_item__c bliToUndelete = listBli[2];
        delete bliToUndelete;
        undelete bliToUndelete;

        Backlog_item__c bliToUpdate = listBli[1];
        bliToUpdate.Story_Points__c = '5';

        update bliToUpdate;

        List<Sprints__c> checkSprint = [SELECT Total_Story_Points__c FROM Sprints__c WHERE Id = :testSprint.Id];
        System.assertEquals(checkSprint[0].Total_Story_Points__c, 7);
    }

    @isTest
    static void testPostDeploymentTasksToggle() {
        User owner = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
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
            
        RingCentralVariousSettings__c settings = (RingCentralVariousSettings__c) new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                    RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10,
                    RingCentralVariousSettings__c.Release_Engineer_User_Id__c => owner.Id
                }
            )
            .create()
            .getRecord();

        Backlog_item__c bi = new Backlog_item__c();
        insert bi;

        bi.Administrative_tasks__c = 'Do PDS';
        update bi;

        List<Task> createdTasks = [SELECT Id FROM Task WHERE WhatId =: bi.Id];

        System.assertEquals(3, createdTasks.size(), '3 tasks for Post Deployments Steps are not created');

        bi.Administrative_tasks__c = '';
        update bi;

        List<Task> deletedTasks = [SELECT Id FROM Task WHERE WhatId =: bi.Id];
        System.assertEquals(0, deletedTasks.size(), 'There should be no tasks for Post Deployments Steps');
    }
}