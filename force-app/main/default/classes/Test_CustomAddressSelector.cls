@isTest
public with sharing class Test_CustomAddressSelector {

    @isTest
    private static void testSelectCustomAddressesByIds() {
        Id dummyAddressId = (Id) new ValueProvider.DummyIdProvider(CustomAddress__c.sObjectType).getValue();

        String query = new CustomAddressSelector()
            .selectCustomAddressesByIds(new List<Object> {new Set<Id> {dummyAddressId}})
            .setQuery()
            .getQuery();

        String expectedWhereClause = 'WHERE Id IN :bind0';
        String expectedFrom = 'FROM CustomAddress__c';

        System.debug('query = ' + query);
        System.assert(query.contains(expectedFrom) && query.contains(expectedWhereClause),
            'selectCustomAddressesByIds should reflect a proper query');
    }

}