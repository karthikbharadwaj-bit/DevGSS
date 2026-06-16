@isTest
private class Test_OrderSelector {

    //Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';

    //Opportunity fields defined
    private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIRE_BRAND_NAME = 'Office';
    private static final String OPPORTUNITY_STAGE_NAME = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Quote fields defined
    private static final String QUOTE_NAME = 'testQuote';

    //Order fields defined
    private static final String ORDER_NAME = 'test';
    private static final String ORDER_STATUS = 'Requested';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Orders should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong order selected';

	@testsetup
    private static void testData(){
        Triggers.SwitchOff();
		Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ACCOUNT_NAME,
                        Account.Billing_ID__c => ACCOUNT_BILLING_ID
                    }
                )
                .create()
                .getRecord();

		Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.Name => OPPORTUNITY_NAME,
                        Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
                        Opportunity.Tier_Name__c => OPPORTUNITY_TIRE_BRAND_NAME,
                        Opportunity.StageName => OPPORTUNITY_STAGE_NAME,
                        Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE,
                        Opportunity.CloseDate => Date.newInstance(2050, 11, 11)
                        }
                )
                .create()
                .getRecord();

		Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
			.setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => QUOTE_NAME,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
                .create()
                .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.AccountId => testAcc.Id,
                    Order.Name => ORDER_NAME,
                    Order.Status => ORDER_STATUS,
                    Order.OpportunityId => testOpp.Id,
                    Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                }
            )
            .create()
            .getRecord();
    }

    @isTest
    private static void testSelectOrders(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
    }

    @isTest
    private static void testSelectOrderWithPhases(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        List<Order> orderWithPhases = (List<Order>) new OrderSelector()
            .selectOrderWithPhases(new List<Object>{new Set<Id>{orders[0].Id},
                									new Set<String>{}})
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(orders[0].Id, orderWithPhases[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectOrdersByIds(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        List<Order> ordersByIds = (List<Order>) new OrderSelector()
            .selectOrdersByIds(new List<Object>{new Set<Id>{orders[0].Id}})
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(orders[0].Id, ordersByIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectOrdersByIdsWithAmounts(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        List<Order> ordersByIdsWithAmounts = (List<Order>) new OrderSelector()
            .selectOrdersByIdsWithAmounts(new List<Object>{new Set<Id>{orders[0].Id}})
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(orders[0].Id, ordersByIdsWithAmounts[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectOrderByOrderNumber(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        List<Order> orderByOrderNumber = (List<Order>) new OrderSelector()
            .selectOrderByOrderNumber(new List<Object>{new Set<String>{orders[0].OrderNumber}})
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(orders[0].Id, orderByOrderNumber[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectOriginalSOWOrderByAccAndOppId(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        List<Order> originalSOWOrderByAccAndOppId = (List<Order>) new OrderSelector()
            .selectOriginalSOWOrderByAccAndOppId(new List<Object>{new Set<Id>{orders[0].AccountId},
                												  new Set<Id>{orders[0].OpportunityId}})
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(orders[0].Id, originalSOWOrderByAccAndOppId[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectMigratedOrdersByAccountIds(){
        List<Order> orders = (List<Order>) new OrderSelector(true, true)
            .selectOrders()
            .executeQuery();

        List<Order> ordersByAccountId = (List<Order>) new OrderSelector()
            .selectMigratedOrdersByAccountIds(orders.get(0).AccountId)
            .executeQuery();

        System.assert(orders.size() == 1, ASSERT_MESSAGE);
        System.assertEquals(orders.get(0).Id, ordersByAccountId.get(0).Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    static void testSelectNewOrdersByAccountIds() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new OrderSelector()
                .SelectNewOrdersByAccountIds(new Set<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('TechnicalAccountId__c IN :bind0'),
            'The selector must filter results by TechnicalAccountId__c'
        );
        Assert.isTrue(
            resultedQuery.contains('Status = \'' + OrderHelper.STATUS_NEW + '\''),
            'The selector must return only new Orders'
        );
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
    }

    @isTest
    static void testSelectOrdersByAccountIds() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new OrderSelector()
                .selectOrdersByAccountIds(new Set<Id> {dummyAccId})
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('TechnicalAccountId__c IN :bind0'),
            'The selector must filter results by TechnicalAccountId__c'
        );
        Assert.isTrue(
            ((Set<Id>) factory.bindings[0]).contains(dummyAccId),
            'The input Account Id must be preserved'
        );
    }

    @isTest
    static void testSelectNewOrdersByOppId() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            QueryFactory factory = new OrderSelector()
                .selectNewOrdersByOppId(dummyOppId)
                .setQuery();
        Test.stopTest();

        String resultedQuery = factory.getQuery();
        Assert.isTrue(
            resultedQuery.contains('TechnicalOpportunityId__c = :bind0'),
            'The selector must filter results by a single Opportunity Id'
        );
        Assert.areEqual(
            dummyOppId,
            (String) factory.bindings[0],
            'The input Opportunity Id must be preserved'
        );
    }

    @isTest
    static void testSelectOrdersByTechQuoteIds() {
        Set<Id> dummyQuoteIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue()};

        Test.startTest();
            QueryFactory factory = new OrderSelector()
                .selectOrdersByTechQuoteIds(dummyQuoteIds)
                .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        System.assert(query.contains('TechnicalQuoteId__c IN :bind0'), 'The selector must filter results by the set of quotes Ids');
        System.assertEquals(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        System.assertEquals(dummyQuoteIds, factory.bindings[0], 'The input Quotes Ids must be preserved');
    }

    @isTest
    static void testSelectOrdersByTechQuoteIdsForManualProvisioningCaseCreationProcessMPUB() {
        Set<Id> dummyQuoteIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersByTechQuoteIdsForManualProvisioningCaseCreationProcessMPUB(dummyQuoteIds)
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        System.assert(query.contains('TechnicalQuoteId__c IN :bind0'), 'The selector must filter results by the set of quotes Ids');
        System.assertEquals(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        System.assertEquals(dummyQuoteIds, factory.bindings[0], 'The input Quotes Ids must be preserved');

        QueryFactory orderItemSubSelector = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(orderItemSubSelector, 'The selector must have a subquery');
        Assert.areEqual(
            OrderItem.SObjectType,
            orderItemSubSelector.sObjType,
            'The selector must return related orderItems.'
        );
    }

    @isTest
    static void testSelectOrdersByIdsForManualProvisioningCaseCreationProcessMPUB() {
        Set<Id> dummyOrderIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Order.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersByIdsForManualProvisioningCaseCreationProcessMPUB(dummyOrderIds)
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        System.assert(query.contains('Id IN :bind0'), 'The selector must filter results by the set of order Ids');
        System.assertEquals(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        System.assertEquals(dummyOrderIds, factory.bindings[0], 'The input Order Ids must be preserved');

        QueryFactory orderItemSubSelector = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(orderItemSubSelector, 'The selector must have a subquery');
        Assert.areEqual(
            OrderItem.SObjectType,
            orderItemSubSelector.sObjType,
            'The selector must return related orderItems.'
        );
    }

    @IsTest
    static void selectOrdersByIdsForPhaseManagement() {
        Set<Id> dummyOrderIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Order.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersByIdsForPhaseManagement(dummyOrderIds)
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        Assert.isTrue(query.contains('Id IN :bind0'), 'The selector must filter results by the set of order Ids');
        Assert.areEqual(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        Assert.areEqual(dummyOrderIds, factory.bindings[0], 'The input Order Ids must be preserved');

        QueryFactory orderItemSubSelector = (QueryFactory) new ListOptional(factory.getSubselectQueries()).getFirst();
        Assert.isNotNull(orderItemSubSelector, 'The selector must have a subquery');
        Assert.areEqual(
            OrderItem.SObjectType,
            orderItemSubSelector.sObjType,
            'The selector must return related orderItems.'
        );
    }

    @IsTest
    static void selectOrdersForSuborderManagement() {
        Set<Id> dummyOrderIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Order.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersForSuborderManagement(new List<Object>{dummyOrderIds})
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        System.assert(query.contains('Id IN :bind0'), 'The selector must filter results by the set of order Ids');
        System.assertEquals(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        System.assertEquals(dummyOrderIds, factory.bindings[0], 'The input Order Ids must be preserved');
    }

    @IsTest
    static void testSelectOrdersForPSIntegrationManagement() {
        Set<Id> dummyOrderIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Order.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersForPSIntegrationManagement(new List<Object>{dummyOrderIds})
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        Assert.isTrue(query.contains('Id IN :bind0'), 'The selector must filter results by the set of order Ids');
        Assert.areEqual(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        Assert.areEqual(dummyOrderIds, factory.bindings[0], 'The input Order Ids must be preserved');
    }

    @IsTest
    static void testSelectOrdersWithPackage() {
        Set<Id> dummyOrderIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Order.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersWithPackage(new List<Object>{dummyOrderIds})
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        Assert.isTrue(query.contains('Id IN :bind0'), 'The selector must filter results by the set of order Ids');
        Assert.areEqual(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        Assert.areEqual(dummyOrderIds, factory.bindings[0], 'The input Order Ids must be preserved');
    }

    @IsTest
    static void testSelectProServOrderByPackageIdsUB() {
        Set<Id> dummyPackageIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Package__c.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectProServOrderByPackageIdsUB(dummyPackageIds)
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        Assert.areEqual(1, factory.bindings.size(), 'There should be exactly one set of bindings');
        Assert.areEqual(dummyPackageIds, factory.bindings[0], 'The input Package Ids must be preserved');
    }

    @IsTest
    static void testSelectOrdersByOpportunityIds() {
        Set<Id> dummyOpptyIds = new Set<Id>{(Id)new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue()};

        Test.startTest();
        QueryFactory factory = new OrderSelector()
            .selectOrdersByOpportunityIds(new List<Object>{dummyOpptyIds, new Set<String>{OrderHelper.RT_ID_PROSERV}})
            .setQuery();
        Test.stopTest();

        String query = factory.getQuery();
        Assert.isTrue(query.contains('Id IN :bind0'), 'The selector must filter results by the set of Opportunity Ids');
        Assert.areEqual(2, factory.bindings.size(), 'There should be exactly two set of bindings');
        Assert.areEqual(dummyOpptyIds, factory.bindings[0], 'The input Opportunity Ids must be preserved');
    }
}