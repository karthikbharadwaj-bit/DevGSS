@IsTest
public class DialogflowShowCaseCommentsGCPTest {
    private static final String CASE_COMMENT_BODY = 'Body test';
    private static final String requestUri = '/services/apexrest/getCaseCommentsForGCP';
    private static final String requestPost= 'POST';
    
    @TestSetup
    static void setupData() {
        
		Case cs = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'Test Case',
                    Case.Description => 'test Description',
                    Case.Status => 'New',
                    Case.Origin => 'Phone'
                }
            )
            .create()
            .getRecord();

		CaseComment testCaseComment = (CaseComment) new SObjectBuilder(CaseComment.SObjectType)
            .quantity(3)
            .setFields(
                new Map<SObjectField, Object>{
					CaseComment.ParentId => cs.Id,
                    CaseComment.CommentBody => CASE_COMMENT_BODY
                	}
            )
            .create()
            .getRecord();
    }

    @IsTest
    static void testGetCommentsByCaseId() {
		List<Case> cases = (List<Case>) new CaseSelector()
		    .selectCases()
		    .executeQuery();		

        // Build fake request body
        Map<String, Object> reqMap = new Map<String, Object>();
        reqMap.put('recordId', cases[0].Id);
        reqMap.put('lastProcessedCommentId', null);
        reqMap.put('currentBatchSize', 2);

        RestRequest req = new RestRequest();
        req.requestUri = requestUri;
        req.httpMethod = requestPost;
        req.requestBody = Blob.valueOf(JSON.serialize(reqMap));

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        DialogflowShowCaseCommentsGCP.getCommentsByCaseId();
        Test.stopTest();

        // Verify response
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        String responseStr = RestContext.response.responseBody.toString();

        // Validate key JSON fields exist
        System.assert(responseStr.contains('totalCaseCommentCount'), 'Response should contain totalCaseCommentCount');
        System.assert(responseStr.contains('caseComments'), 'Response should contain caseComments');
    }

    @IsTest
    static void testMissingRecordId() {
        // Request with no recordId
        Map<String, Object> reqMap = new Map<String, Object>();
        RestRequest req = new RestRequest();
        req.requestUri = requestUri;
        req.httpMethod = requestPost;
        req.requestBody = Blob.valueOf(JSON.serialize(reqMap));

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        DialogflowShowCaseCommentsGCP.getCommentsByCaseId();
        Test.stopTest();
        
        System.assertNotEquals(null, RestContext.response, 'Response should not be null');
    }
}