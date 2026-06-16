@IsTest
public class Test_OrderBasedDC {
    private final static String MAIN_QUOTE_NAME = 'Test Master Office Quote';
    private final static String TECH_OFFICE_QUOTE_NAME = 'Test [system: Office]';
    private final static String TECH_EV_QUOTE_NAME = 'Test [system: Engage Voice Standalone]';
    private final static String TECH_ED_QUOTE_NAME = 'Test [system: Engage Digital Standalone]';
    private final static String TECH_CC_QUOTE_NAME = 'Test [system: RingCentral Contact Center]';
    private final static String PROSERV_QUOTE_NAME = 'Test (ProServ Quote)';
    private final static String CC_PROSERV_QUOTE_NAME = 'CC Test (ProServ Quote)';

    @TestSetup
    static void setup() {
        Triggers.switchOff();
            Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Account.Name => 'Test Master Office Account',
                        Account.IsMultiProductTechnicalAccount__c => false
                    }
                )
                .create()
                .getRecord();

            Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Opportunity.Name => 'Test Master Office Opportunity',
                        Opportunity.AccountId => testMasterAccount.Id,
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.IsMultiProductTechnicalOpportunity__c => false
                    }
                )
                .create()
                .getRecord();

            Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => MAIN_QUOTE_NAME,
                        Quote.IsPrimary__c => true,
                        Quote.OpportunityId => testMasterOpportunity.Id,
                        Quote.isMultiProductTechnicalQuote__c => false,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
                    }
                )
                .create()
                .getRecord();

            List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                            TECH_OFFICE_QUOTE_NAME,
                            TECH_EV_QUOTE_NAME,
                            TECH_ED_QUOTE_NAME,
                            TECH_CC_QUOTE_NAME,
                            PROSERV_QUOTE_NAME
                        }),
                        Quote.IsPrimary__c => ValueProviderBuilder.provideList(
                            new List<Boolean> {
                                false, true, true, true, false
                            }
                        ),
                        Quote.OpportunityId => testMasterOpportunity.Id,
                        Quote.IsMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(
                            new List<Boolean> {true, true, true, true, false}),
                        Quote.MasterQuote__c => ValueProviderBuilder.provideList(
                            new List<String> {
                                testMasterQuote.Id, testMasterQuote.Id, testMasterQuote.Id, testMasterQuote.Id, null
                            }
                        ),
                        Quote.ProServ_Status__c => ValueProviderBuilder.provideList(
                            new List<String> {null, null, null, null, QuoteHelper.PROSERVSTATUS_IN_PROGRESS}
                        ),
                        Quote.RecordTypeId => ValueProviderBuilder.provideList(
                            new List<Id> {
                                QuoteHelper.RT_ID_BILLING,
                                QuoteHelper.RT_ID_BILLING,
                                QuoteHelper.RT_ID_BILLING,
                                QuoteHelper.RT_ID_BILLING,
                                QuoteHelper.RT_ID_PROSERV
                            }
                        ),
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.ServiceName__c => ValueProviderBuilder.provideList(
                            new List<String> {
                                QuoteHelper.NGBS_OFFICE_PRODUCT,
                                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                                QuoteHelper.NGBS_RCCC_PRODUCT,
                                null
                            }
                        ),
                        Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                    }
                )
                .quantity(5)
                .create()
                .getRecords();

            List<Order> testOrders = (List<Order> ) new SObjectBuilder(Order.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Order.QuoteId => testMasterQuote.Id,
                    Order.AccountId => testMasterAccount.Id,
                    Order.TechnicalQuoteId__c => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testQuotes[0].Id,
                            testQuotes[0].Id,
                            testQuotes[1].Id,
                            testQuotes[1].Id,
                            testQuotes[2].Id,
                            testQuotes[2].Id,
                            testQuotes[3].Id,
                            testQuotes[3].Id
                        }
                    ),
                    Order.Provisioning__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            OrderHelper.PROVISIONING_AUTO,
                            OrderHelper.PROVISIONING_MANUAL,
                            OrderHelper.PROVISIONING_AUTO,
                            OrderHelper.PROVISIONING_MANUAL,
                            OrderHelper.PROVISIONING_AUTO,
                            OrderHelper.PROVISIONING_MANUAL,
                            OrderHelper.PROVISIONING_AUTO,
                            OrderHelper.PROVISIONING_MANUAL
                        }
                    ),
                    Order.EffectiveDate => Date.today(),
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                })
                .quantity(8)
                .create()
                .getRecords();

            PriceBookEntry testPbe = (PriceBookEntry) new SOBjectBuilder(PriceBookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideGenericParent(Product2.SObjectType)
                })
                .create()
                .getRecord();

            List<OrderItem> testOrderItems = (List<OrderItem>) new SObjectBuilder(OrderItem.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    OrderItem.OrderId => ValueProviderBuilder.provideParents(testOrders),
                    OrderItem.PricebookEntryId => testPbe.Id,
                    OrderItem.Quantity => 1,
                    OrderItem.UnitPrice => 100
                })
                .quantity(8)
                .create()
                .getRecords();
        Triggers.switchOn();
    }

    @IsTest
    static void testQueryOrders() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryOrders();

            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryOrders();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.isTrue(dc.Orders.size() == 8, 'For each tech quote 2 orders should be retrieved');
        Assert.areEqual(issuedQueriesBeforeSecondRequest, issuedQueriesAfterSecondRequest, 'No more than one query should be performed');
    }

    @IsTest
    static void testQueryOrderItems() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryOrderItems();

            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryOrderItems();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.isTrue(dc.OrderItems.size() == 8, 'Order items for each order should be retrieved');
        Assert.isTrue(issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest, 'Each method call should result to new DataBase query');
    }

    @IsTest
    static void testGroupQuotesByServicesWhenNoQuotes() {
        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(new Set<Id>());

        Test.startTest();
            Map<String, List<Quote>> serviceToQuoteListMap = dc.groupQuotesByServices(new List<Quote>());
        Test.stopTest();

        Assert.isTrue(serviceToQuoteListMap.isEmpty(), 'When no quotes are provided, the result should be empty map');
    }

    @IsTest
    static void testGroupQuotesByServices() {
        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                        MAIN_QUOTE_NAME,
                        TECH_OFFICE_QUOTE_NAME,
                        TECH_EV_QUOTE_NAME,
                        TECH_ED_QUOTE_NAME,
                        TECH_CC_QUOTE_NAME,
                        PROSERV_QUOTE_NAME
                    }),
                    Quote.IsPrimary__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {
                            true, false, false, false, false, false
                        }
                    ),
                    Quote.IsMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {false, true, true, true, true, false}),
                    Quote.RecordTypeId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_BILLING,
                            QuoteHelper.RT_ID_PROSERV
                        }
                    ),
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(
                        new List<String> {
                            QuoteHelper.NGBS_OFFICE_PRODUCT,
                            QuoteHelper.NGBS_OFFICE_PRODUCT,
                            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                            QuoteHelper.NGBS_RCCC_PRODUCT,
                            null
                        }
                    )
                }
            )
            .quantity(6)
            .build()
            .getRecords();
        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(new Set<Id>());

        Test.startTest();
            Map<String, List<Quote>> serviceToQuoteListMap = dc.groupQuotesByServices(testQuotes);
        Test.stopTest();

        Assert.isFalse(serviceToQuoteListMap.isEmpty(), 'The result should not be empty');
        Assert.areEqual(4, serviceToQuoteListMap.size(), 'The result should contain 4 services');
        Assert.areEqual(
            3,
            serviceToQuoteListMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT).size(),
            'Office service bundle should contain main Office, tech Office and Proserv quotes'
        );
        Assert.areEqual(
            1,
            serviceToQuoteListMap.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT).size(),
            'Engage Voice service bundle should contain single tech quote'
        );
        Assert.areEqual(
            1,
            serviceToQuoteListMap.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).size(),
            'Engage Digital service bundle should contain single tech quote'
        );
        Assert.areEqual(
            1,
            serviceToQuoteListMap.get(QuoteHelper.NGBS_RCCC_PRODUCT).size(),
            'CC service bundle should contain single tech quote'
        );
    }

    @IsTest
    static void testGroupQuotesByServicesProServ() {
        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    MAIN_QUOTE_NAME,
                    TECH_ED_QUOTE_NAME,
                    PROSERV_QUOTE_NAME,
                    CC_PROSERV_QUOTE_NAME
                }),
                Quote.IsPrimary__c => ValueProviderBuilder.provideList(
                    new List<Boolean> { true, false, true, true }
                ),
                Quote.IsMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(
                    new List<Boolean> { false, true, false, false }
                ),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_PROSERV,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                    null,
                    null
                })
            })
            .quantity(4)
            .build()
            .getRecords();

        PODataCollector.OrderBasedDC dc = new PODataCollector.OrderBasedDC(new Set<Id>());

        Test.startTest();
            Map<String, List<Quote>> serviceToQuoteListMapOfficeMain = dc.groupQuotesByServices(testQuotes);
            testQuotes.remove(0);
            Map<String, List<Quote>> serviceToQuoteListMapEngageMain = dc.groupQuotesByServices(testQuotes);
        Test.stopTest();

        Assert.areEqual(2, serviceToQuoteListMapOfficeMain.size(), 'The result should contain 2 services');
        Assert.areEqual(
            3,
            serviceToQuoteListMapOfficeMain.get(QuoteHelper.NGBS_OFFICE_PRODUCT).size(),
            'Office service bundle should contain main Office, and both Proserv quotes'
        );
        Assert.areEqual(
            1,
            serviceToQuoteListMapOfficeMain.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).size(),
            'Engage Digital service bundle should contain single tech quote'
        );

        Assert.areEqual(1, serviceToQuoteListMapEngageMain.size(), 'The result should contain 1 service');
        Assert.areEqual(
            3,
            serviceToQuoteListMapEngageMain.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT).size(),
            'Engage service bundle should contain main Engage, and both Proserv quotes'
        );
    }

    @IsTest
    static void testCollectDataWhenNoTargetIdsArePassed() {
        Test.startTest();
            PODataCollector dc = new PODataCollector.OrderBasedDC(new Set<Id>()).collectData();
        Test.stopTest();

        Assert.isTrue(dc.quotes.isEmpty(), 'No quotes should be queried');
        Assert.isTrue(dc.opportunities.isEmpty(), 'No opportunities should be queried');
        Assert.isNotNull(dc.usr, 'User should be queried');
        Assert.isTrue(dc.promotions.isEmpty(), 'No promotions should be queried');
        Assert.isTrue(dc.approvals.isEmpty(), 'No approvals should be queried');
        Assert.isTrue(dc.accountsRelation.isEmpty(), 'No account relations should be queried');
        Assert.isNull(dc.contact, 'No contact should be queried');
        Assert.isTrue(dc.aclis.isEmpty(), 'No area code line items should be queried');
        Assert.isTrue(dc.alis.isEmpty(), 'No assignment line items should be queried');
        Assert.isTrue(
            dc.qlisWithCustomAddressAssignments.isEmpty(),
            'No quote line items should be queried when user has no AllowProcessOrderWithoutShipping permission'
        );
    }

    @isTest
    static void testFilterProservQuotes() {
        PODataCollector dC = new PODataCollector.OrderBasedDC(new Set<Id>());
        dC.quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.RecordTypeId, ValueProviderBuilder.provideList(new List<String> {QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_PROSERV}))
            .quantity(2)
            .build()
            .getRecords(); 

        Test.startTest();
            List<Quote> quotesWithoutProServ = dC.filterProservQuotes();
        Test.stopTest();

        Assert.isTrue(quotesWithoutProServ.size() == 1, 'Only one quote should be left after filtering');
        Assert.areEqual(QuoteHelper.RT_ID_BILLING, quotesWithoutProServ[0].RecordTypeId, 'Only billing quote should be left');
    }

    @isTest
    static void testPrepareData() {
        PODataCollector.OrderBasedDC dC = new PODataCollector.OrderBasedDC(new Set<Id>());
        dC.quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideList(new List<Id> {
                    (Id) new ValueProvider.DummyIdProvider(Quote.SObjectType).getValue(), 
                    null, 
                    null
                }),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(new List<Boolean> {false, true, true}),
                Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_RCCC_PRODUCT,
                    QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT
                }),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .quantity(3)
            .build()
            .getRecords();
        dC.masterQuote = dC.quotes[0];

        Test.startTest();
            dC.prepareData();
        Test.stopTest();

        Assert.areEqual(2, dC.preparedQuotes.size(), 'Only two quotes should be left after filtering - RCCC and Engage Voice');
    }

    @isTest
    static void testPrepareDataWOTargetIds() {
        PODataCollector.OrderBasedDC dC = new PODataCollector.OrderBasedDC(new Set<Id>());

        Test.startTest();
            dC.prepareData();
        Test.stopTest();

        Assert.areEqual(0, dC.preparedQuotes.size(), 'Prepared opportunities should be empty');
    }

    @isTest
    static void testTransformPreparedData() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.OrderBasedDC dC = (PODataCollector.OrderBasedDC) new PODataCollector.OrderBasedDC(quoteMap.keySet()).collectData();
        dC.prepareData();

        Test.startTest();
            List<Response> responseList = dC.transformPreparedData();
        Test.stopTest();

        Assert.isFalse(responseList.isEmpty(), 'Response list should contain prepared data');
        Assert.areEqual(4, responseList.size(), 'Response list should contain 4 responses');
        for (Response resp : responseList) {
            Assert.isNotNull(resp.data.get('targetQuote'), 'Response data should contain target quote');
            Assert.isNotNull(resp.data.get('primaryQuote'), 'Response data should contain primary quote');
            Assert.isNotNull(resp.data.get('boundAccs'), 'Response data should contain master account');
            Assert.isNotNull(resp.data.get('opportunity'), 'Response data should contain opportunity');
        }
    }

    @isTest
    static void testTransformPreparedDataWOTargetIds() {
        PODataCollector.OrderBasedDC dC = (PODataCollector.OrderBasedDC) new PODataCollector.OrderBasedDC(new Set<Id>()).collectData();
        dC.prepareData();

        Test.startTest();
            List<Response> responseList = dC.transformPreparedData();
        Test.stopTest();

        Assert.isTrue(responseList.isEmpty(), 'Response list should be empty');
    }
}