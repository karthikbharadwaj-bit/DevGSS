@isTest
public class Test_Batch_partnerAccountChannelManager {

    @testSetup
    static void setupData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(
            Alias = 'standt',
            Email='standarduser757@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='standarduser757@testorg.com',
            isActive=true
        );
        insert testUser;

        RecordType partnerRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Partner Account' LIMIT 1];
        RecordType customerRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Customer Account' LIMIT 1];

        Account partnerAccount = new Account(
            Name = 'Partner Account 1',
            RecordTypeId = partnerRecordType.Id,
            Inside_Sales_Rep__c = testUser.Id
        );
        Account customerAccount = new Account(
            Name = 'Customer Account 1',
            RecordTypeId = customerRecordType.Id,
            Partner_Account__c = partnerAccount.Id
        );
        insert new List<Account> { partnerAccount, customerAccount };

        AccountTeamMember atm = new AccountTeamMember(
            AccountId = partnerAccount.Id,
            UserId = testUser.Id,
            TeamMemberRole = 'Some Role'
        );
        insert atm;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
            Batch_partnerAccountChannelManagerToATM batchJob = new Batch_partnerAccountChannelManagerToATM();
            Database.executeBatch(batchJob, 10);

            Batch_partnerAccountChannelManagerToATM batchJobWithCondition = new Batch_partnerAccountChannelManagerToATM(false, ' AND Name LIKE \'%Customer%\'');
            Database.executeBatch(batchJobWithCondition, 10);
            Batch_partnerAccountChannelManagerToATM batchJobEmpty = new Batch_partnerAccountChannelManagerToATM(true, ' AND Name = \'Nonexistent Account\'');
            Database.executeBatch(batchJobEmpty, 10);
        Test.stopTest();
    }

    @isTest
    static void testConstructATMObj() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Id testAccountId = testAccount.Id;
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Id testUserId = testUser.Id;

        Batch_partnerAccountChannelManagerToATM batchClass = new Batch_partnerAccountChannelManagerToATM();
        AccountTeamMember atmObj = batchClass.constructATMObj(testAccountId, testUserId);

        System.assertEquals(testAccountId, atmObj.AccountId, 'Account Id should match');
        System.assertEquals(testUserId, atmObj.UserId, 'User Id should match');
        System.assertEquals(batchClass.accessLevel, atmObj.AccountAccessLevel, 'Access level should match');
        System.assertEquals(batchClass.accessLevel, atmObj.CaseAccessLevel, 'Access level should match');
        System.assertEquals(batchClass.accessLevel, atmObj.ContactAccessLevel, 'Access level should match');
        System.assertEquals(batchClass.accessLevel, atmObj.OpportunityAccessLevel, 'Access level should match');
        System.assertEquals(batchClass.atmRole, atmObj.TeamMemberRole, 'Team member role should match');
    }
}