@IsTest
private class Test_SWNActionRunner {
    private static final String FIRST_STEP_NAME = 'FIRST_STEP_NAME';
    private static final String LAST_STEP_NAME = 'LAST_STEP_NAME';
    private static final String TEST_SCENARIO_NAME = 'TEST_SCENARIO_NAME';
    private static final String TEST_EXCEPTION_MSG = 'TEST_EXCEPTION_MSG';
    private static final String USER_LAST_NAME = 'USER_LAST_NAME';
    private static final String PACKAGE_NAME_NEW = 'PACKAGE_NAME_NEW';
    private static final String UNIQUE_RECORD_NAME = String.valueOf(Datetime.now().getTime());
    private static final String MESSAGE = 'message';
    private static final String DETAILS = 'details';
    private static final String CASE_REASON = 'caseReason';
    private static final String PACKAGE_ID = 'packageId';
    private static final String BILLING_ID = 'billingId';
    private static final String PRODUCT_ID = 'productId';
    private static final String RUN_EXCEPTION_MSG = 'This is a test exception message, that was raised by a runner.';

    private static final SObjectField STATUS_FIELD_FOR_STEP = ServiceInfo__c.ContractCancellationStepStatus__c;

    class TestException extends Exception {}

    class FreeServiceCreditMock implements HttpCalloutMock {
        private Boolean wasCalloutMade = false;

        public void resetMock() {
            wasCalloutMade = false;
        }

        public HTTPResponse respond(HTTPRequest req) {
            if (!req.getEndpoint().contains('/freeServiceCredit')) {
                HttpResponse res = new HttpResponse();
                res.setBody('{"status": "error"}');
                res.setStatusCode(400);
                return res;
            }

            wasCalloutMade = true;
            HttpResponse res = new HttpResponse();
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    class FinalizeStepTestData {
        public User testUser;
        public Account acc;
        public Quote qt;
        public ServiceInfo__c testSobject;
        public NGBSSyncables.ISyncable mockedSyncable;
        public List<String> stepNames;
        public SWNStep step;

        public FinalizeStepTestData(User testUser, Account testAcc, Quote testQt, ServiceInfo__c testSobject, NGBSSyncables.ISyncable mockedSyncable, SWNStep testStep, List<String> stepNames) {
            this.acc = testAcc;
            this.qt = testQt;
            this.testSobject = testSobject;
            this.mockedSyncable = mockedSyncable;
            this.step = testStep;
            this.stepNames = stepNames;
            this.testUser = testUser;
        }
    }

    class SyncTestData {
        FinalizeStepTestData finalizeStepTestData;

        public SyncTestData(FinalizeStepTestData finalizeStepTestData) {
            this.finalizeStepTestData = finalizeStepTestData;
        }
    }

    virtual class SWNActionRunnerMock extends SWNActionRunner {
        public Boolean isRunCalled = false;

        SWNActionRunnerMock() {
            super();
        }
        SWNActionRunnerMock(SWNDataCollector mockedSdc) {
            super();
            this.sdc = mockedSdc;
        }
        SWNActionRunnerMock(Id quoteId) {
            super(quoteId);
        }
        SWNActionRunnerMock(Id quoteId, String action) {
            super(quoteId, action);
        }

        protected virtual override void run() {
            isRunCalled = true;
        }
    }

    class FailingSWNActionRunnerMock extends SWNActionRunnerMock {
        private final Exception exceptionToRaise;
        public Boolean isRunCalled = false;

        FailingSWNActionRunnerMock(SWNDataCollector mockedSdc, Exception exceptionToRaise) {
            super();
            this.sdc = mockedSdc;
            this.exceptionToRaise = exceptionToRaise;
        }

        protected override void run() {
            isRunCalled = true;
            throw exceptionToRaise;
        }
    }

    private static String parseException(Exception ex) {
        return 'Exception caught: ' + ex + '::Stack Trace::' + ex.getStackTraceString();
    }

    private static User buildTestUser() {
        return (User) new SObjectBuilder(User.sObjectType)
            .setField(User.LastName, USER_LAST_NAME)
            .build()
            .getRecord();
    }
    private static SWNStep buildStep(String stepName) {
        return new SWNStep.SWNStepBuilder()
            .withName(stepName)
            .build();
    }
    private static SWNDataCollector buildDataCollectorWithQuote(Quote qt) {
        return buildDataCollectorWithQuote(qt, null);
    }
    private static SWNDataCollector buildDataCollectorWithQuote(Quote qt, String stepName) {
        BillingWrappers.BillingContract contract = new BillingWrappers.BillingContract();
        contract.startBillingCycleNumber = 1;

        SWNDataCollector sdc = new SWNDataCollector(qt.Id, stepName);
        sdc.packageId = PACKAGE_ID;
        sdc.billingId = BILLING_ID;
        sdc.billingContracts = new List<BillingWrappers.BillingContract> {contract};
        sdc.qt = qt;
        return sdc;
    }
    private static SWNDataCollector buildDataCollectorWithLBOQuoteAndSyncable() {
        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Enabled_LBO__c => true,
                Quote.PackageNameNew__c => PACKAGE_NAME_NEW
            })
            .build()
            .getRecord();
        SWNDataCollector sdc = buildDataCollectorWithQuote(qt);
        sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().build();
        return sdc;
    }

