public class CaseHelper {

    // Case Describe Object
    public static final SObjectDescribeHelper DESCRIBE_HELPER = SObjectDescribeHelper.getDescribe(Case.getSObjectType());
    public static final String STATUS_FIELD_APINAME = 'Status';

    // Record Types
    public static final String RT_NAME_CERT = 'CERT';
    public static final String RT_NAME_PORTING_PHONE = 'Porting - Phone';
    public static final String RT_NAME_SUPPORT_T1 = 'Support - T1';
    public static final String RT_NAME_SUPPORT_T2 = 'Support - T2';
    public static final String RT_NAME_SUPPORT_T3 = 'Support - T3';
    public static final String RT_NAME_SUPPORT_QOS = 'Support - QoS';
    public static final String RT_NAME_SUPPORT_CASE = 'Support-Case';
    public static final String RT_NAME_SUPPORT_BILLING = 'Support - Billing';
    public static final String RT_NAME_GDPR_REQUEST = 'DSR Request';
    public static final String RT_NAME_SUPPORT_CHAT = 'Support - Chat';
    public static final String RT_NAME_SUPPORT_EMAIL = 'Support - Email';
    public static final String RT_NAME_SUPPORT_MANAGER = 'Support - Manager';
    public static final String RT_NAME_SUPPORT_IA_INBOUND = 'Support - IA Inbound';
    public static final String RT_NAME_SUPPORT_PS = 'Support - PS';
    public static final String RT_NAME_SUPPORT_VIPFR = 'Support - VIPFR';
    public static final String RT_NAME_SUPPORT_TELUS = 'Support - Telus';
    public static final String RT_NAME_SUPPORT_TALK_TO_RC_MGMT = 'Support - TalkToRCMgmt';
    public static final String RT_NAME_SERVICE_ENGINEER = 'Service Engineer';
    public static final String RT_NAME_SUPPORT_CV = 'Support - CV';
    public static final String RT_NAME_SUPPORT_RED_ACCOUNT = 'Support - Red Account';
    public static final String RT_NAME_SUPPORT_SOCIAL_MEDIA = 'Support - Social Media';
    public static final String RT_NAME_SUPPORT_GLIP = 'Support - Glip';
    public static final String RT_NAME_SUPPORT_MOBILE = 'Support - Mobile';
    public static final String RT_COLLECTIONS_DISPUTE = 'Collections Dispute';
    public static final String RT_NAME_SUPPORT_FEEDBACK = 'Support - FeedBack';
    public static final String RT_NAME_CUSTOMER_FEEDBACK = 'Customer Feedback';
    public static final String RT_NAME_SUPPORT_RC_APP = 'Support-RC App';
    public static final String RT_NAME_SUPPORT_T1_VAR_PARTNERS = 'Support - T1 (VAR & Partners)';
    public static final String RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM = 'Support - Executive Response Team';
    public static final String RT_NAME_PORTING_OUT = 'Porting - Out';
    public static final String RT_NAME_PROFESSIONAL_SERVICES = 'Professional Services';
    public static final String RT_NAME_IT_HELPDESK_SUPPORT = 'IT Deskside Support';
    public static final String RT_NAME_IT_HELPDESK = 'IT Helpdesk';
    public static final String RT_NAME_IT_INFRASTRUCTURE = 'IT Infrastructure';
    public static final String RT_NAME_SYSTEM_OPERATIONS = 'System Operations';
    public static final String RT_NAME_SUPPORT_INTEGRATIONS = 'Support - Integrations';
    public static final String RT_NAME_MAINTENANCE = 'Maintenance';
    public static final String RT_NAME_DEALDESK = 'Sales Order Except Desk';
    public static final String RT_NAME_INTERNAL_BUSINESS_SERVICES = 'Internal Business Services';
    public static final String RT_NAME_SALES_CUST_FORM = 'Sales - Customer Issue Form';
    public static final String RT_NAME_ENGAGE_ORDER_DESK = 'Engage Order Desk';
    public static final String RT_NAME_INCONTACT_ORDER = 'inContact Order';
    public static final String RT_NAME_DEVELOPER_PLATFORM = 'Developer Platform';
    public static final String RT_NAME_FINANCE = 'COE Audit';
    public static final String RT_NAME_FINANCE_DEAL_REVIEW = 'Finance Deal Review';
    public static final String RT_NAME_COLLECTION_DISPUTE = 'Collections Dispute';
    public static final String RT_NAME_DEAL_AND_ORDER_SUPPORT = 'Deal and Order Support';
    public static final String RT_NAME_SUPPORT_T1_SHIPPING = 'Support - T1 (Shipping)';
    public static final String RT_NAME_INTERNAL_OPS_TO_OPS = 'Internal OPS to OPS';
    public static final String RT_NAME_IT_NEW_HIRE_REQUEST = 'IT New Hire Request';
    public static final String RT_NAME_PRODUCT_PLATFORM_ISSUES = 'Product / Platform Issues';
    public static final String RT_NAME_SUPPORT_TECH_ASSIST = 'Support - Tech Assist';
    public static final String RT_NAME_PORTING_IN = 'Porting - In';
    public static final String RT_NAME_PORTING_BULK_PROJECT = 'Porting - Bulk/Project';
    public static final String RT_NAME_PORTING_NEUSTAR = 'Porting - In (NeuStar)';
    public static final String RT_NAME_PORTING_RC_UK = 'Porting - In (RC UK)';
    public static final String RT_NAME_PORTING_RC = 'Porting - In (RC)';
    public static final String RT_NAME_PORTING_TELUS = 'Porting - In (TELUS)';
    public static final String RT_NAME_PORTING_VANITY = 'Porting - Vanity';
    public static final String RT_NAME_RESELLER_TEAM = 'Reseller Team';

    public static final String RT_CASE_ACTIVITY_CLOSE_ATTEMPT = 'Close Attempt';
    public static final String RT_CASE_ACTIVITY_CONTACT_ATTEMPT = 'Contact Attempt';
    public static final String RT_NAME_CLOSE_LOOP_FEEDBACK_MEDALLIA = 'Close Loop Feedback Qualtrics';
    public static final String RT_NAME_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP = 'Close Loop Feedback Qualtrics Relationship';
    public static final String RT_NAME_CLOSE_LOOP_FEEDBACK_MEDALLIA_SUPPORT_SURVEY = 'Close Loop Feedback Qualtrics SupportSurvey';
    public static final String RT_NAME_RISE_PARTNER_SUPPORT = 'RISE Partner Support';
    public static final String CASE_IS_NOT_CLOSED = 'Case is not closed';
    public static final String CASE_IS_ALREADY_REOPENED_TEXT = 'Case is already reopened';
    public static final String CASE_IS_ALREADY_ESCALATED_TEXT = 'Case is already escalated';
    public static final String CASE_CANNOT_BE_ESCALATED_BEFORE_SLA_TEXT = 'Case cannot be escalated before the SLA expires';
    public static final String CASE_CLOSED_CANNOT_BE_ESCALATED_TEXT = 'Closed case cannot be escalated';
    public static final String CASE_CLOSED_CANNOT_BE_REOPENED_TEXT = 'Case has been closed for 10 days or more. Please open a new case';
    public static final String CASE_HAS_ALREADY_BEEN_REOPENED_TEXT = 'Case has already been reopened once';
    public static final String CASE_TYPE_PRODUCT_DEFECT = 'Product Defect';
    public static final String CASE_TYPE_PLATFORM_INCIDENT = 'Platform Incident';

