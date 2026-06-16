public class IcbHelper {
    public static final String STATUS_SUCCESS = 'success';
    public static final String STATUS_ERROR = 'error';
    public static final String SEVERITY_ERROR = 'error';

    public static final String WRONG_JSON_FORMAT = 'wrong json format';

    //Validation error info
    public static final String EMPTY_REQUEST = 'Empty request';
    public static final String EMPTY_REQUEST_DETAILS = 'Request does not contain case numbers';
    public static final String OPPORTUNITY_ID_IS_MISSING = 'Opportunity id is missing';
    public static final String CASE_NUMBER_IS_MISSING = 'Case number is missing';
    public static final String OPPORTUNITY_NOT_FOUND = 'Opportunity not found';
    public static final String CASE_NOT_FOUND = 'Case not found';
    public static final String EMPTY_MESSAGE_PARAM = 'Message parameter is required';
    public static final String EMPTY_MESSAGE_PARAM_DETAILS = 'Message parameter equals to null';
    public static final String CASE_TO_OPPORTUNITY_MISMATCH = 'Case is not linked to opportunity';
    public static final String CASE_TO_OPPORTUNITY_MISMATCH_DETAILS =
        'Case Opportunity_Reference__c field value does not match affected opportunity id';
    public static final String SHARING_NOT_COMPLETED = 'Sharing is not completed';
    public static final String SYNC_TO_ICB_IS_NOT_FINISHED = 'Sync to ICB is not finished';
    public static final String SYNC_TO_ICB_IS_NOT_FINISHED_DETAILS = 'Previous step was not completed. Please finish Sync with ICB process';
    public static final String CASE_WAS_NOT_CREATED_DUE_TO_SUSPENSION = 'Case was not created due to suspension';
    public static final String OPPORTUNITY_PROVISIONING_IS_PAUSED = 'Opportunity provisioning is paused.';
    public static final String OPPORTUNITY_PROVISIONING_IS_PAUSED_DETAILS = 'Opportunity provisioning is paused.'
        + ' Changes will be done automatically after the current billing period will be invoiced.';

    public static final String OPPORTUNITY_SYNC_WITH_NGBS_FAILED = 'Error during Process Order';
    public static final String OPPORTUNITY_SYNC_WITH_NGBS_FAILED_DETAILS = 'There was an error during SyncWIthNGBS,'
        + ' and now it is not possible to complete this due to timeout.';

    public static final String CASE_CREATION_SUCCESS = 'Case successfully created ';
    public static final String SYNC_WITH_NGBS_ERROR = 'While Process Order an error has occurred: {0}';

    public static final String CC_SYNC_STATUS_NOT_APPLICABLE = 'Not applicable';
    public static final String CC_SYNC_STATUS_NOT_STARTED = 'Not Started';
    public static final String CC_SYNC_STATUS_STARTED = 'Started';
    public static final String CC_SYNC_STATUS_COMPLETED = 'Completed';
    public static final String SIGNUP_NIC_ERROR = 'Error - Nice Signup';
    public static final String SIGNUP_NGBS_DISCOUNTS_ERROR = 'Error - Discount Creation';
    public static final String SIGNUP_NGBS_ACTIVATION_ERROR = 'Error - Account Activation';
    public static final String SIGNUP_NGBS_LIMITS_ERROR = 'Error - Limit Update';
    public static final String SIGNUP_ICB_ACCOUNT_CREATION_ERROR = 'Error - ICB Account Creation';
    public static final String SIGNUP_SFDC_SYNC_ERROR = 'Error - Sync to SF';
    public static final String SIGNUP_END_ERROR = 'Error - Signup Failed';
    public static final String CHANGE_NIC_ERROR = 'Error - Nice Sync';
    public static final String CHANGE_SFDC_CASE_ERROR = 'Error - Case Creation';
    public static final String CHANGE_SFDC_NGBS_ERROR = 'Error - NGSB Sync';
    public static final String CHANGE_ICB_ACCOUNT_CREATION_ERROR = 'Error - ICB Account Activation';
    public static final String CHANGE_END_ERROR = 'Error - Sync Failed- limits update';
    public static final String DEFAULT_SYNC_ERROR = 'Error - Sync to NGBS';

    public enum ICBEventType {
        SIGNUP_END_OK,
        CHANGE_NIC_OK,
        CHANGE_NIC_SKIP,

        // errors
        CHANGE_END_ERROR,
        CHANGE_ICB_ERROR,
        CHANGE_ICB_ACCOUNT_CREATION_ERROR,
        CHANGE_INVOICE_WAITING,
        CHANGE_NIC_ERROR,
        CHANGE_NIC_WAITING_TOO_LONG,
        CHANGE_SFDC_NGBS_ERROR,
        CHANGE_SFDC_CASE_ERROR,
        SIGNUP_END_ERROR,
        SIGNUP_ICB_ACCOUNT_CREATION_ERROR,
        SIGNUP_NGBS_ERROR,
        SIGNUP_NGBS_DISCOUNTS_ERROR,
        SIGNUP_NGBS_ACTIVATION_ERROR,
        SIGNUP_NGBS_LIMITS_ERROR,
        SIGNUP_SFDC_SYNC_ERROR,
        SIGNUP_NIC_ERROR
    }

    public static final Map<ICBEventType, String> CC_SYNC_STATUSES = new Map<ICBEventType, String> {
        ICBEventType.SIGNUP_NIC_ERROR => SIGNUP_NIC_ERROR,
        ICBEventType.SIGNUP_NGBS_DISCOUNTS_ERROR => SIGNUP_NGBS_DISCOUNTS_ERROR,
        ICBEventType.SIGNUP_NGBS_ACTIVATION_ERROR => SIGNUP_NGBS_ACTIVATION_ERROR,
        ICBEventType.SIGNUP_ICB_ACCOUNT_CREATION_ERROR => SIGNUP_ICB_ACCOUNT_CREATION_ERROR,
        ICBEventType.SIGNUP_SFDC_SYNC_ERROR => SIGNUP_SFDC_SYNC_ERROR,
        ICBEventType.SIGNUP_END_ERROR => SIGNUP_END_ERROR,
        ICBEventType.CHANGE_NIC_ERROR => CHANGE_NIC_ERROR,
        ICBEventType.CHANGE_SFDC_CASE_ERROR => CHANGE_SFDC_CASE_ERROR,
        ICBEventType.CHANGE_SFDC_NGBS_ERROR => CHANGE_SFDC_NGBS_ERROR,
        ICBEventType.CHANGE_ICB_ACCOUNT_CREATION_ERROR => CHANGE_ICB_ACCOUNT_CREATION_ERROR,
        ICBEventType.CHANGE_END_ERROR => CHANGE_END_ERROR,
        ICBEventType.SIGNUP_NGBS_LIMITS_ERROR => SIGNUP_NGBS_LIMITS_ERROR,
        ICBEventType.SIGNUP_END_OK => CC_SYNC_STATUS_COMPLETED
    };

    public class IcbPollRequest {
        public List<String> caseNumbers;
    }

    public class ICBCaseRequest {
        public Id opportunityId;
        public String caseType;
        public ICBRequestCaseBody caseBody;
    }

    public class ICBRequestCaseBody {
        public String subject;
        public String defaultTimeZone;
        public String geoRegion;
        public String inContactSegment;
        public Boolean customerNotification;
        public String contactEmail;
        public String implementationTeam;
        public String description;
        public String contactCenterNumber;
    }

    public class IcbEventRequest {
        public String type;
        public String message;
        public String messageDetails;
        public String oppId;
        public String caseNumber;
    }

    public class IcbCase {
        @AuraEnabled public String caseId;
        @AuraEnabled public String caseNumber;
        public String accountName;
        public String opportunityReference;
        public String ringCentralUID;
        public String ringCentralAccountNumber;
        @AuraEnabled public String subject;
        public String caseOwner;
        @AuraEnabled public String status;
        public String defaultTimeZone;
        public String geoRegion;
        public String caseOrigin;
        public String contactCenterNumber;
        @AuraEnabled public String inContactBUID;
        public String inContactCluster;
        public String inContactSegment;
        @AuraEnabled public String inContactStatus;
        public Boolean customerNotification;
        public String contactEmail;
        public String implementationTeam;
        public String icCaseNumber;
        public String ccOrderType;
        public String productOrService;
        public String description;
        public String provisionDate;
        public String sharedCaseId;
        @AuraEnabled public String sharingStatus;
        @AuraEnabled public String sharingStartDate;

        public IcbCase(Case caseSObject) {
            if (caseSObject == null) {
                return;
            }
            this.caseNumber = caseSObject.CaseNumber;
            this.caseId = caseSObject.Id;
            this.accountName = caseSObject.Account.Name;
            this.opportunityReference = caseSObject.Opportunity_Reference__c;
            this.ringCentralUID = AccountHelper.isMPUBAccount(caseSObject.AccountId)
                ? caseSObject.Account.RC_User_Id__c
                : caseSObject.Account.Internal_Enterprise_Account_ID__c;
            this.ringCentralAccountNumber = caseSObject.RingCentral_Account_Number__c;
            this.subject = caseSObject.Subject;
            this.caseOwner = caseSObject.OwnerId;
            this.status = caseSObject.Status;
            this.defaultTimeZone = caseSObject.Default_Time_Zone__c;
            this.geoRegion = caseSObject.Geo_Region__c;
            this.caseOrigin = caseSObject.Origin;
            this.contactCenterNumber = caseSObject.Contact_Center_Number__c;
            this.inContactBUID = String.valueOf(caseSObject.inContact_BU_ID__c);
            this.inContactCluster = caseSObject.inContact_Cluster__c;
            this.inContactSegment = caseSObject.inContact_Segment__c;
            this.inContactStatus = caseSObject.inContact_Status__c;
            this.customerNotification = caseSObject.Customer_Notification__c;
            this.contactEmail = caseSObject.Contact_Name__c;
            this.implementationTeam = caseSObject.Implementation_Team__c;
            this.icCaseNumber = caseSObject.IC_Case_Number__c;
            this.ccOrderType = caseSObject.CC_Order_Type__c;
            this.productOrService = caseSObject.Product_or_Service__c;
            this.description = caseSObject.Description;
            this.provisionDate = String.valueOf(caseSObject.Provision_Date__c);
        }

        public IcbCase(Case caseSObject, PartnerNetworkRecordConnection pnrc) {
            this(caseSObject);
            if (pnrc == null) {
                return;
            }
            this.sharingStatus = pnrc.Status;
            this.sharedCaseId = pnrc.PartnerRecordId;
            this.sharingStartDate = String.valueOf(pnrc.StartDate);
        }
    }

    public class IcbResponseParamsData extends IcbResponseParams {
        public IcbData data;

        public IcbResponseParamsData(IcbData data, String status) {
            super(status);
            this.data = data;
        }

        public IcbResponseParamsData(IcbData data, String status, List<IcbMessage> messages) {
            super(status, messages);
            this.data = data;
        }
    }

    public class IcbData {
        public IcbCase caseBody;
        public List<IcbCase> cases;

        public IcbData(IcbCase icbCase) {
            caseBody = icbCase;
        }

        public IcbData(List<IcbCase> icbCases) {
            cases = icbCases;
        }
    }

    public virtual class IcbResponseParams  {
        public String status;
        public List<IcbMessage> messages;

        public IcbResponseParams(String status, List<IcbMessage> messages) {
            this.status = status;
            this.messages = messages;
        }

        public IcbResponseParams(String status) {
            this.status = status;
        }
    }

    public class IcbMessage {
        public String severity;
        public String message;
        public String messageDetails;

        public IcbMessage(String severity, String message, String messageDetails) {
            this.severity = severity;
            this.message = message;
            this.messageDetails = messageDetails;
        }
    }

    public class ICBChangeOrderResponse {
        public String status;
        public List<ICBResponseMessage> messages;
        public Object data;
        public String fullRedirectUrl;
    }

    public class ICBResponseMessage {
        public String severity;
        public String message;
        public String messageDetails;
    }

    public class ICBResponseError {
        public String code;
        public String message;
        public ICBResponseError[] messages;
        public String description;
    }

    private static void setResponseBody(IcbResponseParams params) {
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(params, true));
    }

    public static void setResponse(IcbCase icbCase, String status) {
        setResponseBody(
            new IcbResponseParamsData(new IcbData(icbCase), status)
        );
    }

    public static void setResponse(Case caseSObject, PartnerNetworkRecordConnection pnrc) {
        setResponseBody(
            new IcbResponseParamsData(
                new IcbData(
                    new IcbCase(
                        caseSObject,
                        pnrc
                    )
                ),
                STATUS_SUCCESS
            )
        );
    }

    public static void setResponse(List<IcbCase> icbCases, String status) {
        setResponseBody(new IcbResponseParamsData(new IcbData(icbCases), status));
    }

    public static void setResponse(String status, List<IcbMessage> messages) {
        setResponseBody(new IcbResponseParams(status, messages));
    }

    public static void setResponse(String status) {
        setResponseBody(new IcbResponseParams(status));
    }

    public static void handleError(Exception e) {
        handleError(
            createErrorList(e.getMessage(), e.getStackTraceString())
        );
    }

    public static void handleError(JSONException e) {
        handleError(
            createErrorList(WRONG_JSON_FORMAT, e.getMessage() + ' ' + e.getStackTraceString())
        );
    }

    public static void handleError(List<IcbMessage> errorMessages) {
        setResponse(
            STATUS_ERROR,
            errorMessages
        );
    }
    public static void handleSuspension(List<IcbMessage> errorMessages) {
        setResponse(
            STATUS_SUCCESS,
            errorMessages
        );
    }

    public static List<IcbMessage> createErrorList(String message, String details) {
        return createResponseList(
            SEVERITY_ERROR,
            message,
            details
        );
    }

    public static List<IcbMessage> createResponseList(String severity, String message, String details) {
        return new List<IcbMessage> {
            new IcbMessage(
                severity,
                message,
                details
            )
        };
    }

    @AuraEnabled
    public static Response getRequestFormLink() {
        final ICB_Settings__c ICB_SETTINGS = ICB_Settings__c.getInstance();

        Response result = new Response();
        result.setData('formLink', StringHelper.safeString(ICB_SETTINGS.FormLink__c));
        return result;
    }

    public static void startAutoSync(Id quoteId) {
        if (!Test.isRunningTest()) {
            SyncWithNGBSQueueable.enqueueAutoSyncWithNGBS(quoteId);
        }
    }

    public static Case selectICBCase(Opportunity opp) {
        Id oppId = opp.IsMultiProductTechnicalOpportunity__c ? opp.MasterOpportunity__c : opp.Id;
        return (Case) new ListOptional(new CaseSelector()
            .selectCasesByRecordTypeAndOpportunityIds(CaseHelper.RT_ID_INCONTACT_ORDER, new Set<Id> { oppId })
            .executeQuery()
        ).getFirst();
    }

    public static Opportunity selectOpportunityForInContactCaseSharing(Id oppId) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForInContactCaseSharing(oppId)
            .executeQuery()
        ).getFirst();
    }

    @future
    public static void updateRCCCSyncStatus(Id oppId, String rcccSyncStatus) {
        Triggers.switchOff();
        update new Opportunity(
            Id = oppId,
            RCCCSyncStatus__c = rcccSyncStatus
        );
        Triggers.switchOn();
    }
}