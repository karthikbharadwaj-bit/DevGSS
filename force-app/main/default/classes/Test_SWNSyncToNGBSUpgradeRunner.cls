@isTest
class Test_SWNSyncToNGBSUpgradeRunner {
    
    @TestSetup
    static void setup() {
        Triggers.switchOff();
        NGBS_Settings__c settings = (NGBS_Settings__c) new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://test.com',
                NGBS_Settings__c.AccountManagerPath__c => 'http://test.com/test_manager',
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();
        Triggers.switchOn();
    }
    
    static SWNSyncToNGBSUpgradeRunner generateTestData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => '123',
                Account.Id => new ValueProvider.DummyIdProvider(Account.SObjectType)
            })
            .build()
            .getRecord();
        
        String pInfo = '[{"packageInfo":{"id":"123","catalogId": "1", "version":"2"},"contract":{"extId":"Office","billingId":"234","status":"test"}}]';
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Package_Info__c => pInfo
            })
            .build()
            .getRecord();
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.ngbsAcc = new BillingWrappers.NGBSAccount();
        sdc.qt = (Quote) TestDataGenerator.linkParentToChild(qt, acc, 'Account');
        sdc.currentStep = SWNStep.buildSyncToNgbsUpgradeStep();

        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        sdc.ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> { ngbsPkg };
        ngbsPkg.id = '123';
        ngbsPkg.catalogId = '1';
        ngbsPkg.version = '2';

        SWNSyncToNGBSUpgradeRunner runner = new SWNSyncToNGBSUpgradeRunner(qt.Id, SWNStep.SYNC_TO_NGBS_UPGRADE);
        runner.sdc = sdc;
        return runner;
    }

    @isTest
    static void testRunnerWhenUpgradeSynced() {
        SWNSyncToNGBSUpgradeRunner runner = generateTestData();
        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.areEqual(1, runner.res.messages.size(), 'Should have 1 message');
        Assert.areEqual(SWNMessageHelper.PKG_AND_LICENSES_QUANTITIES_SYNCED_MSG, runner.res.messages[0].messageDetails, 'Wrong message about synced charge terms');
    }

    @isTest
    static void testRunnerWhenUpgradeNotSynced() {
        SWNSyncToNGBSUpgradeRunner runner = generateTestData();
        runner.sdc.ngbsAcc.packages[0].version = '22';

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }

    @isTest
    static void testDownsellCaseCreationInUpgrade() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> { 
                Feature_Toggle__c.EnableSimplifiedDownsellForRingCC__c => true
            })
            .create();

        SWNSyncToNGBSUpgradeRunner runner = generateTestData();
        runner.sdc.ngbsAcc.packages[0].version = '22';
        runner.sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().withDownsellCaseCreated(false).build();
        
        String bodyForMock = '[{' +
            '"amount": 120009.99,' +
            '"catalogId": "LC_HD_4",' +
            '"discountAmount": 0,' +
            '"qty": 2001' +
            '}]';
        BillingHttpRequestMock mockNGBSBillingInfoSummaryLicenses = new BillingHttpRequestMock();
        mockNGBSBillingInfoSummaryLicenses.body = bodyForMock;
        mockNGBSBillingInfoSummaryLicenses.code = 200;
        mockNGBSBillingInfoSummaryLicenses.status = 'Completed';

        Test.setMock(HttpCalloutMock.class, mockNGBSBillingInfoSummaryLicenses);
        
        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.syncable.isDownsellCaseCreated(), 'Downsell checkbox should be set to true');    
    }
}