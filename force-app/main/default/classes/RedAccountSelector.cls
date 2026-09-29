public inherited sharing class RedAccountSelector extends SObjectSelector {
  private static final String FACTORY_NAME = 'selectRedAccounts';

  public RedAccountSelector() {
    super();
  }

  public RedAccountSelector(
    String relationshipName,
    SObjectType relationshipBase
  ) {
    super(relationshipName, relationshipBase);
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

  public QueryFactory selectRedAccounts() {
    return newQueryFactory()
      .setFactoryName(FACTORY_NAME)
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded();
  }
}
