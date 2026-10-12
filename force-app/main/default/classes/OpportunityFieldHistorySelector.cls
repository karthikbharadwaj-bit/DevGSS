public inherited sharing class OpportunityFieldHistorySelector extends SObjectSelector {

    public OpportunityFieldHistorySelector() {
        super();
    }

    public OpportunityFieldHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return OpportunityFieldHistory.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            OpportunityFieldHistory.Id,
            OpportunityFieldHistory.OpportunityId,
            OpportunityFieldHistory.Field,
            OpportunityFieldHistory.CreatedDate
        };
    }

    public QueryFactory selectFieldHistoryByOpportunityIdAndFields(Id opportunityId, Set<String> fields) {
        return newQueryFactory()
            .setFactoryName('selectFieldHistoryByOpportunityIdAndFields')
            .withSelectorFieldsIncluded()
            .selectFields(new List<String>{ 'OldValue', 'NewValue' })
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId = :bind0 AND Field IN :bind1')
            // Newest first so callers can LIMIT to recent field changes.
            .addOrdering(OpportunityFieldHistory.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{ opportunityId, fields });
    }
}
