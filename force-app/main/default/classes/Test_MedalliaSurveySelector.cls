@isTest
private class Test_MedalliaSurveySelector {
    private static String basePattern = '(^SELECT){1}(\\s[A-z0-9.]+,?\\s?)+';
    private static List<Object> bindings = new List<Object> {new Set<Id> {null}};

    @isTest
    static void testSelectMedalliaSurveysByCaseId() {
        QueryFactory queryFactory = new MedalliaSurveySelector()
            .selectMedalliaSurveysByCaseId(bindings)
            .setQuery();
        String last = '(FROM Medallia_Survey__c WHERE Case_SFDC_ID__c IN :bind0)';
        String pattern = basePattern + last;
		Assert.isFalse(queryFactory.fields.isEmpty(), 'Query does not contain fields');
        Assert.isFalse(String.isBlank(queryFactory.getQuery()), 'Query is empty');
    }
}