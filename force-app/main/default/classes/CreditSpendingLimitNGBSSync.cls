global with sharing class CreditSpendingLimitNGBSSync extends QueueableBase {
    public static final String SUCCESS_TEXT = 'Success';
    public static final String ERROR_START_TEXT = 'Error: ';
    private final Integer MAX_SCOPE_SIZE = 20;
    private Map<Id, String> NGBSUpdateStatus = new Map<Id, String>();
    private Map<Id, Account> accountsById = new Map<Id, Account>();

    public override void execute(QueueableContext context) {
        List<Approval__c> approvalsToProcess = new List<Approval__c>();
        List<Approval__c> approvalsForUpdate = new List<Approval__c>();
        List<Account> accountsToProcess = new List<Account>();
        Set<Id> approvalIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, NGBSAPI.AccountPackageLimit> currLimits = new Map<Id, NGBSAPI.AccountPackageLimit>();

        for (Object item : getLocalScope(MAX_SCOPE_SIZE)) {
            approvalIds.add((Id) item);
        }

        // 1 - get approval list
        if (!approvalIds.isEmpty()) {
            approvalsToProcess = (List<Approval__c>) new ApprovalSelector()
                .selectCreditLimitIncreaseById(new List<Object>{approvalIds})
                .executeQuery();
        }

        // 2 - get accountIds
        for (Approval__c app: approvalsToProcess) {
            accountIds.add(app.Account__c);
        }

        // 3 - get accounts by approvals
        if (!accountIds.isEmpty()) {
            accountsToProcess = (List<Account>) new AccountSelector()
                .selectAccountsForApproval(new List<Object>{accountIds})
                .executeQuery();
        }

        // 4 - get Current Spending Limits for accounts
        for (Account acc: accountsToProcess) {
            accountsById.put(acc.Id, acc);
            currLimits.put(acc.Id, getCurrentSpendingLimit(acc.Id, acc.Billing_ID__c, acc.Service_Accounts__r != null && !acc.Service_Accounts__r.isEmpty() ? acc.Service_Accounts__r[0].Account_Package_Id__c : null));
        }

        // 5 - Process Approvals
        for (Approval__c app: approvalsToProcess) {
            NGBSAPI.AccountPackageLimit currentSpendingLimit = currLimits.get(app.Account__c);
            if (app.Status__c == ApprovalHelper.STATUS_APPROVED && app.NGBSSyncInfo__c != SUCCESS_TEXT) {
                // Increase Spending Limit
                Account acc = accountsById.get(app.Account__c);
                approvalsForUpdate.add(app);
                if (currentSpendingLimit == null || currentSpendingLimit.value != app.NGBSCurrentSpendingLimit__c) {
                    NGBSUpdateStatus.put(app.Id, ERROR_START_TEXT + 'Current Spending Limit from NGBS not equal Current Spending Limit from Approval');
                } else if (acc.Account_Payment_Method__c == null || acc.Account_Payment_Method__c.deleteWhitespace() != currentSpendingLimit.paymentType.deleteWhitespace()) {
                    NGBSUpdateStatus.put(app.Id, ERROR_START_TEXT + 'Payment Method from NGBS not equal Payment Method from SF Account');
                } else {
                    increaseSpendingLimit(app, acc, currentSpendingLimit);
                }
            }
        }

        if (!approvalsForUpdate.isEmpty()) {
            updateNGBSStatusInfo(approvalsToProcess);
        }

        if (!this.scope.isEmpty()) {
            enqueJob('CreditSpendingLimitNGBSSync', this.scope);
        }
    }

    public static NGBSAPI.AccountPackageLimit getCurrentSpendingLimit(Id accId, String billingId, String packageId) {
        if (!String.isBlank(accId) && !String.isBlank(billingId) && !String.isBlank(packageId)) {
            try {
                List<NGBSAPI.AccountPackageLimit> limits = NGBSAPI.getAccountPackageLimits(
                    billingId,
                    packageId
                );
                for (NGBSAPI.AccountPackageLimit lim : limits) {
                    if (lim.code == NGBSAPI.MONTHLY_AMOUNT_LIMIT) {
                        if (lim.paymentType == null) {
                            NGBSAPI.PaymentMethodTypeHistory paymentTypeObj = NGBSAPI.getAccountPaymentType(billingId);
                            if (paymentTypeObj != null && String.isNotEmpty(paymentTypeObj.currentType)) {
                                lim.paymentType = paymentTypeObj.currentType;
                            }
                        }
                        return lim;
                    }
                }
            } catch (Exception e) {
                ObjectMonitoringHelper.createObjectMonitoring(accId, CreditSpendingLimitNGBSSync.class.getName(), '', '', '', String.valueOf(System.UserInfo.getUserId()), 'getCurrentSpendingLimit', e.getStackTraceString());
                return null;
            }
        } else {
            ObjectMonitoringHelper.createObjectMonitoring(accId, CreditSpendingLimitNGBSSync.class.getName(), '', '', '', String.valueOf(System.UserInfo.getUserId()), 'getCurrentSpendingLimit', 'Service account not found');
        }
        return null;
    }

    private void increaseSpendingLimit(Approval__c app, Account acc, NGBSAPI.AccountPackageLimit currentSpendingLimit) {
        try {
            NGBSAPI.UpdateAccountPackageLimitData newLimit = getNewLimit(app, currentSpendingLimit);

            // update spending limit depends on Account.Payment_Method__c
            if (acc.Account_Payment_Method__c == QuoteHelper.PAYMENT_METHOD_INVOICE
                && currentSpendingLimit.limitOverride != null) {
                newLimit.overrideData = new NGBSAPI.AccountPackageLimitOverrideData(currentSpendingLimit.limitOverride);
            }

            NGBSAPI.accountPackageLimitsIncrease(
                acc.Billing_ID__c,
                acc.Service_Accounts__r[0].Account_Package_Id__c,
                new List<NGBSAPI.UpdateAccountPackageLimitData>{newLimit}
            );

            NGBSUpdateStatus.put(app.Id, SUCCESS_TEXT);
        } catch (Exception e) {
            NGBSUpdateStatus.put(app.Id, ERROR_START_TEXT + e.getMessage());
            if(!Test.isRunningTest()) {
                ObjectMonitoringHelper.createObjectMonitoring(
                    app.Id,
                    Approval__c.class.getName(),
                    '',
                    '',
                    '',
                    UserInfo.getUserId(),
                    'CreditSpendingLimitNGBSSync Failed: ' + e.getMessage()
                );
            }
        }
    }

    @TestVisible
    private static NGBSAPI.UpdateAccountPackageLimitData getNewLimit(Approval__c app, NGBSAPI.AccountPackageLimit currentSpendingLimit) {
        Decimal newSpendingLimit = app.NGBSCurrentSpendingLimit__c + 2 * app.NGBSAmountToIncrease__c;

        return new NGBSAPI.UpdateAccountPackageLimitData(
            NGBSAPI.MONTHLY_AMOUNT_LIMIT,
            newSpendingLimit,
            currentSpendingLimit.exclusions
        );
    }

    private void updateNGBSStatusInfo(List<Approval__c> approvals) {
        List<Approval__c> approvalsToUpdate = new List<Approval__c>();
        for (Approval__c app : approvals) {
            if (app.Status__c == ApprovalHelper.STATUS_APPROVED) {
                String statusStr = NGBSUpdateStatus.get(app.Id);
                if (!String.isEmpty(statusStr)) {
                    app.NGBSSyncInfo__c = statusStr.replace('<br>', '\\n');
                } else {
                    app.NGBSSyncInfo__c = '';
                }
                approvalsToUpdate.add(app);
                if (statusStr.startsWith(ERROR_START_TEXT)) {
                    DealDeskCaseGenerator.createDealDeskCaseApprovalNGBSAPIException(
                        app,
                        accountsById.get(app.Account__c),
                        'Increase Spending Limit don\'t sync with NGBS.'
                    );
                }
            }
        }
        if (!approvalsToUpdate.isEmpty()) {
            Triggers.switchOff();
            update approvalsToUpdate;
            Triggers.switchOn();
        }
    }
}