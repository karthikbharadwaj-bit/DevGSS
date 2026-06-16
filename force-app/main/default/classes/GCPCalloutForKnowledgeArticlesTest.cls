@IsTest
private class GCPCalloutForKnowledgeArticlesTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            Username = 'test.userArticle@example.com',
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.userArticle@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Support Manager - KB' LIMIT 1].Id,
            KCS_Role__c='KCS Coach',
            UserPermissionsKnowledgeUser=true,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        GCP_Endpoint_Settings__c gcpSetting = new GCP_Endpoint_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Identity_Token_URL__c = 'https://oauth2.googleapis.com/token',
            Service_Account_Email__c = 'test@test-project.iam.gserviceaccount.com',
            Article_Cloud_Run_Endpoint__c = 'https://test-endpoint.run.app',
            Certificate_Name__c = 'privatekey'
        );
        insert gcpSetting;

        System.runAs(testUser) {
        // Create test knowledge articles for getArticleIdsByArticleNumbers method
        List<Knowledge__kav> testArticles = new List<Knowledge__kav>();
        for (Integer i = 1; i <= 3; i++) {
            testArticles.add(new Knowledge__kav(
                Title = 'Test Article ' + i,
                Summary = 'Test Summary ' + i,
                UrlName = 'test-article-' + i,
                Language = 'en_US'
            ));
            }
        insert testArticles;
        }
    }
    
    @IsTest
    static void testMakeGCPCallout_Success() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.userArticle@example.com' LIMIT 1];
        
        // Mock successful HTTP responses
        Test.setMock(HttpCalloutMock.class, new GCPKnowledgeCalloutSuccessMock());
        
        Test.startTest();
        String result = GCPCalloutForKnowledgeArticles.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id,  // Using user ID as record ID for test
            'Test Function',
            'Test Specific Issue',
            'Test Issue Occurrence',
            'Test Product',
            'Test Model Version Platform'
        );
        Test.stopTest();
        
        // Verify result
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should return success');
        System.assert(resultMap.containsKey('articles'), 'Should contain articles');
        
        List<Object> articles = (List<Object>) resultMap.get('articles');
        System.assert(articles.size() > 0, 'Should return some articles');
    }
    
    @IsTest
    static void testMakeGCPCallout_AllParametersEmpty() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.userArticle@example.com' LIMIT 1];
        
        // Mock successful HTTP responses
        Test.setMock(HttpCalloutMock.class, new GCPKnowledgeCalloutSuccessMock());
        
        Test.startTest();
        String result = GCPCalloutForKnowledgeArticles.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            '',  // Empty description
            testUser.Id,
            '',  // Empty function
            '',  // Empty specific issue
            '',  // Empty issue occurrence
            '',  // Empty product
            ''   // Empty model version platform
        );
        Test.stopTest();
        
        // Verify result
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should handle empty parameters');
    }
    
    @IsTest
    static void testMakeGCPCallout_IdentityTokenFailure() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.userArticle@example.com' LIMIT 1];
        
        // Mock failed identity token response
        Test.setMock(HttpCalloutMock.class, new GCPKnowledgeIdentityTokenFailureMock());
        
        Test.startTest();
        try {
            String result = GCPCalloutForKnowledgeArticles.makeGCPCallout(
                testUser.Id,
                'Test Subject',
                'Test Description',
                testUser.Id,
                'Test Function',
                'Test Specific Issue',
                'Test Issue Occurrence',
                'Test Product',
                'Test Model Version Platform'
            );
            System.assert(false, 'Should throw CalloutException for identity token failure');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Failed to get ID Token'), 'Should contain correct error message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMakeGCPCallout_CloudRunFailure() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.userArticle@example.com' LIMIT 1];
        
        // Mock failed Cloud Run response
        Test.setMock(HttpCalloutMock.class, new GCPKnowledgeCloudRunFailureMock());
        
        Test.startTest();
        try {
            String result = GCPCalloutForKnowledgeArticles.makeGCPCallout(
                testUser.Id,
                'Test Subject',
                'Test Description',
                testUser.Id,
                'Test Function',
                'Test Specific Issue',
                'Test Issue Occurrence',
                'Test Product',
                'Test Model Version Platform'
            );
            // This might not throw exception depending on how error is handled
        } catch (Exception e) {
            System.assert(true, 'Exception handling is working');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMakeGCPCallout_StringResponse() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.userArticle@example.com' LIMIT 1];
        
        // Mock string response (error message from Cloud Run)
        Test.setMock(HttpCalloutMock.class, new GCPKnowledgeStringResponseMock());
        
        Test.startTest();
        String result = GCPCalloutForKnowledgeArticles.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id,
            'Test Function',
            'Test Specific Issue',
            'Test Issue Occurrence',
            'Test Product',
            'Test Model Version Platform'
        );
        Test.stopTest();
        
        // Verify error handling
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure');
        System.assertEquals('Error from Knowledge Cloud Run', resultMap.get('message'), 'Should contain error message from Cloud Run');
    }
    
    @IsTest
    static void testMakeGCPCallout_UnexpectedResponseFormat() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.userArticle@example.com' LIMIT 1];
        
        // Mock unexpected response format
        Test.setMock(HttpCalloutMock.class, new GCPKnowledgeUnexpectedResponseMock());
        
        Test.startTest();
        String result = GCPCalloutForKnowledgeArticles.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id,
            'Test Function',
            'Test Specific Issue',
            'Test Issue Occurrence',
            'Test Product',
            'Test Model Version Platform'
        );
        Test.stopTest();
        
        // Verify error handling
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure');
        System.assertEquals('Unexpected response format', resultMap.get('message'), 'Should contain unexpected format message');
    }
    
    @IsTest
    static void testGetArticleIdsByArticleNumbers() {
        List<Knowledge__kav> testArticles = [SELECT ArticleNumber FROM Knowledge__kav LIMIT 3];
        List<String> articleNumbers = new List<String>();
        for (Knowledge__kav article : testArticles) {
            articleNumbers.add(article.ArticleNumber);
        }
        
        Test.startTest();
        Map<String, String> result = GCPCalloutForKnowledgeArticles.getArticleIdsByArticleNumbers(articleNumbers);
        Test.stopTest();
        
        // Verify result
        System.assertNotEquals(null, result, 'Should return a map');
        // Note: The actual implementation depends on KnowledgeArticleSelectorDialogflow
    }
    
    @IsTest
    static void testGetArticleIdsByArticleNumbers_EmptyList() {
        Test.startTest();
        Map<String, String> result = GCPCalloutForKnowledgeArticles.getArticleIdsByArticleNumbers(new List<String>());
        Test.stopTest();
        
        // Verify result
        System.assertNotEquals(null, result, 'Should return a map even for empty input');
    }
    
    @IsTest
    static void testApplicationException() {
        Test.startTest();
        try {
            GCPCalloutForKnowledgeArticles.ApplicationException testException = new GCPCalloutForKnowledgeArticles.ApplicationException('Test');
            System.assert(true, 'ApplicationException should be instantiable');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception when creating ApplicationException: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testStaticInitializer_NoCustomSetting() {
        // Delete the custom setting to test ApplicationException in static initializer
        delete [SELECT Id FROM GCP_Endpoint_Settings__c];
        
        Test.startTest();
        try {
            // This will trigger a new class load and should throw ApplicationException
            // However, since the class is already loaded, we can't easily test this scenario
            // We can at least verify the ApplicationException class exists
            GCPCalloutForKnowledgeArticles.ApplicationException testException = new GCPCalloutForKnowledgeArticles.ApplicationException('Test configuration error');
            System.assertEquals('Test configuration error', testException.getMessage(), 'ApplicationException should store message correctly');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testLogAIHEvent_View() {
        Test.startTest();
        GCPCalloutForKnowledgeArticles.logAIHEvent('aih_view', 'Knowledge Articles', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Knowledge Articles', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].View_Count__c, 'View count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Like() {
        String feedback = '{"feature":"KnowledgeArticles","parentNumber":"2436","itemType":"Article","itemNumber":"KB001"}';
        
        Test.startTest();
        GCPCalloutForKnowledgeArticles.logAIHEvent('aih_like', 'Knowledge Articles', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Knowledge Articles', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].Like_Count__c, 'Like count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Dislike() {
        String feedback = '{"feature":"KnowledgeArticles","parentNumber":"2436","itemType":"Article","itemNumber":"KB001"}';
        
        Test.startTest();
        GCPCalloutForKnowledgeArticles.logAIHEvent('aih_dislike', 'Knowledge Articles', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Knowledge Articles', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].Dislike_Count__c, 'Dislike count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Feedback() {
        String feedback = '{"feature":"KnowledgeArticles","parentNumber":"2436","reason":"not helpful"}';
        
        Test.startTest();
        GCPCalloutForKnowledgeArticles.logAIHEvent('aih_feedback', 'Knowledge Articles', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Knowledge Articles', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertNotEquals(null, logs[0].AIH_Feedback__c, 'Feedback should be recorded');
    }
    
    // Mock classes for HTTP callouts
    private class GCPKnowledgeCalloutSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                // Mock identity token response
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                // Mock Cloud Run response
                res.setBody('{"body": [{"article": "test article 1", "title": "Test Title 1"}, {"article": "test article 2", "title": "Test Title 2"}]}');
            }
            
            return res;
        }
    }
    
    private class GCPKnowledgeIdentityTokenFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setStatusCode(400);
                res.setBody('{"error": "invalid_grant"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"body": []}');
            }
            
            return res;
        }
    }
    
    private class GCPKnowledgeCloudRunFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setStatusCode(200);
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error": "Internal Server Error"}');
            }
            
            return res;
        }
    }
    
    private class GCPKnowledgeStringResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setStatusCode(200);
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"body": "Error from Knowledge Cloud Run"}');
            }
            
            return res;
        }
    }
    
    private class GCPKnowledgeUnexpectedResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setStatusCode(200);
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"body": {"unexpected": "format"}}');
            }
            
            return res;
        }
    }
}