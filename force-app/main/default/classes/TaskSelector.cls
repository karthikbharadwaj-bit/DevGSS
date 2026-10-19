public inherited sharing class TaskSelector extends SObjectSelector {
  /*
   * Activity worth summarising is a completed contact with the customer. Open tasks are to-dos,
   * mass emails and the auto-reply subject are notices, and :bind1 holds the integration users
   * whose tasks are automated (BISUAT analysis, 2026-10-08).
   */
  private static final String HUMAN_TASK_FILTER =
    ' AND IsClosed = true AND TaskSubtype != \'ListEmail\'' +
    ' AND (ActivityDate = null OR ActivityDate <= TODAY)' +
    ' AND CreatedBy.Name NOT IN :bind1' +
    ' AND (NOT Subject LIKE \'Email: Thank you for contacting us%\')';

  public TaskSelector() {
    super();
  }

  public TaskSelector(Boolean enforceCRUD, Boolean enforceFLS) {
    super(enforceCRUD, enforceFLS);
  }

  public override Schema.SObjectType getSObjectType() {
    return Task.SObjectType;
  }

  public override List<Schema.SObjectField> getDefaultFieldList() {
    return new List<Schema.SObjectField>{
      Task.Id,
      Task.Subject,
      Task.Status,
      Task.Type,
      Task.ActivityDate,
      Task.CreatedDate,
      Task.WhatId,
      Task.Description
    };
  }

  public QueryFactory selectTasksByWhatIdForOpportunitySummary(Id whatId) {
    return newQueryFactory()
      .setFactoryName('selectTasksByWhatIdForOpportunitySummary')
      .withSelectorFieldsIncluded()
      .selectFields(new List<String>{ 'Owner.Name' })
      .withoutSelectorOrderByIncluded()
      .setCondition('WhatId = :bind0')
      .addOrdering(Task.CreatedDate, QueryFactory.SortOrder.DESCENDING)
      .setQueryBindings(new List<Object>{ whatId });
  }

  public QueryFactory selectTasksByWhatIdSinceForOpportunitySummary(
    Id whatId,
    Datetime since,
    Integer rowLimit
  ) {
    return selectTasksByWhatIdForOpportunitySummary(whatId)
      .setFactoryName('selectTasksByWhatIdSinceForOpportunitySummary')
      .selectFields(
        new List<Schema.SObjectField>{
          Task.WhoId,
          Task.IsClosed,
          Task.TaskSubtype
        }
      )
      .setCondition('WhatId = :bind0 AND CreatedDate >= :bind1')
      .setQueryBindings(new List<Object>{ whatId, since })
      .setLimit(rowLimit);
  }

  /**
   * Static SOQL on purpose: QueryFactory validates fields through a describe helper compiled at
   * API 41, which predates Task.CompletedDateTime.
   */
  public List<Task> selectTaskCompletionTimesByIds(Set<Id> taskIds) {
    return [SELECT Id, CompletedDateTime FROM Task WHERE Id IN :taskIds];
  }

  /**
   * AccountId covers activities on the Account, its Opportunities, Contracts and Contacts.
   */
  public QueryFactory selectHumanTasksForAccountSummary(
    Id accountId,
    List<String> excludedCreatorNames
  ) {
    return newQueryFactory()
      .setFactoryName('selectHumanTasksForAccountSummary')
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(getAccountSummaryFieldList())
      .selectFields(getAccountSummaryRelatedFieldList())
      .setCondition('AccountId = :bind0' + HUMAN_TASK_FILTER)
      .setQueryBindings(new List<Object>{ accountId, excludedCreatorNames })
      .addOrdering(Task.ActivityDate, QueryFactory.SortOrder.DESCENDING, true);
  }

  /** Fields the Account Summary sends for this list, in payload order. */
  public List<Schema.SObjectField> getAccountSummaryFieldList() {
    return new List<Schema.SObjectField>{
      Task.Id,
      Task.Subject,
      Task.CreatedDate,
      Task.Description,
      Task.ActivityDate,
      Task.TaskSubtype,
      Task.WhatId,
      Task.Type,
      Task.CallDurationInSeconds
    };
  }

  /** Relationship fields the Account Summary sends with this list. */
  public List<String> getAccountSummaryRelatedFieldList() {
    return new List<String>{ 'What.Name', 'Who.Name', 'Owner.Name' };
  }

  /**
   * Salesforce does not roll Case activities up to the Account, so they need their own query.
   * Rows whose AccountId already matches (through the Contact) are in the account task list.
   */
  public QueryFactory selectHumanCaseTasksForAccountSummary(
    Id accountId,
    List<String> excludedCreatorNames
  ) {
    return newQueryFactory()
      .setFactoryName('selectHumanCaseTasksForAccountSummary')
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(getAccountSummaryFieldList())
      .selectFields(getAccountSummaryRelatedFieldList())
      .setCondition(
        'WhatId IN (SELECT Id FROM Case WHERE AccountId = :bind0) AND AccountId != :bind0' +
        HUMAN_TASK_FILTER
      )
      .setQueryBindings(new List<Object>{ accountId, excludedCreatorNames })
      .addOrdering(Task.ActivityDate, QueryFactory.SortOrder.DESCENDING, true);
  }
}
