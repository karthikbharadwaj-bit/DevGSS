@isTest
private class Test_RedAccountTriggerHandler {

    @testSetup
    static void PrepareTestData() {
        User accCsmUser = (User) new SObjectBuilder(User.SObjectType)
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


        Account testAccount = new Account
        (
            Name = 'Test Account',
            CSM__c = accCsmUser.Id
        );

        insert testAccount;

        Red_Account__c redAccount = new Red_Account__c
        (
            EscalatedAccount__c = testAccount.Id,
            Issue_Category__c = 'Other',
            Issue_Status__c = 'New',
            Primary_Competitor__c = 'Comcast',
            Primary_Reason_for_Red__c = 'Support Issues',
            Sub_Reason_for_Red__c = '3rd Party Integrations',
            Risk_Type__c = 'Elasticity'
        );

        insert redAccount;
    }

    @isTest
    static void test_StartDateSetOnCreate() {
        Red_Account__c[] results = [
            SELECT Red_Start_Date__c
            FROM Red_Account__c
        ];

        System.assert(results.size() > 0, 'Red_Account__c record was not found');
        System.assert(results[0].Red_Start_Date__c == Date.today(), 'Red_Start_Date__c not equals to current date');
    }

    /*@isTest
    static void test_IssueOwnerAssignedOnCretae() {
        Red_Account__c[] redAccounts = [
            SELECT Issue_Owner__c
            FROM Red_Account__c
        ];

        Account[] accounts = [
            SELECT CSM__c
            FROM Account
        ];

        System.assert(redAccounts.size() > 0, 'Red_Account__c record was not found');
        System.assert(accounts.size() > 0, 'Account record was not found');
        System.assertEquals(redAccounts[0].Issue_Owner__c, accounts[0].CSM__c, 'Value of the Red_Account__c.Issue_Ower__c field ' +
            'not equals to the Account.CSM__c field value');
    }*/

    @isTest
    static void test_RedEndDateUpdatedOnUpdate() {
        List<String> statusesToUpdateEndDate = new List<String>
        {
            RedAccountTriggerHandler.STATUS_RESOLVED_DOWN,
            RedAccountTriggerHandler.STATUS_RESOLVED_SAVE,
            RedAccountTriggerHandler.STATUS_RESOLVED_LOST
        };

        Red_Account__c[] redAccounts = [
            SELECT Red_Start_Date__c
            FROM Red_Account__c
        ];

        System.assert(redAccounts.size() > 0, 'Red_Account__c record was not found');

        Test.startTest();

        for (String status : statusesToUpdateEndDate) {
            redAccounts[0].Status__c = status;
            update redAccounts;
            redAccounts = [SELECT Red_End_Date__c FROM Red_Account__c];
            System.assert(redAccounts.size() > 0, 'Red_Account__c record not found');
            System.assertEquals(redAccounts[0].Red_End_Date__c, Date.today(), 'Red_End_Date__c not equals to current date, ' +
                'even Status__c field was properly changed');

            redAccounts[0].Red_End_Date__c = null;
            redAccounts[0].Status__c = null;
            update redAccounts;
        }

        Test.stopTest();
    }

    @isTest
    static void test_RedEndDateUpdatedOnInsert() {
        List<String> statusesToUpdateEndDate = new List<String>
        {
            RedAccountTriggerHandler.STATUS_RESOLVED_DOWN,
            RedAccountTriggerHandler.STATUS_RESOLVED_SAVE,
            RedAccountTriggerHandler.STATUS_RESOLVED_LOST
        };

        Account[] accounts = [SELECT Id FROM Account];
        System.assert(accounts.size() > 0, 'Account record was not found');

        Test.startTest();

        List<Red_Account__c> redAccounts = new List<Red_Account__c>();
        for (String status : statusesToUpdateEndDate) {
            Red_Account__c redAcc = new Red_Account__c (
                EscalatedAccount__c = accounts[0].Id,
                Status__c = status,
                Issue_Category__c = 'Other',
                Issue_Status__c = 'New',
                Primary_Competitor__c = 'Comcast',
                Primary_Reason_for_Red__c = 'Support Issues',
                Sub_Reason_for_Red__c = '3rd Party Integrations',
                Risk_Type__c = 'Elasticity'
            );
            redAccounts.add(redAcc);
        }
        insert redAccounts;

        Red_Account__c[] insertResult = [SELECT Red_End_Date__c FROM Red_Account__c WHERE Id IN :redAccounts];

        Test.stopTest();

        for (Red_Account__c redAcc : insertResult) {
            System.assertEquals(Date.today(), redAcc.Red_End_Date__c, 'Red_End_Date__c not equals to current date');
        }
    }

    @isTest
    static void test_RedEndDateNotUpdatedOnUpdate() {
        Set<String> bypassStatuses = new Set<String>
        {
            RedAccountTriggerHandler.STATUS_RESOLVED_DOWN,
            RedAccountTriggerHandler.STATUS_RESOLVED_SAVE,
            RedAccountTriggerHandler.STATUS_RESOLVED_LOST
        };

        Schema.PicklistEntry[] objStatuses = Red_Account__c.Status__c.getDescribe().getPicklistValues();
        List<String> statusesToTest = new List<String>();
        for (Schema.PicklistEntry entry : objStatuses) {
            String currentValue = entry.getValue();
            if (bypassStatuses.contains(currentValue) == false) {
                statusesToTest.add(currentValue);
            }
        }

        Red_Account__c[] redAccounts = [
            SELECT Red_Start_Date__c
            FROM Red_Account__c
        ];

        System.assert(redAccounts.size() > 0, 'Red_Account__c record was not found');

        Test.startTest();

        for (String status : statusesToTest) {
            redAccounts[0].Status__c = status;
            update redAccounts;
            redAccounts = [SELECT Red_End_Date__c FROM Red_Account__c];
            System.assert(redAccounts.size() > 0, 'Red_Account__c record not found');
            System.assert(redAccounts[0].Red_End_Date__c == null, 'Red_End_Date__c was updated, but should not');
        }

        Test.stopTest();
    }
}