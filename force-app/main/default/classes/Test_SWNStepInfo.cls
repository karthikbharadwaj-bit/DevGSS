@IsTest
private class Test_SWNStepInfo {
    private static final String TEST_SYNC_STATUS = 'TEST_SYNC_STATUS';
    private static final String PRODUCT_EXT_ID = 'LC_DL-UNL_50';
    private static final String BILLING_ID = BillingHttpRequestMock.ACCOUNT_ID;
    private static final String PACKAGE_ID = BillingHttpRequestMock.PACKAGE_ID;
    private static final String SIMPLE_PACKAGE_INFO = '{"duration":"' + Product2Helper.CHARGE_TERM_MONTHLY + '"}';

    private class TestSyncInfo extends SWNStepInfo {
        private Boolean wasGetSyncStatusCalled = false;
        private SWNDataCollector sdc;

        public TestSyncInfo(SWNDataCollector sdc) {
            super(sdc);
        }
        public TestSyncInfo(SWNDataCollector sdc, Boolean skip, Boolean auto) {
            super(sdc, skip, auto);
        }

        protected override String getSyncStatus(SWNDataCollector sdc) {
            wasGetSyncStatusCalled = true;
            this.sdc = sdc;
            return TEST_SYNC_STATUS;
        }
    }

    private static void assertStepStatusSynced(String step, String syncInfoClass, SWNDataCollector sdc) {
        Test.startTest();
            SWNStepInfo syncInfo = SWNStepInfo.getStepInfo(step, sdc);
        Test.stopTest();

        Assert.isNotNull(syncInfo, syncInfoClass + ' was initialized');
        Assert.areEqual(SWNHelper.SYNCED, syncInfo.status, 'Statuse should SYNCED');
    }

    private static SWNDataCollector buildSWNDataCollector(NGBSSyncables.ISyncable syncable) {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = syncable;
        return sdc;
    }
    private static SWNDataCollector buildSWNDataCollectorForCCBDownsell(Boolean isDownsellCompleted, Integer newQuantity, Integer oldQuantity) {
        NGBSSyncables.ISyncable downsellStepIsNotCompleted = new SWNMockBuilders.NGBSSyncableBuilder()
            .withDownsellStepCompleted(isDownsellCompleted)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(downsellStepIsNotCompleted);
        sdc.qlis = buildTestQli(newQuantity, oldQuantity);
        sdc.packageId = PACKAGE_ID;
        sdc.billingId = BILLING_ID;
        return sdc;
    }
    private static List<QuoteLineItem> buildTestQli(Integer newQuantity, Integer oldQuantity) {
        Quote qt = new Quote(RecordTypeId = QuoteHelper.RT_ID_BILLING);
        Product2 prodDL = new Product2(
            ExtID__c = PRODUCT_EXT_ID,
            Family = null
        );
        QuoteLineItem qliDL = new QuoteLineItem(
            NewQuantity__c = newQuantity,
            IsHiddenLicense__c = false,
            PackageInfo__c = SIMPLE_PACKAGE_INFO,
            Quote = qt,
            Product2 = prodDL
        );
        if (oldQuantity != null) {
            qliDL.Entitlement__r = new Entitlement__c(Quantity__c = oldQuantity);
        }
        return new List<QuoteLineItem> {qliDL};
    }

    private static void assertNotSyncedSyncInfo(String syncInfoName, SWNStepInfo testSyncInfo, Boolean expectedSkip, Boolean expectedAuto) {
        assertSyncInfo(syncInfoName, testSyncInfo, SWNHelper.NOT_SYNCED, expectedSkip, expectedAuto);
    }
    private static void assertSyncInfoWithReason(String syncInfoName, SWNStepInfo testSyncInfo, String expectedStatus, String reasonForWrongStatus) {
        assertSyncInfo(syncInfoName, testSyncInfo, expectedStatus, false, false, reasonForWrongStatus);
    }
    private static void assertSyncedSyncInfo(String syncInfoName, SWNStepInfo testSyncInfo, Boolean expectedSkip, Boolean expectedAuto) {
        assertSyncInfo(syncInfoName, testSyncInfo, SWNHelper.SYNCED, expectedSkip, expectedAuto);
    }
    private static void assertSyncInfo(String syncInfoName, SWNStepInfo testSyncInfo, String expectedStatus, Boolean expectedSkip, Boolean expectedAuto) {
        assertSyncInfo(syncInfoName, testSyncInfo, expectedStatus, expectedSkip, expectedAuto, null);
    }
    private static void assertSyncInfo(String syncInfoName, SWNStepInfo testSyncInfo, String expectedStatus, Boolean expectedSkip, Boolean expectedAuto, String reasonForWrongStatus) {
        String testingSyncInfoScenario = syncInfoName + '::' + expectedStatus;
        String assertMsg = 'Wrong status was returned for ' + testingSyncInfoScenario;
        if (String.isNotBlank(reasonForWrongStatus)) {
            assertMsg += ', ' + reasonForWrongStatus;
        }

        Assert.isNotNull(testSyncInfo, 'SyncInfo was not created for ' + testingSyncInfoScenario);
        Assert.areEqual(expectedStatus, testSyncInfo.status, 'Wrong status was returned for ' + testingSyncInfoScenario);
        Assert.areEqual(expectedSkip, testSyncInfo.skip, 'Wrong skip was returned for ' + testingSyncInfoScenario);
        Assert.areEqual(expectedAuto, testSyncInfo.auto, 'Wrong auto was returned for ' + testingSyncInfoScenario);
    }

