@isTest
private class Test_DialogflowService1 {
    
    private static final String MOCK_ACCESS_TOKEN = 'mock_access_token_123';
    private static final String MOCK_RESPONSE = '{"queryResult":{"responseMessages":[{"text":{"text":["This is a test response"]}}]}}';
    
    @TestSetup
    static void setupTestData() {
        // Create test Support Agent AI Assist records for both sandbox and production
        List<Support_Agent_AI_Assist__c> configs = new List<Support_Agent_AI_Assist__c>();
        
        // Sandbox config
        Support_Agent_AI_Assist__c sandboxConfig = new Support_Agent_AI_Assist__c(
            Name = 'test',
            Org__c = 'test',
            Agent_Id__c = 'test-agent-id-sandbox',
            Is_Sandbox__c = true
        );
        configs.add(sandboxConfig);
        
        // Production config
        Support_Agent_AI_Assist__c prodConfig = new Support_Agent_AI_Assist__c(
            Name = 'Production',
            Org__c = 'Production',
            Agent_Id__c = 'test-agent-id-biztest1',
            Is_Sandbox__c = false
        );
        configs.add(prodConfig);
        
        insert configs;
        
        // Create test Case
        Case testCase = new Case(
            Subject = 'Test Case'
        );
        insert testCase;
        Profile p = [SELECT Id FROM Profile WHERE Name='Support Manager - KB'];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@test.com' + System.currentTimeMillis(),
            KCS_Role__c='KCS Coach'
        );
        insert testUser;
        

        // Create test Knowledge Article
        Knowledge__kav testArticle = new Knowledge__kav(
            Title = 'Test Article',
            URLName = 'Test-Article-by-Support-Agent',
            Language = 'en_US'
        );      
        system.runAs(testUser){
            insert testArticle;
        }
    }
    
    @isTest
    static void testSendMessageSuccess() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new DialogflowServiceMock(200, MOCK_RESPONSE));
        
        Test.startTest();
        String response = DialogflowService1.sendMessage('Hi');
        Test.stopTest();
        
        // Verify response
        System.assertEquals('This is a test response', response, 'This is a test response');
    }
    
    @isTest
    static void testSendMessageError() {
        Test.setMock(HttpCalloutMock.class, new DialogflowServiceMock(400, '{"error": "Bad Request"}'));
        
        Test.startTest();
        try {
            DialogflowService1.sendMessage('Test message');
            System.assert(false, 'Expected an AuraHandledException to be thrown for API error.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'),
                          'Expected AuraHandledException with specific message content.');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetCaseIdByCaseNumber() {
        Case testCase = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        
        Test.startTest();
        Id resultId = DialogflowService1.getCaseIdByCaseNumber(testCase.CaseNumber);
        Test.stopTest();
        
        System.assertEquals(testCase.Id, resultId, 'Should return correct case ID');
    }
    
    @isTest
    static void testGetCaseIdByCaseNumberNotFound() {
        Test.startTest();
        try {
            DialogflowService1.getCaseIdByCaseNumber('12345678');
            System.assert(false, 'Should throw exception for invalid case number');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetKnowledgeIdByArticleNumber() {

        Knowledge__kav testArticle = [SELECT Id, ArticleNumber FROM Knowledge__kav WHERE Title like '%Article%'  LIMIT 1];
        Test.startTest();
        Id resultId = DialogflowService1.getKnowledgeIdByArticleNumber(testArticle.ArticleNumber);
        Test.stopTest();
        
        System.assertEquals(testArticle.Id, resultId, 'Should return correct article ID');
    }
    
    @isTest
    static void testGetKnowledgeIdByArticleNumberNotFound() {
        Test.startTest();
        try {
            DialogflowService1.getKnowledgeIdByArticleNumber('111111');
            System.assert(false, 'Should throw exception for invalid article number');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
    
    // Mock HTTP Callout class
    private class DialogflowServiceMock implements HttpCalloutMock {
        private Integer statusCode;
        private String response;
        
        public DialogflowServiceMock(Integer statusCode, String response) {
            this.statusCode = statusCode;
            this.response = response;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            // Verify request parameters
            System.assertNotEquals(null, req.getEndpoint(), 'Endpoint should not be null');
            System.assertNotEquals(null,req.getHeader('Content-Type'), 'Content-Type should not be null');
            System.assert(req.getHeader('Authorization').startsWith('Bearer '), 'Should include Bearer token');
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(response);
            return res;
        }
    }
}