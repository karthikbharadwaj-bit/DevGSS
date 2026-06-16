public inherited sharing class CaseHistorySelector extends SObjectSelector {

    public CaseHistorySelector() {
        super();
    }

    public CaseHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return CaseHistory.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            CaseHistory.Id
        };
    }

    public QueryFactory selectCaseHistoriesByCaseIdAndFieldAndNewValue(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseHistoriesByCaseIdAndFieldAndNewValue')
            .selectFields(new String[]{
                'newValue',
                'caseId',
                'Field'
            })
            .setCondition('CaseId = :bind0 AND Field = :bind1')
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCaseHistoriesForCasesAndByField(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCaseHistoriesForCasesAndByField')
            .selectFields(new String[]{
                'Id',
                'CaseId',
                'Field',
                'NewValue',
                'OldValue',
                'CreatedDate'
            })
            .setCondition('CaseId IN :bind0 AND Field = :bind1')
            .addOrdering(CaseHistory.CreatedDate, QueryFactory.SortOrder.DESCENDING )
            .setQueryBindings(bindings);
    }
}