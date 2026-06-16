@isTest
public with sharing class Test_DealDeskCaseDescriptionSelector {

    @isTest
    private static void testSelectDealDeskCaseDescriptionsForAccounts() {
        Id dummyAccId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        String query = new DealDeskCaseDescriptionSelector()
            .selectDealDeskCaseDescriptionsForAccounts(new List<Object> {new Set<Id> {dummyAccId}})
            .setQuery()
            .getQuery();

        String expectedWhereClause = 'WHERE Account__c IN :bind0';
        String expectedFrom = 'FROM DealDeskCaseDescription__c';

        System.assert(query.contains(expectedFrom) && query.contains(expectedWhereClause),
            'selectDealDeskCaseDescriptionsForAccounts should reflect a proper query');
    }
}