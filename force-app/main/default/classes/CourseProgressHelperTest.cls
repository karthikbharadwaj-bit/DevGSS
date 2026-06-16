@isTest
public class CourseProgressHelperTest {

    @TestSetup
    static void makeData(){
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
                    skilljar__Course_Progress__c.skilljar__Obfuscated_Id__c => ValueProviderBuilder.provideList(new String[]{'123456','12345'}),
                    skilljar__Course_Progress__c.skilljar__Published_Course__c => publishedCourse.Id,
                    skilljar__Course_Progress__c.skilljar__Student__c => student.Id,
                    skilljar__Course_Progress__c.skilljar__Course__c => course.Id,
                    skilljar__Course_Progress__c.skilljar__Contact__c => cont.Id
                }
            )
            .quantity(2)
            .create();
    }

    @isTest
    static void calculateCDPStatus_whenStatusShouldBeComplete_shouldBeOk(){
        Test.startTest();
            String newCDPStatus = CourseProgressHelper.calculateCDPStatus(1, '');
        Test.stopTest();

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_INCOMPLETE, newCDPStatus, 'Invalid CDP Status');
    }

    @isTest
    static void calculateCDPStatus_whenStatusShouldBeIncomplete_shouldBeOk(){
        Test.startTest();
            String newCDPStatus = CourseProgressHelper.calculateCDPStatus(2, 'Incomplete');
        Test.stopTest();

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_COMPLETE, newCDPStatus, 'Invalid CDP Status');
    }

    @isTest
    static void calculateCDPStatus_whenStatusShouldBeNone_shouldBeOk(){
        Test.startTest();
            String newCDPStatus = CourseProgressHelper.calculateCDPStatus(0, 'Complete');
        Test.stopTest();

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_NONE, newCDPStatus, 'Invalid CDP Status');
    }

    @isTest
    static void updateAccountCertifiedDeliveryPartnerStatusField_whenCDPStatusFieldMustUpdateToIncomple_shouldUpdateFieldValue(){
        List<skilljar__Course_Progress__c> coursesProgresses = (List<skilljar__Course_Progress__c>) new CourseProgressSelector()
            .selectAllCDPCourses()
            .executeQuery();

        Test.startTest();
            coursesProgresses[0].skilljar__Completed_At__c = Datetime.now();
            update coursesProgresses;
        Test.stopTest();

        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_INCOMPLETE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }

    @isTest
    static void updateAccountCertifiedDeliveryPartnerStatusField_whenCDPStatusFieldMustUpdateToComplete_shouldUpdateFieldValue(){
        List<skilljar__Course_Progress__c> coursesProgresses = (List<skilljar__Course_Progress__c>) new CourseProgressSelector()
            .selectAllCDPCourses()
            .executeQuery();

        Test.startTest();
            coursesProgresses[0].skilljar__Completed_At__c = Datetime.now();
            coursesProgresses[1].skilljar__Completed_At__c = Datetime.now();
            update coursesProgresses;
        Test.stopTest();

        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_COMPLETE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }

    @isTest
    static void updateAccountCertifiedDeliveryPartnerStatusField_whenCDPStatusFieldMustUpdateToNone_shouldUpdateFieldValue(){
        List<skilljar__Course_Progress__c> coursesProgresses = (List<skilljar__Course_Progress__c>) new CourseProgressSelector()
            .selectAllCDPCourses()
            .executeQuery();

        coursesProgresses[0].skilljar__Completed_At__c = Datetime.now();
        update coursesProgresses;
        Test.startTest();
            coursesProgresses[0].skilljar__Completed_At__c = null;
            update coursesProgresses;
        Test.stopTest();

        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_NONE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }

    @isTest
    static void updateAccountCertifiedDeliveryPartnerStatusField_whenCourseProgressIsDeleted_shouldUpdateFieldValue(){
        List<skilljar__Course_Progress__c> coursesProgresses = (List<skilljar__Course_Progress__c>) new CourseProgressSelector()
            .selectAllCDPCourses()
            .executeQuery();

        coursesProgresses[0].skilljar__Completed_At__c = Datetime.now();
        update coursesProgresses;
        Test.startTest();
            delete coursesProgresses;
        Test.stopTest();

        Account acc = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];

        Assert.areEqual(CourseProgressHelper.CDP_STATUS_NONE, acc.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }

    @isTest
    static void updateAccountCertifiedDeliveryPartnerStatusField_whenCourseProgressContactFieldValueChange_shouldUpdateFieldValue(){
        List<skilljar__Course_Progress__c> coursesProgresses = (List<skilljar__Course_Progress__c>) new CourseProgressSelector()
            .selectAllCDPCourses()
            .executeQuery();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'test2'
            })
            .create()
            .getRecord();
            
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'firstname2',
                    Contact.LastName => 'lastnam2e',
                    Contact.Email => 'fakeemail2@gmail.com',
                    Contact.Phone => '12345672',
                    Contact.Phone_Ext__c => 321,
                    Contact.Contact_Status__c => '2. Contacted',
                    Contact.AccountId => acc.Id
                }
            )
            .create()
            .getRecord();

        coursesProgresses[0].skilljar__Completed_At__c = Datetime.now();
        coursesProgresses[1].skilljar__Completed_At__c = Datetime.now();
        update coursesProgresses;
        Test.startTest();
            coursesProgresses[0].skilljar__Contact__c = cont.Id;
            coursesProgresses[1].skilljar__Contact__c = cont.Id;
            update coursesProgresses;
        Test.stopTest();
            
        Account acc1 = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test2'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];
        
        Assert.areEqual(CourseProgressHelper.CDP_STATUS_COMPLETE, acc1.Certified_Delivery_Partner_Status__c, 'Invalid value');

        Account acc2 = (Account) new AccountSelector()
            .selectAccountByName(new Object[]{'test'})
            .selectFields(new List<String>{'Certified_Delivery_Partner_Status__c'})
            .executeQuery()[0];
        
        Assert.areEqual(CourseProgressHelper.CDP_STATUS_NONE, acc2.Certified_Delivery_Partner_Status__c, 'Invalid value');
    }
}