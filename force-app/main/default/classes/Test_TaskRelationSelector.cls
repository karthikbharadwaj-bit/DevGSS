/* Covers the TaskRelation selector used by Opportunity Summary participants. */
@IsTest
private class Test_TaskRelationSelector {
  private static final String ID_SUFFIX = '0'.repeat(12);
  private static final Integer ROW_LIMIT = 5;

  // ── selectWhoRelationsByTaskIds ───
  @IsTest
  static void shouldFilterByParentIdsWhenSelectingRelations() {
    Set<Id> parentIds = new Set<Id>{
      Id.valueOf(Task.SObjectType.getDescribe().getKeyPrefix() + ID_SUFFIX)
    };

    Test.startTest();
    QueryFactory factory = new TaskRelationSelector()
      .selectWhoRelationsByTaskIds(parentIds, ROW_LIMIT)
      .setQuery();
    Test.stopTest();

    String objectMessage = 'The selector must query TaskRelation.';
    String conditionMessage = 'Relations must be limited to the requested parents.';
    String limitMessage = 'The caller row cap must be applied.';
    Assert.isTrue(
      factory.getQuery().contains('FROM TaskRelation'),
      objectMessage
    );
    Assert.areEqual(
      'TaskId IN :bind0 AND IsWhat = false',
      factory.getCondition(),
      conditionMessage
    );
    Assert.isTrue(
      factory.getQuery().contains('LIMIT ' + ROW_LIMIT),
      limitMessage
    );
  }

  @IsTest
  static void shouldReturnNoRowsWhenNoParentIdsGiven() {
    Test.startTest();
    List<SObject> rows = new TaskRelationSelector()
      .selectWhoRelationsByTaskIds(new Set<Id>(), ROW_LIMIT)
      .executeQuery();
    Test.stopTest();

    String emptyMessage = 'An empty Id set must return no relations.';
    Assert.isTrue(rows.isEmpty(), emptyMessage);
  }

  @IsTest
  static void shouldReturnDefaultFieldsWhenDefaultListRequested() {
    Test.startTest();
    List<Schema.SObjectField> fields = new TaskRelationSelector()
      .getDefaultFieldList();
    Test.stopTest();

    String defaultFieldMessage = 'The default field list must include the relation Id.';
    Assert.isTrue(
      fields.contains(TaskRelation.RelationId),
      defaultFieldMessage
    );
    Assert.isTrue(fields.contains(TaskRelation.TaskId), defaultFieldMessage);
  }

  @IsTest
  static void shouldCreateSelectorWhenUsingSecurityConstructor() {
    Test.startTest();
    TaskRelationSelector securitySelector = new TaskRelationSelector(
      true,
      true
    );
    Test.stopTest();

    String securityMessage = 'The security constructor must create a selector.';
    Assert.isNotNull(securitySelector, securityMessage);
  }
}
