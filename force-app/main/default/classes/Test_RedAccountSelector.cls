/* Covers the Red_Account__c selector used by Account Summary. */
@IsTest
private class Test_RedAccountSelector {
  @IsTest
  static void shouldBuildRedAccountQueryWhenSelectingRedAccounts() {
    Test.startTest();
    QueryFactory factory = new RedAccountSelector()
      .selectRedAccounts()
      .selectFields(new List<Schema.SObjectField>{ Red_Account__c.Status__c })
      .setQuery();
    Test.stopTest();

    String objectMessage = 'The selector must query Red_Account__c.';
    String fieldMessage = 'The selector must keep the requested fields.';
    Assert.isTrue(
      factory.getQuery().contains('FROM Red_Account__c'),
      objectMessage
    );
    Assert.isTrue(
      factory.getSelectedFields().contains('Status__c'),
      fieldMessage
    );
  }

  @IsTest
  static void shouldReturnDefaultFieldsWhenDefaultListRequested() {
    Test.startTest();
    List<Schema.SObjectField> fields = new RedAccountSelector()
      .getDefaultFieldList();
    Test.stopTest();

    String defaultFieldMessage = 'The default field list must include the Red Account Id.';
    Assert.isTrue(fields.contains(Red_Account__c.Id), defaultFieldMessage);
  }

  @IsTest
  static void shouldCreateSelectorWhenUsingAlternateConstructors() {
    Test.startTest();
    RedAccountSelector relationshipSelector = new RedAccountSelector(
      'Escalations__r',
      Account.SObjectType
    );
    RedAccountSelector securitySelector = new RedAccountSelector(true, true);
    Test.stopTest();

    String relationshipMessage = 'The relationship constructor must create a selector.';
    String securityMessage = 'The security constructor must create a selector.';
    Assert.isNotNull(relationshipSelector, relationshipMessage);
    Assert.isNotNull(securitySelector, securityMessage);
  }
}
