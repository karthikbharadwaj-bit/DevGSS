@isTest
private class Test_BatchJob_UpdatePackageFromAccount {
    private static final String EXPECTED_QUERY = 'SELECT Account__c FROM Package__c GROUP BY Account__c HAVING COUNT(Id) = 1 LIMIT 1000';
    @testSetup
    static void setup() {
        Triggers.switchOff();
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                SignupPlatform__c = 'Platform ' + i,
                Number_of_POC_Users__c = i,
                Service_Status__c = 'Active',
                No_of_InContact_Seats__c = 10,
                Price_per_Seat__c = 10.0,
                Billing_ID__c = '12345'+i
            );
            accounts.add(acc);
        }
        insert accounts;

        List<Package__c> packages = new List<Package__c>();
        for (Account acc : accounts) {
            Package__c pkg = new Package__c(
                Account__c = acc.Id,
                Account_Package_Id__c = '1010101' + acc.Number_of_POC_Users__c
            );
            packages.add(pkg);
        }
        insert packages;
        Triggers.switchOn();
    }

    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        BatchJob_UpdatePackageFromAccount batch = new BatchJob_UpdatePackageFromAccount();
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(batch.query), 'The query should not be blank');
    }

    @isTest
    static void testConstructorWithAccIds() {
        Id dummyAccId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        Set<Id> testAccIds = new Set<Id> {dummyAccId};
        Test.startTest();
        BatchJob_UpdatePackageFromAccount batch = new BatchJob_UpdatePackageFromAccount(testAccIds);
        Test.stopTest();

        Assert.isTrue(batch.query.contains('Id IN (\'' + dummyAccId + '\')'), 'The query should contain the account IDs passed to the constructor');
    }

    @isTest
    static void testConstructorWithCondition() {
        String condition = 'RC_Account_Status__c != \'Canceled\' AND RC_Account_Status__c != \'Cancelled\' AND Billing_ID__c != null';
        Test.startTest();
        BatchJob_UpdatePackageFromAccount batch = new BatchJob_UpdatePackageFromAccount(condition);
        Test.stopTest();

        Assert.isTrue(batch.query.contains(condition), 'The query should contain the condition passed to the constructor');
    }

    @isTest
    static void testStart() {
        Id dummyAccId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        BatchJob_UpdatePackageFromAccount batch = new BatchJob_UpdatePackageFromAccount(new Set<id> {dummyAccId});
        Test.startTest();
        Iterable<sObject> ql = batch.start(null);
        Test.stopTest();
        Assert.areNotEqual(null, ql);
    }

    @isTest
    static void testExecuteWithoutAccountIds() {
        BatchJob_UpdatePackageFromAccount batch = new BatchJob_UpdatePackageFromAccount();

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Account testAcc = (Account) new AccountSelector()
            .selectAccounts()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<String>{
                'SignupPlatform__c',
                'Number_of_POC_Users__c',
                'Service_Status__c',
                'Seat_MRR__c'
            })
            .subselect(
                new PackageSelector('Service_Accounts__r', Package__c.SObjectType)
                    .newQueryFactory()
                    .selectFields(new List<String>{
                        'SignupPlatform__c',
                        'Number_of_POC_Users__c',
                        'Service_Status__c',
                        'SeatMRR__c'
                    })
            )
            .executeQuery()
            .get(0);

        Assert.areEqual(testAcc.SignupPlatform__c, testAcc.Service_Accounts__r[0].SignupPlatform__c, 'Package__c.SignupPlatform__c should be the same as Account.SignupPlatform__c');
        Assert.areEqual(testAcc.Number_of_POC_Users__c, testAcc.Service_Accounts__r[0].Number_of_POC_Users__c, 'Package__c.Number_of_POC_Users__c should be the same as Account.Number_of_POC_Users__c');
        Assert.areEqual(testAcc.Service_Status__c, testAcc.Service_Accounts__r[0].Service_Status__c, 'Package__c.Service_Status__c should be the same as Account.Service_Status__c');
        Assert.areEqual(testAcc.Seat_MRR__c, testAcc.Service_Accounts__r[0].SeatMRR__c, 'Package__c.SeatMRR__c should be the same as Account.Seat_MRR__c');
    }
}