    public static final String SUBJECT_HAS_ALREADY_BEEN_REOPENED = 'Case has already been reopened';
    public static final String SUBJECT_PS_UC_QUOTE_REQUESTED = 'UC ProServ requested';
    public static final String SUBJECT_PS_CC_QUOTE_REQUESTED = 'CC ProServ requested';
    public static final String SUBJECT_PS_UC_QUOTE_CANCELATION = 'UC ProServ cancellation';
    public static final String SUBJECT_PS_CC_QUOTE_CANCELATION = 'CC ProServ cancellation';
    public static final String BRAND_BT_BUSINESS = 'BT Business';
    public static final String PORTAL_BT_SUPPORT = 'BT Support Portal';
    public static final String PORTAL_MAIN_SUPPORT = 'Main Support Portal';

    @TestVisible
    private static final Integer DAYS_TO_SLA_BREACHED = 2;
    @TestVisible
    private static final Integer DAYS_FROM_WHICH_A_CASE_CAN_BE_REOPENED = 10;

    public static final Set<String> CASE_RTS_TO_REASSIGN_ON_CASE_OWNER_INACTIVE = new Set<String>{
        RT_NAME_SUPPORT_T1,
        RT_NAME_SUPPORT_T2,
        RT_NAME_SUPPORT_T3,
        RT_NAME_SUPPORT_CASE,
        RT_NAME_SUPPORT_CHAT,
        RT_NAME_SUPPORT_GLIP,
        RT_NAME_SUPPORT_MOBILE,
        RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM
    };
    public static final Set<String> CASE_RTS_FOR_PORTING_SURVEY = new Set<String> {
        RT_NAME_PORTING_IN,
        RT_NAME_PORTING_NEUSTAR,
        RT_NAME_PORTING_RC_UK,
        RT_NAME_PORTING_RC,
        RT_NAME_PORTING_TELUS,
        RT_NAME_PORTING_VANITY
    };
    public static final Set<String> CASE_RTS_FOR_IT_SURVEYS = new Set<String> {
        RT_NAME_IT_HELPDESK,
        RT_NAME_IT_HELPDESK_SUPPORT,
        RT_NAME_IT_INFRASTRUCTURE
    };
    public static final Set<String> CASE_RTS_FOR_PORTING_FIELDS = new Set<String> {
        RT_NAME_PORTING_IN,
        RT_NAME_PORTING_OUT,
        RT_NAME_PORTING_BULK_PROJECT
    };
    public static final Set<String> CASE_RECORD_TYPES_FOR_CLOSED_NOT_RESPONSE_STATUS = new Set<String> {
        RT_NAME_SUPPORT_CHAT,
        RT_NAME_SUPPORT_EMAIL,
        RT_NAME_SUPPORT_MANAGER,
        RT_NAME_SUPPORT_T1,
        RT_NAME_SUPPORT_T2,
        RT_NAME_SUPPORT_T3,
        RT_NAME_PORTING_PHONE,
        RT_NAME_SUPPORT_T1_VAR_PARTNERS,
        RT_NAME_SUPPORT_IA_INBOUND,
        RT_NAME_SUPPORT_PS,
        RT_NAME_SUPPORT_VIPFR,
        RT_NAME_SUPPORT_CASE,
        RT_NAME_SUPPORT_QOS,
        RT_NAME_SUPPORT_TELUS
    };
    public static final Set<String> CASE_RECORD_TYPES_FOR_SURVEY = new Set<String> {
        RT_NAME_SUPPORT_CHAT,
        RT_NAME_SUPPORT_EMAIL,
        RT_NAME_SUPPORT_MANAGER,
        RT_NAME_SUPPORT_T1,
        RT_NAME_SUPPORT_T2,
        RT_NAME_SUPPORT_T3,
        RT_NAME_PORTING_PHONE,
        RT_NAME_SUPPORT_T1_VAR_PARTNERS,
        RT_NAME_SUPPORT_IA_INBOUND,
        RT_NAME_SUPPORT_PS,
        RT_NAME_SUPPORT_VIPFR,
        RT_NAME_SUPPORT_CASE,
        RT_NAME_SUPPORT_QOS,
        RT_NAME_SUPPORT_TELUS,
        RT_NAME_SUPPORT_TECH_ASSIST,
        RT_NAME_SUPPORT_MOBILE,
        RT_NAME_SUPPORT_TALK_TO_RC_MGMT,
        RT_NAME_SERVICE_ENGINEER,
        RT_NAME_SUPPORT_CV,
        RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM,
        RT_NAME_SUPPORT_RED_ACCOUNT,
        RT_NAME_SUPPORT_SOCIAL_MEDIA,
        RT_NAME_SUPPORT_FEEDBACK
    };

    public static final Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME = DESCRIBE_HELPER.getDescribe().getRecordTypeInfosByName();
    public static final Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID = DESCRIBE_HELPER.getDescribe().getRecordTypeInfosById();

