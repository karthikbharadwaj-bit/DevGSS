@isTest
private class Test_AccountHistorySelector {
    private static List<Object> bindings = new List<Object>{null};

    @isTest
    static void testSelectRCAccountStatusHistoryCorrectQuery() {
        QueryFactory qf = new AccountHistorySelector()
            .selectRCAccountStatusHistory(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0, 'Should be fields for query');
        System.assert(String.isNotBlank(qf.getQuery()), 'Should be body of query');
    }
}