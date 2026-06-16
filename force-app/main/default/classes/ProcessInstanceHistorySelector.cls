public inherited sharing class ProcessInstanceHistorySelector extends SObjectSelector {

    public ProcessInstanceHistorySelector() {
        super();
    }

    public ProcessInstanceHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ProcessInstanceHistory.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ProcessInstanceHistory.StepStatus,
            ProcessInstanceHistory.CreatedDate,
            ProcessInstanceHistory.ActorId
        };
    }

    public List<String> getExtraFields() {
        return new List<String> {
            'OriginalActor.Name'
        };
    }

    public QueryFactory selectStepsAndWorkItemsForApproval() {
        return newQueryFactory()
                .setFactoryName('selectStepsAndWorkItemsForApproval')
                .withSelectorFieldsIncluded()
                .selectFields(getExtraFields())
                .withoutSelectorOrderByIncluded()
                .setCondition('OriginalActor.Name = \'Finance Invoice Approval\'')
                .addOrdering('CreatedDate', QueryFactory.SortOrder.ASCENDING);
    }

    public QueryFactory selectPendingSteps() {
        return newQueryFactory()
            .setFactoryName('selectPendingSteps')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('StepStatus = \'Pending\'');
    }
}