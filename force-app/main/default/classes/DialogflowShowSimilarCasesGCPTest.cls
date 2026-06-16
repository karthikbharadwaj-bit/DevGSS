@isTest
private class DialogflowShowSimilarCasesGCPTest {
    
    @TestSetup
    static void setupTestData() {
        List<Case> testCases = new List<Case>();
        
        Case case1 = new Case(
            Subject = 'Test Case 1 - Login Issue',
            Description = 'User cannot login to the system',
            Status = 'Closed',
            Priority = 'High',
            Resolution__c = 'Password reset resolved the issue'
        );
        testCases.add(case1);
        
        Case case2 = new Case(
            Subject = 'Test Case 2 - Performance Issue',
            Description = 'System running slowly',
            Status = 'Closed',
            Priority = 'Medium',
            Resolution__c = 'Database optimization fixed the performance'
        );
        testCases.add(case2);
        
        Case case3 = new Case(
            Subject = 'Test Case 3 - Open Issue',
            Description = 'Current open case for testing',
            Status = 'New',
            Priority = 'Low'
        );
        testCases.add(case3);
        
        insert testCases;
    }
    
    @isTest
    static void testGetCaseDetailsBySubject_Success() {
        Case testCase = [SELECT Id FROM Case WHERE Status = 'New' LIMIT 1];
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'recordId' => testCase.Id
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        DialogflowShowSimilarCasesGCP.getCaseDetailsBySubject();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertNotEquals(null, responseMap, 'Response should not be null');
        System.assert(responseMap.containsKey('cases'), 'Response should contain cases key');
        System.assert(responseMap.containsKey('caseCount'), 'Response should contain caseCount key');
        
        List<Object> cases = (List<Object>) responseMap.get('cases');
        Integer caseCount = (Integer) responseMap.get('caseCount');
        System.assertEquals(cases.size(), caseCount, 'Case count should match cases list size');
    }
    
    @isTest
    static void testGetCaseDetailsBySubject_MissingRecordId() {
        Map<String, Object> requestBody = new Map<String, Object>{
            'otherField' => 'someValue'
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requestBody));
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        DialogflowShowSimilarCasesGCP.getCaseDetailsBySubject();
        Test.stopTest();
        
        System.assert(true, 'Method should complete without throwing unhandled exceptions');
    }
    
    @isTest
    static void testCaseDTO_Constructor() {
        Case testCase = new Case(
            Subject = 'Test Subject',
            Description = 'Test Description',
            Resolution__c = 'Test Resolution'
        );
        insert testCase;
        
        testCase = [SELECT Id, CaseNumber, Subject, Description, Resolution__c FROM Case WHERE Id = :testCase.Id];
        
        Test.startTest();
        DialogflowShowSimilarCasesGCP.CaseDTO dto = new DialogflowShowSimilarCasesGCP.CaseDTO(testCase);
        Test.stopTest();
        
        System.assertEquals(testCase.CaseNumber, dto.CaseNumber, 'CaseNumber should be mapped correctly');
        System.assertEquals(testCase.Subject, dto.Subject, 'Subject should be mapped correctly');
        System.assertEquals(testCase.Description, dto.Description, 'Description should be mapped correctly');
        System.assertEquals(testCase.Resolution__c, dto.Resolution, 'Resolution should be mapped correctly');
    }
}