@isTest
public class Test_CaseHistorySelector {

    private static List<Object> bindings = new List<Object>{null};

    @isTest
    static void testSelectCaseHistoriesForCasesAndByField() {
        QueryFactory qf = new CaseHistorySelector()
            .selectCaseHistoriesForCasesAndByField(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0, 'Should be fields for query');
        System.assert(String.isNotBlank(qf.getQuery()), 'Should be body of query');
    }

    @isTest
    static void testSelectCaseHistoriesByCaseIdAndFieldAndNewValue() {
        QueryFactory qf = new CaseHistorySelector(false, false)
            .selectCaseHistoriesByCaseIdAndFieldAndNewValue(bindings)
            .setQuery();
        System.assert(qf.fields.size() > 0, 'Should be fields for query');
        System.assert(String.isNotBlank(qf.getQuery()), 'Should be body of query');
    }
}