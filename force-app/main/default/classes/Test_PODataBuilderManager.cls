@IsTest
class Test_PODataBuilderManager {
    static final String OPP_NAME = 'Opp name';
    static final String QUOTE_WITH_OPP = 'Quote with Opportunity';
    static final String QUOTE_WITHOUT_OPP = 'Quote without Opportunity';
    static final String TECH_QUOTE = 'Tech Quote';
    static final String PRIMARY_QUOTE = 'Primary Quote';
    static final String POC_QUOTE = 'POC Quote';
    static final String OTHER_QUOTE = 'Other Quote';
    static final String CC_QUOTE = 'CC Quote';
    static final String SUB_BRAND = 'SubBrandTest';
    static final String PACKAGE_INFO_FOR_BILLING = '[{"id":"18","version":"1","packageInfo":{"id":9710001,"catalogId":"18","version":"1"},"productName":"Office"}]';

    class TestPODataBuilderManager extends PODataBuilderManager {
        public TestPODataBuilderManager() {
            super();
        }
        public TestPODataBuilderManager(PODataCollector.QuoteBasedDC dc, Opportunity opp) {
            super(dc, opp);
        }
        public TestPODataBuilderManager(PODataCollector.OrderBasedDC dc) {
            super(dc);
        }

        public override List<QuoteLineItem> getTargetQuoteLineItems(List<QuoteLineItem> qlis) {
            return qlis;
        }
    }

