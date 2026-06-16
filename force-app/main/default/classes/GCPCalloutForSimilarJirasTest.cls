@IsTest
private class GCPCalloutForSimilarJirasTest {

    private static final String TEST_SUBJECT     = 'Test Jira Case';
    private static final String TEST_DESCRIPTION = 'Test description for similar jiras';
    private static final String TEST_PRODUCT     = 'TestProduct';
    private static final String TEST_PRODUCT_CS  = 'TestProductCS';
    private static final String OPEN_CSL1        = 'Open Support Level';
    private static final String CLOSE_CSL1       = 'Close Support Level';
    private static final String MAPPED_PRODUCT   = 'Mapped Product';

    @TestSetup
    static void setupData() {
        Case c = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId                    => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject                         => TEST_SUBJECT,
                    Case.Description                     => TEST_DESCRIPTION,
                    Case.Status                          => 'New',
                    Case.Origin                          => 'Phone',
                    Case.ProductType__c                  => TEST_PRODUCT,
                    Case.ProductType_CS__c               => TEST_PRODUCT_CS,
                    Case.OpenCustomerSupportLevel1__c    => OPEN_CSL1,
                    Case.CloseCustomerSupportLevel1__c   => CLOSE_CSL1
                }
            )
            .create()
            .getRecord();

        GCP_Endpoint_Settings__c gcpSetting = new GCP_Endpoint_Settings__c(
            SetupOwnerId                    = UserInfo.getOrganizationId(),
            Similar_Jiras_Endpoint__c       = '/similar-jiras',
            Similar_Jiras_Summary_Endpoint__c = '/jira-summary'
        );
        insert gcpSetting;

        GCP_Feature_Toggle__c featureToggle = new GCP_Feature_Toggle__c(
            SetupOwnerId           = UserInfo.getOrganizationId(),
            Enable_Similar_Jiras__c = true,
            JiraURL__c             = 'https://jira.example.com'
        );
        insert featureToggle;

        Similar_Jira_Product_Mapping__c mapping = new Similar_Jira_Product_Mapping__c(
            Name                          = 'TestMapping',
            ProductType__c                = TEST_PRODUCT,
            ProductType_CS__c             = TEST_PRODUCT_CS,
            OpenCustomerSupportLevel1__c  = OPEN_CSL1,
            CloseCustomerSupportLevel1__c = CLOSE_CSL1,
            Product_Name__c               = MAPPED_PRODUCT
        );
        insert mapping;
    }

    // ---- makeGCPCallout ----

    @IsTest
    static void testMakeGCPCallout_Success_NestedTickets() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new SimilarJirasSuccessNestedMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, TEST_DESCRIPTION, cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true,  resultMap.get('success'),        'Should return success');
        System.assertEquals(true,  resultMap.get('productMatched'), 'Product should be matched');
        System.assert(resultMap.containsKey('jiras'),               'Should contain jiras key');
        List<Object> jiras = (List<Object>) resultMap.get('jiras');
        System.assertEquals(2, jiras.size(), 'Should return 2 tickets from nested response');
    }

    @IsTest
    static void testMakeGCPCallout_Success_FlatList() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new SimilarJirasSuccessFlatListMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, TEST_DESCRIPTION, cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'),        'Should return success with flat list');
        System.assertEquals(true, resultMap.get('productMatched'), 'Product should be matched');
    }

    @IsTest
    static void testMakeGCPCallout_Success_MapBodyTickets() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new SimilarJirasSuccessMapBodyMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, TEST_DESCRIPTION, cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'),        'Should return success with map body tickets');
        System.assertEquals(true, resultMap.get('productMatched'), 'Product should be matched');
    }

    @IsTest
    static void testMakeGCPCallout_NoProductMatch() {
        Id userId = UserInfo.getUserId();
        Case unmatchedCase = (Case) new SObjectBuilder(Case.SObjectType)
            .quantity(1)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId   => CaseHelper.RT_ID_SUPPORT_CASE,
                    Case.Subject        => 'Unmatched Case',
                    Case.Status         => 'New',
                    Case.Origin         => 'Phone',
                    Case.ProductType__c => 'NoMatchProduct'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, unmatchedCase.Subject, '', unmatchedCase.Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true,  resultMap.get('success'),        'Should return success (no-op)');
        System.assertEquals(false, resultMap.get('productMatched'), 'Product should not be matched');
        List<Object> jiras = (List<Object>) resultMap.get('jiras');
        System.assertEquals(0, jiras.size(), 'Jiras list should be empty when no product matches');
    }

    @IsTest
    static void testMakeGCPCallout_EmptyDescription() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new SimilarJirasSuccessNestedMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, '', cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should handle empty description successfully');
    }

    @IsTest
    static void testMakeGCPCallout_CalloutFailure() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new HttpFailureMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, TEST_DESCRIPTION, cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure on non-200 response');
        System.assert(((String) resultMap.get('message')).contains('Callout error'), 'Should contain callout error');
    }

    @IsTest
    static void testMakeGCPCallout_StringBodyResponse() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new StringBodyMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, TEST_DESCRIPTION, cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should return success for string body response (no results)');
        System.assertEquals(true, resultMap.get('productMatched'), 'Product should be matched');
        List<Object> jiras = (List<Object>) resultMap.get('jiras');
        System.assertEquals(0, jiras.size(), 'Jiras list should be empty for string body response');
    }

    @IsTest
    static void testMakeGCPCallout_UnexpectedFormat() {
        Id userId = UserInfo.getUserId();
        List<Case> cases = (List<Case>) new CaseSelector().selectCases().executeQuery();

        Test.setMock(HttpCalloutMock.class, new UnexpectedFormatMock());
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.makeGCPCallout(
            userId, TEST_SUBJECT, TEST_DESCRIPTION, cases[0].Id
        );
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure for unexpected response format');
        System.assertEquals('Unexpected response format', resultMap.get('message'));
    }

    // ---- generateJiraSummary ----

    @IsTest
    static void testGenerateJiraSummary_Success_MapFormat() {
        Test.setMock(HttpCalloutMock.class, new SummarySuccessMapMock());
        String payload = '{"jiras": [{"id": "JIRA-123", "summary": "Test issue"}]}';

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.generateJiraSummary(payload);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should return success for map format');
        System.assert(resultMap.containsKey('ai_summary'),   'Should contain ai_summary key');
        System.assertNotEquals(null, resultMap.get('ai_summary'), 'ai_summary should not be null');
    }

    @IsTest
    static void testGenerateJiraSummary_Success_ListFormat() {
        Test.setMock(HttpCalloutMock.class, new SummarySuccessListMock());
        String payload = '{"jiras": [{"id": "JIRA-123"}]}';

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.generateJiraSummary(payload);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, resultMap.get('success'), 'Should return success for list format');
        System.assert(resultMap.containsKey('ai_summary'),   'Should contain ai_summary key');
    }

    @IsTest
    static void testGenerateJiraSummary_NullPayload() {
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.generateJiraSummary(null);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure for null payload');
    }

    @IsTest
    static void testGenerateJiraSummary_CalloutFailure() {
        Test.setMock(HttpCalloutMock.class, new HttpFailureMock());
        String payload = '{"jiras": [{"id": "JIRA-123"}]}';

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.generateJiraSummary(payload);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure on non-200 response');
        System.assert(((String) resultMap.get('message')).contains('Summary call failed'));
    }

    @IsTest
    static void testGenerateJiraSummary_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, new EmptyResponseMock());
        String payload = '{"jiras": [{"id": "JIRA-123"}]}';

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.generateJiraSummary(payload);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure for empty response');
        System.assertEquals('Error in fetching similar jiras', resultMap.get('message'));
    }

    @IsTest
    static void testGenerateJiraSummary_NoSummaryKey() {
        Test.setMock(HttpCalloutMock.class, new SummaryNoSummaryKeyMock());
        String payload = '{"jiras": [{"id": "JIRA-123"}]}';

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.generateJiraSummary(payload);
        Test.stopTest();

        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, resultMap.get('success'), 'Should return failure when ai_summary is absent');
        System.assertEquals('No summary found in response', resultMap.get('message'));
    }

    // ---- isSimilarJirasEnabled ----

    @IsTest
    static void testIsSimilarJirasEnabled_True() {
        Test.startTest();
        Boolean result = GCPCalloutForSimilarJiras.isSimilarJirasEnabled();
        Test.stopTest();

        System.assertEquals(true, result, 'Feature should be enabled');
    }

    @IsTest
    static void testIsSimilarJirasEnabled_False() {
        GCP_Feature_Toggle__c toggle = GCP_Feature_Toggle__c.getInstance();
        toggle.Enable_Similar_Jiras__c = false;
        upsert toggle;

        Test.startTest();
        Boolean result = GCPCalloutForSimilarJiras.isSimilarJirasEnabled();
        Test.stopTest();

        System.assertEquals(false, result, 'Feature should be disabled');
    }

    @IsTest
    static void testIsSimilarJirasEnabled_NoSetting() {
        delete [SELECT Id FROM GCP_Feature_Toggle__c];

        Test.startTest();
        Boolean result = GCPCalloutForSimilarJiras.isSimilarJirasEnabled();
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when no feature toggle exists');
    }

    // ---- getJiraBaseUrl ----

    @IsTest
    static void testGetJiraBaseUrl_WithUrl() {
        Test.startTest();
        String result = GCPCalloutForSimilarJiras.getJiraBaseUrl();
        Test.stopTest();

        System.assertEquals('https://jira.example.com', result, 'Should return the Jira URL from setting');
    }

    @IsTest
    static void testGetJiraBaseUrl_NoSetting() {
        delete [SELECT Id FROM GCP_Feature_Toggle__c];

        Test.startTest();
        String result = GCPCalloutForSimilarJiras.getJiraBaseUrl();
        Test.stopTest();

        System.assertEquals('', result, 'Should return empty string when no setting exists');
    }

    // ---- logAIHEvent ----

    @IsTest
    static void testLogAIHEvent_View() {
        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('aih_view', 'Similar Jiras', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Jiras', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].View_Count__c, 'View count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Like() {
        String feedback = '{"feature":"SimilarJiras","parentNumber":"1001","itemType":"Jira","itemNumber":"JIRA-456"}';

        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('aih_like', 'Similar Jiras', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Jiras', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].Like_Count__c, 'Like count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Dislike() {
        String feedback = '{"feature":"SimilarJiras","parentNumber":"1001","itemType":"Jira","itemNumber":"JIRA-456"}';

        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('aih_dislike', 'Similar Jiras', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Jiras', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertEquals(1, logs[0].Dislike_Count__c, 'Dislike count should be 1');
    }

    @IsTest
    static void testLogAIHEvent_Feedback() {
        String feedback = '{"feature":"SimilarJiras","parentNumber":"1001","reason":"not relevant"}';

        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('aih_feedback', 'Similar Jiras', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Jiras', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(1, logs.size(), 'Should create one AIH log record');
        System.assertNotEquals(null, logs[0].AIH_Feedback__c, 'Feedback should be recorded');
    }

    @IsTest
    static void testLogAIHEvent_InvalidEventType() {
        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('invalid_event', 'Similar Jiras', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Jiras', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(0, logs.size(), 'Should not create log for invalid event type');
    }

    @IsTest
    static void testLogAIHEvent_BlankEventType() {
        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('', 'Similar Jiras', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Similar Jiras', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(0, logs.size(), 'Should not create log for blank event type');
    }

    @IsTest
    static void testLogAIHEvent_EmptySubfeature() {
        Test.startTest();
        GCPCalloutForSimilarJiras.logAIHEvent('aih_view', '', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Unknown', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();

        System.assertEquals(1, logs.size(), 'Should create log with Unknown subfeature when empty');
    }

    // ---- getMatchingProductName ----

    @IsTest
    static void testGetMatchingProductName_ProductTypeMatch() {
        Case c = new Case(ProductType__c = TEST_PRODUCT);

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(MAPPED_PRODUCT, productName, 'Should match by ProductType__c');
    }

    @IsTest
    static void testGetMatchingProductName_ProductTypeCSMatch() {
        Case c = new Case(ProductType_CS__c = TEST_PRODUCT_CS);

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(MAPPED_PRODUCT, productName, 'Should match by ProductType_CS__c');
    }

    @IsTest
    static void testGetMatchingProductName_OpenCSL1Match() {
        Case c = new Case(OpenCustomerSupportLevel1__c = OPEN_CSL1);

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(MAPPED_PRODUCT, productName, 'Should match by OpenCustomerSupportLevel1__c');
    }

    @IsTest
    static void testGetMatchingProductName_OpenCSL1PartialContains() {
        Case c = new Case(OpenCustomerSupportLevel1__c = OPEN_CSL1 + ' Extended');

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(MAPPED_PRODUCT, productName, 'Should match when case value contains the mapping value');
    }

    @IsTest
    static void testGetMatchingProductName_CloseCSL1Match() {
        Case c = new Case(CloseCustomerSupportLevel1__c = CLOSE_CSL1);

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(MAPPED_PRODUCT, productName, 'Should match by CloseCustomerSupportLevel1__c');
    }

    @IsTest
    static void testGetMatchingProductName_NoMatch() {
        Case c = new Case(ProductType__c = 'NonExistentProduct');

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(null, productName, 'Should return null when no mapping matches');
    }

    @IsTest
    static void testGetMatchingProductName_NullFields() {
        Case c = new Case();

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(null, productName, 'Should return null when all case product fields are null');
    }

    @IsTest
    static void testGetMatchingProductName_NoMappings() {
        delete [SELECT Id FROM Similar_Jira_Product_Mapping__c];
        Case c = new Case(ProductType__c = TEST_PRODUCT);

        Test.startTest();
        String productName = GCPCalloutForSimilarJiras.getMatchingProductName(c);
        Test.stopTest();

        System.assertEquals(null, productName, 'Should return null when no product mappings exist');
    }

    // ---- HTTP Mock classes ----

    private class SimilarJirasSuccessNestedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('[{"body": {"similar_jira_tickets": [{"key": "JIRA-001", "summary": "Ticket 1"}, {"key": "JIRA-002", "summary": "Ticket 2"}]}}]');
            return res;
        }
    }

    private class SimilarJirasSuccessFlatListMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('[{"key": "JIRA-001", "summary": "Ticket 1"}, {"key": "JIRA-002", "summary": "Ticket 2"}]');
            return res;
        }
    }

    private class SimilarJirasSuccessMapBodyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"body": {"similar_jira_tickets": [{"key": "JIRA-001", "summary": "Ticket 1"}]}}');
            return res;
        }
    }

    private class HttpFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }

    private class EmptyResponseMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('');
            return res;
        }
    }

    private class StringBodyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"body": "Error message from n8n"}');
            return res;
        }
    }

    private class UnexpectedFormatMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"body": {"unexpected": "format"}}');
            return res;
        }
    }

    private class SummarySuccessMapMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"body": {"ai_summary": "AI-generated summary of the Jira tickets."}}');
            return res;
        }
    }

    private class SummarySuccessListMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('[{"body": {"ai_summary": "AI-generated summary from list format."}}]');
            return res;
        }
    }

    private class SummaryNoSummaryKeyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            res.setBody('{"body": {"other_key": "no summary here"}}');
            return res;
        }
    }
}