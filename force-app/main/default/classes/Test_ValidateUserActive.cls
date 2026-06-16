@isTest
public class Test_ValidateUserActive {
    
    @testSetup
    static void setup() {
        List<License_Harvesting__c> licenses = new List<License_Harvesting__c>();
        for (Integer i = 0; i < 10; i++) {
            licenses.add(new License_Harvesting__c(Is_Active__c = false));
        }
        insert licenses;
        
        User usr = new User(
            Username = 'testuser858@test.com',
            LastName = 'User',
            Email = 'testuser858@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert usr;
        
        User inactiveUsr = new User(
            Username = 'inactiveuser765@test.com',
            LastName = 'Inactive',
            Email = 'inactiveuser765@test.com',
            Alias = 'iuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            IsActive = false
        );
        insert inactiveUsr;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSaveTodoRecordWithTestContext() {
        License_Harvesting__c lhc = [SELECT Id, User_ID__c FROM License_Harvesting__c LIMIT 1];

        Test.startTest();
		validateUserActive.saveTodoRecord();
        Test.stopTest();
     }
    
    @isTest
    static void testUpdateActive() {
        List<License_Harvesting__c> licenses = [SELECT Id FROM License_Harvesting__c LIMIT 5];
        List<Id> licenseIds = new List<Id>();
        for (License_Harvesting__c license : licenses) {
            licenseIds.add(license.Id);
        }
        
        Test.startTest();
        validateUserActive.updateActive(licenseIds);
        Test.stopTest();
        
        licenses = [SELECT Is_Active__c, Last_Login_Date__c FROM License_Harvesting__c WHERE Id IN :licenseIds];
        for (License_Harvesting__c license : licenses) {
            System.assertEquals(true, license.Is_Active__c);
            System.assertNotEquals(null, license.Last_Login_Date__c);
        }
    }
    
    @isTest
    static void testGetUser() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser858@test.com' LIMIT 1];
        
        User result = validateUserActive.getUser(testUser.Id);
        
        System.assertEquals(testUser.Id, result.Id);
    }
    
    @isTest
    static void testActivateUser() {
        User testUser = [SELECT Id, IsActive FROM User WHERE Username = 'inactiveuser765@test.com' LIMIT 1];
        
        Test.startTest();
        validateUserActive.activateUser(testUser);
        Test.stopTest();
        
        User updatedUser = [SELECT IsActive FROM User WHERE Id = :testUser.Id];
        System.assertEquals(true, updatedUser.IsActive);
    }
}