    public static final Id RT_ID_CERT = RT_INFO_BY_NAME.get(RT_NAME_CERT).getRecordTypeId();
    public static final Id RT_ID_PORTING_PHONE = RT_INFO_BY_NAME.get(RT_NAME_PORTING_PHONE).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_T1 = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_T1).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_RC_APP = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_RC_APP).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_T2 = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_T2).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_FEEDBACK = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_FEEDBACK).getRecordTypeId();
    public static final Id RT_ID_CUSTOMER_FEEDBACK = RT_INFO_BY_NAME.get(RT_NAME_CUSTOMER_FEEDBACK).getRecordTypeId();
    public static final Id RT_ID_PROFESSIONAL_SERVICES = RT_INFO_BY_NAME.get(RT_NAME_PROFESSIONAL_SERVICES).getRecordTypeId();
    public static final Id RT_ID_PORTING_OUT = RT_INFO_BY_NAME.get(RT_NAME_PORTING_OUT).getRecordTypeId();
    public static final Id RT_ID_IT_HELPDESK_SUPPORT = RT_INFO_BY_NAME.get(RT_NAME_IT_HELPDESK_SUPPORT).getRecordTypeId();
    public static final Id RT_ID_IT_HELPDESK = RT_INFO_BY_NAME.get(RT_NAME_IT_HELPDESK).getRecordTypeId();
    public static final Id RT_ID_IT_INFRASTRUCTURE = RT_INFO_BY_NAME.get(RT_NAME_IT_INFRASTRUCTURE).getRecordTypeId();
    public static final Id RT_ID_SYSTEM_OPERATIONS = RT_INFO_BY_NAME.get(RT_NAME_SYSTEM_OPERATIONS).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_EXECUTIVE_RESPONSE_TEAM = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_EXECUTIVE_RESPONSE_TEAM).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_INTEGRATIONS = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_INTEGRATIONS).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_CASE = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_CASE).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_QOS = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_QOS).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_BILLING = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_BILLING).getRecordTypeId();
    public static final Id RT_ID_GDPR_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_GDPR_REQUEST).getRecordTypeId();
    public static final Id RT_ID_MAINTENANCE_CASE = RT_INFO_BY_NAME.get(RT_NAME_MAINTENANCE).getRecordTypeId();
    public static final Id RT_ID_DEALDESK_CASE = RT_INFO_BY_NAME.get(RT_NAME_DEALDESK).getRecordTypeId();
    public static final Id RT_ID_COLLECTIONS_DISPUTE = RT_INFO_BY_NAME.get(RT_COLLECTIONS_DISPUTE).getRecordTypeId();
    public static final Id RT_ID_INTERNAL_BUSINESS_SERVICES = RT_INFO_BY_NAME.get(RT_NAME_INTERNAL_BUSINESS_SERVICES).getRecordTypeId();
    public static final Id RT_ID_SALES_CUST_FORM = RT_INFO_BY_NAME.get(RT_NAME_SALES_CUST_FORM).getRecordTypeId();
    public static final Id RT_ID_ENGAGE_ORDER_DESK = RT_INFO_BY_NAME.get(RT_NAME_ENGAGE_ORDER_DESK).getRecordTypeId();
    public static final Id RT_ID_INCONTACT_ORDER = RT_INFO_BY_NAME.get(RT_NAME_INCONTACT_ORDER).getRecordTypeId();
    public static final Id RT_ID_DEVELOPER_PORTAL = RT_INFO_BY_NAME.get(RT_NAME_DEVELOPER_PLATFORM).getRecordTypeId();
    public static final Id RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA = RT_INFO_BY_NAME.get(RT_NAME_CLOSE_LOOP_FEEDBACK_MEDALLIA).getRecordTypeId();
    public static final Id RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP = RT_INFO_BY_NAME.get(RT_NAME_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP).getRecordTypeId();
    public static final Id RT_ID_FINANCE = RT_INFO_BY_NAME.get(RT_NAME_FINANCE).getRecordTypeId();
    public static final Id RT_ID_FINANCE_DEAL_REVIEW = RT_INFO_BY_NAME.get(RT_NAME_FINANCE_DEAL_REVIEW).getRecordTypeId();
    public static final Id RT_ID_COLLECTION_DISPUTE = RT_INFO_BY_NAME.get(RT_NAME_COLLECTION_DISPUTE).getRecordTypeId();
    public static final Id RT_ID_CASE_ACTIVITY_CLOSE_ATTEMPT = Case_Activity__c.SObjectType.getDescribe()
        .getRecordTypeInfosByName().get(RT_CASE_ACTIVITY_CLOSE_ATTEMPT).getRecordTypeId();
    public static final Id RT_ID_CASE_ACTIVITY_CONTACT_ATTEMPT = Case_Activity__c.SObjectType.getDescribe()
    .getRecordTypeInfosByName().get(RT_CASE_ACTIVITY_CONTACT_ATTEMPT).getRecordTypeId();
    public static final Id RT_ID_DEAL_AND_ORDER_SUPPORT = RT_INFO_BY_NAME.get(RT_NAME_DEAL_AND_ORDER_SUPPORT).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_T1_SHIPPING = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_T1_SHIPPING).getRecordTypeId();
    public static final Id RT_ID_RESSELLER_TEAM = RT_INFO_BY_NAME.get(GroupHelper.RESSELER_TEAM_DEV_NAME).getRecordTypeId();
    public static final Id RT_ID_PORTING_IN_RCCA = RT_INFO_BY_NAME.get(PortingESBHelper.PortingInRCCA).getRecordTypeId();
    public static final Id RT_ID_PORTING_IN = RT_INFO_BY_NAME.get(PortingESBHelper.PortingIn).getRecordTypeId();
    public static final Id RT_ID_INTERNAL_OPS_TO_OPS = RT_INFO_BY_NAME.get(RT_NAME_INTERNAL_OPS_TO_OPS).getRecordTypeId();
    public static final Id RT_ID_IT_NEW_HIRE_REQUEST = RT_INFO_BY_NAME.get(RT_NAME_IT_NEW_HIRE_REQUEST).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_T3 = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_T3).getRecordTypeId();
    public static final Id RT_ID_PRODUCT_PLATFORM_ISSUES = RT_INFO_BY_NAME.get(RT_NAME_PRODUCT_PLATFORM_ISSUES).getRecordTypeId();
    public static final Id RT_ID_PORTING_NEUSTAR = RT_INFO_BY_NAME.get(RT_NAME_PORTING_NEUSTAR).getRecordTypeId();
    public static final Id RT_ID_PORTING_RC = RT_INFO_BY_NAME.get(RT_NAME_PORTING_RC).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_T1_VAR_PARTNERS = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_T1_VAR_PARTNERS).getRecordTypeId();
    public static final Id RT_ID_SUPPORT_CHAT = RT_INFO_BY_NAME.get(RT_NAME_SUPPORT_CHAT).getRecordTypeId();
    public static final Id RT_ID_RISE_PARTNER_SUPPORT = RT_INFO_BY_NAME.get(RT_NAME_RISE_PARTNER_SUPPORT).getRecordTypeId();
    public static final Id RT_ID_RESELLER_TEAM = RT_INFO_BY_NAME.get(RT_NAME_RESELLER_TEAM).getRecordTypeId();

    public static final Set<Id> CASE_RT_FOR_PACKAGE = new Set<Id>{
        RT_ID_FINANCE,
        RT_ID_FINANCE_DEAL_REVIEW,
        RT_ID_COLLECTION_DISPUTE
    };

    // Case Statuses
    public static final String CASE_STATUS_CLOSED = 'Closed';
    public static final String CASE_STATUS_CLOSED_BY_CUSTOMER = 'Closed - By Customer';
    public static final String CASE_STATUS_CLOSED_NO_RESPONSE = 'Closed - No Response';
    public static final String CASE_STATUS_CANCELLED = 'Cancelled';
    public static final String CASE_STATUS_DUPLICATE = 'Duplicate';
    public static final String CASE_STATUS_COMPLETED = 'Completed';
    public static final String CASE_STATUS_WAITING_ON_CUSTOMER = 'Waiting on Customer';
    public static final String CASE_STATUS_UPDATED_BY_CUSTOMER = 'Updated by Customer';
    public static final String CASE_STATUS_NEW = 'New';
    public static final String CASE_STATUS_REJECT = 'Rejected';
    public static final String CASE_STATUS_SUBMIT = 'Submitted';
    public static final String CASE_STATUS_TRANSFER_DATE = 'Transfer Date Confirmed';
    public static final String CASE_STATUS_WAITING_ON_LOA = 'Waiting on LOA/COB';
    public static final String CASE_STATUS_ADDITIONAL_INFO = 'Additional Information required';
    public static final String CASE_STATUS_PORT_VALIDATION = 'Portability Validation';
    public static final String CASE_STATUS_REOPENED = 'Reopened';
    public static final String CASE_STATUS_WIP = 'Work in Progress';
    public static final String CASE_STATUS_INFORMATION_REQUESTED = 'Information Requested';
    public static final String CASE_STATUS_NEED_REVIEW = 'Need Review';
    public static final String CASE_STATUS_RESOLVED = 'Resolved';
    public static final String CASE_STATUS_NEEDS_APPROVAL_TO_CLOSE = 'Needs Approval to Close (Waiting for Confirmation)';
    public static final Set<Id> CASE_RT_IDS_TO_REASSIGN_ON_LAST_CASE_OWNER = new Set<Id>{
        RT_ID_SUPPORT_T1,
        RT_ID_SUPPORT_T2,
        RT_ID_SUPPORT_T3,
        RT_ID_SUPPORT_QOS,
        RT_ID_SUPPORT_CASE,
        RT_ID_SUPPORT_CHAT,
        RT_ID_SUPPORT_T1_VAR_PARTNERS,
        RT_ID_SALES_CUST_FORM
    };

    public static final Set<String> CASE_IN_CONTACT_STATUSES = new Set<String> {
        CASE_STATUS_COMPLETED,
        CASE_STATUS_INFORMATION_REQUESTED
    };

    public static final Set<String> CASE_STATUSES_TO_REASSIGN_ON_CASE_OWNER_INACTIVE = new Set<String>{
        CASE_STATUS_CLOSED,
        CASE_STATUS_CLOSED_NO_RESPONSE,
        CASE_STATUS_CANCELLED,
        CASE_STATUS_DUPLICATE
    };

    public static final Set<String> CASE_STATUSES_FOR_SURVEY = new Set<String> {
        CASE_STATUS_CLOSED,
        CASE_STATUS_COMPLETED,
        CASE_STATUS_CLOSED_NO_RESPONSE
    };

    public static final Set<String> CASE_STATUSES_FOR_RELATED_CONTACT = new Set<String> {
        CASE_STATUS_NEW,
        CASE_STATUS_SUBMIT,
        CASE_STATUS_REJECT,
        CASE_STATUS_NEED_REVIEW
    };

    public static final String CASE_PRIORITY_MEDIUM = 'Medium';
    public static final String CASE_ORIGIN_AUTO_EMAIL = 'Auto-Email';

    public static final String CASE_REASON_PLAN_CHANGED = 'Plan on Quote was Changed';
    public static final String CASE_REASON_PACKAGE_CHANGED = 'Package on Quote was Upgraded/Downgraded';
    public static final String CASE_REASON_CONVERTED_TO_PAID = 'Quote is Converted to Paid';
    public static final String CASE_REASON_EXCEPTION = 'Exception on Quote occurred';
    public static final String CASE_REASON_SPENDING_LIMIT_EXCEPTION = 'Sync hasn\'t been performed: spending limit is too low';
    public static final String CASE_REASON_INVOICE_EXCEPTION = 'Exception on Quote occurred due to sync Invoice approval';
    public static final String CASE_REASON_DOWNSELL = 'Quote contains Downsell with rental phones and/or insufficient unassigned licenses';
    public static final String CASE_REASON_DOWNSELL_WT_PERMISSION = 'Quote contains Downsell';
    public static final String CASE_REASON_PERMISSION = 'You have no permissions for Shipping tab in Quote wizard';
    public static final String CASE_REASON_UPSELL = 'Quote contains Upsell';

    // Case Owners
    public static final String CNRQUEUE_ID = HardcodedIdsMapper.getMatchedObjectId('00G34000003XRSkEAO');
    public static final QueueSObject BIZ_SERV_INNOVATION_TEAM = (QueueSObject)new QueueSelector().selectQueueByName(new List<Object> {'Biz Serv Innovation Team'}).executeQuery().get(0);

    // Case Support Disposition Levels
    public static final String SUPPORT_DISPOSITION_LEVEL_1 = 'Quote Assistance';
    public static final String SUPPORT_DISPOSITION_LEVEL_2 = 'Other Please Specify';
    public static final String LEVEL_BLOCKED_COUNTRY = 'RingCentral Blocked Country';
    public static final String INTERNAL_WORK_FLOW = 'Internal Work Flow';
    public static final String INTERNAL_WORKFLOW = 'Internal Workflow';
    public static final String FEATURE_REQUEST = 'Feature Request';
    public static final String OUTAGE = 'Outage';
    public static final String DO_NOT_CONTACT_REQUEST = 'Do Not Contact Request';
    public static final String CANCELLATION_REQUEST = 'Cancellation Request';
    public static final Set<String> SUPPORT_DISPOSITION_LEVELS_2 = new Set<String> {
        FEATURE_REQUEST,
        OUTAGE,
        DO_NOT_CONTACT_REQUEST,
        CANCELLATION_REQUEST
    };

    // Case disposition comments
    public static final String COMMENTS = 'QT2.0 Case Inquiery';

    //Case Application(Application__c)
    public static final String CASE_APPLICATION_SALESFORCE = 'Salesforce';

    //Case Category(Case_Category__c)
    public static final String CASE_CATEGORY_SYSTEMS = 'Systems, Process & Tools';
    public static final String CASE_CATEGORY_SYSTEM_ISSUE = 'System Issue';

    //Category (Category__c)
    public static final String CASE_CATEGORY_PROVISIONING = 'Provisioning Assistance';

    //Subject
    public static final String CASE_SUBJECT_MANUAL_SHIPPING = 'Products for manual shipping';
    public static final String CASE_SUBJECT_MANUAL_PROVISIONING = 'Products for manual provisioning';

    //Case Category(Case_Category__c)
    public static final String CASE_CATEGORY_IGNITE = 'Ignite Partner';

    //Category (Case_Subcategory__c)
    public static final String CASE_SUB_CATEGORY_GENERATE_CONTRACT = 'Generate a Contract';
    public static final String CASE_SUB_CATEGORY_OPPORTUNITY = 'Opportunity';

    // Product_Assistance__c
    public static final String CASE_PRODUCT_ASSISTANCE = 'Product Feedback';
    //Porting_RC_Review__c
    public static final String CASE_PORTING_RC_REVIEW_REJECTED = 'Rejected';
    public static final String CASE_PORTING_RC_REVIEW_ACCEPTED = 'Accepted';

    //Case.CC_Order_Type__c
    public static final String CASE_CC_ORDER_TYPE_NEW_ORDER = 'New Order';
    public static final String CASE_CC_ORDER_TYPE_CHANGE_ORDER = 'Change Order';

    // Call_Outcome__c
    public static final String CALL_OUTCOME_CANCELLED = 'Cancelled';

    //Case Origin(Origin)
    public static final String CASE_ORIGIN_CASE = 'Case';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CASE_ORIGIN_QUOTING_PAGE = 'Quoting Page';

    //Case Is_Quickwin__c
    public static final String IS_QUICKWIN_SUPPORT = 'Support';

    //Case Resolution_Code__c
    public static final String RESOLUTION_CODE_RESOLVED_SUCCESSFULLY = 'Resolved Successfully';

    //Case Severity(Case_Severity__c)
    public static final String CASE_SEVERITY_MEDIUM = 'Level 4 - Medium';

    //Escalate To (Support_Escalate_To__c)
    public static final String SUPPORT_ESCALATE_TO_TELECOM_OPS = 'Telecom (Ops)';
    public static final String SUPPORT_ESCALATE_TO_SYSTEM_OPS = 'Support - System Ops';
    public static final String SUPPORT_ESCALATE_TO_TIER_1 = 'Tier 1';

    private static final String EMPTY_TIMEZONE_VALUE = 'None';

    private static final String DEFAULT_LANG = 'en_US';

    // Queues
    public static final String QUEUE_NAME_DEAL_MANAGEMENT = 'Deal Management (DM)';
    public static final String QUEUE_NAME_ORDER_MANAGEMENT = 'Order Management (OM)';
    public static final String QUEUE_NAME_IPA_TEAM = 'IPA Team';

    public static final Set<String> DEAL_AND_ORDER_SUPPORT_QUEUES_NAMES = new Set<String> {
        QUEUE_NAME_DEAL_MANAGEMENT,
        QUEUE_NAME_ORDER_MANAGEMENT,
        QUEUE_NAME_IPA_TEAM
    };

    // Entitlement Type
    public static final String ENTITLEMENT_NAME_MANAGED_SERVICES = 'Managed Services';

    // Professional Service categories
    public static final String CATEGORY_IMPLEMENTATION_SERVICES = 'Implementation Services Quote / SOW';
    public static final String CATEGORY_MANAGED_OR_RECURRING_SERVICES = 'Managed Services, Recurring Services, Advanced Support';
    public static final String CATEGORY_VIDEO = 'Video / Rooms in a Box';
    public static final String CATEGORY_AFTERMARKET_SUPPORT = 'Aftermarket PS Support';

    public static final String LAYOUT_NAME_DEAL_AND_ORDER_SUPPORT = 'Deal and Order Support';

    public static final String CASE_DESCRIPTION_CLONED_QUOTE = 'The new quote was created by cloning a previous quote.';

    @testVisible
    private static Boolean doChainJob = true;

    public static final String CASE_NUMBER = 'caseNumber';
    public static final String NBU_CASE_SUBJECT = 'NBU';
    public static final String EMEA_CASE_GEOREGION = 'EMEA';
    
    public static final String CASE_TYPE_CERT_CUSTOMER_SUCCESS_ESCALATION = 'CERT/Customer Success Escalation';

    private static final String DSR_RESPONSE_EMAIL_SUBJECT = 'Data Subject Request';

    private static final String DSR_RESPONSE_EMAIL_NOTIFICATION_TEMPLATE =
        'Hello {customerName},<br><br>' +
        'Thank you for submitting your data subject request, received on {dateOfReceipt}.<br>' +
        'Your request has been received and is in process. Estimated response time is 30 calendar days.<br>' +
        'We will contact you with further information, including a completion confirmation, as appropriate.<br><br>' +
        'Kind regards,<br>' +
        '{supportTier}';

    public static Case buildAssistCase(Opportunity oppForAssist, Map<String, Group> groupMap) {

        String subject = 'Opportunity Closed';
        String ownerId = null;
        if (BooleanHelper.toBoolean(OpportunityHelper.engageOppIdToTerminationStatus(new List<Opportunity>{oppForAssist})?.get(oppForAssist.Id))) {
            subject = OpportunityHelper.isEngageDigital(oppForAssist) || OpportunityHelper.isEngageVoice(oppForAssist) ?
                oppForAssist.Tier_Name__c.replace('Standalone', Label.CaseTerminationSubject)
                : oppForAssist.Tier_Name__c + Label.CaseTerminationSubject;
            ownerId = groupMap.get(QueueHelper.DEAL_DESK_ENGAGE_QUEUE)?.Id;

        }

        Id recordTypeId = RT_ID_ENGAGE_ORDER_DESK;

        return (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {

                Case.AccountId => oppForAssist.AccountId,
                Case.Application__c => CASE_APPLICATION_SALESFORCE,
                Case.Case_Category__c => CASE_CATEGORY_SYSTEMS,
                Case.Case_Severity__c => CASE_SEVERITY_MEDIUM,
                Case.ContactId => oppForAssist.Primary_Opportunity_Contact__c,
                Case.Description => getAssistCaseDescription(oppForAssist),
                Case.Opportunity_Reference__c => oppForAssist.Id,
                Case.Origin => CASE_ORIGIN_WEB,
                Case.OwnerId => ownerId,
                Case.RecordTypeId => recordTypeId,
                Case.Subject => subject

            })
            .build()
            .getRecord();
    }

    public static Case buildCase(Map<SObjectField, Object> fieldsMap) {
        return (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(fieldsMap)
            .create()
            .getRecord();
    }

    public static void createRestResponse(){
        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }
    }

    public static Map<SObjectField, Object> buildCaseFieldsMap(Map<String, Object> paramsMap) {
        Map <String, Schema.SObjectField> allCaseFields = Case.getSobjectType().getDescribe().fields.getMap();
        Map<SObjectField, Object> fieldsMap = new Map<SObjectField, Object>();
        for(String attribute : paramsMap.keyset()) {
            fieldsMap.put(allCaseFields.get(attribute), paramsMap.get(attribute));
        }
        return fieldsMap;
    }

    public static Map<String, Object> getParamsAsMap(BillingWrappers.CaseCreateParams params){
        String jsonInstance = JSON.serialize(params);
        return (Map<String, Object>)JSON.deserializeUntyped(jsonInstance);
    }

    public static Map<String, Object> addSalesOrderExceptDescQueueMapFields(Map<String, Object> paramsMap) {
        Boolean caseRoutingChange = FeatureManagement.checkPermission(CustomPermissionHelper.PERMISSION_ALTERNATIVE_CASE_ROUTING);

        Id recordTypeId = caseRoutingChange ? RT_ID_INTERNAL_BUSINESS_SERVICES : RT_ID_DEALDESK_CASE;
        Id ownerId = caseRoutingChange ? BIZ_SERV_INNOVATION_TEAM.QueueId : DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId;
        paramsMap.put('RecordTypeId', recordTypeId);
        paramsMap.put('OwnerId', ownerId);
        paramsMap.put('Comments__c', COMMENTS);
        paramsMap.put('support_disposition_level_1__c', SUPPORT_DISPOSITION_LEVEL_1);
        paramsMap.put('support_disposition_level_2__c', SUPPORT_DISPOSITION_LEVEL_2);
        paramsMap.put('Status', CASE_STATUS_NEW);
        paramsMap.put('Priority', CASE_PRIORITY_MEDIUM);
        paramsMap.put('Origin', CASE_ORIGIN_AUTO_EMAIL);

        paramsMap = adjustParamsMapFields(paramsMap);

        return paramsMap;
    }

    public static Map<String, Object> addCreateCaseFromProServMapFields(Map<String, Object> paramsMap) {
        Id recordTypeId = RT_ID_PROFESSIONAL_SERVICES;
        paramsMap.put('RecordTypeId', recordTypeId);
        paramsMap = adjustParamsMapFields(paramsMap);

        return paramsMap;
    }

    public static Map<String, Object> adjustParamsMapFields(Map<String, Object> paramsMap) {
        Object opportunityId = paramsMap.get('opportunityId');
        paramsMap.remove('opportunityId');
        paramsMap.remove('action');
        paramsMap.put('opportunity_reference__c', opportunityId);

        Object quoteApprovalId = paramsMap.get('quoteApprovalId');
        paramsMap.remove('quoteApprovalId');
        paramsMap.put('Quote_Approval_ID__c', quoteApprovalId);

        Object opportunityOwnerEmail = paramsMap.get('opportunityOwnerEmail');
        paramsMap.remove('opportunityOwnerEmail');
        paramsMap.put('OpportunityOwnerEmail__c', opportunityOwnerEmail);

        Object partnerContact = paramsMap.get('partnerContact');
        paramsMap.remove('partnerContact');
        paramsMap.put('Partner_Contact__c', partnerContact);

        Object category = paramsMap.get('category');
        paramsMap.remove('category');
        paramsMap.put('Category__c', category);

        Object caseCategory = paramsMap.get('caseCategory');
        paramsMap.remove('caseCategory');
        paramsMap.put('Case_Category__c', caseCategory);

        Object segment = paramsMap.get('segment');
        paramsMap.remove('segment');
        paramsMap.put('Segment__c', segment);

        paramsMap.remove('isFromProServ');

        return paramsMap;
    }

    private static String getAssistCaseDescription(Opportunity opp) {
        String description = '';

        String accountLink = getObjectBaseUrl(opp.AccountId);
        String masterAccountLink = getObjectBaseUrl(opp.Account.Master_Account__c);
        String opptyLink = getObjectBaseUrl(opp.Id);
        String userLink = getObjectBaseUrl(UserInfo.getUserId());
        String primaryContact = getObjectBaseUrl(opp.Primary_Opportunity_Contact__c);

        description += 'Account: "' + accountLink + '" \n\n';
        description += 'Master Account: "' + masterAccountLink + '" \n\n';
        description += 'Opportunity: "' + opptyLink + '" \n\n';
        description += 'Sales Rep: "' + userLink + '" \n\n';
        description += 'Primary Contact: "' + primaryContact + '"';

        return description;
    }

    private static String getObjectBaseUrl(String objectId) {
        return String.isNotBlank(objectId)
            ? URL.getOrgDomainUrl().toExternalForm() + '/' + objectId
            : '-';
    }

    public static void sendDSREmail(Id caseId, String customerName, String emailAddress) {
        
        // Fetch FROM Email Address from Custom Metadata        
        DSR_Fixed_Records__mdt fixedRecord = [           
            SELECT Fixed_Account_UID__c, Fixed_Contact_Email__c, From_Email__c FROM DSR_Fixed_Records__mdt LIMIT 1            
        ];
            
        // Null check for custom metadata and FROM email       
        if (fixedRecord == null || String.isBlank(fixedRecord.From_Email__c)) {            
            throw new HandledException(CaseCreateAPIController.DSR_ERROR_MESSAGE_CUSTOM_METADATA_NOT_FOUND);            
        }
  
        String fromEmail = fixedRecord.From_Email__c;
        Id orgWideEmailId = getOrgWideEmailId(fromEmail); 
        if (orgWideEmailId == null) {            
            throw new HandledException(CaseCreateAPIController.ORG_WIDE_EMAIL_NOT_FOUND);            
        }
        
        // Get the current date and time in the desired format
        String dateOfReceipt = Datetime.now().format('MMMM dd, yyyy HH:mm z', 'en_US');
        
        String htmlBody = DSR_RESPONSE_EMAIL_NOTIFICATION_TEMPLATE;
        htmlBody = htmlBody.replace('{customerName}', customerName)
                           .replace('{dateOfReceipt}', dateOfReceipt);
        
        
        Messaging.SingleEmailMessage dsrEmail = new Messaging.SingleEmailMessage();
        
        if (caseId != null) {           
            htmlBody = htmlBody.replace('{supportTier}', 'RingCentral Tier 2 Support');                  
            // Use the email address passed from the request body
            dsrEmail.setToAddresses(new List<String>{ emailAddress });
        }
        
        dsrEmail.setSubject(DSR_RESPONSE_EMAIL_SUBJECT);
        dsrEmail.setHtmlBody(htmlBody);
        dsrEmail.setTreatBodiesAsTemplate(true);
        
        // Set FROM Email Address              
        dsrEmail.setOrgWideEmailAddressId(orgWideEmailId);          
        try {           
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ dsrEmail });                     
        } catch (Exception e) {                       
            throw new HandledException(CaseCreateAPIController.DSR_EMAIL_NOT_SENT);            
        }        
    }
    
    /**
    * Fetch Org-Wide Email Address ID based on email address.
    */   
    private static Id getOrgWideEmailId(String fromEmail) {       
        if (String.isBlank(fromEmail)) {                    
            return null;            
        }          
        OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :fromEmail LIMIT 1];            
        return orgWideEmail != null ? orgWideEmail.Id : null;   
    }

    public static void sendEmail(String emailTemplateName, List<Case> engageDigitalList, List<String> toAddressList){
        Emails__c emailSettings = Emails__c.getAll().get(emailTemplateName);
        EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:emailTemplateName];
        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>();

        for(Case caseObj : engageDigitalList){
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplate.Id, null,caseObj.Id);
            email.setSenderDisplayName(emailSettings.Description__c.split(';')[0]);
            email.setReplyTo(emailSettings.Email_Address__c);
            email.toAddresses = toAddressList;
            emailMsgList.add(email);
        }

        if (!emailMsgList.isEmpty()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMsgList);
            if (results[0].success){
                System.debug('+*+* The email was sent successfully.');
            } else {
                System.debug('+*+* The email failed to send: ' +  results[0].errors[0].message);
            }
        }
    }

    public static String icbCaseSubject(Opportunity opp) {
        Account acc = opp.isMultiproductTechnicalOpportunity__c ? opp.Account.Master_Account__r : opp.Account;
        return (String.isBlank(acc.inContact_Account_Id__c) ? NBU_CASE_SUBJECT : OrderHelper.TYPE_CHANGE_ORDER) + ' ' + acc.Name;
    }

    public static String icbCaseOrderType(String inContactAccId) {
        return String.isBlank(inContactAccId) ? OrderHelper.TYPE_NEW_ORDER : OrderHelper.TYPE_CHANGE_ORDER;
    }

    public static Long icbCaseBuId(String inContactAccId) {
        return String.isBlank(inContactAccId) ? null : Long.valueOf(inContactAccId);
    }

    public static Id createICBCase(
        Opportunity opp,
        String defaultTimeZone,
        String geoRegion,
        String description,
        String contactCenterNumber,
        String subject,
        String implementationTeam,
        String inContactSegment
    ) {
        Case defaultCaseValues = (Case) Case.SObjectType.newSObject(null, true);

        String ringCentralAccountNumber = StringHelper.defaultString(
            opp.NumberToBeRCMainNumber__c,
            opp.Account.RC_Account_Number__c
        );

        // Do not use SObjectBuilder here, as it cannot set inContact_BU_ID__c with long type correctly and error occurs during insert
        Account masterAcc = opp.isMultiproductTechnicalOpportunity__c ? opp.Account.Master_Account__r : opp.Account;
        Case cs = new Case(
            AccountId = masterAcc.Id,
            Opportunity_Reference__c = opp.isMultiproductTechnicalOpportunity__c ? opp.MasterOpportunity__c : opp.Id,
            Default_Time_Zone__c = defaultTimeZone,
            Geo_Region__c = geoRegion,
            inContact_Segment__c = inContactSegment,
            Implementation_Team__c = implementationTeam,
            Contact_Center_Number__c = contactCenterNumber,
            RingCentral_Account_Number__c = ringCentralAccountNumber,
            Description = description,
            Subject = subject,
            RecordTypeId = RT_ID_INCONTACT_ORDER,
            Customer_Notification__c = true,
            Origin = CASE_ORIGIN_WEB,
            Status = CASE_STATUS_SUBMIT,
            CC_Order_Type__c = icbCaseOrderType(masterAcc.inContact_Account_Id__c),
            Contact_Name__c = (String) defaultCaseValues.get(Case.Contact_Name__c),
            inContact_BU_ID__c = icbCaseBuId(masterAcc.inContact_Account_Id__c)
        );

        insert cs;
        return cs.Id;
    }

    public static Id createICBCase(Opportunity opp, BillingWrappers.AccountParams accParams, String description) {
        return createICBCase(
            opp,
            accParams.timeZoneValue,
            accParams.geoRegionValue,
            description,
            accParams.contactCenterNumber,
            icbCaseSubject(opp),
            accParams.implementationTeamValue,
            accParams.nicSegmentValue
        );
    }

    public static Id createICBCase(IcbHelper.ICBRequestCaseBody caseBody, Opportunity opp) {
        String defaultTimeZone = String.isBlank(caseBody.defaultTimeZone) ? EMPTY_TIMEZONE_VALUE : caseBody.defaultTimeZone;
        String contactCenterNumber = StringHelper.defaultString(
            caseBody.contactCenterNumber,
            opp.NumberToBeCCNumber__c
        );
        return createICBCase(
            opp,
            defaultTimeZone,
            caseBody.geoRegion,
            caseBody.description,
            contactCenterNumber,
            caseBody.subject ?? icbCaseSubject(opp),
            caseBody.implementationTeam,
            caseBody.inContactSegment
        );
    }

    public static Set<String> getAllowedRecordTypesForContact(Contact contact) {
        String portal = isBTBrand(contact) ? PORTAL_BT_SUPPORT : PORTAL_MAIN_SUPPORT;
        return getSCRecordTypes(portal);
    }
    
    public static Boolean isBTBrand(Contact contact) {
        if (contact == null) {
            return false;          
        }
        Contact dbContact = contact;        
        if (contact.Id != null) {
            List<Contact> contacts = new ContactSelector()
                .selectContactById(new List<Object>{contact.Id})
                .executeQuery();
            if (!contacts.isEmpty()){
                dbContact = contacts[0];
            } 
        }       
        return dbContact.Account != null &&
            String.isNotBlank(dbContact.Account.RC_Brand__c) &&
            dbContact.Account.RC_Brand__c.equalsIgnoreCase(BRAND_BT_BUSINESS);
    }
    
    public static Set<String> getSCRecordTypes(String portal) {
        Set<String> response = new Set<String>();
        for (SC_Case_Record_Type__mdt caseRT : SC_Case_Record_Type__mdt.getAll().values()) {
            if (String.isBlank(portal)) {
                response.add(caseRT.MasterLabel); 
            } else if (caseRT.Supported_Portal__c != null) {
                List<String> portals = caseRT.Supported_Portal__c.split(';');
                for (String p : portals) {
                    if (p.trim().equalsIgnoreCase(portal.trim())) {
                        response.add(caseRT.MasterLabel);
                        break; 
                    }
                }
            }
        }
        return response;
    }

    public static List<String> getCaseSeverityOptions() {
        List<String> caseSeverityOptions = new List<String>();

        for(Case_Severity__mdt caseSeverity : Case_Severity__mdt.getAll().values()) {
            caseSeverityOptions.add(caseSeverity.MasterLabel);
        }

        return caseSeverityOptions;
    }

    @AuraEnabled
    public static Boolean isEscalatable(Case cs) {
        return !isInSlaPeriod(cs) && !cs.IsEscalated && !cs.IsClosed;
    }

    @AuraEnabled
    public static String getEscalateErrorMessage(Case cs) {

        String reason = '';

        if (cs.IsClosed) {
            reason = CASE_CLOSED_CANNOT_BE_ESCALATED_TEXT;
        } else if (cs.IsEscalated) {
            reason = CASE_IS_ALREADY_ESCALATED_TEXT;
        } else if (isInSlaPeriod(cs)) {
            reason = CASE_CANNOT_BE_ESCALATED_BEFORE_SLA_TEXT;
        }

        return reason;
    }

    public static Boolean isInSlaPeriod(Case cs) {
        return cs.CreatedDate > Datetime.now().addDays(DAYS_TO_SLA_BREACHED * -1);
    }

    public static Boolean hasAlreadyBeenReopened(Case cs) {
        Boolean result = (Test.isRunningTest() && cs.Subject.equalsIgnoreCase(SUBJECT_HAS_ALREADY_BEEN_REOPENED));

        for (CaseHistory csHistory : (List<CaseHistory>) new CaseHistorySelector()
            .selectCaseHistoriesByCaseIdAndFieldAndNewValue(new Object[]{cs.Id,STATUS_FIELD_APINAME})
            .executeQuery()
        ) {
            if (CASE_STATUS_REOPENED.equalsIgnoreCase(csHistory.newValue.toString())) {
                result = true;
                break;
            }
        }

        return result;
    }

    @AuraEnabled
    public static Boolean isReopenable(Case cs) {
        return cs.IsClosed
            && (cs.ClosedDate > Datetime.now().addDays(DAYS_FROM_WHICH_A_CASE_CAN_BE_REOPENED * -1) )
            && !hasAlreadyBeenReopened(cs);
    }

    @AuraEnabled
    public static String getReopenErrorMessage(Case cs) {

        String reason = null;

        if (!isReopenable(cs)) {
            if (cs.Status.equalsIgnoreCase(CASE_STATUS_REOPENED)) {
                reason = CASE_IS_ALREADY_REOPENED_TEXT;
            } else if (!cs.IsClosed) {
                reason = CASE_IS_NOT_CLOSED;
            } else if(hasAlreadyBeenReopened(cs)){
                reason = CASE_HAS_ALREADY_BEEN_REOPENED_TEXT;
            } else {
                reason = CASE_CLOSED_CANNOT_BE_REOPENED_TEXT;
            }
        }

        return reason;
    }

    @AuraEnabled
    public static List<String> getFunctionValues() {
        List<String> values = new List<String>();

        List<Case_Re_Open_function__mdt> functionsMdt = Case_Re_Open_function__mdt.getAll().values();

        for (Case_Re_Open_function__mdt functionMdt : functionsMdt) {
            values.add(functionMdt.Value__c);
        }

        return values;
    }

    public static Map<String, String> getTranslatedLabelByValue(String sObjectApiName, String recordTypeName, String lang, String fields, Boolean hasDependentField) {
        Map<String, String> translatedLabelByValue = new Map<String, String>();

        //Translate it only if it is not the default language.
        if (!DEFAULT_LANG.equalsIgnoreCase(lang)) {
            List<PicklistSiteopsController.Picklist> picklistValues = SFDescribeHelper.getPicklistOptions(sObjectApiName, recordTypeName, fields, lang, hasDependentField);

            for (PicklistSiteopsController.Picklist picklistValue : picklistValues) {
                for (SCWRappers.BaseOption option : picklistValue.Options) {
                    translatedLabelByValue.put(option.Value, option.Label);
                }
            }

        }

        return translatedLabelByValue;
    }

    public static Map<String, String> getTranslatedLabelByValue(List<String> fieldApiNames, String lang) {
        Map<String, String> translatedLabelByValue = new Map<String, String>();

        //Translate it only if it is not the default language.
        if (!DEFAULT_LANG.equalsIgnoreCase(lang)) {
            List<SC_Translation__mdt> mdtTranslations = SC_Translation__mdt.getAll().values();

            List<String> fieldApiNamesFormatted = new List<String>();

            for (String fieldApiName : fieldApiNames) {
                fieldApiNamesFormatted.add(fieldApiName.toLowerCase());
            }

            for (SC_Translation__mdt mdtTranslation : mdtTranslations) {
                if (mdtTranslation.Language__c.toLowerCase() == lang.toLowerCase()
                    && fieldApiNamesFormatted.contains(mdtTranslation.Field__c.toLowerCase())
                ) {
                    translatedLabelByValue.put(mdtTranslation.Value__c, mdtTranslation.Label__c);
                }
            }
        }

        return translatedLabelByValue;
    }

    public static String getTranslatedLabel(Map<String, String> translatedLabelByValue, String value) {
        return translatedLabelByValue.containsKey(value) ?
            translatedLabelByValue.get(value) :
            value;
    }

    public static Boolean isValidLanguage(String languageToValidate) {
        //This is hardcoded because Salesforce doesn't provide an efficient way to retrieve all available languages for the org.
        //The workaround is to get all picklist values for User.LanguageLocaleKey and it takes almost 3 seconds to execute.
        //This code just takes 150ms to execute.
        List<String> validLanguages = new String[]{
            'sq','af','am','ar_dz','ar_bh','ar_eg','ar_iq','ar_jo','ar_kw','ar_lb','ar_ly','ar_ma','ar_om','ar_qa','ar_sa','ar_sd',
            'ar_sy','ar_tn','ar_ae','ar_ye','hy','eu','bs','bn','my','ca','zh_hk','zh_sh','zh_my','nl_be','en_au','en_be','en_ca',
            'en_cy','en_de','en_hk','en_in','en_ie','en_il','en_my','en_mt','en_nl','en_nz','en_ph','en_sh','en_za','en_ae','et','fa',
            'fr_be','fr_ca','fr_lu','fr_ma','fr_ch','ka','de_at','de_be','de_lu','de_ch','el_cy','kl','gu','haw','ht','hi','hmn','is',
            'ga','it_CH','kn','kk','km','lv','lt','lb','mk','ms','ml','mt','mr','sh_me','pa','ro_md','rm','ru_am','ru_by','ru_KZ',
            'ru_kg','ru_lt','ru_md','ru_pl','ru_ua','sm','sr','sh','es_ar','es_bo','es_cl','es_co','es_cr','es_do','es_ec','es_sv',
            'es_gt','es_hn','es_ni','es_pa','es_py','es_pe','es_pr','es_us','es_uy','es_ve','sw','tl','ta','mi','te','ur','cy','xh',
            'ji','zu','zh_cn','zh_tw','da','nl_nl','en_us','fi','fr','de','it','ja','ko','no','pt_br','ru','es','es_mx','sv','th'
        };


        return validLanguages.contains(languageToValidate.toLowerCase());
    }

	public static void createCaseContactAttempts(Map<Id, Case> newCaseMap) {
        Case_Activity__c[] caseActivities = new Case_Activity__c[]{};

        for (Case newCase : newCaseMap.values()) {
            if (newCase.RecordTypeId == RT_ID_CLOSE_LOOP_FEEDBACK_MEDALLIA_RELATIONSHIP) {
                for (Integer i = 0; i < 3; i++) {
                    caseActivities.add(new Case_Activity__c(
                        Name = 'Contact attempt #' + (i+1),
                        Case__c = newCase.Id,
                        Status__c = 'New',
                        Assigned_To__c = String.valueOf(newCase.OwnerId).startsWith('00G') ? null : newCase.OwnerId,
                        RecordTypeId = CaseHelper.RT_ID_CASE_ACTIVITY_CONTACT_ATTEMPT
                    ));
                }
            }
        }

        if (caseActivities.size() > 0) {
            insert caseActivities;
        }
	}

    @AuraEnabled
    public static Response createProblemCase(Id leadId, Id accId, Id oppId, String description, String caseSubject) {

        if (caseSubject == 'Wholesale_Partner_Operations') {
            return createWholesaleProblemCase(accId, description);
        }

        Response result = new Response();
        Opportunity opp;
        if (oppId != null) {
            opp = (Opportunity) new OpportunitySelector()
                .selectOpportunitiesByIds(new Set<Id>{ oppId })
                .executeQuery()
                .get(0);
        }

        Profile currentUserProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<String>{ UserInfo.getProfileId() })
            .executeQuery()
            .get(0);

        Boolean isDealDeskUser = ProfileHelper.DEAL_DESK_PROFILES.contains(currentUserProfile.Name);
        Case problemCase = createCase(accId, opp, description, caseSubject, isDealDeskUser);

        if (leadId != null) {
            problemCase.Description = 'Lead link: ' + StringHelper.createObjectLink(leadId) + '\n' + problemCase.Description;
        } else if (oppId != null) {
            problemCase.Description = 'Opportunity link: ' + StringHelper.createObjectLink(oppId) + '\n' + problemCase.Description;
        }
        try {
            insert problemCase;
            Case createdProblemCase = (Case) new CaseSelector()
                .selectCasesByIds(new Set<Id>{problemCase.Id})
                .executeQuery()
                .get(0);

            result.addMessage('is successfully created. Thank you for the report.', 'success');
            result.setData('caseId', createdProblemCase.Id);
            result.setData(CaseHelper.CASE_NUMBER, createdProblemCase.CaseNumber);
        } catch (Exception e) {
            result.error(e.getTypeName(), e.getMessage());
        }
        return result;
    }

    public static Response createWholesaleProblemCase(Id accId, String description){
        Response result = new Response();

        PartnerOperationsLog__c partnerOperationsLog = (PartnerOperationsLog__c)
            new QueryFactory(PartnerOperationsLog__c.SObjectType)
                .selectFields(new List<String> {'Opportunity__c'})
                .setCondition('Account__c =:bind0 AND isRejected__c=false AND isCompleted__c=false')
                .setQueryBindings(new List<Object>{new Set<Id>{accId}})
                .executeQuery()
                .get(0);

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{partnerOperationsLog.Opportunity__c})
            .executeQuery()
            .get(0);

        Case problemCase = createCase(
            accId,
            opp,
            description,
            'Wholesale_Partner_Operations',
            false
        );

        try {
            insert problemCase;
            result.addMessage('Thank you for the report. Case is successfully created', 'success');
        } catch (Exception e) {
            result.error(e.getTypeName(), e.getMessage());
        }
        return result;
    }

    public static Case createCase(Id accId, Opportunity opp, String description, String caseSubject, Boolean isDealDesk) {

        return (Case) new SObjectBuilder(Case.sObjectType)
        .setFields(new Map<SObjectField, Object> {
            Case.AccountId => accId,
            Case.Application__c => CASE_APPLICATION_SALESFORCE,
            Case.Case_Category__c => CASE_CATEGORY_SYSTEMS,
            Case.Case_Severity__c => CASE_SEVERITY_MEDIUM,
            Case.Status => CASE_STATUS_NEW,
            Case.ContactId => opp?.Primary_Opportunity_Contact__c,
            Case.Description => description,
            Case.Opportunity_Reference__c => opp?.Id,
            Case.Origin => CASE_ORIGIN_AUTO_EMAIL,
            Case.OwnerId => isDealDesk ? DealDeskCaseGenerator.BIZ_SERV_INNOVATION_QUEUE.QueueId : DealDeskCaseGenerator.DEAL_DESK_QUEUE.QueueId,
            Case.RecordTypeId => isDealDesk ? RT_ID_INTERNAL_BUSINESS_SERVICES : RT_ID_DEALDESK_CASE,
            Case.Subject => caseSubject
        })
        .build()
        .getRecord();
    }

    @AuraEnabled
    public static Response getDealAndOrderSupportRecordTypeId() {
        Response resp = new Response();
        try {
            resp.setData('dealAndOrderSupportRecordTypeId', RT_ID_DEAL_AND_ORDER_SUPPORT);
        } catch (Exception e) {
            resp.error(e);
        }
        return resp;
    }

    public static DateTime getOriginalTime(Case cs, String field) {
        String dateFromField = (String) cs.get(field);
        List<String> splitedTime = dateFromField.split(':');
        Integer hours = Integer.valueOf(splitedTime[0]);
        Integer minutes = Integer.valueOf(splitedTime[1]);
        Integer seconds = Integer.valueOf(splitedTime[2]);
        DateTime originalDate = cs.CreatedDate.addSeconds(seconds).addMinutes(minutes).addHours(hours);

        return originalDate;
    }

    public static String getTimeBetweenDates(DateTime oldDate, DateTime newDate) {
        return HelperUtils.getTimeBetweenDates(oldDate, newDate);
    }

    public static Boolean isUserIsQueuesMember(Set<String> queuesSet) {
        List<Object> queryBindings = new List<Object>();
        queryBindings.add(Userinfo.getUserId());
        queryBindings.add('Queue');
        queryBindings.add(queuesSet);
        List<GroupMember> groupMembersList = new GroupMemberSelector()
            .selectGroupMemberBasedOnUserAndGroupName(queryBindings)
            .executeQuery();
        return !groupMembersList.isEmpty();
    }

    public static Map<SObjectField, Object> prepareCaseFields(BillingWrappers.CaseCreateParams params) {
        Map<String, Object> paramsAsMap = getParamsAsMap(params);
        Boolean isFromProServ = paramsAsMap.get('isFromProServ') == true;
        paramsAsMap = isFromProServ
            ? addCreateCaseFromProServMapFields(paramsAsMap)
            : addSalesOrderExceptDescQueueMapFields(paramsAsMap);
        Map<SObjectField, Object> fieldsMap = buildCaseFieldsMap(paramsAsMap);

        return fieldsMap;
    }

    public static Boolean isUcProServCase(Case cs) {
        return cs.Subject.toLowerCase().contains(SUBJECT_PS_UC_QUOTE_REQUESTED.toLowerCase());
    }

    public static Boolean isCcProServCase(Case cs) {
        return cs.Subject.toLowerCase().contains(SUBJECT_PS_CC_QUOTE_REQUESTED.toLowerCase());
    }

    public static Boolean isUcProServCancelationCase(Case cs) {
        return cs.Subject.toLowerCase().contains(SUBJECT_PS_UC_QUOTE_CANCELATION.toLowerCase());
    }

    public static Boolean isCcProServCancelationCase(Case cs) {
        return cs.Subject.toLowerCase().contains(SUBJECT_PS_CC_QUOTE_CANCELATION.toLowerCase());
    }

    public static void sendProServCaseEmail(Case cs) {
        String emailTemplateApiName;
        if(isUcProServCase(cs)) {
            emailTemplateApiName = QuotingToolQuoteApexController.PROSERV_ENGAGED_EMAIL_API_NAME;
        } else if (isCcProServCase(cs)) {
            emailTemplateApiName = QuotingToolQuoteApexController.CC_PROSERV_ENGAGED_EMAIL_API_NAME;
        } else if (isUcProServCancelationCase(cs)) {
            emailTemplateApiName = QuotingToolQuoteApexController.PROSERV_CANCELLED_EMAIL_API_NAME;
        } else if (isCcProServCancelationCase(cs)) {
            emailTemplateApiName = QuotingToolQuoteApexController.CC_PROSERV_CANCELLED_EMAIL_API_NAME;
        }
        if (String.isNotBlank(emailTemplateApiName)) {
            QuotingToolQuoteApexController.sendMail(new Map<String, String>{
                    'templateApiName' => emailTemplateApiName,
                    'opportunityId' => cs.Opportunity_Reference__c,
                    'isProServInNGBS' => 'true'
            });
        }
    }
}