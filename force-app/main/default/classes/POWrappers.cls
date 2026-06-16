public with sharing class POWrappers {
    public final static String PAYMENT_METHOD_INV_FUNNEL = 'Inv';
    public final static String PAYMENT_METHOD_INV_BOB_FUNNEL = 'InvB';
    public final static String PAYMENT_METHOD_WHOLESALE_FUNNEL = 'InvW';
    public final static String PAYMENT_METHOD_DD_FUNNEL = 'DD';
    public final static String PAYMENT_METHOD_CC_FUNNEL = 'CC';

    public static final String DEFAULT_SAF_ID = '00000';
    public static final String OID_PREFIX = 'OID[0]=';
    public static final String TRIAL_DURATION_PREFIX = 'D_';
    public static final String TARGET_PACKAGE_DURATION = 'Days';
    public static final String MONTHLY_AMOUNT_LIMIT = 'MONTHLY_AMOUNT_LIMIT';
    public static final String DURATION_MONTHS = 'Months';
    public static final String NGBS_ISO_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
    public static final String INVOICE = 'Invoice';

    //SignUpRequestBody fields
    public static final String FIELD_NAME_SPID = 'SPID';
    public static final String FIELD_NAME_OPPID = 'OPPID';
    public static final String FIELD_NAME_PACKAGE_NAME = 'PackageName';
    public static final String FIELD_NAME_PACKAGE_ID = 'PackageID';
    public static final String FIELD_NAME_PACKAGE_VERSION = 'PackageVersion';
    public static final String FIELD_NAME_OFFER_TYPE = 'OfferType';
    public static final String FIELD_NAME_TRIAL_PACKAGE_ID = 'TrialPackageID';
    public static final String FIELD_NAME_TRIAL_PACKAGE_VERSION = 'TrialPackageVersion';
    public static final String FIELD_NAME_TARGET_PACKAGE_ID = 'TargetPackageId';
    public static final String FIELD_NAME_TARGET_PACKAGE_VERSION = 'TargetPackageVersion';
    public static final String FIELD_NAME_TARGET_PACKAGE = 'TargetPackage';
    public static final String FIELD_NAME_PACKAGE_DURATION_UNIT = 'PackageDurationUnit';
    public static final String FIELD_NAME_PACKAGE_DURATION_VALUE = 'PackageDurationValue';
    public static final String FIELD_NAME_DEFAULT_PACKAGE_LIMITS = 'DefaultPackageLimits';
    public static final String FIELD_NAME_IS_TERMINATION_OPPORTUNITY = 'isTerminationOpportunity';
    public static final String FIELD_NAME_UBRAND_ID = 'uBrandId';
    public static final String FIELD_NAME_PID = 'PID';
    public static final String FIELD_NAME_SAFID = 'SAFID';
    public static final String FIELD_NAME_PAYMENT_METHOD_TYPE = 'PaymentMethodType';
    public static final String FIELD_NAME_ENTERPRISE_ACCOUNT_ID = 'enterpriseAccountId';
    public static final String FIELD_NAME_BILLING_ID = 'billingId';
    public static final String FIELD_NAME_RC_ACCOUNT_ID = 'rcAccountId';
    public static final String FIELD_NAME_PARTNER_ID = 'PartnerID';
    public static final String FIELD_NAME_BMID = 'BMID';
    public static final String FIELD_NAME_OID = 'OID';
    public static final String FIELD_NAME_BC = 'BC';
    public static final String FIELD_NAME_CONTRACT_DESCRIPTION = 'ContractDescription';
    public static final String FIELD_NAME_CONTRACT_TERM = 'ContractTerm';
    public static final String FIELD_NAME_CONTRACT_AUTO_RENEWAL = 'contractAutoRenewal';
    public static final String FIELD_NAME_CONTRACT_RENEWAL_TERM = 'contractRenewalTerm';
    public static final String FIELD_NAME_ENABLE_PHONE_LEASING = 'EnablePhoneLeasing';
    public static final String FIELD_NAME_ORDER_ID = 'OrderId';
    public static final String FIELD_NAME_FSC_AMOUNT = 'FSCAmount';
    public static final String FIELD_NAME_PLAN_DURATION = 'PlanDuration';
    public static final String FIELD_NAME_BUSINESS_IDENTITY_ID = 'businessIdentityId';
    public static final String FIELD_NAME_PREFERRED_USER_LANGUAGE = 'preferredUserLanguage';
    public static final String FIELD_NAME_BILLING_TIMEZONE_ID = 'BillingTimeZoneId';
    public static final String FIELD_NAME_TRIAL_DURATION = 'TrialDuration';
    public static final String FIELD_NAME_ELA_TYPE = 'ELAType';
    public static final String FIELD_NAME_DISCOUNT_ID = 'DiscountID';
    public static final String FIELD_NAME_EXEMPT_FROM_STATE_AND_LOCAL_TAXES = 'ExemptFromStateAndLocalTaxes';
    public static final String FIELD_NAME_RCBS = 'RCBS';
    public static final String FIELD_NAME_IS_LBO = 'isLBO';
    public static final String FIELD_NAME_NGBS_PARTNER_ID = 'NgbsPartnerId';
    public static final String FIELD_NAME_PARTNER_PACKAGE_ID = 'partnerPackageId';
    public static final String FIELD_NAME_PARTNER_PACKAGE_VERSION = 'partnerPackageVersion';
    public static final String FIELD_NAME_RC_ACCOUNT_NUMBER = 'rcAccountNumber';
    public static final String FIELD_NAME_CC_ACCOUNT_NUMBER = 'ccAccountNumber';
    public static final String FIELD_NAME_ENTERPRISE_CUSTOMER_ID = 'enterpriseCustomerId';
    public static final String FIELD_NAME_BILLING_ALIGNMENT_ENABLED = 'billingAlignmentEnabled';
    public static final String FIELD_NAME_INVOICE_CONSOLIDATION_ENABLED = 'invoiceConsolidationEnabled';
    public static final String FIELD_NAME_BILLING_ACCOUNT_ID = 'billingAccountId';
    public static final String FIELD_NAME_SALES_ORDER_ID = 'salesOrderId';
    public static final String FIELD_NAME_SERVICE_INFO = 'serviceInfo';
    public static final String FIELD_NAME_SERVICE_ACCOUNT_ID = 'serviceAccountId';
    public static final String FIELD_NAME_DURATION = 'duration';
    public static final String FIELD_NAME_PACKAGE = 'package';
    public static final String FIELD_NAME_PROSERV_PACKAGE_ID = 'id';
    public static final String FIELD_NAME_PROSERV_PACKAGE_VERSION = 'version';
    public static final String FIELD_NAME_LBOX_OVERRIDES = 'lboxOverrides';
    public static final String FIELD_NAME_APPROVED_PACKAGE_LIMITS = 'ApprovedPackageLimits';
    public static final String FIELD_NAME_TAX_SETTINGS = 'TaxSettings';
    public static final String FIELD_NAME_SUBSCRIPTION_INFO = 'SubscriptionInfo';
    public static final String FIELD_NAME_SERVICE_ORDER_ID = 'serviceOrderId';
    public static final String FIELD_NAME_SALES_AGENT_ID = 'salesAgentId';
    public static final String FIELD_NAME_LIMITS = 'limits';
    public static final String FIELD_NAME_CODE = 'code';
    public static final String FIELD_NAME_VALUE = 'value';
    public static final String FIELD_NAME_OVERRIDE = 'override';
    public static final String FIELD_NAME_START_DATE = 'startDate';
    public static final String FIELD_NAME_UNIT = 'unit';
    public static final String FIELD_NAME_SIGNUP_VALUE = 'signUpFieldValue';
    public static final String FIELD_NAME_MONTHLY_VALUE = 'monthlyFieldValue';
    public static final String FIELD_NAME_CONTRACT = 'contract';
    public static final String FIELD_NAME_CATALOGID = 'catalogId';
    public static final String FIELD_NAME_QUANTITY = 'quantity';
    public static final String FIELD_NAME_LICENSES= 'licenses';
    public static final String FIELD_NAME_ORDER= 'order';
    public static final String FIELD_NAME_DISCOUNTS= 'discount';
    public static final String FIELD_NAME_PROMOCODES= 'promoCodes';
    public static final String FIELD_NAME_DESCRIPTION= 'description';
    public static final String FIELD_NAME_ACCOUNT = 'account';
    public static final String FIELD_NAME_TIMEZONE = 'timezone';
    public static final String FIELD_NAME_CONTACT = 'contact';
    public static final String FIELD_NAME_CONTACT_FIRST_NAME = 'firstName';
    public static final String FIELD_NAME_CONTACT_LAST_NAME = 'lastName';
    public static final String FIELD_NAME_COMPANY_NAME = 'companyName';
    public static final String FIELD_NAME_CONTACT_PHONE = 'phone';
    public static final String FIELD_NAME_CONTACT_EMAIL = 'email';
    public static final String FIELD_NAME_BILLING_ADDRESS = 'billingAddress';
    public static final String FIELD_NAME_BILLING_ADDRESS_LINE1 = 'street1';
    public static final String FIELD_NAME_BILLING_ADDRESS_CITY = 'city';
    public static final String FIELD_NAME_BILLING_ADDRESS_STATE = 'state';
    public static final String FIELD_NAME_BILLING_ADDRESS_ZIP = 'zip';
    public static final String FIELD_NAME_BILLING_ADDRESS_COUNTRY = 'country';
    public static final String FIELD_NAME_TAX_SETTING = 'taxSettings';
    public static final String FIELD_NAME_PAYMENT_METHOD = 'paymentMethod';
    public static final String FIELD_NAME_TYPE = 'type';
    public static final String FIELD_NAME_TERMS = 'terms';
    public static final String FIELD_NAME_TERM = 'term';
    public static final String FIELD_NAME_AUTO_RENEWAL = 'autoRenewal';
    public static final String FIELD_NAME_RENEWAL_TERM = 'renewalTerm';
    public static final String FIELD_NAME_CONSOLIDATION = 'consolidationSettings';
    public static final String FIELD_NAME_PROVISIONING_INFO = 'provisioningInfo';
    public static final String FIELD_NAME_EVENTS = 'events';
    public static final String FIELD_NAME_ADMIN_USER = 'adminUser';

    // Quote Type Status Constants
    public static final String QUOTE_TYPE_SALES_SIGNED_UP = 'salesSignedUp';
    public static final String QUOTE_TYPE_POC_SIGNED_UP = 'pocSignedUp';
    public static final String QUOTE_TYPE_SALES_STATUS = 'salesStatus';
    public static final String QUOTE_TYPE_POC_STATUS = 'pocStatus';
    
    // Package Status Constants
    public static final String PACKAGE_STATUS_ACTIVE = 'Active';
    public static final String PACKAGE_STATUS_INITIAL = 'Initial';
    public static final String PACKAGE_STATUS_NOT_SIGNED_UP = 'notSignedUp';
    
    // String Replacement Constants
    public static final String SIGNED_UP_SUFFIX = 'SignedUp';
    public static final String STATUS_SUFFIX = 'Status';

    public enum SIGNUP_ACTION {
        QUERY_DATA,
        VALIDATE_DATA,
        CREATE_DEAL_DESK_CASE_DESCRIPTION,
        EXECUTE_PRESIGNUP_ACTIONS,
        VALIDATE_PROCESS_ORDER,
        SIGNUP,
        BODY_PREVIEW,
        UPDATE_PROCESS_ORDER_CC_SYNC_STATUS,
        ERROR
    }

    public class OppDetailWrapper {
        @AuraEnabled public Opportunity opportunity{get;set;}
        @AuraEnabled public Boolean isMultiProductFTEnabled{get;set;}
        @AuraEnabled public Boolean isSimplifiedLboDownsellEnabled {get;set;}
        @AuraEnabled public Boolean isMPUB {get;set;}
        @AuraEnabled public Quote[] masterAndTechQuotes{get;set;}
        @AuraEnabled public Map<String, Boolean> uiLessMap = new Map<String, Boolean> {
            OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE => SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderEngage__c,
            OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE => SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderEngage__c,
            OpportunityHelper.TIER_RC_CONTACT_CENTER => true,
            OpportunityHelper.TIER_OFFICE => SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderMVP__c,
            OpportunityHelper.TIER_MEETINGS => SettingsHelper.FEATURE_TOGGLE.EnableUILessProcessOrderMeetings__c,
            OpportunityHelper.TIER_PROFESSIONAL_SERVICES => true,
            Constants.CONST_RC_EVENT => true
        };
        @AuraEnabled public String ngbsAccountStatus {get;set;}
        @AuraEnabled public String message{get;set;}
        @AuraEnabled public Map<String, Object> productNameToPackageIsActiveStatusMap {get;set;}
        @AuraEnabled public Map<Id, SyncableWrapper> qtIdToSyncInfoMap {get;set;}
    }
    public class SyncableWrapper {
        @AuraEnabled public String syncInfo{get;set;}
        @AuraEnabled public Boolean isSyncedToICB{get;set;}
        @AuraEnabled public Boolean isICBProvisioningComplete{get;set;}
    }
    public class ActionRequestParams {
        public SIGNUP_ACTION action;
        public String[] targetIds;
        public String rcccSyncStatus;
        /* data and dataArr are separated for better readability */
        /* Used for signUp and process order validation actions */
        public SignUpParams data;
        /* Used for data validation and for preSignUp actions */
        public SignUpParams[] dataArr;
    }
    public class SignUpParams {
        public Opportunity opportunity { get; set; }
        public Quote[] quotes { get; set; }
        public Quote primaryQuote { get; set; }
        public Quote targetQuote { get; set; }
        public Quote ccQuote { get; set; }
        public Quote pocQuote { get; set; }
        public Quote psQuote { get; set; }
        public Account masterAcc { get; set; }
        public List<Account> boundAccs { get; set; }
        public List<Approval__c> approvals { get; set; }
        public List<AccountRelation__c> accRelations { get; set; }
        public Area_Code_Line_Item__c[] areaCodeLineItems { get; set; }
        public Area_Codes__c[] areaCodes { get; set; }
        public AssignmentLineItem__c[] assignementLineItem { get; set; }
        public Contact contact { get; set; }
        public User user { get; set; }
        public SubscriberInfoBuilder.AssignmentData[] assignmentsToSignUp { get; set; }
        public SubscriberInfoBuilder.AssignmentData[] assignmentsToManual { get; set; }
        public List<Promotion__c> promotions { get; set; }
        public String paymentMethod { get; set; }
        public Boolean isExistingBusiness { get; set; }
        public Boolean isMultiProductFTEnabled { get; set; }
        public String ngbsAccountStatus { get; set; }
        //Distribution Routing SubBrandId
        public String uBrandId { get; set; }
        public String timezoneId { get; set; }
        public String timezoneName { get; set; }
        public Boolean isProServQuotesNotCancelled { get; set; }
        public List<String> servicesOnPrimaryQuote { get; set; }
    }
    public class SignUpRequestBody {
        public Map<String, Object> requestBodyMap;

        public SignUpRequestBody(Map<String, Object> requestBodyMap) {
            this.requestBodyMap = requestBodyMap;
        }
        public SignUpRequestBody() {}
    }
    public class ApprovedPackageLimits {
        public Decimal MonthlyCreditLimitC;
        public Decimal SignUpPurchaseLimitC;
        public String PaymentTermsC;
        public String InvoiceTermsC;

        public ApprovedPackageLimits() {}

        public ApprovedPackageLimits(
            Decimal monthlyCreditLimit,
            Decimal signUpPurchaseLimit,
            String paymentTerms,
            String invoiceTerms
        ) {
            this.MonthlyCreditLimitC = monthlyCreditLimit;
            this.SignUpPurchaseLimitC = signUpPurchaseLimit;
            this.PaymentTermsC = paymentTerms;
            this.InvoiceTermsC = invoiceTerms;
        }

        public void setMonthlyCreditLimit(Decimal monthlyCreditLimit) {
            this.MonthlyCreditLimitC = monthlyCreditLimit;
        }

        public void setSignUpPurchaseLimit(Decimal signUpPurchaseLimit) {
            this.SignUpPurchaseLimitC = signUpPurchaseLimit;
        }

        public void setPaymentTerms(String paymentTerms) {
            this.PaymentTermsC = paymentTerms;
        }

        public void setInvoiceTerms(String invoiceTerms) {
            this.InvoiceTermsC = invoiceTerms;
        }
    }
    public class LboxOverridesRequest {
        public String catalogId;
        public Integer min;
        public Integer max;

        public LboxOverridesRequest(String catalogId, Integer min, Integer max) {
            this.catalogId = catalogId;
            this.min = min;
            this.max = max;
        }
    }
    public class LBData {
        @TestVisible
        Integer qty;
        @TestVisible
        LboxOverridesRequest lboxOR;

        public LBData(BillingWrappers.LBox lbox) {
            this.qty = 0;
            this.lboxOR = new LboxOverridesRequest(
                lbox.elementID,
                lbox.min.intValue(),
                lbox.max.intValue()
            );
        }

        public void add(Decimal val) {
            this.qty += val.intValue();
        }

        public LboxOverridesRequest getLboxOverridesRequest() {
            if (this.qty > this.lboxOR.max) {
                this.lboxOR.max = this.qty;
            }
            return this.lboxOR;
        }
    }
    public class SalesFunnelUIResponse {
        public String Status;
        public String Message;
        public String RedirectUrl;
    }
    //TODO: SignUpFunnelUIRequestParams is not just a wrapper, class should be reworked
    public class SignUpFunnelUIRequestParams {
        public String headers;
        public String endpoint;
        public String contentTypeValue = HttpHelper.CONTENT_TYPE_APPLICATION_FORM;

        public SignUpFunnelUIRequestParams(Quote qt) {
            if (QuoteHelper.isEngage(qt)) {
                this.engageParams();
            } else if (QuoteHelper.isRCCC(qt)) {
                this.inContactParams();
            }
        }

        private void engageParams() {
            this.headers = HttpHelper.prepareBasicAuthHeader(
                CCBAPI.CCB_SETTINGS.Login__c,
                CCBAPI.CCB_SETTINGS.Password__c
            );
            this.endpoint = CCBAPI.CCB_SETTINGS.BaseEndpoint__c + CCBAPI.CCB_SETTINGS.SignUpPath__c;
        }

        private void inContactParams() {
            this.contentTypeValue = HttpHelper.CONTENT_TYPE_APPLICATION_JSON;
            this.endpoint = ICBAPI.BASE_ENDPOINT_V1 + ICBAPI.ICB_SETTINGS.SignUpPath__c;
            this.headers = HttpHelper.prepareJWTAuthHeader(HttpHelper.CERT_DEV_NAME_ICB);
        }
    }
    public class GWSignUpResponse {

        public String GWApiSId;
        public String OppId;
        public String SalesAgentId;
        public String Url;
        public String fullRedirectUrl;

        public String generateUrl() {
            String result = this.Url;
            List<String> params = new List<String>();
            params.add('OPPID='        + this.OppId);
            params.add('SALESAGENTID=' + this.SalesAgentId);
            params.add('GWAPISID='     + this.GWApiSId);

            for(Integer i = 0; i < params.size(); i++){
                String separator = i == 0 ? '?' : '&';
                result += separator + params[i];
            }

            return result;
        }
    }

    public class CostCenterParams {
        public String billingId { get; set; }
    }

    public class adminUserDetails{
        public String firstName;
        public String lastName;
        public String email;

        public adminUserDetails(String firstName, String lastName, String email) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
        }
    }
}