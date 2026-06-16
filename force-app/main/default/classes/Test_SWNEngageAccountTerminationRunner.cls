@isTest
class Test_SWNEngageAccountTerminationRunner {
    private static final String RC_USER_ID = 'RC_USER_ID';
    class MockHttpResponseGenerator implements HttpCalloutMock {
        private Boolean isSuccess;
        
        public MockHttpResponseGenerator(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (isSuccess) {
                res.setStatusCode(200);
                res.setStatus('OK');
                res.setBody('{"success": true}');
            } else {
                res.setStatusCode(400);
                res.setStatus('BAD');
                res.setBody('{"success": false, "messages": [{"message": "Error occurred"}]}');
            }
            return res;
        }
    }

    private static SWNDataCollector generateSDC() {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        sdc.ngbsPackage.id = 'somePackageId';

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Id => new ValueProvider.DummyIdProvider(Opportunity.sObjectType),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .build()
            .getRecord();

        opp.putSObject(Opportunity.AccountId, new Account(RC_User_ID__c = RC_USER_ID));
        sdc.opp = opp;
        sdc.currentStep = SWNStep.buildEngageAccountTerminationStep();
        return sdc;
    }

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
    static void testBuildEndpoint() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .create()
            .getRecord();

        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        String expectedEndpoint = CCBAPI.CCB_SETTINGS.BaseEndpoint__c
            + CCBAPI.CCB_SETTINGS.TerminationPath__c
            + '/' + RC_USER_ID;

        Test.startTest();
            String endpoint = runner.buildEndpoint(RC_USER_ID);
        Test.stopTest();

        Assert.areEqual(expectedEndpoint, endpoint, 'Wrong endpoint');
    }

    @isTest
    static void testBuildEndpointUILess() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, true)
            .create()
            .getRecord();

        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        String expectedEndpoint = CCBAPI.CCB_SETTINGS.DirectBaseEndpoint__c
            + CCBAPI.CCB_SETTINGS.APIVersion2Path__c
            + CCBAPI.CCB_SETTINGS.TerminationPath__c
            + '/' + RC_USER_ID;

        Test.startTest();
            String endpoint = runner.buildEndpoint(RC_USER_ID);
        Test.stopTest();

        Assert.areEqual(expectedEndpoint, endpoint, 'Wrong endpoint');
    }

    @isTest
    static void testHandleSuccess() {
        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        Response resp = new Response();

        Test.startTest();
            runner.handleSuccess(resp);
        Test.stopTest();

        Assert.areEqual(1, resp.messages.size(), 'There should be one success message.');
        Assert.areEqual(
            SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.ACCOUNT_TERMINATION_SUCCESS).message,
            resp.messages[0].messageDetails,
            'The success message should match the expected message.'
        );
    }

    @isTest
    static void testHandleExceptionError() {
        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        HttpResponse httpResp = new HttpResponse();
        httpResp.setStatusCode(500);
        httpResp.setBody('{"error":"Internal Server Error"}');
        
        Test.startTest();
            try {
                runner.handleExceptionError(httpResp, RC_USER_ID);
                Assert.fail('Exception should be thrown');
            } catch (AquivaHelper.AquivaException e) {
                Assert.isTrue(e.getMessage().contains(CCBAPI.REQUEST_CCB_EXCEPTION_MESSAGE), 'Error message does not contain expected text');
            }
        Test.stopTest();
    }

    @isTest
    static void testParseErrorMessage() {
        String jsonResponse = '{"messages":[{"message":"Error 1"},{"message":null},{"message":"Error 2"}]}';
        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        Test.startTest();
            String result = runner.parseErrorMessage(jsonResponse);
        Test.stopTest();
        
        Assert.areEqual('Error 1\nError 2', result, 'The parsed error messages should match the expected output.');
    }

    @isTest
    static void testHandleError() {
        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        Response resp = new Response();
        HttpResponse httpResp = new HttpResponse();

        httpResp.setStatusCode(400);
        httpResp.setBody('{"messages":[{"message":"Error occurred"}]}');

        Test.startTest();
            runner.handleError(resp, httpResp, RC_USER_ID);
        Test.stopTest();

        Assert.areEqual(1, resp.messages.size(), 'There should be one success message.');
        Assert.areEqual(Label.Account_Termination_request_failed, resp.messages[0].message, 'The error message should match the expected value.');
        Assert.areEqual('Error occurred', resp.messages[0].messageDetails, 'The error details should match the expected value.');
    }

    @isTest
    static void testTerminateAccountSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(true));
        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        runner.sdc = generateSDC();
        
        Test.startTest();
            runner.terminateAccount();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed');
    }
    
    @isTest
    static void testTerminateAccountFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        SWNEngageAccountTerminationRunner runner = new SWNEngageAccountTerminationRunner();
        runner.sdc = generateSDC();
        
        Test.startTest();
            runner.terminateAccount();
        Test.stopTest();

        Assert.isFalse(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should not be completed');
    }
}