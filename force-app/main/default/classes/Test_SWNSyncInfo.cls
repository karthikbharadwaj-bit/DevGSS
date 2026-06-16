@IsTest
private class Test_SWNSyncInfo {
    private static final String TEST_SCENARIO_NAME = 'some_scenario_name';
    private static final String TEST_SCENARIO_NAME_2 = 'some_scenario_name_2';
    private static final String TEST_STEP_NAME = 'some_step_name';
    private static final String TEST_STEP_NAME_2 = 'some_step_name_2';
    private static final String TEST_USER_NAME = 'test user';

    private static final String PACKAGE_CATALOG_ID = '18';
    private static final String PACKAGE_VERSION = '1';
    private static final String PACKAGE_ID = '1389379001';
    private static String NGBS_ACCOUNT_RESPONSE = '{"id":"1","packages":[{"catalogId":"' + PACKAGE_CATALOG_ID + '",'
        + '"version":"' + PACKAGE_VERSION + '","offerType":"null","id":' + PACKAGE_ID + ',"licenses":[{"id":"3","qty":5,"catalogId": "'
        + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}]}';

    private static final String CORRECT_SCENARIO_ASSERT_MSG = 'syncInfo should contain scenario name';
    private static final String SHOULD_CONTAIN_STEP_NAME_ASSERT_MSG = ' should contain ' + TEST_STEP_NAME + ' as a key with ';
    private static final String DATETIME_ASSERT_MSG = 'timeStampMap' + SHOULD_CONTAIN_STEP_NAME_ASSERT_MSG + 'today\'s DateTime';
    private static final String USERNAME_ASSERT_MSG = 'userNameMap' + SHOULD_CONTAIN_STEP_NAME_ASSERT_MSG + 'with specific user name';
    private static final String UNEXPECTED_NUMBER_PRESENT_ASSERT_MSG = 'Unexpected number of steps are present in ';

    private static void assertUpdateSyncInfoJson(String result, String expectedScenarioName) {
        assertUpdateSyncInfoJson(result, expectedScenarioName, new Map<String, Datetime> {
            TEST_STEP_NAME => Datetime.now()
        });
    }
    private static void assertUpdateSyncInfoJson(String result, String expectedScenarioName, Map<String, Datetime> expectedStepsToTimestamps) {
        Assert.isFalse(String.isBlank(result), 'updateSyncInfo should always return a sync info');
        SWNSyncInfo resultedSyncInfo = (SWNSyncInfo) JSON.deserialize(
            result,
            SWNSyncInfo.class
        );

        Assert.areEqual(
            expectedScenarioName,
            resultedSyncInfo.scenarioName,
            CORRECT_SCENARIO_ASSERT_MSG
        );

        Integer expectedStepsAmount = expectedStepsToTimestamps.size();
        Assert.areEqual(
            expectedStepsAmount,
            resultedSyncInfo.timeStampMap.size(),
            UNEXPECTED_NUMBER_PRESENT_ASSERT_MSG + 'syncInfo.timeStampMap'
        );
        Assert.areEqual(
            expectedStepsAmount,
            resultedSyncInfo.userNameMap.size(),
            UNEXPECTED_NUMBER_PRESENT_ASSERT_MSG + 'syncInfo.userNameMap'
        );

        for (String stepName : expectedStepsToTimestamps.keySet()) {
            assertSyncInfoStepMaps(resultedSyncInfo, stepName, expectedStepsToTimestamps.get(stepName));
        }
    }
    private static void assertSyncInfoStepMaps(SWNSyncInfo syncInfo, String stepName, Datetime expectedTimeStamp) {
        Assert.isTrue(
            syncInfo.timeStampMap.containsKey(stepName),
            DATETIME_ASSERT_MSG
        );
        Assert.isTrue(
            syncInfo.userNameMap.containsKey(stepName),
            USERNAME_ASSERT_MSG
        );
        Assert.areEqual(
            TEST_USER_NAME,
            syncInfo.userNameMap.get(stepName),
            USERNAME_ASSERT_MSG
        );
        Assert.areEqual(
            expectedTimeStamp,
            syncInfo.timeStampMap.get(stepName),
            DATETIME_ASSERT_MSG
        );
    }

    @isTest
    static void testUpdateSyncInfoJsonWithInvalidParams() {
        try {
            SWNSyncInfo.updateSyncInfoJson(null, null, null, null, null);
            Assert.fail('Exception should be thrown');
        } catch (AquivaHelper.AquivaException ex) {
            Assert.areEqual(
                SWNSyncInfo.REQUIRED_PARAM_ERROR,
                ex.getMessage(),
                'Unexpected exception message: ' + ex.getMessage()
            );
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdateSyncInfoJson() {
        User testUser = (User) new SObjectBuilder(User.sObjectType)
            .setField(User.LastName, TEST_USER_NAME)
            .build()
            .getRecord();

        Test.startTest();
            String newSyncInfoJson;
            System.runAs(testUser) {
                newSyncInfoJson = SWNSyncInfo.updateSyncInfoJson(
                    TEST_SCENARIO_NAME,
                    null,
                    TEST_STEP_NAME,
                    null,
                    null
                );
            }
        Test.stopTest();

        assertUpdateSyncInfoJson(newSyncInfoJson, TEST_SCENARIO_NAME);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testUpdateSyncInfoJsonWhenExistingInfoIsPassed() {
        SWNSyncInfo existingSyncInfo = new SWNMockBuilders.SyncInfoBuilder(new List<String> {TEST_STEP_NAME}, TEST_SCENARIO_NAME)
            .withUsername(TEST_USER_NAME)
            .build()
            .getSyncInfo();
        String existingSyncInfoJson = JSON.serialize(existingSyncInfo);

        Test.startTest();
            String updatedSyncInfoJson = SWNSyncInfo.updateSyncInfoJson(
                TEST_SCENARIO_NAME_2,
                existingSyncInfoJson,
                TEST_STEP_NAME_2,
                TEST_USER_NAME,
                null
            );
        Test.stopTest();

        Map<String, Datetime> expectedStepsToTimestamps = new Map<String, Datetime> {
            TEST_STEP_NAME => existingSyncInfo.timeStampMap.get(TEST_STEP_NAME),
            TEST_STEP_NAME_2 => Datetime.now()
        };
        assertUpdateSyncInfoJson(updatedSyncInfoJson, TEST_SCENARIO_NAME_2, expectedStepsToTimestamps);
    }
}