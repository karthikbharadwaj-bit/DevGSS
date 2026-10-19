public inherited sharing class RetentionTaskSelector extends SObjectSelector {
  public RetentionTaskSelector() {
    super();
  }

  public RetentionTaskSelector(
    String relationshipName,
    SObjectType relationshipBase
  ) {
    super(relationshipName, relationshipBase);
  }

  public RetentionTaskSelector(Boolean enforceCRUD, Boolean enforceFLS) {
    super(enforceCRUD, enforceFLS);
  }

  public override Schema.SObjectType getSObjectType() {
    return Retention_Task__c.SObjectType;
  }

  public override List<Schema.SObjectField> getDefaultFieldList() {
    return new List<Schema.SObjectField>{ Retention_Task__c.Id };
  }

  public QueryFactory selectRetentionTasks() {
    return newQueryFactory()
      .setFactoryName('selectRetentionTasks')
      .selectFields(getDefaultFieldList());
  }

  public QueryFactory selectRetentionTasksForAccountSummary(Id accountId) {
    return newQueryFactory()
      .setFactoryName('selectRetentionTasksForAccountSummary')
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(getAccountSummaryFieldList())
      .setCondition('Account__c = :bind0')
      .setQueryBindings(new List<Object>{ accountId })
      .addOrdering(
        Retention_Task__c.CreatedDate,
        QueryFactory.SortOrder.DESCENDING,
        true
      );
  }

  /** Fields the Account Summary sends for this list, in payload order. */
  public List<Schema.SObjectField> getAccountSummaryFieldList() {
    return new List<Schema.SObjectField>{
      Retention_Task__c.Status__c,
      Retention_Task__c.Dunning_Status__c
    };
  }
}
