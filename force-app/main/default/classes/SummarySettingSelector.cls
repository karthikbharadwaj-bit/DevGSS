public inherited sharing class SummarySettingSelector extends SObjectSelector {
  private static final String SETTING_BY_NAME_FACTORY_NAME = 'selectSettingByDeveloperName';
  private static final String DEVELOPER_NAME_CONDITION = 'DeveloperName = :bind0';
  private static final String DEFAULT_ORDER_BY = 'DeveloperName';

  public SummarySettingSelector() {
    super();
  }

  public SummarySettingSelector(Boolean enforceCRUD, Boolean enforceFLS) {
    super(enforceCRUD, enforceFLS);
  }

  public override Schema.SObjectType getSObjectType() {
    return Summary_Setting__mdt.SObjectType;
  }

  /* Every setting field; a summary reads only the ones it uses. */
  public override List<Schema.SObjectField> getDefaultFieldList() {
    return new List<Schema.SObjectField>{
      Summary_Setting__mdt.DeveloperName,
      Summary_Setting__mdt.CacheHours__c,
      Summary_Setting__mdt.CacheMaxKB__c,
      Summary_Setting__mdt.TimeoutSeconds__c,
      Summary_Setting__mdt.ListRowsInitial__c,
      Summary_Setting__mdt.ListRowLimit__c,
      Summary_Setting__mdt.ExcludedActivityCreators__c,
      Summary_Setting__mdt.ActivityDays__c,
      Summary_Setting__mdt.ClosedCaseMonths__c,
      Summary_Setting__mdt.RecentDays__c,
      Summary_Setting__mdt.MaxActivities__c,
      Summary_Setting__mdt.MaxHistoryRows__c,
      Summary_Setting__mdt.MaxOpenCases__c,
      Summary_Setting__mdt.MaxClosedCases__c,
      Summary_Setting__mdt.MaxRelatedOpps__c,
      Summary_Setting__mdt.MaxLineItems__c,
      Summary_Setting__mdt.MaxStakeholders__c,
      Summary_Setting__mdt.MaxConversationItems__c,
      Summary_Setting__mdt.MaxOpenOpportunities__c,
      Summary_Setting__mdt.MaxClosedOpportunities__c,
      Summary_Setting__mdt.MaxEscalations__c,
      Summary_Setting__mdt.MaxEntitlements__c,
      Summary_Setting__mdt.MaxTeamMembers__c,
      Summary_Setting__mdt.MaxContacts__c,
      Summary_Setting__mdt.MaxTasks__c,
      Summary_Setting__mdt.MaxCaseTasks__c,
      Summary_Setting__mdt.MaxEvents__c,
      Summary_Setting__mdt.MaxUpcomingEvents__c,
      Summary_Setting__mdt.UpcomingEventDays__c,
      Summary_Setting__mdt.MaxRetentionTasks__c,
      Summary_Setting__mdt.MaxOrders__c,
      Summary_Setting__mdt.MaxContracts__c,
      Summary_Setting__mdt.HistoryDays__c,
      Summary_Setting__mdt.UnresolvedNames__c,
      Summary_Setting__mdt.GenericEmailDomains__c
    };
  }

  /* Custom metadata has no CreatedDate, and its name field is not guaranteed to sort. */
  public override String getOrderBy() {
    return DEFAULT_ORDER_BY;
  }

  /**
   * The settings record of one summary, such as OpportunitySummary. Queried rather than read with
   * getInstance(), which returns only the first 255 characters of a long text area.
   */
  public QueryFactory selectSettingByDeveloperName(String developerName) {
    return newQueryFactory()
      .setFactoryName(SETTING_BY_NAME_FACTORY_NAME)
      .setCondition(DEVELOPER_NAME_CONDITION)
      .setQueryBindings(new List<Object>{ developerName })
      .setLimit(1);
  }
}
