public inherited sharing class RedAccountSelector extends SObjectSelector {
  private static final String ESCALATIONS_FACTORY_NAME = 'selectEscalationsForAccountSummary';

  public RedAccountSelector() {
    super();
  }

  public RedAccountSelector(Boolean enforceCRUD, Boolean enforceFLS) {
    super(enforceCRUD, enforceFLS);
  }

  public override Schema.SObjectType getSObjectType() {
    return Red_Account__c.SObjectType;
  }

  public override List<Schema.SObjectField> getDefaultFieldList() {
    return new List<Schema.SObjectField>{
      Red_Account__c.Id,
      Red_Account__c.Status__c,
      Red_Account__c.EscalatedAccount__c
    };
  }

  /**
   * Every escalation on the account, open or not: lifetime count and days in Red need the full
   * history. Newest Red start first.
   */
  public QueryFactory selectEscalationsForAccountSummary(Id accountId) {
    return newQueryFactory()
      .setFactoryName(ESCALATIONS_FACTORY_NAME)
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .setCondition('EscalatedAccount__c = :bind0')
      .setQueryBindings(new List<Object>{ accountId })
      .addOrdering(
        Red_Account__c.Red_Start_Date__c,
        QueryFactory.SortOrder.DESCENDING,
        true
      );
  }
}
