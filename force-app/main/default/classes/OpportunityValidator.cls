public with sharing class OpportunityValidator {

    public class NoQuotesValidator extends Validator{
        private List<Quote> quoteList;
        private Opportunity opty;

        public NoQuotesValidator(List<Quote> quoteList, Opportunity opty) {
            this.quoteList = quoteList;
            this.opty = opty;
        }

        public NoQuotesValidator(String priority, List<Quote> quoteList, Opportunity opty) {
            super(priority);
            this.quoteList = quoteList;
            this.opty = opty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_No_sales_agreements_text,
                Label.Opportunity_Error_OnClose_No_sales_agreements_help_text,
                Response.SEVERITY_ERROR
            	);
        }

        public override Boolean isFailedValidation () {
            return
                quoteList != null && quoteList.isEmpty()
                	&& !OpportunityHelper.isGSPBrand(opty)
                    && opty != null && opty.Brand_Name__c != null
                    && (opty.Brand_Name__c.contains('RingCentral') || OpportunityHelper.isRiseBrand(opty))
                    // quote is not required for Renewal Opportunity without changes
                    && !OpportunityHelper.isRenewalOptyWithoutChanges(opty, quoteList);
        }
    }

    public class UnsupportedBrandValidator extends Validator {
        private Opportunity opportunity;
        private QuoteValidator.BillingProcessType processType;
        private Set<String> unsupportedBrands;

        public UnsupportedBrandValidator(String severity, Opportunity opportunity, Set<String> brandsToCheck, QuoteValidator.BillingProcessType processType) {
            super();
            this.severity = severity;
            this.opportunity = opportunity;
            this.unsupportedBrands = brandsToCheck;
            this.processType = processType;
        }

        public override void addErrorMessage(Response resp) {
            String message = null;
            String details = null;
            switch on this.processType {
                when SYNC_WITH_NGBS {
                    message = String.format(Label.IsNotRequiredToSyncWithNGBS, new List<Object> { this.opportunity.Brand_Name__c });
                    details = String.format(Label.IsNotAvailableToSyncWithNGBSDetails, new List<Object> { this.opportunity.Brand_Name__c });
                }
                when SIGN_UP {
                    message = String.format(Label.IsNotAvailableForSignUp, new List<Object> { this.opportunity.Brand_Name__c });
                    details = String.format(Label.IsNotAvailableForSignUpDetails, new List<Object> { this.opportunity.Brand_Name__c });
                }
            }
            resp.addMessage(message, details, Response.SEVERITY_ERROR);
        }

        public override Boolean isFailedValidation() {
            return this.unsupportedBrands.contains(this.opportunity.Brand_Name__c);
        }
    }

    public class BillingAddressValidator extends Validator{
        private Opportunity opty;
        private String billingAddressError = 'Corresponding fields must be specified: ';
        private String emptyFieldsList = '</br><ul class="slds-list--dotted">';

        public BillingAddressValidator(Opportunity opty) {
            super();
            this.opty = opty;
        }

        public BillingAddressValidator(String priority, Opportunity opty) {
            super(priority);
            this.opty = opty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_CC_Billing_Address_is_incomplete,
                billingAddressError+emptyFieldsList,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            emptyFieldsList = '</br><ul class="slds-list--dotted">';
            if (opty != null) {
                if (String.isBlank(opty.Account.BillingStreet)) {
                    emptyFieldsList += '<li>Billing Street</li>';
                }

                if (String.isBlank(opty.Account.BillingCity)) {
                    emptyFieldsList += '<li>Billing City</li>';
                }

                if (!AccountTriggerHelper.isValidBillingState(opty.Account.BillingState, opty.Account.BillingCountry)) {
                    emptyFieldsList += '<li>Billing State/Province</li>';
                }

                if (String.isBlank(opty.Account.BillingPostalCode)) {
                    emptyFieldsList += '<li>Billing Zip/Postal Code</li>';
                }

                if (String.isBlank(opty.Account.BillingCountry)) {
                    emptyFieldsList += '<li>Billing Country</li>';
                }
            }

            emptyFieldsList += '</ul>';

            return (emptyFieldsList != '</br><ul class="slds-list--dotted"></ul>');
        }
    }

    public class BillingActiveAgreementValidator extends Validator{
        private Quote primaryQuote;
        private Opportunity opty;
        private String errorMessage;

        public BillingActiveAgreementValidator(Quote primaryQuote, Opportunity opty) {
            super();
            this.primaryQuote = primaryQuote;
            this.opty = opty;
            this.errorMessage = Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                errorMessage,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            if (QuoteHelper.isQuoteTermsChanged(primaryQuote, opty)) {
                errorMessage = Label.Opportunity_Error_OnClose_Active_agreement_terms_help_text;
                return true;
            }
            Boolean isValidationFailed = false;
            String jsonString = primaryQuote.Package_Info__c;

            if (String.isNotBlank(jsonString)) {
                BillingWrappers.QuotePackageInfo packageInfoDeserialized = new BillingWrappers.quotePackageInfo();
                //need to rename override and type parameters because they are keywords in apex
                packageInfoDeserialized = (BillingWrappers.QuotePackageInfo)
                    JSON.deserialize(
                        jsonString.substring(1, jsonString.length() - 1)
                            .replaceAll('override', 'isOverride')
                            .replaceAll('type', 'limitType'),
                        BillingWrappers.QuotePackageInfo.class
                    );

                Boolean isAgreementTypeButNotActive =  (QuoteHelper.QUOTE_TYPE_AGREEMENT.equalsIgnoreCase(primaryQuote.QuoteType__c) ||QuoteHelper.QUOTE_TYPE_QUOTE.equalsIgnoreCase(primaryQuote.QuoteType__c))&&
                    !QuoteHelper.QUOTE_STATUS_ACTIVE.equalsIgnoreCase(primaryQuote.Status);
                Boolean isUpgrade = QuoteHelper.isNGBSUpgrade(primaryQuote.QuoteLineItems) &&
                    primaryQuote.Account.Active_Sales_Agreement__c != null;

                Boolean isPriceChanged = isPriceChanged(primaryQuote.QuoteLineItems);

                Boolean isNewCustomer = primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_NEW_CUSTOMER;
                Boolean isUpsell = primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_UPSELL;

                Boolean isEngage = QuoteHelper.isEngageService(primaryQuote)
                    || QuoteHelper.isMultiProductQuoteHasServicePackage(primaryQuote, new List<String>(OpportunityHelper.ENGAGE_TIERS));

                Boolean isUpsellForMigratedAccount = opty.Account.Billing_ID__c != null &&
                    opty.Account.Active_Sales_Agreement__c == null;

                Boolean activeAgreementRequired = (isUpgrade || isPriceChanged || isUpsellForMigratedAccount
                    || isNewCustomer || isEngage || isUpsell) && isAgreementTypeButNotActive &&
                    packageInfoDeserialized.contract != null;

                if (activeAgreementRequired) {
                        isValidationFailed = true;
                }
            }
            return isValidationFailed;
        }
    }

    public class SignUp_NoQuotesValidator extends Validator{
        private Quote quote;

        public SignUp_NoQuotesValidator(Quote quote) {
            this.quote = quote;
        }

        public SignUp_NoQuotesValidator(String priority, Quote quote) {
            super(priority);
            this.quote = quote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.QW_Notification_Oppty_does_not_have_any_quote_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return quote == null;
        }
    }

    public class SyncWithNGBS_NoOpportunityValidator extends Validator {
        private Opportunity opp;

        public SyncWithNGBS_NoOpportunityValidator(String severity, Opportunity opp) {
            super(severity);
            this.opp = opp;
        }
        public SyncWithNGBS_NoOpportunityValidator(Opportunity opp) {
            super();
            this.opp = opp;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.IsNotAvailableToSyncWithNGBS,
                Label.NoOpportunityForSyncWithNGBS,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return opp == null;
        }
    }

    public class SyncWithNGBS_SyncInContactFailedValidator extends Validator {
        private NGBSSyncables.ISyncable syncable;

        public SyncWithNGBS_SyncInContactFailedValidator(NGBSSyncables.ISyncable syncable) {
            super();
            this.syncable = syncable;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED,
                IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED_DETAILS,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return !syncable.isSyncedToICB() && syncable.isICBProvisioningComplete();
        }
    }

    public class SyncWithNGBS_ClosedOpportunityValidator extends Validator {
        private Opportunity opp;

        public SyncWithNGBS_ClosedOpportunityValidator(String severity, Opportunity opp) {
            super(severity);
            this.opp = opp;
        }

        public SyncWithNGBS_ClosedOpportunityValidator(Opportunity opp) {
            super();
            this.opp = opp;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.IsNotAvailableToSyncWithNGBS,
                Label.NotClosedOpportunity,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return !OpportunityHelper.isClosedOpp(opp.StageName);
        }
    }

    public class SignUp_VerizonValidator extends Validator {
        private Opportunity opp;

        public SignUp_VerizonValidator(String severity, Opportunity opp) {
            super(severity);
            this.opp = opp;
        }

        public SignUp_VerizonValidator(Opportunity opp) {
            super();
            this.opp = opp;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.VerizonCantBeSignedUp,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return OpportunityHelper.isVerizon(opp);
        }
    }

    public class SwissVatIdValidator extends Validator {
        private Opportunity opp;
        private List<Approval__c> apps;

        public SwissVatIdValidator(Opportunity opp, List<Approval__c> apps) {
            this.opp = opp;
            this.apps = apps;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                opp.Account.Billing_ID__c == null ? Label.OpportunitySignUpError : Label.OpportunityCloseError,
                Label.VatNumberOrVatIdRequired,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            Boolean isFailedValidation = false;
            Map<String, String> countryCodes = SettingsService.getCountryCodes();
            if (opp != null && opp.Account.BillingCountry != null && countryCodes.containsKey(opp.Account.BillingCountry.toLowerCase()) && countryCodes.get(opp.Account.BillingCountry.toLowerCase()) == 'CHE' && opp.Account.VATNumber__c == null && apps.isEmpty()) {
                isFailedValidation = true;
            }
            return isFailedValidation;
        }
    }

    public class TaiwanVatandTaxValidatorParams {
        public Opportunity opp;
        public List<Approval__c> Approvals;
        public Boolean onClose;
        public TaiwanVatandTaxValidatorParams(
            Opportunity opp,
            List<Approval__c> Approvals,
            Boolean onClose
        ) {
            this.opp = opp;
            this.Approvals = Approvals;
            this.onClose = onClose;
        }
    }

    public class TaiwanVatIdValidator extends Validator {
        public TaiwanVatandTaxValidatorParams params;
        public TaiwanVatIdValidator(TaiwanVatandTaxValidatorParams params) {
            this.params = params;
        }
        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                params.onClose
                    ? Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text
                    : Label.Sign_Up_is_not_allowed,
                Label.VatNumberOrTaxExemptApprovalRequired,
                Response.SEVERITY_ERROR
            );
        }

		public override Boolean isFailedValidation() {
            Boolean isFailedValidation = false;
            Map<String, String> countryCodes = SettingsService.getCountryCodes();
            if (params.opp != null && params.opp.Account.BillingCountry != null && params.opp.Account.VATNumber__c == null && params.Approvals.isEmpty()) {
                	isFailedValidation = true;
           	}
            return isFailedValidation;
        }
    }



    private static Boolean isPriceChanged(List<QuoteLineItem> qliList) {
        Boolean isPriceChanged = false;
        for (QuoteLineItem qli : qliList) {
            if (qli.Entitlement__c == null) {
                continue;
            }

            if (getScaledValue(qli.EffectivePriceNew__c) != getScaledValue(qli.Entitlement__r.EffectivePrice__c) ||
                getScaledValue(qli.UnitPrice) != getScaledValue(qli.Entitlement__r.Price__c)) {
                isPriceChanged = true;
                break;
            }
        }
        return isPriceChanged;
    }

    @TestVisible
    private static Decimal getScaledValue(Decimal value) {
        Decimal result = 0;
        if (value != null) {
            result = value.setScale(2, RoundingMode.HALF_UP);
        }
        return result;
    }

    public class RCEventsAdminRoleValidator extends Validator {
        private Opportunity opp;
        private Quote quote;

        public RCEventsAdminRoleValidator(String severity, Opportunity opp, Quote quote) {
            super(severity);
            this.opp = opp;
            this.quote = quote;
        }

        public RCEventsAdminRoleValidator(Opportunity opp, Quote quote) {
            super();
            this.opp = opp;
            this.quote = quote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Admin_Contact_Role_Missing,
                Label.Admin_Role_Required,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            if (quote == null || opp?.AccountId == null) {
                return false;
            }
            if (!hasEventsInQuote()) {
                return false; 
            }
            List<AccountContactRole> eventsAdminRoles = (List<AccountContactRole>) new AccountContactRoleSelector()
                .selectAccountContactRoles()
                .setCondition('AccountId = :bind0 AND Role = :bind1')
                .setQueryBindings(new List<Object> {opp.AccountId, AccountContactRoleHelper.CONTACT_ROLE_EVENTS_ADMIN_USER})
                .setLimit(1)
                .executeQuery();
            
            return eventsAdminRoles.isEmpty();
        }

        private Boolean hasEventsInQuote() {
            if (String.isBlank(quote.Package_Info__c)) {
                return false;
            }
            List<BillingWrappers.QuotePackageInfo> packageInfos = new BillingWrappers.QuotePackageInfoWrapper().parseQuotePackageInfo(quote.Package_Info__c);
            if (packageInfos != null && packageInfos.size() > 1) {
                for (BillingWrappers.QuotePackageInfo packageInfo : packageInfos) {
                    if (QuoteHelper.RC_EVENT_SERVICES_PRODUCT.equalsIgnoreCase(packageInfo.productName)) {
                        return true;
                    }
                }
            } else {
                return QuoteHelper.isEvents(quote);
            }
    
            return false;
        }
    }
}