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
    return new List<Schema.SObjectField>{
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

  /**
   * Status and Owner are the only tracked Account fields that change in production. An Owner change writes one row of user Ids and one of names; DataType = 'Text' keeps only the names.
   * @param accountId Account whose history is read.
   * @param createdSince Earliest history row returned.
   */
  public QueryFactory selectStatusAndOwnerChangesForAccountSummary(
    Id accountId,
    Datetime createdSince
  ) {
    return newQueryFactory()
      .setFactoryName('selectStatusAndOwnerChangesForAccountSummary')
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(getAccountSummaryFieldList())
      .setCondition(
        'AccountId = :bind0 AND Field IN (\'RC_Account_Status__c\', \'Owner\') AND DataType = \'Text\' AND CreatedDate >= :bind1'
      )
      .setQueryBindings(new List<Object>{ accountId, createdSince })
      .addOrdering(
        AccountHistory.CreatedDate,
        QueryFactory.SortOrder.DESCENDING,
        true
      );
  }

  /** Fields the Account Summary sends for this list, in payload order. */
  public List<Schema.SObjectField> getAccountSummaryFieldList() {
    return new List<Schema.SObjectField>{
      AccountHistory.Field,
      AccountHistory.OldValue,
      AccountHistory.NewValue,
      AccountHistory.CreatedDate
    };
  }
}
