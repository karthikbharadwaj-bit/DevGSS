/**************************************************************************************************
*   @Class          :   ApprovalHelperCls
*   @Author         :   Rajesh Kumar
*   @CreatedDate    :   4th May,2015
*   @Description    :   Class to handle functionalities done on after insert event

UPDATE:

by:             eugenebasianomutya
date:           4/26/2016
case:           04577495
description:    Quote Approval Process - Auto Approve on Sales Manager

UPDATE
by            eugenebasianomutya
date          5/17/2016
case          04458955
description   Automate Agent Credit Split
***************************************************************************************************/

global without sharing class ApprovalHelperCls {

    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_RECALLED = 'Recalled';
    public static final String STATUS_REJECTED = 'Rejected';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_OUT_FOR_SIGNATURE = 'Out For Signature';
    public static final String STATUS_READY_FOR_SIGNATURE = 'Ready For Signature';
    public static final String STATUS_LOST = 'Lost';
    public static final String STATUS_COMPLETED_AUDIT = 'Completed Audit';
    public static final String STATUS_PENDING_L1_APPROVAL = 'PendingL1Approval';
    public static final String STATUS_PENDING_L2_APPROVAL = 'PendingL2Approval';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_REQUIRED = 'Required';
    public static final String STATUS_FIELD = 'Status__c';

    public static final List<String> WHOLESALE_APPROVAL_ACCOUNT_PARTNER_TYPES = new List<String>{
        AccountHelper.ACCOUNT_PARTNER_WHOLESALE,
        AccountHelper.ACCOUNT_PARTNER_ALCATEL_LUCENT_WHOLESALE,
        AccountHelper.ACCOUNT_PARTNER_ATOS_WHOLESALE,
        AccountHelper.ACCOUNT_PARTNER_AVAYA_WHOLESALE,
        AccountHelper.ACCOUNT_PARTNER_MASTER_AGENT
    };

    public static final Set<String> TERMINAL_STATUSES = new Set<String>{
            STATUS_COMPLETED, STATUS_COMPLETED_AUDIT, STATUS_LOST, STATUS_OUT_FOR_SIGNATURE
    };
    public static final Set<String> ELEGAL_CHANGE_ORDER_TYPES = new Set<String>{'HIPAA/BAA', 'Address Change', 'Company name change',
    'Feature add ons', 'SLAs', 'Feature requests', 'Elasticity clause', 'NDA+ SOC 2 REPORT', 'Change of Ownership'};

    public static final String LEGAL_REQUEST_TYPE_AMENDMENT = 'Amendment';

    public static final String PRELEGAL_APPROVAL_PROCESS_NAME = 'Quote_Legal_Request_Approval_v3';

    // Approval Describe Object
    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Approval__c.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    // Record types
    public static final String RT_NAME_REFUND_APPROVAL = 'Refund Approval';
    public static final String RT_NAME_ENGAGE_LEGAL = 'Engage Legal';
    public static final String RT_NAME_INVOICING_REQUEST = 'Invoicing Request';

    // Email templates
    public static final String BOB_REVENUE_TEAM_APPROVAL_TEMPLATE_NAME = 'BoB_Revenue_Team_Approval';
    public static final String BOB_REVENUE_TEAM_REJECTION_TEMPLATE_NAME = 'BoB_Revenue_Team_Rejection';
    public static final String WHOLESALE_REVENUE_TEAM_APPROVAL_TEMPLATE_NAME = 'Wholesale_Revenue_Team_Approval';
    public static final String WHOLESALE_REVENUE_TEAM_REJECTION_TEMPLATE_NAME = 'Wholesale_Revenue_Team_Rejection';

    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }

    public static final Id RT_ID_REFUND_APPROVAL = RT_INFO_BY_NAME.get(RT_NAME_REFUND_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_ENGAGE_LEGAL = RT_INFO_BY_NAME.get(RT_NAME_ENGAGE_LEGAL).getRecordTypeId();
    public static final Id RT_ID_INVOICING_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_INVOICING_REQUEST).getRecordTypeId();

    // Static Opportunity Map<Id,opoortunity>
    public static Map<Id,Opportunity> opportunityStaticMap = new Map<Id,Opportunity>();

    // variables for recordType Describing By NAME
    public static Schema.DescribeSObjectResult result ;
    public static Map<ID,Schema.RecordTypeInfo> rtMapByName;
    // variables for recordType Describing By ID
    public static Schema.DescribeSObjectResult resultByID ;
    public static Map<String,Schema.RecordTypeInfo> rtMapByID;
    // Account Map Static Map
    public static Map<Id,Account> accountStaticMap = new Map<Id,Account>();
    // Newmap of Trigger.new
    public static Map<Id,Approval__c> approvalNewStaticMap = new Map<Id,Approval__c>();
    // Old map of trigger
    public static Map<Id,Approval__c> oldApprovalStaticMap = new Map<id,Approval__c>();
    // approval to AccountSplit ID map
    public static Map<Id,Account_Split__c> approvalToAcSplitMap = new Map<Id,Account_Split__c>();
    // Static Opportunity Map<Id,Opportunity.OwnerId>
    public static Map<Id,Id> opportunityToOwnerIdMap = new Map<Id,Id>();
    // Static Account Map<Id,Account.OwnerId>
    public static Map<Id,Id> accountToOwnerIdMap = new Map<Id,Id>();

    // All below 4 list are populted in Before Approval trigger and will be inserted/updated in After trigger.
    public static List<Account_Split__c> accntSpltToInsertList = new List<Account_Split__c>();
    public static List<OpportunityTeamMember> optyTeamMembrToInsertList = new List<OpportunityTeamMember>();
    public static List<AccountTeamMember> accntTeamMembrToInsertList = new List<AccountTeamMember>();
    public static Map<Id, Opportunity> opptyToUpdateList = new Map<Id, Opportunity>();
    public static Map<Id, Account> customeraAcountTOUpdateList = new Map<Id, Account>();

    @AuraEnabled
    webservice static String signMeUp(String recordId) {
        Approval__c appr = [SELECT Id, Status__c, OwnerId FROM Approval__c WHERE Id = :recordId];
        Group legalQueue;
        try {
            legalQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Sales_Desk_Legal' AND Type = 'Queue' LIMIT 1];
        } catch(QueryException ex) {
            return Label.Approval_Error_OnSignMeUp_NoSalesDeskLegal;
        }
        if (appr.OwnerId == UserInfo.getUserId()) {
            return Label.Approval_Error_OnSignMeUp_AssignedToYou;
        }
        if (new Set<String>{STATUS_REQUIRED, STATUS_RECALLED}.contains(appr.Status__c)) {
            return String.format(Label.Approval_Error_OnSignMeUp_IncorrectStatus,
                    new List<String>{
                            appr.Status__c
                    });
        }
        if (appr.OwnerId != legalQueue.Id && !AquivaHelper.isAdmin()) {
            return Label.Approval_Error_OnSignMeUp_AssignedToOtherPerson;
        } else {
            if (ApprovalTriggerHandler.getUserIdsFromGroup(new Set<Id>{legalQueue.Id}).contains(UserInfo.getUserId())
                    || AquivaHelper.isAdmin()) {
                appr.OwnerId = UserInfo.getUserId();
                appr.Status__c = STATUS_IN_PROGRESS;
                try {
                    update appr;
                } catch (DmlException ex) {
                    return ex.getDmlMessage(0);
                }
            } else {
                return Label.Approval_Error_OnSignMeUp_NotBelongToLegalQueue;
            }
        }
        return null;
    }
   @AuraEnabled
    webservice static String readyForSignature(String recordId) {
        Approval__c appr = [SELECT Id, OwnerId, Status__c FROM Approval__c WHERE Id = :recordId];
        if (appr.OwnerId != UserInfo.getUserId()) {
            return Label.Approval_Error_OnReadyForSignature_NotOwner;
        }
        if (new Set<String>{STATUS_REQUIRED, STATUS_RECALLED}.contains(appr.Status__c)) {
            return String.format(Label.Approval_Error_OnReadyForSignature_IncorrectStatus,
                    new List<String>{
                            appr.Status__c
                    });
        }
        appr.Status__c = STATUS_READY_FOR_SIGNATURE;
        ApprovalTriggerHandler.sendOutForSignatureOverride = true;
        try {
            update appr;
        } catch (DmlException ex) {
            return ex.getDMLMessage(0);
        }
        return null;
    }
   @AuraEnabled
    webservice static String approveOrReject(String recordId, Boolean approve){
        Approval__c appr = [SELECT Id, OwnerId, Status__c FROM Approval__c WHERE Id =: recordId];
        Id userId = UserInfo.getUserId();
        if(appr.OwnerId != userId){
            return 'You are not the owner of this record, therefore you can\'t change statuses.';
        } else {
            appr.Status__c = approve ? STATUS_READY_FOR_SIGNATURE : STATUS_REJECTED;
            ApprovalTriggerHandler.sendOutForSignatureOverride = true;
            try{
                update appr;
            } catch (DmlException ex) {
                return ex.getDMLMessage(0);
            }
        }
        return null;
    }

    @AuraEnabled
    webservice static String activatePartnerAccount (Id recordId) {
        Account account = (Account) new AccountSelector()
                            .selectAccountForPartnerApproval(recordId)
                            .executeQuery()
                            .get(0);

        if (account.PartnerStatus__c == AccountHelper.ACTIVE_STATUS){
            return ApprovalHelper.APPROVAL_PARTNER_IS_ACTIVE_ERROR;
        }

        String appRecTypeId = getPartnerApprovalRecordTypeId(account);
        if (String.isEmpty(appRecTypeId)) {
            return ApprovalHelper.APPROVAL_PARTNER_NOT_COMPLETED_ERROR;
        }

        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForPartnerAccounts(
                new List<Object>{
                    new Set<Id>{ appRecTypeId },
                    new Set<Id>{ recordId },
                    new List<String>{ ApprovalHelper.STATUS_APPROVED }
                },
                new List<String>{
                    'RecordType.Name'
                }
            )
            .executeQuery();

        if (approvals.size() > 1) {
            return 'Account must contain only one related ' + approvals[0].RecordType.Name + ' record';
        } else if (approvals.isEmpty()) {
            return ApprovalHelper.APPROVAL_PARTNER_NOT_COMPLETED_ERROR;
        }

        if (approvals[0].RecordType.Name == ApprovalHelper.RT_NAME_WHOLESALE_APPROVAL) {
            List<Approval__c> approvedTaxApprovals = new List<Approval__c>();
            List<Approval__c> taxApprovals = (List<Approval__c>) new ApprovalSelector()
                .selectApprovalsByRecTypeForAccount(
                    new List<Object>{
                        new Set<Id>{ ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL },
                        new Set<Id>{ recordId }
                    }
                )
                .selectFields(new List<String> {
                    'Status__c'
                })
                .executeQuery();

            for (Approval__c taxApproval : taxApprovals) {
                if (taxApproval.Status__c == ApprovalHelper.STATUS_APPROVED) {
                    approvedTaxApprovals.add(taxApproval);
                }
            }

            if (!taxApprovals.isEmpty() && approvedTaxApprovals.isEmpty()){
                return ApprovalHelper.APPROVAL_PARTNER_TAX_NOT_COMPLETED_ERROR;
            }
        }

        account.PartnerStatus__c = AccountHelper.ACTIVE_STATUS;
        try{
            update account;
        } catch (DmlException ex) {
            return ex.getDMLMessage(0);
        }

        return null;
    }

    @AuraEnabled
    public static String checkPartnerFinanceRevenueApproval(Id approvalId){
        List<GroupMember> groupMembers = (List<GroupMember>) new GroupMemberSelector()
                    .selectGroupMembersByGroupName(AttachmentTriggerHelper.BOB_APPROVERS_QUEUE_NAME)
                    .addOrdering('SystemModstamp', QueryFactory.SortOrder.ASCENDING)
                    .setQueryCaching(true)
                    .executeQuery();

        Set<Id> queueMemberIds = new Set<Id>();
        for (GroupMember member : groupMembers) {
            queueMemberIds.add(member.UserOrGroupId);
        }

        if (!queueMemberIds.contains(UserInfo.getUserId()) && !AquivaHelper.isAdmin()) {
            return ApprovalHelper.PARTNER_FINANCE_APPROVAL_USER_ERROR;
        }

        Approval__c partnerApproval = [SELECT Id, Status__c,
                                        (SELECT Id FROM Attachments),
                                        (SELECT Id FROM ContentDocumentLinks)
                                    FROM Approval__c
                                    WHERE Id =: approvalId
                                    LIMIT 1];

        if (partnerApproval.Status__c != ApprovalHelper.STATUS_PENDING_FINANCE_APPROVAL) {
            return ApprovalHelper.PARTNER_FINANCE_APPROVAL_STATUS_ERROR;
        }

        if (partnerApproval.Attachments.isEmpty() && partnerApproval.ContentDocumentLinks.isEmpty()) {
            return ApprovalHelper.PARTNER_FINANCE_APPROVAL_DOCUMENTS_ERROR;
        }

        return '';
    }

    @AuraEnabled
    public static String handlePartnerFinanceRevenueAction(Id approvalId, Boolean isApproveAction, String rejectionComment){
        if (isApproveAction) {
            update new Approval__c(
                Id = approvalId,
                Status__c = ApprovalHelper.STATUS_APPROVED
            );
        }

        Approval__c approval = [SELECT Id, OwnerId, Owner.Name, Owner.Email, RecordTypeId FROM Approval__c WHERE Id =: approvalId LIMIT 1];

        String emailTemplateName;

        if (approval.RecordTypeId == ApprovalHelper.RT_ID_BOB_APPROVAL) {
            emailTemplateName = isApproveAction ? BOB_REVENUE_TEAM_APPROVAL_TEMPLATE_NAME : BOB_REVENUE_TEAM_REJECTION_TEMPLATE_NAME;
        }

        if (approval.RecordTypeId == ApprovalHelper.RT_ID_WHOLESALE_APPROVAL) {
            emailTemplateName = isApproveAction ? WHOLESALE_REVENUE_TEAM_APPROVAL_TEMPLATE_NAME : WHOLESALE_REVENUE_TEAM_REJECTION_TEMPLATE_NAME;
        }

        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, DeveloperName, Body
                                        FROM EmailTemplate
                                        WHERE DeveloperName =: emailTemplateName
                                        LIMIT 1];

        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplate.Id, approval.OwnerId, approval.Id);

        email.setSaveAsActivity(false);
        email.setToAddresses(new String[] { approval.Owner.Email });

        if (!isApproveAction) {
            String htmlBody = email.getHtmlBody();
            String plainBody = email.getPlainTextBody();

            htmlBody = htmlBody.replace('!rejectionComment', rejectionComment);
            plainBody = plainBody.replace('!rejectionComment', rejectionComment);

            email.setHtmlBody(htmlBody);
            email.setPlainTextBody(plainBody);
        }

        Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});

        return isApproveAction ? '' : approval.Owner.Name;
    }

    public class PartnerApprovalWrapper {
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String approvalRecTypeName { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }
        @AuraEnabled public Decimal partnerMRR { get; set; }
        @AuraEnabled public Id accountId { get; set; }
    }

    @AuraEnabled
    public static void rejectApprovalProcess(ID approvalId, String approvalComment) {
        if (approvalId != null) {
            List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId
                                                        FROM ProcessInstanceWorkitem
                                                        WHERE ProcessInstance.TargetObjectId = :approvalId];
            if (!workItems.isEmpty()) {
                List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

                for(ProcessInstanceWorkitem workItem : workItems){
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);
                    //Valid values are: Approve, Reject, or Removed.
                    //Only system administrators can specify Removed.
                    req.setAction('Reject');
                    req.setComments(approvalComment);
                    requests.add(req);
                }
                Approval.ProcessResult[] processResults = Approval.process(requests);
            } else {
                update new Approval__c(
                    Id = approvalId,
                    Status__c = ApprovalHelper.STATUS_REJECTED
                );
            }
        }
    }

    @AuraEnabled
    webservice static String cancelPartnerAccount (String recordId) {
        Account acc = [SELECT Account__r.Id, Account__r.PartnerStatus__c FROM Approval__c WHERE Id =: recordId].Account__r;
        if(acc.PartnerStatus__c == AccountHelper.CANCELLED_STATUS){
            return 'Partner Account is already cancelled.';
        } else if(acc.PartnerStatus__c != AccountHelper.NEW_STATUS
                  && acc.PartnerStatus__c != AccountHelper.ACTIVE_STATUS
                  && acc.PartnerStatus__c != AccountHelper.PENDING_STATUS){
            return 'Only \'New\', \'Active\' and \'Pending\' Partner Accounts can be cancelled.';
        } else {
            // Rejecting Approval
            rejectApprovalProcess(recordId, 'Rejected by cancelling Partner Account');

            // Cancelling Account
            acc.PartnerStatus__c = AccountHelper.CANCELLED_STATUS;
            try{
                update acc;
            } catch (DmlException ex) {
                return ex.getDMLMessage(0);
            }
        }
        return null;
    }

    @AuraEnabled
    public static PartnerApprovalWrapper checkPartnerAccount(Id accountId) {
        PartnerApprovalWrapper response = new PartnerApprovalWrapper();
        Account accRecord = (Account) new AccountSelector()
                            .selectAccountForPartnerApproval(accountId)
                            .executeQuery()
                            .get(0);

        String appRecTypeName = getPartnerApprovalRecordType(accRecord);

        if (String.isEmpty(accRecord.Partner_Type__c)
                || accRecord.PartnerStatus__c != AccountHelper.NEW_STATUS
                || String.isEmpty(appRecTypeName)) {
            response.isValid = false;
            response.message = AccountHelper.PARTNER_APPROVAL_VALIDATION_EXCEPTION;
            return response;
        }

        List<Approval__c> recTypeApprovals = getPartnerApprovals(accRecord);

        if (!recTypeApprovals.isEmpty()) {
            response.isValid = false;
            response.message = appRecTypeName + ' ' + AccountHelper.PARTNER_APPROVAL_EXCEPTION;
            return response;
        }

        response.isValid = true;
        response.approvalRecTypeName = appRecTypeName;
        response.currencyIsoCode = accRecord.CurrencyIsoCode;

        return response;
    }

    public static String getPartnerApprovalRecordType(Account accRecord) {
        if (AccountHelper.ACCOUNT_BILL_ON_BEHALF_PARTNERS.contains(accRecord.Partner_Type__c)) {
            return ApprovalHelper.RT_NAME_BOB_APPROVAL;
        }

        if (WHOLESALE_APPROVAL_ACCOUNT_PARTNER_TYPES.contains(accRecord.Partner_Type__c)) {
            return ApprovalHelper.RT_NAME_WHOLESALE_APPROVAL;
        }

        return null;
    }

    public static Id getPartnerApprovalRecordTypeId(Account account) {
        return RT_INFO_BY_NAME.get(getPartnerApprovalRecordType(account))
            ?.getRecordTypeId();
    }

    public static List<Approval__c> getPartnerApprovals(Account account) {
        return (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsByRecTypeForAccount(
                new List<Object>{
                    new Set<Id>{ getPartnerApprovalRecordTypeId(account) },
                    new Set<Id>{ account.Id }
                }
            )
            .executeQuery();
    }

    @AuraEnabled
    public static Id createPartnerApproval(PartnerApprovalWrapper params){
        Account accRecord = (Account) new AccountSelector()
                            .selectAccountForPartnerApproval(params.accountId)
                            .executeQuery()
                            .get(0);

        List<Approval__c> recTypeApprovals = getPartnerApprovals(accRecord);

        if (!recTypeApprovals.isEmpty()) {
            throw new AuraHandledException(getPartnerApprovalRecordType(accRecord) + ' ' + AccountHelper.PARTNER_APPROVAL_EXCEPTION);
        }

        Approval__c partnerApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Account__c => accRecord.Id,
                Approval__c.Partner_First_Name__c => accRecord.Reseller_Requests__r.Partner_First_Name__c,
                Approval__c.Partner_Last_Name__c => accRecord.Reseller_Requests__r.Partner_Last_Name__c,
                Approval__c.Email_Address__c => accRecord.Reseller_Requests__r.Partner_Email_Address__c,
                Approval__c.Partner_Phone_Number__c => accRecord.Reseller_Requests__r.Partner_Phone__c,
                Approval__c.Partner_Company_Name__c => accRecord.Reseller_Requests__r.Partner_Company_Name__c,
                Approval__c.Partner_Address__c => accRecord.Reseller_Requests__r.Partner_Address1__c,
                Approval__c.Partner_Address_2__c => accRecord.Reseller_Requests__r.Partner_Address2__c,
                Approval__c.Partner_City__c => accRecord.Reseller_Requests__r.Partner_City__c,
                Approval__c.Partner_State_Province__c => accRecord.Reseller_Requests__r.Partner_State__c,
                Approval__c.Partner_Zip_Code__c => accRecord.Reseller_Requests__r.Partner_Zip__c,
                Approval__c.Partner_Country__c => accRecord.Reseller_Requests__r.Partner_Country__c,
                Approval__c.Partner_Hierarchy__c => accRecord.Partner_Hierarchy_Level__c,
                Approval__c.Partner_Type__c => accRecord.Reseller_Requests__r.Partner_Type__c,
                Approval__c.Brands_Permitted_to_Sell__c => accRecord.Permitted_Brands__c,
                Approval__c.VAR_Territory__c => accRecord.VAR_Territory__c,
                Approval__c.Partner_Account_ID__c => accRecord.Partner_ID__c,
                Approval__c.Parent_Partner_ID__c => accRecord.Parent_Account_ID__c,
                Approval__c.Invoicing_Partner_ID__c => accRecord.Invoicing_Partner_ID__c,
                Approval__c.Invoice_Copy_Partner_ID__c => accRecord.Invoice_Copy_Partner_ID__c,
                Approval__c.Partner_MRR__c => params.partnerMRR,
                Approval__c.Settlement_type__c => 'Commission',
                Approval__c.CurrencyIsoCode => accRecord.CurrencyIsoCode
            })
            .build()
            .getRecord();

        setPartnerSpecificFields(accRecord, partnerApproval);

        try {
            insert partnerApproval;
        } catch (DmlException ex) {
            throw new AuraHandledException(ex.getDMLMessage(0));
        }

        return partnerApproval.Id;
    }

    private static void setPartnerSpecificFields(Account accRecord, Approval__c partnerApproval) {
        partnerApproval.RecordTypeId = getPartnerApprovalRecordTypeId(accRecord);

        if (ApprovalHelper.isWholesaleApproval(partnerApproval)) {
            partnerApproval.Settlement_Partner__c = accRecord.Reseller_Requests__r.Settlement_Type__c;
            partnerApproval.Settlement_Partner_ID__c = accRecord.Reseller_Requests__r.Settlement_Partner_ID__c;
            partnerApproval.Settlement_Rate_Partner_ID__c = accRecord.Reseller_Requests__r.Settlement_Rate_Partner_ID__c;
        }
    }

    webservice static String recall(String recordId) {
        Approval__c appr = [SELECT Id, CreatedById, CreatedBy.Name, Status__c FROM Approval__c WHERE Id = :recordId];
        List<ProcessInstance> instance = new List<ProcessInstance>([
                SELECT Id, Status
                FROM ProcessInstance
                WHERE TargetObjectId = :recordId
                ORDER BY LastModifiedDate DESC
                LIMIT 1
        ]);
        if (appr.Status__c.contains('Pending')) {
            if (!(appr.CreatedById == UserInfo.getUserId() || AquivaHelper.isAdmin())) {
                return String.format(Label.Approval_Error_OnRecall_NotCreator,
                        new List<String>{
                                appr.CreatedBy.Name
                        });
            }
            if (!instance.isEmpty()) {
                if (instance.get(0).Status == 'Rejected') {
                    return Label.Approval_Error_OnRecall_AlreadyRejected;
                } else if (instance.get(0).Status == 'Removed') {
                    return Label.Approval_Error_OnRecall_AlreadyRecalled;
                } else if (instance.get(0).Status == 'Pending') {
                    ProcessInstanceWorkitem workItem = [
                            SELECT Id
                            FROM ProcessInstanceWorkitem
                            WHERE ProcessInstanceId = :instance.get(0).Id
                            LIMIT 1
                    ];
                    Approval.ProcessWorkItemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);
                    req.setAction('Removed');
                    Approval.process(req);
                }
            } else {
                return Label.Approval_Error_OnRecall_NoApprovalProcess;
            }
        } else {
            if (TERMINAL_STATUSES.contains(appr.Status__c) && !STATUS_RECALLED.equals(appr.Status__c)) {
                return String.format(Label.Approval_Error_OnRecall_IncorrectStatus,
                        new List<String>{
                                appr.Status__c
                        });
            } else if (AquivaHelper.isCurrentUserSuitableForRecallingEL() || appr.CreatedById == UserInfo.getUserId() || AquivaHelper.isAdmin()) {
                appr.Status__c = STATUS_RECALLED;
                try {
                    update appr;
                } catch (DmlException ex) {
                    return ex.getDmlMessage(0);
                }
                if (!instance.isEmpty()) {
                    if (instance.get(0).Status == 'Pending' && (appr.CreatedById == UserInfo.getUserId() || AquivaHelper.isAdmin())) {
                        ProcessInstanceWorkitem workItem = [
                                SELECT Id
                                FROM ProcessInstanceWorkitem
                                WHERE ProcessInstanceId = :instance.get(0).Id
                                LIMIT 1
                        ];
                        Approval.ProcessWorkItemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setWorkitemId(workItem.Id);
                        req.setAction('Removed');
                        Approval.process(req);
                    }
                }
            } else {
                return String.format(Label.Approval_Error_OnRecall_NotCreator,
                        new List<String>{
                                appr.CreatedBy.Name
                        });
            }
        }
        return null;
    }
    webservice static String submitForApproval(String recordId, String message) {
        Approval__c appr = (Approval__c) new ApprovalSelector()
            .selectApprovals()
            .selectFields(new Set<String>{'Id', 'CreatedById', 'CreatedBy.Name', 'Status__c', 'NGBSAmountToIncrease__c',
                           'Opportunity__c', 'Opportunity__r.Special_TOS_Approval__c','Account__r.Account_Payment_Method__c', 'RecordTypeId'})
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{ recordId })
            .executeQuery()
            .get(0);

        if (appr.RecordTypeId != ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE) {
            if (appr.Opportunity__r.Special_TOS_Approval__c != null
                    && appr.Id != appr.Opportunity__r.Special_TOS_Approval__c) {
                return Label.Approval_Error_OnSubmitForApproval_ActiveLegalEngagement;
            }
            if (!appr.Status__c.equals(STATUS_REQUIRED)) {
                return Label.Approval_Error_OnSubmitForApproval_IncorrectStatus;
            }
            if (!(appr.CreatedById == UserInfo.getUserId() || AquivaHelper.isAdmin())) {
                return String.format(Label.Approval_Error_OnSubmitForApproval_NotCreator,
                        new List<String>{
                                appr.CreatedBy.Name
                        });
            }
        }
        try {
            ProcessInstance instance = [
                    SELECT Id, Status
                    FROM ProcessInstance
                    WHERE TargetObjectId = :recordId
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
            ];
            if (instance.Status == 'Pending') {
                return Label.Approval_Error_OnSubmitForApproval_AlreadyOnApproval;
            }
        } catch(QueryException ex) {
            // Ignore
        }
        try {
            if (appr.RecordTypeId != ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE) {
                update new Opportunity(Id = appr.Opportunity__c, Special_TOS_Approval__c = appr.Id);
            }
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            if (appr.RecordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE){
                req.setComments(message);
                req.setProcessDefinitionNameOrId(ApprovalHelper.PROCESS_CREDIT_LIMIT_APPROVAL);
            } else {
                req.setProcessDefinitionNameOrId(PRELEGAL_APPROVAL_PROCESS_NAME);
            }

            req.setObjectId(appr.Id);
            req.setSubmitterId(UserInfo.getUserId());
            Approval.ProcessResult result = Approval.process(req);

            if (result.getEntityId() != null &&
                appr.RecordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE &&
                appr.Account__r.Account_Payment_Method__c != null &&
                    (
                        (appr.Account__r.Account_Payment_Method__c.equalsIgnoreCase(AccountHelper.PAYMENT_METHOD_CREDIT_CARD) ||
                        appr.Account__r.Account_Payment_Method__c.equalsIgnoreCase(AccountHelper.PAYMENT_METHOD_NGBS_CREDIT_CARD)) ||
                        ((appr.Account__r.Account_Payment_Method__c.equalsIgnoreCase(AccountHelper.PAYMENT_METHOD_INVOICE) ||
                            appr.Account__r.Account_Payment_Method__c.equalsIgnoreCase(AccountHelper.PAYMENT_METHOD_DIRECT_DEBIT) ||
                            appr.Account__r.Account_Payment_Method__c.equalsIgnoreCase(AccountHelper.PAYMENT_METHOD_DIRECTDEBIT)
                        ) && appr.NGBSAmountToIncrease__c < 10000)
                    )
            ) {
                ApprovalHelper.processApprovalRequest(new Set<Id>{(Id)result.getEntityId()}, 'This step has been approved automatically', 'Approve');
            }
        } catch (DmlException ex) {
            return ex.getDmlMessage(0);
        }
        return null;
    }

    public static List<User> findLegals() {
        List<Group> groupList = [
                SELECT Id
                FROM Group
                WHERE DeveloperName = 'Sales_Desk_Legal'
                AND Type = 'Queue'
                LIMIT 1
        ];
        Group legalQueue = groupList.isEmpty() ? null : groupList[0];
        if (legalQueue == null) {
            throw new AquivaHelper.AquivaException('Legal Group is not found.');
        }
        Set<Id> legalUsersIds = ApprovalTriggerHandler.getUserIdsFromGroup(new Set<Id>{legalQueue.Id});
        return [
                SELECT Id, Name, Email
                FROM User
                WHERE Id IN :legalUsersIds
        ];
    }

    public static List<User> findInvoiceUsers() {
        List<Group> groupList = [
                SELECT Id
                FROM Group
                WHERE DeveloperName = 'Invoice_Approval_Queue'
                AND Type = 'Queue'
                LIMIT 1
        ];
        Group invoiceQueue = groupList.isEmpty() ? null : groupList[0];
        if (invoiceQueue == null) {
            throw new AquivaHelper.AquivaException('Invoice Approval Group is not found.');
        }
        Set<Id> invoiceUsersIds = ApprovalTriggerHandler.getUserIdsFromGroup(new Set<Id>{invoiceQueue.Id});
        return [
                SELECT Id, Name, Email
                FROM User
                WHERE Id IN :invoiceUsersIds
        ];
    }

    public virtual class Email {
        private List<String> emails;

        public String Subject { get; protected set; }
        public String EmailHtmlBody { get; protected set; }

        public virtual Messaging.SingleEmailMessage getMail() {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(this.emails);
            mail.setSubject(this.subject);
            mail.setHtmlBody(this.emailHtmlBody);
            return mail;
        }

        public Email(String subject, String emailHtmlBody) {
            this.Subject = subject;
            this.EmailHtmlBody = emailHtmlBody;
        }

        public Email(String email, String subject, String emailHtmlBody) {
            this(new List<String>{email}, subject, emailHtmlBody);
        }

        public Email(List<String> emails, String subject, String emailHtmlBody) {
            this.EmailHtmlBody = emailHtmlBody;
            this.Subject = subject;
            this.emails = emails;
        }

        public void addParameter(String key, Object value) {
            String replacer = null == value ? '' : String.valueOf(value);
            this.subject = this.subject.replace(
                '{!' + key + '}',
                replacer);
            this.emailHtmlBody = this.emailHtmlBody.replace(
                '{!' + key + '}',
                replacer);
        }
    }

    public class InternalEmail extends Email {
        private List<Id> recipientsIds;

        public InternalEmail(Id recipientId, String subject, String emailHtmlBody) {
            this(new List<Id>{ recipientId }, subject, emailHtmlBody);
        }

        public InternalEmail(List<Id> recipientId, String subject, String emailHtmlBody) {
            super(subject, emailHtmlBody);
            this.recipientsIds = recipientId;
        }

        public override Messaging.SingleEmailMessage getMail() {
            throw new CustomException('This method not available in this class');
        }

        public Messaging.SingleEmailMessage[] getMails() {
            List<Messaging.SingleEmailMessage> result = new List<Messaging.SingleEmailMessage>();
            for(Id recipientId : recipientsIds) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSubject(this.Subject);
                email.setHtmlBody(this.EmailHtmlBody);
                email.setTargetObjectId(recipientId);
                email.setSaveAsActivity(false);
                result.add(email);
            }
            return result;
        }
    }

    public static List<User> findQueueUsers(String queueName) {
        if (String.isBlank(queueName)) {
            return new List<User>();
        }

        List<Group> groupList = new List<Group>([SELECT Id, Name
                                                 FROM Group
                                                 WHERE DeveloperName = :queueName
                                                 AND Type = 'Queue'
                                                 LIMIT 1]);

        Group retrievedQueue = groupList.isEmpty() ? null : groupList[0];
        if (retrievedQueue == null) {
            throw new AquivaHelper.AquivaException(queueName + 'was not found.');
        }
        Set<Id> queueUsersIds = ApprovalTriggerHandler.getUserIdsFromGroup(new Set<Id>{retrievedQueue.Id});
        if (!queueUsersIds.isEmpty()) {
            return [SELECT Id, Name, Email
                    FROM User
                    WHERE Id IN :queueUsersIds];
        } else {
            throw new AquivaHelper.AquivaException('No users from this queue were found.');
        }
    }

    /*************************************************************************************************
    *   @Method         :   describeRecordTypesByName
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   void
    ***************************************************************************************************/
    public static void describeRecordTypesByName(){
        try{
            result = Approval__c.SObjectType.getDescribe();
            rtMapByName = result.getRecordTypeInfosById();
        }catch(Exception e){
            System.debug('########## Exception occurred in Method describeRecordTypesByName : '+ e.getMessage());
        }
    }

    /*************************************************************************************************
    *   @Method         :   describeRecordTypesById
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   void
    ***************************************************************************************************/
    public static void describeRecordTypesById(){
        try{
            resultByID = Approval__c.SObjectType.getDescribe();
            rtMapByID= resultByID.getRecordTypeInfosByName();
        }catch(Exception e){
            System.debug('########## Exception occurred in Method describeRecordTypesById : '+ e.getMessage());
        }
    }

    /*************************************************************************************************
    *   @Method         :   createAccountSplitsDirectToVar
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   Trigger.new (Approval__c)
    *   @returnType     :   void
    *   @author         :   Rajesh Kumar
    ***************************************************************************************************/
    public static void createAccntSplitDirToVar(){
        try{

            Map<Id,Id> approvalToPartnerOwnerMap = new Map<Id,Id>();
            //Relayware
            Map<Id,Id> approvalToPartnerContactMap = new Map<Id,Id>();

            for(Approval__c appObj : approvalNewStaticMap.values()){
                System.debug('###### appObj.create '+appObj.CreatedById);
                if(appObj.RecordTypeId != null && rtMapByName.get(appObj.recordtypeId).getName() == 'Channel Cross Sell'){
                    String relatedUsrField = '';
                    //Relayware
                    if(appObj.Type__c == 'Direct to VAR'){
                        //Relayware
                        if(string.isNotBlank(appObj.Partner_Contact__c)){
                            relatedUsrField = 'Partner_Contact__c';
                        } else {
                            relatedUsrField = 'Partner_Owner__c';
                        }
                    }else if(appObj.Type__c == 'VAR to Direct'){
                        relatedUsrField = 'Direct_Sales_Rep__c';
                    }
                    //End
                    if(relatedUsrField != '' && eligibleToCreateAccountSplits(appObj,relatedUsrField)){
                        String oppotyMarket = '';
                        // logic used for related opportunity
                        if(appObj.Opportunity__c != NULL){
                            if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(appObj.Opportunity__c) && opportunityStaticMap.get(appObj.Opportunity__c) != NULL){
                                Opportunity oppty = opportunityStaticMap.get(appObj.Opportunity__c);
                                // Creating a map of OpoortunityId to Opportunity.OwnerId
                                opportunityToOwnerIdMap.put(oppty.Id,oppty.OwnerId);
                                // skip creating AccountSplit for this approval if employee Range AND Forecasted Users on opportunity are not populated.
                                if(oppty.Effective_No_of_Employees_Range__c == NULL
                                    || oppty.Forecasted_Users__c == NULL
                                    || oppty.Forecasted_Users__c == 0){
                                    continue;
                                }
                                //Relayware
                                if((relatedUsrField == 'Partner_Contact__c') ||
                                    (appObj.Type__c == 'VAR to Direct' && string.isNotBlank(appObj.Partner_Contact__c))){
                                    approvalToPartnerContactMap.put(appObj.id,appObj.Partner_Contact__c);
                                } else {
                                    approvalToPartnerOwnerMap.put(appObj.id,appObj.Partner_Owner__c);
                                }
                                //End

                                oppotyMarket = findMarketTypeOfOppty(oppty.Effective_No_of_Employees_Range__c,Integer.valueOf(oppty.Forecasted_Users__c));
                                // Updating the Opportunity Team
                                OpportunityTeamMember optyTeamMembrObj = new OpportunityTeamMember();
                                optyTeamMembrObj = (OpportunityTeamMember)updateRelatedTeams(oppotyMarket,oppty.Id,appObj.OwnerId,appObj.Type__c,appObj.Direct_Sales_Rep__c);
                                if(optyTeamMembrObj != NULL){
                                    optyTeamMembrToInsertList.add(optyTeamMembrObj);
                                }
                            }
                        }
                        // logic used related to Account
                        if(appObj.Account__c != NULL){
                            String rcAccountStatus = '';
                            Account acc = new Account();
                            if(accountStaticMap != NULL && accountStaticMap.containsKey(appObj.Account__c) && accountStaticMap.get(appObj.Account__c) != NULL){
                                acc = accountStaticMap.get(appObj.Account__c);
                                accountToOwnerIdMap.put(acc.Id,acc.OwnerId);
                                if(acc.RC_Account_Status__c != NULL){
                                    rcAccountStatus = acc.RC_Account_Status__c;
                                }
                            }
                            // Updating the Account Team
                            AccountTeamMember accntTeamMembrObj = new AccountTeamMember();
                            accntTeamMembrObj = (AccountTeamMember)updateRelatedTeams(oppotyMarket,appObj.Account__c,appObj.OwnerId,appObj.Type__c,appObj.Direct_Sales_Rep__c);
                            if(accntTeamMembrObj != NULL){
                                accntTeamMembrToInsertList.add(accntTeamMembrObj);
                            }
                            // Creating Account_Split__c Record based on Approval fields
                            Account_Split__c acSplit =  returnNewAccountSplit(rcAccountStatus,appObj.Id,oppotyMarket,appObj.Type__c,appObj.Account__c,appObj.OwnerId,appObj.Direct_Sales_Rep__c);
                            accntSpltToInsertList.add(acSplit);
                            approvalToAcSplitMap.put(appObj.Id,acSplit);
                            System.debug('#$#$##@#@#@#@# accntSpltToInsertList '+ accntSpltToInsertList);
                            appObj.Status__c = 'Completed';
                            appObj.Completed_Date__c = System.today();
                        }
                    }
                }
            }// end of For loop
            if(approvalToPartnerOwnerMap.size() > 0 ){
                updateRelatedParentObjects(approvalToPartnerOwnerMap);
            }
            //Relayware
            if(approvalToPartnerContactMap.size() > 0 ){
                updateRelatedParentObjectsBasedContact(approvalToPartnerContactMap);
            }
            //End
        }catch(Exception e){
            System.debug('########## Exception occurred in Method createAccntSplitDirToVar : '+ e.getMessage() +'Line == '+ e.getLineNumber());
        }

    }

    /***************************************************************************************************
    *   @Method         :   isChangedObjectsfield
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   String
    *   @Description    :   Generic method to Assess if any field of given object is changed or not.
    *   @returnType     :   Boolean
    *   @createdBy      :   Rajesh
    ***************************************************************************************************/
    private static Boolean isChangedObjectsfield(Sobject obj, String fieldName, Map<id,Sobject> objectOldMap){
        if(objectOldMap != NULL && objectOldMap.containsKey(obj.Id) && objectOldMap.get(obj.Id) != NULL
                                  && objectOldMap.get(obj.Id).get(fieldName) != obj.get(fieldName)){
            System.debug('############# 111111111 Truee');
            return true;
        }
        System.debug('############# 111111111 flaseeee');
        return false;
    }

    /***************************************************************************************************
    *   @Method         :   updateRelatedParentObjects
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   Map<Id,Id> (Key = approval Id, Value = Approval.PartnerOwner Id)
    *   @Description    :   updates Opportunity Owner
    *   @returnType     :   void
    ***************************************************************************************************/
    private static void updateRelatedParentObjects(Map<Id,Id> approvalToPartnerOwnerMap){
        Schema.DescribeSObjectResult resultOpp = Opportunity.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByNameOpp = resultOpp.getRecordTypeInfosByName();
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id,ContactId,Contact.Account.Current_Owner__c,Contact.Account.Inside_Sales_Rep__c,
                                                        Contact.Account.Partner_ID__c,Contact.Account.Ultimate_Partner_ID__c,
                                                        Contact.Account.Ultimate_Parent_Partner_ID__c, Contact.Account.Ultimate_Partner_Name__c
                                                        FROM User WHERE Id IN : approvalToPartnerOwnerMap.values()]);
        for(Approval__c apprObj : approvalNewStaticMap.values()){
            system.debug('======= 11111' );
            if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(apprObj.Opportunity__c) && opportunityStaticMap.get(apprObj.Opportunity__c) != NULL){
                Opportunity oppty = opportunityStaticMap.get(apprObj.Opportunity__c);

                Account opptysAccount = new Account();
                if(accountStaticMap != NULL && accountStaticMap.containsKey(oppty.AccountId) && accountStaticMap.get(oppty.AccountId) != NULL){
                    opptysAccount = accountStaticMap.get(oppty.AccountId);
                }

                oppty.RecordTypeId = rtMapByNameOpp.get('VAR Opportunity').getRecordTypeId();
                if(userMap != NULL && userMap.containsKey(approvalToPartnerOwnerMap.get(apprObj.Id)) && userMap.get(approvalToPartnerOwnerMap.get(apprObj.Id)) != NULL){
                    system.debug('************ == '+apprObj.Id);
                    User tempUser = userMap.get(approvalToPartnerOwnerMap.get(apprObj.Id));
                    system.debug('************ == 111 '+apprObj.Id);
                    if(tempUser.ContactId != NULL && tempUser.Contact.Account != NULL){
                        system.debug('************ == apprObj.Partner_Owner__c ==  '+apprObj.Partner_Owner__c);

                        Account partnerAccount = tempUser.Contact.Account;
                        // update Opportunity's fields.

                        oppty.Partner_Owner__c = (apprObj.Partner_Owner__c != NULL ? apprObj.Partner_Owner__c : oppty.Partner_Owner__c);
                        oppty.Partner_ID__c = (partnerAccount.Partner_ID__c != NULL && partnerAccount.Partner_ID__c != '' ? partnerAccount.Partner_ID__c : oppty.Partner_ID__c);

                        //Relayware
                        oppty.Partner_Contact__c = NULL;
                        oppty.Partner_Account__c = NULL;
                        //End

                        if(apprObj.Type__c == 'Direct to VAR'){
                            TriggerHandler.IsByPassedValidaionOnOppty = true; // New Line Case #03793086
                            //CR-97501 Remove changing OwnerId
                            oppty.Partner_Lead_Source__c = 'RingCentral';
                            oppty.Inside_Sales_Rep__c = (partnerAccount.Inside_Sales_Rep__c != NULL ? partnerAccount.Inside_Sales_Rep__c :oppty.Inside_Sales_Rep__c);
                        }
                        if(partnerAccount.Ultimate_Parent_Partner_ID__c != NULL && partnerAccount.Ultimate_Parent_Partner_ID__c != ''){
                            oppty.Ultimate_Parent_Account_Partner_ID__c = partnerAccount.Ultimate_Parent_Partner_ID__c;
                        }
                        // update Opportunity's Account (Customer Account) fields.
                        opptysAccount.Inside_Sales_Rep__c = (partnerAccount.Inside_Sales_Rep__c != NULL ? partnerAccount.Inside_Sales_Rep__c : opptysAccount.Inside_Sales_Rep__c);
                        opptysAccount.Current_Owner__c = (partnerAccount.Current_Owner__c != NULL ? partnerAccount.Current_Owner__c : opptysAccount.Current_Owner__c);
                        opptysAccount.Partner_ID__c = (partnerAccount.Partner_ID__c != '' && partnerAccount.Partner_ID__c != NULL ? partnerAccount.Partner_ID__c : opptysAccount.Partner_ID__c);
                        if(partnerAccount.Ultimate_Partner_ID__c != '' && partnerAccount.Ultimate_Partner_ID__c != NULL){
                            opptysAccount.Ultimate_Partner_ID__c = partnerAccount.Ultimate_Partner_ID__c;
                        }
                        if(partnerAccount.Ultimate_Partner_Name__c != '' && partnerAccount.Ultimate_Partner_Name__c != NULL){
                            opptysAccount.Ultimate_Partner_Name__c = partnerAccount.Ultimate_Partner_Name__c;
                        }

                        // Populating approvalToAcSplitMap
                        System.debug('&&&&&&&&&&&&&&&&&&&& partnerAccount.Partner_ID__c ' + partnerAccount.Partner_ID__c);
                        if(approvalToAcSplitMap != NULL && approvalToAcSplitMap.containsKey(apprObj.Id) && approvalToAcSplitMap.get(apprObj.Id)!= NULL){
                            approvalToAcSplitMap.get(apprObj.Id).PartnerId__c = partnerAccount.Partner_ID__c ;
                        }
                    }
                }
                opptyToUpdateList.put(oppty.Id, oppty);
                customeraAcountTOUpdateList.put(opptysAccount.Id, opptysAccount);
            }
        }
        System.debug('&&&&&&&&&&&& approvalToAcSplitMap ' + approvalToAcSplitMap);
    }

    //Relayware
    public static void updateRelatedParentObjectsBasedContact(Map<Id,Id> approvalToPartnerContactMap){
        Schema.DescribeSObjectResult resultOpp = Opportunity.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByNameOpp = resultOpp.getRecordTypeInfosByName();
        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id,Account.Current_Owner__c,Account.Inside_Sales_Rep__c,
                                                        Account.Partner_ID__c,Account.Ultimate_Partner_ID__c,AccountId,
                                                        Account.Ultimate_Parent_Partner_ID__c,Account.Ultimate_Partner_Name__c
                                                        FROM Contact WHERE Id IN : approvalToPartnerContactMap.values()]);
        for(Approval__c apprObj : approvalNewStaticMap.values()){
            if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(apprObj.Opportunity__c) && opportunityStaticMap.get(apprObj.Opportunity__c) != NULL){
                Opportunity oppty = opportunityStaticMap.get(apprObj.Opportunity__c);

                Account opptysAccount = new Account();
                if(accountStaticMap != NULL && accountStaticMap.containsKey(oppty.AccountId) && accountStaticMap.get(oppty.AccountId) != NULL){
                    opptysAccount = accountStaticMap.get(oppty.AccountId);
                }

                oppty.RecordTypeId = rtMapByNameOpp.get('VAR Opportunity').getRecordTypeId();
                if(contactMap != NULL && contactMap.containsKey(approvalToPartnerContactMap.get(apprObj.Id)) && contactMap.get(approvalToPartnerContactMap.get(apprObj.Id)) != NULL){
                    Contact tempContact = contactMap.get(approvalToPartnerContactMap.get(apprObj.Id));
                    if(tempContact.Account != NULL){

                        Account partnerAccount = tempContact.Account;
                        // update Opportunity's fields.
                        oppty.Partner_Contact__c = (apprObj.Partner_Contact__c != NULL ? apprObj.Partner_Contact__c : oppty.Partner_Contact__c);
                        oppty.Partner_Account__c =  partnerAccount.Id;
                        oppty.Partner_ID__c = (partnerAccount.Partner_ID__c != NULL && partnerAccount.Partner_ID__c != '' ? partnerAccount.Partner_ID__c : oppty.Partner_ID__c);

                        if(apprObj.Type__c == 'Direct to VAR'){
                            TriggerHandler.IsByPassedValidaionOnOppty = true; // New Line Case #03793086
                            //CR-97501 Remove changing OwnerId
                            oppty.Partner_Lead_Source__c = 'RingCentral';
                            oppty.Inside_Sales_Rep__c = (partnerAccount.Inside_Sales_Rep__c != NULL ? partnerAccount.Inside_Sales_Rep__c :oppty.Inside_Sales_Rep__c);
                        }
                        if(partnerAccount.Ultimate_Parent_Partner_ID__c != NULL && partnerAccount.Ultimate_Parent_Partner_ID__c != ''){
                            oppty.Ultimate_Parent_Account_Partner_ID__c = partnerAccount.Ultimate_Parent_Partner_ID__c;
                        }
                        // update Opportunity's Account (Customer Account) fields.
                        opptysAccount.Inside_Sales_Rep__c = (partnerAccount.Inside_Sales_Rep__c != NULL ? partnerAccount.Inside_Sales_Rep__c : opptysAccount.Inside_Sales_Rep__c);
                        opptysAccount.Current_Owner__c = (partnerAccount.Current_Owner__c != NULL ? partnerAccount.Current_Owner__c : opptysAccount.Current_Owner__c);
                        opptysAccount.Partner_ID__c = (partnerAccount.Partner_ID__c != '' && partnerAccount.Partner_ID__c != NULL ? partnerAccount.Partner_ID__c : opptysAccount.Partner_ID__c);
                        opptysAccount.Partner_Contact__c = oppty.Partner_Contact__c;
                        if(partnerAccount.Ultimate_Partner_ID__c != '' && partnerAccount.Ultimate_Partner_ID__c != NULL){
                            opptysAccount.Ultimate_Partner_ID__c = partnerAccount.Ultimate_Partner_ID__c;
                        }
                        if(partnerAccount.Ultimate_Partner_Name__c != '' && partnerAccount.Ultimate_Partner_Name__c != NULL){
                            opptysAccount.Ultimate_Partner_Name__c = partnerAccount.Ultimate_Partner_Name__c;
                        }

                        // Populating approvalToAcSplitMap
                        System.debug('&&&&&&&&&&&&&&&&&&&& partnerAccount.Partner_ID__c ' + partnerAccount.Partner_ID__c);
                        if(approvalToAcSplitMap != NULL && approvalToAcSplitMap.containsKey(apprObj.Id) && approvalToAcSplitMap.get(apprObj.Id)!= NULL){
                            approvalToAcSplitMap.get(apprObj.Id).PartnerId__c = partnerAccount.Partner_ID__c ;
                        }
                    }
                }
                opptyToUpdateList.put(oppty.Id, oppty);
                customeraAcountTOUpdateList.put(opptysAccount.Id, opptysAccount);
            }
        }
        System.debug('&&&&&&&&&&&& approvalToAcSplitMap ' + approvalToAcSplitMap);
    }
    //End

    /***************************************************************************************************
    *   @Method         :   findMarketTypeOfOppty
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   String, Integer
    *   @Description    :   Return if oppty is Upmarket or Downmarket
    *   @returnType     :   String
    ***************************************************************************************************/
    private static String findMarketTypeOfOppty(String employeeRange,Integer forecastedUsers){
        if(employeeRange != NULL){
            if(employeeRange.contains('50-249') || employeeRange.contains('250-999') || employeeRange.contains('1000+') ){
                return 'Upmarket';
            }else if(employeeRange.contains('10-49') || employeeRange.contains('2-9') || employeeRange.contains('Just me') ){
                if(forecastedUsers < 50 ){
                    return 'Downmarket';
                }else{
                    return 'Upmarket';
                }
            }else{
                return '';
            }
        }else{
                return '';
        }
    }
    /****************************************************************************************************
    *   @Method         :   insertAccountSplits
    *   @CreatedDate    :   4th May,2015
    *   @Params         :   String, double
    *   @Description    :   updateRelatedAccountTeam
    *   @returnType     :   sObject
    ***************************************************************************************************/
    private static Sobject updateRelatedTeams(String oppotyMarket,Id objId,Id appOwnerId,String approvalType,Id dsrId){
        String teamMemberRoleStrng = '';
        Id teamMemberUser;
        if(oppotyMarket == 'Downmarket'){
            if(approvalType == 'Direct to VAR'){
                teamMemberRoleStrng = 'Shared Downmarket Deal - Direct to VAR';
            }else if(approvalType == 'VAR to Direct'){
                teamMemberRoleStrng = 'Overlay Downmarket Deal - VAR to Direct';
            }
        }else if(oppotyMarket == 'Upmarket'){
            if(approvalType == 'Direct to VAR'){
                teamMemberRoleStrng = 'Shared Upmarket Deal - Direct to VAR';
            }else if(approvalType == 'VAR to Direct'){
                teamMemberRoleStrng = 'Overlay Upmarket Deal - VAR to Direct';
            }
        }
        if(String.valueOf(objId).startsWith('006')){
            teamMemberUser = [SELECT OwnerId FROM Lead WHERE ConvertedOpportunityId = :objId].OwnerId;
            OpportunityTeamMember otmObj = new OpportunityTeamMember(UserId = teamMemberUser,OpportunityId = objId,TeamMemberRole = teamMemberRoleStrng);
            return otmObj;
        }else if(String.valueOf(objId).startsWith('001')){
            teamMemberUser = [SELECT OwnerId FROM Lead WHERE ConvertedAccountId = :objId].OwnerId;
            AccountTeamMember atmObj = new AccountTeamMember(UserId = teamMemberUser,AccountId = objId,TeamMemberRole = teamMemberRoleStrng);
            return atmObj;
        }else{
            return null;
        }
    }
    /****************************************************************************************************
    *   @Method         :   updateAccOppShareMethod
    *   @Description    :   update AccountShare and Opportunity Share
    *   @returnType     :   void
    ***************************************************************************************************/
    private static void updateAccOppShareMethod(sObject[] sObjectList){
        List<AccountTeamMember> accntTeamMembrList = new List<AccountTeamMember>();
        List<OpportunityTeamMember> oppTeamMembrList = new List<OpportunityTeamMember>();
        Map<Id,Map<Id,AccountShare>> accountToAccountShareMap = new Map <Id,Map<Id,AccountShare>>();
        Map<Id,Map<Id,OpportunityShare>> oppToOpportunityShareMap = new Map <Id,Map<Id,OpportunityShare>>();
        for(SObject so : sObjectList ){
            if(so.getSObjectType()==AccountTeamMember.sObjectType){
                accntTeamMembrList.add((AccountTeamMember)so);
            }else if(so.getSObjectType()==OpportunityTeamMember.sObjectType){
                oppTeamMembrList.add((OpportunityTeamMember)so);
            }

        }
        if(accntTeamMembrList.size()>0 && accntTeamMembrList!=null){
            set<Id> accntIdSet = new set<Id>();
            for(AccountTeamMember atmObj : accntTeamMembrList) {
                accntIdSet.add(atmObj.AccountId);
            }
            for(AccountShare asObj : [select Id,AccountAccessLevel,CaseAccessLevel,ContactAccessLevel,
                                        AccountId,UserOrGroupId from AccountShare where AccountId IN : accntIdSet]){
                if(accountToAccountShareMap != NULL && !accountToAccountShareMap.containskey(asObj.AccountId)) {
                    accountToAccountShareMap.put(asObj.AccountId,new map<Id,AccountShare>());
                }
                accountToAccountShareMap.get(asObj.AccountId).put(asObj.UserOrGroupId,asObj);
            }
            List<AccountShare> AccountShareListToUpdate = new List<AccountShare>();
            for(AccountTeamMember atm : accntTeamMembrList){
                if(accountToAccountShareMap!=null && accountToAccountShareMap.containsKey(atm.AccountId)){
                    if(accountToAccountShareMap!=null && accountToAccountShareMap.get(atm.AccountId).containsKey(atm.UserId)){
                        if(accountToOwnerIdMap != NULL && accountToOwnerIdMap.get(atm.AccountId) != NULL){
                        //Only update Account Team Member access to read/write if Acct Team Member is NOT Accnt.Owner, otherwise it will throw -
                        //- an error as Accnt Owner is already having full access including (read/write)
                            if(accountToOwnerIdMap.get(atm.AccountId) != atm.UserId){
                                accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).AccountAccessLevel = 'Edit';
                                if( accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).CaseAccessLevel == 'None'
                                    ||
                                    accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).CaseAccessLevel == 'Read'){
                                    accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).CaseAccessLevel = 'Edit';
                                }
                                if( accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).ContactAccessLevel == 'None'
                                    ||
                                    accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).ContactAccessLevel == 'Read'){
                                    accountToAccountShareMap.get(atm.AccountId).get(atm.UserId).ContactAccessLevel = 'Edit';
                                }
                                AccountShareListToUpdate.add(accountToAccountShareMap.get(atm.AccountId).get(atm.UserId));
                            }
                        }
                    }
                }
            }
            if(AccountShareListToUpdate != null && AccountShareListToUpdate.size()>0){
                update AccountShareListToUpdate;
            }
       }

       if(oppTeamMembrList.size()>0 && oppTeamMembrList!=null){
        set<Id> oppIdSet = new set<Id>();
        for(OpportunityTeamMember otmObj : oppTeamMembrList) {
            oppIdSet.add(otmObj.OpportunityId);
        }
        for(OpportunityShare osObj : [select Id,OpportunityAccessLevel,OpportunityId,UserOrGroupId from OpportunityShare where OpportunityId IN : oppIdSet]){
            if(!oppToOpportunityShareMap.containskey(osObj.OpportunityId)) {
                oppToOpportunityShareMap.put(osObj.OpportunityId,new map<Id,OpportunityShare>());
            }
            oppToOpportunityShareMap.get(osObj.OpportunityId).put(osObj.UserOrGroupId,osObj);
        }
        List<OpportunityShare> OpportunityShareListToUpdate = new List<OpportunityShare>();
        for(OpportunityTeamMember otm : oppTeamMembrList){
            if(oppToOpportunityShareMap!=null && oppToOpportunityShareMap.containsKey(otm.OpportunityId)){
                if(oppToOpportunityShareMap!=null && oppToOpportunityShareMap.get(otm.OpportunityId).containsKey(otm.UserId)){
                    if(opportunityToOwnerIdMap != NULL && opportunityToOwnerIdMap.get(otm.OpportunityId) != NULL){
                        //Only update Oppty Team Member access to read/write if Oppty Team Member is NOT Oppty.Owner, otherwise it will throw -
                        //- an error as Oppty Owner is already having full access including (read/write)
                        if(opportunityToOwnerIdMap.get(otm.OpportunityId) != otm.UserId){
                            oppToOpportunityShareMap.get(otm.OpportunityId).get(otm.UserId).OpportunityAccessLevel = 'Edit';
                            OpportunityShareListToUpdate.add(oppToOpportunityShareMap.get(otm.OpportunityId).get(otm.UserId));
                        }
                    }
                }
            }
        }
        if(OpportunityShareListToUpdate != null && OpportunityShareListToUpdate.size()>0){
            update OpportunityShareListToUpdate;
        }
      }
    }
    /****************************************************************************************************
    *   @Method         :   doDMLOpertnInAfterTgr
    *   @Params         :   void
    *   @Description    :   updateRelatedAccountTeam
    *   @returnType     :   void
    ***************************************************************************************************/
    public static void doDMLOpertnInAfterTgr(){
        try{
            // insert list
            List<Sobject> sobjectToInsertList = new List<Sobject>();
            // update list
            List<Sobject> sobjectToUpdateList = new List<Sobject>();
            // populating values in insert list
            sobjectToInsertList.addAll((List<Sobject>)accntSpltToInsertList);
            sobjectToInsertList.addAll((List<Sobject>)optyTeamMembrToInsertList);
            sobjectToInsertList.addAll((List<Sobject>)accntTeamMembrToInsertList);
            TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = true;
            TriggerHandler.BY_PASS_CONTACT_ON_INSERT = true;
            if(sobjectToInsertList.size() > 0){
                system.debug('#$#$##$#$#$$ '+ sobjectToInsertList);
                Database.SaveResult[] sr = Database.insert(sobjectToInsertList, false);
                for (Integer i = 0; i < sr.size(); i++) {
                	if (!sr[i].isSuccess()) {
                    	for (Database.Error e : sr[i].getErrors()) {
                        	System.debug('########## Exception occurrede in Method doDMLOpertnInAfterTgr : '+ e.getMessage());
                        }
                    }
                }
                updateAccOppShareMethod(sobjectToInsertList);
            }
            if(customeraAcountTOUpdateList.size() > 0){
                update customeraAcountTOUpdateList.values();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            }
            if(opptyToUpdateList.size() > 0){
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
                update opptyToUpdateList.values();
                accntSpltToInsertList = new List<Account_Split__c>();
                optyTeamMembrToInsertList = new List<OpportunityTeamMember>();
                accntTeamMembrToInsertList = new List<AccountTeamMember>();
                opptyToUpdateList = new Map<Id, Opportunity>();
                customeraAcountTOUpdateList = new Map<Id, Account>();
                sobjectToUpdateList = new List<Sobject>();
                sobjectToInsertList = new List<Sobject>();
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
                TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
            }
        }catch(Exception e){
            System.debug('########## Exception occurrede in Method doDMLOpertnInAfterTgr : '+ e.getMessage());
        }
    }
    /****************************************************************************************************
    *   @Method         :   eligibleToCreateAccountSplitRecords
    *   @Params         :
    *   @Description    :
    *   @returnType     :   Boolean
    ***************************************************************************************************/
    private static Boolean eligibleToCreateAccountSplits(Approval__c appObj,String relatedUsrField){
        if(String.valueOf(appObj.Status__c).containsIgnoreCase('approved')){
            if((isChangedObjectsfield(appObj,'Status__c',(Map<Id,Sobject>)oldApprovalStaticMap)  ||
                isChangedObjectsfield(appObj,relatedUsrField,(Map<Id,Sobject>)oldApprovalStaticMap))
                &&  (appObj.get(relatedUsrField) != NULL)
            ){
                System.debug('#################1111111111 true');
                return true;
            }else{
                System.debug('#################22222222222222 false');
                return false;
            }
        }else{
            System.debug('#################333333 false');
            return false;
        }
    }
    /****************************************************************************************************
    *   @Method         :   returnNewAccountSplit
    *   @Params         :
    *   @Description    :
    *   @returnType     :   Account_Split__c
    ***************************************************************************************************/
    private static Account_Split__c returnNewAccountSplit(String rcAccountStatus,Id apprID,String oppotyMarket,String appObjType,Id appObjAccount,Id appObjOwnerId,Id dsrId){
        String marketSegment = '';
        String partnerID = '';
        Id salesAgent;
        Boolean beginDateUpdateOnStatusChange = (rcAccountStatus.equalsIgnoreCase('Paid') ? true : false);
        if(appObjType == 'Direct to VAR'){
            marketSegment = 'Direct-to-VAR - ' + oppotyMarket;
            salesAgent = appObjOwnerId;
        }else if(appObjType == 'VAR to Direct'){
            marketSegment = 'VAR-to-Direct - ' + oppotyMarket;
            salesAgent = dsrId;
        }

        Account_Split__c accSplitObj = new Account_Split__c(Account__c = appObjAccount,Sales_Agent__c = salesAgent,Role__c = 'DSR Shared Agent',
                            PartnerId__c = partnerID,Agent_Credit_Split__c = 'Overlay',beginDateUpdateOnStatusChange__c = beginDateUpdateOnStatusChange,
                            Agent_Credit_Sub_Type__c = 'Overlay Shared',Market_Segment__c = marketSegment,
                            Commission__c = ((oppotyMarket == 'Upmarket' && appObjType == 'VAR to Direct') ? 100 : 80),Begin_Date__c = System.today());
        return accSplitObj;
    }
    /****************************************************************************************************
    *   @Method         :   chnageOpportunityRecordType
    *   @Params         :   Approval__c Trigger.new List
    *   @Description    :
    *   @returnType     :   void
    ***************************************************************************************************/
    public static void chnageOpportunityRecordType(List<Approval__c> approvalNewList,String triggerEvent){
        Schema.DescribeSObjectResult resultOpp = Opportunity.SObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByNameOpp = resultOpp.getRecordTypeInfosByName();
        system.debug('&*&*&*&*&*&*&* ');
        for(Approval__c appObj : approvalNewList){
            system.debug('&*&*&*&*&*&*&* 1111 '+ approvalNewStaticMap.values());
            if(appObj.Type__c == 'Direct to VAR'){
                if(appObj.RecordTypeId != null && rtMapByName.get(appObj.recordtypeId).getName() == 'Channel Cross Sell'){
                    if(appObj.Opportunity__c != NULL){
                        if(opportunityStaticMap != NULL && opportunityStaticMap.containsKey(appObj.Opportunity__c) && opportunityStaticMap.get(appObj.Opportunity__c) != NULL){
                            Opportunity oppty = opportunityStaticMap.get(appObj.Opportunity__c);
                            if(triggerEvent == 'isUpdate'){
                                if(isChangedObjectsfield(appObj,'Status__c',(Map<Id,Sobject>)oldApprovalStaticMap)){
                                    if((appObj.Status__c == 'Returned' || appObj.Status__c == 'Rejected')){
                                        String recordType = oppty.ChangedFromRecordType__c != null ?oppty.ChangedFromRecordType__c : 'Sales Opportunity';
                                        oppty.RecordTypeId = rtMapByNameOpp.get(recordType).getRecordTypeId();
                                        //Relayware
                                        oppty.Partner_Contact__c = null;
                                        oppty.Partner_Owner__c = null;
                                        oppty.Partner_ID__c = null;
                                        oppty.Partner_Account__c = null;
                                        //End
                                    }else if(appObj.Status__c != NULL
                                                && String.valueOf(appObj.Status__c).containsIgnoreCase('Pending')
                                                && (oldApprovalStaticMap.get(appObj.Id).Status__c == 'Returned'
                                                || oldApprovalStaticMap.get(appObj.Id).Status__c == 'Rejected')){
                                        oppty.RecordTypeId = rtMapByNameOpp.get('VAR Opportunity').getRecordTypeId();
                                    }
                                }
                            }else{
                                oppty.RecordTypeId = rtMapByNameOpp.get('VAR Opportunity').getRecordTypeId();
                            }
                            opptyToUpdateList.put(oppty.Id, oppty);
                        }
                    }
                }
            }
        }
        if(opptyToUpdateList.size() > 0){
            system.debug('&*&*&*&*&*&*&* 2222222222');
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
            update opptyToUpdateList.values();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        }
    }

    /****************************************************************************************************
    *   @Method         :   approveVarToDirectAutoApprls [FUTURE METHOD]
    *   @Params         :   Set<Id> : ids of Approval
    *   @Description    :   Method is called when lead is converted and approval records eligible for -
    *                   :   auto approval are passed to get approved automatically from this method
    *   @returnType     :   void
    ***************************************************************************************************/
    @future
    public static void approveVarToDirectAutoApprls(Set<Id> apprvalIdSet){
        List<Approval__c> appList = [SELECT Id,Type__c,Territory_DSR__c FROM Approval__c WHERE ID IN : apprvalIdSet];

        for(Approval__c app : appList){
            if(app.Territory_DSR__c == true){
                app.Status__c = 'Approved';
            }
        }
        if(appList.size() > 0){
            update appList;
        }
    }

    public static Boolean checkForShippingProcessing (Approval__c appr, Map<Id,user> allUserManagerMap) {
        return appr.Record_Type_Name__c == ApprovalHelper.RT_NAME_MANUAL_REFUNDS &&
                allUserManagerMap.get(appr.OwnerId).Division == ApprovalHelper.SHIPPING_TEAM &&
                allUserManagerMap.get(appr.OwnerId).Team__c == ApprovalHelper.SHIPPING_TEAM;
    }

    private static List<String> getExclusionApprovalFields() {
        return new List<String> {
            'Name',
            'Master_Approval__c',
            'IsMultiProductTechnicalApproval__c',
            'Opportunity__c',
            'Account__c',
            'OwnerId',
            'Sign_Up_Purchase_Limit__c',
            'Sign_Up_Purchase_Limit_Office__c',
            'Sign_Up_Purchase_Limit_Contact_Center__c',
            'Sign_Up_Purchase_Limit_Engage_Voice__c',
            'Sign_Up_Purchase_Limit_Engage_Digital__c',
            'Monthly_Credit_Limit__c',
            'Monthly_Credit_Limit_Office__c',
            'Monthly_Credit_Limit_Contact_Center__c',
            'Monthly_Credit_Limit_Engage_Voice__c',
            'Monthly_Credit_Limit_Engage_Digital__c',
            'Monthly_Credit_Limit_for_RC_Events__c',
            'Sign_Up_Purchase_Limit_for_RC_Events__c'
        };
    }

    public static void createTechnicalApprovals(
        List<Approval__c> newApprovals
    ) {
        List<Approval__c> invoiceApprovals = new List<Approval__c>();
        Set<Id> masterOpportunityIds = new Set<Id>();
        Map<String, Opportunity> technicalOppoptunitiesMap = new Map<String, Opportunity>();
        Map<Id, Map<String, Opportunity>> masterOpptyToTechnicalOpportunitiesMap = new Map<Id, Map<String, Opportunity>>();
        for (Approval__c approval : newApprovals) {
            if (ApprovalHelper.isInvoicingRequestApproval(approval) && !approval.IsMultiProductTechnicalApproval__c ) {
                invoiceApprovals.add(approval);
                masterOpportunityIds.add(approval.Opportunity__c);
            }
        }

        List<Opportunity> technicalOpportunities = new OpportunitySelector()
            .selectServiceOpportunitiesByMasterIds(new List<Object>{masterOpportunityIds})
            .executeQuery();

        if (technicalOpportunities.isEmpty() || invoiceApprovals.isEmpty()){
            return;
        }

        for(Approval__c approval : invoiceApprovals) {
            Opportunity opp = opportunityStaticMap.get(approval.Opportunity__c);
            if (opp.Tier_Name__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                technicalOppoptunitiesMap.put(opp.Tier_Name__c, opp);
            }
            for (Opportunity oppty : technicalOpportunities) {
                if (oppty.MasterOpportunity__c == approval.Opportunity__c) {
                    technicalOppoptunitiesMap.put(oppty.Tier_Name__c, oppty);
                }
            }
            masterOpptyToTechnicalOpportunitiesMap.put(approval.Opportunity__c, technicalOppoptunitiesMap);
        }
        createTechnicalApprovals(invoiceApprovals, masterOpptyToTechnicalOpportunitiesMap);
    }

    public static void createTechnicalApprovals(
        List<Approval__c> masterApprovals,
        Map<Id, Map<String, Opportunity>> masterOpptyToTechnicalOpportunitiesMap
    ) {
        List<Schema.SObjectField> approvalFields = AquivaHelper.getAllFieldsForObject('Approval__c');
        List<Approval__c> approvalToCreate = new List<Approval__c>();
        User technicalUser = UserHelper.getMultiproductTechnicalUser();
        for (Approval__c masterApproval : masterApprovals) {
            Map<String, Opportunity> technicalOpportunities = masterOpptyToTechnicalOpportunitiesMap.get(masterApproval.Opportunity__c);
            for (String service: technicalOpportunities.keySet()) {
                Opportunity opp = technicalOpportunities.get(service);
                Approval__c technicalApproval = new Approval__c();
                for (Schema.SObjectField field: approvalFields) {
                    if (!field.getDescribe().isUpdateable() || getExclusionApprovalFields().contains(String.valueOf(field)) || masterApproval.get(field) == null) {
                        continue;
                    }
                    technicalApproval.put(field,masterApproval.get(field));
                }

                technicalApproval.Name = 'Technical Invoice Request: ' + service;
                technicalApproval.MasterApproval__c = masterApproval.Id;
                technicalApproval.IsMultiProductTechnicalApproval__c = true;
                technicalApproval.Opportunity__c = QuoteHelper.CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(service)
                    ? opp.Id
                    : masterApproval.Opportunity__c;
                technicalApproval.Account__c = QuoteHelper.CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(service)
                    ? opp.AccountId
                    : masterApproval.Account__c;
                if (service == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                    technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Office__c;
                    technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Office__c;
                }
                if (service == QuoteHelper.NGBS_RCCC_PRODUCT) {
                    technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Contact_Center__c;
                    technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Contact_Center__c;
                }
                if (service == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
                    technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Engage_Voice__c;
                    technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Engage_Voice__c;
                }
                if (service == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
                    technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Engage_Digital__c;
                    technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Engage_Digital__c;
                }
                if (technicalUser != null) {
                    technicalApproval.OwnerId = technicalUser.Id;
                }

                approvalToCreate.add(technicalApproval);
            }
        }

        if (!approvalToCreate.isEmpty()) {
            Triggers.SwitchOff();
            insert approvalToCreate;
            Triggers.SwitchOn();
        }
    }

    public static void populateAccountLimitFieldOnApproval(List<Approval__c> masterApprovals) {
        List<Approval__c> invoiceApprovals = new List<Approval__c>();
        Set<Id> masterAccountIds = new Set<Id>();
        List<Approval__c> apprToUpdate = new List<Approval__c>();
        for (Approval__c approval : masterApprovals) {
            if (ApprovalHelper.isInvoicingRequestApproval(approval) && !approval.IsMultiProductTechnicalApproval__c ) {
                invoiceApprovals.add(approval);
                masterAccountIds.add(approval.Account__c);
            }
        }

        List<Account> technicalAccounts = new AccountSelector()
            .selectMPTechAccountsByMasterIds(masterAccountIds)
            .executeQuery();

        if (technicalAccounts.isEmpty() || invoiceApprovals.isEmpty()){
            return;
        }

        for (Approval__c approval : invoiceApprovals) {
            Approval__c appr = new Approval__c(Id = approval.Id);
            for (Account account : technicalAccounts) {
                if (account.RC_Service_name__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                    appr.AccountSignUpPurchaseLimitCC__c = account.Sign_Up_Purchase_Limit__c;
                    appr.AccountMonthlyCreditLimitCC__c = account.Monthly_Credit_Limit__c;
                }
                if (account.RC_Service_name__c == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
                    appr.AccountSignUpPurchaseLimitEV__c = account.Sign_Up_Purchase_Limit__c;
                    appr.AccountMonthlyCreditLimitEV__c = account.Monthly_Credit_Limit__c;
                }
                if (account.RC_Service_name__c == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
                    appr.AccountSignUpPurchaseLimitED__c = account.Sign_Up_Purchase_Limit__c;
                    appr.AccountMonthlyCreditLimitED__c = account.Monthly_Credit_Limit__c;
                }
                if (account.RC_Service_name__c == Constants.CONST_RC_EVENT) {
                    appr.Account_Sign_Up_Purchase_Limit_RCEvents__c = account.Sign_Up_Purchase_Limit__c;
                    appr.AccountMonthlyCreditLimitRCEvents__c = account.Monthly_Credit_Limit__c;
                }
            }
            apprToUpdate.add(appr);
        }
        if (!apprToUpdate.isEmpty()) {
            Triggers.SwitchOff();
            update apprToUpdate;
            Triggers.SwitchOn();
        }
    }

    public static void populateInvoiceTerms(List<Approval__c> approvals) {
        List<Approval__c> approvalsToUpdate = new List<Approval__c>();

        for (Approval__c approval : approvals) {
            if (
                ApprovalHelper.isInvoicingRequestApproval(approval)
                && !approval.IsMultiProductTechnicalApproval__c
                && String.isBlank(approval.Invoice_Terms__c)
            ) {
                approvalsToUpdate.add(
                    new Approval__c(
                        Id = approval.Id,
                        Invoice_Terms__c = ApprovalHelper.INVOICING_REQUEST_DEFAULT_TERMS
                    )
                );
            }
        }

        if (!approvalsToUpdate.isEmpty()) {
            Triggers.switchOff();
            update approvalsToUpdate;
            Triggers.switchOn();
        }
    }


    public static Map<Id, List<Approval__c>> getMasterApprovalToTechnicalApprovals(
        List<Approval__c> masterApprovals,
        Boolean isProcessOnlyInvoiceTechnicalApprovals
    ) {
        Set<Id> masterApprovalsIds = new Set<Id>();
        List<Approval__c> technicalApprovals = new List<Approval__c>();
        Map<Id, List<Approval__c>> masterAppToTechnicalApprovals = new Map<Id, List<Approval__c>>();
        for (Approval__c approval : masterApprovals) {
            if ((!isProcessOnlyInvoiceTechnicalApprovals || ApprovalHelper.isInvoicingRequestApproval(approval))
                && !approval.IsMultiProductTechnicalApproval__c && approval.Id != null
            ) {
                masterApprovalsIds.add(approval.Id);
            }
        }

        List<Approval__c> allTechnicalApprovals = new ApprovalSelector()
            .selectServiceApprovalsByMasterId(new List<Object>{masterApprovalsIds})
            .executeQuery();

        if (allTechnicalApprovals.isEmpty()){
            return masterAppToTechnicalApprovals;
        }

        for(Id masterApprovalId : masterApprovalsIds) {
            for (Approval__c ta : allTechnicalApprovals) {
                if (ta.MasterApproval__c == masterApprovalId) {
                    technicalApprovals.add(ta);
                }
            }
            masterAppToTechnicalApprovals.put(masterApprovalId, technicalApprovals);
        }

        return masterAppToTechnicalApprovals;
    }

    public static void updateTechnicalApprovals(
        List<Approval__c> masterApprovals,
        Map<Id, List<Approval__c>> masterAppToTechnicalApprovals
    ) {
        if (masterAppToTechnicalApprovals.isEmpty()) {
            return;
        }
        List<Schema.SObjectField> approvalFields = AquivaHelper.getAllFieldsForObject('Approval__c');
        List<Approval__c> approvalToUpdate = new List<Approval__c>();
        for (Approval__c masterApproval : masterApprovals) {
           List<Approval__c> technicalApprovals = masterAppToTechnicalApprovals.get(masterApproval.Id);
           if (!technicalApprovals.isEmpty()) {
                for (Approval__c technicalApproval: technicalApprovals) {
                    for (Schema.SObjectField field: approvalFields) {
                        if ((!field.getDescribe().isUpdateable() && String.valueOf(field) != STATUS_FIELD )|| getExclusionApprovalFields().contains(String.valueOf(field)) || masterApproval.get(field) == null) {
                            continue;
                        }
                        technicalApproval.put(field, masterApproval.get(field));
                    }
                    if (technicalApproval.Opportunity__r.Tier_Name__c == QuoteHelper.NGBS_OFFICE_PRODUCT) {
                        technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Office__c;
                        technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Office__c;
                    }
                    if (technicalApproval.Opportunity__r.Tier_Name__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
                        technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Contact_Center__c;
                        technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Contact_Center__c;
                    }
                    if (technicalApproval.Opportunity__r.Tier_Name__c == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
                        technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Engage_Voice__c;
                        technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Engage_Voice__c;
                    }
                    if (technicalApproval.Opportunity__r.Tier_Name__c == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
                        technicalApproval.Sign_Up_Purchase_Limit__c = masterApproval.Sign_Up_Purchase_Limit_Engage_Digital__c;
                        technicalApproval.Monthly_Credit_Limit__c = masterApproval.Monthly_Credit_Limit_Engage_Digital__c;
                    }

                    approvalToUpdate.add(technicalApproval);
                }
            }
        }

        if (!approvalToUpdate.isEmpty()) {
            Triggers.SwitchOff();
            try {
                update approvalToUpdate;
            } catch(DmlException ex) {
                masterApprovals.get(0).addError(ex.getdmlMessage(0));
            }
            Triggers.SwitchOn();
        }
    }
    /* GOA 2 - ****************************************************************** END */

    // Case 04458955: Automate Agent Credit Split - START
    public static void AgentCreditSplit(map<Id, Approval__c> approvalNew, Map<Id, Approval__c>approvalOld){

        Map<ID,Schema.RecordTypeInfo> rt_Map = Approval__c.sObjectType.getDescribe().getRecordTypeInfosById();

        map<Id, wrprAgentCredit> mAccIdACWrppr = new map<Id, wrprAgentCredit>();
        map<Id, Id> mApprovalAccount = new map<Id,Id>();
        set<Id> UserIds = new set<Id>();
        set<Id> AgentCreditIds = new set<Id>();

        map<Id,Approval__c> mAppToProcessNew = new map<Id,Approval__c>();


        for(Approval__c approvalObj : approvalNew.values()) {
            Approval__c approvalNewObj = approvalNew.get(approvalObj.Id);
            Approval__c approvalOldObj = approvalOld.get(approvalObj.Id);
            system.debug('RecordTypeId='+approvalObj.recordTypeID);
            if( rt_map.get(approvalObj.recordTypeID).getName() == 'Agent Credit Split' &&
                approvalNewObj.Status__c=='Approved' && approvalOldObj.Status__c!='Approved'){

                UserIds.add(approvalObj.Credit_Split_Between_Agent_2__c);
                UserIds.add(approvalObj.Agent_2_Manager__c);
                AgentCreditIds.add(approvalObj.Agent_Credit__c);

                mAppToProcessNew.put(approvalObj.id, approvalNew.get(approvalObj.Id));

            }
        }

        if(AgentCreditIds.size() > 0){

            Map<Id,User> mUser;
            Map<Id,Agent_Credit__c> mAgentCredit;

            mAgentCredit = new Map<Id, Agent_Credit__c>([
                SELECT Id, Order__c, Account__c, Partner__c, Compensation_Date__c,
                    Agent_Credit_Sub_Type__c, Agent_Credit_Type__c, OwnerId
                FROM Agent_Credit__c
                WHERE Id IN: AgentCreditIds
            ]);

            if(UserIds.size()>0){
                mUser = new Map<Id, User>([
                    SELECT Id, Email, FirstName, LastName, Team__c, Division, UserRole.Name, PID__c
                    FROM User
                    WHERE Id IN: UserIds
                ]);
            }

            for(Approval__c approvalObj : mAppToProcessNew.values()) {

                Id AccId = mAgentCredit.get(approvalObj.Agent_Credit__c).Account__c;

                wrprAgentCredit wAC = new wrprAgentCredit(
                    approvalObj.Agent_Credit__c,
                    AccId,
                    approvalObj.Credit_Split_Between_Agent_1__c,
                    approvalObj.Credit_Split_Between_Agent_2__c,
                    approvalObj.Agent_1_Manager__c,
                    approvalObj.Agent_2_Manager__c,
                    approvalObj.Amount_1_12M_Commission_Split__c,
                    approvalObj.Amount_2_12M_Commission_Split__c,
                    approvalObj.Amount_1_12M_Sales_Split__c,
                    approvalObj.Amount_2_12M_Sales_Split__c,
                    approvalObj.Split_Percentage_for_Agent_1__c,
                    approvalObj.Split_Percentage_for_Agent_2__c);

                mAccIdACWrppr.put(AccId, wAC);
                mApprovalAccount.put(approvalObj.Id, AccId);
            }


            if(mApprovalAccount.size()>0){
                List<Agent_Credit__c> lACNew = new List<Agent_Credit__c>();
                List<Agent_Credit__c> lACUpdate = new List<Agent_Credit__c>();

                for(Id appId : mApprovalAccount.keySet()){

                    Id myAccountId = mApprovalAccount.get(appId);
                    Id myAgentCreditId = mAccIdACWrppr.get(mApprovalAccount.get(appId)).myAgentCredit;
                    Id myNewAgentId = mAccIdACWrppr.get(mApprovalAccount.get(appId)).myAgent2;
                    Id myNewManagerId = mAccIdACWrppr.get(mApprovalAccount.get(appId)).myManager2;

                    Decimal myNewAmountAdd = (mAccIdACWrppr.get(mApprovalAccount.get(appId)).myAmount2); // * mAccIdACWrppr.get(mApprovalAccount.get(appId)).myPercent1)/100;
                    Decimal myNewAmountUpdate = (mAccIdACWrppr.get(mApprovalAccount.get(appId)).myAmount1); // * mAccIdACWrppr.get(mApprovalAccount.get(appId)).myPercent2)/100;
                    Decimal myNewAmountSalesAdd = (mAccIdACWrppr.get(mApprovalAccount.get(appId)).myAmountSales2);
                    Decimal myNewAmountSalesUpdate = (mAccIdACWrppr.get(mApprovalAccount.get(appId)).myAmountSales1);
                    Agent_Credit__c aNew = new Agent_Credit__c(
                        Name = appId,
                        OwnerId = myNewAgentId,
                        Account__c = myAccountId,
                        X12M_Commission_Booking_Amount__c = myNewAmountAdd,
                        X12M_Sales_Booking_Amount__c = myNewAmountSalesAdd,
                        Agent_Credit_Type__c = mAgentCredit.get(myAgentCreditId).Agent_Credit_Type__c,

                        Compensation_Date__c = mAgentCredit.get(myAgentCreditId).Compensation_Date__c,
                        Order__c = mAgentCredit.get(myAgentCreditId).Order__c,
                        Partner__c = mAgentCredit.get(myAgentCreditId).Partner__c,
                        Agent_Credit_Sub_Type__c =mAgentCredit.get(myAgentCreditId).Agent_Credit_Sub_Type__c,

                        Agent_Email__c = mUser.get(myNewAgentId).Email,
                        Agent_First_Name__c = mUser.get(myNewAgentId).FirstName,
                        Agent_Last_Name__c = mUser.get(myNewAgentId).LastName,
                        Agent_Team__c = mUser.get(myNewAgentId).Team__c,
                        Agent_Division__c = mUser.get(myNewAgentId).Division,
                        Agent_Role__c = mUser.get(myNewAgentId).UserRole.Name,
                        Agent_SPID__c = mUser.get(myNewAgentId).PID__c,

                        Agent_Manager_Email__c = mUser.get(myNewManagerId).Email,
                        Agent_Manager_First_Name__c = mUser.get(myNewManagerId).FirstName,
                        Agent_Manager_Last_Name__c = mUser.get(myNewManagerId).LastName
                    );

                    lACNew.add(aNew);

                    Agent_Credit__c aUpdate = new Agent_Credit__c();
                    aUpdate.Id = myAgentCreditId;
                    aUpdate.X12M_Commission_Booking_Amount__c = myNewAmountUpdate;
                    aUpdate.X12M_Sales_Booking_Amount__c = myNewAmountSalesUpdate;

                    lACUpdate.add(aUpdate);

                }

                if(lACUpdate.size()>0){
                    update lACUpdate;
                    System.debug('Agent Credit for Update >>>>> ' + lACUpdate);
                }

                if(lACNew.size()>0){
                    insert lACNew;
                    System.debug('Agent Credit for Createtion >>>>> ' + lACNew);
                }

            }
        }

    }

    public class wrprAgentCredit{

        public Id myAgentCredit         {get;set;}
        public Id myAccountId           {get;set;}
        public Id myAgent1              {get;set;}
        public Id myAgent2              {get;set;}
        public Id myManager1            {get;set;}
        public Id myManager2            {get;set;}
        public Decimal myAmount1        {get;set;}
        public Decimal myAmount2        {get;set;}
        public Decimal myAmountSales1   {get;set;}
        public Decimal myAmountSales2   {get;set;}
        public Decimal myPercent1       {get;set;}
        public Decimal myPercent2       {get;set;}

        public wrprAgentCredit(
            Id AgentCredit, Id AccountId, Id Agent1, Id Agent2, Id Manager1, Id Manager2, Decimal Amount1,
            Decimal Amount2, Decimal AmountSales1, Decimal AmountSales2, Decimal Percent1, Decimal Percent2) {

            this.myAgentCredit  =   AgentCredit;
            this.myAccountId    =   AccountId;
            this.myAgent1       =   Agent1;
            this.myAgent2       =   Agent2;
            this.myManager1     =   Manager1;
            this.myManager2     =   Manager2;
            this.myAmount1      =   Amount1;
            this.myAmount2      =   Amount2;
            this.myAmountSales1 =   AmountSales1;
            this.myAmountSales2 =   AmountSales2;
            this.myPercent1     =   Percent1;
            this.myPercent2     =   Percent2;

        }

    }
    // Case 04458955: Automate Agent Credit Split - END

    public class CustomException extends Exception {}
}