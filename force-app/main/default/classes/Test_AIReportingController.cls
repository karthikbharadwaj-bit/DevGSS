@isTest
private class Test_AIReportingController {
    private static String JSON_TABLE_DATA = '[{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Agriculture & Livestock","AnnualRevenue":null,"AccountSource":null,"AccountNumber":null,"Name":"Test account 2","Id":"001TH00000Lij2NYAR","recordUrl":"/001TH00000Lij2NYAR"},{"attributes":{"type":"Account"},"RC_Brand__c":"RingCentral","Industry":"Communications","AnnualRevenue":null,"AccountSource":"Online Chat","AccountNumber":null,"Name":"Test RC Account","Id":"001TH00000LfGkhYAF","recordUrl":"/001TH00000LfGkhYAF"},{"attributes":{"type":"Account"},"RC_Brand__c":"RingCentral UK","Industry":null,"AnnualRevenue":null,"AccountSource":null,"AccountNumber":null,"Name":"Nive-RC_UK_Acc","Id":"001TH00000Lc1LZYAZ","recordUrl":"/001TH00000Lc1LZYAZ"},{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Transportation","AnnualRevenue":8200000,"AccountSource":"Online Chat","AccountNumber":"AC1007","Name":"TransGlobal Shipping","Id":"001TH00000LWBfUYAX","recordUrl":"/001TH00000LWBfUYAX"},{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Life Sciences","AnnualRevenue":9500000,"AccountSource":"Office Trials","AccountNumber":"AC1008","Name":"HealthPlus Pharma","Id":"001TH00000LWBfVYAX","recordUrl":"/001TH00000LWBfVYAX"},{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Energy","AnnualRevenue":8800000,"AccountSource":"General Weblead","AccountNumber":"AC1009","Name":"Civic Energy Solutions","Id":"001TH00000LWBfWYAX","recordUrl":"/001TH00000LWBfWYAX"},{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Entertainment","AnnualRevenue":7800000,"AccountSource":"Referral Programs","AccountNumber":"AC1004","Name":"MediaSpark Studios","Id":"001TH00000LWBfRYAX","recordUrl":"/001TH00000LWBfRYAX"},{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Construction","AnnualRevenue":6300000,"AccountSource":"LinkedIn Sales Navigator","AccountNumber":"AC1005","Name":"BrightBuild Construction","Id":"001TH00000LWBfSYAX","recordUrl":"/001TH00000LWBfSYAX"},{"attributes":{"type":"Account"},"RC_Brand__c":null,"Industry":"Agriculture & Livestock","AnnualRevenue":2500000,"AccountSource":"Farming Outbound","AccountNumber":"AC1002","Name":"Greenway Agrotech","Id":"001TH00000LWBfPYAX","recordUrl":"/001TH00000LWBfPYAX"}]';
	private static String SEARCH_PROMPT = 'Show ten recently created accounts';

