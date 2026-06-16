public class SWNUpsellRunner extends SWNActionRunner {

    public SWNUpsellRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        upsell();
    }

    private void upsell() {
        if (!QuoteHelper.isPhoenix(sdc.qt)) {
            return;
        }
        res = SWNHelper.getStopSync(sdc.action, sdc.qt, sdc.billingId, sdc.ngbsAcc);
        if (BooleanHelper.toBoolean(res.data.get(SWNHelper.STOP_AUTO_SYNC))) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
            DealDeskCaseGenerator.createCase(sdc.qt, sdc.opp, false, (String) res.data.get(SWNHelper.CASE_REASON), sdc.syncable);
        }
    }
}