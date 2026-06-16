@isTest
private class Test_DQQuoteStatusTrackerSelector {

    @isTest
    private static void testSelectAllFieldsForCloning() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Account__c => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        DQ_Quote_Status_Tracker__c testDqRecord = (DQ_Quote_Status_Tracker__c) new SObjectBuilder(DQ_Quote_Status_Tracker__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Quote_Status_Tracker__c.Quote__c => quote.Id,
                DQ_Quote_Status_Tracker__c.Quote_Status__c => 'New'
            })
            .create()
            .getRecord();

        DQ_Quote_Status_Tracker__c dqRecord = (DQ_Quote_Status_Tracker__c) new DQQuoteStatusTrackerSelector()
            .selectAllFieldsForCloning(new List<Object>{ new Set<Id>{quote.Id} })
            .executeQuery()
            .get(0);

        System.assertEquals(quote.Id, dqRecord.Quote__c, 'Quote__c should be populated');
        System.assertEquals('New', dqRecord.Quote_Status__c, 'Quote_Status__c should be populated');
    }
}