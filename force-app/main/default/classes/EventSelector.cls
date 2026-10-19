public class EventSelector extends SObjectSelector {
  public EventSelector() {
    super();
  }
  public EventSelector(Boolean enforceCRUD, Boolean enforceFLS) {
    super(enforceCRUD, enforceFLS);
  }
  public override Schema.SObjectType getSObjectType() {
    return Event.SObjectType;
  }

  public override List<Schema.SObjectField> getDefaultFieldList() {
    return new List<Schema.SObjectField>{
      Event.Id,
      Event.WhoId,
      Event.WhatId,
      Event.CreatedDate,
      Event.Type,
      Event.Appointment_Source__c
    };
  }

  public QueryFactory selectEventsByWhatIds(Set<Id> whatIds) {
    return newQueryFactory()
      .setFactoryName('selectEventsByWhatIds')
      .setCondition('WhatId IN :bind0')
      .setQueryBindings(new List<Object>{ whatIds });
  }

  public QueryFactory selectEventsByWhatIdSinceForSummary(
    Id whatId,
    Datetime since,
    Integer rowLimit
  ) {
    return newQueryFactory()
      .setFactoryName('selectEventsByWhatIdSinceForSummary')
      .selectFields(
        new List<Schema.SObjectField>{
          Event.Id,
          Event.WhoId,
          Event.Subject,
          Event.StartDateTime,
          Event.EndDateTime,
          Event.CreatedDate,
          Event.OwnerId,
          Event.Description
        }
      )
      .withoutSelectorOrderByIncluded()
      .setCondition('WhatId IN :bind0 AND StartDateTime >= :bind1')
      .setQueryBindings(new List<Object>{ new Set<Id>{ whatId }, since })
      .addOrdering(Event.StartDateTime, QueryFactory.SortOrder.DESCENDING)
      .setLimit(rowLimit);
  }

  /*
   * System Use events are integration records on Implementation__c, not meetings. Past and upcoming
   * split on StartDateTime, because a meeting later today has an ActivityDate of today.
   */
  public QueryFactory selectPastEventsForAccountSummary(
    Id accountId,
    Datetime asOf
  ) {
    return newQueryFactory()
      .setFactoryName('selectPastEventsForAccountSummary')
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(getAccountSummaryFieldList())
      .selectFields(getAccountSummaryRelatedFieldList())
      .setCondition(
        'AccountId = :bind0 AND StartDateTime <= :bind1 AND Type != \'System Use\''
      )
      .setQueryBindings(new List<Object>{ accountId, asOf })
      .addOrdering(
        Event.StartDateTime,
        QueryFactory.SortOrder.DESCENDING,
        true
      );
  }

  /** Fields the Account Summary sends for this list, in payload order. */
  public List<Schema.SObjectField> getAccountSummaryFieldList() {
    return new List<Schema.SObjectField>{
      Event.Id,
      Event.Subject,
      Event.CreatedDate,
      Event.Description,
      Event.ActivityDate,
      Event.StartDateTime,
      Event.DurationInMinutes,
      Event.Type,
      Event.WhatId
    };
  }

  /** Relationship fields the Account Summary sends with this list. */
  public List<String> getAccountSummaryRelatedFieldList() {
    return new List<String>{ 'What.Name', 'Who.Name', 'CreatedBy.Name' };
  }

  public QueryFactory selectUpcomingEventsForAccountSummary(
    Id accountId,
    Datetime asOf,
    Datetime until
  ) {
    return newQueryFactory()
      .setFactoryName('selectUpcomingEventsForAccountSummary')
      .withoutSelectorFieldsIncluded()
      .withoutSelectorOrderByIncluded()
      .selectFields(getAccountSummaryFieldList())
      .selectFields(getAccountSummaryRelatedFieldList())
      .setCondition(
        'AccountId = :bind0 AND StartDateTime > :bind1 AND StartDateTime <= :bind2 AND Type != \'System Use\''
      )
      .setQueryBindings(new List<Object>{ accountId, asOf, until })
      .addOrdering(Event.StartDateTime, QueryFactory.SortOrder.ASCENDING, true);
  }
}
