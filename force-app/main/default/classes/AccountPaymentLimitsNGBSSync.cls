global with sharing class AccountPaymentLimitsNGBSSync extends QueueableBase {

    private final Integer MAX_SCOPE_SIZE = 20;
    private Map<Account, String> syncErrorAccounts = new Map<Account, String>();

    public override void execute(QueueableContext context) {
        List<Account> accountsToProcess = new List<Account>();
        Set<Id> accountIds = new Set<Id>();
        for (Object item : getLocalScope(MAX_SCOPE_SIZE)) {
            Account acc = (Account) item;
            accountIds.add(acc.Id);
        }

        accountsToProcess = (List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{accountIds})
            .executeQuery();

        for (Account a : accountsToProcess) {
            syncPaymentLimitsNGBS(a);
        }

        if (!syncErrorAccounts.isEmpty()) {
            handleErrors();
        }

        if (!this.scope.isEmpty()) {
            enqueJob('AccountPaymentLimitsNGBSSync', this.scope);
        }
    }

    private void syncPaymentLimitsNGBS(Account acc) {
        try{
            if (acc.Service_Accounts__r != null && !acc.Service_Accounts__r.isEmpty()) {
                HttpResponse limitOverrideResp = NGBSAPI.updateAccountPackageLimits(acc, acc.Service_Accounts__r[0]);
                if (limitOverrideResp.getStatusCode() != 200) {
                    syncErrorAccounts.put(acc, 'An error occured due to limits sync');
                }    
            }
        } catch (Exception e) {
            syncErrorAccounts.put(acc, e.getMessage());
        }
    }

    private void handleErrors() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Account acc : syncErrorAccounts.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    'AccountPaymentLimitsNGBSSync',
                    'Error occured during Payment Limits update on account: ' + acc.Id,
                    syncErrorAccounts.get(acc),
                    null,
                    null
                )
            );
        }

        PlatformLog.logResults(logs);
    }
}