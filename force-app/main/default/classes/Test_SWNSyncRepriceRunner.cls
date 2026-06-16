@isTest
private class Test_SWNSyncRepriceRunner {
    private static final String DTG_RESPONSE = '[{"id":72106001, "name":"Test", "priority":"^", "target":{"catalogId":"123"}}]';
    private static final String DTG_RESPONSE_SKIP = '[{"id":72106001, "name":"Test", "priority":"-", "target":{"catalogId":"444"}}]';

    static SWNSyncRepriceRunner generateTestData() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.OpportunityId => ValueProviderBuilder.provideDummyId(Opportunity.SObjectType)
            })
            .build()
            .getRecord();

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.currentStep = SWNStep.buildRepriceSyncStep();

        SWNSyncRepriceRunner runner = new SWNSyncRepriceRunner(qt.Id, SWNStep.REPRICE_SYNC);
        runner.sdc = sdc;
        return runner;
    }

    private class MockSyncRepriceRunner implements HttpCalloutMock {
        String body = DTG_RESPONSE;
        Boolean isException = false;
        public String capturedRequestBody;

        public MockSyncRepriceRunner() {}

        public MockSyncRepriceRunner(String body) {
            this.body = body;
        }

        public MockSyncRepriceRunner(Boolean isException) {
            this.isException = isException;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().endsWith('discountTemplateGroup')) {
                res.setStatus(HttpHelper.RESPONSE_STATUS_COMPLETED);
                res.setStatusCode(200);
                res.setBody(body);
            } else if (req.getEndpoint().endsWith('priceChange') && isException) {
                throw new CalloutException(SWNSyncRepriceRunner.EXCEEDED_MAX_SIZE_LIMIT);
            } else if (req.getEndpoint().endsWith('priceChange')) {
                // Capture the request body for verification
                capturedRequestBody = req.getBody();

                res.setStatus(HttpHelper.RESPONSE_STATUS_COMPLETED);
                res.setStatusCode(200);
                res.setBody('{"status": "success"}');
            }
            return res;
        }
    }

    @TestSetup
    static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://example.com',
                NGBS_Settings__c.AccountManagerPath__c => '/api/account-manager/v1.0',
                NGBS_Settings__c.Login__c => 'testLogin',
                NGBS_Settings__c.Password__c => 'testPassword'
            })
            .create();
    }

    static void assertSyncRepriceStep(String message, SWNSyncRepriceRunner runner) {
        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed successfully');
        Assert.areEqual(1, runner.res.messages.size(), 'Should have 1 message');
        Assert.areEqual(message, runner.res.messages[0].messageDetails, 'Wrong success message');
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSyncRepriceSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockSyncRepriceRunner());

        SWNSyncRepriceRunner runner = generateTestData();

        Test.startTest();
            runner.run();
        Test.stopTest();

        assertSyncRepriceStep(SWNMessageHelper.SYNC_REPRICE_MSG, runner);
    }

    @isTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void testSyncRepriceIsSkipped() {
        Test.setMock(HttpCalloutMock.class, new MockSyncRepriceRunner(DTG_RESPONSE_SKIP));

        SWNSyncRepriceRunner runner = generateTestData();

        Test.startTest();
            runner.run();
        Test.stopTest();

        assertSyncRepriceStep(SWNMessageHelper.REPRICE_SKIPPED_MSG, runner);
    }

    @isTest
    static void testRepriceHandlesException() {
        Test.setMock(HttpCalloutMock.class, new MockSyncRepriceRunner(true));

        SWNSyncRepriceRunner runner = generateTestData();

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.areEqual(SWNMessageHelper.REPRICE_RESPONSE_EXCEEDS_HEAP_MSG, runner.res.messages[0].messageDetails, 'Wrong error message');
    }

    @isTest
    static void testSalesOrderIdInRequest() {
        // Setup
        MockSyncRepriceRunner mock = new MockSyncRepriceRunner();
        Test.setMock(HttpCalloutMock.class, mock);

        SWNSyncRepriceRunner runner = generateTestData();
        Id expectedOpportunityId = runner.sdc.qt.OpportunityId;

        // Act
        Test.startTest();
        runner.run();
        Test.stopTest();

        // Assert
        Assert.isNotNull(mock.capturedRequestBody, 'Request body should have been captured');

        // Verify salesOrderId in the serialized request
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(mock.capturedRequestBody);
        Assert.isTrue(requestMap.containsKey('salesOrderId'), 'Request should contain salesOrderId');
        Assert.areEqual(expectedOpportunityId, requestMap.get('salesOrderId'), 'salesOrderId in request should match OpportunityId');
    }
}