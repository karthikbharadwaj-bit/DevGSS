@isTest
public class Test_ContactLeadQualificationController {
    
    private class STCControllerHelperConcrete extends STCControllerHelper {
    }

    Static Account CreateAccount(){
        Account testAcc = new Account(Name = 'Test Account');
        Insert testAcc;
        return testAcc;
    }
    
    static Contact createContact(Account testAcc){
        Contact testCon = new Contact(Email = 'fake@email.com',
                                     LastName = 'test_Doe',
                                     Phone = '9098760000',
                                     AccountId = testAcc.Id,
                                     Preferred_Language__c = 'en_US',
                                     CurrencyIsoCode = 'USD');
        insert testCon;
        return testCon;
    }
    
    static Lead_Qualification__c createLeadQualificaton(Contact testCon){
        Lead_Qualification__c lq = new Lead_Qualification__c();
        lq.Contact__c = testCon.Id;
        Insert lq;
        return lq;
    }
    
    static ContactLeadQualificationController createController(Contact controllerContact) {
		return new ContactLeadQualificationController(new ApexPages.StandardController(controllerContact));
	}
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void LeadQualificationControllerCreation(){
        Account testAcc = createAccount();
        Contact testCon = createContact(testAcc);
        Lead_Qualification__c lq = createLeadQualificaton(testCon);
        PageReference currentPage = Page.ContactLeadQualification;
		currentPage.getParameters().put('id', testCon.Id);
		Test.setCurrentPage(currentPage);
        ContactLeadQualificationController controller = createController(testCon);
    }
    
    @isTest
    private static void testSalesInsideProfileUser(){
        Account testAcc = createAccount();
        Contact testCon = createContact(testAcc);
        Lead_Qualification__c lq = createLeadQualificaton(testCon);
        User us = (User) new SObjectBuilder (User.SObjectType)        
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
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Sales Manager w Insidesales'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();
        System.runAs(us) {
            Test.startTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(testCon);
                ContactLeadQualificationController controller = new ContactLeadQualificationController(sc);
            Test.stopTest();

            System.assertEquals(controller.isSalesProfile,
                                false,
                                'Sales profile was not assigned correctly to user.');
            System.assertEquals(controller.isInsideSalesProfile,
                                true,
                                'Inside Sales profile was not assigned correctly to user.');
        }
    }

    @isTest
    private static void testSalesProfileUser(){
        Account testAcc = createAccount();
        Contact testCon = createContact(testAcc);
        Lead_Qualification__c lq = createLeadQualificaton(testCon);
        User us = (User) new SObjectBuilder (User.SObjectType)        
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
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'Channel Sales - Lightning'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();

        System.runAs(us) {
            Test.startTest();
                ApexPages.StandardController sc = new ApexPages.StandardController(testCon);
                ContactLeadQualificationController controller = new ContactLeadQualificationController(sc);
            Test.stopTest();

            System.assertEquals(controller.isSalesProfile,
                                true,
                                'Sales profile was not assigned correctly to user.');
            System.assertEquals(controller.isInsideSalesProfile,
                                false,
                                'Inside Sales profile was not assigned correctly to user.');
        }
    }

    @isTest
    static void testOffset() {
        STCControllerHelperConcrete helper = new STCControllerHelperConcrete();
        Double offsetValue = helper.offset;
       
        System.assertNotEquals(null, offsetValue);
        System.assert(offsetValue >= -1 && offsetValue <= 1);
    }

    @isTest
    static void testHistoryWrapperProperties() {
        STCControllerHelper helper = new STCControllerHelperConcrete();
        helper.showEdit();
        helper.hideEdit();

        Datetime testDate = Datetime.now();
        STCControllerHelper.HistoryWrapper hw = new STCControllerHelper.HistoryWrapper('Test User', 'Test Field', testDate);
   
        System.assertEquals('Test User', hw.changer);
        System.assertEquals('Test Field', hw.fieldName);
        System.assertEquals(testDate, hw.modifyDate);
    }
}