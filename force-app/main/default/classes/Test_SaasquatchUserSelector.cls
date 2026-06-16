@isTest
private with sharing class Test_SaasquatchUserSelector {

    @isTest
    static void testSelectUserByReferralCode() {
        Test.startTest();
        saasquatch__SaaSquatch_User__c  testMatchByCode = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c  => 'CODE1234',
                    saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
					saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        List<saasquatch__SaaSquatch_User__c> users = (List<saasquatch__SaaSquatch_User__c>) new SaasquatchUserSelector()
            .selectUsersByReferralCode(new List<Object> {new List<String> {'CODE1234'}})
            .executeQuery();

        System.assertEquals(1, users.size(), '1 User should have been found');
        System.assertEquals('TestingMock', users[0].saasquatch__First_Name__c , 'Matched user name is not ok');
    }

    @isTest
    static void testSelectUsersByContactCode() {
        Test.startTest();
        saasquatch__SaaSquatch_User__c  testMatchByCode = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c  => 'CODE1234',
                    saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
					saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        Contact ct = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.Email, 'test@test.com')
            .setField(Contact.UK_Saasquatch_Referral_Code__c, 'TESTCODE')
            .create()
            .getRecord();
        testMatchByCode.saasquatch__Contact__c = ct.Id;
        update testMatchByCode;
        
        List<String> advocateIdsToMatchByContact = new List<String> {'TESTCODE'};
        String condition = 'saasquatch__Contact__r.UK_Saasquatch_Referral_Code__c IN :bind0';
        
        List<saasquatch__SaaSquatch_User__c> users = (List<saasquatch__SaaSquatch_User__c>) new SaasquatchUserSelector()
            .selectUsersByContactCode(new List<Object> {advocateIdsToMatchByContact}, condition)
            .executeQuery();

        System.assertEquals(1, users.size(), '1 User should have been found');
        System.assertEquals('TESTCODE', users[0].saasquatch__Contact__r.UK_Saasquatch_Referral_Code__c , 'Matched user is not ok');
    }

    @isTest
    static void testSelectUsersById() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        saasquatch__SaaSquatch_User__c  testMatchById = (saasquatch__SaaSquatch_User__c) new SObjectBuilder(saasquatch__SaaSquatch_User__c.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c => 'TestingMock',
                    saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c  => 'CODE1234',
                    saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c => 'test.test@gmail.com',
					saasquatch__SaaSquatch_User__c.saasquatch__Email__c => 'test.test@gmail.com',
                    saasquatch__SaaSquatch_User__c.saasquatch__SaaSquatch_Combined_User_Id__c => 'test.test@gmail.com/test.test@gmail.com'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        
        List<saasquatch__SaaSquatch_User__c> users = (List<saasquatch__SaaSquatch_User__c>) new SaasquatchUserSelector()
            .selectUsersById(new List<Object> {new List<String> {testMatchById.Id}})
            .executeQuery();

        System.assert(users.size() == 1, '1 User should have been found');
        System.assertEquals(testMatchById.Id, users[0].Id , 'Matched User Id is not OK');
    }
}