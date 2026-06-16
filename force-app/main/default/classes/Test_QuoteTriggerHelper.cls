@isTest
private class Test_QuoteTriggerHelper {
    private static final String TEST_STRING = 'TestString';
    private static final String PACKAGE_INFO_WITH_CONTRACT =
        '[{"id":"18","contract":{"id":"a8f0S0000008cxHQAQ","extId":"nib","billingId":"2"}}]';

    @TestSetup
    static void testSetup() {
        new SObjectBuilder(LeadConversionConfiguration__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                LeadConversionConfiguration__c.Name => ValueProviderBuilder.provideList(
                    new List<String> {OpportunityHelper.BRAND_RINGCENTRAL, RingCentralHelper.BRAND_VODAFONE}
                ),
                LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => ValueProviderBuilder.provideList(
                    new List<Boolean> {true, false}
                ),
                LeadConversionConfiguration__c.IsQuotingAvailableExistingBusiness__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {true, false}
                )
            }
        )
        .quantity(2)
        .create();
    }


    @isTest static void testProServQuoteAddressPopulationFromAccount() {
        Test.startTest();
        Account testAcc = new Account(Name = 'testAcc',
                                      BillingStreet='443 Kearney Frontage',
                                      BillingCity='Fresno',
                                      BillingState='CA',
                                      BillingPostalCode='93706',
                                      BillingCountry='United States');
        insert testAcc;

        Opportunity testOpp = new Opportunity(Name = 'testOpp',
                                              AccountId = testAcc.Id,
                                              Type = 'Existing Business',
                                              Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
                                              Tier_Name__c = 'Office',
                                              StageName = '1. Qualify',
                                              CloseDate = System.today(),
                                              CurrencyIsoCode = 'USD');
        insert testOpp;

        Quote testQuote = new Quote(Name = 'testQuote',
                                    OpportunityId = testOpp.Id,
                                    RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert testQuote;

        Quote checkQuote = [SELECT Address_Line__c, City__c, State__c, Postal_Code__c, Country__c
                            FROM Quote WHERE Id = :testQuote.Id];

        System.assertEquals(checkQuote.Address_Line__c, testAcc.BillingStreet);
        System.assertEquals(checkQuote.City__c, testAcc.BillingCity);
        System.assertEquals(checkQuote.State__c, testAcc.BillingState);
        System.assertEquals(checkQuote.Postal_Code__c, testAcc.BillingPostalCode);
        System.assertEquals(checkQuote.Country__c, testAcc.BillingCountry);

        Test.stopTest();
    }

    @isTest
    static void testUpdateAccStaticMapOnQuoteTriggerHelperOnInsertUpdate() {

        Test.startTest();
        Account testAcc = new Account(Name = 'testAcc',
                                      BillingStreet='443 Kearney Frontage',
                                      BillingCity='Fresno',
                                      BillingState='CA',
                                      BillingPostalCode='93706',
                                      BillingCountry='United States');
        insert testAcc;

        Opportunity testOpp = new Opportunity(Name = 'testOpp',
                                              AccountId = testAcc.Id,
                                              Type = 'Existing Business',
                                              Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
                                              Tier_Name__c = 'Office',
                                              StageName = '1. Qualify',
                                              CloseDate = System.today(),
                                              CurrencyIsoCode = 'USD');
        insert testOpp;

        Quote testQuote = new Quote(Name = 'testQuote',
                                    OpportunityId = testOpp.Id,
                                    RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert testQuote;

        QuoteTriggerHelper.opportunityMapStatic.put(testOpp.Id, testOpp);

        QuoteTriggerHelper.updateAccStaticMapOnQuoteTriggerHelper(true, new List<Quote>{testQuote});

        System.assertEquals(1, QuoteTriggerHelper.accountMapStatic.size());
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccStaticMapOnQuoteTriggerHelperOnDelete() {

        Test.startTest();
        Account testAcc = new Account(Name = 'testAcc',
                                      BillingStreet='443 Kearney Frontage',
                                      BillingCity='Fresno',
                                      BillingState='CA',
                                      BillingPostalCode='93706',
                                      BillingCountry='United States');
        insert testAcc;

        Opportunity testOpp = new Opportunity(Name = 'testOpp',
                                              AccountId = testAcc.Id,
                                              Type = 'Existing Business',
                                              Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
                                              Tier_Name__c = 'Office',
                                              StageName = '1. Qualify',
                                              CloseDate = System.today(),
                                              CurrencyIsoCode = 'USD');
        insert testOpp;

        Quote testQuote = new Quote(Name = 'testQuote',
                                    OpportunityId = testOpp.Id,
                                    RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert testQuote;
        QuoteTriggerHelper.accountMapStatic.put(testAcc.Id, testAcc);

        QuoteTriggerHelper.updateAccStaticMapOnQuoteTriggerHelper(false, new List<Quote>{testQuote});
        Test.stopTest();

        System.assertEquals(0, QuoteTriggerHelper.accountMapStatic.size());
    }

    @isTest
    static void testUpdatingSOWTypeShouldNotChangeProservStatus() {

        Account testAcc = new Account(
            Name = 'testAcc',
            BillingStreet = '443 Kearney Frontage',
            BillingCity = 'Fresno',
            BillingState = 'CA',
            BillingPostalCode = '93706',
            BillingCountry = 'United States'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Type = 'Existing Business',
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Quote testQuote = new Quote(
            Name = 'testQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            ProServ_Status__c = 'Synced'
        );
        insert testQuote;

        Test.startTest();

            testQuote.SOW_Type__c = 'Single Phase';
            update testQuote;

            Quote reselectedTestQuote = [select Id, ProServ_Status__c from Quote where Id = :testQuote.Id];

            System.assertEquals(reselectedTestQuote.ProServ_Status__c, testQuote.ProServ_Status__c);

        Test.stopTest();
    }

    @isTest
    private static void testUpdateRelatedQuotePhase() {
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'testTestOppty',
                    User.Username => 'TestOppty!user@gmail.com',
                    User.Email => 'TestOppty@gmail.com',
                    User.Alias => 'test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.Current_Owner__c => us.Id,
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
            DateTime dateNow = System.now();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.ProServSalesRep__c => us.Id
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV,
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();
        Test.startTest();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true);
        Phase__c phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'testPhase_1',
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => acc.Id,
                    Phase__c.Opportunity__c => oppty.Id,
                    Phase__c.Quote__c => q.Id,
                    Phase__c.Order__c => ord.Id,
                    Phase__c.Initial_Payment__c => 10,
                    Phase__c.Phase_Number__c => 1
                }
            )
            .create()
            .getRecord();
        q.ProServSalesRep__c = us.Id;


            update q;
        Test.stopTest();

        phase = [SELECT MavenlinkIntegrationStatus__c
                FROM Phase__c
                WHERE Quote__c = :q.Id
                LIMIT 1];

        System.assert(!phase.MavenlinkIntegrationStatus__c.containsIgnoreCase('ProServ Architect'),
                        'ProServ Architect field on the Phase was updated incorrectly.');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testApproveBillingQuoteWithContactCenter() {
        Account testAcc = new Account(
            Name = 'testAcc'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            StageName = '1. Qualify',
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            CloseDate = System.today()
        );
        insert testOpp;

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'Annual'
        );
        insert testPriceBook;

        List<Quote> qtList = new List<Quote>();

        Quote testBillingQuote = new Quote(
            Name = 'testBillingQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Pricebook2Id = testPriceBook.Id,
            Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED
        );
        qtList.add(testBillingQuote);

        Quote testContactCenterQuote = new Quote(
            Name = 'testContactCenterQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_CC,
            Pricebook2Id = testPriceBook.Id,
            Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED
        );
        qtList.add(testContactCenterQuote);
        insert qtList;

        // approve billing quote
        Test.startTest();
            testBillingQuote.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            update testBillingQuote;
        Test.stopTest();

        // verify that Contact Center Quote become Approved
        List<Quote> reselectedQuotes = [select Id, Name, Approved_Status__c from Quote where Id in: new Set<Id>{testContactCenterQuote.Id}];
        for(Quote qt : reselectedQuotes) {
            //System.assertEquals(QuoteHelper.APPROVAL_STATUS_APPROVED, qt.Approved_Status__c);
        }
    }
    @isTest
    private static void testCaseCreationForCCProServQuotes(){
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Product2 p2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                            Product2.Name => 'Connect Pro - Annual Fee',
                            Product2.IsActive => true,
                            Product2.GOA_Group__c => 'DEVICES_B_STOCK',
                            Product2.Family => 'RingCentral'
                    }
            )
            .create()
            .getRecord();

        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.Name => 'Test Opportunity 2016',
                        Opportunity.Type => 'Syndicated - New',
                        Opportunity.StageName => 'Planning',
                        Opportunity.CloseDate => system.today().addMonths(1),
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Primary_Opportunity_Contact__c => contact.Id
                    }
                )
                .create()
                .getRecord();
        Quote ccPsQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            ccPsQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
            update ccPsQuote;
        Test.stopTest();

        Id accId = acc.id;

        System.assertEquals(2, [SELECT count()
                                FROM Case],
                                '2 Cases should be added when a CC proserv Quote is Marked as sold');
    }

    @isTest
    static void testPaymentPlanPopulation() {
        Account testAcc = new Account(
            Name = 'testAcc'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'Annual'
        );
        Pricebook2 testPriceBook2 = new Pricebook2(
            Name = 'Test Price Book 2',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'TEST'
        );
        insert new List<Pricebook2> { testPriceBook, testPriceBook2 };

        List<Quote> qtList = new List<Quote>();

        Quote testBillingQuote = new Quote(
            Name = 'testBillingQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Pricebook2Id = testPriceBook2.Id,
            Package_Info__c = '[{"duration":"Monthly"}]'
        );
        qtList.add(testBillingQuote);

        Quote testSalesQuote = new Quote(
            Name = 'testSalesQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = testPriceBook.Id
        );
        qtList.add(testSalesQuote);
        insert qtList;

        Map<id, Quote> quotes = new Map<id, Quote>([SELECT Id, Payment_Plan__c, Payment_Period__c FROM Quote]);
        Quote resultSalesQuote = quotes.get(testSalesQuote.Id);
        Quote resultBillingQuote = quotes.get(testBillingQuote.Id);

        System.assertEquals(QuoteHelper.ANNUAL_PAYMENT_METHOD, resultSalesQuote.Payment_Period__c);
        System.assertEquals('Annual', resultSalesQuote.Payment_Plan__c);

        System.assertEquals(QuoteHelper.MONTHLY_PAYMENT_METHOD, resultBillingQuote.Payment_Period__c);
        System.assertEquals('Monthly', resultBillingQuote.Payment_Plan__c);
    }

    @isTest
    static void testServiceEntitlementPopulation() {
        Account testAcc = new Account(
            Name = 'testAcc'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;

        Product2 testProd = new Product2(
            Name = 'testServiceProd',
            Family = Product2Helper.FAMILY_SERVICE,
            Feature__c = Product2Helper.FEATURE_SERVICE_PLAN,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );

        insert testProd;

        Entitlement__c testEntitlement = new Entitlement__c(
            Account__c = testAcc.Id,
            Product__c = testProd.Id,
            Active__c = true
        );

        insert testEntitlement;

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'Annual'
        );
        Pricebook2 testPriceBook2 = new Pricebook2(
            Name = 'Test Price Book 2',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'TEST'
        );
        insert new List<Pricebook2> { testPriceBook, testPriceBook2 };

        List<Quote> qtList = new List<Quote>();

        Quote testBillingQuote = new Quote(
            Name = 'testBillingQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Pricebook2Id = testPriceBook2.Id,
            Package_Info__c = '[{"duration":"Monthly"}]'
        );
        qtList.add(testBillingQuote);

        Quote testSalesQuote = new Quote(
            Name = 'testSalesQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Pricebook2Id = testPriceBook.Id
        );
        qtList.add(testSalesQuote);
        Test.startTest();
        insert qtList;
        Test.stopTest();

        Map<id, Quote> quotes = new Map<id, Quote>([SELECT Id, CurrentService__c FROM Quote]);
        Quote resultSalesQuote = quotes.get(testSalesQuote.Id);
        Quote resultBillingQuote = quotes.get(testBillingQuote.Id);

        System.assertEquals(testEntitlement.Id, resultSalesQuote.CurrentService__c);
        System.assertEquals(null, resultBillingQuote.CurrentService__c);
    }

    @isTest
    static void testDeleteRelatedEntitlements() {
        Account testAcc = new Account(
            Name = 'testAcc'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;

        Product2 testProd = new Product2(
            Name = 'testServiceProd',
            Family = Product2Helper.FAMILY_SERVICE,
            Feature__c = Product2Helper.FEATURE_SERVICE_PLAN,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY
        );

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'Annual'
        );

        Pricebook2 testPriceBook2 = new Pricebook2(
            Name = 'Test Price Book 2',
            Description ='Test Price Book Products',
            IsActive = true,
            CurrencyIsoCode = 'USD',
            Plan__c = 'TEST'
        );
        insert new List<Pricebook2> { testPriceBook, testPriceBook2 };

        insert testProd;
        Quote testBillingQuote = new Quote(
            Name = 'testBillingQuote',
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Pricebook2Id = testPriceBook2.Id,
            Package_Info__c = '[{"duration":"Monthly"}]'
        );
        insert testBillingQuote;

        Entitlement__c testEntitlement = new Entitlement__c(
            Account__c = testAcc.Id,
            Product__c = testProd.Id,
            Active__c = true,
            Quote__c = testBillingQuote.Id
        );

        insert testEntitlement;

        delete testBillingQuote;
        List<Entitlement__c> entsToDelete = [SELECT Id FROM Entitlement__c];

        System.assertEquals(0, entsToDelete.size());
    }

    @isTest
    private static void testUpdateApprovalAfterQuoteActivation() {

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.IsActive, true)
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Family, Product2Helper.FAMILY_SERVICE)
            .setField(Product2.Charge_Term__c, null)
            .create()
            .getRecord();

        PricebookEntry testPricebookentryStandard = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPriceBookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 0)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        PricebookEntry testPricebookentry = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, testPriceBook.Id)
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.provideUniqueNumber(1))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideGenericParent(Opportunity.SobjectType))
            .setField(Quote.Start_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.End_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_AGREEMENT)
            .setField(Quote.PriceBook2Id, testPriceBook.Id)
            .create()
            .getRecord();

        Test.startTest();

            QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setField(QuoteLineItem.Product2Id, testProduct.Id)
                .setField(QuoteLineItem.QuoteId, testQuote.Id)
                .setField(QuoteLineItem.PricebookEntryId, testPricebookentry.Id)
                .setField(QuoteLineItem.Quantity, 1)
                .setField(QuoteLineItem.Zero_Quantity__c, false)
                .setField(QuoteLineItem.UnitPrice, testPricebookentry.UnitPrice)
                .create()
                .getRecord();
            Approval__c testEngageLegalApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
                .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_ENGAGE_LEGAL)
                .setField(Approval__c.Quote__c, testQuote.Id)
                .setField(Approval__c.Account__c, testQuote.AccountId)
                .create()
                .getRecord();

            testQuote.Status = QuoteHelper.QUOTE_STATUS_ACTIVE;
            update testQuote;

            Approval__c reselectedApproval = [SELECT Id, Contracted_Montlhy_DL_Price__c
                                              FROM Approval__c
                                              WHERE Id = :testEngageLegalApproval.Id
                                              LIMIT 1];

            QuoteLineItem reselectedQLI = [SELECT Id, EffectivePrice__c
                                           FROM QuoteLineItem
                                           WHERE Id = :testQLI.Id
                                           LIMIT 1];
        Test.stopTest();

        System.assertEquals(
            reselectedQLI.EffectivePrice__c,
            reselectedApproval.Contracted_Montlhy_DL_Price__c,
            'Contracted_Montlhy_DL_Price__c copied incorreclty '
            + 'from Service QLI.EffectivePrice__c when Quote Status is changed to '
            + 'Active Agreement');
    }

    @isTest
    private static void verifyQuoteTriggerCreatesDefaultQLIsOnQuoteInsert() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
                }
            )
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                    PriceBook2.IsActive => true
                }
            )
            .create()
            .getRecord();

        Product2 serviceProd = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Family => Product2Helper.FAMILY_SERVICE,
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                    Product2.Description => ValueProviderBuilder.provideUniqueString()
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                        new List<Object> {
                            Test.getStandardPricebookId(),
                            pb.Id
                        }
                    ),
                    PricebookEntry.Product2Id => serviceProd.Id,
                    PricebookEntry.UnitPrice => ValueProviderBuilder.provideUniqueNumber(),
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                })
            .create();

        Test.startTest();
            Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Quote.Pricebook2Id => pb.Id,
                        Quote.OpportunityId => opp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<QuoteLineItem> qlis = [
            SELECT Id, QuoteId, Product2Id
            FROM QuoteLineItem
        ];

        System.assert(!qlis.isEmpty(), 'Default QLIs weren\'t added');

        System.assertEquals(serviceProd.Id, qlis[0].Product2Id, 'Default QLI doesn\'t use provided default product');

        System.assertEquals(q.Id, qlis[0].QuoteId, 'Created QLIs aren\'t related to Quote from test');
    }

    @isTest
    private static void testTotalNumberOfDLForBillingQuote() {

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => -5000,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        QuoteSelector quoteSelector = new QuoteSelector();
        List<Quote> quoteList = (List<Quote>) quoteSelector
            .selectQuotes()
            .selectField(Quote.Total_Number_of_Digital_Lines__c)
            .setCondition('Id = \'' + testBillingQuote.Id + '\'')
            .setLimit(1)
            .executeQuery();

        Quote reselectedQuote = quoteList.get(0);

        System.assertEquals(
            0,
            reselectedQuote.Total_Number_of_Digital_Lines__c,
            'if Pricebook2.Line_Range_Min__c has negative value - Quote.Total_Number_of_Digital_Lines__c ' +
            'should be populated with 0'
        );

        Decimal quoteLineItemQuantity = 7;

        Triggers.switchOff();
        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => testBillingQuote.Id,
                QuoteLineItem.Quantity => quoteLineItemQuantity,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Discount_Number__c => 10,
                QuoteLineItem.UnitPrice => 200
            })
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.startTest();

            // clear Total_Number_of_Digital_Lines__c and verify that is populated from 'service product' quantity
            reselectedQuote.Total_Number_of_Digital_Lines__c = null;
            update reselectedQuote;

            quoteList = (List<Quote>) quoteSelector
                .selectQuotes()
                .selectField(Quote.Total_Number_of_Digital_Lines__c)
                .setCondition('Id = \'' + testBillingQuote.Id + '\'')
                .setLimit(1)
                .executeQuery();

            reselectedQuote = quoteList.get(0);

            System.assertEquals(
                quoteLineItemQuantity,
                reselectedQuote.Total_Number_of_Digital_Lines__c,
                'Quote.Total_Number_of_Digital_Lines__c should be populatede from "service product" quantity'
            );

        Test.stopTest();
    }

    @isTest
    static void testSetTotalNumberOfDLMethodWithoutData() {

        QuoteTriggerHelper.SetDefaultLineItems handlerInstance = new QuoteTriggerHelper.SetDefaultLineItems();

        System.assertEquals(
            null,
            handlerInstance.setTotalNumberOfDL(null, null, null, null),
            'method should return null if all passed params is null'
        );

        Quote updatedQuote = handlerInstance.setTotalNumberOfDL(
            new Quote(),
            new Map<Id, List<QuoteLineItem>>(),
            null,
            null
        );

        System.assertEquals(
            0,
            updatedQuote.Total_Number_of_Digital_Lines__c,
            'method should populate Quote.Total_Number_of_Digital_Lines__c with 0'
        );

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .build()
            .getRecord();

        Boolean isUpdate = false;
        Decimal lineRangeMin = 10;
        updatedQuote = handlerInstance.setTotalNumberOfDL(
            testBillingQuote,
            new Map<Id, List<QuoteLineItem>>(),
            lineRangeMin,
            isUpdate
        );

        System.assertEquals(
            lineRangeMin,
            updatedQuote.Total_Number_of_Digital_Lines__c,
            'method should populate Quote.Total_Number_of_Digital_Lines__c with number passed as second parameter'
        );

        isUpdate = true;
        updatedQuote = handlerInstance.setTotalNumberOfDL(
            testBillingQuote,
            new Map<Id, List<QuoteLineItem>>(),
            lineRangeMin,
            isUpdate
        );

        System.assertEquals(
            0,
            updatedQuote.Total_Number_of_Digital_Lines__c,
            'method should populate Quote.Total_Number_of_Digital_Lines__c with 0 ' +
            'if Quote has no QuoteLineItems and this is update quote case'
        );
    }

    @isTest
    static void testSetTotalNumberOfDLMethodWithData() {

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testServiceProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Test.startTest();

            Decimal serviceProductQuantity = 3;

            List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                    QuoteLineItem.QuoteId => testBillingQuote.Id,
                    QuoteLineItem.Quantity => serviceProductQuantity,
                    QuoteLineItem.UnitPrice => 200
                })
                .create()
                .getRecords();

            List<QuoteLineItem> reselectedQliList = new QuoteLineItemSelector()
                .selectServiceQlisByQuoteIds(new Set<Id>{ testBillingQuote.Id })
                .executeQuery();

            Map<Id, List<QuoteLineItem>> quoteIdToQliListMap = new Map<Id, List<QuoteLineItem>>{
                testBillingQuote.Id => reselectedQliList
            };

            QuoteTriggerHelper.SetDefaultLineItems handlerInstance = new QuoteTriggerHelper.SetDefaultLineItems();

            Boolean isUpdate = false;
            Decimal lineRangeMin = 10;
            Quote updatedQuote = handlerInstance.setTotalNumberOfDL(testBillingQuote, quoteIdToQliListMap, lineRangeMin, isUpdate);

            System.assertEquals(
                lineRangeMin,
                updatedQuote.Total_Number_of_Digital_Lines__c,
                'method should populate Quote.Total_Number_of_Digital_Lines__c with number passed as second parameter'
            );

            isUpdate = true;
            updatedQuote = handlerInstance.setTotalNumberOfDL(testBillingQuote, quoteIdToQliListMap, lineRangeMin, isUpdate);

            System.assertEquals(
                serviceProductQuantity,
                updatedQuote.Total_Number_of_Digital_Lines__c,
                'method should populate Quote.Total_Number_of_Digital_Lines__c with Quantity of "Sevice product" '
            );

        Test.stopTest();
    }

    @isTest
    static void testValidateRenewalTerms() {

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .create()
            .getRecord();

        Test.startTest();

        try {
            billingQuote.Auto_Renewal__c = true;
            billingQuote.Term_months__c = null;
            update billingQuote;

            System.assert(
                false,
                'Billing Quote should not pass validation'
            );
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().containsIgnoreCase('Please specify the correct Renewal Term'),
                'Quote validation passed incorrectly'
            );
        }

        Test.stopTest();
    }

    @isTest
    static void verifyThatPocQuoteUpdatedWithDraftStatus() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testOpp',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => 'Existing Business',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        testQuote.Status = QuoteHelper.QUOTE_STATUS_ACTIVE;
        update testQuote;
        Test.stopTest();

        QuoteSelector quoteSelector = new QuoteSelector();
        List<Object> binds = new List<Object>();
        binds.add(testQuote.Id);
        List<Quote> selectedQuotes = (List<Quote>) quoteSelector.selectQuoteById(binds).executeQuery();

        System.assertEquals(QuoteHelper.QUOTE_STATUS_DRAFT, selectedQuotes[0].Status, 'POC Quote should be created in Draft status');
    }

    @isTest
    static void verifyThatPocQuoteInsertWithPrimaryAttribute() {

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'United States'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testOpp',
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Type => 'Existing Business',
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                }
            )
            .build()
            .getRecord();

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                }
            )
            .build()
            .getRecord();

        insert new List<Quote>{billingQuote, proServQuote};

        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
                }
            )
            .build()
            .getRecord();

        Test.startTest();
        insert pocQuote;
        Test.stopTest();

        QuoteSelector quoteSelector = new QuoteSelector();
        List<Object> binds = new List<Object>();
        binds.add(pocQuote.Id);
        List<Quote> selectedQuotes = (List<Quote>) quoteSelector.selectQuoteById(binds).executeQuery();

        System.assert(
            selectedQuotes[0].isPrimary__c,
            'POC Quote should be created as Primary'
        );
    }

    @isTest
    static void testPopulatedApprovedFieldsOnQLI() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c, true)
            .create();

        final String newBusinessQuoteName = 'New Business Quote';
        final String existingBusinessQuoteName = 'Existing Business quote';

        List<Account> testAccounts = (List<Account>) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString('Test account'),
                Account.RC_User_ID__c => ValueProviderBuilder.provideList(new List<String>{null, '12345'}),
                Account.Billing_ID__c => ValueProviderBuilder.provideList(new List<String>{null, '54321'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Package__c> pkgs = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => ValueProviderBuilder.provideParents(testAccounts),
                Package__c.Account_Package_Id__c => ValueProviderBuilder.provideUniqueString('AccPkgId')
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Opportunity> testOpps = (List<Opportunity>) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideParents(testAccounts),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideList(new List<String>{
                    newBusinessQuoteName, existingBusinessQuoteName
                }),
                Quote.OpportunityId => ValueProviderBuilder.provideParents(testOpps),
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPricebookId(),
                Quote.BillingPackage__c => ValueProviderBuilder.provideParents(pkgs),
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED
            })
            .quantity(2)
            .create()
            .getRecords();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString(),
                    Product2.Family => Product2Helper.FAMILY_PHONE,
                    Product2.Charge_Term__c => null
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPricebookentry = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => ValueProviderBuilder.provideUniqueNumber(1),
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 4
            })
            .create()
            .getRecord();
        Triggers.switchOff();
        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideParents(testQuotes),
                QuoteLineItem.PricebookEntryId => testPricebookentry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => testPricebookentry.UnitPrice,
                QuoteLineItem.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();
        Quote newBusinessQuote;
        Quote existingBusinessQuote;
        for (Quote qt : testQuotes) {
            qt.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_APPROVED;
            if (qt.Name == newBusinessQuoteName) {
                newBusinessQuote = qt;
            } else if (qt.Name == existingBusinessQuoteName) {
                existingBusinessQuote = qt;
            }
        }
        update testQuotes;

        List<QuoteLineItem> selectedQLIs = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(new Set<Id> {newBusinessQuote.Id, existingBusinessQuote.Id})
            .executeQuery();

        Test.stopTest();

        QuoteLineItem newBusinessQli;
        QuoteLineItem existingBusinessQli;
        for (QuoteLineItem qli : selectedQLIs) {
            if (qli.QuoteId == newBusinessQuote.Id) {
                newBusinessQli = qli;
            } else if (qli.QuoteId == existingBusinessQuote.Id) {
                existingBusinessQli = qli;
            }
        }

        System.assertNotEquals(null, existingBusinessQli.Approved_Discount__c, 'Approved fields should be populated when Approved Status is Approved on quote');
        System.assertEquals(0, existingBusinessQli.Approved_Discount__c, 'Approved fields should be populated when Approved Status is Approved on quote');
        System.assertNotEquals(null, existingBusinessQli.Approved_Discount_Type__c, 'Approved fields should be populated when Approved Status is Approved on quote');
        System.assertNotEquals(null, existingBusinessQli.Last_Approved_Quantity__c, 'Approved fields should be populated when Approved Status is Approved on quote');
        System.assertNotEquals(null, existingBusinessQli.Last_Approved_Discount__c, 'Approved fields should be populated when Approved Status is Approved on quote');
        System.assertEquals(0, existingBusinessQli.Last_Approved_Discount__c, 'Approved fields should be populated when Approved Status is Approved on quote');

        System.assertEquals(null, newBusinessQli.Approved_Discount__c, 'Approved fields should be populated for existing business quotes when EnableTPAndDQBasedGOAInQT__c is enabled');
        System.assertEquals(null, newBusinessQli.Approved_Discount_Type__c, 'Approved fields should be populated for existing business quotes when EnableTPAndDQBasedGOAInQT__c is enabled');
        System.assertEquals(null, newBusinessQli.Last_Approved_Quantity__c, 'Approved fields should be populated for existing business quotes when EnableTPAndDQBasedGOAInQT__c is enabled');
        System.assertEquals(null, newBusinessQli.Last_Approved_Discount__c, 'Approved fields should be populated for existing business quotes when EnableTPAndDQBasedGOAInQT__c is enabled');
    }

    @isTest
    static void testFreeValuesCalculation() {

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Feature_Toggle__c testFeatureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.CalculateFSCInQW__c => true
            })
            .create()
            .getRecord();

        Test.startTest();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Package_Info__c => PACKAGE_INFO_WITH_CONTRACT
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString(),
                    Product2.Family => Product2Helper.FAMILY_PHONE,
                    Product2.Charge_Term__c => 'Monthly'
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPricebookentry = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => ValueProviderBuilder.provideUniqueNumber(1),
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 4
            })
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id  => testProduct.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => testPricebookentry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => testPricebookentry.UnitPrice
            })
            .create()
            .getRecord();

        testQuote.Special_Terms__c = QuoteHelper.FREE_MONTH_1;
        update testQuote;

        Quote selectedQuotes = (Quote) new QuoteSelector().selectQuoteForSignUp(testQuote.Id).executeQuery().get(0);

        Test.stopTest();

        System.assertEquals(null, selectedQuotes.Free_Service_Taxes__c, 'Free Service Taxes populated if Special Terms was not filled on Quote');
        System.assertEquals(null, selectedQuotes.Credit_Amount__c, 'Credit Amount populated if Special Terms was not filled on Quote');
    }

    @isTest
    private static void testPopulatePrimaryQuoteOnOpportunity() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Test.startTest();

            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.isPrimary__c => true
                })
                .create()
                .getRecord();

            Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
                .selectOpportunities()
                .selectFields(
                    new Set<SObjectField>{
                        Opportunity.PrimaryQuote__c
                    }
                )
                .setCondition('Id = :bind0')
                .setQueryBindings(new List<Object>{ opp.Id })
                .executeQuery()
                .get(0);

            System.assertEquals(
                qt.Id,
                reselectedOpp.PrimaryQuote__c,
                'Opportunity.PrimaryQuote__c should be populated with Id of Primary Quote'
            );

        Test.stopTest();
    }

    @isTest
    private static void testPopulatePrimaryQuoteOnUpdate() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{true, false, false}
                )
            })
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();

            // make another quote primary
            Quote oldPrimaryQuote = quotes.get(0);
            oldPrimaryQuote.isPrimary__c = false;

            Quote newPrimaryQuote = quotes.get(1);
            newPrimaryQuote.isPrimary__c = true;

            update new List<Quote>{oldPrimaryQuote, newPrimaryQuote};

        Test.stopTest();

        Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.PrimaryQuote__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ opp.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            newPrimaryQuote.Id,
            reselectedOpp.PrimaryQuote__c,
            'Opportunity.PrimaryQuote__c should be populated with Id of Primary Quote'
        );
    }

    @isTest
    private static void testPopulateCCProServQuoteOnInsert() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV
            })
            .create()
            .getRecords();

        Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.CC_ProServ_Quote__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ opp.Id })
            .executeQuery()
            .get(0);

        System.assertEquals(
            quotes[0].Id,
            reselectedOpp.CC_ProServ_Quote__c
        );
    }

    @isTest
    private static void testPopulateCCProServQuoteOnUpdate() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV
            })
            .create()
            .getRecords();

        Test.startTest();
            quotes[0].ProServ_Status__c = 'Cancelled';
            update quotes;
        Test.stopTest();

        Opportunity reselectedOpp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectFields(
                new Set<SObjectField>{
                    Opportunity.CC_ProServ_Quote__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ opp.Id })
            .executeQuery()
            .get(0);


        System.assertEquals(
            null,
            reselectedOpp.CC_ProServ_Quote__c
        );
    }

    @isTest
    static void testRenewalTermIsReseted_testUpdate() {
        Triggers.switchOff();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Auto_Renewal__c => true,
                Quote.Term_months__c => '12'
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            testQuote.Auto_Renewal__c = false;
            update testQuote;

        Test.stopTest();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuoteById(new List<Object>{testQuote.Id})
            .withoutSelectorFieldsIncluded()
            .selectField(Quote.Id)
            .selectField(Quote.Term_months__c)
            .executeQuery();

        System.assertEquals(1, reselectedQuotes.size());
        System.assertEquals(testQuote.Id, reselectedQuotes[0].Id);
        System.assertEquals(null, reselectedQuotes[0].Term_months__c);
    }

    @isTest
    static void testSalesAgreementExtensionSet_testUpdate() {
        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Previous_Sales_Agreement_End_Date__c, System.today())
            .create()
            .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            testQuote.End_Date__c  = System.today().addYears(1);
            update testQuote;

        Test.stopTest();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuoteById(new List<Object>{testQuote.Id})
            .withoutSelectorFieldsIncluded()
            .selectField(Quote.Id)
            .selectField(Quote.isSalesAgreementExtension__c)
            .executeQuery();

        System.assertEquals(1, reselectedQuotes.size());
        System.assertEquals(testQuote.Id, reselectedQuotes[0].Id);
        System.assertEquals(true, reselectedQuotes[0].isSalesAgreementExtension__c);
    }

    @isTest
    static void testQuotingIsDisabled_newBusiness_testInsert() {
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

            try {
                Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        Quote.Name => ValueProviderBuilder.provideUniqueString(),
                        Quote.OpportunityId => testOpp.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.IsPrimary__c => true,
                        Quote.PriceBook2Id => Test.getStandardPriceBookId()
                    })
                    .create()
                    .getRecord();
            } catch (DmlException e) {
                System.assertEquals(
                    'Quoting is not available for current brand.',
                    e.getDmlMessage(0),
                    'Wrong DML Exception caught');
                Test.stopTest();
                return;
            }

        Test.stopTest();

        System.assert(false, 'Test should throw DML Exception for ' + RingCentralHelper.BRAND_VODAFONE + ' brand');
    }

    @isTest
    static void testQuotingIsDisabled_existingBusiness_testInsert() {
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .create()
                .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                })
                .create()
                .getRecord();
        Triggers.switchOn();

        Test.startTest();

        try {
            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            Quote.Name => ValueProviderBuilder.provideUniqueString(),
                            Quote.OpportunityId => testOpp.Id,
                            Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                            Quote.IsPrimary__c => true,
                            Quote.PriceBook2Id => Test.getStandardPriceBookId()
                    })
                    .create()
                    .getRecord();
        } catch (DmlException e) {
            System.assertEquals(
                    'Quoting is not available for current brand.',
                    e.getDmlMessage(0),
                    'Wrong DML Exception caught');
            Test.stopTest();
            return;
        }

        Test.stopTest();

        System.assert(false, 'Test should throw DML Exception for ' + RingCentralHelper.BRAND_VODAFONE + ' brand');
    }

    @isTest
    static void testQuotingIsDisabled_newBusiness_testUpdate() {
        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Opportunity testOppQuotingOff = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            try {
                // Change Quote's opp to the one having brand with disabled quoting
                testQuote.OpportunityId = testOppQuotingOff.Id;
                update testQuote;
            } catch (DmlException e) {
                System.assertEquals(
                    'Quoting is not available for current brand.',
                    e.getDmlMessage(0),
                    'Wrong DML Exception caught');
                Test.stopTest();
                return;
            }

        Test.stopTest();

        System.assert(false, 'Test should throw DML Exception for ' + RingCentralHelper.BRAND_VODAFONE + ' brand');
    }

    @isTest
    static void testQuotingIsDisabled_existingBusiness_testUpdate() {
        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .create()
                .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => RingCentralHelper.USD
                })
                .create()
                .getRecord();

        Opportunity testOppQuotingOff = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE,
                        Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                        Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
                })
                .create()
                .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Quote.Name => ValueProviderBuilder.provideUniqueString(),
                        Quote.OpportunityId => testOppQuotingOn.Id,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.IsPrimary__c => true,
                        Quote.PriceBook2Id => Test.getStandardPriceBookId()
                })
                .create()
                .getRecord();

        Triggers.switchOn();

        Test.startTest();

        try {
            // Change Quote's opp to the one having brand with disabled quoting
            testQuote.OpportunityId = testOppQuotingOff.Id;
            update testQuote;
        } catch (DmlException e) {
            System.assertEquals(
                    'Quoting is not available for current brand.',
                    e.getDmlMessage(0),
                    'Wrong DML Exception caught');
            Test.stopTest();
            return;
        }

        Test.stopTest();

        System.assert(false, 'Test should throw DML Exception for ' + RingCentralHelper.BRAND_VODAFONE + ' brand');
    }

    @isTest
    static void testQuotingIsEnabled_newBusiness_testInsert() {
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.IsPrimary__c => true,
                    Quote.PriceBook2Id => Test.getStandardPriceBookId()
                })
                .create()
                .getRecord();

        Test.stopTest();

        System.assert(testQuote != null, 'Should insert new quote');
    }
    @isTest
    static void testQuotingIsEnabled_existingBusiness_testInsert() {
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();

            Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.IsPrimary__c => true,
                    Quote.PriceBook2Id => Test.getStandardPriceBookId()
                })
                .create()
                .getRecord();

        Test.stopTest();

        System.assert(testQuote != null, 'Should insert new quote');
    }

    @isTest
    static void testQuotingIsEnabled_newBusiness_testUpdate() {
        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            testQuote.Name = 'updated name';
            update testQuote;

        Test.stopTest();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuoteById(new List<Object>{testQuote.Id})
            .withoutSelectorFieldsIncluded()
            .selectField(Quote.Id)
            .selectField(Quote.Name)
            .executeQuery();

        System.assertEquals(1, reselectedQuotes.size());
        System.assertEquals(testQuote.Id, reselectedQuotes[0].Id);
        System.assertEquals('updated name', reselectedQuotes[0].Name);
    }

    @isTest
    static void testQuotingIsEnabled_existingBusiness_testUpdate() {
        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            testQuote.Name = 'updated name';
            update testQuote;

        Test.stopTest();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuoteById(new List<Object>{testQuote.Id})
            .withoutSelectorFieldsIncluded()
            .selectField(Quote.Id)
            .selectField(Quote.Name)
            .executeQuery();

        System.assertEquals(1, reselectedQuotes.size());
        System.assertEquals(testQuote.Id, reselectedQuotes[0].Id);
        System.assertEquals('updated name', reselectedQuotes[0].Name);
    }

    @IsTest
    static void test_UpdateParentOpportunityOnOpportunity() {
        Triggers.switchOff();

        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Account childAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, masterAccount.Id)
            .create()
            .getRecord();

        List<AccountContactRole> contactRoles = (List<AccountContactRole>) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        masterAccount.Id, childAccount.Id
                    }),
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY,
                    AccountContactRole.IsPrimary => true
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Opportunity masterOpty = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => masterAccount.Id,
                Opportunity.Name => 'New Business Oppty',
                Opportunity.Type => 'New Business',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Opportunity childOpty = (Opportunity) new SOBjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => childAccount.Id,
                Opportunity.Name => 'New Business Oppty',
                Opportunity.Type => 'New Business',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => new ValueProvider.UniqueStringProvider('quoteName'),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                    Quote.OpportunityId => masterOpty.Id,
                    Quote.PriceBook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Quote childQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => new ValueProvider.UniqueStringProvider('quoteName'),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                    Quote.OpportunityId => childOpty.Id,
                    Quote.PriceBook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

        childAccount.Master_Account__c = masterAccount.Id;
        update childAccount;

        childQuote.ParentQuote__c = masterQuote.Id;
        update childQuote;

        List<Opportunity> reselectedOppWithParent = new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{childOpty.Id})
            .withoutSelectorFieldsIncluded()
            .executeQuery();

        childQuote.ParentQuote__c = null;
        update childQuote;

        List<Opportunity> reselectedOppWOParent = new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id>{childOpty.Id})
                .withoutSelectorFieldsIncluded()
                .executeQuery();

        childQuote.ParentQuote__c = masterQuote.Id;
        update childQuote;
        delete masterQuote;
        List<Opportunity> reselectedOpp = new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id>{childOpty.Id})
                .withoutSelectorFieldsIncluded()
                .executeQuery();

        Test.stopTest();

        System.assertEquals(1, reselectedOppWithParent.size(), 'There must be at least one opp in the list');
        System.assertEquals(1, reselectedOppWOParent.size(), 'There must be at least one opp in the list');
        System.assertEquals(1, reselectedOpp.size(), 'There must be at least one opp in the list');
    }


    @isTest
    static void testProServUsersAndQuotedHoursConversion() {

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Test.startTest();

        Integer numberOfUsers = 5;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServUsers__c => numberOfUsers
            })
            .create()
            .getRecord();

        Test.stopTest();

        Quote checkQuote = [SELECT ProServUsers__c, TotalProjectHoursQuoted__c FROM Quote WHERE Id = :testQuote.Id];

        System.assertEquals(checkQuote.TotalProjectHoursQuoted__c, numberOfUsers);
        System.assertEquals(checkQuote.ProServUsers__c, numberOfUsers);
    }

    @isTest
    static void testSyncMasterQuoteToTechQuotes() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.SalesAgreementStatusChangeValidation__c, true)
            .create();

        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => mpStruct.masterAccount.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Quote quoteToUpdate = mpStruct.masterQuote;
        quoteToUpdate.Status = QuoteHelper.QUOTE_STATUS_ACTIVE;
        quoteToUpdate.AreaCode__c = ac.Id;
        quoteToUpdate.FaxAreaCode__c = ac.Id;
        quoteToUpdate.ContactId = contact.Id;
        quoteToUpdate.Enabled_LBO__c = true;
        Triggers.switchOn();
        Test.startTest();
        update quoteToUpdate;
        Test.stopTest();

        List<Quote> techQuoteList = (List<Quote>) new QuoteSelector()
            .selectMultiProductTechnicalQuotesByMasterQuoteIds(quoteToUpdate.Id)
            .executeQuery();

        for(Quote quote : techQuoteList) {

            System.assertEquals(
                quote.MasterQuote__r.Status, quote.Status,
                'Status from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quote.MasterQuote__r.Start_Date__c, quote.Start_Date__c,
                'Start date from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quote.MasterQuote__r.QuoteType__c, quote.QuoteType__c,
                'Quote type from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quote.MasterQuote__r.Term_months__c, quote.Term_months__c,
                'Term_months__c from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quote.MasterQuote__r.Initial_Term_months__c, quote.Initial_Term_months__c,
                'Initial_Term_months__c from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quoteToUpdate.AreaCode__c, quote.AreaCode__c,
                'AreaCode__c from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quoteToUpdate.FaxAreaCode__c, quote.FaxAreaCode__c,
                'FaxAreaCode__c from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quoteToUpdate.AreaCode__c, quote.AreaCode__c,
                'AreaCode__c from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quoteToUpdate.FaxAreaCode__c, quote.FaxAreaCode__c,
                'FaxAreaCode__c from master quote should be passed to tech quotes'
            );

            System.assertEquals(
                quoteToUpdate.ContactId, quote.ContactId,
                'ContactId from master quote should be passed to tech quotes'
            );

            BillingWrappers.QuotePackageInfo masterServicePackageInfo = QuoteHelper.getTechnicalQuotePackageInfo(quoteToUpdate, quote.ServiceName__c);
            String packageInfo = JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{
                masterServicePackageInfo
            });
            System.assertEquals(
                packageInfo, quote.Package_Info__c,
                'Package_Info__c from master quote should be passed to tech quotes'
            );

            if (quote.ServiceName__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                System.assertEquals(
                    quoteToUpdate.Enabled_LBO__c, quote.Enabled_LBO__c,
                    'Enabled_LBO__c from master quote should be passed to MVP tech quotes'
                );
            } else {
                System.assertEquals(
                    false, quote.Enabled_LBO__c,
                    'Enabled_LBO__c from master quote should be passed to MVP tech quotes'
                );
            }
        }
    }

    @isTest
    static void testSyncMasterQuoteToTechQuotesExistingOpptyPOC() {
        Triggers.switchOff();
        Account masterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .setField(Account.Offer_Type__c, AccountHelper.OFFER_TYPE_POC)
            .setField(Account.Billing_ID__c, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity masterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, masterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .setField(Quote.Term_months__c, '24')
            .create()
            .getRecord();

        Triggers.switchOn();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .setField(Quote.Term_months__c, '24')
            .create()
            .getRecord();

        Test.startTest();

        masterQuote.Term_months__c = '12';

        update masterQuote;

        Test.stopTest();

        List<Quote> techQuoteList = (List<Quote>) new QuoteSelector()
            .selectMultiProductTechnicalQuotesByMasterQuoteIds(masterQuote.Id)
            .executeQuery();

        for(Quote quote : techQuoteList) {
            System.assertEquals(
                quote.Term_months__c,
                masterQuote.Term_months__c,
                'Term_months__c from technical quote should be same as on master quote for POC-to-Paid scenario when existing Opportunity with New Business type is used (ISUS-108)'
            );
        }
    }

    @isTest
    static void testSyncMasterQuoteToTechQuotesClearFSC() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.SalesAgreementStatusChangeValidation__c, true)
            .create();

        Triggers.switchOff();
        Account masterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity masterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, masterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .create()
            .getRecord();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .create()
            .getRecord();

        Triggers.switchOn();

        System.assertEquals(
            masterQuote.Credit_Amount__c, techQuote.Credit_Amount__c,
            'Credit_Amount__c from master quote should be passed to tech quotes'
        );

        System.assertEquals(
            masterQuote.Free_Service_Taxes__c, techQuote.Free_Service_Taxes__c,
            'Free_Service_Taxes__c from master quote should be passed to tech quotes'
        );

        System.assertEquals(
            masterQuote.Special_Terms__c, techQuote.Special_Terms__c,
            'Special_Terms__c from master quote should be passed to tech quotes'
        );

        Test.startTest();

        masterQuote.Status = QuoteHelper.QUOTE_STATUS_ACTIVE;
        masterQuote.Credit_Amount__c = null;
        masterQuote.Free_Service_Taxes__c = null;
        masterQuote.Special_Terms__c = null;

        update masterQuote;

        Test.stopTest();

        List<Quote> techQuoteList = (List<Quote>) new QuoteSelector()
            .selectMultiProductTechnicalQuotesByMasterQuoteIds(masterQuote.Id)
            .executeQuery();

        for(Quote quote : techQuoteList) {
            System.assertEquals(
                masterQuote.Credit_Amount__c, quote.Credit_Amount__c,
                'Credit_Amount__c from master quote should be passed to tech quotes and be null'
            );

            System.assertEquals(
                masterQuote.Free_Service_Taxes__c, quote.Free_Service_Taxes__c,
                'Free_Service_Taxes__c from master quote should be passed to tech quotes and be null'
            );

            System.assertEquals(
                masterQuote.Special_Terms__c, quote.Special_Terms__c,
                'Special_Terms__c from master quote should be passed to tech quotes and be null'
            );
        }
    }

    @isTest
    static void verifyTechQuotesAreDeleteOnDeletingMasterQuote() {
        Triggers.switchOff();
        Account masterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Opportunity masterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, masterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .create()
            .getRecord();

        Quote masterQuote2 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .create()
            .getRecord();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, masterOpportunity.Id)
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Start_Date__c, Date.today())
            .setField(Quote.End_Date__c, Date.today().addDays(2))
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .setField(Quote.Credit_Amount__c, 100)
            .setField(Quote.Free_Service_Taxes__c, 1)
            .setField(Quote.Special_Terms__c, '1 Free Month of Service')
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        delete masterQuote;
        Test.stopTest();

        List<Quote> techQuotes = [SELECT Id from Quote WHERE IsMultiProductTechnicalQuote__c = TRUE];
        System.assertEquals(0, techQuotes.size(),
        'Technical Quotes should be deleted asynchronously after master quote deletion');
    }

    @isTest
    static void testActivatingValidationQuoteOnSingleProduct() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOppQuotingOn = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Integer numberOfUsers = 5;

        Quote activeQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServUsers__c => numberOfUsers,
                Quote.Status => QuoteTriggerHelper.STATUS_ACTIVE,
                Quote.End_Date__c => Date.today(),
                Quote.Start_Date__c => Date.today()
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOppQuotingOn.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServUsers__c => numberOfUsers,
                Quote.End_Date__c => Date.today(),
                Quote.Start_Date__c => Date.today()
            })
            .create()
            .getRecord();

        Test.startTest();
        String error = '';

        QuoteTriggerHelper.isSalesAgreementValidationExecuted = false;
        testQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
        try {
            update testQuote;
        } catch (Exception ex) {
            error = ex.getMessage();
        }
        Test.stopTest();

        System.assert(!String.isEmpty(error), 'Error should be not empty');
    }

    @isTest
    static void testActivateValidationQuoteOnMultiproduct() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.SalesAgreementStatusChangeValidation__c, true)
            .create();

        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        mpStruct.masterQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
        update mpStruct.masterQuote;
        Triggers.switchOn();
        List<Quote> quoteList = mpStruct.serviceQuotes.values();
        Quote testQuote = quoteList[0];

        Test.startTest();
        String error = '';

        try {
            testQuote.QuoteType__c = QuoteTriggerHelper.TYPE_AGREEMENT;
            testQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
            update testQuote;
        } catch (Exception ex) {
            error = ex.getMessage();
        }

        Test.stopTest();

        System.assert(String.isEmpty(error), 'Tech quote should be activated');
    }

    @isTest
    static void testSyncTechnicalQuotesOnMasterQuoteActivation() {

        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.SalesAgreementStatusChangeValidation__c, true)
            .create();

        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();
            mpStruct.masterOpp.Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS;
            update mpStruct.masterOpp;

        Test.startTest();
            mpStruct.masterQuote.Term_months__c = '24';
            mpStruct.masterQuote.Initial_Term_months__c = '36';
            mpStruct.masterQuote.Auto_Renewal__c = true;
            mpStruct.masterQuote.Start_Date__c = Date.newInstance(Date.today().year() - 1, 1, 15);
            mpStruct.masterQuote.End_Date__c = Date.newInstance(Date.today().year() - 1, 1, 15).addMonths(36);
            mpStruct.masterQuote.isPrimary__c = true;
            mpStruct.masterQuote.IsMultiProductTechnicalQuote__c = false;
            mpStruct.masterQuote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
            mpStruct.masterQuote.QuoteType__c = 'Agreement';
            update mpStruct.masterQuote;

            List<Quote> techQuotes = new QuoteSelector()
                .selectMultiProductTechnicalQuotesByMasterQuoteIds(mpStruct.masterQuote.Id)
                .executeQuery();
            Quote techQuote = techQuotes.get(0);

        Test.stopTest();

        // This test uses Date.today() (not hardcoded), so result depends on when test runs.
        // monthsBetween() truncates partial months, so we may need to add 1 month.
        // End_Date__c day is 15 (set as Date.newInstance(year, 1, 15).addMonths(36)).
        // If today's day < 15 (days 1-14): +1 month needed
        // If today's day >= 15 (days 15-31): +1 month NOT needed
        Integer expectedTerms = Math.abs(Date.today().monthsBetween(techQuote.MasterQuote__r.End_Date__c));
        Date expectedEndDate = Date.today().addMonths(expectedTerms);
        if (expectedEndDate < techQuote.MasterQuote__r.End_Date__c) {
            expectedEndDate = expectedEndDate.addMonths(1);
        }
        System.assertEquals(
            expectedEndDate,
            techQuote.End_Date__c,
            'End_Date__c on technical quote is wrong'
        );
        System.assertEquals(
            techQuote.Start_Date__c.monthsBetween(techQuote.End_Date__c),
            Integer.valueOf(techQuote.Initial_Term_months__c),
            'Initial_Term_months__c on the technical quote is wrong'
        );
        System.assertEquals(
            mpStruct.masterQuote.Status,
            techQuote.Status,
            'Status should be the same for the technical and master quotes'
        );
        System.assertEquals(
            mpStruct.masterQuote.Term_months__c,
            techQuote.Term_months__c,
            'Term_months__c should be the same for the technical and master quotes'
        );
        System.assertEquals(
            mpStruct.masterQuote.Auto_Renewal__c,
            techQuote.Auto_Renewal__c,
            'Auto_Renewal__c should be the same for the technical and master quotes'
        );
        System.assertEquals(
            mpStruct.masterQuote.QuoteType__c,
            techQuote.QuoteType__c,
            'QuoteType__c should be the same for the technical and master quotes'
        );
        System.assertEquals(
            Date.today(),
            techQuote.Start_Date__c,
            'Start_Date__c should be set as today'
        );
    }

    @isTest
    static void testMoveAcceptedQuoteToActiveStatus() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
            	Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
            	Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.PriceBook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        DSFS__DocuSign_Status__c docuSignStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => testAccount.Id,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => testOpp.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => testQuote.Id,
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16),
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            docuSignStatus.DSFS__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
            update docuSignStatus;
        Test.stopTest();

        Quote updatedQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{testQuote.Id})
            .executeQuery()
            .get(0);

        System.assertEquals(QuoteHelper.QUOTE_STATUS_ACTIVE, updatedQuote.Status, 'Quote should be in '
            + QuoteHelper.QUOTE_STATUS_ACTIVE + ' status after docusign status is moved to ' + DocuSignHelper.ENVELOPE_STATUS_COMPLETED);
    }

    @IsTest
    static void testAdjustTechAccountTermsOnMasterUpdate() {
        Triggers.switchOff();
        Triggers.except('QuoteTriggerHelper.AdjustTechQuoteTermsOnMasterUpdate');
        Account masterAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Master Account',
                Account.RC_Service_name__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();
        Opportunity masterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => masterAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => masterOpportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Status => 'Draft',
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.Approved_Status__c => 'Approved',
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
            	Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Term_months__c => '12',
                Quote.Initial_Term_months__c => '12',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
            })
            .create()
            .getRecord();


        List<String> services = new List<String> {
            QuoteHelper.NGBS_OFFICE_PRODUCT,
            QuoteHelper.NGBS_RCCC_PRODUCT
        };
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(
            masterAccount.Id,
            services
        );
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(
            masterOpportunity.Id,
            serviceAccounts,
            services
        );

        BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();
        rccQuoteInfo.renewalTerm = '6';
        rccQuoteInfo.initialTerm = '3';

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new BillingWrappers.QuoteWrapper(),
            QuoteHelper.NGBS_RCCC_PRODUCT => rccQuoteInfo
        };
        Map<String, Quote> serviceQuotes = QuoteHelper.upsertTechnicalQuotes(
            masterQuote,
            quoteInfoByService,
            serviceOpportunities
        );

        Test.startTest();
        update new Quote(Id = masterQuote.Id, Term_months__c = '24', Initial_Term_months__c = '24');
        serviceQuotes = QuoteHelper.getTechnicalQuotesByMasterId(masterQuote, services, serviceOpportunities);
        System.assertEquals(
            '24',
            serviceQuotes.get(QuoteHelper.NGBS_OFFICE_PRODUCT).Term_months__c,
            'Term_months__c should be updated on technical quote'
        );
        System.assertEquals(
            '18',
            serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Term_months__c,
            'Term_months__c should be updated on technical quote'
        );
        System.assertEquals(
            '15',
            serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT).Initial_Term_months__c,
            'Initial_Term_months__c should not be updated on technical quote'
        );
        Test.stopTest();
        Triggers.switchOn();
    }

    @IsTest
    static void testPrimaryQuoteChange() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .quantity(2)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .quantity(2)
            .create()
            .getRecords();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();

        Quote testMasterQuote1 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        List<Quote> testQuotes1 = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote1.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.IsPrimary__c, ValueProviderBuilder.provideList(new List<Boolean>{false, true }))
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC})
                })
            )
            .quantity(2)
            .create()
            .getRecords();

        Quote testMasterQuote2 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        List<Quote> testQuotes2 = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote2.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Package_Info__c, ValueProviderBuilder.provideList(new List<String>{
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}),
                JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC})
                })
            )
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();

        testMasterQuote1.isPrimary__c = false;
        testMasterQuote2.isPrimary__c = true;
        List<Quote> quotesToUpdate = new List<Quote>{testMasterQuote1, testMasterQuote2};
        Boolean exceptionThrown = false;
        try {
            update quotesToUpdate;
        } catch(Exception e) {
            if(e.getMessage().contains('You should always have a Primary Quote. If you want to change it just make another Quote a Primary one')){
                exceptionThrown = true;
            }
        }

        Test.stopTest();

        System.assertEquals(false, exceptionThrown, 'Exception shouldn`t be thrown');
    }

    @IsTest
    static void testFirstTechQuoteIsNotPrimaryOnOppty() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Account techAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .create()
            .getRecord();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        Opportunity techOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, techAccount.Id)
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();

        Quote testMasterQuote1 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        Quote testMasterQuote2 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, techOpportunity.Id)
            .setField(Quote.MasterQuote__c, testMasterQuote2.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}))
            .build()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            insert techQuote;
        Test.stopTest();

        List<Quote> techQuotes = new QuoteSelector()
            .selectQuotes()
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ techOpportunity.Id })
            .executeQuery();

        Assert.areEqual(techQuotes.size(), 1, 'There must be at least one quote in the list');
        Assert.isFalse(techQuotes[0].isPrimary__c, 'The First Tech Quote on Opportunity schould be not Primary');
    }

    @IsTest
    static void testLastModifiedTechQuoteIsNotPrimaryOnOppty() {
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        Account techAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .create()
            .getRecord();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        Opportunity techOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, techAccount.Id)
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo pInfoOffice = new BillingWrappers.QuotePackageInfo();
        BillingWrappers.QuotePackageInfo pInfoCC = new BillingWrappers.QuotePackageInfo();

        Quote testMasterQuote1 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        Quote testMasterQuote2 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoOffice}))
            .create()
            .getRecord();

        Quote techQuote1 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, techOpportunity.Id)
            .setField(Quote.MasterQuote__c, testMasterQuote1.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}))
            .create()
            .getRecord();

        Quote techQuote2 = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, techOpportunity.Id)
            .setField(Quote.MasterQuote__c, testMasterQuote2.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.Package_Info__c, JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfoCC}))
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            delete techQuote1;
        Test.stopTest();

        List<Quote> techQuotes = new QuoteSelector()
            .selectQuotes()
            .setCondition('OpportunityId = :bind0')
            .setQueryBindings(new List<Object>{ techOpportunity.Id })
            .executeQuery();

        Assert.areEqual(techQuotes.size(), 1, 'There must be at least one quote in the list');
        Assert.isFalse(techQuotes[0].isPrimary__c, 'The Last Modified Tech Quote on Opportunity schould be not Primary');
    }

    @IsTest
    static void testDeleteRelatedAssignments() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(
                    Product2Helper.MOBILE_USER_ELEMENT_ID
                )
            })
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => pricebook.Id
            })
            .create()
            .getRecord();

        PricebookEntry standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry pricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pricebook.Id,
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productMonthly.Id,
                QuoteLineItem.PricebookEntryId => pricebookEntry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        Area_Codes__c areaCode = (Area_Codes__c) new SobjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Area_Codes__c.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        List<AssignmentLineItem__c> alis = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Quantity__c => 2,
                AssignmentLineItem__c.AreaCode__c => areaCode.Id
            })
            .quantity(2)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => ValueProviderBuilder.provideList(new List<String> {'10 Avenue Jean Médecin'}),
                CustomAddress__c.City__c => ValueProviderBuilder.provideList(new List<String> {'Nice'}),
                CustomAddress__c.Country__c => ValueProviderBuilder.provideList(new List<String> {'France'}),
                CustomAddress__c.State__c => ValueProviderBuilder.provideList(new List<String> {'Nice'}),
                CustomAddress__c.PostalCode__c => ValueProviderBuilder.provideList(new List<String> {'06000'})
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> caa = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => ValueProviderBuilder.provideList(new List<String> {'Test France 1', 'Test France 2'}),
                CustomAddressAssignments__c.CustomAddress__c => ValueProviderBuilder.provideList(new List<Id> {ca.Id}),
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {2, 4}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {qlis[0].Id, qlis[1].Id}),
                CustomAddressAssignments__c.Type__c => 'Ground',
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'})
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            qt.Enabled_LBO__c = true;
            update qt;
            List<AssignmentLineItem__c> reselectedAlis = new AssignmentLineItemSelector()
                .selectALIForMasterQuotes(new List<Object> { new List<Id>{ qt.Id }})
                .executeQuery();
            List<CustomAddressAssignments__c> reselectedCaas = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignmentsByQuoteIds(new Set<Id>{ qt.Id })
                .executeQuery();
            List<Area_Code_Line_Item__c> reselectedAclis = new AreaCodeLineItemSelector()
                .selectACLIForMasterQuotes(new List<Object>{ new List<Id>{ qt.Id }})
                .executeQuery();
        Test.stopTest();

        System.assertEquals(0, reselectedAlis.size(), 'Assignment line items should be deleted');
        System.assertEquals(0, reselectedCaas.size(), 'Custom address assignments should be deleted');
        System.assertEquals(0, reselectedAclis.size(), 'Area code line items should be deleted');
    }

    @IsTest
    static void testSendEmailsOnIgniteQuoteCreation() {
        Email_Configuration__c settings = new Email_Configuration__c(
            CC_Emails_Ignite_Quote_Creation__c = 'test_partners.sales@ringcentral.com'
        );
        insert settings;

        Triggers.switchOff();
        Triggers.except('QuoteTriggerHelper.SendEmailsOnIgniteQuoteCreation');
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();
        Opportunity testOppNB = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();


        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_OFFICE,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.PartnerProgram__c => 'Ignite'
            })
            .create()
            .getRecord();

        Test.startTest();
        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.IsPrimary__c => true,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .quantity(1)
            .create()
            .getRecords();
        Integer numOfEmailInvocations = Limits.getEmailInvocations();
        Test.stopTest();
        Triggers.switchOff();

        System.assertEquals(1, testQuotes.size(), 'Quote should be created');
        System.assertEquals(1, numOfEmailInvocations, 'Email should be sent');
    }

    @IsTest
    static void testUpdateServiceInfo() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.IsProcessOrderSent__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
        update qt;
        Test.stopTest();

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'IsProcessOrderSent__c' })
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(new List<Object>{ qt.Id })
            .executeQuery();

        System.assertEquals(1, serviceInfos.size(), 'Only one service info should be created');
        System.assertEquals(false, serviceInfos[0].IsProcessOrderSent__c, 'IsProcessOrderSent__c should be reset to false');
    }

    @IsTest
    static void testManageQuotesMapStatic() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        update qt;
        System.assertNotEquals(null, QuoteLineItemTriggerHelper.quotesMapStatic.get(qt.Id), 'quote should be added into static map');
    }

    @isTest
    static void testSendEmailToSSE() {

        insert new Emails__c (
            Name = 'SSE_Direct_Leadership',
            Description__c = 'Test',
            Email_Address__c  = 'xyz@ringcentral.com'
        );
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;
        Quote quote = new Quote(OpportunityId = testOpp.Id, RecordTypeId = QuoteHelper.RT_ID_POC, Name = 'Test Quote',
            IsQuoteHasErrors__c = false, isPrimary__c = true);
        insert quote;

        Test.startTest();
        quote.Total_Number_of_Digital_Lines__c = 22;  // Above the threshold of 20
        update quote;
        System.assertNotEquals(null,quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailToCESE() {
        
        insert new Emails__c (
            Name = 'SSE_Direct_Leadership',
            Description__c = 'Test SSE Email',
            Email_Address__c  = 'sse@ringcentral.com'
        );
        
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Alias => StringHelper.getRandomString(8),
                User.Email => ValueProviderBuilder.provideUniqueEmail(),
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.LocaleSidKey => 'en_US',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.Region__c => 'US',
                User.Sub_Region__c => 'All',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.Username => ValueProviderBuilder.provideUniqueEmail()
            })
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;
        
        Quote masterQuote = new Quote(
            OpportunityId = testOpp.Id, 
            RecordTypeId = QuoteHelper.RT_ID_POC, 
            Name = 'Test Master Quote',
            IsQuoteHasErrors__c = true, 
            isPrimary__c = false
        );
        insert masterQuote;
        
        Quote technicalQuote = new Quote(
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_POC,
            Name = 'Test Technical Quote',
            MasterQuote__c = masterQuote.Id,
            IsMultiProductTechnicalQuote__c = true,
            ServiceName__c = 'Engage Voice Standalone',
            IsQuoteHasErrors__c = false,
            isPrimary__c = false
        );
        insert technicalQuote;
        
        Test.startTest();
        
        masterQuote.isPrimary__c = true;
        masterQuote.IsQuoteHasErrors__c = false;
        update masterQuote;
        
        Test.stopTest();
        
        System.assertNotEquals(null, masterQuote.Id, 'Master quote ID should not be null');
        
        Quote updatedTechnicalQuote = [SELECT Id, ServiceName__c, MasterQuote__c 
                                      FROM Quote 
                                      WHERE Id = :technicalQuote.Id];
        System.assertEquals('Engage Voice Standalone', updatedTechnicalQuote.ServiceName__c, 'Technical quote should have Engage Voice Standalone service');
        System.assertEquals(masterQuote.Id, updatedTechnicalQuote.MasterQuote__c, 'Technical quote should be linked to master quote');
    }

    @isTest
    static void testSendEmailToCESENoEngageVoiceService() {
        
        insert new Emails__c (
            Name = 'SSE_Direct_Leadership',
            Description__c = 'Test SSE Email',
            Email_Address__c  = 'sse@ringcentral.com'
        );
        
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Alias => StringHelper.getRandomString(8),
                User.Email => ValueProviderBuilder.provideUniqueEmail(),
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.LocaleSidKey => 'en_US',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.Region__c => 'US',
                User.Sub_Region__c => 'All',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.Username => ValueProviderBuilder.provideUniqueEmail()
            })
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;
        
        Quote masterQuote = new Quote(
            OpportunityId = testOpp.Id, 
            RecordTypeId = QuoteHelper.RT_ID_POC, 
            Name = 'Test Master Quote',
            IsQuoteHasErrors__c = true, 
            isPrimary__c = false
        );
        insert masterQuote;
        
        Quote technicalQuote = new Quote(
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_POC,
            Name = 'Test Technical Quote',
            MasterQuote__c = masterQuote.Id,
            IsMultiProductTechnicalQuote__c = true,
            ServiceName__c = 'RingEX',  // Different service
            IsQuoteHasErrors__c = false,
            isPrimary__c = false
        );
        insert technicalQuote;
        
        Test.startTest();
        
        masterQuote.isPrimary__c = true;
        masterQuote.IsQuoteHasErrors__c = false;
        update masterQuote;
        
        Test.stopTest();
        
        System.assertNotEquals(null, masterQuote.Id, 'Master quote ID should not be null');
        
        Quote updatedTechnicalQuote = [SELECT Id, ServiceName__c, MasterQuote__c 
                                      FROM Quote 
                                      WHERE Id = :technicalQuote.Id];
        System.assertEquals('RingEX', updatedTechnicalQuote.ServiceName__c, 'Technical quote should have RingEX service');
        System.assertEquals(masterQuote.Id, updatedTechnicalQuote.MasterQuote__c, 'Technical quote should be linked to master quote');
    }

    @isTest
    static void testSendEmailToCESENonPOCQuote() {
        
        insert new Emails__c (
            Name = 'SSE_Direct_Leadership',
            Description__c = 'Test SSE Email',
            Email_Address__c  = 'sse@ringcentral.com'
        );
        
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Alias => StringHelper.getRandomString(8),
                User.Email => ValueProviderBuilder.provideUniqueEmail(),
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.LocaleSidKey => 'en_US',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.Region__c => 'US',
                User.Sub_Region__c => 'All',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.Username => ValueProviderBuilder.provideUniqueEmail()
            })
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;
        
        Quote nonPOCQuote = new Quote(
            OpportunityId = testOpp.Id, 
            RecordTypeId = QuoteHelper.RT_ID_BILLING,  // Not POC record type
            Name = 'Test Non-POC Quote',
            IsQuoteHasErrors__c = true, 
            isPrimary__c = false
        );
        insert nonPOCQuote;
        
        Test.startTest();
        
        nonPOCQuote.isPrimary__c = true;
        nonPOCQuote.IsQuoteHasErrors__c = false;
        update nonPOCQuote;
        
        Test.stopTest();
        
        System.assertNotEquals(null, nonPOCQuote.Id, 'Quote ID should not be null');
        
        Quote updatedQuote = [SELECT Id, RecordTypeId FROM Quote WHERE Id = :nonPOCQuote.Id];
        System.assertNotEquals(QuoteHelper.RT_ID_POC, updatedQuote.RecordTypeId, 'Quote should not be a POC quote');
    }
    
    @isTest
    static void testSendEmailToCESEOnMasterQuoteInsert() {
        insert new Emails__c (
            Name = 'SSE_Direct_Leadership',
            Description__c = 'Test SSE Email',
            Email_Address__c  = 'sse@ringcentral.com'
        );
        
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Alias => StringHelper.getRandomString(8),
                User.Email => ValueProviderBuilder.provideUniqueEmail(),
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.LocaleSidKey => 'en_US',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.Region__c => 'US',
                User.Sub_Region__c => 'All',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.Username => ValueProviderBuilder.provideUniqueEmail()
            })
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;
        
        Test.startTest();
        
        Quote masterQuote = new Quote(
            OpportunityId = testOpp.Id, 
            RecordTypeId = QuoteHelper.RT_ID_POC, 
            Name = 'Test Master Quote',
            IsQuoteHasErrors__c = false, 
            isPrimary__c = true,
            ServiceName__c = 'Engage Voice Standalone'
        );
        insert masterQuote;
        
        Test.stopTest();
        
        System.assertEquals('Engage Voice Standalone', masterQuote.ServiceName__c, 'Master quote should have Engage Voice Standalone service');
        System.assertEquals(true, masterQuote.isPrimary__c, 'Master quote should be primary');
        System.assertEquals(false, masterQuote.IsQuoteHasErrors__c, 'Master quote should have no errors');
    }
    
    @isTest
    static void testSendEmailToCESEOnTechnicalQuoteInsert() {

        insert new Emails__c (
            Name = 'SSE_Direct_Leadership',
            Description__c = 'Test SSE Email',
            Email_Address__c  = 'sse@ringcentral.com'
        );
        
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Alias => StringHelper.getRandomString(8),
                User.Email => ValueProviderBuilder.provideUniqueEmail(),
                User.EmailEncodingKey => 'UTF-8',
                User.LanguageLocaleKey => 'en_US',
                User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                User.LocaleSidKey => 'en_US',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                User.Region__c => 'US',
                User.Sub_Region__c => 'All',
                User.TimeZoneSidKey => 'America/Los_Angeles',
               User.Username => ValueProviderBuilder.provideUniqueEmail()
            })
            .create()
            .getRecord();
        
        Account testAcc = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL,
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;
        
        Quote masterQuote = new Quote(
            OpportunityId = testOpp.Id, 
            RecordTypeId = QuoteHelper.RT_ID_POC, 
            Name = 'Test Master Quote',
            IsQuoteHasErrors__c = false, 
            isPrimary__c = true,
            ServiceName__c = 'RingEX'  // Different service
        );
        insert masterQuote;
        
        Test.startTest();
        
        Quote technicalQuote = new Quote(
            OpportunityId = testOpp.Id,
            RecordTypeId = QuoteHelper.RT_ID_POC,
            Name = 'Test Technical Quote',
            MasterQuote__c = masterQuote.Id,
            IsMultiProductTechnicalQuote__c = true,
            ServiceName__c = 'Engage Voice Standalone',
            IsQuoteHasErrors__c = false,
            isPrimary__c = false
        );
        insert technicalQuote;
        
        Test.stopTest();
        
        System.assertEquals('Engage Voice Standalone', technicalQuote.ServiceName__c, 'Technical quote should have Engage Voice Standalone service');
        System.assertEquals(masterQuote.Id, technicalQuote.MasterQuote__c, 'Technical quote should be linked to master quote');
        System.assertEquals(true, masterQuote.isPrimary__c, 'Master quote should be primary');
    }
}