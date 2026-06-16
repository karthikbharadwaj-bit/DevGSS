@isTest
class Test_SWNUpgradeRunner {
    static final String P_INFO = '[{"id":"5","version":"3","packageInfo":{"id":"456","catalogId":"5","version":"3","name":"Office"},"productName":"Office","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';
    static SWNUpgradeRunner generateTestData() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => false,
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Package_Info__c => P_INFO
            })
            .build()
            .getRecord();
        SWNDataCollector sdc = new SWNDataCollector(qt.Id, SWNStep.UP_SELL);
        sdc.ngbsAcc = new BillingWrappers.NGBSAccount();
        sdc.qt = qt;
        sdc.currentStep = SWNStep.buildUpgradeStep();

        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        sdc.ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> { ngbsPkg };
        ngbsPkg.id = '456';
        ngbsPkg.catalogId = '5';
        ngbsPkg.version = '3';
        sdc.billingId = '123';
        ngbsPkg.masterDuration = QuoteLineItemHelper.CHARGE_TERM_ANNUAL;

        SWNUpgradeRunner runner = new SWNUpgradeRunner(qt.Id, SWNStep.UPGRADE);
        runner.sdc = sdc;
        return runner;
    }

    @isTest
    static void testRunnerLBOEnabled() {
        new SObjectBuilder(NGBS_Phoenix_Settings__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableBrands__c => 'RingCentral;RingCentral Canada;RingCentral AU;RingCentral UK;RingCentral EU; Unify Office;',
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailablePackageIDs__c => '5;321',
                NGBS_Phoenix_Settings__c.NGBSPhoenixAvailableProducts__c => 'RC Meetings;Meetings;'
            })
            .create();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c =>'http://185.23.251.118:8080',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => 'testLogin',
                NGBS_Settings__c.Password__c => 'testPassword'
            })
            .create();
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        SWNUpgradeRunner runner = generateTestData();
        runner.sdc.qt.Id = null;
        runner.sdc.qt.Enabled_LBO__c = true;

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }

    @isTest
    static void testRunnerNotPhoenix() {
        SWNUpgradeRunner runner = generateTestData();
        runner.sdc.qt.IsMultiProductTechnicalQuote__c = true;
        runner.sdc.qt.ServiceName__c = 'test';

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }

    @isTest
    static void testRunnerError() {
        SWNUpgradeRunner runner = generateTestData();
        runner.sdc.ngbsAcc.packages[0].masterDuration = QuoteLineItemHelper.CHARGE_TERM_MONTHLY;
        runner.sdc.qt.IsMultiProductTechnicalQuote__c = true;
        runner.sdc.qt.ServiceName__c = 'test';

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isFalse(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should not be completed');
        Assert.areEqual(1, runner.res.messages.size(), '1 Error message should be added');
        Assert.areEqual(SWNUpgradeRunner.UPGRADE_ERROR, runner.res.messages[0].message, 'Wrong error message');
    }
}