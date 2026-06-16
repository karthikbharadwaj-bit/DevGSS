@isTest
private class Test_CustomAddressAssignmentsSelector {

    static void assertSelector(QueryFactory factory, String selectorName, String expectedWhereClause, Integer bindingSize) {
        String query = factory.getQuery();

        Assert.isNotNull(factory, getAssertMessageForSelector(selectorName, 'must return QuoteFactory'));
        Assert.isFalse(String.isBlank(query), getAssertMessageForSelector(selectorName, 'must compose a string query'));
        Assert.isTrue(query.contains(expectedWhereClause), getAssertMessageForSelector(selectorName, 'must have the right WHERE clause'));
        Assert.areEqual(bindingSize, factory.bindings.size(), getAssertMessageForSelector(selectorName, 'must have ' + bindingSize + ' input binding variable'));
    }

    static String getAssertMessageForSelector(String selectorName, String assertMessage) {
        return selectorName + ' ' + assertMessage;
    }

    @isTest
    static void testSelectCustomAddressAssignmentsByOppIds() {
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        List<Id> dummyIds = new List<Id> { dummyId };

        Test.startTest();
            QueryFactory qFactory = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignmentsByOppIds(dummyIds)
                .setQuery();
        Test.stopTest();
     
        String selectorName = 'selectCustomAddressAssignmentsByOppIds';
        String expectedWhereClause = 'WHERE QuoteLineItem__r.Quote.OpportunityId IN :bind0';
        List<Object> expectedBindings = new List<Object> { dummyIds };

        assertSelector(qFactory, selectorName, expectedWhereClause, expectedBindings.size());
        Assert.isTrue(new Set<Id>(dummyIds).containsAll((List<Id>) qFactory.bindings[0]), 'selectCustomAddressAssignmentsByOppIds must contain all input values');
    
    }

    @isTest
    static void verifySelectCustomAddressAssignmentsByQliIds() {
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType).getValue();
        List<Id> dummyIds = new List<Id> { dummyId };

        Test.startTest();
            QueryFactory qFactory = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignmentsByQliIds(dummyIds)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectCustomAddressAssignmentsByQliIds';
        String expectedWhereClause = 'WHERE QuoteLineItem__c IN :bind0';
        List<Object> expectedBindings = new List<Object> { dummyIds };

        assertSelector(qFactory, selectorName, expectedWhereClause, expectedBindings.size());
        Assert.isTrue(new Set<Id>(dummyIds).containsAll((List<Id>) qFactory.bindings[0]), 'selectCustomAddressAssignmentsByQliIds must contain all input values');

    }

    @isTest
    static void testSelectCustomAddressAssignmentsByQuoteIds() {
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        Set<Id> dummyIds = new Set<Id> { dummyId };

        Test.startTest();
            QueryFactory qFactory = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignmentsByQuoteIds(dummyIds)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectCustomAddressAssignmentsByQuoteIds';
        String expectedWhereClause = 'WHERE QuoteLineItem__r.QuoteId IN :bind0';
        List<Object> expectedBindings = new List<Object> { dummyIds };

        assertSelector(qFactory, selectorName, expectedWhereClause, expectedBindings.size());
        Assert.isTrue(dummyIds.containsAll((Set<Id>) qFactory.bindings[0]), 'selectCustomAddressAssignmentsByQuoteIds must contain all input values');
    }

    @isTest
    static void testSelectCAAForShipping() {
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType).getValue();
        Set<Id> dummyIds = new Set<Id> { dummyId };
        List<Object> expectedBindings = new List<Object> { dummyIds };

        Test.startTest();
            QueryFactory qFactory = new CustomAddressAssignmentsSelector()
                .selectCAAForShipping(expectedBindings)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectCAAForShipping';
        String expectedWhereClause = 'WHERE QuoteLineItem__c IN :bind0';

        assertSelector(qFactory, selectorName, expectedWhereClause, expectedBindings.size());
        Assert.isTrue(dummyIds.containsAll((Set<Id>) qFactory.bindings[0]), 'selectCAAForShipping must contain all input values');
    }

    @isTest
    static void testSelectAllFieldsForCloning() {
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType).getValue();
        Set<Id> dummyIds = new Set<Id> { dummyId };
        List<Object> expectedBindings = new List<Object> { dummyIds };

        Test.startTest();
            QueryFactory qFactory = new CustomAddressAssignmentsSelector()
                .selectAllFieldsForCloning(expectedBindings)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectAllFieldsForCloning';
        String expectedWhereClause = 'WHERE QuoteLineItem__c IN :bind0';

        assertSelector(qFactory, selectorName, expectedWhereClause, expectedBindings.size());
        Assert.isTrue(dummyIds.containsAll((Set<Id>) qFactory.bindings[0]), 'selectAllFieldsForCloning must contain all input values');
    }

    @isTest
    static void testSelectTechnicalCAA() {
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType).getValue();
        Set<Id> dummyIds = new Set<Id> { dummyId };

        Test.startTest();
            QueryFactory qFactory = new CustomAddressAssignmentsSelector()
                .selectTechnicalCAA(dummyIds)
                .setQuery();
        Test.stopTest();

        String selectorName = 'selectTechnicalCAA';
        String expectedWhereClause = 'WHERE QuoteLineItem__r.MasterQLI__c IN :bind0';
        List<Object> expectedBindings = new List<Object> { dummyIds };

        assertSelector(qFactory, selectorName, expectedWhereClause, expectedBindings.size());
        Assert.isTrue(dummyIds.containsAll((Set<Id>) qFactory.bindings[0]), 'selectTechnicalCAA must contain all input values');
    }
}