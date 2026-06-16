@IsTest
private class Test_BatchJob_PopulateSyncInfoMPUB {
    private static final String OVERRIDE_QUERY_ASSERT_MSG = 'The overrideQuery property should be set to null when override query is not provided';
    private static final String STEP_NAMES_WERE_NOT_UPDATED_ASSERT_MSG = 'The "stepNames" parameter in SyncInfo__c field was saved incorrectly for ';

    private static final String EXPECTED_MPUB_QUERY = 'SELECT Id, Quote__r.Account.Billing_ID__c, Quote__r.Account.Offer_Type__c, Quote__r.Account.RC_User_ID__c, Quote__r.Enabled_LBO__c, Quote__r.IsMultiProductTechnicalQuote__c, Quote__r.Opportunity.Type, Quote__r.PackageNameOld__c, SyncInfo__c FROM ServiceInfo__c WHERE Quote__r.Opportunity.IsClosed = true AND Quote__r.Opportunity.StageName = \'7. Closed Won\' AND Quote__r.Opportunity.CloseDate = LAST_N_DAYS:120';
    private static final String EXPECTED_MPL_QUERY = 'SELECT Id, SyncInfo__c FROM Opportunity WHERE IsClosed = true AND StageName = \'7. Closed Won\'';
    private static final String EXPECTED_OVERRIDDEN_QUERY = 'SELECT Id, SyncInfo__c FROM ServiceInfo__c';

    private static final String STEP_NAME_1 = 'STEP_NAME_1';
    private static final String STEP_NAME_2 = 'STEP_NAME_2';
    private static final String STEP_NAME_3 = 'STEP_NAME_3';
    private static final String SCENARIO_NAME = 'SCENARIO_NAME';
    private static final String PACKAGE_NAME_OLD = 'Old Package';

