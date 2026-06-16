global with sharing class AccountPartnerPaymentMethodNGBSSync extends QueueableBase {

    private final Integer MAX_SCOPE_SIZE = 20;
    private Map<Account, String> syncErrorAccounts = new Map<Account, String>();
    private Set<Account> syncSuccessAccounts = new Set<Account>();

    public override void execute(QueueableContext context) {
        List<Account> accountsToProcess = new List<Account>();
        List<Id> partnerAccountIds = new List<Id>();
        Map<String, List<Object>> agrumentsMap = (Map<String, List<Object>>) getLocalScope(MAX_SCOPE_SIZE)[0];
        List<Account> accounts = (List<Account>) agrumentsMap.get('accounts');
        for (Account acc : accounts) {
            accountsToProcess.add(acc);
            if (acc.Partner_Account__c != null) {
                partnerAccountIds.add(acc.Partner_Account__c);
            }
        }

        Map<Id, Account> partnerAccMap = new Map<Id, Account>((List<Account>) new AccountSelector()
            .selectAccountsByIds(new List<Object>{partnerAccountIds})
            .executeQuery());

        for (Account a : accountsToProcess) {
            syncAccountPaymentMethodNGBS(a, partnerAccMap.get(a.Partner_Account__c));
        }

        if (!syncErrorAccounts.isEmpty()) {
            handleErrors();
        }

        if (!this.scope.isEmpty()) {
            enqueJob('AccountPartnerPaymentMethodNGBSSync', this.scope);
        }
    }

    private void syncAccountPaymentMethodNGBS(Account acc, Account partnerAcc) {
        Quote primaryQuote = !acc.Quotes__r.isEmpty() ? acc.Quotes__r[0] : null;
        AccountContactRole primaryContactRole = !acc.AccountContactRoles.isEmpty() ? acc.AccountContactRoles[0] : null;
        try{
            System.debug('acc' + acc);
            HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(acc, primaryContactRole, partnerAcc, primaryQuote, null);
            Boolean needToUpdatePaymentMethod = paymentMethodResp != null;
            if (!needToUpdatePaymentMethod || (needToUpdatePaymentMethod && paymentMethodResp.getStatusCode() == 200)) {
                syncSuccessAccounts.add(acc);
            }
        } catch (Exception e) {
            syncSuccessAccounts.remove(acc);
            syncErrorAccounts.put(acc, e.getMessage());
        }
    }

    private void handleErrors() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Account acc : syncErrorAccounts.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    'AccountPartnerPaymentMethodNGBSSync',
                    'Error occured during Payment Method update to Invoice On Behalf on account: ' + acc.Id,
                    syncErrorAccounts.get(acc),
                    null,
                    null
                )
            );
        }

        PlatformLog.logResults(logs);
    }
}