    private static Account createAccount() {
        return (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();
    }
    private static FinalizeStepTestData createTestDataForFinalizeStep() {
        return createTestDataForFinalizeStep(FIRST_STEP_NAME);
    }
    private static FinalizeStepTestData createTestDataForFinalizeStep(String currentStepName) {
        Triggers.switchOff();
        User testUser = buildTestUser();
        ServiceInfo__c testSobject = new ServiceInfo__c();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.CloseDate, Date.today())
            .create()
            .getRecord();
        Quote testQt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SOBjectField, Object> {
                Quote.Enabled_LBO__c => true,
                Quote.OpportunityId => opp.Id,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.PackageNameNew__c => PACKAGE_NAME_NEW,
                Quote.Package_Info__c => new SWNMockBuilders.PackageInfoBuilder()
                    .withProductId(PRODUCT_ID)
                    .buildAsJson()
            })
            .build()
            .getRecord();
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .build()
            .getRecord();
        insert new List<SObject> {testAcc, testSobject, testQt, testUser};  // inserting a test user in order to avoid "You have uncommitted work pending" error
        Triggers.switchOn();

        List<String> stepNames = new List<String> {FIRST_STEP_NAME, LAST_STEP_NAME};
        SWNStep testStep = buildStep(currentStepName);
        testStep.isStepCompletedSuccessfully = true;
        testStep.isNeedToLogTimeStamp = true;
        testStep.quoteFieldsToUpdate = new Map<String, Object> {Quote.Id.toString() => testQt.Id, Quote.Name.toString() => UNIQUE_RECORD_NAME};
        testStep.accountFieldsToUpdate = new Map<String, Object> {Account.Id.toString() => testAcc.Id, Account.Name.toString() => UNIQUE_RECORD_NAME};
        NGBSSyncables.ISyncable mockedSyncable = new SWNMockBuilders.NGBSSyncableBuilder()
            .withSObjectToUpdate(testSobject)
            .withNameToSObjectFieldMap(new Map<String, SObjectField> {testStep.name => STATUS_FIELD_FOR_STEP})
            .withSObjFieldsToUpdate(new Map<SObjectField, Object> {ServiceInfo__c.Name => UNIQUE_RECORD_NAME})
            .build();

