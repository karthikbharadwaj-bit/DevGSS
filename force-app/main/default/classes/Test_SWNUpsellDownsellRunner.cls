@isTest
class Test_SWNUpsellDownsellRunner {
    static final String DONWSELL_QLI_NAME = 'DONWSELL_QLI_NAME';
    static final String UPSELL_QLI_NAME = 'UPSELL_QLI_NAME';

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

    static List<QuoteLineItem> generateQlis() {
        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Quantity__c, new ValueProvider.ListProvider(new List<Integer> {4, 1}))
            .quantity(2)
            .build()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.NewQuantity__c => 2,
                QuoteLineItem.Display_Name__c => new ValueProvider.ListProvider(new List<String> {DONWSELL_QLI_NAME, UPSELL_QLI_NAME})
            })
            .quantity(2)
            .build()
            .getRecords();

        for (Integer i = 0; i < qlis.size(); i++) {
            qlis[i].putSObject(QuoteLineItem.Entitlement__c, ents[i]);
        }
        return qlis;
    }

    static SWNUpsellDownsellRunner generateOneTimeData() {
        SWNUpsellDownsellRunner runner = new SWNUpsellDownsellRunner(null, SWNStep.SYNC_TO_NGBS_DOWNSELL);
        runner.sdc = new SWNDataCollector(null, SWNStep.SYNC_TO_NGBS_DOWNSELL);
        runner.sdc.currentStep = SWNStep.buildSyncToNgbsDownsellStep();
        runner.sdc.billingId = '123';
        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        ngbsPkg.id = '456';
        runner.sdc.ngbsPackage = ngbsPkg;

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
                Quote.Package_Info__c => pInfo
            })
            .build()
            .getRecord();
        runner.sdc.qt = (Quote) TestDataGenerator.linkParentToChild(qt, acc, 'Account');

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Quantity__c, 4)
            .build()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test Name',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, 2)
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Product2Id, testProduct);
        qli.putSObject(QuoteLineItem.Entitlement__c, ent);
        runner.sdc.qlis = new List<QuoteLineItem> { qli };
        return runner;
    }

    @isTest
    static void testIsSyncToCCBsSyncToCCB() {
        Test.startTest();
            for (String action : SWNUpsellDownsellRunner.CCB_SYNC_ACTIONS) {
                SWNUpsellDownsellRunner runner = new SWNUpsellDownsellRunner(null, action);
                Assert.isTrue(runner.isSyncToCCB(), 'Should return true for action: ' + action);
            }
        Test.stopTest();
    }

    @isTest
    static void testIsDownsell() {
        Test.startTest();
            for (String action : SWNUpsellDownsellRunner.DOWNSELL_ACTIONS) {
                SWNUpsellDownsellRunner runner = new SWNUpsellDownsellRunner(null, action);
                Assert.isTrue(runner.isDownsell(), 'Should return true for action: ' + action);
            }
        Test.stopTest();
    }

    @isTest
    static void testGetFilteredQliListDownsell() {
        SWNUpsellDownsellRunner runner = new SWNUpsellDownsellRunner(null, SWNStep.SYNC_TO_CCB_DOWNSELL);
        runner.sdc = new SWNDataCollector(null, SWNStep.SYNC_TO_CCB_DOWNSELL);
        runner.sdc.qlis = generateQlis();

        Assert.areEqual(2, runner.sdc.qlis.size(), 'Should be 2 qlis before test execution');

        Test.startTest();
            List<QuoteLineItem> filteredQlis = runner.getFilteredQliList();
        Test.stopTest();

        Assert.areEqual(1, filteredQlis.size(), '1 qli should be filtered');
        Assert.areEqual(DONWSELL_QLI_NAME, filteredQlis[0].Display_Name__c, '1 qli should be filtered');
    }

    @isTest
    static void testGetFilteredQliListUpsell() {
        SWNUpsellDownsellRunner runner = new SWNUpsellDownsellRunner(null, SWNStep.SYNC_TO_CCB_UPSELL);
        runner.sdc = new SWNDataCollector(null, SWNStep.SYNC_TO_CCB_UPSELL);
        runner.sdc.qlis = generateQlis();

        Assert.areEqual(2, runner.sdc.qlis.size(), 'Should be 2 qlis before test execution');

        Test.startTest();
            List<QuoteLineItem> filteredQlis = runner.getFilteredQliList();
        Test.stopTest();

        Assert.areEqual(1, filteredQlis.size(), '1 qli should be filtered');
        Assert.areEqual(UPSELL_QLI_NAME, filteredQlis[0].Display_Name__c, '1 qli should be filtered');
    }

    @isTest
    static void testRunner() {
        SWNUpsellDownsellRunner runner = generateOneTimeData();

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }

    @isTest
    static void testCreateDownsellCase() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> { 
                Feature_Toggle__c.EnableSimplifiedDownsellForRingCC__c => true
            })
            .create();

        SWNUpsellDownsellRunner runner = generateOneTimeData();
        runner.sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().withDownsellCaseCreated(false).build();

        Response res = new Response();
        res.setData(SWNHelper.STATUS_PROP, Response.STATUS_SUCCESS);
        runner.res = res;

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
            runner.createDownsellCase();
        Test.stopTest();

        Assert.isTrue(runner.sdc.syncable.isDownsellCaseCreated(), 'Downsell checkbox should be set to true');
    }

    @isTest
    static void testIsSyncToCCBStepCompletedMP() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> { 
                Feature_Toggle__c.EnableUILessProcessOrderEngage__c => true,
                Feature_Toggle__c.EnableMultiProduct__c => true
            })
            .create();

        SWNUpsellDownsellRunner runner = new SWNUpsellDownsellRunner(null, SWNStep.SYNC_TO_NGBS_DOWNSELL);

        Test.startTest();
            Assert.isTrue(runner.isSyncToCCBStepCompleted(), 'Should be true if res is successfull');
            runner.res.error();
            Assert.isFalse(runner.isSyncToCCBStepCompleted(), 'Should be false if res is not successfull');
        Test.stopTest();
    }

    @isTest
    static void testIsSyncToCCBStepCompleted() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> { 
                Feature_Toggle__c.EnableUILessProcessOrderEngage__c => false,
                Feature_Toggle__c.EnableMultiProduct__c => false
            })
            .create();
        SWNUpsellDownsellRunner runner = generateOneTimeData();

        Test.startTest();
            Assert.isFalse(runner.isSyncToCCBStepCompleted(), 'Should be false if res does not have REDIRECT_URL');
            runner.res.setData(SWNUpsellDownsellRunner.REDIRECT_URL, 'testURL');
            Assert.isTrue(runner.isSyncToCCBStepCompleted(), 'Should be true if res has REDIRECT_URL');
        Test.stopTest();
    }
}