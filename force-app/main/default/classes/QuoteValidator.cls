public with sharing class QuoteValidator {

    public abstract class QuoteNotApprovedGenericValidator extends Validator{
        private Quote qt;
        private Opportunity opp;

        public QuoteNotApprovedGenericValidator() {
            super();
        }
        public QuoteNotApprovedGenericValidator(Quote qt, Opportunity opp) {
            this.qt = qt;
            this.opp = opp;
        }

        public override void addErrorMessage(Response resp){
            addErrorMessageBody(resp);
        }
        protected abstract void addErrorMessageBody(Response resp);

        public override Boolean isFailedValidation () {
            return !QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(qt?.Approved_Status__c)
                && opp?.RecordType?.Name == OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY
				&& !OpportunityHelper.isGSPBrand(opp);
        }
    }

    public class PrimaryQuoteNotApprovedValidator extends QuoteNotApprovedGenericValidator{
        public PrimaryQuoteNotApprovedValidator(Quote qt, Opportunity opp) {
            super(qt, opp);
        }
        protected override void addErrorMessageBody(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Primary_quote_is_not_approved_text,
                Label.QW_Notification_Primary_quote_does_not_contains_required_approvals,
                Response.SEVERITY_ERROR
            );
        }
    }

    public class CCQuoteNotApprovedValidator extends QuoteNotApprovedGenericValidator{
        public CCQuoteNotApprovedValidator(Quote qt, Opportunity opp) {
            super(qt, opp);
        }
        protected override void addErrorMessageBody(Response resp) {
            resp.addMessage(
                Label.Contact_center_quote_is_not_approved_text,
                Label.Opportunity_Error_OnClose_Contact_center_is_not_approved_help_text,
                Response.SEVERITY_ERROR
            );
        }
    }

    public class NoQuoteLineItemsValidator extends Validator{
        private Quote primaryQuote;
        private Opportunity opp;

        public NoQuoteLineItemsValidator(Quote primaryQuote, Opportunity opp) {
            this.primaryQuote = primaryQuote;
            this.opp = opp;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Empty_Cart_text,
                Label.Opportunity_Error_OnClose_Empty_cart_help_text,
                Response.SEVERITY_ERROR
            );
        }
        public override Boolean isFailedValidation () {
            if (primaryQuote != null &&!OpportunityHelper.isGSPBrand(opp) && primaryQuote.RecordTypeId == QuoteHelper.RT_ID_PROSERV
                && (new Set<String>{RingCentralHelper.BRAND_BT_BUSINESS, RingCentralHelper.BRAND_TELUS, RingCentralHelper.BRAND_ATT, RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT}).contains(opp.Brand_Name__c)) {
                return false;
            }

            return primaryQuote != null && primaryQuote.QuoteLineItems.isEmpty();
        }
    }

    public class QuoteIsInvalidValidator extends Validator{
        private Quote primaryQuote;

        public QuoteIsInvalidValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public QuoteIsInvalidValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_OnClose_Quote_is_invalid_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return primaryQuote != null && primaryQuote.Quote_is_Invalid__c;
        }
    }

    public class AreaCodeLineItemValidator extends Validator{
        private Quote primaryQuote;
        private List<Area_Code_Line_Item__c> areaCodeLineItems;

        public AreaCodeLineItemValidator(Quote primaryQuote, List<Area_Code_Line_Item__c> areaCodeLineItems) {
            this.primaryQuote = primaryQuote;
            this.areaCodeLineItems = areaCodeLineItems;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_OnClose_Area_codes_are_missing_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            if (
                featureToggle.Area_Codes_Check_On_Opportunity_Close__c &&
                    primaryQuote != null && areaCodeLineItems != null &&
                    QuoteHelper.isAreaCodeLineItemsMissed(primaryQuote.QuoteLineItems, areaCodeLineItems)
                ) {
                isFailedValidation = true;
            }
            return isFailedValidation;
        }
    }

    public class ChangeOrderEmptyPhasesValidator extends Validator{
        private List<Quote> optyQuotes;
        private Opportunity opty;
        private List<Phase__c> phases;

        public ChangeOrderEmptyPhasesValidator(List<Quote> optyQuotes, Opportunity opty, List<Phase__c> phases) {
            this.optyQuotes = optyQuotes;
            this.opty = opty;
            this.phases = phases;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Empty_phases_text,
                Label.Opportunity_Error_OnClose_Empty_phases_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return OpportunityHelper.isChangeOrderOpportunity(opty, optyQuotes) &&
                PhaseHelper.isHasEmptyPhases(phases);
        }
    }

    public class ChangeOrderQliAssignementValidator extends Validator{
        private List<Quote> optyQuotes;
        private Opportunity opty;
        private List<Phase__c> phases;
        private Quote proServQuote;
        private Quote ccProServQuote;

        public ChangeOrderQliAssignementValidator(
            List<Quote> optyQuotes,
            Opportunity opty,
            List<Phase__c> phases,
            Quote proServQuote,
            Quote ccProServQuote) {

            this.optyQuotes = optyQuotes;
            this.opty = opty;
            this.phases = phases;
            this.proServQuote = proServQuote;
            this.ccProServQuote = ccProServQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Unassigned_PLI_text,
                Label.Opportunity_Error_OnClose_Unassigned_PLI_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Quote ccOrProServQuote = proServQuote != null ? proServQuote : ccProServQuote;

            return OpportunityHelper.isChangeOrderOpportunity(opty, optyQuotes) && ccOrProServQuote != null &&
                !PhaseHelper.isAllQLIAssigned(ccOrProServQuote.QuoteLineItems, phases);
        }
    }

    public class ExtendedEnterpriseSupportProductValidator extends Validator{
        private Quote primaryQuote;

        public ExtendedEnterpriseSupportProductValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_OnClose_PS_architect_empty_field_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isPrimaryHasExtendedEnterpriseProdQLI = false;
            if (primaryQuote != null) {
                for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
                    if (qli.Product2.Feature__c == Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT) {
                        isPrimaryHasExtendedEnterpriseProdQLI = true;
                        break;
                    }
                }
            }

            return (isPrimaryHasExtendedEnterpriseProdQLI && primaryQuote.ProServSalesRep__c == null);
        }
    }

    public class EmptyProvisionNotesValidator extends Validator{
        private Quote primaryQuote;
        private Opportunity opty;

        public EmptyProvisionNotesValidator(Quote primaryQuote, Opportunity opty) {
            this.primaryQuote = primaryQuote;
            this.opty = opty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_OnClose_Provisioning_details_on_downsell_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            if (featureToggle.ProvisioningDetailsField__c && primaryQuote != null &&
                isProvNotesEmptyOnDownsell(opty, primaryQuote)) {

                isFailedValidation = true;
            }

            return isFailedValidation;
        }

        @testVisible
        private Boolean isProvNotesEmptyOnDownsell(Opportunity opp, Quote primaryQuote) {
            if (String.isBlank(opp.ProvisioningDetails__c) && opp.Brand_Name__c != OpportunityHelper.BRAND_TELUS_BUSINESS_CONNECT) {
                for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
                    if (qli.NewQuantity__c < qli.Entitlement__r.DisplayQuantity__c) {
                        return true;
                    }
                }
            }

            return false;
        }
    }

    public class ActiveAgreementValidator extends Validator{
        private Quote primaryQuote;
        private Opportunity opty;

        public ActiveAgreementValidator(Quote primaryQuote, Opportunity opty) {
            this.primaryQuote = primaryQuote;
            this.opty = opty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            if (primaryQuote == null) {
                return isFailedValidation;
            }

            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            Boolean isUpgradeOnMonthlyContract =
                primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_UPGRADE &&
                    primaryQuote.Pricebook2.Plan__c == Pricebook2Helper.PLAN_MONTHLY_CONTRACT;

            Boolean isNeedActiveAgreement = false;
            // B-6047
            Id accAgreementId = opty.Account.Active_Sales_Agreement__c;
            if (featureToggle.OpptyActiveSalesAgreementValidation__c) {
                if(accAgreementId != null) {
                    Id fixedPrimaryQuoteId = primaryQuote.Id;

                    isNeedActiveAgreement = (!fixedPrimaryQuoteId.equals(accAgreementId)
                        && isQliQuantityDecreased(primaryQuote))
                        || (primaryQuote.Upsell_Status__c == QuoteHelper.STATUS_UPGRADE
                        && !fixedPrimaryQuoteId.equals(accAgreementId))
                        || (isUpgradeOnMonthlyContract
                        && !fixedPrimaryQuoteId.equals(accAgreementId));
                }
            }

            Boolean isPrimaryQuoteNotActiveAgreement = false;
            if(
                QuoteHelper.QUOTE_TYPE_AGREEMENT.equalsIgnoreCase(primaryQuote.QuoteType__c)
                    && !QuoteHelper.QUOTE_STATUS_ACTIVE.equalsIgnoreCase(primaryQuote.Status)
                ) {
                isPrimaryQuoteNotActiveAgreement = true;
            }
            if (String.isNotEmpty(primaryQuote.Package_Info__c)) {
                List<BillingWrappers.QuotePackageInfo> pInfos = (List<BillingWrappers.QuotePackageInfo>)
                    JSON.deserialize(primaryQuote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
                BillingWrappers.QuotePackageInfo pInfo = pInfos[0];
                if (pInfo.contract == null && primaryQuote.Account.RC_Account_Status__c == AccountHelper.PAID_STATUS)
                {
                    return isFailedValidation;
                }
            }

            if(
                !OpportunityHelper.isBTContactCenterOpportunity(opty)
                    && !RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(opty.Brand_Name__c)
                    && (
                    isPrimaryQuoteNotActiveAgreement
                        || accAgreementId != null && isNeedActiveAgreement
                        || accAgreementId == null && isUpgradeOnMonthlyContract
                )
                ) {
                isFailedValidation = true;
            }

            return isFailedValidation;
        }
    }

    /*
     * Check if the Customer wants to reduce quantity of any Active Agreement's recurring item in the Cart
     * of the Primary Sales Quote
     */
    @testVisible
    private static Boolean isQliQuantityDecreased(Quote primaryQuote) {
        Boolean isQuantityDecreased = false;

        for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
            if (qli.Entitlement__r == null || qli.Entitlement__r.DisplayQuantity__c == null) {
                continue;
            }

            if (qli.NewQuantity__c < qli.Entitlement__r.DisplayQuantity__c) {
                isQuantityDecreased = true;
                break;
            }
        }

        return isQuantityDecreased;
    }

    public class ProservSyncRequiredValidator extends Validator{
        private Quote primaryQuote;
        private Quote proservQuote;

        public ProservSyncRequiredValidator(Quote primaryQuote, Quote proservQuote) {
            this.primaryQuote = primaryQuote;
            this.proservQuote = proservQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Primary_quote_not_synced_with_ProServ,
                String.format(
                    Label.Opportunity_Error_OnClose_Sync_latest_changes_help_text,
                    new String[] {proServQuote.LastModifiedBy.Id, proServQuote.LastModifiedBy.Name}),
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                !QuoteHelper.isChangeOrderQuote(primaryQuote, 'proserv') &&
                    QuoteHelper.isProServSyncRequired(proServQuote);
        }
    }

    public class ProservSoldRequiredValidator extends Validator{
        private Quote primaryQuote;
        private Quote proservQuote;

        public ProservSoldRequiredValidator(Quote primaryQuote, Quote proservQuote) {
            this.primaryQuote = primaryQuote;
            this.proservQuote = proservQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_ProServ_Quote_is_not_marked_as_Sold_text,
                Label.Opportunity_Error_OnClose_ProServ_Quote_is_not_marked_as_Sold_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                QuoteHelper.isProservSoldRequired(proServQuote) &&
                    (QuoteHelper.isChangeOrderQuote(primaryQuote, 'proserv') ||
                        !QuoteHelper.isProServSyncRequired(proServQuote));
        }
    }

    public class ActiveServicePlanValidator extends Validator{
        private Quote primaryQuote;
        private List<TierTypeSetting__c> tierTypeSetting;
        private String userProfileName;
        private Package__c billingPackage;

        public ActiveServicePlanValidator(
            Quote primaryQuote,
            List<TierTypeSetting__c> tierTypeSetting,
            String userProfileName,
            Package__c billingPackage) {

            this.primaryQuote = primaryQuote;
            this.tierTypeSetting = tierTypeSetting;
            this.userProfileName = userProfileName;
            this.billingPackage = billingPackage;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Inactive_service_plan_text,
                Label.Opportunity_Error_OnClose_Inactive_service_plan_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            //Start of EU Privacy Sales Profile Changes
            List<String> salesMgrprofiles = new List<String>();
            List<EU_Component_reference__mdt> profileList = [Select DeveloperName,Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%QuoteValidator%' and DeveloperName='SalesMgrBizProcessingProfiles'];

            for(EU_Component_reference__mdt profRec:profileList){
                if(String.isNotBlank(profRec.Values__c)) {
                    salesMgrprofiles.addall(profRec.Values__c.split(','));
                }
            }
            //End of EU Privacy Sales Profile Changes
            Set<String> tierIdSet = OpportunityHelper.getTierIdSet(tierTypeSetting);
            if (
                primaryQuote != null &&
                    QuoteHelper.isUpgrade(primaryQuote)
                    && !tierIdSet.contains(primaryQuote.Pricebook2.Tier_ID__c)
                    && primaryQuote.Pricebook2.IsActive
                    && primaryQuote.Pricebook2.Service__c == Pricebook2Helper.SERVICE_OFFICE
                    && billingPackage != null
                    && primaryQuote.Pricebook2.Tier_ID__c != billingPackage.RC_Tier_ID__c
                    && userProfileName != ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING
                    && !ProfileHelper.isCurrentUserSysAdmin()
                ) {
                isFailedValidation = true;
            }
            return isFailedValidation;
        }
    }

    public class ActiveAgreementForContactCenterValidator extends Validator{
        private Quote primaryQuote;
        private Opportunity opty;
        private List<Quote> optyQuotes;

        public ActiveAgreementForContactCenterValidator(Quote primaryQuote, Opportunity opty, List<Quote> optyQuotes) {
            this.primaryQuote = primaryQuote;
            this.opty = opty;
            this.optyQuotes = optyQuotes;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_OnClose_Active_agreement_status_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                !OpportunityHelper.BRAND_BT_BUSINESS.equalsIgnoreCase(opty.Brand_Name__c) &&
                    !RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(opty.Brand_Name__c) &&
                    primaryQuote != null &&
                    QuoteHelper.isHasContactCenterProductsInCart(optyQuotes, primaryQuote) &&
                    !QuoteHelper.isActiveAgreement(primaryQuote);
        }
    }

    public class CCProservEngagementValidator extends Validator{
        private Quote primaryQuote;
        private Quote ccProservQuote;

        public CCProservEngagementValidator(Quote primaryQuote, Quote ccProservQuote) {
            this.primaryQuote = primaryQuote;
            this.ccProservQuote = ccProservQuote;
        }

        public override void addErrorMessage(Response resp) {
            String quoteCCCategory = QuoteHelper.getCCCategory(primaryQuote.QuoteLineItems);
            resp.addMessage(
                String.format(
                    Label.Opportunity_Error_OnClose_Deal_without_engaging_cc_proserv_text,
                    new String[] {quoteCCCategory}
                ),
                String.format(
                    Label.Opportunity_Error_OnClose_Deal_without_engaging_cc_proserv_help_text,
                    new String[] {quoteCCCategory}
                ),
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return primaryQuote != null && QuoteHelper.isCCProServEngagementRequired(primaryQuote, ccProServQuote);
        }
    }

    public class CCProservSyncRequiredValidator extends Validator{
        private Quote primaryQuote;
        private Quote ccProservQuote;

        public CCProservSyncRequiredValidator(Quote primaryQuote, Quote ccProservQuote) {
            this.primaryQuote = primaryQuote;
            this.ccProservQuote = ccProservQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                String.format(
                    Label.QW_Notification_Primary_quote_not_synced_with_CCProServ, new String[] {'CC Proserv'}
                ),
                String.format(
                    Label.Opportunity_Error_OnClose_Sync_latest_changes_help_text,
                    new String[] {ccProServQuote.LastModifiedBy.Id, ccProServQuote.LastModifiedBy.Name}),
                Response.SEVERITY_ERROR
            );
        }
        public override Boolean isFailedValidation () {
            return
                !QuoteHelper.isCCProServEngagementRequired(primaryQuote, ccProServQuote)
                    && !QuoteHelper.isChangeOrderQuote(primaryQuote, 'proservCC')
                    && QuoteHelper.isProServSyncRequired(ccProServQuote);
        }
    }

    public class CCProservSoldRequiredValidator extends Validator{
        private Quote primaryQuote;
        private Quote ccProservQuote;

        public CCProservSoldRequiredValidator(Quote primaryQuote, Quote ccProservQuote) {
            this.primaryQuote = primaryQuote;
            this.ccProservQuote = ccProservQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Proserv_quotes_not_marked_as_sold_text,
                Label.Opportunity_Error_OnClose_Proserv_quotes_not_marked_as_sold_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {

            return
                primaryQuote != null &&
                    !QuoteHelper.isCCProServEngagementRequired(primaryQuote, ccProServQuote) &&
                    (QuoteHelper.isChangeOrderQuote(primaryQuote, 'proservCC') ||
                        !QuoteHelper.isProServSyncRequired(ccProServQuote)) &&
                    QuoteHelper.isProservSoldRequired(ccProServQuote);
        }
    }

    public class RentalPhoneValidator extends Validator{
        public Quote primaryQuote;

        public RentalPhoneValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Rental_phones_require_a_long_term_contract_text,
                Label.QW_Notification_Rental_phones_long_term_contract_active_agreement_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            Boolean isAnnualOrMonthlyPlan =
                primaryQuote != null &&
                    (
                        primaryQuote.Pricebook2.Plan__c == Pricebook2Helper.PLAN_MONTHLY_CONTRACT ||
                            primaryQuote.Pricebook2.Plan__c == Pricebook2Helper.PLAN_ANNUAL
                    );
            Boolean isNotActiveAgreement =
                primaryQuote != null &&
                    (
                        StringHelper.asInteger(primaryQuote.Initial_Term_months__c) < 24 ||
                            primaryQuote.QuoteType__c != QuoteHelper.QUOTE_TYPE_AGREEMENT ||
                            primaryQuote.Status != QuoteHelper.QUOTE_STATUS_ACTIVE
                    );

            Boolean isCartHasRentalPhonesUpsell = QuoteHelper.isRentalPhonesUpsellInCart(primaryQuote);

            if (
                isAnnualOrMonthlyPlan &&
                    isNotActiveAgreement &&
                    isCartHasRentalPhonesUpsell
                ) {
                isFailedValidation = true;
            }
            return isFailedValidation;
        }
    }

    public class PhonesAndDlsValidator extends Validator{
        private Quote primaryQuote;
        private Opportunity opty;

        public PhonesAndDlsValidator(Quote primaryQuote, Opportunity opty) {
            this.primaryQuote = primaryQuote;
            this.opty = opty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Different_number_of_phones_and_DLs_text,
                Label.Opportunity_Error_OnClose_Different_number_of_phones_and_DLs_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            if(OpportunityHelper.isGSPBrand(opty)) {
                return isFailedValidation;
            }

            Boolean isMismatchPhonesAndDlsAmount =
                primaryQuote.InvalidDiscountedPhonesQuantity__c ||
                    primaryQuote.InvalidGlobalOfficePhonesQuantity__c ||
                    primaryQuote.InvalidLimitedExtensionPhonesQuantity__c ||
                    primaryQuote.Invalid_GO_LE_Phones_Quantity__c;
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            if (
                primaryQuote != null && featureToggle.AutogenerateOrders__c &&
                    opty != null && opty.RecordType.Name != OpportunityHelper.RT_NAME_CANCEL_OPPORTUNITY &&
                    isMismatchPhonesAndDlsAmount
                ) {
                isFailedValidation = true;
            }
            return isFailedValidation;
        }
    }

    /* Billing validations */
    public class CostCenterAssignementValidator extends Validator{
        private Quote primaryQuote;
        private Map<Id, Cost_Center_Line_Item__c> costCenterLineItems;
        List<String> bypassLicenses;

        public CostCenterAssignementValidator(Quote primaryQuote, Map<Id, Cost_Center_Line_Item__c> costCenterLineItems) {
            this.primaryQuote = primaryQuote;
            this.costCenterLineItems = costCenterLineItems;
            this.bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(primaryQuote?.Opportunity?.BusinessIdentity__c);
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Oppty_Line_items_not_assigned_text,
                Label.Oppty_Line_items_not_assigned_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            Boolean isExistingBusiness = primaryQuote.Account.Billing_ID__c != null;
            return primaryQuote != null
                && primaryQuote.RecordTypeId == QuoteHelper.RT_ID_BILLING
                && featureToggle.Cost_Center_Close_Validation__c
                && hasProductsNotAssignedToCostCenters(isExistingBusiness, primaryQuote.QuoteLineItems, costCenterLineItems, bypassLicenses);
        }

        @testVisible
        private Boolean hasProductsNotAssignedToCostCenters(
            Boolean isExistingBusiness,
            List<QuoteLineItem> qliList,
            Map<Id, Cost_Center_Line_Item__c> costCenterLineItemsMap,
            List<String> bypassLicenses
        ) {
            Boolean result = false;

            if (costCenterLineItemsMap == null || costCenterLineItemsMap.isEmpty()) {
                return result;
            }

            Map<Id, Decimal> qliIdToQliQuantityMap = buildQliIdToQliQuanityMap(qliList, isExistingBusiness, bypassLicenses);

            Map<Id, Decimal> qliIdToCcliQuantityMap = buildQliIdToCcliQuanityMap(costCenterLineItemsMap);

            for (Id qli : qliIdToQliQuantityMap.keySet()) {
                if (qliIdToQliQuantityMap.get(qli) != qliIdToCcliQuantityMap.get(qli)) {
                    result = true;
                    break;
                }
            }

            if (qliIdToQliQuantityMap.size() != qliIdToCcliQuantityMap.size()) {
                result = true;
            }

            return result;
        }

        @testVisible
        private Map<Id, Decimal> buildQliIdToQliQuanityMap(
            List<QuoteLineItem> qliList,
            Boolean isExistingBusiness,
            List<String> bypassLicenses
        ) {
            Map<Id, Decimal> qliIdToQuantityMap = new Map<Id, Decimal>();

            if (qliList == null || qliList.isEmpty()) {
                return qliIdToQuantityMap;
            }

            Set<String> categoryCodesToPass = new Set<String>{
                'CRF',
                'E911'
            };

            for(QuoteLineItem qli : qliList) {

                BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);

                Boolean isTax = qli.Product_Family__c == Product2Helper.FAMILY_TAXES;
                Boolean isHiddenLicense = isHidden(
                    qli,
                    pInfo.id,
                    SettingsService.getLicenseSettings(isExistingBusiness, bypassLicenses).hiddenLicenseSettings
                );

                if (categoryCodesToPass.contains(pInfo.CategoryCode)) {
                    continue;
                }

                Boolean isDigitalLineQli = isDigitalLine(qli.Product2);

                Boolean isServicePlanQli = Product2Helper.isServicePlan(qli.Product2);

                Boolean isSkipByLicenseIdOnEB = isSkipByLicenseId(qli.Product2) && isExistingBusiness;

                Boolean isSkipQli = isTax
                  || isHiddenLicense
                  || qli.Zero_Quantity__c
                  || isDigitalLineQli
                  || isServicePlanQli
                  || isSkipByLicenseIdOnEB;

                if (!isSkipQli) {
                    qliIdToQuantityMap.put(qli.Id, qli.Quantity);
                }
            }

            return qliIdToQuantityMap;
        }

        @testVisible
        private Boolean isHidden(
            QuoteLineItem qli, String catalogId, Map<String, Set<String>> hiddenLicenseSettings) {
            Boolean result = false;
            try {
                String elementId = qli.Product2.ExtID__c;
                Set<String> all = hiddenLicenseSettings.get(SettingsService.ALL);
                Set<String> byCatalogId = hiddenLicenseSettings.get(catalogId);

                result = (all != null && all.contains(elementId)) || (byCatalogId != null && byCatalogId.contains(elementId));
            } catch (Exception e) {
                AquivaHelper.throwAquivaException('can not get information about availability to assign on cost centers');
            }

            return result;
        }

        @testVisible
        private Map<Id, Decimal> buildQliIdToCcliQuanityMap(Map<Id, Cost_Center_Line_Item__c> costCenterLineItemsMap) {

            Map<Id, Decimal> qliIdToCcliQuantityMap = new Map<Id, Decimal>();

            if (costCenterLineItemsMap == null || costCenterLineItemsMap.isEmpty()) {
                return qliIdToCcliQuantityMap;
            }

            for (Cost_Center_Line_Item__c ccli : costCenterLineItemsMap.values()) {
                Boolean isDigitalLineQli = isDigitalLine(ccli.Quote_Line_Item__r.Product2);
                Boolean isServicePlanQli = Product2Helper.isServicePlan(ccli.Quote_Line_Item__r.Product2);
                if (isDigitalLineQli || isServicePlanQli) {
                    continue;
                }
                if (!qliIdToCcliQuantityMap.containsKey(ccli.Quote_Line_Item__c)) {
                    qliIdToCcliQuantityMap.put(ccli.Quote_Line_Item__c, 0);
                }
                if (ccli.Quantity__c == null && ccli.Parent__c != null) {
                    Cost_Center_Line_Item__c parentCcli = costCenterLineItemsMap.get(ccli.Parent__c);
                    Decimal quantity = qliIdToCcliQuantityMap.get(ccli.Quote_Line_Item__c) + parentCcli.Quantity__c;
                    qliIdToCcliQuantityMap.put(ccli.Quote_Line_Item__c, quantity);
                } else {
                    Decimal quantity = qliIdToCcliQuantityMap.get(ccli.Quote_Line_Item__c) + ccli.Quantity__c;
                    qliIdToCcliQuantityMap.put(ccli.Quote_Line_Item__c, quantity);
                }
            }

            return qliIdToCcliQuantityMap;
        }

        private Boolean isDigitalLine(Product2 product) {
            return product != null && product.Family == Product2Helper.FAMILY_TECHNICAL_LICENSE &&
                product.Feature__c == Product2Helper.FEATURE_SERVICE_PLAN;
        }

        private Boolean isSkipByLicenseId(Product2 product) {
          return product != null && Product2Helper.ELEMENT_ID_FAX_NUMBER == product.ExtID__c;
        }
    }

    public class QuoteErrorsValidator extends Validator{
        private Quote primaryQuote;

        public QuoteErrorsValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public QuoteErrorsValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Primary_quote_has_errors_text,
                Label.Opportunity_Error_OnClose_Primary_quote_has_errors_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return QuoteHelper.isBillingQuoteHasErrors(primaryQuote);
        }
    }

    public enum BillingProcessType {CLOSE_ON_OPPORTUNITY, SIGN_UP, SYNC_WITH_NGBS}

    public class BillingPackageExpirationValidator extends Validator{
        private Quote primaryQuote;
        private BillingProcessType processType = null;
        private BillingWrappers.NGBSAccount ngbsAccount;
        private Boolean failedToGetBillingPackage = false;
        public Map<BillingProcessType, String> messages = new Map<BillingProcessType, String>{
            QuoteValidator.BillingProcessType.CLOSE_ON_OPPORTUNITY => Label.Package_has_expired_on_close_help_text,
            QuoteValidator.BillingProcessType.SIGN_UP => Label.Package_has_expired_on_sign_up_help_text,
            QuoteValidator.BillingProcessType.SYNC_WITH_NGBS => Label.PackageIsNotAllowedForSync
        };

        public BillingPackageExpirationValidator(Quote primaryQuote) {
            this(Validator.SEVERITY_NORMAL, primaryQuote, null);
        }

        public BillingPackageExpirationValidator(Quote primaryQuote, BillingProcessType processType) {
            this(Validator.SEVERITY_NORMAL, primaryQuote, processType);
        }

        public BillingPackageExpirationValidator(String priority, Quote primaryQuote, BillingProcessType processType) {
            this(priority, primaryQuote, processType, null);
        }

        public BillingPackageExpirationValidator(Quote primaryQuote, BillingProcessType processType, BillingWrappers.NGBSAccount ngbsAccount) {
            this(Validator.SEVERITY_NORMAL, primaryQuote, processType, ngbsAccount);
        }

        public BillingPackageExpirationValidator(String priority, Quote primaryQuote, BillingProcessType processType, BillingWrappers.NGBSAccount ngbsAccount) {
            super(priority);
            this.primaryQuote = primaryQuote;
            this.processType = processType;
            this.ngbsAccount = ngbsAccount;
        }

        public override void addErrorMessage(Response resp) {
            if (failedToGetBillingPackage) {
                resp.addMessage(
                    Label.Unexpexted_Error_on_checking_package_expiration_text,
                    Label.Unexpexted_Error_on_checking_package_expiration_help_text,
                    Response.SEVERITY_ERROR
                );
            } else {
                resp.addMessage(
                    Label.Package_has_expired_text,
                    messages.get(processType),
                    Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {
            if (!Feature_Toggle__c.getInstance()?.NGBSPackagesExpirationFiltration__c) {
                return false;
            }
            Boolean isQuoteContinueFiltration = true;
            switch on processType {
                when CLOSE_ON_OPPORTUNITY {
                    isQuoteContinueFiltration = checkUpgradePackageStatus(primaryQuote, ngbsAccount)
                        && (QuoteHelper.isNewBillingQuote(primaryQuote)
                        || QuoteHelper.isPOCQuote(primaryQuote));
                }
                when SYNC_WITH_NGBS {
                    isQuoteContinueFiltration = checkUpgradePackageStatus(primaryQuote, ngbsAccount);
                }
            }
            Boolean isPackageExpired = false;
            if (isQuoteContinueFiltration) {
                try {
                    isPackageExpired = isBillingPackageExpired(primaryQuote);
                } catch(Exception ex) {
                    failedToGetBillingPackage = true;
                }
            }
            return isPackageExpired || failedToGetBillingPackage;
        }
    }

    @testVisible
    public static Boolean isBillingPackageExpired(Quote billingQuote) {
        Map<String, Object> fieldsToValue = billingQuote.getPopulatedFieldsAsMap();
        if(!fieldsToValue.containsKey(Quote.Package_Info__c.getDescribe().getName())) {
            throw new AquivaHelper.AquivaException('Required field Quote.Package_Info__c is not selected!');
        }

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(billingQuote);

        String catalogId = pInfo.packageInfo.catalogId;
        String catalogVersion = pInfo.packageInfo.version;

        Boolean result;
        if (Feature_Toggle__c.getInstance()?.SelectPackagesByBusinessIdentity__c) {
            BillingWrappers.NGBSPackage pkg = NGBSAPI.getPackage(catalogId, catalogVersion);
            result = pkg.isExpired(
                QuoteHelper.isNewBusiness(billingQuote),
                AccountHelper.isPartner(billingQuote.Account)
            );
        } else {
            String packageExpirationType = NGBSAPI.getPackageExpirationInfo(catalogId, catalogVersion);
            result = packageExpirationType == BillingWrappers.EXPIRATION_TYPE_EXPIRED;
        }

        return result;
    }

    @testVisible
    private static Boolean checkUpgradePackageStatus(Quote qt, BillingWrappers.NGBSAccount ngbsAccount) {
        if (ngbsAccount == null) {
            try {
                ngbsAccount = NGBSAPI.getNGBSAccount(qt.Account.Billing_ID__c);
            } catch (Exception e) {
                AquivaHelper.throwAquivaException('Failed to check quote upgrade status');
            }
        }

        Boolean isPackageDifferent = false;

        if (ngbsAccount != null) {
            BillingWrappers.NGBSAccountPackage ngbsPackage = ngbsAccount.getPackage();
            BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
            if (ngbsPackage == null) {
                AquivaHelper.throwAquivaException('Failed to check quote upgrade status - no NGBS package');
            }
            if (pInfo?.packageInfo == null) {
                AquivaHelper.throwAquivaException('Failed to check quote upgrade status - no package info on selected package');
            }

            isPackageDifferent = pInfo.packageInfo.catalogId != ngbsPackage.catalogId
                || pInfo.packageInfo.version != ngbsPackage.version;
        }

        return isPackageDifferent;
    }

    public class AreaCodesAssignementValidator extends Validator{
        public Quote primaryQuote;
        public Opportunity opty;
        public List<Area_Code_Line_Item__c> areaCodeLineItems;

        public AreaCodesAssignementValidator(
            Quote primaryQuote,
            Opportunity opty,
            List<Area_Code_Line_Item__c> areaCodeLineItems) {

            this.primaryQuote = primaryQuote;
            this.opty = opty;
            this.areaCodeLineItems = areaCodeLineItems;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Validation_OnClose_Area_Codes_are_missing_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            if (
                featureToggle.Area_Codes_Check_On_Opportunity_Close__c &&
                    primaryQuote != null && opty != null && opty.Tier_Name__c != QuoteHelper.NGBS_FAX_PRODUCT &&
                    !primaryQuote.Enabled_LBO__c &&
                    QuoteHelper.isAreaCodeLineItemsMissedBilling(primaryQuote.QuoteLineItems, areaCodeLineItems)
                ) {
                isFailedValidation = true;
            }
            return isFailedValidation;
        }
    }

    public class ProservSyncAndSoldValidator extends Validator{
        public Quote proServQuote;

        public Boolean isSyncRequired = false;
        public Boolean isSoldRequired = false;

        public ProservSyncAndSoldValidator(Quote proServQuote) {
            this.proServQuote = proServQuote;
        }

        public override void addErrorMessage(Response resp) {
            if (isSyncRequired) {
                resp.addMessage(
                    Label.Primary_quote_not_synced_with_ProServ,
                    String.format(
                        Label.Opportunity_Error_OnClose_Sync_latest_changes_help_text,
                        new String[] {proServQuote.LastModifiedBy.Id, proServQuote.LastModifiedBy.Name}),
                    Response.SEVERITY_ERROR
                );
            }

            if (isSoldRequired) {
                resp.addMessage(
                    Label.Opportunity_Error_OnClose_ProServ_Quote_is_not_marked_as_Sold_text,
                    Label.Opportunity_Error_OnClose_ProServ_Quote_is_not_marked_as_Sold_help_text,
                    Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if (proServQuote != null) {
                if (
                    proServQuote.Pricebook2.AllowedRecordType__c == Pricebook2Helper.ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV
                        && !QuoteHelper.isCancelled(proServQuote)
                        && !QuoteHelper.isSold(proServQuote)
                    ) {
                    if (!QuoteHelper.isSynced(proServQuote)) {
                        isSyncRequired = true;
                    } else {
                        isSoldRequired = true;
                    }
                    isFailedValidation = true;
                }
            }
            return isFailedValidation;
        }
    }

    public class ProductReachedSalesEndDateValidator extends Validator{
        private Quote primaryQuote;

        public ProductReachedSalesEndDateValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.Opportunity_Error_Some_Products_Reached_SalesEndDate_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return isAnyProductReachedSalesEndDate();
        }


        private Boolean isAnyProductReachedSalesEndDate() {
            if (primaryQuote.QuoteLineItems == null || primaryQuote.QuoteLineItems.isEmpty()) {
                return false;
            }

            Boolean isNotRCCC = !QuoteHelper.isCCService(primaryQuote);

            for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
                if (!QuoteLineItemHelper.isProductReachedSalesEndDate(qli)) {
                    continue;
                }

                Boolean isQuantityIncreased = qli.NewQuantity__c > qli.Entitlement__r.DisplayQuantity__c;
                if (qli.Entitlement__c == null || (isQuantityIncreased && isNotRCCC)) {
                    return true;
                }
            }

            return false;
        }
    }

    public class CCQuoteRequiresCCProservValidator extends Validator{
        public Quote ccQuote;
        public Quote ccProServQuote;

        public CCQuoteRequiresCCProservValidator(Quote ccQuote, Quote ccProServQuote) {
            this.ccQuote = ccQuote;
            this.ccProServQuote = ccProServQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_No_CC_close_without_engaging_CC_ProServ_text,
                Label.Opportunity_Error_OnClose_No_CC_close_without_engaging_CC_ProServ_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return QuoteHelper.isCCQuoteRequiresCCProserv(ccQuote, ccProServQuote);
        }
    }

    public class CCProservQuoteValidator extends Validator{
        public Quote ccProServQuote;

        public Boolean isSyncRequired = false;
        public Boolean isSoldRequired = false;

        public CCProservQuoteValidator(Quote ccProServQuote) {
            this.ccProServQuote = ccProServQuote;
        }

        public override void addErrorMessage(Response resp) {
            String proservType = OpportunityHelper.isEngage(ccProServQuote.Opportunity) ? 'Proserv' : 'CC Proserv';
            if (isSyncRequired) {
                resp.addMessage(
                    String.format(
                        Label.QW_Notification_Primary_quote_not_synced_with_CCProServ, new String[] {proservType}
                    ),
                    String.format(
                        Label.Opportunity_Error_OnClose_Sync_latest_changes_help_text,
                        new String[] {
                            ccProServQuote.LastModifiedBy.Id,
                            ccProServQuote.LastModifiedBy.Name
                        }
                    ),
                    Response.SEVERITY_ERROR
                );
            }

            if (isSoldRequired) {
                resp.addMessage(
                    String.format(
                        Label.Opportunity_Error_OnClose_CC_ProServ_is_not_marked_as_sold_text,
                        new String[] {proservType}
                    ),
                    String.format(
                        Label.Opportunity_Error_OnClose_CC_ProServ_is_not_marked_as_sold_help_text,
                        new String[] {proservType}
                    ),
                    Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if (ccProServQuote != null) {
                if (!QuoteHelper.isCancelled(ccProServQuote) && !QuoteHelper.isSold(ccProServQuote)) {
                    if (!QuoteHelper.isSynced(ccProServQuote) && !QuoteHelper.isOutForSignature(ccProServQuote)) {
                        isSyncRequired = true;
                    } else {
                        isSoldRequired = true;
                    }
                    isFailedValidation = true;
                }
            }
            return isFailedValidation;
        }
    }

    public class RentalNGBSInCartValidator extends Validator{
        private Quote primaryQuote;

        public RentalNGBSInCartValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Rental_phones_require_a_long_term_contract_text,
                Label.QW_Notification_Rental_phones_long_term_contract_quote_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                primaryQuote != null &&
                    QuoteHelper.isRentalPhonesUpsellInCart(primaryQuote) &&
                    StringHelper.asInteger(primaryQuote.Initial_Term_months__c) < 24;
        }
    }

    public class SignUp_QuoteHasErrorsValidator extends Validator{
        private Quote primaryQuote;

        public SignUp_QuoteHasErrorsValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.SignUpValidationQuoteHasErrorsMessage,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return QuoteHelper.isBillingQuoteHasErrors(primaryQuote);
        }
    }

    public class SignUp_QuoteHasPaymentMethodValidator extends Validator{
        private Quote primaryQuote;

        public SignUp_QuoteHasPaymentMethodValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Sign_Up_is_not_allowed,
                Label.EmptyPaymentMethod,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            if (this.primaryQuote.PaymentMethod__c != null) {
                return false;
            }
            return true;
        }
    }

    public class SignUp_BillingCountryMatchBIValidator extends Validator{
        private Quote primaryQuote;

        public SignUp_BillingCountryMatchBIValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public SignUp_BillingCountryMatchBIValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            String biId = QuoteHelper.getApprovedBiIdFromQuote(primaryQuote);

            if (biId == RingCentralHelper.BUSINESS_IDENTITY_RC_EU_DE) {
                resp.addMessage(
                        Label.Opportunity_SignUp_Validation_SignUp_failed,
                        Label.Billing_Country_Is_Not_Match_RC_EU_Germany_BI,
                        Response.SEVERITY_ERROR
                );
            } else if (biId == RingCentralHelper.BUSINESS_IDENTITY_RC_EU_FR) {
                resp.addMessage(
                        Label.Opportunity_SignUp_Validation_SignUp_failed,
                        Label.Billing_Country_Is_Not_Match_RC_EU_France_BI,
                        Response.SEVERITY_ERROR
                );
            } else if (biId == RingCentralHelper.BUSINESS_IDENTITY_RC_EU_CH
                         || biId == RingCentralHelper.BUSINESS_IDENTITY_UO_CH
                         || biId == RingCentralHelper.BUSINESS_IDENTITY_ACO_CH
            ) {
                resp.addMessage(
                        Label.Opportunity_SignUp_Validation_SignUp_failed,
                        Label.Billing_Country_Is_Not_Match_Swiss_BI,
                        Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {
            Boolean isNewBusiness = QuoteHelper.isNewBusiness(primaryQuote);
            Boolean isNotMultiProductTechnicalQuote = !primaryQuote.IsMultiProductTechnicalQuote__c;
            Boolean isCheckedBrand = OpportunityHelper.isAvaya(primaryQuote.Opportunity)
                                    || OpportunityHelper.isAtos(primaryQuote.Opportunity)
                                    || OpportunityHelper.isRcEuBrand(primaryQuote.Opportunity);
            Boolean isBillingCountryBIMismatch = !QuoteHelper.isBillingCountryMatchBI(primaryQuote);

            return isNewBusiness
                && isNotMultiProductTechnicalQuote
                && isCheckedBrand
                && isBillingCountryBIMismatch;
        }
    }

    public class SignUp_DocusignNotCompletedValidator extends Validator{
        private Quote primaryQuote;

        public SignUp_DocusignNotCompletedValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote.isMultiProductTechnicalQuote__c ? primaryQuote.MasterQuote__r : primaryQuote;
        }

        public SignUp_DocusignNotCompletedValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote.isMultiProductTechnicalQuote__c ? primaryQuote.MasterQuote__r : primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.Opportunity_Validation_SignUp_Envelop_NOT_Completed_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                !OpportunityHelper.isAvaya(primaryQuote.Opportunity) &&
                !OpportunityHelper.isAtos(primaryQuote.Opportunity) &&
                !OpportunityHelper.isRainbow(primaryQuote.Opportunity) &&
                !AccountHelper.isInvoiceOnBehalfAccount(primaryQuote.Account) &&
                !AccountHelper.isWholesaleAccount(primaryQuote.Account) &&
                !QuoteHelper.isDocuSignStatusCompleted(primaryQuote);
        }
    }

    public class SignUp_AreaCodesAssignementValidator extends Validator{
        public Quote primaryQuote;
        public List<Area_Code_Line_Item__c> areaCodeLineItems;

        public SignUp_AreaCodesAssignementValidator(
            String priority,
            Quote primaryQuote,
            List<Area_Code_Line_Item__c> areaCodeLineItems) {

            super(priority);
            this.primaryQuote = primaryQuote;
            this.areaCodeLineItems = areaCodeLineItems;
        }

        public SignUp_AreaCodesAssignementValidator(
            Quote primaryQuote,
            List<Area_Code_Line_Item__c> areaCodeLineItems) {

            this.primaryQuote = primaryQuote;
            this.areaCodeLineItems = areaCodeLineItems;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.Opportunity_Validation_SignUp_Area_Codes_are_missing_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                QuoteHelper.isOfficeService(primaryQuote) && !primaryQuote.Enabled_LBO__c &&
                    QuoteHelper.isAreaCodeLineItemsMissedBilling(primaryQuote.QuoteLineItems, areaCodeLineItems);
        }
    }

    public class SignUp_NGBSOfficeSignUpValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_NGBSOfficeSignUpValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_NGBSOfficeSignUpValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.Opportunity_SignUp_Validation_NGBS_is_not_allowed,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

            Boolean isMeetingsSignUp =
                String.isNotBlank(primaryQuote.Package_Info__c) &&
                    Product2Helper.PRODUCT_MEETINGS.equalsIgnoreCase(
                        BillingWrappers.parseQuotePackageInfo(primaryQuote.Package_Info__c).productName
                    );

            return !featureToggle.NGBSOfficeSignUp__c &&
                QuoteHelper.isNewBillingQuote(primaryQuote) &&
                !isMeetingsSignUp;
        }
    }

    public class SignUp_ContractPricingValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_ContractPricingValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_ContractPricingValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Contract_pricing_requirement_text,
                Label.QW_Notification_Contract_pricing_requirement_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                !Feature_Toggle__c.getInstance().Enable_new_Contract_Term_flow__c &&
                    QuoteHelper.getPlan(primaryQuote) == Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT &&
                    QuoteHelper.QUOTE_TYPE_AGREEMENT.equalsIgnoreCase(primaryQuote.QuoteType__c) &&
                    QuoteHelper.QUOTE_STATUS_ACTIVE.equalsIgnoreCase(primaryQuote.Status) &&
                    StringHelper.asInteger(primaryQuote.Initial_Term_months__c) < 12;
        }
    }

    public class SignUp_SpecialTermsRequireActiveAgreementValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_SpecialTermsRequireActiveAgreementValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_SpecialTermsRequireActiveAgreementValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_activeAgreement_is_not_active_text,
                Label.QW_Notification_activeAgreementSpecialTerms_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return
                String.isNotBlank(primaryQuote.Special_Terms__c) &&
                    !QuoteHelper.QUOTE_STATUS_ACTIVE.equalsIgnoreCase(primaryQuote.Status);
        }
    }

    public class SignUp_SpecialTermsWithoutContractValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_SpecialTermsWithoutContractValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_SpecialTermsWithoutContractValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Special_Terms_are_selected_without_Contract_text,
                Label.QW_Notification_Special_Terms_are_selected_without_Contract_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            if (primaryQuote != null && String.isNotBlank(primaryQuote.Package_Info__c)) {
                String packageJSON = primaryQuote.Package_Info__c;
                BillingWrappers.QuotePackageInfo info = (BillingWrappers.QuotePackageInfo)
                    JSON.deserialize(
                        packageJSON.substring(1, packageJSON.length() - 1),
                        BillingWrappers.QuotePackageInfo.class
                    );
                isFailedValidation = String.isNotBlank(primaryQuote.Special_Terms__c) && (info.contract == null);
            }

            return isFailedValidation;
        }
    }

    public class SignUp_AreaCodeLineItemValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_AreaCodeLineItemValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_AreaCodeLineItemValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Area_Code_are_missing_text,
                Label.QW_Notification_Area_Code_are_missing_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

            String packageJSON = primaryQuote.Package_Info__c;
            BillingWrappers.QuotePackageInfo info = (BillingWrappers.QuotePackageInfo)
                JSON.deserialize(
                    packageJSON.substring(1, packageJSON.length() - 1),
                    BillingWrappers.QuotePackageInfo.class
                );

            return
                featureToggle.BillingWizardAreaCodes__c &&
                    QuoteHelper.NGBS_OFFICE_PRODUCT.equalsIgnoreCase(info.productName) &&
                    (primaryQuote.AreaCode__c == null || primaryQuote.FaxAreaCode__c == null);
        }
    }

    public class SignUp_ProductReachedSalesEndDateValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_ProductReachedSalesEndDateValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_ProductReachedSalesEndDateValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_on_SignUp_Some_Products_Reached_SalesEndDate_text,
                Label.Opportunity_Error_Some_Products_Reached_SalesEndDate_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
                if (QuoteLineItemHelper.isProductReachedSalesEndDate(qli)) {
                    return true;
                }
            }
            return false;
        }
    }

    public class SignUp_ContractAndActiveAgreementValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_ContractAndActiveAgreementValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_ContractAndActiveAgreementValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Fail_Header,
                Label.Opportunity_SignUp_Active_Agreement_Fail,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return QuoteHelper.getNGBSContract(primaryQuote) != null && !QuoteHelper.isActiveAgreement(primaryQuote);
        }
    }

    public class SignUp_RentalPhoneValidator extends Validator{
        public Quote primaryQuote;

        public SignUp_RentalPhoneValidator(String priority, Quote primaryQuote) {
            super(priority);
            this.primaryQuote = primaryQuote;
        }

        public SignUp_RentalPhoneValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Rental_phones_require_a_long_term_contract_text,
                Label.QW_Notification_Rental_phones_long_term_contract_quote_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;

            Decimal initialTermMonths = primaryQuote.Initial_Term_months__c == null
                ? 0
                : Decimal.valueOf(primaryQuote.Initial_Term_months__c);

            if (initialTermMonths  != null &&
                initialTermMonths < 24 &&
                QuoteHelper.isRentalPhonesUpsellInCart(primaryQuote)
                ) {
                isFailedValidation = true;
            }

            return isFailedValidation;
        }
    }

    public class SignUp_NoQuoteLineItemsValidator extends Validator{
        private Quote primaryQuote;

        public SignUp_NoQuoteLineItemsValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public SignUp_NoQuoteLineItemsValidator(String priotity, Quote primaryQuote) {
            super(priotity);
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.QW_Notification_Empty_Cart_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return primaryQuote.QuoteLineItems.isEmpty();
        }
    }

    public class SignUp_PrimaryQuoteNotApprovedValidator extends Validator{
        private Quote primaryQuote;

        public SignUp_PrimaryQuoteNotApprovedValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.QW_Notification_Primary_quote_is_not_approved_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return !QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(primaryQuote.Approved_Status__c);
        }
    }

    public class SignUp_CCQuoteNotApprovedValidator extends Validator{
        private Quote ccQuote;

        public SignUp_CCQuoteNotApprovedValidator(Quote ccQuote) {
            this.ccQuote = ccQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.QW_Notification_Contact_center_quote_is_not_approved_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return ccQuote != null && !QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(ccQuote.Approved_Status__c);
        }
    }

    public class SignUp_ActiveAgreementValidator extends Validator{
        public Quote primaryQuote;
        public Boolean isMPUB;

        public SignUp_ActiveAgreementValidator(String priority, Quote primaryQuote, Boolean isMPUB) {
            super(priority);
            this.primaryQuote = primaryQuote;
            this.isMPUB = isMPUB;
        }

        public SignUp_ActiveAgreementValidator(Quote primaryQuote, Boolean isMPUB) {
            this.primaryQuote = primaryQuote;
            this.isMPUB = isMPUB;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.QW_Notification_activeAgreement_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            String status = isMPUB ? primaryQuote?.MasterQuote__r.Status : primaryQuote?.Status;
            String quoteType = isMPUB ? primaryQuote?.MasterQuote__r.QuoteType__c : primaryQuote?.QuoteType__c;
            return
                QuoteHelper.QUOTE_TYPE_AGREEMENT.equalsIgnoreCase(quoteType) &&
                    !QuoteHelper.QUOTE_STATUS_ACTIVE.equalsIgnoreCase(status);
        }
    }

    public class SignUp_ProservSyncAndSoldValidator extends Validator{
        public Quote psQuote;

        public SignUp_ProservSyncAndSoldValidator(String priority, Quote psQuote) {
            super(priority);
            this.psQuote = psQuote;
        }

        public SignUp_ProservSyncAndSoldValidator(Quote psQuote) {
            this.psQuote = psQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.Primary_quote_not_synced_with_ProServ + '. ' + Label.QW_Notification_Sync_latest_changes,
                Response.SEVERITY_ERROR,
                URL.getOrgDomainUrl().toExternalForm() + '/' + psQuote.LastModifiedBy.Id,
                psQuote.LastModifiedBy.Name
            );
        }

        public override Boolean isFailedValidation () {
            return
                psQuote != null &&
                    psQuote.ProServ_Status__c != null &&
                    !(QuoteHelper.isSold(psQuote) || QuoteHelper.isCancelled(psQuote) || QuoteHelper.isSynced(psQuote));
        }
    }

    public class SignUp_MissApprovedPOCApprovalValidator extends Validator{
        public Quote primaryQuote;
        public List<Approval__c> approvals;

        public SignUp_MissApprovedPOCApprovalValidator(Quote primaryQuote, List<Approval__c> approvals) {
            this.primaryQuote = primaryQuote;
            this.approvals = approvals;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.Sign_Up_Approved_POC_Account_Approval_is_required,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            List<Approval__c> approvedPOCapprovals = getApprovedPOCapprovals(approvals);
            return !ApprovalHelper.hasApprovedPOCApproval(approvedPOCapprovals);
        }
    }

    @testVisible
    private static List<Approval__c> getApprovedPOCapprovals(List<Approval__c> approvals) {
        List<Approval__c> approvedPOCapprovals = new List<Approval__c>();

        for (Approval__c app : approvals) {
            if (app.RecordTypeId == ApprovalHelper.RT_ID_POC_ACCOUNT
                && app.Status__c == ApprovalHelper.STATUS_APPROVED) {
                approvedPOCapprovals.add(app);
            }
        }

        return approvedPOCapprovals;
    }

    public class SignUp_PendingTaxExemptionApprovalValidator extends Validator{
        public Quote primaryQuote;
        public List<Approval__c> approvals;

        public SignUp_PendingTaxExemptionApprovalValidator(Quote primaryQuote, List<Approval__c> approvals) {
            this.primaryQuote = primaryQuote;
            this.approvals = approvals;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.QW_Notification_Tax_Exempt_Approval_is_in_progress_text,
                Label.QW_Notification_Tax_Exempt_Approval_is_in_progress_redirect,
                Response.SEVERITY_WARNING
            );
        }

        public override Boolean isFailedValidation () {
            List<Approval__c> pendingTaxExemptApprovals = getPendingTaxExemptApprovals(approvals);
            return TaxExemptionHelper.isEnabled && !pendingTaxExemptApprovals.isEmpty();
        }
    }

    @testVisible
    private static List<Approval__c> getPendingTaxExemptApprovals(List<Approval__c> approvals) {
        List<Approval__c> pendingTaxExemptApprovals = new List<Approval__c>();

        for (Approval__c app : approvals) {
            if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                && app.Status__c == ApprovalHelper.STATUS_PENDING_APPROVAL) {
                pendingTaxExemptApprovals.add(app);
            }
        }

        return pendingTaxExemptApprovals;
    }

    public class SignUp_InProgressTaxExemptionApprovalValidator extends Validator{
        public Quote primaryQuote;
        public List<Approval__c> approvals;

        public SignUp_InProgressTaxExemptionApprovalValidator(Quote primaryQuote, List<Approval__c> approvals) {
            this.primaryQuote = primaryQuote;
            this.approvals = approvals;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.QW_Notification_Tax_Exempt_Approval_is_in_progress_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            List<Approval__c> inProgressTaxExemptApprovals = getInProgressTaxExemptiApprovals(approvals);
            return !TaxExemptionHelper.isEnabled && !inProgressTaxExemptApprovals.isEmpty();
        }
    }

    @testVisible
    private static List<Approval__c> getInProgressTaxExemptiApprovals(List<Approval__c> approvals) {
        List<Approval__c> inProgressTaxExemptApprovals = new List<Approval__c>();

        for (Approval__c app : approvals) {
            if (app.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                && app.Status__c != ApprovalHelper.STATUS_APPROVED
                && app.Status__c != ApprovalHelper.STATUS_REJECTED
                && app.Status__c != ApprovalHelper.STATUS_RECALLED) {
                inProgressTaxExemptApprovals.add(app);
            }
        }

        return inProgressTaxExemptApprovals;
    }

    public class QuantityShippingValidator extends Validator {
        public Quote primaryQuote;
        public List<QuoteLineItem> qlis;
        public Boolean checkSFAccount;
        public Boolean isProServQuotesNotCancelled;

        public QuantityShippingValidator(
            Quote primaryQuote,
            List<QuoteLineItem> qlis,
            Boolean checkSFAccount,
            Boolean isProServQuotesNotCancelled
        ) {
            this.primaryQuote = primaryQuote;
            this.qlis = qlis;
            this.checkSFAccount = checkSFAccount;
            this.isProServQuotesNotCancelled = isProServQuotesNotCancelled;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Unassigned_Shipping_Devices_text,
                Label.Opportunity_Error_OnClose_Unassigned_Shipping_Devices_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            Boolean isPocAccount = false;
            if (checkSFAccount) {
                isPocAccount = primaryQuote.Account.Offer_Type__c == QuoteHelper.PACKAGE_OFFER_TYPE_POC;
            } else {
                BillingWrappers.NGBSAccount ngbsAcc = NGBSAPI.getNGBSAccount(primaryQuote?.Account?.Billing_ID__c);
                isPocAccount = ngbsAcc != null && ngbsAcc.getPackage().offerType == QuoteHelper.PACKAGE_OFFER_TYPE_POC;
            }
            Map<QuoteLineItem, Integer> mapQuantity = new Map<QuoteLineItem, Integer>();
            if (primaryQuote != null &&
				(primaryQuote.Enabled_LBO__c || isPocAccount) &&
                primaryQuote.Account.RC_User_ID__c != null &&
                primaryQuote.Account.Billing_ID__c != null &&
                primaryQuote.Upsell_Status__c != QuoteHelper.STATUS_NEW_CUSTOMER &&
                !isProServQuotesNotCancelled)
            {
                if (qlis.isEmpty()) {
                    qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                        .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object>{new Set<Id>{primaryQuote.Id}})
                        .executeQuery();
                }

                if (!qlis.isEmpty()) {
                    for (QuoteLineItem qli : qlis) {
                        if (qli.PackageInfo__c != null) {
                            Boolean isShippingAvailableForLicense = Product2Helper.isShippingTypeAuto(qli.Product2);
                            if (isShippingAvailableForLicense) {
                                if (!qli.Zero_Quantity__c && qli.Quantity > 0) {
                                    if (!qli.Custom_Address_QLI__r.isEmpty()) {
                                        Integer caaQuantity = 0;
                                        for (CustomAddressAssignments__c caa : qli.Custom_Address_QLI__r) {
                                            caaQuantity += Integer.valueOf(String.valueOf(caa.Quantity__c));
                                            mapQuantity.put(qli, caaQuantity);
                                        }
                                    } else {
                                        isFailedValidation = true;
                                    }
                                }
                            }
                        }
                    }

                    if (mapQuantity.size() > 0) {
                        for (QuoteLineItem qli : mapQuantity.keySet()) {
                            Integer shippingQuantity = mapQuantity.get(qli);
                            if (qli.Quantity > 0 && qli.Quantity != shippingQuantity) {
                                isFailedValidation = true;
                            }
                        }
                    }
                }
            }
            return isFailedValidation;
        }
    }

    public class QuantityShippingTabPermissionValidator extends Validator {
        public Quote primaryQuote;
        public List<QuoteLineItem> qlis;

        public QuantityShippingTabPermissionValidator(Quote primaryQuote, List<QuoteLineItem> qlis) {
            this.primaryQuote = primaryQuote;
            this.qlis = qlis;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_ShippingTabPermissions_text,
                Label.Opportunity_Error_OnClose_ShippingTabPermissions_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if (primaryQuote != null && primaryQuote.Enabled_LBO__c &&
                primaryQuote.Account.RC_User_ID__c != null &&
                primaryQuote.Account.Billing_ID__c != null)
            {
                BillingWrappers.NGBSAccount ngbsAcc = NGBSAPI.getNGBSAccount(primaryQuote.Account.Billing_ID__c);
                if (ngbsAcc != null && ngbsAcc.getPackage().offerType == QuoteHelper.PACKAGE_OFFER_TYPE_POC) {
                    return isFailedValidation;
                }
                if (qlis.isEmpty()) {
                    qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                        .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object>{new Set<Id>{primaryQuote.Id}})
                        .executeQuery();
                }

                if (!qlis.isEmpty()) {
                    for (QuoteLineItem qli : qlis) {
                        if (qli.PackageInfo__c != null) {
                            BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                                JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);
                            if (qliPackageInfo.CategoryCode != null && Product2Helper.SHIPPING_PHONES.contains(qliPackageInfo.CategoryCode)) {
                                if (!qli.Zero_Quantity__c && qli.Quantity > 0) {
                                    if (!Schema.SObjectType.CustomAddress__c.isAccessible() || !Schema.SObjectType.CustomAddressAssignments__c.isAccessible()) {
                                        isFailedValidation = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return isFailedValidation;
        }
    }

    public class ShippingCostCenterValidator extends Validator {
        public Quote primaryQuote;
        public List<QuoteLineItem> qlis;
        public List<Cost_Center__c> costCenters;
        public Boolean isProservNotCancelled;

        public ShippingCostCenterValidator(
            Quote primaryQuote,
            List<QuoteLineItem> qlis,
            List<Cost_Center__c> costCenters,
            Boolean isProservNotCancelled
        ) {
            this.primaryQuote = primaryQuote;
            this.qlis = qlis;
            this.costCenters = costCenters;
            this.isProservNotCancelled = isProservNotCancelled;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Unassigned_ShippingGroups_to_CostCenters_text,
                Label.Opportunity_Error_OnClose_Unassigned_ShippingGroups_to_CostCenters_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            Boolean isPOC = false;
            List<String> costCentersIds = new List<String>();

            if (primaryQuote?.Account?.Offer_Type__c != null) {
                isPOC = QuoteHelper.isOfferTypePOC(primaryQuote.Account.Offer_Type__c);
            }

            if(primaryQuote?.Opportunity?.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS || isPOC) {
                return isFailedValidation;
            }

            if (primaryQuote != null && primaryQuote.Enabled_LBO__c && !isProservNotCancelled) {
                if (costCenters.isEmpty()) {
                    costCenters = new CostCenterSelector()
                        .selectCostCentersByQuoteId(new List<Object>{new Set<Id>{primaryQuote.Id}})
                        .executeQuery();
                }
                if (!costCenters.isEmpty()) {
                    for (Cost_Center__c cc : costCenters) {
                        costCentersIds.add(cc.BillingId__c);
                    }
                }
                if (qlis.isEmpty()) {
                    qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                        .selectQuoteLineItemsByQuoteIdsForShipping(
                            new List<Object> {new Set<Id>{primaryQuote.Id}})
                        .executeQuery();
                }
            }

            if (!qlis.isEmpty() && !costCenters.isEmpty()) {
                for (QuoteLineItem qli : qlis) {
                    if (qli.PackageInfo__c != null) {
                        BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                            JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);

                        if (qliPackageInfo.CategoryCode != null && Product2Helper.SHIPPING_PHONES.contains(qliPackageInfo.CategoryCode)) {
                            if (!qli.Zero_Quantity__c && qli.Quantity > 0) {
                                if (qli.Custom_Address_QLI__r.size() > 0) {
                                    for (CustomAddressAssignments__c caa : qli.Custom_Address_QLI__r) {
                                        if (!costCentersIds.contains(caa.ShippingBillingCodeId__c)) {
                                            isFailedValidation = true;
                                        }
                                    }
                                } else {
                                    isFailedValidation = true;
                                }
                            }
                        }
                    }
                }
            }
            return isFailedValidation;
        }
    }

    public class SignUp_QuantityShippingValidator extends Validator {
        public Quote primaryQuote;
        public List<QuoteLineItem> qlis;
        public Boolean isAllowProcessOrderWithoutShipping;
        public Boolean isProServQuotesNotCancelled;

        public SignUp_QuantityShippingValidator(
            Quote primaryQuote,
            List<QuoteLineItem> qlisForShipping,
            Boolean isAllowProcessOrderWithoutShipping,
            Boolean isProServQuotesNotCancelled
        ) {
            this.primaryQuote = primaryQuote;
            this.qlis = qlisForShipping;
            this.isAllowProcessOrderWithoutShipping = isAllowProcessOrderWithoutShipping;
            this.isProServQuotesNotCancelled = isProServQuotesNotCancelled;
        }

        public override void addErrorMessage(Response resp) {
            if(isAllowProcessOrderWithoutShipping){
                resp.addMessage(
                    Label.Opportunity_Error_OnSignUp_Devices_Less_Quantity_Then_Shipping_text,
                    Label.Opportunity_Warning_OnSignUp_Unassigned_Shipping_Devices_text,
                    Response.SEVERITY_WARNING
                );
            } else {
                resp.addMessage(
                    Label.Opportunity_Error_OnSignUp_Devices_Less_Quantity_Then_Shipping_text,
                    Label.Opportunity_Error_OnSignUp_Unassigned_Shipping_Devices_text,
                    Response.SEVERITY_ERROR
                );
            }
        }

        public override Boolean isFailedValidation () {
            return isProServQuotesNotCancelled
                ? false
                : getSignUpShippingValidations(primaryQuote, qlis, 'SignUp_QuantityShippingValidator') ;
        }
    }

    public class SignUp_QuantityLessThenShippingValidator extends Validator {
        public Quote primaryQuote;
        public List<QuoteLineItem> qlis;

        public SignUp_QuantityLessThenShippingValidator(Quote primaryQuote, List<QuoteLineItem> qlisForShipping) {
            this.primaryQuote = primaryQuote;
            this.qlis = qlisForShipping;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnSignUp_Devices_Less_Quantity_Then_Shipping_text,
                Label.Opportunity_Error_OnSignUp_Devices_Less_Quantity_Then_Shipping_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return getSignUpShippingValidations(primaryQuote, qlis, 'SignUp_QuantityLessThenShippingValidator');
        }
    }

    public static Boolean getSignUpShippingValidations(Quote primaryQuote, List<QuoteLineItem> qlis, String validator) {
        Map<QuoteLineItem, Integer> mapQuantity = new Map<QuoteLineItem, Integer>();
        Boolean isFailedValidation = false;
        Boolean allowShipping = Feature_Toggle__c.getInstance().Shipping_Tab_New_Business__c;
        if (allowShipping && primaryQuote != null &&
            primaryQuote.Account.RC_User_ID__c == null &&
            primaryQuote.Account.Billing_ID__c == null)
        {
            if (qlis != null && !qlis.isEmpty()) {
                for (QuoteLineItem qli : qlis) {
                    if (qli.PackageInfo__c != null) {
                        BillingWrappers.QLIPackageInfo qliPackageInfo = (BillingWrappers.QLIPackageInfo)
                                JSON.deserialize(qli.PackageInfo__c, BillingWrappers.QLIPackageInfo.class);
                        if (qliPackageInfo.CategoryCode != null && Product2Helper.SHIPPING_PHONES.contains(qliPackageInfo.CategoryCode)) {
                            if (!qli.Zero_Quantity__c && qli.Quantity > 0) {
                                if (!qli.Custom_Address_QLI__r.isEmpty()) {
                                    Integer caaQuantity = 0;
                                    for (CustomAddressAssignments__c caa : qli.Custom_Address_QLI__r) {
                                        caaQuantity += Integer.valueOf(String.valueOf(caa.Quantity__c));
                                        mapQuantity.put(qli, caaQuantity);
                                    }
                                } else {
                                    if (validator != 'SignUp_QuantityLessThenShippingValidator') {
                                        isFailedValidation = true;
                                    }
                                }
                            }
                        }
                    }
                }

                if (mapQuantity.size() > 0) {
                    for (QuoteLineItem qli : mapQuantity.keySet()) {
                        Integer shippingQuantity = mapQuantity.get(qli) != null ? mapQuantity.get(qli) : 0;
                        if (qli.Quantity > 0) {
                            if (validator == 'SignUp_QuantityShippingValidator' && qli.Quantity > shippingQuantity) {
                                isFailedValidation = true;
                            }
                            if (validator == 'SignUp_QuantityLessThenShippingValidator' && shippingQuantity > 0 && qli.Quantity < shippingQuantity) {
                                isFailedValidation = true;
                            }
                        }
                    }
                }
            }
        }
        return isFailedValidation;
    }

    public abstract class ExpiredPromoGenericValidator extends Validator{
        public List<Promotion__c> promoList;

        public ExpiredPromoGenericValidator(List<Promotion__c> promoList) {
            this.promoList = promoList;
        }

        public override void addErrorMessage(Response resp) {
            addErrorMessageBody(resp);
        }
        protected abstract void addErrorMessageBody(Response resp);

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = false;
            if(!promoList.isEmpty()) {
                for(Promotion__c promo : promoList) {
                    if (promo.End_Date__c < System.today()) {
                        isFailedValidation = true;
                        break;
                    }
                }
            }
            return isFailedValidation;
        }
    }

    public class ExpiredPromoValidator extends ExpiredPromoGenericValidator{
        public ExpiredPromoValidator(List<Promotion__c> promoList) {
            super(promoList);
        }
        public override void addErrorMessageBody(Response resp) {
            resp.addMessage(
                Label.Applied_Promo_Is_Expired_text,
                Label.Opportunity_Error_OnClose_Applied_Promo_Is_Expired_help_text,
                Response.SEVERITY_ERROR
            );
        }
    }

    public class SignUp_ExpiredPromoValidator extends ExpiredPromoGenericValidator{
        public SignUp_ExpiredPromoValidator(List<Promotion__c> promoList) {
            super(promoList);
        }
        public override void addErrorMessageBody(Response resp) {
            resp.addMessage(
                Label.Applied_Promo_Is_Expired_text,
                Label.Opportunity_Error_OnSignUp_Applied_Promo_Is_Expired_help_text,
                Response.SEVERITY_ERROR
            );
        }
    }

    public class SignUp_PackageLabelsValidator extends Validator{
        BillingWrappers.BillingLabels packageLabels;
        Opportunity oppty;

        public SignUp_PackageLabelsValidator(BillingWrappers.BillingLabels packageLabels, Opportunity oppty) {
            this.packageLabels = packageLabels;
            this.oppty = oppty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Wrong_package_label_text,
                Label.Wrong_package_label_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            Boolean isFailedValidation = true;
            List<String> allowedPackageLabels = new List<String>{
                BillingWrappers.EXPIRATION_TYPE_ACTIVE,
                BillingWrappers.EXPIRATION_TYPE_ABOUT_TO_EXPIRE,
                BillingWrappers.EXPIRATION_TYPE_ACTIVE_TESTING
            };

            if (packageLabels != null && OpportunityHelper.isSalesOpportunity(oppty.RecordTypeId) && packageLabels.signup_sfdc != null && allowedPackageLabels.contains(packageLabels.signup_sfdc[0])) {
                isFailedValidation = false;
            } else if (packageLabels != null && OpportunityHelper.isPartnerOpportunity(oppty.RecordTypeId) && packageLabels.signup_sfdcvar != null && allowedPackageLabels.contains(packageLabels.signup_sfdcvar[0])) {
                isFailedValidation = false;
            }
            return isFailedValidation;
        }
    }

    public class SyncWithNGBS_EmptyBillingIdValidator extends Validator {
        private Quote quoteToValidate;

        public SyncWithNGBS_EmptyBillingIdValidator(Quote quoteToValidate) {
            super();
            this.quoteToValidate = quoteToValidate;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.IsNotAvailableToSyncWithNGBS,
                Label.SyncEmptyBillingId,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return QuoteHelper.isBillingNotSynced(quoteToValidate);
        }
    }

    public class SyncWithNGBS_DuplicatedQLIsValidator extends Validator {
        List<QuoteLineItem> qliList;

        public SyncWithNGBS_DuplicatedQLIsValidator(Quote quote) {
            this.qliList = quote?.QuoteLineItems;
        }
        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.IsNotAvailableToSyncWithNGBS,
                Label.DuplicatedQlisOnPrimaryQuote,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            Map<String, QuoteLineItem> qlisMap = new Map<String, QuoteLineItem>();
            if (qliList == null) {
                return false;
            }
            for (QuoteLineItem qli : qliList) {
                if (qlisMap.containsKey(qli.Product2.ExtID__c)) {
                    return true;
                }
                qlisMap.put(qli.Product2.ExtID__c, qli);
            }
            return false;
        }
    }

    public class SignUp_HasIndiaInvoiceRequestValidator extends Validator{
        public List<Approval__c> invoiceApprovals;
        public Opportunity opty;

        public SignUp_HasIndiaInvoiceRequestValidator(Opportunity opty, List<Approval__c> invoiceApprovals) {
            this.opty = opty;
            this.invoiceApprovals = invoiceApprovals;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Sign_Up_is_not_allowed,
                Label.InvoicingRequestIsRequired,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            List<Approval__c> approvalsForOppty = new List<Approval__c>();

            for (Approval__c app : invoiceApprovals) {
                if (app.Opportunity__c == opty.Id) {
                    approvalsForOppty.add(app);
                }
            }
            return approvalsForOppty.isEmpty();
        }
    }

    public class DeviceAvailabilityBackorderValidator extends Validator {
        public Quote primaryQuote;

        public DeviceAvailabilityBackorderValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                    Label.Opportunity_Error_OnClose_DeviceAvailabilityBackorder_text,
                    Label.Opportunity_Error_OnClose_DeviceAvailabilityBackorder_help_text,
                    Response.SEVERITY_WARNING
            );
        }

        public override Boolean isFailedValidation () {
            return isDeviceAvailabilityFailedValidation(primaryQuote, DEVICE_AVAILABILITY_BACKORDER_VALIDATOR);
        }
    }

    public class DeviceAvailabilityOutOfStockValidator extends Validator {
        public Quote primaryQuote;

        public DeviceAvailabilityOutOfStockValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                    Label.Opportunity_Error_OnClose_DeviceAvailabilityOutOfStock_text,
                    Label.Opportunity_Error_OnClose_DeviceAvailabilityOutOfStock_help_text,
                    Response.SEVERITY_WARNING
            );
        }

        public override Boolean isFailedValidation () {
            return isDeviceAvailabilityFailedValidation(primaryQuote, DEVICE_AVAILABILITY_OUTOFSTOCK_VALIDATOR);
        }
    }

    public class DeviceAvailabilityHiddenDiscontinuedValidator extends Validator {
        public Quote primaryQuote;

        public DeviceAvailabilityHiddenDiscontinuedValidator(Quote primaryQuote) {
            this.primaryQuote = primaryQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                    Label.Opportunity_Error_OnClose_DeviceAvailabilityHiddenDiscontinued_text,
                    Label.Opportunity_Error_OnClose_DeviceAvailabilityHiddenDiscontinued_help_text,
                    Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return isDeviceAvailabilityFailedValidation(primaryQuote, DEVICE_AVAILABILITY_HIDDEN_DISCONTINUED_VALIDATOR);
        }
    }

    public class NoProservQuote extends Validator {
        public Quote proservQt;

        public NoProservQuote(Quote proservQt) {
            this.proservQt = proservQt;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.NoProservQuoteText,
                Label.NoProservQuoteHelpText,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return proservQt == null;
        }
    }

    // Not using NoQuoteLineItemsValidator because it's polluted with GSP checks
    // Below validator is used for GSP only anyway, though the check conditions are based on different CS
    // TODO: remove GSP checks in NoQuoteLineItemsValidator & refactor OpportunityHelper to use it instead of this
    public class NoProservOrCCProServQuoteLineItems extends Validator {
        public Quote proservQt;
        public Quote ccProservQt;
        public Opportunity oppty;

        public NoProservOrCCProServQuoteLineItems(Quote proservQt, Quote ccProservQt, Opportunity oppty) {
            this.proservQt = proservQt;
            this.ccProservQt = ccProservQt;
            this.oppty = oppty;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Empty_Cart_text,
                Label.NoProservQuoteHelpText,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return (
                        proservQt != null
                        && proservQt.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED
                        && proservQt.QuoteLineItems.isEmpty()
                        && !OpportunityHelper.isGSPBrand(oppty)
                    )
                    || (
                        ccProservQt != null
                        && ccProservQt.ProServ_Status__c != QuoteHelper.PROSERVSTATUS_CANCELLED
                        && ccProservQt.QuoteLineItems.isEmpty()
                        && !OpportunityHelper.isGSPBrand(oppty)
                    );
        }
    }

    public class SyncWithNGBS_ProfileValidator extends Validator {
        private Quote qt;
        private String profileName;
        private String messageLabel;
        private SWNMessageHelper.SWNMessage message;
        private Boolean skipValidation;

        public SyncWithNGBS_ProfileValidator(Quote qt) {
            super(Validator.SEVERITY_CRITICAL);
            setParams(qt, false);
        }

        public SyncWithNGBS_ProfileValidator(Quote qt, Boolean skipValidation) {
            super(Validator.SEVERITY_CRITICAL);
            setParams(qt, skipValidation);
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(messageLabel, message.header + '. ' + message.message, message.status);
        }

        public override Boolean isFailedValidation() {
            return !this.skipValidation && !FeatureManagement.checkPermission(this.profileName);
        }

        private void setParams(Quote qt, Boolean skipValidation) {
            this.qt = qt;
            this.skipValidation = skipValidation;
            SWNMessageHelper.ErrorMessagesBuilder builder = new SWNMessageHelper.ErrorMessagesBuilder();

            if (QuoteHelper.isEngage(this.qt)) {
                profileName = CustomPermissionHelper.PERMISSION_CAN_SYNC_RINGCX;
                messageLabel = Label.IsNotAvailableToSyncRINGCX;
                message = builder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RINGCX_ERROR);
            } else if (QuoteHelper.isRCCC(this.qt)) {
                profileName = CustomPermissionHelper.PERMISSION_CAN_SYNC_RCCC;
                messageLabel = Label.IsNotAvailableToSyncRCCC;
                message = builder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RCCC_ERROR);
            } else {
                profileName = CustomPermissionHelper.PERMISSION_CAN_SYNC_WITH_NGBS;
                messageLabel = Label.IsNotAvailableToSyncWithNGBS;
                message = builder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_WITH_NGBS_ERROR);
            }
        }
    }

    public class SignUp_ProfileValidator extends Validator {
        private Quote qt;
        @TestVisible
        private String permissionName;
        @TestVisible
        private List<String> shortTier = new List<String>();

        public SignUp_ProfileValidator(Quote qt) {
            super();
            setParams(qt);
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                String.format(Label.IsNotAvailableToSignUp, shortTier),
                String.format(Label.IsNotAvailableToSignUpDetails, shortTier),
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            return this.permissionName != null && !FeatureManagement.checkPermission(this.permissionName);
        }

        private void setParams(Quote qt) {
            this.qt = qt;
            if (QuoteHelper.isEngage(this.qt)) {
                this.shortTier.add(OpportunityHelper.TIER_ENGAGE_SHORT);
                this.permissionName = CustomPermissionHelper.PERMISSION_CAN_SIGN_UP_RINGCX;
            }

            if (QuoteHelper.isRCCC(this.qt)) {
                this.shortTier.add(OpportunityHelper.TIER_RC_CONTACT_SHORT);
                this.permissionName = CustomPermissionHelper.PERMISSION_CAN_SIGN_UP_RCCC;
            }
        }
    }

    public class ProServOrCCProServNotSoldOrCancelled extends Validator {
        public Quote proservQt;
        public Quote ccProservQt;

        public ProServOrCCProServNotSoldOrCancelled(Quote proservQt, Quote ccProservQt) {
            this.proservQt = proservQt;
            this.ccProservQt = ccProservQt;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Proserv_quotes_not_marked_as_sold_text,
                Label.Opportunity_Error_OnClose_Proserv_quotes_not_marked_as_sold_help_text,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation () {
            return (proservQt != null && !QuoteHelper.isSold(proservQt) && !QuoteHelper.isCancelled(proservQt))
                || (ccProservQt != null && !QuoteHelper.isSold(ccProservQt) && !QuoteHelper.isCancelled(ccProservQt));
        }
    }
    public class SignUp_ProserveProfileValidator extends Validator {
        private Quote qt;
        @TestVisible
        private String permissionName;
        @TestVisible
        private List<String> shortTier = new List<String>();
        private Map<String,Boolean> packageToActiveMap = new Map<String,Boolean>();
        private List<String> serviceOnPrimaryQuote = new List<String>();
        private Boolean onSignUpClick = false;
        List<String> proServProfiles = new List<String>{'Professional Services Lightning','Professional Services Lightning - EU Restricted','ProServ API','ProServ -Lightning','ProServ -Lightning - EU Restricted'};       
        
        public SignUp_ProserveProfileValidator(Quote qt,Boolean onSignUpClick) {
            super();
            setParams(qt,onSignUpClick);
        }
    
        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                String.format(Label.IsNotAvailableToSignUp, shortTier),
                String.format(Label.IsNotAvailableToSignUpDetails, shortTier),
                onSignUpClick ? Response.SEVERITY_ERROR : Response.SEVERITY_WARNING
            );
        }
    
        public override Boolean isFailedValidation() {
            Profile currentUserProfile = (Profile) new ProfileSelector()
                .selectProfileById(new List<String>{ UserInfo.getProfileId() })
                .executeQuery()
                .get(0);
            
            String profileName = currentUserProfile.Name;
            String serviceName = this.qt.ServiceName__c;

            if(serviceName!=Constants.CONST_PROSERV && proServProfiles.contains(profileName)){
                this.shortTier.add(serviceName);    
                return true;    
            }
            return false;
        }
    
        private void setParams(Quote qt,Boolean  onSignUpClick) {
            this.qt = qt;
            this.onSignUpClick = onSignUpClick;
        }
    }
    

    public static Boolean isDeviceAvailabilityFailedValidation(Quote primaryQuote, String validator) {

        Boolean deviceValidationFailed = false;
        Set<String> deviceIds = new Set<String>();
        Set<String> countryIds = new Set<String>();
        Set<Id> qliIds = new Set<Id>();
        List<CustomAddressAssignments__c> addressAssignments = new List<CustomAddressAssignments__c>();
        if (primaryQuote != null &&
            primaryQuote.Package_Info__c != null &&
            primaryQuote.Enabled_LBO__c &&
            primaryQuote.Account.Billing_ID__c != null &&
            !primaryQuote.QuoteLineItems.isEmpty()) {

            List<BillingWrappers.QuotePackageInfo> pInfos = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(primaryQuote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
            for (QuoteLineItem qli : primaryQuote.QuoteLineItems) {
                BillingWrappers.QLIPackageInfo qliPackage = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
                if (Product2Helper.SHIPPING_PHONES.contains(qliPackage.categoryCode) &&
                    qli.Quantity >= 1 && !qli.Zero_Quantity__c
                ) {
                    deviceIds.add(qli.Product_Lic_Id__c);
                    qliIds.add(qli.Id);
                }
            }
            if (!qliIds.isEmpty()) {
                addressAssignments = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
                    .selectCAAForShipping(new List<Object>{qliIds})
                    .executeQuery();

                if (!addressAssignments.isEmpty()) {
                    Map<String, String> countryCodes = SettingsService.getCountryCodes();
                    for (CustomAddressAssignments__c caa : addressAssignments) {
                        countryIds.add(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase()));
                    }
                    Response res = FunnelAPI.getDevicesAvailability(pInfos[0].id, pInfos[0].version, new List<String>(deviceIds), new List<String>(countryIds));
                    BillingWrappers.DeviceAvailabilityResponse dar = (BillingWrappers.DeviceAvailabilityResponse) res.data.get('deviceAvailability');
                    for (CustomAddressAssignments__c caa : addressAssignments) {
                        if (dar.devices.get(caa.QuoteLineItem__r.Product_Lic_Id__c).containsKey(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase())) &&
                            dar.devices.get(caa.QuoteLineItem__r.Product_Lic_Id__c).get(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase())) != null) {
                            if (deviceAvailabilityWarningValidatorsMap.containsKey(validator) && dar.devices.get(caa.QuoteLineItem__r.Product_Lic_Id__c).get(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase())).ruleType == deviceAvailabilityWarningValidatorsMap.get(validator)) {
                                deviceValidationFailed = true;
                            }
                            if (deviceAvailabilityErrorsValidatorsMap.containsKey(validator) && deviceAvailabilityErrorsValidatorsMap.get(validator).contains(String.valueOf(dar.devices.get(caa.QuoteLineItem__r.Product_Lic_Id__c).get(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase())).ruleType))) {
                                if (dar.devices.get(caa.QuoteLineItem__r.Product_Lic_Id__c).get(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase())).ruleType == 2) {
                                    String dateStr = dar.devices.get(caa.QuoteLineItem__r.Product_Lic_Id__c).get(countryCodes.get(caa.CustomAddress__r.Country__c.toLowerCase())).endOfSalesDate;
                                    Date endDate = Date.newInstance(Integer.valueOf(dateStr.split('/')[2]), Integer.valueOf(dateStr.split('/')[0]), Integer.valueOf(dateStr.split('/')[1]));
                                    if (System.today() >= endDate) {
                                        deviceValidationFailed = true;
                                    }
                                } else {
                                    deviceValidationFailed = true;
                                }
                            }
                        }
                    }
                }
            }
        }
        return deviceValidationFailed;
    }

    public static final String DEVICE_AVAILABILITY_HIDDEN_DISCONTINUED_VALIDATOR = 'DeviceAvailabilityHiddenDiscountedValidator';
    public static final String DEVICE_AVAILABILITY_OUTOFSTOCK_VALIDATOR = 'DeviceAvailabilityOutOfStockValidator';
    public static final String DEVICE_AVAILABILITY_BACKORDER_VALIDATOR = 'DeviceAvailabilityBackorderValidator';
    public static final Map<String, Integer> deviceAvailabilityWarningValidatorsMap = new Map<String, Integer> {
            DEVICE_AVAILABILITY_OUTOFSTOCK_VALIDATOR => 1,
            DEVICE_AVAILABILITY_BACKORDER_VALIDATOR => 3
    };

    public static final Map<String, String> deviceAvailabilityErrorsValidatorsMap = new Map<String, String> {
            DEVICE_AVAILABILITY_HIDDEN_DISCONTINUED_VALIDATOR => '0,2'
    };

    public class PSFieldsValidation extends Validator {
        private Quote primaryQuote;
        private Opportunity opty;
        Boolean isProServPackageIncluded;

        public PSFieldsValidation(Quote primaryQuote, Opportunity opty, Boolean isProServPackageIncluded) {
            this.primaryQuote = primaryQuote;
            this.opty = opty;
            this.isProServPackageIncluded = isProServPackageIncluded;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_Error_OnClose_Cannot_close_this_oppty_text,
                Label.NoProServRequiredFields,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            Boolean isFailedValidation = false;
            if (primaryQuote != null
                && (this.isProServPackageIncluded || String.isNotBlank(primaryQuote.Package_Info__c))
            ) {
                this.isProServPackageIncluded |= this.isProServPackageIncludedByPackageInfo(primaryQuote);
                isFailedValidation = this.isProServPackageIncluded &&
                    (primaryQuote.TotalProjectHoursQuoted__c == null ||
                    primaryQuote.PSProjectComplexity__c == null ||
                    primaryQuote.ProServ_Forecasted_Close_Date__c == null);
            }
            return isFailedValidation;
        }

        private Boolean isProServPackageIncludedByPackageInfo(Quote primaryQuote) {
            if (String.isBlank(primaryQuote?.Package_Info__c)) {
                return false;
            }
            List<BillingWrappers.QuotePackageInfo> pInfos = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(primaryQuote.Package_Info__c, List<BillingWrappers.QuotePackageInfo>.class);
            for (BillingWrappers.QuotePackageInfo p : pInfos) {
                if (p.productName == QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT) {
                    return true;
                }
            }
            return false;
        }
    }

    public class ProServQliToPhaseValidator extends Validator {
        private Quote primaryQuote;
        private List<String> servicesOnPrimaryQuote;
        private Boolean isSingleQuote;

        public ProServQliToPhaseValidator(List<String> servicesOnPrimaryQuote, Quote primaryQuote, Boolean isSingleQuote) {
            this.servicesOnPrimaryQuote = servicesOnPrimaryQuote;
            this.primaryQuote = primaryQuote;
            this.isSingleQuote = isSingleQuote;
        }

        public override void addErrorMessage(Response resp) {
            resp.addMessage(
                Label.Opportunity_SignUp_Validation_SignUp_failed,
                Label.ProServQliToPhaseAssignmentErrorMessage,
                Response.SEVERITY_ERROR
            );
        }

        public override Boolean isFailedValidation() {
            Boolean isFailedValidation = false;
            if (servicesOnPrimaryQuote.contains(QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT)) {
                Id quoteIdForRequest = isSingleQuote ? primaryQuote.Id : primaryQuote.MasterQuote__c;
                Map<Id, QuoteLineItem> quoteLineItemsMap = new Map<Id, QuoteLineItem>((List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItemsByQuoteIdAndServiceName(new Set<Id>{quoteIdForRequest}, QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT)
                    .executeQuery());

                List<Hardware_Line_Item__c> phasesLineItemsByQlisIds = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector()
                    .selectAllFieldsForCloning(new List<Object>{quoteLineItemsMap.keySet()})
                    .executeQuery();
                Map<Id, Decimal> qliToPhliQuantityMap = new Map<Id, Decimal>();

                for (Hardware_Line_Item__c phli : phasesLineItemsByQlisIds) {
                    if (qliToPhliQuantityMap.get(phli.Quote_Line_Item__c) == null) {
                        qliToPhliQuantityMap.put(phli.Quote_Line_Item__c, phli.Quantity__c);
                    } else {
                        qliToPhliQuantityMap.put(phli.Quote_Line_Item__c, qliToPhliQuantityMap.get(phli.Quote_Line_Item__c) + phli.Quantity__c);
                    }
                }

                for (QuoteLineItem qli: quoteLineItemsMap.values()) {
                    Decimal quantity = qli.DeliveredQuantity__c != null ? qli.NewQuantity__c - qli.DeliveredQuantity__c : qli.NewQuantity__c;
                    Decimal sumPhliQuantites = qliToPhliQuantityMap.get(qli.Id) != null ? qliToPhliQuantityMap.get(qli.Id) : 0;
                    if (quantity != sumPhliQuantites) {
                        return true;
                    }
                }

            }
            return isFailedValidation;
        }
    }
}