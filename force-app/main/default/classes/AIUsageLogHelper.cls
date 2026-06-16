public class AIUsageLogHelper {
    public static final String SUPPORT_AGENT_RT_NAME = 'AI Support Agent';
    public static final String REPORTING_RT_NAME = 'AI Reporting Tool';
    public static final String AIH_RT_NAME = 'AI Insights Hub';
    public static final Id RT_ID_SUPPORT_AGENT = RT_INFO_BY_NAME.get(SUPPORT_AGENT_RT_NAME).getRecordTypeId();   
    public static final Id RT_ID_REPORTING = RT_INFO_BY_NAME.get(REPORTING_RT_NAME).getRecordTypeId(); 
    public static final Id RT_ID_AIH = RT_INFO_BY_NAME.get(AIH_RT_NAME).getRecordTypeId();
    public static String FEEDBACK_PROMPT1 = 'Feedback_Prompt_1';
    public static String FEEDBACK_PROMPT2 = 'Feedback_Prompt_2';
    public static String DEFAULT_FEEDBACK = 'Not applicable';
    public static String CONVERT_PARAM_START = '({text={text=(';
    public static String CONVERT_PARAM_END = ')}})';
    public static String POSITIVE_FEEDBACK = 'Satisfied';
    public static String NEGATIVE_FEEDBACK = 'Not Satisfied';
    public static String POSITIVE_RESPONSE = 'Positive';
    public static String NEGATIVE_RESPONSE = 'Negative';
    public static String WELCOME_INTENT = 'Welcome_Intent';
    public static String CREATE_METHOD = 'Create';
    public static String UPDATE_METHOD = 'Update';
    public static String FEEDBACK_METHOD = 'Feedback';

    // Features that do not have per-item context (only the case itself)
    private static final Set<String> AIH_SIMPLE_FEATURES = new Set<String>{'CaseSummary', 'CaseCommentSummary', 'EmailSummary', 'JiraCommentSummary'};
    
    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }
    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = AI_Usage_Log__c.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    public static void logEvent(String eventType, String contextValue) {
        if (eventType != null && eventType.startsWith('aih_')) {
            handleAIHEvent(eventType, contextValue);
            return;
        }
        Date today = Date.today();
        Id userId = UserInfo.getUserId();
        Datetime nowTime = System.now();

        AIUsageLogSelector selector = new AIUsageLogSelector();
        
        List<AI_Usage_Log__c> userLogs = selector.selectUserLog(userId, 'Daily Log', RT_ID_REPORTING).executeQuery();
        List<AI_Usage_Log__c> globalLogs = selector.selectGlobalLog('Global Summary', RT_ID_REPORTING).executeQuery();
        
        AI_Usage_Log__c userLog = !userLogs.isEmpty() ? userLogs[0] : new AI_Usage_Log__c(
            Log_Date__c = today,
            User__c = userId,
            Is_Overall_Record__c = false,
            Log_Category__c = 'Daily Log',
            RecordTypeId = RT_ID_REPORTING
            
        );

        AI_Usage_Log__c globalLog = !globalLogs.isEmpty() ? globalLogs[0] : new AI_Usage_Log__c(
            Is_Overall_Record__c = true,
            Log_Category__c = 'Global Summary',
            RecordTypeId = RT_ID_REPORTING
            
        );

        if (eventType == 'access') {
            if (userLog.First_Access__c == null) {
                userLog.First_Access__c = nowTime;
            }
            userLog.Last_Access__c = nowTime;

            if (globalLog.First_Access__c == null) {
                globalLog.First_Access__c = nowTime;
            }
            globalLog.Last_Access__c = nowTime;
        }

        if (eventType == 'prompt') {
            userLog.Prompt_Count__c = (userLog.Prompt_Count__c == null ? 1 : userLog.Prompt_Count__c + 1);
            globalLog.Prompt_Count__c = (globalLog.Prompt_Count__c == null ? 1 : globalLog.Prompt_Count__c + 1);
            userLog.Prompt_Topics__c = mergeTopics(userLog.Prompt_Topics__c, contextValue);
            globalLog.Prompt_Topics__c = mergeTopics(globalLog.Prompt_Topics__c, contextValue);
        }

        if (eventType == 'report') {
            userLog.Report_Count__c = (userLog.Report_Count__c == null ? 1 : userLog.Report_Count__c + 1);
            globalLog.Report_Count__c = (globalLog.Report_Count__c == null ? 1 : globalLog.Report_Count__c + 1);
        }

        if (eventType == 'report_like') {
            userLog.Report_Like_Count__c = (userLog.Report_Like_Count__c == null ? 1 : userLog.Report_Like_Count__c + 1);
            globalLog.Report_Like_Count__c = (globalLog.Report_Like_Count__c == null ? 1 : globalLog.Report_Like_Count__c + 1);
            userLog.Liked_Report_Names__c = mergeReportNames(userLog.Liked_Report_Names__c, contextValue);
            globalLog.Liked_Report_Names__c = mergeReportNames(globalLog.Liked_Report_Names__c, contextValue);
        }

        if (eventType == 'report_dislike') {
            userLog.Report_Dislike_Count__c = (userLog.Report_Dislike_Count__c == null ? 1 : userLog.Report_Dislike_Count__c + 1);
            globalLog.Report_Dislike_Count__c = (globalLog.Report_Dislike_Count__c == null ? 1 : globalLog.Report_Dislike_Count__c + 1);
            userLog.Disliked_Report_Names__c = mergeReportNames(userLog.Disliked_Report_Names__c, contextValue);
            globalLog.Disliked_Report_Names__c = mergeReportNames(globalLog.Disliked_Report_Names__c, contextValue);
        }

        if (eventType == 'summary') {
            userLog.Summary_Count__c = (userLog.Summary_Count__c == null ? 1 : userLog.Summary_Count__c + 1);
            globalLog.Summary_Count__c = (globalLog.Summary_Count__c == null ? 1 : globalLog.Summary_Count__c + 1);
        }

        if (eventType == 'summary_like') {
            userLog.Summary_Like_Count__c = (userLog.Summary_Like_Count__c == null ? 1 : userLog.Summary_Like_Count__c + 1);
            globalLog.Summary_Like_Count__c = (globalLog.Summary_Like_Count__c == null ? 1 : globalLog.Summary_Like_Count__c + 1);
        }

        if (eventType == 'summary_dislike') {
            userLog.Summary_Dislike_Count__c = (userLog.Summary_Dislike_Count__c == null ? 1 : userLog.Summary_Dislike_Count__c + 1);
            globalLog.Summary_Dislike_Count__c = (globalLog.Summary_Dislike_Count__c == null ? 1 : globalLog.Summary_Dislike_Count__c + 1);
        }

        upsert new List<AI_Usage_Log__c>{ userLog, globalLog };
            }
    
    // 🔹 Handle AI Insights Hub events
    private static void handleAIHEvent(String eventType, String contextValue) {
        // contextValue JSON shape:
        // {"subfeature":"Similar Cases","feedback":"{...json...}"}
        // where feedback (for aih_feedback) is. Eg:
        // {"feature":"SimilarCases","parentNumber":"2436","itemType":"Case","itemNumber":"2431","reason":"not relevant"}
        
        String subfeature = 'Unknown';
        String feedbackJson = '';
        
        try {
            if (!String.isBlank(contextValue)) {
                Map<String, Object> userFeedback = (Map<String, Object>) JSON.deserializeUntyped(contextValue);
                if (userFeedback != null) {
                    if (userFeedback.containsKey('subfeature') && userFeedback.get('subfeature') != null) {
                        subfeature = String.valueOf(userFeedback.get('subfeature')).trim();
                        if (String.isBlank(subfeature)) {
                            subfeature = 'Unknown';
                        }
                    }
                    
                    if (userFeedback.containsKey('feedback') && userFeedback.get('feedback') != null) {
                        feedbackJson = String.valueOf(userFeedback.get('feedback')).trim();
                    }
                }
            }
        } catch (Exception ex) {
            subfeature = String.isBlank(contextValue) ? 'Unknown' : contextValue.left(255);
        }
        
        Date today = Date.today();
        Id userId = UserInfo.getUserId();
        Datetime nowTime = System.now();
        
        AIUsageLogSelector selector = new AIUsageLogSelector();
        
        // Per-user daily log for this subfeature
        List<AI_Usage_Log__c> userLogs = selector
            .selectAIHUserLog(userId, 'Daily Log', subfeature, RT_ID_AIH)
            .executeQuery();
        
        AI_Usage_Log__c userUsage;
        if (!userLogs.isEmpty()) {
            userUsage = userLogs[0];
        } else {
            userUsage = new AI_Usage_Log__c(
                Log_Date__c         = today,
                User__c             = userId,
                Is_Overall_Record__c= false,
                Log_Category__c     = 'Daily Log',
                RecordTypeId        = RT_ID_AIH,
                AIH_Subfeature__c   = subfeature
            );
        }
        
        // Global summary for this subfeature (no feedback lines written here)
        List<AI_Usage_Log__c> globalLogs = selector
            .selectAIHGlobalLog('Global Summary', subfeature, RT_ID_AIH)
            .executeQuery();
        
        AI_Usage_Log__c globalUsage;
        if (!globalLogs.isEmpty()) {
            globalUsage = globalLogs[0];
        } else {
            globalUsage = new AI_Usage_Log__c(
                Is_Overall_Record__c= true,
                Log_Category__c     = 'Global Summary',
                RecordTypeId        = RT_ID_AIH,
                AIH_Subfeature__c   = subfeature
            );
        }
        
        if (eventType == 'aih_view') {
            if (userUsage.First_Access__c == null) {
                userUsage.First_Access__c = nowTime;
            }
            userUsage.Last_Access__c = nowTime;
            
            if (globalUsage.First_Access__c == null) {
                globalUsage.First_Access__c = nowTime;
            }
            globalUsage.Last_Access__c = nowTime;
            
            userUsage.View_Count__c   = (userUsage.View_Count__c == null   ? 1 : userUsage.View_Count__c + 1);
            globalUsage.View_Count__c = (globalUsage.View_Count__c == null ? 1 : globalUsage.View_Count__c + 1);
        }
        else if (eventType == 'aih_like' || eventType == 'aih_dislike') {
            String featureName   = 'SimilarCases';
            String parentNumber  = 'Unknown';
            String itemTypeName  = 'Case';
            String itemNumber    = 'Unknown';
            
            if (!String.isBlank(feedbackJson)) {
                
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(feedbackJson);                   
                if (parsed != null) {
                    if (parsed.containsKey('feature') && parsed.get('feature') != null) {
                        featureName = String.valueOf(parsed.get('feature')).trim();
                    }
                    if (parsed.containsKey('parentNumber') && parsed.get('parentNumber') != null) {
                        parentNumber = String.valueOf(parsed.get('parentNumber')).trim();
                    }
                    if (parsed.containsKey('itemType') && parsed.get('itemType') != null) {
                        itemTypeName = String.valueOf(parsed.get('itemType')).trim();
                    }
                    if (parsed.containsKey('itemNumber') && parsed.get('itemNumber') != null) {
                        itemNumber = String.valueOf(parsed.get('itemNumber')).trim();
                    }
                }
                
            }
            
            // Simple = feature-level action (no per-item context). Itemized = record-level (Similar Cases/Articles).
            Boolean isSimpleScope = AIH_SIMPLE_FEATURES.contains(featureName) ||
                'case summary'.equalsIgnoreCase(String.valueOf(subfeature));
            
            String action = (eventType == 'aih_like') ? 'like' : 'dislike';
            
            // Prefix that is common across both formats (feature + parent)
            String keyPrefix = 'feature=' + featureName + ' | parent=' + parentNumber;
            
            // Full key for itemized logs
            String scopedKey = isSimpleScope
                ? keyPrefix
                : keyPrefix + ' | itemType=' + itemTypeName + ' | item=' + itemNumber;
            
            // ----- Find previous action for the same scope -----
            // For simple features -> search by keyPrefix (feature-level toggle)
            // For itemized features -> search by full key (record-level toggle)
            String previousAction = null;
            if (!String.isBlank(userUsage.AIH_Feedback__c)) {
                List<String> lines = userUsage.AIH_Feedback__c.split('\n');
                for (Integer i = lines.size() - 1; i >= 0; i--) {
                    String line = lines[i];
                    Boolean matchesScope = isSimpleScope ? line.contains(keyPrefix) : line.contains(scopedKey);
                    if (matchesScope) {                       
                        if (line.contains('action=like')) {
                            previousAction = 'like';
                        } else if (line.contains('action=dislike')) {
                            previousAction = 'dislike';
                        }                        
                        break;
                    }
                }
            }
            
            if (previousAction != action) {
                Decimal userLikes      = (userUsage.Like_Count__c      == null ? 0 : userUsage.Like_Count__c);
                Decimal userDislikes   = (userUsage.Dislike_Count__c   == null ? 0 : userUsage.Dislike_Count__c);
                Decimal globalLikes    = (globalUsage.Like_Count__c    == null ? 0 : globalUsage.Like_Count__c);
                Decimal globalDislikes = (globalUsage.Dislike_Count__c == null ? 0 : globalUsage.Dislike_Count__c);
                
                if (previousAction == 'like' && action == 'dislike') {
                    // Switch from like -> dislike within the SAME scope (feature or same item)
                    userLikes      = (userLikes      > 0) ? userLikes - 1 : 0;
                    globalLikes    = (globalLikes    > 0) ? globalLikes - 1 : 0;
                    userDislikes   = userDislikes + 1;
                    globalDislikes = globalDislikes + 1;
                } else if (previousAction == 'dislike' && action == 'like') {
                    // Switch from dislike -> like within the SAME scope (feature or same item)
                    userDislikes   = (userDislikes   > 0) ? userDislikes - 1 : 0;
                    globalDislikes = (globalDislikes > 0) ? globalDislikes - 1 : 0;
                    userLikes      = userLikes + 1;
                    globalLikes    = globalLikes + 1;
                } else if (previousAction == null) {
                    // First action within this scope
                    if (action == 'like') { userLikes++; globalLikes++; }
                    else { userDislikes++; globalDislikes++; }
                }
                
                userUsage.Like_Count__c      = userLikes;
                userUsage.Dislike_Count__c   = userDislikes;
                globalUsage.Like_Count__c    = globalLikes;
                globalUsage.Dislike_Count__c = globalDislikes;
                
                String timestampIso = System.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                String logLine = '[' + timestampIso + '] action=' + action + ' | ' + scopedKey;
                userUsage.AIH_Feedback__c = String.isBlank(userUsage.AIH_Feedback__c)
                    ? logLine
                    : userUsage.AIH_Feedback__c + '\n' + logLine;
            }
        }
        else if (eventType == 'aih_feedback') {
            if (!String.isBlank(feedbackJson)) {
                
                Map<String, Object> userInputFeedback = (Map<String, Object>) JSON.deserializeUntyped(feedbackJson);
                
                String feature     = userInputFeedback != null && userInputFeedback.containsKey('feature')      && userInputFeedback.get('feature')      != null ? String.valueOf(userInputFeedback.get('feature')).trim()      : 'Unknown';
                String parentNo    = userInputFeedback != null && userInputFeedback.containsKey('parentNumber') && userInputFeedback.get('parentNumber') != null ? String.valueOf(userInputFeedback.get('parentNumber')).trim() : 'Unknown';
                String itemType    = userInputFeedback != null && userInputFeedback.containsKey('itemType')     && userInputFeedback.get('itemType')     != null ? String.valueOf(userInputFeedback.get('itemType')).trim()     : 'Unknown';
                String itemNo      = userInputFeedback != null && userInputFeedback.containsKey('itemNumber')   && userInputFeedback.get('itemNumber')   != null ? String.valueOf(userInputFeedback.get('itemNumber')).trim()   : 'Unknown';
                String reasonRaw   = userInputFeedback != null && userInputFeedback.containsKey('reason')       && userInputFeedback.get('reason')       != null ? String.valueOf(userInputFeedback.get('reason')).trim()       : '';
                
                // Escape double quotes inside the reason
                String reasonEscaped = String.isBlank(reasonRaw) ? '' : reasonRaw.replaceAll('"', '\\"');
                
                // UTC timestamp like 2025-09-11T12:20:01Z
                String ts = System.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                
                Boolean isSimpleFeature = AIH_SIMPLE_FEATURES.contains(feature);
                
                String line = isSimpleFeature
                    ? ('[' + ts + ']' +
                       ' Feature=' + feature +
                       ' | parent=' + parentNo +
                       ' | reason="' + reasonEscaped + '"')
                    : ('[' + ts + ']' +
                       ' Feature=' + feature +
                       ' | parent=' + parentNo +
                       ' | itemType=' + itemType +
                       ' | item=' + itemNo +
                       ' | reason="' + reasonEscaped + '"');
                           
                           if (String.isBlank(userUsage.AIH_Feedback__c)) {
                               userUsage.AIH_Feedback__c = line;
                           } else {
                               userUsage.AIH_Feedback__c = userUsage.AIH_Feedback__c + '\n' + line;
                           }
                
            }
        }
        upsert new List<AI_Usage_Log__c>{ userUsage, globalUsage };
            }

    
    private static Map<String, Set<String>> getObjectKeywordMapFromCMDT() {
        List<Map<String, String>> rawList = AIReportingController.getObjectKeywordMap();
        Map<String, Set<String>> objectKeywordMap = new Map<String, Set<String>>();

        for (Map<String, String> row : rawList) {
            String objectName = row.get('objectName');
            String keywordsStr = row.get('keywords');
            if (String.isBlank(objectName) || String.isBlank(keywordsStr)) {
                continue;
            }

            Set<String> keywords = new Set<String>();
            for (String keyword : keywordsStr.split(',')) {
                if (!String.isBlank(keyword)) {
                    keywords.add(keyword.trim().toLowerCase());
                }
            }
            objectKeywordMap.put(objectName, keywords);
        }

        return objectKeywordMap;
    }

    private static AI_Usage_Log__c getOrCreateLog(Id userId, Date today, Boolean isGlobal, String logCategory) {
        List<AI_Usage_Log__c> logs;

        if (isGlobal) {
            logs = [
                SELECT Id, User__c, Log_Date__c, Prompt_Count__c, Report_Count__c, Summary_Count__c,
                Report_Like_Count__c, Summary_Like_Count__c, Summary_Dislike_Count__c, Liked_Report_Names__c, Report_Dislike_Count__c, Disliked_Report_Names__c,
                Prompt_Topics__c, First_Access__c, Last_Access__c, Log_Category__c
                FROM AI_Usage_Log__c
                WHERE Is_Overall_Record__c = true
                AND Log_Category__c = 'Global Summary'
                AND RecordTypeId = :RT_ID_REPORTING
                LIMIT 1 FOR UPDATE
            ];
        } else {
            logs = [
                SELECT Id, User__c, Log_Date__c, Prompt_Count__c, Report_Count__c, Summary_Count__c,
                Report_Like_Count__c, Summary_Like_Count__c, Summary_Dislike_Count__c, Liked_Report_Names__c, Report_Dislike_Count__c, Disliked_Report_Names__c,
                Prompt_Topics__c, First_Access__c, Last_Access__c, Log_Category__c
                FROM AI_Usage_Log__c
                WHERE User__c = :userId
                AND Log_Category__c = 'Daily Log'
                AND Is_Overall_Record__c = false
                AND RecordTypeId = :RT_ID_REPORTING
                LIMIT 1 FOR UPDATE
            ];
        }

        if (!logs.isEmpty()) { 
            return logs[0];
        }
        
        return new AI_Usage_Log__c(
            Log_Date__c = isGlobal ? null : today,
            User__c = isGlobal ? null : userId,
            Is_Overall_Record__c = isGlobal,
            Log_Category__c = logCategory,
            RecordTypeId = RT_ID_REPORTING
        );
    }
    
    public static List<AI_Usage_Log__c> selectAllLogsForDate(Date day, String logCategory) {
        List<AI_Usage_Log__c> dailyLogs = new List<AI_Usage_Log__c>();
        dailyLogs = new AIUsageLogSelector().selectAllLogsForDate(day, logCategory).executeQuery();
        return dailyLogs;
    }
    
    public static List<AI_Usage_Log__c> selectCumulativeLogs(String logCategory) {
        List<AI_Usage_Log__c> dailyLogs = new List<AI_Usage_Log__c>();
        dailyLogs = new AIUsageLogSelector().selectCumulativeLogs(logCategory).executeQuery();
        return dailyLogs;
    }

    private static String mergeReportNames(String existing, String contextValue) {
        if (String.isBlank(contextValue)) {
            return existing;
        }

        Map<String, Set<String>> objectKeywordMap = getObjectKeywordMapFromCMDT();

        Set<String> normalizedObjects = new Set<String>();
        String lowerContext = contextValue.toLowerCase();
        for (String obj : objectKeywordMap.keySet()) {
            for (String keyword : objectKeywordMap.get(obj)) {
                if (lowerContext.contains(keyword)) {
                    normalizedObjects.add(obj);
                    break;
                }
            }
        }
        if (normalizedObjects.isEmpty()) { 
            normalizedObjects.add('Unknown');
        }
        Set<String> finalSet = new Set<String>();
        if (!String.isBlank(existing)) {
            finalSet.addAll(existing.split(';'));
        }
        finalSet.addAll(normalizedObjects);
        return String.join(new List<String>(finalSet), ';');
    }

    private static String mergeTopics(String existing, String newPrompt) {
        if (String.isBlank(newPrompt)) {
            return existing;
        }

        Map<String, Set<String>> objectKeywordMap = getObjectKeywordMapFromCMDT();

        Set<String> all = new Set<String>();

        String promptLower = newPrompt.toLowerCase();

        for (String obj : objectKeywordMap.keySet()) {
            for (String keyword : objectKeywordMap.get(obj)) {
                if (promptLower.contains(keyword)) {
                    all.add(keyword);
                }
            }
        }

        if (!String.isBlank(existing)) {
            all.addAll(existing.toLowerCase().split(','));
        }

        return String.join(new List<String>(all), ',');
    }
}