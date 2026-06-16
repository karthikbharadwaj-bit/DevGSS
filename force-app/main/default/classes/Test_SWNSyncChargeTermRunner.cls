@isTest
class Test_SWNSyncChargeTermRunner {
    static SWNSyncChargeTermRunner generateTestData() {
        String pInfo = '[{"duration":"Annual","packageInfo":{"id":"123"},"contract":{"extId":"Office","billingId":"234","status":"test"}}]';
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Package_Info__c => pInfo
            })
            .build()
            .getRecord();
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.ngbsAcc = new BillingWrappers.NGBSAccount();
        sdc.qt = qt;
        sdc.currentStep = SWNStep.buildChargeTermSyncStep();

        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        ngbsPkg.id = '123';
        ngbsPkg.masterDuration = QuoteLineItemHelper.CHARGE_TERM_ANNUAL;
        sdc.ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> { ngbsPkg };
        SWNSyncChargeTermRunner runner = new SWNSyncChargeTermRunner(qt.Id, SWNStep.CHARGE_TERM_SYNC);
        runner.sdc = sdc;
        return runner;
    }

    @isTest
    static void testRunnerWhenChargeTermSynced() {
        SWNSyncChargeTermRunner runner = generateTestData();
        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.areEqual(1, runner.res.messages.size(), 'Should have 1 message');
        Assert.areEqual(SWNMessageHelper.CHARGE_TERM_SYNCED_MSG, runner.res.messages[0].messageDetails, 'Wrong message about synced charge terms');
    }

    @isTest
    static void testRunnerWhenChargeTermNotSynced() {
        SWNSyncChargeTermRunner runner = generateTestData();
        runner.sdc.ngbsAcc.packages[0].masterDuration = QuoteLineItemHelper.CHARGE_TERM_MONTHLY;

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }
}