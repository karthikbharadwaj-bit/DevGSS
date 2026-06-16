public with sharing class ApprovalValidator {

    public final static String DIRECT_DEBIT_THRESHOLD = 'DIRECT_DEBIT_THRESHOLD';
    public final static String DIRECT_DEBIT_LIMIT = 'DIRECT_DEBIT_LIMIT';

    public final static String SIGN_UP = 'SIGN_UP';
    public final static String CLOSE = 'CLOSE';

    public final static String HEAD = 'HEAD';
    public final static String BODY = 'BODY';

    public final static Map<String, Map<String, Map<String, String>>> messages = new Map<String, Map<String, Map<String, String>>>{
        DIRECT_DEBIT_THRESHOLD => new Map<String, Map<String, String>>{
            SIGN_UP => new Map<String, String>{
                HEAD => Label.Sign_Up_is_not_allowed,
                BODY => Label.Approval_Direct_Debit_Threshold_Error
            },
            CLOSE => new Map<String, String>{
                HEAD => Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                BODY => Label.Approval_Direct_Debit_Threshold_Error
            }
        },
        DIRECT_DEBIT_LIMIT => new Map<String, Map<String, String>>{
            SIGN_UP => new Map<String, String>{
                HEAD => Label.Sign_Up_is_not_allowed,
                BODY => Label.Approval_Direct_Debit_Limit_Error
            },
            CLOSE => new Map<String, String>{
                HEAD => Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                BODY => Label.Approval_Direct_Debit_Limit_Error
            }
        }
    };

    public static String getMessage(String key, String action, String type) {
        String result;
        if (messages?.get(key)?.get(action)?.get(type) == null) {
            AquivaHelper.throwAquivaException('Can not find a message');
        }
        return messages.get(key).get(action).get(type);
    }

    public class DirectDebitThresholdValidator extends Validator {

        private Quote primaryQuote;
        private Boolean hasDirectDebitApproval;
        private Boolean isInvalid;
        private String paymentMethod;
        private String action;

        public DirectDebitThresholdValidator(Quote qt, Boolean hasDirectDebitApproval, String paymentMethod, String action) {
            super(Validator.SEVERITY_CRITICAL);
            this.primaryQuote = qt;
            this.hasDirectDebitApproval = hasDirectDebitApproval;
            this.paymentMethod = paymentMethod;
            this.action = action;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                ApprovalValidator.getMessage(DIRECT_DEBIT_THRESHOLD, this.action, HEAD),
                ApprovalValidator.getMessage(DIRECT_DEBIT_THRESHOLD, this.action, BODY),
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            validate();
            return this.isInvalid;
        }

        private Boolean isNewBusinessInvalidTreshold() {
            if (this.primaryQuote != null) {
                if (ApprovalHelper.getDirectDebitApprovalThreshold(this.primaryQuote) <= getTotal()) {
                    return !this.hasDirectDebitApproval;
                }
            }
            return false;
        }

        private Boolean isExistingBusinessInvalidTreshold() {
            if (this.primaryQuote == null) {
                return false;
            }
            return getDirectDebitApprovalThreshold() <= getTotal() && !this.hasDirectDebitApproval;
        }

        private Decimal getTotal() {
            Decimal totalRR = this.primaryQuote.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD
                ? this.primaryQuote.Total_ARR_with_Taxes__c
                : this.primaryQuote.Total_MRR_with_Taxes__c;

            return totalRR + this.primaryQuote.Total_One_Time_with_Taxes__c;
        }

        private Decimal getDirectDebitApprovalThreshold() {
            Decimal treshold = ApprovalHelper.getDirectDebitApprovalThreshold(this.primaryQuote);
            if (this.primaryQuote.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD) {
                return treshold * 12;
            }
            return treshold;
        }

        private void validate() {
            Boolean isNewBusiness = QuoteHelper.isNewBusiness(this.primaryQuote) && QuoteHelper.isNGBSQuote(this.primaryQuote);
            Boolean isExistingBusiness = QuoteHelper.isExistingBusiness(this.primaryQuote);
            this.isInvalid = false;
            if (Feature_Toggle__c.getInstance().Enable_Direct_Debit_as_a_payment_method__c && QuoteHelper.isDirectDebit(this.paymentMethod)) {
                if (isNewBusiness) {
                    this.isInvalid = isNewBusinessInvalidTreshold();
                }
                if (isExistingBusiness) {
                    this.isInvalid = isExistingBusinessInvalidTreshold();
                }
            }
        }

    }

    public class DirectDebitLimitValidation extends Validator {

        private Quote qt;
        private String paymentMethod;
        private Approval__c approval;
        private Boolean isInvalid;
        private String action;

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                ApprovalValidator.getMessage(DIRECT_DEBIT_LIMIT, this.action, HEAD),
                ApprovalValidator.getMessage(DIRECT_DEBIT_LIMIT, this.action, BODY),
                Response.SEVERITY_ERROR
            );
        }
        public DirectDebitLimitValidation(Quote qt, String paymentMethod, String action) {
            super(Validator.SEVERITY_CRITICAL);
            this.qt = qt;
            this.paymentMethod = paymentMethod;
            this.action = action;
        }

        public DirectDebitLimitValidation(Quote qt, String paymentMethod, String action, Approval__c approval) {
            this(qt, paymentMethod, action);
            this.approval = approval;
        }

        public override Boolean isFailedValidation () {
            validate();
            return this.isInvalid;
        }

        public Boolean isFeatureToggleOn() {
            return Feature_Toggle__c.getInstance().Enable_Direct_Debit_as_a_payment_method__c;
        }

        public Boolean isExceededLimits(Approval__c approval) {
            return getLimit(approval) < getTotal();
        }

        public Boolean isExceededThreshold() {
            return getThreshold() < getTotal();
        }

        private Decimal getLimit(Approval__c approval) {
            Decimal monthlyCreditLimit = approval?.Monthly_Credit_Limit__c;
            if (this.qt.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD) {
                monthlyCreditLimit = monthlyCreditLimit * 12;
            }
            return monthlyCreditLimit;
        }

        private Decimal getTotal() {
            Decimal totalRR = this.qt.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD
                ? this.qt.Total_ARR_with_Taxes__c
                : this.qt.Total_MRR_with_Taxes__c;

            return totalRR + this.qt.Total_One_Time_with_Taxes__c;
        }

        private Decimal getThreshold() {
            Decimal threshold = ApprovalHelper.getDirectDebitApprovalThreshold(this.qt);
            if (this.qt.Payment_Period__c == QuoteHelper.ANNUAL_PAYMENT_METHOD) {
                threshold = threshold * 12;
            }
            return threshold;
        }

        public Approval__c getLastApproval(Id accId) {
            return approval != null
                ? approval
                : ApprovalHelper.getLastApprovedApproval(accId, ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST);
        }

        private Boolean validate() {
            this.isInvalid = false;
            if (qt == null) {
                return this.isInvalid;
            }
            Boolean isNewBusiness = QuoteHelper.isNewBusiness(qt) && QuoteHelper.isNGBSQuote(qt);
            Boolean isExistingBusiness = QuoteHelper.isExistingBusiness(qt);

            if(isFeatureToggleOn() && QuoteHelper.isDirectDebit(paymentMethod) && isExceededThreshold()) {
                Approval__c approval = getLastApproval(this.qt.Account__c);
                if (isNewBusiness) {
                    this.isInvalid = approval == null;
                }
                if (isExistingBusiness) {
                    this.isInvalid = approval == null || isExceededLimits(approval);
                }
            }
            return this.isInvalid;
        }
    }
}