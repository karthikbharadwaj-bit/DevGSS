public class SWNUpgradeRunner extends SWNActionRunner {
    @TestVisible
    private static final String UPGRADE_ERROR = 'Please change package on the Account before marking \'Upgrade\' step as completed';

    public SWNUpgradeRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        upgradeProcess();
    }

    private void upgradeProcess() {
        if (SWNHelper.isLBOOrOfficeProductSelected(sdc.qt) || QuoteHelper.isPhoenix(sdc.qt)) {
            res = SWNHelper.getStopSync(sdc.action, sdc.qt, sdc.billingId, sdc.ngbsAcc);
            if (BooleanHelper.toBoolean(res.data.get(SWNHelper.STOP_AUTO_SYNC))) {
                sdc.currentStep.isStepCompletedSuccessfully = false;
                DealDeskCaseGenerator.createCase(sdc.qt, new Opportunity(), false, (String) res.data.get(SWNHelper.CASE_REASON), sdc.syncable);
            }
            return;
        }

        if (SWNHelper.checkUpgradeStatus(sdc.ngbsPackage, sdc.qt)) {
            return;
        }

        sdc.currentStep.isStepCompletedSuccessfully = false;
        res.error(UPGRADE_ERROR);
    }
}