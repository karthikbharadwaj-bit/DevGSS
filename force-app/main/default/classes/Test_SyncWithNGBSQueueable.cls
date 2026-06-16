@isTest
private class Test_SyncWithNGBSQueueable {
    private class Mock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));

            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';
            if (req.getEndpoint().endsWith('/summary?shortView=true') && req.getMethod() == HttpHelper.METHOD_GET) {
                body = NGBS_ACCOUNT_RESPONSE;
            } else if (req.getEndpoint().endsWith('contract') && req.getMethod() == HttpHelper.METHOD_GET) {
                body = CONTRACT_RESPONSE;
            } else if (req.getEndpoint().endsWith('/discountTemplateGroup')) {
                body = DISCOUNT_TEMPLATE_GROUP_RESPONSE;
            } else if (req.getEndpoint().endsWith(CHANGED_BILLING_ID) || req.getMethod() == HttpHelper.METHOD_PUT) {
                body = TestDataGenerator.TEST_PACKAGE_INFO;
            }
            return body;
        }
    }

    private static final String BILLING_ID = '1234';
    private static final String OPP_NAME = 'Test Opportunity';
    private static final String ENTITLEMENT_NAME = 'Test Entitlement';
    private static final String PACKAGE_ID = '9710001';
    private static final String PACKAGE_CATALOG_ID = '18';
    private static final String PACKAGE_VERSION = '1';
    private static final String PACKAGE_DURATION = Product2Helper.CHARGE_TERM_MONTHLY;
    private static final String CHANGED_BILLING_ID = '1239';
    private static final String PRODUCT_DIGITALLINE_UNLIMITED = 'DigitalLine Unlimited';
    private static final String PRODUCT_EXT_ID = 'LC_DL-UNL_50';
    private static final String BASE_ENDPOINT = 'http://test.com';
    private static final String MANAGER_PATH = '/test_manager';
    private static final String PACKAGE_CHANGED_CATALOG_ID = '15';
    private static final String PACKAGE_INFO =
        '[{"id":"18","version":"1","packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"' +
        PACKAGE_CATALOG_ID + '","version":"' + PACKAGE_VERSION + '"},"productName":"Office"' +
        ',"duration":"' + PACKAGE_DURATION + '","edition":{"id":1,"name":"Standard"},"contract":' +
        '{"id":"a8f0S0000008cxHQAQ","extId":"nib","billingId":' + CHANGED_BILLING_ID +
        '},"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":' +
        '"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":' +
        '"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
        '"override":false}],"discountTemplates":[{"id":123,"values":{}}]}]';

    private static String NGBS_ACCOUNT_RESPONSE = '{"id":"1","packages":[{"catalogId":"' + PACKAGE_CATALOG_ID + '",' +
        '"version":"' + PACKAGE_VERSION + '","offerType":"Regular","id":' + PACKAGE_ID + ',"licenses":[{"id":"3",' +
        '"qty":5,"catalogId": "' + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}]}';

    private static String CONTRACT_RESPONSE = '[{"id":42775001,"packages":[{"packageId":"555","description":"test description"}],"startBillingCycleNumber":0,"startDate":"2019-07-26",' +
        '"renewalDate":null,"term":12,"renewalTerm":12,"autoRenewal":true,"packageVersion":"1","licenses":' +
        '[{"id":25905001,"catalogId":"LC_DL-UNL_50","contractualQty":101},{"id":25906001,"catalogId":"LC_CRF_51","contractualQty":101}]}]';

    private static final String DISCOUNT_TEMPLATE_GROUP_RESPONSE = '[{"id":72106001,"packageId":' + PACKAGE_ID + ',"contractId":null,' +
        '"description":"a description","priority":"A","addedAt":"2019-01-23T12:37:37.990Z[UTC]","promoCode":null,"promoType":null,' +
        '"target":{"catalogId":"' + PACKAGE_CATALOG_ID + '","version":"' + PACKAGE_VERSION + '"},"discountTemplates":[{"id":86266001,"description":"a description",' +
        '"applicableTo":{"type":"CatalogId","id":"LC_WB_409"},"applicationTerms":{"startDate":"2018-05-09T00:00Z[UTC]",' +
        '"endDate":"2020-05-09T00:00Z[UTC]","maxLicenses":10000,"licenseScope":"All"},"values":{' +
        '"Monthly":{"unit":"Money","value":1E+1,"recurringTerms":{"unit":"Months","value":1}}}}],"visible":true}]';

    @testSetup
    static void createTestData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => BASE_ENDPOINT,
                NGBS_Settings__c.AccountManagerPath__c => MANAGER_PATH,
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
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
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.isICBProvisioningComplete__c => true,
                Opportunity.isSyncedToICB__c => true
            })
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper(PACKAGE_INFO);

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.PackageNameNew__c => 'Test',
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.Package_Info__c => qtPInfoWrapper.toString(),
                Quote.BillingPackage__c => pkg.Id,
                Quote.IsPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => PRODUCT_DIGITALLINE_UNLIMITED,
                Product2.ExtId__c => PRODUCT_EXT_ID,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        BillingWrappers.QLIPackageInfo qliPackageInfo = new BillingWrappers.QLIPackageInfo(TestDataGenerator.TEST_PACKAGE_INFO);
        qliPackageInfo.categoryPath = 'DL';
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

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ENTITLEMENT_NAME,
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 2,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageCatalogId__c => PACKAGE_CATALOG_ID,
                Entitlement__c.PackageVersion__c => PACKAGE_VERSION,
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.NewQuantity__c => 4,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.PackageInfo__c => JSON.serialize(qliPackageInfo),
                QuoteLineItem.Entitlement__c => ent.Id
            })
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testValidateAndProceedSyncQueueablePassed() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            SyncWithNGBSQueueable.enqueueAutoSyncWithNGBS(qt.Id);
        Test.stopTest();

        Assert.isTrue(String.isBlank(SyncWithNGBSQueueable.error), 'Validation should be passed');
    }

    @isTest
    static void testValidateAndProceedSyncQueueableFailed() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Quote qt = queryQuote(OPP_NAME);
        Opportunity opp = selectOpportunity(qt.OpportunityId);

        Test.startTest();
            opp.Brand_Name__c = RingCentralHelper.BRAND_VODAFONE;
            updateWithoutTriggers(new List<SObject> {opp});

            SyncWithNGBSQueueable.enqueueAutoSyncWithNGBS(qt.Id);
        Test.stopTest();

        SObjectSelector selector = new PlatformLogSelector();
        PlatformLog__c log = (PlatformLog__c) new ListOptional(new QueryFactory(selector)
                .selectFields(new List<SObjectField> {PlatformLog__c.Id, PlatformLog__c.Source__c})
                .executeQuery()
            ).getFirst();

        Assert.areEqual(log.Source__c, SyncWithNGBSQueueable.class.getName(), 'Log source should be equal');
        Assert.isTrue(String.isNotBlank(SyncWithNGBSQueueable.error), 'Validation should not be passed');
    }

    @isTest
    static void testValidateAndProceedSyncQueueableCommonException() {
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            SyncWithNGBSQueueable.enqueueAutoSyncWithNGBS(qt.Id);
        Test.stopTest();

        SObjectSelector selector = new PlatformLogSelector();
        PlatformLog__c log = (PlatformLog__c) new ListOptional(new QueryFactory(selector)
                .selectFields(new List<SObjectField> {PlatformLog__c.Id, PlatformLog__c.Source__c})
                .executeQuery()
            ).getFirst();

        Assert.areEqual(log.Source__c, SyncWithNGBSQueueable.class.getName(), 'Log source should be equal');
    }

    @isTest
    static void testCreateDealDeskCaseDescriptionAndProceedSyncPassed() {
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            System.enqueueJob(new SyncWithNGBSQueueable.CreateDealDeskCaseDescriptionAndProceedSyncQueueable(qt.Id));
        Test.stopTest();

        Assert.areEqual(SyncWithNGBSQueueable.res.status, Response.SEVERITY_SUCCESS, 'Response should be successful');
    }

    @isTest
    static void testSyncEntitlementsAndProceedSyncPassed() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            System.enqueueJob(new SyncWithNGBSQueueable.SyncEntitlementsAndProceedSyncQueueable(qt.Id));
        Test.stopTest();

        Assert.areEqual(SyncWithNGBSQueueable.res.status, Response.SEVERITY_SUCCESS, 'Response should be successful');
    }

    @isTest
    static void testSyncEntitlementsAndProceedSyncFailed() {
        Quote qt = queryQuote(OPP_NAME);

        QuoteLineItem qli = (QuoteLineItem) new ListOptional(new QuoteLineItemSelector()
                .selectQuoteLineItemsForSyncWithNGBS()
                .withoutSelectorFieldsIncluded()
                .selectField(QuoteLineItem.Entitlement__c)
                .executeQuery()
            ).getFirst();

        qli.Entitlement__c = null;
        updateWithoutTriggers(new List<SObject> {qli});

        Test.startTest();
            System.enqueueJob(new SyncWithNGBSQueueable.SyncEntitlementsAndProceedSyncQueueable(qt.Id));
        Test.stopTest();

        SObjectSelector selector = new PlatformLogSelector();
        PlatformLog__c log = (PlatformLog__c) new ListOptional(new QueryFactory(selector)
                .selectFields(new List<SObjectField> {PlatformLog__c.Id, PlatformLog__c.Source__c})
                .executeQuery()
            ).getFirst();

        Assert.areEqual(log.Source__c, SyncWithNGBSQueueable.class.getName(), 'Log source should be equal');
        Assert.isTrue(ChatterHelper.lastFeedItemInput != null, 'Post to chatter should be made');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.toString().contains(SyncWithNGBSQueueable.ERROR_UPON_SYNCING_ENTITLEMENTS), 'Message should contain the same error message');
        Assert.areEqual(SyncWithNGBSQueueable.res.status, Response.SEVERITY_ERROR, 'Log source should be equal');
    }

    @isTest
    static void testInitializeSyncScenarioError() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Test.startTest();
            SyncWithNGBSQueueable.initializeSyncScenario(null, new List<String>());
        Test.stopTest();

        SObjectSelector selector = new PlatformLogSelector();
        PlatformLog__c log = (PlatformLog__c) new ListOptional(new QueryFactory(selector)
                .selectFields(new List<SObjectField> {PlatformLog__c.Id, PlatformLog__c.Source__c})
                .executeQuery()
            ).getFirst();

        Assert.areEqual(log.Source__c, SyncWithNGBSQueueable.class.getName(), 'Log source should be equal to class name');
    }

    @isTest
    static void testSyncWithNGBSQueueablePassed() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            System.enqueueJob(new SyncWithNGBSQueueable(qt.Id, new List<String>()));
        Test.stopTest();

        Opportunity testOpp = selectOpportunity(qt.OpportunityId);

        Assert.areEqual(SyncWithNGBSQueueable.res.status, Response.SEVERITY_SUCCESS, 'Response should be successful');
        Assert.isTrue(testOpp.isFSCSynced__c, 'FSC sync step should be completed');
    }

    @isTest
    static void testSyncWithNGBSQueueableFailed() {
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            System.enqueueJob(new SyncWithNGBSQueueable(qt.Id, new List<String>()));
        Test.stopTest();

        SObjectSelector selector = new PlatformLogSelector();
        PlatformLog__c log = (PlatformLog__c) new ListOptional(new QueryFactory(selector)
                .selectFields(new List<SObjectField> {PlatformLog__c.Id, PlatformLog__c.Source__c})
                .executeQuery()
            ).getFirst();

        Assert.isNotNull(log, 'Platform log should exist');
    }

    @isTest
    static void testEnqueueNextContractSyncStep() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        SyncWithNGBSQueueable.notSyncedStepNames = new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC};
        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO
            .replace(CHANGED_BILLING_ID, 'null')
            .replace(PACKAGE_CATALOG_ID, PACKAGE_CHANGED_CATALOG_ID);
        qt.Initial_Term_months__c = '12';
        qt.Term_months__c = '12';
        qt.Start_Date__c = Date.today();
        qt.Credit_Amount__c = 42;
        updateWithoutTriggers(new List<SObject> {qt});

        Test.startTest();
            SyncWithNGBSQueueable.enqueueNextStep(qt.Id);
        Test.stopTest();

        Opportunity testOpp = selectOpportunity(qt.OpportunityId);

        Assert.isTrue(testOpp.isContractsSynced__c, 'Contracts should be synced');
    }

    @isTest
    static void testEnqueueNextDownsellStep() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        SyncWithNGBSQueueable.notSyncedStepNames = new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DOWN_SELL};

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncWithNGBS()
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<SObjectField> {QuoteLineItem.NewQuantity__c, QuoteLineItem.Zero_Quantity__c})
            .executeQuery();

        for (QuoteLineItem qli : qlis) {
            qli.NewQuantity__c = 2;
            qli.Zero_Quantity__c = false;
        }
        updateWithoutTriggers(qlis);

        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            SyncWithNGBSQueueable.enqueueNextStep(qt.Id);
        Test.stopTest();

        Opportunity testOpp = selectOpportunity(qt.OpportunityId);

        Assert.isTrue(testOpp.isDownsellStepCompleted__c, 'Downsell step should be synced');
    }

    @isTest
    static void testEnqueueNextStepError() {
        SyncWithNGBSQueueable.notSyncedStepNames = new List<String>();
        SyncWithNGBSQueueable.res.error();
        Quote qt = queryQuote(OPP_NAME);

        Test.startTest();
            SyncWithNGBSQueueable.enqueueNextStep(qt.Id);
        Test.stopTest();

        SObjectSelector selector = new PlatformLogSelector();
        PlatformLog__c log = (PlatformLog__c) new ListOptional(new QueryFactory(selector)
                .selectFields(new List<SObjectField> {PlatformLog__c.Id, PlatformLog__c.Source__c})
                .executeQuery()
            ).getFirst();

        Assert.areEqual(log.Source__c, SyncWithNGBSQueueable.class.getName(), 'Log source should be equal to class name');
    }

    @isTest
    static void testGetNotSyncedStepNames() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Quote qt = queryQuote(OPP_NAME);
        Opportunity opp = selectOpportunity(qt.OpportunityId);
        opp.isDiscountsSynced__c = true;
        updateWithoutTriggers(new List<SObject> {opp});

        Test.startTest();
            SyncWithNGBSQueueable.getNotSyncedStepNames(qt.Id, new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC});
        Test.stopTest();

        Assert.areEqual(SyncWithNGBSQueueable.notSyncedStepNames.size(), 1, 'Not synced step names should be 1');
        Assert.isTrue(SyncWithNGBSQueueable.notSyncedStepNames.contains(SWNStep.CONTRACT_SYNC), 'Not synced step names should contain CONTRACT_SYNC');
    }

    private static Quote queryQuote(String oppName) {
        return (Quote) new ListOptional(new QuoteSelector()
                .selectQuoteForSyncWithNGBSByName(oppName)
                .executeQuery()
            ).getFirst();
    }

    private static void updateWithoutTriggers(List<SObject> sobjectsToUpdate) {
        Triggers.switchOff();
        update sobjectsToUpdate;
        Triggers.switchOn();
    }

    private static Account queryAccount() {
        return (Account) new ListOptional(new AccountSelector()
                .selectAccounts()
                .executeQuery()
            ).getFirst();
    }

    private static Opportunity selectOpportunity(Id oppId) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
                .selectOpportunityForSyncWithNGBS(oppId)
                .withoutSelectorFieldsIncluded()
                .selectFields(new List<SObjectField> {
                    Opportunity.isUpsellStepCompleted__c,
                    Opportunity.isContractsSynced__c,
                    Opportunity.isDiscountsSynced__c,
                    Opportunity.isDownsellStepCompleted__c
                })
                .executeQuery()
            ).getFirst();
    }
}