    @testSetup
    static void createTestData() {
        List<Account> acctList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'Test Acc 1','Test Acc 2','Test Acc 3'}),
                Account.Industry => ValueProviderBuilder.provideList(new List<String> {'Communications','Agriculture & Livestock','Life Sciences'}),
                Account.AnnualRevenue => ValueProviderBuilder.provideList(new List<Decimal> {15000,16000,17000}),
                Account.RC_Brand__c => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.BRAND_RINGCENTRAL,OpportunityHelper.BRAND_RINGCENTRAL_EU,OpportunityHelper.BRAND_RINGCENTRAL_UK}),
                Account.AccountSource => ValueProviderBuilder.provideList(new List<String> {'Live Demo','Online Chat','Consultant'}),
                Account.AccountNumber => ValueProviderBuilder.provideList(new List<String> {'12323432','768547','234345'})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<Account> acctList2 = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'Test Acc 4','Test Acc 5','Test Acc 6'}),
                Account.Industry => ValueProviderBuilder.provideList(new List<String> {'Construction','Education','Energy'}),
                Account.AnnualRevenue => ValueProviderBuilder.provideList(new List<Decimal> {56000,70000,100000}),
                Account.RC_Brand__c => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.BRAND_RINGCENTRAL,OpportunityHelper.BRAND_RINGCENTRAL_AU,OpportunityHelper.BRAND_RINGCENTRAL_CA}),
                Account.AccountSource => ValueProviderBuilder.provideList(new List<String> {'Data.com','Weblead','Jigsaw'}),
                Account.AccountNumber => ValueProviderBuilder.provideList(new List<String> {'566778768','32435','6576767665'})
            })
            .quantity(3)
            .create()
            .getRecords();
    }

    public class AIReportingServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id": "chatcmpl-BOj34XoCF1VbbKV5PjYcRnkXII0nx","object": "chat.completion","created": 1745232738,"model": "gpt-4.5-preview-2025-02-27","choices": [{"index": 0,"message": {"role": "assistant","content": "SELECT Id, Name, AccountNumber, AccountSource, AnnualRevenue, Industry, RC_Brand__c FROM Account ORDER BY CreatedDate DESC LIMIT 10","refusal": null,"annotations": []},"finish_reason": "stop"}],"usage": {"prompt_tokens": 35728,"completion_tokens": 35,"total_tokens": 35763,"prompt_tokens_details": {"cached_tokens": 0,"audio_tokens": 0},"completion_tokens_details": {"reasoning_tokens": 0,"audio_tokens": 0,"accepted_prediction_tokens": 0,"rejected_prediction_tokens": 0}},"service_tier": "default","system_fingerprint": null}');
            return res;
        }
    }

    public class AIReportingServiceErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('Internal Server Error');
            res.setStatusCode(500);
            res.setBody('');
            return res;
        }
    }

    public class AIReportingSummarySvcMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"choices":[{"message":{"content":"{\\\"step1\\\":\\\"SELECT Id, QuoteId FROM QuoteLineItem WHERE Product2.Name LIKE \'%TestProduct%\'\\\",\\\"step2\\\":\\\"SELECT Id, OpportunityId FROM Quote WHERE Id IN :QUOTE_IDS_FROM_STEP_1\\\",\\\"step3\\\":\\\"SELECT Id, AccountId FROM Opportunity WHERE Id IN :OPPTY_IDS_FROM_STEP_2\\\"}"}}]}');
            return res;
        }
    }

    public class AIReportingSummarySvcErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('Internal Server Error');
            res.setStatusCode(500);
            res.setBody('');
            return res;
        }
    }

    public class AIReportingStepByStepMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id": "chatcmpl-BOj34XoCF1VbbKV5PjYcRnkXII0nx","object": "chat.completion","created": 1745232738,"model": "gpt-4.5-preview-2025-02-27","choices": [{"index": 0,"message": {"role": "assistant","content": "- **Highest Revenue**: HealthPlus Pharma with $9.5M.- **Lowest Revenue**: Greenway Agrotech with $2.5M.- **Top Industries by Revenue**: Life Sciences ($9.5M), Energy ($8.8M), Transportation ($8.2M), Entertainment ($7.8M), Construction ($6.3M).- **Most Frequent Industry**: Agriculture & Livestock (2 accounts).- **Common Account Source**: Online Chat (2 accounts: TransGlobal Shipping, Test RC Account).- **Notable Missing Data**: Several accounts lack Annual Revenue, Industry, and Account Source information.- **Brand Distribution**: Majority of accounts have no associated RC_Brand; identified brands include BT Business, RingCentral, and RingCentral UK.- **Highest Revenue Account without Brand**: HealthPlus Pharma ($9.5M).- **Notable Account Numbers**: Accounts with provided numbers range from AC1002 to AC1009; several accounts have no account numbers recorded.","refusal": null,"annotations": []},"finish_reason": "stop"}],"usage": {"prompt_tokens": 35728,"completion_tokens": 35,"total_tokens": 35763,"prompt_tokens_details": {"cached_tokens": 0,"audio_tokens": 0},"completion_tokens_details": {"reasoning_tokens": 0,"audio_tokens": 0,"accepted_prediction_tokens": 0,"rejected_prediction_tokens": 0}},"service_tier": "default","system_fingerprint": null}');
            return res;
        }
    }

    @isTest
    static void testPromptLoad() {
        String searchKeyword = 'account';
        List<String> resultList = AIReportingController.getPromptSuggestions(searchKeyword);
        Assert.areEqual(true, resultList.size()>0, 'Error in loading prompts..!');

        searchKeyword = '';
        List<String> resultList1 = AIReportingController.getPromptSuggestions(searchKeyword);
        Assert.areEqual(true, resultList1.size()==0, 'Error in loading prompts..!');
    }

    @isTest
    static void testAIReport() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AIReportingServiceMock());
            String responseJson = AIReportingController.getAIReport(SEARCH_PROMPT);
            Assert.areEqual(true, String.isNotBlank(responseJson), 'Error in loading mock response for AI Reports...!');
        Test.stopTest();
    }

    @isTest
    static void testAIReportError() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AIReportingServiceErrorMock());
            String responseJson = AIReportingController.getAIReport(SEARCH_PROMPT);
            Assert.areEqual(true, String.isNotBlank(responseJson), 'Error in loading Error mock response for AI Reports...!');
        Test.stopTest();
    }

    @isTest
    static void testAIReportException() {
        String responseJson = AIReportingController.getAIReport(SEARCH_PROMPT);
        Assert.areEqual(true, String.isNotBlank(responseJson), 'Error in loading Exception mock response for AI Reports...!');
    }

    @isTest
    static void testReportSummary() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AIReportingSummarySvcMock());
            String responseJson = AIReportingController.getAISummary(JSON_TABLE_DATA);
            Assert.areEqual(true, String.isNotBlank(responseJson), 'Error in loading mock response for AI Report Summary...!');
        Test.stopTest();
    }

    @isTest
    static void testReportSummaryError() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AIReportingSummarySvcErrorMock());
            String responseJson = AIReportingController.getAISummary(JSON_TABLE_DATA);
            Assert.areEqual(true, String.isNotBlank(responseJson), 'Error in loading Error mock response for AI Report Summary...!');
        Test.stopTest();
    }

    @isTest
    static void testReportSummaryException() {
    	String responseJson = AIReportingController.getAISummary(JSON_TABLE_DATA);
        Assert.areEqual(true, String.isNotBlank(responseJson), 'Error in loading Exception mock response for AI Report Summary...!');
    }

    @isTest
    static void testReportSummaryEmail() {
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new AIReportingSummarySvcMock());
            String response = AIReportingController.sendEmailWithSummary(JSON_TABLE_DATA);
        	String response2 = AIReportingController.sendEmailWithSummary('');
            Assert.areEqual(true,
            	response.contains('Error: Invalid query: unexpected token'),
            	'Expected query parse failure from AI summary SOQL execution'
        );
        Test.stopTest();
    }

    @isTest
    static void testSalesAgreementRelatedReport() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Package_Info__c => Test_OpportunityValidator.packageInfo,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        /* Imitate that active agrement exist */
        testAccount.Active_Sales_Agreement__c = qt.Id;

        update testAccount;
        Triggers.switchOn();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => product.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.Quantity__c => 3,
                Entitlement__c.Price__c => 200
            })
            .create()
            .getRecord();

        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        Test.setMock(HttpCalloutMock.class, new AIReportingStepByStepMock());        
        String stepwisePrompt = 'Show me opportunity with salesagreement and product named TestProduct';
        String result = AIReportingController.getAIReport(stepwisePrompt);
        Assert.areEqual(false, result.contains('records'), 'Expected SOQL result structure');
        Test.stopTest();
    }

    @isTest
    static void testSalesAgreementQueryStepwiseToAccount() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AIReportingStepByStepMock());        
        String stepwisePrompt = 'Show me opportunity with salesagreement and product named TestProduct';
        String result = AIReportingController.getAIReport(stepwisePrompt);
        System.assertEquals(false, result.contains('records'), 'Expected SOQL result structure');
        Test.stopTest();
    }

    @isTest
    static void testFormatIdList() {
        List<Account> acctList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideList(new List<String> {'Test Acc 1','Test Acc 2','Test Acc 3'}),
                Account.Industry => ValueProviderBuilder.provideList(new List<String> {'Communications','Agriculture & Livestock','Life Sciences'}),
                Account.AnnualRevenue => ValueProviderBuilder.provideList(new List<Decimal> {15000,16000,17000}),
                Account.RC_Brand__c => ValueProviderBuilder.provideList(new List<String> {OpportunityHelper.BRAND_RINGCENTRAL,OpportunityHelper.BRAND_RINGCENTRAL_EU,OpportunityHelper.BRAND_RINGCENTRAL_UK}),
                Account.AccountSource => ValueProviderBuilder.provideList(new List<String> {'Live Demo','Online Chat','Consultant'}),
                Account.AccountNumber => ValueProviderBuilder.provideList(new List<String> {'12323432','768547','234345'})
            })
            .quantity(3)
            .create()
            .getRecords();

        Set<Id> ids = new Set<Id> {acctList[0].Id, acctList[1].Id, acctList[2].Id};
        String formatted = AIReportingController.formatIdList(ids);
        Assert.areEqual(true, formatted.startsWith('(') && formatted.endsWith(')'), 'Should return IDs wrapped in parenthesis');
        Assert.areEqual(true, formatted.contains('\''), 'Should contain quoted Ids');
        Assert.areEqual(3, formatted.split(',').size(), 'Should format all 3 Ids');
    }

    @isTest
    static void testIsFinalObjectAccount() {
        // Should return true (explicit account list)
        Assert.areEqual(true, AIReportingController.isFinalObjectAccount('List of accounts'));
        // Should return true (account + context)
        Assert.areEqual(true, AIReportingController.isFinalObjectAccount('Accounts with stage and product info'));
        // Should return false (no account keywords)
        Assert.areEqual(false, AIReportingController.isFinalObjectAccount('Show opportunities with stage'));
        // Should return false (account only, no context)
        Assert.areEqual(false, AIReportingController.isFinalObjectAccount('account overview'));
    }

    @isTest
    static void testGetLargeDataMessage() {
        String message = AIReportingController.getLargeDataMessage();
        Assert.areNotEqual(null, message, 'Should not return null');
        Assert.areEqual(Label.AIReporting_LargeData_Message, message, 'Should return correct label value');
    }

    @isTest
    static void testGetAllowedFieldsPromptFallback() {
        // Step 1: Simulate a non-existing profile name (e.g. "NonExistentProfile")
        String objectApiName = 'Account';
        String nonMatchingProfile = 'NonExistentProfile';
        Boolean isAggregateQuery = false;
        String allowedFields = AIReportingController.getAllowedFieldsPrompt(objectApiName, nonMatchingProfile, isAggregateQuery);
        Assert.areNotEqual('', allowedFields, 'Expected fallback to default Allowed Fields');
    }

    @isTest
    static void testExecuteSOQLDirectly() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        String soql = 'SELECT Id, Name FROM Account WHERE Id = \'' + testAccount.Id + '\'';
        String resultJson = AIReportingController.executeSOQL(soql);
        Assert.areEqual(true, resultJson.contains('records'), 'Should contain records section');
        Assert.areEqual(true, resultJson.contains('fieldLabels'), 'Should contain fieldLabels section');
    }
}