    static TestPODataBuilderManager generateManagerForQli() {
        String shippingDeviceInfo = NGBSTestDataGenerator.generateQLIPackageInfo(new Map<String, Object> {
            'Id' => '23',
            'Duration' => 'Monthly',
            'CategoryCode' => 'HD',
            'CategoryPath' => 'HD'
        });

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Name => PRIMARY_QUOTE,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .build()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.PackageInfo__c => new ValueProvider.ListProvider(
                    new List<String> { shippingDeviceInfo, NGBSTestDataGenerator.generateQLIPackageInfo() }
                ),
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Id => ValueProviderBuilder.provideDummyId(QuoteLineItem.SObjectType),
                QuoteLineItem.Quantity => 1
            })
            .quantity(2)
            .build()
            .getRecords();

        Map<String, Object> queryResultMap = new Map<String, Object> {
            'totalSize' => qlis.size(),
            'done' => true,
            'records' => qlis
        };

        Map<String, Object> qtMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(qt));
        qtMap.put('QuoteLineItems', queryResultMap);
        qtMap.put('Account', new Account());

        qt = (Quote) JSON.deserialize(JSON.serialize(qtMap), Quote.class);

        List<Area_Code_Line_Item__c> areaCodeList = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Id => ValueProviderBuilder.provideDummyId(Area_Code_Line_Item__c.SObjectType),
                Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<Id> { qlis[0].Id, qlis[1].Id }
                ),
                Area_Code_Line_Item__c.Quantity__c => 1
            })
            .quantity(2)
            .build()
            .getRecords();

        List<Object> areaCodeListObj = (List<Object>) JSON.deserializeUntyped(JSON.serialize(areaCodeList));
        for (Integer i = 0; i < areaCodeListObj.size(); i++) {
            Map<String, Object> areaCodeMap = (Map<String, Object>) areaCodeListObj[i];
            areaCodeMap.put('Quote_Line_Item__r', qlis[i]);
        }
        areaCodeList = (List<Area_Code_Line_Item__c>) JSON.deserialize(JSON.serialize(areaCodeListObj), List<Area_Code_Line_Item__c>.class);

        List<AssignmentLineItem__c> assignmentsList = (List<AssignmentLineItem__c>) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Id => ValueProviderBuilder.provideDummyId(AssignmentLineItem__c.SObjectType),
                AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideList(
                    new List<Id> { qlis[0].Id, qlis[1].Id }
                ),
                AssignmentLineItem__c.Quantity__c => 1
            })
            .quantity(2)
            .build()
            .getRecords();

        List<Object> assignmentsListObj = (List<Object>) JSON.deserializeUntyped(JSON.serialize(assignmentsList));
        for (Integer i = 0; i < assignmentsListObj.size(); i++) {
            Map<String, Object> assignmentMap = (Map<String, Object>) assignmentsListObj[i];
            assignmentMap.put('Child__r', qlis[i]);
            assignmentMap.put('Parent__r', qlis[i]);
        }
        assignmentsList = (List<AssignmentLineItem__c>) JSON.deserialize(JSON.serialize(assignmentsListObj), List<AssignmentLineItem__c>.class);

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.aclis = areaCodeList;
        dc.alis = assignmentsList;
        dc.qlisWithCustomAddressAssignments = qlis;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager();
        testManager.dc = dc;
        testManager.targetQuote = qt;
        testManager.optyQuotes = new List<Quote>();

        return testManager;
    }

    static User getUserWithShippingPermission() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .create()
            .getRecord();

        SetupEntityAccess sea = (SetupEntityAccess) new ListOptional(new SetupEntityAccessSelector()
            .selectSetupEntityAccessByCustomPermissionName(new List<Object> {
                CustomPermissionHelper.PERMISSION_SKIP_SHIPPING_VALIDATION
            })
            .executeQuery()
        ).getFirst();

        new SObjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PermissionSetAssignment.AssigneeId => testUser.Id,
                PermissionSetAssignment.PermissionSetId => sea.ParentId
            })
            .create();

        return testUser;
    }

    @TestSetup
    static void makeData() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Shipping_Tab_New_Business__c => true,
                Feature_Toggle__c.SelectPackagesByBusinessIdentity__c => false
            })
            .create();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();
    }

    @IsTest
    static void testOptyQuotesGetter() {
        Id oppId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType).getValue();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => new ValueProvider.ListProvider(
                    new List<String> { oppId, oppId, null }
                ),
                Quote.Name => new ValueProvider.ListProvider(
                    new List<String> { QUOTE_WITH_OPP, QUOTE_WITH_OPP, QUOTE_WITHOUT_OPP }
                )
            })
            .quantity(3)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id> { oppId });
        dc.quotes = quotes;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager();
        testManager.dc = dc;
        testManager.opp = new Opportunity(Id = oppId);

        Test.startTest();
            List<Quote> result = testManager.optyQuotes;
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Should return only quotes related to the opportunity');
        for (Quote qt : result) {
            Assert.areEqual(oppId, qt.OpportunityId, 'Should return only quotes related to the opportunity');
            Assert.areNotEqual(QUOTE_WITHOUT_OPP, qt.Name, 'Should return only quotes related to the opportunity');
        }

        List<Quote> cachedResult = testManager.optyQuotes;
        Assert.areEqual(result, cachedResult, 'Should return the same instance on subsequent calls');
    }

    @IsTest
    static void testTargetQuoteGetter() {
        Id oppId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType).getValue();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => oppId,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Name => new ValueProvider.ListProvider(
                    new List<String> { POC_QUOTE, TECH_QUOTE, PRIMARY_QUOTE, OTHER_QUOTE }
                ),
                Quote.RecordTypeId => new ValueProvider.ListProvider(
                    new List<String> {
                        QuoteHelper.RT_ID_POC,
                        QuoteHelper.RT_ID_BILLING,
                        QuoteHelper.RT_ID_BILLING,
                        QuoteHelper.RT_ID_BILLING
                    }
                ),
                Quote.isPrimary__c => new ValueProvider.ListProvider(
                    new List<Boolean> { true, false, true, false }
                ),
                Quote.IsMultiProductTechnicalQuote__c => new ValueProvider.ListProvider(
                    new List<Boolean> { false, true, false, false }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id> { oppId });
        dc.quotes = quotes;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager();
        testManager.dc = dc;
        testManager.opp = new Opportunity(Id = oppId);

        Test.startTest();
            Quote result = testManager.targetQuote;

            Assert.isNotNull(result, 'Target quote should not be null');
            Assert.areEqual(POC_QUOTE, result.Name, 'Should return the poc quote as target');

            Quote cachedResult = testManager.targetQuote;
            Assert.areEqual(result, cachedResult, 'Should return the same instance on subsequent calls');

            testManager.dc.quotes.remove(0);
            testManager.targetQuote = null;
            result = testManager.targetQuote;
            Assert.areEqual(TECH_QUOTE, result.Name, 'Should return tech quote');

            testManager.dc.quotes.remove(0);
            testManager.targetQuote = null;
            result = testManager.targetQuote;
            Assert.areEqual(PRIMARY_QUOTE, result.Name, 'Should return primary quote');
        Test.stopTest();
    }

    @IsTest
    static void testTargetQuoteLineItemsGetter() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        Test.startTest();
            List<QuoteLineItem> result;
            System.runAs(getUserWithShippingPermission()) {
                result = testManager.targetQuoteLineItems;
                Assert.areEqual(1, result.size(), '1 quote line item should be filtered');

                BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                    JSON.deserialize(result[0].PackageInfo__c, BillingWrappers.QLIPackageInfo.class);

                Assert.areNotEqual('HD', qliPackageInfo.categoryCode, 'Shipping qli should be filtered');
            }

            testManager.targetQuote = null;
            result = testManager.targetQuoteLineItems;
            Assert.areEqual(1, result.size(), 'Result should be cached');

            testManager.targetQuoteLineItems = null;
            result = testManager.targetQuoteLineItems;
            Assert.isTrue(result.isEmpty(), 'Empty list should be returned');
        Test.stopTest();
    }

    @IsTest
    static void testAreaCodeLineItemListGetter() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        List<QuoteLineItem> qlis = testManager.dc.qlisWithCustomAddressAssignments;
        testManager.targetQuoteLineItems = qlis;

        Test.startTest();
            List<Area_Code_Line_Item__c> result;
            System.runAs(getUserWithShippingPermission()) {
                result = testManager.areaCodeLineItemList;
                Assert.areEqual(1, result.size(), '1 area code line item should be filtered');
                Assert.areEqual(qlis[1].Id, result[0].Quote_Line_Item__c, 'Shipping area code line item should be filtered');
            }

            testManager.targetQuote = null;
            result = testManager.areaCodeLineItemList;
            Assert.areEqual(1, result.size(), 'Result should be cached');

            testManager.areaCodeLineItemList = null;
            result = testManager.areaCodeLineItemList;
            Assert.isTrue(result.isEmpty(), 'Empty list should be returned');
        Test.stopTest();
    }

    @IsTest
    static void testAssignmentLineItemListGetter() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        List<QuoteLineItem> qlis = testManager.dc.qlisWithCustomAddressAssignments;
        testManager.targetQuoteLineItems = qlis;

        Test.startTest();
            List<AssignmentLineItem__c> result;
            System.runAs(getUserWithShippingPermission()) {
                result = testManager.assignmentLineItemList;
                Assert.areEqual(1, result.size(), '1 assignment line item should be filtered');
                Assert.areEqual(qlis[1].Id, result[0].Child__c, 'Shipping assignment line item should be filtered');
            }

            testManager.targetQuote = null;
            result = testManager.assignmentLineItemList;
            Assert.areEqual(1, result.size(), 'Result should be cached');

            testManager.assignmentLineItemList = null;
            result = testManager.assignmentLineItemList;
            Assert.isTrue(result.isEmpty(), 'Empty list should be returned');
    }

    @IsTest
    static void testProservQuoteGetter() {
        Id oppId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType).getValue();

        Pricebook2 pb = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setField(Pricebook2.AllowedRecordType__c, QuoteHelper.ALLOWED_RT_NAME_BILLING_PROSERV)
            .build()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.OpportunityId => oppId,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<Id> { QuoteHelper.RT_ID_SALES, QuoteHelper.RT_ID_PROSERV }
                ),
                Quote.Name => QUOTE_WITH_OPP
            })
            .quantity(2)
            .build()
            .getRecords();

        List<Object> quotesListObj = (List<Object>) JSON.deserializeUntyped(JSON.serialize(quotes));
        for (Integer i = 0; i < quotesListObj.size(); i++) {
            Map<String, Object> quoteMap = (Map<String, Object>) quotesListObj[i];
            quoteMap.put('Pricebook2', pb);
        }
        quotes = (List<Quote>) JSON.deserialize(JSON.serialize(quotesListObj), List<Quote>.class);

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id> { oppId });
        dc.quotes = quotes;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager();
        testManager.dc = dc;
        testManager.opp = new Opportunity(Id = oppId);

        Test.startTest();
            Quote result = testManager.proservQuote;

            Assert.isNotNull(result, 'Proserv quote should be returned');
            Assert.areEqual(QuoteHelper.RT_ID_PROSERV, result.RecordTypeId, 'Correct proserv quote should be returned');

            dc.quotes = new List<Quote>();
            testManager.optyQuotes = new List<Quote>();
            Assert.areEqual(result, testManager.proservQuote, 'Quote should be cached');
        Test.stopTest();
    }

    @IsTest
    static void testCCProservQuoteGetter() {
        Id oppId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType).getValue();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.OpportunityId => oppId,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<Id> { QuoteHelper.RT_ID_SALES, QuoteHelper.RT_ID_CC_PROSERV }
                ),
                Quote.Name => QUOTE_WITH_OPP
            })
            .quantity(2)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id> { oppId });
        dc.quotes = quotes;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager();
        testManager.dc = dc;
        testManager.opp = new Opportunity(Id = oppId);

        Test.startTest();
            Quote result = testManager.ccProServQuote;

            Assert.isNotNull(result, 'CC proserv quote should be returned');
            Assert.areEqual(QuoteHelper.RT_ID_CC_PROSERV, result.RecordTypeId, 'Correct cc proserv quote should be returned');

            dc.quotes = new List<Quote>();
            testManager.optyQuotes = new List<Quote>();
            Assert.areEqual(result, testManager.ccProServQuote, 'Quote should be cached');
        Test.stopTest();
    }

    @IsTest
    static void testGetTargetQuote() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, new ValueProvider.ListProvider(
                new List<String> { TECH_QUOTE, PRIMARY_QUOTE, POC_QUOTE }
            ))
            .quantity(3)
            .build()
            .getRecords();

        Quote techQuote = quotes[0];
        Quote primaryQuote = quotes[1];
        Quote pocQuote = quotes[2];

        Test.startTest();
            TestPODataBuilderManager testManager = new TestPODataBuilderManager();
            Quote result = testManager.getTargetQuote(techQuote, primaryQuote, pocQuote);
            Assert.areEqual(techQuote.Name, result.Name, 'Tech quote should be returned');

            result = testManager.getTargetQuote(null, primaryQuote, pocQuote);
            Assert.areEqual(primaryQuote.Name, result.Name, 'Primary quote should be returned');

            result = testManager.getTargetQuote(null, null, pocQuote);
            Assert.areEqual(pocQuote.Name, result.Name, 'POC quote should be returned');

        Test.stopTest();
    }

    @IsTest
    static void testQuoteDataBuilder() {
        Id oppId = (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType).getValue();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => oppId,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoRCCC(),
                Quote.Name => new ValueProvider.ListProvider(
                    new List<String> { POC_QUOTE, TECH_QUOTE, PRIMARY_QUOTE, OTHER_QUOTE, CC_QUOTE }
                ),
                Quote.RecordTypeId => new ValueProvider.ListProvider(
                    new List<String> {
                        QuoteHelper.RT_ID_POC,
                        QuoteHelper.RT_ID_BILLING,
                        QuoteHelper.RT_ID_BILLING,
                        QuoteHelper.RT_ID_PROSERV,
                        QuoteHelper.RT_ID_CC
                    }
                ),
                Quote.isPrimary__c => new ValueProvider.ListProvider(
                    new List<Boolean> { true, false, true, false, false }
                ),
                Quote.IsMultiProductTechnicalQuote__c => new ValueProvider.ListProvider(
                    new List<Boolean> { false, true, false, false, false }
                )
            })
            .quantity(5)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id> { oppId });
        dc.quotes = quotes;

        Quote pocQuote = quotes[0];
        Quote techQuote = quotes[1];
        Quote primaryQuote = quotes[2];
        Quote proservQuote = quotes[3];
        Quote ccQuote = quotes[4];

        TestPODataBuilderManager testManager = new TestPODataBuilderManager();
        testManager.dc = dc;
        testManager.opp = new Opportunity(Id = oppId);
        testManager.proservQuote = proservQuote;

        Test.startTest();
            PODataBuilderManager.QuoteDataBuilder builder = new PODataBuilderManager.QuoteDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Assert.areEqual(techQuote.Name, ((Quote) response.getData(builder.TARGET_QUOTE)).Name, 'Target quote should match');
        Assert.areEqual(primaryQuote.Name, ((Quote) response.getData(builder.PRIMARY_QUOTE)).Name, 'Primary quote should match');
        Assert.areEqual(ccQuote.Name, ((Quote) response.getData(builder.CC_QUOTE)).Name, 'CC quote should match');
        Assert.areEqual(pocQuote.Name, ((Quote) response.getData(builder.POC_QUOTE)).Name, 'POC quote should match');
        Assert.areEqual(proservQuote.Name, ((Quote) response.getData(builder.PS_QUOTE)).Name, 'Proserv quote should match');
        Assert.isTrue((Boolean) response.getData(builder.IS_PROSERV_QUOTE_NOT_CANCELLED), 'Proserv quotes should not be cancelled');
    }

    @IsTest
    static void testQuoteDataBuilderIsProServQuotesNotCancelled() {
        PODataBuilderManager.QuoteDataBuilder builder = new PODataBuilderManager.QuoteDataBuilder();
        Quote testQuote;
        Test.startTest();
            Boolean result = builder.isProServQuotesNotCancelled(testQuote);
            Assert.isFalse(result, 'Result should be false when quote is not defined');

            testQuote = new Quote();
            result = builder.isProServQuotesNotCancelled(testQuote);
            Assert.isTrue(result, 'Result should be true when status is not cancelled');

            testQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            result = builder.isProServQuotesNotCancelled(testQuote);
            Assert.isFalse(result, 'Result should be false when status is cancelled');
        Test.stopTest();
    }

    @IsTest
    static void testOpportunityDataBuilder() {
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(
            new PODataCollector.QuoteBasedDC(new Set<Id>()),
            new Opportunity(Name = OPP_NAME)
        );

        Test.startTest();
            PODataBuilderManager.OpportunityDataBuilder builder = new PODataBuilderManager.OpportunityDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Assert.areEqual(OPP_NAME, ((Opportunity) response.getData(builder.OPPORTUNITY)).Name, 'Oppty should match');
    }

    @IsTest
    static void testUserDataBuilder() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Id, ValueProviderBuilder.provideDummyId(User.SObjectType))
            .build()
            .getRecord();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.usr = testUser;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());

        Test.startTest();
            PODataBuilderManager.UserDataBuilder builder = new PODataBuilderManager.UserDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Assert.areEqual(testUser.Id, ((User) response.getData(builder.USER)).Id, 'User data should match');
    }

    @IsTest
    static void testPromotionDataBuilder() {
        Id qtId = (Id) ValueProviderBuilder.provideDummyId(Quote.SObjectType).getValue();
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());

        dc.promotions = (List<Promotion__c>) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Promotion__c.Quote__c => ValueProviderBuilder.provideList(new List<Id> {
                    qtId, null, qtId, null
                })
            })
            .quantity(4)
            .build()
            .getRecords();

        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());
        testManager.targetQuote = new Quote(Id = qtId);

        Test.startTest();
            PODataBuilderManager.PromotionDataBuilder builder = new PODataBuilderManager.PromotionDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Assert.areEqual(2, ((List<Promotion__c>) response.getData(builder.PROMOTIONS)).size(), 'Promotions data should match');
    }

    @IsTest
    static void testApprovalDataBuilder() {
        List<Approval__c> approvals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .quantity(2)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.approvals = approvals;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());

        Test.startTest();
            PODataBuilderManager.ApprovalDataBuilder builder = new PODataBuilderManager.ApprovalDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Assert.areEqual(
            approvals.size(),
            ((List<Approval__c>) response.getData(builder.APPROVALS)).size(),
            'Approvals data should match'
        );
    }

    @IsTest
    static void testAccountDataBuilder() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.SObjectType);
        Id masterAccId = (Id) dummyIdProvider.getValue();
        Id accId = (Id) dummyIdProvider.getValue();

        Account masterAcc = new Account(Id = masterAccId);
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Billing_ID__c => '123',
                Account.RC_User_ID__c => '123',
                Account.Payment_Method__c => AccountHelper.PAYMENT_METHOD_INVOICE,
                Account.Master_Account__c => masterAcc.Id,
                Account.Id => accId
            })
            .build()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Id => ValueProviderBuilder.provideDummyId(Opportunity.SObjectType),
                Opportunity.Sub_Brand__c => SUB_BRAND,
                Opportunity.AccountId => acc.Id
            })
            .build()
            .getRecord();

        Map<String, Object> oppRecordMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(opp));
        oppRecordMap.put('Account', acc);
        opp = (Opportunity) JSON.deserialize(JSON.serialize(oppRecordMap), Opportunity.class);

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Package_Info__c => PACKAGE_INFO_FOR_BILLING
            })
            .build()
            .getRecord();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.accountMap = new Map<Id, Account>(new List<Account> { masterAcc, acc});

        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, opp);
        testManager.optyQuotes = new List<Quote>();
        testManager.targetQuote = qt;

        Test.startTest();
            PODataBuilderManager.AccountDataBuilder builder = new PODataBuilderManager.AccountDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        String pMethod = (String) response.getData(builder.PAYMENT_METHOD);
        String ngbsAccStatus = (String) response.getData(builder.NGBS_ACCOUNT_STATUS);
        String uiBrandId = (String) response.getData(builder.UBRAND_ID);
        Account resultMasterAcc = (Account) response.getData(builder.MASTER_ACC);
        List<Account> accs = (List<Account>) response.getData(builder.BOUND_ACCS);

        Assert.areEqual(AccountHelper.PAYMENT_METHOD_INVOICE, pMethod, 'Payment method should match');
        Assert.areEqual('active', ngbsAccStatus, 'NGBS Account Status should match');
        Assert.areEqual(SUB_BRAND, uiBrandId, 'UI Brand ID should match');
        Assert.areEqual(masterAccId, resultMasterAcc.Id, 'Master Account ID should match');
        Assert.areEqual(2, accs.size(), 'All accounts should be treated as bound accounts');
    }

    @IsTest
    static void testAccountRelationDataBuilder() {
        IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(Account.SObjectType);
        Id masterAccId = (Id) dummyIdProvider.getValue();
        Id accId = (Id) dummyIdProvider.getValue();

        List<AccountRelation__c> testAccountRelations = (List<AccountRelation__c>) new SObjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountRelation__c.Child_Account__c => ValueProviderBuilder.provideList(new List<Id> {
                    masterAccId,
                    accId
                })
            })
            .quantity(2)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.accountsRelation = testAccountRelations;

        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity(AccountId = masterAccId));

        Test.startTest();
            PODataBuilderManager.AccountRelationDataBuilder builder = new PODataBuilderManager.AccountRelationDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        List<AccountRelation__c> result = (List<AccountRelation__c>) response.getData(builder.ACC_RELATIONS);
        Assert.areEqual(1, result.size(), 'Promotions data should match');
        Assert.areEqual(masterAccId, result[0].Child_Account__c, 'Promotions data should match');
    }

    @IsTest
    static void testContactDataBuilder() {
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.Id, ValueProviderBuilder.provideDummyId(Contact.SObjectType))
            .build()
            .getRecord();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.contact = testContact;
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());

        Test.startTest();
            PODataBuilderManager.ContactDataBuilder builder = new PODataBuilderManager.ContactDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        Contact responseContact = (Contact) response.getData(builder.CONTACT);
        Assert.areEqual(testContact.Id, responseContact.Id, 'Contact Id should match');
    }

    @IsTest
    static void testAreaCodeLineItemDataBuilder() {
        List<Area_Code_Line_Item__c> areaCodeLineItems = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setField(Area_Code_Line_Item__c.Id, ValueProviderBuilder.provideDummyId(Area_Code_Line_Item__c.SObjectType))
            .quantity(2)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());
        testManager.areaCodeLineItemList = areaCodeLineItems;

        Test.startTest();
            PODataBuilderManager.AreaCodeLineItemDataBuilder builder = new PODataBuilderManager.AreaCodeLineItemDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        List<Area_Code_Line_Item__c> result = (List<Area_Code_Line_Item__c>) response.getData(builder.AREA_CODE_LINE_ITEMS);

        Assert.areEqual(areaCodeLineItems.size(), result.size(), 'Area Code Line Items data size should match');
        for (Integer i = 0; i < areaCodeLineItems.size(); i++) {
            Assert.areEqual(areaCodeLineItems[i].Id, result[i].Id, 'Area Code Line Item Id should match');
        }
    }

    @IsTest
    static void testAssignmentLineItemDataBuilder() {
        List<AssignmentLineItem__c> assignmentLineItems = (List<AssignmentLineItem__c>) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .setField(AssignmentLineItem__c.Id, ValueProviderBuilder.provideDummyId(AssignmentLineItem__c.SObjectType))
            .quantity(2)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());
        testmanager.assignmentLineItemList = assignmentLineItems;

        Test.startTest();
            PODataBuilderManager.AssignmentLineItemDataBuilder builder = new PODataBuilderManager.AssignmentLineItemDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        List<AssignmentLineItem__c> result = (List<AssignmentLineItem__c>) response.getData(builder.ASSIGNMENT_LINE_ITEM);

        Assert.areEqual(assignmentLineItems.size(), result.size(), 'Assignment Line Items data size should match');
        for (Integer i = 0; i < assignmentLineItems.size(); i++) {
            Assert.areEqual(assignmentLineItems[i].Id, result[i].Id, 'Assignment Line Item Id should match');
        }
    }

    @IsTest
    static void testAreaCodeDataBuilder() {
        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setField(Area_Codes__c.Id, ValueProviderBuilder.provideDummyId(Area_Codes__c.SObjectType))
            .quantity(4)
            .build()
            .getRecords();

        List<Area_Code_Line_Item__c> areaCodeLineItems = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Id => ValueProviderBuilder.provideDummyId(Area_Code_Line_Item__c.SObjectType),
                Area_Code_Line_Item__c.Area_Code__c => new ValueProvider.ListProvider(new List<Id> { areaCodes[0].Id, areaCodes[1].Id })
            })
            .quantity(2)
            .build()
            .getRecords();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => true,
                Quote.AreaCode__c => areaCodes[2].Id
            })
            .build()
            .getRecord();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.areaCodes = areaCodes;
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());
        testmanager.areaCodeLineItemList = areaCodeLineItems;
        testmanager.targetQuote = qt;
        testmanager.optyQuotes = new List<Quote>();

        Test.startTest();
            PODataBuilderManager.AreaCodeDataBuilder builder = new PODataBuilderManager.AreaCodeDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        List<Area_Codes__c> result = (List<Area_Codes__c>) response.getData(builder.AREA_CODE);

        Assert.areEqual(3, result.size(), 'Area codes data should match');

        for (Area_Codes__c ac : result) {
            Assert.areNotEqual(areaCodes[3].Id, ac.Id, 'Area code should be filtered');
        }
    }

    @IsTest
    static void testAssignmentDataBuilder() {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Id => ValueProviderBuilder.provideDummyId(QuoteLineItem.SObjectType),
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                QuoteLineItem.Package_Info_QLI__c => NGBSTestDataGenerator.generateQLIPackageInfo()
            })
            .build()
            .getRecords();


        List<Area_Codes__c> acList = (List<Area_Codes__c>) new SObjectBuilder(Area_Codes__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Id => ValueProviderBuilder.provideDummyId(Area_Codes__c.SObjectType),
                Area_Codes__c.Area_Code__c => ValueProviderBuilder.provideList(new List<Decimal> { 800, 833, 866 }),
                Area_Codes__c.City__c => 'New York',
                Area_Codes__c.Country__c => 'United States'
            })
            .build()
            .getRecords();

        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Id => ValueProviderBuilder.provideDummyId(Area_Code_Line_Item__c.SObjectType),
                Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<Id> { qlis[0].Id, qlis[1].Id, qlis[2].Id }
                ),
                Area_Code_Line_Item__c.Area_Code__c => ValueProviderBuilder.provideList(
                    new List<Id> { acList[0].Id, acList[1].Id, acList[2].Id }
                ),
                Area_Code_Line_Item__c.Quantity__c => 1
            })
            .build()
            .getRecords();

        List<AssignmentLineItem__c> alis = (List<AssignmentLineItem__c>) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Parent__c => qlis[0].Id,
                AssignmentLineItem__c.Child__c =>  qlis[1].Id,
                AssignmentLineItem__c.AreaCode__c => ValueProviderBuilder.provideList(
                    new List<Id> { acList[2].Id, acList[1].Id }
                ),
                AssignmentLineItem__c.Quantity__c => 1
            })
            .build()
            .getRecords();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.areaCodes = acList;
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity(BusinessIdentity__c = ''));
        testmanager.areaCodeLineItemList = aclis;
        testmanager.assignmentLineItemList = alis;
        testmanager.targetQuote = qt;
        testmanager.targetQuoteLineItems = qlis;
        testmanager.optyQuotes = new List<Quote>();

        Test.startTest();
            PODataBuilderManager.AssignmentDataBuilder builder = new PODataBuilderManager.AssignmentDataBuilder();
            builder.init(testManager);
            Response response = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(response, 'Response should not be null');
        List<SubscriberInfoBuilder.AssignmentData> resultAssignmentToSignUp = (List<SubscriberInfoBuilder.AssignmentData>) response.getData(builder.ASSIGNMENTS_TO_SIGN_UP);
        List<SubscriberInfoBuilder.AssignmentData> resultAssignmentToManual = (List<SubscriberInfoBuilder.AssignmentData>) response.getData(builder.ASSIGNMENTS_TO_SIGN_UP);

        Assert.areEqual(4, resultAssignmentToSignUp.size(), 'Incorrect quantity of AssignmentToSignUp');
        Assert.areEqual(4, resultAssignmentToManual.size(), 'Incorrect quantity of AssignmentToManual');
    }

    @IsTest
    static void testExistingBusinessBuilder() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        TestPODataBuilderManager testManager = new TestPODataBuilderManager(dc, new Opportunity());
        testmanager.targetQuote = new Quote(BillingPackage__c = (String) ValueProviderBuilder.provideDummyId(Package__c.SObjectType).getValue());
        testmanager.optyQuotes = new List<Quote>();

        Test.startTest();
            PODataBuilderManager.ExistingBusinessBuilder builder = new PODataBuilderManager.ExistingBusinessBuilder();
            builder.init(testManager);
            Response response = builder.buildData();

            Assert.isNotNull(response, 'Response should not be null');
            Boolean result = (Boolean) response.getData(builder.EXISTING_BUSINESS);
            Assert.isTrue(result, 'Existing Business data should be true');

            testManager.resp = new Response();
            testManager.targetQuote = new Quote();
            builder.init(testManager);
            response = builder.buildData();

            Assert.isNotNull(response, 'Response should not be null');
            result = (Boolean) response.getData(builder.EXISTING_BUSINESS);
            Assert.isFalse(result, 'Existing Business data should be false');
        Test.stopTest();
    }

    @IsTest
    static void testOrderBasedManagerConstructor() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<Id> { null, null, null, QuoteHelper.RT_ID_PROSERV }
                )
            })
            .quantity(4)
            .build()
            .getRecords();
        Quote masterQuote = quotes[0];
        Quote techQuote = quotes[1];
        Quote otherQuote = quotes[2];

        List<Order> orders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Id => ValueProviderBuilder.provideDummyId(Order.SObjectType),
                Order.QuoteId => ValueProviderBuilder.provideList(
                    new List<Id> { masterQuote.Id, null, null }
                ),
                Order.TechnicalQuoteId__c => ValueProviderBuilder.provideList(
                    new List<Id> { null, techQuote.Id, null }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(new Set<Id>());
        dc.orders = orders;
        Test.startTest();
            PODataBuilderManager.OrderBasedManager manager = new PODataBuilderManager.OrderBasedManager(dc, quotes);
            List<Quote> result = manager.optyQuotes;
        Test.stopTest();

        Assert.areEqual(3, result.size(), 'Other quote should be filtered');
        for (Quote qt : result) {
            Assert.areNotEqual(otherQuote.Id, qt.Id, 'Other quote should be filtered');
        }
    }

    @IsTest
    static void testOrderBasedManagerConstructorEmptyOrders() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<Id> { null, null, null, QuoteHelper.RT_ID_PROSERV }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(new Set<Id>());
        dc.orders = new List<Order>();
        Test.startTest();
            PODataBuilderManager.OrderBasedManager manager = new PODataBuilderManager.OrderBasedManager(dc, quotes);
            List<Quote> result = manager.optyQuotes;
        Test.stopTest();

        Assert.areEqual(4, result.size(), 'All quotes should be returned');
    }

    @IsTest
    static void testOrderBasedManagerGetTargetQuoteLineItems() {
    IValueProvider dummyIdProvider = ValueProviderBuilder.provideDummyId(QuoteLineItem.SObjectType);
    Id masterQliId = (Id) dummyIdProvider.getValue();
    Id qliId1 = (Id) dummyIdProvider.getVAlue();
    Id qliId2 = (Id) dummyIdProvider.getVAlue();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Id => ValueProviderBuilder.provideList(
                    new List<Id> { masterQliId, qliId1, qliId2 }
                ) ,
                QuoteLineItem.MasterQLI__c => ValueProviderBuilder.provideList(
                    new List<Id> { null, masterQliId, null }
                )
            })
            .quantity(3)
            .build()
            .getRecords();

        OrderItem orderItem = (OrderItem) new SObjectBuilder(OrderItem.SObjectType)
            .setField(OrderItem.QuoteLineItemId, qliId1)
            .build()
            .getRecord();

        Map<String, Object> orderMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(orderItem));
        orderMap.put('QuoteLineItem', qlis[1]);
        orderItem = (OrderItem) JSON.deserialize(JSON.serialize(orderMap), OrderItem.class);

        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(new Set<Id>());
        dc.orderItems = new List<OrderItem> { orderItem };

        Test.startTest();
            PODataBuilderManager.OrderBasedManager manager = new PODataBuilderManager.OrderBasedManager(dc, new List<Quote>());
            List<QuoteLineItem> result = manager.getTargetQuoteLineItems(qlis);
        Test.stopTest();

        Assert.areEqual(2, result.size(), '1 quote line item shoould be filtered');
        for (QuoteLineItem qli : result) {
            Assert.areNotEqual(qliId2, qli.Id, '1 quote line item should be filtered');
        }
    }

    @IsTest
    static void testQuoteBasedManagerGetTargetQuoteLineItems() {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Id, ValueProviderBuilder.provideDummyId(QuoteLineItem.SObjectType))
            .quantity(3)
            .build()
            .getRecords();
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());

        Test.startTest();
            PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, new Opportunity());
            List<QuoteLineItem> result = manager.getTargetQuoteLineItems(qlis);
        Test.stopTest();

        Assert.areEqual(3, result.size(), 'All quote line items should exist');

        Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>(qlis);
        for (QuoteLineItem qli : result) {
            Assert.areEqual(qlisMap.get(qli.Id).Id, qli.Id, 'Quote line items should match');
        }
    }

    @IsTest
    static void testGetLineItemsWithShippingPermissionBasedOnALI() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        List<QuoteLineItem> qlis = testManager.dc.qlisWithCustomAddressAssignments;
        testManager.targetQuoteLineItems = qlis;
        List<AssignmentLineItem__c> filteredResult;
        List<AssignmentLineItem__c> emptyResult;

        Test.startTest();
            System.runAs(getUserWithShippingPermission()) {
                List<AssignmentLineItem__c> quoteAssignmentLineItems = testManager.filterAssignmentLineItemsByQuote(testManager.dc.alis, testManager.targetQuote);
                filteredResult = (List<AssignmentLineItem__c>) testManager.getLineItems(quoteAssignmentLineItems, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
                emptyResult = (List<AssignmentLineItem__c>) testManager.getLineItems(null, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
            }
        Test.stopTest();
        Assert.areEqual(1, filteredResult.size(), '1 assignment line item should be filtered');
        Assert.areEqual(qlis[1].Id, filteredResult[0].Child__c, 'Shipping assignment line item should be filtered');
        Assert.areEqual(null, emptyResult, 'Result should be empty');
    }

    @IsTest
    static void testGetLineItemsWithoutShippingPermissionBasedOnALI() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        List<QuoteLineItem> qlis = testManager.dc.qlisWithCustomAddressAssignments;
        testManager.targetQuoteLineItems = qlis;

        User testUserWithoutShippingPerm = (User) new SObjectBuilder(User.SObjectType)
            .create()
            .getRecord();

        List<AssignmentLineItem__c> result;
        List<AssignmentLineItem__c> emptyResult;

        Test.startTest();
            System.runAs(testUserWithoutShippingPerm) {
                List<AssignmentLineItem__c> quoteAssignmentLineItems = testManager.filterAssignmentLineItemsByQuote(testManager.dc.alis, testManager.targetQuote);
                result = (List<AssignmentLineItem__c>) testManager.getLineItems(quoteAssignmentLineItems, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
                emptyResult = (List<AssignmentLineItem__c>) testManager.getLineItems(null, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
            }
        Test.stopTest();
        Assert.areEqual(2, result.size(), '2 assignment line items should be in result');
        Assert.areEqual(null, emptyResult, 'Result should be empty');

    }

    @IsTest
    static void testGetLineItemsWithShippingPermissionBasedOnACLI() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        List<QuoteLineItem> qlis = testManager.dc.qlisWithCustomAddressAssignments;
        testManager.targetQuoteLineItems = qlis;
        List<Area_Code_Line_Item__c> filteredResult;
        List<Area_Code_Line_Item__c> emptyResult;

        Test.startTest();
            System.runAs(getUserWithShippingPermission()) {
                List<Area_Code_Line_Item__c> quoteAreaCodeLineItems = testManager.filterAreaCodeLineItemsByQuote(testManager.dc.aclis, testManager.targetQuote);
                filteredResult = (List<Area_Code_Line_Item__c>) testManager.getLineItems(quoteAreaCodeLineItems, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
                emptyResult = (List<Area_Code_Line_Item__c>) testManager.getLineItems(null, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
            }
        Test.stopTest();
        Assert.areEqual(1, filteredResult.size(), '1 area code line item should be filtered');
        Assert.areEqual(qlis[1].Id, filteredResult[0].Quote_Line_Item__c, 'Shipping area code line item should be filtered');
        Assert.areEqual(null, emptyResult, 'Result should be empty');
    }

    @IsTest
    static void testGetLineItemsWithoutShippingPermissionBasedOnACLI() {
        TestPODataBuilderManager testManager = generateManagerForQli();
        List<QuoteLineItem> qlis = testManager.dc.qlisWithCustomAddressAssignments;
        testManager.targetQuoteLineItems = qlis;

        User testUserWithoutShippingPerm = (User) new SObjectBuilder(User.SObjectType)
            .create()
            .getRecord();

        List<Area_Code_Line_Item__c> result;
        List<Area_Code_Line_Item__c> emptyResult;

        Test.startTest();
            System.runAs(testUserWithoutShippingPerm) {
                List<Area_Code_Line_Item__c> quoteAreaCodeLineItems = testManager.filterAreaCodeLineItemsByQuote(testManager.dc.aclis, testManager.targetQuote);
                result = (List<Area_Code_Line_Item__c>) testManager.getLineItems(quoteAreaCodeLineItems, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
                emptyResult = (List<Area_Code_Line_Item__c>) testManager.getLineItems(null, testManager.dc.qlisWithCustomAddressAssignments, testManager.targetQuote);
            }
        Test.stopTest();
        Assert.areEqual(2, result.size(), '2 area code line items should be in result');
        Assert.areEqual(null, emptyResult, 'Result should be empty');
    }
}