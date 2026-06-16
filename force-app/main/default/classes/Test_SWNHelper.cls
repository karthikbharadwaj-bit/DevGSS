@IsTest
private class Test_SWNHelper {
    private static final String PACKAGE_ID = '1389379001';
    private static final String PACKAGE_CATALOG_ID = '18';
    private static final String PACKAGE_VERSION = '1';
    private static final String PACKAGE_DURATION = Product2Helper.CHARGE_TERM_MONTHLY;
    private static final String CHANGED_BILLING_ID = '1239';
    private static final String BILLING_ID = (String) ValueProviderBuilder.provideUniqueString().getValue();
    private static final Date TODAY = Date.today();
    // private static final String PACKAGE_INFO = '[{"packageInfo":{"id":"1234"},"contract":{"extId":"Office","billingId":"4321","status":"test"}}]';
    private static final String PACKAGE_INFO =
        '[{"id":"18","version":"1","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"' +
            PACKAGE_CATALOG_ID + '","version":"' + PACKAGE_VERSION + '"},"productName":"Office"' +
            ',"duration":"' + PACKAGE_DURATION + '","edition":{"id":1,"name":"Standard"},"contract":' +
            '{"id":"a8f0S0000008cxHQAQ","extId":"nib","billingId":' + CHANGED_BILLING_ID +
            '},"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":' +
            '"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":' +
            '"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null,"discountTemplates":[{"id":123,"values":{}}]}]';

