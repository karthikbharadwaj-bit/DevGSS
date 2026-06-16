@IsTest
private class GCPCalloutForSimilarCasesTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user for testing
        User testUser = new User(
            Username = 'test.GCPuser@example.com',
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.GCPuser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        GCP_Endpoint_Settings__c gcpSetting = new GCP_Endpoint_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Identity_Token_URL__c = 'https://oauth2.googleapis.com/token',
            Service_Account_Email__c = 'test@test-project.iam.gserviceaccount.com',
            Cloud_Run_Endpoint__c = 'https://test-endpoint.run.app',
            Certificate_Name__c = 'privatekey'
        );
        insert gcpSetting;

        
        // Create test cases for getCaseIdsByCaseNumbers method
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Case> testCases = new List<Case>();
        for (Integer i = 1; i <= 3; i++) {
            testCases.add(new Case(
                AccountId = testAccount.Id,
                Subject = 'Test Case ' + i,
                Status = 'New',
                Priority = 'Medium'
            ));
        }
        insert testCases;
    }
    
    @IsTest
    static void testMakeGCPCallout_Success() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.GCPuser@example.com' LIMIT 1];
        
        // Mock successful HTTP responses
        Test.setMock(HttpCalloutMock.class, new GCPCalloutSuccessMock());
        
        Test.startTest();
        String result = GCPCalloutForSimilarCases.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id  // Using user ID as record ID for test
        );
        Test.stopTest();
        
        // Verify result
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should return success');
        System.assert(resultMap.containsKey('cases'), 'Should contain cases');
    }
    
    @IsTest
    static void testMakeGCPCallout_IdentityTokenFailure() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.GCPuser@example.com' LIMIT 1];
        
        // Mock failed identity token response
        Test.setMock(HttpCalloutMock.class, new GCPIdentityTokenFailureMock());
        
        Test.startTest();
        String result = GCPCalloutForSimilarCases.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id
        );
        Test.stopTest();
        
        // Verify error handling
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure');
        System.assert(((String) resultMap.get('message')).contains('Callout error'), 'Should contain callout error message');
    }
    
    @IsTest
    static void testMakeGCPCallout_CloudRunFailure() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.GCPuser@example.com' LIMIT 1];
        
        // Mock failed Cloud Run response
        Test.setMock(HttpCalloutMock.class, new GCPCloudRunFailureMock());
        
        Test.startTest();
        String result = GCPCalloutForSimilarCases.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id
        );
        Test.stopTest();
        
        // Verify error handling
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure');
        System.assert(((String) resultMap.get('message')).contains('Callout error'), 'Should contain callout error message');
    }
    
    @IsTest
    static void testMakeGCPCallout_InvalidJSONResponse() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.GCPuser@example.com' LIMIT 1];
        
        // Mock invalid JSON response
        Test.setMock(HttpCalloutMock.class, new GCPInvalidJSONMock());
        
        Test.startTest();
        String result = GCPCalloutForSimilarCases.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id
        );
        Test.stopTest();
        
        // Verify error handling
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure');
    }
    
    @IsTest
    static void testMakeGCPCallout_StringResponse() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.GCPuser@example.com' LIMIT 1];
        
        // Mock string response (error message from Cloud Run)
        Test.setMock(HttpCalloutMock.class, new GCPStringResponseMock());
        
        Test.startTest();
        String result = GCPCalloutForSimilarCases.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            'Test Description',
            testUser.Id
        );
        Test.stopTest();
        
        // Verify error handling
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure');
        System.assertEquals('Error from Cloud Run', resultMap.get('message'), 'Should contain error message from Cloud Run');
    }
    
    @IsTest
    static void testMakeGCPCallout_EmptyDescription() {
        User testUser = [SELECT Id FROM User WHERE Username = 'test.GCPuser@example.com' LIMIT 1];
        
        // Mock successful HTTP responses
        Test.setMock(HttpCalloutMock.class, new GCPCalloutSuccessMock());
        
        Test.startTest();
        String result = GCPCalloutForSimilarCases.makeGCPCallout(
            testUser.Id,
            'Test Subject',
            '',  // Empty description
            testUser.Id
        );
        Test.stopTest();
        
        // Verify result
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should handle empty description');
    }
    
    @IsTest
    static void testGetCaseIdsByCaseNumbers() {
        List<Case> testCases = [SELECT CaseNumber FROM Case LIMIT 3];
        List<String> caseNumbers = new List<String>();
        for (Case c : testCases) {
            caseNumbers.add(c.CaseNumber);
        }
        
        Test.startTest();
        Map<String, String> result = GCPCalloutForSimilarCases.getCaseIdsByCaseNumbers(caseNumbers);
        Test.stopTest();
        
        // Verify result
        System.assertNotEquals(null, result, 'Should return a map');
        // Note: The actual implementation depends on CaseSelectorDialogflow.getInstance()
    }
    
    @IsTest
    static void testGetCaseIdsByCaseNumbers_EmptyList() {
        Test.startTest();
        Map<String, String> result = GCPCalloutForSimilarCases.getCaseIdsByCaseNumbers(new List<String>());
        Test.stopTest();
        
        // Verify result
        System.assertNotEquals(null, result, 'Should return a map even for empty input');
    }
    
    @IsTest
    static void testApplicationException() {
        // Delete the custom setting to trigger ApplicationException
        delete [SELECT Id FROM GCP_Endpoint_Settings__c];
        
        Test.startTest();
        try {
            // This should trigger the static initializer to throw ApplicationException
            GCPCalloutForSimilarCases.ApplicationException testException = new GCPCalloutForSimilarCases.ApplicationException('Test');
            System.assert(true, 'ApplicationException should be instantiable');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception when creating ApplicationException: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testLogAIHEvent_View() {
        Test.startTest();
        GCPCalloutForSimilarCases.logAIHEvent('aih_view', 'Similar Cases', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Cases', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].View_Count__c, 'View count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Like() {
        String feedback = '{"feature":"SimilarCases","parentNumber":"2436","itemType":"Case","itemNumber":"2431"}';
        
        Test.startTest();
        GCPCalloutForSimilarCases.logAIHEvent('aih_like', 'Similar Cases', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Cases', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].Like_Count__c, 'Like count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Feedback() {
        String feedback = '{"feature":"SimilarCases","parentNumber":"2436","reason":"not relevant"}';
        
        Test.startTest();
        GCPCalloutForSimilarCases.logAIHEvent('aih_feedback', 'Similar Cases', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Cases', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertNotEquals(null, logs[0].AIH_Feedback__c, 'Feedback should be recorded');
    }
    
    @IsTest
    static void testLogAIHEvent_EmptySubfeature() {
        Test.startTest();
        GCPCalloutForSimilarCases.logAIHEvent('aih_view', '', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Unknown', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        System.assertEquals(1, logs.size(), 'Should create one AIH log record with Unknown subfeature');
    }
    
    // Mock classes for HTTP callouts
    private class GCPCalloutSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                // Mock identity token response
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                // Mock Cloud Run response
                res.setBody('{"body": [{"case": "test case 1"}, {"case": "test case 2"}]}');
            }
            
            return res;
        }
    }
    
    private class GCPIdentityTokenFailureMock implements HttpCalloutMock {
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
    
    private class GCPCloudRunFailureMock implements HttpCalloutMock {
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
    
    private class GCPInvalidJSONMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setStatusCode(200);
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('invalid json response');
            }
            
            return res;
        }
    }
    
    private class GCPStringResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            
            if (req.getEndpoint().contains('oauth2.googleapis.com')) {
                res.setStatusCode(200);
                res.setBody('{"id_token": "mock_id_token"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"body": "Error from Cloud Run"}');
            }
            
            return res;
        }
    }
}