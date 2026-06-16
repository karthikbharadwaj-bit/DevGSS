@isTest
private class Test_DialogFlowGetSimilarCases {
    
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
            // Create test cases with similar subjects
            List<Case> testCases = new List<Case>();
            
            // Cases with similar subjects
            Case case1 = new Case(
                Subject = 'Printer not working',
                Description = 'HP Printer not working properly',
                Status = 'New',
                Priority = 'High',
                RecordTypeId = rt.Id
            );
            testCases.add(case1);
            
            Case case2 = new Case(
                Subject = 'Network printer not responding',
                Description = 'Printer connection issues',
                Status = 'New',
                Priority = 'Medium',
                RecordTypeId = rt.Id
            );
            testCases.add(case2);
            
            Case case3 = new Case(
                Subject = 'Different subject',
                Description = 'But contains printer issues in description',
                Status = 'New',
                Priority = 'Low',
                RecordTypeId = rt.Id
            );
            testCases.add(case3);
            
            Case case4 = new Case(
                Subject = 'Unrelated issue',
                Description = 'Something completely different',
                Status = 'New',
                Priority = 'Low',
                RecordTypeId = rt.Id
            );
            testCases.add(case4);
            
            insert testCases;
        }
    }
    
    @isTest
    static void testGetSimilarCasesSuccess() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' and Name = 'Testing' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getSimilarCases';
        req.httpMethod = 'POST';
        
        // Create test request body
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => testUser.Id,
            'subject' => 'printer'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetSimilarCases.getCaseDetailsBySubject();
        Test.stopTest();
        
        // Verify response
        RestResponse res = RestContext.response;
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
        
        List<Object> data = (List<Object>) responseMap.get('data');
        System.assertEquals(2, data.size(), 'Should return 2 similar cases');
        
        // Verify each case is printer-related
        for(Object caseObj : data) {
            Map<String, Object> caseMap = (Map<String, Object>) caseObj;
            String subject = (String) caseMap.get('subject');
            System.assert(
                subject.toLowerCase().contains('printer') || 
                ((String)caseMap.get('description')).toLowerCase().contains('printer'),
                'Case should be related to printer'
            );
        }
    }
    
    @isTest
    static void testGetSimilarCasesNoAccess() {
        // Create a new user without access to the cases
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
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getSimilarCases';
        req.httpMethod = 'POST';
        
        // Create test request body
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => noAccessUser.Id,
            'subject' => 'printer'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetSimilarCases.getCaseDetailsBySubject();
        Test.stopTest();
        
        // Verify response
        RestResponse res = RestContext.response;
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
        
        List<Object> data = (List<Object>) responseMap.get('data');
        System.assertEquals(0, data.size(), 'Should return no cases for user without access');
    }
    
    @isTest
    static void testGetSimilarCasesMissingParams() {
        // Prepare the REST request with missing required parameter
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getSimilarCases';
        req.httpMethod = 'POST';
        
        Map<String, String> requestBody = new Map<String, String>{
            'subject' => 'printer'
            // Missing salesforceUserId
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetSimilarCases.getCaseDetailsBySubject();
        Test.stopTest();
        
        // Verify error response
        RestResponse res = RestContext.response;
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        
        System.assertEquals(500, res.statusCode, 'Status code should be 500');
        System.assertEquals(false, responseMap.get('success'), 'Response should indicate failure');
        System.assert(((String)responseMap.get('message')).contains('Required parameters missing'), 
                     'Error message should indicate missing parameters');
    }
    
    @isTest
    static void testGetSimilarCasesNoMatches() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@test.com' LIMIT 1];
        
        // Prepare the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/getSimilarCases';
        req.httpMethod = 'POST';
        
        // Create test request body with subject that won't match any cases
        Map<String, String> requestBody = new Map<String, String>{
            'salesforceUserId' => testUser.Id,
            'subject' => 'xyzabc123'
        };
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        DialogFlowGetSimilarCases.getCaseDetailsBySubject();
        Test.stopTest();
        
        // Verify response
        RestResponse res = RestContext.response;
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        
        System.assertEquals(200, res.statusCode, 'Status code should be 200');
        System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
        
        List<Object> data = (List<Object>) responseMap.get('data');
        System.assertEquals(0, data.size(), 'Should return no cases when no matches found');
    }
}