    private static SWNSyncInfo getSyncInfo(ServiceInfo__c serviceInfo) {
        return (SWNSyncInfo) JSON.deserialize(serviceInfo.SyncInfo__c, SWNSyncInfo.class);
    }
    private static List<String> getStepNames(ServiceInfo__c serviceInfo) {
        return getSyncInfo(serviceInfo).stepNames;
    }
    private static Quote createQuote() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => Date.today()
            })
            .create()
            .getRecord();
        Quote testQt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.PackageNameOld__c => PACKAGE_NAME_OLD,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Enabled_LBO__c => true,
                Quote.OpportunityId => opp.Id
            })
            .create()
            .getRecord();
        return testQt;
    }
    private static Boolean hasReprice(SWNScenarioHelper.Scenario sc) {
        return sc.stepNames.contains(SWNStep.REPRICE_SYNC);
    }
    private static void assertQueryLocator(Database.QueryLocator ql, Boolean isMPUB) {
        Assert.isNotNull(ql, 'A QueryLocator must be returned');

        String expectedQuery;
        if (isMPUB == null) {
            expectedQuery = EXPECTED_OVERRIDDEN_QUERY;
        } else if (isMPUB) {
            expectedQuery = EXPECTED_MPUB_QUERY;
        } else {
            expectedQuery = EXPECTED_MPL_QUERY;
        }
        String qry = ql.getQuery();
        Assert.areEqual(expectedQuery, qry, 'The query in the QueryLocator does not match the expected query');

        if (isMPUB == null) {
            return;
        }
        SObjectType expectedSObjectType = isMPUB ? ServiceInfo__c.SObjectType : Opportunity.SObjectType;
        List<SObject> queriedRecords = Database.query(qry);
        Assert.areEqual(
            expectedSObjectType,
            queriedRecords.getSObjectType(),
            'The queried records are not of the expected SObjectType for ' + (isMPUB ? 'MPUB' : 'MPL')
        );
    }

    @isTest
    static void testConstructor() {
        Test.startTest();
            BatchJob_PopulateSyncInfoMPUB mpubBatch = new BatchJob_PopulateSyncInfoMPUB();
            BatchJob_PopulateSyncInfoMPUB overriddenBatch = new BatchJob_PopulateSyncInfoMPUB(EXPECTED_OVERRIDDEN_QUERY);
        Test.stopTest();

        Assert.isNull(mpubBatch.overrideQuery, OVERRIDE_QUERY_ASSERT_MSG);
        Assert.areEqual(EXPECTED_OVERRIDDEN_QUERY, overriddenBatch.overrideQuery, 'The overrideQuery property should be set to the provided query');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testBatchStartMethod() {
        Test.startTest();
            Database.QueryLocator mpubQl = new BatchJob_PopulateSyncInfoMPUB().start(null);
            Database.QueryLocator overriddenQl = new BatchJob_PopulateSyncInfoMPUB(EXPECTED_OVERRIDDEN_QUERY).start(null);
        Test.stopTest();

        assertQueryLocator(mpubQl, true);
        assertQueryLocator(overriddenQl, null);
    }

    @isTest
    static void testExecuteMethod() {
        List<String> stepNames = new List<String> { STEP_NAME_1, SWNStep.REPRICE_SYNC, STEP_NAME_2, SWNStep.ORDER, SWNStep.DISCOUNT_SYNC, STEP_NAME_3, SWNStep.CONTRACT_SYNC };
        new SWNMockBuilders.ScenarioBuilder(SCENARIO_NAME)
            .addSteps(stepNames)
            .putSteps()
            .buildAndPut();
        String syncInfoWithStepNames = new SWNMockBuilders.SyncInfoBuilder(stepNames, SCENARIO_NAME)
            .build()
            .getAsJson();
        SWNSyncInfo syncInfoWithoutStepNamesButAllStepsAreCompleted = new SWNMockBuilders.SyncInfoBuilder(stepNames, SCENARIO_NAME)
            .build()
            .getSyncInfo();
        syncInfoWithoutStepNamesButAllStepsAreCompleted.stepNames = null;
        SWNSyncInfo syncInfoWithoutStepNames = new SWNMockBuilders.SyncInfoBuilder(new List<String>(), SCENARIO_NAME)
            .build()
            .getSyncInfo();
        syncInfoWithoutStepNames.stepNames = null;
        List<String> syncInfosToProvide = new List<String> {
            null,
            syncInfoWithStepNames,
            JSON.serialize(syncInfoWithoutStepNamesButAllStepsAreCompleted).remove('"stepNames":null,'),
            JSON.serialize(syncInfoWithoutStepNames).remove('"stepNames":null,')
        };
        List<String> serviceInfoNames = new List<String> {
            'null',
            'syncInfoWithStepNames',
            'syncInfoWithoutStepNamesButAllStepsAreCompleted',
            'syncInfoWithoutStepNames'
        };

        Triggers.switchOff();
        Quote testQt = createQuote();
        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.SyncInfo__c => ValueProviderBuilder.provideList(syncInfosToProvide),
                ServiceInfo__c.Name => ValueProviderBuilder.provideList(serviceInfoNames),
                ServiceInfo__c.Quote__c => testQt.Id
            })
            .quantity(syncInfosToProvide.size())
            .create()
            .getRecords();
        Triggers.switchOn();
        ServiceInfo__c serviceInfoWithNoSyncInfo = serviceInfos[0];
        ServiceInfo__c serviceInfoWithStepNames = serviceInfos[1];
        ServiceInfo__c serviceInfoWithoutStepNamesButAllStepsAreCompleted = serviceInfos[2];
        ServiceInfo__c serviceInfoWithoutStepNames = serviceInfos[3];
        serviceInfoWithoutStepNamesButAllStepsAreCompleted.Quote__r = testQt;
        serviceInfoWithoutStepNames.Quote__r = testQt;

        BatchJob_PopulateSyncInfoMPUB batch = new BatchJob_PopulateSyncInfoMPUB();
        Test.startTest();
            batch.execute(null, serviceInfos);
        Test.stopTest();

        Map<Id, ServiceInfo__c> resultedServiceInfos = new Map<Id, ServiceInfo__c>((List<serviceInfo__c>) new ServiceInfoSelector()
            .newQueryFactory()
            .setFactoryName('resultedServiceInfos')
            .selectFields(new Set<SObjectField> {
                ServiceInfo__c.Id,
                ServiceInfo__c.Name,
                ServiceInfo__c.SyncInfo__c
            })
            .setCondition('Id IN :bind0')
            .setQueryBindings(new Map<Id, ServiceInfo__c>(serviceInfos).keySet())
            .executeQuery());
        Assert.isNull(
            resultedServiceInfos.get(serviceInfoWithNoSyncInfo.Id).SyncInfo__c,
            'The SyncInfo__c field should be null if the SyncInfo was null in the original record'
        );
        Assert.areEqual(
            serviceInfoWithStepNames.SyncInfo__c,
            resultedServiceInfos.get(serviceInfoWithStepNames.Id).SyncInfo__c,
            'The SyncInfo__c field should be the same as the SyncInfo in the original record, if it already had step names in it'
        );
        Assert.areEqual(
            new List<String> {SWNStep.REPRICE_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC},
            getStepNames(resultedServiceInfos.get(serviceInfoWithoutStepNames.Id)),
            STEP_NAMES_WERE_NOT_UPDATED_ASSERT_MSG + serviceInfoWithoutStepNames.Name
        );
        Assert.areEqual(
            stepNames,
            getStepNames(resultedServiceInfos.get(serviceInfoWithoutStepNamesButAllStepsAreCompleted.Id)),
            'The "stepNames" parameter in SyncInfo__c field should contain all completed steps in the preserved order'
        );
    }

    @isTest
    static void testFilterOutReprice() {
        List<String> stepNamesWithNoReprice = new List<String> { STEP_NAME_1, STEP_NAME_2, STEP_NAME_3 };
        List<String> stepNamesWithRepriceAsLast = new List<String> { STEP_NAME_1, STEP_NAME_2, STEP_NAME_3, SWNStep.REPRICE_SYNC };
        List<String> stepNamesWithReprice = new List<String> { STEP_NAME_1, STEP_NAME_2, SWNStep.REPRICE_SYNC, STEP_NAME_3 };
        List<String> stepNamesWithRepriceAsFirstStep = new List<String> { SWNStep.REPRICE_SYNC, STEP_NAME_1, STEP_NAME_2, STEP_NAME_3 };

        SWNScenarioHelper.Scenario scWithRepriceAsLastStep = new SWNMockBuilders.ScenarioBuilder('Scenario with reprice as last step')
            .addSteps(stepNamesWithRepriceAsLast)
            .putSteps()
            .build()
            .getScenario();
        SWNScenarioHelper.Scenario scWithReprice = new SWNMockBuilders.ScenarioBuilder('scWithReprice')
            .addSteps(stepNamesWithReprice)
            .putSteps()
            .build()
            .getScenario();
        SWNScenarioHelper.Scenario scWithRepriceAsFirstStep = new SWNMockBuilders.ScenarioBuilder('scWithRepriceAsFirstStep')
            .addSteps(stepNamesWithRepriceAsFirstStep)
            .putSteps()
            .build()
            .getScenario();
        SWNScenarioHelper.Scenario scWithoutReprice = new SWNMockBuilders.ScenarioBuilder('stepNamesWithNoReprice')
            .addSteps(stepNamesWithNoReprice)
            .putSteps()
            .build()
            .getScenario();

        SWNSyncInfo syncInfoWithRepriceCompleted = new SWNMockBuilders.SyncInfoBuilder(stepNamesWithRepriceAsLast, 'Scenario with reprice as first step')
            .build()
            .getSyncInfo();
        SWNSyncInfo syncInfoWithNoReprice = new SWNMockBuilders.SyncInfoBuilder(stepNamesWithNoReprice, 'Scenario with no reprice step')
            .build()
            .getSyncInfo();
        SWNSyncInfo syncInfoWithNoSteps = new SWNMockBuilders.SyncInfoBuilder(new List<String>(), 'Scenario with no steps completed')
            .build()
            .getSyncInfo();

        BatchJob_PopulateSyncInfoMPUB batch = new BatchJob_PopulateSyncInfoMPUB();
        Test.startTest();
            batch.filterOutReprice(scWithRepriceAsLastStep, syncInfoWithRepriceCompleted);
            Assert.isTrue(hasReprice(scWithRepriceAsLastStep), 'The reprice step should not be removed from the scenario if it was completed');
            batch.filterOutReprice(scWithRepriceAsFirstStep, syncInfoWithNoSteps);
            Assert.isTrue(hasReprice(scWithRepriceAsFirstStep), 'The reprice step should not be removed from the scenario if no step was completed');
            batch.filterOutReprice(scWithRepriceAsLastStep, syncInfoWithNoReprice);
            Assert.isTrue(hasReprice(scWithRepriceAsLastStep), 'The reprice step should not be removed from the scenario if it was not completed and it is on the last position');

            batch.filterOutReprice(scWithReprice, syncInfoWithRepriceCompleted);
            Assert.isTrue(hasReprice(scWithReprice), 'The reprice step should not be removed from the scenario if it was completed');
            batch.filterOutReprice(scWithRepriceAsFirstStep, syncInfoWithNoSteps);
            Assert.isTrue(hasReprice(scWithRepriceAsFirstStep), 'The reprice step should not be removed from the scenario if no step was completed');
            batch.filterOutReprice(scWithReprice, syncInfoWithNoReprice);
            Assert.isFalse(hasReprice(scWithReprice), 'The reprice step should be removed from the scenario if it was not completed, and a step after it was completed');

            batch.filterOutReprice(scWithRepriceAsFirstStep, syncInfoWithRepriceCompleted);
            Assert.isTrue(hasReprice(scWithRepriceAsFirstStep), 'The reprice step should not be removed from the scenario if it was completed');
            batch.filterOutReprice(scWithRepriceAsFirstStep, syncInfoWithNoSteps);
            Assert.isTrue(hasReprice(scWithRepriceAsFirstStep), 'The reprice step should not be removed from the scenario if no step was completed');
            batch.filterOutReprice(scWithRepriceAsFirstStep, syncInfoWithNoReprice);
            Assert.isFalse(hasReprice(scWithRepriceAsFirstStep), 'The reprice step should be removed from the scenario if it was not completed, and a step after it was completed');

            batch.filterOutReprice(scWithoutReprice, syncInfoWithNoReprice);
            Assert.isFalse(hasReprice(scWithoutReprice), 'The reprice step should not be present the scenario if the scenario does not have it');
        Test.stopTest();
    }

    @isTest
    static void testFilterOutSteps() {
        final Integer EXPECTED_STEPS_AMOUNT = 3;

        List<String> stepNames = new List<String> { STEP_NAME_1, SWNStep.REPRICE_SYNC, STEP_NAME_2, SWNStep.ORDER, SWNStep.DISCOUNT_SYNC, STEP_NAME_3, SWNStep.CONTRACT_SYNC };
        SWNScenarioHelper.Scenario sc = new SWNMockBuilders.ScenarioBuilder(SCENARIO_NAME)
            .addSteps(stepNames)
            .putSteps()
            .build()
            .getScenario();

        Account pocAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Offer_Type__c, AccountHelper.OFFER_TYPE_POC)
            .build()
            .getRecord();
        Opportunity newBusinessOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
            .build()
            .getRecord();
        Quote testQt = new Quote(
            Opportunity = newBusinessOpp,
            Enabled_LBO__c = true,
            PackageNameOld__c = PACKAGE_NAME_OLD,
            IsMultiProductTechnicalQuote__c = true
        );
        testQt = (Quote) Test_Utils.putIntoUnwritableField(testQt, Quote.class, 'Account', pocAcc);

        BatchJob_PopulateSyncInfoMPUB batch = new BatchJob_PopulateSyncInfoMPUB();
        Test.startTest();
            batch.filterOutSteps(sc, testQt, new SWNSyncInfo());
        Test.stopTest();

        Assert.areEqual(EXPECTED_STEPS_AMOUNT, sc.stepNames.size(), 'The scenario should have ' + EXPECTED_STEPS_AMOUNT + ' steps after filtering out the steps');
        for (String expectedStepName : new Set<String> {SWNStep.REPRICE_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC}) {
            Assert.isTrue(
                sc.stepNames.contains(expectedStepName),
                'The step ' + expectedStepName + ' should be present in the scenario'
            );
        }
    }
}