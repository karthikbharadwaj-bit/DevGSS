public with sharing class SignUpRequestBuilderManager {
    @TestVisible
    private static final String EX_MSG_USER_IS_REQUIRED = 'User is required';
    @TestVisible
    private static final String EX_MSG_ACCOUNT_IS_REQUIRED = 'Account is required';
    @TestVisible
    private static final String EX_MSG_OPPORTUNITY_IS_REQUIRED = 'Opportunity is required';
    @TestVisible
    private static final String EX_MSG_QUOTE_IS_REQUIRED = 'Quote is required';
    @TestVisible
    private static final String EX_MSG_PACKAGE_INFO_IS_REQUIRED = 'Package Info is required';
    @TestVisible
    private static final String EX_MSG_FIELDS_ARE_REQUIRED = 'Next fields are required: ';
    @TestVisible
    private static final String EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO = 'Target Package ID and/or Version are missing on the Primary POC Quote. Please use \'Create a Case\' button to report this issue.';

    public Map<String, Object> requestBodyMap = new Map<String, Object>();
    @TestVisible
    Quote qt;
    @TestVisible
    Account acc;
    Map<Id, Account> boundAccs = new Map<Id, Account>();
    @TestVisible
    Opportunity opp;
    @TestVisible
    User user;
    @TestVisible
    List<Promotion__c> promoList = new List<Promotion__c>();
    @TestVisible
    String uBrandId;
    @TestVisible
    String paymentMethod;
    @TestVisible
    String timezoneId;
    @TestVisible
    String timezoneName;
    Contact contact;
    @TestVisible
    List<Approval__c> approvals = new List<Approval__c>();
    SubscriberInfoBuilder.AssignmentData[] assignments;
    @TestVisible
    Boolean isUpsell;
    @TestVisible
    Map<String, String> countryCodeMap = new Map<String, String>();


    @TestVisible
    BillingWrappers.QuotePackageInfo pInfo {
        get {
            if (pInfo != null) {
                return pInfo;
            }
            pInfo = QuoteHelper.getQuotePackage(qt);

            return pInfo;
        }
        set;
    }
    @TestVisible
    Boolean isNotJSONFormatRequest {
        get {
            return QuoteHelper.isEngage(qt) && !POHelper.isEngageUILessSettingsOn;
        }
        set;
    }
    @TestVisible
    String paymentMethodType {
        get {
            if (paymentMethodType != null) {
                return paymentMethodType;
            }
            if (QuoteHelper.isPOCQuote(qt)) {
                paymentMethodType = AccountHelper.PAYMENT_METHOD_NONE;
                return paymentMethodType;
            }

            paymentMethodType = '';
            if (OpportunityHelper.isSearchPackagesEnabledWithValidOppBI(opp)) {
                paymentMethodType = POHelper.getQuotePaymentMethodType(paymentMethod);
            } else {
                paymentMethodType = POHelper.getAccountPaymentMethodType(paymentMethod, qt.Opportunity);
            }

            return paymentMethodType;
        }
        set;
    }
    @TestVisible
    String contractDescription {
        get {
            if (contractDescription != null) {
                return contractDescription;
            }

            contractDescription = '';
            if (pInfo?.contract == null) {
                return contractDescription;
            }

            Map<String, String> contractInfo = new Map<String, String> {
                'salesAgreement'    => qt.Id,
                'contractExtId'     => String.valueOf(pInfo.contract.extId)
            };
            contractDescription = JSON.serialize(contractInfo);
            return contractDescription;
        }
        set;
    }
    @TestVisible
    Boolean isTrial {
        get {
            if (isTrial != null) {
                return isTrial;
            }
            String offerType = offerType;
            String trialOfferTypes = String.join(
                new List<String> {QuoteHelper.OFFER_TYPE_TRIAL, QuoteHelper.OFFER_TYPE_POC},
                ' '
            );

            isTrial = trialOfferTypes.containsIgnoreCase(offerType);
            return isTrial;
        }
        set;
    }
    @TestVisible
    String offerType{
        get {
            if (offerType != null) {
                return offerType;
            }

            String result = pInfo.offerType;

            if (pInfo.offerType.equalsIgnoreCase(QuoteHelper.OFFER_TYPE_REGULAR)) {
                result = QuoteHelper.OFFER_TYPE_BUY;
            } else if (pInfo.offerType.equalsIgnoreCase(QuoteHelper.OFFER_TYPE_POC)) {
                result = QuoteHelper.OFFER_TYPE_POC;
            } else if (pInfo.offerType.equalsIgnoreCase(QuoteHelper.OFFER_TYPE_TRIAL)) {
                result = QuoteHelper.OFFER_TYPE_TRIAL;
            } else if (pInfo.offerType.equalsIgnoreCase(QuoteHelper.OFFER_TYPE_FREE)) {
                result = QuoteHelper.OFFER_TYPE_FREE;
            }
            offerType = result;

            return offerType;
        }
        set;
    }
    @TestVisible
    Boolean isMPUB {
        get {
            if (isMPUB != null) {
                return isMPUB;
            }
            Map<Id, Account> accMap = boundAccs.clone();

            Set<Id> keysToRemove = new Set<Id>();
            for (Account currentAcc : accMap.values()) {
                if (currentAcc.Master_Account__c != null &&
                    currentAcc.IsMultiProductTechnicalAccount__c == false
                ) {
                    keysToRemove.add(currentAcc.Id);
                    keysToRemove.add(currentAcc.Master_Account__c);
                }
            }
            accMap.keySet().removeAll(keysToRemove);

            if (accMap.containsKey(acc.Id)) {
                accMap.remove(acc.Id);
            }

            isMPUB = AccountHelper.isMPUBAccount(acc.Id, accMap.values());
            return isMPUB;
        }
        set;
    }
    @TestVisible
    Boolean isTermination {
        get {
            if (isTermination != null) {
                return isTermination;
            }
            if (!BooleanHelper.toBoolean(isMPUB)) {
                return opp?.IsTermination__c;
            }
            List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
                .selectServiceInfoForClear(new List<Object>{ qt.Id })
                .executeQuery();
            isTermination = !serviceInfos.isEmpty() && serviceInfos.get(0).IsTermination__c;
            return isTermination;
        }
        set;
    }

    public SignUpRequestBuilderManager(POWrappers.SignUpParams data) {
        qt = data.targetQuote;
        acc = data.opportunity?.Account;
        user = data.user;
        uBrandId = data.uBrandId;
        paymentMethod = data.paymentMethod;
        opp = data.opportunity;
        promoList = data.promotions;
        approvals = data.approvals;
        timezoneId = data.timezoneId;
        timezoneName = data.timezoneName;
        contact = data.contact;
        assignments = data.assignmentsToSignUp;
        boundAccs = new Map<Id, Account>(data.boundAccs);
        isUpsell = data.isExistingBusiness == true;
        countryCodeMap = SettingsHelper.getCountryAlphaCode();

        /* check */
        if (user == null) {
            AquivaHelper.throwAquivaException(EX_MSG_USER_IS_REQUIRED);
        }
        if (opp == null) {
            AquivaHelper.throwAquivaException(EX_MSG_OPPORTUNITY_IS_REQUIRED);
        }
        if (acc == null) {
            AquivaHelper.throwAquivaException(EX_MSG_ACCOUNT_IS_REQUIRED);
        }
        if (qt == null) {
            AquivaHelper.throwAquivaException(EX_MSG_QUOTE_IS_REQUIRED);
        }
        if (String.isBlank(qt.Package_Info__c)) {
            AquivaHelper.throwAquivaException(EX_MSG_PACKAGE_INFO_IS_REQUIRED);
        }
    }

    public SignUpRequestBuilderManager build(Builder builder) {
        builder.init(this);
        Map<String, Object> builderParams = builder.getSignUpParameter();
        if (builderParams != null && !builderParams.isEmpty()) {
            requestBodyMap.putAll(builderParams);
        }

        return this;
    }

    public POWrappers.SignUpRequestBody getSignUpRequestBody() {
        return new POWrappers.SignUpRequestBody(requestBodyMap);
    }

    public void validateSignUpRequestBody() {
        Set<String> errorFields = new Set<String>();
        Set<String> requiredFields = new Set<String> {
            POWrappers.FIELD_NAME_SPID,
            POWrappers.FIELD_NAME_OPPID,
            POWrappers.FIELD_NAME_PACKAGE_NAME,
            POWrappers.FIELD_NAME_PACKAGE_ID,
            POWrappers.FIELD_NAME_PACKAGE_VERSION,
            POWrappers.FIELD_NAME_OFFER_TYPE
        };

        if (this.isTrial) {
            requiredFields.add(POWrappers.FIELD_NAME_TRIAL_PACKAGE_ID);
            requiredFields.add(POWrappers.FIELD_NAME_TRIAL_PACKAGE_VERSION);
        }

        for (String key : requiredFields) {
            if (requestBodyMap.get(key) == null) {
                errorFields.add(key);
            }
        }

        if (!errorFields.isEmpty()) {
            AquivaHelper.throwAquivaException(EX_MSG_FIELDS_ARE_REQUIRED + String.join(errorFields, ', '));
        }
    }

    private interface LimitParamBuilder {
        String buildLimitParam(String mark, Integer index, String propertyName);
    }

    public abstract class Builder {
        @TestVisible
        private SignUpRequestBuilderManager m;
        public abstract Map<String, Object> getSignUpParameter();

        public void init(SignUpRequestBuilderManager manager) {
            this.m = manager;
        }
    }

    public class OfferTypeBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_OFFER_TYPE => m.offerType
            };
        }
    }
    public class DefaultPackageLimitsBuilder extends Builder implements LimitParamBuilder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_DEFAULT_PACKAGE_LIMITS => getDefaultPackageLimits(m.pInfo, m.acc)
            };
        }

        public String buildLimitParam(String mark, Integer index, String propertyName) {
            return POHelper.buildLimitParam(mark, POWrappers.FIELD_NAME_DEFAULT_PACKAGE_LIMITS.toUpperCase(), index, propertyName);
        }

        private Object getDefaultPackageLimits(BillingWrappers.QuotePackageInfo pInfo, Account acc) {
            return AccountHelper.isWholesaleAccount(acc)
                ? getBPackageDefaultLimits(pInfo)
                : getQPackageInfoLimits(pInfo.globalPackageLimits);
        }

        @TestVisible
        private Object getBPackageDefaultLimits(BillingWrappers.QuotePackageInfo pInfo) {
            String catalogId = m.isTrial
                ? pInfo?.poc?.catalogId
                : pInfo?.packageInfo?.catalogId;
            String catalogVersion = m.isTrial
                ? pInfo?.poc?.version
                : pInfo?.packageInfo?.version;

            BillingWrappers.NGBSPackage bPackage = NGBSAPI.getPackage(catalogId, catalogVersion);
            Boolean isBPackageHasNoLimits = bPackage?.globalPackageLimits == null
                || bPackage?.globalPackageLimits.isEmpty()
                || String.isBlank(bPackage?.globalPackageLimits[0].code);

            return m.isNotJSONFormatRequest
                ? (Object) formatGlobalPackageLimits(bPackage?.globalPackageLimits)
                : isBPackageHasNoLimits ? null : (Object) bPackage.globalPackageLimits;
        }

        @TestVisible
        private Object getQPackageInfoLimits(List<BillingWrappers.GlobalPackageLimits> limits) {
            return m.isNotJSONFormatRequest
                ? (Object) formatGlobalPackageLimits(limits)
                : (Object) limits;
        }

        @TestVisible
        private String formatGlobalPackageLimits(List<BillingWrappers.GlobalPackageLimits> limits) {
            Boolean isBPackageHasNoLimits = limits == null
                || limits.isEmpty()
                || String.isBlank(limits[0].code);

            if (isBPackageHasNoLimits) {
                return null;
            }

            Integer i = 0;
            String url = '';

            for (BillingWrappers.GlobalPackageLimits lim : limits) {
                url += buildLimitParam(String.isNotBlank(url) ? '&' : '', i, 'value') + lim.value
                    + buildLimitParam('&', i, 'code') + lim.code
                    + buildLimitParam('&', i, 'name') + lim.name
                    + buildLimitParam('&', i, 'type') + lim.limitType
                    + buildLimitParam('&', i, 'scope') + lim.scope
                    + buildLimitParam('&', i, 'transactionType') + lim.transactionType
                    + buildLimitParam('&', i, 'target') + lim.target
                    + buildLimitParam('&', i, 'override') + lim.isOverride ;

                i++;
            }

            return url;
        }
    }
    public class ApprovedPackageLimitsBuilder extends Builder implements LimitParamBuilder {
        public override Map<String, Object> getSignUpParameter() {
            Object approvedPkgLimits = m.isNotJSONFormatRequest
                ? (Object) buildNotJSONFormatRequest(m.acc, m.qt, m.paymentMethodType, m.approvals)
                : (Object) buildJSONFormatRequest(m.acc, m.qt, m.paymentMethodType, m.approvals);

            if (approvedPkgLimits == null) {
                return null;
            }

            return new Map<String, Object> {
                POWrappers.FIELD_NAME_APPROVED_PACKAGE_LIMITS => approvedPkgLimits
            };
        }

        public String buildLimitParam(String mark, Integer index, String propertyName) {
            return POHelper.buildLimitParam(mark, POWrappers.FIELD_NAME_APPROVED_PACKAGE_LIMITS.toUpperCase(), index, propertyName);
        }

        @TestVisible
        private String buildNotJSONFormatRequest(Account acc, Quote qt, String paymentMethodType, List<Approval__c> approvals) {
            return SettingsHelper.FEATURE_TOGGLE.Enable_Direct_Debit_as_a_payment_method__c
                ? getApprovedPackageLimits(m.acc, m.qt, m.paymentMethodType, m.approvals)
                : getApprovedPackageLimits(m.acc, m.qt, m.approvals);
        }

        @TestVisible
        private List<POWrappers.ApprovedPackageLimits> buildJSONFormatRequest(
            Account acc,
            Quote qt,
            String paymentMethodType,
            List<Approval__c> approvals
        ) {
            POWrappers.ApprovedPackageLimits limits = getApprovedPackageLimitsWrapper(m.acc, m.qt, m.paymentMethodType, m.approvals);
            return limits == null ? null : new List<POWrappers.ApprovedPackageLimits>{ limits };
        }

        @TestVisible
        private String getApprovedPackageLimits(Account acc, Quote qt, String paymentMethodType, List<Approval__c> approvals) {
            String limits = null;

            if (paymentMethodType == POWrappers.PAYMENT_METHOD_DD_FUNNEL) {
                POWrappers.ApprovedPackageLimits approvedPackageLimits = getDirectDebitApprovedPackageLimits(acc, qt);
                limits = this.formatDirectDebitApprovedPackageLimits(approvedPackageLimits);
            }

            if (paymentMethodType == POWrappers.PAYMENT_METHOD_INV_FUNNEL
                || paymentMethodType == POWrappers.PAYMENT_METHOD_INV_BOB_FUNNEL
                || paymentMethodType == POWrappers.PAYMENT_METHOD_WHOLESALE_FUNNEL
            ) {
                limits = formatApprovedPackageLimits(acc, qt, approvals);
            }

            return limits;
        }

        @TestVisible
        private String getApprovedPackageLimits(Account acc, Quote qt, List<Approval__c> approvals) {
            return AccountHelper.isAnyInvoiceAccount(acc)
                ? formatApprovedPackageLimits(acc, qt, approvals)
                : null;
        }

        @TestVisible
        private String formatApprovedPackageLimits(Account acc, Quote qt, List<Approval__c> approvals) {
            POWrappers.ApprovedPackageLimits approvedPackageLimits = SettingsHelper.FEATURE_TOGGLE.EnableMultiProductUnifiedBilling__c
                ? getApprovedPackageLimitsUB(qt, approvals)
                : getApprovedPackageLimitsObj(acc);
            return this.formatApprovedPackageLimits(approvedPackageLimits);
        }

        @TestVisible
        private String decimalToString(Decimal param) {
            return NumberHelper.toNumber(param).toPlainString();
        }

        @TestVisible
        private String formatDirectDebitApprovedPackageLimits(POWrappers.ApprovedPackageLimits approvedPackageLimits) {
            String url = buildLimitParam('', 0, 'MonthlyCreditLimitC') + decimalToString(approvedPackageLimits.MonthlyCreditLimitC)
                + buildLimitParam('&', 0, 'SignUpPurchaseLimitC') + decimalToString(approvedPackageLimits.SignUpPurchaseLimitC);

            return url;
        }

        @TestVisible
        private String formatApprovedPackageLimits(POWrappers.ApprovedPackageLimits approvedPackageLimits) {
            String url = formatDirectDebitApprovedPackageLimits(approvedPackageLimits)
                + buildLimitParam('&', 0, 'PaymentTermsC') + approvedPackageLimits.PaymentTermsC
                + buildLimitParam('&', 0, 'InvoiceTermsC') + approvedPackageLimits.InvoiceTermsC;

            return url;
        }

        @TestVisible
        private POWrappers.ApprovedPackageLimits getApprovedPackageLimitsObj(Account acc) {
            if (!AccountHelper.isAnyInvoiceAccount(acc)) {
                return null;
            }

            POWrappers.ApprovedPackageLimits approvedPackageLimits = new POWrappers.ApprovedPackageLimits();
            approvedPackageLimits.setMonthlyCreditLimit(acc.Monthly_Credit_Limit__c);
            approvedPackageLimits.setSignUpPurchaseLimit(acc.Sign_up_Purchase_Limit__c);
            approvedPackageLimits.setPaymentTerms(acc.Payment_Terms__c);
            approvedPackageLimits.setInvoiceTerms(acc.Invoice_Terms__c);

            return approvedPackageLimits;
        }

        @TestVisible
        private POWrappers.ApprovedPackageLimits getApprovedPackageLimitsUB(Quote qt, List<Approval__c> approvals) {
            Boolean isSingleQuote = String.isEmpty(qt.MasterQuote__c);
            List<Approval__c> approvedApprovalsForOppty = new List<Approval__c>();
            Set<Id> recordTypeIds = ApprovalHelper.APPROVAL_ID_TO_LAYOUT_NAME.keySet();

            for (Approval__c approval: approvals) {
                if (recordTypeIds.contains(approval.RecordTypeId)
                    && (approval.Opportunity__c == qt.OpportunityId
                        || !isSingleQuote && approval.Opportunity__c == qt.MasterQuote__r.OpportunityId
                    )
                ) {
                    approvedApprovalsForOppty.add(approval);
                }
            }

            Approval__c approval = ApprovalHelper.getLastApprovedInvoiceApproval(approvedApprovalsForOppty, isSingleQuote);

            if (approval == null) {
                return null;
            }
            POWrappers.ApprovedPackageLimits approvedPackageLimits = new POWrappers.ApprovedPackageLimits();
            Map<String, Decimal> approvedPackageLimitsMap = ApprovalHelper.getApprovedPackageLimitsMap(qt, approval);

            approvedPackageLimits.setMonthlyCreditLimit(approvedPackageLimitsMap.get('MonthlyCreditLimitC'));
            approvedPackageLimits.setSignUpPurchaseLimit(approvedPackageLimitsMap.get('SignUpPurchaseLimitC'));
            approvedPackageLimits.setPaymentTerms(approval.Payment_Terms__c);
            approvedPackageLimits.setInvoiceTerms(approval.Invoice_Terms__c);
            return approvedPackageLimits;
        }

        @TestVisible
        private POWrappers.ApprovedPackageLimits getApprovedPackageLimitsWrapper(
            Account acc,
            Quote qt,
            String paymentMethodType,
            List<Approval__c> approvals
        ) {
            if (SettingsHelper.FEATURE_TOGGLE.Enable_Direct_Debit_as_a_payment_method__c
                && paymentMethodType == POWrappers.PAYMENT_METHOD_DD_FUNNEL
            ) {
                POWrappers.ApprovedPackageLimits limits = getDirectDebitApprovedPackageLimits(acc, qt);
                if (limits == null || !isValidLimit(limits.MonthlyCreditLimitC) || !isValidLimit(limits.SignUpPurchaseLimitC)) {
                    return null;
                }
                return limits;
            }

            POWrappers.ApprovedPackageLimits limits = SettingsHelper.FEATURE_TOGGLE.EnableMultiProductUnifiedBilling__c
                ? getApprovedPackageLimitsUB(qt, approvals)
                : getApprovedPackageLimitsObj(acc);

            if (limits == null
                || !isValidLimit(limits.MonthlyCreditLimitC)
                || !isValidLimit(limits.SignUpPurchaseLimitC)
                || String.isBlank(limits.PaymentTermsC)
                || String.isBlank(limits.InvoiceTermsC)) {
                return null;
            }
            return limits;
        }

        @TestVisible
        private POWrappers.ApprovedPackageLimits getDirectDebitApprovedPackageLimits(Account acc, Quote qt) {
            Decimal threshold = ApprovalHelper.getDirectDebitApprovalThreshold(qt);
            Decimal initialPayment = qt.Total_MRR_with_Taxes__c + qt.Total_One_Time_with_Taxes__c;
            Decimal monthlyCreditLimit = threshold;
            Decimal signUpPurchaseLimit = threshold;

            if (initialPayment > threshold) {
                //TODO: should be removed to queryData method
                Approval__c approval = ApprovalHelper.getLastApprovedApproval(acc.Id, ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST);
                //Service specific limits
                Map<String, Decimal> approvedPackageLimitsMap = ApprovalHelper.getApprovedPackageLimitsMap(qt, approval);
                monthlyCreditLimit = approvedPackageLimitsMap.get('MonthlyCreditLimitC');
                signUpPurchaseLimit = approvedPackageLimitsMap.get('SignUpPurchaseLimitC');
            }

            POWrappers.ApprovedPackageLimits approvedPackageLimits = new POWrappers.ApprovedPackageLimits();
            approvedPackageLimits.setMonthlyCreditLimit(monthlyCreditLimit);
            approvedPackageLimits.setSignUpPurchaseLimit(signUpPurchaseLimit);

            return approvedPackageLimits;
        }

        private Boolean isValidLimit(Decimal limitValue) {
            return limitValue != null && limitValue > 0;
        }
    }
    public class TaxSettingsBuilder extends Builder implements LimitParamBuilder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_TAX_SETTINGS => getTaxSettings(m.acc.Id)
            };
        }

        public String buildLimitParam(String mark, Integer index, String propertyName) {
            return POHelper.buildLimitParam(mark, POWrappers.FIELD_NAME_TAX_SETTINGS.toUpperCase(), index, propertyName);
        }

        @TestVisible
        public NGBSAPI.TaxExemption buildTaxSetting(Id accountId) {
            if (!TaxExemptionHelper.isEnabled && !Test.isRunningTest()) {
                return null;
            }
            //TODO: Move SOQL query to PODataCollector
            List<Approval__c> approvedApprovals = (List<Approval__c>) new ApprovalSelector()
                .selectTaxExemptApprovalsInStatuses(new List<Object>{
                    accountId,
                    new List<String>{ApprovalHelper.STATUS_APPROVED}})
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                .executeQuery();

            NGBSAPI.TaxExemption taxSettings = new NGBSAPI.TaxExemption();

            if (!approvedApprovals.isEmpty()) {
                Approval__c app = approvedApprovals.get(0);

                Map<String, String> countryNameMap = SettingsHelper.getCountryCodesFullName();

                taxSettings.setFederalTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.FederalTaxExemption__c));
                taxSettings.setStateTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.StateTaxExemption__c));
                taxSettings.setCountyTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.CountyTaxExemption__c));
                taxSettings.setLocalTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.LocalTaxExemption__c));
                taxSettings.setSalesTaxExemption(TaxExemptionHelper.isTaxExemptionActive(app.SalesTaxExemption__c));
                taxSettings.setVatExemption(TaxExemptionHelper.isTaxExemptionActive(app.VATExemption__c));
                taxSettings.setVatNumber(app.VATNumber__c);
                taxSettings.setSezWopExemption(TaxExemptionHelper.isTaxExemptionActive(app.SEZWOPExemption__c));
                taxSettings.setGstNumber(app.GstNo__c);
                if (countryNameMap.size() > 0 && app.VATCountry__c !=null) {
                    taxSettings.setVatCountry(countryNameMap.get(app.VATCountry__c.toLowerCase()));
                }
            }

            return taxSettings;
        }

        private Object getTaxSettings(Id accountId) {
            return m.isNotJSONFormatRequest
                ? formatTaxSetting(buildTaxSetting(accountId))
                : buildTaxSetting(accountId);
        }

        @TestVisible
        private Object formatTaxSetting(NGBSAPI.TaxExemption taxSettings) {
            return buildLimitParam('&', null, 'federalTaxExemption') + taxSettings.getFederalTaxExemption()
                + buildLimitParam('&', null, 'stateTaxExemption') + taxSettings.getStateTaxExemption()
                + buildLimitParam('&', null, 'countyTaxExemption') + taxSettings.getCountyTaxExemption()
                + buildLimitParam('&', null, 'localTaxExemption') + taxSettings.getLocalTaxExemption()
                + buildLimitParam('&', null, 'salesTaxExemption') + taxSettings.getSalesTaxExemption()
                + buildLimitParam('&', null, 'VATExemption') + taxSettings.getVatExemption()
                + buildLimitParam('&', null, 'VATNumber') + taxSettings.getVatNumber()
                + buildLimitParam('&', null, 'GSTNumber') + taxSettings.getGstNumber()
                + buildLimitParam('&', null, 'SEZWOPExemption') + taxSettings.getSezWopExemption()
                + buildLimitParam('&', null, 'VATExemptionCountry') + taxSettings.getVatCountry();
        }

    }
    public class SubscriptionInfoBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_SUBSCRIPTION_INFO => getSubscriptionInfo(
                    m.user,
                    m.acc,
                    m.contact,
                    m.qt,
                    m.assignments,
                    getCustomAddressAssignmentMap(POHelper.getQuoteLineItemsWithAddressAssignment(m.qt)),
                    m.paymentMethod)
            };
        }

        @TestVisible
        private Object getSubscriptionInfo(
            User user,
            Account acc,
            Contact contact,
            Quote qt,
            SubscriberInfoBuilder.AssignmentData[] assignments,
            Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap,
            String paymentMethod
        ) {

            //TODO: should be discussed if it is still required
            if (m.opp.Account.IsMultiProductTechnicalAccount__c) {
                acc.Name = removeMultiproductSystemNameMarker(acc.Name);
            }
            SubscriberInfoBuilder infoBuilder = new SubscriberInfoBuilder(
                user,
                acc,
                contact,
                qt,
                assignments,
                addressAssignmentsMap,
                paymentMethod,
                m.isMPUB
            );

            Object subscriptionInfo;

            if (m.isNotJSONFormatRequest) {
                subscriptionInfo = infoBuilder.getValue();
            } else {
                subscriptionInfo = QuoteHelper.isRCCC(m.qt) && m.isUpsell
                    ? infoBuilder.getJsonWithoutZeroLicenses()
                    : infoBuilder.getJsonValue();
            }

            return subscriptionInfo;
        }
        @TestVisible
        private Map<Id, List<CustomAddressAssignments__c>> getCustomAddressAssignmentMap(List<QuoteLineItem> qlisWithShipping) {
            Map<Id, List<CustomAddressAssignments__c>> addressAssignmentsMap = new Map<Id, List<CustomAddressAssignments__c>>();
            for (QuoteLineItem qli : qlisWithShipping) {
                if (!qli.Custom_Address_QLI__r.isEmpty()) {
                    for (CustomAddressAssignments__c caa : qli.Custom_Address_QLI__r) {
                        if (!addressAssignmentsMap.containsKey(caa.CustomAddress__c)) {
                            addressAssignmentsMap.put(caa.CustomAddress__c, new List<CustomAddressAssignments__c>{caa});
                        } else {
                            addressAssignmentsMap.get(caa.CustomAddress__c).add(caa);
                        }
                    }
                }
            }

            return addressAssignmentsMap;
        }
        @TestVisible
        private String removeMultiproductSystemNameMarker(String objName) {
            Pattern pattern = Pattern.compile('\\[(system:.*?)]$');
            Matcher matcher = pattern.matcher(objName);

            if (matcher.find()) {
                Integer lastIndex = objName.lastIndexOf('[');
                return objName.substring(0, lastIndex).trim();
            }

            return objName;
        }
    }
    public class LBoxOverridesBuilder extends Builder implements LimitParamBuilder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_LBOX_OVERRIDES => getLBoxOverrides(m.qt)
            };
        }

        public String buildLimitParam(String mark, Integer index, String propertyName) {
            return POHelper.buildLimitParam(mark, POWrappers.FIELD_NAME_LBOX_OVERRIDES, index, propertyName);
        }

        @TestVisible
        private Object getLBoxOverrides(Quote qt) {
            return m.isNotJSONFormatRequest
                ? (Object) getStringLBoxOverrides(getObjectLBoxOverrides(qt))
                : (Object) getObjectLBoxOverrides(qt);
        }
        @TestVisible
        private List<POWrappers.LboxOverridesRequest> getObjectLBoxOverrides(Quote qt) {
            Map<String, POWrappers.LBData> LBDataMap = new Map<String, POWrappers.LBData>();
            List<POWrappers.LboxOverridesRequest> lboxORs = new List<POWrappers.LboxOverridesRequest>();

            if (QuoteHelper.isPOCQuote(qt)) {
                for (QuoteLineItem qli : qt.QuoteLineItems) {
                    if (String.isNotBlank(qli.PackageInfo__c)) {
                        BillingWrappers.QLIPackageInfo qliPInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);

                        if (qliPInfo.lboxes != null && !qliPInfo.lboxes.isEmpty()) {
                            for (BillingWrappers.LBox lbox : qliPInfo.lboxes) {
                                Decimal qty = (Decimal) NumberHelper.getNumberNullSafe(qli.Quantity);
                                POWrappers.LBData lbd = LBDataMap.get(lbox.elementID);
                                if (lbd == null) {
                                    lbd = new POWrappers.LBData(lbox);
                                }

                                lbd.add(qty);
                                LBDataMap.put(lbox.elementID, lbd);
                            }
                        }
                    }
                }
                for (POWrappers.LBData lbd : LBDataMap.values()) {
                    lboxORs.add(lbd.getLboxOverridesRequest());
                }
                return lboxORs.isEmpty() ? null : lboxORs;
            }
            return null;
        }
        @TestVisible
        private String getStringLBoxOverrides(List<POWrappers.LboxOverridesRequest> lboxORs) {
            String url= '';
            Integer i = 0;
            if (lboxORs != null) {
                for (POWrappers.LboxOverridesRequest lbox : lboxORs) {
                    url += buildLimitParam(String.isNotBlank(url) ? '&' : '', i, 'catalogId') + lbox.catalogId
                        + buildLimitParam('&', i, 'min') + (lbox.min != null ? lbox.min : 0)
                        + buildLimitParam('&', i, 'max')  + (lbox.max != null ? lbox.max : 0);
                    i++;
                }
                return url;
            }
            return null;
        }
    }
    public class IsTerminationOpportunityBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (QuoteHelper.isRCCC(m.qt) && m.isUpsell && !m.isNotJSONFormatRequest) {
                signUpParameter.put(POWrappers.FIELD_NAME_IS_TERMINATION_OPPORTUNITY, BooleanHelper.toBoolean(m.isTermination));
            }

            return signUpParameter;
        }
    }
    public class UserBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                'SPID' => m.user.PID__c,
                /* In this mode user can add/delete features on Funnel */
                'isAdmin' => isAdminUser(m.user)
            };
        }

        @TestVisible
        private Boolean isAdminUser(User us) {
            //EU phase 3 Changes - START
            Set<String> adminProfileNames = new Set<String>();
            List<EU_Component_Reference__mdt> euComp = new List<EU_Component_Reference__mdt>([SELECT Values__c FROM EU_Component_Reference__mdt WHERE Apex_Classes__c LIKE '%SignUpCustomersBilling%' AND DeveloperName LIKE 'adminProfileNames%' ]);
            for (EU_Component_Reference__mdt e:euComp) {
                if (e.Values__c.length() > 0) {
                    adminProfileNames.addAll(e.Values__c.split(','));
                }
            }
            //EU Phase 3 Changes - END
            return Feature_Toggle__c.getInstance().LockNGBSSalesFunnel__c
                ? adminProfileNames.contains(us.Profile.Name)
                : true;
        }
    }
    public class UBrandIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_UBRAND_ID => m.uBrandId
            };
        }
    }
    public class PIDBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_PID => m.acc.PID__c
            };
        }
    }
    public class PaymentMethodTypeBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            if (m.isMPUB && QuoteHelper.isEngage(m.qt) && String.isNotBlank(m.acc.Billing_ID__c)) {
                return null;
            }
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_PAYMENT_METHOD_TYPE => m.paymentMethodType
            };
        }
    }
    public class SAFIDBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            String safid = this.getSAFID(m.pInfo);
            if (!String.isBlank(safid)) {
                signUpParameter.put(POWrappers.FIELD_NAME_SAFID, safid);
            }

            return signUpParameter;
        }

        private String getSAFID(BillingWrappers.QuotePackageInfo pInfo) {
            String safid;

            if (QuoteHelper.NGBS_RCCC_PRODUCT.equalsIgnoreCase(pInfo?.productName)
                || QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT.equalsIgnoreCase(pInfo?.productName)
                || QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT.equalsIgnoreCase(pInfo?.productName)
                || QuoteHelper.NGBS_ENGAGE_VOICE_LEGACY_PRODUCT.equalsIgnoreCase(pInfo?.productName)
                || QuoteHelper.NGBS_ENGAGE_DIGITAL_LEGACY_PRODUCT.equalsIgnoreCase(pInfo?.productName)
            ) {
                safid = POWrappers.DEFAULT_SAF_ID;
            }

            return safid;
        }
    }
    public class EnterpriseAccountIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (QuoteHelper.isEngageOrInContact(m.qt)) {
                signUpParameter.put(POWrappers.FIELD_NAME_ENTERPRISE_ACCOUNT_ID, getEnterpriseAccountId(m.acc));
            }

            return signUpParameter;
        }

        private String getEnterpriseAccountId(Account acc) {
            if(!m.qt.IsMultiProductTechnicalQuote__c && acc != null && String.isNotBlank(acc.RC_Account_Status__c) && acc.RC_Account_Status__c.equalsIgnoreCase('Paid') && m.qt.recordtype.name.equalsIgnoreCase('POC Quote')){
                return acc.RC_User_ID__c;
            }
            return !m.isMPUB || !m.qt.IsMultiProductTechnicalQuote__c
                ? acc.Internal_Enterprise_Account_ID__c
                : acc.RC_User_ID__c;
        }
    }
    public class BillingIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (QuoteHelper.isEngageOrInContact(m.qt)) {
                signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ID, m.acc.Billing_ID__c);
            }

            return signUpParameter;
        }
    }
    public class RCAccountIDBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (QuoteHelper.isEngageOrInContact(m.qt) && (m.qt.IsMultiProductTechnicalQuote__c || (!m.qt.IsMultiProductTechnicalQuote__c && m.acc != null && String.isNotBlank(m.acc.RC_Account_Status__c) && m.acc.RC_Account_Status__c.equalsIgnoreCase('Paid') && m.qt.recordtype.name.equalsIgnoreCase('POC Quote')))) {
                signUpParameter.put(POWrappers.FIELD_NAME_RC_ACCOUNT_ID, getBoundRcAccountId());
            }

            return signUpParameter;
        }

        @TestVisible
        private String getBoundRcAccountId() {
            return m.isMPUB
                ? m.acc.RC_User_ID__c
                : m.opp.Account?.Master_Account__r?.RC_User_ID__c;
        }
    }
    public class OpportunityBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_OPPID => m.opp.Id,
                POWrappers.FIELD_NAME_PARTNER_ID => m.opp.Partner_ID__c,
                POWrappers.FIELD_NAME_BMID => m.opp.BMID__c,
                POWrappers.FIELD_NAME_OID => getOID(m.opp),
                POWrappers.FIELD_NAME_BC => getBC(m.opp)
            };
        }

        private String getOID(Opportunity opp) {
            return String.isNotBlank(opp.OID__c)
                ? (POWrappers.OID_PREFIX + opp.OID__c)
                : '';
        }
        @TestVisible
        private String getBC(Opportunity opp) {
            return opp.Enable_Cost_Center_Management__c ? '1' : '0';
        }
    }
    public class ContractDescriptionBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_CONTRACT_DESCRIPTION => m.contractDescription
            };
        }
    }
    public class ContractTermBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (String.isNotBlank(m.contractDescription)) {
                signUpParameter.put(POWrappers.FIELD_NAME_CONTRACT_TERM, getContractTerm(m.qt, m.pInfo));
            }

            return signUpParameter;
        }

        @TestVisible
        private Integer getContractTerm(Quote qt, BillingWrappers.QuotePackageInfo pInfo) {
            return (pInfo.contract == null || qt.Initial_Term_months__c == null)
                ? null
                : Integer.valueOf(qt.Initial_Term_months__c);
        }
    }
    public class ContractAutoRenewalBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (String.isNotBlank(m.contractDescription)) {
                signUpParameter.put(POWrappers.FIELD_NAME_CONTRACT_AUTO_RENEWAL, m.qt.Auto_Renewal__c);
            }

            return signUpParameter;
        }
    }
    public class ContractRenewalTermBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (String.isNotBlank(m.contractDescription)) {
                signUpParameter.put(POWrappers.FIELD_NAME_CONTRACT_RENEWAL_TERM, getContractRenewalTerm(m.qt));
            }

            return signUpParameter;
        }

        @TestVisible
        private Integer getContractRenewalTerm(Quote qt) {
            return qt.Auto_Renewal__c ? Integer.valueOf(qt.Term_months__c) : null;
        }
    }
    public class EnablePhoneLeasingBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (String.isNotBlank(m.contractDescription)) {
                signUpParameter.put(POWrappers.FIELD_NAME_ENABLE_PHONE_LEASING, isPhoneLeasingEnabled(m.qt, m.opp));
            }

            return signUpParameter;
        }

        private Boolean isPhoneLeasingEnabled(Quote qt, Opportunity opp) {
            return QuoteHelper.isPhoneLeasingEnabled(
                QuoteHelper.isPhoenix(qt),
                OpportunityHelper.isIndia(opp),
                qt.QuoteLineItems
            );
        }
    }
    public class OrderIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_ORDER_ID => m.qt.Id
            };
        }
    }
    public class FSCAmountBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_FSC_AMOUNT => getFSCAmount(m.qt)
            };
        }

        @TestVisible
        private String getFSCAmount(Quote qt) {
            Decimal freeServiceCredit = qt.Free_Service_Credit_Total__c;

            String result = '';
            if (SettingsHelper.FEATURE_TOGGLE.Credit_Process_NGBS__c && freeServiceCredit > 0) {
                result = String.valueOf(freeServiceCredit);
            }

            return result;
        }
    }
    public class PlanDurationBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_PLAN_DURATION => m.pInfo.duration
            };
        }
    }
    public class BusinessIdentityIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            Integer biId = this.getBusinessIdentityId(m.pInfo);
            if (biId != null) {
                signUpParameter.put(POWrappers.FIELD_NAME_BUSINESS_IDENTITY_ID, biId);
            }

            return signUpParameter;
        }

        public Integer getBusinessIdentityId(BillingWrappers.QuotePackageInfo packageInfo) {
            if (packageInfo.packageBusinessIdentities != null
                && packageInfo.packageBusinessIdentities.approvedBi != null
                && packageInfo.packageBusinessIdentities.approvedBi.id != null
            ) {
                return Integer.valueOf(packageInfo.packageBusinessIdentities.approvedBi.id);
            }
            return null;
        }
    }
    public class PromotionsBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            ServiceInfoBuilder serviceBuilder = new ServiceInfoBuilder();
            return serviceBuilder.generateSignupPromoCode(m);
        }

        @TestVisible
        private Boolean isNeedToSendPromotionId(List<Promotion__c> promoList) {
            return !promoList.isEmpty();
        }
    }
    public class PackageBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameters = new Map<String, Object> {
                POWrappers.FIELD_NAME_PACKAGE_NAME => m.pInfo.packageInfo.name,
                POWrappers.FIELD_NAME_PACKAGE_ID => m.pInfo.packageInfo.catalogId,
                POWrappers.FIELD_NAME_PACKAGE_VERSION => m.pInfo.packageInfo.version
            };
            if (m.isTrial) {
                if (m.pInfo.poc == null || String.isBlank(m.pInfo.poc.catalogId) || String.isBlank(m.pInfo.poc.version)) {
                    AquivaHelper.throwAquivaException(EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO);
                }
                signUpParameters.put(POWrappers.FIELD_NAME_TRIAL_PACKAGE_ID, m.pInfo.poc.catalogId);
                signUpParameters.put(POWrappers.FIELD_NAME_TRIAL_PACKAGE_VERSION, m.pInfo.poc.version);
            }

            return signUpParameters;
        }
    }
    public class PreferredLanguageIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.pInfo.preferredLanguage != null) {
                signUpParameter.put(POWrappers.FIELD_NAME_PREFERRED_USER_LANGUAGE, m.pInfo.preferredLanguage.localeCode);
            }

            return signUpParameter;
        }
    }
    public class BillingTimeZoneIdLanguageIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_BILLING_TIMEZONE_ID => m.timezoneId
            };
        }
    }
    public class TrialDurationBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_TRIAL_DURATION => getTrialDuration(m.qt)
            };
        }

        private String getTrialDuration(Quote qt) {
            /* ??? 'D_20, M_1' */
            return QuoteHelper.isPOCQuote(qt) ? POWrappers.TRIAL_DURATION_PREFIX + qt.Initial_Term_POC__c : null;
        }
    }
    
    public class TargetPackageBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.isTrial && QuoteHelper.isPOCQuote(m.qt)) {
                Map<String, Object> targetPackageMap = new Map<String, Object>();
                targetPackageMap.put(POWrappers.FIELD_NAME_TARGET_PACKAGE_ID, m.pInfo.poc.catalogId);
                targetPackageMap.put(POWrappers.FIELD_NAME_TARGET_PACKAGE_VERSION, m.pInfo.poc.version);
                targetPackageMap.put(POWrappers.FIELD_NAME_PACKAGE_DURATION_UNIT, POWrappers.TARGET_PACKAGE_DURATION);
                targetPackageMap.put(POWrappers.FIELD_NAME_PACKAGE_DURATION_VALUE, m.qt.Initial_Term_POC__c);
                
                signUpParameter.put(POWrappers.FIELD_NAME_TARGET_PACKAGE, targetPackageMap);
            }
            return signUpParameter;
        }
    }
    
    public class ELATypeBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (!String.isEmpty(m.acc.ELA_Account_Type__c)) {
                signUpParameter.put(POWrappers.FIELD_NAME_ELA_TYPE, AccountHelper.ACCOUNT_TYPE_ELA_MAP.get(m.acc.ELA_Account_Type__c));
            }

            return signUpParameter;
        }
    }
    public class DiscountIDBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_DISCOUNT_ID => createDiscounts(m.qt, m.pInfo)
            };
        }

        public String createDiscountsV2(Quote quote, BillingWrappers.QuotePackageInfo pInfo) {
            return  createDiscounts(quote,pInfo);
        }

        @TestVisible
        private String createDiscounts(Quote qt, BillingWrappers.QuotePackageInfo pInfo) {
            //TODO: should be removed to Selectors
            Contract__c accountContract = ContractRestAPI.selectContract(pInfo);
            NGBS_Discount.RootDiscountTemplateGroup discountTemplateGroup =
                NGBS_Discount.createRootDiscountTemplateGroup(qt, pInfo, accountContract, null);

            if (discountTemplateGroup == null || discountTemplateGroup.discountTemplates.size() == 0) {
                return null;
            }
            String body = JSON.serialize(discountTemplateGroup);
            String contentTypeValue = 'text/json';

            String result;
            if (!Test.isRunningTest()) {
                HttpResponse response = NGBSAPI.requestNGBS(NGBSAPI.NGBS_DISCOUNT_GROUP, HttpHelper.METHOD_POST, body, contentTypeValue);
                result = response.getBody();
            } else {
                result = JSON.serialize(discountTemplateGroup);
            }

            NGBS_Discount.RootDiscountTemplateGroup responseDiscount =
                (NGBS_Discount.RootDiscountTemplateGroup) JSON.deserialize(
                    result,
                    NGBS_Discount.RootDiscountTemplateGroup.class
                );

            return responseDiscount.promoCode;
        }
    }
    public class ExemptFromStateAndLocalTaxesBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_EXEMPT_FROM_STATE_AND_LOCAL_TAXES => false
            };
        }
    }
    public class RCBSBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            /* true -> funnel will work with new RC Billing through JEDI. */
            return new Map<String, Object> {
                POWrappers.FIELD_NAME_RCBS => true
            };
        }
    }
    public class EnabledLBOBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.qt.Enabled_LBO__c) {
                signUpParameter.put(POWrappers.FIELD_NAME_IS_LBO, m.qt.Enabled_LBO__c);
            }
            return signUpParameter;
        }
    }
    public class NGBSPartnerIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (String.isNotBlank(m.acc.Partner_Account__c)
                && (!QuoteHelper.isPOCQuote(m.qt) || AccountHelper.isWholesaleAccount(m.acc))
            ) {
                signUpParameter.put(POWrappers.FIELD_NAME_NGBS_PARTNER_ID, AccountHelper.getNgbsPartnerId(m.acc.Partner_Account__c));
            }
            return signUpParameter;
        }
    }
    public class PartnerPackageIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (AccountHelper.isWholesaleAccount(m.acc)) {
                signUpParameter.put(POWrappers.FIELD_NAME_PARTNER_PACKAGE_ID, m.pInfo.partnerPackage?.id);
            }
            return signUpParameter;
        }
    }
    public class PartnerPackageVersionBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (AccountHelper.isWholesaleAccount(m.acc)) {
                signUpParameter.put(POWrappers.FIELD_NAME_PARTNER_PACKAGE_VERSION, m.pInfo.partnerPackage?.version);
            }
            return signUpParameter;
        }
    }
    public class InContactBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (QuoteHelper.isRCCC(m.qt)) {
                signUpParameter.put(POWrappers.FIELD_NAME_RC_ACCOUNT_NUMBER, m.opp.NumberToBeRCMainNumber__c);
                signUpParameter.put(POWrappers.FIELD_NAME_CC_ACCOUNT_NUMBER, m.opp.NumberToBeCCNumber__c);
            }
            return signUpParameter;
        }
    }
    public class EnterpriseCustomerIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.opp.Account.IsMultiProductTechnicalAccount__c && m.opp.Account.EnterpriseCustomerID__c != null) {
                signUpParameter.put(POWrappers.FIELD_NAME_ENTERPRISE_CUSTOMER_ID, m.opp.Account.EnterpriseCustomerID__c);
            }
            return signUpParameter;
        }
    }
    public class BillingAlignmentEnabledBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.isMPUB && (m.qt.IsMultiProductTechnicalQuote__c || (!m.qt.IsMultiProductTechnicalQuote__c && m.acc != null && String.isNotBlank(m.acc.RC_Account_Status__c) && m.acc.RC_Account_Status__c.equalsIgnoreCase('Paid') && m.qt.recordtype.name.equalsIgnoreCase('POC Quote'))) && QuoteHelper.isEngageOrInContact(m.qt)) {
                signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ALIGNMENT_ENABLED, true);
            }
            return signUpParameter;
        }
    }
    public class InvoiceConsolidationEnabledBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.isMPUB && (m.qt.IsMultiProductTechnicalQuote__c || (!m.qt.IsMultiProductTechnicalQuote__c && m.acc != null && String.isNotBlank(m.acc.RC_Account_Status__c) && m.acc.RC_Account_Status__c.equalsIgnoreCase('Paid') && m.qt.recordtype.name.equalsIgnoreCase('POC Quote'))) && QuoteHelper.isEngageOrInContact(m.qt)) {
                signUpParameter.put(POWrappers.FIELD_NAME_INVOICE_CONSOLIDATION_ENABLED, true);
            }
            return signUpParameter;
        }
    }
    public class BillingAccountIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (m.acc.Billing_ID__c != null) {
                signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ACCOUNT_ID, m.acc.Billing_ID__c);
            }
            return signUpParameter;
        }
    }
    public class SalesOrderIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_SALES_ORDER_ID, m.opp.Id);
            return signUpParameter;
        }
    }

    public class AccountInfoBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_ACCOUNT, getAccountInfo());
            return signUpParameter;
        }

        @TestVisible
        private Map<String, Object> getAccountInfo() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_ENTERPRISE_ACCOUNT_ID, m.acc.Internal_Enterprise_Account_ID__c);
            BusinessIdentityIdBuilder biBuild = new BusinessIdentityIdBuilder();
            Integer biId = biBuild.getBusinessIdentityId(m.pInfo);
            signUpParameter.put(POWrappers.FIELD_NAME_BUSINESS_IDENTITY_ID, biId!=null ? (object)String.valueof(biId) : new Map<String, Object>());
            signUpParameter.put(POWrappers.FIELD_NAME_TIMEZONE, m.timezoneName);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT, getContactInfo());
            signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ADDRESS, getBillingAddressInfo());
            signUpParameter.put(POWrappers.FIELD_NAME_TAX_SETTING, getTaxSettingsInfo());
            signUpParameter.put(POWrappers.FIELD_NAME_PAYMENT_METHOD, getPaymentMethodInfo());
            signUpParameter.put(POWrappers.FIELD_NAME_CONTRACT, getContractDetails());
            return signUpParameter;
        }

        private Map<String, Object> getContactInfo() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_FIRST_NAME, m.contact.FirstName);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_LAST_NAME, m.contact.LastName);
            signUpParameter.put(POWrappers.FIELD_NAME_COMPANY_NAME, m.acc.Name);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_EMAIL, m.contact.Email);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_PHONE, m.contact.Phone);
            return signUpParameter;
        }

        private Map<String, Object> getBillingAddressInfo() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            SubscriberInfoBuilder.ContactInfoRequest contactInfo;
            if (POWrappers.INVOICE.equals(m.qt.PaymentMethod__c)) {
                contactInfo = new SubscriberInfoBuilder().getPayableContactInfo(m.acc);
            }
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_FIRST_NAME, contactInfo?.firstName ?? m.contact.FirstName);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_LAST_NAME, contactInfo?.lastName ?? m.contact.LastName);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_PHONE, contactInfo?.contactPhone ?? m.contact.Phone);
            signUpParameter.put(POWrappers.FIELD_NAME_CONTACT_EMAIL, contactInfo?.email ?? m.contact.Email);
            signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ADDRESS_LINE1, m.acc.BillingStreet);
            signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ADDRESS_CITY, m.acc.BillingCity);
            signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ADDRESS_STATE,m.acc.BillingState);
            signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ADDRESS_ZIP, m.acc.BillingPostalCode);
            signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ADDRESS_COUNTRY, m.countryCodeMap.containsKey(m.acc.BillingCountry.toLowerCase()) ? m.countryCodeMap.get(m.acc.BillingCountry.toLowerCase()) : 'USA');
            return signUpParameter;
        }

        private object getTaxSettingsInfo() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            TaxSettingsBuilder taxSettingsBuilder = new TaxSettingsBuilder();
            NGBSAPI.TaxExemption txEmp = taxSettingsBuilder.buildTaxSetting(m.acc.Id);
            String vatNumber = null;
            String gstNumber = null;

            if(txEmp.getVatCountry() != null){
                String vatCountry = m.countryCodeMap.containsKey(txEmp.getVatCountry().toLowerCase()) ? m.countryCodeMap.get(txEmp.getVatCountry().toLowerCase()) : 'USA';
                txEmp.setvatCountry(vatCountry);
            }
            if(m.acc.VATNumber__c != null){
                if (TaxExemptionHelper.isIndiaCountry(m.acc.BillingCountry) && txEmp.getGstNumber() == null ) {
                    gstNumber = m.acc.VATNumber__c;
                    txEmp.setGSTNumber(gstNumber);
                } else if(SettingsService.isSwitzerland(m.acc.BillingCountry) && txEmp.getVatNumber() == null)  {
                    SubscriberInfoBuilder.BillingAddress ba = new SubscriberInfoBuilder.BillingAddress();
                    vatNumber = ba.trimCountryCodeFromVatNumber(m.acc.VATNumber__c, m.acc.BillingCountry);
                    txEmp.setVatNumber(vatNumber);
                } else if (txEmp.getVatNumber() == null){
                    vatNumber = m.acc.VATNumber__c;
                    txEmp.setVatNumber(vatNumber);
                }
                if((txEmp.getVatNumber() != null || txEmp.getGstNumber() != null) &&  txEmp.getvatCountry() == null) {
                    txEmp.setvatCountry(m.countryCodeMap.get(m.acc.BillingCountry.toLowerCase()));
                }
            }

            return (object)txEmp;
        }

        private Map<String, Object> getPaymentMethodInfo() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_TYPE, m.qt.PaymentMethod__c);
            signUpParameter.put(m.qt.PaymentMethod__c.toLowerCase(), new Map<String, Object>{POWrappers.FIELD_NAME_TERMS => 3});
            return signUpParameter;
        }

        private Map<String, Object> getContractDetails() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_DESCRIPTION, m.contractDescription);
            signUpParameter.put(POWrappers.FIELD_NAME_TERM,m.qt.Initial_Term_months__c);
            signUpParameter.put(POWrappers.FIELD_NAME_AUTO_RENEWAL,m.qt.Auto_Renewal__c);
            signUpParameter.put(POWrappers.FIELD_NAME_RENEWAL_TERM,m.qt.Term_months__c);
            return signUpParameter;
        }
    }
    public class ServiceInfoBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            Map<String, Object> serviceInfoMap = new Map<String, Object>();
            Map<String, Object> packageInfoMap = new Map<String, Object>();
            packageInfoMap.put(POWrappers.FIELD_NAME_PROSERV_PACKAGE_ID, m.pInfo.packageInfo.catalogId);
            packageInfoMap.put(POWrappers.FIELD_NAME_PROSERV_PACKAGE_VERSION, m.pInfo.packageInfo.version);
            serviceInfoMap.put(POWrappers.FIELD_NAME_DURATION, m.pInfo.duration);
            serviceInfoMap.put(POWrappers.FIELD_NAME_PACKAGE, packageInfoMap);
            if (!(QuoteHelper.isProServService(m.qt) && QuoteHelper.isCreditCard(m.qt.PaymentMethod__c))) {
                serviceInfoMap.put(POWrappers.FIELD_NAME_LIMITS, getLimits(m.qt, m.approvals));
            }
            if (m.isMPUB && m.qt.IsMultiProductTechnicalQuote__c && (QuoteHelper.isEvents(m.qt) || QuoteHelper.isProServService(m.qt))) {
                serviceInfoMap.put(POWrappers.FIELD_NAME_CONSOLIDATION , getConsolidationSettings());
            }
            if(m.qt.ServiceName__c == Constants.CONST_RC_EVENT){
                serviceInfoMap.put(POWrappers.FIELD_NAME_PROVISIONING_INFO, getEventsAdminDetails());
            }else{
                serviceInfoMap.put(POWrappers.FIELD_NAME_SERVICE_ACCOUNT_ID, m.opp.Id);
            }
            signUpParameter.put(POWrappers.FIELD_NAME_SERVICE_INFO, serviceInfoMap);
            if(!m.qt.IsMultiProductTechnicalQuote__c ||  m.qt.IsMultiProductTechnicalQuote__c && m.qt.ServiceName__c == Constants.CONST_RC_EVENT) {
                serviceInfoMap.put(POWrappers.FIELD_NAME_CONTRACT, new Map<String, Object> {POWrappers.FIELD_NAME_DESCRIPTION => m.contractDescription});
                serviceInfoMap.put(POWrappers.FIELD_NAME_ORDER, getOrderDetails());
                serviceInfoMap.put(POWrappers.FIELD_NAME_DISCOUNTS, getDiscountDetails());
            }
            return signUpParameter;
        }

        public Map<String, Object>  getConsolidationSettings() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
                signUpParameter.put(POWrappers.FIELD_NAME_BILLING_ALIGNMENT_ENABLED, true );
                signUpParameter.put(POWrappers.FIELD_NAME_INVOICE_CONSOLIDATION_ENABLED, true );
            return signUpParameter;
        }

        public Map<String, Object>  generateSignupPromoCode(SignUpRequestBuilderManager m) {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if (!isNeedToSendPromotionId(m.promoList)) {
                return signUpParameter;
            }

            Integer promotionListSize = m.promoList.size();
            List<String> promoCodes = new List<String>();
            for (Integer i=0; i<promotionListSize; i++) {
                String encodedPromocode = EncodingUtil.urlEncode(m.promoList[i].Promo_Code__c, 'UTF-8');
                if (m.isNotJSONFormatRequest) {
                    signUpParameter.put('promoCodes['+ i + ']' , encodedPromocode);
                } else {
                    promoCodes.add(encodedPromocode);
                }
            }
            if (!m.isNotJSONFormatRequest) {
                signUpParameter.put('promoCodes', promoCodes);
            }

            return signUpParameter;
        }

        public  Map<String, Object> getSignUpParameterPromoCode(String signUpParam) {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            if(signUpParam == POWrappers.FIELD_NAME_DISCOUNT_ID){
                DiscountIDBuilder discount = new DiscountIDBuilder();
                return new Map<String, Object> {
                    POWrappers.FIELD_NAME_DISCOUNT_ID => discount.createDiscountsV2(m.qt, m.pInfo)
                };
            }else if(signUpParam == POWrappers.FIELD_NAME_PROMOCODES){
                    signUpParameter = generateSignupPromoCode(m);

            }
            return signUpParameter;
        }

        @TestVisible
        private Boolean isNeedToSendPromotionId(List<Promotion__c> promoList) {
            return !promoList.isEmpty();
        }

        @TestVisible
        private  Map<String,Object> getDiscountDetails(){
            Map<String,Object> discountMap = new Map<String,Object>();
            Map<String,Object> promoCodetMap = new Map<String,Object>();
            List<Object> promocodeList = new List<Object>();
            promoCodetMap = getSignUpParameterPromoCode(POWrappers.FIELD_NAME_PROMOCODES);
            if(!promoCodetMap.isEmpty() && promoCodetMap.containsKey(POWrappers.FIELD_NAME_PROMOCODES) && promoCodetMap.get(POWrappers.FIELD_NAME_PROMOCODES) != null){
                List<Object> promocodes = (List<Object>)promoCodetMap?.get(POWrappers.FIELD_NAME_PROMOCODES);
                if(promocodes.size() > 0){
                    promocodeList.addAll(promocodes);
                }
            }

            if(!Test.isRunningTest()){ promoCodetMap = getSignUpParameterPromoCode(POWrappers.FIELD_NAME_DISCOUNT_ID); }
            if(!promoCodetMap.isEmpty() && promoCodetMap.containsKey(POWrappers.FIELD_NAME_DISCOUNT_ID) && promoCodetMap.get(POWrappers.FIELD_NAME_DISCOUNT_ID) != null){
                promocodeList.add(promoCodetMap.get(POWrappers.FIELD_NAME_DISCOUNT_ID));
            }

            if(promocodeList.size() > 0){
                discountMap.put(POWrappers.FIELD_NAME_PROMOCODES,promocodeList);
            }
            return discountMap;
        }

        @TestVisible
        private  Map<String,Object> getOrderDetails(){
            List<Map<String,Object>> orderList = new List<Map<String,Object>>();
            Map<String,List<Map<String,Object>>> orderToLicenseMap = new Map<String,List<Map<String,Object>>>();

            for (QuoteLineItem qli : m.qt.QuoteLineItems) {
                if(qli.Product2.Family == 'Taxes') {
                    continue;
                }
                Integer quantity = ((Decimal)qli.get('Quantity')).intValue();
                String catalogId = (String)qli.Product2.get('ExtID__c');
                if(quantity>0){
                    Map<String,Object> licenseMap = new Map<String,Object>();
                    licenseMap.put(POWrappers.FIELD_NAME_CATALOGID,catalogId);
                    licenseMap.put(POWrappers.FIELD_NAME_QUANTITY,quantity);
                    Map<String, Object> packageInfoQLI = (Map<String, Object>)Json.deserializeUntyped((String)qli.get('Package_Info_QLI__c'));
                    if(!packageInfoQLI.isEmpty() && packageInfoQLI.containsKey(POWrappers.FIELD_NAME_DURATION)){
                        String duration = (String)packageInfoQLI?.get(POWrappers.FIELD_NAME_DURATION);
                        licenseMap.put(POWrappers.FIELD_NAME_DURATION,duration);
                    }
                    orderList.add(licenseMap);
                }
            }

            orderToLicenseMap.put(POWrappers.FIELD_NAME_LICENSES,orderList);
            return orderToLicenseMap;
        }

        @TestVisible
        private List<Object> getLimits(Quote qt, List<Approval__c> approvals) {
            Map<String, Object> limitsMap = new Map<String, Object>();
            Map<String, Object> monthlyCreditLimitMap = new Map<String, Object>();
            Map<String, Object> durationMap = new Map<String, Object>();
            Map<String,Integer> limitsValueMap = new Map<String,Integer>();
            Approval__c approval = getLastApprovedInvoiceApproval(qt, approvals);
            if(approval == null) {
                return new List<Object>{ (Object)limitsMap };
            }
            limitsValueMap = getLimitValue(qt, approval);
            limitsMap.put(POWrappers.FIELD_NAME_CODE, POWrappers.MONTHLY_AMOUNT_LIMIT);
            limitsMap.put(POWrappers.FIELD_NAME_VALUE, limitsValueMap.get(POWrappers.FIELD_NAME_MONTHLY_VALUE));
            monthlyCreditLimitMap.put(POWrappers.FIELD_NAME_VALUE, limitsValueMap.get(POWrappers.FIELD_NAME_SIGNUP_VALUE));
            monthlyCreditLimitMap.put(POWrappers.FIELD_NAME_START_DATE, ((m.qt.IsMultiProductTechnicalQuote__c && m.qt.ServiceName__c == Constants.CONST_RC_EVENT) || !m.qt.IsMultiProductTechnicalQuote__c) ?   (object)datetime.now().formatGmt(POWrappers.NGBS_ISO_FORMAT) : datetime.now());
            durationMap.put(POWrappers.FIELD_NAME_UNIT, POWrappers.DURATION_MONTHS);
            durationMap.put(POWrappers.FIELD_NAME_VALUE, approval.Invoice_Terms__c);
            monthlyCreditLimitMap.put(POWrappers.FIELD_NAME_DURATION, durationMap);
            limitsMap.put(POWrappers.FIELD_NAME_OVERRIDE, monthlyCreditLimitMap);

            return new List<Object>{ (Object)limitsMap };
        }

        @TestVisible
        private Map<String,Integer> getLimitValue(Quote qt,Approval__c approval) {
                String signUpField;
                String monthlyField;
                Map<String,Integer> limitsValueMap = new Map<String,Integer>();
                if(qt.IsMultiProductTechnicalQuote__c && m.qt.ServiceName__c == Constants.CONST_RC_EVENT) {
                    signUpField = 'Sign_Up_Purchase_Limit_for_RC_Events__c';
                    monthlyField = 'Monthly_Credit_Limit_for_RC_Events__c';
                } else if(qt.IsMultiProductTechnicalQuote__c && m.qt.ServiceName__c == Constants.CONST_PROSERV){
                    signUpField = 'SignUpPurchaseLimitProServ__c';
                    monthlyField = 'MonthlyCreditLimitProServ__c';
                }else {
                    signUpField = 'Sign_Up_Purchase_Limit__c';
                    monthlyField = 'Monthly_Credit_Limit__c';
                }
                limitsValueMap.put(POWrappers.FIELD_NAME_SIGNUP_VALUE, ((Decimal)approval.get(signUpField)).intValue());
                limitsValueMap.put(POWrappers.FIELD_NAME_MONTHLY_VALUE, ((Decimal)approval.get(monthlyField)).intValue());
                return limitsValueMap;
        }

        @TestVisible
        private Approval__c getLastApprovedInvoiceApproval(Quote qt, List<Approval__c> approvals) {
            List<Approval__c> approvedApprovalsForOppty = new List<Approval__c>();
            Set<Id> recordTypeIds = ApprovalHelper.APPROVAL_ID_TO_LAYOUT_NAME.keySet();
			Boolean isSingleQuote = !qt.IsMultiProductTechnicalQuote__c;
            
            BillingWrappers.NGBSAccount accountInfo = NGBSAPI.getNGBSAccount(m.acc.Billing_ID__c);
            
            Set<String> extServices = new Set<String>(); 
            if (!isSingleQuote && accountInfo != null && accountInfo.packages != null) { 
                for (BillingWrappers.NGBSAccountPackage accPackage : accountInfo.packages){
                    if (accPackage.product != null) {
                        extServices.add(accPackage.product);
                    }
                }
            }
            
            Boolean hasProfServices = extServices.contains(AccountHelper.SERVICE_TYPE_PROFESSIONAL_SERVICES);
			
            for (Approval__c approval: approvals) {
                if (
                        recordTypeIds.contains(approval.RecordTypeId) && 
                        (
                            approval.Opportunity__c == qt.MasterQuote__r.OpportunityId || 
                            approval.Opportunity__c == qt.OpportunityId || 
                            hasProfServices
                        )
                ) {
                    approvedApprovalsForOppty.add(approval);
                }
            }

            return ApprovalHelper.getLastApprovedInvoiceApproval(approvedApprovalsForOppty, isSingleQuote);
        }


        @TestVisible
        private String generateEnterpriseAccountId() {
            final Integer LEGACY_OFFSET = 130000000;
            final Integer BLOCK_ID = 990;

            Id orgId = UserInfo.getOrganizationId();
            RCSequence__c rcSequence = [
                SELECT SubSequence__c, SandboxNumber__c
                FROM RCSequence__c
                WHERE SetupOwnerId =: orgId FOR UPDATE
            ].get(0);
            Integer sq = NumberHelper.toNumber((Integer) rcSequence.SubSequence__c) + 1;

            Integer sequenceShift = 1000;
            Integer envShift = 0;
            Integer envNumber = NumberHelper.toNumber((Integer) rcSequence.SandboxNumber__c);
            if (envNumber > 0) {
                Integer sequenceShiftMultiplier = (Integer) Math.pow(10, (Double) String.valueOf(envNumber).length());
                envShift = sequenceShift * envNumber;
                sequenceShift = sequenceShift * sequenceShiftMultiplier;
            }

            return String.valueOf(LEGACY_OFFSET + sequenceShift*sq + envShift + BLOCK_ID);
        }
        @TestVisible
        private Map<String,Object> getEventsAdminDetails(){
            return new Map<String, Object>{
                            POWrappers.FIELD_NAME_EVENTS => getAdminDetails()
                     };
        }
        @TestVisible
        private Map<String, Object> getAdminDetails(){
            Map<String, Object> admindetailsMap = new Map<String, Object>();
            List<AccountContactRole> adminDetails = (List<AccountContactRole>) new AccountContactRoleSelector().selectAccountContactRoles()
                                                    .withoutSelectorOrderByIncluded()
                                                    .selectFields(new AccountContactRoleSelector().getCloseFieldList())
                                                    .setCondition('AccountId = :bind0 AND Role = :bind1')
                                                    .addOrdering('LastModifiedDate', QueryFactory.SortOrder.DESCENDING)
                                                    .setQueryBindings(new List<Object> {m.acc.id,AccountContactRoleHelper.CONTACT_ROLE_EVENTS_ADMIN_USER})
                                                    .setLimit(1)
                                                    .executeQuery();
            for(AccountContactRole actrole: adminDetails){
                admindetailsMap.put(POWrappers.FIELD_NAME_ADMIN_USER , new POWrappers.adminUserDetails(actrole.Contact.FirstName, actrole.Contact.LastName, actrole.Contact.Email));
            }

            return admindetailsMap;
        }
        
    }

    public class ServiceOrderIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_SERVICE_ORDER_ID, m.qt.Id);
            return signUpParameter;
        }
    }

    public class SalesAgentIdBuilder extends Builder {
        public override Map<String, Object> getSignUpParameter() {
            Map<String, Object> signUpParameter = new Map<String, Object>();
            signUpParameter.put(POWrappers.FIELD_NAME_SALES_AGENT_ID, UserInfo.getUserId());
            return signUpParameter;
        }
    }
}