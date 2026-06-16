public class SWNConvertToPaidRunner extends SWNActionRunner {
    @TestVisible
    private static final String PACKAGE_IS_NOT_CONVERTED = 'Package is not converted to Paid. Convert account to Paid before proceeding';

    public SWNConvertToPaidRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    protected override void run() {
        convertToPaid();
    }

    @TestVisible
    private void convertToPaid() {
        if (!SWNHelper.checkPaidStatus(sdc.ngbsPackage)) {
            handleException(
                Response.STATUS_ERROR,
                PACKAGE_IS_NOT_CONVERTED,
                CaseHelper.CASE_REASON_CONVERTED_TO_PAID,
                false
            );
        }
        isSkipFinalize = true;
    }
}