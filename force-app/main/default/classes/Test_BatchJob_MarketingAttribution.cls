@isTest
class Test_BatchJob_MarketingAttribution {

    static final String OFFICE_SIGNUP_FUNNEL = 'signUpFunnelOffice';
    static final String RCCC_SIGNUP_FUNNEL = 'signUpFunnelRCCC';
    static final String ACC_NAME1 = 'ACC_NAME1';
    static final String ACC_NAME2 = 'ACC_NAME2';
    static final Map<String, String> ACC_NAME_TO_FUNNEL = new Map<String, String> {
        ACC_NAME1 => RCCC_SIGNUP_FUNNEL,
        ACC_NAME2 => OFFICE_SIGNUP_FUNNEL
    };

    static void assertSelector(QueryFactory factory) {
        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('SELECT Account__c FROM Package__c WHERE LastModifiedDate >= 2024-11-01T00:00:00Z'),
            'The selector must include package condition'
        );
    }

    @testSetup
    static void setupTestData() {
        Triggers.switchOff();
        List<Account> testAccs = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideList(new List<String> {ACC_NAME1, ACC_NAME2}))
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => ValueProviderBuilder.provideList(new List<Id> {testAccs[0].Id, testAccs[0].Id, testAccs[1].Id, testAccs[1].Id}),
                Package__c.IsUsedForAccountAttribution__c => false,
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideUniqueString(),
                Package__c.RC_Signup_Funnel__c => ValueProviderBuilder.provideList(new List<String> {
                    null,
                    RCCC_SIGNUP_FUNNEL,
                    OFFICE_SIGNUP_FUNNEL,
                    RCCC_SIGNUP_FUNNEL
                }),
                Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_RCCC_PRODUCT,
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_RCCC_PRODUCT
                })
            })
            .quantity(4)
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testBatchExecution() {
        BatchJob_MarketingAttributionProcessing batch = new BatchJob_MarketingAttributionProcessing();

        List<Package__c> packages = (List<Package__c>) new PackageSelector()
            .selectPkgsForMarketingAttributionUpdate()
            .executeQuery();
        Assert.areEqual(0, packages.size(), 'There should be no marketing packages before batch execution.');

        Test.startTest();
            Database.executeBatch(new BatchJob_MarketingAttributionProcessing());
        Test.stopTest();

        packages = (List<Package__c>) new PackageSelector()
            .selectPkgsForMarketingAttributionUpdate()
            .executeQuery();
        Assert.areEqual(2, packages.size(), 'All packages should be marked as used for account attribution.');

        List<Account> updatedAccounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .selectFields(new List<SObjectField> {Account.Name, Account.RC_Signup_Funnel__c})
            .executeQuery();

        for (Account acc : updatedAccounts) {
            ASsert.areEqual(ACC_NAME_TO_FUNNEL.get(acc.Name), acc.RC_Signup_Funnel__c, 'Account funnel should be updated.');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testPackageSelector() {
        BatchJob_MarketingAttributionProcessing batch = new BatchJob_MarketingAttributionProcessing();
        Test.startTest();
            QueryFactory factory = batch
                .selectPackages()
                .setQuery();
        Test.stopTest();

        assertSelector(factory);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testAccountSelector() {
        BatchJob_MarketingAttributionProcessing batch = new BatchJob_MarketingAttributionProcessing();
        Test.startTest();
            QueryFactory factory = batch
                .selectAccounts()
                .setQuery();
        Test.stopTest();

        assertSelector(factory);
    }
}