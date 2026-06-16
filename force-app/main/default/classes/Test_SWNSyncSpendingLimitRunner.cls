@isTest
class Test_SWNSyncSpendingLimitRunner {
    static SWNSyncSpendingLimitRunner generateTestData() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Total_One_Time__c => 2,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.ngbsAcc = new BillingWrappers.NGBSAccount();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => new ValueProvider.DummyIdProvider(Account.sObjectType),
                Account.Billing_Id__c => '123'
            })
            .build()
            .getRecord();
        sdc.qt = (Quote) Test_Utils.putIntoUnwritableFields(
            qt,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'AccountId' => acc.Id
            }
        );
        sdc.currentStep = SWNStep.buildSyncSpendingLimitRetrieveStep();

        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        ngbsPkg.id = '456';
        sdc.ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> { ngbsPkg };
        sdc.ngbsPackage = ngbsPkg;
        SWNSyncSpendingLimitRunner runner = new SWNSyncSpendingLimitRunner(qt.Id, SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE);
        runner.sdc = sdc;
        return runner;
    }

    @TestSetup
    static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c =>'http://185.23.251.118:8080',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => 'testLogin',
                NGBS_Settings__c.Password__c => 'testPassword'
            })
            .create();
    }

    @isTest
    static void testRunner() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        SWNSyncSpendingLimitRunner runner = generateTestData();

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.areEqual(1, runner.res.messages.size(), 'Should have 1 message');
        Assert.areEqual(SWNMessageHelper.SPENDING_LIMIT_RETRIEVED_MSG, runner.res.messages[0].messageDetails, 'Wrong message about synced Spending Limit');
        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }
}