        return new FinalizeStepTestData(testUser, testAcc, testQt, testSobject, mockedSyncable, testStep, stepNames);
    }
    private static SWNDataCollector buildDataCollectorForSync(Test_SWNActionRunner.FinalizeStepTestData testData) {
        SWNDataCollector sdc = buildDataCollectorWithQuote(testData.qt, FIRST_STEP_NAME);
        sdc.syncable = testData.mockedSyncable;
        sdc.currentScenario = new SWNMockBuilders.ScenarioBuilder(TEST_SCENARIO_NAME)
            .addSteps(testData.stepNames)
            .putSteps()
            .buildAndPut()
            .getScenario();
        sdc.currentStep = testData.step;
        sdc.currentScenarioKey = TEST_SCENARIO_NAME;
        return sdc;
    }

    private static Case selectCaseBySubject(String subject) {
        return (Case) new ListOptional(
            new CaseSelector()
                .newQueryFactory()
                .setFactoryName('selectCaseBySubject')
                .selectFields(new Set<SObjectField> {
                    Case.Subject,
                    Case.RecordTypeId,
                    Case.OwnerId,
                    Case.Status,
                    Case.Priority,
                    Case.Origin,
                    Case.Description
                })
                .addCondition('Subject = :bind0')
                .setQueryBindings(new List<Object> {subject})
                .executeQuery()
        ).getFirst();
    }
    private static ServiceInfo__c selectServiceInfo(Id recordId) {
        return (ServiceInfo__c) new ServiceInfoSelector()
            .newQueryFactory()
            .setFactoryName('SelectById')
            .selectFields(new Set<SObjectField> {
                ServiceInfo__c.Name,
                STATUS_FIELD_FOR_STEP
            })
            .setCondition('Id = :bind0')
            .setQueryBindings(recordId)
            .executeQuery()
            .get(0);
    }
    private static Quote selectQuote(Id quoteId) {
        return (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object> {quoteId})
            .executeQuery()
            .get(0);
    }
    private static Account selectAccount(Id accId) {
        return (Account) new AccountSelector()
            .selectAccountById(accId)
            .executeQuery()
            .get(0);
    }

    private static void assertCreatedDealDeskCase(String expectedSubject, String expectedCaseReason) {
        Case dealDeskCase = selectCaseBySubject(expectedSubject);
        Assert.isNotNull(dealDeskCase, 'Case should be created with a correct subject');
        Assert.areEqual(expectedSubject, dealDeskCase.Subject, 'Case subject should be correct');
        Assert.areEqual(CaseHelper.RT_ID_DEALDESK_CASE, dealDeskCase.RecordTypeId, 'A Case with a wrong record type was created');
        Assert.areEqual(DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId, dealDeskCase.OwnerId, 'Case owner should be correct');
        Assert.areEqual(CaseHelper.CASE_STATUS_NEW, dealDeskCase.Status, 'Case status should be correct');
        Assert.areEqual(CaseHelper.CASE_PRIORITY_MEDIUM, dealDeskCase.Priority, 'Case priority should be correct');
        Assert.areEqual(CaseHelper.CASE_ORIGIN_AUTO_EMAIL, dealDeskCase.Origin, 'A Case with a wrong origin was created');
        Assert.isTrue(dealDeskCase.Description.contains(expectedCaseReason), 'Case description must include correct case reason');
    }
    private static void assertRunnerResponse(Response runnerResp, String expectedMessage, String expectedDetails) {
        Assert.isNotNull(runnerResp, 'Response should be initialized');
        Assert.isTrue(runnerResp.isError(), 'Response should be marked as error');
        Assert.isFalse(runnerResp.messages.isEmpty(), 'Response should have at least one message');
        Assert.areEqual(expectedMessage, runnerResp.messages[0].message, 'Response message should be correct');
        Assert.areEqual(expectedDetails, runnerResp.messages[0].messageDetails, 'Response message details should be correct');
    }
    private static void assertHandleException(SWNActionRunnerMock runner, String expectedMessage, String expectedDetails, String expectedCaseReason) {
        String expectedCaseSubject = DealDeskCaseGenerator.getSubjectPrefix(runner.sdc.qt) + DealDeskCaseGenerator.CASE_SUBJECT_UPGRADE_DOWNGRADE_PLANCHANGE_EXCEPTION;
        assertRunnerResponse(runner.res, expectedMessage, expectedDetails);
        assertCreatedDealDeskCase(expectedCaseSubject, expectedCaseReason);
        Assert.isFalse(runner.sdc.syncable.isDownsellStepCompleted(), 'Downsell step should not be marked as completed, when handling an exception');
    }
    private static void assertHandleMessages(SWNActionRunnerMock runner, String expectedMessage, String expectedDetails, String expectedCaseReason) {
        assertHandleException(runner, expectedMessage, expectedDetails, expectedCaseReason);
        List<SObject> logs = new PlatformLogSelector()
            .selectLogsByLikeSource(SWNActionRunner.SOURCE + ': %')
            .executeQuery();
        Assert.areEqual(1, logs.size(), 'One log with correct source should be created');
    }
    private static void assertFinalizeStep(FinalizeStepTestData testData) {
        Account updatedAcc = selectAccount(testData.acc.Id);
        Quote updatedQt = selectQuote(testData.qt.Id);
        ServiceInfo__c updatedSobject = selectServiceInfo(testData.testSobject.Id);

        Assert.areEqual(UNIQUE_RECORD_NAME, updatedAcc.Name, 'Account field must be updated, if a given step requires it.');
        Assert.areEqual(UNIQUE_RECORD_NAME, updatedQt.Name, 'Quote field must be updated, if a given step requires it.');
        Assert.areEqual(UNIQUE_RECORD_NAME, updatedSobject.Name, 'SObject field must be updated, if a given step requires it.');
        Assert.isTrue((Boolean) updatedSobject.get(STATUS_FIELD_FOR_STEP), 'A corresponding status field must be set as true when finalizing a step.');
        Assert.isTrue(String.isNotBlank(testData.mockedSyncable.getSyncInfoField()), 'SyncInfo field must be updated, if a given step requires it.');
    }
    private static void assertFinalizeStepWasNotCalled(FinalizeStepTestData testData) {
        Account updatedAcc = selectAccount(testData.acc.Id);
        Quote updatedQt = selectQuote(testData.qt.Id);
        ServiceInfo__c updatedSobject = selectServiceInfo(testData.testSobject.Id);

        Assert.areNotEqual(UNIQUE_RECORD_NAME, updatedAcc.Name, 'Account must not be updated, if finalize step is skipped.');
        Assert.areNotEqual(UNIQUE_RECORD_NAME, updatedQt.Name, 'Quote must not be updated, if finalize step is skipped.');
        Assert.areNotEqual(UNIQUE_RECORD_NAME, updatedSobject.Name, 'SObject field must not be updated, if finalize step is skipped.');
        Assert.isFalse((Boolean) updatedSobject.get(STATUS_FIELD_FOR_STEP), 'A corresponding status field must not be set as true, if finalize step is skipped.');
        Assert.isTrue(String.isBlank(testData.mockedSyncable.getSyncInfoField()), 'SyncInfo field must not be updated, if finalize step is skipped.');
    }
    private static void assertUpdateSyncStepExecutorInfo(SWNMockBuilders.SyncableMock mockedSyncable, String expectedStepName) {
        String expectedExecutorInfo = JSON.serialize(
            new SWNActionRunner.SyncStepExecutorInfo(
                USER_LAST_NAME,
                expectedStepName,
                SWNHelper.SYNC_MANUALLY
            )
        );
        Assert.areEqual(expectedExecutorInfo, mockedSyncable.getNGBSSyncExecutorInfo(), 'Sync step executor info was created incorrectly');
        Assert.isTrue(mockedSyncable.isUpdateSobjectCalled, 'Sync step executor info should be updated');
    }

    @TestSetup
    static void setup() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi/',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();
    }

    @isTest
    static void testConstructor() {
        Id fakeQuoteId = (Id) ValueProviderBuilder.provideDummyId(Quote.sObjectType).getValue();
        String fakeAction = 'fakeAction';

        Test.startTest();
            SWNActionRunnerMock runnerWithQuoteId = new SWNActionRunnerMock(fakeQuoteId);
            SWNActionRunnerMock runnerWithQuoteIdAndAction = new SWNActionRunnerMock(fakeQuoteId, fakeAction);
        Test.stopTest();

        for (SWNActionRunner runner : new SWNActionRunner[] {runnerWithQuoteId, runnerWithQuoteIdAndAction}) {
            Assert.isNotNull(runner, 'Runner should be created');
            Assert.isNotNull(runner.sdc, 'Runner must have initialized SWNDataCollector');
            Assert.isFalse(runner.isSkipFinalize, 'Runner should not skip finalize step by default');
            Assert.isNotNull(runner.res, 'Runner must initialize a Response');
        }
    }

    @isTest
    static void testSyncWithNonLastStep() {
        FinalizeStepTestData testData = createTestDataForFinalizeStep();
        Triggers.switchOff();
        new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setField(DealDeskCaseDescription__c.Account__c, testData.acc.Id)
            .create();
        Triggers.switchOn();
        SWNDataCollector sdc = buildDataCollectorForSync(testData);
        sdc.opp = new Opportunity(AccountId = testData.acc.Id);
        SWNActionRunnerMock runner = new SWNActionRunnerMock(sdc);

        FreeServiceCreditMock mock = new FreeServiceCreditMock();
        Response result;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            System.runAs(testData.testUser) {
                result = runner.sync();
            }
        Test.stopTest();

        Assert.isNotNull(result, 'A Response object should be returned');
        Assert.isTrue(result.isSuccess(), 'Response should be marked as success in normal circumstances');
        Assert.isTrue(mock.wasCalloutMade, 'Runner should update free service credit');
        Assert.isTrue(runner.isRunCalled, 'Runner should call run() method in sync()');
        assertFinalizeStep(testData);
        Assert.isFalse(runner.wasCaseQueueableEnqueued, 'CaseQueueable should not be enqueued for a non-last step');
        assertUpdateSyncStepExecutorInfo((SWNMockBuilders.SyncableMock) testData.mockedSyncable, FIRST_STEP_NAME);
    }

    @isTest
    static void testSyncWithLastStep() {
        FinalizeStepTestData testData = createTestDataForFinalizeStep(LAST_STEP_NAME);
        Triggers.switchOff();
        new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setField(DealDeskCaseDescription__c.Account__c, testData.acc.Id)
            .create();
        Triggers.switchOn();
        SWNDataCollector sdc = buildDataCollectorWithQuote(testData.qt, LAST_STEP_NAME);
        sdc.syncable = testData.mockedSyncable;
        sdc.currentScenario = new SWNMockBuilders.ScenarioBuilder(TEST_SCENARIO_NAME)
            .addSteps(testData.stepNames)
            .putSteps()
            .buildAndPut()
            .getScenario();
        sdc.currentStep = testData.step;
        sdc.currentScenarioKey = TEST_SCENARIO_NAME;
        sdc.opp = new Opportunity(AccountId = testData.acc.Id);
        SWNActionRunnerMock runner = new SWNActionRunnerMock(sdc);

        FreeServiceCreditMock mock = new FreeServiceCreditMock();
        Response result;
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);
            System.runAs(testData.testUser) {
                result = runner.sync();
            }
        Test.stopTest();

        Assert.isNotNull(result, 'A Response object should be returned');
        Assert.isTrue(result.isSuccess(), 'Response should be marked as success in normal circumstances');
        Assert.isTrue(mock.wasCalloutMade, 'Runner should update free service credit');
        Assert.isTrue(runner.isRunCalled, 'Runner should call run() method in sync()');
        assertFinalizeStep(testData);
        Assert.isTrue(runner.wasCaseQueueableEnqueued, 'CaseQueueable should be enqueued for the last step');
        assertUpdateSyncStepExecutorInfo((SWNMockBuilders.SyncableMock) testData.mockedSyncable, LAST_STEP_NAME);
    }

    @isTest
    static void testSyncWhenFinalizeStepShouldBeSkipped() {
        FinalizeStepTestData testData = createTestDataForFinalizeStep();
        SWNDataCollector sdc = buildDataCollectorForSync(testData);
        SWNActionRunnerMock runner = new SWNActionRunnerMock(sdc);
        runner.isSkipFinalize = true;

        FreeServiceCreditMock mock = new FreeServiceCreditMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Response result;
        Test.startTest();
            System.runAs(testData.testUser) {
                result = runner.sync();
            }
        Test.stopTest();

        Assert.isNotNull(result, 'A Response object should be returned');
        Assert.isTrue(result.isSuccess(), 'Response should be marked as success in normal circumstances, even if finalize step is skipped');
        Assert.isTrue(mock.wasCalloutMade, 'Runner should update free service credit regardless of finalize step is skipped or not');
        Assert.isTrue(runner.isRunCalled, 'Runner should call run() method in sync() regardless of finalize step is skipped or not');
        assertFinalizeStepWasNotCalled(testData);
        Assert.isFalse(runner.wasCaseQueueableEnqueued, 'CaseQueueable should not be enqueued when finalize step is skipped');
        assertUpdateSyncStepExecutorInfo((SWNMockBuilders.SyncableMock) testData.mockedSyncable, FIRST_STEP_NAME);
    }

    @isTest
    static void testSyncWhenExceptionOccurs() {
        FinalizeStepTestData testData = createTestDataForFinalizeStep();
        TestException exceptionToRaise = new TestException(RUN_EXCEPTION_MSG);
        SWNDataCollector sdc = buildDataCollectorForSync(testData);
        FailingSWNActionRunnerMock runner = new FailingSWNActionRunnerMock(sdc, exceptionToRaise);

        FreeServiceCreditMock mock = new FreeServiceCreditMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Response result;
        Test.startTest();
            System.runAs(testData.testUser) {
                result = runner.sync();
            }
        Test.stopTest();

        Assert.isNotNull(result, 'A Response object should be returned, regardless of an exception');
        assertHandleMessages(runner, RUN_EXCEPTION_MSG, exceptionToRaise.getStackTraceString(), CaseHelper.CASE_REASON_EXCEPTION);
        assertFinalizeStepWasNotCalled(testData);
        Assert.isFalse(runner.wasCaseQueueableEnqueued, 'CaseQueueable should not be enqueued when an exception has occurred');
        assertUpdateSyncStepExecutorInfo((SWNMockBuilders.SyncableMock) testData.mockedSyncable, FIRST_STEP_NAME);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testHandleException() {
        Quote testQt = new Quote(PackageNameNew__c = PACKAGE_NAME_NEW);
        SWNDataCollector sdc = buildDataCollectorWithQuote(testQt);
        sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().build();
        SWNActionRunnerMock runner = new SWNActionRunnerMock(sdc);

        Test.startTest();
            runner.handleException(MESSAGE, DETAILS, CASE_REASON, true);
        Test.stopTest();

        assertHandleException(runner, MESSAGE, DETAILS, CASE_REASON);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testOverloadedHandleException() {
        Quote testQt = new Quote(PackageNameNew__c = PACKAGE_NAME_NEW);
        SWNDataCollector sdc = buildDataCollectorWithQuote(testQt);
        sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().build();
        SWNActionRunnerMock runner = new SWNActionRunnerMock(sdc);

        Test.startTest();
            runner.handleException(MESSAGE, DETAILS, true);
        Test.stopTest();

        assertHandleException(runner, MESSAGE, DETAILS, MESSAGE);
    }

    @isTest
    static void testUpdateFreeServiceCredit() {
        Quote qtThatNeedsFreeServiceCredit = new Quote();
        qtThatNeedsFreeServiceCredit.Upsell_Status__c = QuoteHelper.STATUS_UPSELL;
        qtThatNeedsFreeServiceCredit.Package_Info__c = new SWNMockBuilders.PackageInfoBuilder()
            .withProductId(PRODUCT_ID)
            .buildAsJson();
        Quote qtThatDoesNotNeedFreeServiceCredit = new Quote();

        SWNActionRunnerMock runner = new SWNActionRunnerMock(buildDataCollectorWithQuote(qtThatNeedsFreeServiceCredit));

        FreeServiceCreditMock mock = new FreeServiceCreditMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
            runner.updateFreeServiceCredit();
            Boolean expectedCalloutMade = mock.wasCalloutMade;

            mock.resetMock();
            runner.sdc.qt = qtThatDoesNotNeedFreeServiceCredit;
            runner.updateFreeServiceCredit();
            Boolean unexpectedCalloutMade = mock.wasCalloutMade;
        Test.stopTest();

        Assert.isTrue(expectedCalloutMade, 'Callout should be made');
        Assert.isFalse(unexpectedCalloutMade, 'Should not update free service credit if Quote doesn\'t have ');
    }

    @isTest
    static void testExecuteCaseQueueable() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();
        new SObjectBuilder(DealDeskCaseDescription__c.SObjectType)
            .setField(DealDeskCaseDescription__c.Account__c, testAcc.Id)
            .create();
        Triggers.switchOn();

        Quote nonLBOQuote = new Quote();
        Quote lboQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Enabled_LBO__c, true)
            .build()
            .getRecord();
        SWNDataCollector sdcWithLBOQuote = buildDataCollectorWithQuote(lboQuote);
        sdcWithLBOQuote.opp = new Opportunity();
        sdcWithLBOQuote.currentScenario = new SWNMockBuilders.ScenarioBuilder(TEST_SCENARIO_NAME)
            .addSteps(new List<String> {FIRST_STEP_NAME, LAST_STEP_NAME})
            .putSteps()
            .build()
            .getScenario();
        sdcWithLBOQuote.currentStep = buildStep(FIRST_STEP_NAME);

        SWNActionRunnerMock nonLBORunner = new SWNActionRunnerMock(buildDataCollectorWithQuote(nonLBOQuote));
        SWNActionRunnerMock lboRunnerNotOnLastStep = new SWNActionRunnerMock(sdcWithLBOQuote);
        SWNActionRunnerMock lboRunnerOnLastStep = new SWNActionRunnerMock(sdcWithLBOQuote);

        Test.startTest();
            nonLBORunner.executeCaseQueueable();
            lboRunnerNotOnLastStep.executeCaseQueueable();

            sdcWithLBOQuote.currentStep = buildStep(LAST_STEP_NAME);
            lboRunnerOnLastStep.executeCaseQueueable();
            Boolean whenOnKastStepWithNoExistingDescriptions = lboRunnerOnLastStep.wasCaseQueueableEnqueued;

            sdcWithLBOQuote.opp.AccountId = testAcc.Id;
            lboRunnerOnLastStep.executeCaseQueueable();
        Test.stopTest();

        Assert.isFalse(nonLBORunner.wasCaseQueueableEnqueued, 'Case should not be enqueued if a given Quote is not an LBO Quote');
        Assert.isFalse(lboRunnerNotOnLastStep.wasCaseQueueableEnqueued, 'Case should not be enqueued if a given Quote is not on the last step');
        Assert.isFalse(whenOnKastStepWithNoExistingDescriptions, 'Case should not be enqueued if there are no existing Deal Desk Case Descriptions');
        Assert.isTrue(lboRunnerOnLastStep.wasCaseQueueableEnqueued, 'CaseQueueable should be enqueued if all conditions are met');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testHandleMessagesWhenTransactionLimit() {
        Exception transactionLimitException = new TestException(SWNActionRunner.TRANSACTION_LIMIT_EXCEEDED + ' ' + SWNActionRunner.TYPE_AMOUNT);

        SWNActionRunnerMock runnerWithTransactionLimit = new SWNActionRunnerMock(buildDataCollectorWithLBOQuoteAndSyncable());
        Test.startTest();
            runnerWithTransactionLimit.handleMessages(transactionLimitException);
        Test.stopTest();

        assertHandleMessages(runnerWithTransactionLimit, SWNActionRunner.ERROR_MSG, CaseHelper.CASE_REASON_SPENDING_LIMIT_EXCEPTION, CaseHelper.CASE_REASON_SPENDING_LIMIT_EXCEPTION);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testHandleMessages() {
        Exception testEx = new TestException(TEST_EXCEPTION_MSG);
        SWNActionRunnerMock runner = new SWNActionRunnerMock(buildDataCollectorWithLBOQuoteAndSyncable());

        Test.startTest();
            runner.handleMessages(testEx);
        Test.stopTest();

        assertHandleMessages(runner, TEST_EXCEPTION_MSG, testEx.getStackTraceString(), CaseHelper.CASE_REASON_EXCEPTION);
    }

    @isTest
    static void testFinalizeStepWhenStepIsNotCompleted() {
        SWNStep testStep = buildStep(FIRST_STEP_NAME);
        testStep.isStepCompletedSuccessfully = false;
        NGBSSyncables.ISyncable mockedSyncable = new SWNMockBuilders.NGBSSyncableBuilder().build();

        SWNActionRunnerMock runner = new SWNActionRunnerMock();

        Test.startTest();
            try {
                runner.finalizeStep(testStep, TEST_SCENARIO_NAME, mockedSyncable, new List<String>());
            } catch (Exception ex) {
                Assert.fail('When a step is not completed, should return from the function immediately. ' + parseException(ex));
            }
        Test.stopTest();
    }

    @isTest
    static void testFinalizeStepWhenNothingToUpdate() {
        NGBSSyncables.ISyncable mockedSyncable = new SWNMockBuilders.NGBSSyncableBuilder().build();
        SWNStep testStep = buildStep(FIRST_STEP_NAME);
        testStep.isStepCompletedSuccessfully = true;
        testStep.isNeedToLogTimeStamp = false;

        SWNActionRunnerMock runner = new SWNActionRunnerMock();

        Test.startTest();
            try {
                runner.finalizeStep(testStep, TEST_SCENARIO_NAME, mockedSyncable, new List<String>());
            } catch (Exception ex) {
                Assert.fail('When there is nothing to update, should return from the function with no exceptions. ' + parseException(ex));
            }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testFinalizeStep() {
        FinalizeStepTestData testData = createTestDataForFinalizeStep();
        SWNActionRunnerMock runner = new SWNActionRunnerMock();

        Test.startTest();
            runner.finalizeStep(testData.step, TEST_SCENARIO_NAME, testData.mockedSyncable, testData.stepNames);
        Test.stopTest();

        assertFinalizeStep(testData);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdateSyncStepExecutorInfo() {
        SWNMockBuilders.SyncableMock mockedSyncable = (SWNMockBuilders.SyncableMock) new SWNMockBuilders.NGBSSyncableBuilder().build();
        SWNActionRunnerMock runner = new SWNActionRunnerMock();
        User testUser = buildTestUser();

        Test.startTest();
            System.runAs(testUser) {
                runner.updateSyncStepExecutorInfo(mockedSyncable, FIRST_STEP_NAME);
            }
        Test.stopTest();

        assertUpdateSyncStepExecutorInfo(mockedSyncable, FIRST_STEP_NAME);
    }

    @isTest
    static void testUpdateSyncStepExecutorInfoWhenDMLException() {
        NGBSSyncables.ISyncable mockedSyncable = new SWNMockBuilders.NGBSSyncableBuilder(new SWNMockBuilders.FailingSyncableMock()).build();
        SWNActionRunnerMock runner = new SWNActionRunnerMock();
        User testUser = buildTestUser();

        Test.startTest();
            try {
                System.runAs(testUser) {
                    runner.updateSyncStepExecutorInfo(mockedSyncable, FIRST_STEP_NAME);
                }
            } catch (Exception ex) {
                Assert.fail('If any error happens in updateSyncStepExecutorInfo, the sync itself should not fail. E.g. no exception should be raised. ' + parseException(ex));
            }
        Test.stopTest();
    }
}