/* Covers the EventRelation selector used by Opportunity Summary attendees. */
@IsTest
private class Test_EventRelationSelector {
  private static final String ID_SUFFIX = '0'.repeat(12);
  private static final Integer ROW_LIMIT = 5;

  // ── selectRelationsByEventIds ───
  @IsTest
  static void shouldFilterByParentIdsWhenSelectingRelations() {
    Set<Id> parentIds = new Set<Id>{
      Id.valueOf(Event.SObjectType.getDescribe().getKeyPrefix() + ID_SUFFIX)
    };

    Test.startTest();
    QueryFactory factory = new EventRelationSelector()
      .selectRelationsByEventIds(parentIds, ROW_LIMIT)
      .setQuery();
    Test.stopTest();

    String objectMessage = 'The selector must query EventRelation.';
    String conditionMessage = 'Relations must be limited to the requested parents.';
    String limitMessage = 'The caller row cap must be applied.';
    Assert.isTrue(
      factory.getQuery().contains('FROM EventRelation'),
      objectMessage
    );
    Assert.areEqual(
      'EventId IN :bind0',
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
    List<SObject> rows = new EventRelationSelector()
      .selectRelationsByEventIds(new Set<Id>(), ROW_LIMIT)
      .executeQuery();
    Test.stopTest();

    String emptyMessage = 'An empty Id set must return no relations.';
    Assert.isTrue(rows.isEmpty(), emptyMessage);
  }

  @IsTest
  static void shouldReturnDefaultFieldsWhenDefaultListRequested() {
    Test.startTest();
    List<Schema.SObjectField> fields = new EventRelationSelector()
      .getDefaultFieldList();
    Test.stopTest();

    String defaultFieldMessage = 'The default field list must include the relation Id.';
    Assert.isTrue(
      fields.contains(EventRelation.RelationId),
      defaultFieldMessage
    );
    Assert.isTrue(fields.contains(EventRelation.EventId), defaultFieldMessage);
  }

  @IsTest
  static void shouldCreateSelectorWhenUsingSecurityConstructor() {
    Test.startTest();
    EventRelationSelector securitySelector = new EventRelationSelector(
      true,
      true
    );
    Test.stopTest();

    String securityMessage = 'The security constructor must create a selector.';
    Assert.isNotNull(securitySelector, securityMessage);
  }
}
