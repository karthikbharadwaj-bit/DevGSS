public class SWNDownsellRunner extends SWNActionRunner {
    @TestVisible
    private static final String MISSING_QUOTE_ERROR = 'Quote is missed or empty, downsell is not possible';

    @TestVisible
    private SWNDownsellRunner() {}

    public SWNDownsellRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    protected override void run() {
        downsell();
    }

    // the method has return type Boolean for unit testing purposes
    @TestVisible
    private Boolean downsell() {
        Boolean isStepShouldBePassedByDefault = !SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c
            && !SWNHelper.isLBOOrOfficeProductSelected(sdc.qt)
            && !QuoteHelper.isPhoenix(sdc.qt);

        if (isStepShouldBePassedByDefault) {
            return true;
        }

        res = SWNHelper.getStopSync(sdc.action, sdc.qt, sdc.billingId, sdc.ngbsAcc);
        if (!BooleanHelper.toBoolean(res.data.get(SWNHelper.STOP_AUTO_SYNC))) {
            return true;
        }

        if (sdc.syncable.isDownsellCaseCreated()) {
            isSkipFinalize = true;
            return true;
        }

        processDownsell();
        return false;
    }

    @TestVisible
    private void processDownsell() {
        if (SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c) {
            SWNStep step = sdc.currentStep;
            step.isStepCompletedSuccessfully = processSimplifiedLBODownsell();
        } else if (sdc.qt.Enabled_LBO__c || QuoteHelper.isPhoenix(sdc.qt)) {
            DealDeskCaseGenerator.createCase(sdc.qt, sdc.opp, false, (String)res.data.get(SWNHelper.CASE_REASON), sdc.syncable);
        }
    }

    @TestVisible
    private Boolean processSimplifiedLBODownsell() {
        Boolean isDownsellCompleted = false;
        if (sdc.qt.quoteLineItems?.isEmpty() != false) {
            res.error(Response.STATUS_ERROR, MISSING_QUOTE_ERROR);
            return isDownsellCompleted;
        }

        List<QuoteLineItem> downsellQliList = SWNHelper.filterQuoteLineItems(SWNHelper.getDownsellQliList(sdc.qt.QuoteLineItems));
        Map<String, List<QuoteLineItem>> qliTypesMap = SWNHelper.getQliTypesForSimplifiedLBODownsell(sdc.qt, downsellQliList, sdc.costCenters);
        List<QuoteLineItem> qlisForAutoDownsell = SWNHelper.getQlisForAutoDownsell(qliTypesMap);

        return qlisForAutoDownsell.isEmpty()
            ? finishDownsell(false, qliTypesMap)
            : callDownsell(qlisForAutoDownsell, qliTypesMap);
    }

    @TestVisible
    private Boolean callDownsell(
        List<QuoteLineItem> qlisForAutoDownsell,
        Map<String, List<QuoteLineItem>> qliTypesMap
    ) {
        if (Test.isRunningTest()) {
            res.setData(SWNHelper.STATUS_PROP, Response.STATUS_SUCCESS);
            return false;
        }

        Response downsellResp = NGBSOrderRequest.callNGBSWithPreparedOrder(sdc, qlisForAutoDownsell, SWNStep.DOWN_SELL);
        return finishDownsell(handleDownsellResponse(downsellResp, qliTypesMap), qliTypesMap);
    }

    @TestVisible
    private Boolean finishDownsell(Boolean isDownsellCompleted, Map<String, List<QuoteLineItem>> qliTypesMap) {
        SWNHelper.createDownsellCase(sdc.qt, qliTypesMap, sdc.syncable);
       if(sdc.qt.ServiceName__c.equalsIgnoreCase(Constants.CONST_RC_EVENT)){
                SObject objectToUpdate = sdc.syncable.getSObjectToUpdate();
                Map<SObjectField, Object> sObjectFieldsToUpdate = sdc.syncable.getSObjFieldsToUpdate();
                objectToUpdate.put('DownsellStepStatus__c', true);
                update objectToUpdate;
        }
        return isDownsellCompleted;
    }

    @TestVisible
    private Boolean handleDownsellResponse(Response downsellResp, Map<String, List<QuoteLineItem>> qliTypesMap) {
        if (!downsellResp.isSuccess() || hasNoManualDownsellType(qliTypesMap)) {
            res.data = new Map<String, Object>();
            res.messages = new List<Response.ResponseMessage>();
            res.setData(downsellResp);
            return hasNoManualDownsellType(qliTypesMap);
        }
        return false;
    }

    @TestVisible
    private Boolean hasNoManualDownsellType(Map<String, List<QuoteLineItem>> qliTypesMap) {
        return qliTypesMap.get(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE)?.isEmpty() != false
            && qliTypesMap.get(SWNHelper.DOWNSELL_TYPE_MANUAL)?.isEmpty() != false
            && qliTypesMap.get(SWNHelper.DOWNSELL_TYPE_EXCEPTION)?.isEmpty() != false;
    }
}