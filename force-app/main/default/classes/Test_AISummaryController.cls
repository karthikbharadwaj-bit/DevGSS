@isTest
private class Test_AISummaryController {

    public class ChatGPTAcctServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id": "chatcmpl-BOj34XoCF1VbbKV5PjYcRnkXII0nx","object": "chat.completion","created": 1745232738,"model": "gpt-4.5-preview-2025-02-27","choices": [{"index": 0,"message": {"role": "assistant","content": "The account Test Account is a customer in the Computing Services industry, based in Canada, with a monthly recurring revenue of 12,000 and a next renewal date set in next six months","refusal": null,"annotations": []},"finish_reason": "stop"}],"usage": {"prompt_tokens": 35728,"completion_tokens": 35,"total_tokens": 35763,"prompt_tokens_details": {"cached_tokens": 0,"audio_tokens": 0},"completion_tokens_details": {"reasoning_tokens": 0,"audio_tokens": 0,"accepted_prediction_tokens": 0,"rejected_prediction_tokens": 0}},"service_tier": "default","system_fingerprint": null}');
            return res;
        }
    }

    public class ChatGPTCaseServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id": "chatcmpl-BOj34XoCF1VbbKV5PjYcRnkXII0nx","object": "chat.completion","created": 1745232738,"model": "gpt-4.5-preview-2025-02-27","choices": [{"index": 0,"message": {"role": "assistant","content": "This case is associated with the account Test Account. It has a high severity level (Level 3) and falls under the Direct Customer call category. The subject of the case suggests its a test case and it is currently in New status.","refusal": null,"annotations": []},"finish_reason": "stop"}],"usage": {"prompt_tokens": 35728,"completion_tokens": 35,"total_tokens": 35763,"prompt_tokens_details": {"cached_tokens": 0,"audio_tokens": 0},"completion_tokens_details": {"reasoning_tokens": 0,"audio_tokens": 0,"accepted_prediction_tokens": 0,"rejected_prediction_tokens": 0}},"service_tier": "default","system_fingerprint": null}');
            return res;
        }
    }

    public class ChatGPTOpptyServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id": "chatcmpl-BOj34XoCF1VbbKV5PjYcRnkXII0nx","object": "chat.completion","created": 1745232738,"model": "gpt-4.5-preview-2025-02-27","choices": [{"index": 0,"message": {"role": "assistant","content": "This opportunity Test Opportunity is in the Prospecting stage with a 20% probability. It has an estimated 12-month pipeline of $100000 and is set to close in the next quarter.","refusal": null,"annotations": []},"finish_reason": "stop"}],"usage": {"prompt_tokens": 35728,"completion_tokens": 35,"total_tokens": 35763,"prompt_tokens_details": {"cached_tokens": 0,"audio_tokens": 0},"completion_tokens_details": {"reasoning_tokens": 0,"audio_tokens": 0,"accepted_prediction_tokens": 0,"rejected_prediction_tokens": 0}},"service_tier": "default","system_fingerprint": null}');
            return res;
        }
    }

    public class ChatGPTLeadServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id": "chatcmpl-BOj34XoCF1VbbKV5PjYcRnkXII0nx","object": "chat.completion","created": 1745232738,"model": "gpt-4.5-preview-2025-02-27","choices": [{"index": 0,"message": {"role": "assistant","content": "The lead is from Marcus and Co Law Firm located in the United States and operates within the Other industry category.The lead was generated through sales activities and is currently at the Contacted stage.Contact email provided for the lead is contact_marcusandco@mnc.com","refusal": null,"annotations": []},"finish_reason": "stop"}],"usage": {"prompt_tokens": 35728,"completion_tokens": 35,"total_tokens": 35763,"prompt_tokens_details": {"cached_tokens": 0,"audio_tokens": 0},"completion_tokens_details": {"reasoning_tokens": 0,"audio_tokens": 0,"accepted_prediction_tokens": 0,"rejected_prediction_tokens": 0}},"service_tier": "default","system_fingerprint": null}');
            return res;
        }
    }

    public class GCPRedAccountServiceMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            // First call is the JWT -> identity token exchange; second call is the Cloud Run endpoint.
            if (callCount == 1) {
                res.setBody('{"id_token":"mock-id-token-value"}');
            } else {
                res.setBody('{"body":{"red_account_summary":{"overall_summary":"<p>...</p>","risk_reason":"<p>...</p>","current_status":"<p>...</p>","next_steps":"<p>...</p>"}},"statusCode":200}');
            }
            return res;
        }
    }

    @isTest
    static void testAcctSummary() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Name, 'Test Account')
            .setField(Account.Type, 'Customer')
            .setField(Account.Industry, 'Computing Services')
            .setField(Account.BillingCountry, 'Canada')
            .setField(Account.MRR__c, 12000.00)
            .setField(Account.Next_Renewal_Date__c, Date.Today().AddMonths(6))
            .create()
            .getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ChatGPTAcctServiceMock());
        String response = AISummaryController.generateAccountSummary(acc.Id);
        Assert.areEqual(true, String.isNotBlank(response), 'No response received from Acct Mock ChatGPT Service');
        Test.stopTest();
    }

    @isTest
    static void testCaseSummary() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Name, 'Test Account')
            .setField(Account.Type, 'Customer')
            .setField(Account.Industry, 'Computing Services')
            .setField(Account.BillingCountry, 'Canada')
            .setField(Account.MRR__c, 12000.00)
            .setField(Account.Next_Renewal_Date__c, Date.Today().AddMonths(6))
            .create()
            .getRecord();

        Case cs = (Case) new sObjectBuilder(Case.sObjectType)
            .setField(Case.RecordTypeId, CaseHelper.RT_ID_SUPPORT_T1)
            .setField(Case.AccountId, acc.Id)
            .setField(Case.Subject, 'Test Case - Pls ignore')
            .setField(Case.Description, 'Test Description')
            .setField(Case.Case_Severity__c, 'Level 3 - High')
            .setField(Case.Call_Category__c, 'Direct Customer')
            .setField(Case.Status, 'New')
            .create()
            .getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ChatGPTCaseServiceMock());
        String response = AISummaryController.generateCaseSummary(cs.Id);
        Assert.areEqual(true, String.isNotBlank(response), 'No response received from Case Mock ChatGPT Service');
        Test.stopTest();
    }

    @isTest
    static void testOpportunitySummary() {
        // Create test account
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        // Create test opportunity
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.StageName, 'Prospecting')
            .setField(Opportunity.CloseDate, Date.Today().addMonths(3))
            .setField(Opportunity.Probability, 20)
            .setField(Opportunity.Estimated_12M_Total_Pipeline__c, 100000)
            .setField(Opportunity.Type, 'New Business')
            .create()
            .getRecord();

        // Create test task
        Task tsk = (Task) new SObjectBuilder(Task.SObjectType)
            .setField(Task.WhatId, opp.Id)
            .setField(Task.Subject, 'Test Task')
            .setField(Task.Status, 'Not Started')
            .setField(Task.ActivityDate, Date.Today())
            .create()
            .getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ChatGPTOpptyServiceMock());
        String response = AISummaryController.generateOpptySummary(opp.Id);
        Assert.areEqual(true, String.isNotBlank(response), 'No response received from Opportunity Mock ChatGPT Service');
        Test.stopTest();
    }

    @isTest
    static void testLeadSummary() {
        Lead leadVar = (Lead) new sObjectBuilder(Lead.sObjectType)
            .setField(Lead.RecordTypeId, LeadHelper.RT_ID_SALES_LEADS)
            .setField(Lead.Company, 'Marcus and Co Law Firm')
            .setField(Lead.Email, 'contact_marcusandco@mnc.com')
            .setField(Lead.LastName, 'MarcusLead1')
            .setField(Lead.Industry, 'Other')
            .setField(Lead.LeadSource, 'Sales Generated')
            .setField(Lead.Status, '2. Contacted')
            .setField(Lead.Country__c, 'United States')
            .create()
            .getRecord();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ChatGPTLeadServiceMock());
        String response = AISummaryController.generateLeadSummary(leadVar.Id);
        Assert.areEqual(true, String.isNotBlank(response), 'No response received from Lead Mock ChatGPT Service');
        Test.stopTest();
    }
    
    @isTest
    static void testLogAIHEvent_View() {
        Test.startTest();
        AISummaryController.logAIHEvent('aih_view', 'Case Summary', null);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Case Summary', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areEqual(1, logs[0].View_Count__c, 'View count should be 1');
    }

    @isTest
    static void testLogAIHEvent_Like() {
        String feedback = '{"feature":"CaseSummary","parentNumber":"2436","reason":"helpful"}';
        
        Test.startTest();
        AISummaryController.logAIHEvent('aih_like', 'Case Summary', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Case Summary', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areEqual(1, logs[0].Like_Count__c, 'Like count should be 1');
    }

    @isTest
    static void testLogAIHEvent_Feedback() {
        String feedback = '{"feature":"CaseSummary","parentNumber":"2436","reason":"needs improvement"}';
        
        Test.startTest();
        AISummaryController.logAIHEvent('aih_feedback', 'Case Summary', feedback);
        Test.stopTest();

        Id userId = UserInfo.getUserId();
        List<AI_Usage_Log__c> logs = new AIUsageLogSelector()
            .selectAIHUserLog(userId, 'Daily Log', 'Case Summary', AIUsageLogHelper.RT_ID_AIH)
            .executeQuery();
        
        Assert.areEqual(1, logs.size(), 'Should create one AIH log record');
        Assert.areNotEqual(null, logs[0].AIH_Feedback__c, 'Feedback should be recorded');
    }



    @isTest
    static void testParseRedAccountSummaryTopLevelResponse() {
        String responseBody = '{"red_account_summary":{"overall_summary":"<p>Overall text</p>","risk_reason":"<p>Risk text</p>","current_status":"<p>Status text</p>","next_steps":"<p>Next step text</p>"},"statusCode":200}';

        Test.startTest();
        String response = AISummaryController.parseRedAccountSummaryResponse(responseBody);
        Test.stopTest();

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(true, (Boolean) parsed.get('success'), 'Top-level red account summary response should parse successfully.');
        Assert.isTrue(String.valueOf(parsed.get('summary')).contains('Overall Summary'), 'Expected overall section header.');
    }

    @isTest
    static void testParseRedAccountSummaryStringBodyResponse() {
        String bodyJson = '{"red_account_summary":{"overall_summary":"<p>Overall text</p>","risk_reason":"<p>Risk text</p>","current_status":"<p>Status text</p>","next_steps":"<p>Next step text</p>"}}';
        String responseBody = JSON.serialize(new Map<String, Object>{ 'body' => bodyJson, 'statusCode' => 200 });

        Test.startTest();
        String response = AISummaryController.parseRedAccountSummaryResponse(responseBody);
        Test.stopTest();

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(true, (Boolean) parsed.get('success'), 'String body red account summary response should parse successfully.');
        Assert.isTrue(String.valueOf(parsed.get('summary')).contains('Next Steps'), 'Expected next steps section header.');
    }

    @isTest
    static void testRedAccountSummaryToggleEnabledTrue() {
        GCP_Feature_Toggle__c setting = new GCP_Feature_Toggle__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Red_Account_Summary_Switch__c = true
        );
        insert setting;

        Test.startTest();
        Boolean result = AISummaryController.isRedAccountSummaryEnabled();
        Test.stopTest();

        Assert.areEqual(true, result, 'Red Account Summary toggle should return TRUE when enabled.');
    }

    @isTest
    static void testRedAccountSummaryToggleEnabledFalse() {
        GCP_Feature_Toggle__c setting = new GCP_Feature_Toggle__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Red_Account_Summary_Switch__c = false
        );
        insert setting;

        Test.startTest();
        Boolean result = AISummaryController.isRedAccountSummaryEnabled();
        Test.stopTest();

        Assert.areEqual(false, result, 'Red Account Summary toggle should return FALSE when disabled.');
    }

    @isTest
    static void testRedAccountSummary() {
        // Org-default custom settings required by GCPAuthUtil.loadConfig and getRedactionFlag.
        GCP_Endpoint_Settings__c gcpSettings = new GCP_Endpoint_Settings__c(
            Service_Account_Email__c = 'quantiphiandgss@appspot.gserviceaccount.com',
            Identity_Token_URL__c = 'https://oauth2.googleapis.com/token',
            Certificate_Name__c = 'privatekey',
            Red_Account_Summary_Endpoint__c = 'https://mock-gcp-endpoint.example.com'
        );
        insert gcpSettings;

        AI_Feature_Pilot_Control__c pilotControl = new AI_Feature_Pilot_Control__c(
            Redaction_Needed__c = false
        );
        insert pilotControl;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.Name, 'Test Red Account Parent')
            .setField(Account.Type, 'Customer')
            .create()
            .getRecord();
        
        Red_Account__c redAcc = (Red_Account__c) new SObjectBuilder(Red_Account__c.SObjectType)
            .setField(Red_Account__c.EscalatedAccount__c, acc.Id)
            .setField(Red_Account__c.Primary_Reason_for_Red__c, 'Business Decision')
            .setField(Red_Account__c.Sub_Reason_for_Red__c, 'Fewer employees')
            .setField(Red_Account__c.Issue_Category__c, 'Other')
            .setField(Red_Account__c.Issue_Status__c, 'At Risk')
            .setField(Red_Account__c.Best_Case_Downsell__c, 100)
            .setField(Red_Account__c.Likely_Case_Downsell__c, 50)
            .setField(Red_Account__c.Executive_Summary__c, 'Customer requested removal of 3 unused DLs due to reduced headcount.')
            .setField(Red_Account__c.Issue_Summary__c, '05/01 - Downsell opportunity created, pending internal approval.')
            .setField(Red_Account__c.Detailed_Action_Plan__c, 'Submit change order for approval, then notify customer once processed.')
            .create()
            .getRecord();

        Test.startTest();
        // Single mock instance handles both callouts (JWT exchange + Cloud Run) via internal counter.
        Test.setMock(HttpCalloutMock.class, new GCPRedAccountServiceMock());
        String response = AISummaryController.generateRedAccountSummary(UserInfo.getUserId(), redAcc.Id);
        Test.stopTest();

        Assert.areEqual(true, String.isNotBlank(response), 'No response received from Red Account Mock GCP Service');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(response);
        Assert.areEqual(true, (Boolean) parsed.get('success'), 'Expected GCP Red Account Summary call to succeed. Response: ' + response);
    }
}