    private static final String PACKAGE_INFO_QLI = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"DL","discount":{"type":"Percent","value":"3.48"},"price":"40"}';

    private static final String LICENSE_RESPONSE = '[{"catalogId":"LC_DL_75","qty":"5"},{"catalogId":"LC_DL-UNL_50","qty":"5"}]';
    private static final String PKG_DESCRIPTION = '{"contractExtId":"nib","salesAgreement":"Test"}';

    @testSetup
    static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://fake-billing-api',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.Login__c => 'login',
                NGBS_Settings__c.Password__c => 'password'
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => BILLING_ID,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();
    }

    private static Quote buildQuoteWithPkgInfo(String pkgInfo) {
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, pkgInfo)
            .build()
            .getRecord();
    }

    private static Quote selectQuoteById(Id quoteId) {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(quoteId)
            .subselect(new ServiceInfoSelector().selectServiceInfo())
            .executeQuery()
        ).getFirst();
    }

    private static Account queryAccount() {
        return (Account) new ListOptional(new AccountSelector()
            .selectAccounts()
            .executeQuery()
        ).getFirst();
    }

    private static BillingWrappers.BillingContract buildActiveBillingContract() {
        BillingWrappers.BillingContract cnt = new BillingWrappers.BillingContract();
        cnt.id = '2';
        cnt.startBillingCycleNumber = 1;
        cnt.term = 24;
        cnt.renewalTerm = 24;
        cnt.startDate = System.today();
        cnt.description = PKG_DESCRIPTION;
        return cnt;
    }

    private static User createSalesUser() {
        Profile salesProfile = (Profile) new ProfileSelector()
            .selectProfileByName(ProfileHelper.PROFILE_NAME_SALES_REP_LIGHTNING)
            .executeQuery()
            .get(0);

        return (User) new SObjectBuilder(User.SObjectType)
            .setField(User.ProfileId, salesProfile.Id)
            .create()
            .getRecord();
    }

    private static void setAllowRepricePermission(Id userId) {
        PermissionSet ps1 = new PermissionSet(
            Name = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE,
            Label = CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE
        );
        insert ps1;

        SetupEntityAccess testEntityAccess = new SetupEntityAccess(
            ParentId = ps1.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CustomPermissionHelper.PERMISSION_CAN_TRIGGER_NGBS_REPRICE].Id);
        insert testEntityAccess;

        PermissionSetAssignment psa1 = new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = ps1.Id
        );
        insert psa1;
    }

    @isTest
    static void testGetContractSyncStatus() {
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
        Quote qtWithContract = new Quote(Package_Info__c = new SWNMockBuilders.PackageInfoBuilder().withContract().buildAsJson());
        Quote qtWithoutContact = new Quote(Package_Info__c = new SWNMockBuilders.PackageInfoBuilder().buildAsJson());

        Test.startTest();
            String skippedIsExpected = SWNHelper.getContractSyncStatus(contractNotSynced, qtWithoutContact);
            String notSyncedIsExpected = SWNHelper.getContractSyncStatus(contractNotSynced, qtWithContract);
            String syncIsExpected = SWNHelper.getContractSyncStatus(contractSynced, qtWithContract);
            String resyncIsExpected = SWNHelper.getContractSyncStatus(contractResynced, qtWithContract);
        Test.stopTest();

        Assert.areEqual(SWNHelper.SKIPPED, skippedIsExpected, SWNHelper.SKIPPED + ' is expected when there is no contract');
        Assert.areEqual(SWNHelper.NOT_SYNCED, notSyncedIsExpected, SWNHelper.NOT_SYNCED + ' is expected when there contract is not synced');
        Assert.areEqual(SWNHelper.SYNCED, syncIsExpected, SWNHelper.SYNCED + ' is expected when contract is synced');
        Assert.areEqual(SWNHelper.RESYNC, resyncIsExpected, SWNHelper.RESYNC + ' is expected when contract is re-synced');
    }

    @isTest
    static void testCustomRulesValidatorPass() {
        Opportunity oppPass = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => TODAY,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity oppFailed = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => TODAY,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .build()
            .getRecord();

        String passedValidator = SyncWithNGBS.customRulesValidation(oppPass.Id);
        String failedValidator = SyncWithNGBS.customRulesValidation(oppFailed.Id);

        List<Response.ResponseMessage> respByPassedValidator =
            (List<Response.ResponseMessage>) JSON.deserialize(passedValidator, List<Response.ResponseMessage>.class);
        List<Response.ResponseMessage> respByFailedValidator =
            (List<Response.ResponseMessage>) JSON.deserialize(failedValidator, List<Response.ResponseMessage>.class);

        String validationMessage = 'some validation rule text';

        Test.startTest();
            String customMessage = SWNHelper.getCustomValidationMessage('FIELD_CUSTOM_VALIDATION_EXCEPTION, ' + validationMessage + ' : [  ');
        Test.stopTest();

        Assert.areEqual(0, respByPassedValidator.size(), 'Validation should be passed when opp is updated');
        Assert.areNotEqual(0, respByFailedValidator.size(), 'Validation shouldn\'t be passed is not updated');
        Assert.isTrue(customMessage.contains(validationMessage), 'Custom message should contains validation rule error message');
    }

    @isTest
    static void testGetRunners() {
        Id quoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Map<String, Type> stepToRunnerMap = new Map<String, Type> {
            SWNStep.SYNC_TO_CCB_DOWNSELL => SWNUpsellDownsellRunner.class,
            SWNStep.SYNC_TO_CCB_UPGRADE => SWNSyncToCCBUpgradeRunner.class,
            SWNStep.SYNC_TO_NGBS_UPGRADE => SWNSyncToNGBSUpgradeRunner.class,
            SWNStep.SYNC_TO_ICB => SWNSyncToICBOrInContactRunner.class,
            SWNStep.CONVERT_TO_PAID => SWNConvertToPaidRunner.class,
            SWNStep.UP_SELL => SWNUpsellRunner.class,
            SWNStep.ORDER => SWNOrderRunner.class,
            SWNStep.DOWN_SELL => SWNDownsellRunner.class,
            SWNStep.UPGRADE => SWNUpgradeRunner.class,
            SWNStep.DISCOUNT_SYNC => SWNSyncDiscountRunner.class,
            SWNStep.CONTRACT_SYNC => SWNSyncContractRunner.class,
            SWNStep.REPRICE_SYNC => SWNSyncRepriceRunner.class,
            SWNStep.UPDATE_LICENSE_LIMITS => SWNUpdateLicenseLimitsRunner.class,
            SWNStep.CONTRACT_CANCELLATION => SWNContractCancellationRunner.class,
            SWNStep.SYNC_INVOICE => SWNSyncInvoiceRunner.class,
            SWNStep.ENGAGE_ACCOUNT_TERMINATION => SWNEngageAccountTerminationRunner.class,
            SWNStep.CHARGE_TERM_SYNC => SWNSyncChargeTermRunner.class,
            SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE => SWNSyncSpendingLimitRunner.class
        };

        Test.startTest();
            for (String step : stepToRunnerMap.keySet()) {
                Assert.areEqual(
                    stepToRunnerMap.get(step).getName(),
                    String.valueOf(SWNHelper.getRunner(quoteId, step)).split(':')[0],
                    'Runner should have ' + stepToRunnerMap.get(step).getName() + ' type'
                );
            }
        Test.stopTest();
    }

    @isTest
    static void testValidateSyncWithNGBS() {
        Id quoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            try {
                SWNHelper.validateSyncWithNGBS(quoteId, false);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.areEqual(QuoteHelper.QUOTE_NOT_FOUND, ex.getMessage(), 'Quote not found error message should be thrown');
            }
        Test.stopTest();
    }

    @isTest
    static void testGetStopSyncDownsell() {
        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO);

        Test.startTest();
            Response res = SWNHelper.getStopSync(SWNStep.DOWN_SELL, qt, '1234', null);
        Test.stopTest();

        Assert.isNull(res.getData(SWNHelper.STOP_AUTO_SYNC), 'There is no stop sync property in response');
    }

    @isTest
    static void testGetStopSyncUpgrade() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', LICENSE_RESPONSE, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO);
        BillingWrappers.NGBSAccount acc = new BillingWrappers.NGBSAccount();
        acc.id = '1234';

        Test.startTest();
            try {
                SWNHelper.getStopSync(SWNStep.UPGRADE, qt, '1234', acc);
                Assert.fail('Error should be thrown');
            } catch (Exception ex) {
                Assert.areEqual('Can not get information for "isNGBSPlanChange" (Quote line items not found)', ex.getMessage(), 'Messages should be equal');
            }
        Test.stopTest();
    }

    @isTest
    static void testGetStopSyncUpsell() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', LICENSE_RESPONSE, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO);

        Test.startTest();
            Response res = SWNHelper.getStopSync(SWNStep.UP_SELL, qt, '1234', null);
        Test.stopTest();

        Assert.isNull(res.getData(SWNHelper.STOP_AUTO_SYNC), 'There is no stop sync property in response');
    }

    @isTest
    static void testFilterDiscountTemplates() {
        final String dtgJson = '[{"id":72106001,"priority":"A","target":{"catalogId":"123","version":"2"},"discountTemplates":[{"id":86266001,"applicableTo":{"type":"CatalogId","id":"LC_DID_53"},'
            + '"applicationTerms":{"startDate":"2018-05-09T00:00Z[UTC]","endDate":"2020-05-09T00:00Z[UTC]"},"values":{"Monthly":{"unit":"Money","value":1E+1,'
            + '"recurringTerms":{"unit":"Months","value":1}}}}]}]';
        NGBS_Discount.DiscountTemplateGroup dg1 = new NGBS_Discount.DiscountTemplateGroup();
        dg1.priority = '1';
        NGBS_Discount.DiscountTemplateGroup dg2 = new NGBS_Discount.DiscountTemplateGroup();
        dg2.priority = 'A';
        NGBS_Discount.DiscountTemplateGroup dg3 = new NGBS_Discount.DiscountTemplateGroup();
        dg3.priority = 'A';
        BillingWrappers.PackageInfo pkgInfo1 = new BillingWrappers.PackageInfo();
        pkgInfo1.catalogId = '123';
        pkgInfo1.version = '2';
        dg3.target = pkgInfo1;
        NGBS_Discount.DiscountTemplateGroup dg4 = new NGBS_Discount.DiscountTemplateGroup();
        dg4.priority = 'A';
        BillingWrappers.PackageInfo pkgInfo2 = new BillingWrappers.PackageInfo();
        pkgInfo2.catalogId = '321';
        pkgInfo2.version = '2';
        dg4.target = pkgInfo2;

        List<NGBS_Discount.DiscountTemplateGroup> dtGroups1 = new List<NGBS_Discount.DiscountTemplateGroup> { dg1, dg2, dg3, dg4 };
        List<NGBS_Discount.DiscountTemplateGroup> dtGroups2 = (List<NGBS_Discount.DiscountTemplateGroup>) JSON.deserialize(dtgJson, List<NGBS_Discount.DiscountTemplateGroup>.class);

        Test.startTest();
            List<NGBS_Discount.DiscountTemplateGroup> dtgResp1 = SWNHelper.filterDiscountTemplates_new(dtGroups1, '321', '2', null);
            List<NGBS_Discount.DiscountTemplateGroup> dtgResp2 = SWNHelper.filterDiscountTemplates_new(dtGroups2, '123', '2', 'Monthly');
        Test.stopTest();

        Assert.areEqual(1, dtgResp1.size(), 'Discount template group size is 1');
        Assert.areEqual(1, dtgResp2.size(), 'Discount template group size is 1');
    }

    @isTest
    static void testGetDownsellQliList() {
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, 5)
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Quantity__c, 10)
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Entitlement__c, ent);

        Test.startTest();
            List<QuoteLineItem> qlis = SWNHelper.getDownsellQliList(new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.areEqual(1, qlis.size(), 'There should be one downsell qli');
    }

    @isTest
    static void testFilterRepriceStep() {
        final String pkgInfo = '[{"packageInfo":{"id":"1234"}}]';
        Quote qt = buildQuoteWithPkgInfo(pkgInfo);
        SWNScenarioHelper.Scenario sc = SWNScenarioHelper.SCENARIOS.get('CONTRACTED_PAID_UPSELL');

        Assert.areEqual(4, sc.stepNames.size(), 'Amount of steps should 4');
        Assert.isTrue(sc.stepNames.contains(SWNStep.REPRICE_SYNC), 'Reprice step exists');

        Test.startTest();
            SWNHelper.filterRepriceStep(sc, qt, new List<BillingWrappers.BillingContract>());
        Test.stopTest();

        Assert.areEqual(3, sc.stepNames.size(), 'Amount of steps should 3');
        Assert.isFalse(sc.stepNames.contains(SWNStep.REPRICE_SYNC), 'Reprice step should be removed');
    }

    @isTest
    static void testUpdateSimplifiedDownsellStep() {
        Account acc = queryAccount();

        Triggers.switchOff();
        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Auto and manual items',
                    'Only auto items',
                    'Only manual items'
                }),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => Date.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Auto and manual items',
                    'Only auto items',
                    'Only manual items'
                }),
                Quote.OpportunityId => ValueProviderBuilder.provideList(new List<String> {opps[0].Id, opps[1].Id, opps[2].Id}),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.IsPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'HD_AutoWithCase', 'HD_Auto', 'HD_Manual'}),
                Product2.ExtId__c => ValueProviderBuilder.provideList(new List<String> {'LC_HD_1', 'LC_HD_2', 'LC_HD_3'}),
                Product2.DownsellType__c => ValueProviderBuilder.provideList(new List<String> {
                    Product2Helper.PRODUCT_DOWNSELL_TYPE_AUTO_WITH_CASE,
                    Product2Helper.PRODUCT_DOWNSELL_TYPE_AUTO,
                    '' // this product should be sent to manual case by default
                })
            })
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(
                    new List<String> {products[0].Id, products[1].Id, products[2].Id}),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ValueProviderBuilder.provideList(new List<String> {'HD_AutoWithCase', 'HD_Auto', 'HD_Manual'}),
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.Product__c => ValueProviderBuilder.provideList(new List<String> {products[0].Id, products[1].Id, products[2].Id}),
                Entitlement__c.Quote__c => ValueProviderBuilder.provideList(new List<String> {quotes[0].Id, quotes[1].Id, quotes[2].Id})
            })
            .quantity(3)
            .create()
            .getRecords();

        BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(TestDataGenerator.TEST_PACKAGE_INFO);
        qliPackageInfo.CategoryCode = 'HD';
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<String> {quotes[0].Id, quotes[1].Id, quotes[2].Id}),
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {products[0].Id, products[1].Id, products[2].Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<String> {pbes[0].Id, pbes[1].Id, pbes[2].Id}),
                QuoteLineItem.Quantity => -5,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Entitlement__c => ValueProviderBuilder.provideList(new List<String> {ents[0].Id, ents[1].Id, ents[2].Id}),
                QuoteLineItem.PackageInfo__c => JSON.serialize(qliPackageInfo)
            })
            .quantity(3)
            .create()
            .getRecords();

        BillingHttpRequestMock mockNGBSBillingInfoSummaryLicenses = new BillingHttpRequestMock();
        mockNGBSBillingInfoSummaryLicenses.body = '[]';
        mockNGBSBillingInfoSummaryLicenses.code = 200;
        mockNGBSBillingInfoSummaryLicenses.status = 'Completed';
        Test.setMock(HttpCalloutMock.class, mockNGBSBillingInfoSummaryLicenses);

        Test.startTest();
            List<Quote> quotesForSync = new List<Quote>();
            for (Quote currentQuote : quotes) {
                Quote qt = selectQuoteById(currentQuote.Id);
                quotesForSync.add(qt);
            }

            SWNScenarioHelper.Context context = new SWNScenarioHelper.Context();
            context.setFlow(new SWNScenarioHelper.SalesQuoteFlow(quotesForSync[0]));
            SWNScenarioHelper.Scenario sc = context.getScenario();

            List<String> downSellStepLabelsAfterUpdate = new List<String>();
            List<Boolean> downSellStepTimestamp = new List<Boolean>();

            for (Quote qt : quotesForSync) {
                // reinitialize to prevent context sharing between iterations
                SWNStep step = SWNStep.STEPS.get(SWNStep.DOWN_SELL);
                step.isNeedToLogTimeStamp = false;

                SWNHelper.updateSimplifiedDownsellStep(sc, qt);
                downSellStepLabelsAfterUpdate.add(sc.stepsMap.get(SWNStep.DOWN_SELL).label);
                downSellStepTimestamp.add(sc.stepsMap.get(SWNStep.DOWN_SELL).isNeedToLogTimeStamp);
            }
        Test.stopTest();

        Assert.areEqual(
            SWNHelper.SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO_AND_MANUAL,
            downSellStepLabelsAfterUpdate[0],
            'Auto-manual label should be set for: ' + opps[0].Name
        );
        Assert.isTrue(
            downSellStepTimestamp[0],
            'Timestamp logging should be enabled for the downsell step with auto and manual labels'
        );

        Assert.areEqual(
            SWNHelper.SIMPLIFIED_LBO_DOWN_SELL_LABEL_AUTO,
            downSellStepLabelsAfterUpdate[1],
            'Auto label should be set for: ' + opps[1].Name
        );
        Assert.isTrue(
            downSellStepTimestamp[1],
            'Timestamp logging should be enabled for the downsell step with auto label'
        );

        Assert.areEqual(
            SWNHelper.SIMPLIFIED_LBO_DOWN_SELL_LABEL_MANUAL,
            downSellStepLabelsAfterUpdate[2],
            'Manual label should be set for: ' + opps[2].Name
        );
        Assert.isFalse(
            downSellStepTimestamp[2],
            'Timestamp logging should be disabled for the manual downsell step'
        );
    }

    @isTest
    static void testValidateRepriceStep() {
        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO);

        List<BillingWrappers.BillingContract> billingContracts = new List<BillingWrappers.BillingContract> { buildActiveBillingContract() };

        User testUser = createSalesUser();
        Test.startTest();
            System.runAs(testUser) {
                setAllowRepricePermission(testUser.Id);
                Boolean isValid = SWNHelper.validateRepriceStep(qt, billingContracts);
                Assert.isTrue(isValid, 'Reprice step validation should be passed');
            }
        Test.stopTest();
    }

    @isTest
    static void testIsContractChanged() {
        List<BillingWrappers.BillingContract> billingContracts1 = new List<BillingWrappers.BillingContract> { buildActiveBillingContract() };

        BillingWrappers.BillingContract cnt = new BillingWrappers.BillingContract();
        cnt.startBillingCycleNumber = 1;
        BillingWrappers.FunnelPackage pkg = new BillingWrappers.FunnelPackage(PACKAGE_ID, PACKAGE_VERSION);
        pkg.description = PKG_DESCRIPTION;
        cnt.packages = new List<BillingWrappers.FunnelPackage> { pkg };
        List<BillingWrappers.BillingContract> billingContracts2 = new List<BillingWrappers.BillingContract> { cnt };

        Test.startTest();
            Boolean isContractChanged1 = SWNHelper.isContractChanged(null, null, null);
            Boolean isContractChanged2 = SWNHelper.isContractChanged(billingContracts1, 'nib', null);
            Boolean isContractChanged3 = SWNHelper.isContractChanged(billingContracts2, 'bin', PACKAGE_ID);
        Test.stopTest();

        Assert.isFalse(isContractChanged1, 'Billing contract has not changed');
        Assert.isFalse(isContractChanged2, 'Billing contract has not changed');
        Assert.isTrue(isContractChanged3, 'Billing contract has changed');
    }

    @isTest
    static void testGetUpsellQliList() {
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, 10)
            .build()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.Quantity__c, 5)
            .build()
            .getRecord();
        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qli,
            QuoteLineItem.class,
            'Entitlement__r',
            ent
        );

        Test.startTest();
            List<QuoteLineItem> qlis = SWNHelper.getUpsellQliList(new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.areEqual(1, qlis.size(), 'There should be one upsell qli');
    }

    @isTest
    static void testCheckSyncQtyStatus() {
        final String billingLicensesByCategoriesResponse = '[{"id": 1518895002,"catalogId": "LC_DL-UNL_50","scheduledForRemoval":false,"externalId": null,' +
            '"categoryId": "DL-UNL","description": "test","qty": 5,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": []}]';
        final String licensesResponse = '[{"catalogId":"LC_DL-UNL_50","qty":"5"}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'test name',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(new List<Integer> { 10, 5 }),
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .quantity(2)
            .build()
            .getRecords();

        qlis[0].putSObject(QuoteLineItem.Product2Id, prod);
        qlis[1].putSObject(QuoteLineItem.Product2Id, prod);

        Test.startTest();
            Boolean isSyncedQty1 = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qlis[0] });
            Boolean isSyncedQty2 = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qlis[1] });
        Test.stopTest();

        Assert.isFalse(isSyncedQty1, 'Quantity was not synced yet');
        Assert.isTrue(isSyncedQty2, 'Quantity was successfully synced');
    }

    @isTest
    static void checkSyncQtyStatus_onlyOneTimeQlis_returnsFalse() {
        // Given - all QLIs are one-time, should return false early without API calls
        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'One Time Product',
                Product2.ExtId__c => 'LC_ONETIME_1',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, prod);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isFalse(result, 'Should return false for one-time only QLIs');
    }

    @isTest
    static void checkSyncQtyStatus_withScheduledForRemoval_returnsTrue() {
        // Given - license has qty 10, but 3 are scheduledForRemoval, so synced qty = 7
        final String billingLicensesByCategoriesResponse = '[{"id": 1518895002,"catalogId": "LC_DL-UNL_50","scheduledForRemoval":true,"externalId": null,' +
            '"categoryId": "DL-UNL","description": "test","qty": 3,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": []}]';
        final String licensesResponse = '[{"catalogId":"LC_DL-UNL_50","qty":"10"}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'test name',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => 10,
                QuoteLineItem.NewQuantity__c => 7,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, prod);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when synced qty (10-3=7) matches NewQuantity__c (7)');
    }

    @isTest
    static void checkSyncQtyStatus_withTaxesProduct_skipsAndReturnsTrue() {
        // Given - taxes product should be skipped
        final String billingLicensesByCategoriesResponse = '[]';
        final String licensesResponse = '[]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 taxProd = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Tax Product',
                Product2.ExtId__c => 'LC_TAX_1',
                Product2.Family => Product2Helper.FAMILY_TAXES,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => taxProd.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 999,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, taxProd);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when taxes QLI is skipped');
    }

    @isTest
    static void checkSyncQtyStatus_withTechnicalProduct_skipsAndReturnsTrue() {
        // Given - technical product should be skipped
        final String billingLicensesByCategoriesResponse = '[]';
        final String licensesResponse = '[]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 techProd = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Technical Product',
                Product2.ExtId__c => 'LC_TECH_1',
                Product2.Family => Product2Helper.FAMILY_TECHNICAL,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => techProd.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 999,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, techProd);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when technical QLI is skipped');
    }

    @isTest
    static void checkSyncQtyStatus_withHiddenLicense_skipsAndReturnsTrue() {
        // Given - hidden license should be skipped
        final String billingLicensesByCategoriesResponse = '[]';
        final String licensesResponse = '[]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Hidden Product',
                Product2.ExtId__c => 'LC_HIDDEN_1',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 999,
                QuoteLineItem.IsHiddenLicense__c => true,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, prod);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when hidden license QLI is skipped');
    }

    @isTest
    static void checkSyncQtyStatus_emptyQliList_returnsTrue() {
        // Given - empty QLI list
        final String billingLicensesByCategoriesResponse = '[]';
        final String licensesResponse = '[]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem>());
        Test.stopTest();

        Assert.isTrue(result, 'Should return true for empty QLI list');
    }

    @isTest
    static void checkSyncQtyStatus_licenseNotFound_returnsFalse() {
        // Given - no matching license in response for the QLI catalogId
        final String billingLicensesByCategoriesResponse = '[]';
        final String licensesResponse = '[{"catalogId":"LC_OTHER_99","qty":"5"}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'test name',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, prod);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isFalse(result, 'Should return false when license not found and NewQuantity != 0');
    }

    @isTest
    static void checkSyncQtyStatus_mixedQlisWithSkippable_returnsTrue() {
        // Given - one regular QLI (synced) and one taxes QLI (should be skipped)
        final String billingLicensesByCategoriesResponse = '[{"id": 1518895002,"catalogId": "LC_DL-UNL_50","scheduledForRemoval":false,"externalId": null,' +
            '"categoryId": "DL-UNL","description": "test","qty": 5,"billingType": "Recurring","billingCycleDuration": "Monthly","subLicenses": []}]';
        final String licensesResponse = '[{"catalogId":"LC_DL-UNL_50","qty":"5"}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/license/info/categories', 'Completed', billingLicensesByCategoriesResponse, 200, HttpHelper.METHOD_POST),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Product2 serviceProd = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Service Product',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        Product2 taxProd = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Tax Product',
                Product2.ExtId__c => 'LC_TAX_1',
                Product2.Family => Product2Helper.FAMILY_TAXES,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem serviceQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => serviceProd.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        serviceQli.putSObject(QuoteLineItem.Product2Id, serviceProd);

        QuoteLineItem taxQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => taxProd.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 999,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .build()
            .getRecord();
        taxQli.putSObject(QuoteLineItem.Product2Id, taxProd);

        Test.startTest();
            Boolean result = SWNHelper.checkSyncQtyStatus('test', 'test', new List<QuoteLineItem> { serviceQli, taxQli });
        Test.stopTest();

        Assert.isTrue(result, 'Should return true when non-skippable QLIs are synced');
    }

    @isTest
    static void testIsSkipQli() {
        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Family => Product2Helper.FAMILY_TAXES,
                Product2.Id => ValueProviderBuilder.provideDummyId(Product2.sObjectType)
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, 10)
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Product2Id, prod);

        Test.startTest();
            Boolean isSkipQli = SWNHelper.isSkipQli(qli);
        Test.stopTest();

        Assert.isTrue(isSkipQli, 'Taxes qli should be skipped');
    }

    @isTest
    static void testCheckUpgradeCCBStatus() {
        final String pkgInfo = '[{"duration":"12","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":' + PACKAGE_CATALOG_ID + ',"version":' + PACKAGE_VERSION + '}}]';
        Quote qt = buildQuoteWithPkgInfo(pkgInfo);

        BillingWrappers.NGBSAccount acc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;
        pkg.catalogId = PACKAGE_CATALOG_ID;
        pkg.version = PACKAGE_VERSION;
        pkg.masterDuration = '12';
        acc.packages = new List<BillingWrappers.NGBSAccountPackage> { pkg };

        Test.startTest();
            Boolean isCheckStatus2 = SWNHelper.checkUpgradeCCBStatus(qt, acc);
        Test.stopTest();

        Assert.isTrue(isCheckStatus2, 'Upgrade status is checked');
    }

    @isTest
    static void testCheckUpgradeCCBStatusFailed() {
        final String pkgInfo = '[{"packageInfo":{"id":' + PACKAGE_ID + '}}]';
        Quote qt = buildQuoteWithPkgInfo(pkgInfo);

        BillingWrappers.NGBSAccount acc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;

        try {
            Test.startTest();
                SWNHelper.checkUpgradeCCBStatus(qt, acc);
                Assert.fail('Error should be thrown');
            Test.stopTest();
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Failed to check upgrade status'), 'Error occured');
        }
    }

    @isTest
    static void testIsPackageEqual() {
        final String pkgInfo = '[{"packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":' + PACKAGE_CATALOG_ID + ',"version":' + PACKAGE_VERSION + '}}]';
        Quote qt = buildQuoteWithPkgInfo(pkgInfo);

        BillingWrappers.NGBSAccount acc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;
        pkg.catalogId = PACKAGE_CATALOG_ID;
        pkg.version = PACKAGE_VERSION;
        acc.packages = new List<BillingWrappers.NGBSAccountPackage> { pkg };

        Test.startTest();
            Boolean isPkgEqual = SWNHelper.isPackageEqual(acc, qt);
        Test.stopTest();

        Assert.isTrue(isPkgEqual, 'Packages should be equal');
    }

    @isTest
    static void testCheckPaidStatus() {
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.offerType = 'Regular';

        Test.startTest();
            Boolean isStatusPaid = SWNHelper.checkPaidStatus(pkg);
        Test.stopTest();

        Assert.isTrue(isStatusPaid, 'Status should be Paid');
    }

    @isTest
    static void testGetLBOBillingExceptions() {
        final String categories = 'test_category_code_2';
        final String productLic = 'LC_2';
        new SObjectBuilder(NGBSLBOBillingLimits__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSLBOBillingLimits__c.Name => 'test_1',
                NGBSLBOBillingLimits__c.Categories__c => categories,
                NGBSLBOBillingLimits__c.Quantity__c => 0,
                NGBSLBOBillingLimits__c.Manual_Upsell__c => true,
                NGBSLBOBillingLimits__c.Only_LBO__c => true
            })
            .create();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.PackageInfo__c,'{"categoryCode":"' + categories + '"}')
            .build()
            .getRecord();

        qli = (QuoteLineItem) Test_Utils.putIntoUnwritableFields(
            qli,
            QuoteLineItem.class,
            new Map<String, Object> {
                'Product_Lic_Id__c' => productLic
            }
        );

        Test.startTest();
            Map<String, String> exceptions = SWNHelper.getLBOBillingExceptions(new List<QuoteLineItem> { qli }, new List<String>());
        Test.stopTest();

        Assert.isTrue(exceptions.size() == 1, 'There should be 1 exception in map');
        Assert.areEqual(categories, exceptions.get(productLic), 'There should be 1 exception in map');
    }

    @isTest
    static void testSelectQuoteByIdWithExactField() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'test name',
                Opportunity.CloseDate => Date.today()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.InvoiceId__c => 'testInvoice'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            Quote selectedQt = SWNHelper.selectQuoteByIdWithExactField(qt.Id, Quote.InvoiceId__c);
        Test.stopTest();

        Assert.isNotNull(selectedQt, 'Quote should be selected');
        Assert.isNotNull(selectedQt.InvoiceId__c, 'Field should be selected additionally');
    }


    @isTest
    static void testGetQliTypesForSimplifiedLBODownsell() {
        final String bodyForMock = '[{"amount": 120009.99,"catalogId": "LC_HD_4","discountAmount": 0,"qty": 2001},{' +
            '"amount": 120009.99,"catalogId": "LC_HD_4","discountAmount": -36012,"discountValue": {"unit": "Percent","value": 30},"qty": 1000}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license?mergeDiscounts=false', 'Completed', bodyForMock, 200, HttpHelper.METHOD_GET)
        };

        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = queryAccount();

        Triggers.switchOff();
        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'test Oppty',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => Date.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.BillingPackage__c => pkg.Id,
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.IsPrimary__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> { 'LC_HD_1', 'LC_HD_2', 'LC_HD_3', 'LC_HD_4' }),
                Product2.ExtId__c => ValueProviderBuilder.provideList(new List<String> { 'LC_HD_1', 'LC_HD_2', 'LC_HD_3', 'LC_HD_4' }),
                Product2.downsellType__c => ValueProviderBuilder.provideList(new List<String> {
                    product2helper.PRODUCT_DOWNSELL_TYPE_AUTO,
                    product2helper.PRODUCT_DOWNSELL_TYPE_AUTO_WITH_CASE,
                    '',
                    product2helper.PRODUCT_DOWNSELL_TYPE_AUTO
                })
            })
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(
                    new List<String> {products[0].Id, products[1].Id, products[2].Id, products[3].Id}),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true
            })
            .quantity(4)
            .create()
            .getRecords();

        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ValueProviderBuilder.provideList(new List<String> {'LC_HD_1', 'LC_HD_2', 'LC_HD_3', 'LC_HD_4'}),
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.Product__c => ValueProviderBuilder.provideList(new List<String> {products[0].Id, products[1].Id, products[2].Id, products[3].Id}),
                Entitlement__c.Quote__c => qt.Id
            })
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {products[0].Id, products[1].Id, products[2].Id, products[3].Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<String> {pbes[0].Id, pbes[1].Id, pbes[2].Id, pbes[3].Id}),
                QuoteLineItem.Quantity => -5,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuotelIneItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                QuotelIneItem.Discount => 0,
                QuoteLineItem.Entitlement__c => ValueProviderBuilder.provideList(new List<String> {ents[0].Id, ents[1].Id, ents[2].Id, ents[3].Id})
            })
            .quantity(4)
            .create()
            .getRecords();

        qt = selectQuoteById(qt.Id);

        Test.startTest();
            List<QuoteLineItem> downsellQliList = SWNHelper.filterQuoteLineItems(SWNHelper.getDownsellQliList(qt.QuoteLineItems));
            Map<String, List<QuoteLineItem>> qliTypes = SWNHelper.getQliTypesForSimplifiedLBODownsell(qt, downsellQliList, new List<Cost_Center__c>());
        Test.stopTest();

        Assert.areEqual(4, qliTypes.keySet().size(), 'There should be all 4 types of QLIs');
        Assert.areEqual('LC_HD_1', qliTypes.get(SWNHelper.DOWNSELL_TYPE_AUTO)[0].Product2.Name, 'LC_HD_1 should be placed in Auto type');
        Assert.areEqual('LC_HD_2', qliTypes.get(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE)[0].Product2.Name, 'LC_HD_1 should be placed in Auto With Case type');
        Assert.areEqual('LC_HD_3', qliTypes.get(SWNHelper.DOWNSELL_TYPE_MANUAL)[0].Product2.Name, 'LC_HD_1 should be placed in Manual type');
    }

    @isTest
    private static void testSyncEntitlements() {
        final String licenseId = 'LC_DL_75';
        final String ngbsAccResponse = '{"id":5218705001,"packages":[{"id":' + PACKAGE_ID + ',"catalogId":"18","version":"1","status":"Active",' +
            '"offerType":"ProofOfConcept","description":"RingCentral Office Standard","currency":"USD","masterDuration":"Monthly",' +
            '"licenses":[{"id":47787810001,"catalogId":"' + licenseId + '","categoryId":"DL","externalId":"rc:phonelineid:1791051012","description":"DigitalLine",' +
            '"qty":1,"billingType":"Recurring","billingCycleDuration":"Monthly","descriptionKey":"F33BCA901CB8B47F14DE4C52F2413875"}]}]}';

        final String licensesResponse = '[{"amount":0.08,"catalogId":"' + licenseId + '","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly",' +
            '"dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Disconnect Scrub, per 10 scrubs","descriptionKey":"E528A917D99E9C0E7976FE2F7301474B"}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/summary?shortView=true', 'Completed', ngbsAccResponse, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        final String qliPkgInfo = '{"categoryCode":"DL-UNL", "categoryPath":"DL-UNL", "discount"' +
            ':{},"duration":"Monthly","id":"18","price":0,"version":"1","parent":"' + licenseId + '","q":33,' +
            '"lboxes":[{"elementID":"LB_702","min":1,"max":100}]}';

        Account acc = queryAccount();
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'test name',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.Account__c => acc.Id,
                Quote.IsPrimary__c => true
            })
            .create()
            .getRecord();


        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'test name',
                Product2.ExtId__c => licenseId,
                Product2.Family => Product2Helper.FAMILY_COMMON_PHONE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Package_Info_QLI__c => qliPkgInfo
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            SWNHelper.syncEntitlements(qt.Id);
        Test.stopTest();

        Quote selectQt = (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(opp.Name)
            .executeQuery()
        ).getFirst();

        for (QuoteLineItem qli : selectQt.QuoteLineItems) {
            Assert.isTrue(qli.Entitlement__r.Active__c, 'Status should be active');
            Assert.areEqual(0, qli.Entitlement__r.Price__c, 'Prices should be equal');
            Assert.areEqual(qli.Product2Id, qli.Entitlement__r.Product__c, 'Product Id should be correct');
            Assert.areEqual(QuoteLineItemHelper.CHARGE_TERM_MONTHLY, qli.Entitlement__r.ChargeTerm__c, 'Charge term should be Monthly');
            Assert.areEqual(0, qli.Entitlement__r.Discount__c, 'There should not be discounts');
            Assert.areEqual(null, qli.Entitlement__r.Discount_Type__c, 'There should not be discount type');
            Assert.areEqual(QuoteHelper.PACKAGE_OFFER_TYPE_POC, qli.Entitlement__r.PackageOfferType__c, 'Package offer type should be POC');
            Assert.areEqual('1', qli.Entitlement__r.PackageVersion__c, 'Versions should be equal');
            Assert.areEqual('18', qli.Entitlement__r.PackageCatalogId__c, 'CatalogId should be equal');
        }
    }

    @isTest
    static void testGetDiscountTemplateGroups() {
        final String dtgResponse = '[{"id":72106001}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/discountTemplateGroup', 'Completed', dtgResponse, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Response res = SWNHelper.getDiscountTemplateGroups('test', 'test');
        Test.stopTest();

        List<NGBS_Discount.DiscountTemplateGroup> dTGs = (List<NGBS_Discount.DiscountTemplateGroup>) res.getData('result');
        Assert.isNotNull(dTGs, 'Response should have discount templates');
        Assert.areEqual('72106001', dTGs.get(0).id, 'Ids should be equal');
    }

    @isTest
    static void testIsContractWasDeselected() {
        final String pkgInfo = '[{"packageInfo":{"id":"1234"}}]';
        Quote qt = buildQuoteWithPkgInfo(pkgInfo);

        Test.startTest();
            Boolean isContractWasDeselected = SWNHelper.isContractWasDeselected(qt, new List<BillingWrappers.BillingContract> { buildActiveBillingContract() });
        Test.stopTest();

        Assert.isTrue(isContractWasDeselected, 'Contract should absent in SF');
    }

    @isTest
    static void testIsPackagePlanEqual() {
        final String pkgInfo = '[{"duration":"12","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":' + PACKAGE_CATALOG_ID + ',"version":' + PACKAGE_VERSION + '}}]';
        Quote qt = buildQuoteWithPkgInfo(pkgInfo);

        BillingWrappers.NGBSAccount acc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;
        pkg.catalogId = PACKAGE_CATALOG_ID;
        pkg.version = PACKAGE_VERSION;
        pkg.masterDuration = '12';
        acc.packages = new List<BillingWrappers.NGBSAccountPackage> { pkg };

        Test.startTest();
            Boolean isPackagePlanEqual = SWNHelper.isPackagePlanEqual(acc, qt);
        Test.stopTest();

        Assert.isTrue(isPackagePlanEqual, 'Package plan should be changed');
    }

    @isTest
    static void testIsPackagePlanEqualFailed() {
        try {
            Test.startTest();
                SWNHelper.isPackagePlanEqual(new BillingWrappers.NGBSAccount() , new Quote());
                Assert.fail('Error should be thrown');
            Test.stopTest();
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Failed to check change plan status'), 'Messages should be equal');
        }
    }

    @isTest
    static void testIsLBOOrOfficeProductSelectedWhenLBO() {
        Quote testQuote = new Quote(Enabled_LBO__c = true);
        Assert.isTrue(SWNHelper.isLBOOrOfficeProductSelected(testQuote), 'Should return true when LBO is selected');
    }

    @isTest
    static void testIsLBOOrOfficeProductSelectedWhenOfficeProductSelected() {
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => false,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        Assert.isTrue(SWNHelper.isLBOOrOfficeProductSelected(testQuote), 'Should return true when Office product is selected');
    }

    @isTest
    static void testIsLBOOrOfficeProductSelectedWhenNeitherLBOOrOfficeProductSelected() {
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => false,
                Quote.ServiceName__c => 'test',
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.package_info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();

        Assert.isFalse(SWNHelper.isLBOOrOfficeProductSelected(testQuote), 'Should return false when neither LBO or Office product is selected');
    }

    @isTest
    static void testGetQlisForAutoDownsell() {
        Map<String, List<QuoteLineItem>> qliTypesMap = new Map<String, List<QuoteLineItem>> {
            SWNHelper.DOWNSELL_TYPE_AUTO => new List<QuoteLineItem> { new QuoteLineItem() },
            SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE => new List<QuoteLineItem> { new QuoteLineItem() }
        };

        Test.startTest();
            List<QuoteLineItem> qlis = SWNHelper.getQlisForAutoDownsell(qliTypesMap);
        Test.stopTest();

        Assert.areEqual(2, qlis.size(), 'There should be two qlis of different downsell type');
    }

    @isTest
    static void testGetLicenseIdsToSkipForCheckQuantity() {
        new SObjectBuilder(NGBSHiddenLicenses__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSHiddenLicenses__c.Name => ValueProviderBuilder.provideList(new List<String> { 'test1', 'test2' }),
                NGBSHiddenLicenses__c.SkipQuantityValidationInSync__c => ValueProviderBuilder.provideList(new List<Boolean> { false, true }),
                NGBSHiddenLicenses__c.LicenseElementId__c => ValueProviderBuilder.provideList(new List<String> { 'LC_HD_522', 'ID1;ID2;ID3' })
            })
            .quantity(2)
            .create();

        Test.startTest();
            List<String> licenses = SWNHelper.getLicenseIdsToSkipForCheckQuantity();
        Test.stopTest();

        Assert.areEqual(3, licenses.size(), 'Licenses size should be 3');
    }

    @isTest
    static void testGetLicensesRequestBody() {
        QuoteLineItem qli = (QuoteLineItem) Test_Utils.putIntoUnwritableFields(
            new QuoteLineItem(),
            QuoteLineItem.class,
            new Map<String, Object> {
                'Product_Lic_Id__c' => 'LC_2'
            }
        );

        Test.startTest();
            List<BillingWrappers.LicensesRequestBody> reqBody1 = SWNHelper.getLicensesRequestBody(new List<QuoteLineItem>());
            List<BillingWrappers.LicensesRequestBody> reqBody2 = SWNHelper.getLicensesRequestBody(new List<QuoteLineItem> { qli });
        Test.stopTest();

        Assert.isTrue(reqBody1.isEmpty(), 'There is no request body');
        Assert.areEqual(1, reqBody2.size(), 'There should be one request body');
    }
}