    @TestSetup
    static void setup() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => BillingHttpRequestMock.BASE_ENDPOINT,
                NGBS_Settings__c.AccountManagerPath__c => BillingHttpRequestMock.ACCOUNT_MANAGER_PATH,
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create();
    }

    @isTest
    static void testSWNSyncInfoConstructor() {
        Boolean testSkip = true;
        Boolean testAuto = true;

        Test.startTest();
            TestSyncInfo testShorthandConstructor = new TestSyncInfo(new SWNDataCollector());
            TestSyncInfo testConstructor = new TestSyncInfo(new SWNDataCollector(), testSkip, testAuto);
        Test.stopTest();

        assertSyncInfo('shorthand constructor', testShorthandConstructor, TEST_SYNC_STATUS, false, false);
        assertSyncInfo('full constructor', testConstructor, TEST_SYNC_STATUS, testSkip, testAuto);
        Assert.isTrue(testShorthandConstructor.wasGetSyncStatusCalled, 'getSyncStatus was not called for shorthand constructor');
        Assert.isTrue(testConstructor.wasGetSyncStatusCalled, 'getSyncStatus was not called for full constructor');
    }

    @isTest
    static void testGetSyncStatus() {
        TestSyncInfo testSyncInfo = new TestSyncInfo(new SWNDataCollector());

        Test.startTest();
            String whenSynced = testSyncInfo.getSyncStatus(true);
            String whenNotSynced = testSyncInfo.getSyncStatus(false);
        Test.stopTest();

        Assert.areEqual(SWNHelper.SYNCED, whenSynced, 'getSyncStatus returned wrong status when synced');
        Assert.areEqual(SWNHelper.NOT_SYNCED, whenNotSynced, 'getSyncStatus returned wrong status when not synced');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testDiscountSyncInfo() {
        NGBSSyncables.ISyncable discountsSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withDiscountsSynced(true)
            .build();
        NGBSSyncables.ISyncable discountsNotSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withDiscountsSynced(false)
            .build();

        SWNDataCollector sdcSynced = buildSWNDataCollector(discountsSynced);
        SWNDataCollector sdcNotSynced = buildSWNDataCollector(discountsNotSynced);

        Test.startTest();
            SWNStepInfo whenSynced = new SWNStepInfo.DiscountSyncInfo(sdcSynced);
            SWNStepInfo whenNotSynced = new SWNStepInfo.DiscountSyncInfo(sdcNotSynced);
        Test.stopTest();

        assertSyncedSyncInfo(SWNStepInfo.DiscountSyncInfo.class.getName(), whenSynced, false, true);
        assertNotSyncedSyncInfo(SWNStepInfo.DiscountSyncInfo.class.getName(), whenNotSynced, false, true);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testContractSyncInfo() {
        NGBSSyncables.ISyncable contractResynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withContractsSynced(true)
            .withResyncContractAllowed(true)
            .build();
        NGBSSyncables.ISyncable contractSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withContractsSynced(true)
            .withResyncContractAllowed(false)
            .build();
        NGBSSyncables.ISyncable contractNotSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withContractsSynced(false)
            .withResyncContractAllowed(false)
            .build();
        String pInfoWithContract = new SWNMockBuilders.PackageInfoBuilder().withContract().buildAsJson();
        String pInfoWithoutContact = new SWNMockBuilders.PackageInfoBuilder().buildAsJson();
        SWNDataCollector sdc = buildSWNDataCollector(contractNotSynced);

        Test.startTest();
            sdc.qt = new Quote(Package_Info__c = pInfoWithoutContact);
            SWNStepInfo skippedIsExpected = new SWNStepInfo.ContractSyncInfo(sdc);

            sdc.qt = new Quote(Package_Info__c = pInfoWithContract);
            SWNStepInfo notSyncedIsExpected = new SWNStepInfo.ContractSyncInfo(sdc);

            sdc.syncable = contractSynced;
            SWNStepInfo syncIsExpected = new SWNStepInfo.ContractSyncInfo(sdc);

            sdc.syncable = contractResynced;
            SWNStepInfo resyncIsExpected = new SWNStepInfo.ContractSyncInfo(sdc);
        Test.stopTest();

        String stepInfoName = SWNStepInfo.ContractSyncInfo.class.getName();
        assertSyncInfo(stepInfoName, skippedIsExpected, SWNHelper.SKIPPED, false, true);
        assertSyncInfo(stepInfoName, resyncIsExpected, SWNHelper.RESYNC, false, true);
        assertSyncedSyncInfo(stepInfoName, syncIsExpected, false, true);
        assertNotSyncedSyncInfo(stepInfoName, notSyncedIsExpected, false, true);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncToCCBDownSellInfoNoDownsellQli() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        SWNDataCollector sdc = buildSWNDataCollectorForCCBDownsell(false, 100, null);

        Test.startTest();
            SWNStepInfo stepInfo = new SWNStepInfo.SyncToCCBDownSellInfo(sdc);
        Test.stopTest();

        assertSyncInfoWithReason(
            SWNStepInfo.SyncToCCBDownSellInfo.class.getName(),
            stepInfo,
            SWNHelper.SYNCED,
            'because qli will be filtered and we check only downsell sync'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncToCCBDownSellInfoQtyStatusReturnFalse() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        SWNDataCollector sdc = buildSWNDataCollectorForCCBDownsell(false, 10, 30);

        Test.startTest();
            SWNStepInfo stepInfo = new SWNStepInfo.SyncToCCBDownSellInfo(sdc);
        Test.stopTest();

        assertSyncInfoWithReason(
            SWNStepInfo.SyncToCCBDownSellInfo.class.getName(),
            stepInfo,
            SWNHelper.NOT_SYNCED,
            'because qli qty less then qty returned from response'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCheckDownSellSyncQtyStatusReturnFalseCase3() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        SWNDataCollector sdc = buildSWNDataCollectorForCCBDownsell(false, 100, 30);

        Test.startTest();
            SWNStepInfo stepInfo = new SWNStepInfo.SyncToCCBDownSellInfo(sdc);
        Test.stopTest();

        assertSyncInfoWithReason(
            SWNStepInfo.SyncToCCBDownSellInfo.class.getName(),
            stepInfo,
            SWNHelper.SYNCED,
            'because qli will be filtered and we check only downsell sync'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncToNGBSUpgradeStep() {
        NGBSSyncables.ISyncable upgradeStepSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withUpgradeStepCompleted(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(upgradeStepSynced);

        assertStepStatusSynced(SWNStep.SYNC_TO_NGBS_UPGRADE, SWNStepInfo.UpgradeICBInfo.class.getName(), sdc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncInvoiceStep() {
        NGBSSyncables.ISyncable invoiceStepSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withInvoiceStepCompleted(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(invoiceStepSynced);

        assertStepStatusSynced(SWNStep.SYNC_INVOICE, SWNStepInfo.InvoiceStepInfo.class.getName(), sdc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncSpendingLimitRetrieveStep() {
        NGBSSyncables.ISyncable invoiceStepSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withSpendingLimitRetrieveStepCompleted(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(invoiceStepSynced);

        assertStepStatusSynced(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE, SWNStepInfo.SpendingLimitRetrieveStepInfo.class.getName(), sdc);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testEngageAccountTerminationStep() {
        NGBSSyncables.ISyncable invoiceStepSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withTerminationStepCompleted(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(invoiceStepSynced);

        assertStepStatusSynced(SWNStep.ENGAGE_ACCOUNT_TERMINATION, SWNStepInfo.AccountTerminationCCBInfo.class.getName(), sdc);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testChargeTermSyncedStep() {
        NGBSSyncables.ISyncable chargeTermStepSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withChargeTermSynced(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(chargeTermStepSynced);

        assertStepStatusSynced(SWNStep.CHARGE_TERM_SYNC, SWNStepInfo.ChargeTermICBInfo.class.getName(), sdc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncToICBStep() {
        NGBSSyncables.ISyncable syncToICBStep = new SWNMockBuilders.NGBSSyncableBuilder()
            .withSyncedToICB(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(syncToICBStep);

        assertStepStatusSynced(SWNStep.SYNC_TO_ICB, SWNStepInfo.SyncToICBInfo.class.getName(), sdc);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSyncToInContactStep() {
        NGBSSyncables.ISyncable syncToInContactStep = new SWNMockBuilders.NGBSSyncableBuilder()
            .withICBProvisioningComplete(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(syncToInContactStep);

        assertStepStatusSynced(SWNStep.SYNC_TO_INCONTACT, SWNStepInfo.SyncToInContactInfo.class.getName(), sdc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testChargeTermICBInfoWhenChargeTermIsAlreadySynced() {
        NGBSSyncables.ISyncable chargeTermSynced = new SWNMockBuilders.NGBSSyncableBuilder()
            .withChargeTermSynced(true)
            .build();
        SWNDataCollector sdc = buildSWNDataCollector(chargeTermSynced);

        Test.startTest();
            SWNStepInfo whenChargeTermSynced = new SWNStepInfo.ChargeTermICBInfo(sdc);
        Test.stopTest();

        assertSyncInfoWithReason(
            SWNStepInfo.ChargeTermICBInfo.class.getName(),
            whenChargeTermSynced,
            SWNHelper.SYNCED,
            'because charge term is already synced'
        );
    }
}