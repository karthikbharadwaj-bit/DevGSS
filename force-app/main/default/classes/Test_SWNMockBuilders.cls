@IsTest
private class Test_SWNMockBuilders {
    private static final IValueProvider STEP_NAME_PROVIDER = ValueProviderBuilder.provideUniqueString('Test Step');
    private static final String SCENARIO_NAME = 'Test Scenario';
    private static final String STEP_NAME_1 = (String) STEP_NAME_PROVIDER.getValue();
    private static final String STEP_NAME_2 = (String) STEP_NAME_PROVIDER.getValue();
    private static final String STEP_NAME_3 = (String) STEP_NAME_PROVIDER.getValue();
    private static final String STEP_NAME_4 = (String) STEP_NAME_PROVIDER.getValue();

    private static void assertStepTimeStamps(Integer stepIndex, Datetime stepTimeStamp, Map<String, Datetime> timeStampMap, List<String> stepNames) {
        for (Integer i = 0; i < stepIndex; i++) {
            Assert.isTrue(
                stepTimeStamp > timeStampMap.get(stepNames[i]),
                'Older step timestamps must be less than newer step timestamps'
            );
        }
    }

    @isTest
    static void testBuildSyncInfo() {
        List<String> stepNames = new List<String> {STEP_NAME_1, STEP_NAME_2, STEP_NAME_3, STEP_NAME_4};
        SWNMockBuilders.ScenarioBuilder builder = new SWNMockBuilders.ScenarioBuilder(SCENARIO_NAME)
            .addSteps(stepNames);

        Test.startTest();
            SWNSyncInfo syncInfo = new SWNMockBuilders.SyncInfoBuilder(builder).build().getSyncInfo();
        Test.stopTest();

        Assert.isNotNull(syncInfo, 'buildOpportunitySyncInfo must return OpportunitySyncInfo');
        Assert.areEqual(
            SCENARIO_NAME,
            syncInfo.scenarioName,
            'OpportunitySyncInfo must have the same scenario name as the builder'
        );
        Assert.areEqual(
            stepNames.size(),
            syncInfo.timeStampMap.size(),
            'OpportunitySyncInfo must have the same number of steps as the builder'
        );
        Integer stepSize = stepNames.size();
        for (Integer i = stepSize - 1; i > -1; i--) {
            String stepName = stepNames[i];
            Assert.isTrue(
                syncInfo.timeStampMap.containsKey(stepName),
                'OpportunitySyncInfo must have a timestamp for each step in the builder'
            );

            Datetime timeStamp = syncInfo.timeStampMap.get(stepName);
            Assert.isNotNull(timeStamp, 'OpportunitySyncInfo must have a timestamp for each step in the builder');
            assertStepTimeStamps(i, timeStamp, syncInfo.timeStampMap, stepNames);
        }
    }
}