@RestResource(UrlMapping='/ApprovalService/*')
global with sharing class ApprovalService {

    @HttpPost
    global static void handle() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.Params paramsData = (BillingWrappers.Params) JSON.deserialize(body, BillingWrappers.Params.class);
        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            if (paramsData.action == 'getApprovals') {
                result = JSON.serialize(getApprovals(paramsData));
            }
            if (paramsData.action == 'getPOCApprovals') {
                result = JSON.serialize(getPOCApprovals(paramsData));
            }
            if (paramsData.action == 'hasTaxExemptionApprovals') {
                result = JSON.serialize(hasTaxExemptionApprovals(paramsData.accountId, paramsData.brand));
            }
            if (paramsData.action == 'rejectTaxExemptionApprovals') {
                result = JSON.serialize(rejectTaxExemptionApprovals(paramsData.accountId, paramsData.brand));
            }
            if (paramsData.action == 'getEngageLegalApprovals') {
                result = JSON.serialize(getEngageLegalApprovals(paramsData.opportunityId));
            }
            if (paramsData.action == 'getApprovalDetails') {
                result = JSON.serialize(getApprovalDetails(paramsData.approvalParams));
            }
            if (paramsData.action == 'createPartnerOperation') {
                result = JSON.serialize(createPartnerOperation(paramsData.accountId, paramsData.opportunityId, paramsData.partnerInfo));
                OpportunityHelper.updatePartnerFieldsOnOppty(paramsData.opportunityId, paramsData.partnerInfo);
            }
            res.responseBody = Blob.valueOf(result);
        } catch (Exception e) {
            Map<String, String> errMsg = new Map<String, String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.responseBody = Blob.valueOf(JSON.serialize(errMsg));
        }
    }

    private static List<Approval__c> getApprovals(BillingWrappers.Params paramsData) {
        List<Account> technicalAccounts = new AccountSelector()
            .selectMPTechAccountsByMasterIds(paramsData.accountId)
            .executeQuery();
        Set<Id> allAccIds = new Set<Id>();
        for (Account techAcc: technicalAccounts) {
            allAccIds.add(techAcc.Id);
        }
        allAccIds.add(paramsData.accountId);
        return new ApprovalSelector()
            .selectApprovalsForAccountForQuoteService(new List<Object>{new Set<Id>(allAccIds)})
            .executeQuery();
    }

    private static List<Approval__c> getPOCApprovals(BillingWrappers.Params paramsData) {
        return new ApprovalSelector().selectPOCApprovalsForQW(paramsData.opportunityId).executeQuery();
    }

    public static Boolean hasTaxExemptionApprovals(Id accountId, String brand) {
        Boolean hasApprovals = false;
        Account acc = (Account) new AccountSelector()
            .selectAccountWithTaxExemptionApprovals(new List<Object> { new List<Id>{ accountId } })
            .executeQuery()[0];

        if (acc.Approvals__r.size() > 0 && brand != null && String.isEmpty(acc.Billing_ID__c)) {
            for (Approval__c app : acc.Approvals__r) {
                if ((!String.isEmpty(app.OpportunityBrand__c) && app.OpportunityBrand__c != brand) ||
                    (String.isEmpty(app.OpportunityBrand__c) && TaxExemptionHelper.VATBRANDS.contains(brand))) {
                    hasApprovals = true;
                }
            }
        }
        return hasApprovals;
    }

    public static List<Approval__c> rejectTaxExemptionApprovals(Id accountId, String brand) {
        List<Approval__c> updateApprovals = new List<Approval__c>();
        Account acc = (Account) new AccountSelector()
            .selectAccountWithTaxExemptionApprovals(new List<Object>{ new List<Id>{ accountId }})
            .executeQuery()[0];

        if (acc.Approvals__r.size() > 0 && brand != null) {
            for (Approval__c app : acc.Approvals__r) {
                if (app.OpportunityBrand__c != brand) {
                    updateApprovals.add(app);
                }
            }
            String comment = 'Approval was rejected due to opportunity brand changed';
            if (updateApprovals.size() > 0) {
                System.enqueueJob(new BusinessIdentitiesService(updateApprovals, comment));
            }
        }
        return updateApprovals;
    }

    private static List<Approval__c> getEngageLegalApprovals(Id opportunityId) {
        return new ApprovalSelector()
            .selectEngageLegalApprovalsForOpportunity(new List<Object> {opportunityId})
            .executeQuery();
    }

    private static List<String> getApprovalFields(String recordType) {
        Metadata.Layout approvalLayout = SFDescribeHelper.getLayoutInfo(
            ApprovalHelper.APPROVAL_OBJECT_NAME,
            recordType == ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL
                ? 'Invoice-on-behalf Request Layout'
                : 'Invoice Request Layout'
        );
        List<String> approvalFields = new List<String>();
        for (Metadata.LayoutSection section : approvalLayout.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        if (item.field != null) {
                            approvalFields.add(item.field);
                        }
                    }
                }
            }
        }
        approvalFields.add('StatusLastModifiedDate__c');
        return approvalFields;
    }

    public static List<ApprovalDetails> getApprovalDetails(BillingWrappers.ApprovalParams params) {
        List<ApprovalDetails> result = new List<ApprovalDetails>();

        /* We don't know if we deal with child or master account */
        List<Account> accList = (List<Account>) new AccountSelector()
            .selectBoundAccountsByIdOrMasterAccountId(new List<Object> { new Set<Id>{
                params.masterAccountId != null
                    ? params.masterAccountId
                    : params.accountId
            }})
            .executeQuery();

        Map<Id, ApprovalDetails> accIdToApprovalDetailsMap = new Map<Id, ApprovalDetails>();
        /* We definitely deal with bound accounts */
        if (accList.size() > 1) {
            for (Account acc : accList) {
                accIdToApprovalDetailsMap.put(acc.Id, new ApprovalDetails(acc.Master_Account__c == null, acc.Name, acc));
            }
        } else {
            accIdToApprovalDetailsMap.put(accList[0].Id, new ApprovalDetails(false, accList[0].Name, accList[0]));
        }

        List<String> approvalFields = getApprovalFields(params.recordType);
        /* Get Approvals */
        Map<Id, List<Approval__c>> accIdToApprovalListMap = buildAccIdToApprovalListMap(params.action, accIdToApprovalDetailsMap.keySet(), approvalFields);
        /* Get Contact Roles */
        Map<Id, List<AccountContactRole>> accIdToAccountPayableContactListMap = getAccIdToAccountPayableContactListMap(
            new Set<Id>(accIdToApprovalDetailsMap.keySet()),
            params.accountPartner?.id
        );
        List<AccountContactRole> partnerAccContactRoles = accIdToAccountPayableContactListMap.get(params.accountPartner?.id);

        for (Id accId : accIdToApprovalDetailsMap.keySet()) {
            ApprovalDetails ad = accIdToApprovalDetailsMap.get(accId);
            ad.accountPartner = params.accountPartner;

            ad.recordTypeId = ApprovalHelper.RT_INFO_BY_NAME.get(params.recordType).getRecordTypeId();
            ad.recordTypeName = params.recordType;

            List<Approval__c> accApprovals = accIdToApprovalListMap.get(accId);
            List<AccountContactRole> accContactRoles = accIdToAccountPayableContactListMap.get(accId);

            Approval__c resultApproval;

            if (accApprovals != null && accApprovals.size() > 0) {
                resultApproval = accApprovals[0];
            } else {
                resultApproval = new Approval__c(Account__c = accId);
                if (accContactRoles != null && accContactRoles.size() == 1) {
                    resultApproval.AccountPayableContact__c = accContactRoles[0].ContactId;
                }
            }

            resultApproval.IsChangePaymentMethodRequest__c = true;

            if (params.recordType == ApprovalHelper.RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL) {
                if (partnerAccContactRoles != null && partnerAccContactRoles.size() == 1) {
                    resultApproval.PartnerAccountPayableContact__c = partnerAccContactRoles[0].ContactId;
                }
            }
            if (String.isNotBlank(params.accountPartner?.id)) {
                resultApproval.SwitchInvoicePartnerAccount__c = params.accountPartner?.id;
            }

            resultApproval.RecordTypeId = ad.recordTypeId;
            resultApproval.OwnerId = UserInfo.getUserId();

            ad.defaultFieldValues = resultApproval;

            result.add(ad);
        }

        return result;
    }

    private static Map<Id, List<Approval__c>> buildAccIdToApprovalListMap(String action, Set<Id> accountIds, List<String> approvalFields) {
        List<Approval__c> invoiceApprovals = getSourceInvoiceApprovals(action, accountIds, approvalFields);

        Map<Id, List<Approval__c>> accIdToApprovalListMap = new Map<Id, List<Approval__c>>();
        for (Approval__c app : invoiceApprovals) {
            if (!accIdToApprovalListMap.containsKey(app.Account__c)) {
                accIdToApprovalListMap.put(app.Account__c, new List<Approval__c>());
            }
            accIdToApprovalListMap.get(app.Account__c).add(app);
        }
        return accIdToApprovalListMap;
    }

    private static List<Approval__c> getSourceInvoiceApprovals(String action, Set<Id> accountIds, List<String> approvalFields) {
        List<Approval__c> invoiceApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForPartnerOperations(
                new List<Object>{
                    new Set<Id>{
                        ApprovalHelper.RT_ID_INVOICING_REQUEST,
                        ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                        ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
                    },
                    accountIds,
                    new List<String>{ ApprovalHelper.STATUS_APPROVED }
                },
                approvalFields
            )
            .executeQuery();
        return invoiceApprovals;
    }

    private static Map<Id, List<AccountContactRole>> getAccIdToAccountPayableContactListMap(Set<Id> accountIds, Id partnerAccId) {
        accountIds.add(partnerAccId);

        List<AccountContactRole> accountPayableContacts = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountPayableContactRolesByAccount(new List<Object> { accountIds, null })
            .executeQuery();

        Map<Id, List<AccountContactRole>> accIdToAccountPayableContacts = new Map<Id, List<AccountContactRole>>();
        for (AccountContactRole acr : accountPayableContacts) {
            if (!accIdToAccountPayableContacts.containsKey(acr.AccountId)) {
                accIdToAccountPayableContacts.put(acr.AccountId, new List<AccountContactRole>());
            }
            accIdToAccountPayableContacts.get(acr.AccountId).add(acr);
        }
        return accIdToAccountPayableContacts;
    }

    public class ApprovalDetails {
        public Id recordTypeId;
        public Approval__c defaultFieldValues;

        public Boolean isMasterApproval;
        public String accountName;
        public String recordTypeName;
        public BillingWrappers.AccountPartner accountPartner;
        public Account account;

        public ApprovalDetails() {}
        public ApprovalDetails(Boolean isMasterApproval, String accountName, Account acc) {
            this.isMasterApproval = isMasterApproval;
            this.accountName = accountName;
            this.account = acc;
        }
    }

    public static Response createPartnerOperation(String accountId, String opportunityId, String partnerInfo) {
        Response res = new Response();

        PartnerOperationsLog__c partnerLog = (PartnerOperationsLog__c) new SObjectBuilder(PartnerOperationsLog__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PartnerOperationsLog__c.Account__c => accountId,
                PartnerOperationsLog__c.Opportunity__c => opportunityId,
                PartnerOperationsLog__c.PartnerInfo__c => partnerInfo,
                PartnerOperationsLog__c.isCompleted__c => false,
                PartnerOperationsLog__c.isRejected__c => false
            })
            .create()
            .getRecord();

        List<PartnerOperationsStep__c> partnerSteps = new List<PartnerOperationsStep__c>();

        for (String key: PartnerOperationsController.STEPS.keySet()) {
            PartnerOperationsStep__c step = (PartnerOperationsStep__c) new SObjectBuilder(PartnerOperationsStep__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    PartnerOperationsStep__c.PartnerOperationsLog__c => partnerLog.Id,
                    PartnerOperationsStep__c.Order__c => PartnerOperationsController.STEPS.get(key).order,
                    PartnerOperationsStep__c.Name => key,
                    PartnerOperationsStep__c.StepName__c => key,
                    PartnerOperationsStep__c.isCompleted__c => key == PartnerOperationsController.CREATE_WHOLESALE_OPPTY
                })
                .build()
                .getRecord();

            partnerSteps.add(step);
        }
        insert partnerSteps;

        res.addMessage('success', 'Operation is created');
        return res;
    }

    public static List<String> getApprovalLayoutInfo(String layoutName) {
        Metadata.Layout approvalLayout = SFDescribeHelper.getLayoutInfo(
            ApprovalHelper.APPROVAL_OBJECT_NAME,
            layoutName
        );
        List<String> approvalFields = new List<String>();
        for (Metadata.LayoutSection section : approvalLayout.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        if (item.field != null) {
                            approvalFields.add(item.field);
                        }
                    }
                }
            }
        }
        return approvalFields;
    }
}