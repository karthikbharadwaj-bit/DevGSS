global with sharing class AccountUpdateBillingAddressNGBSSync extends QueueableBase {

    // Max scope 100 because AccountUpdateBillingAddressNGBSSync makes only one HTTP callout
    private final Integer MAX_SCOPE_SIZE = 100;
    private final String EMPTY_GST_NO = '';

    private Map<Id, String> syncErrorAccounts = new Map<Id, String>();
    private Map<Id, Account> accountsToSalesforceUpdate = new Map<Id, Account>();
    /* Tmp logs to write info about accounts which Billing Addresses should be updated in SF */
    private List<PlatformLog__c> platformLogs = new List<PlatformLog__c>();

    public override void execute(QueueableContext context) {
        for (Object item : getLocalScope(MAX_SCOPE_SIZE)) {
            Account acc = (Account) item;
            if (acc.Billing_ID__c != null) {
                syncBillingInfoWithNgbs(acc);
            } else {
                accountsToSalesforceUpdate.put(acc.Id, acc);
            }
            buildAccountInfoLog(acc.Id);
        }

        if (!platformLogs.isEmpty()) {
            PlatformLog.logResults(platformLogs);
        }

        if (!accountsToSalesforceUpdate.isEmpty()) {
            KycDetailsHelper.setAccountsForBillingAddressSync(accountsToSalesforceUpdate.keySet());
            update accountsToSalesforceUpdate.values();
        }
        if (!syncErrorAccounts.isEmpty()) {
            handleErrors();
        }
    }

    private Boolean syncBillingInfoWithNgbs(Account acc) {
        /* Firstly reset Gst No to update billing address with changed State */
        return syncGstNumberWithNgbs(acc.Id, acc.Billing_ID__c, EMPTY_GST_NO)
            && syncAccountBillingAddressNGBS(acc)
            && syncGstNumberWithNgbs(acc.Id, acc.Billing_ID__c, acc.VATNumber__c);
    }

    private Boolean syncGstNumberWithNgbs(Id accId, String billingId, String gstNo) {
        Boolean isSuccess = false;
        try {
            // https://jira.ringcentral.com/browse/PBC-7318
            // request was replaced with postTaxExemption, because we should set sezWopExemption param to false in NGBS also
            HttpResponse response = TaxExemptionHelper.postTaxExemption(billingId, false, false, false, false, false, false, false, null, null, gstNo);
            if (HttpHelper.isSuccess(response)) {
                isSuccess = true;
            } else {
                syncErrorAccounts.put(accId, (String) response.getBody());
            }
        } catch (Exception e) {
            syncErrorAccounts.put(accId, e.getMessage());
        }
        return isSuccess;
    }

    private Boolean syncAccountBillingAddressNGBS(Account acc) {
        Boolean isSuccess = false;
        try {
            HttpResponse response = NGBSAPI.updateAccountBillingAddress(acc);
            if (HttpHelper.isSuccess(response)) {
                accountsToSalesforceUpdate.put(acc.Id, acc);
                isSuccess = true;
            } else {
                syncErrorAccounts.put(acc.Id, response.getBody());
            }
        } catch (Exception e) {
            syncErrorAccounts.put(acc.Id, e.getMessage());
        }
        return isSuccess;
    }

    private void buildAccountInfoLog(Id accountId) {
        if (!this.accountsToSalesforceUpdate.isEmpty() && !this.accountsToSalesforceUpdate.keySet().contains(accountId)) {
            String message = 'Account ' + accountId + ' was not added for Billing Address in Salesforce update.';
            platformLogs.add(
                PlatformLog.buildLog(
                'AccountUpdateBillingAddressNGBSSync',
                message,
                null,
                null,
                null
                )
            );
        }
    }

    private void handleErrors() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Id accId : syncErrorAccounts.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    'AccountUpdateBillingAddressNGBSSync',
                    'Error occured during sync Billing Address on account: ' + accId,
                    syncErrorAccounts.get(accId),
                    null,
                    null
                )
            );
        }
        PlatformLog.logResults(logs);
    }
}