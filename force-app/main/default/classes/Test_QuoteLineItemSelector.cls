@IsTest
public with sharing class Test_QuoteLineItemSelector {

    @TestSetup
    private static void createTestData(){
        createData();
    }

    private static void createData() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.Name => 'Test acc'
        })
        .create()
        .getRecord();

        List<Opportunity> opp = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Type => 'Syndicated - New',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecords();

        Quote q1 = NGBSTestDataGenerator.createQuote(opp[0].Id);
		Quote q2 = NGBSTestDataGenerator.createQuote(opp[1].Id);
        new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => q1.Id,
                Order.RecordTypeId => OrderHelper.RT_ID_CC,
                Order.AccountId => acc.Id,
                Order.EffectiveDate => System.today(),
                Order.Status => 'New'
            })
            .create();

        String testElementId = 'LC_DL_75';
        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'test product',
                Product2.ExtID__c => testElementId,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.Family => Product2Helper.FAMILY_SERVICE
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => q1.Id,
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Discount__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.PackageCatalogId__c => '7',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.Active__c => true
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        new SObjectBuilder(QuoteLineItem.sObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                //QuoteLineItem.QuoteId => q.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount_number__c => 1,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                // TODO get rid of
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                QuoteLineItem.Package_Info__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                QuoteLineItem.Package_Info_QLI__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                QuoteLineItem.PackageCatalogId__c => '7',
                QuoteLineItem.PackageVersion__c => '1'
            })
            .setField(QuoteLineItem.QuoteId, ValueProviderBuilder.provideList(new List<String>{
                q1.Id,
                q2.Id
            }))
            .create();
    }

    @IsTest
    private static void test_selectQuoteLineItemsForSyncWithNGBS(){
        QueryFactory queryFactory = new QuoteLineItemSelector().selectQuoteLineItemsForSyncWithNGBS();
        List<SObject> quoteLineItems = queryFactory.executeQuery();
        System.assertEquals(2, quoteLineItems.size());
    }

    @IsTest
    private static void test_selectQuoteLineItemsByQuoteIdsForShipping(){
        Quote primaryQuote = [SELECT Id FROM Quote LIMIT 1];
        QueryFactory queryFactory = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object> {new Set<Id>{primaryQuote.Id}});
        List<SObject> quoteLineItems = queryFactory.executeQuery();
        System.assertEquals(1, quoteLineItems.size());
        System.assertEquals(false, quoteLineItems[0].get('Zero_Quantity__c'));
        System.assertEquals(primaryQuote.Id, quoteLineItems[0].get('QuoteId'));

    }

    @IsTest
    private static void test_selectQuoteLineItemsByQuoteIds(){
        Quote primaryQuote = [SELECT Id FROM Quote LIMIT 1];
        QueryFactory queryFactory = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(primaryQuote.Id);
        List<SObject> quoteLineItems = queryFactory.executeQuery();
        System.assertEquals(1, quoteLineItems.size());
        System.assertEquals(primaryQuote.Id, quoteLineItems[0].get('QuoteId'));
    }

    @IsTest
    static void test_selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields() {
        QueryFactory qf = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsToPopulateApprovedFields(new Set<Id>())
            .setQuery();

        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }


    @IsTest
    private static void test_selectQuoteLineItemsForQuoteService(){
        QueryFactory queryFactory =  new QuoteLineItemSelector()
            .selectQuoteLineItemsForQuoteService();
        List<SObject> quoteLineItems = queryFactory.executeQuery();
        System.assertEquals(2, quoteLineItems.size());

    }

    @IsTest
    private static void test_selectQuoteLineItemsByOrderId() {
        Id testOrderId = [SELECT Id FROM Order LIMIT 1].Id;
        List<SObject> quoteLineItems = new QuoteLineItemSelector()
                .selectQuoteLineItemsByOrderId(new List<Object>{testOrderId})
                .executeQuery();
        System.assertEquals(1, quoteLineItems.size());
    }

    @IsTest
    private static void test_selectQuoteLineItemsForPOCApproval() {
        List<SObject> quoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsForPOCApproval()
            .executeQuery();
        System.assertEquals(0, quoteLineItems.size(), 'There is on PoC quote line items');
    }

    @isTest
    static void test_selectQuoteLineItemsByQuoteIdsAndByProductFamilyName() {
        Quote testQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('Test quote')
            .selectField('Id')
            .executeQuery()
            .get(0);
        List<SObject> quoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsAndByProductFamilyName(new Set<Id> {testQuote.Id}, Product2Helper.FAMILY_SERVICE)
            .executeQuery();
        System.assertEquals(1, quoteLineItems.size(), 'Expected only one QLI based on the queries conditions');
    }

    @isTest
    static void test_selectQuoteLineItemsWithCustomAddressAssignments() {
        Quote testQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('Test quote')
            .selectField('Id')
            .executeQuery()
            .get(0);
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsWithCustomAddressAssignments(new List<Object>{new Set<Id>{testQuote.Id}})
            .executeQuery();
        System.assertEquals(1, qlis.size(), 'QuoteLineItems should be queried');
    }

    @IsTest
    private static void test_selectQuoteLineItemsForOrderCreationProcess() {
        List<SObject> quoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsForOrderCreationProcess()
            .executeQuery();
        System.assertEquals(2, quoteLineItems.size(), 'All QuoteLineItems should be queried');
    }

    @IsTest
    private static void testSelectQuoteLineItemsByQuoteIdAndServiceName() {
        Quote testQuote = (Quote) new QuoteSelector()
            .selectQuoteByName('Test quote')
            .selectField('Id')
            .executeQuery()
            .get(0);
        Triggers.switchOff();
        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Product2.Name => 'test'
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.ServiceName__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();
            List<QuoteLineItem> quoteLineItems = new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIdAndServiceName(new Set<Id>{testQuote.Id}, OpportunityHelper.TIER_PROFESSIONAL_SERVICES)
                .executeQuery();
        Test.stopTest();

        System.assertEquals(1, quoteLineItems.size(), 'All QuoteLineItems should be queried');
    }
    
    @isTest
    static void testSelectQuoteLineItemsForHandleBillingQuotes() {
        Set<Id> oppIds = new Set<Id>{(Id) ValueProviderBuilder.provideDummyId(Opportunity.sObjectType).getValue()};
        Set<Id> qliIds = new Set<Id>{(Id) ValueProviderBuilder.provideDummyId(QuoteLineItem.sObjectType).getValue()};

        Test.startTest();
            QueryFactory factoryWithNoQlis = new QuoteLineItemSelector().selectQuoteLineItemsForHandleBillingQuotes(oppIds, null);
            QueryFactory factoryWithQlis = new QuoteLineItemSelector().selectQuoteLineItemsForHandleBillingQuotes(oppIds, qliIds);
        Test.stopTest();

        Set<Id> expectedRecordIds = new Set<Id> { QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_CC };
        String expectedCondition = 'Quote.OpportunityId IN :bind0 AND Quote.RecordTypeId IN :bind1';
        String expectedConditionForQlis = expectedCondition + ' AND Id NOT IN :bind2';
        for (QueryFactory factory : new List<QueryFactory> {factoryWithQlis, factoryWithNoQlis}) {
            Assert.isNotNull(factory, 'QueryFactory should not be null');
            Assert.areEqual(oppIds, factory.bindings[0], 'The factory should filter by oppIds');
            Assert.isTrue(expectedRecordIds.containsAll((Set<Id>) factory.bindings[1]), 'Correct record types should be used for filtering');
        }
        Assert.areEqual(
            expectedCondition,
            factoryWithNoQlis.getCondition(),
            'Unexpected condition is used for factory without qliIds'
        );
        Assert.areEqual(
            expectedConditionForQlis,
            factoryWithQlis.getCondition(),
            'Unexpected condition is used for factory with qliIds'
        );
        Assert.areEqual(qliIds, factoryWithQlis.bindings[2], 'If qliIds are present, the factory should filter by them');
    }

    @isTest
    static void testQuoteLineItemsForHandleQuotes() {
        Set<Id> quoteIds = new Set<Id>{(Id) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue()};
        Set<Id> qliIds = new Set<Id>{(Id) ValueProviderBuilder.provideDummyId(QuoteLineItem.sObjectType).getValue()};

        Test.startTest();
            QueryFactory factoryWithNoQlis = new QuoteLineItemSelector().selectQuoteLineItemsForHandleQuotes(quoteIds, null);
            QueryFactory factoryWithQlis = new QuoteLineItemSelector().selectQuoteLineItemsForHandleQuotes(quoteIds, qliIds);
        Test.stopTest();

        String expectedCondition = 'QuoteId IN :bind0';
        String expectedConditionForQlis = expectedCondition + ' AND Id NOT IN :bind1';
        for (QueryFactory factory : new List<QueryFactory> {factoryWithQlis, factoryWithNoQlis}) {
            Assert.isNotNull(factory, 'QueryFactory should not be null');
            Assert.areEqual(quoteIds, factory.bindings[0], 'The factory should filter by quoteIds');
        }
        Assert.areEqual(
            expectedCondition,
            factoryWithNoQlis.getCondition(),
            'Unexpected condition is used for factory without qliIds'
        );
        Assert.areEqual(
            expectedConditionForQlis,
            factoryWithQlis.getCondition(),
            'Unexpected condition is used for factory with qliIds'
        );
        Assert.areEqual(qliIds, factoryWithQlis.bindings[1], 'If qliIds are present, the factory should filter by them');
    }
}