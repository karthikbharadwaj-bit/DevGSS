@IsTest
public class Test_QuoteBasedManager {
    private final static String MAIN_QUOTE_NAME = 'Test Master Office Quote';
    private final static String TECH_OFFICE_QUOTE_NAME = 'Test [system: Office]';
    private final static String TECH_EV_QUOTE_NAME = 'Test [system: Engage Voice Standalone]';
    private final static String TECH_ED_QUOTE_NAME = 'Test [system: Engage Digital Standalone]';
    private final static String TECH_CC_QUOTE_NAME = 'Test [system: RingCentral Contact Center]';
    private final static String PROSERV_QUOTE_NAME = 'Test (ProServ Quote)';
    private final static String LEGACY_CC_QUOTE_NAME = 'Test Legacy Contact Center';

    @IsTest
    static void testQuoteDataBuilder() {
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Id => (Id) ValueProviderBuilder.provideDummyId(Opportunity.sObjectType).getValue(),
                    Opportunity.Name => 'Test Master Office Opportunity',
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false
                }
            )
            .build()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                        MAIN_QUOTE_NAME,
                        TECH_OFFICE_QUOTE_NAME,
                        TECH_EV_QUOTE_NAME,
                        TECH_ED_QUOTE_NAME,
                        TECH_CC_QUOTE_NAME,
                        PROSERV_QUOTE_NAME,
                        LEGACY_CC_QUOTE_NAME
                    }),
                    Quote.IsPrimary__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {
                            true, false, true, true, true, false, false
                        }
                    ),
                    Quote.OpportunityId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testOpportunity.Id,
                            testOpportunity.Id,
                            null,
                            null,
                            null,
                            testOpportunity.Id,
                            testOpportunity.Id
                        }
                    ),
                    Quote.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_PROSERV,
                            QuoteHelper.RT_ID_CC
                        }
                    ),
                    Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001,"catalogId":"18","version":"1"},"productName":"Office"}]',
                    Quote.isMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(
                        new List<Boolean> { false, true, true, true, true, false, false }
                    )
                }
            )
            .quantity(7)
            .build()
            .getRecords();

        PriceBook2 proservPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBook2.AllowedRecordType__c => QuoteHelper.ALLOWED_RT_NAME_BILLING_PROSERV
                }
            )
            .build()
            .getRecord();
        Quote testPSQuote = testQuotes[5];
        testPSQuote.Pricebook2 = proservPriceBook;
        testPSQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_IN_PROGRESS;

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.quotes = testQuotes;
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, testOpportunity);
        PODataBuilderManager.QuoteDataBuilder builder = new PODataBuilderManager.QuoteDataBuilder();
        builder.init(manager);

        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Quote targetQuote = (Quote) resp.getData(builder.TARGET_QUOTE);
        Assert.areEqual(TECH_OFFICE_QUOTE_NAME, targetQuote.Name, 'Target quote should be considered as the technical office quote');

        Quote primaryQuote = (Quote) resp.getData(builder.PRIMARY_QUOTE);
        Assert.areEqual(MAIN_QUOTE_NAME, primaryQuote.Name, 'Primary quote should be considered as the main quote');

        Quote ccQuote = (Quote) resp.getData(builder.CC_QUOTE);
        Assert.areEqual(LEGACY_CC_QUOTE_NAME, ccQuote.Name, 'CC quote should be considered as the legacy CC quote');

        Quote pocQuote = (Quote) resp.getData(builder.POC_QUOTE);
        Assert.isNull(pocQuote, 'No POC quote should be found');

        Quote psQuote = (Quote) resp.getData(builder.PS_QUOTE);
        Assert.areEqual(PROSERV_QUOTE_NAME, psQuote.Name, 'PS quote should be considered as the ProServ quote');

        Boolean isProservQuoteNotCancelled = (Boolean) resp.getData(builder.IS_PROSERV_QUOTE_NOT_CANCELLED);
        Assert.isTrue(isProservQuoteNotCancelled, 'ProServ quote should not be treated as cancelled');
    }

    @IsTest
    static void testQuoteDataBuilderWithEmptyInputs() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, null);
        PODataBuilderManager.QuoteDataBuilder builder = new PODataBuilderManager.QuoteDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Assert.isTrue(resp.data.isEmpty(), 'No data to be build and stored');
    }

    @IsTest
    static void testOpportunityDataBuilder() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(
            dc,
            new Opportunity()
        );
        PODataBuilderManager.OpportunityDataBuilder builder = new PODataBuilderManager.OpportunityDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Assert.isNotNull(resp.getData(builder.OPPORTUNITY), 'Opportunity object should be built and stored');
    }

    @IsTest
    static void testOpportunityDataBuilderWithEmptyInputs() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, null);
        PODataBuilderManager.OpportunityDataBuilder builder = new PODataBuilderManager.OpportunityDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Assert.isTrue(resp.data.isEmpty(), 'No data to be build and stored');
    }

    @IsTest
    static void testUserDataBuilder() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.usr = new User();
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, null);
        PODataBuilderManager.UserDataBuilder builder = new PODataBuilderManager.UserDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Assert.isNotNull(resp.getData(builder.USER), 'User object should be built and stored');
    }

    @IsTest
    static void testUserDataBuilderWithEmptyInputs() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, null);
        PODataBuilderManager.UserDataBuilder builder = new PODataBuilderManager.UserDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Assert.isTrue(resp.data.isEmpty(), 'No data to be build and stored');
    }

    @IsTest
    static void testPromotionDataBuilder() {
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Id => (Id) ValueProviderBuilder.provideDummyId(Opportunity.sObjectType).getValue(),
                    Opportunity.Name => 'Test Master Office Opportunity',
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false
                }
            )
            .build()
            .getRecord();

        String mainQuoteIdString = (String) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();
        String techQuoteIdString = mainQuoteIdString.substring(0, mainQuoteIdString.length() - 1) + 'A';


        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Id => ValueProviderBuilder.provideList(
                        new List<Id> {
                            (Id) mainQuoteIdString,
                            (Id) techQuoteIdString
                        }
                    ),
                    Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                        MAIN_QUOTE_NAME,
                        TECH_OFFICE_QUOTE_NAME
                    }),
                    Quote.IsPrimary__c => ValueProviderBuilder.provideList(
                        new List<Boolean> { true, false }
                    ),
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001,"catalogId":"18","version":"1"},"productName":"Office"}]',
                    Quote.isMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(
                        new List<Boolean> { false, true }
                    )
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        List<Promotion__c> testPromotions = (List<Promotion__c>) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Promotion__c.Quote__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        testQuotes[0].Id,
                        testQuotes[0].Id,
                        testQuotes[1].Id,
                        testQuotes[1].Id,
                        testQuotes[1].Id
                    }
                )
            })
            .quantity(5)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.quotes = testQuotes;
        dc.promotions = testPromotions;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, testOpportunity);
        PODataBuilderManager.PromotionDataBuilder builder = new PODataBuilderManager.PromotionDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        List<Promotion__c> promolist = (List<Promotion__c>) resp.getData(builder.PROMOTIONS);
        Assert.isTrue(promolist.size() == 3, 'Promotions from tech quote should be stored');
    }

    @IsTest
    static void testApprovalDataBuilder() {
        String testAccountIdString = (String) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        String anotherAccountIdString = testAccountIdString.substring(0, testAccountIdString.length() - 1) + 'A';

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => (Id) testAccountIdString,
                    Opportunity.Name => 'Test Master Office Opportunity',
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false
                }
            )
            .build()
            .getRecord();

        List<Approval__c> testApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, ValueProviderBuilder.provideList(
                new List<Id> {
                    (Id) testAccountIdString,
                    (Id) testAccountIdString,
                    (Id) anotherAccountIdString,
                    (Id) anotherAccountIdString,
                    (Id) anotherAccountIdString
                }
            ))
            .quantity(5)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.approvals = testApprovals;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, testOpportunity);
        PODataBuilderManager.ApprovalDataBuilder builder = new PODataBuilderManager.ApprovalDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        List<Approval__c> approvals = (List<Approval__c>) resp.getData(builder.APPROVALS);
        Assert.isTrue(approvals.size() == 5, 'All Approvals from DataCollector should be stored');
    }

    @IsTest
    static void testAccountDataBuilder() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        String testMasterAccountIdString = (String) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        String testEVAccountIdString = testMasterAccountIdString.substring(0, testMasterAccountIdString.length() - 1) + 'A';
        String testEDAccountIdString = testEVAccountIdString.substring(0, testEVAccountIdString.length() - 1) + 'B';
        String testCCAccountIdString = testEDAccountIdString.substring(0, testEDAccountIdString.length() - 1) + 'C';

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Id => ValueProviderBuilder.provideList(
                        new List<Id> {
                            (Id) testMasterAccountIdString,
                            (Id) testEVAccountIdString,
                            (Id) testEDAccountIdString,
                            (Id) testCCAccountIdString
                        }
                    ),
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {
                        'Test Master Office Account',
                        'Test [system: Engage Voice Standalone]',
                        'Test [system: Engage Digital Standalone]',
                        'Test [system: RingCentral Contact Center]'
                    }),
                    Account.IsMultiProductTechnicalAccount__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {
                            false, true, true, true
                        }
                    ),
                    Account.Master_Account__c => ValueProviderBuilder.provideList(
                        new List<Id> {
                            null,
                            (Id) testMasterAccountIdString,
                            (Id) testMasterAccountIdString,
                            (Id) testMasterAccountIdString
                        }
                    ),
                    Account.Payment_Method__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            AccountHelper.PAYMENT_METHOD_INVOICE,
                            null,
                            null,
                            null
                        }
                    ),
                    Account.Billing_ID__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            '123',
                            null,
                            null,
                            null
                        }
                    )
                }
            )
            .quantity(4)
            .build()
            .getRecords();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => (Id) testMasterAccountIdString,
                    Opportunity.Name => 'Test Master Office Opportunity',
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false,
                    Opportunity.Sub_Brand__c => '6010.JenneUS'
                }
            )
            .build()
            .getRecord();
        testOpportunity.Account = testAccounts[0];

        String mainQuoteIdString = (String) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();
        String techQuoteIdString = mainQuoteIdString.substring(0, mainQuoteIdString.length() - 1) + 'A';

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Id => ValueProviderBuilder.provideList(
                        new List<Id> {
                            (Id) mainQuoteIdString,
                            (Id) techQuoteIdString
                        }
                    ),
                    Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                        MAIN_QUOTE_NAME,
                        TECH_OFFICE_QUOTE_NAME
                    }),
                    Quote.IsPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> { true, false }),
                    Quote.OpportunityId => testOpportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.isMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(new List<Boolean> { false, true }),
                    Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001,"catalogId":"18","version":"1"},"productName":"Office"}]'
                }
            )
            .quantity(2)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.accountMap = new Map<Id, Account>(testAccounts);
        dc.quotes = testQuotes;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, testOpportunity);
        PODataBuilderManager.AccountDataBuilder builder = new PODataBuilderManager.AccountDataBuilder();
        builder.init(manager);
        Test.startTest();
            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            Test.setMock(HttpCalloutMock.class, tstMock);
            Response resp = builder.buildData();
        Test.stopTest();
        Account masterAcc = (Account) resp.getData(builder.MASTER_ACC);
        Assert.isNull(masterAcc, 'No Master account should exist for Master Office Account');

        List<Account> boundAccs = (List<Account>) resp.getData(builder.BOUND_ACCS);
        Assert.isTrue(boundAccs.size() == 4, 'All queried accounts should be treated as bound accounts');

        String uBrandId = (String) resp.getData(builder.UBRAND_ID);
        Assert.isTrue(uBrandId == '6010.JenneUS', 'UBRAND_ID should be taken from the test Opportunity');

        String paymentMethod = (String) resp.getData(builder.PAYMENT_METHOD);
        Assert.isTrue(paymentMethod == testAccounts[0].Payment_Method__c, 'Payment method should be taken from Master Office Account');

        String accountStatus = (String) resp.getData(builder.NGBS_ACCOUNT_STATUS);
        Assert.isTrue(accountStatus == 'Active', 'Account status should be taken from NGBS Account');
    }

    @IsTest
    static void testAccountRelationDataBuilder() {
        String testMasterAccountIdString = (String) ValueProviderBuilder.provideDummyId(Account.sObjectType).getValue();
        String anotherAccountIdString = testMasterAccountIdString.substring(0, testMasterAccountIdString.length() - 1) + 'A';
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => (Id) testMasterAccountIdString,
                    Opportunity.Name => 'Test Master Office Opportunity',
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false
                }
            )
            .build()
            .getRecord();

        List<AccountRelation__c> testAccountRelations = (List<AccountRelation__c>) new SobjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountRelation__c.Child_Account__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        (Id) testMasterAccountIdString,
                        (Id) anotherAccountIdString,
                        (Id) anotherAccountIdString,
                        (Id) anotherAccountIdString
                    }
                ),
                AccountRelation__c.Parent_Account__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        (Id) anotherAccountIdString,
                        (Id) testMasterAccountIdString,
                        (Id) anotherAccountIdString,
                        (Id) anotherAccountIdString
                    }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.accountsRelation = testAccountRelations;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, testOpportunity);
        PODataBuilderManager.AccountRelationDataBuilder builder = new PODataBuilderManager.AccountRelationDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        List<AccountRelation__c> accRelations = (List<AccountRelation__c>) resp.getData(builder.ACC_RELATIONS);
        Assert.areEqual(2, accRelations.size(), 'Account relations from only Master Account should be stored');
    }

    @IsTest
    static void testContactDataBuilder() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.contact = new Contact();

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, new Opportunity());
        PODataBuilderManager.ContactDataBuilder builder = new PODataBuilderManager.ContactDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        Contact contact = (Contact) resp.getData(builder.CONTACT);
        Assert.isNotNull(contact, 'Contact object should be built and stored');
    }

    @IsTest
    static void testAreaCodeLineItemDataBuilder() {
        String testQuoteIdString = (String) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();
        String anotherQuoteIdString = testQuoteIdString.substring(0, testQuoteIdString.length() - 1) + 'A';

        Quote targetQuote = buildTargetQuote(testQuoteIdString);

        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(
                    new List<Id> {
                        (Id) testQuoteIdString,
                        (Id) testQuoteIdString,
                        (Id) testQuoteIdString,
                        (Id) anotherQuoteIdString
                    }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        List<Area_Code_Line_Item__c> testAclis = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .quantity(4)
            .build()
            .getRecords();
        testAclis[0].Quote_Line_Item__r = testQlis[0];
        testAclis[1].Quote_Line_Item__r = testQlis[1];
        testAclis[2].Quote_Line_Item__r = testQlis[2];
        testAclis[3].Quote_Line_Item__r = testQlis[3];

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.aclis = testAclis;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, new Opportunity());
        manager.targetQuote = targetQuote;
        PODataBuilderManager.AreaCodeLineItemDataBuilder builder = new PODataBuilderManager.AreaCodeLineItemDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        List<Area_Code_Line_Item__c> areaCodeLineItems = (List<Area_Code_Line_Item__c>) resp.getData(builder.AREA_CODE_LINE_ITEMS);
        Assert.areEqual(3, areaCodeLineItems.size(), 'Area Code Line Items from only target quote should be stored');
    }

    @IsTest
    static void testAssignmentLineItemDataBuilder() {
        String testQuoteIdString = (String) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();
        String anotherQuoteIdString = testQuoteIdString.substring(0, testQuoteIdString.length() - 1) + 'A';

        Quote targetQuote = buildTargetQuote(testQuoteIdString);

        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(
                    new List<Id> {
                        (Id) testQuoteIdString,
                        (Id) testQuoteIdString,
                        (Id) testQuoteIdString,
                        (Id) anotherQuoteIdString
                    }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        List<AssignmentLineItem__c> testAlis = (List<AssignmentLineItem__c>) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .quantity(4)
            .build()
            .getRecords();
        testAlis[0].Parent__r = testQlis[0];
        testAlis[1].Parent__r = testQlis[1];
        testAlis[2].Parent__r = testQlis[2];
        testAlis[3].Parent__r = testQlis[3];

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.alis = testAlis;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, new Opportunity());
        manager.targetQuote = targetQuote;
        PODataBuilderManager.AssignmentLineItemDataBuilder builder = new PODataBuilderManager.AssignmentLineItemDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        List<AssignmentLineItem__c> assignmentLineItems = (List<AssignmentLineItem__c>) resp.getData(builder.ASSIGNMENT_LINE_ITEM);
        Assert.areEqual(3, assignmentLineItems.size(), 'Assignment Line Items from only target quote should be stored');
    }

    @IsTest
    static void testAreaCodeDataBuilder() {
        String testQuoteAreaCodeIdString = (String) ValueProviderBuilder.provideDummyId(Area_Codes__c.sObjectType).getValue();
        Quote targetQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                        MAIN_QUOTE_NAME
                    }),
                    Quote.Enabled_LBO__c => true,
                    Quote.AreaCode__c => (Id) testQuoteAreaCodeIdString
                }
            )
            .build()
            .getRecord();


        List<Id> testAreaCodeIdsForAclis = new List<Id> {
            (Id) (testQuoteAreaCodeIdString.substring(0, testQuoteAreaCodeIdString.length() - 1) + 'A'),
            (Id) (testQuoteAreaCodeIdString.substring(0, testQuoteAreaCodeIdString.length() - 1) + 'B')
        };
        List<Area_Code_Line_Item__c> testAclis = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.area_code__c => ValueProviderBuilder.provideList(testAreaCodeIdsForAclis)
            })
            .quantity(2)
            .build()
            .getRecords();

        String anotherAreaCodeIdString = testQuoteAreaCodeIdString.substring(0, testQuoteAreaCodeIdString.length() - 1) + 'C';
        List<Area_Codes__c> testAreaCodes = (List<Area_Codes__c>) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Id => ValueProviderBuilder.provideList(new List<Id> {
                    (Id) testQuoteAreaCodeIdString,
                    testAreaCodeIdsForAclis[0],
                    testAreaCodeIdsForAclis[1],
                    anotherAreaCodeIdString
                })
            })
            .quantity(4)
            .build()
            .getRecords();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        dc.areaCodes = testAreaCodes;

        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, new Opportunity());
        manager.targetQuote = targetQuote;
        manager.areaCodeLineItemList = testAclis;
        PODataBuilderManager.AreaCodeDataBuilder builder = new PODataBuilderManager.AreaCodeDataBuilder();
        builder.init(manager);
        Test.startTest();
            Response resp = builder.buildData();
        Test.stopTest();
        List<Area_Codes__c> areaCodes = (List<Area_Codes__c>) resp.getData(builder.AREA_CODE);
        Assert.areEqual(3, areaCodes.size(), 'Area Codes from only target quote and aclis should be stored');
    }

    @IsTest
    static void testExistingBusinessBuilder() {
        String testQuoteIdString = (String) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();

        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());
        PODataBuilderManager.QuoteBasedManager manager = new PODataBuilderManager.QuoteBasedManager(dc, new Opportunity());
        PODataBuilderManager.ExistingBusinessBuilder builder = new PODataBuilderManager.ExistingBusinessBuilder();
        manager.targetQuote = buildTargetQuote(testQuoteIdString);
        builder.init(manager);

        Test.startTest();
        Response resp = builder.buildData();
        Test.stopTest();

        Assert.isNotNull(resp.getData(builder.EXISTING_BUSINESS), 'EXISTING_BUSINESS property should be built and stored');
    }

    private static Quote buildTargetQuote(String strId) {
        return (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => (Id) strId,
                Quote.Name => MAIN_QUOTE_NAME
            }
        )
        .build()
        .getRecord();
    }
}