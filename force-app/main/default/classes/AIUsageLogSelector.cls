public inherited sharing class AIUsageLogSelector extends SObjectSelector {

    public AIUsageLogSelector() {
        super();
    }

    public AIUsageLogSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(enforceCRUD, enforceFLS);
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            AI_Usage_Log__c.Id,
            AI_Usage_Log__c.User__c,
            AI_Usage_Log__c.Log_Date__c,
            AI_Usage_Log__c.Prompt_Count__c,
            AI_Usage_Log__c.Report_Count__c,
            AI_Usage_Log__c.Summary_Count__c,
            AI_Usage_Log__c.Report_Like_Count__c,
            AI_Usage_Log__c.Summary_Like_Count__c,
            AI_Usage_Log__c.Summary_Dislike_Count__c,
            AI_Usage_Log__c.Liked_Report_Names__c,
            AI_Usage_Log__c.Report_Dislike_Count__c,
            AI_Usage_Log__c.Disliked_Report_Names__c,
            AI_Usage_Log__c.Prompt_Topics__c,
            AI_Usage_Log__c.First_Access__c,
            AI_Usage_Log__c.Last_Access__c,
            AI_Usage_Log__c.Log_Category__c,
            AI_Usage_Log__c.AIH_Subfeature__c,
            AI_Usage_Log__c.AIH_Feedback__c,
            AI_Usage_Log__c.View_Count__c,
            AI_Usage_Log__c.Like_Count__c,
            AI_Usage_Log__c.Dislike_Count__c
        };
    }

    public override Schema.SObjectType getSObjectType() {
        return AI_Usage_Log__c.SObjectType;
    }

    public QueryFactory selectGlobalLog(String logCategory, Id recordTypeId) {
        return newQueryFactory()
            .setFactoryName('selectGlobalLog')
            .setCondition('Is_Overall_Record__c = true AND Log_Category__c = :bind0 AND RecordTypeId = :bind1')
            .setQueryBindings(new List<Object>{ logCategory, recordTypeId });
    }

    public QueryFactory selectUserLog(Id userId, String logCategory, Id recordTypeId) {
        return newQueryFactory()
            .setFactoryName('selectUserLog')
            .setCondition('User__c = :bind0 AND Log_Category__c = :bind1 AND Is_Overall_Record__c = false AND RecordTypeId = :bind2')
            .setQueryBindings(new List<Object>{ userId, logCategory, recordTypeId });
    }
    
    public QueryFactory selectUserLogFromUserId(Id userId) {
        return newQueryFactory()
            .setFactoryName('selectUserLog')
            .setCondition('User__c = :bind0 AND Is_Overall_Record__c = false')
            .setQueryBindings(new List<Object>{ userId });
    }

    public QueryFactory selectAllLogsForDate(Date day, String logCategory) {
        return newQueryFactory()
            .setFactoryName('selectAllLogsForDate')
            .setCondition('Log_Date__c = :bind0 AND Log_Category__c = :bind1')
            .setQueryBindings(new List<Object>{ day, logCategory });
    }

    public QueryFactory selectCumulativeLogs(String logCategory) {
        return newQueryFactory()
            .setFactoryName('selectCumulativeLogs')
            .setCondition('Is_Overall_Record__c = true AND Log_Category__c = :bind0')
            .setQueryBindings(new List<Object>{ logCategory });
    }
        
    // ===== 🔹 AI Insights Hub selectors (per subfeature) =====
    public QueryFactory selectAIHUserLog(Id userId, String logCategory, String subfeature, Id recordTypeId) {
        return newQueryFactory()
            .setFactoryName('selectAIHUserLog')
            .setCondition('User__c = :bind0 AND Log_Category__c = :bind1 AND Is_Overall_Record__c = false AND AIH_Subfeature__c = :bind2 AND RecordTypeId = :bind3')
            .setQueryBindings(new List<Object>{ userId, logCategory, subfeature, recordTypeId });
    }
    
    public QueryFactory selectAIHGlobalLog(String logCategory, String subfeature, Id recordTypeId) {
        return newQueryFactory()
            .setFactoryName('selectAIHGlobalLog')
            .setCondition('Is_Overall_Record__c = true AND Log_Category__c = :bind0 AND AIH_Subfeature__c = :bind1 AND RecordTypeId = :bind2')
            .setQueryBindings(new List<Object>{ logCategory, subfeature, recordTypeId });
    }
}