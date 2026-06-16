@isTest
private class Test_AIUsageLogHelper {

    @isTest
    static void testLogEventAccess() {
        Id userId = UserInfo.getUserId();
        Date today = Date.today();
        
        Test.startTest();
        AIUsageLogHelper.logEvent('access', null);
        Test.stopTest();
        
        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areNotEqual(null, userLogs[0].Last_Access__c, 'Last access should be set');
        
        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areNotEqual(null, globalLogs[0].Last_Access__c, 'Global last access should be set');
    }

    @isTest
    static void testLogEventPrompt() {
        
        Id userId = UserInfo.getUserId();
        String promptText = 'Test prompt about Account and Contact';
        
        Test.startTest();
        AIUsageLogHelper.logEvent('prompt', promptText);
        Test.stopTest();
        
        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Prompt_Count__c, 'Prompt count should be 1');
        
        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Prompt_Count__c, 'Global prompt count should be 1');
    }

    @isTest
    static void testLogEventReport() {

        Id userId = UserInfo.getUserId();

        Test.startTest();
            AIUsageLogHelper.logEvent('report', 'Account');
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Report_Count__c, 'Report count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Report_Count__c, 'Global report count should be 1');
    }

    @isTest
    static void testLogEventReportLike() {

        Id userId = UserInfo.getUserId();
        String reportName = 'Account Summary Report';

        Test.startTest();
            AIUsageLogHelper.logEvent('report_like', reportName);
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Report_Like_Count__c, 'Report like count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Report_Like_Count__c, 'Global report like count should be 1');
    }

    @isTest
    static void testLogEventReportDislike() {

        Id userId = UserInfo.getUserId();
        String reportName = 'Contact Summary Report';

        Test.startTest();
            AIUsageLogHelper.logEvent('report_dislike', reportName);
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Report_Dislike_Count__c, 'Report dislike count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Report_Dislike_Count__c, 'Global report dislike count should be 1');
    }

    @isTest
    static void testLogEventSummary() {

        Id userId = UserInfo.getUserId();

        Test.startTest();
            AIUsageLogHelper.logEvent('summary', null);
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Summary_Count__c, 'Summary count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Summary_Count__c, 'Global summary count should be 1');
    }

    @isTest
    static void testLogEventSummaryLike() {

        Id userId = UserInfo.getUserId();

        Test.startTest();
            AIUsageLogHelper.logEvent('summary_like', null);
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Summary_Like_Count__c, 'Summary like count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Summary_Like_Count__c, 'Global summary like count should be 1');
    }

    @isTest
    static void testLogEventSummaryDislike() {

        Id userId = UserInfo.getUserId();

        Test.startTest();
            AIUsageLogHelper.logEvent('summary_dislike', null);
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should create one user log record');
        Assert.areEqual(1, userLogs[0].Summary_Dislike_Count__c, 'Summary dislike count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should create one global log record');
        Assert.areEqual(1, globalLogs[0].Summary_Dislike_Count__c, 'Global summary dislike count should be 1');
    }

    @isTest
    static void testLogEventMultipleEvents() {

        Id userId = UserInfo.getUserId();

        Test.startTest();
            AIUsageLogHelper.logEvent('access', null);
            AIUsageLogHelper.logEvent('prompt', 'Test prompt');
            AIUsageLogHelper.logEvent('report', 'Account');
        Test.stopTest();

        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector().selectUserLog(userId, 'Daily Log', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, userLogs.size(), 'Should have only one user log record');
        Assert.areEqual(1, userLogs[0].Prompt_Count__c, 'Prompt count should be 1');

        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector().selectGlobalLog('Global Summary', AIUsageLogHelper.RT_ID_REPORTING).executeQuery();
        Assert.areEqual(1, globalLogs.size(), 'Should have only one global log record');
        Assert.areEqual(1, globalLogs[0].Prompt_Count__c, 'Global prompt count should be 1');
    }

    @isTest
    static void testSelectLogsFunctionality() {
        Test.startTest();
        	AIUsageLogHelper.logEvent('access', null);
            AIUsageLogHelper.logEvent('prompt', 'Show the 10 most recently created accounts');
            AIUsageLogHelper.logEvent('prompt', 'Show the leads created within last 10 days');
        Test.stopTest();

        List<AI_Usage_Log__c> allLogs = AIUsageLogHelper.selectAllLogsForDate(Date.Today(), 'Daily Log');
        Assert.areEqual(1, allLogs.size(), 'Should have only one Daily log record');
        List<AI_Usage_Log__c> cumulativeLogs = AIUsageLogHelper.selectCumulativeLogs('Global Summary');
        Assert.areEqual(1, cumulativeLogs.size(), 'Should have only one cumulative daily log record');
    }

    @isTest
    static void testLogAIHViewEvent() {
        Id userId = UserInfo.getUserId();
        String subfeature = 'Similar Cases';
        String contextValue = '{"subfeature":"Similar Cases"}';
        
        Test.startTest();
        AIUsageLogHelper.logEvent('aih_view', contextValue);
        Test.stopTest();
        
        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', subfeature, AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        Assert.areEqual(1, userLogs.size(), 'Should create one user AIH log record');
        Assert.areEqual(1, userLogs[0].View_Count__c, 'View count should be 1');
        Assert.areNotEqual(null, userLogs[0].Last_Access__c, 'Last access should be set');
        
        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector()
            .selectAIHGlobalLog('Global Summary', subfeature, AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        Assert.areEqual(1, globalLogs.size(), 'Should create one global AIH log record');
        Assert.areEqual(1, globalLogs[0].View_Count__c, 'Global view count should be 1');
    }
    
    @isTest
    static void testLogAIHLikeEvent() {
        Id userId = UserInfo.getUserId();
        String subfeature = 'Similar Cases';
        
        // Build inner feedback JSON safely
        Map<String, Object> feedback = new Map<String, Object>{
            'feature'      => 'SimilarCases',
                'parentNumber' => '2436',
                'itemType'     => 'Case',
                'itemNumber'   => '2431'
                // "action" not needed; helper infers from eventType
                };
                    String feedbackJsonString = JSON.serialize(feedback);
        
        // Outer payload
        Map<String, Object> ctx = new Map<String, Object>{
            'subfeature' => subfeature,
                'feedback'   => feedbackJsonString
                };
                    String contextValue = JSON.serialize(ctx);
        
        Test.startTest();
        AIUsageLogHelper.logEvent('aih_like', contextValue);
        Test.stopTest();
        
        // User log
        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', subfeature, AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        System.assertEquals(1, userLogs.size(), 'Should create one user AIH log record');
        System.assertEquals(1, userLogs[0].Like_Count__c, 'Like count should be 1');
        
        // Global log
        List<AI_Usage_Log__c> globalLogs = new AIUsageLogSelector()
            .selectAIHGlobalLog('Global Summary', subfeature, AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        System.assertEquals(1, globalLogs.size(), 'Should create one global AIH log record');
        System.assertEquals(1, globalLogs[0].Like_Count__c, 'Global like count should be 1');
    }

    
    @isTest
    static void testLogAIHDislikeEvent() {
        Id userId = UserInfo.getUserId();
        String subfeature   = 'Similar Articles';
        Map<String, Object> feedback = new Map<String, Object>{
            'feature'     => 'SimilarArticles',
                'parentNumber'=> '2436',
                'itemType'    => 'Article',
                'itemNumber'  => 'KB001',
                'action' => 'dislike'
                };
                    
                    String feedbackJsonString = JSON.serialize(feedback);
        
        Map<String, Object> ctx = new Map<String, Object>{
            'subfeature' => 'Similar Articles',
                'feedback'   => feedbackJsonString
                };
                    String contextValue = JSON.serialize(ctx);
        
        // Derive what the helper will read
        String expectedSubfeature =
            (String)((Map<String,Object>)JSON.deserializeUntyped(contextValue)).get('subfeature');
        
        Test.startTest();
        AIUsageLogHelper.logEvent('aih_dislike', contextValue);
        Test.stopTest();
       
        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', subfeature, AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, userLogs.size(), 'Should create one user AIH log record');
        System.assertEquals(1, userLogs[0].Dislike_Count__c, 'Dislike count should be 1');
    }
    
    @isTest
    static void testLogAIHFeedbackEvent() {
        Id userId = UserInfo.getUserId();
        String subfeature = 'Case Summary';
        
        // Build inner feedback JSON safely
        Map<String, Object> feedback = new Map<String, Object>{
            'feature'      => 'CaseSummary',
                'parentNumber' => '2436',
                'reason'       => 'not relevant'
                };
                    String feedbackJsonString = JSON.serialize(feedback);
        
        // Outer payload (feedback is a *string* containing JSON)
        Map<String, Object> ctx = new Map<String, Object>{
            'subfeature' => subfeature,
                'feedback'   => feedbackJsonString
                };
                    String contextValue = JSON.serialize(ctx);
        
        Test.startTest();
        AIUsageLogHelper.logEvent('aih_feedback', contextValue);
        Test.stopTest();
        
        
        List<AI_Usage_Log__c> userLogs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', subfeature, AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, userLogs.size(), 'Should create one user AIH log record');
        System.assert(userLogs[0].AIH_Feedback__c != null && userLogs[0].AIH_Feedback__c.contains('not relevant'),
                      'Should contain feedback reason');
    }
}