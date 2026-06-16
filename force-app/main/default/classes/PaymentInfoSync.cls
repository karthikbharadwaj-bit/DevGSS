public with sharing class PaymentInfoSync extends QueueableBase {

    public static final String SYNCED_PAYMENT_METHOD_ACCOUNT_ID = 'syncedPaymentMethodAccountId';
    public static final String SYNCED_LIMIT_ACCOUNT_ID = 'syncedLimitAccountId';

    public class PaymentInfoParams {
        public String ngbsAccountId;
        public String ngbsPackageId;
        public String accountId; // for log
        public String paymentMethod; // in case of null - get current payment in NGBS
        public Decimal limitValue; // in case of null - find corresponding approval based of paymentMethod
        public Quote qt;
        public Boolean isPOCBillingPackage;

        public PaymentInfoParams(String ngbsAccountId, String accountId, String paymentMethod, Decimal limitValue, Quote qt) {
            this.ngbsAccountId = ngbsAccountId;
            this.accountId = accountId;
            this.paymentMethod = paymentMethod;
            this.limitValue = limitValue;
            this.qt = qt;
        }
    }

    private final Integer MAX_SCOPE_SIZE = 20;

    @TestVisible
    private static final String ERROR_HEADER = 'PaymentInfoSync';

    @TestVisible
    private static final String ERROR_BODY = 'Error occured during payment method syncing to NGBS';

    private Map<String, String> errorMap = new Map<String, String>();
    private Set<Id> syncedPaymentMethodAccountId = new Set<Id>();
    private Set<Id> syncedLimitAccountId = new Set<Id>();

    public override void execute(QueueableContext context) {
        List<PaymentInfoParams> paramsList = new List<PaymentInfoParams>();
        for (Object item : getLocalScope(MAX_SCOPE_SIZE)) {
            paramsList.add((PaymentInfoParams) item);
        }

        for (PaymentInfoParams params : paramsList) {
            BillingWrappers.NGBSAccount accountInfo = getBillingAccount(params.ngbsAccountId);
            BillingWrappers.NGBSAccountPackage accountPackage = accountInfo.getPackage();
            params.isPOCBillingPackage = accountPackage.isPOC();
            params.ngbsPackageId = accountPackage.id;

            // Case when sync starts from trigger on close (only existing business)
            if (params.paymentMethod == null) {
                params.paymentMethod = QuoteHelper.getPaymentMethod(params.qt.Account, params.qt.Opportunity, params.qt, accountInfo, true);
            }
        }

        for (PaymentInfoParams params : paramsList) {
            syncPaymentInfo(params);
        }

        if (!errorMap.isEmpty()) {
            handleErrors();
        }

        if (!this.scope.isEmpty()) {
            enqueJob('QueueableBase.PaymentInfoSync', this.scope);
        }

        if (Test.isRunningTest()) {
            handleSuccessful();
        }
    }

    private BillingWrappers.NGBSAccount getBillingAccount(String ngbsAccountId) {
        BillingWrappers.NGBSAccount accountInfo;
        try {
            accountInfo = NGBSAPI.getNGBSAccount(ngbsAccountId);
        } catch (Exception ex) {
            errorMap.put(ngbsAccountId, ex.getMessage());
        }
        return accountInfo;
    }

    private Boolean isNeedToSyncPaymentMethod(PaymentInfoParams params) {
        return params.isPOCBillingPackage && (QuoteHelper.isDirectDebit(params.paymentMethod) || QuoteHelper.isCreditCard(params.paymentMethod));
    }

    private Boolean isNeedToSyncPaymentLimit(PaymentInfoParams params) {
        try {
            if (params.isPOCBillingPackage) {
                return params.qt == null ? true : QuoteHelper.isDirectDebit(params.paymentMethod);
            } else {
                String billingAccountPaymentMethod = NGBSAPI.getBillingAccountPaymentMethod(params.NGBSAccountId);
                return QuoteHelper.isDirectDebit(billingAccountPaymentMethod);
            }
        } catch (Exception ex) {
            errorMap.put(params.accountId, ex.getMessage());
        }
        return false;
    }

    private Decimal getLimit(PaymentInfoParams params) {
        if (QuoteHelper.isDirectDebit(params.paymentMethod)) {
            return ApprovalHelper.getDirectDebitLimit(params.accountId, params.qt);
        }
        return null;
    }

    private void syncPaymentInfo(PaymentInfoParams params) {
        Response res = new Response();

        // #1
        if (isNeedToSyncPaymentMethod(params)) {
            res = syncIntendedPaymentMethod(params);
            if (res.isSuccess()) {
                syncedPaymentMethodAccountId.add(params.accountId);
            }
        }

        // #2
        if (res.isSuccess() && isNeedToSyncPaymentLimit(params)) {
            res = syncPaymentLimit(params);
            if (res.isSuccess()) {
                syncedLimitAccountId.add(params.accountId);
            }
        }

        // log #1 || #2
        if (!res.isSuccess()) {
            errorMap.put(params.accountId, res.messages.get(0).message);
        }
    }

    private Response syncIntendedPaymentMethod(PaymentInfoParams params) {
        Response res = new Response();
        try {
            Boolean isPaymentMethodUpdated = NGBSAPI.setIntendedPaymentMethod(params.ngbsAccountId, params.paymentMethod);
            if (!isPaymentMethodUpdated) {
                res.error('Failed to set intended payment method');
            }
        } catch (Exception ex) {
            res.error(ex);
            errorMap.put(params.accountId, ex.getMessage());
        }
        return res;
    }

    private Response syncPaymentLimit(PaymentInfoParams params) {
        Response res = new Response();
        try {
            Decimal limitValue = params.limitValue;
            if (limitValue == null) {
                limitValue = getLimit(params);
            }
            Boolean isPaymentLimitsUpdated = NGBSAPI.updatePaymentLimits(
                params.ngbsAccountId,
                params.ngbsPackageId,
                limitValue
            );

            if (!isPaymentLimitsUpdated) {
                res.error('Failed to update payment limits');
            }
        } catch (Exception ex) {
            res.error(ex);
            errorMap.put(params.accountId, ex.getMessage());
        }
        return res;
    }

    private void handleSuccessful() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Id accountId : syncedPaymentMethodAccountId) {
            logs.add(PlatformLog.buildLog(SYNCED_PAYMENT_METHOD_ACCOUNT_ID, accountId, null, null, null));
        }
        for (Id accountId : syncedLimitAccountId) {
            logs.add(PlatformLog.buildLog(SYNCED_LIMIT_ACCOUNT_ID, accountId, null, null, null));
        }
        PlatformLog.logResults(logs);
    }

    private void handleErrors() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (String accountId : errorMap.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    ERROR_HEADER,
                    ERROR_BODY + ': ' + accountId,
                    errorMap.get(accountId),
                    null,
                    null
                )
            );
        }

        PlatformLog.logResults(logs);
    }
}