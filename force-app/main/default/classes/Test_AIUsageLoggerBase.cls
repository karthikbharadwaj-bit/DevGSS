@isTest
private class Test_AIUsageLoggerBase {

    // Mock implementation of AIUsageLoggerBase for testing
    private class MockAIUsageLogger extends AIUsageLoggerBase {
        public Boolean accessCalled = false;
        public String lastPromptText;
        public String lastObjectName;
        public Boolean summaryCalled = false;

        public override void logAccess() {
            accessCalled = true;
        }

        public override void logPrompt(String promptText) {
            lastPromptText = promptText;
        }

        public override void logReport(String objectName) {
            lastObjectName = objectName;
        }

        public override void logLike(String objectName) {
            lastObjectName = objectName;
        }

        public override void logDislike(String objectName) {
            lastObjectName = objectName;
        }

        public override void logSummary() {
            summaryCalled = true;
        }

        public override void logSummaryLike(String objectName) {
            lastObjectName = objectName;
        }
        
        public override void logSummaryDislike(String objectName) {
            lastObjectName = objectName;
        }

        public override void logAccessAndPrompt(String promptText) {
            accessCalled = true;
            lastPromptText = promptText;
        }

        // New AIH methods
        public String lastSubfeature;
        public String lastFeedback;
        
        public override void logAIHView(String subfeature) {
            lastSubfeature = subfeature;
        }
        
        public override void logAIHLike(String subfeature) {
            lastSubfeature = subfeature;
        }
        
        public override void logAIHDislike(String subfeature) {
            lastSubfeature = subfeature;
        }
        
        public override void logAIHFeedback(String subfeature, String feedback) {
            lastSubfeature = subfeature;
            lastFeedback = feedback;
        }
    }

    @isTest
    static void testLogAccess() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        logger.logAccess();
        Assert.areEqual(true,logger.accessCalled, 'logAccess should set accessCalled to true');
    }

    @isTest
    static void testLogPrompt() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testPrompt = 'Test prompt text';
        logger.logPrompt(testPrompt);
        Assert.areEqual(testPrompt, logger.lastPromptText, 'logPrompt should store the prompt text');
    }

    @isTest
    static void testLogReport() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testObject = 'Account';
        logger.logReport(testObject);
        Assert.areEqual(testObject, logger.lastObjectName, 'logReport should store the object name');
    }

    @isTest
    static void testLogLike() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testObject = 'Contact';
        logger.logLike(testObject);
        Assert.areEqual(testObject, logger.lastObjectName, 'logLike should store the object name');
    }

    @isTest
    static void testLogDislike() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testObject = 'Lead';
        logger.logDislike(testObject);
        Assert.areEqual(testObject, logger.lastObjectName, 'logDislike should store the object name');
    }

    @isTest
    static void testLogSummary() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        logger.logSummary();
        Assert.areEqual(true,logger.summaryCalled, 'logSummary should set summaryCalled to true');
    }

    @isTest
    static void testLogSummaryLike() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testObject = 'Opportunity';
        logger.logSummaryLike(testObject);
        Assert.areEqual(testObject, logger.lastObjectName, 'logSummaryLike should store the object name');
    }

    @isTest
    static void testLogSummaryDislike() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testObject = 'Case';
        logger.logSummaryDislike(testObject);
        Assert.areEqual(testObject, logger.lastObjectName, 'logSummaryDislike should store the object name');
    }

    @isTest
    static void testLogAccessAndPrompt() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testPrompt = 'Test combined prompt';
        logger.logAccessAndPrompt(testPrompt);
        Assert.areEqual(true,logger.accessCalled, 'logAccessAndPrompt should set accessCalled to true');
        Assert.areEqual(testPrompt, logger.lastPromptText, 'logAccessAndPrompt should store the prompt text');
    }

    @isTest
    static void testLogAIHView() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testSubfeature = 'Similar Cases';
        logger.logAIHView(testSubfeature);
        Assert.areEqual(testSubfeature, logger.lastSubfeature, 'logAIHView should store the subfeature');
    }

    @isTest
    static void testLogAIHLike() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testSubfeature = 'Knowledge Articles';
        logger.logAIHLike(testSubfeature);
        Assert.areEqual(testSubfeature, logger.lastSubfeature, 'logAIHLike should store the subfeature');
    }

    @isTest
    static void testLogAIHDislike() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testSubfeature = 'Case Summary';
        logger.logAIHDislike(testSubfeature);
        Assert.areEqual(testSubfeature, logger.lastSubfeature, 'logAIHDislike should store the subfeature');
    }

    @isTest
    static void testLogAIHFeedback() {
        MockAIUsageLogger logger = new MockAIUsageLogger();
        String testSubfeature = 'Similar Cases';
        String testFeedback = '{"feature":"SimilarCases","reason":"not relevant"}';
        logger.logAIHFeedback(testSubfeature, testFeedback);
        Assert.areEqual(testSubfeature, logger.lastSubfeature, 'logAIHFeedback should store the subfeature');
        Assert.areEqual(testFeedback, logger.lastFeedback, 'logAIHFeedback should store the feedback');
    }
}