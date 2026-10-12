public inherited sharing class OpportunityHistorySelector extends SObjectSelector {

    public OpportunityHistorySelector() {
        super();
    }

    public OpportunityHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return OpportunityHistory.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            OpportunityHistory.Id,
            OpportunityHistory.OpportunityId,
            OpportunityHistory.StageName,
            OpportunityHistory.Amount,
            OpportunityHistory.Probability,
            OpportunityHistory.CloseDate,
            OpportunityHistory.ForecastCategory,
            OpportunityHistory.CreatedDate
        };
    }

    public QueryFactory selectStageHistoryByOpportunityId(Id opportunityId) {
        return newQueryFactory()
            .setFactoryName('selectStageHistoryByOpportunityId')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('OpportunityId = :bind0')
            // Newest first so callers can LIMIT to recent stage moves.
            .addOrdering(OpportunityHistory.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setQueryBindings(new List<Object>{ opportunityId });
    }
}
