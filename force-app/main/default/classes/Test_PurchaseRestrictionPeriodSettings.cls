@IsTest
private class Test_PurchaseRestrictionPeriodSettings {
    private static final String TERMINATED_SERVICE_NAME = 'Terminated Service';
    private static final String TARGET_SERVICE_NAME = 'Target Service';
    private static final Integer COOLDOWN_PERIOD_MONTHS = 3;

    class PurchaseRestrictionPeriodSettingsAsserter {
        public String expectedTerminatedServiceName;
        public String expectedTargetServiceName;
        public Integer expectedCooldownPeriodMonths;

        PurchaseRestrictionPeriodSettingsAsserter(String terminatedServiceName, String targetServiceName, Integer cooldownPeriodMonths) {
            this.expectedTerminatedServiceName = terminatedServiceName;
            this.expectedTargetServiceName = targetServiceName;
            this.expectedCooldownPeriodMonths = cooldownPeriodMonths;
        }

        public void assert(PurchaseRestrictionPeriodSettings settingsToAssert) {
            Assert.isNotNull(settingsToAssert, 'Settings should not be null');
            Assert.areEqual(expectedTerminatedServiceName, settingsToAssert.terminatedServiceName, 'Unexpected terminated service name was found');
            Assert.areEqual(expectedTargetServiceName, settingsToAssert.targetServiceName, 'Unexpected target service name was found');
            Assert.areEqual(expectedCooldownPeriodMonths, settingsToAssert.cooldownPeriodInMonths, 'Unexpected cooldown period was found');
        }
    }

    class PreparedTestData {
        public List<ServicePurchaseRestrictionPeriod__c> settingsToInsert;
        Map<String, PurchaseRestrictionPeriodSettingsAsserter> settingsNameToAsserter;

        public PreparedTestData(List<ServicePurchaseRestrictionPeriod__c> settingsToInsert, Map<String, PurchaseRestrictionPeriodSettingsAsserter> settingsNameToAsserter) {
            this.settingsToInsert = settingsToInsert;
            this.settingsNameToAsserter = settingsNameToAsserter;
        }
    }

    private static PreparedTestData buildTestData(Integer amountOfSettingRecords) {
        List<ServicePurchaseRestrictionPeriod__c> settingsToInsert = new List<ServicePurchaseRestrictionPeriod__c>();
        Map<String, PurchaseRestrictionPeriodSettingsAsserter> settingsNameToAsserter = new Map<String, PurchaseRestrictionPeriodSettingsAsserter>();
        for (Integer i = 0; i < amountOfSettingRecords; i++) {
            String terminatedServiceName = TERMINATED_SERVICE_NAME + 'x' + i;
            String targetServiceName = TARGET_SERVICE_NAME + 'x' + i;
            String settingsName = terminatedServiceName + targetServiceName;
            Integer cooldownPeriodMonths = COOLDOWN_PERIOD_MONTHS + i;

            settingsToInsert.add((ServicePurchaseRestrictionPeriod__c) new SObjectBuilder(ServicePurchaseRestrictionPeriod__c.sObjectType)
                .setFields(new Map<SObjectField, Object> {
                    ServicePurchaseRestrictionPeriod__c.Name => settingsName,
                    ServicePurchaseRestrictionPeriod__c.TerminatedService__c => terminatedServiceName,
                    ServicePurchaseRestrictionPeriod__c.TargetService__c => targetServiceName,
                    ServicePurchaseRestrictionPeriod__c.MonthsPassed__c => cooldownPeriodMonths
                })
                .build()
                .getRecord());
            settingsNameToAsserter.put(
                settingsName,
                new PurchaseRestrictionPeriodSettingsAsserter(
                    terminatedServiceName,
                    targetServiceName,
                    cooldownPeriodMonths
                )
            );
        }

        return new PreparedTestData(settingsToInsert, settingsNameToAsserter);
    }

    private static void assertGetSettingsResult(List<PurchaseRestrictionPeriodSettings> result, PreparedTestData testData) {
        assertGetSettingsResult(result, testData, null);
    }

    private static void assertGetSettingsResult(List<PurchaseRestrictionPeriodSettings> result, PreparedTestData testData, String assertMessage) {
        Assert.isNotNull(result, 'Result should not be null');

        Integer expectedSize = testData.settingsToInsert.size();
        String assertMsg = assertMessage ?? 'Result should have size of ' + expectedSize;
        Assert.areEqual(expectedSize, result.size(), assertMsg);

        for (PurchaseRestrictionPeriodSettings settings : result) {
            String settingsName = settings.terminatedServiceName + settings.targetServiceName;
            PurchaseRestrictionPeriodSettingsAsserter asserter = testData.settingsNameToAsserter.get(settingsName);
            Assert.isNotNull(asserter, 'Expected settings were not found: ' + settingsName);
            asserter.assert(settings);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetSettings() {
        PreparedTestData testData = buildTestData(1);
        insert testData.settingsToInsert;

        Test.startTest();
            List<PurchaseRestrictionPeriodSettings> result = PurchaseRestrictionPeriodSettings.getSettings();
        Test.stopTest();

        assertGetSettingsResult(result, testData);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetSettingsWhenNoSettingIsDefined() {
        PreparedTestData testData = buildTestData(0);

        Test.startTest();
            List<PurchaseRestrictionPeriodSettings> result = PurchaseRestrictionPeriodSettings.getSettings();
        Test.stopTest();

        assertGetSettingsResult(
            result,
            testData,
            'Result should be empty, when no ServicePurchaseRestrictionPeriod__c record is present in a database'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testGetSettingsWhenManySettingsAreDefined() {
        final Integer NUMBER_OF_SETTINGS_PRESENT = 5;

        PreparedTestData testData = buildTestData(NUMBER_OF_SETTINGS_PRESENT);
        insert testData.settingsToInsert;

        Test.startTest();
            List<PurchaseRestrictionPeriodSettings> result = PurchaseRestrictionPeriodSettings.getSettings();
        Test.stopTest();

        assertGetSettingsResult(result, testData);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testServiceCooldownSettings() {
        PreparedTestData testData = buildTestData(1);
        ServicePurchaseRestrictionPeriod__c setting = testData.settingsToInsert[0];
        PurchaseRestrictionPeriodSettingsAsserter asserter = testData.settingsNameToAsserter.get(setting.Name);

        Test.startTest();
            PurchaseRestrictionPeriodSettings result = new PurchaseRestrictionPeriodSettings(setting);
        Test.stopTest();

        asserter.assert(result);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testServiceCooldownSettingsWhenValuesAreNull() {
        ServicePurchaseRestrictionPeriod__c setting = (ServicePurchaseRestrictionPeriod__c) new SObjectBuilder(ServicePurchaseRestrictionPeriod__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServicePurchaseRestrictionPeriod__c.Name => null,
                ServicePurchaseRestrictionPeriod__c.TerminatedService__c => null,
                ServicePurchaseRestrictionPeriod__c.TargetService__c => null,
                ServicePurchaseRestrictionPeriod__c.MonthsPassed__c => null
            })
            .build()
            .getRecord();

        Test.startTest();
            PurchaseRestrictionPeriodSettings result = new PurchaseRestrictionPeriodSettings(setting);
        Test.stopTest();

        new PurchaseRestrictionPeriodSettingsAsserter(null, null, 0).assert(result);
    }
}