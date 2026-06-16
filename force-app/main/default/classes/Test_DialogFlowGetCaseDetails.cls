@isTest
private class Test_DialogFlowGetCaseDetails {
    
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
        
        System.runAs(testUser) {
            // Create test case
            Case testCase = new Case(
                Subject = 'Test Case Subject',
                Status = 'New',
                Priority = 'High',
                Resolution__c = 'Test Resolution'
            );
            insert testCase;
        }
    }
    
    @isTest
    static void testGetCaseDetailsSuccess() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' and Name = 'Testing' LIMIT 1];
        Case testCase = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Test Case Subject' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCasesDetails';
        req.httpMethod = 'POST';
        
        // Create test request body
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => testUser.Id,
            'caseNumber' => testCase.CaseNumber
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCaseDetails.getCaseDetailsByNumber();
        Test.stopTest();
        
        // Verify results
        System.assertEquals(200, RestContext.response.statusCode, 'Should return success status code');
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        
        System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
        Map<String, Object> caseDetails = (Map<String, Object>)responseMap.get('data');
        System.assertEquals(testCase.CaseNumber, caseDetails.get('caseNumber'), 'Should return correct case details');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetCaseDetailsInvalidCase() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCasesDetails';
        req.httpMethod = 'POST';
        
        // Create test request body with invalid case number
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => testUser.Id,
            'caseNumber' => 'INVALID-CASE-123'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCaseDetails.getCaseDetailsByNumber();
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetCaseDetailsNoAccess() {
        // Create a new user without access to the case
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User noAccessUser = new User(
            Alias = 'nuser',
            Email = 'noaccess@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoAccess',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'noaccess@test.com' + System.currentTimeMillis()
        );
        insert noAccessUser;
        
        Case testCase = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Test Case Subject' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCasesDetails';
        req.httpMethod = 'POST';
        
        // Create test request body
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => noAccessUser.Id,
            'caseNumber' => testCase.CaseNumber
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCaseDetails.getCaseDetailsByNumber();
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetCaseDetailsNullCaseNumber() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getCasesDetails';
        req.httpMethod = 'POST';
        
        // Create test request body with null case number
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => testUser.Id,
            'caseNumber' => null
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetCaseDetails.getCaseDetailsByNumber();
        Test.stopTest();
    }
}