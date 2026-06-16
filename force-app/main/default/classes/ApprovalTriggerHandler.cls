public with sharing class ApprovalTriggerHandler {

    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();
    private static final String LEGAL_REJECTION_TEMPLATE_NAME = 'Legal_Rejection_Email_Template';
    private static final String LEGAL_COMPLETION_TEMPLATE_NAME = 'Legal_Completion_Email_Template';
    private static final String LEGAL_OWNAGE_TEMPLATE_NAME = 'Legal_Ownage_Email_Template';
    private static final String LEGAL_READY_FOR_SIGNATURE_TEMPLATE_NAME = 'Legal_Ready_For_Signature_Email_Template';
    private static final String LEGAL_REQUEST_EMAIL_TEMPLATE = 'Legal_Request_Email_Template';
    private static final String LEGAL_APPROVAL_REJECTED_BY_SALES_MANAGER_TEMPLATE = 'Legal_Approval_Rejected_By_Sales_Manager';
    private static final String LEGAL_APPROVAL_RECALLED_TEMPLATE = 'Legal_Approval_Recalled';
    private static final String LEGAL_APPROVAL_REQUIRED_TEMPLATE = 'Legal_Approval_Required';
    private static final String LEGAL_APPROVAL_GRANTED_BY_SALES_MANAGER_TEMPLATE = 'Legal_Approval_Granted_By_Sales_Manager';
    private static final String LEGAL_APPROVAL_STATUS_CHANGES_DUE_TO_OPP_CHANGES = 'Legal_Approval_Status_Changes_Due_To_Opp_Changes';
    private static final String INVOICING_REQUEST_INTERM_APPROVED_TEMPLATE = 'Invoicing_Request_Interm_Approved';
    private static final String INVOICING_REQUEST_REJECTED = 'Invoicing_Request_Rejected';
    private static final String APPROVAL_EMAIL_INVOICE = 'Invoice_Group_Request';
    private static final String INVOICE_REQUEST_FINAL_APPROVAL = 'Invoice_Request_Final_Approval';
    private static final String INVOICING_REQUEST_QUOTE_ACTIVATION = 'Invoicing_Request_Quote_Activation_Notification';
    private static final String DNB_PENDING_MAIL = 'Invoice_Group_Request_DNB';
    private static final String DIRECT_DEBIT_REQUEST_FINAL_APPROVAL = 'Direct_Debit_Request_Final_Approval';
    private static final String DIRECT_DEBIT_REQUEST_INTERM_APPROVED = 'Direct_Debit_Request_Interm_Approved';
    private static final String DIRECT_DEBIT_REQUEST_REJECTED = 'Direct_Debit_Request_Rejected';
    private static final String INVOICE_ON_BEHALF_REQUEST_FINAL_APPROVAL = 'Invoice_On_Behalf_Request_Final_Approval';
    private static final String INVOICE_ON_BEHALF_REQUEST_INTERM_APPROVED = 'Invoice_On_Behalf_Request_Interm_Approved';
    private static final String INVOICE_ON_BEHALF_REQUEST_REJECTED = 'Invoice_On_Behalf_Request_Rejected';
    private static final String INVOICE_WHOLESALE_REQUEST_FINAL_APPROVAL = 'Invoice_Wholesale_Request_Final_Approval';
	private static final String INVOICE_WHOLESALE_REQUEST_INTERM_APPROVED = 'Invoice_Wholesale_Request_Interm_Approved';
	private static final String INVOICE_WHOLESALE_REQUEST_REJECTED = 'Invoice_Wholesale_Request_Rejected';
    private static final String DNB_PENDING_MAIL_INVOICE= 'Invoice_Group_Request_DNB';
    private static final String DNB_PENDING_MAIL_BOB = 'Bill_On_Behalf_DNB';
    private static final String DNB_PENDING_MAIL_WHOLESALE = 'Wholesale_DNB';
    private static final Set<String> CACHED_TEMPLATES = new Set<String>{
        LEGAL_REJECTION_TEMPLATE_NAME,
        LEGAL_COMPLETION_TEMPLATE_NAME,
        LEGAL_OWNAGE_TEMPLATE_NAME,
        LEGAL_READY_FOR_SIGNATURE_TEMPLATE_NAME,
        LEGAL_REQUEST_EMAIL_TEMPLATE,
        LEGAL_APPROVAL_REJECTED_BY_SALES_MANAGER_TEMPLATE,
        LEGAL_APPROVAL_STATUS_CHANGES_DUE_TO_OPP_CHANGES,
        LEGAL_APPROVAL_GRANTED_BY_SALES_MANAGER_TEMPLATE,
        LEGAL_APPROVAL_RECALLED_TEMPLATE,
        LEGAL_APPROVAL_REQUIRED_TEMPLATE,
        INVOICING_REQUEST_INTERM_APPROVED_TEMPLATE,
        INVOICING_REQUEST_REJECTED,
        APPROVAL_EMAIL_INVOICE,
        INVOICE_REQUEST_FINAL_APPROVAL,
        INVOICING_REQUEST_QUOTE_ACTIVATION,
        DNB_PENDING_MAIL_INVOICE,
        DNB_PENDING_MAIL_BOB,
        DNB_PENDING_MAIL_WHOLESALE
    };

    private static final String RC_ACC_STATUS_PAID = 'Paid';
    private static final String RC_ACC_STATUS_DISABLED = 'Disabled';
    private static final String RC_ACC_STATUS_CANCELLED = 'Canceled';

    private static final String APPROVAL_ACC_TYPE_POC = 'POC';
    private static final String APPROVAL_ACC_TYPE_EXISTING = 'Existing';
    private static final String APPROVAL_ACC_TYPE_NEW = 'New';

    private static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_STATUS_REQUIRED = 'Required';

    private static final String APPROVAL_STATUS_NEW = 'New';

    private static final String POC_ACCOUNT_APPROVAL_RT_NAME = 'POC Account';
    private static final String INVOICING_REQUEST_APPROVAL_RT_NAME = 'Invoicing Request';
    private static final String INVOICE_ON_BEHALF_REQUEST_APPROVAL_RT_NAME = 'Invoice-on-behalf Request';
    private static final String INVOICE_WHOLESALE_REQUEST_APPROVAL_RT_NAME = 'Invoice Wholesale Request';

    public static final String MCLESS500SULESS150K = 'MonthlyCreditLessThan500SignUpLimitLessThan150k';
    public static final String MCLESS500SUMORE150KLESS750K = 'MonthlyCreditLessThan500SignUpLimitMoreThan150KLessThan750k';
    public static final String MCLESS500SUMORE750K = 'MonthlyCreditLessThan500SignUpLimitMoreThan750k';
    public static final String MCMORE500SULESS10K = 'MonthlyCreditMoreThan500SignUpLimitLessThan10k';
    public static final String MCMORE500SUMORE10KLESS150K = 'MonthlyCreditMoreThan500SignUpLimitMoreThan10kLessThan150k';
    public static final String MCMORE500SUMORE150KLESS750K = 'MonthlyCreditMoreThan500SignUpLimitMoreThan150kLessThan750k';
    public static final String MCMORE500SUMORE750K = 'MonthlyCreditMoreThan500SignUpLimitMoreThan750k';
    public static final String FINANCEINVOICE = 'Finance Invoice Approval';
    public static final String APPROVAL_QUEUEABLE_JOB = 'ApprovalQueueable';
    public static Boolean sendOutForSignatureOverride = false;

    public static final String MRRLESS500 = 'MRRLess500';
    public static final String MRRMORE500LESS10K = 'MRRMore500Less10K';
    public static final String MRRMORE10KLESS150K = 'MRRMore10KLess150K';
    public static final String MRRMORE150KLESS750K = 'MRRMore150KLess750K';
    public static final String MRRMORE750K = 'MRRMore750K';

    private static Map<String, EmailTemplate> emailTemplatesCache;
    @TestVisible
    private static Map< Id, List<Transaction_History__c> > approvalIdToTransactionHistoryMap;
    @TestVisible
    private static List<Approval__c> approvalsToProcess;
    private static Map<String, String> userHierarchyRoleCache;

    public static final String LEGAL_APPROVAL_SLA_TYPE_STANDARD = 'Standard';
    public static final String LEGAL_APPROVAL_SLA_TYPE_STANDARD_VIDEO = 'Standard-Video';
    public static final String LEGAL_APPROVAL_SLA_TYPE_NONSTANDARD = 'Non-Standard';
    private static Map<Id, Map<String, Object>> accountIdToLastApprovedApprovalFromAccount = new Map<Id, Map<String, Object>>();
    public static Map<Id, Account> customerToPartnerAccounts = new Map<Id, Account>();
    public static Map<Id, List<Approval__c>> masterApprovalToTechnicalApprovals = new Map<Id, List<Approval__c>>();

    public static final String LEGAL_APPROVAL_SLA_SERVICE_RC_OFFICE = 'RC Office';
    public static final String LEGAL_APPROVAL_SLA_SERVICE_RC_OFFICE_VIDEO = 'RC Video';
    public static final String LEGAL_APPROVAL_SLA_SERVICE_CC_CORE = 'CC Core';
    public static final String LEGAL_APPROVAL_SLA_SERVICE_CC_PD = 'CC Predictive Dialing';
    public static final String LEGAL_APPROVAL_SLA_SERVICE_CC_WFO = 'CC WFO';

    private static final String SE_ROLE = 'Solutions Engineer (Primary)';
    private static final String CUSTOMER_EXPERIENCE_SE_ROLE = 'Customer Experience SE';
    private static Integer THRESHHOLD_DL_NO = 20;

    public static final Map<Schema.SObjectField, Map<String, List<String>>> fieldToServiceTypeListMap =
        new Map<Schema.SObjectField, Map<String, List<String>>> {
            Approval__c.SLA__c => new Map<String, List<String>> {
                LEGAL_APPROVAL_SLA_TYPE_STANDARD => new List<String> { LEGAL_APPROVAL_SLA_SERVICE_RC_OFFICE },
                LEGAL_APPROVAL_SLA_TYPE_STANDARD_VIDEO => new List<String> { LEGAL_APPROVAL_SLA_SERVICE_RC_OFFICE, LEGAL_APPROVAL_SLA_SERVICE_RC_OFFICE_VIDEO },
                LEGAL_APPROVAL_SLA_TYPE_NONSTANDARD => new List<String> { LEGAL_APPROVAL_SLA_SERVICE_RC_OFFICE }
            },
            Approval__c.SLA_Contact_Center__c => new Map<String, List<String>> {
                LEGAL_APPROVAL_SLA_TYPE_STANDARD => new List<String> { LEGAL_APPROVAL_SLA_SERVICE_CC_CORE, LEGAL_APPROVAL_SLA_SERVICE_CC_PD, LEGAL_APPROVAL_SLA_SERVICE_CC_WFO },
                LEGAL_APPROVAL_SLA_TYPE_NONSTANDARD => new List<String> { LEGAL_APPROVAL_SLA_SERVICE_CC_CORE, LEGAL_APPROVAL_SLA_SERVICE_CC_PD, LEGAL_APPROVAL_SLA_SERVICE_CC_WFO }
            }
        };

    private static Map<Id, Approval__c> approvalRelatedOpportunitiesAndQuotesCache;
    private static Map<Id, Id> approvalProcessInstanceMap = new Map<Id, Id>();
    @TestVisible
    private static Set<Id> invoiceRequestIds = new Set<Id>();
    private static Map<Id,Double> creditCheckForApprovalMap = new Map<Id, Double>();
    @TestVisible
    private static Map<Id, Approval__c> convertedCurrencyApprovals;
    private static Map<String, String> approverMap = new Map<String, String>();
    @TestVisible
    private static Map<Id, String> paymentPlans = new Map<Id, String>();



    public static Map<Id, Approval__c> getApprovalRelatedOpportunitiesAndQuotes(List<Approval__c> approvals) {
        if (approvalRelatedOpportunitiesAndQuotesCache == null)
        {
            approvalRelatedOpportunitiesAndQuotesCache = new Map<Id, Approval__c>([
                SELECT Id,
                    Opportunity__r.Id, Opportunity__r.Effective_No_of_Employees_Range__c,
                    Opportunity__r.Name, Opportunity__r.OwnerId, Opportunity__r.Owner.Email,
                    Opportunity__r.Type, Opportunity__r.X12_Month_Booking__c,
                    Opportunity__r.Estimated_12M_Contact_Center_Pipeline__c,
                    Opportunity__r.EstimatedProfessionalServices12Month__c,
                    Opportunity__r.Total_Potential_Users__c,
                    Quote__r.Id, Quote__r.Name, Quote__r.Special_Terms__c,
                    Opportunity__r.AccountId, Opportunity__r.Account.Name,
                    Opportunity__r.Brand_Name__c
                FROM Approval__c
                WHERE Id IN :approvals]);
        }
        return approvalRelatedOpportunitiesAndQuotesCache;
    }

    public static Set<Id> getUserIdsFromGroup(Set<Id> groupIds){
        // store the results in a set so we don't get duplicates
        Set<Id> result = new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxys = new Set<Id>();
        // Loop through all group members in a group
        for(GroupMember m : [Select Id, UserOrGroupId From GroupMember Where GroupId in :groupIds])
        {
            // If the user or group id is a user
            if(((String)m.UserOrGroupId).startsWith(userType))
            {
                result.add(m.UserOrGroupId);
            }
            // If the user or group id is a group
            // Note: there may be a problem with governor limits if this is called too many times
            else if (((String)m.UserOrGroupId).startsWith(groupType))
            {
                // Call this function again but pass in the group found within this group
                groupIdProxys.add(m.UserOrGroupId);
            }
        }
        if(groupIdProxys.size() > 0)
        {
            result.addAll(getUSerIdsFromGroup(groupIdProxys));
        }
        return result;
    }

    public static EmailTemplate getEmailTemplate(String name) {
        if(null == emailTemplatesCache){
            emailTemplatesCache = new Map<String, EmailTemplate>();
            List<EmailTemplate> templates = [SELECT ID, HtmlValue, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName IN: CACHED_TEMPLATES];
            for(EmailTemplate t: templates) {
                emailTemplatesCache.put(t.DeveloperName, t);
            }
        }
        return emailTemplatesCache.get(name);
    }

    public static String getUserHierarchyRole(Id userId) {
        if (null == userHierarchyRoleCache) {
            Id currentUserId = UserInfo.getUserId();
            userHierarchyRoleCache = new Map<String, String>();
            User usr = [SELECT Hierarchy_Role__c FROM User WHERE Id = :currentUserId];
            String role = usr.Hierarchy_Role__c;
            userHierarchyRoleCache.put(currentUserId, role);
        }
        return userHierarchyRoleCache.get(userId);
    }

    public class PrepareData extends Triggers.TriggerHandlerBase {
        override public void handle() {
            prepareUsers();

            if (!Trigger.isDelete) {
                prepareApprovalsAndTransactions();
                getCustomerToPartnerAccounts();
                masterApprovalToTechnicalApprovals = ApprovalHelperCls.getMasterApprovalToTechnicalApprovals(
                    (List<Approval__c>)Trigger.new,
                    true
                );
            } else if (!System.isFuture()) {
                masterApprovalToTechnicalApprovals = ApprovalHelperCls.getMasterApprovalToTechnicalApprovals(
                    (List<Approval__c>)Trigger.old,
                    false
                );
            }
        }

        private void prepareUsers() {
            Set<Id> userIdsToGet = new Set<Id>();
            userIdsToGet.add(UserInfo.getUserId());
            userIdsToGet.addAll(getOwnersSet());
            userIdsToGet.addAll(getCreatedByIdSet());
            userIdsToGet.addAll(getRefundOwnerIds());
            UserHelper.getORQueryUsers(userIdsToGet);
        }

        private Set<Id> getOwnersSet() {
            List<Approval__c> approvals = new List<Approval__c>();
            Set<Id> ownersSet = new Set<Id>();
            if (Trigger.new != null) {
                approvals = (List<Approval__c>)Trigger.new;
            } else {
                approvals = (List<Approval__c>)Trigger.old;
            }
            for (Approval__c appr : approvals) {
                ownersSet.add(appr.OwnerId);
            }
            return ownersSet;
        }

        private Set<Id> getCreatedByIdSet() {
            List<Approval__c> approvals = new List<Approval__c>();
            Set<Id> createdByIdSet = new Set<Id>();
            if (Trigger.new != null) {
                approvals = (List<Approval__c>)Trigger.new;
            } else {
                approvals = (List<Approval__c>)Trigger.old;
            }
            for (Approval__c appr : approvals) {
                createdByIdSet.add(appr.CreatedById);
            }
            return createdByIdSet;
        }

        private Set<Id> getRefundOwnerIds() {
            List<Approval__c> approvals = new List<Approval__c>();
            Set<Id> userIdsToQuery = new Set<Id>();
            if (Trigger.new != null) {
                approvals = (List<Approval__c>)Trigger.new;
            } else {
                approvals = (List<Approval__c>)Trigger.old;
            }
            for (Approval__c appr : approvals) {
                if (appr.Refund_Owner__c == null) {
                    continue;
                }
                userIdsToQuery.add(appr.Refund_Owner__c);
            }
            return userIdsToQuery;
        }

        private void prepareApprovalsAndTransactions() {
            approvalIdToTransactionHistoryMap = new Map< Id, List<Transaction_History__c> >();
            Set<Id> editedApprovalsIdSet = new Set<Id>();
            approvalsToProcess = (List<Approval__c>)Trigger.new;
            for(Approval__c a : approvalsToProcess) {
                // we have to populate this since legacy logic could rely on having null Ids in the map
                if(!approvalIdToTransactionHistoryMap.containsKey(a.Id)) {
                    approvalIdToTransactionHistoryMap.put(a.Id, new List<Transaction_History__c>());
                }
                //skip approvals with empty ids.
                if (String.isBlank(a.Id)) {
                    continue;
                }
                editedApprovalsIdSet.add(a.Id);
            }
            if (editedApprovalsIdSet.isEmpty()) {
                return;
            }

            // fill approvalIdToTransactionHistoryMap with Transaction Histories list by Approval Id they are related to
            for(Transaction_History__c th : [SELECT Id, RefundAmount__c, Approval__r.Id
                                             FROM Transaction_History__c
                                             WHERE Approval__r.Id IN :editedApprovalsIdSet]) {
                approvalIdToTransactionHistoryMap.get(th.Approval__r.Id).add(th);
            }
        }

        private void getCustomerToPartnerAccounts() {
            Set<Id> partnersIds = new Set<Id>();
            for (Approval__c appr : (List<Approval__c>)Trigger.new) {
                Boolean isInvoiceOnBehalfRequest =
                    appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST;
                Boolean isInvoiceWholesaleRequest =
                    appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST;
                Boolean isSwitchToInvoiceWithPartner =
                    appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST
                        && String.isNotBlank(appr.SwitchInvoicePartnerAccount__c);

                if ((isInvoiceOnBehalfRequest || isInvoiceWholesaleRequest || isSwitchToInvoiceWithPartner)
                    && String.isNotBlank(appr.Account__c)
                    ) {
                    partnersIds.add(appr.SwitchInvoicePartnerAccount__c);
                }
            }

            if (!partnersIds.isEmpty()) {
                Map<Id, Account> partnerIdToAccounts = new Map<Id, Account>(
                    (List<Account>) new AccountSelector()
                        .selectPartnerAccountsByIds(new List<Object>{partnersIds})
                        .subselect(new AccountContactRoleSelector()
                            .selectAccountContactRoles()
                            .selectFields(new List<String>{
                                'ContactId'
                            })
                            .setCondition('Role = \'Accounts Payable\''))
                        .executeQuery()
                );
                for (Approval__c appr: (List<Approval__c>)Trigger.new) {
                    customerToPartnerAccounts.put(
                        appr.Account__c,
                        partnerIdToAccounts.get(appr.SwitchInvoicePartnerAccount__c)
                    );
                }
            }
        }
    }

    public abstract class LegalApprovalHandler extends Triggers.TriggerHandlerBase {
        public List<Approval__c> recordsToProcess = new List<Approval__c>();

        override abstract public void handle();
        public LegalApprovalHandler(List<sObject> recList) {
            for(Approval__c appr : (List<Approval__c>) triggerRecords) {
                if(appr.RecordTypeId == ApprovalHelperCls.RT_ID_ENGAGE_LEGAL) {
                    recordsToProcess.add(appr);
                }
            }
        }

        public LegalApprovalHandler() {
            this(Trigger.isDelete ? Trigger.old : Trigger.new);
        }

        public LegalApprovalHandler(TriggerOperation operationType, List<Approval__c> newList) {
            super(true, operationType, newList);
        }
    }

    public class StatusChangeValidator extends LegalApprovalHandler {

        public override void handle(){
            legalApprovalTerminalStatusCheck(recordsToProcess);
            refundApprovalStatusCheck(approvalsToProcess);
        }

        private void legalApprovalTerminalStatusCheck(List<Approval__c> approvals){
            for(Approval__c appr : approvals) {	// Trigger.New
                if(!ProfileHelper.isCurrentUserSysAdmin()
                        && (super.isChangedFieldFrom(appr, Approval__c.Status__c, ApprovalHelper.STATUS_COMPLETED) && appr.Status__c != ApprovalHelper.STATUS_REJECTED
                        || super.isChangedFieldFrom(appr, Approval__c.Status__c, ApprovalHelper.STATUS_REJECTED) && appr.Status__c != ApprovalHelper.STATUS_COMPLETED)) {
                    appr.addError('This approval is already in terminal status.');
                }
            }
        }

        private void refundApprovalStatusCheck(List<Approval__c> approvals){
            for(Approval__c appr : approvals) {	// Trigger.New
                if(appr.RecordTypeId == ApprovalHelper.RT_ID_REFUND_APPROVAL) {
                    validateApprovalStatusChange(appr);
                }
            }
        }

        // Gets currently modified approval and checks whether its status can be changed
        private void validateApprovalStatusChange(Approval__c appr) {
            if (!approvalIdToTransactionHistoryMap.get(appr.Id).isEmpty()) {
                if(appr.Status__c.equals(ApprovalHelper.STATUS_RECALLED)) {
                    appr.addError(ApprovalHelper.REFUND_APPROVAL_RECALL_ERROR);
                } else if(appr.Status__c.equals(ApprovalHelper.STATUS_REJECTED)) {
                    appr.addError(ApprovalHelper.REFUND_APPROVAL_REJECT_ERROR);
                } else if(appr.Status__c.equals(ApprovalHelper.STATUS_RETURNED)) {
                    appr.addError(ApprovalHelper.REFUND_APPROVAL_RETURN_ERROR);
                }
            }
        }

        public StatusChangeValidator() {
            super();
            // construct
        }

        public StatusChangeValidator(TriggerOperation operationType, List<Approval__c> newList) {
            super(operationType, newList);
        }
    }

    public class RequestCompleteDateFiller extends LegalApprovalHandler {
        public override void handle(){
            for(Approval__c appr: recordsToProcess) {
                if(super.isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_COMPLETED)) {
                    appr.Completed_Date__c = Date.today();
                }
            }
        }

        public RequestCompleteDateFiller() {
            super();
            // construct
        }
    }

    // Tested in ApprovalHelperClsTest.testRecallingAndResubmittingOfEL()
    public class LegalRequestRecalledApproval extends LegalApprovalHandler {

        // According to B-4694, Chief Revenue Officer, David Sipes is L2 approver
        // private Id chiefRevenueOfficerId = Id.valueOf(HardcodedIdsMapper.getMatchedObjectId('00580000001upqp'));
        // replacing David Sipes id with Anand Eswaran (B-10507)
        private Id chiefRevenueOfficerId = (Id) (new UserSelector()
            .selectUserByName(new List<Object> {
                new Set<String> { 'Phil Sorgen' }
            })
            .executeQuery()
            .get(0)).Id;
        private Id currentUserId = Id.valueOf(UserInfo.getUserId());

        private Map<Id, User> approvers {
            get {
                if (null == approvers) {
                    this.approvers = UserHelper.getORQueryUsers(
                            new Set<Id>{chiefRevenueOfficerId, currentUserId}
                    );
                }
                return this.approvers;
            }
            set;
        }

        private List<String> legalQueueEmails {
            get {
                if (null == legalQueueEmails) {
                    legalQueueEmails = new List<String>();
                    for (User legal : ApprovalHelperCls.findLegals()) {
                        this.legalQueueEmails.add(legal.Email);
                    }
                }
                return this.legalQueueEmails;
            }
            set;
        }

        private List<Id> legalQueueUserIds {
            get {
                if (null == legalQueueUserIds) {
                    legalQueueUserIds = new List<Id>();
                    for (User legal : ApprovalHelperCls.findLegals()) {
                        if (String.IsNotBlank(legal.Email)) {
                            this.legalQueueUserIds.add(legal.Id);
                        }
                    }
                }
                return this.legalQueueUserIds;
            }
            set;
        }

        private String currentUserFullName {
            get {
                if (null == currentUserFullName) {
                    currentUserFullName = String.format('{0} {1}',
                            new List<String>{UserInfo.getFirstName(), UserInfo.getLastName()});
                }
                return this.currentUserFullName;
            }
            set;
        }

        private EmailTemplate mailTemplate {
            get {
                if (null == mailTemplate) {
                    mailTemplate = ApprovalTriggerHandler.getEmailTemplate(LEGAL_APPROVAL_RECALLED_TEMPLATE);
                }
                return this.mailTemplate;
            }
            set;
        }

        public override void handle() {
            if (recordsToProcess.isEmpty()) {
                return;
            }
            processOpptys();
            sendNotifications();
        }

        private void processOpptys() {
            List<Opportunity> opptys = new List<Opportunity>();
            for (Approval__c appr : recordsToProcess) {
            if(appr.Opportunity__c != null){
                opptys.add(new Opportunity(Id = appr.Opportunity__c, Special_TOS_Approval__c = null));
                }
            }
            update opptys;
        }

        private void configureEmail(ApprovalHelperCls.Email mail, Approval__c appr) {
            mail.addParameter('User.Name', currentUserFullName);
            mail.addParameter('Approval.Name', appr.Name);
            mail.addParameter('Approval.Link', BASE_URL + '/' + appr.Id);
        }

        private void sendNotifications() {

            String managerEmail = approvers.get(currentUserId).Manager.Email;
            Id managerId = approvers.get(currentUserId).Manager.Id;
            String chiefRevenueOfficerEmail = approvers.get(chiefRevenueOfficerId).Email;

            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Map<Id, Approval__c> owners = new Map<Id, Approval__c>();

            Map<Approval__c, String> approvalsOwnedByUsers = new Map<Approval__c, String>();
            List<Approval__c> approvalsOwnedByLegalQueue = new List<Approval__c>();
            for (Approval__c appr : recordsToProcess) {
                if (((String) appr.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())) {
                    if (currentUserId != appr.OwnerId) {
                        owners.put(appr.OwnerId, appr);
                    } else if (isChangedFieldFrom(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_PENDING_L1_APPROVAL)
                            && String.isNotEmpty(managerEmail)) {
                        // If current user is EL owner and Status of Approval = PendingL1Approval
                        // then send notification to user manager
                        ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(managerId,
                                mailTemplate.Subject, mailTemplate.HtmlValue);
                        configureEmail(mail, appr);
                        mails.addAll(mail.getMails());
                    } else if (isChangedFieldFrom(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_PENDING_L2_APPROVAL)
                            && String.isNotEmpty(chiefRevenueOfficerEmail)) {
                        // If current user is EL owner and Status of Approval = PendingL2Approval
                        // then send notification to David Sipes
                        ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(chiefRevenueOfficerId,
                                mailTemplate.Subject, mailTemplate.HtmlValue);
                        configureEmail(mail, appr);
                        mails.addAll(mail.getMails());
                    }
                } else {
                    approvalsOwnedByLegalQueue.add(appr);
                }
            }

            for (User user : UserHelper.getORQueryUsers(owners.keySet()).values()) {
                approvalsOwnedByUsers.put(owners.get(user.Id), user.Id);
            }

            for (Approval__c appr : approvalsOwnedByUsers.keySet()) {
                // Send notification to EL owner
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(approvalsOwnedByUsers.get(appr),
                        mailTemplate.Subject, mailTemplate.HtmlValue);
                configureEmail(mail, appr);
                mails.addAll(mail.getMails());
            }

            for (Approval__c appr : approvalsOwnedByLegalQueue) {
                // Send notification to legal queue
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(legalQueueUserIds,
                        mailTemplate.Subject, mailTemplate.HtmlValue);
                configureEmail(mail, appr);
                mails.addAll(mail.getMails());
            }

            if (!mails.isEmpty()) {
                Messaging.sendEmail(mails);
            }
        }

        public LegalRequestRecalledApproval() {
            super();
            List<Approval__c> legalApprovals = new List<Approval__c>(recordsToProcess);
            recordsToProcess = new List<Approval__c>();
            if (Trigger.isBefore && Trigger.isInsert) {
                return;
            }
            for (Approval__c appr: legalApprovals) {
                if (isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_RECALLED)) {
                    recordsToProcess.add(appr);
                }
            }
        }
    }

    public abstract class LegalRequestApprovalProcess extends LegalApprovalHandler {
        protected abstract Boolean isProceed(Approval__c record);

        protected virtual List<ApprovalHelperCls.Email> getEmail(Approval__c appr, Quote quote, Opportunity oppty){
            throw new AquivaHelper.AquivaException('getEmail is not defined!');
            return null;
        }

        protected virtual String getEmailTemplateName(){
            throw new AquivaHelper.AquivaException('getEmailTemplateName is not defined!');
            return null;
        }

        protected virtual List<User> getUsersToSendEmailsTo(){
            throw new AquivaHelper.AquivaException('getUsersToSendEmailsTo is not defined!');
            return null;
        }

        protected EmailTemplate template {
            get{
                if(null == this.template){
                    this.template = getEmailTemplate(getEmailTemplateName());
                }
                return this.template;
            }
            set;
        }

        protected String baseUrl {
            get{
                if(null == baseUrl){
                    this.baseUrl = URL.getOrgDomainUrl().toExternalForm();
                }
                return this.baseUrl;
            }
            set;
        }

        protected List<String> emails {
            get{
                if(null == emails){
                    emails = new List<String>();
                    List<User> users = getUsersToSendEmailsTo();
                    for(User u: users) {
                        this.emails.add(u.EMail);
                    }
                }
                return this.emails;
            }
            private set;
        }

        protected List<Id> EmailRecipientsIds {
            get{
                if(null == EmailRecipientsIds){
                    EmailRecipientsIds = new List<Id>();
                    List<User> users = getUsersToSendEmailsTo();
                    for(User u: users) {
                        if (String.IsNotBlank(u.Email)) {
                            this.EmailRecipientsIds.add(u.Id);
                        }
                    }
                }
                return this.EmailRecipientsIds;
            }
            private set;
        }

        protected String getCurrentUserName(){
            return String.format('{0} {1}', new List<String>{ UserInfo.getFirstName(), UserInfo.getLastName() } );
        }

        private Boolean isInApproval(Approval__c record) {
            return Approval.isLocked(record.Id);
        }

        protected void sendNotifications(List<Approval__c> requests) {
            // Email notification
            List<ApprovalHelperCls.Email> emailMessages = new List<ApprovalHelperCls.Email>();

            Map<Id, Approval__c> approvalsWithOpportunitiesAndQuotesInfo = getApprovalRelatedOpportunitiesAndQuotes(requests);

            for(Approval__c req: requests) {
                Approval__c fulfilledApproval = approvalsWithOpportunitiesAndQuotesInfo.get(req.Id);
                emailMessages.addAll(getEmail(req, fulfilledApproval.Quote__r, fulfilledApproval.Opportunity__r));
            }

            try {
                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
                for(ApprovalHelperCls.Email email: emailMessages) {
                    if (email instanceOf ApprovalHelperCls.InternalEmail) {
                        messages.addAll(((ApprovalHelperCls.InternalEmail)email).getMails());
                    } else {
                        messages.add(email.getMail());
                    }
                }
                Messaging.sendEmail(messages);
            } catch (Exception ex) {
                throw new AquivaHelper.AquivaException(ex.getMessage());
            }
        }

        public LegalRequestApprovalProcess() {
            super();
            List<Approval__c> legalApprovals = new List<Approval__c>(recordsToProcess);
            recordsToProcess = new List<Approval__c>();
            if(Trigger.isBefore && Trigger.isInsert){
                return;
            }
            for(Approval__c appr: legalApprovals) {

                System.debug('Checking if in Apptoval' + isInApproval(appr));
                System.debug('Checking if is proceed' + isProceed(appr));
                Boolean isProceed = isInApproval(appr) && isProceed(appr);
                if(isProceed){
                    recordsToProcess.add(appr);
                }
            }
        }
    }

    public class LegalRequestRejectedApproval extends LegalRequestApprovalProcess {
        protected override String getEmailTemplateName(){
            return LEGAL_APPROVAL_REJECTED_BY_SALES_MANAGER_TEMPLATE;
        }

        protected override Boolean isProceed(Approval__c record) {
            return isChangedFieldTo(record, Approval__c.Status__c, ApprovalHelperCls.STATUS_REJECTED);
        }

        override public void handle() {
            if(recordsToProcess.isEmpty()){
                return;
            }
            processOpptys();
            sendNotifications(recordsToProcess);
        }

        private void processOpptys() {
            List<Opportunity> opptys = new List<Opportunity>();
            for(Approval__c appr: recordsToProcess) {
                if(appr.Opportunity__c != null){
                opptys.add(new Opportunity(Id = appr.Opportunity__c, Special_TOS_Approval__c = null));
                }
            }
            update opptys;
        }

        protected override List<ApprovalHelperCls.Email> getEmail(Approval__c appr, Quote quote, Opportunity oppty) {
            List<ApprovalHelperCls.Email> result = new List<ApprovalHelperCls.Email>();
            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(oppty.Owner.Id, template.SUbject, template.HtmlValue);

            mail.addParameter('User.Name', getCurrentUserName());
            mail.addParameter('Approval__c.Type__c', appr.Type__c);
            mail.addParameter('Opportunity.Name', oppty.Name);
            mail.addParameter('Account.Name', oppty.Account.Name);

            result.add(mail);
            return result;
        }

        public LegalRequestRejectedApproval() {
            super();
        }
    }

    public class LegalRequestPassApproval extends LegalRequestApprovalProcess {
        private String repName;
        private UserRole role;
        private EmailTemplate approvalGrantedTemplate;

        private Group legalQueue{
            get{
                return GroupHelper.groupDeveloperNameToGroup.get(GroupHelper.GROUP_SALES_DESK_LEGAL_QUEUE);
            }
            set;
        }

        protected override List<User> getUsersToSendEmailsTo(){
            return getLegalUsers();
        }

        private List<User> getLegalUsers(){
            Set<Id> legalUsersIds = getUserIdsFromGroup(new Set<Id>{this.legalQueue.Id});
            if(legalUsersIds.isEmpty()){
                throw new AquivaHelper.AquivaException('No users found in Legal Group.');
            }
            return UserHelper.getORQueryUsers(legalUsersIds).values();
        }

        protected override String getEmailTemplateName(){
            return LEGAL_REQUEST_EMAIL_TEMPLATE;
        }

        protected override Boolean isProceed(Approval__c record) {
            if(null == legalQueue){
                return false;
            }
            return isChangedFieldTo(record, Approval__c.OwnerId, legalQueue.Id) && isChangedFieldTo(record, Approval__c.Status__c, ApprovalHelperCls.STATUS_APPROVED);
        }

        public override void handle() {
            if(recordsToProcess.isEmpty()){
                return;
            }
            sendNotifications(recordsToProcess);
        }

        protected override List<ApprovalHelperCls.Email> getEmail(Approval__c appr, Quote quote, Opportunity oppty) {
            List<ApprovalHelperCls.Email> result = new List<ApprovalHelperCls.Email>();
            //mail to legal dept
            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(this.EmailRecipientsIds, template.Subject, template.HtmlValue);

            String requestLink = baseUrl + '/' + appr.Id;
            String accountLink = baseUrl + '/' + oppty.Account.Id;

            String emptyReplacer = 'N/A';
            String effNumberOfEmployees = null == oppty.Effective_No_of_Employees_Range__c ? emptyReplacer : oppty.Effective_No_of_Employees_Range__c;
            Integer totalPotUsers = null == oppty.Total_Potential_Users__c ? 0 : Integer.valueOf(oppty.Total_Potential_Users__c);

            mail.addParameter('User.Name', repName);
            mail.addParameter('User.Role', role.Name);

            mail.addParameter('Approval__c.Link', requestLink);
            mail.addParameter('Approval__c.Type__c', appr.Type__c);
            mail.addParameter('Approval__c.Add_ons__c', String.isNotBlank(appr.Add_ons__c) ? appr.Add_ons__c.replace(';', '; ') : emptyReplacer);
            mail.addParameter('Approval__c.Accomodations__c', String.isNotBlank(appr.Accomodations__c) ? appr.Accomodations__c.replace(';', '; ') : emptyReplacer);
            mail.addParameter('Approval__c.Feature_Add_ons__c', String.isNotBlank(appr.Feature_Add_ons__c) ? appr.Feature_Add_ons__c.replace(';', '; ') : emptyReplacer);
            mail.addParameter('Approval__c.Ask_By_Customer__c', appr.Ask_By_Customer__c);
            mail.addParameter('Approval__c.Contract_Link__c', String.isNotBlank(appr.Contract_Link__c) ? appr.Contract_Link__c : emptyReplacer);

            mail.addParameter('Opportunity.Name', oppty.Name);
            mail.addParameter('Opportunity.Type', oppty.Type);
            mail.addParameter('Opportunity.Effective_No_of_Employees_Range__c', effNumberOfEmployees);
            mail.addParameter('Opportunity.X12_Month_Booking__c', oppty.X12_Month_Booking__c);
            mail.addParameter('Opportunity.Brand_Name__c', oppty.Brand_Name__c);
            mail.addParameter('Opportunity.Estimated_12M_Contact_Center_Pipeline__c', oppty.Estimated_12M_Contact_Center_Pipeline__c);
            mail.addParameter('Opportunity.EstimatedProfessionalServices12Month__c', oppty.EstimatedProfessionalServices12Month__c);
            mail.addParameter('Opportunity.Total_Potential_Users__c', null != totalPotUsers ? String.valueOf(totalPotUsers) : emptyReplacer);

            mail.addParameter('Account.Name', oppty.Account.Name);
            mail.addParameter('Account.Link', accountLink);

            if (quote != null)
            {
                mail.addParameter('Quote.Special_Terms__c', String.isNotBlank(quote.Special_Terms__c) ? quote.Special_Terms__c : emptyReplacer);
            }
            else
            {
                mail.addParameter('Quote.Special_Terms__c', emptyReplacer);
            }

            result.add(mail);

            ApprovalHelperCls.InternalEmail ownerMail = new ApprovalHelperCls.InternalEmail(oppty.Owner.Id, this.approvalGrantedTemplate.SUbject, this.approvalGrantedTemplate.HtmlValue);
            ownerMail.addParameter('User.Name', getCurrentUserName());
            ownerMail.addParameter('Approval__c.Type__c', appr.Type__c);
            ownerMail.addParameter('Opportunity.Name', oppty.Name);
            ownerMail.addParameter('Account.Name', oppty.Account.Name);
            result.add(ownerMail);

            return result;
        }

        public LegalRequestPassApproval() {
            super();
            this.repName = getCurrentUserName();
            this.role = AquivaHelper.getCurrentUserRole();
            this.approvalGrantedTemplate = getEmailTemplate(LEGAL_APPROVAL_GRANTED_BY_SALES_MANAGER_TEMPLATE);
        }
    }

    public class LegalInProgressNotifier extends LegalApprovalHandler {
        public override void handle() {
            if(Trigger.isAfter && Trigger.isUpdate){
                processInProgressNotifications();
            }
        }

        private void processInProgressNotifications() {
            List<Approval__c> selectedApprovals = new List<Approval__c>();
            Set<Id> ownerIds = new Set<Id>();

            for(Approval__c appr: recordsToProcess) {
                if(super.isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_IN_PROGRESS)){
                    selectedApprovals.add(appr);
                    ownerIds.add(appr.OwnerId);
                }
            }
            if(selectedApprovals.isEmpty()){
                return;
            }
            Map<Id, User> userMap = UserHelper.getORQueryUsers(ownerIds);

            Map<Id, Approval__c> approvalsWithOpportunitiesAndQuotesInfo = getApprovalRelatedOpportunitiesAndQuotes(selectedApprovals);

            EmailTemplate ownageTemplate = getEmailTemplate(LEGAL_OWNAGE_TEMPLATE_NAME);

            List<Messaging.SingleEmailMessage> ownageEmails = new List<Messaging.SingleEmailMessage>();
            for(Approval__c appr: selectedApprovals) {
                User owner = userMap.get(appr.OwnerId);
                String repName = String.format('{0} {1}', new List<String>{ owner.FirstName, owner.LastName } );
                String apprLink = BASE_URL + '/' + appr.Id;
                Opportunity oppty = approvalsWithOpportunitiesAndQuotesInfo.get(appr.Id).Opportunity__r;
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(oppty.Owner.Id, ownageTemplate.Subject, ownageTemplate.HtmlValue);
                mail.addParameter('Approval__c.Link', apprLink);
                mail.addParameter('Approval__c.Type__c', appr.Type__c);
                mail.addParameter('User.Name', repName);
                mail.addParameter('Opportunity.Name', oppty.Name);
                mail.addParameter('Account.Name', oppty.Account.Name);
                ownageEmails.addAll(mail.getMails());
            }
            if(!ownageEmails.isEmpty()) {
                Messaging.sendEmail(ownageEmails);
            }
        }

        public LegalInProgressNotifier() {
            super();
            // construct
        }
    }

    public class LegalRequiredNotifier extends LegalApprovalHandler {

        private String currentUserFullName {
            get {
                if (null == currentUserFullName) {
                    currentUserFullName = String.format('{0} {1}',
                            new List<String>{UserInfo.getFirstName(), UserInfo.getLastName()});
                }
                return this.currentUserFullName;
            }
            set;
        }

        private List<Id> legalQueueUserIds {
            get {
                if (null == legalQueueUserIds) {
                    legalQueueUserIds = new List<Id>();
                    for (User legal : ApprovalHelperCls.findLegals()) {
                        if (String.IsNotBlank(legal.Email)) {
                            this.legalQueueUserIds.add(legal.Id);
                        }
                    }
                }
                return this.legalQueueUserIds;
            }
            set;
        }

        private EmailTemplate mailTemplate {
            get {
                if (null == mailTemplate) {
                    mailTemplate = ApprovalTriggerHandler.getEmailTemplate(LEGAL_APPROVAL_REQUIRED_TEMPLATE);
                }
                return this.mailTemplate;
            }
            set;
        }

        private void configureEmail(ApprovalHelperCls.Email mail, Approval__c appr) {
            mail.addParameter('User.Name', currentUserFullName);
            mail.addParameter('Approval.Name', appr.Name);
            mail.addParameter('Approval.Link', BASE_URL + '/' + appr.Id);
            mail.addParameter('Approval.TrialPeriod', appr.Trial_Period__c);
        }

        public override void handle() {
            if (Trigger.isAfter && Trigger.isUpdate) {
                processRequiredNotifications();
            }
        }

        private void processRequiredNotifications() {

            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

            Map<Id, Approval__c> owners = new Map<Id, Approval__c>();
            Map<Approval__c, User> approvalsOwnedByUsers = new Map<Approval__c, User>();
            List<Approval__c> approvalsOwnedByLegalQueue = new List<Approval__c>();

            for (Approval__c appr : recordsToProcess) {
                if (isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_REQUIRED)) {
                    if (((String) appr.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())) {
                        if (UserInfo.getUserId() != appr.OwnerId) {
                            owners.put(appr.OwnerId, appr);
                        }
                    } else {
                        approvalsOwnedByLegalQueue.add(appr);
                    }
                }
            }

            for (User user : UserHelper.getORQueryUsers(owners.keySet()).values()) {
                approvalsOwnedByUsers.put(owners.get(user.Id), user);
            }

            for (Approval__c appr : approvalsOwnedByUsers.keySet()) {
                // Send notification to EL owner
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(approvalsOwnedByUsers.get(appr).Id,
                        mailTemplate.Subject, mailTemplate.HtmlValue);
                configureEmail(mail, appr);
                mails.addAll(mail.getMails());
            }

            for (Approval__c appr : approvalsOwnedByLegalQueue) {
                // Send notification to legal queue
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(legalQueueUserIds,
                    mailTemplate.Subject, mailTemplate.HtmlValue);
                configureEmail(mail, appr);
                mails.addAll(mail.getMails());
            }

            if (!mails.isEmpty()) {
                Messaging.sendEmail(mails);
            }
        }

        public LegalRequiredNotifier() {
            super();
            List<Approval__c> legalApprovals = new List<Approval__c>(recordsToProcess);
            recordsToProcess = new List<Approval__c>();
            for(Approval__c appr: legalApprovals) {
                if (isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_REQUIRED) &&
                        !isChangedFieldFrom(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_RECALLED)) {
                    recordsToProcess.add(appr);
                }
            }
        }
    }

    public class LegalOutForSignatureHandler extends LegalApprovalHandler{
        private String STATUS_TO_CHECK = ApprovalHelperCls.STATUS_READY_FOR_SIGNATURE;

        public override void handle(){
            if(Trigger.isBefore){
                validateReadyForSignature();
            } else if (Trigger.isAfter) {
                copyAttachments();
                sendEmails();
            }
        }

        private void validateReadyForSignature() {
            List<Approval__c> approvalsToCheck = new List<Approval__c>();
             List<Id> approvalIds = new List<Id>();
            Map<Id,Id> filesList = new Map<Id,Id>();
            for(Approval__c appr: recordsToProcess) {
            system.debug('Approval Status'+appr.Status__c);
                if(super.isChangedFieldTo(appr, Approval__c.Status__c, STATUS_TO_CHECK)
                    || (sendOutForSignatureOverride && STATUS_TO_CHECK == appr.Status__c)){
                    approvalsToCheck.add(appr);
                    approvalIds.add(appr.Id);
                }
            }
            if(approvalIds.size()>0){
                List<ContentDocumentLink> totalFileRecords = [SELECT Id,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in :approvalIds];

                for(ContentDocumentLink files: totalFileRecords) {
                    filesList.put(files.LinkedEntityId,files.Id);
                }
                system.debug('filesList>>>'+filesList);
                if (approvalsToCheck.size() > 0) {
                    approvalsToCheck = [
                        SELECT Id, Name, Special_Terms_and_Notes__c, Special_Terms_and_Notes_Contact_Center__c, (SELECT Id FROM Attachments LIMIT 1)
                        FROM Approval__c
                        WHERE Id IN: approvalsToCheck
                    ];
                }

                for(Approval__c appr: approvalsToCheck) {
                    system.debug('Approval Attachments'+appr.Attachments.isEmpty());
                    system.debug('Approval Files'+filesList.get(appr.id));
                    system.debug('Approval Special_Terms_and_Notes__c'+appr.Special_Terms_and_Notes__c);
                    system.debug('Approval Special_Terms_and_Notes_Contact_Center__c'+appr.Special_Terms_and_Notes_Contact_Center__c);
                    if(String.isEmpty(filesList.get(appr.id)) && appr.Attachments.isEmpty() && String.isBlank(appr.Special_Terms_and_Notes__c) && String.isBlank(appr.Special_Terms_and_Notes_Contact_Center__c)) {
                        Trigger.newMap.get(appr.Id).addError('You can\'t move Legal Engagement request to "' + STATUS_TO_CHECK + '" state without non-standard terms of service document attached or specifying Special Terms and Notes!');
                    }
                }
            }
        }

        private void copyAttachments() {
            Map<Id, Id> copyFromToMap = new Map<Id, Id>();
            for(Approval__c appr: recordsToProcess) {
                if(super.isChangedFieldTo(appr, Approval__c.Status__c, STATUS_TO_CHECK)
                    || (sendOutForSignatureOverride && STATUS_TO_CHECK == appr.Status__c)){
                    copyFromToMap.put(appr.Id, appr.Opportunity__c);
                }
            }
            if(!copyFromToMap.keySet().isEmpty()) {
                BatchJob_AttachmentCopy batchCopy = new BatchJob_AttachmentCopy(copyFromToMap, true);
                batchCopy.execute();

                if(!Test.isRunningTest()){
                BatchJob_FileCopy batchFileCopy = new BatchJob_FileCopy(copyFromToMap, true);
                batchFileCopy.execute();
                }
            }
        }

        private void sendEmails() {
            Map<Approval__c, Id> approvalToQuoteId = new Map<Approval__c, Id>();
            for(Approval__c appr: recordsToProcess) {
                if((super.isChangedFieldTo(appr, Approval__c.Status__c, STATUS_TO_CHECK)
                    || (sendOutForSignatureOverride && STATUS_TO_CHECK == appr.Status__c))
                    && appr.Quote__c != null){
                    approvalToQuoteId.put(appr, appr.Quote__c);
                }
            }
            if(approvalToQuoteId.values().isEmpty()){
                return;
            }
            Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Name, Opportunity.OwnerId, Opportunity.Owner.Email,
                                                            Opportunity.Name,
                                                            Opportunity.Effective_No_of_Employees_Range__c, Account.Name
                                                            FROM Quote
                                                            WHERE Id IN: approvalToQuoteId.values()
                                                        ]);

            List<Messaging.SingleEmailMessage> completionEmails = new List<Messaging.SingleEmailMessage>();
            for(Approval__c appr: approvalToQuoteId.keySet()) {
                Quote quote = quoteMap.get(approvalToQuoteId.get(appr));
                String repName = String.format('{0} {1}', new List<String>{ UserInfo.getFirstName(), UserInfo.getLastName() } );
                EmailTemplate completionTemplate = getEmailTemplate(LEGAL_READY_FOR_SIGNATURE_TEMPLATE_NAME);
                String opptyLink = BASE_URL + '/' + appr.Opportunity__c;
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(quote.Opportunity.Owner.Id, completionTemplate.Subject, completionTemplate.HtmlValue);
                mail.addParameter('Opportunity.Link', opptyLink);
                mail.addParameter('Opportunity.Name', quote.Opportunity.Name);
                mail.addParameter('Approval__c.Type__c', appr.Type__c);
                mail.addParameter('Account.Name', quote.Account.Name);
                mail.addParameter('User.Name', repName);
                completionEmails.addAll(mail.getMails());
            }
            if(!completionEmails.isEmpty()) {
                Messaging.sendEmail(completionEmails);
            }
        }

        public LegalOutForSignatureHandler() {
            super();
        }
    }


    private static Map<Id, User> managerIDsStaticMap = new Map<Id, User>();

    // Approval rejected by Legal Dept - notify sales rep
    public class LegalRejectionNotifier extends LegalApprovalHandler {
        public override void handle(){
            if(Trigger.isAfter && Trigger.isUpdate){
                processRejections();
            }
        }

        private void processRejections() {
            Map<Approval__c, Id> approvalToQuoteId = new Map<Approval__c, Id>();
            for(Approval__c appr: recordsToProcess) {
                if(!Approval.isLocked(appr.Id) && appr.Quote__c != null
                    && super.isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_REJECTED)){
                    approvalToQuoteId.put(appr, appr.Quote__c);
                }
            }
            if(approvalToQuoteId.values().isEmpty()){
                return;
            }
            Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Name, Opportunity.OwnerId, Opportunity.Owner.Email,
                                                            Opportunity.Name,
                                                            Opportunity.Effective_No_of_Employees_Range__c, Account.Name
                                                            FROM Quote
                                                            WHERE Id IN: approvalToQuoteId.values()
                                                        ]);
            EmailTemplate rejectionTemplate = getEmailTemplate(LEGAL_REJECTION_TEMPLATE_NAME);

            List<Messaging.SingleEmailMessage> rejectionEmails = new List<Messaging.SingleEmailMessage>();
            for(Approval__c appr: approvalToQuoteId.keySet()) {
                Quote quote = quoteMap.get(approvalToQuoteId.get(appr));
                String repName = String.format('{0} {1}', new List<String>{ UserInfo.getFirstName(), UserInfo.getLastName() } );
                String opptyLink = BASE_URL + '/' + appr.Opportunity__c;
                ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(quote.Opportunity.Owner.Id, rejectionTemplate.Subject, rejectionTemplate.HtmlValue);
                mail.addParameter('Opportunity.Link', opptyLink);
                mail.addParameter('Opportunity.Name', quote.Opportunity.Name);
                mail.addParameter('Approval__c.Type__c', appr.Type__c);
                mail.addParameter('Account.Name', quote.Account.Name);
                mail.addParameter('User.Name', repName);
                rejectionEmails.addAll(mail.getMails());
            }
            if(!rejectionEmails.isEmpty()) {
                Messaging.sendEmail(rejectionEmails);
            }
        }

        public LegalRejectionNotifier() {
            super();
        }
    }

    public class LegalServiceLevelAgreementValidator extends LegalApprovalHandler {

        public LegalServiceLevelAgreementValidator() {
            super();
        }
        public LegalServiceLevelAgreementValidator(TriggerOperation operationType, List<Approval__c> newList) {
            super(operationType, newList);
        }

        public override void handle() {
            if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
                validateSLAs();
            }
        }

        public void validateSLAs() {
            List<Approval__c> approvals = this.recordsToProcess;

            if(approvals.size() == 0) {
                return;
            }

            Map<Id, Map<String, SLA__c>> slaByAccountByServiceType = SLAHelper.getSLAsByAccountIdByServiceType(approvals);
            Map<String, SLAController.ServiceLevelAgreement> standardSLAByServiceType = SLAHelper.getStandardSLAsByServiceType();

            List<SLAController.ServiceLevelAgreement> slaToSave = new List<SLAController.ServiceLevelAgreement>();

            for(Approval__c approval : approvals) {
                Map<String, SLA__c> slaByServiceType = slaByAccountByServiceType.get(approval.Account__c);

                if(slaByServiceType == null) {
                    slaByServiceType = new Map<String, SLA__c>();
                }

                for (Schema.SObjectField field : fieldToServiceTypeListMap.keyset()) {
                    String currentPicklistValue = (String) approval.get(field);

                    if(!this.isChangedField((SObject) approval, field)) {
                        continue;
                    }

                    if(currentPicklistValue == null) {
                        continue;
                    }

                    List<String> serviceTypes = fieldToServiceTypeListMap.get(field).get(currentPicklistValue);

                    if(serviceTypes == null) {
                        continue;
                    }

                    Boolean isPicklistValueStandard = currentPicklistValue != LEGAL_APPROVAL_SLA_TYPE_NONSTANDARD;
                    Set<String> serviceTypeMissing = new Set<String>();

                    for (String serviceType : serviceTypes) {
                        if(isPicklistValueStandard) {
                            SLA__c sla = slaByServiceType.get(serviceType);
                            SLAController.ServiceLevelAgreement standardSLA = standardSLAByServiceType.get(serviceType);

                            if(standardSLA == null) {
                                approval.addError('Standard terms for the ' + serviceType + ' Service Type could not be found in custom settings');
                                continue;
                            }

                            if (sla != null) {
                                if (!sla.IsStandardSLA__c) {
                                    // add error to approval that standard SLA of serviceType is missing
                                    approval.addError('This account has custom SLA terms for this service. ' +
                                        'Please select \'Non-Standard\' for this service or modify the existing SLA.');
                                }
                            } else {
                                // add to create list
                                standardSLA.account = approval.Account__c;
                                standardSLA.engageLegal = approval.Id;

                                slaToSave.add(standardSLA);
                            }
                        }
                    }

                    Set<String> existingServiceTypes = slaByServiceType.keySet();
                    if(!isPicklistValueStandard) {
                        for (String serviceType : serviceTypes) {
                            SLA__c sla = slaByServiceType.get(serviceType);

                            if (sla == null) {
                                serviceTypeMissing.add(serviceType);
                            }
                        }
                    }

                    if(serviceTypeMissing.size() > 0) {
                        approval.addError('SLA for services do not exist: ' + String.join(new List<String>(serviceTypeMissing), ', '));
                    }
                }
            }

            SLAHelper.saveMultipleSLAs(slaToSave);
        }
    }

    public class RepPenaltyMultiplier extends Triggers.TriggerHandlerBase {
        public RepPenaltyMultiplier() {
            super();
        }
        public RepPenaltyMultiplier(TriggerOperation operationType, List<Approval__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {

            Map<sObjectField, sObjectField> categoryToTypeFieldMap = new Map<sObjectField, sObjectField>{
                Approval__c.Category__c => Approval__c.Refund_Type__c,
                Approval__c.Refund_Category_2__c => Approval__c.Refund_Type_2__c,
                Approval__c.Refund_Category_3__c => Approval__c.Refund_Type_3__c,
                Approval__c.Refund_Category_4__c => Approval__c.Refund_Type_4__c,
                Approval__c.Refund_Category_5__c => Approval__c.Refund_Type_5__c,
                Approval__c.Refund_Category_6__c => Approval__c.Refund_Type_6__c
            };

            Map<sObjectField, sObjectField> categoryToPenaltyFieldMap = new Map<sObjectField, sObjectField>{
                Approval__c.Category__c => Approval__c.RepPenaltyMultiplier__c,
                Approval__c.Refund_Category_2__c => Approval__c.RepPenaltyMultiplier2__c,
                Approval__c.Refund_Category_3__c => Approval__c.RepPenaltyMultiplier3__c,
                Approval__c.Refund_Category_4__c => Approval__c.RepPenaltyMultiplier4__c,
                Approval__c.Refund_Category_5__c => Approval__c.RepPenaltyMultiplier5__c,
                Approval__c.Refund_Category_6__c => Approval__c.RepPenaltyMultiplier6__c
            };
            List<Approval__c> approvalsToSetRepPenalty = new List<Approval__c>();
            Map<String, Decimal> refundPenaltyMap = getRefundPenaltyMultiplierMap();

            for (Approval__c approval : (List<Approval__c>)this.triggerRecords) {

                for (sObjectField catFieldKey : categoryToTypeFieldMap.keySet()) {
                    if (
                        isChangedAnyField(
                            approval,
                            new Set<sObjectField>{
                                catFieldKey,
                                categoryToTypeFieldMap.get(catFieldKey),
                                categoryToPenaltyFieldMap.get(catFieldKey)
                            }
                        )
                    ) {
                        if(approval.get(catFieldKey) != null
                        && approval.get(categoryToTypeFieldMap.get(catFieldKey)) != null) {
                            String penKey = (String)approval.get(catFieldKey) + ':'
                                            + (String)approval.get(categoryToTypeFieldMap.get(catFieldKey));
                            approval.put(categoryToPenaltyFieldMap.get(catFieldKey), refundPenaltyMap.get(penKey));
                        } else {
                            approval.put(categoryToPenaltyFieldMap.get(catFieldKey), null);
                        }
                    }
                }
            }
        }

        private Map<String, Decimal> getRefundPenaltyMultiplierMap () {

            Map<String, Decimal> refundPenaltyMap = new Map<String, Decimal>();
            List<RefundRepPenaltyMultiplierMapping__c> refundMappingCustomSettings
                = (RefundRepPenaltyMultiplierMapping__c.getAll()).values();

            for(RefundRepPenaltyMultiplierMapping__c refundPenMult : refundMappingCustomSettings) {
                if (refundPenMult.RefundCategory__c != null && refundPenMult.RefundType__c != null
                && refundPenMult.PenaltyMultiplier__c != null) {
                    refundPenaltyMap.put(
                        refundPenMult.RefundCategory__c + ':' + refundPenMult.RefundType__c,
                        refundPenMult.PenaltyMultiplier__c
                    );
                }
            }

            return refundPenaltyMap;
        }

    }

    public class ApprovalBefore extends Triggers.TriggerHandlerBase {

        override public void handle(){

            if (TriggerHandler.BY_PASS_Approver_Trigger) {
                return;
            }
            Set<Id> idUserSet = new Set<Id>();
            Set<Id> idAgentCreditSet = new Set<Id>();
            // populating values for recordtypeName
            ApprovalHelperCls.describeRecordTypesByName(); // Direct to var
            ApprovalHelperCls.describeRecordTypesById(); // Direct to Var
            Set<Id> accountIdSet = new Set<id>(); // Direct to Var

            Set<id> OpportunityIds = new Set<id>();
            for(Approval__c appr: (List<Approval__c>)Trigger.new) {
                if(appr.Ownerid != null && !idUserSet.contains(appr.Ownerid)) {
                    idUserSet.add(appr.Ownerid);
                }
                // Direct to Var
                if(appr.Opportunity__c != null){
                    OpportunityIds.add(appr.Opportunity__c);
                }
                // Direct to Var
                if(appr.Account__c != null){
                    accountIdSet.add(appr.Account__c);
                }
                if(appr.Agent_Credit__c != null && !idAgentCreditSet.contains(appr.Agent_Credit__c)) {
                    idAgentCreditSet.add(appr.Agent_Credit__c);
                }
                if(appr.Credit_Transfer_To_Agent__c != null && !idUserSet.contains(appr.Credit_Transfer_To_Agent__c)) {
                    idUserSet.add(appr.Credit_Transfer_To_Agent__c);
                }
            }
              // Direct to Var
            Map<Id, Opportunity> opportunityMap = (Map<Id, Opportunity>) getObjectMap(opportunityIds, 'Opportunity');

            ApprovalHelperCls.opportunityStaticMap = OpportunityMap.clone();

            ApprovalHelperCls.accountStaticMap = (Map<Id, Account>) getObjectMap(accountIdSet, 'Account');

            //Direct to VAR
            if(Trigger.isUpdate){
                  ApprovalHelperCls.approvalNewStaticMap = (Map<Id, Approval__c>)Trigger.newMap;
                  ApprovalHelperCls.oldApprovalStaticMap = (Map<Id, Approval__c>)Trigger.oldMap;
            /* createAccntSplitDirToVar method does the following :-
                1. Updates the Approval record itself with status (thats why in before trigger)
                2. Creates lists of related records and those lists are eventually being updated/inserted in Approval_After Trigger.
                */
                ApprovalHelperCls.createAccntSplitDirToVar();
                ApprovalHelperCls.updateTechnicalApprovals((List<Approval__c>)Trigger.new, masterApprovalToTechnicalApprovals);
            }

            Map<Id, Id> agentCreditMap;
            if(idAgentCreditSet != null && idAgentCreditSet.size()>0) {
                List<Agent_Credit__c> agentCreditList = getAgentCreditList(idAgentCreditSet);
                if(agentCreditList != null && agentCreditList.size()>0) {
                    agentCreditMap = new map<Id,Id>();
                    for(Agent_Credit__c agentCreditObj : agentCreditList) {
                        agentCreditMap.put(agentCreditObj.Id,agentCreditObj.OwnerId);
                        idUserSet.add(agentCreditObj.OwnerId);
                    }
                }
            }

            Map<Id, User> allAgentCreditOwners = UserHelper.getORQueryUsers(idUserSet);
            Map<Id, User> activeAgentCreditOwners = UserHelper.getActiveUsers(allAgentCreditOwners);

            if(trigger.IsInsert){
                  User currentUser = new User();
                  User userIdentifiesManager = new User();
                  Set<id> CaseIds = new Set<id>();

                  Set<id> AgentCreditIds = new Set<id>();
                  Set<id> ContactIds = new Set<id>();

                // getting the loggedIn user detail //
                currentUser = UserHelper.getORQueryUser(UserInfo.getUserId());
                Id userIdentifiesManagerId ;
                for(Approval__c appr:(List<Approval__c>)Trigger.new){
                    if(appr.Case__c != null){
                        CaseIds.add(appr.Case__c);
                    }else if(appr.Opportunity__c != null){
                        OpportunityIds.add(appr.Opportunity__c);
                    }else if(appr.Agent_Credit__c != null){
                        AgentCreditIds.add(appr.Agent_Credit__c);
                    }else if(appr.Contact__c != null){
                        ContactIds.add(appr.Contact__c);
                    }
                    if(appr.RecordTypeId != null && ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'QuoteApprovalProcess'){
                        if(currentUser != null && currentUser.profile.Name.contains('RC Partner')){
                            if(currentUser.Contact.Account.Inside_Sales_Rep__c != NULL){
                                userIdentifiesManagerId = currentUser.Contact.Account.Inside_Sales_Rep__c;
                            }else if(currentUser.Contact.Account.Inside_Sales_Rep__c == NULL && currentUser.Contact.Account.Current_Owner__c!= NULL){
                                userIdentifiesManagerId = currentUser.Contact.Account.Current_Owner__c;
                            }
                        }
                    }
                }
                if(currentUser != null && currentUser.profile.Name.contains('RC Partner') && userIdentifiesManagerId != NULL){
                    userIdentifiesManager = [SELECT Id,Manager_Id__c,Manager_Manager_ID__c FROM USER WHERE Id =: userIdentifiesManagerId];
                }


                Map<Id, Case> CaseMap = (Map<Id, Case>) getObjectMap(CaseIds, 'Case');


                Map<Id, Agent_Credit__c> AgentCMap = new Map<Id, Agent_Credit__c>(getAgentCreditList(AgentCreditIds));
                Map<Id, Contact> ContactMap = (Map<Id, Contact>) getObjectMap(ContactIds, 'Contact');

                Integer i=0;
                for(Approval__c appr:(List<Approval__c>)Trigger.new) {
                    if(agentCreditMap != null && appr.Agent_Credit__c != null && agentCreditMap.containskey(appr.Agent_Credit__c)) {
                        appr.Credit_Transfer_From_Agent__c = agentCreditMap.get(appr.Agent_Credit__c);
                    }
                    if(activeAgentCreditOwners != null && appr.Ownerid != null && activeAgentCreditOwners.containskey(appr.Ownerid)) {
                        appr.Submitter_Email__c = activeAgentCreditOwners.get(appr.Ownerid).Email;
                        appr.Manager_Email__c =  activeAgentCreditOwners.get(appr.Ownerid).Manager.Email;
                    }
                    if(activeAgentCreditOwners != null && appr.Credit_Transfer_From_Agent__c != null && activeAgentCreditOwners.containskey(appr.Credit_Transfer_From_Agent__c)) {
                        appr.Transfer_from_Mgr_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_From_Agent__c).ManagerId;
                    }
                    if(activeAgentCreditOwners != null && appr.Credit_Transfer_To_Agent__c != null && activeAgentCreditOwners.containskey(appr.Credit_Transfer_To_Agent__c)) {
                        appr.Transfer_to_Mgr_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).ManagerId;
                    }

                    /********************************************************************************************************
                    *    @Description    :   Verifying if current user the profile name contains  Sales or Sales Manager   *
                    *                        or Sales Director then on the basis of profile name, providing values for     *
                    *                        following field Level1Approver, Level2Approver, Level3Approver.               *
                    *    @Created By     :   India Team.                                                                   *
                    *    @case Number    :   02739719.                                                                     *
                    *    Created Dated   :   03-July-2014.                                                                 *
                    *******************************************************************************************************/
                    try{
                                /* verifying the if profile name contains  Sales or Sales Manager or Sales Director and on the basis of profile name, providing
                                values for  following field Level1Approver, Level2Approver ,Level3Approver. */

                        // START -- Case # 03931608 - GOA - Identify the values of Approver 1, 2 and 3
                        if(currentUser != null && appr.RecordTypeId != null &&
                            ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'QuoteApprovalProcess') {

                            Id ManagerId = null;
                            Id ManagerManagerID = null;
                            Id ManagerManagerManagerID = null;

                            if(currentUser.ManagerId != null){
                                ManagerId = currentUser.ManagerId;
                                ManagerManagerID = currentUser.Manager.ManagerId;
                                ManagerManagerManagerID = currentUser.Manager.Manager.ManagerId;
                            }else{
                                if(userIdentifiesManager.id != NULL){
                                    ManagerId = userIdentifiesManager.id;
                                    ManagerManagerID = userIdentifiesManager.Manager_Id__c;
                                    ManagerManagerManagerID = userIdentifiesManager.Manager_Manager_ID__c;
                                }
                            }

                            //B-331 As a any user in RC SalesForce I want Approvers to be populated for me if I
                            // update the Quote or Line Items so I could Submit for Approval if needed.

                            appr.Level1Approver__c = ManagerId;
                            appr.Level2Approver__c = ManagerManagerID;
                            appr.Level3Approver__c = ManagerManagerManagerID;
                        }
                    // END -- Case # 03931608 - GOA

                    }catch(Exception ex){
                        system.debug('####### Exception Message #### '+ex.getMessage());
                        system.debug('####### Exception Line Number #### '+ex.getLineNumber());
                    }
                            /****************************************************************************************************************
                            *   @Description    :   Updating the AccountId in Approval if it is null , working on Sepecific RecordTypeIds   *
                            *   @Created By     :   India Team.                                                                             *
                            *   @case Number    :   02739719.                                                                               *
                            *   Created Dated   :   03-July-2014.                                                                           *
                            ****************************************************************************************************************/

                    try{
                        if(appr.Account__c == null && appr.recordtypeId != null && (ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Farming Claim Owner'
                            || ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName() == 'Agent Credit Transfers')){
                            System.debug('====appr.Case__c===='+appr.Case__c);
                            if(appr.Case__c != null && CaseMap.get(appr.Case__c).AccountID != null){
                                appr.Account__c = CaseMap.get(appr.Case__c).AccountID;
                                }else if(appr.Opportunity__c != null && OpportunityMap.get(appr.Opportunity__c).AccountID != null){
                                    appr.Account__c = OpportunityMap.get(appr.Opportunity__c).AccountID;
                                }else if(appr.Agent_Credit__c != null && AgentCMap.get(appr.Agent_Credit__c).Account__c != null){
                                    appr.Account__c = AgentCMap.get(appr.Agent_Credit__c).Account__c;
                                }else if(appr.Contact__c != null && ContactMap.get(appr.Contact__c).AccountId != null){
                                    appr.Account__c = ContactMap.get(appr.Contact__c).AccountId;
                                }
                            }
                    }catch(Exception ex){
                        system.debug('####### Exception Message #### '+ex.getMessage());
                        system.debug('####### Exception Line Number #### '+ex.getLineNumber());
                    }
                }
            }


            if(trigger.IsUpdate){

                Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>();
                for(Schema.RecordTypeInfo item : Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName().values()) {
                    recordTypeMap.put(item.getRecordTypeId(), new RecordType(Name = item.getName()));
                }


                Integer i = 0;
                List<Agent_Credit__c> agentCreditList =  new List<Agent_Credit__c>();
                List<Account> accListTOUPD = new List<Account>();
                for(Approval__c appr:(List<Approval__c>)Trigger.new) {

                    Approval__c apprOld = (Approval__c)Trigger.oldMap.get(appr.id);

                    if(agentCreditMap != null && appr.Agent_Credit__c != null && agentCreditMap.containskey(appr.Agent_Credit__c)) {
                        appr.Credit_Transfer_From_Agent__c = agentCreditMap.get(appr.Agent_Credit__c);
                    }
                    if(activeAgentCreditOwners != null && appr.Credit_Transfer_From_Agent__c != null && activeAgentCreditOwners.containskey(appr.Credit_Transfer_From_Agent__c)) {
                        appr.Transfer_from_Mgr_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_From_Agent__c).ManagerId;
                    }
                    if(activeAgentCreditOwners != null && appr.Credit_Transfer_To_Agent__c != null && activeAgentCreditOwners.containskey(appr.Credit_Transfer_To_Agent__c)) {
                        appr.Transfer_to_Mgr_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).ManagerId;
                    }
                    if (appr.Status__c == 'Approved' && apprOld.Status__c != 'Approved' &&                 // apprOld.Status__c == 'PendingL1Approval'
                        recordTypeMap.get(appr.RecordTypeId).Name == 'Agent Credit Transfers') {
                        try {
                            if(appr.Agent_Credit__c != null && activeAgentCreditOwners.containskey(appr.Credit_Transfer_To_Agent__c)) {
                                Agent_Credit__c agenCrdObj = new Agent_Credit__c(Id = appr.Agent_Credit__c);
                                agenCrdObj.OwnerId = appr.Credit_Transfer_To_Agent__c;
                                agenCrdObj.Agent_Email__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).Email;
                                agenCrdObj.Agent_Division__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).Division;
                                agenCrdObj.Agent_First_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).FirstName;
                                agenCrdObj.Agent_Last_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).LastName;
                                agenCrdObj.Agent_Manager_Email__c= activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).Manager.Email;
                                agenCrdObj.Agent_Manager_First_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).Manager.FirstName;
                                agenCrdObj.Agent_Manager_Last_Name__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).Manager.LastName;
                                agenCrdObj.Agent_Role__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).UserRole.Name;
                                agenCrdObj.Agent_SPID__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).PID__c;
                                agenCrdObj.Agent_Team__c = activeAgentCreditOwners.get(appr.Credit_Transfer_To_Agent__c).Team__c;
                                agentCreditList.add(agenCrdObj);
                            }
                        } catch(Exception e) {
                            appr.addError(e);
                        }
                    }

                    if (appr.RecordTypeId == ApprovalHelperCls.RT_ID_ENGAGE_LEGAL) {
                        if (isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelperCls.STATUS_PENDING_L1_APPROVAL)) {
                            appr.OwnerId = appr.CreatedById;
                        }
                        if (isChangedField(appr, Approval__c.Trial_Period__c)) {
                            if (ApprovalHelperCls.TERMINAL_STATUSES.contains(appr.Status__c)) {
                                appr.addError('It\'s prohibited to change Trial Period of Legal Engagement request in status ' + appr.Status__c);
                            } else {
                                appr.Status__c = ApprovalHelperCls.STATUS_REQUIRED;
                            }
                        }
                    }

                    i++;
                }
                try {
                    if(agentCreditList != null && agentCreditList.size()>0) {
                        update agentCreditList;
                    }

                    if(accListTOUPD != null && accListTOUPD.size()>0) {
                        update accListTOUPD;
                    }
                } catch(Exception ex) {
                    System.debug(loggingLevel.Error, 'ex.getMessage() >>> ' + ex.getMessage());
                    System.debug(loggingLevel.Error, 'ex.getStacktraceString() >>> ' + ex.getStacktraceString());
                }

                //===== Farming Claim Owner Change Approved ====
                // All the Approved Requests will be processed
                // The related account will be updated with Audit fields

                List<Account> AccToUpdate = new List<Account>();
                Map<Id,Approval__c> AccountToApprovalMap = new Map<Id,Approval__c>();
                for(Approval__c appr:(List<Approval__c>)Trigger.new){
                    if( appr.Status__c=='Approved' &&
                        recordTypeMap.get(appr.RecordTypeId).Name =='Farming Claim Owner' &&
                        appr.Account__c != null)
                    {
                        AccountToApprovalMap.put(appr.Account__c,appr);
                    }
                }

                if(AccountToApprovalMap.keyset().size()>0){
                    // Diirect to Var

                    for(ID accID:AccountToApprovalMap.keyset())
                    {
                        Approval__c appr = new Approval__c();
                        appr = AccountToApprovalMap.get(accID);
                        Account acc = new Account();
                        // Direct To VAR
                        acc = ApprovalHelperCls.accountStaticMap.get(accID);

                        if(appr.Status__c=='Approved')
                        {
                            //Set the MRR Transfer Effective Date to the date based on
                            //      If Referral OR Existing Customer, then = Current Date
                            //      If Internal Transfer, then = First day of the next month


                            if(appr.Transfer_Type__c =='Referral'||appr.Transfer_Type__c =='Existing Customer'){
                                acc.MRR_Transfer_Effective_date__c = Date.today();
                            }


                            if(appr.Transfer_Type__c =='Internal Transfer'){
                                acc.MRR_Transfer_Effective_date__c = Date.today().toStartOfMonth().addMonths(1);
                            }

                            AccToUpdate.add(acc);
                        }
                    }
                }
                if(AccToUpdate.size()>0){
                    Update AccToUpdate;
                }
            }

            // B-959 "Approval Record for Feature Add-Ons"

            if ( trigger.isInsert || trigger.isUpdate ) {
                Schema.DescribeSObjectResult d = Schema.SObjectType.Approval__c;
                Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();

                Set<Id> accountIds = new Set<Id>();

                for( Approval__c appr : (List<Approval__c>)trigger.new ) {
                    if ( rtMapById.get( appr.RecordTypeId ).getName() == 'Feature Add-Ons' &&
                        (new List <String>{'New', 'Recalled', 'Approved', 'Completed', 'Rejected'}.contains(appr.Status__c)) && appr.Account__c != null) {

                        accountIds.add( appr.Account__c );
                    }

                    Boolean notElegalChangeOrderType = true;

                    for (String type : ApprovalHelperCls.ELEGAL_CHANGE_ORDER_TYPES) {
                        if (appr.Change_Order_Type__c != null && appr.Change_Order_Type__c.contains(type)) {
                            notElegalChangeOrderType = false;
                            break;
                        }
                    }

                    //B-2783 (Approval Name population) Savickiy Alexander 17.08.2017
                    for (id accountId : ApprovalHelperCls.accountStaticMap.keyset()){
                        Boolean isAPCChangedSubmittedForApproval = Trigger.isUpdate
                            && appr.InvoiceApprovalType__c == ApprovalHelper.GOTOTHEFINALSTEP
                            && ApprovalHelper.isRequiredKeyFieldsNotChanged(
                                appr.getPopulatedFieldsAsMap(),
                                ((Approval__c) Trigger.oldMap.get(appr.id))?.getPopulatedFieldsAsMap(),
                                new Set<String>{ 'Status__c', 'Approval_History__c' }
                            );
                        if (accountId == appr.Account__c && !isAPCChangedSubmittedForApproval && notElegalChangeOrderType){
                            appr.Name = populateApprovalName(appr);
                        }
                    }
                }

                if ( !accountIds.isEmpty() ) {
                    Map<Id, Approval__c> accountToLastApprovedApproval = new Map<Id, Approval__c>();
                    Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Number_of_POC_Users__c, RC_User_ID__c, RC_Tier__c, RC_Account_Status__c FROM Account WHERE id IN :accountIds]);
                    Map<Id, String> accToTierMap = createMapAccToTier( accMap.values() );
                    Map<String, String> tierToEditionMap = createMapTierToEdition( accToTierMap.values() );
                    Map<String, ApprovalAssignment__c> approvalAssignmentsCS = ApprovalAssignment__c.getall();
                    Map<String, String> APINameTolabelFieldsMap = new Map<String, String>{
                        'POCGlobalOffice__c' => 'POC - Global Office',
                        'POCEnableFullTestingCapability__c' => 'POC - Enable full testing capability',
                        'POCSendOutAdditionalPOCDevices__c' => 'POC - Send out additional POC Devices',
                        'POCExtensionUpTo60Days__c' => 'POC - Extension up to 60 days',
                        'POCExtension61PlusDays__c' => 'POC - Extension 61+ days',
                        'PeoplePerMeeting__c' => '50 people per meeting',
                        'CostCenterManagement__c' => 'Cost Center Management',
                        'InboundCallerIDName__c' => 'Inbound Caller ID Name',
                        'HDVoice__c' => 'HD Voice',
                        'AutomaticCallRecording__c' => 'Automatic call recording',
                        'IntegrationWithSFDCZendeskDesk__c' => 'Integration with SFDC/Zendesk',
                        'SingleSignOn__c' => 'Single Sign-On',
                        'VoicemailToTextStandard__c' => 'Voicemail to text Standard',
                        'VoicemailToTextPremium__c' => 'Voicemail to text Premium',
                        'Active_Directory_Integration__c' => 'Active Directory Integration',
                        'Custom_Roles__c' => 'Custom Roles',
                        'Call_Monitoring__c' => 'Call Monitoring',
                        'X75_People_per_meeting__c' => '75 People per meeting',
                        'Other__c' => 'Other',
                        'Hot_Desking__c' => 'Hot Desking',
                        'Proserv_Billing_Start__c' => 'Proserv Billing Start'
                    };

                    List<String> namesApproves = new List<String>{
                        'Direct_Manager__c',
                        'Segment_Leader__c',
                        'SVP_WWS_Directs__c',
                        'SVP_WWS__c',
                        'Finance_Queue__c',
                        'FeatureActivations__c'
                    };

                    if (Trigger.isInsert) {
                        accountToLastApprovedApproval = ApprovalHelper.fetchLatestPOCApprovalForEachAccount(accountIds);
                    }

                    for (Approval__c appr : (List<Approval__c>)trigger.new) {
                        Approval__c lastApprovedPOCApproval = accountToLastApprovedApproval.get(appr.Account__c);
                        Decimal numberOfPOCUsers = getNumberOfPOCUsers(lastApprovedPOCApproval);
                        String rcUserID = accMap.get(appr.Account__c).RC_User_ID__c;
                        String rcAccountStatus = accMap.get(appr.Account__c).RC_Account_Status__c;
                        List<String> tiers = new List<String>();

                        String accType = determineAccountType(numberOfPOCUsers, rcAccountStatus, rcUserID);

                        appr.AccountType__c = accType;


                        if ( appr.Free_Active_Virtual_Extensions__c == 'Entire Account' ) {
                            APINameTolabelFieldsMap.put('Free_Active_Virtual_Extensions__c','Free Active Virtual Extensions En');
                        } else if ( appr.Free_Active_Virtual_Extensions__c == 'Specified Number' ) {
                            APINameTolabelFieldsMap.put('Free_Active_Virtual_Extensions__c','Free Active Virtual Extensions Sp');
                        }

                        // Fill Edition__c field from Edition__c on PriceBook2
                        appr.Edition__c = tierToEditionMap.get( accToTierMap.get( appr.Account__c ) );

                        if(!appr.Proserv_Billing_Start__c) {
                            // Fill AdditionalFeatures__c field from selected checkboxes
                            appr.AdditionalFeatures__c = generateStringFromSelectedChechboxes( appr, APINameTolabelFieldsMap, true );
                        }

                        // Fill fields for approvers (ex. Level1Approver__c) from custom setting "ApprovalAssignment__c"
                        if( String.isNotBlank( appr.AdditionalFeatures__c)
                            && !ApprovalHelper.RT_SKIP_APPROVAL_LEVELS_CALC.contains(ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName()) ) {
                            System.debug('////appr.AdditionalFeatures__c' + appr.AdditionalFeatures__c);
                            List<String> approvalSteps = getStepsForApproval(appr, APINameTolabelFieldsMap, approvalAssignmentsCS, namesApproves);
                            System.debug('approvalSteps >>> ' + approvalSteps);
                            if(!appr.Proserv_Billing_Start__c) {
                                appr.AdditionalFeatures__c = generateStringFromSelectedChechboxes( appr, APINameTolabelFieldsMap, false );
                            }

                            if(approvalSteps.size() > 0) {
                                if(appr.Brand__c != null && appr.Brand__c == 'AT&T Office@Hand'){
                                 	setBizApproversAndStatus(appr, approvalSteps);
                                } else {
                                	setApproversAndStatus(appr, approvalSteps);
                                }
                            }
                        }
                    }
                }
            }


            if (Trigger.isBefore && Trigger.isInsert) {
                setSalesOwner(Trigger.new);
            }
        }

        private Decimal getNumberOfPOCUsers(Approval__c approval) {
            Decimal numberOfPOCUsers = 0;

            if (approval != null) {
                numberOfPOCUsers = approval.Number_of_POC_Users__c;
            }

            return numberOfPOCUsers;
        }

        public Map<Id, SObject> getObjectMap(Set<Id> objectIds, String objectToQuery) {
            Map<Id, SObject> queryResult = new Map<Id, SObject>();
            try {
                queryResult = (Map<Id, SObject>) Type.forName('Map<Id,' + objectToQuery + '>').newInstance();
                if (objectIds.isEmpty() || String.isBlank(objectToQuery)) {
                    return queryResult;
                }
                List<Object> bindings = new List<Object>{objectIds};

                switch on objectToQuery {
                    when 'Opportunity' {
                        OpportunitySelector getOpportunityInfo = new OpportunitySelector();
                        queryResult.putAll(getOpportunityInfo
                                               .selectOpportunitiesForApproval(bindings)
                                               .executeQuery());
                    }
                    when 'Account' {
                        AccountSelector getAccountInfo = new AccountSelector();
                        queryResult.putAll(
                            getAccountInfo
                            .selectAccountsForApproval(bindings)
                            .subselect(
                                new AccountContactRoleSelector()
                                .selectAccountContactRolesForOpportunityClose()
                                .setCondition(
                                    'isPrimary = true'
                                )
                            )
                            .executeQuery()
                        );
                    }
                    when 'Case' {
                        CaseSelector getCaseInfo = new CaseSelector();
                        queryResult.putAll(getCaseInfo
                                               .selectCasesForApproval(bindings)
                                               .executeQuery());
                    }
                    when 'Contact' {
                        ContactSelector getContactInfo = new ContactSelector();
                        queryResult.putAll(getContactInfo
                                               .selectContactsForApproval(bindings)
                                               .executeQuery());
                   }
                    when 'User' {
                       UserSelector getUserInfo = new UserSelector();
                       queryResult.putAll((List<User>) getUserInfo
                                                .selectUserForApproval(bindings)
                                                .executeQuery());
                   }
                    when 'Approval__c' {
                        ApprovalSelector getKycApprovalInfo = new ApprovalSelector();
                        queryResult.putAll((List<Approval__c>) getKycApprovalInfo
                                                .selectKYCRequestApprovalsForAccount(bindings)
                                                .executeQuery());
                    }
                }
            } catch (Exception e) {
                PlatformLog.logResult('ApprovalTriggerHandler.getObjectMap()',
                    'Process failed: ',
                    e.getMessage(),
                    null,
                    null,
                    false);
            }
            return queryResult;
        }

        public List<Agent_Credit__c> getAgentCreditList(Set<Id> agentCreditIds) {
            List<Agent_Credit__c> queryResult = new List<Agent_Credit__c>();
            if (agentCreditIds.isEmpty()) {
                return queryResult;
            }
            List<Object> bindings = new List<Object>();
            bindings.add(agentCreditIds);
            AgentCreditSelector getAgentCreditInfo = new AgentCreditSelector();
            queryResult.addAll((List<Agent_Credit__c>) getAgentCreditInfo
                                                           .selectAgentCreditsForApproval(bindings)
                                                           .executeQuery());
            return queryResult;
        }
        private void setApproversAndStatus(Approval__c appr, List<String> approvalSteps) {

            List<String> approverHierarchyRoleList = filterHierarchyRoles(approvalSteps);
            approverHierarchyRoleList = QuoteApprovals.sortRoleList(approverHierarchyRoleList);
            List<Feature_Add_Ons_Approval__c> FeatureAddOnsApprovers = Feature_Add_Ons_Approval__c.getall().values();
            Map<Id, Feature_Add_Ons_Approval__c> FeatureAddOnMapping = new Map<Id, Feature_Add_Ons_Approval__c>();
            for(Feature_Add_Ons_Approval__c faddonAppr : FeatureAddOnsApprovers){
                FeatureAddOnMapping.put(faddonAppr.OwnerId__c, faddonAppr);
            }

            Set<String> apprvsHRSet = new Set<String> (approverHierarchyRoleList);
            Integer lastApprv = 0;
            for(String hr: apprvsHRSet){
                if(UserHelper.hierarchyRolesNameToOrderMap.containsKey(hr) && lastApprv < UserHelper.hierarchyRolesNameToOrderMap.get(hr)){
                    lastApprv = UserHelper.hierarchyRolesNameToOrderMap.get(hr);
                }
            }
            if(approverHierarchyRoleList.size() > 0) {

                // use approval creator user as startedSearch user instead of current user
                User currentUser = ApproversSearch.findUserById(appr.OwnerId);
                List<Id> approversIdList = new List<Id>();
                String currentUserHRole = currentUser.Hierarchy_Role__c;
                Boolean isSuitableRole = ApproversSearch.isSuitableHierarchyRole(currentUserHRole);

                if(currentUserHRole == null || !isSuitableRole) {
                    currentUserHRole = UserHelper.SALES_REP_ROLE;
                }

                ApproversSearch approversSearcher = new ApproversSearch();
                approversIdList = approversSearcher.findApproverIdsByHierarchyRoles(approverHierarchyRoleList, currentUser);

                if (!Feature_Toggle__c.getInstance().Bypass_GOA_Feature_AddOns_Approval__c && FeatureAddOnMapping.keyset().contains(appr.OwnerId)){
                    approversIdList.clear();
                    if(FeatureAddOnMapping.get(appr.OwnerId).Level_1__c != null && lastApprv >= 2){
                        approversIdList.add(FeatureAddOnMapping.get(appr.OwnerId).Level_1__c);
                    }
                    if(FeatureAddOnMapping.get(appr.OwnerId).Level_2__c != null && lastApprv >= 3){
                        approversIdList.add(FeatureAddOnMapping.get(appr.OwnerId).Level_2__c);
                    }
                    if(FeatureAddOnMapping.get(appr.OwnerId).Level_3__c != null && lastApprv >= 3){
                        approversIdList.add(FeatureAddOnMapping.get(appr.OwnerId).Level_3__c);
                    }
                    if(FeatureAddOnMapping.get(appr.OwnerId).Level_4__c != null && lastApprv >= 4){
                        approversIdList.add(FeatureAddOnMapping.get(appr.OwnerId).Level_4__c);
                    }
                    if(FeatureAddOnMapping.get(appr.OwnerId).Level_5__c != null && lastApprv >= 5){
                        approversIdList.add(FeatureAddOnMapping.get(appr.OwnerId).Level_5__c);
                    }
                }

                appr = fillApproverLvls(approversIdList, appr, FeatureAddOnMapping);

            }else{

                // approval from User don't needed - clear fields
                appr.Level1Approver__c = null;
                appr.Level2Approver__c = null;
                appr.Level3Approver__c = null;
                appr.Level4Approver__c = null;
                appr.InvoiceBillingLevel5Approver__c = null;
            }

            List<String> queueNamesList = filterNotHierarchyRoles(approvalSteps);

            // check we have Feature Activations queue for approval and set Finance__c checkbox
            Boolean hasFeatureActivationsQueue = false;
            for(String item : queueNamesList) {

                if(item == 'Feature Activations') {

                    hasFeatureActivationsQueue = true;
                }
            }

            if(hasFeatureActivationsQueue) {
                appr.Level5Approver__c = true;
            }else{
                appr.Level5Approver__c = false;
            }

            // check we have Finance queue for approval and set Finance__c checkbox
            Boolean hasFinanceQueue = false;
            for(String item : queueNamesList) {

                if(item == 'Finance Queue') {

                    hasFinanceQueue = true;
                }
            }

            if(hasFinanceQueue) {
                appr.Finance__c = true;
            }else{
                appr.Finance__c = false;
            }


            Boolean setApprovedStatus = checkAutoApprove(appr);

            if(setApprovedStatus) {

                appr.Status__c = APPROVAL_STATUS_APPROVED;
            }

            if(trigger.isUpdate) {

                // check fields and set status
                Approval__c oldApproval = (Approval__c) trigger.oldMap.get(appr.Id);

                Boolean isNeedClearStatus = isNeedClearStatus(appr, oldApproval);

                if(isNeedClearStatus && !setApprovedStatus) {

                    appr.Status__c = APPROVAL_STATUS_NEW;
                }
            }
        }
        private void setBizApproversAndStatus(Approval__c appr, List<String> approvalSteps) {

        List<String> approverHierarchyRoleList = filterHierarchyRoles(approvalSteps);
        approverHierarchyRoleList = QuoteApprovals.sortRoleList(approverHierarchyRoleList);

        if(approverHierarchyRoleList.size() > 0) {

            // use approval creator user as startedSearch user instead of current user
            User currentUser = ApproversSearch.findUserById(appr.OwnerId);

            String currentUserHRole = currentUser.Hierarchy_Role__c;

            Boolean isSuitableRole = ApproversSearch.isSuitableHierarchyRole(currentUserHRole);

            if(currentUserHRole == null || !isSuitableRole) {
                currentUserHRole = UserHelper.SALES_REP_ROLE;
            }

            ApproversSearch approversSearcher = new ApproversSearch();
            List<Id> approversIdList;
            if(appr.Brand__c != null && appr.Brand__c == 'AT&T Office@Hand'){
                approversIdList = approversSearcher.findApproverIdsByHierarchyRolesforBiz(approverHierarchyRoleList, currentUser);
            }
            else {
                approversIdList = approversSearcher.findApproverIdsByHierarchyRoles(approverHierarchyRoleList, currentUser);
            }

            appr = fillApproverLvls(approversIdList, appr);

        }else{

            // approval from User don't needed - clear fields
            appr.Level1Approver__c = null;
            appr.Level2Approver__c = null;
            appr.Level3Approver__c = null;
            appr.Level4Approver__c = null;
        }

        List<String> queueNamesList = filterNotHierarchyRoles(approvalSteps);

        // check we have Feature Activations queue for approval and set Finance__c checkbox
        Boolean hasFeatureActivationsQueue = false;
        for(String item : queueNamesList) {

            if(item == 'Feature Activations') {

                hasFeatureActivationsQueue = true;
            }
        }

        if(hasFeatureActivationsQueue) {
            appr.Level5Approver__c = true;
        }else{
            appr.Level5Approver__c = false;
        }

        // check we have Finance queue for approval and set Finance__c checkbox
        Boolean hasFinanceQueue = false;
        for(String item : queueNamesList) {

            if(item == 'Finance Queue') {

                hasFinanceQueue = true;
            }
        }

        if(hasFinanceQueue) {
            appr.Finance__c = true;
        }else{
            appr.Finance__c = false;
        }


        Boolean setApprovedStatus = checkAutoApprove(appr);

        if(setApprovedStatus) {

            appr.Status__c = APPROVAL_STATUS_APPROVED;
        }

        if(trigger.isUpdate) {

            // check fields and set status
            Approval__c oldApproval = (Approval__c) trigger.oldMap.get(appr.Id);

            Boolean isNeedClearStatus = isNeedClearStatus(appr, oldApproval);

            if(isNeedClearStatus && !setApprovedStatus) {

                appr.Status__c = APPROVAL_STATUS_NEW;
            }
        }
    }


        private List<String> getStepsForApproval( Approval__c appr, Map<String, String> APINameTolabelFieldsMap, Map<String, ApprovalAssignment__c> approvalAssignmentsCS, List<String> namesApproves ){

            Map<String, String> approverFieldNameToHierarchyRoleMap = new Map<String, String>{
                'Direct_Manager__c' => UserHelper.DIRECT_MANAGER_ROLE,
                'Segment_Leader__c' => UserHelper.SEGMENT_LEADER_ROLE,
                'SVP_WWS__c' => UserHelper.SVP_WWS_ROLE,
                'SVP_WWS_Directs__c' => UserHelper.SVP_WWS_DIRECTS_ROLE,
                'Finance_Queue__c' => 'Finance Queue',
                'FeatureActivations__c' => 'Feature Activations'
            };

            List<String> approverHierarchyRoleList = new List<String>();
            ApprovalAssignment__c approversCS;
            if (!appr.Proserv_Billing_Start__c){
                try {

                    List<String> selectedFields = appr.AdditionalFeatures__c.split( '; ' );
                    for( String field : selectedFields ) {
                        approversCS = approvalAssignmentsCS.get( APINameTolabelFieldsMap.get( field ));
                        for( String approver : namesApproves ) {

                            if( (Boolean)approversCS.get( approver ) ) {

                                String hierarchyRoleName = approverFieldNameToHierarchyRoleMap.get(approver);

                                approverHierarchyRoleList.add( hierarchyRoleName );
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('e >>>> ' + e);
                    appr.addError('Not able to get steps for approval. Please contact administrator. Administrator info:  Please make sure that the custom setting ApprovalAssignment__c is up to date. If it is, and the error\'s still there - please contact sustain developers team. Thank you!');
                    System.debug(e.getMessage());
                }
            } else{
                approversCS = approvalAssignmentsCS.get( 'ProServ Billing Start' );
                for( String approver : namesApproves ) {

                    if( (Boolean)approversCS.get( approver ) ) {

                        String hierarchyRoleName = approverFieldNameToHierarchyRoleMap.get(approver);

                        approverHierarchyRoleList.add( hierarchyRoleName );
                    }
                }
            }
            return approverHierarchyRoleList;
        }

        private List<String> filterHierarchyRoles(List<String> approvalSteps) {

            List<String> result = new List<String>();

            Set<String> hierarchyRolesSet = UserHelper.hierarchyRolesNameToOrderMap.keySet();

            for(String item : approvalSteps) {

                if(hierarchyRolesSet.contains(item)) {

                    result.add(item);
                }
            }

            return result;
        }

        private List<String> filterNotHierarchyRoles(List<String> approvalSteps) {

            List<String> result = new List<String>();

            Set<String> hierarchyRolesSet = UserHelper.hierarchyRolesNameToOrderMap.keySet();

            for(String item : approvalSteps) {

                if(!hierarchyRolesSet.contains(item)) {

                    result.add(item);
                }
            }

            return result;
        }

        private Boolean isNeedClearStatus(Approval__c appr, Approval__c oldApproval) {

            Boolean level1ApprovalChanged = appr.Level1Approver__c != oldApproval.Level1Approver__c;
            Boolean level2ApprovalChanged = appr.Level2Approver__c != oldApproval.Level2Approver__c;
            Boolean level3ApprovalChanged = appr.Level3Approver__c != oldApproval.Level3Approver__c;
            Boolean level4ApprovalChanged = appr.Level4Approver__c != oldApproval.Level4Approver__c;

            Boolean featureActivationsChanged = appr.Level5Approver__c != oldApproval.Level5Approver__c;
            Boolean financeChanged = appr.Finance__c != oldApproval.Finance__c;

            Boolean appoverFieldsValueUpdated = (level1ApprovalChanged || level2ApprovalChanged || level3ApprovalChanged || level4ApprovalChanged || featureActivationsChanged || financeChanged);


            Boolean pocGlobalOfficeChanged = appr.POCGlobalOffice__c != oldApproval.POCGlobalOffice__c;
            Boolean pocEnableFullTestingCapabilityChanged = appr.POCEnableFullTestingCapability__c != oldApproval.POCEnableFullTestingCapability__c;
            Boolean pocSendOutAdditionlDevicesChanged = appr.POCSendOutAdditionalPOCDevices__c != oldApproval.POCSendOutAdditionalPOCDevices__c;
            Boolean pocExtensionUpTo60DaysChanged = appr.POCExtensionUpTo60Days__c != oldApproval.POCExtensionUpTo60Days__c;
            Boolean pocExtensionPlus61DaysChanged = appr.POCExtension61PlusDays__c != oldApproval.POCExtension61PlusDays__c;
            Boolean pocPeoplePerMeetingChanged = appr.PeoplePerMeeting__c != oldApproval.PeoplePerMeeting__c;
            Boolean pocZenDescIntegrationChanged = appr.IntegrationWithSFDCZendeskDesk__c != oldApproval.IntegrationWithSFDCZendeskDesk__c;
            Boolean pocCostCenterManagementChanged = appr.CostCenterManagement__c != oldApproval.CostCenterManagement__c;
            Boolean pocSingleSignOnChanged = appr.SingleSignOn__c != oldApproval.SingleSignOn__c;
            Boolean pocInboundCallerChanged = appr.InboundCallerIDName__c != oldApproval.InboundCallerIDName__c;
            Boolean pocVoiceMailToTextChanged = appr.VoicemailToTextStandard__c != oldApproval.VoicemailToTextStandard__c;
            Boolean pocHDVoiceChanged = appr.HDVoice__c != oldApproval.HDVoice__c;
            Boolean pocHotDeskingChanged = appr.Hot_Desking__c != oldApproval.Hot_Desking__c;
            Boolean pocAutomaticCallRecordingChanged = appr.AutomaticCallRecording__c != oldApproval.AutomaticCallRecording__c;
            Boolean pocCustomRolesChanged = appr.Custom_Roles__c != oldApproval.Custom_Roles__c;
            Boolean pocActiveDirectoryIntegrationChanged = appr.Active_Directory_Integration__c != oldApproval.Active_Directory_Integration__c;
            Boolean pocCallMonitoringChanged = appr.Call_Monitoring__c != oldApproval.Call_Monitoring__c;
            Boolean pocVoiceMailToTextPremiumChanged = appr.VoicemailToTextPremium__c != oldApproval.VoicemailToTextPremium__c;
            Boolean pocX75PeoplePerMeetingChanged = appr.X75_People_per_meeting__c != oldApproval.X75_People_per_meeting__c;


            Boolean featureCheckboxesUpdated = (pocGlobalOfficeChanged || pocEnableFullTestingCapabilityChanged || pocSendOutAdditionlDevicesChanged ||
                                                pocExtensionUpTo60DaysChanged || pocExtensionPlus61DaysChanged || pocPeoplePerMeetingChanged ||
                                                pocZenDescIntegrationChanged || pocCostCenterManagementChanged || pocSingleSignOnChanged ||
                                                pocInboundCallerChanged || pocVoiceMailToTextChanged || pocHDVoiceChanged || pocHotDeskingChanged ||
                                                pocAutomaticCallRecordingChanged || pocCustomRolesChanged || pocActiveDirectoryIntegrationChanged ||
                                                pocCallMonitoringChanged || pocVoiceMailToTextPremiumChanged || pocX75PeoplePerMeetingChanged);


            return appoverFieldsValueUpdated || featureCheckboxesUpdated;
        }

        private Boolean checkAutoApprove(Approval__c appr) {

            Boolean level1ApprovalEmpty = appr.Level1Approver__c == null;
            Boolean level2ApprovalEmpty = appr.Level2Approver__c == null;
            Boolean level3ApprovalEmpty = appr.Level3Approver__c == null;
            Boolean level4ApprovalEmpty = appr.Level4Approver__c == null;

            Boolean autoApproveNeeded = (level1ApprovalEmpty && level2ApprovalEmpty &&
                                            level3ApprovalEmpty && level4ApprovalEmpty &&
                                            appr.Level5Approver__c == false && appr.Finance__c == false);

            return autoApproveNeeded;
        }


        public String generateStringFromSelectedChechboxes( Approval__c appr, Map<String, String> APINameTolabelFieldsMap, Boolean isAPI ) {
            String additionalFeatures = '';

            if ( isAPI ) {
                for( String field : APINameTolabelFieldsMap.keySet() ) {
                    if (appr.get( field ) == null) {
                        continue;
                    }
                    if (appr.get( field ) instanceof  String || (appr.get(field) instanceof Boolean && (Boolean)appr.get(field))) {
                        additionalFeatures += field + '; ';
                    }
                }
                if ( String.isNotBlank(String.valueOf(appr.get('Free_Active_Virtual_Extensions__c')) ) ) {
                    additionalFeatures += 'Free_Active_Virtual_Extensions__c; ';
                }
            } else {
                for( String field : APINameTolabelFieldsMap.keySet() ) {
                    if (appr.get( field ) == null) {
                        continue;
                    }
                    if (appr.get( field ) instanceof  String || (appr.get(field) instanceof Boolean && (Boolean)appr.get(field))) {
                        if (appr.get( field ) == 'Entire Account' || appr.get( field ) == 'Specified Number' || APINameTolabelFieldsMap.get(field) == 'Other'){
                            continue;
                        }
                        additionalFeatures += APINameTolabelFieldsMap.get(field) + '; ';
                    }
                }
                if ( String.isNotBlank(String.valueOf(appr.get('Free_Active_Virtual_Extensions__c'))) ) {
                    if (appr.get('Free_Active_Virtual_Extensions__c') == 'Entire Account') {
                        additionalFeatures += 'Free Mobile Users for entire Account; ';
                    } else if (appr.get('Free_Active_Virtual_Extensions__c') == 'Specified Number') {
                        Integer numberOfFreeMobUser = appr.get('Number_of_free_Virtual_Extensions__c') == null ? 0 : ((Decimal)appr.get('Number_of_free_Virtual_Extensions__c')).intValue();
                        additionalFeatures +=  numberOfFreeMobUser + ' free Mobile User(s); ';
                    }
                }
                if ( String.isNotBlank(String.valueOf(appr.get('Other__c'))) ){
                    additionalFeatures += 'Other: ' + appr.get('Other__c');
                }
            }

            return additionalFeatures;
        }

        public Map<Id, String> createMapAccToTier( List<Account> accs) {
            Pattern regexPattern = Pattern.compile('\\[\\d+\\]');
            Map<Id, String> accToTierMap = new Map< Id, String>();

            for( Account acc : accs ) {
                String tier = acc.RC_Tier__c == null ? '' : acc.RC_Tier__c;
                Matcher regexMatcher = regexPattern.matcher( tier );
                if ( regexMatcher.find() ) {
                    accToTierMap.put( acc.Id , regexMatcher.group().removeStart('[').removeEnd(']') );
                } else {
                    accToTierMap.put( acc.Id , null );
                }
            }

            return accToTierMap;
        }

        public Map<String, String> createMapTierToEdition( List<String> tiers) {
            Map<String, String> tierToEditionMap = new Map<String, String>();
            List<Pricebook2> pb2s = [ SELECT Tier_ID__c, Edition__c FROM Pricebook2 WHERE Tier_ID__c IN :tiers ];

            for( Pricebook2 pb2 : pb2s ) {
                tierToEditionMap.put( pb2.Tier_ID__c, pb2.Edition__c );
            }

            return tierToEditionMap;
        }

        //if salesOwner's not set on approval creation- we set it as account owner.
        public void setSalesOwner(List<Approval__c> approvals) {
            Map<Id, Account> accounts = getAccountsToSetSalesOwner(approvals);
            for (Approval__c app : approvals) {
                if (accounts.get(app.Account__c) != null){
                    app.Refund_Owner__c = determineRefundOwnerId(accounts.get(app.Account__c));
                }
            }
        }

        private String determineAccountType(Decimal numberOfPOCUsers, String rcAccountStatus, String rcUserID) {

            String accType = '';

            // Fill AccountType__c field according to the logic below
            if (numberOfPOCUsers > 0 && rcAccountStatus != RC_ACC_STATUS_PAID && rcAccountStatus != RC_ACC_STATUS_DISABLED && rcAccountStatus != RC_ACC_STATUS_CANCELLED) {
                accType = APPROVAL_ACC_TYPE_POC;
            } else if (String.isNotBlank(rcUserID)) {
                accType = APPROVAL_ACC_TYPE_EXISTING;
            } else {
                accType = APPROVAL_ACC_TYPE_NEW;
            }

            return accType;
        }

        private Map<Id, Account> getAccountsToSetSalesOwner(List<Approval__c> approvals) {
            Set<Id> accountsToQuery = new Set<Id>();
            for (Approval__c app : approvals) {
                if (String.isBlank(app.Refund_Owner__c)){
                    accountsToQuery.add(app.Account__c);
                }
            }
            return new Map<Id, Account>([SELECT Id, Account__c, Current_Owner__c, Current_Owner__r.isActive, Current_Owner__r.ManagerId, Current_Owner__r.Manager.isActive, Current_Owner__r.Manager.ManagerId, Current_Owner__r.Manager.Manager.isActive FROM Account WHERE Id IN: accountsToQuery]);
        }

        private Id determineRefundOwnerId(Account acc) {
            //could be that quote's opportunity owner is inactive - handle those situations.
            if (acc.Current_Owner__r.isActive){
                return acc.Current_Owner__c;
            }
            if (acc.Current_Owner__r.ManagerId != null && acc.Current_Owner__r.Manager.isActive){
                return acc.Current_Owner__r.ManagerId;
            }
            if (acc.Current_Owner__r.ManagerId != null && acc.Current_Owner__r.Manager.ManagerId != null && acc.Current_Owner__r.Manager.Manager.isActive){
                return acc.Current_Owner__r.Manager.ManagerId;
            }
            //if even manager.manager is inactive - return quote.Owner, which will throw an error
            return acc.Current_Owner__c;
        }
    }

    @TestVisible
    private static String populateApprovalName(Approval__c app){
        final String NGBSApprovalPrefix = 'NGBS';
        final String InvoicingRequestPrefix = 'Invoicing Request "';
        final String BillingDateChangeRequestPrefix = 'Change Billing Date "';
        List<Approval__c> invoicingRequestApprovals = new List<Approval__c>();
        List<Approval__c> billingDateChangeRequestApprovals = new List<Approval__c>();
        String approvalName = '';
        String recordType = ApprovalHelperCls.rtMapByName.get(app.recordtypeId).getName();
        String accountName = ApprovalHelperCls.accountStaticMap.get(app.Account__c).Name;
        if (app.RecordtypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST || app.RecordtypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL) {
            Set<String> approvalTypes = new Set<String> {
                ApprovalHelper.RT_ID_INVOICING_REQUEST,
                ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL
            };
            Account accWithApprovals = (Account) new AccountSelector()
                .selectAccountWithAllApprovals(app.Account__c, approvalTypes)
                .executeQuery()
                .get(0);

            for (Approval__c appr : accWithApprovals.Approvals__r) {
                if (appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                    invoicingRequestApprovals.add(appr);
                } else if (appr.RecordTypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL) {
                    billingDateChangeRequestApprovals.add(appr);
                }
            }
        }

        Boolean isAPCChangedOnApprovedRecord = Trigger.isUpdate
            && ApprovalHelper.isApprovalApproved(app)
            && app.InvoiceApprovalType__c == ApprovalHelper.GOTOTHEFINALSTEP
            && (CoreObjectBase.isFieldChanged(app, Approval__c.AccountPayableContact__c)
                || CoreObjectBase.isFieldChanged(app, Approval__c.PartnerAccountPayableContact__c));

        if (app.RecordtypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
            if (Trigger.isInsert) {
                approvalName = InvoicingRequestPrefix + accountName + '" ' + String.valueOf(invoicingRequestApprovals.size() + 1);
            } else if (Trigger.isUpdate && app.Name.startsWith(InvoicingRequestPrefix)) {
                approvalName = app.Name;
            }
            approvalname = approvalname.abbreviate(80);
            return approvalName;
        }

        if (app.RecordtypeId == ApprovalHelper.RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL) {
            if (Trigger.isInsert) {
                approvalName = BillingDateChangeRequestPrefix + accountName + '" ' + String.valueOf(billingDateChangeRequestApprovals.size() + 1);
            } else if (Trigger.isUpdate && app.Name.startsWith(BillingDateChangeRequestPrefix)) {
                approvalName = app.Name;
            }
            approvalname = approvalname.abbreviate(80);
            return approvalName;
        }

        String apcChange = isAPCChangedOnApprovedRecord
            ? '(Change APC)'
            : '';
        approvalName = recordType + apcChange + ' - ' + accountName;

        if (app.RecordtypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
            if (app.Name.startsWith(NGBSApprovalPrefix)) {
                approvalName = app.Name;
            } else if (app.Status__c == ApprovalHelper.STATUS_PENDING_APPROVAL
                && TaxExemptionHelper.isAccountBasedTaxExemptionFlow(app)) {

                approvalName = NGBSApprovalPrefix + ' ' + approvalName;
            }
        }

        approvalname = approvalname.abbreviate(80);
        return approvalName;
    }

    private static Approval__c fillApproverLvls(List<Id> approversIdList, Approval__c appr, Map<Id, Feature_Add_Ons_Approval__c> FeatureAddOnMapping) {

        if(approversIdList == null || appr == null) {
            return appr;
        }
        if(appr.Account__c != null &&  appr.RecordTypeId  == ApprovalHelper.RT_ID_FEATURE_ADD_ONS_APPROVAL) {
            Set<String> targetIdSet = new Set<String>();
            for (FeatureAddonApproversRemoval__c approver : FeatureAddonApproversRemoval__c.getall().values()) {
                targetIdSet.add(approver.User_ID__c);
            }
            List<Id> newApproversIdList = new List<Id>();
            for(Id approverId : approversIdList) {
                if(targetIdSet.contains(approverId)) {
                    if(approversIdList.indexOf(approverId) == 0) {
                        newApproversIdList.add(approverId);
                    }
                    break;
                }else {
                    newApproversIdList.add(approverId);
                }
            }
            if(newApproversIdList.size()!=null) {
                approversIdList=newApproversIdList;
            }
        }

        if(approversIdList.size() == 0) {

            // approval from User don't needed - clear fields
            appr.Level1Approver__c = null;
            appr.Level2Approver__c = null;
            appr.Level3Approver__c = null;
            appr.Level4Approver__c = null;

        }else if(approversIdList.size() == 1) {

            appr.Level1Approver__c = approversIdList.get(0);
            appr.Level2Approver__c = null;
            appr.Level3Approver__c = null;
            appr.Level4Approver__c = null;

        }else if(approversIdList.size() == 2) {

            appr.Level1Approver__c = approversIdList.get(0);
            appr.Level2Approver__c = approversIdList.get(1);
            appr.Level3Approver__c = null;
            appr.Level4Approver__c = null;

        }else if(approversIdList.size() == 3) {

            appr.Level1Approver__c = approversIdList.get(0);
            appr.Level2Approver__c = approversIdList.get(1);
            appr.Level3Approver__c = approversIdList.get(2);
            appr.Level4Approver__c = null;

        }else if(approversIdList.size() == 4) {

            appr.Level1Approver__c = approversIdList.get(0);
            appr.Level2Approver__c = approversIdList.get(1);
            appr.Level3Approver__c = approversIdList.get(2);
            appr.Level4Approver__c = approversIdList.get(3);

        }else if(approversIdList.size() == 5) {

            appr.Level1Approver__c = approversIdList.get(0);
            appr.Level2Approver__c = approversIdList.get(1);
            appr.Level3Approver__c = approversIdList.get(2);
            appr.Level4Approver__c = approversIdList.get(3);
        }

        if(FeatureAddOnMapping != null && FeatureAddOnMapping.keyset().contains(appr.OwnerId) && approversIdList.size() == 5){
            appr.InvoiceBillingLevel5Approver__c = approversIdList.get(4);
        }else{
            appr.InvoiceBillingLevel5Approver__c = null;
        }

        return appr;
    }
    private static Approval__c fillApproverLvls(List<Id> approversIdList, Approval__c appr) {

		if(approversIdList == null || appr == null) {
			return appr;
		}

		if(approversIdList.size() == 0) {

			// approval from User don't needed - clear fields
			appr.Level1Approver__c = null;
			appr.Level2Approver__c = null;
			appr.Level3Approver__c = null;
			appr.Level4Approver__c = null;

		}else if(approversIdList.size() > 1) {

			appr.Level1Approver__c = approversIdList.get(0);
			appr.Level2Approver__c = null;
			appr.Level3Approver__c = null;
			appr.Level4Approver__c = null;

		}

		return appr;
	}


    public class SetAccountId extends Triggers.TriggerHandlerBase {
        /*
        * Copy AccountId from related Opportunity record
        * for approvals with Invoicing_Request recordType
        */
        override public void handle() {

            Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Approval__c.getRecordTypeInfosById();

            List<Approval__c> approvalsToProcess = new List<Approval__c>();

            for(Approval__c item : (List<Approval__c>) Trigger.new) {

                if(ApprovalHelper.isApprovalOfInvoicingType(item)) {
                    approvalsToProcess.add(item);
                }
            }

            if(approvalsToProcess.size() > 0) {
                List<Approval__c> processedApprovals = populateAccountId(approvalsToProcess);
            }
        }

        private List<Approval__c> populateAccountId(List<Approval__c> approvals) {

            Set<Id> oppIdSet = new Set<Id>();

            for(Approval__c item : approvals) {
                oppIdSet.add(item.Opportunity__c);
            }

            List<Approval__c> updatedApprovals = new List<Approval__c>();

            if(oppIdSet.size() > 0) {

                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([select Id, AccountId from Opportunity where Id in :oppIdSet]);

                for(Approval__c item : approvals) {

                    Opportunity opp = oppMap.get(item.Opportunity__c);

                    if(item.Account__c != opp.AccountId) {

                        item.Account__c = opp.AccountId;
                        updatedApprovals.add(item);
                    }
                }
            }

            return updatedApprovals;
        }
    }


    public class SetCurrencyIsoCode extends Triggers.TriggerHandlerBase {
        public SetCurrencyIsoCode() {
            super();
        }
        public SetCurrencyIsoCode(TriggerOperation operationType, List<Approval__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            List<Approval__c> approvalsRelatedToAccount = new List<Approval__c>();
            Set<Id> relatedAccountsIds = new Set<Id>();

            List<Approval__c> approvalsRelatedToOpportunity = new List<Approval__c>();
            Set<Id> relatedOpportunitiesIds = new Set<Id>();

            for (Approval__c app : (List<Approval__c>) this.triggerRecords) {
                /* Special case for KYC Approvals */
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    app.CurrencyIsoCode = RingCentralHelper.INR;
                    continue;
                }
                if (isApprovalRelatedToAccount(app)) {
                    approvalsRelatedToAccount.add(app);
                    relatedAccountsIds.add(app.Account__c);
                }
                if (isApprovalRelatedToOpportunity(app)) {
                    approvalsRelatedToOpportunity.add(app);
                    relatedOpportunitiesIds.add(app.Opportunity__c);
                }
            }

            Map<Id, Account> relatedAccountsMap = relatedAccountsIds.isEmpty()
                ? new Map<Id, Account>()
                : new Map<Id, Account>(
                    (List<Account>) new AccountSelector()
                        .selectOnlyAccountsByIds(new List<Object>{relatedAccountsIds})
                        .selectFields(new List<String>{'CurrencyIsoCode'})
                        .executeQuery()
                    );
            Map<Id, Opportunity> relatedOpportunitiesMap = relatedOpportunitiesIds.isEmpty()
                ? new Map<Id, Opportunity>()
                : new Map<Id, Opportunity>(
                    (List<Opportunity>) new OpportunitySelector()
                        .selectOpportunitiesByIds(relatedOpportunitiesIds)
                        .selectFields(new List<String>{'CurrencyIsoCode'})
                        .executeQuery()
                    );

            for (Approval__c app : approvalsRelatedToAccount) {
                app.CurrencyIsoCode = relatedAccountsMap.get(app.Account__c).CurrencyIsoCode;
            }
            for (Approval__c app : approvalsRelatedToOpportunity) {
                app.CurrencyIsoCode = relatedOpportunitiesMap.get(app.Opportunity__c).CurrencyIsoCode;
            }
        }

        private Boolean isApprovalRelatedToAccount(Approval__c app) {
            return app.Account__c != null
                && app.RecordTypeId == ApprovalHelper.RT_ID_REFUND_APPROVAL
                || (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && TaxExemptionHelper.isEnabled);
        }

        private Boolean isApprovalRelatedToOpportunity(Approval__c app) {
            return app.Opportunity__c != null && (ApprovalHelper.isApprovalOfInvoicingType(app));
        }
    }

    public class CopyInvoiceValuesToRelatedRecords extends Triggers.TriggerHandlerBase {
        /*
        * Copy values from Invoicing Request approval
        * to related Account
        */
        override public void handle() {

            // First pass - collect account IDs for invoices that need to be loaded
            Set<Id> invoiceAccIds = new Set<Id>();
            for (Approval__c appr : (List<Approval__c>) Trigger.new) {
                Boolean isInvoicingRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST;
                Boolean isRecordBecomeApproved = isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED);
                Boolean isImportantFieldsChangedOnApprovedRecord = appr.Status__c == APPROVAL_STATUS_APPROVED &&
                    (isChangedField(appr, Approval__c.Sign_Up_Purchase_Limit__c) ||
                    isChangedField(appr, Approval__c.Monthly_Credit_Limit__c) ||
                    isChangedField(appr, Approval__c.Invoice_Terms__c) ||
                    isChangedField(appr, Approval__c.Payment_Terms__c));

                Boolean shouldProceed = isInvoicingRequest
                    && (isRecordBecomeApproved || isImportantFieldsChangedOnApprovedRecord)
                    && appr.Account__c != null;

                if (shouldProceed) {
                    invoiceAccIds.add(appr.Account__c);
                }
            }

            // Load accounts using AccountSelector
            Map<Id, Account> accountsMap = new Map<Id, Account>();
            if (!invoiceAccIds.isEmpty()) {
                List<Account> accountsList = (List<Account>) new AccountSelector()
                    .selectOnlyAccountsByIds(new List<Object>{new List<Id>(invoiceAccIds)})
                    .executeQuery();
                for (Account acc : accountsList) {
                    accountsMap.put(acc.Id, acc);
                }
            }

            List<Account> accListToUpd = new List<Account>();
            List<Opportunity> oppListToUpdate = new List<Opportunity>();
            List<Approval__c> technicalApprovals = new List<Approval__c>();

            Map<Id, Boolean> approvalsToProcess = new Map<Id, Boolean>();
            List<Id> oppIdsForQuoteUpdate = new List<Id>();
            List<Quote> quoteListToUpdate = new List<Quote>();

            for (Approval__c appr : (List<Approval__c>) Trigger.new) {
                Boolean isInvoicingRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST;
                Boolean isInvoiceOnBehalfRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST;
                Boolean isInvoiceWholesaleRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST;
                Boolean isRecordBecomeApproved = isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED);
                Boolean isImportantFieldsChangedOnApprovedRecord = appr.Status__c == APPROVAL_STATUS_APPROVED &&
                    (isChangedField(appr, Approval__c.Sign_Up_Purchase_Limit__c) ||
                    isChangedField(appr, Approval__c.Monthly_Credit_Limit__c) ||
                    isChangedField(appr, Approval__c.Invoice_Terms__c) ||
                    isChangedField(appr, Approval__c.Payment_Terms__c));

                Boolean shouldProceed = (isInvoicingRequest || isInvoiceOnBehalfRequest || isInvoiceWholesaleRequest)
                    && (isRecordBecomeApproved || isImportantFieldsChangedOnApprovedRecord)
                    && appr.Account__c != null;

                approvalsToProcess.put(appr.Id, shouldProceed);
                if (shouldProceed && appr.Opportunity__c != null) {
                    oppIdsForQuoteUpdate.add(appr.Opportunity__c);
                }
            }

            List<Quote> quotesToUpdate = new QuoteSelector()
                .selectQuotesForShippingByOppIds(oppIdsForQuoteUpdate)
                .selectField('OpportunityId')
                .executeQuery();

            for (Approval__c appr : (List<Approval__c>) Trigger.new) {
                if (!approvalsToProcess.get(appr.Id)) {
                    continue;
                }

                Boolean isInvoicingRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST;
                Boolean isInvoiceOnBehalfRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST;
                Boolean isInvoiceWholesaleRequest = appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST;

                if (masterApprovalToTechnicalApprovals.get(appr.Id) != null) {
                    technicalApprovals = masterApprovalToTechnicalApprovals.get(appr.Id);
                }

                Account acc = new Account(Id = appr.Account__c);
                acc.Sign_up_Purchase_Limit__c = appr.Sign_up_Purchase_Limit__c;
                acc.Payment_Method__c = isInvoicingRequest
                    ? AccountHelper.PAYMENT_METHOD_INVOICE
                    : isInvoiceOnBehalfRequest
                        ? AccountHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF
                        : AccountHelper.PAYMENT_METHOD_WHOLESALE;
                acc.Monthly_Credit_Limit__c = appr.Monthly_Credit_Limit__c;
                acc.Approval_Date__c = appr.Completed_Date__c;
                acc.Active_Invoice_Approval__c = appr.Id;
                acc.Invoice_Terms__c = appr.Invoice_Terms__c;
                acc.Payment_Terms__c = appr.Payment_Terms__c;

                if (isInvoicingRequest) {
                    Account customerAccount = accountsMap.get(appr.Account__c);
                    if (customerAccount != null && AccountHelper.isExistingBusiness(customerAccount)) {
                        for (Quote quote : quotesToUpdate) {
                            if (quote.OpportunityId == appr.Opportunity__c) {
                                quote.PaymentMethod__c = QuoteHelper.PAYMENT_METHOD_INVOICE;
                                quoteListToUpdate.add(quote);
                            }
                        }
                    }
                }

                if (isInvoicingRequest && appr.IsChangePaymentMethodRequest__c) {
                    if (String.isNotBlank(appr.SwitchInvoicePartnerAccount__c)) {
                        Account partnerAccount = customerToPartnerAccounts.get(appr.Account__c);
                        acc = AccountHelper.copyPartnerInformation(acc, partnerAccount);
                        acc.Partner_Contact__c = partnerAccount.AccountContactRoles.size() > 0
                            ? partnerAccount.AccountContactRoles[0].ContactId
                            : partnerAccount.Partner_Contact__c;
                    } else {
                        acc.Partner_Account__c = null;
                        acc.Partner_ID__c = null;
                        acc.Partner_Type__c = null;
                        acc.Partner_Account_Name__c = null;
                        acc.Partner_Contact__c = null;
                        acc.Parent_Partner_Account__c = null;
                        acc.Ultimate_Partner_Name__c = null;
                        acc.Ultimate_Partner_ID__c = null;
                        acc.Settlement_Type__c = null;
                    }
                }

                if (isInvoiceOnBehalfRequest) {
                    Account partnerAccount = customerToPartnerAccounts.get(appr.Account__c);
                    acc = AccountHelper.copyPartnerInformation(acc, partnerAccount);
                    acc.Partner_Contact__c = appr.PartnerAccountPayableContact__c;
                }

                if (appr.Opportunity__c != null && !isInvoiceWholesaleRequest) {
                    Opportunity opp = new Opportunity(Id = appr.Opportunity__c);
                    opp.Partner_Account__c = acc.Partner_Account__c;
                    opp.Partner_Contact__c = acc.Partner_Contact__c;
                    oppListToUpdate.add(opp);
                }

                Opportunity oppty = ApprovalHelperCls.opportunityStaticMap.get(appr.Opportunity__c);
                if (!technicalApprovals.isEmpty()
                    && (QuoteHelper.CREATE_TECHNICAL_ACCOUNT_FOR_SERVICES.contains(oppty.Tier_Name__c)
                        || oppty.Tier_Name__c == QuoteHelper.NGBS_OFFICE_PRODUCT)) {
                    for (Approval__c technicalApproval : technicalApprovals) {
                        acc = new Account(Id = technicalApproval.Account__c);
                        acc.Sign_up_Purchase_Limit__c = technicalApproval.Sign_up_Purchase_Limit__c;
                        acc.Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
                        acc.Monthly_Credit_Limit__c = technicalApproval.Monthly_Credit_Limit__c;
                        acc.Approval_Date__c = appr.Completed_Date__c;
                        acc.Active_Invoice_Approval__c = appr.Id;
                        acc.Invoice_Terms__c = appr.Invoice_Terms__c;
                        acc.Payment_Terms__c = appr.Payment_Terms__c;
                        accListToUpd.add(acc);
                    }
                    if (Trigger.isUpdate) {
                        appr.AccountSignUpPurchaseLimitCC__c = appr.Sign_Up_Purchase_Limit_Contact_Center__c > 0 ? appr.Sign_Up_Purchase_Limit_Contact_Center__c : null;
                        appr.AccountSignUpPurchaseLimitEV__c = appr.Sign_Up_Purchase_Limit_Engage_Voice__c > 0 ? appr.Sign_Up_Purchase_Limit_Engage_Voice__c : null;
                        appr.AccountSignUpPurchaseLimitED__c = appr.Sign_Up_Purchase_Limit_Engage_Digital__c > 0 ? appr.Sign_Up_Purchase_Limit_Engage_Digital__c : null;
                        appr.Account_Sign_Up_Purchase_Limit_RCEvents__c = appr.Sign_Up_Purchase_Limit_for_RC_Events__c > 0 ? appr.Sign_Up_Purchase_Limit_for_RC_Events__c : null;
                        appr.AccountMonthlyCreditLimitCC__c = appr.Monthly_Credit_Limit_Contact_Center__c > 0 ? appr.Monthly_Credit_Limit_Contact_Center__c : null;
                        appr.AccountMonthlyCreditLimitEV__c = appr.Monthly_Credit_Limit_Engage_Voice__c > 0 ? appr.Monthly_Credit_Limit_Engage_Voice__c : null;
                        appr.AccountMonthlyCreditLimitED__c = appr.Monthly_Credit_Limit_Engage_Digital__c > 0 ? appr.Monthly_Credit_Limit_Engage_Digital__c : null;
                        appr.AccountMonthlyCreditLimitRCEvents__c = appr.Monthly_Credit_Limit_for_RC_Events__c > 0 ? appr.Monthly_Credit_Limit_for_RC_Events__c : null;
                    }
                } else {
                    accListToUpd.add(acc);
                }
            }

            if(!accListToUpd.isEmpty()) {
                update accListToUpd;
            }
            Triggers.switchOff();
            if (!oppListToUpdate.isEmpty()) {
                update oppListToUpdate;
            }
            if (!quoteListToUpdate.isEmpty()) {
                update quoteListToUpdate;
            }
            Triggers.switchOn();
        }
    }

    public class BrandPartnerPopulationHandler extends BrandPartnerFieldPopulationHandler {
        public BrandPartnerPopulationHandler() {
            super(Approval__c.sObjectType);
        }
    }

    public class ProcessExistingApprovals extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Approval__c.getRecordTypeInfosById();
            Map<Id, Boolean> accountIdToChangePaymentRequestApprovals = new Map<Id, Boolean>();

            List<Id> approvalAccountIds = new List<Id>();

            for (Approval__c item : (List<Approval__c>) Trigger.new) {
                if (item.Account__c != null
                    && (ApprovalHelper.isApprovalOfInvoicingType(item))
                    && (!item.Status__c.equals(ApprovalHelper.STATUS_APPROVED)
                        || CoreObjectBase.isFieldChanged(item, Approval__c.AccountPayableContact__c)
                        || CoreObjectBase.isFieldChanged(item, Approval__c.PartnerAccountPayableContact__c))
                ) {
                    approvalAccountIds.add(item.Account__c);
                    accountIdToChangePaymentRequestApprovals.put(item.Account__c, item.IsChangePaymentMethodRequest__c);
				}
			}

			if (approvalAccountIds.size() == 0) {
				return;
			}

            List<String> approvalFields = getExistingApprovalFields((Approval__c) Trigger.new[0]);

			List<Approval__c> existingApprovals = (List<Approval__c>) new ApprovalSelector()
				.selectApprovalsForPartnerOperations(
					new List<Object>{
						new Set<Id>{
                            ApprovalHelper.RT_ID_INVOICING_REQUEST,
                            ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
                            ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
                        },
						approvalAccountIds,
						ApprovalHelper.APPROVAL_STATUSES
					},
				approvalFields
			)
			.executeQuery();

            // prepare data for comparing changes in SetApprovers if Approval was created from Account Viewer
            // received Approvals are already sorted by LastModifiedDate descending
            for (Approval__c existingApproval : existingApprovals) {
                if (accountIdToLastApprovedApprovalFromAccount.containsKey(existingApproval.Account__c)) {
                    continue;
                }
                if (existingApproval.Status__c.equals(ApprovalHelper.STATUS_APPROVED)) {
                    accountIdToLastApprovedApprovalFromAccount.put(
                        existingApproval.Account__c,
                        existingApproval.getPopulatedFieldsAsMap()
                    );
                }
            }

			if (Trigger.isBefore && Trigger.isInsert) {
				recallExistingApprovalsOnChangeRequest(existingApprovals, accountIdToChangePaymentRequestApprovals);
			}
		}

        private List<String> getExistingApprovalFields(Approval__c approval) {
            Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Approval__c.getRecordTypeInfosById();

            List<String> approvalFields = new List<String>();

            Metadata.Layout approvalLayout = SFDescribeHelper.getLayoutInfo(
                ApprovalHelper.APPROVAL_OBJECT_NAME,
                rtMapById.get( approval.RecordTypeId ).getName() == INVOICE_ON_BEHALF_REQUEST_APPROVAL_RT_NAME
                    ? 'Invoice-on-behalf Request Layout'
                    : 'Invoice Request Layout'
            );

            for (Metadata.LayoutSection section : approvalLayout.layoutSections) {
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            if (item.field != null && item.behavior == Metadata.UiBehavior.Required) {
                                approvalFields.add(item.field);
                            }
                        }
                    }
                }
            }
            approvalFields.AddAll(new List<String> {
                'Status__c',
                'InvoiceApprovalType__c',
                'RecordTypeId',
                'StatusLastModifiedDate__c',
                'Sign_Up_Purchase_Limit_Contact_Center__c',
                'Sign_Up_Purchase_Limit_Engage_Digital__c',
                'Sign_Up_Purchase_Limit_Engage_Voice__c',
                'Sign_Up_Purchase_Limit_Office__c',
                'Sign_Up_Purchase_Limit_for_RC_Events__c',
                'Monthly_Credit_Limit_Contact_Center__c',
                'Monthly_Credit_Limit_Engage_Digital__c',
                'Monthly_Credit_Limit_Engage_Voice__c',
                'Monthly_Credit_Limit_Office__c',
                'Monthly_Credit_Limit_for_RC_Events__c'
            });
            return approvalFields;
        }

		private void recallExistingApprovalsOnChangeRequest(
            List<Approval__c> approvalsList,
            Map<Id, Boolean> accountIdToChangePaymentRequestApprovals
        ) {
            List<Approval__c> approvalsToUpdate = new List<Approval__c>();
            for (Approval__c existingApproval : approvalsList) {
                if (
                    accountIdToChangePaymentRequestApprovals.get(existingApproval.Account__c)
                    && !existingApproval.Status__c.equals(ApprovalHelper.STATUS_APPROVED)
                ) {
                    existingApproval.Status__c = ApprovalHelper.STATUS_RECALLED;
                    approvalsToUpdate.add(existingApproval);
                }
            }

            if (approvalsToupdate.size() > 0) {
                Triggers.switchOff();
                update approvalsToUpdate;
                Triggers.switchOn();
            }
        }
    }

    public class SetApprovers extends Triggers.TriggerHandlerBase {
        override public void handle() {

            if ( Trigger.isInsert || Trigger.isUpdate ) {

                Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Approval__c.getRecordTypeInfosById();

                //process approvals with POC_Account recordType
                List<Approval__c> pocApprovals = filterPOCApprovals((List<Approval__c>) Trigger.new, rtMapById);
                if(pocApprovals.size() > 0) {
                    processPOCApprovals(pocApprovals);
                }


                //process approvals with Invoicing_Request, Invoice_On_Behalf_Request and Invoice_Wholesale recordTypes
                List<Approval__c> invoicingRequestApprovals = filterInvoicingRequestApprovals((List<Approval__c>) Trigger.new, rtMapById);
                if(invoicingRequestApprovals.size() > 0) {
                    processInvoicingRequestApprovals(invoicingRequestApprovals);
                }

                //process approvals with Bill_On_Behalf or Wholesale recordType
                List<Approval__c> accountPartnerfApprovals = filterAccountPartnerApprovals((List<Approval__c>) Trigger.new, rtMapById);

                if(accountPartnerfApprovals.size() > 0) {
                    processAccountPartnerApprovals(accountPartnerfApprovals);
                }

                //process approvals with DirectDebit recordType
                List<Approval__c> directDebitApprovals = filterDirectDebitApprovals((List<Approval__c>) Trigger.new);
                if(!directDebitApprovals.isEmpty()) {
                    processDirectDebitApprovals(directDebitApprovals);
                }
            }
        }

        private List<Approval__c> filterPOCApprovals(List<Approval__c> rawApprovalsList, Map<Id,Schema.RecordTypeInfo> rtMapById) {

            List<Approval__c> pocApprovals = new List<Approval__c>();

            if(rawApprovalsList == null || rtMapById == null) {
                return pocApprovals;
            }

            for(Approval__c item : rawApprovalsList) {

                if(rtMapById.get( item.RecordTypeId ).getName() == POC_ACCOUNT_APPROVAL_RT_NAME) {

                    if(Trigger.isUpdate) {

                        Approval__c apprOld = (Approval__c)Trigger.oldMap.get(item.Id);

                        Boolean pocChanged = item.Number_of_POC_Users__c != apprOld.Number_of_POC_Users__c;
                        Boolean rcxPOCChanged = item.Enable_RingCX_POC__c != apprOld.Enable_RingCX_POC__c;

                        if(!pocChanged && !rcxPOCChanged) {
                            continue;
                        }
                    }

                    pocApprovals.add(item);
                }
            }

            return pocApprovals;
        }

        private void processPOCApprovals(List<Approval__c> approvals) {
            processRingEXPOCApprovals(approvals);
            
            processRingCXPOCApprovals(approvals);
        }
        
        private void processRingCXPOCApprovals(List<Approval__c> approvals) {
            if (approvals == null || approvals.isEmpty()) {
                return;
            }

            Map<Id,Approval__c> approvalwithOppIds = new Map<Id,Approval__c>();
            for(Approval__c item : approvals) {
                if (item.Enable_RingCX_POC__c && item.Opportunity__c != null) {
                    approvalwithOppIds.put(item.Opportunity__c,item);
                }
            }
            
            Map<Id, OpportunityTeamMember> customerExperienceSEMap = getOpportunityTeamMemberMap(approvalwithOppIds.keySet(), CUSTOMER_EXPERIENCE_SE_ROLE);
            List<POCApprovalEmail__e> events = new List<POCApprovalEmail__e>();
            
            for (Approval__c approval : approvalwithOppIds.values()) {
                if (!customerExperienceSEMap.containsKey(approval.Opportunity__c)) {
                    events.add(new POCApprovalEmail__e(
                        OpportunityId__c = approval.Opportunity__c,
                        SubmitterUserId__c = UserInfo.getUserId()
                    ));
                    approval.addError('RingCX POC approval requires an associated Opportunity and an Opportunity Team member with the \'Customer Experience SE\' role. Please ensure both are in place to continue.');
                }
            }

            if (!events.isEmpty()) {
                try {
                    PlatformEvents.publishPlatformEvent(events, 'ApprovalTriggerHandler.processRingCXPOCApprovals');
                } catch (Exception e) {
                    Platformlog.logResult('ApprovalTriggerHandler', 'Error publishing POCApprovalEmail__e events', 'ErrorMessage: ' + e.getMessage() + ' StackTrace: ' + e.getStackTraceString(), null, null, false);
                }
            }

            if (events.isEmpty()) {
                assignRingCXApprovers(approvalwithOppIds.values(), customerExperienceSEMap);
            }
        }
        
        private Map<Id, OpportunityTeamMember> getOpportunityTeamMemberMap(Set<Id> oppIds, String role) {
            
            Map<Id, OpportunityTeamMember> teamMemberMap = new Map<Id, OpportunityTeamMember>();
            List<OpportunityTeamMember> teamMembers = (List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
                .selectByOpportunityIdsAndRoles(new List<Object> {oppIds, new List<String>{role}})
                .executeQuery();
                
            for (OpportunityTeamMember member : teamMembers) {
                teamMemberMap.put(member.OpportunityId, member);
            }
            return teamMemberMap;
        }
        
        private void assignRingCXApprovers(List<Approval__c> ringCXPOCApprovals, Map<Id, OpportunityTeamMember> customerExperienceSEMap) {
            for(Approval__c item : ringCXPOCApprovals) {
                OpportunityTeamMember customerExperienceSE = customerExperienceSEMap.get(item.Opportunity__c);
                
                if (customerExperienceSE != null) {
                    User aprUser = ApproversSearch.findUserById(customerExperienceSE.UserId);
                    if (item.Level1Approver__c != null  && item.Number_of_POC_Users__c > 0) {
                        item.Level2Approver__c = aprUser.ManagerId;
                    } else {
                        item.Level1Approver__c = aprUser.ManagerId;
                    }
                }
                if(item.Enable_RingCX_POC__c && item.Level1Approver__c != null && item.Status__c == APPROVAL_STATUS_APPROVED) {    
                    item.Status__c = APPROVAL_STATUS_REQUIRED;
                }
            }
        }
        
        private void processRingEXPOCApprovals(List<Approval__c> approvals) {
            Set<Id> oppIdSet = new Set<Id>();
            for(Approval__c item : approvals) {
                if (item.Number_of_POC_Users__c >= THRESHHOLD_DL_NO) {
                    oppIdSet.add(item.Opportunity__c);
                }
            }
            if (!oppIdSet.isEmpty()) {
                Map<Id, OpportunityTeamMember> oppTeamMemberMap = getOpportunityTeamMemberMap(oppIdSet, SE_ROLE);

                if (!oppTeamMemberMap.isEmpty()) {
                    for(Approval__c item : approvals) {
                        User aprUser = ApproversSearch.findUserById(oppTeamMemberMap.get(item.Opportunity__c).UserId);
                        item.Level1Approver__c = aprUser.ManagerId;
                    }
                }
            }
            else{
                POC_GOA__c pocSettings = POC_GOA__c.getInstance();

                List<QuoteApprovals.Range> rangeList = new List<QuoteApprovals.Range>();

                QuoteApprovals.Range salesRepPOC = new QuoteApprovals.Range(pocSettings.Sales_Rep__c, '-', UserHelper.SALES_REP_ROLE);
                rangeList.add(salesRepPOC);

                QuoteApprovals.Range directMangerPOC = new QuoteApprovals.Range(pocSettings.Direct_Manager__c, '-', UserHelper.DIRECT_MANAGER_ROLE);
                rangeList.add(directMangerPOC);

                QuoteApprovals.Range segmentLeaderPOC = new QuoteApprovals.Range(pocSettings.Segment_Leader__c, '-', UserHelper.SEGMENT_LEADER_ROLE);
                rangeList.add(segmentLeaderPOC);

                QuoteApprovals.Range svpWwsDirectsPOC = new QuoteApprovals.Range(pocSettings.SVP_WWS_Directs__c, '-', UserHelper.SVP_WWS_DIRECTS_ROLE);
                rangeList.add(svpWwsDirectsPOC);

                QuoteApprovals.Range svpWwsPOC = new QuoteApprovals.Range(pocSettings.SVP_WWS__c, '-', UserHelper.SVP_WWS_ROLE);
                rangeList.add(svpWwsPOC);


                for(Approval__c item : approvals) {

                    // use approval creator user as startedSearch user instead of current user
                    User currentUser = ApproversSearch.findUserById(item.OwnerId);

                    String currentUserHRole = currentUser.Hierarchy_Role__c;

                    Boolean isSuitableRole = ApproversSearch.isSuitableHierarchyRole(currentUserHRole);

                    if(currentUserHRole == null || !isSuitableRole) {
                        currentUserHRole = UserHelper.SALES_REP_ROLE;
                    }


                    for(QuoteApprovals.Range currentRange : rangeList) {

                        Boolean pocValueInRange = currentRange.isInRange(item.Number_of_POC_Users__c);

                        if(pocValueInRange) {

                            // determine Status__c
                            Boolean setStatusToApproved = (UserHelper.hierarchyRolesNameToOrderMap.get(currentRange.rangeName) == UserHelper.hierarchyRolesNameToOrderMap.get(currentUserHRole)) ||
                                UserHelper.hierarchyRolesNameToOrderMap.get(currentUserHRole) > UserHelper.hierarchyRolesNameToOrderMap.get(currentRange.rangeName);

                            if(setStatusToApproved) {
                                item.Status__c = APPROVAL_STATUS_APPROVED;

                                // status is Approved - clear Lvl#Approver fields
                                item.Level1Approver__c = null;
                                item.Level2Approver__c = null;
                                item.Level3Approver__c = null;
                                item.Level4Approver__c = null;

                            }else{
                                item.Status__c = APPROVAL_STATUS_REQUIRED;

                                ApproversSearch approversSearcher = new ApproversSearch();

                                List<Id> approversIdList = approversSearcher.findApproverIdsByHierarchyRoles(new List<String>{ currentRange.rangeName }, currentUser);

                                item = fillApproverLvls(approversIdList, item, null);
                            }
                        }
                    }
                }
            }
        }

        private List<Approval__c> filterAccountPartnerApprovals(List<Approval__c> rawApprovalsList, Map<Id,Schema.RecordTypeInfo> rtMapById) {

            List<Approval__c> accPartnerApprovals = new List<Approval__c>();

            if(rawApprovalsList == null || rtMapById == null) {
                return accPartnerApprovals;
            }

            for(Approval__c approval : rawApprovalsList) {

                if(rtMapById.get( approval.RecordTypeId ).getName() == ApprovalHelper.RT_NAME_BOB_APPROVAL
                    || rtMapById.get( approval.RecordTypeId ).getName() == ApprovalHelper.RT_NAME_WHOLESALE_APPROVAL) {

                    populatePartnerFields(approval);

                    if(Trigger.isUpdate) {

                        Approval__c apprOld = (Approval__c)Trigger.oldMap.get(approval.Id);

                        Boolean partnerMRRChanged = approval.Partner_MRR__c != apprOld.Partner_MRR__c;

                        if (partnerMRRChanged) {
                            if (approval.Status__c == ApprovalHelper.STATUS_REQUIRED) {
                                setAccountPartnerApprovalFlow(approval);
                            } else {
                                approval.Status__c = ApprovalHelper.STATUS_REJECTED;
                                setAccountPartnerApprovalFlow(approval);
                            }
                            approval.NS_Assignment__c = false;
                        } else {
                            if (approval.Status__c == ApprovalHelperCls.STATUS_PENDING_L1_APPROVAL
                                && apprOld.Status__c != ApprovalHelperCls.STATUS_PENDING_L1_APPROVAL) {
                                if (approval.NS_Assignment__c) {
                                    approval.Status__c = ApprovalHelper.STATUS_PENDING_APPROVAL;
                                } else {
                                    approval.NS_Assignment__c = true;
                                }
                            }

                            if (approval.Status__c == ApprovalHelper.STATUS_REJECTED
                                && apprOld.Status__c == ApprovalHelperCls.STATUS_PENDING_L1_APPROVAL) {
                                approval.NS_Assignment__c = false;
                            }
                        }
                        continue;
                    }

                    accPartnerApprovals.add(approval);
                }
            }

            return accPartnerApprovals;
        }

        private void populatePartnerFields(Approval__c approval) {
            approval.Legal_Company_Name_Head_Office__c = approval.Partner_Company_Name__c;
            approval.Legal_Physical_Address_Street__c = approval.Partner_Address__c;
            approval.Legal_Physical_Address_City__c = approval.Partner_City__c;
            approval.Legal_Physical_Address_State_Province__c = approval.Partner_State_Province__c;
            approval.Legal_Physical_Address_Zip_Code__c = approval.Partner_Zip_Code__c;
            approval.Legal_Physical_Address_Country__c = approval.Partner_Country__c;
            approval.Monthly_Credit_Limit__c = 0;
        }

        private void populateL1Approvers(Approval__c approval){
            Opportunity Opp = [select id, Owner.Manager_Id__c from Opportunity where Id = :approval.Opportunity__c limit 1];
            system.debug('Opportunity Manager Id:' +Opp.Owner.Manager_Id__c);
            if(Opp.Owner.Manager_Id__c != null){
                system.debug('L1 approver before update:' +approval.Level1Approver__c);
                approval.Level1Approver__c = Opp.Owner.Manager_Id__c;
           }
        }

        private void processAccountPartnerApprovals(List<Approval__c> approvals) {
            Map<Integer, String> levelToUserId = new Map<Integer, String>();

            for (Bill_On_Behalf_Approvers__c approver : Bill_On_Behalf_Approvers__c.getall().values()) {
                levelToUserId.put(Integer.valueOf(approver.Approver_Level__c), approver.User_Id__c);
            }

            for (Approval__c approval : approvals) {

                if (levelToUserId.isEmpty()){
                    continue;
                }
                for (Integer level = 1; level <= levelToUserId.size(); level++) {
                    approval.put('Level' + level + 'Approver__c', levelToUserId.get(level));
                }

                approval.Status__c = APPROVAL_STATUS_REQUIRED;

                setAccountPartnerApprovalFlow(approval);
            }
        }

        private void setAccountPartnerApprovalFlow(Approval__c approval) {
            if (approval.Partner_MRR__c < 500) {
                approval.InvoiceApprovalType__c = MRRLESS500;
            } else if (approval.Partner_MRR__c < 10000) {
                approval.InvoiceApprovalType__c = MRRMORE500LESS10K;
            } else if (approval.Partner_MRR__c < 150000) {
                approval.InvoiceApprovalType__c = MRRMORE10KLESS150K;
            } else if (approval.Partner_MRR__c < 750000) {
                approval.InvoiceApprovalType__c = MRRMORE150KLESS750K;
            } else {
                approval.InvoiceApprovalType__c = MRRMORE750K;
            }
        }

        private List<Approval__c> filterInvoicingRequestApprovals(List<Approval__c> rawApprovalsList, Map<Id,Schema.RecordTypeInfo> rtMapById) {

            List<Approval__c> filteredApprovalsList = new List<Approval__c>();

            if(rawApprovalsList == null || rtMapById == null) {
                return filteredApprovalsList;
            }

            for(Approval__c item : rawApprovalsList) {

                if(ApprovalHelper.isApprovalOfInvoicingType(item)) {
                    populateL1Approvers(item);
                    if(Trigger.isUpdate) {
                        Approval__c apprOld = (Approval__c)Trigger.oldMap.get(item.Id);

                        Boolean monthlyCreditChanged = item.Monthly_Credit_Limit__c != apprOld.Monthly_Credit_Limit__c;
                        Boolean signUpPurchaseLimitChanged = item.Sign_Up_Purchase_Limit__c != apprOld.Sign_Up_Purchase_Limit__c;

                        Boolean ownerChanged = item.OwnerId != apprOld.OwnerId;

						if(!monthlyCreditChanged && !ownerChanged && !signUpPurchaseLimitChanged) {
							continue;
						}
					}
					filteredApprovalsList.add(item);
				}
			}
			return filteredApprovalsList;
		}

        private void processInvoicingRequestApprovals(List<Approval__c> approvals) {

            Map<String, List<QuoteApprovals.Range>> currencyToInvoiceGOAListMap = new Map<String, List<QuoteApprovals.Range>>();

            for(Invoice_GOA__c item : Invoice_GOA__c.getAll().values()) {

                List<QuoteApprovals.Range> rangeList = new List<QuoteApprovals.Range>();

                if(item.Sales_Rep__c != null) {
                    QuoteApprovals.Range salesRepSettings = new QuoteApprovals.Range(item.Sales_Rep__c, '-', UserHelper.SALES_REP_ROLE);
                    rangeList.add(salesRepSettings);
                }

                if(item.Direct_Manager__c != null) {
                    QuoteApprovals.Range directMangerSettings = new QuoteApprovals.Range(item.Direct_Manager__c, '-', UserHelper.DIRECT_MANAGER_ROLE);
                    rangeList.add(directMangerSettings);
                }

                if(item.Segment_Leader__c != null) {
                    QuoteApprovals.Range segmentLeaderSettings = new QuoteApprovals.Range(item.Segment_Leader__c, '-', UserHelper.SEGMENT_LEADER_ROLE);
                    rangeList.add(segmentLeaderSettings);
                }

                if(item.SVP_WWS_Directs__c != null) {
                    QuoteApprovals.Range svpWwsDirectsSettings = new QuoteApprovals.Range(item.SVP_WWS_Directs__c, '-', UserHelper.SVP_WWS_DIRECTS_ROLE);
                    rangeList.add(svpWwsDirectsSettings);
                }

                if(item.SVP_WWS__c != null) {
                    QuoteApprovals.Range svpWwsSettings = new QuoteApprovals.Range(item.SVP_WWS__c, '-', UserHelper.SVP_WWS_ROLE);
                    rangeList.add(svpWwsSettings);
                }

                if(currencyToInvoiceGOAListMap.get(item.Currency__c) == null) {
                    currencyToInvoiceGOAListMap.put(item.Currency__c, rangeList);
                }
            }

            for(Approval__c item : approvals) {

                // use approval creator user as startedSearch user instead of current user
                User currentUser = ApproversSearch.findUserById(item.OwnerId);

                String currentUserHRole = currentUser.Hierarchy_Role__c;

                Boolean isSuitableRole = ApproversSearch.isSuitableHierarchyRole(currentUserHRole);

                Boolean isMoveToInvoiceAndSetStatusApproved = false;
                Boolean isGoToTheFinalStep = false;

                if (!accountIdToLastApprovedApprovalFromAccount.isEmpty()) {
                    isGoToTheFinalStep = ApprovalHelper.isInvoiceApprovalRequestValidForFinalStep(
                        item,
                        accountIdToLastApprovedApprovalFromAccount.get(item.Account__c),
                        customerToPartnerAccounts.get(item.Account__c)
                    );

                    Boolean isLastApprovedBOB =
                        accountIdToLastApprovedApprovalFromAccount.get(item.Account__c).get('RecordTypeId')
                            == ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST;

                    Boolean isLastApprovedAnyInvoicingType = accountIdToLastApprovedApprovalFromAccount.get(item.Account__c).get('RecordTypeId')
                            == ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST
                        || accountIdToLastApprovedApprovalFromAccount.get(item.Account__c).get('RecordTypeId')
                            == ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
                        || accountIdToLastApprovedApprovalFromAccount.get(item.Account__c).get('RecordTypeId')
                            == ApprovalHelper.RT_ID_INVOICING_REQUEST;

                    Boolean isMoveToInvoice = ApprovalHelper.isInvoicingRequestApproval(item) && isLastApprovedBOB;

                    Boolean isMoveToWholesale = ApprovalHelper.isInvoiceWholesaleRequestApproval(item) && isLastApprovedAnyInvoicingType;

                	Boolean isChangedAccPayContact = item.AccountPayableContact__c
                        != accountIdToLastApprovedApprovalFromAccount.get(item.Account__c)?.get('AccountPayableContact__c');

                    isMoveToInvoiceAndSetStatusApproved = isGoToTheFinalStep && (isMoveToInvoice || isMoveToWholesale)  && !isChangedAccPayContact;
                }

                if(currentUserHRole == null || !isSuitableRole) {
                    currentUserHRole = UserHelper.SALES_REP_ROLE;
                }

                List<QuoteApprovals.Range> rangeList = currencyToInvoiceGOAListMap.get(item.CurrencyIsoCode);

                if(rangeList == null || rangeList.isEmpty()) {
                    continue;
                }

                for(QuoteApprovals.Range currentRange : rangeList) {

                    Boolean monthlyCreditLimitInRange = currentRange.isInRange(item.Monthly_Credit_Limit__c);

                    if(monthlyCreditLimitInRange) {
                        // determine Status__c
                        Boolean setStatusToApproved = (UserHelper.hierarchyRolesNameToOrderMap.get(currentRange.rangeName) == UserHelper.hierarchyRolesNameToOrderMap.get(currentUserHRole)) ||
                            UserHelper.hierarchyRolesNameToOrderMap.get(currentUserHRole) > UserHelper.hierarchyRolesNameToOrderMap.get(currentRange.rangeName);

                        // for auto-approved records set 'Required' status - so user can submit for approval in any time (B-3815)
                        if(setStatusToApproved && isGoToTheFinalStep) {

                            item.Status__c = APPROVAL_STATUS_APPROVED;
                        } else {

                            item.Status__c = APPROVAL_STATUS_REQUIRED;

                            ApproversSearch approversSearcher = new ApproversSearch();

                            List<Id> approversIdList = approversSearcher.findApproverIdsByHierarchyRoles(new List<String>{ currentRange.rangeName }, currentUser);

                            item = fillApproverLvls(approversIdList, item, null);
                        }
                    }
                }
                if (isMoveToInvoiceAndSetStatusApproved) {
                    item.Status__c = APPROVAL_STATUS_APPROVED;
                }
            }
        }


        private List<Approval__c> filterDirectDebitApprovals(List<Approval__c> rawApprovalsList) {

            List<Approval__c> filteredApprovalsList = new List<Approval__c>();

            if (rawApprovalsList == null || rawApprovalsList.isEmpty()) {
                return filteredApprovalsList;
            }

            for (Approval__c item : rawApprovalsList) {

                if (item.RecordTypeId == ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST) {

                    if (Trigger.isUpdate) {

                        Approval__c apprOld = (Approval__c)Trigger.oldMap.get(item.Id);

                        Boolean monthlyCreditChanged = item.Monthly_Credit_Limit__c != apprOld.Monthly_Credit_Limit__c;
                        Boolean signUpPurchaseLimitChanged = item.Sign_Up_Purchase_Limit__c != apprOld.Sign_Up_Purchase_Limit__c;

                        Boolean ownerChanged = item.OwnerId != apprOld.OwnerId;

                        if(!monthlyCreditChanged && !ownerChanged && !signUpPurchaseLimitChanged) {
                            continue;
                        }
                    }

                    filteredApprovalsList.add(item);
                }
            }

            return filteredApprovalsList;
        }

        private void processDirectDebitApprovals(List<Approval__c> approvals) {

            Map<String, List<QuoteApprovals.Range>> currencyToGOAListMap = new Map<String, List<QuoteApprovals.Range>>();

            for(DirectDebitGOA__c item : DirectDebitGOA__c.getAll().values()) {

                List<QuoteApprovals.Range> rangeList = new List<QuoteApprovals.Range>();

                if(item.SalesRep__c != null) {
                    QuoteApprovals.Range salesRepSettings = new QuoteApprovals.Range(item.SalesRep__c, '-', UserHelper.SALES_REP_ROLE);
                    rangeList.add(salesRepSettings);
                }

                if(item.DirectManager__c != null) {
                    QuoteApprovals.Range directMangerSettings = new QuoteApprovals.Range(item.DirectManager__c, '-', UserHelper.DIRECT_MANAGER_ROLE);
                    rangeList.add(directMangerSettings);
                }

                if(item.SegmentLeader__c != null) {
                    QuoteApprovals.Range segmentLeaderSettings = new QuoteApprovals.Range(item.SegmentLeader__c, '-', UserHelper.SEGMENT_LEADER_ROLE);
                    rangeList.add(segmentLeaderSettings);
                }

                if(item.SVPWWSDirects__c != null) {
                    QuoteApprovals.Range svpWwsDirectsSettings = new QuoteApprovals.Range(item.SVPWWSDirects__c, '-', UserHelper.SVP_WWS_DIRECTS_ROLE);
                    rangeList.add(svpWwsDirectsSettings);
                }

                if(item.SVPWWS__c != null) {
                    QuoteApprovals.Range svpWwsSettings = new QuoteApprovals.Range(item.SVPWWS__c, '-', UserHelper.SVP_WWS_ROLE);
                    rangeList.add(svpWwsSettings);
                }

                if(currencyToGOAListMap.get(item.Currency__c) == null) {
                    currencyToGOAListMap.put(item.Currency__c, rangeList);
                }
            }

            for(Approval__c item : approvals) {

                // use approval creator user as startedSearch user instead of current user
                User currentUser = ApproversSearch.findUserById(item.OwnerId);

                String currentUserHRole = currentUser.Hierarchy_Role__c;

                Boolean isSuitableRole = ApproversSearch.isSuitableHierarchyRole(currentUserHRole);

                if (currentUserHRole == null || !isSuitableRole) {
                    currentUserHRole = UserHelper.SALES_REP_ROLE;
                }

                List<QuoteApprovals.Range> rangeList = currencyToGOAListMap.get(item.CurrencyIsoCode);

                if (rangeList == null || rangeList.isEmpty()) {
                    continue;
                }

                for (QuoteApprovals.Range currentRange : rangeList) {

                    Boolean monthlyCreditLimitInRange = currentRange.isInRange(item.Monthly_Credit_Limit__c);

                    if (monthlyCreditLimitInRange) {

                        Boolean isApproverLevelsUpdateNeeded = UserHelper.hierarchyRolesNameToOrderMap.get(currentUserHRole) < UserHelper.hierarchyRolesNameToOrderMap.get(currentRange.rangeName);

                        item.Status__c = APPROVAL_STATUS_REQUIRED;

                        if(isApproverLevelsUpdateNeeded) {
                            List<Id> approversIdList = new ApproversSearch()
                                .findApproverIdsByHierarchyRoles(new List<String>{ currentRange.rangeName }, currentUser);
                            item = fillApproverLvls(approversIdList, item, null);
                        }
                    }
                }
            }
        }
    }

    public class PopulateApprovalHistory extends Triggers.TriggerHandlerBase {
        override public void handle() {

            Set<Id> approvalIdSet = new Set<Id>();

            for(Approval__c approval : (List<Approval__c>)Trigger.new) {
                if(CoreObjectBase.isFieldChanged(approval, Approval__c.Status__c)) {
                    approvalIdSet.add(approval.Id);
                }
            }

            if(approvalIdSet.size() > 0) {

                Map<Id, String> quoteApprovalHistoryTable = genApprovalHistoryTable(approvalIdSet);

                for(Approval__c approval : (List<Approval__c>)Trigger.new) {

                    if(quoteApprovalHistoryTable.containsKey(approval.Id)) {
                        approval.Approval_History__c = quoteApprovalHistoryTable.get(approval.Id);
                    }
                }
            }
        }

        private Map<Id, String> genApprovalHistoryTable(Set<Id> approvalIdSet) {
            return QuoteTriggerHelper.generateApprovalHistoryTable(new List<Id>(approvalIdSet));
        }
    }

    // Logic moved fomr Approval_After.trigger
    public class ApprovalAfter extends Triggers.TriggerHandlerBase {
        override public void handle(){
            System.Debug('>>TriggerHandler.BY_PASS_Approver_Trigger>>>'+TriggerHandler.BY_PASS_Approver_Trigger);
            if(TriggerHandler.BY_PASS_Approver_Trigger == true) {
                return;
            }
            try {

                List<Approval__c> approvalListTOUpdWithOwner = new List<Approval__c>();
                set<Id> accountIdSet = new set<Id>();
                for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                    if(appr.Account__c != null) {
                        accountIdSet.add(appr.Account__c);
                    }
                }
                // Direct to Var
                /********************************************************/
                if(Trigger.isUpdate){
                    ApprovalHelperCls.doDMLOpertnInAfterTgr();
                    ApprovalHelperCls.chnageOpportunityRecordType(Trigger.new,'isUpdate');
                    // Case  04458955 - Automate Agent Credit Split  - START
                    ApprovalHelperCls.AgentCreditSplit((Map<Id, Approval__c>)trigger.newMap, (Map<Id, Approval__c>)trigger.oldMap);
                    // Case  04458955 - Automate Agent Credit Split  - END
                }
                if(Trigger.isInsert){
                    ApprovalHelperCls.chnageOpportunityRecordType((List<Approval__c>)Trigger.new,'isInsert');
                    ApprovalHelperCls.createTechnicalApprovals((List<Approval__c>)Trigger.new);
                    ApprovalHelperCls.populateAccountLimitFieldOnApproval((List<Approval__c>)Trigger.new);
                    ApprovalHelperCls.populateInvoiceTerms((List<Approval__c>)Trigger.new);
                    /*******************************************************/
                }

                Schema.DescribeSObjectResult result1 = Case.SObjectType.getDescribe();
                Map<string,Schema.RecordTypeInfo> rtMapByName1 = result1.getRecordTypeInfosByName();

                Schema.DescribeSObjectResult result = Approval__c.SObjectType.getDescribe();
                Map<Id,Schema.RecordTypeInfo> rtMapByName = result.getRecordTypeInfosById();

                Map<Id,Account> accountCurrentOwnerMap = new map<Id,Account>();
                Map<Id, Package__c> packageMap = new Map<Id, Package__c>();
                if (!accountIdSet.isEmpty()) {
                    accountCurrentOwnerMap = new map<Id,Account>([select Name,Number_of_POC_Users__c,Current_Owner__c,Current_Owner__r.Name, Current_Owner__r.ManagerId
                    from Account where Id IN :accountIdSet]);
                    List<Package__c> packages = new PackageSelector()
                        .selectPackagesForNewReferences(new List<Object> {accountIdSet})
                        .setQueryCaching(true)
                        .executeQuery();
                    packageMap = PackageHelper.filterPackagesByService(packages, QuoteHelper.NGBS_OFFICE_PRODUCT);
                }

                List<Account> accountToUpdateList = new List<Account>();
                List<Package__c> packageToUpdateList = new List<Package__c>();
                Id SupportRefundQueue = GroupHelper.groupDeveloperNameToGroup.get(GroupHelper.GROUP_SUPPORT_REFUND_APPROVAL_QUEUE).Id;

                List<Case> caseObjectsToInsert = new List<Case>();
                List<Approval__c> approvalListTOUpd2 = new List<Approval__c>();
                for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                    // Case NUMBER : 02989446 // APPROVAL POC ACCOUNT // Deployed 7th October,2014
                    Boolean copyNumberOfPOCToPackage = appr.RecordTypeId != null &&
                        rtMapByName.get(appr.RecordTypeId).getName() == POC_ACCOUNT_APPROVAL_RT_NAME &&
                        appr.Status__c == APPROVAL_STATUS_APPROVED &&
                        packageMap != null &&
                        packageMap.get(appr.Account__c) != null &&
                        appr.Number_of_POC_Users__c != null;

                    if( (Trigger.isUpdate || Trigger.isInsert) && copyNumberOfPOCToPackage ) {
                        Package__c pkg = packageMap.get(appr.Account__c);
                        pkg.Number_of_POC_Users__c = appr.Number_of_POC_Users__c;
                        packageToUpdateList.add(pkg);
                    }

                    //B-573 Mark Account as Tax Exempt when Tax Exempt Approval was Approved
                    if (Trigger.isUpdate && appr.RecordTypeId != null &&
                        rtMapByName.get(appr.RecordTypeId).getName() == 'Tax Exempt Approval' &&
                        appr.Status__c=='Approved' && accountCurrentOwnerMap != NULL &&
                        accountCurrentOwnerMap.get(appr.Account__c) != NULL) {
                        Account acnt = accountCurrentOwnerMap.get(appr.Account__c);
                        acnt.Tax_Exempt__c = true;
                        accountToUpdateList.add(acnt);
                    }
                    if(Trigger.isUpdate && appr.RecordTypeId != null && rtMapByName.get(appr.RecordTypeId).getName() == 'Manual Refunds' &&
                        rtMapByName.get(((Approval__c)Trigger.oldMap.get(appr.Id)).RecordTypeId).getName() == 'Refund Approval' && appr.Account__c != null &&
                        accountCurrentOwnerMap != null) {
                        approvalListTOUpd2.add(new Approval__c(id = appr.id));
                        Case caseObj = new Case();
                        caseObj.AccountId = appr.Account__c;
                        caseObj.subject = 'Refund Approval Transfer from Sales for ' + accountCurrentOwnerMap.get(appr.Account__c).Name;
                        caseObj.Description  = appr.JustificationandDescription__c;
                        caseObj.Origin = 'Walk In';
                        caseObj.OwnerId = SupportRefundQueue;
                        caseObj.RecordTypeId = rtMapByName1.get('Support Refund Approval').getRecordTypeId(); //'012S00000004dNG';
                        caseObjectsToInsert.add(caseObj);
                    }
                }
                insert caseObjectsToInsert;

                for(Integer i = 0; i < approvalListTOUpd2.size(); i++) {
                    if(caseObjectsToInsert.get(i).id != null) {
                            approvalListTOUpd2.get(i).Case__c = caseObjectsToInsert.get(i).id;
                    }
                    approvalListTOUpdWithOwner.add(approvalListTOUpd2.get(i));
                }

                update approvalListTOUpdWithOwner;

                if(accountToUpdateList.size() > 0 ){
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
                    update accountToUpdateList;
                    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
                }

                if(!packageToUpdateList.isEmpty()) {
                    Triggers.switchOff();
                    update packageToUpdateList;
                    Triggers.switchOn();
                }

                Set<Id> ownersAndCreatorsOfApprovals = new Set<Id>();
                for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                    ownersAndCreatorsOfApprovals.add(appr.createdById);
                    if(appr.OwnerId != null) {
                        ownersAndCreatorsOfApprovals.add(appr.OwnerId);
                    }
                }

                Map<Id,user> allUserManagerMap = UserHelper.getORQueryUsers(ownersAndCreatorsOfApprovals);

                Map<Id,Map<string,Id>> mapPossibleAppToManagerId  = new Map<Id,Map<string,Id>>();
                for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                    if(appr.Possible_Approval_From__c != null) {
                        System.Debug('>>1>>');
                        Map<string,Id> possibleValueToManagerIdMap = new Map<string,Id>();
                        if(appr.Possible_Approval_From__c == 'Owner' && appr.OwnerId != null) {
                            System.Debug('>>1>>');
                            possibleValueToManagerIdMap.put(appr.Possible_Approval_From__c,appr.OwnerId);
                        } else if(appr.Possible_Approval_From__c == 'Record Submitter') {
                            System.Debug('>>2>>');
                            possibleValueToManagerIdMap.put(appr.Possible_Approval_From__c,appr.createdById);
                        } else if(appr.Possible_Approval_From__c == 'Refund Owner' && appr.Refund_Owner__c != null) {
                            System.Debug('>>3>>');
                            possibleValueToManagerIdMap.put(appr.Possible_Approval_From__c,appr.Refund_Owner__c);
                        }
                        mapPossibleAppToManagerId.put(appr.id,possibleValueToManagerIdMap);
                    }
                }

                system.Debug('>>>>44>>>'+ mapPossibleAppToManagerId);

                List<Approval__c> approvalListToUpd = new List<Approval__c>();
                for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                    if((appr.Possible_Approval_From__c != '' && appr.Possible_Approval_From__c != null) && (Trigger.isInsert || (trigger.isUpdate
                        && (((Approval__c)Trigger.oldMap.get(appr.id)).Possible_Approval_From__c != appr.Possible_Approval_From__c ||
                            ((Approval__c)Trigger.oldMap.get(appr.id)).OwnerId != appr.OwnerId ||
                            ((Approval__c)Trigger.oldMap.get(appr.id)).Refund_Owner__c != appr.Refund_Owner__c)))) {
                        if(mapPossibleAppToManagerId != null && mapPossibleAppToManagerId.get(appr.id) != null &&
                            mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c) != null &&
                            allUserManagerMap != null && allUserManagerMap.get(mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c)) != null) {
                            Approval__c appObjtoUpd =  new Approval__c(Id = appr.Id);
                            if (appr.RecordTypeId != null &&
                                !ApprovalHelper.isApprovalOfInvoicingType(appr) &&
                                rtMapByName.get(appr.recordtypeId).getName() != POC_ACCOUNT_APPROVAL_RT_NAME &&
                                rtMapByName.get(appr.recordtypeId).getName() != ApprovalHelper.RT_NAME_DIRECT_DEBIT_REQUEST &&
                                rtMapByName.get(appr.recordtypeId).getName() != ApprovalHelper.RT_NAME_BOB_APPROVAL &&
                                rtMapByName.get(appr.recordtypeId).getName() != 'Feature Add-Ons' &&
                                !ApprovalHelper.RT_SKIP_APPROVAL_LEVELS_CALC.contains(ApprovalHelperCls.rtMapByName.get(appr.recordtypeId).getName())) {
                                    if (ApprovalHelperCls.checkForShippingProcessing(appr, allUserManagerMap) && RingCentralVariousSettings__c.getInstance().Shipping_Level1Approver__c != null) {
                                        appObjtoUpd.Level2Approver__c = allUserManagerMap.get(mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c)).ManagerId;
                                    } else {
                                      appObjtoUpd.Level1Approver__c = allUserManagerMap.get(mapPossibleAppToManagerId.get(appr.id).get(appr.Possible_Approval_From__c)).ManagerId;
                                    }
                            }
                            approvalListToUpd.add(appObjtoUpd);
                        }
                    }
                }
                if(approvalListToUpd != null && approvalListToUpd.size()>0) {
                    update  approvalListToUpd;
                }

                /************************ Code for Reject Bill on Behalf Approval Processes when MMR was changed  ********************/
                if(Trigger.isUpdate) {
                    Set<Id> approvalsToRejectAppProcess = new Set<Id>();

                    for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                        if(rtMapByName.get(appr.recordtypeId).getName() == ApprovalHelper.RT_NAME_BOB_APPROVAL) {
                            Approval__c apprOld = (Approval__c)Trigger.oldMap.get(appr.Id);
                            if (appr.Partner_MRR__c != apprOld.Partner_MRR__c) {
                                approvalsToRejectAppProcess.add(appr.Id);
                            }
                        }
                    }

                    if(approvalsToRejectAppProcess.size() > 0) {
                        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ProcessInstanceId
                                                        FROM ProcessInstanceWorkitem
                                                        WHERE ProcessInstance.TargetObjectId IN :approvalsToRejectAppProcess];
                        if (!workItems.isEmpty()) {
                            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

                            for(ProcessInstanceWorkitem workItem : workItems){
                                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                req.setWorkitemId(workItem.Id);
                                //Valid values are: Approve, Reject, or Removed.
                                //Only system administrators can specify Removed.
                                req.setAction('Reject');
                                req.setComments('Rejected by changing Partner MRR');
                                requests.add(req);
                            }
                            Approval.ProcessResult[] processResults = Approval.process(requests);
                        }
                    }
                }
			} catch(Exception ex) {
				System.debug(loggingLevel.Error, 'ex.getMessage() >>> ' + ex.getMessage());
				System.debug(loggingLevel.Error, 'ex.GetStacktraceString() >>> ' + ex.GetStacktraceString());
			}

            if(Trigger.isInsert) {
                Map<Id, Id> oppToApprovalIds = new Map<Id, Id>();
                for(Approval__c appr : (List<Approval__c>)Trigger.new) {
                    if (appr.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
                    && appr.Opportunity__c != null) {
                        oppToApprovalIds.put(appr.Opportunity__c, appr.Id);
                    }
                }

                if (!oppToApprovalIds.isEmpty()) {
                    List<PartnerOperationsLog__c> existingPartnerOperationsLogs =
                        (List<PartnerOperationsLog__c>)new QueryFactory(PartnerOperationsLog__c.SObjectType)
                        .selectFields(new List<String> {'Opportunity__c'})
                        .setCondition('Opportunity__c IN :bind0 AND isCompleted__c = false AND isRejected__c = false')
                        .setQueryBindings(new List<Object>{oppToApprovalIds.keySet()})
                        .executeQuery();

                    for(PartnerOperationsLog__c log : existingPartnerOperationsLogs) {
                        log.Approval__c = oppToApprovalIds.get(log.Opportunity__c);
                    }

                    update existingPartnerOperationsLogs;
                }
            }

            if(Trigger.isUpdate) {
                try {
                    List<Approval.ProcessWorkitemRequest> listApprvProcess;
                    map<Id,Approval__c> approvalMap = new map<Id,Approval__c>([Select id,name,createdDate,
                        (Select Id, TargetObjectId,targetObject.type From ProcessInstances where Status = 'Pending')
                        From Approval__c where RecordType.Name = 'Agent Credit Transfers' and status__c = 'Rejected'
                        and ID IN : Trigger.newMap.keyset() and IsAutoRejected__c = true order by createdDate desc]);
                    Set<Id> setInstanceId = new set<ID>();
                    for(Approval__c approvalObj : (List<Approval__c>)Trigger.New) {
                        Approval__c approvalNewObj = (Approval__c)Trigger.newMap.get(approvalObj.Id);
                        Approval__c approvalOldObj = (Approval__c)Trigger.oldMap.get(approvalObj.Id);
                        if(approvalOldObj.Status__c == 'PendingL1Approval' && approvalNewObj.Status__c == 'Rejected'
                            && approvalNewObj.IsAutoRejected__c == true) {
                            if(approvalMap != null && approvalMap.get(approvalObj.Id) != null && approvalMap.get(approvalObj.Id).ProcessInstances != null) {
                                for(ProcessInstance processObj : approvalMap.get(approvalObj.Id).ProcessInstances) {
                                    setInstanceId.add(processObj.Id);
                                }
                            }
                        }
                    }
                    if(setInstanceId != null && setInstanceId.size()>0) {
                        List<ProcessInstanceWorkitem> listworkItem = [Select ProcessInstanceId, Id From ProcessInstanceWorkitem
                        where ProcessInstanceId IN :setInstanceId];
                        if(listworkItem != null && listworkItem.size()>0) {
                            listApprvProcess = new List<Approval.ProcessWorkitemRequest>();
                            for(ProcessInstanceWorkitem workItemObj : listworkItem) {
                                System.Debug('>>>222>>'+UserInfo.getUserId());
                                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                req.setComments('Auto Reject.');
                                req.setAction('Reject');
                                req.setWorkitemId(workItemObj.Id);
                                listApprvProcess.add(req);
                            }
                        }
                    }

                    if(listApprvProcess != null && listApprvProcess.size()>0) {
                        List<Approval.ProcessResult> result =  Approval.process(listApprvProcess);
                    }
                } catch(Exception ex) {
                    System.debug(loggingLevel.Error, 'ex.getMessage() >>> ' + ex.getMessage());
                    System.debug(loggingLevel.Error, 'ex.getStacktraceString() >>> ' + ex.getStacktraceString());
                }

                try {
                    QueueableBase.enqueJob(APPROVAL_QUEUEABLE_JOB, Trigger.New);
                } catch(Exception ex) {
                    System.debug(loggingLevel.Error, 'ex.getMessage() >>> ' + ex.getMessage());
                    System.debug(loggingLevel.Error, 'ex.getStacktraceString() >>> ' + ex.getStacktraceString());
                }
            }
        }
    }
    //Not a formula field, because of error "You have reached the maximum number of 20 object references on Approval"
    public class AssignRefundOwnerManager extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> approvals = (List<Approval__c>)Trigger.new;
            Set<Id> refundOwnerIdsToQuery = getRefundOwnerIdsToQuery(approvals);
            Map<Id, User> refundOwnersWithManagers =
                    UserHelper.getORQueryUsers(refundOwnerIdsToQuery);

            for (Approval__c appr : approvals) {
                Boolean isUserQueriedAndManagerExists =
                        (refundOwnersWithManagers.get(appr.Refund_Owner__c) != null
                                && refundOwnersWithManagers.get(appr.Refund_Owner__c).ManagerId != null) ? true : false;
                if (isUserQueriedAndManagerExists) {
                    appr.Refund_Owner_Manager__c = refundOwnersWithManagers.get(appr.Refund_Owner__c).ManagerId;
                }
            }
        }

        private Set<Id> getRefundOwnerIdsToQuery(List<Approval__c> approvals) {
            Set<Id> userIdsToQuery = new Set<Id>();
            for (Approval__c appr : approvals) {
                if (appr.Refund_Owner__c != null){
                    userIdsToQuery.add(appr.Refund_Owner__c);
                }
            }
            return userIdsToQuery;
        }
    }

    public class CheckSecondaryDLUniqueness extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> approvals = (List<Approval__c>) Trigger.new;
            List<String> accountIds = new List<String>();
            List<String> approvalsIds = new List<String>();
            for (Approval__c appr : approvals) {
                if (appr.RecordTypeId == ApprovalHelper.RT_ID_SECONDARY_DL) {
                    accountIds.add(appr.Account__c);
                    if (appr.Id != null) {
                        approvalsIds.add(appr.Id);
                    }
                }
            }

            if (accountIds.size() > 0) {
                List<Approval__c> existingApprovals = (List<Approval__c>) new ApprovalSelector()
                    .selectSecondaryDLApprovalsForAccounts(accountIds, approvalsIds)
                    .setLimit(1)
                    .executeQuery();

                if (!existingApprovals.isEmpty()) {
                    for (Approval__c appr : approvals) {
                        if (appr.RecordTypeId == ApprovalHelper.RT_ID_SECONDARY_DL) {
                            appr.addError(ApprovalHelper.SECONDARY_DL_APPROVAL_UNIQUENESS_ERROR);
                        }
                    }
                }
            }

        }
    }

    public class PopulateContractFromAccount extends Triggers.TriggerHandlerBase {
        public PopulateContractFromAccount() {
            super();
        }

        public PopulateContractFromAccount(TriggerOperation operationType, List<Approval__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            List<Approval__c> approvals = (List<Approval__c>) this.triggerRecords;
            Set<Id> accountsIds = new Set<Id>();
            for(Approval__c appr: approvals) {
                accountsIds.add(appr.Account__c);
            }
            List<Contract> contracts = new List<Contract>();
            if (!accountsIds.isEmpty()) {
                contracts = [SELECT Id, Status, AccountId, Source__c, LastModifiedDate
                FROM Contract
                WHERE AccountId IN :accountsIdS AND Status = 'Active'
                ORDER BY LastModifiedDate ASC];
            }

            List<Contract> automationContracts = new List<Contract>();
            List<Contract> sumatiContracts = new List<Contract>();
            List<Contract> accountReviewContracts = new List<Contract>();
            List<Contract> auditContracts = new List<Contract>();
            List<Contract> otherContracts = new List<Contract>();

            for(Contract contr: contracts) {
                if(contr.Source__c != null) {
                    if (contr.Source__c.equals('Automation')) {
                        automationContracts.add(contr);
                    } else if (contr.Source__c.equals('Sumati')) {
                        sumatiContracts.add(contr);
                    } else if (contr.Source__c.equals('Account Review')) {
                        accountReviewContracts.add(contr);
                    } else if (contr.Source__c.equals('606 Audit')) {
                        auditContracts.add(contr);
                    }
                } else {
                    otherContracts.add(contr);
                }
            }

            for(Approval__c approval: approvals) {
                if(!automationContracts.isEmpty()) {
                    for(Contract contract: automationContracts) {
                        if(approval.Account__c == contract.AccountId) {
                            approval.Contracts__c = contract.Id;
                        }
                    }
                } else if(!sumatiContracts.isEmpty()) {
                    for(Contract contract: sumatiContracts) {
                        if(approval.Account__c == contract.AccountId) {
                            approval.Contracts__c = contract.Id;
                        }
                    }
                } else if(!accountReviewContracts.isEmpty()) {
                    for(Contract contract: accountReviewContracts) {
                        if(approval.Account__c == contract.AccountId) {
                            approval.Contracts__c = contract.Id;
                        }
                    }
                } else if(!auditContracts.isEmpty()) {
                    for(Contract contract: auditContracts) {
                        if(approval.Account__c == contract.AccountId) {
                            approval.Contracts__c = contract.Id;
                        }
                    }
                } else if(!otherContracts.isEmpty()) {
                    for(Contract contract: otherContracts) {
                        if(approval.Account__c == contract.AccountId) {
                            approval.Contracts__c = contract.Id;
                        }
                    }
                }
            }
        }
    }

    public class PopulateDLsFromQLI extends Triggers.TriggerHandlerBase {

        override public void handle() {

            List<Approval__c> approvals = Trigger.new;
            List<Id> quoteIds = new List<Id>();
            List<Id> oppIds = new List<Id>();
            List<Id> accIds = new List<Id>();
            for (Approval__c approval: approvals) {
                quoteIds.add(approval.Quote__c);
                oppIds.add(approval.Opportunity__c);
                accIds.add(approval.Account__c);
            }

            List<Account> accounts = [SELECT Id, Number_of_DL_s__c
                                      FROM Account
                                      WHERE Id IN :accIds];

            List<Quote> quotes = [SELECT Id
                                  FROM Quote
                                  WHERE Id IN :quoteIds AND isPrimary__c = true AND RecordType.Name = 'Sales Quote'
                                  AND OpportunityId IN :oppIds];
            List<Id> fitQuoteIds = new List<Id>();
            for (Quote quote: quotes) {
                fitQuoteIds.add(quote.Id);
            }

            List<QuoteLineItem> quoteLineItems = [SELECT Id, NewQuantity__c, Quantity, Product2Id, QuoteId, EffectivePrice__c
                                                  FROM QuoteLineItem
                                                  WHERE QuoteId IN :fitQuoteIds];
            List<Id> productIds = new List<Id>();
            for(QuoteLineItem quoteLineItem: quoteLineItems) {
                productIds.add(quoteLineItem.Product2Id);
            }

            List<Product2> products = [SELECT Id, Charge_Term__c
                                       FROM Product2
                                       WHERE Id IN :productIds AND Family = 'Service'];

            for (Approval__c appr: approvals) {
                for (QuoteLineItem qli: quoteLineItems) {
                    if(qli.QuoteId == appr.Quote__c) {
                        for(Product2 product: products) {
                            if(qli.Product2Id == product.Id) {
                                for (Account acc: accounts) {
                                    if ( appr.Account__c == acc.Id) {
                                        appr.Contracted_Montlhy_DL_Price__c = product.Charge_Term__c.toLowerCase().contains('annual') ?
                                        qli.EffectivePrice__c/12 : qli.EffectivePrice__c;
                                        appr.Current_number_of_DLs__c = qli.NewQuantity__c != null ? qli.NewQuantity__c : qli.Quantity + acc.Number_of_DL_s__c;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public without sharing class CheckAndRecallApproval extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> approvalIdSet = new Set<Id>();
            for (Approval__c approvalRecord: (List<Approval__c>) Trigger.new) {
                if (ApprovalHelper.isApprovalOfInvoicingType(approvalRecord)) {
                    if (Trigger.isUpdate && isChangedFieldTo(approvalRecord, Approval__c.Status__c, 'Required')) { 
                        approvalIdSet.add(approvalRecord.Id);
                    }
                }
            }
            
            if (!approvalIdSet.isEmpty()) {
                List<ProcessInstanceWorkitem> workItems = [ SELECT Id
                                                                FROM ProcessInstanceWorkitem
                                                                WHERE ProcessInstance.TargetObjectId IN :approvalIdSet
                                                                AND ProcessInstance.Status = 'Pending' ];
                if (!workItems.isEmpty()) { 
                    List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
                        for(ProcessInstanceWorkitem workItem : workItems) { 
                            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                            req.setComments('Initial values were changed on Approval record. Approval rejected. Please resubmit for the approval.');
                            req.setAction('Reject');
                            req.setWorkitemId(workItem.Id);
                            requests.add(req);
                        }
                    Approval.ProcessResult[] processResults = Approval.process(requests);
                }
            }
        }
    }

    public class PrepopulateFieldsFromAccount extends Triggers.TriggerHandlerBase {
        public PrepopulateFieldsFromAccount() {
            super();
        }

        public PrepopulateFieldsFromAccount(TriggerOperation operationType, List<Approval__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {
            for (Approval__c ap : (List<Approval__c>) this.triggerRecords) {
                if (ap.RecordTypeId != ApprovalHelperCls.RT_ID_REFUND_APPROVAL) {
                    continue;
                }

                Account ac = ApprovalHelperCls.accountStaticMap.get(ap.Account__c);
                if (ac == null) {
                    continue;
                }
                ap.Payment_Plan__c = ac.Payment_Plan__c;
                ap.Payment_Method__c = ac.Account_Payment_Method__c;
                ap.RC_Account_Status__c = ac.RC_Account_Status__c;
            }
        }
    }

    public class DNBInvoiceAndPartnerApprovalHandler extends Triggers.TriggerHandlerBase {
        List<D_B_Credit_Check__c> creditCheckList = new List<D_B_Credit_Check__c>();
        override public void handle() {

            if (Trigger.isInsert && Trigger.isAfter) {
                for (Approval__c app : (List<Approval__c>)Trigger.new) {
                    D_B_Credit_Check__c creditCheck = new D_B_Credit_Check__c();
                    if(ApprovalHelper.isApprovalOfInvoicingType(app)
                        || ApprovalHelper.isApprovalOfPartnerType(app)) {
                            creditCheck.Approval__c = app.Id;
                            creditCheckList.add(creditCheck);
                    }
                }
                insert creditCheckList;
            } else if (Trigger.isInsert && Trigger.isBefore) {
                for (Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (ApprovalHelper.isApprovalOfPartnerType(app)) {
                        app.Sign_Up_Purchase_Limit__c = app.Partner_MRR__c;
                    }
                }
            } else if (Trigger.isUpdate) {
                for (Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (ApprovalHelper.isApprovalOfPartnerType(app) && isChangedField(app, Approval__c.Partner_MRR__c)) {
                        app.Sign_Up_Purchase_Limit__c = app.Partner_MRR__c;
                    }
                }
            }
        }
    }

    public class ValidateApprovalTypeByProfile extends Triggers.TriggerHandlerBase {
        public ValidateApprovalTypeByProfile() {
            super();
        }

        public ValidateApprovalTypeByProfile(TriggerOperation operationType, List<Approval__c> newList) {
            super(true, operationType, newList);
        }

        override public void handle() {

            Set<String> checkedValues = new Set<String>{
                ApprovalHelper.RT_NAME_MANUAL_REFUNDS.toLowerCase(),
                ApprovalHelper.RT_NAME_REFUND_APPROVAL.toLowerCase()
            };

            List<Approval__c> approvalsToCheck = new List<Approval__c>();

            for(Approval__c a : (List<Approval__c>) this.triggerRecords) {
                if(a.Approval_Type__c == null) {
                    continue;
                }
                if(checkedValues.contains(a.Approval_Type__c.toLowerCase())) {
                    approvalsToCheck.add(a);
                }
            }

            if(approvalsToCheck.isEmpty()) {
                return;
            }

            Map<String, Set<String>> profileToApprTypesAvailable = new Map<String, Set<String>>();

            for(Approval_Type_Availability_For_Profiles__c val :
                Approval_Type_Availability_For_Profiles__c.getAll().values())
            {
                profileToApprTypesAvailable.put(
                    val.Profile_Name__c.toLowerCase(),
                    !String.isBlank(val.Available_Picklist_Values__c)
                        ? new Set<String>(val.Available_Picklist_Values__c.toLowerCase().split(';'))
                        : new Set<String>()
                );
            }

            String currentUserProfileId = UserInfo.getProfileId();
            String currentUserProfileName = [
                                                SELECT Name
                                                FROM Profile WHERE Id = :currentUserProfileId
                                            ].Name.toLowerCase();

            for(Approval__c a : approvalsToCheck) {
                if(
                    !profileToApprTypesAvailable.containsKey(currentUserProfileName) ||
                    !profileToApprTypesAvailable.get(currentUserProfileName).contains(a.Approval_Type__c.toLowerCase())
                ) {
                    a.Approval_Type__c.addError('You may not select this Approval Type.');
                }
            }
        }
    }

    public class PopulateRefundApprovalBU extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for(Approval__c a : (List<Approval__c>) Trigger.new) {
                if (!isChangedField(a, Approval__c.Approval_Type__c)) {
                    continue;
                }
                if(ApprovalHelper.RT_NAME_REFUND_APPROVAL.equalsIgnoreCase(a.Approval_Type__c)) {
                    a.Refund_Approval_BU__c = ApprovalHelper.BU_SALES;
                }
                if(ApprovalHelper.RT_NAME_MANUAL_REFUNDS.equalsIgnoreCase(a.Approval_Type__c)) {
                    a.Refund_Approval_BU__c = ApprovalHelper.BU_SUPPORT;
                }
            }
        }
    }

    public class ValidateTaxExemptApprovalStatus extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (TaxExemptionHelper.isEnabled) {
                for (Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (app.Status__c != ApprovalHelper.STATUS_NEW
                        && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                        && !app.IsMultiProductTechnicalApproval__c
                        && TaxExemptionHelper.isAutomaticApprovalMap.get(app.Opportunity__c) == null) {
                        app.addError(ApprovalHelper.TAX_EXEMPT_APPROVAL_STATUS_NOT_NEW_ERROR);
                    }
                }
            }
        }
    }

    public class SetTaxReestimationCheckboxOnRelatedQuotes extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (TaxExemptionHelper.isEnabled) {
                Set<Id> relatedAccountIds = new Set<Id>();

                for (Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                        && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
                        relatedAccountIds.add(app.Account__c);
                    }
                }

                if (!relatedAccountIds.isEmpty()) {
                    List<Quote> relatedQuotes = new QuoteSelector()
                        .selectOpenBillingQuotesForAccount(new List<Object> {relatedAccountIds})
                        .executeQuery();

                    for (Quote q : relatedQuotes) {
                        q.NeedTaxesReestimation__c = true;
                    }

                    update relatedQuotes;
                }
            }
        }
    }

    public class SetBlockedTaxExemptionApprovalStatusToRejected extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (!TaxExemptionHelper.isEnabled) {
                return;
            }

            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (!isAnyFieldForTaxExemptApprovalChanged(app)) {
                    continue;
                }
                if (isTaxExemptApprovalBlocked(app)) {
                    app.Status__c = ApprovalHelper.STATUS_REJECTED;
                }
            }
        }

        private Boolean isAnyFieldForTaxExemptApprovalChanged(Approval__c app) {
            return isChangedAnyField(app, new Set<SObjectField> {
                Approval__c.RecordTypeId,
                Approval__c.Status__c,
                Approval__c.FederalTaxExemption__c,
                Approval__c.StateTaxExemption__c,
                Approval__c.CountyTaxExemption__c,
                Approval__c.LocalTaxExemption__c,
                Approval__c.SEZWOPExemption__c,
                Approval__c.VATExemption__c,
                Approval__c.VATNumber__c,
                Approval__c.GstNo__c
            });
        }

        private Boolean isTaxExemptApprovalBlocked(Approval__c app) {
            return app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                && 	(oldValue(app, Approval__c.Status__c) == ApprovalHelper.STATUS_PENDING_APPROVAL
                    || oldValue(app, Approval__c.Status__c) == ApprovalHelper.STATUS_NEW)
                    && ((app.FederalTaxExemption__c == TaxExemptionHelper.CURRENT
                            && app.StateTaxExemption__c == TaxExemptionHelper.CURRENT
                            && app.CountyTaxExemption__c == TaxExemptionHelper.CURRENT
                            && app.LocalTaxExemption__c == TaxExemptionHelper.CURRENT) ||
                        (app.SEZWOPExemption__c == TaxExemptionHelper.CURRENT) ||
                        (app.VATExemption__c == TaxExemptionHelper.CURRENT
                                && app.VATNumber__c != null
                                && oldValue(app, Approval__c.VATNumber__c) != null
                                && app.VATNumber__c == oldValue(app, Approval__c.VATNumber__c)) ||
                    (app.SEZWOPExemption__c == TaxExemptionHelper.CURRENT
                            && app.GstNo__c != null
                            && oldValue(app, Approval__c.GstNo__c) != null
                            && app.GstNo__c == oldValue(app, Approval__c.GstNo__c)));
        }
    }

    public class CompleteTaxExemptApprovalOnFastApproveOrReject extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (!TaxExemptionHelper.isEnabled || TaxExemptionHelper.isFastApprovalExecuted || System.isFuture()) {
                return;
            }

            List<Id> approvalIds = new List<Id>();

            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (approvalShouldBeCompleted(app, Trigger.OperationType)) {
                    approvalIds.add(app.Id);
                }
            }

            if (!approvalIds.isEmpty()) {
                TaxExemptionHelper.completeApproval(approvalIds, false);
            }
        }

        @TestVisible
        private Boolean approvalShouldBeCompleted(Approval__c app, System.TriggerOperation operationType) {
            return (operationType == System.TriggerOperation.AFTER_UPDATE
                    && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && isChangedFieldFrom(app, Approval__c.Status__c, ApprovalHelper.STATUS_PENDING_APPROVAL)
                    && (isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                    || isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_REJECTED)))
                || (operationType == System.TriggerOperation.AFTER_INSERT
                    && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && app.Status__c == ApprovalHelper.STATUS_APPROVED
                );
        }
    }

    public class ValidateMassApproval extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (TaxExemptionHelper.isEnabled) {
                Set<Id> accountsWithMultipleTaxExemptApprovals = new Set<Id>();

                for(Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (accountsWithMultipleTaxExemptApprovals.contains(app.Account__c)
                        && app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
                        app.addError(ApprovalHelper.TAX_EXEMPT_MASS_APPROVAL_NOT_SUPPORTED);
                    } else if (taxExemptApprovalIsCompleting(app)) {
                        accountsWithMultipleTaxExemptApprovals.add(app.Account__c);
                    }
                }
            }
        }

        private Boolean taxExemptApprovalIsCompleting(Approval__c app) {
            return app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                && isChangedFieldFrom(app, Approval__c.Status__c, ApprovalHelper.STATUS_PENDING_APPROVAL)
                && (isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                    || isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_REJECTED));
        }
    }

    public class TaxExemptionVATCountry extends Triggers.TriggerHandlerBase {
        override public void handle() {

            List<Approval__c> approvals = new List<Approval__c>();
            for (Approval__c app : (List<Approval__c>)Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                    app.VATCountry__c != null &&
                    TaxExemptionHelper.VATBRANDS.contains(app.OpportunityBrand__c)) {
                    for (CountryCodes__c countryCode : CountryCodes__c.getAll().values()) {
                        for (String countryName : countryCode.CountryName__c.split(';')) {
                            if (app.VATCountry__c.toUpperCase() == countryName) {
                                approvals.add(new Approval__c (Id = app.Id, VATCountryForCheck__c = countryCode.CountryNameShort__c));
                            }
                        }
                    }
                }
            }

            if (approvals.size() > 0) {
                update approvals;
            }
        }
    }

    public class UncheckVATExemptionOnAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {

            List<Account> accounts = new List<Account>();
            List<Account> updateAccounts = new List<Account>();
            List<Id> accIds = new List<Id>();
            for (Approval__c app : (List<Approval__c>)Trigger.old) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                    && app.Status__c == APPROVAL_STATUS_APPROVED && app.Account__c != null
                ) {
                    accIds.add(app.Account__c);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }

            accounts = (List<Account>) new AccountSelector()
                .selectAccountWithTaxExemptionApprovals(new List<Object> {accIds})
                .executeQuery();
            if (accounts.isEmpty()) {
                return;
            }

            for (Account acc : accounts) {
                if (acc.TaxExemptionApprovals__c && acc.Approvals__r.isEmpty()) {
                    acc.TaxExemptionApprovals__c = false;
                    updateAccounts.add(acc);
                }
            }
            if (updateAccounts.size() > 0) {
                update updateAccounts;
            }
        }
    }

    public class RemoveTechnicalApprovalsOnMasterDelete extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (System.isFuture()) {
                return;
            }

            Set<Id> technicalApprovalIds = new Set<Id>();

            for (List<Approval__c> techApprovals : masterApprovalToTechnicalApprovals.values()) {
                for (Approval__c approval : techApprovals) {
                    technicalApprovalIds.add(approval.Id);
                }
            }
            if (!technicalApprovalIds.isEmpty()) {
                removeTechnicalApprovals(technicalApprovalIds);
            }
        }
    }

    @future
    public static void removeTechnicalApprovals(Set<Id> approvalIds) {
        delete (List<Approval__c>) new ApprovalSelector()
                .selectApprovalsByIds(new List<Object>{approvalIds})
                .executeQuery();
    }

    public class UncheckSendSpecialTermsToPDFCheckbox extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> oppIdsWithChangedApprovals = new Set<Id>();
            Set<Id> toggledApprovalIds = new Set<Id>();

            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (needToToggleCheckbox(app)) {
                    app.Send_Special_Terms_To_PDF__c = true;
                    toggledApprovalIds.add(app.Id);
                    oppIdsWithChangedApprovals.add(app.Opportunity__c);
                }
            }

            List<Approval__c> approvalsToUncheck = new ApprovalSelector()
                .selectEngageLegalApprovalsToUncheckForPDF(
                    new List<Object>{oppIdsWithChangedApprovals, toggledApprovalIds})
                .executeQuery();

            for (Approval__c app : approvalsToUncheck) {
                app.Send_Special_Terms_To_PDF__c = false;
            }

            update approvalsToUncheck;
        }

        private Boolean needToToggleCheckbox(Approval__c app) {
            return app.RecordTypeId == ApprovalHelperCls.RT_ID_ENGAGE_LEGAL
                && isChangedField(app, Approval__c.Special_Terms_and_Notes__c)
                && LeadConversionConfiguration__c.getValues(app.OpportunityBrand__c) != null
                && LeadConversionConfiguration__c.getValues(app.OpportunityBrand__c).Multiple_Engage_Legal_Management_Flow__c;
        }
    }

    public class SetVATNumberFromAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {

            Map<Id, String> mapAccountVATNumber = new Map<Id, String>();
            List<Account> accounts = new List<Account>();
            List<Id> accIds = new List<Id>();
            for (Approval__c app : (List<Approval__c>)Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                        app.Status__c == APPROVAL_STATUS_NEW) {
                    accIds.add(app.Account__c);
                }
            }

            if (!accIds.isEmpty()) {
                accounts = (List<Account>) new AccountSelector()
                        .selectAccountWithTaxExemptionApprovals(new List<Object> {accIds})
                        .executeQuery();
                if (!accounts.isEmpty()) {
                    for (Account acc : accounts) {
                        List<String> alpha2CountryCodes = SettingsService.getAlpha2CountryCodesByVatType(ApprovalHelper.VAT_NAME.VAT.name());
                        if (acc.VATNumber__c != null && acc.VATNumber__c.length() > 1
                            && !TaxExemptionHelper.isIndiaCountry(acc.BillingCountry)) {
                            mapAccountVATNumber.put(acc.Id, acc.VATNumber__c);
                            String countryCodeStr = acc.VATNumber__c.substring(0, 2);
                            if (alpha2CountryCodes.contains(countryCodeStr) && acc.VATNumber__c.startsWithIgnoreCase(countryCodeStr)) {
                                mapAccountVATNumber.put(acc.Id, acc.VATNumber__c.removeStartIgnoreCase(countryCodeStr));
                            }
                            if (acc.BillingCountry != null) {
                                String alpha2CountryCode = SettingsService.getAlpha2CountryCode(acc.BillingCountry);
                                if (alpha2CountryCodes.contains(alpha2CountryCode) && acc.VATNumber__c.startsWithIgnoreCase(alpha2CountryCode)) {
                                    mapAccountVATNumber.put(acc.Id, acc.VATNumber__c.removeStartIgnoreCase(alpha2CountryCode));
                                }
                            }
                        }
                    }
                }
                for (Approval__c app : (List<Approval__c>)Trigger.new) {
                    if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                            app.Status__c == APPROVAL_STATUS_NEW && mapAccountVATNumber.get(app.Account__c) != null) {
                        app.VATNumber__c = mapAccountVATNumber.get(app.Account__c);
                    }
                }
            }
        }
    }

    public class PopulateFieldsFromKYCToSEZWOPTaxExemption extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> teaApprovals = new List<Approval__c>();
            List<Id> accIds = new List<Id>();

            for (Approval__c tea : (List<Approval__c>)Trigger.new) {
                if (tea.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                    tea.Status__c == APPROVAL_STATUS_NEW) {
                    accIds.add(tea.Account__c);
                    teaApprovals.add(tea);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }

            Map<Id, Approval__c> approvalsByAccount = TaxExemptionHelper.getLastApprovedKYCApprovalByAccounts(accIds);

            for (Approval__c app: teaApprovals) {
                Approval__c kyc = approvalsByAccount.get(app.Account__c);
                if (kyc != null) {
                    String errMsg = TaxExemptionHelper.getKycErrorForTEACreation(kyc);
                    if (String.isBlank(errMsg)) {
                        app.GstNo__c = kyc.GstNo__c;
                        app.KycFiles__c = kyc.KycFiles__c;
                        app.SEZWOPExemption__c = ApprovalHelper.STATUS_REQUESTED;
                    } else {
                        app.addError(errMsg);
                    }
                }
            }
        }
    }

    public class PopulateSourceWithOther extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (String.isEmpty(app.Source__c)
                    && app.RecordTypeId == ApprovalHelper.RT_ID_ENGAGE_LEGAL) {
                    app.Source__c = ApprovalHelper.SOURCE_OTHER;
                }
            }
        }
    }

    public class ValidateInvoiceRequest extends Triggers.TriggerHandlerBase {

        private List<Approval__c> invoiceRequests = new List<Approval__c>();
        private List<AccountContactRole> invoiceRequestsRoles = new List<AccountContactRole>();

        override public void handle() {
            if (ApprovalHelper.isInvoiceNotHasApprovedKycApproval((List<Approval__c>) Trigger.new)) {
                throwErrorFor(ApprovalHelper.KYC_APPROVAL_APPROVED);
            }
            this.invoiceRequests = ApprovalHelper.getInvoiceRequests(Trigger.new);
            if (this.invoiceRequests.isEmpty()) {
                return;
            }
            this.invoiceRequestsRoles = ApprovalHelper.getPayableApprovalsRoles(this.invoiceRequests);
            ApprovalHelper.checkAccountPayableContacts(this.invoiceRequests, this.invoiceRequestsRoles);
        }

        private void throwErrorFor(String nameForError) {
            for (Approval__c approvalRecord : (List<Approval__c>) Trigger.new) {
                if (nameForError == ApprovalHelper.KYC_APPROVAL_APPROVED) {
                    approvalRecord.addError(Label.ApprovedKycApprovalIsRequired);
                }
            }
        }
    }

    public class ValidateInvoiceOnBehalfRequest extends Triggers.TriggerHandlerBase {

        private List<Approval__c> approvalsList = new List<Approval__c>();
        private List<AccountContactRole> accountsRolesWithPartners = new List<AccountContactRole>();
        private Map<Id,Account> accountsWithPartners = new Map<Id,Account>();

        override public void handle() {
            this.approvalsList = ApprovalHelper.getIOBorWholesaleApprovals((List<Approval__c>) Trigger.new);
            this.getAccountsWithPartners();

            this.accountsRolesWithPartners = ApprovalHelper.getPayableApprovalsRolesWithPartners(this.accountsWithPartners.values(), this.approvalsList);

            ApprovalHelper.checkAccountPayableContacts(this.approvalsList, this.accountsRolesWithPartners);
            ApprovalHelper.checkPartnerAccountPayableContacts(this.approvalsList, this.accountsRolesWithPartners, this.accountsWithPartners);
        }

        private void getAccountsWithPartners() {
            Set<Id> approvalsAccountsIds = new Set<Id>();
            for (Approval__c request : this.approvalsList) {
                approvalsAccountsIds.add(request.Account__c);
            }
            if (!approvalsAccountsIds.isEmpty()) {
                this.accountsWithPartners = new Map<Id,Account>(
                    (List<Account>)new AccountSelector()
                        .selectPartnerAccountsByIds(new List<Object>{
                            approvalsAccountsIds
                        })
                    .executeQuery()
                );
            }
        }
    }

    public class SyncPaymentMethodInfo extends Triggers.TriggerHandlerBase {
        override public void handle() {

            List<Approval__c> directDebitApprovals = new List<Approval__c>();
            List<Approval__c> invoiceApprovals = new List<Approval__c>();
            List<Approval__c> invoiceOnBehalfApprovals = new List<Approval__c>();
            List<Approval__c> invoiceWholesaleApprovals = new List<Approval__c>();

            for (Approval__c item : (List<Approval__c>) Trigger.new) {
                Boolean isRecordApproved = isChangedFieldTo(item, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED);
                if (!isRecordApproved) {
                    continue;
                }
                if (item.RecordTypeId == ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST) {
                    directDebitApprovals.add(item);
                }
                if (item.RecordTypeId == ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                    if (masterApprovalToTechnicalApprovals.get(item?.Id) != null) {
                        invoiceApprovals.addAll(masterApprovalToTechnicalApprovals.get(item.Id));
                    } else {
                        invoiceApprovals.add(item);
                    }
                }
                if (item.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST) {
                    invoiceOnBehalfApprovals.add(item);
                }
                if (item.RecordTypeId == ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST) {
                    invoiceWholesaleApprovals.add(item);
                }
            }

            List<Approval__c> approvalsList = new List<Approval__c>(directDebitApprovals);
            approvalsList.addAll(invoiceApprovals);
            approvalsList.addAll(invoiceOnBehalfApprovals);
            approvalsList.addAll(invoiceWholesaleApprovals);

            List<Approval__c> approvalsToSyncPaymentLimits = new List<Approval__c>();
            approvalsToSyncPaymentLimits.addAll(invoiceOnBehalfApprovals);
            approvalsToSyncPaymentLimits.addAll(ApprovalTriggerHandler.getOnlyPartnerPackageNotChangedApprovals(invoiceWholesaleApprovals));

            Map<Id, Account> accountMap = ApprovalHelper.getAccountMap(approvalsList);

            removeAllAccountPayableRolesExceptOfApproved(approvalsList);
            syncAccountPayableRole(approvalsList, accountMap);
            syncDirectDebitPaymentMethod(directDebitApprovals, accountMap);
            syncInvoiceMethod(invoiceApprovals, accountMap);
            syncPartnerPaymentMethod(invoiceOnBehalfApprovals, accountMap);
            syncPaymentLimits(approvalsToSyncPaymentLimits, accountMap);
        }

        private void removeAllAccountPayableRolesExceptOfApproved(List<Approval__c> approvalsList) {
            if (!Feature_Toggle__c.getOrgDefaults().AccountInvoiceBillingNGBSSync__c) {
                return;
            }

            if (approvalsList == null || approvalsList.isEmpty()) {
                return;
            }

            List<AccountContactRole> payableInvoiceRequestsRoles = ApprovalHelper.getPayableApprovalsRoles(approvalsList);

            List<AccountContactRole> accountContactRolesToDelete = new List<AccountContactRole>();
            for (Approval__c approval : approvalsList) {
                for (AccountContactRole role : payableInvoiceRequestsRoles) {
                    if (role.AccountId == approval.Account__c &&
                        role.ContactId != approval.AccountPayableContact__c
                        ) {
                        accountContactRolesToDelete.add(role);
                    }
                }
            }
            if (!accountContactRolesToDelete.isEmpty()) {
                delete accountContactRolesToDelete;
            }
        }

        private void syncAccountPayableRole(List<Approval__c> approvalsList, Map<Id, Account> accountMap) {
            if (!Feature_Toggle__c.getOrgDefaults().AccountInvoiceBillingNGBSSync__c) {
                return;
            }

            if (approvalsList == null || approvalsList.isEmpty() || accountMap.isEmpty()) {
                return;
            }

            List<Approval__c> approvalsToSyncWithNGBS = new List<Approval__c>();

            for (Approval__c item : approvalsList) {
                Account acc = accountMap.get(item.Account__c);
                if (acc == null || String.isBlank(acc.Billing_ID__c)) {
                    continue;
                }
                approvalsToSyncWithNGBS.add(item);
            }

            if (!approvalsToSyncWithNGBS.isEmpty()) {
                QueueableBase.enqueJob('AccountPayableRolesNGBSSync', approvalsToSyncWithNGBS);
            }
        }

        private void syncDirectDebitPaymentMethod(List<Approval__c> approvalsList, Map<Id, Account> accountMap) {

            if (!Feature_Toggle__c.getInstance().Enable_Direct_Debit_as_a_payment_method__c) {
                return;
            }

            if (approvalsList == null || approvalsList.isEmpty() || accountMap.isEmpty()) {
                return;
            }

            List<PaymentInfoSync.PaymentInfoParams> paramsList = new List<PaymentInfoSync.PaymentInfoParams>();
            for (Approval__c item : approvalsList) {
                Account acc = accountMap.get(item.Account__c);
                if (acc == null || String.isBlank(acc.Billing_ID__c)) {
                    continue;
                }
                paramsList.add(
                    new PaymentInfoSync.PaymentInfoParams(
                        acc.Billing_ID__c,
                        item.Account__c,
                        QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT,
                        item.Monthly_Credit_Limit__c,
                        null
                    )
                );
            }

            QueueableBase.enqueJob('PaymentInfoSync', paramsList);
        }


        private void syncInvoiceMethod(List<Approval__c> approvalsList, Map<Id, Account> accountMap) {

            if (!Feature_Toggle__c.getOrgDefaults().AccountInvoiceBillingNGBSSync__c) {
                return;
            }

            syncPaymentMethod(approvalsList, accountMap, 'AccountInvoiceBillingNGBSSync');
        }

        private void syncPartnerPaymentMethod(List<Approval__c> approvalsList, Map<Id, Account> accountMap) {
            syncPaymentMethod(approvalsList, accountMap, 'AccountPartnerPaymentMethodNGBSSync');
        }

        private void syncPaymentMethod(List<Approval__c> approvalsList, Map<Id, Account> accountMap, String job) {

            if (approvalsList == null || approvalsList.isEmpty() || accountMap.isEmpty()) {
                return;
            }

            List<Approval__c> approvalsToSyncWithNGBS = new List<Approval__c>();
            for (Approval__c item : approvalsList) {
                Account acc = accountMap.get(item.Account__c);
                if (acc == null || String.isBlank(acc.Billing_ID__c)) {
                    continue;
                }
                approvalsToSyncWithNGBS.add(item);
            }
            if (!approvalsToSyncWithNGBS.isEmpty()) {
                List<Account> accountsToSyncWithNGBS = getAccountsToSyncWithNGBS(approvalsToSyncWithNGBS);
                Map<String, List<Object>> agrumentsMap = new Map<String, List<Object>>{
                    'accounts' => accountsToSyncWithNGBS,
                    'approvals' => approvalsToSyncWithNGBS
                };
                List<Object> agrumentsList = new List<Object>{agrumentsMap};
                if (accountsToSyncWithNGBS != null && !accountsToSyncWithNGBS.isEmpty() && approvalsToSyncWithNGBS != null && !approvalsToSyncWithNGBS.isEmpty()) {
                    QueueableBase.enqueJob(job, agrumentsList);
                }
            }
        }

        private void syncPaymentLimits(List<Approval__c> approvalsList, Map<Id, Account> accountMap) {

            if (approvalsList == null || approvalsList.isEmpty() || accountMap.isEmpty()) {
                return;
            }

            List<Account> accountsToSyncWithNGBS = new List<Account>();

            for (Approval__c item : approvalsList) {
                Account acc = accountMap.get(item.Account__c);
                if (acc == null || String.isBlank(acc.Billing_ID__c)) {
                    continue;
                }
                accountsToSyncWithNGBS.add(acc);
            }

            if (!accountsToSyncWithNGBS.isEmpty()) {
                QueueableBase.enqueJob('AccountPaymentLimitsNGBSSync', accountsToSyncWithNGBS);
            }
        }

        private List<Account> getAccountsToSyncWithNGBS(List<Approval__c> approvals) {
            List<Account> accountsToSyncWithNGBS = new List<Account>();
            Set<Id> opportunitiesIds = new Set<Id>();
            Map<Id, Approval__c> accIdToApprovalMap = new Map<Id, Approval__c>();

            for (Approval__c appr : approvals) {
                accIdToApprovalMap.put(appr.Account__c, appr);
                opportunitiesIds.add(appr.Opportunity__c);
            }

            if (!accIdToApprovalMap.isEmpty()) {
                Id recordTypeId = approvals.get(0)?.RecordTypeId;
                accIdToApprovalMap = populateMapWithMasterAccountId(accIdToApprovalMap);
                List<Account> accountsWithLastApproval = (List<Account>) new AccountSelector()
                    .selectAccountsWithLastModifiedApprovals(
                        new List<Object>{
                            accIdToApprovalMap.keySet(),
                            opportunitiesIds
                        },
                        recordTypeId
                    )
                    .executeQuery();
                if (!accountsWithLastApproval.isEmpty()) {
                    Map<Id, List<Account>> masterAccToListBoundAccs = getMasterAccountToListBoundAccsMap(accountsWithLastApproval);
                    accountsToSyncWithNGBS = populateAccountsToSyncNGBSList(masterAccToListBoundAccs, accIdToApprovalMap);
                }
            }

            return accountsToSyncWithNGBS;
        }

        private Map<Id, List<Account>> getMasterAccountToListBoundAccsMap(List<Account> accountsWithLastApproval) {
            Map<Id, List<Account>> masterAccToListBoundAccs = new Map<Id, List<Account>>();
            for (Account acc : accountsWithLastApproval) {
                Id accountId = getAccountOrMasterAccountId(acc);
                if (!masterAccToListBoundAccs.containsKey(accountId)) {
                    masterAccToListBoundAccs.put(accountId, new List<Account>{});
                }
                masterAccToListBoundAccs.get(accountId).add(acc);
            }

            return masterAccToListBoundAccs;
        }

        private List<Account> populateAccountsToSyncNGBSList(
            Map<Id, List<Account>> masterAccToListBoundAccs,
            Map<Id, Approval__c> accIdToApprovalMap
        ) {
            List<Account> accountsToSync = new List<Account>();
            for (List<Account> boundAccs : masterAccToListBoundAccs.values()) {
                List<Account> approvedAccounts = new List<Account>();
                for (Account boundAcc : boundAccs) {
                    Boolean hasCommitedApprovedApproval = !boundAcc.Approvals__r.isEmpty()
                        && boundAcc.Approvals__r[0].Status__c == ApprovalHelper.STATUS_APPROVED;
                    Boolean isNotCommitedYetApprovedApproval = accIdToApprovalMap.get(boundAcc.Id)?.Status__c == ApprovalHelper.STATUS_APPROVED;

                    if (hasCommitedApprovedApproval || isNotCommitedYetApprovedApproval) {
                        approvedAccounts.add(boundAcc);
                    }
                }
                if (approvedAccounts.size() == boundAccs.size()) {
                    accountsToSync.addAll(approvedAccounts);
                }
            }

            return accountsToSync;
        }

        private Id getAccountOrMasterAccountId(Account acc) {
            return acc.Master_Account__c != null && !acc.IsMultiProductTechnicalAccount__c ? acc.Master_Account__c : acc.Id;
        }

        private Map<Id, Approval__c> populateMapWithMasterAccountId(Map<Id, Approval__c> accIdToApprovalMap) {
            if (!accIdToApprovalMap.isEmpty()) {
                List<Account> boundAccounts = (List<Account>) new AccountSelector()
                    .selectBoundAccountsByIdOrMasterAccountId(new List<Object>{ accIdToApprovalMap.keySet() })
                    .executeQuery();
                if (!boundAccounts.isEmpty()) {
                    for (Account acc : boundAccounts) {
                        if (acc.Master_Account__c != null && !accIdToApprovalMap.containsKey(acc.Master_Account__c)) {
                            accIdToApprovalMap.put(acc.Master_Account__c, new Approval__c());
                        }
                    }
                }
            }
            return accIdToApprovalMap;
        }
    }

    public static List<Approval__c> getOnlyPartnerPackageNotChangedApprovals(List<Approval__c> approvalsList) {
        Set<Approval__c> approvalsWhenPartnerPackageChanged = new Set<Approval__c>();

        if (approvalsList == null || approvalsList.isEmpty()) {
            return new List<Approval__c>();
        }

        Map<Id, Approval__c> oppIds = new Map<Id, Approval__c>();
        for (Approval__c approval : approvalsList) {
            oppIds.put(approval.Opportunity__c, approval);
        }

        List<Quote> primaryQuotesList =
            new QuoteSelector().selectBillingPrimaryQuotesByOppIds(oppIds.keySet())
            .executeQuery();

        Map<Id, Id> quoteIds = new Map<Id, Id>();
        for (Quote primaryQuote : primaryQuotesList) {
            quoteIds.put(primaryQuote.Id, primaryQuote.OpportunityId);
        }

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(quoteIds.keySet())
            .selectFields(new List<String>{
                'Entitlement__r.PartnerConfig__c',
                'Quote.Package_Info__c',
                'Quote.Id'
            })
            .executeQuery();

        for (QuoteLineItem qli : qliList) {
            BillingWrappers.PartnerPackageConfig partnerConfig;
            if (qli.Entitlement__r.PartnerConfig__c != null) {
                partnerConfig = (BillingWrappers.PartnerPackageConfig)
                    JSON.deserialize(qli.Entitlement__r.PartnerConfig__c, BillingWrappers.PartnerPackageConfig.class);

                Quote primaryQuote = qli.Quote;
                BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(primaryQuote);

                if (partnerConfig?.partnerPackageId != pInfo.partnerPackage?.id
                || partnerConfig?.partnerPackageVersion != pInfo.partnerPackage?.version) {
                    Id opptyID = quoteIds.get(primaryQuote.Id);
                    Approval__c appr = oppIds.get(opptyID);
                    approvalsWhenPartnerPackageChanged.add(appr);
                }
            }
        }

        List<Approval__c> result = new List<Approval__c>();
        for (Approval__c approval : approvalsList) {
            if (!approvalsWhenPartnerPackageChanged.contains(approval)) {
                result.add(approval);
            }
        }

        return result;
    }

    @TestVisible
    private class CustomSettingApprovers {
        public Id directorBO;
        public Id treasureManager;
        public Id treasurer;
        public Id controller;
        public Id invoiceController;

        public CustomSettingApprovers() {
            init();
        }

        private void init() {

            Map<String, String> approvalTypeToUserNameMap = getApproverNames();

            if (approvalTypeToUserNameMap.isEmpty()) {
                return;
            }

            List<User> users = (List<User>) new UserSelector()
                .selectUserByName(new List<Object>{ approvalTypeToUserNameMap.values() })
                .executeQuery();

            for (User u : users) {
                String directorBOName = approvalTypeToUserNameMap.get(ApprovalHelper.DIRECTOR_BO);
                if (!String.isBlank(directorBOName) && u.Name == directorBOName) {
                    this.directorBO = u.Id;
                }

                String treasureManagerName = approvalTypeToUserNameMap.get(ApprovalHelper.TREASURE_MANAGER);
                if (!String.isBlank(treasureManagerName) && u.Name == treasureManagerName) {
                    this.treasureManager = u.Id;
                }

                String treasurerName = approvalTypeToUserNameMap.get(ApprovalHelper.TREASURER);
                if (!String.isBlank(treasurerName) && u.Name == treasurerName) {
                    this.treasurer = u.Id;
                }

                String controllerName = approvalTypeToUserNameMap.get(ApprovalHelper.CONTROLLER);
                if (!String.isBlank(controllerName) && u.Name == controllerName) {
                    this.controller = u.Id;
                }
                String controllerInvoiceName = approvalTypeToUserNameMap.get(ApprovalHelper.INVOICE_CONTROLLER);
                if (!String.isBlank(controllerInvoiceName) && u.Name == controllerInvoiceName) {
                    this.invoiceController = u.Id;
                }
            }
        }

        private Map<String, String> getApproverNames() {

            RingCentralVariousSettings__c setting = RingCentralVariousSettings__c.getInstance();

            Map<String, String> approvalTypeToUserNameMap = new Map<String, String>();

            String directorBOName = getLastUserName(setting.Director_BO_Invoice_Billing_Approver__c);
            if (!String.isBlank(directorBOName)) {
                approvalTypeToUserNameMap.put(ApprovalHelper.DIRECTOR_BO, directorBOName);
            }

            String treasureManagerName = getLastUserName(setting.Treasure_Manager_Invoice_Billing_Approve__c);
            if (!String.isBlank(treasureManagerName)) {
                approvalTypeToUserNameMap.put(ApprovalHelper.TREASURE_MANAGER, treasureManagerName);
            }

            String treasurerName = getLastUserName(setting.Treasurer_Invoice_Billing_Approve__c);
            if (!String.isBlank(treasurerName)) {
                approvalTypeToUserNameMap.put(ApprovalHelper.TREASURER, treasurerName);
            }

            String controllerName = getLastUserName(setting.Controller_Invoice_Billing_Approver__c);
            if (!String.isBlank(controllerName)) {
                approvalTypeToUserNameMap.put(ApprovalHelper.CONTROLLER, controllerName);
            }
            String controllerInvoiceName = getLastUserName(setting.Controller_for_Invoice_Request__c);
            if (!String.isBlank(controllerInvoiceName)) {
                approvalTypeToUserNameMap.put(ApprovalHelper.INVOICE_CONTROLLER, controllerInvoiceName);
            }

            return approvalTypeToUserNameMap;
        }

        private String getLastUserName(String userNamesString) {
            if (String.isBlank(userNamesString)) {
                return '';
            }
            List<String> userNamesList = userNamesString.split('[^a-zA-Z0-9 ]');
            String lastUserName = userNamesList.get(userNamesList.size() - 1);
            return lastUserName.trim();
        }

        public List<String> getEmptyApproverNames() {
            List<String> emptyApproverNames = new List<String>();
            if (this.directorBO == null) {
                emptyApproverNames.add(ApprovalHelper.DIRECTOR_BO);
            }
            if (this.treasureManager == null) {
                emptyApproverNames.add(ApprovalHelper.TREASURE_MANAGER);
            }
            if (this.treasurer == null) {
                emptyApproverNames.add(ApprovalHelper.TREASURER);
            }
            if (this.controller == null) {
                emptyApproverNames.add(ApprovalHelper.CONTROLLER);
            }
            if (this.invoiceController == null) {
                emptyApproverNames.add(ApprovalHelper.INVOICE_CONTROLLER);
            }
            return emptyApproverNames;
        }
    }

    public class ApproverIdsSetter extends Triggers.TriggerHandlerBase {

        private final List<Id> recordTypeIdsToProcess = new List<Id>{
            ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST,
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
        };

        override public void handle() {

            List<Approval__c> recordsToProcess = new List<Approval__c>();

            for (Approval__c item : (List<Approval__c>) Trigger.new) {

                Boolean isRecordSubmittedForApproval = isChangedFieldTo(
                    item,
                    Approval__c.Status__c,
                    ApprovalHelper.STATUS_PENDING_L1_APPROVAL
                );
                Boolean isMonthlyCreditLimitExist = item.Monthly_Credit_Limit__c != null;
                Boolean isSignUpLimitExist = item.Sign_up_Purchase_Limit__c != null;

                Boolean isAPCChangedOnApprovedRecord = Trigger.isUpdate
                    && ApprovalHelper.isApprovalApproved(item)
                    && item.InvoiceApprovalType__c == ApprovalHelper.GOTOTHEFINALSTEP
                    && (isChangedField(item, Approval__c.AccountPayableContact__c)
                        || isChangedField(item, Approval__c.PartnerAccountPayableContact__c));

                Boolean isFinalStepRecordSubmittedWithoutChanges = Trigger.isUpdate
                    && item.InvoiceApprovalType__c == ApprovalHelper.GOTOTHEFINALSTEP
                    && ApprovalHelper.isRequiredKeyFieldsNotChanged(
                        item.getPopulatedFieldsAsMap(),
                        ((Approval__c) Trigger.oldMap.get(item.id))?.getPopulatedFieldsAsMap(),
                        new Set<String>{ 'Status__c', 'Approval_History__c' }
                    );

                Boolean isRecordApplicableForProcessing = recordTypeIdsToProcess.contains(item.RecordTypeId) &&
                    !(isFinalStepRecordSubmittedWithoutChanges && isRecordSubmittedForApproval) &&
                    (Trigger.isInsert
                        || isRecordSubmittedForApproval
                        || !isFinalStepRecordSubmittedWithoutChanges
                        || isAPCChangedOnApprovedRecord) &&
                    isMonthlyCreditLimitExist && isSignUpLimitExist;

                if (isRecordApplicableForProcessing) {
                    recordsToProcess.add(item);
                }
            }

            if (recordsToProcess.isEmpty()) {
                return;
            }

            setApproverIds(recordsToProcess);
        }

        private void setApproverIds(List<Approval__c> approvalList) {
            if (approvalList == null || approvalList.isEmpty()) {
                return;
            }

            // First pass - collect account IDs that need to be loaded
            Set<Id> customAccIds = new Set<Id>();
            for (Approval__c app : approvalList) {
                Boolean isAPCChangedOnApprovedRecord = Trigger.isUpdate
                    && ApprovalHelper.isApprovalApproved(app)
                    && app.InvoiceApprovalType__c == ApprovalHelper.GOTOTHEFINALSTEP
                    && (CoreObjectBase.isFieldChanged(app, Approval__c.AccountPayableContact__c)
                        || CoreObjectBase.isFieldChanged(app, Approval__c.PartnerAccountPayableContact__c));

                // Populate set when opposite condition is true (NOT isInvoiceApprovalRequestValidForFinalStep AND NOT isAPCChangedOnApprovedRecord)
                if (!(
                    ApprovalHelper.isInvoiceApprovalRequestValidForFinalStep(
                        app, accountIdToLastApprovedApprovalFromAccount.get(app.Account__c), customerToPartnerAccounts.get(app.Account__c))
                    || isAPCChangedOnApprovedRecord
                )) {
                    customAccIds.add(app.Account__c);
                }
            }

            // Load accounts using AccountSelector
            Map<Id, Account> accountsMap = new Map<Id, Account>();
            if (!customAccIds.isEmpty()) {
                List<Account> accountsList = (List<Account>) new AccountSelector()
                    .selectOnlyAccountsByIds(new List<Object>{new List<Id>(customAccIds)})
                    .executeQuery();
                for (Account acc : accountsList) {
                    accountsMap.put(acc.Id, acc);
                }
            }

            CustomSettingApprovers approvers = new CustomSettingApprovers();
            validateApprovers(approvers, approvalList);

            User currentUser = (User) new UserSelector()
                .selectCurrentUserForSettingsService()
                .executeQuery()
                .get(0);

            User dnbiUser = D_B_Credit_CheckObj.getDnbiUser();

            for (Approval__c app : approvalList) {
                Boolean isAPCChangedOnApprovedRecord = Trigger.isUpdate
                    && ApprovalHelper.isApprovalApproved(app)
                    && app.InvoiceApprovalType__c == ApprovalHelper.GOTOTHEFINALSTEP
                    && (CoreObjectBase.isFieldChanged(app, Approval__c.AccountPayableContact__c)
                        || CoreObjectBase.isFieldChanged(app, Approval__c.PartnerAccountPayableContact__c));

                if (
                    ApprovalHelper.isInvoiceApprovalRequestValidForFinalStep(
                        app, accountIdToLastApprovedApprovalFromAccount.get(app.Account__c), customerToPartnerAccounts.get(app.Account__c))
                    || isAPCChangedOnApprovedRecord
                ) {
                    if (isAPCChangedOnApprovedRecord) {
                        app.Status__c = APPROVAL_STATUS_REQUIRED;
                    }
                    app.InvoiceApprovalType__c = ApprovalHelper.GOTOTHEFINALSTEP;
                    continue;
                }

                Account partnerAcc = customerToPartnerAccounts.get(app.Account__c);
                Account customerAcc = accountsMap.get(app.Account__c);

                if (AccountHelper.isWholesaleAccount(customerAcc )
                && ApprovalHelper.isInvoiceWholesaleRequestApproval(app)
                && partnerAcc != null
                && (
                    AccountHelper.isExistingBusiness(customerAcc)
                        ? app.Monthly_Credit_Limit__c <= partnerAcc.Credit_Limit__c
                        : app.Sign_up_Purchase_Limit__c <= partnerAcc.Credit_Limit__c
                    )
                && (
                    (Trigger.isUpdate && ApprovalHelper.PENDING_APPROVAL_STATUSES.contains(app.Status__c))
                    || Trigger.isInsert
                    )
                ) {
                    app.Status__c = APPROVAL_STATUS_APPROVED;
                    continue;
                }
                Boolean isDirectDebit = recordTypeIdsToProcess.contains(app.RecordTypeId) &&  app.RecordTypeId == ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST;
                Boolean isInvoiceApproval = recordTypeIdsToProcess.contains(app.RecordTypeId) &&  app.RecordTypeId != ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST;
                if (isDirectDebit) {
                    if (app.Monthly_Credit_Limit__c <= 500 && app.Sign_up_Purchase_Limit__c <= 150000) {
                        app.InvoiceApprovalType__c = MCLESS500SULESS150K;
                        app.Level1Approver__c = currentUser.ManagerId;
                        app.Level2Approver__c = approvers.directorBO;
                        app.Level3Approver__c = dnbiUser.Id;
                    }

                    if (
                        app.Monthly_Credit_Limit__c <= 500 &&
                        app.Sign_up_Purchase_Limit__c > 150000 &&
                        app.Sign_up_Purchase_Limit__c <= 750000
                    ) {
                        app.InvoiceApprovalType__c = MCLESS500SUMORE150KLESS750K;
                        app.Level1Approver__c = currentUser.ManagerId;
                        app.Level2Approver__c = approvers.directorBO;
                        app.Level3Approver__c = dnbiUser.Id;
                        app.Level4Approver__c = approvers.treasurer;
                    }

                    if (app.Monthly_Credit_Limit__c <= 500 && app.Sign_up_Purchase_Limit__c > 750000) {
                        app.InvoiceApprovalType__c = MCLESS500SUMORE750K;
                        app.Level1Approver__c = currentUser.ManagerId;
                        app.Level2Approver__c = approvers.directorBO;
                        app.Level3Approver__c = approvers.treasurer;
                        app.Level4Approver__c = approvers.controller;
                        app.InvoiceBillingLevel5Approver__c = dnbiUser.Id;
                    }

                    if (app.Monthly_Credit_Limit__c > 500 && app.Sign_up_Purchase_Limit__c <= 10000) {
                        app.InvoiceApprovalType__c = MCMORE500SULESS10K;
                        app.Level1Approver__c = null;
                        app.Level2Approver__c = null;
                        app.Level3Approver__c = null;
                        app.Level4Approver__c = null;
                    }

                    if (
                        app.Monthly_Credit_Limit__c > 500 &&
                        app.Sign_up_Purchase_Limit__c > 10000 &&
                        app.Sign_up_Purchase_Limit__c <= 150000
                    ) {
                        app.InvoiceApprovalType__c = MCMORE500SUMORE10KLESS150K;
                        app.Level1Approver__c = dnbiUser.Id;
                        app.Level2Approver__c = null;
                        app.Level3Approver__c = null;
                    }

                    if (
                        app.Monthly_Credit_Limit__c > 500 &&
                        app.Sign_up_Purchase_Limit__c > 150000 &&
                        app.Sign_up_Purchase_Limit__c <= 750000
                    ) {
                        app.InvoiceApprovalType__c = MCMORE500SUMORE150KLESS750K;
                        app.Level1Approver__c = dnbiUser.Id;
                        app.Level2Approver__c = null;
                        app.Level3Approver__c = approvers.treasurer;
                        app.Level4Approver__c = null;
                    }

                    if (app.Monthly_Credit_Limit__c > 500 && app.Sign_up_Purchase_Limit__c > 750000) {
                        app.InvoiceApprovalType__c = MCMORE500SUMORE750K;
                        app.Level1Approver__c = dnbiUser.Id;
                        app.Level3Approver__c = approvers.treasurer;
                        app.Level4Approver__c = approvers.controller;
                    }
                }else if (isInvoiceApproval) {
                    //app.Level1Approver__c = currentUser.ManagerId;
                    app.Level2Approver__c = dnbiUser.Id;
                    app.Level3Approver__c = approvers.directorBO;
                    app.Level4Approver__c = approvers.invoiceController;
                }
            }
        }

        private void validateApprovers(CustomSettingApprovers approvers, List<Approval__c> approvalList) {
            if (approvers == null || (approvalList == null || approvalList.isEmpty())) {
                return;
            }
            List<String> emptyApproverNames = approvers.getEmptyApproverNames();
            if (!emptyApproverNames.isEmpty()) {
                String errorMessage = 'You have no ' + String.join(emptyApproverNames, ', ') + ' for approve. ' +
                    'Please contact your administrator.';
                for (Approval__c app : approvalList) {
                    app.addError(errorMessage);
                }
            }
        }
    }

    public static final String REJECTED_TEMPLATE_TYPE = 'APPROVAL_REJECTED';
    public static final String STEP_APPROVED_TEMPLATE_TYPE = 'APPROVAL_STEP_APPROVED';
    public static final String FINAL_APPROVED_TEMPLATE_TYPE = 'APPROVAL_FINAL_APPROVED';

    @TestVisible
    private static Map<Id, Map<String, String>> recordTypeIdToEmailTemplateNamesMap = new Map<Id, Map<String, String>>{
        ApprovalHelper.RT_ID_INVOICING_REQUEST => new Map<String, String>{
            REJECTED_TEMPLATE_TYPE => INVOICING_REQUEST_REJECTED,
            STEP_APPROVED_TEMPLATE_TYPE => INVOICING_REQUEST_INTERM_APPROVED_TEMPLATE,
            FINAL_APPROVED_TEMPLATE_TYPE => INVOICE_REQUEST_FINAL_APPROVAL
        },
        ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST => new Map<String, String>{
            REJECTED_TEMPLATE_TYPE => DIRECT_DEBIT_REQUEST_REJECTED,
            STEP_APPROVED_TEMPLATE_TYPE => DIRECT_DEBIT_REQUEST_INTERM_APPROVED,
            FINAL_APPROVED_TEMPLATE_TYPE => DIRECT_DEBIT_REQUEST_FINAL_APPROVAL
        },
        ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST => new Map<String, String>{
            REJECTED_TEMPLATE_TYPE => INVOICE_ON_BEHALF_REQUEST_REJECTED,
            STEP_APPROVED_TEMPLATE_TYPE => INVOICE_ON_BEHALF_REQUEST_INTERM_APPROVED,
            FINAL_APPROVED_TEMPLATE_TYPE => INVOICE_ON_BEHALF_REQUEST_FINAL_APPROVAL
        },
		ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST => new Map<String, String>{
            REJECTED_TEMPLATE_TYPE => INVOICE_WHOLESALE_REQUEST_REJECTED,
            STEP_APPROVED_TEMPLATE_TYPE => INVOICE_WHOLESALE_REQUEST_INTERM_APPROVED,
            FINAL_APPROVED_TEMPLATE_TYPE => INVOICE_WHOLESALE_REQUEST_FINAL_APPROVAL
        }
    };

    @TestVisible
    private class EmailTemplatesData {
        public EmailTemplate rejectedTemplate;
        public EmailTemplate finalApprovalTemplate;
        public EmailTemplate stepApprovedTemplate;
    }

    @TestVisible
    private static Map<Id, EmailTemplatesData> getRecordTypeIdToEmailTemplatesMap(Set<Id> recordTypeIdSet) {

        Map<Id, EmailTemplatesData> result = new Map<Id, EmailTemplatesData>();

        if (recordTypeIdSet == null || recordTypeIdSet.isEmpty()) {
            return result;
        }

        List<String> emailTemplateDevNames = new List<String>();

        for (Id recordTypeId : recordTypeIdSet) {
            if (!recordTypeIdToEmailTemplateNamesMap.containsKey(recordTypeId)) {
                continue;
            }
            emailTemplateDevNames.addAll(
                recordTypeIdToEmailTemplateNamesMap.get(recordTypeId).values()
            );
        }

        if (emailTemplateDevNames.isEmpty()) {
            return result;
        }

        List<EmailTemplate> templatesList = (List<EmailTemplate>) new EmailTemplateSelector()
            .selectEmailTemplatesByDeveloperNames(emailTemplateDevNames, true)
            .executeQuery();

        for (Id recordTypeId : recordTypeIdSet) {
            if (!recordTypeIdToEmailTemplateNamesMap.containsKey(recordTypeId)) {
                continue;
            }

            Map<String, String> templateTypeToDevNameMap = recordTypeIdToEmailTemplateNamesMap.get(recordTypeId);
            EmailTemplatesData templatesData = getTemplatesData(templateTypeToDevNameMap, templatesList);
            result.put(recordTypeId, templatesData);
        }

        return result;
    }

    @TestVisible
    private static EmailTemplatesData getTemplatesData(
        Map<String, String> templateTypeToDevNameMap,
        List<EmailTemplate> templatesList
    ) {
        EmailTemplatesData templatesData = new EmailTemplatesData();

        if (templateTypeToDevNameMap == null || templateTypeToDevNameMap.isEmpty()
            || templatesList == null || templatesList.isEmpty()) {
            return templatesData;
        }

        for (String templateType : templateTypeToDevNameMap.keySet()) {
            String templateDevName = templateTypeToDevNameMap.get(templateType);
            for (EmailTemplate template : templatesList) {
                if (templateDevName == template.DeveloperName) {
                    if (templateType == REJECTED_TEMPLATE_TYPE) {
                        templatesData.rejectedTemplate = template;
                    } else if (templateType == STEP_APPROVED_TEMPLATE_TYPE) {
                        templatesData.stepApprovedTemplate = template;
                    } else if (templateType == FINAL_APPROVED_TEMPLATE_TYPE) {
                        templatesData.finalApprovalTemplate = template;
                    }
                }
            }
        }

        return templatesData;
    }

    public class ApprovalEmailsHandler extends Triggers.TriggerHandlerBase {

        private final List<Id> recordTypeIdsToProcess = new List<Id>{
            ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST,
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
			ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
        };

        private final Set<String> pendingApprovalStatuses = new Set<String>{
            ApprovalHelper.STATUS_PENDING_L2_APPROVAL,
            ApprovalHelper.STATUS_PENDING_L3_APPROVAL,
            ApprovalHelper.STATUS_PENDING_L4_APPROVAL,
            ApprovalHelper.STATUS_PENDING_L5_APPROVAL,
            ApprovalHelper.STATUS_PENDING_L6_APPROVAL,
            ApprovalHelper.STATUS_PENDING_L7_APPROVAL,
            ApprovalHelper.STATUS_PENDING_L8_APPROVAL
        };
        private final Set<String> pendingApprovalStatusesForInvoice = new Set<String>{
            ApprovalHelper.STATUS_PENDING_L1_APPROVAL
        };

        override public void handle() {

            Set<String> handlingStatuses = new Set<String>{
                ApprovalHelper.STATUS_REJECTED,
                ApprovalHelper.STATUS_APPROVED
            };
            handlingStatuses.addAll(pendingApprovalStatuses);

            Map<String, Decimal> currencyToConversionRateMap = AquivaHelper.getCurrencyToConversionRateMap();
            List<Approval__c> recordsToProcess = new List<Approval__c>();
            User currentUser = (User) new UserSelector()
                .selectCurrentUserForSettingsService()
                .executeQuery()
                .get(0);

            if(approvalProcessInstanceMap.isEmpty()){
                for (ProcessInstance eachPI : [SELECT Id,TargetObjectId
                FROM ProcessInstance
                WHERE TargetObjectId IN :Trigger.new
                AND (Status = 'Pending' OR Status = 'Started')
                AND ProcessDefinition.Name LIKE '%Invoice Request Approval%' order by createddate asc]) {
                    approvalProcessInstanceMap.put(eachPI.TargetObjectId, eachPI.Id);
                }
            }

            for (Approval__c item : (List<Approval__c>) Trigger.new) {
                Boolean isRecordApplicableForProcessing = recordTypeIdsToProcess.contains(item.RecordTypeId) &&
                    isChangedFieldToAnyString(item, Approval__c.Status__c, handlingStatuses);
                Boolean isRecordApplicableForProcessingForInvoice = recordTypeIdsToProcess.contains(item.RecordTypeId) &&
                    item.RecordTypeId != ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST &&
                    isChangedFieldToAnyString(item, Approval__c.Status__c, pendingApprovalStatusesForInvoice);
                if (isRecordApplicableForProcessingForInvoice) {
                    if (item.Account_Status__c == RC_ACC_STATUS_CANCELLED) {
                        item.addError(System.Label.AccountStatusCanceled);
                    }else if(item.Status__c == ApprovalHelper.STATUS_PENDING_L1_APPROVAL && currentUser.ManagerId== null){
                        item.addError(System.Label.InvoiceApprovalManagerNotFound);
                    }else if(currentUser.ManagerId != null){
                        if(item.RecordTypeId == ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST ) {
                        	item.Level1Approver__c = currentUser.ManagerId;
                        }
                    }
                }

                Decimal exchangeRate = currencyToConversionRateMap.get(item.CurrencyIsoCode) == null ? 1 : currencyToConversionRateMap.get(item.CurrencyIsoCode);
                Decimal convertedSignUp = item.Sign_Up_Purchase_Limit__c != null ? item.Sign_Up_Purchase_Limit__c / exchangeRate : 0;
                Decimal convertedMonthlyCredit = item.Monthly_Credit_Limit__c != null ? item.Monthly_Credit_Limit__c / exchangeRate : 0;

                if (isRecordApplicableForProcessing
                    || (isRecordApplicableForProcessingForInvoice
                    && convertedSignUp > 500
                    && convertedSignUp <= 10000
                    && convertedMonthlyCredit > 500)
                ) {
                    if (approvalProcessInstanceMap.containsKey(item.Id)) {
                        invoiceRequestIds.add(item.Id);
                        item.InvoiceApprovalType__c = approvalProcessInstanceMap.get(item.Id);
                    }
                    recordsToProcess.add(item);
                }
            }

            if (recordsToProcess.isEmpty()) {
                return;
            }

            List<Messaging.SingleEmailMessage> mails = buildEmails(recordsToProcess);
            if (!mails.isEmpty()) {
                try {
                    Messaging.sendEmail(mails);
                } catch (EmailException ex) {
                    for (Approval__c approvalRecord: recordsToProcess) {
                        approvalRecord.addError('You can\'t send Emails. Please contact your administrator');
                    }
                }
            }
        }

        private List<Messaging.SingleEmailMessage> buildEmails(List<Approval__c> approvalList) {

            if (approvalList == null || approvalList.isEmpty()) {
                return new List<Messaging.SingleEmailMessage>();
            }

            Set<Id> recordTypeIdSet = new Set<Id>();
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> approverIdSet = new Set<Id>();
            Set<Id> rejectedIds = new Set<Id>();
            Map<Id, Approval__c> oldApprovals = (Map<Id, Approval__c>) Trigger.oldMap;
            Set<Id> oppIds = new Set<Id>();
            if(invoiceRequestIds?.size() > 0){
                for(D_B_Credit_Check__c eachCreditCheck : [SELECT Id, Approval__c,
                (SELECT Id, DNBI__ApplicationValue__c FROM Decision_Rules__r WHERE Name='RingCentral Application Scorecard' ORDER BY CreatedDate DESC LIMIT 1)
                FROM D_B_Credit_Check__c WHERE Approval__c IN : approvalList]){
                    if(eachCreditCheck?.Decision_Rules__r?.size()==1 && eachCreditCheck.Decision_Rules__r[0].DNBI__ApplicationValue__c != null){
                        try{
                            creditCheckForApprovalMap.put(eachCreditCheck.Approval__c ,Double.valueof(eachCreditCheck.Decision_Rules__r[0].DNBI__ApplicationValue__c) );
                        }
                        catch (Exception ex){
                            system.debug('TypeException '+ex.getMessage());
                        }
                    }
                }
                convertedCurrencyApprovals= new Map<Id, Approval__c>([SELECT Id, convertCurrency(Monthly_Credit_Limit__c), convertCurrency(Sign_Up_Purchase_Limit__c) FROM Approval__c WHERE Id IN : approvalList]);
                CustomSettingApprovers customsetting = new CustomSettingApprovers();
                approverMap = customsetting.getApproverNames();
            }
            for (Approval__c item : approvalList) {
                recordTypeIdSet.add(item.RecordTypeId);

                accountIdSet.add(item.Account__c);

                approverIdSet.add(item.Level1Approver__c);
                approverIdSet.add(item.Level2Approver__c);
                approverIdSet.add(item.Level3Approver__c);
                approverIdSet.add(item.Level4Approver__c);
                approverIdSet.add(item.InvoiceBillingLevel5Approver__c);

                approverIdSet.add(oldApprovals.get(item.Id).Level1Approver__c);
                approverIdSet.add(oldApprovals.get(item.Id).Level2Approver__c);
                approverIdSet.add(oldApprovals.get(item.Id).Level3Approver__c);
                approverIdSet.add(oldApprovals.get(item.Id).Level4Approver__c);
                approverIdSet.add(oldApprovals.get(item.Id).InvoiceBillingLevel5Approver__c);

                if (item.Status__c == ApprovalHelper.STATUS_REJECTED) {
                    rejectedIds.add(item.Id);
                }
                if(item.Opportunity__c != null && invoiceRequestIds != null && invoiceRequestIds.contains(item.Id)){
                    oppIds.add(item.Opportunity__c);
                }
            }
            Map<Id, Account> accountMap = ApprovalHelper.getAccountMap(accountIdSet);
            Map<Id, User> usersMap = getUsersMap(approverIdSet);
            Map<Id, ProcessInstance> approvalWithApprovalProcess = getApprovalIdToApprovalProcessMap(rejectedIds);

            User dnbiUser = D_B_Credit_CheckObj.getDnbiUser();

            Map<Id, EmailTemplatesData> recordTypeIdToEmailTemplatesMap = getRecordTypeIdToEmailTemplatesMap(recordTypeIdSet);

            ApprovalEmailBuilder emailBuilder = new ApprovalEmailBuilder();

            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

            if(oppIds?.size() > 0){
                for(Opportunity opp : [SELECT Id, PrimaryQuote__r.Payment_Plan__c FROM Opportunity WHERE Id IN : oppIds AND PrimaryQuote__c != null]){
                    paymentPlans.put(opp.Id, opp.PrimaryQuote__r.Payment_Plan__c);
                }
            }
            for (Approval__c item : approvalList) {

                EmailTemplatesData templatesData = recordTypeIdToEmailTemplatesMap.get(item.RecordTypeId);

                Account acc = accountMap.get(item.Account__c);

                if (ApprovalHelper.PENDING_APPROVAL_STATUSES.contains(item.Status__c)) {
                    ApprovalHelperCls.InternalEmail email = emailBuilder.buildPendingApprovalEmail(
                        templatesData.stepApprovedTemplate,
                        item,
                        oldApprovals.get(item.Id),
                        acc.Name,
                        usersMap,
                        dnbiUser.Id
                    );
                    if (email != null) {
                        mails.addAll(email.getMails());
                    }
                }

                if (item.Status__c == ApprovalHelper.STATUS_APPROVED) {
                    ApprovalHelperCls.InternalEmail email = emailBuilder.buildApprovedEmail(
                        templatesData.finalApprovalTemplate,
                        item,
                        acc.Name
                    );
                    if (email != null) {
                        mails.addAll(email.getMails());
                    }
                }

                if (item.Status__c == ApprovalHelper.STATUS_REJECTED) {
                    ApprovalHelperCls.InternalEmail email = emailBuilder.buildRejectedEmail(
                        templatesData.rejectedTemplate,
                        item,
                        acc.Name,
                        approvalWithApprovalProcess.get(item.Id)
                    );

                    if (email != null) {
                        mails.addAll(email.getMails());
                    }
                }
            }

            return mails;
        }

        private Map<Id, User> getUsersMap(Set<Id> userIdSet) {

            Map<Id, User> userMap = new Map<Id, User>();

            if (userIdSet == null || userIdSet.isEmpty()) {
                return userMap;
            }
            userIdSet.remove(null);

            if (userIdSet.isEmpty()) {
                return userMap;
            }

            List<User> usersList = (List<User>) new UserSelector()
                .selectUserForApproval(new List<Object>{ userIdSet })
                .executeQuery();

            userMap = new Map<Id, User>(usersList);

            return userMap;
        }

        private List<ProcessInstance> getApprovalSteps(Set<Id> approvalIdSet) {

            if (approvalIdSet == null || approvalIdSet.isEmpty()) {
                return new List<ProcessInstance>();
            }

            List<ProcessInstance> result = (List<ProcessInstance>) new ProcessInstanceSelector()
                .selectProcessInstancesForApproval(new List<Object>{ approvalIdSet })
                .executeQuery();

            return result;
        }

        private Map<Id, ProcessInstance> getApprovalIdToApprovalProcessMap(Set<Id> approvalIdSet) {

            Map<Id, ProcessInstance> result = new Map<Id, ProcessInstance>();

            if (approvalIdSet == null || approvalIdSet.isEmpty()) {
                return result;
            }
            approvalIdSet.remove(null);

            if (approvalIdSet.isEmpty()) {
                return result;
            }

            List<ProcessInstance> approvalSteps = getApprovalSteps(approvalIdSet);
            if (!approvalSteps.isEmpty()) {
                for (ProcessInstance approvalProcess : approvalSteps) {
                    result.put(approvalProcess.TargetObjectId, approvalProcess);
                }
            }

            return result;
        }
    }

    @TestVisible
    private class ApprovalEmailBuilder {

        public ApprovalHelperCls.InternalEmail buildPendingApprovalEmail(
            EmailTemplate template,
            Approval__c item,
            Approval__c itemOld,
            String accountName,
            Map<Id, User> userMap,
            Id dnbiUserId
        ) {

            if (template == null || item == null) {
                return null;
            }
            Double signUp = 0;
            Double monthlyCredit = 0;
            Boolean isInvoiceRequest = false;
            if(convertedCurrencyApprovals != null && convertedCurrencyApprovals.containsKey(item.Id) && invoiceRequestIds != null && invoiceRequestIds.contains(item.Id)){
                isInvoiceRequest = true;
                if(convertedCurrencyApprovals.get(item.Id).Sign_Up_Purchase_Limit__c != null) {
                    signUp = convertedCurrencyApprovals.get(item.Id).Sign_Up_Purchase_Limit__c;
                }
                if(convertedCurrencyApprovals.get(item.Id).Monthly_Credit_Limit__c != null) {
                    monthlyCredit = convertedCurrencyApprovals.get(item.Id).Monthly_Credit_Limit__c;
                }
            }
            String currentUser = String.format('{0} {1}', new List<String>{UserInfo.getFirstName(), UserInfo.getLastName()});

            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(
                item.OwnerId,
                template.Subject,
                template.HtmlValue
            );

            mail.addParameter('ApprovalRequest.External_URL', BASE_URL + '/' + item.Id);
            mail.addParameter('Account.Name', accountName);
            mail.addParameter('Action', 'Approved');

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L1_APPROVAL) {
                if (isInvoiceRequest) {
                    if (signUp > 500 && signUp <= 10000 && monthlyCredit > 500) {
                        mail = null;
                        System.enqueueJob(new InvoiceRequestApprovalHelper(item,ApprovalHelper.DB_CREDIT_CHECK));
                    }
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L2_APPROVAL) {
                if (isInvoiceRequest) {
                    mail.addParameter(ApprovalHelper.PREVIOUS_APPROVER, currentUser);

                    if (signUp <= 10000 && monthlyCredit <= 500) {
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, ApprovalHelper.FINANCE_EXCEPTION_APPROVAL);
                        String brandLabel = System.label.InvoiceRequestBrands.toUppercase();
                        List<String> segmentList = new List<String>(System.label.InvoiceRequestSegments.toUppercase().split(','));
                        List<String> paymentPlanList = new List<String>(System.label.InvoiceRequestPaymentPlan.toUppercase().split(','));
                        if (brandLabel == null && segmentList.isEmpty() && paymentPlanList.isEmpty() && paymentPlans.isEmpty()) {
                            return null;
                        }
                        boolean isValidBrand = item.OpportunityBrand__c != null && item.OpportunityBrand__c.toUppercase().contains(brandLabel);
                        boolean isValidSegment = item.Account_Segment__c != null && segmentList.indexOf(item.Account_Segment__c.toUppercase()) != -1;
                        boolean isValidPaymentPlan = paymentPlans.containsKey(item.Opportunity__c) && paymentPlanList.indexOf(paymentPlans.get(item.Opportunity__c).toUppercase()) != -1;
                        if((isValidBrand && isValidSegment) || (isValidPaymentPlan)){
                            System.enqueueJob(new InvoiceRequestApprovalHelper(item, ApprovalHelper.FINANCE_EXCEPTION_APPROVAL));
                        }
                    }
                } else {
                    if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                        mail.addParameter('Previous_Approver', FINANCEINVOICE);

                        if (item.Level1Approver__c != null && userMap.get(itemOld.Level1Approver__c) != null) {
                            mail.addParameter('New_Approver',
                            userMap.get(itemOld.Level1Approver__c).Name);
                        }

                    } else if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditMoreThan500')
                        && item.Sign_Up_Purchase_Limit__c > 10000) {

                        mail.addParameter('Previous_Approver', FINANCEINVOICE);
                        mail.addParameter('New_Approver', 'Billing Credit Check Queue');
                    } else {
                        mail.addParameter('Previous_Approver', FINANCEINVOICE);
                        mail.addParameter('New_Approver', 'Invoice Approval Queue');
                    }
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L3_APPROVAL) {
                if (isInvoiceRequest) {
                    if (signUp <= 10000 && monthlyCredit <= 500) {
                        mail.addParameter(ApprovalHelper.PREVIOUS_APPROVER, currentUser);
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, ApprovalHelper.DB_CREDIT_CHECK);
                    }
                } else {
                    if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                        if (item.Level1Approver__c != null && userMap.get(itemOld.Level1Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level1Approver__c).Name);
                        }
                        if (item.Level2Approver__c != null && userMap.get(itemOld.Level2Approver__c) != null) {
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level2Approver__c).Name);
                        }
                    } else {

                        mail.addParameter('Previous_Approver', 'Billing Credit Check Queue');

                        if (item.Level1Approver__c != null && userMap.get(itemOld.Level1Approver__c) != null) {
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level1Approver__c).Name);
                        }
                    }
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L4_APPROVAL) {
                if (isInvoiceRequest) {
                    mail.addParameter(ApprovalHelper.PREVIOUS_APPROVER, currentUser);
                    if (signUp > 10000) {
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, approverMap.get(ApprovalHelper.DIRECTOR_BO));
                    } else {
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, ApprovalHelper.INVOICE_APPROVAL_QUEUE);
                    }
                } else {
                    if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                        if (item.Level2Approver__c != null && userMap.get(itemOld.Level2Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level2Approver__c).Name);
                        }
                        mail.addParameter('New_Approver', 'Billing Credit Check Queue');
                    } else {

                        if (item.Level1Approver__c != null && userMap.get(itemOld.Level1Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level1Approver__c).Name);
                        }

                        if (item.Level3Approver__c != null && userMap.get(itemOld.Level3Approver__c) != null) {
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level3Approver__c).Name);
                        } else {
                            mail.addParameter('New_Approver', 'Invoice Approval Queue');
                        }
                    }
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L5_APPROVAL) {
                if (isInvoiceRequest) {
                    mail.addParameter(ApprovalHelper.PREVIOUS_APPROVER, currentUser);
                    if (signUp > 10000 && signUp <= 750000 && approverMap.containsKey(ApprovalHelper.DIRECTOR_BO)) {
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, ApprovalHelper.INVOICE_APPROVAL_QUEUE);
                    } else if (signUp > 750000 && approverMap.containsKey(ApprovalHelper.INVOICE_CONTROLLER)){
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, approverMap.get(ApprovalHelper.INVOICE_CONTROLLER));
                    } else {
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, ApprovalHelper.INVOICE_APPROVAL_QUEUE);
                    }
                } else {
                    if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                        mail.addParameter('Previous_Approver', 'Billing Credit Check Queue');

                        if (item.Level3Approver__c == dnbiUserId && userMap.get(itemOld.Level3Approver__c) != null) {
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level3Approver__c).Name);
                        } else if (userMap.get(itemOld.InvoiceBillingLevel5Approver__c) != null){
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.InvoiceBillingLevel5Approver__c).Name);
                        }
                    } else {

                        if (item.Level3Approver__c != null && userMap.get(itemOld.Level3Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level3Approver__c).Name);
                        }
                        if (item.Sign_Up_Purchase_Limit__c > 750000  &&  userMap.get(itemOld.Level4Approver__c) != null) {
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level4Approver__c).Name);
                        } else {
                            mail.addParameter('New_Approver', 'Invoice Approval Queue');
                        }
                    }
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L6_APPROVAL) {
                if (isInvoiceRequest) {
                    if (signUp > 750000) {
                        mail.addParameter(ApprovalHelper.PREVIOUS_APPROVER, currentUser);
                        mail.addParameter(ApprovalHelper.NEW_APPROVER, ApprovalHelper.INVOICE_APPROVAL_QUEUE);
                    }
                }
                if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                    if (item.Level3Approver__c == dnbiUserId) {
                        if (item.Sign_Up_Purchase_Limit__c <= 150000 && userMap.get(itemOld.Level3Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level3Approver__c).Name);
                            mail.addParameter('New_Approver', 'Invoice Approval Queue');
                        } else {
                            if(userMap.get(itemOld.Level3Approver__c) != null) {
                                mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level3Approver__c).Name);
                            }
                            if(userMap.get(itemOld.Level4Approver__c) != null) {
                                mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level4Approver__c).Name);
                            }
                        }
                    } else {
                        if(userMap.get(itemOld.InvoiceBillingLevel5Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                            userMap.get(itemOld.InvoiceBillingLevel5Approver__c).Name);
                        }
                        if(userMap.get(itemOld.Level3Approver__c) != null) {
                           mail.addParameter('New_Approver',
                            userMap.get(itemOld.Level3Approver__c).Name);
                        }
                    }
                } else {

                    if (item.Level4Approver__c != null && userMap.get(itemOld.Level4Approver__c) != null) {
                        mail.addParameter('Previous_Approver',
                            userMap.get(itemOld.Level4Approver__c).Name);
                    }
                    mail.addParameter('New_Approver', 'Invoice Approval Queue');
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L7_APPROVAL) {
                if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                    if (item.Sign_Up_Purchase_Limit__c > 750000) {
                        if (item.Level3Approver__c != null && userMap.get(itemOld.Level3Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level3Approver__c).Name);
                        }
                        if (item.Level4Approver__c != null && userMap.get(itemOld.Level4Approver__c) != null) {
                            mail.addParameter('New_Approver',
                                userMap.get(itemOld.Level4Approver__c).Name);
                        }
                    } else {
                        if (item.Level4Approver__c != null && userMap.get(itemOld.Level4Approver__c) != null) {
                            mail.addParameter('Previous_Approver',
                                userMap.get(itemOld.Level4Approver__c).Name);
                        }
                        mail.addParameter('New_Approver','Invoice Approval Queue');
                    }
                }
            }

            if (item.Status__c == ApprovalHelper.STATUS_PENDING_L8_APPROVAL) {
                if (item.InvoiceApprovalType__c.StartsWith('MonthlyCreditLessThan500')) {

                    if (item.Level4Approver__c != null && userMap.get(itemOld.Level4Approver__c) != null) {
                        mail.addParameter('Previous_Approver',
                            userMap.get(itemOld.Level4Approver__c).Name);
                    }
                    mail.addParameter('New_Approver', 'Invoice Approval Queue');
                }
            }

            return mail;
        }

        private String hideMCL(Boolean condition) {
            return condition ? 'display:none;' : '';
        }

        private void setMultiProductParametrs(ApprovalHelperCls.InternalEmail mail, Approval__c item) {
            String hideMCL = hideMCL(item.Monthly_Credit_Limit_Office__c >= 0);
            String hideMCL_MVP = hideMCL(item.Monthly_Credit_Limit_Office__c < 0);
            String hideMCL_CC = hideMCL(item.Monthly_Credit_Limit_Contact_Center__c < 0);
            String hideMCL_EV = hideMCL(item.Monthly_Credit_Limit_Engage_Voice__c < 0);
            String hideMCL_ED = hideMCL(item.Monthly_Credit_Limit_Engage_Digital__c < 0);
            String hideMCL_PS = hideMCL(item.MonthlyCreditLimitProServ__c < 0);

            mail.addParameter('Monthly_CL_Office', item.Monthly_Credit_Limit_Office__c);
            mail.addParameter('Monthly_CL_Contact_Center', item.Monthly_Credit_Limit_Contact_Center__c);
            mail.addParameter('Monthly_CL_Engage_Voice', item.Monthly_Credit_Limit_Engage_Voice__c);
            mail.addParameter('Monthly_CL_Engage_Digital', item.Monthly_Credit_Limit_Engage_Digital__c);
            mail.addParameter('Monthly_CL_Professional_Services', item.MonthlyCreditLimitProServ__c);
            mail.addParameter('hideMCL', hideMCL);
            mail.addParameter('hideMCL_MVP', hideMCL_MVP);
            mail.addParameter('hideMCL_CC', hideMCL_CC);
            mail.addParameter('hideMCL_EV', hideMCL_EV);
            mail.addParameter('hideMCL_ED', hideMCL_ED);
            mail.addParameter('hideMCL_PS', hideMCL_PS);
        }

        public ApprovalHelperCls.InternalEmail buildApprovedEmail(EmailTemplate template, Approval__c item, String accountName) {

            if (template == null || item == null) {
                return null;
            }

            if(invoiceRequestIds?.size() > 0 && invoiceRequestIds.contains(item.Id) && item.Status__c == ApprovalHelper.STATUS_APPROVED && String.isBlank(item.Initial_Order_Form_Contract_Link__c)){
                item.addError(System.label.InvoiceInitialOrderForm);
            }

            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(
                item.OwnerId,
                template.Subject,
                template.HtmlValue
            );

            mail.addParameter('Monthly_CL', item.Monthly_Credit_Limit__c);
            mail.addParameter('Potential_Users', item.Potential_Users__c);
            mail.addParameter('ApprovalRequest.External_URL', BASE_URL + '/' + item.Id);
            mail.addParameter('Account.Name', accountName);

            setMultiProductParametrs(mail, item);

            return mail;
        }

        public ApprovalHelperCls.InternalEmail buildRejectedEmail(
            EmailTemplate template,
            Approval__c item,
            String accountName,
            ProcessInstance approvalProcessInstance
        ) {

            if (template == null || item == null) {
                return null;
            }
            Set<Id> rejectEmailRecipientSet = new Set<Id>{ item.OwnerId };

            if (!Test.isRunningTest() && approvalProcessInstance != null && approvalProcessInstance.StepsAndWorkitems.size() > 0 &&
                approvalProcessInstance.StepsAndWorkitems[0].StepStatus != D_B_Credit_CheckTriggerHandler.DNBI_PENDING) {
                rejectEmailRecipientSet.add(approvalProcessInstance.StepsAndWorkitems[0].ActorId);
            } else {
                rejectEmailRecipientSet.add(UserInfo.getUserId());
            }
            List<Id> rejectEmailRecipients = new List<Id>(rejectEmailRecipientSet);
            ApprovalHelperCls.InternalEmail mail = new ApprovalHelperCls.InternalEmail(
                rejectEmailRecipients,
                template.Subject,
                template.HtmlValue
            );

            mail.addParameter('Actual_Approver', UserInfo.getName());
            mail.addParameter('Monthly_CL', item.Monthly_Credit_Limit__c);
            mail.addParameter('Potential_Users', item.Potential_Users__c);
            mail.addParameter('ApprovalRequest.External_URL', BASE_URL + '/' + item.Id);
            mail.addParameter('Account.Name', accountName);

            setMultiProductParametrs(mail, item);

            return mail;
        }
    }

    public class ValidateAccountBillingAddress extends Triggers.TriggerHandlerBase {

        private final List<Id> recordTypeIdsToProcess = new List<Id>{
            ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST,
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
        };

        override public void handle() {

            List<Approval__c> approvalsToProcess = new List<Approval__c>();

            for (Approval__c item : (List<Approval__c>) Trigger.new) {
                Boolean isRecordApplicableForProcessing = recordTypeIdsToProcess.contains(item.RecordTypeId)
                    && isChangedFieldTo(item, Approval__c.Status__c, ApprovalHelper.STATUS_PENDING_L1_APPROVAL);

                if (isRecordApplicableForProcessing) {
                    approvalsToProcess.add(item);
                }
            }

            validateBillingAddress(approvalsToProcess);
        }

        private void validateBillingAddress(List<Approval__c> approvalList) {
            if (approvalList == null || approvalList.isEmpty()) {
                return;
            }

            Map<Id, Account> accountMap = ApprovalHelper.getAccountMap(approvalList);

            for (Approval__c item : approvalList) {
                Account acc = accountMap.get(item.Account__c);
                Boolean isAddressFieldsEmpty = AccountHelper.isBillingAddressEmpty(acc);
                if (isAddressFieldsEmpty) {
                    item.addError(Label.BillingAddressEmptyOnApprovalUpdate);
                }
            }
        }
    }

    public class PopulateCompanyInfo extends Triggers.TriggerHandlerBase {

        private final List<Id> recordTypeIdsToProcess = new List<Id>{
            ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST,
            ApprovalHelper.RT_ID_INVOICING_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_ON_BEHALF_REQUEST,
            ApprovalHelper.RT_ID_INVOICE_WHOLESALE_REQUEST
        };

        override public void handle() {
            List<Approval__c> approvalsToProcess = new List<Approval__c>();

            for (Approval__c item : (List<Approval__c>) Trigger.new) {
                Boolean isRecordApplicableForProcessing = recordTypeIdsToProcess.contains(item.RecordTypeId);
                if (isRecordApplicableForProcessing) {
                    approvalsToProcess.add(item);
                }
            }

            fillCompanyInfo(approvalsToProcess);
        }

        private void fillCompanyInfo(List<Approval__c> approvalList) {

            if (approvalList == null || approvalList.isEmpty()) {
                return;
            }

            Map<Id, Account> accountMap = ApprovalHelper.getAccountMap(approvalList);

            for (Approval__c item : approvalList) {
                if (!accountMap.containsKey(item.Account__c)) {
                    continue;
                }
                Account acc = accountMap.get(item.Account__c);

                item.Company_Phone_Number__c = acc.AH_Name__r.AH_Phone__c;
                item.Company_DUNS_Number__c = acc.AH_Name__r.D_U_N_S_Number__c;
                item.Company_Website__c = acc.AH_Name__r.AH_Website__c;
            }
        }
    }

    public class PopulatePaymentMethod extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Approval__c ap : (List<Approval__c>) Trigger.new) {
                String pMethod = ApprovalHelper.RT_ID_TO_PAYMENT_METHOD_MAP.get(ap.RecordTypeId);
                if (pMethod != null) {
                    ap.Payment_Method__c = pMethod;
                }
                if (ap.RecordTypeId == ApprovalHelperCls.RT_ID_REFUND_APPROVAL) {
                    ap.Payment_Method__c = ApprovalHelperCls.accountStaticMap.get(ap.Account__c)?.Account_Payment_Method__c;
                }
            }
        }
    }

    public class ValidateKycApproval extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    accIds.Add(app.Account__c);
                }
            }
            if (accIds.isEmpty()) {
                return;
            }

            Map<Id, Account> accsMap = new Map<Id, Account>(
                (List<Account>) new AccountSelector()
                    /* Currently inserted KYC approvals must be excluded from query result */
                    .selectAccountWithKYCApprovals(new List<Object>{accIds})
                    .executeQuery()
            );
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                List<Approval__c> accountKYCApprovals = accsMap.get(app.Account__c).Approvals__r;
                if (!accountKYCApprovals.isEmpty() && accountKYCApprovals[0].Status__c == ApprovalHelper.STATUS_PENDING_APPROVAL) {
                    app.addError(Label.KycApprovalCreationError);
                }
            }
        }
    }

    public class SubmitKycApproval extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> approvals = new List<Approval__c>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    approvals.Add(app);
                }
            }
            if (!approvals.isEmpty()) {
                ApprovalHelper.submitKYCApprovals(approvals);
            }
        }
    }

    public class CreateKycDocuments extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Document__c> kycDocuments = new List<Document__c>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId != ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    continue;
                }

                Set<String> documentTypes = new Set<String>{
                    DocumentKYCHelper.TYPE_PHOTOID,
                    DocumentKYCHelper.TYPE_AUTHORISATION_LETTER,
                    DocumentKYCHelper.TYPE_IDENTITY_DOCUMENT
                };
                for (String type: documentTypes) {
                    kycDocuments.add(new Document__c(Approval__c = app.Id, Type__c = type));
                }
            }
            if (!kycDocuments.isEmpty()) {
                insert kycDocuments;
            }
        }
    }

    // https://jira.ringcentral.com/browse/PBC-5370
    // Reject tax exemption approval if new KYC approval was approved and has differences with approval approved before
    public class RejectTaxExemptionApproval extends Triggers.TriggerHandlerBase {

        override public void handle() {
            List<Id> accIds = new List<Id>();
            Set<Id> excludeApprovalId = new Set<Id>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST &&
                        app.Status__c == ApprovalHelper.STATUS_APPROVED && app.Account__c != null) {
                    if (isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)) {
                        accIds.add(app.Account__c);
                        excludeApprovalId.add(app.Id);
                    }
                }
            }
            if (accIds.isEmpty()) {
                return;
            }
            List<Approval__c> taxExemptions = (List<Approval__c>) new ApprovalSelector()
                    .selectNotRejectedTaxExemptionApprovalsForAccount(new List<Object>{
                            accIds,
                            new List<String>{ ApprovalHelper.STATUS_REJECTED }, excludeApprovalId
                    })
                    .executeQuery();

            if (taxExemptions.isEmpty()) {
                return;
            }
            Map<Id, Set<Id>> taxExemptionApprovalId = new Map<Id, Set<Id>>();
            Map<Id, List<Approval__c>> kycApprovalByAccountId = new Map<Id, List<Approval__c>>();
            List<Id> rejectApprovalIds = new List<Id>();
            Set<Id> rejectApprovalByAccountIds = new Set<Id>();

            for (Approval__c approvalNeedRejected : taxExemptions) {
                if (approvalNeedRejected.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST &&
                        approvalNeedRejected.Status__c == ApprovalHelper.STATUS_APPROVED) {
                    if (!kycApprovalByAccountId.containsKey(approvalNeedRejected.Account__c)) {
                        kycApprovalByAccountId.put(approvalNeedRejected.Account__c, new List<Approval__c>{approvalNeedRejected});
                    } else {
                        kycApprovalByAccountId.get(approvalNeedRejected.Account__c).add(approvalNeedRejected);
                    }
                }
                if (approvalNeedRejected.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
                    if (!taxExemptionApprovalId.containsKey(approvalNeedRejected.Account__c)) {
                        taxExemptionApprovalId.put(approvalNeedRejected.Account__c, new Set<Id>{approvalNeedRejected.Id});
                    } else {
                        taxExemptionApprovalId.get(approvalNeedRejected.Account__c).add(approvalNeedRejected.Id);
                    }
                }
            }

            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (!kycApprovalByAccountId.containsKey(app.Account__c)) {
                    continue;
                }
                Approval__c lastApproved = kycApprovalByAccountId.get(app.Account__c)[0];
                if (lastApproved != null && lastApproved.Id != app.Id && (app.GstNo__c != lastApproved.GstNo__c || app.KycFiles__c != lastApproved.KycFiles__c)) {
                    rejectApprovalByAccountIds.add(lastApproved.Account__c);
                }
            }

            for (Id rejectAccId : rejectApprovalByAccountIds) {
                if (taxExemptionApprovalId.containsKey(rejectAccId)) {
                    rejectApprovalIds.addAll(taxExemptionApprovalId.get(rejectAccId));
                }
            }
            if (!rejectApprovalIds.isEmpty()) {
                TaxExemptionHelper.completeApproval(rejectApprovalIds, true);
            }
        }
    }

    public class CopyKycApprovalEntities extends Triggers.TriggerHandlerBase {
        override public void handle() {
            /* Map [Account Id => New Approval Id] */
            Map<Id, Id> accIdsToNewKycId = new Map<Id, Id>();
            for (Approval__c approval : (List<Approval__c>) Trigger.new) {
                if (approval.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    accIdsToNewKycId.put(approval.Account__c, approval.Id);
                }
            }
            if (accIdsToNewKycId.isEmpty()) {
                return;
            }
            /* Map [Source Approval Id => Account Id] */
            Map<Id, Id> sourceApprovedKycIdsToAccIds = getSourceApprovedKYCIdsToAccountsIdsMap(
                accIdsToNewKycId.keySet(),
                Trigger.newMap.keySet()
            );
            if (sourceApprovedKycIdsToAccIds.isEmpty()) {
                return;
            }
            /*
                Copy Local Subscribed Addresses Fields
            */
            List<LocalSubscribedAddress__c> addresses = (List<LocalSubscribedAddress__c>) new LocalSubscribedAddressSelector()
                .selectLocalSubscribedAddressByApprovalId(new List<Set<Id>>{sourceApprovedKycIdsToAccIds.keySet()})
                .executeQuery();
            /* Map [Source LS Address Id => New LS Address] */
            Map<Id, LocalSubscribedAddress__c> sourceAddrIdsToNewAddr = new Map<Id, LocalSubscribedAddress__c>();
            for (LocalSubscribedAddress__c address: addresses) {
                if (address.RecordTypeId != LocalSubscribedAddressHelper.RT_ID_BILLING_ADDRESS) {
                    LocalSubscribedAddress__c newAddress = address.clone(false, false, true, false);
                    newAddress.Approval__c = accIdsToNewKycId.get(sourceApprovedKycIdsToAccIds.get(address.Approval__c));
                    sourceAddrIdsToNewAddr.put(address.Id, newAddress);
                }
            }
            insert sourceAddrIdsToNewAddr.values();
            /*
                Copy Docs Fields
            */
            Map<Id, List<Document__c>> newApprovalToDocumentsList = new Map<Id, List<Document__c>>();
            Map<Id, Document__c> sourceDocuments = new Map<Id, Document__c>();
            selectSourceAndNewDocuments(new List<Id>(sourceApprovedKycIdsToAccIds.keySet()), accIdsToNewKycId.values(), sourceDocuments, newApprovalToDocumentsList);
            List<Document__c> newDocs = new List<Document__c>();
            for (Document__c sourceDoc: sourceDocuments.values()) {
                Id newApprovalId = accIdsToNewKycId.get(sourceApprovedKycIdsToAccIds.get(sourceDoc.Approval__c));
                List<Document__c> newApprovalDocs = newApprovalToDocumentsList.get(newApprovalId);
                for (Document__c doc: newApprovalDocs) {
                    if (doc.Type__c == sourceDoc.Type__c) {
                        Document__c newDoc = sourceDoc.clone(false, false, true, false);
                        newDoc.Approval__c = newApprovalId;
                        newDoc.Id = doc.Id;
                        newDocs.add(newDoc);
                        break;
                    }
                }
            }
            update newDocs;

            Set<Id> entitiesIds = new Set<Id>();
            entitiesIds.addAll(sourceApprovedKycIdsToAccIds.keySet());
            entitiesIds.addAll(sourceAddrIdsToNewAddr.keySet());
            entitiesIds.addAll(sourceDocuments.keySet());
            /*
                Copy Files
            */
            List<ContentDocumentLink> cdLinks = new ContentDocumentLinkSelector()
                .selectLinksByLinkedEntityId(entitiesIds)
                .executeQuery();
            List<ContentDocumentLink> newContentDocumentLinks = new List<ContentDocumentLink>();
            for (ContentDocumentLink cdLink: cdLinks) {
                ContentDocumentLink newCdLink = cdLink.clone(false, false, true, true);
                if (sourceApprovedKycIdsToAccIds.containsKey(cdLink.LinkedEntityId)) {
                    newCdLink.LinkedEntityId = accIdsToNewKycId.get(sourceApprovedKycIdsToAccIds.get(cdLink.LinkedEntityId));
                } else if (sourceAddrIdsToNewAddr.containsKey(cdLink.LinkedEntityId)) {
                    newCdLink.LinkedEntityId = sourceAddrIdsToNewAddr.get(cdLink.LinkedEntityId).Id;
                } else {
                    Document__c sourceDoc = sourceDocuments.get(cdLink.LinkedEntityId);
                    Id newApprovalId = accIdsToNewKycId.get(sourceApprovedKycIdsToAccIds.get(sourceDoc?.Approval__c));
                    List<Document__c> newApprovalDocs = newApprovalToDocumentsList.get(newApprovalId);
                    for (Document__c doc: newApprovalDocs) {
                        if (doc.Type__c == sourceDocuments.get(cdLink.LinkedEntityId)?.Type__c) {
                            newCdLink.LinkedEntityId = doc.Id;
                            break;
                        }
                    }
                }
                newContentDocumentLinks.add(newCdLink);
            }
            insert newContentDocumentLinks;
        }

        private Map<Id, Id> getSourceApprovedKYCIdsToAccountsIdsMap(Set<Id> accounts, Set<Id> insertedApprovalsIds) {
            List<Account> accsWithKYCApprs = new AccountSelector()
                /* Currently updated KYC approvals must be excluded from query result */
                .selectAccountsWithOrderedKYCApprovalsExcludingApprovalRecords(accounts, insertedApprovalsIds)
                .executeQuery();
            /* Map [Source Approved Approval Id => Account Id] */
            Map<Id, Id> kycApprovalIdsToAccountIds = new Map<Id, Id>();
            for (Account acc : accsWithKYCApprs) {
                try {
                    if (acc.Approvals__r.get(0).Status__c == ApprovalHelper.STATUS_APPROVED) {
                        kycApprovalIdsToAccountIds.put(acc.Approvals__r.get(0).Id, acc.Id);
                    }
                } catch (Exception e) {
                    continue;
                }
            }
            return kycApprovalIdsToAccountIds;
        }

        private void selectSourceAndNewDocuments(List<Id> sourceApprovals, List<Id> newApprovals, Map<Id, Document__c> sourceDocsIds, Map<Id, List<Document__c>> newApprovalIdToDoc) {
            List<Id> approvalsIds = new List<Id>();
            approvalsIds.addAll(sourceApprovals);
            approvalsIds.addAll(newApprovals);
            List<Document__c> documents = (List<Document__c>) new DocumentKYCSelector()
                .selectDocumentsByApprovalId(new List<Object>{approvalsIds})
                .executeQuery();
            for (Document__c doc : documents) {
                if (newApprovals.contains(doc.Approval__c)) {
                    if (newApprovalIdToDoc.containsKey(doc.Approval__c)) {
                        List<Document__c> apprDocs = newApprovalIdToDoc.get(doc.Approval__c);
                        apprDocs.add(doc);
                    } else {
                        newApprovalIdToDoc.put(doc.Approval__c, new List<Document__c>{doc});
                    }
                } else {
                    sourceDocsIds.put(doc.Id, doc);
                }
            }
        }
    }

    public class PopulateVatNumberOnAccountByGstNumber extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> approvedKycApprs = new List<Approval__c>();
            for (Approval__c appr: (List<Approval__c>) Trigger.new) {
                if (appr.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                    && super.isChangedFieldTo(appr, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED))
                {
                    approvedKycApprs.add(appr);
                }
            }
            if (approvedKycApprs.isEmpty()) {
                return;
            }
            List<Account> accounts = new List<Account>();
            for (Approval__c appr: approvedKycApprs) {
                if (appr.GstNo__c != null) {
                    accounts.add(new Account(Id = appr.Account__c, VATNumber__c = appr.GstNo__c));
                }
            }
            TaxExemptionHelper.notCheckVATNumber = true;
            update accounts;
        }
    }

    public class ApproveIndiaTaxExemptionApproval extends Triggers.TriggerHandlerBase {

        override public void handle() {
            List<Approval__c> approvals = new List<Approval__c>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL &&
                    app.Status__c == ApprovalHelper.STATUS_NEW &&
                    app.SEZWOPExemption__c == ApprovalHelper.STATUS_REQUESTED) {
                    approvals.add(app);
                }
            }
            if (!approvals.isEmpty()) {
                TaxExemptionHelper.submitForTaxExemptionApproval(approvals);
            }
        }
    }

    public class ValidateKYCApprovalOnApprove extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> kycApprovalsIds = new Set<Id>();
            Map<Id, LocalSubscribedAddress__c> approvalIdToRegisteredAddresssMap;
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    kycApprovalsIds.add(app.Id);
                }
            }
            if (!kycApprovalsIds.isEmpty()) {
                approvalIdToRegisteredAddresssMap =
                LocalSubscribedAddressHelper.getApprovalLocalSubscribedAddressesMap(
                    LocalSubscribedAddressHelper.RT_ID_REGISTERED_ADDRESS_OF_COMPANY,
                    kycApprovalsIds
                );
            }
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                Boolean isApprovedKYCApproval = app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                    && isChangedFieldFrom(app, Approval__c.Status__c, ApprovalHelper.STATUS_PENDING_APPROVAL)
                    && isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED);
                if (isApprovedKYCApproval) {
                    String missedAttachmentsErrorText = ApprovalHelper.getMissedAttachmentErrorText(app);
                    if (
                        app.NameOfTheAuthorisedSignatory__c == null
                        || app.NameOfFatherOrHusband__c == null
                        || app.GenderOfAuthorisedSignatory__c == null
                        || app.DateOfBirthOfAuthorisedSignatory__c == null
                        || app.NationalityOfAuthorisedSignatory__c == null
                        || app.PanGirNo__c == null
                        || app.HouseNo__c == null
                        || app.StreetAddress__c == null
                        || app.Area__c == null
                        || app.City__c == null
                        || app.District__c == null
                        || app.State__c == null
                        || app.PinCode__c == null
                    ) {
                        app.addError(Label.ApprovalKycRequiredFieldsNotPopulated);
                    } else if (String.isBlank(app.PurposeForProcuringTheService__c) && String.isBlank(app.Other__c)) {
                        app.addError(Label.ApprovalErrorPurposeOfProcuringServiceIsEmpty);
                    } else if (approvalIdToRegisteredAddresssMap.get(app.Id) == null) {
                        app.addError(Label.ApprovalErrorRegisteredAddressNotCreated);
                    } else if (String.isBlank(app.GstNo__c)) {
                        app.addError(Label.ApprovalErrorGSTNoIsEmpty);
                    } else if (!String.isBlank(missedAttachmentsErrorText)) {
                        app.addError(missedAttachmentsErrorText);
                    }
                }
            }
        }
    }

    public class PublishEventAfterKycStatusChanging extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<KYC_Approval_Status_Update__e> events = new List<KYC_Approval_Status_Update__e>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                    && (isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                        || isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_REJECTED))
                    ) {
                    events.add(new KYC_Approval_Status_Update__e(Approval__c = app.Id));
                }
            }
            if (!events.isEmpty()) {
                PlatformEvents.publishPlatformEvent(events, 'Approval.trigger after update');
            }
        }
    }

    public class UpdateBillingAddressFromKYCApproval extends Triggers.TriggerHandlerBase {
        private final Map<String, String> BILLING_ADDRESS_FIELDS_MAP = new Map<String, String>{
            'StreetAddress__c' => 'BillingStreet',
            'City__c' =>  'BillingCity',
            'State__c' => 'BillingState',
            'District__c' => 'BillingCountry',
            'PinCode__c' => 'BillingPostalCode'
        };

        override public void handle() {
            Map<Id, Id> apprIdToAccIdMap = new Map<Id, Id>();
            for (Approval__c approval : (List<Approval__c>) Trigger.new) {
                if (approval.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                    && isChangedFieldTo(approval, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)
                ) {
                    apprIdToAccIdMap.put(approval.Id, approval.Account__c);
                }
            }

            Map<Id, Account> accountsForApprovals = new Map<Id, Account>(
                (List<Account>) new AccountSelector()
                    .selectBillingAccountsForKYCApproval(new List<Object>{apprIdToAccIdMap.values()})
                    .executeQuery()
            );
            List<Account> accountsToSync = new List<Account>();
            List<LocalSubscribedAddress__c> localSubscribedAddresses = (List<LocalSubscribedAddress__c>) new LocalSubscribedAddressSelector()
                .selectLocalSubscribedAddressesBillingAddressByApprovals(new List<Object>{apprIdToAccIdMap.keySet()})
                .executeQuery();
            /* Populate Account billing address by new values from LSA */
            for (LocalSubscribedAddress__c lsa: localSubscribedAddresses) {
                Account acc = accountsForApprovals.get(apprIdToAccIdMap.get(lsa.Approval__c));
                Boolean isAddressChanged = false;
                for (String lsaField: BILLING_ADDRESS_FIELDS_MAP.keySet()) {
                    isAddressChanged |= acc.get(BILLING_ADDRESS_FIELDS_MAP.get(lsaField)) != lsa.get(lsaField);
                    acc.put(BILLING_ADDRESS_FIELDS_MAP.get(lsaField), lsa.get(lsaField));
                }
                if (isAddressChanged) {
                    acc.ConfirmTaxExemptionRemoval__c = true;
                    accountsToSync.add(acc);
                }
            }

            if (!accountsToSync.isEmpty()) {
                QueueableBase.enqueJob('AccountUpdateBillingAddressNGBSSync', accountsToSync);
            }
        }
    }

    public class CreateBillingAddressLsaForKycApproval extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            List<Approval__c> approvalToProcess = new List<Approval__c>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST) {
                    approvalToProcess.Add(app);
                    accIds.Add(app.Account__c);
                }
            }
            if (approvalToProcess.isEmpty()) {
                return;
            }
            Map<Id, Account> accountsMap = new Map<Id, Account> ((List<Account>) new AccountSelector()
                    .selectAccountWithKYCApprovals(new List<Object>{accIds})
                    .executeQuery());
            if (!accountsMap.isEmpty()) {
                List<LocalSubscribedAddress__c> lsaToInsert = new List<LocalSubscribedAddress__c>();
                for (Approval__c app : approvalToProcess) {
                    Account acc = accountsMap.get(app.Account__c);
                    lsaToInsert.add(LocalSubscribedAddressHelper.createBillingAddress(acc, app));
                }
                insert lsaToInsert;
            }
        }
    }

    public class PopulateApprovalContactEmail extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Set<Id> contIds = new Set<Id>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL && app.Contact__c != null) {
                    contIds.add(app.Contact__c);
                }
            }
            if (contIds.isEmpty()) {
                return;
            }
            Map<Id,Contact> contacts = new Map<Id, Contact>((List<Contact>)new ContactSelector()
                    .selectContactsForApproval(new List<Object>{contIds})
                    .executeQuery());

            if (!contacts.isEmpty() && contacts != null) {
                for (Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (contacts.containsKey(app.Contact__c)) {
                        Contact cont = contacts.get(app.Contact__c);
                        if (app.Contact_Email__c != cont.Email ||
                            app.Contact_Full_Name__c != cont.FirstName + ' ' + cont.LastName) {
                            app.Contact_Email__c = cont.Email;
                            app.Contact_Full_Name__c = cont.FirstName + ' ' + cont.LastName;
                        }
                    }
                }
            }
        }
    }

    public class PopulateStatusLastModifiedDate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Approval__c appr : (List<Approval__c>) Trigger.new) {
                if (isChangedField(appr, Approval__c.Status__c)) {
                    appr.StatusLastModifiedDate__c = System.now();
                }
            }
        }
    }

    public class ValidateCreationOnTechAccount extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
            Boolean isAdmin = AquivaHelper.isAdmin();
            User technicalUser = UserHelper.getMultiproductTechnicalUser();
            for (Approval__c app : (List<Approval__c>)Trigger.new) {
                accIds.add(app.Account__c);
            }

            if (accIds.isEmpty()) {
                return;
            }

            Map<Id, Account> linkedAccounts = new Map<Id, Account>((List<Account>) new AccountSelector()
                .selectAccsForTechApprovalValidation(new List<Object>{accIds})
                .executeQuery());

            if (linkedAccounts.isEmpty()) {
                return;
            }

            for (Approval__c app : (List<Approval__c>)Trigger.new) {
                if (((technicalUser != null && app.OwnerId != technicalUser.Id) || !app.IsMultiProductTechnicalApproval__c)
                    && linkedAccounts.get(app.Account__c)?.IsMultiProductTechnicalAccount__c == true
                    && !isAdmin) {
                    app.addError(ApprovalHelper.APPROVAL_CREATION_ON_TECH_ACC_ERROR);
                }
            }
        }
    }

    public class IncreaseSpendingLimitAfterApproved extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Id> apps = new List<Id>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE
                    && isChangedFieldTo(app, Approval__c.Status__c, ApprovalHelper.STATUS_APPROVED)) {
                    apps.add(app.Id);
                }
            }
            if (!apps.isEmpty()) {
                QueueableBase.enqueJob('CreditSpendingLimitNGBSSync', apps);
            }
        }
    }

    public class ResubmitCreditLimitApproval extends Triggers.TriggerHandlerBase {

        override public void handle() {
            Set<Id> resubmitApprovalIds = new Set<Id>();
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (
                        app.RecordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE &&
                        isChangedField(app, Approval__c.NGBSAmountToIncrease__c) &&
                        app.NGBSAmountToIncrease__c != null &&
                        app.Status__c == ApprovalHelper.STATUS_PENDING_APPROVAL
                ) {
                    Approval__c oldApp = (Approval__c)Trigger.oldMap.get(app.Id);
                    if (oldApp.NGBSAmountToIncrease__c != null && oldApp.NGBSAmountToIncrease__c < app.NGBSAmountToIncrease__c) {
                        resubmitApprovalIds.add(app.Id);
                    }
                }
            }

            ApprovalHelper.resubmitCreditLimitApprovals(resubmitApprovalIds);
        }
    }

    public class ValidateApprovalsCreditLimitIncrease extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Approval__c> approvals = new List<Approval__c>();
            List<Id> accountIds = new List<Id>();
            Map<Id, Map<Id, Id>> oppByAccountIdMap = new Map<Id, Map<Id, Id>>();
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            if (Trigger.isInsert && Trigger.isBefore) {
                for (Approval__c app : (List<Approval__c>) Trigger.new) {
                    if (app.RecordTypeId == ApprovalHelper.RT_ID_CREDIT_LIMIT_INCREASE && app.Account__c != null) {
                        if (app.Option__c == 'Manual') {
                            app.Opportunity__c = null;
                            app.Quote__c = null;
                        }
                        approvals.add(app);
                        accountIds.add(app.Account__c);
                    }
                }

                if (!approvals.isEmpty()) {
                    for (List<Opportunity> opportunities : [SELECT Id, AccountId, (SELECT Id FROM Quotes WHERE isPrimary__c = TRUE), isOrderStepCompleted__c, isUpsellStepCompleted__c, StageName FROM Opportunity WHERE AccountId IN :accountIds AND StageName= :OpportunityHelper.STAGE_NAME_CLOSED_WON]) {
                        for (Opportunity opp : opportunities) {
                           if(!opp.Quotes.isEmpty() && opp.Quotes != null)
                            {
                                Map<Id, Id> quoteIdByAccountIdMap = new Map<Id, Id>();
                            		quoteIdByAccountIdMap.put(opp.AccountId, opp.Quotes[0].Id);
                            		oppByAccountIdMap.put(opp.Id, quoteIdByAccountIdMap);
                            		oppMap.put(opp.Id, opp);

                            }

                        }
                    }
                    if (!oppByAccountIdMap.isEmpty() && !approvals.isEmpty()) {
                        for (Approval__c app : approvals) {
                            if (app.Option__c != 'Manual') {
                                if (app.Opportunity__c != null && oppMap.containsKey(app.Opportunity__c)) {
                                    Opportunity opp = oppMap.get(app.Opportunity__c);
                                    if (opp.StageName == OpportunityHelper.STAGE_NAME_CLOSED_WON && (opp.isOrderStepCompleted__c || opp.isUpsellStepCompleted__c)) {
                                        app.addError('This opportunity has already been synced');
                                    }
                                }
                                if (app.Opportunity__c != null && app.Quote__c != null && oppByAccountIdMap.containsKey(app.Opportunity__c)) {
                                    Map<Id, Id> relateIds = oppByAccountIdMap.get(app.Opportunity__c);
                                    if (!relateIds.containsKey(app.Account__c)) {
                                        app.addError('There is no opportunity in this approval. Choose the right opportunity.');
                                    } else if (relateIds.containsKey(app.Account__c)) {
                                        Id quoteId = relateIds.get(app.Account__c);
                                        if (app.Quote__c != quoteId) {
                                            app.addError('There is no quote in this approval. Choose the correct opportunity and quote.');
                                        }
                                    }
                                } else {
                                    app.addError('Opportunity and quote must be added.');
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public class RecalculateApprovalsMonthlyAndSignUpLimits extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for (Approval__c app : (List<Approval__c>) Trigger.new) {
                if (app.RecordTypeId != ApprovalHelper.RT_ID_INVOICING_REQUEST) {
                    continue;
                }
                if (app.Sign_Up_Purchase_Limit_Office__c > 0
                    || app.Sign_Up_Purchase_Limit_Contact_Center__c > 0
                    || app.Sign_Up_Purchase_Limit_Engage_Voice__c > 0
                    || app.Sign_Up_Purchase_Limit_Engage_Digital__c > 0
                    || app.SignUpPurchaseLimitProServ__c > 0
                    || app.Sign_Up_Purchase_Limit_for_RC_Events__c > 0
                ) {
                    app.Sign_Up_Purchase_Limit__c = 0;
                    app.Sign_Up_Purchase_Limit__c = addPositiveNumber(app.Sign_Up_Purchase_Limit__c, app.Sign_Up_Purchase_Limit_Office__c);
                    app.Sign_Up_Purchase_Limit__c = addPositiveNumber(app.Sign_Up_Purchase_Limit__c, app.Sign_Up_Purchase_Limit_Contact_Center__c);
                    app.Sign_Up_Purchase_Limit__c = addPositiveNumber(app.Sign_Up_Purchase_Limit__c, app.Sign_Up_Purchase_Limit_Engage_Voice__c);
                    app.Sign_Up_Purchase_Limit__c = addPositiveNumber(app.Sign_Up_Purchase_Limit__c, app.Sign_Up_Purchase_Limit_Engage_Digital__c);
                    app.Sign_Up_Purchase_Limit__c = addPositiveNumber(app.Sign_Up_Purchase_Limit__c, app.SignUpPurchaseLimitProServ__c);
                    app.Sign_Up_Purchase_Limit__c = addPositiveNumber(app.Sign_Up_Purchase_Limit__c, app.Sign_Up_Purchase_Limit_for_RC_Events__c);

                }
                if (app.Monthly_Credit_Limit_Office__c > 0
                    || app.Monthly_Credit_Limit_Contact_Center__c > 0
                    || app.Monthly_Credit_Limit_Engage_Voice__c > 0
                    || app.Monthly_Credit_Limit_Engage_Digital__c > 0
                    || app.MonthlyCreditLimitProServ__c > 0
                    || app.Monthly_Credit_Limit_for_RC_Events__c > 0
                ) {
                    app.Monthly_Credit_Limit__c = 0;
                    app.Monthly_Credit_Limit__c = addPositiveNumber(app.Monthly_Credit_Limit__c, app.Monthly_Credit_Limit_Office__c);
                    app.Monthly_Credit_Limit__c = addPositiveNumber(app.Monthly_Credit_Limit__c, app.Monthly_Credit_Limit_Contact_Center__c);
                    app.Monthly_Credit_Limit__c = addPositiveNumber(app.Monthly_Credit_Limit__c, app.Monthly_Credit_Limit_Engage_Voice__c);
                    app.Monthly_Credit_Limit__c = addPositiveNumber(app.Monthly_Credit_Limit__c, app.Monthly_Credit_Limit_Engage_Digital__c);
                    app.Monthly_Credit_Limit__c = addPositiveNumber(app.Monthly_Credit_Limit__c, app.MonthlyCreditLimitProServ__c);
                    app.Monthly_Credit_Limit__c = addPositiveNumber(app.Monthly_Credit_Limit__c, app.Monthly_Credit_Limit_for_RC_Events__c);
                }
            }
        }
        private Decimal addPositiveNumber(Decimal sum, Decimal num) {
            return num > 0 ? sum += num : sum;
        }
    }
}