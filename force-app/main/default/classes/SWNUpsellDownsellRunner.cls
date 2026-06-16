public with sharing class SWNUpsellDownsellRunner extends SWNActionRunner{
    @TestVisible
    private static final String REDIRECT_URL = 'redirectUrl';
    @TestVisible
    private static final List<String> CCB_SYNC_ACTIONS = new List<String> { SWNStep.SYNC_TO_CCB_DOWNSELL, SWNStep.SYNC_TO_CCB_UPSELL };
    @TestVisible
    private static final List<String> DOWNSELL_ACTIONS = new List<String> { SWNStep.SYNC_TO_CCB_DOWNSELL, SWNStep.SYNC_TO_NGBS_DOWNSELL };

    public SWNUpsellDownsellRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncUpsellOrDownsell();
        createDownsellCase();
    }

    private void syncUpsellOrDownsell() {
        if (isSyncedStatus()) {
            res.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.LICENSE_QUANTITY_SYNCED));
            return;
        }

        String quoteType = isDownsell() ? SWNStep.DOWN_SELL : SWNStep.UP_SELL;

        if (isSyncToCCB()) {
            syncToCCB(quoteType);
            return;
        }
        syncToNGBS(quoteType);
    }

    private void syncToCCB(String quoteType) {
        res = SWNSyncCCBHelper.syncCCB(sdc.qt, quoteType, sdc.isMPUB, sdc.costCenters);
        sdc.currentStep.isStepCompletedSuccessfully = isSyncToCCBStepCompleted();
    }

    private void syncToNGBS(String quoteType) {
        if (!Test.isRunningTest()) {
            res = NGBSOrderRequest.callNGBSWithPreparedOrder(sdc.qt, sdc.opp.Id, sdc.qlis, sdc.billingId, quoteType, sdc.ngbsPackage);
        } else {
            res.setData(SWNHelper.STATUS_PROP, Response.STATUS_SUCCESS);
        }

        sdc.currentStep.isStepCompletedSuccessfully = res.isSuccess();
    }

    private Boolean isSyncedStatus() {
        return SWNHelper.checkSyncQtyStatus(sdc.billingId, sdc.ngbsPackage?.id, getFilteredQliList());
    }

    @TestVisible
    private Boolean isSyncToCCBStepCompleted() {
        if (POHelper.isMultiproductEnabled && POHelper.isEngageUILessSettingsOn) {
            return res.isSuccess();
        }
        return QuoteLineItemHelper.isOnlyOneTime(getFilteredQliList()) 
            && String.isNotBlank((String) res.getData(REDIRECT_URL));
    }

    @TestVisible
    private void createDownsellCase() {
        Boolean isFeatureToggleEnabled = isSyncToCCB() 
            ? SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedDownsellForRingCX__c 
            : SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedDownsellForRingCC__c;
            
        if (res.isSuccess() && isDownsell() && isFeatureToggleEnabled) {
            SWNHelper.createDownsellCase(sdc);
        }
    }

    @TestVisible
    private List<QuoteLineItem> getFilteredQliList() {
        return isDownsell()
            ? SWNHelper.getDownsellQliList(sdc.qlis)
            : SWNHelper.getUpsellQliList(sdc.qlis);
    }

    @TestVisible
    private Boolean isDownsell() {
        return DOWNSELL_ACTIONS.contains(sdc.action);
    }

    @TestVisible
    private Boolean isSyncToCCB() {
        return CCB_SYNC_ACTIONS.contains(sdc.action);
    }
}