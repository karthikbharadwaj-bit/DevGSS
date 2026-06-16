@isTest
private class DialogFlowAddCaseCommentTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.user@example.com',
            Username = 'test.user.' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;
        
        // Create test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Description = 'Test Description',
            Status = 'New',
            Priority = 'High',
            OwnerId = testUser.Id
        );
        insert testCase;
    }
    
    @isTest
    static void testAddCaseComment_Success() {
        // Arrange
        Case testCase = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        User testUser = [SELECT Id, Name FROM User WHERE Email = 'test.user@example.com' LIMIT 1];
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/AddCaseCommenttoCaseNumber';
        req.httpMethod = 'PUT';
        req.params.put('salesforceUserId', testUser.Id);
        req.params.put('casenumber', testCase.CaseNumber);
        req.params.put('casecomments', 'Test comment from user');
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Act
        Test.startTest();
        DialogFlowAddCaseComment.AddCaseCommenttoCaseNumber();
        Test.stopTest();
        
        // Assert
        System.assertEquals(200, RestContext.response.statusCode, 'Should return success status code');
        
        // Verify comment was created
        List<CaseComment> comments = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :testCase.Id];
        System.assertEquals(1, comments.size(), 'Should create one comment');
        System.assert(comments[0].CommentBody.contains(testUser.Name), 'Comment should include user name');
        System.assert(comments[0].CommentBody.contains('Test comment from user'), 'Comment should include provided text');
        
        String responseBody = RestContext.response.responseBody.toString();
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        System.assertEquals(true, responseMap.get('success'), 'Response should indicate success');
    }
    
}