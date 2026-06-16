@isTest
private class Test_QuoteSelector {

    private static void assertQuoteSelector(QueryFactory factory, String selectorName, String expectedWhereClause, Integer bindingSize) {
        String query = factory.getQuery();

        System.assertNotEquals(null, factory, getAssertMessageForSelector(selectorName, 'must return QuoteFactory'));
        System.assertNotEquals(true, String.isBlank(query), getAssertMessageForSelector(selectorName, 'must compose a string query'));
        System.assertEquals(true, query.contains(expectedWhereClause), getAssertMessageForSelector(selectorName, 'must have the right WHERE clause'));
        System.assertEquals(bindingSize, factory.bindings.size(), getAssertMessageForSelector(selectorName, 'must have ' + String.valueOf(bindingSize) + ' input binding variable'));
    }

    private static void assertBindings(QueryFactory factory, String selectorName, List<Object> expectedBindings) {
        Assert.areEqual(expectedBindings, factory.bindings, getAssertMessageForSelector(selectorName, 'must have the right bindings'));
    }

    private static String getAssertMessageForSelector(String selectorName, String assertMessage) {
        return selectorName + ' ' + assertMessage;
    }

    @testSetup
    private static void createTestData(){
        Test.startTest();
        List<Account> testAccounts = (List<Account>) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecords();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccounts[0].Id)
            .setField(Opportunity.Name, 'TestOpportunity')
            .setField(Opportunity.Brand_Name__c, 'RingCentral')
            .setField(Opportunity.Tier_Name__c, 'Office')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CurrencyIsoCode, 'USD')
            .create()
            .getRecord();

        List<Quote> testSalesQuotes = (List<Quote>) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Account__c, testOpp.AccountId)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId())
            .quantity(4)
            .create()
            .getRecords();

        Quote testActiveQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'testActiveQuote')
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Account__c, testOpp.AccountId)
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .create()
            .getRecord();
        Test.stopTest();
    }

    @isTest
    private static void testSelectQuoteForQuotingToolItemsSync() {

        List<Quote> testQuotes = (List<Quote>) new QuoteSelector()
           .selectQuotes()
           .withSelectorFieldsIncluded()
           .executeQuery();

        Quote quoteById = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{testQuotes})
            .withSelectorFieldsIncluded()
            .executeQuery()
            .get(0);

        List<Quote> testQuotesForQuotingToolItemsSync =  (List<Quote>) new QuoteSelector(false, false)
            .selectQuoteForQuotingToolItemsSync(quoteById.Id)
            .executeQuery();

        System.assertEquals(1, testQuotesForQuotingToolItemsSync.size(), 'Wrong number of returned records');
        System.assertEquals(quoteById.Id, testQuotesForQuotingToolItemsSync[0].Id, 'Wrong Quote returned.');
        System.assertEquals('USD', testQuotesForQuotingToolItemsSync[0].CurrencyIsoCode, 'Wrong Quote returned.');
    }

    @isTest
    private static void testSelectorQuotesAndQlisForCloseWizardByOppId() {

        List<Opportunity> testOpps = (List<Opportunity>) new OpportunitySelector()
           .selectOpportunityForSyncWithNGBSByName('TestOpportunity')
           .withoutSelectorFieldsIncluded()
           .selectFields(new List<String>{'Id'})
           .executeQuery();

        List<Quote> testQuotesByOppId =  (List<Quote>) new QuoteSelector()
            .selectorQuotesAndQlisForCloseWizardByOppId(testOpps[0].Id)
            .executeQuery();

        System.assertEquals(5, testQuotesByOppId.size(), 'Wrong number of returned records');
        System.assertEquals(testQuotesByOppId[0].OpportunityId, testOpps[0].Id, 'Incorrect Quote was retrieved.');
    }

    @isTest
    private static void selectorQuotesAndQlisForCloseWizardByOpportunityId_whereClauseAndBindings_returnQuotesForOpportunity() {

        // Given
        List<Opportunity> testOpps = (List<Opportunity>) new OpportunitySelector()
           .selectOpportunityForSyncWithNGBSByName('TestOpportunity')
           .withoutSelectorFieldsIncluded()
           .selectFields(new List<String>{'Id'})
           .executeQuery();

        Id oppId = testOpps[0].Id;

        // When - build factory
        Test.startTest();
            QueryFactory factory = new QuoteSelector()
                .selectorQuotesAndQlisForCloseWizardByOpportunityId(oppId)
                .setQuery();
        Test.stopTest();

        // Then - verify query shape
        String expectedWhereClause = 'FROM Quote WHERE OpportunityId = :bind0';
        String selectorName = 'selectorQuotesAndQlisForCloseWizardByOpportunityId';
        assertQuoteSelector(factory, selectorName, expectedWhereClause, 1);
        Assert.areEqual(1, factory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
        Assert.areEqual(oppId, (Id) factory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));

        // And - execute and validate results are scoped to the Opportunity
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectorQuotesAndQlisForCloseWizardByOpportunityId(oppId)
            .executeQuery();
        Assert.areEqual(5, quotes.size(), 'Wrong number of returned records');
        Assert.areEqual(oppId, quotes[0].OpportunityId, 'Incorrect Quote was retrieved.');
    }

    @isTest
    private static void testSelectQuoteForSyncWithNGBSByName() {

        List<Opportunity> testOpps = (List<Opportunity>) new OpportunitySelector()
           .selectOpportunityForSyncWithNGBSByName('TestOpportunity')
           .withoutSelectorFieldsIncluded()
           .selectFields(new List<String>{'Name'})
           .executeQuery();

        List<Quote> testQuotesForSyncWithNGBSByName =  (List<Quote>) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(testOpps[0].Name)
            .executeQuery();

        System.assertEquals(1, testQuotesForSyncWithNGBSByName.size(), 'Wrong number of returned records');
        System.assertEquals(true, testQuotesForSyncWithNGBSByName[0].isPrimary__c, 'Incorrect Quote was retrieved.');
        System.assertEquals(QuoteHelper.RT_ID_BILLING, testQuotesForSyncWithNGBSByName[0].RecordTypeId, 'Incorrect Quote was retrieved.');
    }

    @isTest
    private static void testSelectQuoteForSignUp() {

        List<Quote> testQuotes = (List<Quote>) new QuoteSelector()
           .selectQuotes()
           .withSelectorFieldsIncluded()
           .executeQuery();

        List<Quote> testQuotesForSignUp =  (List<Quote>) new QuoteSelector()
            .selectQuoteForSignUp(testQuotes[4].Id)
            .executeQuery();

        System.assertEquals(1, testQuotesForSignUp.size(), 'Wrong number of returned records');
        System.assertEquals(testQuotes[4].Id, testQuotesForSignUp[0].Id, 'Incorrect Quote was retrieved.');
    }

    @isTest
    private static void testSelectQuoteForClose() {

     	List<Opportunity> testOpps = (List<Opportunity>) new OpportunitySelector()
           .selectOpportunities()
           .withSelectorFieldsIncluded()
           .executeQuery();

        List<Quote> testQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotesForClose(testOpps[0].Id)
            .executeQuery();

        System.assertEquals(5, testQuotes.size(), 'Wrong number of returned records');
        System.assertEquals(testOpps[0].Id, testQuotes[0].OpportunityId, 'Incorrect Quote was retrieved.');
    }

    @isTest
    private static void testSelectPrimaryQuotes() {

        List<Opportunity> testOpps = (List<Opportunity>) new OpportunitySelector()
           .selectOpportunities()
           .withSelectorFieldsIncluded()
           .executeQuery();

        List<Quote> testPrimaryQuotes =  (List<Quote>) new QuoteSelector()
            .selectPrimaryQuotes(new List<Object>{testOpps[0].Id})
            .executeQuery();

        System.assertEquals(2, testPrimaryQuotes.size(), 'Wrong number of returned records');
        System.assertEquals(true, testPrimaryQuotes[0].isPrimary__c, 'Incorrect Quote was retrieved.');
        System.assertEquals(testOpps[0].Id, testPrimaryQuotes[0].OpportunityId, 'Incorrect Quote was retrieved.');
    }

    @isTest
    private static void testSelectQuotesForPackageTriggerEnabledLBO() {

        List<Account> testAccounts = (List<Account>) new AccountSelector()
           .selectAccounts()
           .withoutSelectorFieldsIncluded()
           .selectFields(new List<String>{'Id'})
           .executeQuery();

        List<Quote> testQuotes =  (List<Quote>) new QuoteSelector()
            .selectQuotesForPackageTriggerEnabledLBO(new List<Id>(new Map<Id, Account>(testAccounts).keySet()))
            .executeQuery();

        System.assertEquals(5, testQuotes.size(), 'Wrong number of returned records');
        System.assertEquals(testAccounts[0].Id, testQuotes[0].Account__c, 'Incorrect Quote was retrieved.');
    }

    @IsTest
    private static void test_selectQuoteForQuoteService(){
        Test.startTest();
            Opportunity testOpp = TestDataGenerator.createOpportunity(null);
            Quote testQuote = TestDataGenerator.createQuote(testOpp);

            Set<String> recordTypes = new Set<String>{
                QuoteHelper.RT_ID_BILLING,
                QuoteHelper.RT_ID_PROSERV,
                QuoteHelper.RT_ID_CC,
                QuoteHelper.RT_ID_CC_PROSERV,
                QuoteHelper.RT_ID_POC
            };

            List<Quote> result = (List<Quote>)  new QuoteSelector()
                .selectQuotesForQuoteService(testOpp.Id, recordTypes, 'OpportunityId = :bind0 AND RecordTypeId IN :bind1')
                .executeQuery();
            System.assertEquals(result.size(), 1);
        Test.stopTest();
    }

    @IsTest
    private static void test_selectQuoteForQuoteServiceAndCheckFields(){
        Test.startTest();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'JohnDoe@test.com',
                    Contact.FirstName => 'John',
                    Contact.LastName => 'Doe'
                }
            )
            .create()
            .getRecord();

        AccountContactRole testAccountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(AccountContactRole.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => testAcc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.IsPrimary => true
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.Type => 'New Business',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Professional',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CurrencyIsoCode => 'USD',
                    Opportunity.Primary_Opportunity_Contact__c => testContact.Id
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => testOpp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.isPrimary__c => true,
                Quote.Account__c => testAcc.Id,
                Quote.Enabled_LBO__c => false,
                Quote.ContactId => testContact.Id
            })
            .create()
            .getRecord();

        Set<String> recordTypes = new Set<String>{
            QuoteHelper.RT_ID_BILLING,
            QuoteHelper.RT_ID_PROSERV,
            QuoteHelper.RT_ID_CC,
            QuoteHelper.RT_ID_CC_PROSERV,
            QuoteHelper.RT_ID_POC
        };

        List<Quote> result = (List<Quote>)  new QuoteSelector()
            .selectQuotesForQuoteService(testOpp.Id, recordTypes, 'OpportunityId = :bind0 AND RecordTypeId IN :bind1')
            .executeQuery();
        Test.stopTest();

        System.assertEquals(result.size(), 1);
        System.assert(result[0].Contact != null, 'Contact field must be in quote');
    }

    @IsTest
    private static void test_selectMultiProductTechnicalQuoteByServiceName(){
        Triggers.switchOff();
        Account testMasterAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, false)
            .create()
            .getRecord();

        List<Account> testAccounts = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setField(Account.IsMultiProductTechnicalAccount__c, true)
            .setField(Account.Master_Account__c, testMasterAccount.Id)
            .quantity(3)
            .create()
            .getRecords();

        Opportunity testMasterOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, testMasterAccount.Id)
            .setField(Opportunity.CloseDate, system.today().addMonths(1))
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, false)
            .create()
            .getRecord();

        List<Opportunity> testOpportunities = (List<Opportunity>) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.AccountId, ValueProviderBuilder.provideList(new List<Id>{testAccounts.get(0).Id, testAccounts.get(1).Id, testAccounts.get(2).Id}))
            .setField(Opportunity.MasterOpportunity__c, testMasterOpportunity.Id)
            .setField(Opportunity.IsMultiProductTechnicalOpportunity__c, true)
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();

        Quote testMasterQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.OpportunityId, testMasterOpportunity.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.IsPrimary__c, false)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideList(new List<Id>{testMasterOpportunity.Id, testOpportunities.get(0).Id, testOpportunities.get(1).Id, testOpportunities.get(2).Id }))
            .setField(Quote.MasterQuote__c, testMasterQuote.Id)
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(new List<String>{
                QuoteHelper.NGBS_RCCC_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT,
                QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT
            }))
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .setField(Quote.IsTermination__c, ValueProviderBuilder.provideList(new List<Boolean>{false, true, true}))
            .quantity(3)
            .create()
            .getRecords();

        List<Quote> result = (List<Quote>)  new QuoteSelector()
            .selectMultiProductTechnicalQuoteByServiceName(testMasterQuote.Id, QuoteHelper.NGBS_RCCC_PRODUCT)
            .executeQuery();
        System.assertEquals(1, result.size(), 'List must have one record');
    }

    @isTest
    static void testSelectQuotesForContractPopulation() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        Set<Id> dummyIds = new Set<Id> {dummyQuoteId};

        Test.startTest();
            QueryFactory selectQuotesForContractPopulationFactory = new QuoteSelector()
                .selectQuotesForContractPopulation(dummyIds)
                .setQuery();
        Test.stopTest();

        assertQuoteSelector(selectQuotesForContractPopulationFactory, 'selectQuotesForContractPopulation', 'FROM Quote WHERE Id IN :bind0', 1);
        System.assertEquals(true, dummyIds.containsAll((Set<Id>) selectQuotesForContractPopulationFactory.bindings[0]), 'selectQuotesForContractPopulation must contain all input values');
    }

    @isTest
    static void testSelectOpenBillingQuotesForAccount() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Set<Id> dummyAccIds = new Set<Id> {dummyAccId};
        List<Object> bindings = new List<Object> {dummyAccIds};

        Test.startTest();
            QueryFactory selectOpenBillingQuotesForAccountFactory = new QuoteSelector()
                .selectOpenBillingQuotesForAccount(bindings)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE '
            + 'Account__c IN :bind0 AND Opportunity.StageName != '
            + '\'' + OpportunityHelper.STAGE_NAME_CLOSED_WON + '\''
            + ' AND Opportunity.StageName != '
            + '\'' + OpportunityHelper.STAGE_NAME_DOWNGRADED + '\''
            + ' AND RecordTypeId = '
            + '\'' + QuoteHelper.RT_ID_BILLING + '\''
            + ' AND QuoteType__c != '
            + '\'' + QuoteHelper.QUOTE_TYPE_AGREEMENT + '\''
            + ' AND Quote_is_Invalid__c != true';
        String selectorName = 'selectOpenBillingQuotesForAccount';
        assertQuoteSelector(selectOpenBillingQuotesForAccountFactory, selectorName, expectedWhereClause, bindings.size());

        Set<Id> bind0 = (Set<Id>) selectOpenBillingQuotesForAccountFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyAccId), getAssertMessageForSelector(selectorName, 'must contain the inputted account Id'));
    }

    @isTest
    static void testSelectQuotesForWizard() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuotesForWizardFactory = new QuoteSelector()
                .selectQuotesForWizard(dummyOppId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE OpportunityId = :bind0';
        String selectorName = 'selectQuotesForWizard';
        assertQuoteSelector(selectQuotesForWizardFactory, selectorName, expectedWhereClause, 1);

        System.assertEquals(dummyOppId, (Id) selectQuotesForWizardFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(2, selectQuotesForWizardFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain two subselect queries'));
    }

    @isTest
    static void testSelectQuoteToProcessNonNGBSOppoty() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuoteToProcessNonNGBSOppotyFactory = new QuoteSelector()
                .selectQuoteToProcessNonNGBSOppoty(dummyOppId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE OpportunityId = :bind0 AND isPrimary__c = true';
        String selectorName = 'selectQuoteToProcessNonNGBSOppoty';
        assertQuoteSelector(selectQuoteToProcessNonNGBSOppotyFactory, selectorName, expectedWhereClause, 1);

        System.assertEquals(dummyOppId, (Id) selectQuoteToProcessNonNGBSOppotyFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(1, selectQuoteToProcessNonNGBSOppotyFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuotesForPrimaryProcess() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuotesForPrimaryProcessFactory = new QuoteSelector()
                .selectQuotesForPrimaryProcess(dummyOppId, dummyQuoteId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE (OpportunityId = :bind0 AND IsMultiProductTechnicalQuote__c = false) OR MasterQuote__c = :bind1';
        String selectorName = 'selectQuotesForPrimaryProcess';
        assertQuoteSelector(selectQuotesForPrimaryProcessFactory, selectorName, expectedWhereClause, 2);

        System.assertEquals(dummyOppId, (Id) selectQuotesForPrimaryProcessFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(dummyQuoteId, (Id) selectQuotesForPrimaryProcessFactory.bindings[1], getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectQuotesForAccount() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Set<Id> dummyAccIds = new Set<Id> {dummyAccId};

        Test.startTest();
            QueryFactory selectQuotesForAccountFactory = new QuoteSelector()
                .selectQuotesForAccount(dummyAccIds)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE AccountId IN :bind0 OR Account__c IN :bind0';
        String selectorName = 'selectQuotesForAccount';
        assertQuoteSelector(selectQuotesForAccountFactory, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuotesForAccountFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyAccId), getAssertMessageForSelector(selectorName, 'must contain the inputted account Id'));
    }

    @isTest
    static void testSelectQuoteByIdForPOCApproval() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuoteByIdForPOCApprovalFactory = new QuoteSelector()
                .selectQuoteByIdForPOCApproval(new List<Object> {dummyQuoteId})
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE Id = :bind0';
        String selectorName = 'selectQuoteByIdForPOCApproval';
        assertQuoteSelector(selectQuoteByIdForPOCApprovalFactory, selectorName, expectedWhereClause, 1);

        System.assertEquals(dummyQuoteId, (Id) selectQuoteByIdForPOCApprovalFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
        System.assertEquals(1, selectQuoteByIdForPOCApprovalFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuoteForPdfTemplates() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuoteForPdfTemplatesFactory = new QuoteSelector()
                .selectQuoteForPdfTemplates(dummyOppId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE OpportunityId = :bind0';
        String selectorName = 'selectQuoteForPdfTemplates';
        assertQuoteSelector(selectQuoteForPdfTemplatesFactory, selectorName, expectedWhereClause, 1);

        System.assertEquals(dummyOppId, (Id) selectQuoteForPdfTemplatesFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(1, selectQuoteForPdfTemplatesFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuoteForDqGoa() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuoteForDqGoaFactory = new QuoteSelector()
                .selectQuoteForDqGoa(dummyQuoteId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE Id = :bind0 OR MasterQuote__c =: bind0';
        String selectorName = 'selectQuoteForDqGoa';
        assertQuoteSelector(selectQuoteForDqGoaFactory, selectorName, expectedWhereClause, 1);

        System.assertEquals(dummyQuoteId, (Id) selectQuoteForDqGoaFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
        System.assertEquals(1, selectQuoteForDqGoaFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuotesForDQSync() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectOpenBillingQuotesForAccountFactory = new QuoteSelector()
                .selectQuotesForDQSync(new Set<Id> {dummyQuoteId})
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE Id IN :bind0 OR MasterQuote__c IN :bind0';
        String selectorName = 'selectQuotesForDQSync';
        assertQuoteSelector(selectOpenBillingQuotesForAccountFactory, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectOpenBillingQuotesForAccountFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyQuoteId), getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
        System.assertEquals(1, selectOpenBillingQuotesForAccountFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuoteForDQGoaApproval() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuoteForDQGoaApprovalFactory = new QuoteSelector()
                .selectQuoteForDQGoaApproval(new Set<Id> {dummyOppId})
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'OpportunityId IN :bind0 AND '
            + 'Approved_Status__c = ' + '\'' + QuoteHelper.APPROVAL_STATUS_REQUIRED + '\' AND '
            + '((Account.RC_User_ID__c = null AND Account.Billing_ID__c = null) OR '
            + '(Account.Billing_ID__c != null AND '
            + '((Account.Offer_Type__c = ' + '\'' + AccountHelper.OFFER_TYPE_POC + '\' OR '
            + 'Account.Offer_Type__c LIKE ' + '\'%' + AccountHelper.OFFER_TYPE_TRIAL + '%\') OR '
            + '(Account.RC_Account_Status__c = ' + '\'' + AccountHelper.OFFER_TYPE_POC + '\' OR '
            + 'Account.RC_Account_Status__c LIKE ' + '\'%' + AccountHelper.OFFER_TYPE_TRIAL + '%\'))))';
        String selectorName = 'selectQuoteForDQGoaApproval';
        assertQuoteSelector(selectQuoteForDQGoaApprovalFactory, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuoteForDQGoaApprovalFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyOppId), getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
    }

    @isTest
    static void testSelectQuotesForQuoteLineItemTrigger() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuotesForQuoteLineItemTriggerFactory = new QuoteSelector()
                .selectQuotesForQuoteLineItemTrigger(new Set<Id> {dummyQuoteId})
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE Id IN :bind0';
        String selectorName = 'selectQuotesForQuoteLineItemTrigger';
        assertQuoteSelector(selectQuotesForQuoteLineItemTriggerFactory, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuotesForQuoteLineItemTriggerFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyQuoteId), getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectMultiProductTechnicalQuotesForSyncByMasterQuoteIds() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectMultiProductTechnicalQuotesForSyncByMasterQuoteIdsFactory = new QuoteSelector()
                .selectMultiProductTechnicalQuotesForSyncByMasterQuoteIds(new Set<Id> {dummyQuoteId})
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE MasterQuote__c IN :bind0 AND IsMultiProductTechnicalQuote__c = true AND Opp_Type__c = \'' + OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS + '\'';
        String selectorName = 'selectMultiProductTechnicalQuotesForSyncByMasterQuoteIds';
        assertQuoteSelector(selectMultiProductTechnicalQuotesForSyncByMasterQuoteIdsFactory, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectMultiProductTechnicalQuotesForSyncByMasterQuoteIdsFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyQuoteId), getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectQuotesByMasterQuoteIdToClearQLIs() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuotesByMasterQuoteIdToClearQLIsFactory = new QuoteSelector()
                .selectQuotesByMasterQuoteIdToClearQLIs(new Set<Id> {dummyQuoteId}, new List<String>())
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE Id IN :bind0 OR (MasterQuote__c IN :bind0 AND IsMultiProductTechnicalQuote__c = true AND ServiceName__c IN :bind1)';
        String selectorName = 'selectQuotesByMasterQuoteIdToClearQLIs';
        assertQuoteSelector(selectQuotesByMasterQuoteIdToClearQLIsFactory, selectorName, expectedWhereClause, 2);

        Set<Id> bind0 = (Set<Id>) selectQuotesByMasterQuoteIdToClearQLIsFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyQuoteId), getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectServiceQuotesForMasterQuoteNoService() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectServiceQuotesForMasterQuoteFactory = new QuoteSelector()
                .selectServiceQuotesForMasterQuote(dummyQuoteId, new List<String>())
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE MasterQuote__c = :bind0';
        String selectorName = 'selectServiceQuotesForMasterQuote';
        assertQuoteSelector(selectServiceQuotesForMasterQuoteFactory, selectorName, expectedWhereClause, 1);

        Id bind0 = (Id) selectServiceQuotesForMasterQuoteFactory.bindings[0];
        System.assertEquals(dummyQuoteId, bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectQuotesWithApprovedPOCApprovals() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuotesWithApprovedPOCApprovalsFactory = new QuoteSelector()
                .selectQuotesWithApprovedPOCApprovals(dummyOppId, new Set<String>())
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE Status__c = \'' + ApprovalHelper.STATUS_APPROVED +
        '\' AND RecordType.Name = \'' + ApprovalHelper.RT_NAME_POC_ACCOUNT + '\'';
        String selectorName = 'selectQuotesWithApprovedPOCApprovals';
        assertQuoteSelector(selectQuotesWithApprovedPOCApprovalsFactory, selectorName, expectedWhereClause, 2);

        Id bind0 = (Id) selectQuotesWithApprovedPOCApprovalsFactory.bindings[0];
        System.assertEquals(dummyOppId, bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
    }

    @isTest
    static void testSelectQuotesForDQWidget() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectQuotesForDQWidgetFactory = new QuoteSelector()
                .selectQuotesForDQWidget(new Set<Id> {dummyOppId}, new Set<String>())
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE OpportunityId IN :bind0 AND RecordTypeId IN :bind1';
        String selectorName = 'selectQuotesForDQWidget';
        assertQuoteSelector(selectQuotesForDQWidgetFactory, selectorName, expectedWhereClause, 2);

        Set<Id> bind0 = (Set<Id>) selectQuotesForDQWidgetFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyOppId), getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
    }

    @isTest
    static void testSelectPrimaryQuotesForDqBatchSync() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectPrimaryQuotesForDqBatchSyncFactory = new QuoteSelector()
                .selectPrimaryQuotesForDqBatchSync(new List<Object> {dummyOppId})
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE OpportunityId IN :bind0 AND isPrimary__c = true';
        String selectorName = 'selectPrimaryQuotesForDqBatchSync';
        assertQuoteSelector(selectPrimaryQuotesForDqBatchSyncFactory, selectorName, expectedWhereClause, 1);

        Id bind0 = (Id) selectPrimaryQuotesForDqBatchSyncFactory.bindings[0];
        System.assertEquals(bind0, dummyOppId, getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectActiveQuotesWithCancelledAccountStatus() {
        Test.startTest();
            QueryFactory selectActiveQuotesWithCancelledAccountStatusFactory = new QuoteSelector()
                .selectActiveQuotesWithCancelledAccountStatus()
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE Status = \'' + QuoteHelper.QUOTE_STATUS_ACTIVE + '\' AND Account__r.RC_Account_Status__c = \'Canceled\'';
        String selectorName = 'selectActiveQuotesWithCancelledAccountStatus';
        assertQuoteSelector(selectActiveQuotesWithCancelledAccountStatusFactory, selectorName, expectedWhereClause, 0);
    }

    @isTest
    static void testSelectChildQuotes() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        List<Object> bindings = new List<Object> {new Set<Id> {dummyQuoteId}};

        Test.startTest();
            QueryFactory selectChildQuotesFactory = new QuoteSelector()
                .selectChildQuotes(bindings)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE ParentQuote__c IN :bind0';
        String selectorName = 'selectChildQuotes';
        assertQuoteSelector(selectChildQuotesFactory, selectorName, expectedWhereClause, bindings.size());

        Set<Id> bind0 = (Set<Id>) selectChildQuotesFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyQuoteId), getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectCCQuoteForDQSync() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory selectCCQuoteForDQSyncFactory = new QuoteSelector()
                .selectCCQuoteForDQSync(dummyOppId)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE OpportunityId = :bind0 AND RecordTypeId = \'' + QuoteHelper.RT_ID_CC + '\'';
        String selectorName = 'SelectCCQuoteForDQSync';
        assertQuoteSelector(selectCCQuoteForDQSyncFactory, selectorName, expectedWhereClause, 1);

        System.assertEquals(dummyOppId, (Id) selectCCQuoteForDQSyncFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(1, selectCCQuoteForDQSyncFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectTechQuoteForClose() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
        QueryFactory selectTechQuoteForCloseFactory = new QuoteSelector()
            .selectTechQuotesForClose(new List<Object>{dummyOppId})
            .setQuery();
        Test.stopTest();
        
        String selectorName = 'selectTechQuotesForClose';

        System.assertEquals(dummyOppId, (Id) selectTechQuoteForCloseFactory.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(1, selectTechQuoteForCloseFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuotesForMultiSignUp() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory SelectQuotesForMultiSignUpFactory = new QuoteSelector()
                .selectQuotesForMultiSignUp(new Set<Id> {dummyOppId})
                .setQuery();
        Test.stopTest();

        QuoteSelector selector = new QuoteSelector();
        String expectedWhereClause = selector.buildQueryConditionForSignUp('Id');
        String selectorName = 'SelectQuotesForMultiSignUp';
        assertQuoteSelector(SelectQuotesForMultiSignUpFactory, selectorName, expectedWhereClause, 2);

        Set<Id> bind0 = (Set<Id>) SelectQuotesForMultiSignUpFactory.bindings[0];
        System.assertEquals(true, bind0.contains(dummyOppId), getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        System.assertEquals(2, SelectQuotesForMultiSignUpFactory.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    private static void testSelectQuotesForShippingByOppIds() {

        List<Opportunity> testOpps = (List<Opportunity>) new OpportunitySelector()
           .selectOpportunityForSyncWithNGBSByName('TestOpportunity')
           .withoutSelectorFieldsIncluded()
           .selectFields(new List<String>{'Id'})
           .executeQuery();

        Test.startTest();
            List<Quote> testQuotesByOppId =  (List<Quote>) new QuoteSelector()
                .selectQuotesForShippingByOppIds(new List<Id>{testOpps[0].Id})
                .executeQuery();
        Test.stopTest();

        System.assert(!testQuotesByOppId.isEmpty(), 'Quantity of quotes shouldn\'t be 0');
    }

    @isTest
    static void testSelectQuotesByMasterQuoteIdToCropQLIs() {
        Set<Id> masterQuoteIds = new Set<Id>{ (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue() };

        Test.startTest();
            QueryFactory selectQuotesByMasterQuoteIdToCropQLIsFactory = new QuoteSelector()
                .selectQuotesByMasterQuoteIdToCropQLIs(masterQuoteIds)
                .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE Id IN :bind0 OR MasterQuote__c IN :bind0';
        String selectorName = 'selectQuotesByMasterQuoteIdToCropQLIs';
        assertQuoteSelector(selectQuotesByMasterQuoteIdToCropQLIsFactory, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuotesByMasterQuoteIdToCropQLIsFactory.bindings[0];
        System.assertEquals(masterQuoteIds, bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectQuotesByIdToQLIsForOrderCreationProcess() {
        Set<Id> quoteIds = new Set<Id>{ (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue() };

        Test.startTest();
        QueryFactory selectQuotesByIdToQLIsForOrderCreationProcess = new QuoteSelector()
            .selectQuotesByIdToQLIsForOrderCreationProcess(quoteIds)
            .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE (Id IN :bind0 OR MasterQuote__c IN :bind0)';
        String selectorName = 'selectQuotesByIdToQLIsForOrderCreationProcess';
        assertQuoteSelector(selectQuotesByIdToQLIsForOrderCreationProcess, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuotesByIdToQLIsForOrderCreationProcess.bindings[0];
        System.assertEquals(quoteIds, bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
    }

    @isTest
    static void testSelectQuotesForOrderCreationByOppId() {
        Id oppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
        QueryFactory selectQuotesForOrderCreationByOppId = new QuoteSelector()
            .selectQuotesForOrderCreationByOppId(oppId)
            .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE OpportunityId = :bind0';
        String selectorName = 'selectQuotesForOrderCreationByOppId';
        assertQuoteSelector(selectQuotesForOrderCreationByOppId, selectorName, expectedWhereClause, 1);

        Id bind0 = (Id) selectQuotesForOrderCreationByOppId.bindings[0];
        System.assertEquals(oppId, bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted opp Id'));
    }

    @isTest
    static void testSelectQuoteForSyncWithNGBSByQuoteId() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
        QueryFactory selector = new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(dummyQuoteId)
            .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'FROM Quote WHERE Id = :bind0';
        String selectorName = 'selectQuoteForSyncWithNGBSByQuoteId';
        assertQuoteSelector(selector, selectorName, expectedWhereClause, 1);

        Assert.areEqual(dummyQuoteId, (Id) selector.bindings[0], getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
        Assert.areEqual(3, selector.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuotesByIdsToServiceInfo() {
        Set<Id> quoteIds = new Set<Id>{ (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue() };

        Test.startTest();
        QueryFactory selectQuotesByIdToQLIsForOrderCreationProcess = new QuoteSelector()
            .selectQuotesByIdsToServiceInfo(quoteIds)
            .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'WHERE Id IN :bind0';
        String selectorName = 'selectQuotesByIdsToServiceInfo';
        assertQuoteSelector(selectQuotesByIdToQLIsForOrderCreationProcess, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuotesByIdToQLIsForOrderCreationProcess.bindings[0];
        System.assertEquals(quoteIds, bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted quote Id'));
        Assert.areEqual(1, selectQuotesByIdToQLIsForOrderCreationProcess.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @isTest
    static void testSelectQuotesByOppIdsWithServiceInfos() {
        List<Id> opptyIds = new List<Id>{ (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue() };

        Test.startTest();
        QueryFactory selectQuotesByOppIdsWithServiceInfos = new QuoteSelector()
            .selectQuotesByOppIdsWithServiceInfos(opptyIds)
            .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'OpportunityId = :bind0';
        String selectorName = 'selectQuotesByOppIdsWithServiceInfos';
        assertQuoteSelector(selectQuotesByOppIdsWithServiceInfos, selectorName, expectedWhereClause, 1);

        Id bind0 = (Id) selectQuotesByOppIdsWithServiceInfos.bindings[0];
        System.assertEquals(opptyIds[0], bind0, getAssertMessageForSelector(selectorName, 'must contain the inputted opportunity Id'));
        Assert.areEqual(1, selectQuotesByOppIdsWithServiceInfos.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain one subselect query'));
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSelectLboQuotesByOppIdsForAutoSyncWithNGBS() {
        QuoteSelector selector = new QuoteSelector();
        String expectedWhereClause = selector.queryConditionForLboQuotesByOppIdsForAutoSyncWithNGBS();

        Test.startTest();
        QueryFactory selectLboQuotesByOppIdsForAutoSyncWithNGBS = selector
            .selectLboQuotesByOppIdsForAutoSyncWithNGBS(new Set<Id>())
            .setQuery();
        Test.stopTest();

        String selectorName = 'SelectLboQuotesByOppIdsForAutoSyncWithNGBS';
        assertQuoteSelector(selectLboQuotesByOppIdsForAutoSyncWithNGBS, selectorName, expectedWhereClause, 3);
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSelectMasterAndTechnicalQuotes() {
        QuoteSelector selector = new QuoteSelector();
        String expectedWhereClause = selector.buildQueryConditionForSignUp('Opportunity.MasterOpportunity__c');

        Triggers.switchOff();

        Account testAcc = TestDataGenerator.createAccount('testAcc');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAcc);
        Set<Id> oppIds = new Set<Id> { testOpp.Id };
        Quote testQuote1 = TestDataGenerator.createMasterQuote(testOpp);
        Quote testQuote2 = TestDataGenerator.createMasterQuote(testOpp);
        Quote techTestQuote1 = TestDataGenerator.createQuote(testOpp);
        Quote techTestQuote2 = TestDataGenerator.createQuote(testOpp);
        Quote testPocQuote1 = TestDataGenerator.createQuote(testOpp);
        Quote testPocQuote2 = TestDataGenerator.createQuote(testOpp);
        Quote testProServQuote = TestDataGenerator.createQuote(testOpp);
        Quote testCCProServQuote = TestDataGenerator.createQuote(testOpp);
        testQuote1.isPrimary__c = true;
        testQuote2.isPrimary__c = false;
        testPocQuote1.RecordTypeId = QuoteHelper.RT_ID_POC;
        testPocQuote2.RecordTypeId = QuoteHelper.RT_ID_POC;
        testPocQuote1.isPrimary__c = true;
        testPocQuote2.isPrimary__c = false;
        testProServQuote.RecordTypeId = QuoteHelper.RT_ID_PROSERV;
        testProServQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
        testCCProServQuote.RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV;
        testCCProServQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
        techTestQuote1.MasterQuote__c = testQuote1.Id;
        techTestQuote1.IsMultiProductTechnicalQuote__c = true;
        techTestQuote2.IsMultiProductTechnicalQuote__c = true;
        techTestQuote2.MasterQuote__c = testQuote2.Id;
        List<Quote> allTestQuotes = new List<Quote>{ testQuote1, testQuote2, testPocQuote1, testPocQuote2, testProServQuote, testCCProServQuote, techTestQuote1, techTestQuote2 };
        update allTestQuotes;

        Triggers.switchOn();

        Test.startTest();
        QueryFactory selectMasterAndTechnicalQuotes = selector
            .selectMasterAndTechnicalQuotes(new Set<Id>())
            .setQuery();        

        List<Quote> queriedQuotes = selector
            .selectMasterAndTechnicalQuotes(oppIds)
            .executeQuery();

        Test.stopTest();

        String selectorName = 'selectMasterAndTechnicalQuotes';
        assertQuoteSelector(selectMasterAndTechnicalQuotes, selectorName, expectedWhereClause, 2);

        Set<Id> expectedQuoteIds = new Set<Id>{
            testQuote1.Id,
            testPocQuote1.Id,
            testProServQuote.Id,
            testCCProServQuote.Id,
            techTestQuote1.Id
        };

        Set<Id> queriedQuoteIds = new Set<Id>();
        for (Quote q : queriedQuotes) {
            queriedQuoteIds.add(q.Id);
        }
        Assert.areEqual(expectedQuoteIds, queriedQuoteIds, 'Queried quotes matches expected quotes.');
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSelectQuotesForEndpointStatusServiceByOppId() {
        String expectedWhereClause = 'Opportunity.Id IN :bind0 AND (isPrimary__c = true OR MasterQuote__r.isPrimary__c = true)';
        Integer bindingSize = 1;

        Test.startTest();
            QueryFactory selectQuotesForEndpointStatusServiceByOppId = new QuoteSelector()
                .selectQuotesForEndpointStatusServiceByOppId(new Set<String>())
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectQuotesForEndpointStatusServiceByOppId';
        assertQuoteSelector(selectQuotesForEndpointStatusServiceByOppId, selectorName, expectedWhereClause, bindingSize);
    }

    @isTest
    static void tesSelectQuotesForOrderActivationProcess() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
        QueryFactory selectQuotesForOrderActivationProcess = new QuoteSelector()
            .selectQuotesForOrderActivationProcess(new List<Object>{new Set<Id> {dummyAccId}})
            .setQuery();
        Test.stopTest();

        String expectedWhereClause = 'AccountId IN :bind0 AND BillingPackage__c = null AND RecordTypeId = \'' + QuoteHelper.RT_ID_BILLING + '\'';
        String selectorName = 'selectQuotesForOrderActivationProcess';
        assertQuoteSelector(selectQuotesForOrderActivationProcess, selectorName, expectedWhereClause, 1);

        Set<Id> bind0 = (Set<Id>) selectQuotesForOrderActivationProcess.bindings[0];
        System.assertEquals(true, bind0.contains(dummyAccId), getAssertMessageForSelector(selectorName, 'must contain the inputted Account Ids'));
        System.assertEquals(2, selectQuotesForOrderActivationProcess.getSubselectQueries().size(), getAssertMessageForSelector(selectorName, 'must contain two subselect queries'));

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectQuotesForCreateServiceInfoBatch() {
        Set<Id> dummyAccIds = new Set<Id> {(Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue()};

        Test.startTest();
            QueryFactory factoryWithoutAccIds = new QuoteSelector()
                .selectQuotesForCreateServiceInfoBatch(new Set<Id>())
                .setQuery();
            QueryFactory factoryWithAccIds = new QuoteSelector()
                .selectQuotesForCreateServiceInfoBatch(dummyAccIds)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectQuotesForCreateServiceInfoBatch';
        String expectedWhereClause = 'WHERE CreatedDate >= LAST_N_DAYS:365 ' +
            'AND Quote_is_Invalid__c = false ' +
            'AND IsMultiProductTechnicalQuote__c = false ' +
            'AND Opportunity.IsMultiProductTechnicalOpportunity__c = false ' +
            'AND Opportunity.StageName != :bind0 ' +
            'AND (isPrimary__c = true OR Opportunity.StageName != :bind1) ' +
            'AND Id NOT IN (SELECT Quote__c FROM ServiceInfo__c)';
        List<Object> expectedBindings = new List<Object> {
            OpportunityHelper.STAGE_NAME_DOWNGRADED,
            OpportunityHelper.STAGE_NAME_CLOSED_WON
        };
        assertQuoteSelector(factoryWithOutAccIds, selectorName, expectedWhereClause, 2);
        assertBindings(
            factoryWithOutAccIds,
            selectorName,
            expectedBindings
        );

        String expectedWhereClauseForAccIds = expectedWhereClause + ' AND AccountId IN :bind2';
        expectedBindings.add(dummyAccIds);
        assertQuoteSelector(factoryWithAccIds, selectorName, expectedWhereClauseForAccIds, 3);
        assertBindings(
            factoryWithAccIds,
            selectorName,
            expectedBindings
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSelectQuotesByIdsWithRecordTypes() {
        Set<Id> quoteIds = new Set<Id> {(Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue()};

        Test.startTest();
            QueryFactory factory = new QuoteSelector()
                .selectQuotesByIdsWithRecordTypes(quoteIds)
                .setQuery();
        Test.stopTest();

        new QueryFactoryAssertBuilder(factory)
            .withBinding(quoteIds)
            .withCondition('Id IN :bind0')
            .withFields(new Set<SObjectField> {
                Quote.Id,
                Quote.RecordTypeId,
                Quote.ProServ_Status__c
            })
            .assert();
    }
}