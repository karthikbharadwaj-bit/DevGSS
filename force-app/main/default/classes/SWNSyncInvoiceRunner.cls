public class SWNSyncInvoiceRunner extends SWNActionRunner {
    private static final String PAYMENT_CONTACT = 'paymentContact';
    private static final String MONTHLY_CREDIT_LIMIT = 'MonthlyCreditLimitC';
    @TestVisible
    private static final String LIMIT_OVERRIDE = 'limitOverride';
    @TestVisible
    private static final String PKG_CONSOLIDATION_SETTINGS = 'packageConsolidationSettings';
    @TestVisible
    private static final String NOT_APPROVED_APPROVAL_ERROR = 'There is not an Approved Approval on the Account';
    @TestVisible
    private static final String CONTACT_SYNC_ERROR = 'An error occured due to contact sync';
    @TestVisible
    private static final String INVOICE_PAYMENT = 'invoicePayment';
    @TestVisible
    private static final String NGBS_ERROR = 'NGBS error:';
    @TestVisible
    private static final String PAYMENT_METHOD_FAILED = 'Payment method verification failed';
    @TestVisible
    private static final String PAYMENT_METHOD_NOT_FOUND = 'Account or payment method not found';
    @TestVisible
    private static final String INVOICE_SYNC_ERROR = 'An error occured due to invoice sync';
    @TestVisible
    private static final String LIMITS_SYNC_ERROR = 'An error occured due to limits sync';
    @TestVisible
    private static final String PKG_CONSOLIDATION_SETTINGS_SYNC_ERROR = 'An error occured due to package consolidation settings sync';

    @TestVisible
    private SWNSyncInvoiceRunner() {}

    public SWNSyncInvoiceRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        syncInvoice();
    }

    private void syncInvoice() {
        res = syncInvoice(sdc.opp, sdc.qt, sdc.isMPUB);
        if (res.isError()) {
            sdc.currentStep.isStepCompletedSuccessfully = false;
            DealDeskCaseGenerator.createCase(sdc.qt, new Opportunity(), false, CaseHelper.CASE_REASON_INVOICE_EXCEPTION, sdc.syncable);
            return;
        }
        AccountHelper.updateWholesalePartnerInformation(sdc.opp);
    }

    @TestVisible
    private Response syncInvoice(Opportunity opp, Quote qt, Boolean isMPUB) {
        Response resp = new Response();
        if (opp == null || qt == null) {
            resp.error();
            return resp;
        }

        Account acc = opp.Account;
        Boolean isSingleQuote = String.isEmpty(qt.MasterQuote__c);
        List<Approval__c> approvedApprovalsForOppty = new List<Approval__c>();

        List<PartnerOperationsLog__c> operationLogList = QuoteHelper.getPartnerOperationLog(opp.Id);
        Boolean isPartnerTypeChanged = !operationLogList.isEmpty()
            && opp.Partner_Account__r.Partner_Type__c != null
            && opp.Partner_Account__r.Partner_Type__c != acc.Partner_Type__c;
        
        Id recordTypeId = getRecordTypeId(acc, isPartnerTypeChanged, operationLogList);

        List<Approval__c> lastApprovedApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovedApprovalsForAccountByRecordType(new List<Object> {recordTypeId, new List<Id> {acc.Id}})
            .executeQuery();

        for (Approval__c approval : lastApprovedApprovals) {
            if (approval.Opportunity__c == opp.Id) {
                approvedApprovalsForOppty.add(approval);
            }
        }

        Approval__c lastApprovedApproval = ApprovalHelper.getLastApprovedInvoiceApproval(approvedApprovalsForOppty, isSingleQuote);

        syncAccountPaymentContact(resp, acc, lastApprovedApproval);
        syncAccountPaymentMethod(resp, acc, opp);
        syncAccountPackageLimits(resp, acc, qt, lastApprovedApproval);
        syncPackageConsolidationSettings(resp, acc, isSingleQuote, isMPUB);

        return resp;
    }

    private Id getRecordTypeId(Account acc, Boolean isPartnerTypeChanged, List<PartnerOperationsLog__c> operationLogList) {
        Id recordTypeId = ApprovalHelper.RT_ID_INVOICING_REQUEST;
        if (AccountHelper.isInvoiceOnBehalfAccount(acc) && !isPartnerTypeChanged) {
            recordTypeId = ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST;
        } else if (AccountHelper.isWholesaleAccount(acc) || !operationLogList.isEmpty()) {
            recordTypeId = ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST;
        }
        return recordTypeId;
    }

    @TestVisible
    private void syncAccountPaymentContact(Response resp, Account acc, Approval__c lastApprovedApproval) {
        if (lastApprovedApproval == null) {
            resp.error(NOT_APPROVED_APPROVAL_ERROR);
            return;
        }
        
        Contact accountPayableContact = (Contact) new ListOptional(new ContactSelector()
                .selectContactsByIds(new List<Object> {new Set<Id> {lastApprovedApproval.AccountPayableContact__c}})
                .executeQuery()
            ).getFirst();

        HttpResponse paymentContactResp = NGBSAPI.updateAccountPaymentContact(acc, accountPayableContact);

        if (paymentContactResp.getStatusCode() == 200) {
            resp.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.ACCOUNT_PAYMENT_CONTACT_SYNCED));
            resp.setData(PAYMENT_CONTACT, paymentContactResp.getBody());
        } else {
            resp.error(CONTACT_SYNC_ERROR);
        }
    }

    @TestVisible
    private void syncAccountPaymentMethod(Response resp, Account acc, Opportunity opp) {
        AccountContactRole accContactRole = (AccountContactRole) new ListOptional(new AccountContactRoleSelector()
                .selectPrimaryAccountContactRolesByAccountIds(new List<Object> {acc.Id})
                .executeQuery()
            ).getFirst();

        Account partnerAcc = getPartnerAccountForPaymentMethodSync(opp.Id, acc);

        Quote primaryBillingQuote = (Quote) new ListOptional(new QuoteSelector()
                .selectBillingPrimaryQuotesByOppIds(new List<Id> {opp.Id})
                .executeQuery()
            ).getFirst();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncPaymentMethod(new List<Object> {primaryBillingQuote.Id})
            .executeQuery();

        HttpResponse invoicePaymentResp = NGBSAPI.updateAccountPaymentMethod(acc, accContactRole, partnerAcc, primaryBillingQuote, qlis);
        
        handlePaymentMethodResponse(resp, invoicePaymentResp);
    }

    @TestVisible
    private void handlePaymentMethodResponse(Response resp, HttpResponse invoicePaymentResp) {
        if (invoicePaymentResp == null) {
            resp.addMessage(SWNHelper.INFO_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.NOTHING_TO_SYNC));
            return;
        }

        switch on invoicePaymentResp.getStatusCode() {
            when 0 {
                resp.addMessage(SWNHelper.INFO_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.NOTHING_TO_SYNC));
            }
            when 200, 201 {
                resp.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.PAYMENT_METHOD_SYNCED));
                resp.setData(INVOICE_PAYMENT, invoicePaymentResp.getBody());
            }
            when 403 {
                resp.error(NGBS_ERROR + ' ' + PAYMENT_METHOD_FAILED);
            }
            when 404 {
                resp.error(NGBS_ERROR + ' ' + PAYMENT_METHOD_NOT_FOUND);
            }
            when else {
                resp.error(INVOICE_SYNC_ERROR);
            }
        }
    }

    private Account getPartnerAccountForPaymentMethodSync(Id opportunityId, Account acc) {
        List<PartnerOperationsLog__c> operationLogList = QuoteHelper.getPartnerOperationLog(opportunityId);

        List<Account> parentAccsList = new List<Account>();

        if (!operationLogList.isEmpty()) {
            Id accountId = ((PartnerOperationsHelper.PartnerInfo)
                JSON.deserialize(operationLogList[0].PartnerInfo__c, PartnerOperationsHelper.PartnerInfo.class))?.id;

            parentAccsList = (List<Account>) new AccountSelector()
                .selectAccountById(accountId)
                .executeQuery();
        } else {
            parentAccsList = (List<Account>) new AccountSelector()
                .selectAccountsByIds(new List<Object> {new List<Id> {acc.Partner_Account__c}})
                .executeQuery();
        }
        return parentAccsList.isEmpty() ? null : parentAccsList[0];
    }

    @TestVisible
    private void syncAccountPackageLimits(Response resp, Account acc, Quote qt, Approval__c lastApprovedApproval) {
        List<Account> accWithServiceAccounts = (List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object> {new Set<Id> {acc.id}})
            .executeQuery();

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .selectServiceInfoForSync(new List<Object> {new Set<Id> {qt.Id}})
            .executeQuery();

        Package__c billingPackage = !serviceInfos.isEmpty() ? serviceInfos[0].BillingPackage__r : accWithServiceAccounts[0].Service_Accounts__r[0];
        Map<String, Decimal> approvedPackageLimitsMap = ApprovalHelper.getApprovedPackageLimitsMap(qt, lastApprovedApproval);
        Decimal monthlyCreditLimit = approvedPackageLimitsMap.get(MONTHLY_CREDIT_LIMIT);
        if (billingPackage == null) {
            return;
        }

        HttpResponse limitOverrideResp = SettingsHelper.FEATURE_TOGGLE.EnableMultiProductUnifiedBilling__c
            ? NGBSAPI.updateAccountPackageLimits(accWithServiceAccounts[0], billingPackage, monthlyCreditLimit)
            : NGBSAPI.updateAccountPackageLimits(accWithServiceAccounts[0], billingPackage);

        handleAccPackageLimitsResponse(resp, limitOverrideResp);
    }

    @TestVisible
    private void handleAccPackageLimitsResponse(Response resp, HttpResponse limitOverrideResp) {
        if (limitOverrideResp.getStatusCode() == 200) {
            resp.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.ACC_PACKAGE_LIMITS_SYNCED));
            resp.setData(LIMIT_OVERRIDE, limitOverrideResp.getBody());
        } else {
            resp.error(LIMITS_SYNC_ERROR);
        }
    }

    @TestVisible
    private void syncPackageConsolidationSettings(Response resp, Account acc, Boolean isSingleProduct, Boolean isMPUB) {
        HttpResponse syncPackageResponse = NGBSAPI.syncPackageConsolidationSettings(acc, isSingleProduct, isMPUB);
        if (syncPackageResponse?.getStatusCode() == 200) {
            resp.addMessage(SWNHelper.SUCCESS_MESSAGES_BUILDER.getSWNMessage(SWNMessageHelper.LabelMessage.PKG_CONSOLIDATION_SETTINGS_SYNCED));
            resp.setData(PKG_CONSOLIDATION_SETTINGS, syncPackageResponse.getBody());
        } else {
            resp.error(PKG_CONSOLIDATION_SETTINGS_SYNC_ERROR);
        }
    }
}