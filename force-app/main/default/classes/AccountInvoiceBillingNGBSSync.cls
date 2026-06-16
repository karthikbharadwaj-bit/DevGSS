global with sharing class AccountInvoiceBillingNGBSSync extends QueueableBase {

    private final Integer MAX_SCOPE_SIZE = 20;
    private Map<Account, String> syncErrorAccounts = new Map<Account, String>();
    private Set<Account> syncSuccessAccounts = new Set<Account>();
    private static final Feature_Toggle__c FEATURE_TOGGLE = Feature_Toggle__c.getInstance();

    public override void execute(QueueableContext context) {
        List<Account> accountsToProcess = new List<Account>();
        Set<Id> accountIds = new Set<Id>();
        Map<String, List<Object>> agrumentsMap = (Map<String, List<Object>>) getLocalScope(MAX_SCOPE_SIZE)[0];
        List<Account> accounts = (List<Account>) agrumentsMap.get('accounts');
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        List<Approval__c> approvals = (List<Approval__c>) agrumentsMap.get('approvals');

        accountsToProcess = (List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{accountIds})
            .executeQuery();
        Map<String, Account> accountsToProcessMap = new Map<String, Account>();
        for (Account acc : accountsToProcess) {
            accountsToProcessMap.put(acc.Id, acc);
        }
        List<Object> bindings = new List<Object>();
        bindings.add(accountIds);
        List<AccountContactRole> primaryAcrList = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectPrimaryAccountContactRolesByAccountIds(bindings)
            .executeQuery();

        Approval__c masterApproval;
        for (Approval__c approval : approvals) {
            masterApproval = !approval.IsMultiProductTechnicalApproval__c ? approval : approval.MasterApproval__r;
            break;
        }

        String opportunityId = masterApproval?.Opportunity__c;
        List<Quote> primaryQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByOppIdsWithServiceInfos(new List<Object> {opportunityId})
            .executeQuery();
            
        Map<Id, AccountContactRole> mapAccountContactRoles = new Map<Id, AccountContactRole>();
        for (AccountContactRole acr : primaryAcrList) {
            mapAccountContactRoles.put(acr.Account.Id, acr);
        }

        for (Account a : accountsToProcess) {
            syncAccountInvoiceNGBS(a, mapAccountContactRoles.get(a.Id), masterApproval, accountsToProcess, accountsToProcessMap, primaryQuotes);          
        }       

        if (!syncSuccessAccounts.isEmpty()) {
            updatePaymentMethod();
        }

        if (!syncErrorAccounts.isEmpty()) {
            handleErrors();
        }

        if (!this.scope.isEmpty()) {
            enqueJob('AccountInvoiceBillingNGBSSync', this.scope);
        }
    }

    private void syncAccountInvoiceNGBS(
        Account acc,
        AccountContactRole primaryContactRole,
        Approval__c masterApproval,
        List<Account> accountsToProcess,
        Map<String, Account> accountsToProcessMap,
        List<Quote> primaryQuotes
    ) {
        try {
            HttpResponse paymentMethodResp = NGBSAPI.updateAccountPaymentMethod(acc, primaryContactRole, null, null, null);
            Boolean needToUpdatePaymentMethod = paymentMethodResp != null;
            if (!needToUpdatePaymentMethod || (needToUpdatePaymentMethod && paymentMethodResp.getStatusCode() == 200)) {
                syncSuccessAccounts.add(acc);
            }
            if (!acc.IsMultiProductTechnicalAccount__c) {
                Boolean isSingleProduct = primaryQuotes.size() == 1 || !isQuotePackageInfoHasMultipleProducts(primaryQuotes);

                syncInvoiceLimitsNGBS(masterApproval, accountsToProcess, accountsToProcessMap, primaryQuotes);
                syncPackageConsolidationSettings(acc, isSingleProduct);
            }
       }
        catch (Exception e) {
            syncSuccessAccounts.remove(acc);
            syncErrorAccounts.put(acc, e.getMessage());
        }
    }

    @TestVisible
    private Boolean isQuotePackageInfoHasMultipleProducts(List<Quote> allQuotes) {
        Quote primaryQuote = QuoteHelper.getPrimaryQuote(allQuotes, true);
        return primaryQuote != null && QuoteHelper.isQuotePackageInfoHasMultipleProducts(primaryQuote);
    }

    private void syncInvoiceLimitsNGBS(
        Approval__c masterApproval,
        List<Account> accountsToProcess,
        Map<String, Account> accountsToProcessMap,
        List<Quote> primaryQuotes
    ) {
        Boolean isMPUBEnabled = FEATURE_TOGGLE.EnableMultiProductUnifiedBilling__c;    
        List<Quote> quotesToProceed = new List<Quote>();
        if (primaryQuotes.size() > 1) {
            for (Quote qt: primaryQuotes) {
                if (qt.IsMultiProductTechnicalQuote__c) {
                    quotesToProceed.add(qt);
                }
            }
        } else {
            quotesToProceed.addAll(primaryQuotes);
        }
        for (Quote qt : quotesToProceed) {
            ServiceInfo__c serviceInfo = !qt.ServiceInfo__r.isEmpty() ? qt.ServiceInfo__r : null;
            Account acc = serviceInfo != null ? accountsToProcess[0] : accountsToProcessMap.get(qt.AccountId);
            Package__c billingPackage = serviceInfo != null 
                ? serviceInfo.BillingPackage__r 
                : acc.Service_Accounts1__r != null && !acc.Service_Accounts1__r.isEmpty() 
                    ? acc.Service_Accounts1__r[0] 
                    : null;
            Map<String, Decimal> approvedPackageLimitsMap = ApprovalHelper.getApprovedPackageLimitsMap(qt, masterApproval);
            Decimal monthlyCreditLimit = approvedPackageLimitsMap.get('MonthlyCreditLimitC');
            if (billingPackage != null) {
                HttpResponse limitOverrideResp = isMPUBEnabled
                        ? NGBSAPI.updateAccountPackageLimits(acc, billingPackage, monthlyCreditLimit)
                        : NGBSAPI.updateAccountPackageLimits(acc, billingPackage);
            }
        }        
    }

    private void syncPackageConsolidationSettings(Account acc, Boolean isSingleProduct) {
        HttpResponse resp = NGBSAPI.syncPackageConsolidationSettings(acc, isSingleProduct);
        if (resp == null) {
            return;
        } 
        if (resp.getStatusCode() == 200) {
            syncSuccessAccounts.add(acc);
        } else {
            syncErrorAccounts.put(acc, 'An error occured due to package consolidation settings sync');
        }
    }

    private void updatePaymentMethod() {

        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : syncSuccessAccounts) {
            if (acc.Account_Payment_Method__c == AccountHelper.PAYMENT_METHOD_INVOICE) {
                continue;
            }
            acc.Account_Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
            accountsToUpdate.add(acc);
        }
        update accountsToUpdate;
    }

    private void handleErrors() {
        List<PlatformLog__c> logs = new List<PlatformLog__c>();
        for (Account acc : syncErrorAccounts.keySet()) {
            logs.add(
                PlatformLog.buildLog(
                    'AccountInvoiceBillingNGBSSync',
                    'Error occured during Payment Method update to Invoice on account: ' + acc.Id,
                    syncErrorAccounts.get(acc),
                    null,
                    null
                )
            );
        }

        PlatformLog.logResults(logs);
    }
}