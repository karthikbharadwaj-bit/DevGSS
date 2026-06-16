public with sharing class ProServDiscountsHelper {
    public static void syncProServDiscounts(Map<Id, String> oppIdToBillingPackageId) {
        List<Quote> proservQuotes = (List<Quote>) new QuoteSelector()
                .selectTechProservQuoteForSyncDiscounts(oppIdToBillingPackageId.keySet())
                .executeQuery();

        if (proservQuotes.isEmpty()) {
            createPlatformLog('Technical Proserv Quote is not available', '');
            return;
        }

        try {
            for (Quote proservQuote : proservQuotes) {
                syncProServDiscount(proservQuote, oppIdToBillingPackageId.get(proservQuote.OpportunityId));
            }
        } catch (Exception e) {
            createPlatformLog(e.getMessage(), 'ErrorMessage: ' + e.getMessage() + ' StackTrace: ' + e.getStackTraceString());
        }
    }

    @TestVisible
    private static void createPlatformLog(String errorText, String stackTrace) {
        Platformlog.logResult(
            'ProcessProservDiscountsSync',
            errorText,
            stackTrace,
            null,
            null,
            false);
    }

    public static void syncProServDiscount(Quote proservQuote, String billingPackageId) {
        SWNActionRunner runner = new SWNProServSyncDiscountRunner(
            proservQuote.Id,
            SWNStep.DISCOUNT_SYNC,
            proservQuote.Account.Billing_ID__c,
            billingPackageId
        );
        runner.sync();
    }
}