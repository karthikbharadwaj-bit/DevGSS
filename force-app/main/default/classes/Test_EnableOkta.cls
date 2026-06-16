@isTest
public class Test_EnableOkta {
    @isTest
    static void testExcuteProcess() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc22072021',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingCity => 'testCity',
                    Account.BillingPostalCode => 'testPC',
                    Account.BillingStreet => 'testStreet',
                    Account.BillingState => 'AP',
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Id__c => 'testPartnerId',
                    Account.RC_User_ID__c => 'rcUserId',
                    Account.RC_Account_Number__c => 'rcAccNumber'
                }
            )
            .create()
            .getRecord();
        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                        Contact.AccountId => acc.Id
                    }
                )
            .create()
            .getRecord();
        List<Profile> profilesList = [SELECT Id, Name FROM Profile WHERE Name like '%Full%'];
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestUser',
                    User.ProfileId => profilesList[0].Id,
                    User.ContactId => con.Id,
                    User.UserName => 'testusername@ringcentral.com'
                })
            .create()
            .getRecord();
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        Test.startTest();
            EnableOkta enableOktaCls = new EnableOkta(controller);
            enableOktaCls.getUsersOnPartnerAccount(acc.Id);
            enableOktaCls.createOktaApplication();
            enableOktaCls.excuteProcess();
        Test.stopTest();
        System.assertEquals(false, enableOktaCls.setUserName.isEmpty(), 'setUserName should be not empty');
        System.assertEquals(true, enableOktaCls.setUserName.contains(testUser.UserName), 'setUserName shoul contain username of test user');
    }

    @isTest
    static void testCreateOktaApplication() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc22072021',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingCity => 'testCity',
                    Account.BillingPostalCode => 'testPC',
                    Account.BillingStreet => 'testStreet',
                    Account.BillingState => 'AP',
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Id__c => 'testPartnerId',
                    Account.RC_User_ID__c => 'rcUserId',
                    Account.RC_Account_Number__c => 'rcAccNumber'
                }
            )
            .create()
            .getRecord();
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestUser'
                })
            .create()
            .getRecord();
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        Test.startTest();
            EnableOkta enableOktaCls = new EnableOkta(controller);
            enableOktaCls.createOktaApplication();
            enableOktaCls.assignOktaApplication('testOktaUserId');
            enableOktaCls.activateOktaUserFromPWDResetStatus('testOktaUserId', testUser);
            enableOktaCls.activateOktaUserFromDeactivate('testOktaUserId');
            enableOktaCls.activateOktaAppliation('testoktaApplicationID');
        Test.stopTest();
        System.assertEquals('0oavytzk2nKNELDPDURP', enableOktaCls.applicationId, 'applicationId should be taken from createOktaApplication method');
    }

    @isTest
    static void testEnableOkta() {
        List<Integration_Details__mdt> lstInegrationDetails = [Select Endpoint_URL__c,API_Key__c,Password__c from Integration_Details__mdt where DeveloperName ='Enable_Okta'];
        System.debug(lstInegrationDetails);
        List<Account> accounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideList(new List<String>{'testAcc1', 'testAcc2'}),
                    Account.BillingCountry => 'testCountry',
                    Account.BillingCity => 'testCity2',
                    Account.BillingPostalCode => 'testPC2',
                    Account.BillingStreet => 'testStreet2',
                    Account.BillingState => 'AP2',
                    Account.RecordTypeId => ValueProviderBuilder.provideList(new List<Id>{AccountHelper.RT_ID_CUSTOMER_ACCOUNT,AccountHelper.RT_ID_PARTNER_ACCOUNT}),
                    Account.Partner_Id__c => 'testPartnerId',
                    Account.RC_User_ID__c => ValueProviderBuilder.provideList(new List<String>{'rcUserId1', 'rcUserId2'}),
                    Account.RC_Account_Number__c => ValueProviderBuilder.provideList(new List<String>{'rcAccNumber1', 'rcAccNumber2'})
                }
            )
            .quantity(2)
            .create()
            .getRecords();
        ApexPages.StandardController controller = new ApexPages.StandardController(accounts[0]);
        Test.startTest();
            EnableOkta enableOktaCls = new EnableOkta(controller);
        Test.stopTest();
        System.assertEquals(false, enableOktaCls.flagToCreateApplication, 'flagToCreateApplication should be false');
    }

    @isTest
    static void testCreateOktaUser() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc22072021',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingCity => 'testCity',
                    Account.BillingPostalCode => 'testPC',
                    Account.BillingStreet => 'testStreet',
                    Account.BillingState => 'AP',
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Id__c => 'testPartnerId',
                    Account.RC_User_ID__c => 'rcUserId',
                    Account.RC_Account_Number__c => 'rcAccNumber'
                }
            )
            .create()
            .getRecord();
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestUser',
                    User.UserName => 'testusername@ringcentral.com'
                })
            .create()
            .getRecord();
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        Test.startTest();
            EnableOkta enableOktaCls = new EnableOkta(controller);
            enableOktaCls.createOktaUser(testUser);
            enableOktaCls.callAPIs('testUrl', 'testBody', 'testAction');
        Test.stopTest();
        System.assertEquals(testUser.UserName, enableOktaCls.mapUserToUpd.get(testUser.Id).UserName, 'mapUserToUpd should contain created user previously');
    }

    @isTest
    static void testPrepareUserListToCreateOnOkta() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc22072021',
                    Account.BillingCountry => 'testCountry',
                    Account.BillingCity => 'testCity',
                    Account.BillingPostalCode => 'testPC',
                    Account.BillingStreet => 'testStreet',
                    Account.BillingState => 'AP',
                    Account.RecordTypeId => AccountHelper.RT_ID_PARTNER_ACCOUNT,
                    Account.Partner_Id__c => 'testPartnerId',
                    Account.RC_User_ID__c => 'rcUserId',
                    Account.RC_Account_Number__c => 'rcAccNumber'
                }
            )
            .create()
            .getRecord();
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestUser'
                })
            .create()
            .getRecord();
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        String result;
        Test.startTest();
            EnableOkta enableOktaCls = new EnableOkta(controller);
            enableOktaCls.setUserName.add(testUser.UserName);
            enableOktaCls.mapOktaLoginToOktaId.put('test', 'test');
            enableOktaCls.prepareUserListToCreateOnOkta();
        Test.stopTest();
        System.assertEquals(true, enableOktaCls.setUserNameToCreateOkta.contains(testUser.UserName), 'setUserNameToCreateOkta should contain created user previously');
    }
}