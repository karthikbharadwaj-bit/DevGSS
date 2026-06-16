global with sharing class AccountPayableRolesNGBSSync extends QueueableBase {

    private final Integer MAX_SCOPE_SIZE = 20;
    private Map<Approval__c, String> syncErrorApprovals = new Map<Approval__c, String>();

    public override void execute(QueueableContext context) {
        List<Approval__c> approvalsToProcess = new List<Approval__c>();

        for (Object item : getLocalScope(MAX_SCOPE_SIZE)) {
            approvalsToProcess.add((Approval__c) item);
        }

        List<Id> accIds = new List<Id>();
        List<Id> paymentContactIds = new List<Id>();
        for (Approval__c ap : approvalsToProcess) {
            accIds.add(ap.Account__c);
            paymentContactIds.add(ap.AccountPayableContact__c);
        }

        Map<Id, Account> accountRecords = new Map<Id, Account>((List<Account>) new AccountSelector()
        .selectAccountsByIds(new List<Object>{accIds})
        .executeQuery());

        List<Object> bindings = new List<Object>();
        bindings.add(paymentContactIds);
        Map<Id, Contact> contactRecords = new Map<Id, Contact>((List<Contact>) new ContactSelector()
        .selectContactsByIds(bindings).executeQuery());

        for (Approval__c ap : approvalsToProcess) {
            try{
                Contact payableContact = contactRecords.get(ap.AccountPayableContact__c);
                HttpResponse paymentContactResp = NGBSAPI.updateAccountPaymentContact(accountRecords.get(ap.Account__c), contactRecords.get(ap.AccountPayableContact__c));
                Boolean ngbsSuccess = paymentContactResp != null && paymentContactResp.getStatusCode() == 200;
                if (!ngbsSuccess) {
                    syncErrorApprovals.put(ap, 'Cannot export AccountPayableContact to NGBS');
                }
            } catch (Exception e) {
                syncErrorApprovals.put(ap, e.getMessage());
            }
        }

        if (!syncErrorApprovals.isEmpty()) {
            handleErrors();
        }
    }

    private void handleErrors() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Approval__c ap : syncErrorApprovals.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    'AccountPayableRolesNGBSSync',
                    'Error occured during Account Payer Role export to NGBS: ' + ap.Id,
                    syncErrorApprovals.get(ap),
                    null,
                    null
                )
            );
        }
        PlatformLog.logResults(logs);
    }
}