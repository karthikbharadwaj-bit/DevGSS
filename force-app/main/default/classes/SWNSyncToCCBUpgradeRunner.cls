public class SWNSyncToCCBUpgradeRunner extends SWNActionRunner {
        
    public SWNSyncToCCBUpgradeRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        if (SWNHelper.checkUpgradeCCBStatus(sdc.qt, sdc.ngbsAcc)) {
            res.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.UPGRADE_SYNC_SUCCESS));
            return;
        }

        res = SWNSyncCCBHelper.syncCCB(sdc.qt, SWNStep.UPGRADE, sdc.isMPUB, sdc.costCenters);
        if (res.isSuccess() && SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedDownsellForRingCX__c) {
            SWNHelper.createDownsellCase(sdc);
        }
        sdc.currentStep.isStepCompletedSuccessfully = res.isSuccess();
    }
}