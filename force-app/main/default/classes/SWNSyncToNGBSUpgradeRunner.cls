public class SWNSyncToNGBSUpgradeRunner extends SWNActionRunner {

    public SWNSyncToNGBSUpgradeRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        if (SWNHelper.isPackageEqual(sdc.ngbsAcc, sdc.qt)) {
            res.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.UPGRADE_SYNC_SUCCESS));
            return;
        }

        if (!Test.isRunningTest()) {
            res = NGBSOrderRequest.callNGBSWithPreparedOrder(sdc.qt, sdc.opp.Id, sdc.qlis, sdc.billingId, SWNStep.UPGRADE, sdc.ngbsPackage);
        } else {
            res.setData(SWNHelper.STATUS_PROP, Response.STATUS_SUCCESS);
        }
        if (res.isSuccess() && SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedDownsellForRingCC__c) {
            SWNHelper.createDownsellCase(sdc);
        }
        sdc.currentStep.isStepCompletedSuccessfully = res.isSuccess();
    }
}