@isTest
private with sharing class Test_SWNSyncDiscountRunner {
    private static final String PACKAGE_ID = '12345';
    private static final String BILLING_ID = '54321';
    private static final String OPP_NAME = 'opp name';
    private static final String PRODUCT_DIGITALLINE_UNLIMITED = 'DigitalLine Unlimited';
    private static final String LC_DL_UNL_50 = 'LC_DL-UNL_50';
    private static final String PACKAGE_INFO_QT = '[{"packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"123","version":"2"},"contract":{"extId":"Office","billingId":' + BILLING_ID + ',"status":"test"}}]';
    private static final String PACKAGE_INFO_QLI = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"DL","discount":{"type":"Percent","value":"3.48"},"price":"40"}';

    private static Quote queryQuote(String oppName) {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .selectField('Opportunity.isDiscountsSynced__c')
            .executeQuery()
        ).getFirst();
    }

    private static void setMock(Integer statusCode, String endpoint, String method, String response) {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo(endpoint, 'Completed', response, statusCode, method)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    }

    private static Opportunity buildOpportunityWithFlag(Boolean flag) {
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.isDiscountsSynced__c, flag)
            .build()
            .getRecord();
    }

    @TestSetup
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

        Triggers.switchOff();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => BILLING_ID,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, billingAcc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
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
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_QT,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.Credit_Amount__c => 42
            })
            .create()
            .getRecord();

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => PRODUCT_DIGITALLINE_UNLIMITED,
                Product2.ExtId__c => LC_DL_UNL_50,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Entitlement__c entDigitalLineUnlimited = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'ent name',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => entDigitalLineUnlimited.Id,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testConstructor() {
        final Id quoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner(quoteId, SWNStep.DISCOUNT_SYNC);
        Test.stopTest();

        Assert.isTrue(runner.sdc != null, 'Data Collector should be initialized');
        Assert.areEqual(SWNStep.DISCOUNT_SYNC, runner.sdc.action, 'Action should be Discount Sync');
        Assert.areEqual(quoteId, runner.sdc.quoteId, 'Quote Ids should be equal');
    }

    @isTest
    static void testRunSuccess() {
        Opportunity opp = buildOpportunityWithFlag(true);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.qt = new Quote();
        sdc.currentStep = SWNStep.buildDiscountStep();

        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            runner.sdc = sdc;
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }

    @isTest
    static void testRunError() {
        final String incorrectJSON = '[{"id":"123"}';

        setMock(200, '/discountTemplateGroup', HttpHelper.METHOD_GET, incorrectJSON);

        Opportunity opp = buildOpportunityWithFlag(false);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.packageId = PACKAGE_ID;
        BillingWrappers.NGBSAccount ngbsAcc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;
        ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> {pkg};
        sdc.ngbsAcc = ngbsAcc;
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.billingId = BILLING_ID;
        sdc.qt = new Quote();
        sdc.currentStep = SWNStep.buildDiscountStep();

        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            runner.sdc = sdc;
            runner.run();
        Test.stopTest();

        Assert.isFalse(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should not be completed');
    }

    @isTest
    static void testProcessDiscountsAlreadySynced() {
        Opportunity opp = buildOpportunityWithFlag(true);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);

        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            runner.sdc = sdc;
            Response discountResponse = runner.processDiscounts_new();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_INFO, discountResponse.status, 'Status should be Info');
        Assert.areEqual(SWNSyncDiscountRunner.DISCOUNTS_SYNCED_MSG, discountResponse.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNSyncDiscountRunner.DISCOUNTS_SYNCED_MSG_DETAILS, discountResponse.messages[0].messageDetails, 'Messages details should be equal');
    }

    @isTest
    static void testProcessDiscountsErrorOnGetDiscountGroups() {
        final String incorrectJSON = '[{"id":"123"}';

        setMock(200, '/discountTemplateGroup', HttpHelper.METHOD_GET, incorrectJSON);

        Opportunity opp = buildOpportunityWithFlag(false);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.packageId = PACKAGE_ID;
        BillingWrappers.NGBSAccount ngbsAcc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;
        ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> {pkg};
        sdc.ngbsAcc = ngbsAcc;
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.billingId = BILLING_ID;
        sdc.qt = new Quote();

        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            runner.sdc = sdc;
            Response discountResponse = runner.processDiscounts_new();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, discountResponse.status, 'Status should be Error');
    }

    @isTest
    static void testProcessDiscountsSuccess() {
        final String dtgResponse = '[{"id":72106001,"priority":"A","target":{"catalogId":"123","version":"2"},"discountTemplates":[{"id":86266001,"applicableTo":{"type":"CatalogId","id":"LC_DID_53"},'
            + '"applicationTerms":{"startDate":"2018-05-09T00:00Z[UTC]","endDate":"2020-05-09T00:00Z[UTC]"},"values":{"Monthly":{"unit":"Money","value":1E+1,'
            + '"recurringTerms":{"unit":"Months","value":1}}}}]}]';

        setMock(200, '/discountTemplateGroup', HttpHelper.METHOD_GET, dtgResponse);

        Opportunity opp = buildOpportunityWithFlag(false);

        Quote qt = queryQuote(OPP_NAME);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Discount_Number__c = 10;
        }

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.packageId = PACKAGE_ID;
        BillingWrappers.NGBSAccount ngbsAcc = new BillingWrappers.NGBSAccount();
        BillingWrappers.NGBSAccountPackage pkg = new BillingWrappers.NGBSAccountPackage();
        pkg.id = PACKAGE_ID;
        ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> {pkg};
        sdc.ngbsAcc = ngbsAcc;
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.billingId = BILLING_ID;
        sdc.qt = qt;
        sdc.billingContracts = new List<BillingWrappers.BillingContract>();

        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            runner.sdc = sdc;
            Response discountResponse = runner.processDiscounts_new();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, discountResponse.status, 'Status should be Success');
        Assert.areEqual(SWNMessageHelper.SYNC_DISCOUNT_HEADER, discountResponse.messages[0].message, 'Message should be Discounts Synced');
        Assert.areEqual(Label.Billing_success_message, discountResponse.messages[0].messageDetails, 'Message details should be Discounts Synced');
    }

    @isTest
    static void testApplyNewDiscountWithoutDiscount() {
        Quote qt = queryQuote(OPP_NAME);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Discount_Number__c = 0;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos = QuoteHelper.getPackageInfoList(qt);
        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Test.startTest();
            SWNMessageHelper.CompositeResult result = SWNSyncDiscountRunner.applyNewDiscounts(
                qt, pInfo, null, null, '111', new List<NGBS_Discount.DiscountTemplateGroup>(), new List<NGBS_Discount.DiscountTemplateGroup>()
            );
        Test.stopTest();

        Assert.areEqual(Response.STATUS_INFO, result.baseMessage.status, 'Status should be Info');
        Assert.areEqual(SWNMessageHelper.INFO_HEADER, result.baseMessage.header, 'There are should be info header');
        Assert.areEqual(SWNMessageHelper.NOTHING_TO_SYNC_MSG, result.baseMessage.message, 'There are should be no discounts for sync');
    }

    @isTest
    static void testApplyNewDiscountWithoutDiscountSimplifiedLBODownsell() {
        SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c = true;
        Quote qt = queryQuote(OPP_NAME);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Discount_Number__c = 0;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos = QuoteHelper.getPackageInfoList(qt);
        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Test.startTest();
            SWNMessageHelper.CompositeResult result = SWNSyncDiscountRunner.applyNewDiscounts(
                qt, pInfo, null, null, '111', new List<NGBS_Discount.DiscountTemplateGroup>(), new List<NGBS_Discount.DiscountTemplateGroup>()
            );
        Test.stopTest();

        Assert.areEqual(Response.STATUS_INFO, result.baseMessage.status, 'Status should be Info');
        Assert.areEqual(SWNMessageHelper.INFO_HEADER, result.baseMessage.header, 'There are should be info header');
        Assert.areEqual(SWNMessageHelper.NOTHING_TO_SYNC_MSG, result.baseMessage.message, 'There are should be no discounts for sync');
    }

    @isTest
    static void testApplyNewDiscountsWithDiscounts() {
        Quote qt = queryQuote(OPP_NAME);
        for (QuoteLineItem qli : qt.QuoteLineItems) {
            qli.Discount_Number__c = 50;
        }

        List<BillingWrappers.QuotePackageInfo> pInfos = QuoteHelper.getPackageInfoList(qt);
        BillingWrappers.QuotePackageInfo pInfo = pInfos[0];

        Test.startTest();
            SWNMessageHelper.CompositeResult result = SWNSyncDiscountRunner.applyNewDiscounts(
                qt, pInfo, null, null, '111', new List<NGBS_Discount.DiscountTemplateGroup>(), new List<NGBS_Discount.DiscountTemplateGroup>()
            );
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, result.baseMessage.status, 'Status should be Success');
        Assert.areEqual(SWNMessageHelper.SYNC_DISCOUNT_HEADER, result.baseMessage.header, 'Discounts should be synced');
        Assert.areEqual(Label.Billing_success_message, result.baseMessage.message, 'Discounts should be successfully applied sync');
    }

    @isTest
    static void testRemoveDiscountsWTPriorities() {
        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            SWNSyncDiscountRunner.removeDiscounts(new List<String>(), null, null);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, runner.res.status, 'Status should be Success');
    }

    @isTest
    static void testRemoveDiscountsError() {
        final String incorrectJSON = '[{"id":"123"}';
        setMock(200, '/discountTemplateGroup', HttpHelper.METHOD_GET, incorrectJSON);

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Id => (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getVAlue(),
                Account.Billing_Id__c => BILLING_ID
            })
            .build()
            .getRecord();

        Quote qt = new Quote();
        qt = (Quote) Test_Utils.putIntoUnwritableFields(
            qt,
            Quote.class,
            new Map<String, Object> {
                'Account' => billingAcc,
                'AccountId' => billingAcc.Id
            }
        );

        Test.startTest();
            try {
                SWNSyncDiscountRunner.removeDiscounts(new List<String> {'A'}, qt, 'test');
                Assert.fail('An exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains(SWNSyncDiscountRunner.SYNC_DISCOUNTS_ERROR), 'Error should be thrown upon applying discounts');
            }
        Test.stopTest();
    }

    @isTest
    static void testRemoveDiscountsSuccess() {
        final String dtgResponse = '[{"priority":"A"}]';
        setMock(200, '/discountTemplateGroup', HttpHelper.METHOD_GET, dtgResponse);

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Id => (Id) ValueProviderBuilder.provideDummyId(Account.sObjectType).getVAlue(),
                Account.Billing_Id__c => BILLING_ID
            })
            .build()
            .getRecord();

        Quote qt = new Quote();
        qt = (Quote) Test_Utils.putIntoUnwritableFields(
            qt,
            Quote.class,
            new Map<String, Object> {
                'Account' => billingAcc,
                'AccountId' => billingAcc.Id
            }
        );

        Test.startTest();
            SWNSyncDiscountRunner runner = new SWNSyncDiscountRunner();
            SWNSyncDiscountRunner.removeDiscounts(new List<String> {'A'}, qt, 'test');
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, runner.res.status, 'Status should be Success');
        Assert.isTrue(runner.res.messages.isEmpty(), 'There should be no errors');
    }

    @isTest
    static void testDeleteDiscountsWTChargeTerm() {
        final String discountId = '1234';
        setMock(200, '/discountTemplateGroup/' + discountId, HttpHelper.METHOD_DELETE, '');

        NGBS_Discount.DiscountTemplateGroup dtg = new NGBS_Discount.DiscountTemplateGroup();
        dtg.id = discountId;

        Test.startTest();
            SWNMessageHelper.CompositeResult result = SWNSyncDiscountRunner.deleteDiscounts_new(
                new List<NGBS_Discount.DiscountTemplateGroup> {dtg},
                'test',
                'test',
                null
            );
        Test.stopTest();

        Assert.isNotNull(result.baseMessage, 'Result should have created instance');
    }

    @isTest
    static void testDeleteDiscountsWithChargeTerm() {
        final String discountId = '1234';
        final String dtg = '[{"id":' + discountId + ',"discountTemplates":[]}]';
        List<NGBS_Discount.DiscountTemplateGroup> dGroups = (List<NGBS_Discount.DiscountTemplateGroup>) JSON.deserialize(dtg, List<NGBS_Discount.DiscountTemplateGroup>.class);

        Test.startTest();
            SWNMessageHelper.CompositeResult result = SWNSyncDiscountRunner.deleteDiscounts_new(
                dGroups,
                'test',
                'test',
                'test'
            );
        Test.stopTest();

        Assert.isNotNull(result.baseMessage, 'Result should have created instance');
    }

    @isTest
    static void testDeleteDiscountsError() {
        final String discountId = '1234';
        final String dtg = '[{"id":' + discountId + ',"discountTemplates":[{"values":{"test":{}}}]}]';
        setMock(
            204,
            '/discountTemplateGroup/' + discountId,
            HttpHelper.METHOD_DELETE,
            ''
        );

        List<NGBS_Discount.DiscountTemplateGroup> dGroups = (List<NGBS_Discount.DiscountTemplateGroup>) JSON.deserialize(dtg, List<NGBS_Discount.DiscountTemplateGroup>.class);

        Test.startTest();
            SWNMessageHelper.CompositeResult result = SWNSyncDiscountRunner.deleteDiscounts_new(
                dGroups,
                'test',
                'test',
                'test'
            );
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, result.baseMessage.status, 'Status should be Error');
        Assert.isTrue(result.baseMessage.header.contains(SWNSyncDiscountRunner.SYNC_DISCOUNTS_ERROR), 'Result should contain error message');
    }
}