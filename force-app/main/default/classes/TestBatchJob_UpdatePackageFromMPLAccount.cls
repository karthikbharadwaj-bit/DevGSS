@isTest
private class TestBatchJob_UpdatePackageFromMPLAccount {
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        BatchJob_UpdatePackageFromMPLAccount batch = new BatchJob_UpdatePackageFromMPLAccount();
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(batch.query), 'The query should not be blank');
    }

    @isTest
    static void testConstructorWithAccIds() {
        Id dummyAccId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        Set<Id> testAccIds = new Set<Id> {dummyAccId};
        Test.startTest();
        BatchJob_UpdatePackageFromMPLAccount batch = new BatchJob_UpdatePackageFromMPLAccount(testAccIds);
        Test.stopTest();

        Assert.isTrue(batch.query.contains('Id IN (\'' + dummyAccId + '\')'), 'The query should contain the account IDs passed to the constructor');
    }

    @isTest
    static void testConstructorWithCondition() {
        String condition = 'IsMultiProductTechnicalAccount__c = true';
        Test.startTest();
        BatchJob_UpdatePackageFromMPLAccount batch = new BatchJob_UpdatePackageFromMPLAccount(condition);
        Test.stopTest();

        Assert.isTrue(batch.query.contains(condition), 'The query should contain the condition passed to the constructor');
    }

    @isTest
    static void testStart() {


        Id dummyAccId = (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        BatchJob_UpdatePackageFromMPLAccount batch = new BatchJob_UpdatePackageFromMPLAccount(new Set<id> {dummyAccId});
        Test.startTest();
        Iterable<sObject> ql = batch.start(null);
        Test.stopTest();
        Assert.areNotEqual(null, ql);
    }

    @isTest
    static void testExecuteWithoutAccountIds() {

        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.isMultiproductTechnicalAccount__c => false,
                Account.Billing_ID__c => '12341234',
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.AID__c => '1234',
                Account.Engage_Domain__c => 'Office Domain'
            }
        )
        .create()
        .getRecord();

        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                Account.Master_Account__c => masterAcc.Id,
                Account.isMultiproductTechnicalAccount__c => true,
                Account.BillingStreet => 'street',
                Account.BillingState => 'state',
                Account.BillingPostalCode => '123',
                Account.BillingCountry => 'USA',
                Account.BillingCity => 'City',
                Account.Phone => '123467445',
                Account.AID__c => '5678',
                Account.Engage_Domain__c => 'ED Domain'
            }
        )
        .create()
        .getRecord();


        Package__c testPackage1 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Package__c.Account_Package_Id__c => '1111',
            Package__c.Account__c => masterAcc.Id,
            Package__c.Enterprise_Account_ID__c => masterAcc.Id,
            Package__c.Service_Type__c => 'Office'
        })
        .create()
        .getRecord();

        Package__c testPackage2 = (Package__c) new SObjectBuilder(Package__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Package__c.Account_Package_Id__c => '11112',
            Package__c.Account__c => masterAcc.Id,
            Package__c.Enterprise_Account_ID__c => techAcc.Id,
            Package__c.Service_Type__c => 'Engage Digital Standalone'
        })
        .create()
        .getRecord();

        BatchJob_UpdatePackageFromMPLAccount batch = new BatchJob_UpdatePackageFromMPLAccount();

        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();


        Package__c reselectedPkg1 = (Package__c) new PackageSelector()
        .selectPackagesById(new List<Id>{ testPackage1.Id })
        .selectFields(new List<Schema.SObjectField> {
            Package__c.AID__c,
            Package__c.Engage_Domain__c
        })
        .executeQuery()
        .get(0);

        Package__c reselectedPkg2 = (Package__c) new PackageSelector()
        .selectPackagesById(new List<Id>{ testPackage2.Id })
        .selectFields(new List<Schema.SObjectField> {
            Package__c.AID__c,
            Package__c.Engage_Domain__c
        })
        .executeQuery()
        .get(0);

        Assert.areEqual(masterAcc.AID__c, reselectedPkg1.AID__c, 'Package__c.AID__c should be the same as Master Account.AID__c');
        Assert.areEqual(techAcc.AID__c, reselectedPkg2.AID__c, 'Package__c.AID__c should be the same as Technical Account.AID__c');
        Assert.areNotEqual(techAcc.Engage_Domain__c, testPackage1.Engage_Domain__c, 'Package__c.SignupPlatform__c should not be the same as ED Technical Account.Engage_Domain__c');
    }
}