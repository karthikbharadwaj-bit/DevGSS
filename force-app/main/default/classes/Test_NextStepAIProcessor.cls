@isTest
private class Test_NextStepAIProcessor {

    @testSetup
    static void setupData() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity AI',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addDays(30)
            })
            .create()
            .getRecord();
        
        GCP_Endpoint_Settings__c gcpSetting = new GCP_Endpoint_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Identity_Token_URL__c = 'https://oauth2.googleapis.com/token',
            Service_Account_Email__c = 'test@test-project.iam.gserviceaccount.com',
            Next_Steps_Endpoint__c = 'https://test-endpoint.run.app',
            Certificate_Name__c = 'privatekey'
        );
        insert gcpSetting;

    }

    /**
     * Helper method to generate standard request payloads
     */
    private static List<NextStepAIProcessor.NextStepRequest> createTestRequests(Id oppId) {
        List<NextStepAIProcessor.NextStepRequest> reqs = new List<NextStepAIProcessor.NextStepRequest>();
        NextStepAIProcessor.NextStepRequest req = new NextStepAIProcessor.NextStepRequest();
        req.oppId = String.valueOf(oppId);
        req.oldNextStepVal = 'Old Step';
        req.newNextStepVal = 'New Step';
        req.lastImmediateNextStepVal = 'Last Step';
        req.modifiedByUserName = 'Test Agent';
        reqs.add(req);
        return reqs;
    }

    @isTest
    static void testExecuteWithEmptyRequests() {
        // Test early exit validation when request list is null/empty
        Test.startTest();
        NextStepAIProcessor processor = new NextStepAIProcessor(new List<NextStepAIProcessor.NextStepRequest>());
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.areEqual(true, NextStepAIProcessor.isImmediateNextStepProcessed, 'Processor flag should flip even if requests are empty.');
    }

    @isTest
    static void testExecuteSuccessPath() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<NextStepAIProcessor.NextStepRequest> reqs = createTestRequests(opp.Id);

        // Mode 1 sets up successful authorization and standard processing payloads
        Test.setMock(HttpCalloutMock.class, new NextStepAIProcessorMock(1, opp.Id));

        Test.startTest();
        System.enqueueJob(new NextStepAIProcessor(reqs));
        Test.stopTest();

        // Verify that the status code 200 payload updated the record appropriately
        Opportunity updatedOpp = [SELECT Next_Steps_Last_Modified__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Updated Step via AI', updatedOpp.Next_Steps_Last_Modified__c, 'Opportunity field should match the mock payload value.');
    }

    @isTest
    static void testExecuteApiStatusError() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<NextStepAIProcessor.NextStepRequest> reqs = createTestRequests(opp.Id);

        // Mode 2 forces an HTTP Non-200 (e.g. 500 Server Error) to trigger platform logs
        Test.setMock(HttpCalloutMock.class, new NextStepAIProcessorMock(2, opp.Id));

        Test.startTest();
        System.enqueueJob(new NextStepAIProcessor(reqs));
        Test.stopTest();

        Assert.areEqual(true, NextStepAIProcessor.isImmediateNextStepProcessed);
    }

    @isTest
    static void testExecuteWrapperSameErrors() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<NextStepAIProcessor.NextStepRequest> reqs = createTestRequests(opp.Id);

        // Mode 3 simulates an API status 200 containing a "BATCH FAILED: SAME ERRORS" payload wrapper
        Test.setMock(HttpCalloutMock.class, new NextStepAIProcessorMock(3, opp.Id));

        Test.startTest();
        System.enqueueJob(new NextStepAIProcessor(reqs));
        Test.stopTest();

        Assert.areEqual(true, NextStepAIProcessor.isImmediateNextStepProcessed);
    }

    @isTest
    static void testExecuteWrapperMixedErrors() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<NextStepAIProcessor.NextStepRequest> reqs = createTestRequests(opp.Id);

        // Mode 4 simulates an API status 200 containing a "BATCH FAILED: MIXED ERRORS" payload wrapper
        Test.setMock(HttpCalloutMock.class, new NextStepAIProcessorMock(4, opp.Id));

        Test.startTest();
        System.enqueueJob(new NextStepAIProcessor(reqs));
        Test.stopTest();

        Assert.areEqual(true, NextStepAIProcessor.isImmediateNextStepProcessed);
    }

    @isTest
    static void testExecuteParsingException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<NextStepAIProcessor.NextStepRequest> reqs = createTestRequests(opp.Id);

        // Mode 5 returns invalid JSON types to trigger the JSON processing try-catch blocks
        Test.setMock(HttpCalloutMock.class, new NextStepAIProcessorMock(5, opp.Id));

        Test.startTest();
        System.enqueueJob(new NextStepAIProcessor(reqs));
        Test.stopTest();

        Assert.areEqual(true, NextStepAIProcessor.isImmediateNextStepProcessed);
    }

    @isTest
    static void testExecuteCalloutException() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<NextStepAIProcessor.NextStepRequest> reqs = createTestRequests(opp.Id);

        // Mode 6 explicitly throws a CalloutException inside the HTTP network layer simulation
        Test.setMock(HttpCalloutMock.class, new NextStepAIProcessorMock(6, opp.Id));

        Test.startTest();
        System.enqueueJob(new NextStepAIProcessor(reqs));
        Test.stopTest();

        Assert.areEqual(true, NextStepAIProcessor.isImmediateNextStepProcessed);
    }

    /**
     * Multi-request HttpCalloutMock implementation to handle complex GCPAuth and downstream routing
     */
    public class NextStepAIProcessorMock implements HttpCalloutMock {
        private Integer executionMode;
        private Id contextOppId;

        public NextStepAIProcessorMock(Integer mode, Id oppId) {
            this.executionMode = mode;
            this.contextOppId = oppId;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // Route 1: Handle early authentication requests intercepted from GCPAuthUtil sequence
            if (req.getEndpoint() != null && (req.getEndpoint().contains('identity') || req.getBody().contains('jwt'))) {
                res.setStatusCode(200);
                res.setBody('{"id_token": "mocked_gcp_bearer_token"}');
                return res;
            }

            // Route 2: Target main processor testing logic based on configured execution configurations
            String oppIdStr = String.valueOf(contextOppId);

            switch on executionMode {
                when 1 {
                    // Success responses processing status 200 (updates field) and status 304 (skips field)
                    res.setStatusCode(200);
                    res.setBody('{"statusCode": 200, "errorMsg": null, "result": [{"oppId": "' + oppIdStr + '", "immediateNextStepValue": "Updated Step via AI", "status": "200"}, {"oppId": "' + oppIdStr + '", "immediateNextStepValue": null, "status": "304"}]}');
                }
                when 2 {
                    // Standard explicit service failure codes
                    res.setStatusCode(500);
                    res.setBody('Internal Endpoint Server Crash Mock');
                }
                when 3 {
                    // Wrapper application structural failure: Same Errors
                    res.setStatusCode(200);
                    res.setBody('{"statusCode": 400, "errorMsg": "BATCH FAILED: SAME ERRORS - Processing Failure", "result": null}');
                }
                when 4 {
                    // Wrapper application structural failure: Mixed Errors
                    res.setStatusCode(200);
                    res.setBody('{"statusCode": 400, "errorMsg": "BATCH FAILED: MIXED ERRORS", "result": [{"oppId": "' + oppIdStr + '", "errorMsg": "Individual item timeout error status.", "status": "400"}]}');
                }
                when 5 {
                    // Type-mismatch serialization structural breaks (String bound to Integer)
                    res.setStatusCode(200);
                    res.setBody('{"statusCode": "CRITICAL_MALFORMED_DATATYPE_STRING"}');
                }
                when 6 {
                    // Simulate system transport Layer Drop out
                    System.CalloutException calloutEx = new System.CalloutException();
                    calloutEx.setMessage('Read timed out / Endpoint unavailable');
                    throw calloutEx;
                }
            }
            return res;
        }
    }
}