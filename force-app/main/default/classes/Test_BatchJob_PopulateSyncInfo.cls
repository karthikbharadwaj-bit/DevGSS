@IsTest
private class Test_BatchJob_PopulateSyncInfo {
    private static final String STEP_NAME_1 = 'STEP_NAME_1';
    private static final String STEP_NAME_2 = 'STEP_NAME_2';
    private static final String STEP_NAME_3 = 'STEP_NAME_3';
    private static final String SCENARIO_NAME = 'SCENARIO_NAME';
    private static final String PACKAGE_NAME_OLD = 'Old Package';

    private static Boolean hasReprice(SWNScenarioHelper.Scenario sc) {
        return sc.stepNames.contains(SWNStep.REPRICE_SYNC);
    }

    private class TestPopulateSyncInfo extends BatchJob_PopulateSyncInfo {
        public void execute(Database.BatchableContext bc, List<SObject> scope) {
        }

        protected override Database.QueryLocator buildQueryLocator() {
            return null;
        }
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

        TestPopulateSyncInfo batch = new TestPopulateSyncInfo();
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

        TestPopulateSyncInfo batch = new TestPopulateSyncInfo();
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