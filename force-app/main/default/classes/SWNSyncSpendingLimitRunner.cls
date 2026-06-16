public class SWNSyncSpendingLimitRunner extends SWNActionRunner {

    public SWNSyncSpendingLimitRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncSpendingLimit();
    }

    private void syncSpendingLimit() {
        Response spendingLimitsResult = processSpendingLimitRetrieve(sdc.qt, sdc.billingId, sdc.ngbsPackage?.id);
        sdc.currentStep.isStepCompletedSuccessfully = spendingLimitsResult.isSuccess();
        res.messages.addAll(spendingLimitsResult.messages);
    }

    private Response processSpendingLimitRetrieve(Quote qt, String billingId, String packageId) {
        Response resp = new Response();
        if (qt.Total_One_Time__c < 1) {
            return resp;
        }
        NGBSAPI.AccountPackageLimit currentSpendingLimit = CreditSpendingLimitNGBSSync.getCurrentSpendingLimit(qt.AccountId, billingId, packageId);
        Decimal newLimitvalue = currentSpendingLimit.value - qt.Total_One_Time__c;
        NGBSAPI.UpdateAccountPackageLimitData newLimit = new NGBSAPI.UpdateAccountPackageLimitData(
            NGBSAPI.MONTHLY_AMOUNT_LIMIT,
            newLimitvalue,
            currentSpendingLimit.exclusions
        );

        if (qt.Account.Account_Payment_Method__c == QuoteHelper.PAYMENT_METHOD_INVOICE) {
            newLimit.overrideData = new NGBSAPI.AccountPackageLimitOverrideData(currentSpendingLimit.limitOverride);
        }

        HttpResponse accPackageLimitResp = NGBSAPI.accountPackageLimitsIncrease(
            billingId,
            packageId,
            new List<NGBSAPI.UpdateAccountPackageLimitData> {newLimit}
        );
        if (accPackageLimitResp.getStatusCode() != 200) {
            resp.error('An error occured due to Sync Spending limits');
        } else {
            resp.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.SYNC_SPENDING_LIMIT_RETRIEVE_SUCCESS));
        }

        return resp;
    }
}