public abstract class BatchJob_PopulateSyncInfo implements Database.Batchable<SObject> {
    @TestVisible
    protected final String overrideQuery;

    public BatchJob_PopulateSyncInfo() {}
    public BatchJob_PopulateSyncInfo(String overrideQuery) {
        this.overrideQuery = overrideQuery;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        if (String.isNotBlank(overrideQuery)) {
            return Database.getQueryLocator(overrideQuery);
        }
        return buildQueryLocator();
    }
    public void finish(Database.BatchableContext BC) {
    }

    protected abstract Database.QueryLocator buildQueryLocator();

    protected Boolean shouldBeSkipped(String syncInfo) {
        return String.isBlank(syncInfo) || syncInfo.contains('stepNames');
    }
    protected String addStepNamesToSyncInfo(String syncInfoStr, Quote qt) {
        SWNSyncInfo syncInfo = (SWNSyncInfo) JSON.deserialize(syncInfoStr, SWNSyncInfo.class);
        SWNScenarioHelper.Scenario sc = SWNScenarioHelper.getScenarioByKey(syncInfo.scenarioName);
        filterOutSteps(sc, qt, syncInfo);
        filterOutReprice(sc, syncInfo);
        syncInfo.stepNames = sc.stepNames;

        return JSON.serialize(syncInfo);
    }
    @TestVisible
    protected void filterOutSteps(SWNScenarioHelper.Scenario sc, Quote qt, SWNSyncInfo syncInfo) {
        if (qt == null || !qt.Enabled_LBO__c || QuoteHelper.isNewBusiness(qt)) {
            return;
        }

        for (Integer i = sc.stepNames.size() - 1; i >= 0 ; --i) {
            String stepName = sc.stepNames.get(i);
            if (stepName != SWNStep.DISCOUNT_SYNC
                && stepName != SWNStep.CONTRACT_SYNC
                && stepName != SWNStep.REPRICE_SYNC
                && !syncInfo.timeStampMap.containsKey(stepName)
            ) {
                sc.stepNames.remove(i);
            }
        }
    }
    @TestVisible
    protected void filterOutReprice(SWNScenarioHelper.Scenario sc, SWNSyncInfo syncInfo) {
        if (syncInfo.timeStampMap.containsKey(SWNStep.REPRICE_SYNC) || !sc.stepNames.contains(SWNStep.REPRICE_SYNC)) {
            return;
        }

        Boolean isStepAfterRepriseCompleted = false;
        Integer repriseIndex = sc.stepNames.indexOf(SWNStep.REPRICE_SYNC);
        for (Integer i = repriseIndex + 1; i < sc.stepNames.size(); i++) {
            if (syncInfo.timeStampMap.containsKey(sc.stepNames.get(i))) {
                isStepAfterRepriseCompleted = true;
                break;
            }
        }

        if (isStepAfterRepriseCompleted) {
            sc.stepNames.remove(repriseIndex);
        }
    }
}