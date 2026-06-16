public class ApprovalHelper {
    public static final String APPROVAL_OBJECT_NAME = 'Approval__c';

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

    // Refund_Product_Family_1__c, Refund_Product_Family_2__c, Refund_Product_Family_3__c,
    // Refund_Product_Family_4__c, Refund_Product_Family_5__c, Refund_Product_Family_6__c
    public static final String REFUND_FAMILY_RC_LEGACY = 'RC Legacy';
    public static final String REFUND_FAMILY_NGBS = 'NGBS';
    public static final String REFUND_FAMILY_CONTACT_CENTER = 'Contact Center';
    public static final String REFUND_FAMILY_PROSERV = 'ProServ';

    public static final String REFUND_FAMILY_NGBS_MVP = 'NGBS - MVP';
    public static final String REFUND_FAMILY_NGBS_CONTACT_CENTER = 'NGBS - Contact Center';
    public static final String REFUND_FAMILY_NGBS_E_VOICE = 'NGBS - Engage Voice';
    public static final String REFUND_FAMILY_NGBS_E_DIGITAL = 'NGBS - Engage Digital';

    public static Map<String, String> productFamilyToService {
        get {
            Map<String, String>  newProductFamilyToService = new Map<String, String>();
            if(productFamilyToService == null) {
                newProductFamilyToService = new Map<String, String> {
                    REFUND_FAMILY_NGBS_CONTACT_CENTER => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                    REFUND_FAMILY_NGBS_E_VOICE => OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE,
                    REFUND_FAMILY_NGBS_E_DIGITAL => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
                };
            }
            return newProductFamilyToService;
        }
        set;
    }

    public static final String INVOICING_REQUEST_DEFAULT_TERMS = '3';

    public static final Integer REFUND_CATEGORY_ID_DEFAULT = 39;
    public static final Integer REFUND_TYPE_ID_DEFAULT = 113;
    public static final String INVALID_REFUND_CATEGORY_MSG =
        'Could not find specified category in Refund_Categories__c custom setting. Category name: {0}';
    public static final String INVALID_REFUND_TYPE_MSG =
        'Could not find specified type in RefundCategoryAndTypeMapping__c custom setting. Category Id: {0}, Type name: {1}';


    // Status__c
    public static final String STATUS_RECALLED = 'Recalled';
    public static final String STATUS_REJECTED = 'Rejected';
    public static final String STATUS_REMOVED = 'Removed';
    public static final String STATUS_RETURNED = 'Returned';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_REQUIRED = 'Required';
    public static final String STATUS_LOST = 'Lost';
    public static final String STATUS_READY_FOR_SIGNATURE = 'Ready For Signature';
    public static final String STATUS_OUT_FOR_SIGNATURE = 'Out For Signature';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_PENDING_FINANCE_APPROVAL = 'Pending Finance Approval';
    public static final String STATUS_PENDING_DOWNSELL_APPROVAL = 'Pending Downsell Approval';
    public static final String STATUS_PENDING_APPROVAL = 'Pending Approval';
    public static final String STATUS_REQUESTED = 'Requested';
    public static final String STATUS_PENDING_L1_APPROVAL = 'PendingL1Approval';
    public static final String STATUS_PENDING_L2_APPROVAL = 'PendingL2Approval';
    public static final String STATUS_PENDING_L3_APPROVAL = 'PendingL3Approval';
    public static final String STATUS_PENDING_L4_APPROVAL = 'PendingL4Approval';
    public static final String STATUS_PENDING_L5_APPROVAL = 'PendingL5Approval';
    public static final String STATUS_PENDING_L6_APPROVAL = 'PendingL6Approval';
    public static final String STATUS_PENDING_L7_APPROVAL = 'PendingL7Approval';
    public static final String STATUS_PENDING_L8_APPROVAL = 'PendingL8Approval';
    public static final String STATUS_PENDING_PROSERV_APPROVAL = 'Pending ProServ Approval';

    public static final string APPROVAL_NON_PAYABLE_CONTACT_ERROR = 'Incorrect Contact is selected. Please select Accounts Payable Contact';
    public static final string APPROVAL_PARTNER_NON_PAYABLE_CONTACT_ERROR = 'Incorrect Contact is selected. Please select Partner\'s Accounts Payable Contact';
    public static final string APPROVAL_PARTNER_NOT_ACTIVE_ERROR = 'You cannot establish relationship with this Partner Account due to Partner\'s Account status';
    public static final string APPROVAL_PARTNER_NOT_CORRECT_BUSINESS_IDENTITY = 'Business Identity is different on Customer and Partner Accounts. Please choose Partner Account with same Business Identity';
    public static final string APPROVAL_PARTNER_IS_ACTIVE_ERROR = 'Account Partner Status is already \'Active\'';
    public static final string APPROVAL_PARTNER_NOT_COMPLETED_ERROR = 'Account cannot be activated. Partner approval is not approved.';
    public static final string APPROVAL_PARTNER_TAX_NOT_COMPLETED_ERROR = 'Account cannot be activated. Tax exemption approval is not approved.';

    public static final string INVOICE_REQUEST_NON_PAYABLE_CONTACT_ERROR = 'Incorrect Contact is selected. Please select Accounts Payable Contact';
    public static final string REFUND_APPROVAL_RECALL_ERROR = 'You can\'t Recall this Approval Record because some Transactions were already refunded.';
    public static final string REFUND_APPROVAL_REJECT_ERROR = 'You can\'t Reject this Approval Record because some Transactions were already refunded.';
    public static final string REFUND_APPROVAL_RETURN_ERROR = 'You can\'t Reject/Recall this Approval Record because some Transactions were already refunded.';
    public static final string REFUND_APPROVAL_COMPLETED_ERROR = 'Please Assign whole Refund Amount from this Approval Record to Transactions before Completing this Approval Record.';
    public static final string REFUND_APPROVAL_NEXT_LEVEL_ERROR = 'You haven\'t next Level Approver. Please contact your administrator.';
    public static final string REFUND_APPROVAL_PREVIOUS_LEVEL_ERROR = 'You haven\'t previous Level Approver. Please contact your administrator.';

    public static final string PARTNER_FINANCE_APPROVAL_STATUS_ERROR = 'Finance Revenue Approval is only available in "' + STATUS_PENDING_FINANCE_APPROVAL + '" status.';
    public static final string PARTNER_FINANCE_APPROVAL_DOCUMENTS_ERROR = 'The Final Contract is not added to Partner Approval.';
    public static final string PARTNER_FINANCE_APPROVAL_USER_ERROR = 'You don\'t have enough permissions to "Finance Revenue Approval".';

    public static final string TAX_EXEMPT_APPROVAL_STATUS_NOT_NEW_ERROR = 'Tax Exempt Approval can be created only in "New" status';
    public static final string TAX_EXEMPT_MASS_APPROVAL_NOT_SUPPORTED = 'Mass Approval is not supported for Tax Exemptions. Please process Tax Exempt Approvals one by one.';
    public static final string SECONDARY_DL_APPROVAL_UNIQUENESS_ERROR = 'Secondary DL approval already exists';
    public static final string APPROVAL_CREATION_ON_TECH_ACC_ERROR = 'Approval creation is not supported for technical accounts. Please select a Master account.';

    public static final String TREASURE_MANAGER_NAME = 'Lin Wang';

    public static final String DIRECTOR_BO = 'Director BO';
    public static final String TREASURE_MANAGER = 'Treasure Manager';
    public static final String TREASURER = 'Treasurer';
    public static final String CONTROLLER = 'Controller';
    public static final String INVOICE_CONTROLLER = 'Invoice Controller';
    public static final String SHIPPING_TEAM = 'Shipping';
    public static final String KYC_APPROVAL_APPROVED = 'Approved KYC Approval';

    // Approval Process
    public static final string PROCESS_QUOTE_APPROVAL_PROCESS_V2 = 'Quote_Approval_Process_V2';
    public static final string PROCESS_QUOTE_APPROVAL_PROCESS_V3 = 'Quote_Approval_Process_V3';
    public static final string PROCESS_QUOTE_APPROVAL_PROCESS_V4 = 'Quote_Approval_Process_V4';
    public static final string PROCESS_QUOTE_APPROVAL_PROCESS_JD = 'Quote_Approval_Process_NewApprovers';
    public static final string PROCESS_PHASE_COMPLETION_APPROVAL_PROCESS = 'Phase_Completion_Approval_Process';
    public static final string PROCESS_TAX_EXEMPTION_APPROVAL_PROCESS = 'Tax_Exempt_Approval_V2';
    public static final string PROCESS_INVOICE_REQUEST_APPROVAL = 'Invoice_Request_Approval_V13';
    public static final String PROCESS_KYC_APPROVAL_REQUEST_V1 = 'KYC_Approval_Request_V1';
    public static final String PROCESS_POC_ACCOUNT_APPROVAL_V4 = 'POC_Account_Approval_V4';
    public static final String PROCESS_CREDIT_LIMIT_APPROVAL = 'CreditLimitApprovalProcess_v4';
    public static final String PROCESS_QUOTE_APPROVAL_PROCESS_PRM = 'QuoteApprovalProcessPRM_V2';
    public static final String PROCESS_QUOTE_APPROVAL_PROCESS_WITH_PROSERV_V2 = 'Quote_Approval_Process_With_Proserv_V2';

    // Record Types and Approval Types
    public static final String RT_NAME_REFUND_APPROVAL = 'Refund Approval';
    public static final String RT_NAME_FARMING_CLAIM_OWNER = 'Farming Claim Owner';
    public static final String RT_NAME_FEATURE_ADD_ONS_APPROVAL = 'Feature Add-Ons';
    public static final String RT_NAME_BILLING_DATE_CHANGE_REQUEST_APPROVAL = 'Billing Date Change Request';
    public static final String RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL = 'Invoice-on-behalf Request';
    public static final String RT_NAME_INVOICE_WHOLESALE_REQUEST_APPROVAL = 'Invoice Wholesale Request';
    public static final String INVOICING_REQUEST_APPROVAL_RT_NAME = 'Invoicing Request';
    public static final String RT_NAME_CHANNEL_CROSS_SELL = 'Channel Cross Sell';
    public static final String RT_NAME_ENGAGE_LEGAL = 'Engage Legal';
    public static final String RT_NAME_MANUAL_REFUNDS = 'Manual Refunds';
    public static final String RT_NAME_TAX_EXEMPT_APPROVAL = 'Tax Exempt Approval';
    public static final String RT_NAME_RETENTION_REFUNDS = 'Retention Refunds';
    public static final String RT_NAME_POC_ACCOUNT = 'POC Account';
    public static final String RT_NAME_UPDATE_CONTRACT_STATUS = 'Update Contract Status';
    public static final String RT_NAME_SECONDARY_DL = 'Secondary DL';
    public static final String RT_NAME_KYC_APPROVAL_REQUEST = 'KYC Approval Request';
    public static final String RT_NAME_DIRECT_DEBIT_REQUEST = 'Direct Debit Request';
    public static final String RT_NAME_BOB_APPROVAL = 'Bill on Behalf Approval';
    public static final String RT_NAME_WHOLESALE_APPROVAL = 'Wholesale Approval';
    public static final String RT_NAME_VAT_ID_Exemption = 'VAT ID Exemption';
    public static final String RT_DEVELOPER_NAME_VAT_ID_Exemption = 'VAT_ID_Exemption';
    public static final String RT_DEV_NAME_INVOICE_WHOLESALE_REQUEST = 'Invoice_Wholesale_Request';
    public static final String RT_DEV_NAME_INVOICE_ON_BEHALF_REQUEST = 'Invoice_On_Behalf_Request';
    public static final String RT_DEV_NAME_INVOICING_REQUEST = 'Invoicing_Request';
    public static final List<String> APPROVAL_INVOICE_RECORD_TYPES = new List<String>{RT_DEV_NAME_INVOICE_WHOLESALE_REQUEST,RT_DEV_NAME_INVOICE_ON_BEHALF_REQUEST, RT_DEV_NAME_INVOICING_REQUEST};
    public static final String RT_NAME_CREDIT_LIMIT_INCREASE = 'Credit Limit Increase';

    // Refund_Approval_BU__c
    public static final String BU_SALES = 'Sales';
    public static final String BU_SUPPORT = 'Support';

    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }

    public static Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID {
        get {
            if(RT_INFO_BY_ID == null) {
                RT_INFO_BY_ID = DESCRIBE.getRecordTypeInfosById();
            }
            return RT_INFO_BY_ID;
        }
        set;
    }

    public static final Id RT_ID_REFUND_APPROVAL = RT_INFO_BY_NAME.get(RT_NAME_REFUND_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_FEATURE_ADD_ONS_APPROVAL =
            RT_INFO_BY_NAME.get(RT_NAME_FEATURE_ADD_ONS_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_INVOICE_ON_BEHALF_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_INVOICE_ON_BEHALF_REQUEST_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_INVOICE_WHOLESALE_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_INVOICE_WHOLESALE_REQUEST_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_INVOICING_REQUEST = RT_INFO_BY_NAME.get(INVOICING_REQUEST_APPROVAL_RT_NAME).getRecordTypeId();
    public static final Id RT_ID_CHANNEL_CROSS_SELL = RT_INFO_BY_NAME.get(RT_NAME_CHANNEL_CROSS_SELL).getRecordTypeId();
    public static final Id RT_ID_ENGAGE_LEGAL = RT_INFO_BY_NAME.get(RT_NAME_ENGAGE_LEGAL).getRecordTypeId();
    public static final Id RT_ID_TAX_EXEMPT_APPROVAL = RT_INFO_BY_NAME.get(RT_NAME_TAX_EXEMPT_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_BILLING_DATE_CHANGE_REQUEST_APPROVAL = RT_INFO_BY_NAME.get(RT_NAME_BILLING_DATE_CHANGE_REQUEST_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_POC_ACCOUNT = RT_INFO_BY_NAME.get(RT_NAME_POC_ACCOUNT).getRecordTypeId();
    public static final Id RT_ID_UPDATE_CONTRACT_STATUS = RT_INFO_BY_NAME.get(RT_NAME_UPDATE_CONTRACT_STATUS).getRecordTypeId();
    public static final Id RT_ID_SECONDARY_DL = RT_INFO_BY_NAME.get(RT_NAME_SECONDARY_DL).getRecordTypeId();
    public static final Id RT_ID_RETENTION_REFUNDS = RT_INFO_BY_NAME.get(RT_NAME_RETENTION_REFUNDS).getRecordTypeId();
    public static final Id RT_ID_KYC_APPROVAL_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_KYC_APPROVAL_REQUEST).getRecordTypeId();
    public static final Id RT_ID_DIRECT_DEBIT_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_DIRECT_DEBIT_REQUEST).getRecordTypeId();
    public static final Id RT_ID_BOB_APPROVAL = RT_INFO_BY_NAME.get(RT_NAME_BOB_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_VAT_ID_Exemption = RT_INFO_BY_NAME.get(RT_NAME_VAT_ID_Exemption).getRecordTypeId();
    public static final Id RT_ID_WHOLESALE_APPROVAL = RT_INFO_BY_NAME.get(RT_NAME_WHOLESALE_APPROVAL).getRecordTypeId();
    public static final Id RT_ID_CREDIT_LIMIT_INCREASE = RT_INFO_BY_NAME.get(RT_NAME_CREDIT_LIMIT_INCREASE).getRecordTypeId();

    public static final Map<Id, String> APPROVAL_ID_TO_LAYOUT_NAME = new Map<Id, String> {
        RT_ID_INVOICING_REQUEST => 'Invoice Request Layout',
        RT_ID_INVOICE_ON_BEHALF_REQUEST => 'Invoice-on-behalf Request Layout',
        RT_ID_INVOICE_WHOLESALE_REQUEST => 'Invoice Wholesale Request Layout'
    };

    public static final Map<Id, String> RT_ID_TO_PAYMENT_METHOD_MAP = new Map<Id, String>{
        RT_ID_INVOICING_REQUEST => AccountHelper.PAYMENT_METHOD_INVOICE,
        RT_ID_INVOICE_ON_BEHALF_REQUEST => AccountHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF
    };

    public static final String LAYOUT_KYC_APPROVAL_NAME = 'KYC Approval Layout';
    public static final String APPROVAL_TYPE_DIRECT_TO_VAR = 'Direct to VAR';
    public static final String APPROVAL_MODULE_MANUAL = 'Manual';

    public static final String SOURCE_OTHER = 'Other';
    public static final String SOURCE_AUTO_GENERATED_FROM_PDF = 'Auto-Generated from PDF';

    public static final String OPTIONS_AUTOMATIC = 'Automatic';

    public static final String AUTOMATIC_APPROVAL = 'Automatic Approval';

    public static final String AMAZON_US = 'Amazon US';

    public static final Set<String> APPROVAL_STATUSES = new Set<String>{
            'Required',
            'Approved',
            'PendingL1Approval',
            STATUS_PENDING_L1_APPROVAL,
            STATUS_PENDING_L2_APPROVAL,
            STATUS_PENDING_L3_APPROVAL,
            STATUS_PENDING_L4_APPROVAL,
            STATUS_PENDING_L5_APPROVAL,
            STATUS_PENDING_L6_APPROVAL,
            STATUS_PENDING_L7_APPROVAL,
            STATUS_PENDING_L8_APPROVAL,
            'New',
            'Pending Second Manager Approval',
            'For Processing - Business Services',
            'Completed (End-State)',
            'Approved By Manager',
            'Approved By Queue',
            'Pending Approval',
            'Completed',
            'In Progress',
            'Ready For Signature',
            'Out For Signature',
            'For processing - SalesOps',
            'Completed (Audit)',
            'For Processing - Bid Desk'
    };

	public static final Set<String> APPROVAL_STATUSES_FOR_VALIDATE = new Set<String>{
            'Approved',
            'PendingL1Approval',
            'PendingL2Approval',
            'PendingL3Approval',
            'PendingL4Approval',
            'PendingL5Approval',
            'PendingL6Approval',
            'PendingL7Approval',
            'PendingL8Approval',
            'Pending Second Manager Approval',
            'Approved By Manager',
            'Approved By Queue',
            'Pending Approval',
            'Approved for Credit'
    };

    public static final Set<String> REFUND_TYPES = new Set<String>{
            'BOGO Phone Promotion',
            'Hardware Discount - New',
            'Hardware Discount - B-Stock Phones',
            'Hardware Discount - W/Out DL'
    };

    public static final Set<String> RT_SKIP_APPROVAL_LEVELS_CALC = new Set<String> {
        'Agent Credit Split',
        'Agent Credit Transfers',
        'Billing Extension Approval',
        'Channel Cross Sell',
        'Engage Legal',
        'Farming Claim Owner',
        'Manual Refunds',
        'QuoteApprovalProcess',
        'Retention Refunds',
        'Shared Deal Claim',
        'Tax Exempt Approval',
        'Update Contract Status'
    };

    public static final Set<String> FIELDS_TO_SKIP_FOR_FINAL_STEP = new Set<String> {
        'Status__c',
        'InvoiceApprovalType__c',
        'Id',
        'Name',
        'AccountPayableContact__c',
        'Opportunity__c',
        'RecordTypeId',
        'CreatedById',
        'PartnerAccountPayableContact__c',
        'StatusLastModifiedDate__c',
        'Monthly_Credit_Limit__c'
    };

    public enum VAT_NAME {
        VAT, GST
    }

    public static final Set<String> PENDING_APPROVAL_STATUSES = new Set<String>{
        ApprovalHelper.STATUS_PENDING_L1_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L2_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L3_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L4_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L5_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L6_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L7_APPROVAL,
        ApprovalHelper.STATUS_PENDING_L8_APPROVAL
    };

    public static final String GOTOTHEFINALSTEP = 'goToTheFinalStep';

    public static final String NATIONALITY_OF_AUTHORISED_SIGNATORY_INDIA = 'India';
    public static final String INVOICE_ON_BEHALF_PAYMENT_METHOD = 'Invoice On Behalf';
    public static final String INVOICE_PAYMENT_METHOD = 'Invoice';
    public static final String FINANCE_EXCEPTION_APPROVAL = 'Finance Exception Approval';
    public static final String DB_CREDIT_CHECK = 'D&B Credit Check';
    public static final String PREVIOUS_APPROVER = 'Previous_Approver';
    public static final String NEW_APPROVER = 'New_Approver';
    public static final String INVOICE_APPROVAL_QUEUE = 'Invoice Approval Queue';
    public static final String AUTO_APPROVED = 'Auto Approved';
    public static final String PROCESSINSTANCE_APPROVE = 'Approve';

    public static Approval.ProcessResult setApprovalAction(Id targetObjectId, String action) {
        return setApprovalAction(targetObjectId, action, null);
    }

    public class NoProcessInstanceWorkitemException extends Exception {}

    public static Approval.ProcessResult setApprovalAction(Id targetObjectId, String action, String comment) {
        System.debug(targetObjectId);
        System.debug(action);
        System.debug(comment);
        Approval.ProcessResult result = null;
        if (String.isBlank(targetObjectId) || String.isBlank(action)){
            return result;
        }
        try {
            List<ProcessInstanceWorkitem> pwList = [
                SELECT Id, OriginalActorId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :targetObjectId
            ];

            if (pwList.isEmpty()) {
                throw new NoProcessInstanceWorkitemException('No ProcessInstanceWorkitem found for targetObjectId: ' + targetObjectId);
            }

            Id currentUserId = UserInfo.getUserId();
            ProcessInstanceWorkitem piwi = pwList.get(0);
            for (ProcessInstanceWorkitem pw : pwList) {
                if (pw.OriginalActorId != currentUserId) {
                    continue;
                }

                piwi = pw;
            }

            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction(action);
            pwr.setWorkitemId(piwi.Id);

            if (!String.isBlank(comment)) {
                pwr.setComments(comment);
            }

            result = Approval.process(pwr);
        } catch (DMLException e) {
            AquivaHelper.throwAquivaException(e);
        }
        return result;
    }

    public static Approval.ProcessResult submitApprovalRequest(Id targetId, String processNameOrId, String comment){
        Approval.ProcessResult result;
        if (String.isBlank(targetId) || String.isBlank(processNameOrId)){
            return result;
        }
        try {
            // Create an approval request
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            if (String.isNotBlank(comment)){
                req.setComments(comment);
            }
            req.setObjectId(targetId);

            // Submit on behalf of a specific submitter
            req.setSubmitterId(UserInfo.getUserId());

            // Submit the record to specific process and skip the criteria evaluation
            req.setProcessDefinitionNameOrId(processNameOrId);
            req.setSkipEntryCriteria(isSkipEntryCriteria(processNameOrId));

            // Submit the approval request for the account
            result = Approval.process(req);
        } catch (DMLException e) {
            AquivaHelper.throwAquivaException(e);
        }

        return result;
    }

    public static Boolean isApprovalApproved(Approval__c approval) {
        return approval?.Status__c == STATUS_APPROVED;
    }

    public static Boolean hasApprovedPOCApproval(Approval__c[] approvals) {
        for (Approval__c a : approvals) {
            if (a.RecordTypeId == RT_ID_POC_ACCOUNT && a.Status__c == STATUS_APPROVED) {
                return true;
            }
        }
        return false;
    }

    public static List<Approval__c> getApprovedApprovals (Set<Id> accIds, List<String> appStatus) {
        List<Approval__c> accountApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectApprovedTaxExemptionApprovalsForAccount(new List<Object>{
                accIds,
                appStatus,
                new Set<Id>()})
            .executeQuery();

        return accountApprovals;
    }

    public static Approval.ProcessResult processApprovalRequest(Set<Id> apps, String comment, String action){
        Approval.ProcessResult result = null;
        Id workItemId;
        if (apps.size()>0) {

            try {
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments(comment);
                req.setAction(action);

                for(ProcessInstanceWorkitem workItem : [SELECT p.Id FROM ProcessInstanceWorkitem p WHERE p.ProcessInstance.TargetObjectId IN : apps]) {
                    workItemId = workItem.Id;
                }
                req.setWorkitemId(workItemId);
                result =  Approval.process(req);
            } catch (DMLException e) {
                PlatformLog.logException('errorProcessApprovalRequest', e);
                AquivaHelper.throwAquivaException(e);
            }
        }
        return result;
    }

    public static Map<String, Decimal> getRefundDetailsTotalsMap(Approval__c appr) {
        Map<String, Decimal> res = new Map<String, Decimal> {
            REFUND_FAMILY_RC_LEGACY => NumberHelper.toNumber(appr.TotalRCCoreRefundAmount__c),
            REFUND_FAMILY_NGBS => NumberHelper.toNumber(appr.TotalNGBSRefundAmount__c),
            REFUND_FAMILY_CONTACT_CENTER => NumberHelper.toNumber(appr.TotalCCRefundAmount__c),
            REFUND_FAMILY_PROSERV => NumberHelper.toNumber(appr.TotalProServRefundAmount__c)
        };

        Map<String, Decimal> transHistoriesMap =
            TransactionHistoryHelper.getTransactionHistoriesSumsByFamily(appr.Id);

        for (String family : res.keySet()) {
            res.put(
                family,
                res.get(family) - transHistoriesMap.get(family)
            );
        }

        return res;
    }

    public static Map<String, Object> getApprovalBillingInfo(Approval__c appr) {
        Map<String, Object> res = new Map<String, Object>();

        Integer refundCategoryId;
        Integer refundTypeId;

        if (Feature_Toggle__c.getInstance().Static_Refund_Category_and_Type__c) {
            refundCategoryId = REFUND_CATEGORY_ID_DEFAULT;
            refundTypeId = REFUND_TYPE_ID_DEFAULT;
        } else {
            refundCategoryId = findCategoryIdByName(appr.Category__c);
            refundTypeId = findRefundTypeId(refundCategoryId, appr.Refund_Type__c);
        }

        //Get date of the last approval step
        List <ProcessInstance> piList = [
            SELECT Id, TargetObjectId
            FROM ProcessInstance
            WHERE TargetObjectId =: appr.Id LIMIT 1
        ];

        DateTime lastStepCreatedDate = DateTime.now(); // refundApprovalDate
        if(!piList.isEmpty()) {
            Id piRecordId = piList.get(0).Id;
            List <ProcessInstanceStep> pisList = [
                SELECT Id, StepStatus, CreatedDate
                FROM ProcessInstanceStep
                WHERE ProcessInstanceId = :piRecordId
                AND StepStatus = :STATUS_APPROVED
                ORDER BY CreatedDate DESC
            ];
            if(!pisList.isEmpty()) {
                lastStepCreatedDate = pisList.get(0).CreatedDate;
            }
        }

        String approvalId = appr.Approval_ID__c;
        String approverEmail = appr.Level1Approver__c != null
                                    ? appr.Level1Approver__r.Email
                                    : appr.Owner.Email;
        String approverFirstName = appr.Level1Approver__c != null
                                    ? appr.Level1Approver__r.FirstName
                                    : appr.Owner.FirstName;
        String approverLastName = appr.Level1Approver__c != null
                                    ? appr.Level1Approver__r.LastName
                                    : appr.Owner.LastName;
        String refundApprovalDate = lastStepCreatedDate.format('MM-dd-yyyy');
        String refundComment = appr.JustificationandDescription__c;
        String refundRequestDate = DateTime.now().format('MM-dd-yyyy');
        String userEmail = appr.Owner.Email;
        String userFirstName = appr.Owner.FirstName;
        String userLastName = appr.Owner.LastName;
        String actorEmail = UserInfo.getUserEmail();

        res.put('approvalId', approvalId);
        res.put('approverEmail', approverEmail);
        res.put('approverFirstName', approverFirstName);
        res.put('approverLastName', approverLastName);
        res.put('refundApprovalDate', refundApprovalDate);
        res.put('refundCategoryId', refundCategoryId);
        res.put('refundComment', refundComment);
        res.put('refundRequestDate', refundRequestDate);
        res.put('refundTypeId', refundTypeId);
        res.put('userEmail', userEmail);
        res.put('userFirstName', userFirstName);
        res.put('userLastName', userLastName);
        res.put('actorEmail', actorEmail);

        return res;
    }

    private static Integer findCategoryIdByName(String refundCategoryName) {

        if (String.isBlank(refundCategoryName)) {
            return null;
        }
        Refund_Categories__c refCat = Refund_Categories__c.getAll().get(refundCategoryName) != null ?
            Refund_Categories__c.getAll().get(refundCategoryName) : null;
        if (refCat == null || refCat.Category_Id__c == null) {
            AquivaHelper.throwAquivaException(String.format(INVALID_REFUND_CATEGORY_MSG, new List<String>{refundCategoryName}));
        }
        return (Integer) refCat.Category_Id__c;
    }

    private static Integer findRefundTypeId(Integer refundCategoryId, String refundTypeName) {

        if (refundCategoryId == null || String.isBlank(refundTypeName)) {
            return null;
        }
        Integer refundTypeId;
        for (RefundCategoryAndTypeMapping__c item : RefundCategoryAndTypeMapping__c.getAll().values()) {
            if (item.Refund_Category_Id__c == refundCategoryId && item.Refund_Type_Name__c == refundTypeName) {
                refundTypeId = (Integer) item.Refund_Type_Id__c;
                break;
            }
        }
        if (refundTypeId == null) {
            AquivaHelper.throwAquivaException(String.format(INVALID_REFUND_TYPE_MSG, new List<Object>{refundCategoryId, refundTypeName}));
        }
        return refundTypeId;
    }

    public static List<Approval__c> getInvoiceRequests(List<Approval__c> approvals) {
        List<Approval__c> invoiceRequests = new List<Approval__c>();
        for (Approval__c app : approvals) {
            if (isInvoicingRequestApproval(app)) {
                invoiceRequests.add(app);
            }
        }
        return invoiceRequests;
    }

    public static List<Approval__c> getIOBorWholesaleApprovals(List<Approval__c> approvals) {
        List<Approval__c> approvalsList = new List<Approval__c>();
        for (Approval__c app : approvals) {
            if (isInvoiceOnBehalfRequestApproval(app) || isInvoiceWholesaleRequestApproval(app)) {
                approvalsList.add(app);
            }
        }
        return approvalsList;
    }

    public static List<AccountContactRole> getPayableApprovalsRoles(List<Approval__c> approvals) {
        List<AccountContactRole> approvalRoles = new List<AccountContactRole>();
        Set<Id> accountIds = new Set<Id>();
        for (Approval__c approval : approvals) {
            accountIds.add(approval.Account__c);
        }
        if (!accountIds.isEmpty()) {
            approvalRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
                .selectAccountContactRolesByRolesAndAccountIds(accountIds, new Set<String> {AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE})
                .executeQuery();
        }
        return approvalRoles;
    }

    public static List<AccountContactRole> getPayableApprovalsRolesWithPartners(List<Account> accountsWithPartners, List<Approval__c> approvalsList) {
        List<AccountContactRole> approvalsRoles = new List<AccountContactRole>();
        Set<Id> accountsIds = new Set<Id>();
        for (Account a : accountsWithPartners) {
            accountsIds.add(a.Id);
            accountsIds.add(a.Partner_Account__c);
        }
        for (Approval__c request : approvalsList) {
            accountsIds.add(request.SwitchInvoicePartnerAccount__c);
        }
        if (!accountsIds.isEmpty()) {
            approvalsRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
                .selectAccountContactRolesByRolesAndAccountIds(accountsIds, new Set<String> {AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE})
                .executeQuery();
        }
        return approvalsRoles;
    }

    public static Boolean validateChangingAccountContactRoles(String accountId, String contactId) {
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
            .selectInvoiceApprovalsForPayableInfo(new List<Object>{
                new List<Id>{ RT_ID_INVOICING_REQUEST, RT_ID_INVOICE_ON_BEHALF_REQUEST, RT_ID_INVOICE_WHOLESALE_REQUEST },
                new Set<Id>{ accountId },
                APPROVAL_STATUSES_FOR_VALIDATE})
            .executeQuery();
        if (approvals != null && !approvals.isEmpty()) {
            for (String status : APPROVAL_STATUSES_FOR_VALIDATE) {
                if (status == approvals[0].Status__c && contactId == approvals[0].AccountPayableContact__c) {
                    return true;
                }
            }
        }
        return false;
    }

    public static void checkAccountPayableContacts(List<Approval__c> approvals, List<AccountContactRole> accountsRoles) {
        for (Approval__c approval : approvals) {
            Boolean contactExistsInRoles = false;
            for (AccountContactRole role : accountsRoles) {
                if (role.Role == AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE &&
                    role.AccountId == approval.Account__c &&
                    role.ContactId == approval.AccountPayableContact__c)
                {
                    contactExistsInRoles = true;
                    break;
                }
            }
            if (!contactExistsInRoles) {
                approval.addError(APPROVAL_NON_PAYABLE_CONTACT_ERROR);
            }
        }
    }

    public static void checkPartnerAccountPayableContacts(List<Approval__c> approvals, List<AccountContactRole> accountsRoles, Map<Id,Account> accountsWithPartners) {

        for (Approval__c approval : approvals) {

            Boolean contactExistsInRoles = false;

            Account approvalAccount = accountsWithPartners.get(approval.Account__c);

            if (approvalAccount == null) {
                continue;
            }

            Account partnerAccount = accountsWithPartners.get(approvalAccount.Partner_Account__c);
            for (AccountContactRole role : accountsRoles) {
                if (role.Role == AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE &&
                    (role.AccountId == approvalAccount.Partner_Account__c || role.AccountId == approval.SwitchInvoicePartnerAccount__c) &&
                    role.ContactId == approval.PartnerAccountPayableContact__c)
                {
                    contactExistsInRoles = true;
                    break;
                }
            }

            if (!contactExistsInRoles) {
                approval.addError(APPROVAL_PARTNER_NON_PAYABLE_CONTACT_ERROR);
            }

            if (partnerAccount == null) {
                continue;
            }

            if (String.isNotBlank(partnerAccount.PartnerStatus__c) && partnerAccount.PartnerStatus__c != AccountHelper.ACTIVE_STATUS) {
                approval.addError(APPROVAL_PARTNER_NOT_ACTIVE_ERROR);
            }

            if (String.isNotBlank(approvalAccount.BusinessIdentity__c)
                && String.isNotBlank(partnerAccount.BusinessIdentity__c)
                && approvalAccount.BusinessIdentity__c != partnerAccount.BusinessIdentity__c
            ) {
                approval.addError(APPROVAL_PARTNER_NOT_CORRECT_BUSINESS_IDENTITY);
            }
        }
    }

    public static Approval__c getLastApprovedApproval(Id accountId, Id recordTypeId) {
        Approval__c last;
        try {
            List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
                .selectApprovedApprovalsForAccountByRecordType(new List<Object> { recordTypeId, new List<Id>{ accountId }})
                .executeQuery();

            for (Approval__c approval : approvals) {

                if (approval.IsMultiProductTechnicalApproval__c) {
                    continue;
                }

                if (last == null) {
                    last = approval;
                    continue;
                }
                Datetime lastCompletedDate = last.ProcessInstances?.get(0)?.CompletedDate;
                Datetime currentCompletedDate = approval.ProcessInstances?.get(0)?.CompletedDate;
                if (lastCompletedDate < currentCompletedDate) {
                    last = approval;
                }
            }
        } catch(Exception e) {
            System.debug('Error occurred while getting last approved approval: ' + e.getMessage());
        }
        return last;
    }

    public static boolean isSingleQuoteApproval(Approval__c approval) {
        return approval.Sign_Up_Purchase_Limit_Contact_Center__c < 0
            && approval.Sign_Up_Purchase_Limit_Engage_Voice__c < 0
            && approval.Sign_Up_Purchase_Limit_Engage_Digital__c < 0
            && approval.Sign_Up_Purchase_Limit_Office__c < 0
            && approval.Sign_Up_Purchase_Limit_for_RC_Events__c < 0
            && approval.Monthly_Credit_Limit_Office__c < 0
            && approval.Monthly_Credit_Limit_Contact_Center__c < 0
            && approval.Monthly_Credit_Limit_Engage_Voice__c < 0
            && approval.Monthly_Credit_Limit_Engage_Digital__c < 0
            && approval.Monthly_Credit_Limit_for_RC_Events__c < 0;
    } 

    public static Approval__c getLastApprovedInvoiceApproval(List<Approval__c> approvals, Boolean isSingleQuote) {
        Boolean isSingleApproval;
        Approval__c last;
        try {
            for (Approval__c currentApproval: approvals) {

                if (currentApproval.IsMultiProductTechnicalApproval__c || currentApproval.Status__c != STATUS_APPROVED) {
                    continue;
                }

                isSingleApproval = isSingleQuote ? isSingleQuoteApproval(currentApproval) : !isSingleQuoteApproval(currentApproval);
                if (isSingleApproval) {
                    if (last == null) {
                        last = currentApproval;
                        continue;
                    }
                    Datetime currentCompletedDate = currentApproval?.StatusLastModifiedDate__c;
                    if (currentCompletedDate != null) {
                        Datetime lastCompletedDate = last?.StatusLastModifiedDate__c;
                        if (lastCompletedDate == null || lastCompletedDate < currentCompletedDate) {
                            last = currentApproval;
                        }
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Error occurred while getting last approved approval: ' + e.getMessage());
        }
        return last;
    }

    public static Approval__c getLastApprovedApprovalByQuoteType(Opportunity opp, Boolean isSingleQuote, String recordTypeId) {
        Approval__c lastApprovedApproval;
        List<Approval__c> approvals = (List<Approval__c>) new ApprovalSelector()
                .selectApprovedApprovalsForAccountByRecordType(new List<Object> { recordTypeId, new List<Id>{ opp.accountId }})
                .executeQuery();

        List<Approval__c> approvedApprovalsForOppty = new List<Approval__c>();
        for (Approval__c approval: approvals) {
            if (approval.Opportunity__c == opp.Id) {
                approvedApprovalsForOppty.add(approval);
            }
        }

        List<Approval__c> requiredApprovals = OpportunityHelper.isNewBusiness(opp)
            ? approvedApprovalsForOppty
            : approvals;

        return getLastApprovedInvoiceApproval(requiredApprovals, isSingleQuote);
    }

    public static Decimal getDirectDebitApprovalThreshold(Quote qt) {
        Decimal result;
        for (DirectDebitApprovalThreshold__c setting : DirectDebitApprovalThreshold__c.getAll().values()) {
            if (qt != null && setting.Brand__c == qt.Brand__c && setting.Currency__c == qt.CurrencyIsoCode) {
                result = setting.ThresholdValue__c;
                break;
            }
        }
        return result;
    }

    public static Map<String, Decimal> getApprovedPackageLimitsMap(Quote qt, Approval__c approval) {
        Map<String, Decimal> approvedPackageLimitsMap = new Map<String, Decimal>();

        if (!qt.IsMultiProductTechnicalQuote__c) {
            approvedPackageLimitsMap.put('MonthlyCreditLimitC', approval.Monthly_Credit_Limit__c);
            approvedPackageLimitsMap.put('SignUpPurchaseLimitC', approval.Sign_Up_Purchase_Limit__c);
            return approvedPackageLimitsMap;
        }

        switch on qt?.ServiceName__c {
            when 'Office' {
                approvedPackageLimitsMap.put('MonthlyCreditLimitC', approval.Monthly_Credit_Limit_Office__c);
                approvedPackageLimitsMap.put('SignUpPurchaseLimitC', approval.Sign_Up_Purchase_Limit_Office__c);
            }
            when 'RingCentral Contact Center' {
                approvedPackageLimitsMap.put('MonthlyCreditLimitC', approval.Monthly_Credit_Limit_Contact_Center__c);
                approvedPackageLimitsMap.put('SignUpPurchaseLimitC', approval.Sign_Up_Purchase_Limit_Contact_Center__c);
            }
            when 'Engage Voice Standalone' {
                approvedPackageLimitsMap.put('MonthlyCreditLimitC', approval.Monthly_Credit_Limit_Engage_Voice__c);
                approvedPackageLimitsMap.put('SignUpPurchaseLimitC', approval.Sign_Up_Purchase_Limit_Engage_Voice__c);
            }
            when 'Engage Digital Standalone' {
                approvedPackageLimitsMap.put('MonthlyCreditLimitC', approval.Monthly_Credit_Limit_Engage_Digital__c);
                approvedPackageLimitsMap.put('SignUpPurchaseLimitC', approval.Sign_Up_Purchase_Limit_Engage_Digital__c);
            }
            when 'Events' {
                approvedPackageLimitsMap.put('MonthlyCreditLimitC', approval.Monthly_Credit_Limit_for_RC_Events__c);
                approvedPackageLimitsMap.put('SignUpPurchaseLimitC', approval.Sign_Up_Purchase_Limit_for_RC_Events__c);
            }
        }

        return approvedPackageLimitsMap;
    }

    public static Decimal getDirectDebitLimit(String accountId, Quote qt) {
        Decimal threshold = getDirectDebitApprovalThreshold(qt);
        Decimal initialPayment = qt.Total_MRR_with_Taxes__c + qt.Total_One_Time_with_Taxes__c;
        Decimal result = threshold;
        if (initialPayment > threshold) {
            Approval__c approval = getLastApprovedApproval(accountId, RT_ID_DIRECT_DEBIT_REQUEST);
            result = approval.Monthly_Credit_Limit__c;
        }
        return result;
    }

    public static Map<Id, Approval__c> fetchLatestPOCApprovalForEachAccount(Set<Id> accountIds) {
        Map<Id, Approval__c> result = new Map<Id, Approval__c>();
        if (accountIds.isEmpty()) {
            return result;
        }

        for (Approval__c approval : (List<Approval__c>) new ApprovalSelector()
            .selectApprovalsForAccountsByRTSortedByApprovedDate(new List<Object> { RT_ID_POC_ACCOUNT, accountIds})
            .executeQuery()) {
            if (!result.containsKey(approval.Account__c)) {
                result.put(approval.Account__c, approval);
            }
        }
        return result;
    }

    public static Boolean isInvoicingRequestApproval(Approval__c approval) {
        return approval?.RecordTypeId == RT_ID_INVOICING_REQUEST;
    }

    public static Boolean isInvoiceOnBehalfRequestApproval(Approval__c approval) {
        return approval?.RecordTypeId == RT_ID_INVOICE_ON_BEHALF_REQUEST;
    }

    public static Boolean isInvoiceWholesaleRequestApproval(Approval__c approval) {
        return approval?.RecordTypeId == RT_ID_INVOICE_WHOLESALE_REQUEST;
    }

    public static Boolean isApprovalOfInvoicingType(Approval__c approval) {
        return isInvoicingRequestApproval(approval)
            || isInvoiceOnBehalfRequestApproval(approval)
            || isInvoiceWholesaleRequestApproval(approval);
    }

    public static Boolean isBillOnBehalfApproval(Approval__c approval) {
        return approval?.RecordTypeId == RT_ID_BOB_APPROVAL;
    }

    public static Boolean isWholesaleApproval(Approval__c approval) {
        return approval?.RecordTypeId == RT_ID_WHOLESALE_APPROVAL;
    }

    public static Boolean isApprovalOfPartnerType(Approval__c approval) {
        return isBillOnBehalfApproval(approval)
            || isWholesaleApproval(approval);
    }

    public static Boolean isInvoiceApprovalRequestValidForFinalStep(
        Approval__c approval,
        Map<String, Object> anotherApprovalFieldToValueMap,
        Account partnerAccount
    ) {
        if (!isApprovalOfInvoicingType(approval)
            || anotherApprovalFieldToValueMap == null
            || anotherApprovalFieldToValueMap.isEmpty()) {
            return false;
        }

        Set<String> fieldsToSkipComparing = new Set<String>(FIELDS_TO_SKIP_FOR_FINAL_STEP);

        Boolean isInvoicingRequest = isInvoicingRequestApproval(approval);
        Boolean isInvoiceOnBehalfRequest = isInvoiceOnBehalfRequestApproval(approval);
        Boolean isInvoiceWholesaleRequest = isInvoiceWholesaleRequestApproval(approval);

        Approval__c anotherApproval = new Approval__c(
            RecordTypeId = (Id) anotherApprovalFieldToValueMap.get('RecordTypeId')
        );
        Boolean isAnotherApprovalInvoicingRequest = isInvoicingRequestApproval(anotherApproval);
        Boolean isAnotherApprovalInvoiceWholesaleRequest = isInvoiceWholesaleRequestApproval(anotherApproval);

        if (isInvoicingRequest) {
            fieldsToSkipComparing.remove('PartnerAccountPayableContact__c');
        }

        if (isInvoiceOnBehalfRequest && isAnotherApprovalInvoicingRequest) {
            return false;
        }

        if (isInvoicingRequest || isInvoiceOnBehalfRequest) {
            if (isAnotherApprovalInvoiceWholesaleRequest) {
                return false;
            }

            Double accountMonthlyCreditLimitFromNGBS = BobMultiApprovalHelper.getMonthlyCreditLimitFromNGBSByAccountId(approval.Account__c);
            Double approvedApprovalMonthlyCreditLimit = (Double) anotherApprovalFieldToValueMap.get('Monthly_Credit_Limit__c');
            if ((accountMonthlyCreditLimitFromNGBS != null && approval.Monthly_Credit_Limit__c != accountMonthlyCreditLimitFromNGBS)
                || (approvedApprovalMonthlyCreditLimit != null && approval.Monthly_Credit_Limit__c != approvedApprovalMonthlyCreditLimit)) {
                return false;
            }

            fieldsToSkipComparing.add('Monthly_Credit_Limit__c');
        }

        if (isInvoiceWholesaleRequest) {
            Boolean isMonthlyCreditLessCreditLimit = partnerAccount != null
                && approval.Monthly_Credit_Limit__c <= partnerAccount?.Credit_Limit__c;
            if (!isMonthlyCreditLessCreditLimit && isApprovalOfInvoicingType(anotherApproval)) {
                return false;
            }
            fieldsToSkipComparing.add('Monthly_Credit_Limit__c');
        }

        return isRequiredKeyFieldsNotChanged(
            approval.getPopulatedFieldsAsMap(),
            anotherApprovalFieldToValueMap,
            fieldsToSkipComparing
        );
    }

    public static Boolean isRequiredKeyFieldsNotChanged(
        Map<String, Object> newApproval,
        Map<String, Object> oldApproval,
        Set<String> fieldsToSkip
    ) {
        for (String field : oldApproval.keySet()) {
            if (fieldsToSkip.contains(field)) {
                continue;
            }
            if (newApproval.get(field) != oldApproval.get(field)) {
                return false;
            }
        }
        return true;
    }

    public static void submitKYCApprovals(List<Approval__c> listApprovals) {
        for (Approval__c approval : listApprovals) {
            submitApprovalRequest(approval.Id, ApprovalHelper.PROCESS_KYC_APPROVAL_REQUEST_V1, null);
        }
    }

    public static Boolean isNeededApprovedKycApproval(List<Approval__c> invoiceRequests, Map<Id, Opportunity> opptiesMap, Map<Id, Approval__c> accIdToKycApprovalMap) {
        Boolean result = false;
        for (Approval__c approvalRecord: invoiceRequests) {
            Opportunity opp = opptiesMap.get(approvalRecord.Opportunity__c);
            Approval__c kycApproval =  accIdToKycApprovalMap.get(approvalRecord.Account__c);
            if (OpportunityHelper.isIndia(opp)
                    && (kycApproval == null
                        || kycApproval.Status__c != STATUS_APPROVED)
            ) {
                result = true;
                break;
            }
        }
        return result;
    }

    private static Boolean isSkipEntryCriteria(String processNameOrId) {
        return processNameOrId != PROCESS_KYC_APPROVAL_REQUEST_V1;
    }

    public static Boolean isInvoiceNotHasApprovedKycApproval(List<Approval__c> approvals) {
        Set<Id> accIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        List<Approval__c> approvalRecordsToProcess = new List<Approval__c>();
        for (Approval__c approvalRecord: approvals) {
            if (approvalRecord.Record_Type_Name__c.equals(INVOICING_REQUEST_APPROVAL_RT_NAME)) {
                approvalRecordsToProcess.add(approvalRecord);
                accIds.add(approvalRecord.Account__c);
                opptyIds.add(approvalRecord.Opportunity__c);
            }
        }
        Map<Id, Opportunity> opptyToId = new Map<Id, Opportunity>(
            (List<Opportunity>) new OpportunitySelector()
                .selectOpportunitiesForApproval(new List<Object>{opptyIds})
                .executeQuery()
            );
        Map<Id, Approval__c> accountIdToKYCApprovalsMap = getAccountIdToLastUpdatedApprovalMap(accIds);
        return isNeededApprovedKycApproval(
            approvalRecordsToProcess,
            opptyToId,
            accountIdToKYCApprovalsMap
        );
    }

    private static Map<Id, Approval__c> getAccountIdToLastUpdatedApprovalMap(Set<Id> accIds) {
        List<Approval__c> kycApprovals = (List<Approval__c>) new ApprovalSelector()
            .selectKYCRequestApprovalsForAccount(new List<Object>{accIds})
            .executeQuery();

        Map<Id, Approval__c> accIdToKycApprovalMap = new Map<Id, Approval__c>();
        for (Approval__c appr: kycApprovals) {
            if (!accIdToKycApprovalMap.keySet().contains(appr.Account__c)) {
                accIdToKycApprovalMap.put(appr.Account__c, appr);
            }
        }

        return accIdToKycApprovalMap;
    }

    public static String getMissedAttachmentErrorText(Approval__c app) {
        String errorText = '';
        List<String> sections = !String.isBlank(app.KycFiles__c)
            ? app.KycFiles__c.split(';', KycDetailsHelper.COUNT_OF_SECTIONS)
            : new List<String>();
        if (sections.size() == KycDetailsHelper.COUNT_OF_SECTIONS) {
            for (Integer sectionId : KycDetailsHelper.sectionIdsList) {
                if ((sectionId == KycDetailsHelper.GST_ATTACHMENT_SECTION || sectionId == KycDetailsHelper.SEZ_ATTACHMENT_SECTION)) {
                    if (app.GstExemptionSezCustomer__c && String.isBlank(sections[sectionId])) {
                        errorText = Label.ApprovalErrorSEZOrGSTCertificateMissed;
                        break;
                    }
                } else {
                    if (String.isBlank(sections[sectionId])) {
                        errorText = String.format(
                            Label.ApprovalErrorKycAttachmentsMissed,
                            new List<String>{KycDetailsHelper.sectionIdToSectionNameMap.get(sectionId)}
                        );
                        break;
                    }
                }
            }
        } else {
            errorText = String.format(
                Label.ApprovalErrorKycAttachmentsMissed,
                new List<String>{KycDetailsHelper.sectionIdToSectionNameMap.get(0)}
            );
        }
        return errorText;
    }

    public static Map<Id, Account> getAccountMap(List<Approval__c> approvalList) {
        if (approvalList == null || approvalList.isEmpty()) {
            return new Map<Id, Account>();
        }

        Set<Id> accountIdSet = new Set<Id>();
        for (Approval__c item : approvalList) {
            accountIdSet.add(item.Account__c);
        }

        return getAccountMap(accountIdSet);
    }

    public static Map<Id, Account> getAccountMap(Set<Id> accIdSet) {
        Map<Id, Account> accMap = new Map<Id, Account>();
        if (accIdSet == null || accIdSet.isEmpty()) {
            return accMap;
        }

        accIdSet.remove(null);
        if (accIdSet.isEmpty()) {
            return accMap;
        }

        return new Map<Id, Account>((List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{accIdSet})
            .executeQuery());
    }

    public static Set<String> getRefundProductFamilies(Approval__c approval) {
        return new Set<String>{
            approval.Refund_Product_Family_1__c,
            approval.Refund_Product_Family_2__c,
            approval.Refund_Product_Family_3__c,
            approval.Refund_Product_Family_4__c,
            approval.Refund_Product_Family_5__c,
            approval.Refund_Product_Family_6__c
        };
    }

    public static List<PostSaleRefundsWrappers.RefundAccountDTO> getServiceAccountsByProductFamily(Approval__c approval) {
        List<PostSaleRefundsWrappers.RefundAccountDTO> serviceAccounts = new List<PostSaleRefundsWrappers.RefundAccountDTO>();

        Set<String> productFamilies = getRefundProductFamilies(approval);

        Map<String, Account> techAccounts = AccountHelper.getTechnicalAccountsByMasterId(approval.Account__r.Id);

        if (!techAccounts.isEmpty()) {
            for (String productFamily : productFamilies) {
                Account serviceAccount;
                if (productFamily == REFUND_FAMILY_NGBS_MVP) {
                    serviceAccount = approval.Account__r;
                } else {
                    serviceAccount = techAccounts.get(productFamilyToService.get(productFamily));
                }

                if (serviceAccount == null || serviceAccount.RC_User_ID__c == null){
                    continue;
                }

                PostSaleRefundsWrappers.RefundAccountDTO accInfo = new PostSaleRefundsWrappers.RefundAccountDTO(serviceAccount);
                accInfo.productFamily = productFamily;
                serviceAccounts.add(accInfo);
            }
        }

        return serviceAccounts;
    }

    public static List<PostSaleRefundsWrappers.MigratedAccountDTO> getMigratedServiceAccounts(Approval__c approval) {
        List<PostSaleRefundsWrappers.MigratedAccountDTO> migratedAccounts = new List<PostSaleRefundsWrappers.MigratedAccountDTO>();

        QueryFactory qFactory = new AccountSelector().selectAccounts()
                    .withoutSelectorOrderByIncluded()
                    .withoutSelectorFieldsIncluded()
                    .selectFields(new Set<String>{
                            'Id', 'Name', 'Billing_Id__c', 'Service_Type__c'
                    })
                    .setCondition('Historical_Master_Account__c = \'' + approval.Account__c + '\' AND Billing_Id__c != null');
        List<Account> migratedAccsObj = (List<Account>) qFactory.executeQuery();

        for (Account acc: migratedAccsObj) {
            PostSaleRefundsWrappers.MigratedAccountDTO accInfo = new PostSaleRefundsWrappers.MigratedAccountDTO(acc);
            migratedAccounts.add(accInfo);
        }

        return migratedAccounts;
    }

    public static List<Approval__c> getTaxExemptsOnProcessOrder(Id masterAccId, Map<Id, Id> techAccIdToTechOppId) {
        if (masterAccId == null || techAccIdToTechOppId.isEmpty()) {
            return new List<Approval__c>();
        }

        List<Account> accountsWithApprovals = (List<Account>) new AccountSelector()
            .selectMPAccountsWithTaxExemptionApprovals(new List<Object> { new List<Id>{ masterAccId } })
            .executeQuery();

        if (accountsWithApprovals.isEmpty()) {
            return new List<Approval__c>();
        }

        List<Account> techAccs = new List<Account>();
        Approval__c approvedTaxExemptApproval;
        List<Approval__c> taxExemptApprovalsForTechAccs = new List<Approval__c>();

        for (Account acc : accountsWithApprovals) {
            if (acc.Id == masterAccId) {
                for (Approval__c approval : acc.Approvals__r) {
                    if (approval.Status__c == STATUS_APPROVED) {
                        approvedTaxExemptApproval = approval;
                        break;
                    }
                }
            } else {
                techAccs.add(acc);
            }
        }

        if (approvedTaxExemptApproval == null) {
            return new List<Approval__c>();
        }

        User technicalUser = UserHelper.getMultiproductTechnicalUser();
        for (Account acc : techAccs) {
            if (!accountHasApprovedTaxExempt(acc)) {
                Approval__c approval = approvedTaxExemptApproval.clone(false, true, false, true);
                approval.Account__c = acc.Id;
                approval.Opportunity__c = techAccIdToTechOppId.get(acc.Id);
                approval.MasterApproval__c = approvedTaxExemptApproval.Id;
                approval.IsMultiProductTechnicalApproval__c = true;
                if (technicalUser != null) {
                    approval.OwnerId = technicalUser.Id;
                }

                taxExemptApprovalsForTechAccs.add(approval);
            }
        }

        return taxExemptApprovalsForTechAccs;
    }

    private static Boolean accountHasApprovedTaxExempt(Account techAcc) {
        for (Approval__c approval : techAcc.Approvals__r) {
            if (approval.Status__c == STATUS_APPROVED) {
                return true;
            }
        }

        return false;
    }

    public static Decimal getCurrentSpendingLimit(String accountId) {
        List<Account> accWithServiceAccounts = (List<Account>) new AccountSelector()
            .selectAccountsForApproval(new List<Object>{new Set<Id>{accountId}})
            .executeQuery();
        if (accWithServiceAccounts != null && !accWithServiceAccounts.isEmpty()) {
            return CreditSpendingLimitNGBSSync.getCurrentSpendingLimit(accWithServiceAccounts[0].Id, accWithServiceAccounts[0].Billing_ID__c, accWithServiceAccounts[0].Service_Accounts__r != null && !accWithServiceAccounts[0].Service_Accounts__r.isEmpty() ? accWithServiceAccounts[0].Service_Accounts__r[0].Account_Package_Id__c : null).value;
        }
        return null;
    }

    public static void submitCreditLimitApprovals(Set<Id> resubmitApprovalIds) {
        for (Id appId : resubmitApprovalIds) {
            submitApprovalRequest(appId, ApprovalHelper.PROCESS_CREDIT_LIMIT_APPROVAL, null);
        }
    }

    public static void resubmitCreditLimitApprovals (Set<Id> resubmitApprovalIds) {
        Set<Id> appIds = new Set<Id>();
        if (!resubmitApprovalIds.isEmpty()) {
            List<ProcessInstanceNode> processSteps = (List<ProcessInstanceNode>) new QueryFactory(ProcessInstanceNode.SObjectType)
                .selectFields(new Set<String>{'NodeStatus', 'ProcessInstance.TargetObjectId', 'ProcessNodeName'})
                .setCondition('NodeStatus =: bind1 AND ProcessNodeName = \'CreditLimitApproval\' AND ProcessInstance.TargetObjectId IN: bind0')
                .setQueryBindings(new List<Object> {resubmitApprovalIds, ApprovalHelper.STATUS_PENDING})
                .executeQuery();

            for (ProcessInstanceNode processStep : processSteps) {
                appIds.add(processStep.ProcessInstance.TargetObjectId);
            }
            Set<Id> membersIds = new Set<Id>();
            Boolean hasGroups = false;
            List<GroupMember> groupMembers = (List<GroupMember>) new GroupMemberSelector()
                .selectGroupMembersByGroupName(GroupHelper.GROUP_CREDIT_LIMIT_APPROVAL_QUEUE)
                .executeQuery();

            if (!groupMembers.isEmpty()) {
                for (GroupMember member : groupMembers) {
                    membersIds.add(member.UserOrGroupId);
                    if (member.UserOrGroupId.getSobjectType() == Group.SObjectType) {
                        hasGroups = true;
                    }
                }
            }

            if (hasGroups) {
                for (GroupMember member : (List<GroupMember>) new GroupMemberSelector().selectGroupMembersByGroupIds(membersIds).executeQuery()) {
                    membersIds.add(member.UserOrGroupId);
                }
            }
            if ((membersIds.contains(UserInfo.getUserId()) || membersIds.contains(UserInfo.getUserRoleId())) && !appIds.isEmpty()) {
                processApprovalRequest(appIds, 'Approval was rejected due to Amount to increase was increased', 'Reject');
                submitCreditLimitApprovals(appIds);
            }
        }
    }
}