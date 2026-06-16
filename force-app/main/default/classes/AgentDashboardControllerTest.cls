@IsTest
public class AgentDashboardControllerTest {
    private static final String TOKEN_URL = 'https://mock.identity/token';
    private static final String DASHBOARD_ENDPOINT = 'https://mock.agentdashboard/endpoint';

    @TestSetup
    static void setupData() {
        GCP_Endpoint_Settings__c config = new GCP_Endpoint_Settings__c(
            Identity_Token_URL__c = TOKEN_URL,
            Agent_Dashboard_Endpoint__c = DASHBOARD_ENDPOINT,
            Certificate_Name__c = 'privatekey',
            Service_Account_Email__c = 'test@test-project.iam.gserviceaccount.com'
        );
        insert config;

        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'Test Agent Dashboard Case',
                    Case.Description => 'Test Description',
                    Case.Status => 'New',
                    Case.Origin => 'Phone',
                    Case.OwnerId => UserInfo.getUserId()
                }
            )
            .create()
            .getRecord();
    }

    private class AgentDashboardCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('identity') || req.getEndpoint().contains('token')) {
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'id_token' => 'mocked-id-token'
                }));
            } else if (req.getEndpoint().contains('agentdashboard') || req.getEndpoint().contains('mock.agentdashboard')) {
                Map<String, Object> bodyByCaseId = new Map<String, Object>();
                Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
                List<Object> cases = (List<Object>) payload.get('cases');
                if (cases != null) {
                    for (Object co : cases) {
                        Map<String, Object> casePayload = (Map<String, Object>) co;
                        String recordID = String.valueOf(casePayload.get('recordID'));
                        bodyByCaseId.put(recordID, new Map<String, Object>{
                            'case_sentiment' => 'positive',
                            'case_sentiment_reason' => 'Customer satisfied',
                            'escalation_sentiment' => 'low',
                            'escalation_sentiment_reason' => 'No escalation risk'
                        });
                    }
                }
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'statusCode' => 200,
                    'body' => bodyByCaseId
                }));
            }
            return res;
        }
    }

    private class AgentDashboardErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Server error"}');
            return res;
        }
    }

    /** Mock that returns legacy format: results array with api1_result / api2_result per case */
    private class LegacyResultsFormatMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('identity') || req.getEndpoint().contains('token')) {
                res.setBody(JSON.serialize(new Map<String, Object>{ 'id_token' => 'mocked-id-token' }));
                return res;
            }
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            List<Object> cases = (List<Object>) payload.get('cases');
            List<Map<String, Object>> results = new List<Map<String, Object>>();
            if (cases != null) {
                for (Object co : cases) {
                    Map<String, Object> casePayload = (Map<String, Object>) co;
                    results.add(new Map<String, Object>{
                        'recordID' => casePayload.get('recordID'),
                        'caseNumber' => casePayload.get('caseNumber'),
                        'priority' => casePayload.get('priority'),
                        'case_status' => casePayload.get('case_status'),
                        'case_age' => casePayload.get('case_age'),
                        'assignedDate' => casePayload.get('assignedDate'),
                        'lastModifiedByName' => casePayload.get('lastModifiedByName'),
                        'lastModifiedDate' => casePayload.get('lastModifiedDate'),
                        'recordTypeName' => casePayload.get('recordTypeName'),
                        'api1_result' => new Map<String, Object>{
                            'statusCode' => 200,
                            'body' => new Map<String, Object>{
                                'sentiment' => 'neutral',
                                'reason' => 'Legacy sentiment reason'
                            }
                        },
                        'api2_result' => new Map<String, Object>{
                            'statusCode' => 200,
                            'body' => new Map<String, Object>{
                                'escalation_metric' => 'medium',
                                'reason' => 'Legacy escalation reason'
                            }
                        }
                    });
                }
            }
            res.setBody(JSON.serialize(new Map<String, Object>{ 'results' => results }));
            return res;
        }
    }

    /** Mock that returns body + statusCode 200 but empty body map (no insights per case -> N/A) */
    private class ProcessedFormatEmptyBodyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('identity') || req.getEndpoint().contains('token')) {
                res.setBody(JSON.serialize(new Map<String, Object>{ 'id_token' => 'mocked-id-token' }));
                return res;
            }
            res.setBody(JSON.serialize(new Map<String, Object>{
                'statusCode' => 200,
                'body' => new Map<String, Object>()
            }));
            return res;
        }
    }

    /** Mock that returns 200 but body that does not match body/statusCode or results (triggers fallback) */
    private class FallbackFormatMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('identity') || req.getEndpoint().contains('token')) {
                res.setBody(JSON.serialize(new Map<String, Object>{ 'id_token' => 'mocked-id-token' }));
                return res;
            }
            res.setBody(JSON.serialize(new Map<String, Object>{
                'otherKey' => 'unrecognized format',
                'body' => 'not a map'
            }));
            return res;
        }
    }

    @IsTest
    static void testGetBatchCasesWithInsights_Success() {
        Id userId = UserInfo.getUserId();
        Test.setMock(HttpCalloutMock.class, new AgentDashboardCalloutMock());

        Test.startTest();
        String result = AgentDashboardController.getBatchCasesWithInsights(userId);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('"success" : true'), 'Response should indicate success');
        System.assert(result.contains('cases'), 'Response should contain cases');
    }

    /** Covers processed cases path: body + statusCode 200, with insights (sentiment/escalation) in response */
    @IsTest
    static void testGetBatchCasesWithInsights_ProcessedCasesWithInsights() {
        Id userId = UserInfo.getUserId();
        Test.setMock(HttpCalloutMock.class, new AgentDashboardCalloutMock());

        Test.startTest();
        String result = AgentDashboardController.getBatchCasesWithInsights(userId);
        Test.stopTest();

        System.assert(result.contains('"success" : true'), 'Response should indicate success');
        System.assert(result.contains('positive'), 'Processed case should contain sentiment from body');
        System.assert(result.contains('Customer satisfied'), 'Processed case should contain sentiment reason');
        System.assert(result.contains('low'), 'Processed case should contain escalation metric');
        System.assert(result.contains('No escalation risk'), 'Processed case should contain escalation reason');
        System.assert(!result.contains('"warning"'), 'Processed format should not include warning');
    }

    /** Covers processed cases when body is empty (no insights -> N/A and empty reasons) */
    @IsTest
    static void testGetBatchCasesWithInsights_ProcessedCasesEmptyBody() {
        Id userId = UserInfo.getUserId();
        Test.setMock(HttpCalloutMock.class, new ProcessedFormatEmptyBodyMock());

        Test.startTest();
        String result = AgentDashboardController.getBatchCasesWithInsights(userId);
        Test.stopTest();

        System.assert(result.contains('"success" : true'), 'Response should indicate success');
        System.assert(result.contains('sentiment') && result.contains('N/A'), 'Case with no insights should have sentiment N/A');
        System.assert(result.contains('escalationMetric') && result.contains('N/A'), 'Case with no insights should have escalationMetric N/A');
    }

    /** Covers legacy format: results array with api1_result / api2_result */
    @IsTest
    static void testGetBatchCasesWithInsights_LegacyResultsFormat() {
        Id userId = UserInfo.getUserId();
        Test.setMock(HttpCalloutMock.class, new LegacyResultsFormatMock());

        Test.startTest();
        String result = AgentDashboardController.getBatchCasesWithInsights(userId);
        Test.stopTest();

        System.assert(result.contains('"success" : true'), 'Response should indicate success');
        System.assert(result.contains('neutral'), 'Legacy processed case should contain sentiment');
        System.assert(result.contains('Legacy sentiment reason'), 'Legacy case should contain sentiment reason');
        System.assert(result.contains('medium'), 'Legacy case should contain escalation metric');
        System.assert(result.contains('Legacy escalation reason'), 'Legacy case should contain escalation reason');
    }

    /** Covers fallback path when GCP response format is not recognized */
    @IsTest
    static void testGetBatchCasesWithInsights_FallbackFormatNotRecognized() {
        Id userId = UserInfo.getUserId();
        Test.setMock(HttpCalloutMock.class, new FallbackFormatMock());

        Test.startTest();
        String result = AgentDashboardController.getBatchCasesWithInsights(userId);
        Test.stopTest();

        System.assert(result.contains('"success" : true'), 'Fallback should still return success');
        System.assert(result.contains('Response format not recognized'), 'Fallback should set sentimentReason/escalationReason');
        System.assert(result.contains('GCP response format not recognized, showing cases without AI insights'), 'Fallback should include warning');
        System.assert(result.contains('"warning"'), 'Response should contain warning key');
    }

    @IsTest
    static void testGetBatchCasesWithInsights_EmptyCases() {
        User runUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'AgentDashboardEmpty',
                    User.Username => 'agentdashboard.empty@test.com',
                    User.Email => 'agentdashboard.empty@test.com',
                    User.Alias => 'adempty',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => UserInfo.getProfileId(),
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();

        System.runAs(runUser) {
            Test.startTest();
            String result = AgentDashboardController.getBatchCasesWithInsights(runUser.Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.contains('"success" : true'), 'Response should indicate success');
            System.assert(result.contains('"cases" : [ ]'), 'Cases list should be empty');
        }
    }

    @IsTest
    static void testGetClosedCasesCountLastMonth_Zero() {
        Id userId = UserInfo.getUserId();
        Test.startTest();
        Integer count = AgentDashboardController.getClosedCasesCountLastMonth(userId);
        Test.stopTest();
        System.assertNotEquals(null, count, 'Count should not be null');
        System.assert(count >= 0, 'Count should be non-negative');
    }

    @IsTest
    static void testGetClosedCasesCountLastMonth_WithClosedCase() {
        Id userId = UserInfo.getUserId();
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject => 'Closed Case',
                    Case.Status => 'Closed',
                    Case.Origin => 'Phone',
                    Case.OwnerId => userId
                }
            )
            .create()
            .getRecord();
        c.Status = 'Closed';
        update c;

        Test.startTest();
        Integer count = AgentDashboardController.getClosedCasesCountLastMonth(userId);
        Test.stopTest();
        System.assertNotEquals(null, count, 'Count should not be null');
        System.assert(count >= 1, 'Should count at least the closed case');
    }
}