@isTest
private class TestAccountHierarchyData {

    private static List<Account_Hierarchy__c> getAllAccountHierarchies(){
        return [SELECT Id, D_U_N_S_Number__c, Name
            FROM Account_Hierarchy__c];
    }

    private static Account_Hierarchy__c getAccountHierarchyByDunsNumber(String dunsNumber, 
        List<Account_Hierarchy__c> accountHierarchies){
            
        for(Account_Hierarchy__c accountHierarchy : accountHierarchies){
            if(accountHierarchy.D_U_N_S_Number__c == dunsNumber){
                return accountHierarchy;
            }
        }
        return null;
    }

    @isTest
    private static void testInsertAccountHierarchiesShouldInsertSuccessfully(){
        Account_Hierarchy__c accHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .build()
            .getRecord();
        List<Account_Hierarchy__c> accountHierarchiesToInsert = 
            new List<Account_Hierarchy__c>{accHierarchy};
        
        AccountHierarchyData.IAccountHierarchyData accountHierarchyData = new AccountHierarchyData();
        Test.startTest();
            accountHierarchyData.insertAccountHierarchies(accountHierarchiesToInsert);
        Test.stopTest();

        System.assert(accountHierarchiesToInsert[0].Id != null, 
            'Account Hierarchy should be inserted successfully');
    }

