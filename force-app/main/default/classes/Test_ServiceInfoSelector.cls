@isTest
private class Test_ServiceInfoSelector {
    private final static String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';

    @isTest
    private static void verifySelectServiceInfoForNGBSSyncablesByQuoteIdReturnCorrectQuery() {
        QueryFactory qf = new ServiceInfoSelector()
            .selectServiceInfoForNGBSSyncablesByQuoteId(null)
            .setQuery();

        String pattern = basePattern + '(FROM ServiceInfo__c WHERE Quote__c IN :bind0 ORDER BY Name ASC NULLS FIRST )';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }

    @isTest
    static void verifyselectServiceInfoForClone() {
        List<Id> quoteIds = new List<Id>{ (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue() };
        QueryFactory qf = new ServiceInfoSelector()
            .selectServiceInfoForClone(quoteIds)
            .setQuery();
        String pattern = basePattern + '(FROM ServiceInfo__c WHERE Quote__c = :bind0 or Quote__r.MasterQuote__c = :bind0 ORDER BY Name ASC NULLS FIRST )';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }

    @isTest
    static void verifySelectServiceInfoForNGBSSyncablesById() {
        QueryFactory qf = new ServiceInfoSelector()
            .selectServiceInfoForNGBSSyncablesById(null)
            .setQuery();

        String pattern = basePattern + '(FROM ServiceInfo__c WHERE Id IN :bind0 ORDER BY Name ASC NULLS FIRST )';
        System.assert(System.Pattern.matches(pattern, qf.getQuery()));
        Assert.isTrue(qf.fields.size() > 0, 'Fields are not selected');
        Assert.isTrue(String.isNotBlank(qf.getQuery()), 'Query is empty');
    }
}