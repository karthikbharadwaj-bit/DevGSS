@IsTest
public class Test_QuoteBasedDC {
    private final static String MAIN_QUOTE_NAME = 'Test Master Office Quote';
    private final static String TECH_OFFICE_QUOTE_NAME = 'Test [system: Office]';
    private final static String TECH_EV_QUOTE_NAME = 'Test [system: Engage Voice Standalone]';
    private final static String TECH_ED_QUOTE_NAME = 'Test [system: Engage Digital Standalone]';
    private final static String TECH_CC_QUOTE_NAME = 'Test [system: RingCentral Contact Center]';
    private final static String PROSERV_QUOTE_NAME = 'Test (ProServ Quote)';

    private final static String MAIN_CONTACT_EMAIL = 'admin@test.com';

    @TestSetup
    static void setup() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'Test Master Office Account',
                    Account.IsMultiProductTechnicalAccount__c => false
                }
            )
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => ValueProviderBuilder.provideList(new List<String> {
                        'Test [system: Engage Voice Standalone]',
                        'Test [system: Engage Digital Standalone]',
                        'Test [system: RingCentral Contact Center]'
                    }),
                    Account.IsMultiProductTechnicalAccount__c => true,
                    Account.Master_Account__c => testMasterAccount.Id
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'Test Master Office Opportunity',
                    Opportunity.AccountId => testMasterAccount.Id,
                    Opportunity.IsMultiProductTechnicalOpportunity__c => false,
                    Opportunity.CloseDate => system.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideList(new List<String> {
                        'Test [system: Engage Voice Standalone]',
                        'Test [system: Engage Digital Standalone]',
                        'Test [system: RingCentral Contact Center]'
                    }),
                    Opportunity.IsMultiProductTechnicalOpportunity__c => true,
                    Opportunity.MasterOpportunity__c => testMasterOpportunity.Id,
                    Opportunity.AccountId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testAccounts.get(0).Id,
                            testAccounts.get(1).Id,
                            testAccounts.get(2).Id
                        }
                    )
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<Area_Codes__c> testAreaCodes = (List<Area_Codes__c>) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => ValueProviderBuilder.provideList(
                    new List<String> {
                        'test area code0',
                        'test area code1',
                        'test area code2',
                        'test area code3'
                    }
                )
            })
            .quantity(4)
            .create()
            .getRecords();

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => MAIN_QUOTE_NAME,
                    Quote.IsPrimary__c => true,
                    Quote.OpportunityId => testMasterOpportunity.Id,
                    Quote.isMultiProductTechnicalQuote__c => false,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.AreaCode__c => testAreaCodes[2].Id,
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
                }
            )
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
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
                    Quote.OpportunityId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testMasterOpportunity.Id,
                            testOpportunities.get(0).Id,
                            testOpportunities.get(1).Id,
                            testOpportunities.get(2).Id,
                            testMasterOpportunity.Id
                        }
                    ),
                    Quote.IsMultiProductTechnicalQuote__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {true, true, true, true, false}
                    ),
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
                    Quote.AreaCode__c => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testAreaCodes[3].Id,
                            null,
                            null,
                            null,
                            null
                        }
                    ),
                    Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
                }
            )
            .quantity(5)
            .create()
            .getRecords();

        List<Promotion__c> testPromotions = (List<Promotion__c>) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Promotion__c.Quote__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        testMasterQuote.Id,
                        testQuotes[0].Id,
                        testQuotes[1].Id,
                        testQuotes[2].Id,
                        testQuotes[3].Id
                    }
                )
            })
            .quantity(5)
            .create()
            .getRecords();

        List<Approval__c> testApprovals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Name => 'testApproval',
                Approval__c.Account__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        testMasterAccount.Id,
                        testAccounts[0].Id,
                        testAccounts[1].Id,
                        testAccounts[2].Id
                    }
                ),
                Approval__c.RecordTypeId => ValueProviderBuilder.provideList(
                    new List<Id> {
                        ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                        ApprovalHelper.RT_ID_INVOICING_REQUEST,
                        ApprovalHelper.RT_ID_BOB_APPROVAL,
                        ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST
                    }
                )
            })
            .quantity(4)
            .create()
            .getRecords();

        List<AccountRelation__c> testAccountRelations = (List<AccountRelation__c>) new SobjectBuilder(AccountRelation__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountRelation__c.Child_Account__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        testMasterAccount.Id,
                        testAccounts[0].Id,
                        testAccounts[1].Id,
                        testAccounts[2].Id
                    }
                ),
                AccountRelation__c.Parent_Account__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        testMasterAccount.Id,
                        testAccounts[1].Id,
                        testAccounts[0].Id,
                        testAccounts[2].Id
                    }
                )
            })
            .quantity(4)
            .create()
            .getRecords();

        List<Contact> testContacts = (List<Contact>) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, ValueProviderBuilder.provideList(
                new List<Id> {
                    testMasterAccount.Id,
                    testMasterAccount.Id,
                    testAccounts[0].Id,
                    testAccounts[1].Id,
                    testAccounts[2].Id
                }
            ))
            .setField(Contact.Email, ValueProviderBuilder.provideList(
                new List<String> {
                    MAIN_CONTACT_EMAIL,
                    'fake@test.com',
                    'tech1@test.com',
                    'tech2@test.com',
                    'tech3@test.com'
                }
            ))
            .quantity(5)
            .create()
            .getRecords();

        List<OpportunityContactRole> testOpportunityContactRoles = (List<OpportunityContactRole>) new SObjectBuilder(OpportunityContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    OpportunityContactRole.OpportunityId => ValueProviderBuilder.provideList(
                        new List<Id> {
                            testMasterOpportunity.Id,
                            testMasterOpportunity.Id,
                            testOpportunities[0].Id,
                            testOpportunities[1].Id,
                            testOpportunities[2].Id
                        }
                    ),
                    OpportunityContactRole.ContactId =>  ValueProviderBuilder.provideList(
                        new List<Id> {
                            testContacts[0].Id,
                            testContacts[1].Id,
                            testContacts[2].Id,
                            testContacts[3].Id,
                            testContacts[4].Id
                        }
                    ),
                    OpportunityContactRole.Role => ValueProviderBuilder.provideList(
                        new List<String> {
                            'Administrator',
                            'FakeRoleForMasterOpportunity',
                            'Administrator',
                            'Administrator',
                            'Administrator'
                        }
                    )
                }
            )
            .quantity(5)
            .create()
            .getRecords();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product1',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testMasterQuote.Id,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        List<QuoteLineItem> testQli = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(
                    new List<Id> {
                        testQuotes[0].Id
                    }
                ),
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => true,
                QuoteLineItem.MasterQLI__c => masterQli.Id
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Area_Code_Line_Item__c> testAclis = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        testAreaCodes[0].Id,
                        testAreaCodes[0].Id,
                        testAreaCodes[1].Id
                    }
                ),
                Area_Code_Line_Item__c.Quantity__c => 1,
                Area_Code_Line_Item__c.Quote_Line_Item__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        masterQli.Id,
                        testQli[0].Id,
                        testQli[1].Id
                    }
                )
            })
            .quantity(3)
            .create()
            .getRecords();

        List<AssignmentLineItem__c> testAlis = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        masterQli.Id,
                        testQli[0].Id,
                        testQli[1].Id
                    }
                ),
                AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        masterQli.Id,
                        testQli[0].Id,
                        testQli[1].Id
                    }
                ),
                AssignmentLineItem__c.Quantity__c => 2
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.switchOn();
    }

    @IsTest
    static void testQueryRecordsWhenNoTargetIdsArePassed() {
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(new Set<Id>());

        Test.startTest();
            dc.queryQuotes()
                .queryOpportunities()
                .queryUser()
                .queryPromotions()
                .queryApprovals()
                .queryAccountsRelations()
                .queryContact()
                .queryAreaCodeLineItems()
                .queryAssignmentLineItems()
                .queryQuoteLineItems();
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
        Assert.isTrue(dc.qlisWithCustomAddressAssignments.isEmpty(), 'No quote line items should be queried');
    }

    @IsTest
    static void testQueryQuotes() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryQuotes();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryQuotes();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(quoteMap.values().size(), dc.quotes.size(), 'Main, technical, proserv quotes should be queried');
        Assert.areEqual(issuedQueriesBeforeSecondRequest, issuedQueriesAfterSecondRequest, 'No more than one query should be performed');
    }

    @IsTest
    static void testQueryOpportunity() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryOpportunities();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryOpportunities();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(4, dc.opportunities.size(), 'Master and technical opportunities should be queried');
        Assert.areEqual(issuedQueriesBeforeSecondRequest, issuedQueriesAfterSecondRequest, 'No more than one query should be performed');
    }

    @IsTest
    static void testQueryUser() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryUser();
        Test.stopTest();

        Assert.isNotNull(dc.usr, 'User should be queried and stored in dc.usr');
    }

    @IsTest
    static void testQueryPromotions() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryPromotions();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryPromotions();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        List<Promotion__c> expectedPromotions = (List<Promotion__c>) new PromotionSelector()
            .selectPromotionByQuoteName(new List<Object> {
                new Set<String> {
                    MAIN_QUOTE_NAME,
                    TECH_OFFICE_QUOTE_NAME,
                    TECH_EV_QUOTE_NAME,
                    TECH_ED_QUOTE_NAME,
                    TECH_CC_QUOTE_NAME
                }
            })
            .executeQuery();

        Assert.areEqual(expectedPromotions.size(), dc.promotions.size(), 'Promotion from each quote should be queried');
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryApprovals() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryApprovals();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryApprovals();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        List<Approval__c> expectedApprovals = (List<Approval__c>) new ApprovalSelector(true, true)
            .selectApprovals()
            .executeQuery();
        Assert.areEqual(expectedApprovals.size(), dc.approvals.size(), 'Approval from each account should be queried');
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryAccounts() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryAccounts();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryAccounts();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        List<Account> expectedAccounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();
        Assert.areEqual(
            expectedAccounts.size(),
            dc.accountMap.size(),
            'All accounts associated with Quotes should be queried'
        );
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryAccountsRelation() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryAccountsRelations();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryAccountsRelations();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        List<AccountRelation__c> expectedAccountRelations = (List<AccountRelation__c>) new AccountRelationSelector()
            .selectAccountRelations()
            .executeQuery();
        Assert.areEqual(
            expectedAccountRelations.size(),
            dc.accountsRelation.size(),
            'All account relations associated Parent and Child Accounts should be queried'
        );
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryContact() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryContact();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryContact();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Contact mainContact = (Contact) new ListOptional(
            new ContactSelector()
                .selectContactByMail(
                    new List<Object> {MAIN_CONTACT_EMAIL}
                )
                .executeQuery()
        ).getFirst();
        Assert.areEqual(
            mainContact.Id,
            dc.contact.Id,
            'Wrong contact was queried'
        );
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryAreaCodeLineItems() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryAreaCodeLineItems();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryAreaCodeLineItems();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(
            3,
            dc.aclis.size(),
            'Wrong number of Area Code Line Items were queried'
        );
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest == issuedQueriesAfterSecondRequest,
            'No more than one query should be performed'
        );
    }

    @IsTest
    static void testQueryAssignmentLineItems() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryAssignmentLineItems();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryAssignmentLineItems();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(3, dc.alis.size(), 'Wrong number of Assignment Line Items were queried');
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryAreaCodes() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());
        Test.startTest();
            dc.queryAreaCodes();
            Integer issuedQueriesBeforeSecondRequest = Limits.getQueries();
            dc.queryAreaCodes();
            Integer issuedQueriesAfterSecondRequest = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(4, dc.areaCodes.size(), 'Wrong number of Area Codes were queried');
        Assert.isTrue(
            issuedQueriesBeforeSecondRequest < issuedQueriesAfterSecondRequest,
            'Each method call should result to new DataBase query'
        );
    }

    @IsTest
    static void testQueryQuoteLineItemsWOPermission() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dc.queryQuoteLineItems();
        Test.stopTest();

        Assert.areEqual(
            0,
            dc.qlisWithCustomAddressAssignments.size(),
            'No quoteLineItems should be returned when user has no AllowProcessOrderWithoutShipping permission'
        );
    }

    @IsTest
    static void queryQuoteLineItemsWithPermission() {
        User testUser = (User) new SobjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    User.Username => 'test!user@gmail.com',
                    User.LastName => 'TestTest',
                    User.Email => 'test_user@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                })
            .create()
            .getRecord();

        SetupEntityAccess sea = (SetupEntityAccess) new ListOptional(new SetupEntityAccessSelector()
            .selectSetupEntityAccessByCustomPermissionName(new List<Object> {CustomPermissionHelper.PERMISSION_SKIP_SHIPPING_VALIDATION})
            .executeQuery()
        ).getFirst();

        new SobjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => sea.ParentId
                })
            .create();

        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        System.runAs(testUser) {
            Test.startTest();
                dc.queryQuoteLineItems();
            Test.stopTest();
            Assert.areEqual(
                1,
                dc.qlisWithCustomAddressAssignments.size(),
                'When user has AllowProcessOrderWithoutShipping permission - quoteLineItems query should be performed'
            );
        }
    }

    @IsTest
    static void testCollectDataWhenNoTargetsArePassed() {
        Test.startTest();
            PODataCollector dc = new PODataCollector.QuoteBasedDC(new Set<Id>()).collectData();
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

    @IsTest
    static void testCollectData() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        Test.startTest();
            PODataCollector dc = new PODataCollector.QuoteBasedDC(quoteMap.keySet()).collectData();
        Test.stopTest();
        Assert.areEqual(quoteMap.keySet().size(), dc.quotes.size(), 'Main, technical, proserv quotes should be queried');
        Assert.areEqual(4, dc.opportunities.size(), 'Master and technical opportunities should be queried');
        Assert.isNotNull(dc.usr, 'User should be queried and stored in dc.usr');

        List<Promotion__c> expectedPromotions = (List<Promotion__c>) new PromotionSelector()
            .selectPromotionByQuoteName(new List<Object> {
                new Set<String> {
                    MAIN_QUOTE_NAME,
                    TECH_OFFICE_QUOTE_NAME,
                    TECH_EV_QUOTE_NAME,
                    TECH_ED_QUOTE_NAME,
                    TECH_CC_QUOTE_NAME
                }
            })
            .executeQuery();
        Assert.areEqual(expectedPromotions.size(), dc.promotions.size(), 'Promotion from each quote should be queried');

        List<Approval__c> expectedApprovals = (List<Approval__c>) new ApprovalSelector(true, true)
            .selectApprovals()
            .executeQuery();
        Assert.areEqual(expectedApprovals.size(), dc.approvals.size(), 'Approval from each account should be queried');

        List<Account> expectedAccounts = (List<Account>) new AccountSelector()
            .selectAccounts()
            .executeQuery();
        Assert.areEqual(
            expectedAccounts.size(),
            dc.accountMap.size(),
            'All accounts associated with Quotes should be queried'
        );

        List<AccountRelation__c> expectedAccountRelations = (List<AccountRelation__c>) new AccountRelationSelector()
            .selectAccountRelations()
            .executeQuery();
        Assert.areEqual(
            expectedAccountRelations.size(),
            dc.accountsRelation.size(),
            'All account relations associated Parent and Child Accounts should be queried'
        );

        Contact mainContact = (Contact) new ListOptional(
            new ContactSelector()
                .selectContactByMail(
                    new List<Object> { MAIN_CONTACT_EMAIL }
                )
                .executeQuery()
        ).getFirst();
        Assert.areEqual(mainContact.Id, dc.contact.Id, 'Wrong contact was queried');
        Assert.areEqual(3, dc.aclis.size(), 'Wrong number of Area Code Line Items were queried');
        Assert.areEqual(3, dc.alis.size(), 'Wrong number of Assignment Line Items were queried');
        Assert.areEqual(4, dc.areaCodes.size(), 'Wrong number of Area Codes were queried');
        Assert.areEqual(
            0,
            dc.qlisWithCustomAddressAssignments.size(),
            'No quoteLineItems should be queried when user has no AllowProcessOrderWithoutShipping permission'
        );
    }

    @isTest
    static void testPrepareData() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dC = new PODataCollector.QuoteBasedDC(quoteMap.keySet());

        Test.startTest();
            dC.prepareData();
        Test.stopTest();

        Assert.areEqual(3, dC.preparedOpportunities.size(), 'Prepared opportunities should contain 3 records');
    }

    @isTest
    static void testPrepareDataWOTargetIds() {
        PODataCollector.QuoteBasedDC dC = new PODataCollector.QuoteBasedDC(new Set<Id>());

        Test.startTest();
            dC.prepareData();
        Test.stopTest();

        Assert.areEqual(0, dC.preparedOpportunities.size(), 'Prepared opportunities should be empty');
    }

    @isTest
    static void testTransformPreparedData() {
        Map<Id, Quote> quoteMap = new Map<Id, Quote>((List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
        );
        PODataCollector.QuoteBasedDC dC = (PODataCollector.QuoteBasedDC) new PODataCollector.QuoteBasedDC(quoteMap.keySet()).collectData();
        dC.prepareData();

        Test.startTest();
            List<Response> responseList = dC.transformPreparedData();
        Test.stopTest();

        Assert.isFalse(responseList.isEmpty(), 'Response list should contain prepared data');
        Assert.areEqual(3, responseList.size(), 'Response list should contain 3 responses');
        for (Response resp : responseList) {
            Assert.isNotNull(resp.data.get('targetQuote'), 'Response data should contain target quote');
            Assert.isNotNull(resp.data.get('primaryQuote'), 'Response data should contain primary quote');
            Assert.isNotNull(resp.data.get('masterAcc'), 'Response data should contain master account');
            Assert.isNotNull(resp.data.get('opportunity'), 'Response data should contain opportunity');
        }
    }

    @isTest
    static void testTransformPreparedDataWOTargetIds() {
        PODataCollector.QuoteBasedDC dC = (PODataCollector.QuoteBasedDC) new PODataCollector.QuoteBasedDC(new Set<Id>()).collectData();
        dC.prepareData();

        Test.startTest();
            List<Response> responseList = dC.transformPreparedData();
        Test.stopTest();

        Assert.isTrue(responseList.isEmpty(), 'Response list should be empty');
    }
}