    @isTest
    private static void testGetAccountHierarchiesByDunsNumberShouldReturnResultSuccessfully(){
        String dunsNumber = '12345';
        Account_Hierarchy__c ahToReturn = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.D_U_N_S_Number__c => dunsNumber,
                    Account_Hierarchy__c.Company_Status__c => 'teststatus'
                }
            )
            .build()
            .getRecord();
        Account_Hierarchy__c accHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .build()
            .getRecord();
        List<Account_Hierarchy__c> accountHierarchiesToInsert = 
            new List<Account_Hierarchy__c>{accHierarchy, ahToReturn};
        insert accountHierarchiesToInsert;

        AccountHierarchyData.IAccountHierarchyData accountHierarchyData = new AccountHierarchyData();
        
        Test.startTest();
            List<Account_Hierarchy__c> ahReturned = accountHierarchyData.getAccountHierarchiesByDunsNumber(
                new Set<String>{dunsNumber});
        Test.stopTest();

        System.assertEquals(1, ahReturned.size(), 
            'Only one Account_Hierarchy__c should be returned');

        System.assertEquals(dunsNumber, ahReturned[0].D_U_N_S_Number__c, 
            'Account_Hierarchy__c should be returned correctly finding by duns number');
    }

    @isTest
    private static void testGetAccountHierarchiesByDunsCountryDomainShouldReturnResultSuccessfully(){
        String countryDomain = 'United States|yahoo.com';
        Account_Hierarchy__c ahToReturn = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Country_Domain__c => countryDomain,
                    Account_Hierarchy__c.Company_Status__c => 'teststatus'
                }
            )
            .build()
            .getRecord();
        Account_Hierarchy__c accHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .build()
            .getRecord();
        List<Account_Hierarchy__c> accountHierarchiesToInsert = 
            new List<Account_Hierarchy__c>{accHierarchy, ahToReturn};
        insert accountHierarchiesToInsert;

        AccountHierarchyData.IAccountHierarchyData accountHierarchyData = new AccountHierarchyData();
        
        Test.startTest();
            List<Account_Hierarchy__c> ahReturned = accountHierarchyData.getAccountHierarchiesByCountryDomain(
                new Set<String>{countryDomain});
        Test.stopTest();

        System.assertEquals(1, ahReturned.size(), 
            'Only one Account_Hierarchy__c should be returned');

        System.assertEquals(countryDomain, ahReturned[0].Country_Domain__c, 
            'Account_Hierarchy__c should be returned correctly finding by country domain');
    }

    @isTest
    private static void testGetAccountHierarchiesByIdShouldReturnResultSuccessfully(){
        Account_Hierarchy__c ahToReturn = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .create()
            .getRecord();
        
        AccountHierarchyData.IAccountHierarchyData accountHierarchyData = new AccountHierarchyData();
        
        Test.startTest();
            List<Account_Hierarchy__c> ahReturned = accountHierarchyData.getAccountHierarchiesById(
                new Set<Id>{ahToReturn.Id});
        Test.stopTest();

        System.assertEquals(1, ahReturned.size(), 
            'Only one Account_Hierarchy__c should be returned');
    }

    @isTest
    private static void testMocksShouldReturnExpectedResults() {
        String dunsNumber = '12345';
        String countryDomain = 'United States|yahoo.com';
        Account_Hierarchy__c ahToReturn = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.D_U_N_S_Number__c => dunsNumber
                }
            )
            .build()
            .getRecord();
        Account_Hierarchy__c accHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .build()
            .getRecord();    
        AccountHierarchyData.AccountHierarchyDataMock accountHierarchyDataMock = 
            new AccountHierarchyData.AccountHierarchyDataMock();
        accountHierarchyDataMock.accountHierarchiesToReturn = new List<Account_Hierarchy__c>{ahToReturn};

        List<Account_Hierarchy__c> ahReturnedByGetAccountHierarchiesByDunsNumber;
        List<Account_Hierarchy__c> ahReturnedByinsertAccountHierarchies;
        List<Account_Hierarchy__c> ahReturnedBygetAccountHierarchiesByCountryDomain;
        List<Account_Hierarchy__c> ahReturnedBygetAccountHierarchiesById;
        
        Test.startTest();
            ahReturnedByGetAccountHierarchiesByDunsNumber = 
                accountHierarchyDataMock.getAccountHierarchiesByDunsNumber(new Set<String>{dunsNumber});
            ahReturnedByinsertAccountHierarchies = 
                accountHierarchyDataMock.insertAccountHierarchies(
                        new List<Account_Hierarchy__c>{accHierarchy}
                );
            ahReturnedBygetAccountHierarchiesByCountryDomain = 
                accountHierarchyDataMock.getAccountHierarchiesByCountryDomain(new Set<String>{countryDomain});
            ahReturnedBygetAccountHierarchiesById =
                accountHierarchyDataMock.getAccountHierarchiesById(new Set<Id>{null});
        Test.stopTest();

        System.assertEquals(dunsNumber, ahReturnedByGetAccountHierarchiesByDunsNumber[0].D_U_N_S_Number__c, 
            'Account_Hierarchy__c should be returned correctly by the mock');
        System.assertEquals(dunsNumber, ahReturnedByinsertAccountHierarchies[0].D_U_N_S_Number__c, 
            'Account_Hierarchy__c should be returned correctly by the mock');
        System.assertEquals(dunsNumber, ahReturnedBygetAccountHierarchiesByCountryDomain[0].D_U_N_S_Number__c, 
            'Account_Hierarchy__c should be returned correctly by the mock');
        System.assertEquals(dunsNumber, ahReturnedBygetAccountHierarchiesById[0].D_U_N_S_Number__c, 
            'Account_Hierarchy__c should be returned correctly by the mock');
    }

    @isTest
    private static void testUpdateOwnerWithInvalidStatus() {
        User us = [
            SELECT Id
            FROM User
            WHERE Name = 'User Marketo'
            AND isActive = true
            LIMIT 1
        ];

        Test.startTest();
            Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account_Hierarchy__c.Company_Status__c => 'Invalid'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        company = [SELECT OwnerId
                    FROM Account_Hierarchy__c
                    WHERE Id = :company.Id];

        System.assertEquals(company.OwnerId,
                            us.Id,
                            'Company Owner was assigned incorrectly.');
    }

    @isTest
    private static void testUpdateOwnerWithValidStatus() {
        User us = [
            SELECT Id
            FROM User
            WHERE Name = 'User Marketo'
            AND isActive = true
            LIMIT 1
        ];

        Test.startTest();
            Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account_Hierarchy__c.Company_Status__c => 'Test',
                        Account_Hierarchy__c.Protected_Owner__c => null,
                        Account_Hierarchy__c.AH_Owner__c => null
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        company = [SELECT OwnerId
                    FROM Account_Hierarchy__c
                    WHERE Id = :company.Id];

        System.assertEquals(company.OwnerId,
                            us.Id,
                            'Company Owner was assigned incorrectly.');
    }

    @isTest
    private static void testUpdateOwnerWithValidStatusAndProtected() {
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest_03',
                    User.Username => 'Test_03!user@gmail.com',
                    User.Email => 'Test_03_user@gmail.com',
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

        Test.startTest();
            Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account_Hierarchy__c.Company_Status__c => 'Test',
                        Account_Hierarchy__c.Protected_Owner__c => us.Id
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        company = [SELECT OwnerId
                    FROM Account_Hierarchy__c
                    WHERE Id = :company.Id];

        System.assertEquals(company.OwnerId,
                            us.Id,
                            'Company Owner was assigned incorrectly.');
    }

    @isTest
    private static void testUpdateOwnerWithValidStatusAndUnprotected() {
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest_04',
                    User.Username => 'Test_04!user@gmail.com',
                    User.Email => 'Test_04_user@gmail.com',
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
        Test.startTest();
            Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account_Hierarchy__c.Company_Status__c => 'Test',
                        Account_Hierarchy__c.Protected_Owner__c => null,
                        Account_Hierarchy__c.AH_Owner__c => us.Id
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        company = [SELECT OwnerId
                    FROM Account_Hierarchy__c
                    WHERE Id = :company.Id];

        System.assertEquals(company.OwnerId,
                            us.Id,
                            'Company Owner was assigned incorrectly.');
    }

    @isTest
    private static void testUpdateOwnerWithInvalidUser() {
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest_05',
                    User.Username => 'Test_05!user@gmail.com',
                    User.Email => 'Test_05_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.isActive => false
                }
            )
            .create()
            .getRecord();

        User testUs = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest_06',
                    User.Username => 'Test_06!user@gmail.com',
                    User.Email => 'Test_06_user@gmail.com',
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

        Test.startTest();
            Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account_Hierarchy__c.Company_Status__c => 'Test',
                        Account_Hierarchy__c.Protected_Owner__c => us.Id,
                        Account_Hierarchy__c.AH_Owner__c => testUs.Id,
                        Account_Hierarchy__c.OwnerId => testUs.Id
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        company = [SELECT OwnerId
                    FROM Account_Hierarchy__c
                    WHERE Id = :company.Id];

        System.assertEquals(company.OwnerId,
                            testUs.Id,
                            'Company Owner was assigned incorrectly.');
    }

    @isTest
    private static void testUpdateOwnerWithValidUser() {
        User us = (User) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest_07',
                    User.Username => 'Test_07!user@gmail.com',
                    User.Email => 'Test_07_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.isActive => false
                }
            )
            .create()
            .getRecord();
        Test.startTest();
            Account_Hierarchy__c company = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account_Hierarchy__c.Company_Status__c => 'Test',
                        Account_Hierarchy__c.Protected_Owner__c => us.Id,
                        Account_Hierarchy__c.AH_Owner__c => us.Id
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        company = [SELECT OwnerId
                    FROM Account_Hierarchy__c
                    WHERE Id = :company.Id];

        System.assertEquals(company.OwnerId,
                            UserInfo.getUserId(),
                            'Company Owner was assigned incorrectly.');
    }
}