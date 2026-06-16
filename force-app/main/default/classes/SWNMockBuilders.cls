@IsTest
public class SWNMockBuilders {
    public static final String TEST_DML_EXCEPTION_MSG = 'Test DML Exception';

    private static final String PACKAGE_INFO_ID = BillingHttpRequestMock.PACKAGE_ID;
    private static final String INNER_PACKAGE_INFO_ID = '1389379001';
    private static final String PACKAGE_INFO_VERSION = '1';
    private static final String PACKAGE_INFO_CATALOG_ID = '18';
    private static final String EDITION_ID = '1';
    private static final String EDITION_NAME = 'Standard';
    private static final String CONTRACT_ID = (String) ValueProviderBuilder.provideDummyId(Contract__c.sObjectType).getValue();
    private static final String CONTRACT_EXT_ID = 'nib';
    private static final String CONTRACT_BILLING_ID = '1239';
    private static final String PACKAGE_LIMIT_CODE = 'testPackageLimitCode';
    private static final String PACKAGE_LIMIT_VALUE = '50000';

    public class ScenarioBuilder {
        private final String scenarioName;
        private final List<String> stepNames = new List<String>();
        private final Map<String, SWNStep> stepsMap = new Map<String, SWNStep>();
        private String descriptionRaw;
        private SWNScenarioHelper.Scenario scenario;

        public ScenarioBuilder(String scenarioName) {
            this.scenarioName = scenarioName;
        }

        public ScenarioBuilder addStep(String stepName) {
            stepNames.add(stepName);
            return this;
        }

        public ScenarioBuilder addSteps(List<String> stepNames) {
            this.stepNames.addAll(stepNames);
            return this;
        }

        public ScenarioBuilder build() {
            if (String.isBlank(this.descriptionRaw)) {
                descriptionRaw = (String) ValueProviderBuilder.provideUniqueString('description').getValue();
            }
            scenario = new SWNScenarioHelper.Scenario(stepNames);
            return this;
        }

        public ScenarioBuilder putScenario() {
            SWNScenarioHelper.SCENARIOS.put(scenarioName, scenario);
            return this;
        }

        public ScenarioBuilder putSteps() {
            for (String stepName : stepNames) {
                if (!SWNStep.STEPS.containsKey(stepName)) {
                    SWNStep.STEPS.put(stepName, buildStep(stepName));
                }
            }
            return this;
        }

        public ScenarioBuilder buildAndPut() {
            return build().putScenario();
        }

        public SWNScenarioHelper.Scenario getScenario() {
            return scenario;
        }

        private SWNStep buildStep(String stepName) {
            return new SWNStep.SWNStepBuilder()
                .withName(stepName)
                .build();
        }
    }

    public class SyncInfoBuilder {
        private final List<String> stepNames;
        private final String scenarioName;
        private String userName;
        private SWNSyncInfo syncInfo;

        public SyncInfoBuilder(ScenarioBuilder builder) {
            this(builder.stepNames, builder.scenarioName);
        }

        public SyncInfoBuilder(List<String> stepNames, String scenarioName) {
            this.stepNames = stepNames;
            this.scenarioName = scenarioName;
        }

        public SyncInfoBuilder withUsername(String username) {
            this.username = username;
            return this;
        }
        public SyncInfoBuilder build() {
            syncInfo = buildSyncInfo(stepNames, scenarioName);
            return this;
        }

        public SWNSyncInfo getSyncInfo() {
            return syncInfo;
        }

        public String getAsJson() {
            return JSON.serialize(getSyncInfo());
        }

        private SWNSyncInfo buildSyncInfo(List<String> stepNames, String scenarioName) {
            Integer stepSize = stepNames.size();
            Map<String, Datetime> stepToTimeStamp = new Map<String, Datetime>();
            Map<String, String> stepToUsername = new Map<String, String>();
            Datetime now = Datetime.now();
            for (Integer i = stepSize - 1; i > -1; i--) {
                String stepName = stepNames[i];
                Datetime timeStamp = now.addMinutes(-1 * (stepSize - i));
                stepToTimeStamp.put(stepName, timeStamp);
                if (String.isNotBlank(userName)) {
                    stepToUsername.put(stepName, userName);
                }
            }

            SWNSyncInfo syncInfo = new SWNSyncInfo();
            syncInfo.scenarioName = scenarioName;
            syncInfo.timeStampMap = stepToTimeStamp;
            syncInfo.stepNames = stepNames;
            if (!stepToUsername.isEmpty()) {
                syncInfo.userNameMap = stepToUsername;
            }
            return syncInfo;
        }
    }

