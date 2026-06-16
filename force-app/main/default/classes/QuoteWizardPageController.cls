public with sharing class QuoteWizardPageController {
    private final Opportunity cOpportunity;
    public String sid {get;set;}
    public String opportunityId {get;set;}
    public String billingId {get;set;}
    public String originUrl {get;set;}
    public String herokuEndpoint {get; set;}
    public Boolean isBilling {get;set;}
    public Boolean isNeedToMigrateOppty { get; set; }
    public String accountSFDCId {get;set;}
    public Boolean isNewGOAEnabled {get;set;}
    public Boolean isFedRamp {get;set;}
    public Boolean isQuotingAvailable {get;set;}
    public Boolean isQuotingNotSupportedForGSPPartner {get;set;}
    public Boolean isOpportunityInvalid {get;set;}
    public Boolean isEngage {get;set;}
    public String businessIdentity { get; set; }
    public Boolean isInContactLegacyExistingBusiness { get; set; }
    public Boolean hasCCLegacyPermission { get; set; }
    public Boolean isAccountMPHasCCEntitlements { get; set;}
    public Boolean isUpsellOppAfterCCMigration { get; set; }
	public String qwAccess{get;set;}
    public Boolean accStatus{get;set;}
    public Boolean isContactCenterPackagesExistInBilling { get; set; }
    public Boolean isShowLinkNewTab {get; set;}
    public Boolean isContactCenterTabBlocked { get; set; }
    public Boolean isLegacyBusinessIdentity { get; set; }
    public Boolean isProServLegacyFlow { get; set; }
    public Boolean isContactCenterLegacyFlow { get; set; }
    //from old wizard
    public Opportunity currentOpportunity {get; set;}
    public String flatCurrentOpportunity {get; set;}
    public String servicePlan {get;set;}
    public String rcTier {get;set;}
    public String paymentPlan {get;set;}
    public Decimal numberDLs {get;set;}
    public Integer contractDays {get;set;}
    public String flatTiers {get;set;}
    public String user {get;set;}
    public String defaultUpsellStatus {get;set;}
    public String settings { get; set; }
    public Boolean IsCCTabVisible {
        get{
            if (IsCCTabVisible ==  null) {
                IsCCTabVisible = Feature_Toggle__c.getInstance().IsContactCenterTabVisible__c;
            }
            return IsCCTabVisible;
        }
        set;
    }
    // Picklist values
    public String quoteTypeValues { get; set; }
    public String initialTermMonthsValues { get; set; }
    public String specialTermsValues { get; set; }
    public String termMonthsValues { get; set; }
    public String statusValues { get; set; }
    public String proServStatusValues { get; set; }
    public String proServForecastCategoryValues { get; set; }
    public String proServOfferTypeValues { get; set; }
    public String proServProjectComplexityValues { get; set; }
    public String proServSOWTypeValues { get; set; }
    public String TEValues { get; set; }
    public String ASAOwnerValues { get; set; }
    public String PSSegmentValues { get; set; }

    public Approval__c engageLegalApprovalMock {
        get{
            if(null == engageLegalApprovalMock) {
                engageLegalApprovalMock = new Approval__c();
                engageLegalApprovalMock.RecordTypeId = ApprovalHelper.RT_ID_ENGAGE_LEGAL;
            }
            return engageLegalApprovalMock;
        }
        private set;
    }

    public Boolean isOpportunityClosed { get; set; }
    public Boolean isPOCQuoteType { get; set; }
    //from old wizard

    public Boolean isDQGoaEnabled { get; set; }
    public Boolean isPortalFlow { get; set; }
    public Boolean isShowUqt { get; set; }

    public QuoteWizardPageController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>{
                'Account.Billing_ID__c',
                'Account.inContact_account_ID__c',
                'Account.GSP__c',
                'isFedRamp__c',
                'Is_Billing_Opportunity__c',
                'BusinessIdentity__c',
                'RecordTypeId',
                'PartnerProgram__c',
                'Brand_Name__c',
                'Type'});
        }
        this.cOpportunity = (Opportunity)stdController.getRecord();
        this.sid = SettingsService.getSessionId();
        this.opportunityId = this.cOpportunity.Id;
        this.billingId = this.cOpportunity.Account.Billing_ID__c;
        this.originUrl = URL.getOrgDomainUrl().toExternalForm();
        this.herokuEndpoint = EndpointsSettingsHandler.uqtServerEndpoint;
        this.accountSFDCId = this.cOpportunity.AccountId;
        this.isFedRamp = this.cOpportunity.isFedRamp__c;
        this.isInContactLegacyExistingBusiness = this.cOpportunity != null ? AccountHelper.isInContactLegacyExistingBusiness(this.cOpportunity.Account) : false;
        this.isAccountMPHasCCEntitlements = AccountHelper.isAccountHasCCEntitlements(this.accountSFDCId);
        this.isContactCenterPackagesExistInBilling = isContactCenterPackagesExistInBilling(this.cOpportunity);
        this.hasCCLegacyPermission = FeatureManagement.checkPermission(CustomPermissionHelper.USE_CONTACT_CENTER_LEGACY_ON_NEW_BUSINESS);

        this.isPOCQuoteType = false;
        String newQuoteTypeParam = ApexPages.currentPage().getParameters().get('newQuoteType');
        String quoteIdParam = ApexPages.currentPage().getParameters().get('quoteId');
        
        if (QuoteHelper.RT_NAME_POC_QUOTE.equalsIgnoreCase(newQuoteTypeParam)) {
            this.isPOCQuoteType = true;
        } else if (String.isNotBlank(quoteIdParam)) {
            List<Quote> existingQuotes = [SELECT Id, RecordTypeId FROM Quote WHERE Id = :quoteIdParam LIMIT 1];
            if (!existingQuotes.isEmpty() && QuoteHelper.isPOCQuote(existingQuotes[0])) {
                this.isPOCQuoteType = true;
            }
        }
        
        this.isShowUqt = true;

        Opportunity controllerOpportunity = (Opportunity)stdController.getRecord();
        if (controllerOpportunity.Id == null) {
            String portalOpptyId = System.currentPageReference().getHeaders().get('Referer').right(18);
            if (portalOpptyId instanceOf Id) {
                currentOpportunity = QuotingToolQuoteApexController.getOpportunity(portalOpptyId);

                this.isPortalFlow = true;
                this.isShowUqt = Partner_OpportunitiesMain.isShowUnifiedQuotingWizard(currentOpportunity.Id);
            } else {
                this.isShowUqt = false;
                return;
            }
        } else {
            currentOpportunity = QuotingToolQuoteApexController.getOpportunity(controllerOpportunity.Id);
        }

        isQuotingAvailable = QuoteHelper.isQuotingAvailableForBrand(currentOpportunity.Brand_Name__c, currentOpportunity.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS);
        isOpportunityInvalid = OpportunityHelper.isOpportunityInvalid(currentOpportunity);
        isEngage = OpportunityHelper.isEngage(currentOpportunity);
        SettingsService.GSPPartnerSetup gspPartner = new SettingsService.GSPPartnerSetup(this.cOpportunity);
        isQuotingNotSupportedForGSPPartner = gspPartner.isQuotingNotSupported();

        // If CPQ Quote Wizard is available for Sales Rep or WWFS Rep, then Hide 2.0 Wizard
        Id profileId= userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        List<String> PROFILES_AVAILABLE_NEWTAB_LINK = new List<String> {
            ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR,
            ProfileHelper.PROFILE_NAME_CRM_DEVELOPER,
            ProfileHelper.PROFILE_NAME_CRM_QA_ENGINEER,
            ProfileHelper.PROFILE_NAME_CRM_SUPPORT_ENGINEER
        };

        List<Quote> allQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotesForWizard(currentOpportunity.Id)
            .executeQuery();

        for (Quote qt : allQuotes) {
            if (QuoteHelper.isCCQuote(qt)) {
                this.isInContactLegacyExistingBusiness = true;
                break;
            }
        }
        this.isUpsellOppAfterCCMigration = AccountHelper.isAccFlagMigrated(currentOpportunity.Account)
            && this.isInContactLegacyExistingBusiness
            && OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS == currentOpportunity.Type
            && AccountHelper.isAccountHasCCEntitlements(this.accountSFDCId);
        flatCurrentOpportunity = JSON.serialize(currentOpportunity);

        this.isShowLinkNewTab = PROFILES_AVAILABLE_NEWTAB_LINK.contains(profileName);
        this.isContactCenterTabBlocked = AccountHelper.isAccFlagInAnyMigrationStatus(currentOpportunity.Account);

        this.isBilling = currentOpportunity.Is_Billing_Opportunity__c;
        this.isNeedToMigrateOppty = !this.isBilling &&
            String.isNotBlank(currentOpportunity.Account.Billing_ID__c) &&
            currentOpportunity.Account.Billing_System__c == 'NBS';
        this.isOpportunityClosed = OpportunityHelper.isClosed(currentOpportunity.StageName);
        this.isNewGOAEnabled = allQuotes.size() > 0 && allQuotes[0].IsNewGOAEnabled__c;

        this.isLegacyBusinessIdentity = false;
        LeadConversionConfiguration__c[] leadConversionConfigs = LeadConversionConfiguration__c.getall().values();
        for (LeadConversionConfiguration__c config : leadConversionConfigs) {
            if (!config.isNGBS__c && currentOpportunity.Brand_Name__c == config.Name) {
                this.isLegacyBusinessIdentity = true;
                break;
            }
        }
        List<Package__c> packages = new PackageSelector()
            .selectPackagesForNewReferences(new List<Object> {new Set<Id>{currentOpportunity.Account.Id}})
            .executeQuery();
        Map <Id, Package__c> packageToProcessMap = PackageHelper.filterPackagesByService(packages, QuoteHelper.NGBS_OFFICE_PRODUCT);
        Package__c pkg = packageToProcessMap.get(currentOpportunity.Account.Id);

        Decimal lines = currentOpportunity.Account.Number_of_DL_s__c;
        String tier = pkg != null ? pkg.RC_Tier_ID__c : '';
        String plan = currentOpportunity.Account.Payment_Plan__c;

        // get user
        String currentUserId = UserInfo.getUserId();
        User userObj = [SELECT Id, Profile.Id, Profile.Name, UserRoleId FROM User WHERE Id = :currentUserId];
        user = JSON.serialize(userObj);

        //Settings
        String sysAdminProfileId = ProfileHelper.PROFILE_ID_SYSADMIN;
        String relaywareProfileName = ProfileHelper.PROFILE_NAME_RELAYWARE;

        /* Start of addition/changes for EU Phase 3 */
        //ProServ
        List<String> PROSERV_PROFILES = new List<String>();
        List<String> PROSERV_PROFILES_WITHOUT_SUPPORT_DIRECTOR = new List<String>();//Added as part of profile consolidation for professional Services
        List<String> CC_PROSERV_PROFILES = new List<String> {'CC Professional Services' };
        List<String> CC_PROSERV_NOT_SHOW_PROFILES = new List<String>();
        List<String> PROSERV_PROFILES_FOR_SALES_QUOTE_ARCHITECT_FIELD = new List<String>();//Added as part of profile consolidation for professional Services

        List<String> SBOList = new List<String>();
        List<EU_Component_reference__mdt> profileList = [Select DeveloperName, Values__c from EU_Component_reference__mdt
                                                         where  Apex_Classes__c like '%QuoteWizardPageController%'];
        for(EU_Component_reference__mdt profRec:profileList)
        {
            if(profRec.DeveloperName == 'Proserv_withSD') {
                PROSERV_PROFILES.addall(profRec.Values__c.contains(',')?profRec.Values__c.split(','):new List<String>{profRec.Values__c});
            }
            if(profRec.DeveloperName == 'Proserv_wo_SD') {
                PROSERV_PROFILES_WITHOUT_SUPPORT_DIRECTOR.addall(profRec.Values__c.contains(',')?profRec.Values__c.split(','):new List<String>{profRec.Values__c});
            }
            if(profRec.DeveloperName == 'Not_CC_Proserv') {
                CC_PROSERV_NOT_SHOW_PROFILES.addall(profRec.Values__c.contains(',')?profRec.Values__c.split(','):new List<String>{profRec.Values__c});
            }
            if(profRec.DeveloperName == 'Proserv_for_SQ') {
                PROSERV_PROFILES_FOR_SALES_QUOTE_ARCHITECT_FIELD.addall(profRec.Values__c.contains(',')?profRec.Values__c.split(','):new List<String>{profRec.Values__c});
            }
            if(profRec.DeveloperName == 'SupportBackOffice') {
                SBOList.addall(profRec.Values__c.contains(',')?profRec.Values__c.split(','):new List<String>{profRec.Values__c});
            }
        }

        //Added as part of profile consolidation of Support Agent profiles - T1 //Added as part of profile consolidation for professional Services
        if(FeatureManagement.checkPermission('Support_Director_permission')){
            if(SBOList.size() > 0)
            {
            PROSERV_PROFILES.addall(SBOList);
            CC_PROSERV_NOT_SHOW_PROFILES.addall(SBOList);
            }
        }
        /* End of addition for EU Phase 3 */

        String SALES_OPS_PROFILE_NAME = 'Sales Operations';
        Set<String> PS_SEGMENT_PROFILES = new Set<String>{'Proserv-Lightning'};
        String PROSERV_PRODUCT_SUBCATEGORY = 'Professional Services';
        String CC_PROSERV_PRODUCT_SUBCATEGORY = 'CC Professional Services';
        String CONTACT_CENTER = 'Contact Center';
        Set<String> CC_CATEGORIES = new Set<String>{'Contact Center', 'RingCentral Contact Center'};
        //Area Codes
        List<String> areaCodesFamilies = new List <String>{
                'Discounted Phones', 'Rental Phones', 'Refurbished Phones', 'Common Phones'
        };
        List<Integer> areaCodesFeatures = new List <Integer> { 2, 3 };
        //Tier_ID__c from TierTypeSetting__c custom setting
        Map<String,TierTypeSetting__c> tierTypeSetting = TierTypeSetting__c.getall();
        Map <String,String> tierId = new Map <String,String>();
        for (String s : tierTypeSetting.keyset()){
            if (tierTypeSetting.get(s).TierId__c != null){
                tierId.put(tierTypeSetting.get(s).TierId__c, tierTypeSetting.get(s).TierId__c);
            }
        }
        //Feature Toggle
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        //CartItems Grouping
        Map<String,Quoting_Wizard_Cart_Items_Grouping__c> cartItemsGrouping = Quoting_Wizard_Cart_Items_Grouping__c.getall();

        //
        Boolean isHasBillingContact = [
                SELECT COUNT()
                FROM Contact
                WHERE Id IN (
                        SELECT ContactId
                        FROM OpportunityContactRole
                        WHERE OpportunityId = :currentOpportunity.Id AND Role = 'Billing Contact'
                )
        ] > 0;

        // PriceBook
        String GOOGLE_APPS_EDITION = 'Google Apps';
        String RINGCENTRAL_BRAND_NAME = 'RingCentral';
        String RINGCENTRAL_CANADA_BRAND_NAME = 'RingCentral Canada';

        List<QuoteLineItemRestrictionSettings__c> quoteLineItemRestrictionSettings = QuoteLineItemRestrictionSettings__c.getall().values();

        //get UserRoles which are allowed to Submit for Approval
        List<QuoteApprovalRoles__c> quoteApprovalRoles = QuoteApprovalRoles__c.getall().values();
        Set <Id> hierarchyRolesIds = new Set <Id>();
        for (QuoteApprovalRoles__c role : quoteApprovalRoles) {
            hierarchyRolesIds.add( Id.valueOf(role.RoleId__c));
        }
        hierarchyRolesIds.addall(AquivaHelper.getAllSubRoleIds(hierarchyRolesIds));
        Boolean isUserRoleAllowed = hierarchyRolesIds.contains(UserInfo.getUserId());

        // Get Map of Custom Permissions for current user
        CustomPermissionHelper customPermissions = new CustomPermissionHelper();
        Map<String, Boolean> userPermissions = new Map<String, Boolean>();
        for (String permission : customPermissions.getPermissionSet()){
            userPermissions.put(permission, true);
        }

        Quote primaryQuote = QuoteHelper.getPrimaryQuote(allQuotes, currentOpportunity.Is_Billing_Opportunity__c);

        Boolean isChangeOrder = OpportunityHelper.isChangeOrderOpportunity(currentOpportunity,allQuotes) ? true : false;
        Boolean isBTBusiness = OpportunityHelper.BRAND_BT_BUSINESS.equalsIgnoreCase(currentOpportunity.Brand_Name__c);
        Boolean isVodafone = RingCentralHelper.BRAND_VODAFONE.equalsIgnoreCase(currentOpportunity.Brand_Name__c);
        Boolean isTelus = RingCentralHelper.BRAND_TELUS_BUSINESS_CONNECT.equalsIgnoreCase(currentOpportunity.Brand_Name__c);
        Boolean isAtos = RingCentralHelper.BRAND_ATOS.equalsIgnoreCase(currentOpportunity.Brand_Name__c);
        Boolean isRainbow = RingCentralHelper.BRAND_RAINBOW.equalsIgnoreCase(currentOpportunity.Brand_Name__c);
        Boolean isPhoenix = QuoteHelper.isPhoenix(primaryQuote);
        Boolean isRiseBrand = OpportunityHelper.isRiseBrand(currentOpportunity);
        Map <String, Object> customSettings = new Map <String, Object> {
            'ngbsSignUpRestrictions' => NgbsSignUpRestrictions__c.getall().values()
        };
        Boolean isPartnerBrand = OpportunityHelper.getPartnersBrandList().contains(currentOpportunity.Brand_Name__c);

        Map<String,Object> settingsMap = new Map <String, Object> {
                'sysAdminProfileId' 			   => sysAdminProfileId,
                'relaywareProfileName'			   => relaywareProfileName,
                'proServRecordTypeId' 			   => QuoteHelper.RT_ID_PROSERV,
                'areaCodesFamilies' 			   => areaCodesFamilies,
                'areaCodesFeatures' 			   => areaCodesFeatures,
                'tierId'						   => tierId,
                'featureToggle'					   => featureToggle,
                'isNewGOAFeatureEnabled'		   => true,
                'cartItemsGrouping'				   => cartItemsGrouping,
                'isHasBillingContact'			   => isHasBillingContact,
                'PENDING_APPROVAL_STATUSES'		   => QuoteHelper.APPROVAL_STATUSES_PENDING,
                'PRE_APPROVAL_STATUSES'			   => QuoteHelper.APPROVAL_STATUSES_PRE,
                'POST_APPROVAL_STATUSES'		   => QuoteHelper.APPROVAL_STATUSES_POST,
                'SALES_QUOTE_RT_NAME'			   => QuoteHelper.RT_NAME_SALES,
                'SALES_QUOTE_V2_RT_NAME'		   => QuoteHelper.RT_NAME_BILLING,
                'PROSERV_QUOTE_RT_NAME'			   => QuoteHelper.RT_NAME_PROSERV,
                'CC_PROSERV_QUOTE_RT_NAME'		   => QuoteHelper.RT_NAME_CC_PROSERV,
                'CC_QUOTE_RT_NAME'                 => QuoteHelper.RT_NAME_CONTACT_CENTER,
                'POC_QUOTE_RT_NAME'                => QuoteHelper.RT_NAME_POC_QUOTE,
                'QUOTE_RT_INFO_BY_NAME'			   => QuoteHelper.RT_INFO_BY_NAME,
                'PROSERV_PRODUCT_SUBCATEGORY'	   => PROSERV_PRODUCT_SUBCATEGORY,
                'PS_SEGMENT_PROFILES'	           => PS_SEGMENT_PROFILES,
                'CC_PROSERV_PRODUCT_SUBCATEGORY'   => CC_PROSERV_PRODUCT_SUBCATEGORY,
                'PROSERV_PROFILES' 				   => PROSERV_PROFILES,
                'CC_PROSERV_PROFILES' 			   => CC_PROSERV_PROFILES,
                'PROSERV_PROFILES_FOR_SALES_QUOTE_ARCHITECT_FIELD' => PROSERV_PROFILES_FOR_SALES_QUOTE_ARCHITECT_FIELD,
                'PROSERV_PROFILES_WITHOUT_SUPPORT_DIRECTOR' => PROSERV_PROFILES_WITHOUT_SUPPORT_DIRECTOR,
                'CONTACT_CENTER'				   => CONTACT_CENTER,
                'CC_CATEGORIES'                    => CC_CATEGORIES,
                'CC_PROSERV_NOT_SHOW_PROFILES'	   => CC_PROSERV_NOT_SHOW_PROFILES,
                'SALES_OPS_PROFILE_NAME'           => SALES_OPS_PROFILE_NAME,
                'GOOGLE_APPS_EDITION'			   => GOOGLE_APPS_EDITION,
                'RINGCENTRAL_BRAND_NAME'		   => RINGCENTRAL_BRAND_NAME,
                'RINGCENTRAL_CANADA_BRAND_NAME'	   => RINGCENTRAL_CANADA_BRAND_NAME,
                'QUOTE_UPSELL_STATUS'			   => QuoteHelper.STATUS_UPSELL,
                'QUOTE_UPGRADE_STATUS'			   => QuoteHelper.STATUS_UPGRADE,
                'QUOTE_NEW_CUSTOMER_STATUS'		   => QuoteHelper.STATUS_NEW_CUSTOMER,
                'quoteLineItemRestrictionSettings' => quoteLineItemRestrictionSettings,
                'quoteLineItemRestriction'         => getRestrictionsMap(),
                'userPermissions'				   => userPermissions,
                'isUserRoleAllowed'                => isUserRoleAllowed,
                'isChangeOrder'                    => isChangeOrder,
                'isBTBusiness'                     => isBTBusiness,
                'isTelus'                          => isTelus,
                'isAtos'                           => isAtos,
                'isRainbow'                        => isRainbow,
                'isPhoenix'                        => isPhoenix,
                'featureForEES'                    => Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
                'rcMinutesBundleFeatures'          => Product2Helper.RC_MINUTES_BUNDLE_FEATURES,
                'OneTimeFeatureSet'                => Product2Helper.ONE_TIME_FEATURE_SET,
                'QUOTE_APPROVED_APPROVED_STATUSES' => QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED,
                'customSettings'                   => customSettings,
                'isRiseBrand'                      => isRiseBrand,
                'gspPartnerSetup'                  => gspPartner,
                'isPartnerBrand'                   => isPartnerBrand
        };

        // Activate Upsell behavior
        defaultUpsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        if (String.isNotBlank(currentOpportunity.Account.RC_User_ID__c)
                && (lines != null && lines != 0 || servicePlan == 'Fax' || servicePlan == 'Professional')
                && String.isNotBlank(tier)
                && String.isNotBlank(plan))
        {
            defaultUpsellStatus = QuoteHelper.STATUS_UPSELL;
            rcTier = tier;
            numberDLs = lines;
            Date stDate = currentOpportunity.Account.Sales_Agreement_Start_Date__c;
            Date endDate = currentOpportunity.Account.Sales_Agreement_End_Date__c;
            try{
                contractDays = stDate.daysBetween(endDate);
            } catch (Exception e){
                contractDays = 0;
            }

            if (plan == 'Monthly' && contractDays > 363){
                    plan = 'Monthly - Contract';
            }
            paymentPlan = plan;
        }
        settingsMap.put('defaultUpsellStatus',JSON.serialize(defaultUpsellStatus));

        // get tiers
        Map < String, String > tiersParams = new Map < String, String > {
                'recordTypeName' => currentOpportunity.RecordType.Name,
                'CurrencyIsoCode' => currentOpportunity.CurrencyIsoCode,
                'isBTBusiness' => String.valueOf(isBTBusiness),
                'isVodafone' => String.valueOf(isVodafone),
                'isTelus' => String.valueOf(isTelus)
        };
        flatTiers = JSON.serialize(QuotingToolQuoteApexController.getTiers(tiersParams));

        // Get picklist values
        quoteTypeValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','QuoteType__c'));
        initialTermMonthsValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','Initial_Term_months__c'));
        specialTermsValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','Special_Terms__c'));
        termMonthsValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','Term_months__c'));
        statusValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','Status'));
        proServStatusValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','ProServ_Status__c'));
        proServForecastCategoryValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','ProServ_Forecast_Category__c'));
        proServOfferTypeValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','PSOfferType__c'));
        proServProjectComplexityValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','PSProjectComplexity__c'));
        proServSOWTypeValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','SOW_Type__c'));
        TEValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','T_E__c'));
        ASAOwnerValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','ASA_Owner__c', true));
        PSSegmentValues = JSON.serialize(SFDescribeHelper.getOptions('Quote','PS_Segment__c', true));

        settings = JSON.serialize(settingsMap);

        isDQGoaEnabled = DQGoa.isDQGoaEnabled();

        if (QuoteHelper.getProServQuote(allQuotes) == null && QuoteHelper.getCCProServQuote(allQuotes) == null) {
            this.isProServLegacyFlow = false;
        } else {
            this.isProServLegacyFlow = true;
        }
        
        if (QuoteHelper.getCCQuote(allQuotes) == null) {
            this.isContactCenterLegacyFlow = false;
        } else {
            this.isContactCenterLegacyFlow = true;
        }
    }

    public static Map <String, QuoteLineItemRestrictionSettings__c> getRestrictionsMap() {
        Map <String, QuoteLineItemRestrictionSettings__c> result  = new Map<String, QuoteLineItemRestrictionSettings__c>();

        for (QuoteLineItemRestrictionSettings__c item : QuoteLineItemRestrictionSettings__c.getall().values()) {
            String key;

            /* by features */
            if (item.FeatureId__c != null) {
                String f   = String.valueOf(item.FeatureId__c);
                String sf  = String.valueOf(item.SubFeatureId__c);
                key = f+'k';

                if (String.isNotBlank(sf)) {
                    key += sf;
                }
                result.put(key, item);
            }

            /* by product type */
            if (item.Product_Type__c != null) {
                key = item.Product_Type__c;

                result.put(key, item);
            }
        }

        return result;
    }

    public String getComponentToCreate() {
        Boolean showQuoteWizard = !String.isEmpty(ApexPages.currentPage().getParameters().get('quoteId'))
            || !String.isEmpty(ApexPages.currentPage().getParameters().get('newQuoteType'));
        Boolean allowedToUseLWCLanding = Feature_Toggle__c.getInstance().EnableLWCLandingPageOfWizard__c;
        Boolean isGSPWithLWCLanding = SettingsService.onlyProServQuotesAvailable(this.cOpportunity);
        return (this.isLegacyBusinessIdentity && !isGSPWithLWCLanding) || !this.isDQGoaEnabled || showQuoteWizard || !allowedToUseLWCLanding
            ? 'c:QuoteWizardWrapper'
            : 'c:UQTQuoteList';
    }

    public String getParamsToPass() {
        Map<String, Object> result = new Map<String, Object>();

        Map<String, Object> settings = (Map<String, Object>) JSON.deserializeUntyped(this.settings);
        result.put('userPermissions', settings.get('userPermissions'));
        result.put('opportunity', this.currentOpportunity);
        result.put('isPortalFlow', this.isPortalFlow);
        result.put('user', this.user);
        result.put('featureToggle', settings.get('featureToggle'));
    
        return JSON.serialize(result);
    }

    public PageReference openNewTab(){
        return new PageReference('/apex/QuoteWizard?id='+opportunityId);
    }

    @TestVisible
    private static Boolean isContactCenterPackagesExistInBilling(Opportunity opp) {
        String biCurrency = '';
        Integer businessIdentityId;
        if (String.isNotBlank(opp?.BusinessIdentity__c)) {
            BillingWrappers.QuoteBusinessIdentity bi = (BillingWrappers.QuoteBusinessIdentity) JSON.deserialize(
                opp.BusinessIdentity__c.replace('currency', 'biCurrency'),
                BillingWrappers.QuoteBusinessIdentity.class
            );
            businessIdentityId = Integer.valueOf(bi.biId);
            biCurrency = bi.biCurrency;
        }

        BillingWrappers.SearchPackagesParams params = new BillingWrappers.SearchPackagesParams();
        params.businessIdentityIds = new List<Integer> { businessIdentityId };
        params.currencyIds = new List<String> { biCurrency };
        params.isVersioned = true;
        params.labels = getLabels();
        params.productName = OpportunityHelper.TIER_RC_CONTACT_CENTER;

        List<BillingWrappers.NGBSPackage> searchPackages = NGBSAPI.getSearchPackages(params);

        return !searchPackages.isEmpty();
    }

    private static Map<String, List<String>> getLabels() {
        Map<String, List<String>> labels = new Map<String, List<String>>();

        List<String> packageLabels = new List<String> {
            BillingWrappers.EXPIRATION_TYPE_ACTIVE,
            BillingWrappers.EXPIRATION_TYPE_ABOUT_TO_EXPIRE,
            BillingWrappers.EXPIRATION_TYPE_ACTIVE_TESTING,
            BillingWrappers.EXPIRATION_TYPE_EXPIRED
        };

        List<String> labelTypes = new List<String> {
            BillingWrappers.SIGNUP_SFDC,
            BillingWrappers.SIGNUP_SFDCVAR
        };

        for (String labelType: labelTypes) {
            labels.put(labelType, packageLabels);
        }

        return labels;
    }

}