@isTest
private class Test_AIReportingUsageLogger {

    @isTest
    static void testLogAccess() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();

        Test.startTest();
            logger.logAccess();
        Test.stopTest();
        
        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areNotEqual(null, logs[0].First_Access__c, 'First access should be set');
    }

    @isTest
    static void testLogPrompt() {
        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testPrompt = 'Test prompt text';

        Test.startTest();
        	logger.logPrompt(testPrompt);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Prompt_Count__c, 'Prompt count should be 1');
    }

    @isTest
    static void testLogReport() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testObject = 'Account';

        Test.startTest();
            logger.logReport(testObject);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Report_Count__c, 'Report count should be 1');
    }

    @isTest
    static void testLogLike() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testObject = 'Contact';

        Test.startTest();
            logger.logLike(testObject);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Report_Like_Count__c, 'Report like count should be 1');
    }

    @isTest
    static void testLogDislike() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testObject = 'Lead';

        Test.startTest();
            logger.logDislike(testObject);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Report_Dislike_Count__c, 'Report dislike count should be 1');
    }

    @isTest
    static void testLogSummary() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();

        Test.startTest();
            logger.logSummary();
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Summary_Count__c, 'Summary count should be 1');
    }

    @isTest
    static void testLogSummaryLike() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testObject = 'Opportunity';

        Test.startTest();
            logger.logSummaryLike(testObject);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Summary_Like_Count__c, 'Summary like count should be 1');
    }

    @isTest
    static void testLogSummaryDislike() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testObject = 'Case';

        Test.startTest();
            logger.logSummaryDislike(testObject);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual(1, logs[0].Summary_Dislike_Count__c, 'Summary dislike count should be 1');
    }

    @isTest
    static void testLogAccessAndPrompt() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testPrompt = 'Test combined prompt';

        Test.startTest();
            logger.logAccessAndPrompt(testPrompt);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areNotEqual(null, logs[0].First_Access__c, 'First access should be set');
        Assert.areEqual(1, logs[0].Prompt_Count__c, 'Prompt count should be 1');
    }

    @isTest
    static void testMultipleLogsInBulk() {

        AIReportingUsageLogger logger = new AIReportingUsageLogger();

        Test.startTest();
            logger.logAccess();
            logger.logPrompt('Test prompt 1');
            logger.logPrompt('Test prompt 2');
            logger.logReport('Account');
            logger.logLike('Contact');
            logger.logSummary();
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectUserLogFromUserId(userId).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areNotEqual(null, logs[0].First_Access__c, 'First access should be set');
        Assert.areEqual(2, logs[0].Prompt_Count__c, 'Prompt count should be 2');
        Assert.areEqual(1, logs[0].Report_Count__c, 'Report count should be 1');
        Assert.areEqual(1, logs[0].Report_Like_Count__c, 'Report like count should be 1');
        Assert.areEqual(1, logs[0].Summary_Count__c, 'Summary count should be 1');
    }

    @isTest
    static void testLogAIHView() {
        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testSubfeature = 'Similar Cases';

        Test.startTest();
        logger.logAIHView(testSubfeature);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectAIHUserLog(userId, 'Daily Log', testSubfeature, AIUsageLogHelper.RT_ID_AIH).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areEqual(1, logs[0].View_Count__c, 'View count should be 1');
    }

    @isTest
    static void testLogAIHLike() {
        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testSubfeature = 'Knowledge Articles';

        Test.startTest();
        logger.logAIHLike(testSubfeature);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectAIHUserLog(userId, 'Daily Log', testSubfeature, AIUsageLogHelper.RT_ID_AIH).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areEqual(1, logs[0].Like_Count__c, 'Like count should be 1');
    }

    @isTest
    static void testLogAIHDislike() {
        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testSubfeature = 'Case Summary';

        Test.startTest();
        logger.logAIHDislike(testSubfeature);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectAIHUserLog(userId, 'Daily Log', testSubfeature, AIUsageLogHelper.RT_ID_AIH).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areEqual(1, logs[0].Dislike_Count__c, 'Dislike count should be 1');
    }

    @isTest
    static void testLogAIHFeedback() {
        AIReportingUsageLogger logger = new AIReportingUsageLogger();
        String testSubfeature = 'Similar Cases';
        String testFeedback = '{"feature":"SimilarCases","reason":"not relevant"}';

        Test.startTest();
        logger.logAIHFeedback(testSubfeature, testFeedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();

        List<AI_Usage_Log__c> logs = new AIUsageLogSelector().selectAIHUserLog(userId, 'Daily Log', testSubfeature, AIUsageLogHelper.RT_ID_AIH).executeQuery();
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areNotEqual(null, logs[0].AIH_Feedback__c, 'Feedback should be recorded');
    }
}