    public class PackageInfoBuilder {
        private BillingWrappers.QuotePackageInfo packageInfo;

        public PackageInfoBuilder() {
            packageInfo = buildPackageInfo();
            // Set contract to null by default, because QuotePackageInfo creates an empty one
            packageInfo.contract = null;
        }

        public PackageInfoBuilder withContract() {
            return withContract(buildContract());
        }
        public PackageInfoBuilder withContract(BillingWrappers.Contract contract) {
            this.packageInfo.contract = contract;
            return this;
        }
        public PackageInfoBuilder withInnerPackageInfo() {
            return withInnerPackageInfo(buildInnerPackageInfo());
        }
        public PackageInfoBuilder withInnerPackageInfo(BillingWrappers.PackageInfo innerPackageInfo) {
            this.packageInfo.packageInfo = innerPackageInfo;
            return this;
        }
        public PackageInfoBuilder withEdition() {
            return withEdition(buildEdition());
        }
        public PackageInfoBuilder withEdition(BillingWrappers.Edition edition) {
            this.packageInfo.edition = edition;
            return this;
        }
        public PackageInfoBuilder withPackageLimit() {
            return withPackageLimit(buildPackageLimit());
        }
        public PackageInfoBuilder withPackageLimit(BillingWrappers.GlobalPackageLimits packageLimit) {
            this.packageInfo.globalPackageLimits = new List<BillingWrappers.GlobalPackageLimits> {packageLimit};
            return this;
        }
        public PackageInfoBuilder withProductId(String productId) {
            this.packageInfo.productId = productId;
            return this;
        }
        public PackageInfoBuilder withProductName(String productName) {
            this.packageInfo.productName = productName;
            return this;
        }

        public List<BillingWrappers.QuotePackageInfo> build() {
            return new List<BillingWrappers.QuotePackageInfo> {packageInfo};
        }
        public String buildAsJson() {
            return JSON.serialize(build());
        }

        private BillingWrappers.QuotePackageInfo buildPackageInfo() {
            BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
            pInfo.id = PACKAGE_INFO_ID;
            pInfo.version = PACKAGE_INFO_VERSION;
            pInfo.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;
            pInfo.duration = Product2Helper.CHARGE_TERM_MONTHLY;
            pInfo.offerType = QuoteHelper.OFFER_TYPE_REGULAR;
            pInfo.permissions = null;
            return pInfo;
        }
        private BillingWrappers.Contract buildContract() {
            BillingWrappers.Contract contract = new BillingWrappers.Contract();
            contract.id = CONTRACT_ID;
            contract.extId = CONTRACT_EXT_ID;
            contract.billingId = CONTRACT_BILLING_ID;
            return contract;
        }
        private BillingWrappers.PackageInfo buildInnerPackageInfo() {
            BillingWrappers.PackageInfo innerPackageInfo = new BillingWrappers.PackageInfo();
            innerPackageInfo.id = INNER_PACKAGE_INFO_ID;
            innerPackageInfo.catalogId = PACKAGE_INFO_CATALOG_ID;
            innerPackageInfo.version = PACKAGE_INFO_VERSION;
            return innerPackageInfo;
        }
        private BillingWrappers.Edition buildEdition() {
            BillingWrappers.Edition edition = new BillingWrappers.Edition();
            edition.id = EDITION_ID;
            edition.name = EDITION_NAME;
            return edition;
        }
        private BillingWrappers.GlobalPackageLimits buildPackageLimit() {
            BillingWrappers.GlobalPackageLimits packageLimit = new BillingWrappers.GlobalPackageLimits();
            packageLimit.value = PACKAGE_LIMIT_VALUE;
            packageLimit.code = PACKAGE_LIMIT_CODE;
            packageLimit.name = PACKAGE_LIMIT_CODE;
            packageLimit.limitType = 'Amount';
            packageLimit.scope = 'BillingCycle';
            packageLimit.transactionType = 'Any';
            packageLimit.target = 'Global';
            packageLimit.isOverride = 'false';
            return packageLimit;
        }
    }

    public class NGBSSyncableBuilder {
        final SyncableMock testSyncable;

        public NGBSSyncableBuilder() {
            testSyncable = new SyncableMock();
        }

