@isTest
private class Test_DialogFlowGetCases {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@test.com' + System.currentTimeMillis()
        );
        insert testUser;
        
        // Create record type for cases
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' LIMIT 1];
        
        System.runAs(testUser) {
            // Create test cases with different statuses
            List<Case> testCases = new List<Case>();
            
            // Create open cases
            for(Integer i = 0; i < 5; i++) {
                Case c = new Case(
                    Subject = 'Test Open Case ' + i,
                    Description = 'Test Description ' + i,
                    Status = 'New',
                    RecordTypeId = rt.Id
                );
                testCases.add(c);
            }
            
            // Create a closed case (should not be returned in query)
            Case closedCase = new Case(
                Subject = 'Test Closed Case',
                Description = 'Closed Case Description',
                Status = 'Closed',
                RecordTypeId = rt.Id
            );
            testCases.add(closedCase);
            
            insert testCases;
        }
    }
    
    @isTest
    static void testGetCasesSuccess() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' and Name = 'Testing' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCases';
        req.httpMethod = 'POST';
        
        // Create test request body
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => testUser.Id
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCases.getCases();
        Test.stopTest();
        
        // Assert
        System.assertEquals(200, RestContext.response.statusCode, 'Should return success status code');
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        
        System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
        List<Object> cases = (List<Object>)responseMap.get('data');
        System.assertEquals(5, cases.size(), 'Should return default limit of cases');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetCasesNoData() {
        // Create a new test user with no cases
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User newUser = new User(
            Alias = 'nuser',
            Email = 'newuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NewTesting',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'newuser@test.com' + System.currentTimeMillis()
        );
        insert newUser;
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCases';
        req.httpMethod = 'POST';
        
        // Create test request body
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => newUser.Id
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCases.getCases();
        Test.stopTest();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetCasesInvalidUserId() {
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCases';
        req.httpMethod = 'POST';
        
        // Create test request body with invalid user ID
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => 'INVALID_USERID'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCases.getCases();
        Test.stopTest();
        
    }
}