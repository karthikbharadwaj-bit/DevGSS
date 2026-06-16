public inherited sharing class ProcessInstanceSelector extends SObjectSelector {

    public ProcessInstanceSelector() {
        super();
    }

    public ProcessInstanceSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType()  {
        return ProcessInstance.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            ProcessInstance.TargetObjectId,
            ProcessInstance.LastActorId,
            ProcessInstance.Status,
            ProcessInstance.CompletedDate
        };
    }

    public List<String> getExtraFields() {
        return new List<String> {
            'LastActor.Name'
        };
    }

    public QueryFactory selectLastProcessInstanceInApprovedStatus() {
        return newQueryFactory()
            .setFactoryName('selectLastProcessInstanceInApprovedStatus')
            .setCondition('Status = \'Approved\'')
            .addOrdering('CompletedDate', QueryFactory.SortOrder.DESCENDING)
            .setLimit(1);
    }

    public QueryFactory selectProcessInstancesForApproval(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectProcessInstancesForApproval')
            .withSelectorFieldsIncluded()
            .selectFields(getExtraFields())
            .withoutSelectorOrderByIncluded()
            .subselect(new ProcessInstanceHistorySelector().selectStepsAndWorkItemsForApproval())
            .setCondition('TargetObjectId IN :bind0')
            .setQueryBindings(bindings)
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING);
    }

    public QueryFactory selectProcessInstanceByQuoteIds(Set<Id> quoteIdSet) {
        return newQueryFactory()
            .setFactoryName('selectProcessInstanceByQuoteIds')
            .withSelectorFieldsIncluded()
            .selectFields(getExtraFields())
            .withoutSelectorOrderByIncluded()
            .subselect(new ProcessInstanceHistorySelector().selectPendingSteps())
            .setCondition('TargetObjectId in :bind0')
            .setQueryBindings(new List<Object>{ quoteIdSet });
    }
}