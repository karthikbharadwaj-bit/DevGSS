@isTest
public with sharing class CourseProgressSelectorTest {

    @TestSetup
    static void makeData() {
        skilljar__Course__c course = (skilljar__Course__c) new SObjectBuilder(skilljar__Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course__c.skilljar__Title__c => 'CDP Course',
                    skilljar__Course__c.skilljar__Skilljar_Id__c => '123456',
                    skilljar__Course__c.skilljar__Short_Description__c => 'This is a CDP Course test record',
                    skilljar__Course__c.CDP_Course__c => true
                }
            )
            .create()
            .getRecord();

        skilljar__Published_Course__c publishedCourse = (skilljar__Published_Course__c) new SObjectBuilder(skilljar__Published_Course__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Published_Course__c.skilljar__Course_Title__c => 'CDP Course',
                    skilljar__Published_Course__c.skilljar__Course_URL__c => 'https://fakeurl.com',
                    skilljar__Published_Course__c.skilljar__Domain__c => 'fakeurl',
                    skilljar__Published_Course__c.skilljar__Lesson_Count__c => 1,
                    skilljar__Published_Course__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Published_Course__c.skilljar__Course__c => course.Id
                }
            )
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test'
            })
            .create()
            .getRecord();
            
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'firstname',
                    Contact.LastName => 'lastname',
                    Contact.Email => 'fakeemail@gmail.com',
                    Contact.Phone => '12345678',
                    Contact.Phone_Ext__c => 123,
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.AccountId => acc.Id
                }
            )
            .create()
            .getRecord();

        skilljar__Student__c student = (skilljar__Student__c) new SObjectBuilder(skilljar__Student__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Student__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Student__c.skilljar__Contact__c => cont.Id,
                    skilljar__Student__c.skilljar__Email__c => 'fakeemail@gmail.com'
                }
            )
            .create()
            .getRecord();
            
        new SObjectBuilder(skilljar__Course_Progress__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    skilljar__Course_Progress__c.skilljar__Obfuscated_Id__c => '123456',
                    skilljar__Course_Progress__c.skilljar__Published_Course__c => publishedCourse.Id,
                    skilljar__Course_Progress__c.skilljar__Student__c => student.Id,
                    skilljar__Course_Progress__c.skilljar__Course__c => course.Id,
                    skilljar__Course_Progress__c.skilljar__Contact__c => cont.Id
                }
            )
            .create();
    }

    @isTest
    static void selectAllCDPCourses_whenThereIsOneCDPCourse_shouldRetrieveThatOne() {
        Assert.areEqual(1, new CourseProgressSelector().selectAllCDPCourses().executeQuery().size(), 'Invalid size');
    }
    
    @isTest
    static void selectCompletedCDPCourses_whenThereIsOneCDPCourse_shouldRetrieveThatOne() {
        skilljar__Course_Progress__c courseProgress = (skilljar__Course_Progress__c) new CourseProgressSelector().selectAllCDPCourses().executeQuery()[0];
        courseProgress.skilljar__Completed_At__c = Datetime.now();
        update courseProgress;
        Assert.areEqual(1, new CourseProgressSelector().selectCompletedCDPCourses().executeQuery().size(), 'Invalid size');
    }

    @isTest
    static void selectCompletedCDPCoursesByContactId_whenThereIsOneCDPCourse_shouldRetrieveThatOne() {
        skilljar__Course_Progress__c courseProgress = (skilljar__Course_Progress__c) new CourseProgressSelector().selectAllCDPCourses().executeQuery()[0];
        courseProgress.skilljar__Completed_At__c = Datetime.now();
        update courseProgress;
        Test.startTest();
        Contact[] contacts = (Contact[]) new ContactSelector().selectContacts().executeQuery();
        Test.stopTest();
        Assert.areEqual(1, new CourseProgressSelector().selectCompletedCDPCoursesByContactId(new Object[]{contacts}).executeQuery().size(), 'Invalid size');
    }
}