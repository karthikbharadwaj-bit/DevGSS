@IsTest
private class Test_CCBAPI {
    @TestSetup
    static void setup() {
        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.BaseEndpoint__c => 'https://fake-icb-api',
                CCB_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.SignUpPath__c => '/sign-up',
                CCB_Settings__c.TerminationPath__c => '/termination/enterprise-account-id',
                CCB_Settings__c.CountriesPath__c => '/countries',
                CCB_Settings__c.DirectBaseEndpoint__c => 'http://ext-ccb.cre-dev.lab.engage.ringcentral.com/restapi',
                CCB_Settings__c.EDPlatformsPath__c => '/engage-digital/platforms',
                CCB_Settings__c.EDSubmit__c => '/engage-digital/sign-up/opportunity',
                CCB_Settings__c.EVPlatformsPath__c => '/engage-voice/platforms',
                CCB_Settings__c.EVSubmit__c => '/engage-voice/sign-up/opportunity',
                CCB_Settings__c.ValidatePath__c => '/address/validate',
                CCB_Settings__c.APIVersion2Path__c => '/v2.0/ccb',
                CCB_Settings__c.APIVersion3Path__c => '/v3.0/ccb'
            })
            .create();
    }

    @isTest
    static void testValidateBillingAddress() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        BillingWrappers.BillingAddress billingAddress = CCBAPIMock.getBillingAddress();

        Test.startTest();
        Response resp = CCBAPI.validateBillingAddress(billingAddress);
        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'The response has error messages');

        Map<String, Object> body = (Map<String, Object>) resp.getData('body');
        System.assertEquals('valid', (String) body.get('status'), 'Expected "valid" status');
    }

    @isTest
    static void testGetEngagePlatformsVoice() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        Test.startTest();
        Response resp = CCBAPI.getEngagePlatforms(true);
        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'The response has error messages');

        List<Object> platforms = (List<Object>) resp.getData('body');
        System.assert(!platforms.isEmpty(), 'Expected at least one platform to be returned');
    }

    @isTest
    static void testGetEngagePlatformsDigital() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        Test.startTest();
        Response resp = CCBAPI.getEngagePlatforms(false);
        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'The response has error messages');

        List<Object> platforms = (List<Object>) resp.getData('body');
        System.assert(!platforms.isEmpty(), 'Expected at least one platform to be returned');
    }

    @isTest
    static void testSubmitEngageVoice() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.isEngageVoice = true;
        params.accountId = 'invalid id';

        Test.startTest();
        Response resp = CCBAPI.submitEngage(params);
        Test.stopTest();

        System.assert(!resp.messages.isEmpty(), 'The response has no error messages');
        System.assertEquals(
            String.format(CCBAPI.ENGAGE_SUBMITTED_WITH_ERROR, new List<String> { 'billing_id', 'enterprise_id' }),
            resp.messages[0].messageDetails,
            'Wrong error message'
        );
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSubmitEngageDigital() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = opp.Id;
        params.accountId = opp.AccountId;
        params.isEngageVoice = false;
        params.isMultiProductTechnicalQuote = false;
        params.isMPUB = false;

        Test.startTest();
        Response resp = CCBAPI.submitEngage(params);
        Test.stopTest();

        assertSubmitEngageDigital(opp.AccountId, resp);
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSubmitEngageDigitalMPUBFlow() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock(CCBAPIMock.MPFlow.MPUB));

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = opp.Id;
        params.accountId = opp.AccountId;
        params.isEngageVoice = false;
        params.isMultiProductTechnicalQuote = false;
        params.isMPUB = true;

        Test.startTest();
            Response resp = CCBAPI.submitEngage(params);
        Test.stopTest();

        assertSubmitEngageDigital(opp.AccountId, resp);
    }

    @isTest
    static void testSubmitEngageFail() {
        CCBAPIMock testMock = new CCBAPIMock();
        testMock.statusCode = 400;
        Test.setMock(HttpCalloutMock.class, testMock);

        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.isEngageVoice = false;

        Test.startTest();
        Response resp = CCBAPI.submitEngage(params);
        Test.stopTest();

        System.assert(resp.messages.size() == 1, 'Expected one error message');

        Response.ResponseMessage message = resp.messages[0];
        System.assertEquals(CCBAPI.SUBMIT_ENGAGE_FAILED, message.message, 'Wrong message is returned');
        System.assertEquals(CCBAPIMock.SUBMIT_ERROR_MESSAGE, message.messageDetails, 'Wrong message details are returned');
        System.assertEquals(Response.SEVERITY_ERROR, message.severity, 'Wrong severity is returned');
    }

    @isTest
    static void testSubmitEngageExceptionIsThrown() {
        CCBAPIMock testMock = new CCBAPIMock();
        testMock.statusCode = 500;
        testMock.raiseException = true;
        Test.setMock(HttpCalloutMock.class, testMock);

        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.isEngageVoice = false;

        Boolean ccbExceptionCaught = false;
        Test.startTest();
        try {
            Response resp = CCBAPI.submitEngage(params);
        } catch (CCBAPI.CCBAPIException ex) {
            ccbExceptionCaught = true;
            System.assert(
                ex.getMessage().startsWith(CCBAPI.addCCBPrefix(CCBAPI.REQUEST_CCB_EXCEPTION_MESSAGE)),
                'Wrong exception message received'
            );
        }
        Test.stopTest();

        System.assert(ccbExceptionCaught, 'No CCBAPI.CCBAPIException was raised');
    }

    @isTest
    static void testGetCountries() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        Test.startTest();
        String stringResp = CCBAPI.getCountries();
        Test.stopTest();

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(stringResp);
        List<Object> messages = (List<Object>) resp.get('messages');
        System.assert(messages.isEmpty(), 'Error message was received');

        Map<String, Object> data = (Map<String, Object>) resp.get('data');
        List<Object> countries = (List<Object>) data.get('countries');
        System.assertEquals(2, countries.size(), 'Wrong amount of countries were received');
    }

    @isTest
    static void testGetCountriesFail() {
        CCBAPIMock testMock = new CCBAPIMock();
        testMock.statusCode = 400;
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
        String stringResp = CCBAPI.getCountries();
        Test.stopTest();

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(stringResp);
        List<Object> messages = (List<Object>) resp.get('messages');
        System.assert(!messages.isEmpty(), 'Error message was not received');

        Map<String, Object> messageMap = (Map<String, Object>) messages[0];
        String message = (String) messageMap.get('message');
        System.assert(message.contains('An error occurred while getting the list of countries.'), 'Wrong message is returned');
        System.assertEquals(null, messageMap.get('messageDetails'), 'Wrong message details are returned');
        System.assertEquals(Response.SEVERITY_ERROR, messageMap.get('severity'), 'Wrong severity is returned');
    }

    @isTest
    static void testHandleResponse() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        final CCB_Settings__c CCB_SETTINGS = CCB_Settings__c.getInstance();
        String endpoint = CCB_SETTINGS.DirectBaseEndpoint__c + CCB_SETTINGS.APIVersion2Path__c + CCB_SETTINGS.SignUpPath__c;

        Test.startTest();
        HttpResponse httpResp = CCBAPI.requestCCB(endpoint, HttpHelper.METHOD_POST, 'requestBody');
        Response resp = CCBAPI.handleResponse(httpResp);
        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'The response has error messages');
        System.assertEquals(null, resp.getData('status'), 'Wrong submit status');
    }

    @isTest
    static void testHandleResponseFail() {
        CCBAPIMock testMock = new CCBAPIMock();
        testMock.statusCode = 400;
        Test.setMock(HttpCalloutMock.class, testMock);

        final CCB_Settings__c CCB_SETTINGS = CCB_Settings__c.getInstance();
        String endpoint = CCB_SETTINGS.DirectBaseEndpoint__c + CCB_SETTINGS.APIVersion2Path__c + CCB_SETTINGS.SignUpPath__c;

        Test.startTest();
        HttpResponse httpResp = CCBAPI.requestCCB(endpoint, HttpHelper.METHOD_POST, 'requestBody');
        Response resp = CCBAPI.handleResponse(httpResp);
        Test.stopTest();

        System.assert(resp.messages.size() == 1, 'Expected one error message');
        System.assertEquals(Response.STATUS_ERROR, resp.status, 'Wrong response status');

        Response.ResponseMessage message = resp.messages[0];
        System.assertEquals(CCBAPI.SYNC_CCB_FAILED, message.message, 'Wrong message is returned');
        System.assertEquals(
            StringHelper.safeString(CCBAPIMock.SUBMIT_ERROR_MESSAGE) + '\n' + StringHelper.safeString(CCBAPIMock.SUBMIT_ERROR_MESSAGE),
            message.messageDetails,
            'Wrong message details are returned'
        );
        System.assertEquals(Response.SEVERITY_ERROR, message.severity, 'Wrong severity is returned');
    }

    @isTest
    static void testGetUILessEndpoint() {
        Test.startTest();
            String multiProductLiteEndpoint = CCBAPI.getSignUpUILessEndpoint(false);
            String mpubEndpoint = CCBAPI.getSignUpUILessEndpoint(true);
        Test.stopTest();

        System.assertEquals(CCBAPI.DIRECT_BASE_ENDPOINT_V2 + CCBAPI.CCB_SETTINGS.SignUpPath__c, multiProductLiteEndpoint, 'Wrong endpoint is returned for MP-Lite');
        System.assertEquals(CCBAPI.DIRECT_BASE_ENDPOINT_V3 + CCBAPI.CCB_SETTINGS.SignUpPath__c, mpubEndpoint, 'Wrong endpoint is returned for MPUB');
    }

    private static void assertSubmitEngageDigital(Id accId, Response resp) {
        System.assert(resp.messages.isEmpty(), 'The response has error messages');
        System.assertEquals(CCBAPI.STATUS_SUBMITTED, resp.getData('status'), 'Wrong submit status');

        Account acc = (Account) new AccountSelector()
            .selectAccountById(accId)
            .executeQuery()
            .get(0);

        System.assertEquals('billing_id', acc.Billing_ID__c, 'Billing id must be updated');
        System.assertEquals('engage_account_id', acc.RC_Engage_Account_ID__c, 'Engage Account id must be updated');
        System.assertEquals('engage_digital_account_id', acc.ED_Account_ID__c, 'Engage Account id must be updated');
    }
}