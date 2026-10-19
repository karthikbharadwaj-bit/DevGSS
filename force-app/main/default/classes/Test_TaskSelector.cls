/* Covers the Task selector methods used by Opportunity and Account Summary. */
@IsTest
private class Test_TaskSelector {
  private static final String ID_SUFFIX = '0'.repeat(12);
  private static final Integer ROW_LIMIT = 5;

  private static Id syntheticId(Schema.SObjectType sObjectType) {
    return Id.valueOf(sObjectType.getDescribe().getKeyPrefix() + ID_SUFFIX);
  }

  // ── selectTasksByWhatIdForOpportunitySummary ───
  @IsTest
  static void shouldFilterOnWhatIdNewestFirstWhenSelectingOpportunityTasks() {
    Test.startTest();
    QueryFactory factory = new TaskSelector()
      .selectTasksByWhatIdForOpportunitySummary(
        syntheticId(Opportunity.SObjectType)
      )
      .setQuery();
    Test.stopTest();

    String message = 'Opportunity tasks must be filtered on WhatId, newest first, with the owner name.';
    Assert.areEqual('WhatId = :bind0', factory.getCondition(), message);
    Assert.isTrue(
      factory.getQuery().contains('ORDER BY CreatedDate DESC'),
      message
    );
    Assert.isTrue(factory.getQuery().contains('Owner.Name'), message);
  }

  // ── selectTasksByWhatIdSinceForOpportunitySummary ───
  @IsTest
  static void shouldAddWindowAndRowCapWhenSelectingRecentOpportunityTasks() {
    Test.startTest();
    QueryFactory factory = new TaskSelector()
      .selectTasksByWhatIdSinceForOpportunitySummary(
        syntheticId(Opportunity.SObjectType),
        Datetime.now().addDays(-30),
        ROW_LIMIT
      )
      .setQuery();
    Test.stopTest();

    String message = 'Recent tasks must be limited to the window and the caller row cap.';
    Assert.areEqual(
      'WhatId = :bind0 AND CreatedDate >= :bind1',
      factory.getCondition(),
      message
    );
    Assert.isTrue(factory.getQuery().contains('LIMIT ' + ROW_LIMIT), message);
    Assert.isTrue(factory.getQuery().contains('TaskSubtype'), message);
  }

  // ── selectTaskCompletionTimesByIds ───
  @IsTest
  static void shouldReturnNoRowsWhenNoTaskIdsGiven() {
    Test.startTest();
    List<Task> rows = new TaskSelector()
      .selectTaskCompletionTimesByIds(new Set<Id>());
    Test.stopTest();

    Assert.isTrue(rows.isEmpty(), 'An empty Id set must return no tasks.');
  }

  // ── selectHumanTasksForAccountSummary ───
  @IsTest
  static void shouldExcludeAutomatedActivityWhenSelectingAccountTasks() {
    Test.startTest();
    QueryFactory factory = new TaskSelector()
      .selectHumanTasksForAccountSummary(
        syntheticId(Account.SObjectType),
        new List<String>{ 'Automation Service' }
      )
      .setQuery();
    Test.stopTest();

    String condition = factory.getCondition();
    String message = 'Account tasks must keep only completed, human, non-notice activity.';
    Assert.isTrue(condition.startsWith('AccountId = :bind0'), message);
    Assert.isTrue(condition.contains('IsClosed = true'), message);
    Assert.isTrue(condition.contains('CreatedBy.Name NOT IN :bind1'), message);
    Assert.isTrue(condition.contains('ListEmail'), message);
  }

  // ── selectHumanCaseTasksForAccountSummary ───
  @IsTest
  static void shouldSkipTasksAlreadyOnTheAccountWhenSelectingCaseTasks() {
    Test.startTest();
    QueryFactory factory = new TaskSelector()
      .selectHumanCaseTasksForAccountSummary(
        syntheticId(Account.SObjectType),
        new List<String>{ 'Automation Service' }
      )
      .setQuery();
    Test.stopTest();

    String message = 'Case tasks must come from the account cases and skip rows already on the account.';
    Assert.isTrue(
      factory.getCondition()
        .startsWith(
          'WhatId IN (SELECT Id FROM Case WHERE AccountId = :bind0) AND AccountId != :bind0'
        ),
      message
    );
    Assert.isTrue(
      factory.getCondition().contains('CreatedBy.Name NOT IN :bind1'),
      message
    );
  }

  @IsTest
  static void shouldReturnDefaultFieldsWhenDefaultListRequested() {
    Test.startTest();
    List<Schema.SObjectField> fields = new TaskSelector().getDefaultFieldList();
    Test.stopTest();

    String message = 'The default field list must include the task Id and subject.';
    Assert.isTrue(fields.contains(Task.Id), message);
    Assert.isTrue(fields.contains(Task.Subject), message);
  }

  @IsTest
  static void shouldCreateSelectorWhenUsingSecurityConstructor() {
    Test.startTest();
    TaskSelector securitySelector = new TaskSelector(true, true);
    Test.stopTest();

    Assert.isNotNull(
      securitySelector,
      'The security constructor must create a selector.'
    );
  }
}
