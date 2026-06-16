public class SWNSyncChargeTermRunner extends SWNActionRunner {

    public SWNSyncChargeTermRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncChargeTerm();
    }

    private void syncChargeTerm() {
        if (SWNHelper.isPackagePlanEqual(sdc.ngbsAcc, sdc.qt)) {
            res.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.CHARGE_TERM_SYNCED));
            return;
        }

        if (!Test.isRunningTest()) {
            res = NGBSOrderRequest.callNGBSWithPreparedOrder(sdc.qt, sdc.opp.Id, sdc.qlis, sdc.billingId, SWNStep.CHARGE_TERM_SYNC, sdc.ngbsPackage);
        } else {
            res.setData(SWNHelper.STATUS_PROP, Response.SEVERITY_SUCCESS);
        }
        sdc.currentStep.isStepCompletedSuccessfully = res.isSuccess();
    }
}