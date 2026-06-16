public inherited sharing class AccountHistorySelector extends SObjectSelector {
    public AccountHistorySelector() {
        super();
    }

    public AccountHistorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override Schema.SObjectType getSObjectType() {
        return AccountHistory.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AccountHistory.Id,
            AccountHistory.AccountId,
            AccountHistory.Field,
            AccountHistory.NewValue,
            AccountHistory.OldValue
        };
    }

    public QueryFactory selectRCAccountStatusHistory(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectRCAccountStatusHistory')
            .selectFields(getDefaultFieldList())
            .setCondition('AccountId = :bind0 AND Field = \'RC_Account_Status__c\'')
            .withSelectorOrderByIncluded()
            .addOrdering('CreatedDate', QueryFactory.SortOrder.ASCENDING)
            .setQueryBindings(bindings);
    }
}