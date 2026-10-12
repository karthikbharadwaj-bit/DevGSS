/* Covers the Red_Account__c selector used by Account Summary. */
@IsTest
private class Test_RedAccountSelector {
  private static final String ID_SUFFIX = '0'.repeat(12);

  @IsTest
  static void shouldQueryEscalationsNewestFirstWhenSelectingForAccountSummary() {
    Id accountId = Account.SObjectType.getDescribe().getKeyPrefix() + ID_SUFFIX;

    Test.startTest();
    QueryFactory factory = new RedAccountSelector()
      .selectEscalationsForAccountSummary(accountId)
      .selectFields(new List<Schema.SObjectField>{ Red_Account__c.Status__c })
      .setQuery();
    Test.stopTest();

    String objectMessage = 'The selector must query Red_Account__c.';
    String fieldMessage = 'The selector must keep the requested fields.';
    String conditionMessage = 'Escalations must be limited to the requested account.';
    String orderMessage = 'Escalations must be ordered by Red start date, newest first.';
    Assert.isTrue(
      factory.getQuery().contains('FROM Red_Account__c'),
      objectMessage
    );
    Assert.isTrue(
      factory.getSelectedFields().contains('Status__c'),
      fieldMessage
    );
    Assert.areEqual(
      'EscalatedAccount__c = :bind0',
      factory.getCondition(),
      conditionMessage
    );
    Assert.isTrue(
      factory.getQuery().contains('ORDER BY Red_Start_Date__c DESC'),
      orderMessage
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
  static void shouldCreateSelectorWhenUsingSecurityConstructor() {
    Test.startTest();
    RedAccountSelector securitySelector = new RedAccountSelector(true, true);
    Test.stopTest();

    String securityMessage = 'The security constructor must create a selector.';
    Assert.isNotNull(securitySelector, securityMessage);
  }
}
