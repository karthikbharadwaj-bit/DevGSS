public with sharing abstract class SWNActionRunner {
    @TestVisible
    private static final String SOURCE = 'SyncWithNGBS';
    @TestVisible
    private static final String ERROR_MSG = 'Error';
    @TestVisible
    private static final String TRANSACTION_LIMIT_EXCEEDED = 'message=transaction limit exceeded';
    @TestVisible
    private static final String TYPE_AMOUNT = 'type=Amount';

    @TestVisible
    protected SWNDataCollector sdc;
    @TestVisible
    protected Boolean isSkipFinalize = false;
    @TestVisible
    protected Response res = new Response();
    @TestVisible
    private Boolean wasCaseQueueableEnqueued = false;

    public SWNActionRunner(Id quoteId) {
        sdc = new SWNDataCollector(quoteId);
    }

    public SWNActionRunner(Id quoteId, String action) {
        sdc = new SWNDataCollector(quoteId, action);
    }

    public SWNActionRunner() {}

    protected abstract void run();

    public Response sync() {
        try {
            NGBSAPI.initNgbsEndpoints(sdc.opp.isFedRamp__c);

            updateFreeServiceCredit();

            run();

            if (isSkipFinalize) {
                return res;
            }

            finalizeStep(sdc.currentStep, sdc.currentScenarioKey, sdc.syncable, sdc.currentScenario.stepNames);
            if (isLastStepCompletedSuccessfully(sdc.currentScenario, sdc.currentStep)) {
                executeCaseQueueable();
                updateRCCCSyncStatus();
            }
        } catch (Exception ex) {
            handleMessages(ex);
        } finally {
            updateSyncStepExecutorInfo(sdc.syncable, sdc.action);
        }
        return res;
    }

    @TestVisible
    protected void handleException(String message, String details, String caseReason, Boolean isValidationException) {
        if (String.isBlank(details)) {
            res.error(message);
        } else {
            res.error(message, details);
        }
        DealDeskCaseGenerator.createCase(sdc.qt, new Opportunity(), isValidationException, caseReason, sdc.syncable);
    }

    @TestVisible
    protected void handleException(String message, String details, Boolean isValidationException) {
        handleException(message, details, message, isValidationException);
    }

    @TestVisible
    private void updateFreeServiceCredit() {
        if (String.isNotBlank(sdc.qt.Package_Info__c)
            && QuoteHelper.isExistingBusiness(sdc.qt)
            && !QuoteHelper.isEngageTerminationQuote(sdc.qt)
            && SWNHelper.isContractWasDeselected(sdc.qt, sdc.billingContracts)
        ) {
            NGBSAPI.updateFreeServiceCredit(sdc.billingId, sdc.packageId, 0);
        }
    }

    @TestVisible
    private void executeCaseQueueable() {
        if (!sdc.qt.Enabled_LBO__c) {
            return;
        }

        List<DealDeskCaseDescription__c> existingDescs = (List<DealDeskCaseDescription__c>) new DealDeskCaseDescriptionSelector()
            .selectDealDeskCaseDescriptionsForAccounts(new List<Object> {new Set<Id> {sdc.opp.AccountId}})
            .executeQuery();

        if (!existingDescs.isEmpty()) {
            if (Test.isRunningTest()) {
                wasCaseQueueableEnqueued = true;
            } else {
                System.enqueueJob(new CaseQueueable(new Set<Id>(), existingDescs));
            }
        }
    }

    @TestVisible
    private void handleMessages(Exception ex) {
        PlatformLog.logResult(SOURCE + ': ' + sdc.action + ' ' + sdc.qt.Id, ex.getMessage(), 'ErrorMessage: ' + ex.getMessage() + ' StackTrace: ' + ex.getStackTraceString(), null, null, false);
        if (ex.getMessage().contains(TRANSACTION_LIMIT_EXCEEDED) && ex.getMessage().contains(TYPE_AMOUNT)) {
            handleException(ERROR_MSG, CaseHelper.CASE_REASON_SPENDING_LIMIT_EXCEPTION, CaseHelper.CASE_REASON_SPENDING_LIMIT_EXCEPTION, false);
            return;
        }

        handleException(ex.getMessage(), ex.getStackTraceString(), CaseHelper.CASE_REASON_EXCEPTION, false);
    }

    @TestVisible
    private void finalizeStep(SWNStep st, String scenarioName, NGBSSyncables.ISyncable syncable, List<String> stepNames) {
        if (!st.isStepCompletedSuccessfully) {
            return;
        }

        List<SObject> recordsToUpdate = new List<SObject>();
        SObject objectToUpdate = syncable.getSObjectToUpdate();

        SObjectField stepField = syncable.getNameToSObjectFieldMap().get(st.name);
        Map<SObjectField, Object> sObjectFieldsToUpdate = syncable.getSObjFieldsToUpdate();

        Boolean isNeedStepInfo = String.isNotBlank(stepField?.toString())
            || !sObjectFieldsToUpdate.isEmpty()
            || st.isNeedToLogTimeStamp;

        if (isNeedStepInfo) {
            if (stepField != null) {
                objectToUpdate.put(stepField, true);
            }
            if (st.isNeedToLogTimeStamp) {
                syncable.setSyncInfo(SWNSyncInfo.updateSyncInfoJson(scenarioName, syncable.getSyncInfoField(), st.name, null, stepNames));
                sObjectFieldsToUpdate = syncable.getSObjFieldsToUpdate();
            }
            for (SObjectField fieldName : sObjectFieldsToUpdate.keySet()) {
                objectToUpdate.put(fieldName, sObjectFieldsToUpdate.get(fieldName));
            }
            recordsToUpdate.add(objectToUpdate);
        }

        if (!st.quoteFieldsToUpdate.isEmpty()) {
            Quote quoteToUpdate = new Quote();
            Boolean isQuoteIdExist = st.quoteFieldsToUpdate.containsKey('Id') || st.quoteFieldsToUpdate.containsKey('id');
            if (!isQuoteIdExist) {
                AquivaHelper.throwAquivaException('Cannot update Quote due to missing Quote.Id');
            }
            for (String fieldName : st.quoteFieldsToUpdate.keySet()) {
                quoteToUpdate.put(fieldName, st.quoteFieldsToUpdate.get(fieldName));
            }
            recordsToUpdate.add(quoteToUpdate);
        }

        if (st.accountFieldsToUpdate.containsKey('Id')) {
            Account accToUpdate = new Account();
            for (String fieldName : st.accountFieldsToUpdate.keySet()) {
                accToUpdate.put(fieldName, st.accountFieldsToUpdate.get(fieldName));
            }
            recordsToUpdate.add(accToUpdate);
        }

        if (recordsToUpdate.isEmpty()) {
            return;
        }

        Triggers.switchOff();
        update recordsToUpdate;
        Triggers.switchOn();
    }

    @TestVisible
    private class SyncStepExecutorInfo {
        public String userName;
        public String stepName;
        public String reason;

        public SyncStepExecutorInfo(String userName, String stepName, String reason) {
            this.userName = userName;
            this.stepName = stepName;
            this.reason = reason;
        }
    }

    @TestVisible
    private void updateSyncStepExecutorInfo(NGBSSyncables.ISyncable syncable, String stepName) {
        try {
            SyncStepExecutorInfo syncStepInfo = new SyncStepExecutorInfo(
                UserInfo.getName(),
                stepName,
                System.isBatch() ? SWNHelper.SYNC_AUTO : SWNHelper.SYNC_MANUALLY
            );
            String syncStepInfoStr = JSON.serialize(syncStepInfo);
            syncable.setNGBSSyncExecutorInfo(syncStepInfoStr);
            syncable.updateSObject();
        } catch (Exception e) {
            // add error handling
        }
    }

    private Boolean isLastStepCompletedSuccessfully(SWNScenarioHelper.Scenario currentScenario, SWNStep currentStep) {
        String lastStepName = currentScenario.stepNames.get(currentScenario.stepNames.size() - 1);
        return lastStepName == currentStep.name && currentStep.isStepCompletedSuccessfully;
    }

    private void updateRCCCSyncStatus() {
        if (QuoteHelper.isRCCC(sdc.qt)) {
            IcbHelper.updateRCCCSyncStatus(sdc.opp.MasterOpportunity__c ?? sdc.opp.Id, IcbHelper.CC_SYNC_STATUS_COMPLETED);
        }
    }
}