        public NGBSSyncableBuilder(SyncableMock mockInstance) {
            testSyncable = mockInstance;
        }

        public NGBSSyncableBuilder withDiscountsSynced(Boolean bool) {
            testSyncable.isDiscountsSynced = bool;
            return this;
        }
        public NGBSSyncableBuilder withContractsSynced(Boolean bool) {
            testSyncable.isContractsSynced = bool;
            return this;
        }
        public NGBSSyncableBuilder withResyncContractAllowed(Boolean bool) {
            testSyncable.isResyncContractAllowed = bool;
            return this;
        }
        public NGBSSyncableBuilder withRepriceSynced(Boolean bool) {
            testSyncable.isRepriceSynced = bool;
            return this;
        }
        public NGBSSyncableBuilder withUpsellStepCompleted(Boolean bool) {
            testSyncable.isUpsellStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withDownsellStepCompleted(Boolean bool) {
            testSyncable.isDownsellStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withUpgradeStepCompleted(Boolean bool) {
            testSyncable.isUpgradeStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withLicenseLimitsSynced(Boolean bool) {
            testSyncable.isLicenseLimitsSynced = bool;
            return this;
        }
        public NGBSSyncableBuilder withContractCancelled(Boolean bool) {
            testSyncable.isContractCancelled = bool;
            return this;
        }
        public NGBSSyncableBuilder withOrderStepCompleted(Boolean bool) {
            testSyncable.isOrderStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withInvoiceStepCompleted(Boolean bool) {
            testSyncable.isInvoiceStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withSpendingLimitRetrieveStepCompleted(Boolean bool) {
            testSyncable.isSpendingLimitRetrieveStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withTerminationStepCompleted(Boolean bool) {
            testSyncable.isTerminationStepCompleted = bool;
            return this;
        }
        public NGBSSyncableBuilder withSyncedToICB(Boolean bool) {
            testSyncable.isSyncedToICB = bool;
            return this;
        }
        public NGBSSyncableBuilder withICBProvisioningComplete(Boolean bool) {
            testSyncable.isICBProvisioningComplete = bool;
            return this;
        }
        public NGBSSyncableBuilder withChargeTermSynced(Boolean bool) {
            testSyncable.isChargeTermSynced = bool;
            return this;
        }
        public NGBSSyncableBuilder withFSCSynced(Boolean bool) {
            testSyncable.isFSCSynced = bool;
            return this;
        }
        public NGBSSyncableBuilder withDownsellCaseCreated(Boolean bool) {
            testSyncable.isDownsellCaseCreated = bool;
            return this;
        }

        public NGBSSyncableBuilder withOrderDate(Date orderDate) {
            testSyncable.setOrderDate(orderDate);
            return this;
        }
        public NGBSSyncableBuilder withSyncInfo(String syncInfo) {
            testSyncable.setSyncInfo(syncInfo);
            return this;
        }
        public NGBSSyncableBuilder withNGBSSyncExecutorInfo(String executorInfo) {
            testSyncable.setNGBSSyncExecutorInfo(executorInfo);
            return this;
        }
        public NGBSSyncableBuilder withSObjectToUpdate(SObject sObjectToUpdate) {
            testSyncable.sObjectToUpdate = sObjectToUpdate;
            return this;
        }
        public NGBSSyncableBuilder withNameToSObjectFieldMap(Map<String, SObjectField> nameToSObjectFieldMap) {
            testSyncable.nameToSObjectFieldMap = nameToSObjectFieldMap;
            return this;
        }
        public NGBSSyncableBuilder withSObjFieldsToUpdate(Map<SObjectField, Object> sObjFieldsToUpdate) {
            testSyncable.sObjFieldsToUpdate = sObjFieldsToUpdate;
            return this;
        }

        public NGBSSyncables.ISyncable build() {
            return testSyncable;
        }
    }

    public virtual class SyncableMock implements NGBSSyncables.ISyncable {
        public Boolean isUpdateSobjectCalled = false;

        String syncInfoField;
        String ngbsSyncExecutorInfo;
        SObject sObjectToUpdate;
        Date orderDate;
        Map<String, SObjectField> nameToSObjectFieldMap = new Map<String, SObjectField>();
        Map<SObjectField, Object> sObjFieldsToUpdate = new Map<SObjectField, Object>();

        Boolean isDiscountsSynced = false;
        Boolean isContractsSynced = false;
        Boolean isResyncContractAllowed = false;
        Boolean isRepriceSynced = false;
        Boolean isUpsellStepCompleted = false;
        Boolean isDownsellStepCompleted = false;
        Boolean isUpgradeStepCompleted = false;
        Boolean isLicenseLimitsSynced = false;
        Boolean isContractCancelled = false;
        Boolean isOrderStepCompleted = false;
        Boolean isInvoiceStepCompleted = false;
        Boolean isSpendingLimitRetrieveStepCompleted = false;
        Boolean isTerminationStepCompleted = false;
        Boolean isSyncedToICB = false;
        Boolean isICBProvisioningComplete = false;
        Boolean isChargeTermSynced = false;
        Boolean isFSCSynced = false;
        Boolean isDownsellCaseCreated = false;

        public String getSyncInfoField() {
            return syncInfoField;
        }

        public SObject getSObjectToUpdate() {
            return sObjectToUpdate;
        }

        public Map<String, SObjectField> getNameToSObjectFieldMap() {
            return nameToSObjectFieldMap;
        }

        public Map<SObjectField, Object> getSObjFieldsToUpdate() {
            return sObjFieldsToUpdate;
        }

        public void setFSCSynced() {
            isFSCSynced = true;
        }

        public void setIsDownsellCaseCreated() {
            isDownsellCaseCreated = true;
        }

        public void setOrderDate(Date orderDate) {
            this.orderDate = orderDate;
        }

        public void setSyncInfo(String updatedSyncInfo) {
            syncInfoField = updatedSyncInfo;
        }

        public void setNGBSSyncExecutorInfo(String updatedExecutorInfo) {
            ngbsSyncExecutorInfo = updatedExecutorInfo;
        }

        public String getNGBSSyncExecutorInfo() {
            return ngbsSyncExecutorInfo;
        }

        public void setFlagSynced(SObjectField field) {
            this.sObjFieldsToUpdate.put(field, true);
        }

        public virtual void updateSObject() {
            isUpdateSobjectCalled = true;
        }

        public void setICBSynced() {
            isSyncedToICB = true;
        }

        public void setICBNotSynced() {
            isSyncedToICB = false;
        }

        public void setICBProvisioning() {
            isICBProvisioningComplete = true;
        }

        public Boolean isDiscountsSynced() {
            return isDiscountsSynced;
        }

        public Boolean isContractsSynced() {
            return isContractsSynced;
        }

        public Boolean isResyncContractAllowed() {
            return isResyncContractAllowed;
        }

        public Boolean isRepriceSynced() {
            return isRepriceSynced;
        }

        public Boolean isUpsellStepCompleted() {
            return isUpsellStepCompleted;
        }

        public Boolean isDownsellStepCompleted() {
            return isDownsellStepCompleted;
        }

        public Boolean isUpgradeStepCompleted() {
            return isUpgradeStepCompleted;
        }

        public Boolean isLicenseLimitsSynced() {
            return isLicenseLimitsSynced;
        }

        public Boolean isContractCancelled() {
            return isContractCancelled;
        }

        public Boolean isOrderStepCompleted() {
            return isOrderStepCompleted;
        }

        public Boolean isInvoiceStepCompleted() {
            return isInvoiceStepCompleted;
        }

        public Boolean isSpendingLimitRetrieveStepCompleted() {
            return isSpendingLimitRetrieveStepCompleted;
        }

        public Boolean isTerminationStepCompleted() {
            return isTerminationStepCompleted;
        }

        public Boolean isSyncedToICB() {
            return isSyncedToICB;
        }

        public Boolean isICBProvisioningComplete() {
            return isICBProvisioningComplete;
        }

        public Boolean isChargeTermSynced() {
            return isChargeTermSynced;
        }

        public Boolean isFSCSynced() {
            return isFSCSynced;
        }

        public Boolean isDownsellCaseCreated() {
            return isDownsellCaseCreated;
        }

        public Boolean getBooleanFlagByStepName(String stepName) {
            return this.nameToSObjectFieldMap?.get(stepName) != null
                && Boolean.valueOf(this.sObjectToUpdate.get(this.nameToSObjectFieldMap.get(stepName)));
        }
    }

    public class FailingSyncableMock extends SyncableMock {
        public override void updateSObject() {
            isUpdateSobjectCalled = true;
            throw new DmlException(TEST_DML_EXCEPTION_MSG);
        }
    }
}