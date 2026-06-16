@RestResource(UrlMapping='/SettingsService/*')
global with sharing class SettingsService {

    global static final Integer COST_CENTER_DEFAULT_NESTING_LEVEL = 4;
    global static final String SECONDARY_DL_SETTING_NAME = 'SecondaryDLApproval';

    global class Params {
        global String name;
    }

    public static String ALL = 'All';

    public static final String ITEM_DELIMITER = ';';
    public static  Map<String, String> countryCodes = getCountryCodes();

    public class NGBSLicenseSetting {
        public Map<String, Set<String>> hiddenSettings = new Map<String, Set<String>>();
        public Map<String, Set<String>> hiddenLargeMeetingsLicenses = new Map<String, Set<String>>();
        public Map<String, Set<String>> licensesUnavailableForLBO = new Map<String, Set<String>>();
        public Map<String, Set<String>> licensesUnavailableForNonLBO = new Map<String, Set<String>>();
        public Map<String, Map<String,Set<String>>> licenseDependenciesSettings = new Map<String, Map<String,Set<String>>>();
        public Map<String, Set<String>> showNameSettings = new Map<String, Set<String>>();
        public Map<String, Set<String>> showEditionSettings = new Map<String, Set<String>>();
        public Map<String, Set<String>> checkChildAssigmentSettings = new Map<String, Set<String>>();
        public Map<String, Set<String>> licensesUnavailableWithoutContract = new Map<String, Set<String>>();
        public Map<String, Map<String, Decimal>> minimumLicenseCategoryQuantity = new Map<String, Map<String, Decimal>>();
        public Map<String, Set<String>> skipLicenseCreation = new Map<String, Set<String>>();
        public Map<String, Map<String, String>> discountSettings = new Map<String, Map<String, String>>();
        public Set<String> notAvailableWithRCVLicenses = new Set<String>();
        public Map<String, Map<String, String>> licensesMinPrice = new Map<String, Map<String, String>>();
        public Set<String> categoryCodesAsExtIdInOrderAPI = new Set<String>();
        public Map<String, Set<String>> licensesUnavailableForPRM = new Map<String, Set<String>>();

        public void addHiddenSettings(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!hiddenSettings.containsKey(packageId)) {
                    hiddenSettings.put(packageId, new Set<String>());
                }
                hiddenSettings.get(packageId).add(elementId);
            }
        }

        public void addHiddenLargeMeetingsLicenses(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!hiddenLargeMeetingsLicenses.containsKey(packageId)) {
                    hiddenLargeMeetingsLicenses.put(packageId, new Set<String>());
                }
                hiddenLargeMeetingsLicenses.get(packageId).add(elementId);
            }
        }

        public void addUnavailableSettingsLBO(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!licensesUnavailableForLBO.containsKey(packageId)) {
                    licensesUnavailableForLBO.put(packageId, new Set<String>());
                }
                licensesUnavailableForLBO.get(packageId).add(elementId);
            }
        }

        public void addUnavailableSettingsNonLBO(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!licensesUnavailableForNonLBO.containsKey(packageId)) {
                    licensesUnavailableForNonLBO.put(packageId, new Set<String>());
                }
                licensesUnavailableForNonLBO.get(packageId).add(elementId);
            }
        }

        public void addShowNameSettings(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!showNameSettings.containsKey(packageId)) {
                    showNameSettings.put(packageId, new Set<String>());
                }
                showNameSettings.get(packageId).add(elementId);
            }
        }

        public void addShowEditionSettings(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!showEditionSettings.containsKey(packageId)) {
                    showEditionSettings.put(packageId, new Set<String>());
                }
                showEditionSettings.get(packageId).add(elementId);
            }
        }

        public void addCheckChildAssignmentSettings(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!checkChildAssigmentSettings.containsKey(packageId)) {
                    checkChildAssigmentSettings.put(packageId, new Set<String>());
                }
                checkChildAssigmentSettings.get(packageId).add(elementId);
            }
        }

        public void addUnavailableWithoutContractSettings(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!licensesUnavailableWithoutContract.containsKey(packageId)) {
                    licensesUnavailableWithoutContract.put(packageId, new Set<String>());
                }
                licensesUnavailableWithoutContract.get(packageId).add(elementId);
            }
        }

        public void addLicenseMinPrice(String packageId, String elementId, String licenseMinPriceVal) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (licensesMinPrice == null) {
                    licenseMinPriceVal = '0';
                }

                if (!licensesMinPrice.containsKey(packageId)) {
                    licensesMinPrice.put(packageId, new Map<String, String>());
                }

                licensesMinPrice.get(packageId).put(elementId, licenseMinPriceVal);
            }
        }

        public void addMinimumLicenseOrCategoryQuantitySettings(String packageId, String elementId, Decimal quantity) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!minimumLicenseCategoryQuantity.containsKey(packageId)) {
                    minimumLicenseCategoryQuantity.put(packageId, new Map<String, Decimal>());
                }
                minimumLicenseCategoryQuantity.get(packageId).put(elementId, quantity);
            }
        }

        public void addSkipLicenseCreationSettings(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!skipLicenseCreation.containsKey(packageId)) {
                    skipLicenseCreation.put(packageId, new Set<String>());
                }
                skipLicenseCreation.get(packageId).add(elementId);
            }
        }

        public void addDiscountSettings(String packageId, String elementId, String allowedDiscountType) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (allowedDiscountType == null) {
                    allowedDiscountType = 'none';
                }
                allowedDiscountType = allowedDiscountType.toLowerCase();

                if (!discountSettings.containsKey(packageId)) {
                    discountSettings.put(packageId, new Map<String, String>());
                }
                discountSettings.get(packageId).put(elementId, allowedDiscountType);
            }
        }

        public void addNotAvailableWithRCVLicense(String elementId) {
            if (String.isNotBlank(elementId)) {
                notAvailableWithRCVLicenses.add(elementId);
            }
        }

        public void addCategoryCodesForExternalIdInOrderAPI(String elementId) {
            if (String.isNotBlank(elementId)) {
                categoryCodesAsExtIdInOrderAPI.add(elementId);
            }
        }

        public void addUnavailableSettingsPRM(String packageId, String elementId) {
            if (String.isNotBlank(packageId) && String.isNotBlank(elementId)) {
                if (!licensesUnavailableForPRM.containsKey(packageId)) {
                    licensesUnavailableForPRM.put(packageId, new Set<String>());
                }
                licensesUnavailableForPRM.get(packageId).add(elementId);
            }
        }

        public void addLicenseDependencies(String packageId, List<String> affectedLicenses, Set<String> dependsOnLicenses) {
            if (String.isBlank(packageId) || affectedLicenses.isEmpty() || dependsOnLicenses.isEmpty()) {
                return;
            }

                if (!licenseDependenciesSettings.containsKey(packageId)) {
                    licenseDependenciesSettings.put(packageId, new Map<String, Set<String>>());
                }

            Map<String, Set<String>> packageDependencies = licenseDependenciesSettings.get(packageId);

                for (String affectedLicense : affectedLicenses) {
                if (!packageDependencies.containsKey(affectedLicense)) {
                    packageDependencies.put(affectedLicense, new Set<String>(dependsOnLicenses));
                    } else {
                    packageDependencies.get(affectedLicense).addAll(dependsOnLicenses);
                }
            }
        }
    }

    public class LicensesSettings {
        public Map<String, Set<String>> hiddenLicenseSettings;
        public Map<String, Set<String>> hiddenLargeMeetingsLicenses;
        public Map<String, Set<String>> licensesUnavailableForLBO;
        public Map<String, Set<String>> licensesUnavailableForNonLBO;
        public Map<String, Map<String, String>> licenseDiscountSettings;
        public Map<String, Map<String, Set<String>>> licenseDependenciesSettings;
        public Map<String, Set<String>> hiddenSettingsLBO = new Map<String, Set<String>>();
        public Map<String, Set<String>> showNameLicensesSettigns;
        public Map<String, Set<String>> showEdition;
        public Map<String, Set<String>> checkChildLicenseSettings;
        public Map<String, Set<String>> licensesDescriptionSettings;
        public Map<String, Set<String>> licensesUnavailableWithoutContract;
        public Map<String, Map<String, Decimal>> minimumLicenseCategoryQuantity;
        public Map<String, Set<String>> skipLicenseCreation;
        public Map<String, Map<String, Boolean>> opportunityPageLicenses;
        public Set<String> notAvailableWithRCVLicenses;
        public Map<String, Map<String, String>> licensesMinPrice;
        public Map<String, Set<String>> licensesUnavailableForPRM;

        public LicensesSettings() {
            hiddenLicenseSettings = new Map<String, Set<String>>();
            hiddenLargeMeetingsLicenses = new Map<String, Set<String>>();
            licenseDiscountSettings = new Map<String, Map<String, String>>();
            showNameLicensesSettigns = new Map<String, Set<String>>();
            showEdition = new Map<String, Set<String>>();
            checkChildLicenseSettings = new Map<String, Set<String>>();
            licensesDescriptionSettings = new Map<String, Set<String>>();
            licensesUnavailableWithoutContract = new Map<String, Set<String>>();
            minimumLicenseCategoryQuantity = new Map<String, Map<String, Decimal>>();
            skipLicenseCreation = new Map<String, Set<String>>();
            opportunityPageLicenses = new Map<String, Map<String, Boolean>>();
            notAvailableWithRCVLicenses = new Set<String>();
            licensesMinPrice = new Map<String, Map<String, String>>();
            licenseDependenciesSettings = new Map<String, Map<String, Set<String>>>();
        }
    }

    public class NGBSPackagesFiltration {
        public List<String> qop;
        public List<String> leadConvert;
        public List<String> quotingTool;

        public NGBSPackagesFiltration() {
            this.qop = new List<String>();
            this.leadConvert = new List<String>();
            this.quotingTool = new List<String>();
        }
    }

    public class NGBSAdditionalPackageFiltration {
        public Decimal priority;
        public String billingCountry;
        public String businessIdentityId;
        public Boolean byProfile;
        public Boolean byPermission;
        public String service;
        public List<String> listOfPackageIDs;
        public String action;
        public String accountType;
        public String quoteType;
        public List<String> signUp_SFDC;
        public List<String> signUp_SFDCVAR;
        public List<String> signUp_SFDCPRM;
        public List<String> upgradeWizardExpiration;
        public String defaultPackage;
        public Boolean byCriteria;

        public NGBSAdditionalPackageFiltration(
            NGBSAdditionalPackageFiltration__c record,
            String userProfileName,
            Account acc,
            Opportunity Opp,
            Map<String, Boolean> userPermissionsMap
        ) {
            this.priority = Decimal.valueOf(record.Priority__c);
            this.billingCountry = record.Billing_Country__c;
            this.businessIdentityId = record.Business_Identity_ID__c;
            this.service = record.Service__c;
            this.listOfPackageIDs = String.isBlank(record.ListOfPackageIDs__c) ?
                new List<String>() :
                record.ListOfPackageIDs__c.split(ITEM_DELIMITER);
            this.action = record.Action__c;
            this.accountType = record.Account_Type__c;
            this.quoteType = record.Quote_Type__c;
            this.signUp_SFDC = String.isBlank(record.SignUp_SFDC__c) ?
                new List<String>() :
                record.SignUp_SFDC__c.split(ITEM_DELIMITER);
            this.signUp_SFDCVAR = String.isBlank(record.SignUp_SFDCVAR__c) ?
                new List<String>() :
                record.SignUp_SFDCVAR__c.split(ITEM_DELIMITER);
            this.signUp_SFDCPRM = String.isBlank(record.SignUp_SFDCPRM__c) ?
                new List<String>() :
                record.SignUp_SFDCPRM__c.split(ITEM_DELIMITER);
            this.upgradeWizardExpiration = String.isBlank(record.UpgradeWizardExpiration__c) ?
                new List<String>() :
                record.UpgradeWizardExpiration__c.split(ITEM_DELIMITER);
            this.defaultPackage = record.Default_Package__c;
            this.byCriteria = String.isBlank(record.Criteria__c) || isCriteriaMatches(record, acc, opp);
            this.byPermission = String.isBlank(record.Permission__c) || userPermissionsMap.keySet().contains(record.Permission__c);
            this.byProfile = String.isBlank(record.Profile__c) || record.Profile__c.split(',').contains(userProfileName);
        }
    }

    public class FunnelLimit {
        public String category;
        public Decimal quantity;

        public FunnelLimit(String category, Decimal quantity) {
            this.category = category;
            this.quantity = quantity;
        }
    }

    public class LeadCountryMapping {
        public String label;
        public String countryName;
        public String currencyCode;

        public LeadCountryMapping(Lead_Country_Mapping__mdt record) {
            this.label = record.Label;
            this.countryName = record.Country_Name__c;
            this.currencyCode = record.Currency__c;
        }
    }

    public class BusinessIdentityOverride {
        public String label;
        public String brand;
        public String billingCountry;
        public String businessIdentityId;
        public List<String> listOfPackageIDs;

        public BusinessIdentityOverride (NGBS_Business_Identity_Override__mdt record) {
            this.label = record.Label;
            this.brand = record.Brand__c;
            this.billingCountry = record.Billing_Country__c;
            this.businessIdentityId = record.Business_Identity_ID__c;
            this.listOfPackageIDs = String.isBlank(record.ListOfPackageIDs__c) ?
                new List<String>() :
                record.ListOfPackageIDs__c.split(ITEM_DELIMITER);
        }
    }

    public class LanguageCodeMapping {
        public Boolean isActive = true;
        public Decimal sortOrder = 0;
        public String label;
        public String languageCode;

        public LanguageCodeMapping (NGBSLanguageCodeMapping__mdt record) {
            this.isActive = record.IsActive__c;
            this.sortOrder = record.SortOrder__c;
            this.label = record.MasterLabel;
            this.languageCode = record.DeveloperName;
        }
    }

    public class PackageMainLicenses {
        public String packageId;
        public String packageGroup;
        public String licenseId;

        public PackageMainLicenses(Package_Main_Licenses__c record) {
            this.packageId = record.Package_ID__c;
            this.packageGroup = record.Package_Group__c;
            this.licenseId = record.Main_License__c;
        }
    }

    public class TargetPriceBusinessIdentityMapping {
        public String brandName;
        public String currencies;
        public Boolean isCCLegacyCanBeSold;

        public TargetPriceBusinessIdentityMapping(TargetPriceBusinessIdentityMapping__c record) {
            this.brandName = record.BrandName__c;
            this.currencies = record.Currency__c;
            this.isCCLegacyCanBeSold = record.IsCCLegacyCanBeSold__c;
        }
    }

    @HttpPost
    global static void setting() {
        String body = RestContext.request.requestBody.toString();

        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            Response resp = new Response();
            Params params = (Params) JSON.deserialize(body, Params.class);

            resp.setData('userId', UserInfo.getUserId());

            if(params.name == 'ngbs') {
                resp.setData('NGBS_Settings__c', NGBS_Settings__c.getInstance());
                resp.setData('gwSettings', GW_Settings__c.getInstance());
                resp.setData('gwEndpoint', RingCentralVariousSettings__c.getInstance().GW_Endpoint__c);
                resp.setData('gwEndpointFedRamp', RingCentralVariousSettings__c.getInstance().GW_Endpoint_FedRamp__c);
            } else if (params.name == 'psr') {
                resp.setData(
                    'Refunds_Settings__c',
                    Refunds_Settings__c.getInstance()
                );
            } else if (params.name == 'ngbsfedramp') {
                resp.setData('NGBS_Setting_FedRamp__c', NGBS_Settings_FedRamp__c.getInstance());
                resp.setData('gwEndpointFedRamp', RingCentralVariousSettings__c.getInstance().GW_Endpoint_FedRamp__c);
            }

            res.responseBody = Blob.valueOf(JSON.serialize(resp));
        } catch(Exception e) {
            Map<String,String> errMsg = new Map<String,String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.responseBody = Blob.valueOf( JSON.serialize(errMsg) );
        }
    }

    @HttpGet
    global static void settings() {
        String result = '';

        boolean newOppPage = RestContext.request.params.get('newOppPage') == 'true';
        String oppId = RestContext.request.params.get('oppId');
               oppId = String.isNotBlank(oppId) ? oppId : null;
        String accId = RestContext.request.params.get('accId');
        String leadId = RestContext.request.params.get('leadId');
               leadId = String.isNotBlank(leadId) ? leadId : null;

        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            Opportunity opp = getOpportunity(oppId);
            List<Approval__c> accountApprovals = getAccountApprovals(opp);

            String userJson = JSON.serialize( getUser() );
            String profilesJson = JSON.serialize( getProfiles() );
            String featureToggleJson = JSON.serialize( Feature_Toggle__c.getInstance() );
            String otherJson = JSON.serialize( getOther() );
            String permissionsJson = JSON.serialize(new CustomPermissionHelper().getPermissionMap());
            String specialTerms = JSON.serialize(QuoteHelper.specialTermsList);
            String freeShippingTerms = JSON.serialize(QuoteHelper.freeShippingTermsList);
            String recordTypes = JSON.serialize( getRecordTypes() );
            String recordTypeNames = JSON.serialize( getRecordTypeNames() );
            String recordTypeIds = JSON.serialize( getRecordTypeIds() );
            String opportunity = !newOppPage ? JSON.serialize( opp ) : null;

            Account account = newOppPage
                ? getAccount(accId)
                : opp != null && opp.Account != null
                    ? getAccount(opp.Account.Id)
                    : null;
            String costCenter = JSON.serialize( getCostCenterSettings());
            String isOpportunityHasActiveEnvelopes = JSON.serialize(DocuSignController.getEnvelopes(oppId, null)
                .data.get('isOpportunityHasActiveEnvelopes'));
            String categoryCodes = JSON.serialize( getCategoryCodes() );
            String leadCountryMappings = JSON.serialize( getLeadCountryMappings() );
            String defaultPackagesForLeadConvert = getDefaultPackageForLeadConvert();
            String taxExemptionApprovals = JSON.serialize(getTaxExemptionApprovals(accountApprovals));
            String vatIdExemptionApprovals = JSON.serialize(getVatIdExemptionApprovals(accountApprovals));
            String lastApprovedKYCApproval = JSON.serialize(getLastApprovedKYCApproval(accountApprovals));
            String pickListValuesInitialTermPOC = JSON.serialize(SFDescribeHelper.getOptions('Quote','Initial_Term_POC__c'));
            String funnelLimits = JSON.serialize(getFunnelLimits());
            String[] elaLicenses = UserCustomSettingHelper.getELALicenses();

            String dqInitialTermsOptions = JSON.serialize(getAccessibleTerms(SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Initial_Term__c')));
            String dqRenewalTermsOptions = JSON.serialize(getAccessibleTerms(SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Renewal_Term__c')));
            String dqSpecialTermsOptions = JSON.serialize(getAccessibleSpecialTerms(SFDescribeHelper.getOptionsMap('DQ_Deal_Qualification__c', 'Special_Terms__c')));
            String dqSpecialTermsCCOptions = JSON.serialize(getAccessibleSpecialTerms(SFDescribeHelper.getOptionsMap('DQ_Deal_Qualification__c', 'CC_Special_Terms__c')));
            String dqFreeShippingTermsOptions = JSON.serialize(SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Free_Shipping_Terms_Options__c'));
            String dqChargeTermOptions = JSON.serialize(SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'Charge_Term__c'));
            String dqElaInitialTermsOptions = JSON.serialize(getAccessibleTerms(SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'ELA_Initial_Terms__c')));
            String dqTrueUpTermsOptions = JSON.serialize(SFDescribeHelper.getOptions('DQ_Deal_Qualification__c', 'True_Up_Terms__c'));

            Boolean isMPUBAccount = AccountHelper.isMPUBAccount(account?.Id);

            DqProductCategories dqProductCategories = getDqProductCategoryOptions();

            List<String> bypassLicenses = QuoteLineItemHelper.getLicensesForPurchaseBypass(opp?.BusinessIdentity__c);

            List<String> nonEmptyBIPackages = getNonEmptyBIPackages();

            LicensesSettings licenseConfig = getLicenseSettings(account?.Billing_ID__c != null, bypassLicenses);

            String countryCodes = JSON.serialize(getCountryCodes());
            String countryCodeToCountryMapping = JSON.serialize(getCountryCodeToCountryMapping());

            EndpointsSettings__c es = SettingsHelper.getEndpointsSettings();
            String docuSignCLMEndpoint = es.DocuSign_CLM_Endpoint__c;
            String docuSignCLMAccountId = es.DocusignCLMAccountId__c;

            String languageCodeMappings = JSON.serialize(getLanguageCodeMap());
            List<String> partnerBrands = OpportunityHelper.getPartnersBrandList();

            List<Approval__c> approvals;
            if (account != null) {
            	approvals = getApprovals(new Set<Id>{account.Id});
            }

            Map<String, String> settingsMap = new Map <String, String> {
                'User'                              => userJson,
                'Profiles'                          => profilesJson,
                'FeatureToggle'                     => featureToggleJson,
                'CustomPermissions'                 => permissionsJson,
                'Other'                             => otherJson,
                'specialTerms'                      => specialTerms,
                'freeShippingTerms'                 => freeShippingTerms,
                'RecordTypes'                       => recordTypes,
                'RecordTypeNames'                   => recordTypeNames,
                'RecordTypeIds'                     => recordTypeIds,
                'Opportunity'                       => opportunity,
                'Account'                           => JSON.serialize(account),
                'isMPUBAccount'                     => JSON.serialize(isMPUBAccount),
                'CostCenter'                        => costCenter,
                'isOpportunityHasActiveEnvelopes'   => isOpportunityHasActiveEnvelopes,
                'CategoryCodes'                     => categoryCodes,
                'billOnBehalfPartnerTypes'          => JSON.serialize(AccountHelper.ACCOUNT_BILL_ON_BEHALF_PARTNERS),
                'wholesalePartnerTypes'             => JSON.serialize(AccountHelper.ACCOUNT_WHOLESALE_PARTNERS),
                'currentPartnerOperation'           => JSON.serialize(getCurrentPartnerOperation(account?.Id)),
                'LBOSettings'                       => JSON.serialize(NGBS_LBO_Settings__c.getInstance()),
                'LicenseDescriptionsCategorySettings'       => JSON.serialize(NGBS_Licenses_Description_Settings__c.getInstance()),
                'BusinessIdentityOverrides'         => JSON.serialize(getBusinessIdentityOverrides()),
                'PackageMainLicenses'               => JSON.serialize(getPackageMainLicensesRecords()),
                'PhoenixSettings'                   => JSON.serialize(NGBS_Phoenix_Settings__c.getInstance()),
                'BrandConfiguration'                => JSON.serialize(LeadConversionConfiguration__c.getAll().values()),
                'hiddenLicenses'                    => JSON.serialize(licenseConfig.hiddenLicenseSettings),
                'hiddenLargeMeetingsLicenses'       => JSON.serialize(licenseConfig.hiddenLargeMeetingsLicenses),
                'licensesUnavailableForLBO'         => JSON.serialize(licenseConfig.licensesUnavailableForLBO),
                'licensesUnavailableForNonLBO'      => JSON.serialize(licenseConfig.licensesUnavailableForNonLBO),
                'licensesUnavailableForPRM'         => JSON.serialize(licenseConfig.licensesUnavailableForPRM),
                'licenseDiscountSettings'           => JSON.serialize(licenseConfig.licenseDiscountSettings),
                'licenseDependenciesSettings'       => JSON.serialize(licenseConfig.licenseDependenciesSettings),
                'showNameLicensesSettigns'          => JSON.serialize(licenseConfig.showNameLicensesSettigns),
                'showEdition'                       => JSON.serialize(licenseConfig.showEdition),
                'checkChildLicenseSettings'         => JSON.serialize(licenseConfig.checkChildLicenseSettings),
                'licenseDescriptionSettings'        => JSON.serialize(licenseConfig.licensesDescriptionSettings),
                'licensesUnavailableWithoutContract'=> JSON.serialize(licenseConfig.licensesUnavailableWithoutContract),
                'minimumLicenseCategoryQuantity'    => JSON.serialize(licenseConfig.minimumLicenseCategoryQuantity),
                'skipLicenseCreation'               => JSON.serialize(licenseConfig.skipLicenseCreation),
                'opportunityPageLicenses'           => JSON.serialize(licenseConfig.opportunityPageLicenses),
                'notAvailableWithRCVLicenses'       => JSON.serialize(licenseConfig.notAvailableWithRCVLicenses),
                'licensesMinPrice'                  => JSON.serialize(licenseConfig.licensesMinPrice),
                'funnelLimits'                      => funnelLimits,
                'bypassLicenseRestrictions'         => JSON.serialize(bypassLicenses),
                'nonEmptyBIPackages'                => JSON.serialize(nonEmptyBIPackages),
                'packagesFiltration'                => JSON.serialize(getPackagesFiltrationSettings()),
                'additionalPackageFiltration'       => JSON.serialize(getAdditionalPackageFiltrationSettings(account, opp)),
                'DefaultPackages'                   => defaultPackagesForLeadConvert,
                'PickListValuesInitialTermPOC'      => pickListValuesInitialTermPOC,
                'taxExemptionApprovals'             => taxExemptionApprovals,
                'vatIdExemptionApprovals'           => vatIdExemptionApprovals,
                'kycApproval'                       => lastApprovedKYCApproval,
                'LeadCountryMappings'               => leadCountryMappings,
                'hiddenCategories'                  => JSON.serialize(getHiddenLicenseCategories(opp)),
                'discountNotifications'             => JSON.serialize(NGBS_License_Discount_Notifications__c.getAll().values()),
                'extendedSpecialTerms'              => JSON.serialize(NGBSExtendedSpecialTerms__c.getAll().values()),
                'CountryCodes'                      => countryCodes,
                'CountryCodeToCountryMapping'       => countryCodeToCountryMapping,
                'BusinessIdentityMapping'           => getBusinessIdentityMappingJSON(leadId),
                'PackageLabelsMapping'              => getPackageLabelsMappingJSON(),
                'RingCentralVariousSettings'        => JSON.serialize(RingCentralVariousSettings__c.getInstance()),
                'baseUrl'                           => JSON.serialize(URL.getOrgDomainUrl().toExternalForm()),
                'DocuSignCLMEndpoint'               => JSON.serialize(docuSignCLMEndpoint),
                'DocuSignCLMAccountId'              => JSON.serialize(docuSignCLMAccountId),
                'elaLicenses'                       => JSON.serialize(elaLicenses),
                'DirectDebitApprovalThreshold'      => JSON.serialize(DirectDebitApprovalThreshold__c.getAll().values()),
                'Approvals'                         => JSON.serialize(approvals),
                'createMSAButtonName'               => JSON.serialize(getCreateMSAButtonName(account, opp)),
                'BrandToAllowedCountryMapping'      => SettingsHelper.getBrandToAllowedCountryMapping(),
                'languageCodeMappings'              => languageCodeMappings,
                'targetPricingKeys'                 => JSON.serialize(getTargetPricingKeys()),
                'targetPricingPotentialRaters'      => JSON.serialize(getTargetPricingPotentialRaters()),
                'targetPricingGlobalRaters'         => JSON.serialize(getTargetPricingGlobalRaters()),
                'discountCeilingsCBox'              => JSON.serialize(getDiscountCeilingCBox()),
                'discountCeilingsCategory'          => JSON.serialize(getDiscountCeilingCategory()),
                'discountCeilingsLicense'           => JSON.serialize(getDiscountCeilingLicense()),
                'packageBasePriceMapping'           => JSON.serialize(getPackageBasePriceMapping()),
                'dqInitialTermsOptions'             => dqInitialTermsOptions,
                'dqRenewalTermsOptions'             => dqRenewalTermsOptions,
                'dqSpecialTermsOptions'             => dqSpecialTermsOptions,
                'dqSpecialTermsCCOptions'           => dqSpecialTermsCCOptions,
                'dqFreeShippingTermsOptions'        => dqFreeShippingTermsOptions,
                'dqChargeTermOptions'               => dqChargeTermOptions,
                'dqElaInitialTermsOptions'          => dqElaInitialTermsOptions,
                'dqTrueUpTermsOptions'              => dqTrueUpTermsOptions,
                'dqProductCategoriesSalesOptions'   => dqProductCategories.salesCategoriesJson,
                'dqProductCategoriesCCOptions'      => dqProductCategories.ccCategoriesJson,
                'dqProductCategoriesAllOptions'     => dqProductCategories.allCategoriesJson,
                'targetPriceBusinessIdentityMapping'=> JSON.serialize(getTargetPriceBusinessIdentityMappingRecords()),
                'IcbSettings'                       => JSON.serialize(ICB_Settings__c.getInstance()),
                'purchaseRestrictionPeriod'         => JSON.serialize(PurchaseRestrictionPeriodSettings.getSettings()),
                'gspPartnerSetupRecord'             => JSON.serialize(new GSPPartnerSetup(opp)),
                'oppTeamMembersWithSERole'       => JSON.serialize(oppTeamMembersWithSERole(oppId)),
                'oppTeamMembersWithCESERole'       => JSON.serialize(oppTeamMembersWithCESERole(oppId)),
                'partnerBrands'                     => JSON.serialize(partnerBrands)
            };

            result = JSON.serialize(settingsMap);
            res.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            Map<String,String> errMsg = new Map<String,String>();
            errMsg.put('error', 'Error occurred while getting settings (' + e.getMessage() + ')');
            res.responseBody = Blob.valueOf( JSON.serialize(errMsg) );
        }

    }

    public static PartnerOperationsHelper.PartnerOperation getCurrentPartnerOperation(Id accountId) {
        PartnerOperationsHelper.PartnerOperation result;
        if (String.isBlank(accountId)) {
            return result;
        }

        try {
            List<PartnerOperationsLog__c> partnerOperationsLogs = (List<PartnerOperationsLog__c>)
                new QueryFactory(PartnerOperationsLog__c.SObjectType)
                    .selectFields(new List<String>{
                        'Id',
                        'Account__c',
                        'Opportunity__c',
                        'Approval__c',
                        'isCompleted__c',
                        'PartnerInfo__c'
                    })
                    .setQueryBindings(new List<Object>{ accountId })
                    .setCondition('isCompleted__c = false AND isRejected__c = false AND Account__c =:bind0')
                    .executeQuery();
            if (!partnerOperationsLogs.isEmpty()) {
                result = new PartnerOperationsHelper.PartnerOperation(partnerOperationsLogs.get(0));
            }
        } catch (Exception ex) {
            return null;
        }

        return result;
    }

    @testVisible
    private static List<Approval__c> getApprovals(Set<Id> accIdSet) {
        return new ApprovalSelector()
            .selectApprovalsForAccountOrderedByStatusLastModifiedDate(new List<Object>{accIdSet})
            .executeQuery();
    }


    @testVisible
    private static List<Approval__c> getTaxExemptionApprovals (List<Approval__c> accountApprovals) {
        List<Approval__c> taxExemptionApprovals = new List<Approval__c>();

        if (!accountApprovals.isEmpty()) {
            for (Approval__c appr: accountApprovals) {
                if (appr.RecordTypeId == ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL) {
                    taxExemptionApprovals.add(appr);
                }
            }
        }

        return taxExemptionApprovals;
    }

    @testVisible
    private static List<Approval__c> getVatIdExemptionApprovals (List<Approval__c> accountApprovals) {
        List<Approval__c> vatIdExemptionApprovals = new List<Approval__c>();

        if (!accountApprovals.isEmpty()) {
            for (Approval__c appr: accountApprovals) {
                if (appr.RecordTypeId == ApprovalHelper.RT_ID_VAT_ID_Exemption) {
                    vatIdExemptionApprovals.add(appr);
                }
            }
        }

        return vatIdExemptionApprovals;
    }

    private static List<FunnelLimit> getFunnelLimits() {
        List<FunnelLimit> limits = new List<FunnelLimit>();
        for (Funnel_Limits__c funnelLimit : Funnel_Limits__c.getAll().values()) {
            for (String category : funnelLimit.Categories__c.split(' ')) {
                limits.add(new FunnelLimit(category, funnelLimit.Quantity__c));
            }
        }
        return limits;
    }

    private static List<BusinessIdentityOverride> getBusinessIdentityOverrides() {
        List<NGBS_Business_Identity_Override__mdt> records = (List<NGBS_Business_Identity_Override__mdt>) new NGBSBusinessIdentityOverrideSelector()
            .selectActiveBusinessIdentityOverrides()
            .executeQuery();

        List<BusinessIdentityOverride> overrides = new List<BusinessIdentityOverride>();

        for(NGBS_Business_Identity_Override__mdt record: records) {
            overrides.add(new BusinessIdentityOverride(record));
        }

        return overrides;
    }

    private static List<PackageMainLicenses> getPackageMainLicensesRecords() {
        List<Package_Main_Licenses__c> records = (List<Package_Main_Licenses__c>) new PackageMainLicensesSelector()
            .selectPackageMainLicensesRecords()
            .executeQuery();

        List<PackageMainLicenses> items = new List<PackageMainLicenses>();

        for(Package_Main_Licenses__c record: records) {
            items.add(new PackageMainLicenses(record));
        }

        return items;
    }

    @testVisible
    private static List<TargetPriceBusinessIdentityMapping> getTargetPriceBusinessIdentityMappingRecords() {
        List<TargetPriceBusinessIdentityMapping__c> records = TargetPriceBusinessIdentityMapping__c.getAll().values();
        List<TargetPriceBusinessIdentityMapping> items = new List<TargetPriceBusinessIdentityMapping>();

        for (TargetPriceBusinessIdentityMapping__c record : records) {
            items.add(new TargetPriceBusinessIdentityMapping(record));
        }

        return items;
    }

    private static List<LeadCountryMapping> getLeadCountryMappings() {
        List<Lead_Country_Mapping__mdt> records = (List<Lead_Country_Mapping__mdt>) new LeadCountryMappingSelector()
            .selectActiveCountryMappings()
            .executeQuery();
        List<LeadCountryMapping> mappings = new List<LeadCountryMapping>();

        for(Lead_Country_Mapping__mdt record: records) {
            mappings.add(new LeadCountryMapping(record));
        }

        return mappings;
    }

    private static Approval__c getSecondaryDLApproval(Opportunity opp) {
        return new NoSharing().getSecondaryDLApproval(opp);
    }

    public static List<String> getHiddenLicenseCategories(Opportunity opp) {
        Approval__c approval = getSecondaryDLApproval(opp);
        if (approval == null || approval.Status__c != ApprovalHelper.STATUS_APPROVED) {
            NGBSCategoriesSettings__c categoriesSettings = NGBSCategoriesSettings__c.getValues(SECONDARY_DL_SETTING_NAME);
            if (categoriesSettings != null) {
                return categoriesSettings.HiddenCategories__c.split(',');
            }
        }
        return new List<String>();
    }

    private static User getUser() {
        return (User) new UserSelector().selectCurrentUserForSettingsService().executeQuery().get(0);
    }

    private static Opportunity getOpportunity(String oppId) {
        Opportunity opp;

        try {
            opp = (Opportunity) new OpportunitySelector()
                .selectOpportunityForSettingService(oppId)
                .executeQuery()
                .get(0);
        } catch(Exception e) {
            System.debug('trace' + e.getStackTraceString());
            // AquivaHelper.throwAquivaException(e);
        }
        System.debug('opp: ' + opp);
        return opp;
    }

    private static Account getAccount(String accId) {
        Account acc;

        try{
            acc = (Account) new AccountSelector()
                .selectAccountForNewWizard(accId)
                .executeQuery()
                .get(0);
        } catch(Exception e) {
            System.debug('trace' + e.getStackTraceString());
        }

        return acc;
    }

    private static Map<String, Object> getProfiles() {
        Map<string, object> profiles = new Map<string, object>();
        profiles.put('relaywareProfileName', ProfileHelper.PROFILE_NAME_RELAYWARE);
        return profiles;
    }

    private static Map<String, Object> getOther() {
        Map<String, Object> other = new Map<String, Object>();
        other.put('PENDING_APPROVAL_STATUSES', QuoteHelper.APPROVAL_STATUSES_PENDING);
        other.put('PRE_APPROVAL_STATUSES', QuoteHelper.APPROVAL_STATUSES_PRE);
        other.put('POST_APPROVAL_STATUSES', QuoteHelper.APPROVAL_STATUSES_POST);
        other.put('isUserCanApprove', isUserCanApprove());
        other.put('origin', URL.getOrgDomainUrl().toExternalForm());
        other.put('timezoneOffset', UserHelper.getUserTZOffset());
        return other;
    }

    private static Map<String, String> getRecordTypes() {
        Map<String, String> result = new Map<String, String>();

        // Quote
        result.put('Billing', QuoteHelper.RT_ID_BILLING);
        result.put('ProServ', QuoteHelper.RT_ID_PROSERV);
        result.put('ContactCenter', QuoteHelper.RT_ID_CC);
        result.put('CCProServ', QuoteHelper.RT_ID_CC_PROSERV);
        result.put('POCQuote', QuoteHelper.RT_ID_POC);

        // Approval
        result.put('InvoiceApproval', ApprovalHelper.RT_ID_INVOICING_REQUEST);
        result.put('DirectDebitApproval', ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST);

        // DQ_Deal_Qualification_Discounts__c
        result.put('DqDiscountSales', DQServiceHelper.DQ_SALES_RECORD_TYPE_ID);
        result.put('DqDiscountContactCenter', DQServiceHelper.DQ_CC_RECORD_TYPE_ID);

        // Case
        result.put('DealAndOrderSupport', CaseHelper.RT_ID_DEAL_AND_ORDER_SUPPORT);
        return result;
    }

    private static Map<String, String> getRecordTypeIds() {
        Map<String, String> result = new Map<String, String>();
        result.put('PartnerLead', LeadHelper.RT_ID_PARTNER_LEADS);
        result.put('PartnerAccount', AccountHelper.RT_ID_PARTNER_ACCOUNT);
        result.put('PartnerOpportunity', OpportunityHelper.RT_ID_VAR_OPPORTUNITY);
        return result;
    }

    private static Map<String, String> getRecordTypeNames() {
        Map<String, String> result = new Map<String, String>();

        // Quote
        result.put('Billing', 'Sales Quote');
        result.put('ProServ', QuoteHelper.RT_NAME_PROSERV);
        result.put('ContactCenter', QuoteHelper.RT_NAME_CONTACT_CENTER);
        result.put('CCProServ', QuoteHelper.RT_NAME_CC_PROSERV);
        result.put('POCQuote', QuoteHelper.RT_NAME_POC_QUOTE);

        // Approval
        result.put('InvoiceApproval', ApprovalHelper.INVOICING_REQUEST_APPROVAL_RT_NAME);
        result.put('DirectDebitApproval', ApprovalHelper.RT_NAME_DIRECT_DEBIT_REQUEST);
        return result;
    }

    public static Boolean isUserCanApprove() {
        Boolean result;

        List<QuoteApprovalRoles__c> quoteApprovalRoles = QuoteApprovalRoles__c.getAll().values();
        Set <Id> hierarchyRolesIds = new Set <Id>();
        for (QuoteApprovalRoles__c role : quoteApprovalRoles) {
            hierarchyRolesIds.add(Id.valueOf(role.RoleId__c));
        }
        hierarchyRolesIds.addAll(AquivaHelper.getAllSubRoleIds(hierarchyRolesIds));
        result = hierarchyRolesIds.contains(UserInfo.getUserRoleId());

        return result;
    }

    private static Map<String, String> getCostCenterSettings() {
        Map<String, String> result = new Map<String, String>();

        Integer nestingLevel;
        try {
            nestingLevel = Integer.valueOf(NGBS_Settings__c.getInstance().CostCenterNestingLevel__c);
        } catch(Exception e) {
            System.debug('Cannot get Cost Center Nesting Level ' + e.getMessage());
        }
        if (nestingLevel == null) {
            nestingLevel = COST_CENTER_DEFAULT_NESTING_LEVEL;
        }

        result.put('NestingLevel', String.valueOf(nestingLevel));
        return result;
    }

    @TestVisible
    private static Map<String, Set<String>> getCategoryCodes() {

        Map<String, Category_Codes__c> codesMap = Category_Codes__c.getAll();

        Map<String, Set<String>> resultMap = new Map<String, Set<String>>();

        for(String codeName : codesMap.keySet()) {

            String codesStr = codesMap.get(codeName).Codes__c;

            if(String.isBlank(codesStr)) {
                continue;
            }

            codesStr = codesStr.containsWhitespace() ? codesStr.deleteWhitespace() : codesStr;

            resultMap.put(codeName, new Set<String>(codesStr.split(',')));
        }

        return resultMap;
    }

    @TestVisible
    private static String getCreateMSAButtonName(Account acc, Opportunity opp) {
        if (acc == null || opp == null) {
            return null;
        }

        return getCreateMSAButtonName(opp.Brand_Name__c, acc.BillingCountry);
    }

    @TestVisible
    private static String getCreateMSAButtonName(String brand, String billingCountry) {
        Map<String, CreateMSAButtonURLLogic__c> createMSAButtonNames = CreateMSAButtonURLLogic__c.getAll();
        String buttonName = null;

        if (brand == null || billingCountry == null) {
            return null;
        }

        for (CreateMSAButtonURLLogic__c item: createMSAButtonNames.values()) {
            if (String.isBlank(item.Brand__c)) {
                continue;
            }

            List<String> itemBrands = item.Brand__c.split(',');

            for (String itemBrand: itemBrands) {
                if (brand.equalsIgnoreCase(itemBrand)) {
                    if (String.isNotBlank(item.BillingCountry__c)) {
                        List<String> countries = item.BillingCountry__c.split(',');

                        for (String country: countries) {
                            if (billingCountry.equalsIgnoreCase(country)) {
                                buttonName = item.ButtonName__c;
                                break;
                            }
                        }
                    } else {
                        buttonName = item.ButtonName__c;
                    }
                }
            }

            if (buttonName != null) {
                // If we found the button name, stop the loop
                break;
            }
        }

        return buttonName;
    }

    public static NGBSPackagesFiltration getPackagesFiltrationSettings() {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        NGBSPackagesFiltration packageSettings = new NGBSPackagesFiltration();
        for (NGBSPackagesFiltration__c pkgConfig : NGBSPackagesFiltration__c.getAll().values()) {

            List<String> packageIdsList = pkgConfig.ListOfPackageIDs__c.split(ITEM_DELIMITER);

            Boolean isSingaporeConfig = pkgConfig.Name.equalsIgnoreCase('RingCentral Singapore');

            if (isSingaporeConfig && !featureToggle.SelectPackagesByBusinessIdentity__c) {
                packageSettings.qop.addAll(packageIdsList);
                packageSettings.leadConvert.addAll(packageIdsList);
                packageSettings.quotingTool.addAll(packageIdsList);

                continue;
            }

            if (!pkgConfig.IsActive__c) {
                continue;
            }
            if (pkgConfig.FilterOutForQOP__c) {
                packageSettings.qop.addAll(packageIdsList);
            }
            if (pkgConfig.FilterOutForLC__c) {
                packageSettings.leadConvert.addAll(packageIdsList);
            }
            if (pkgConfig.FilterOutForQW__c) {
                packageSettings.quotingTool.addAll(packageIdsList);
            }
        }
        return packageSettings;
    }

    public static List<NGBSAdditionalPackageFiltration> getAdditionalPackageFiltrationSettings(Account acc, Opportunity opp) {
        List<NGBSAdditionalPackageFiltration> additionalPackageSettings = new List<NGBSAdditionalPackageFiltration>();
        Profile userProfile = (Profile) new ProfileSelector()
            .selectProfileById(new List<Object>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);

        String userProfileName = userProfile.Name;

        Map<String, Boolean> userPermissionsMap = new CustomPermissionHelper().getPermissionMap();

        for (NGBSAdditionalPackageFiltration__c pkgConfig : NGBSAdditionalPackageFiltration__c.getAll().values()) {
            NGBSAdditionalPackageFiltration pkgFilter = new NGBSAdditionalPackageFiltration(pkgConfig, userProfileName, acc, opp, userPermissionsMap);
            additionalPackageSettings.add(pkgFilter);
        }

        return additionalPackageSettings;
    }

    @TestVisible
    private static Boolean isCriteriaMatches(NGBSAdditionalPackageFiltration__c pkgFilter, Account acc, Opportunity opp) {
        String pkgCriteria = pkgFilter.Criteria__c;
        try {
            if (pkgCriteria != null) {
                String[] criteriaAND = pkgCriteria.split(' AND ');
                String[] criteriaOR = pkgCriteria.split(' OR ');
                List<Boolean> checker = new List<Boolean>();
                if (criteriaAND.size() > 1) {

                    for (String str : criteriaAND) {
                        checker.add(parseCriteria(str, acc, opp));
                    }

                    return !checker.contains(false);
                } else if (criteriaOR.size() > 1) {

                    for (String str : criteriaOR) {
                        checker.add(parseCriteria(str, acc, opp));
                    }

                    return checker.contains(true);
                } else {
                    return parseCriteria(pkgCriteria, acc, opp);
                }
            } else {
                return false;
            }

        } catch (Exception ex) {
            System.debug('Check if criteria =>( ' + pkgCriteria + ' ) are valid');
            System.debug('Exception == ' + ex.getMessage() + ex.getStackTraceString());
            System.debug('NGBSAdditionalPackageFiltration problem record => ' + JSON.serializePretty(pkgFilter));
            return false;
        }
    }

    private static Boolean parseCriteria(String pkgCriteria, Account acc, Opportunity opp) {

        String CRITERIA_PATTERN = '\\s*(\\w+)(?:\\.([\\w.]+))\\s*(\\!?\\=+)\\s*(.+)';

        Matcher filterMatcher = Pattern.compile(CRITERIA_PATTERN).matcher(pkgCriteria);

        String objectName;
        String objectField;
        String operator;
        String value;

        if (filterMatcher.matches()) {
            objectName = filterMatcher.group(1);
            objectField = filterMatcher.group(2);
            operator = filterMatcher.group(3);
            value = filterMatcher.group(4);

            Boolean isAccCriteriaMatch = objectName.equalsIgnoreCase('account') &&
                ((operator == '=' && String.valueOf(acc?.get(objectField)) == value) || (operator == '!=' && String.valueOf(acc?.get(objectField)) != value));

            Boolean isOpptyCriteriaMatch = objectName.equalsIgnoreCase('opportunity') &&
                ((operator == '=' && String.valueOf(opp?.get(objectField)) == value) || (operator == '!=' && String.valueOf(opp?.get(objectField)) != value));

            if (isAccCriteriaMatch || isOpptyCriteriaMatch) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    public static LicensesSettings getLicenseSettings(Boolean isExistingBusiness, List<String> bypassLicenses) {
        LicensesSettings licenseSettings = new LicensesSettings();
        NGBSLicenseSetting ngbsLicenseSetting = getNGBSLicenseSetting(isExistingBusiness, bypassLicenses);
        /* discount settings */
        licenseSettings.licenseDiscountSettings = ngbsLicenseSetting.discountSettings;

        /* hidden */
        licenseSettings.hiddenLicenseSettings = ngbsLicenseSetting.hiddenSettings;
        licenseSettings.hiddenLargeMeetingsLicenses = ngbsLicenseSetting.hiddenLargeMeetingsLicenses;

        /* Unavailable for LBO / non-LBO */
        licenseSettings.licensesUnavailableForLBO = ngbsLicenseSetting.licensesUnavailableForLBO;
        licenseSettings.licensesUnavailableForNonLBO = ngbsLicenseSetting.licensesUnavailableForNonLBO;

        /* Unavailable for PRM */
        licenseSettings.licensesUnavailableForPRM = ngbsLicenseSetting.licensesUnavailableForPRM;

        /* show name */
        licenseSettings.showNameLicensesSettigns = ngbsLicenseSetting.showNameSettings;

        /* show edition */
        licenseSettings.showEdition = ngbsLicenseSetting.showEditionSettings;

        /* check child license quantities */
        licenseSettings.checkChildLicenseSettings = ngbsLicenseSetting.checkChildAssigmentSettings;

        /* unavailable without contract */
        licenseSettings.licensesUnavailableWithoutContract = ngbsLicenseSetting.licensesUnavailableWithoutContract;

        /* minimum quantity for licenses/category */
        licenseSettings.minimumLicenseCategoryQuantity = ngbsLicenseSetting.minimumLicenseCategoryQuantity;

        /* don't create those licenses */
        licenseSettings.skipLicenseCreation = ngbsLicenseSetting.skipLicenseCreation;

        /* get licenses description */
        licenseSettings.licensesDescriptionSettings = getNGBSLicensesDescription();

        /* get opp page licenses */
        licenseSettings.opportunityPageLicenses = getNGBSOpptyPageLicenses();

        licenseSettings.notAvailableWithRCVLicenses = ngbsLicenseSetting.notAvailableWithRCVLicenses;

        /* get licenses minimum price */
        licenseSettings.licensesMinPrice = ngbsLicenseSetting.licensesMinPrice;

        /* get licenses dependencies */
        licenseSettings.licenseDependenciesSettings = ngbsLicenseSetting.licenseDependenciesSettings;

        return licenseSettings;
    }

    public static NGBSLicenseSetting getNGBSLicenseSetting(Boolean isExistingBusiness, List<String> bypassLicenses) {
        NGBSLicenseSetting result = new NGBSLicenseSetting();

        String currentUserId = UserInfo.getUserId();
        String currentProfileId = UserInfo.getProfileId();
        for (NGBSHiddenLicenses__c licenseConfig : NGBSHiddenLicenses__c.getAll().values()) {
            Boolean isBypassConfig =
                isExistingBusiness && licenseConfig.NewBusinessOnly__c && !licenseConfig.ExistingBusinessOnly__c
                || !isExistingBusiness && !licenseConfig.NewBusinessOnly__c && licenseConfig.ExistingBusinessOnly__c;
            List<String> packageIds = String.isNotBlank(licenseConfig.AffectedPackage__c)
                ? licenseConfig.AffectedPackage__c.split(ITEM_DELIMITER)
                : new List<String>{ ALL };
            List<String> elementIds = licenseConfig.LicenseElementId__c.split(ITEM_DELIMITER);
            Boolean isAvailableUserOrProfile = isAvailableUserOrProfile(licenseConfig.AvailableForUsers__c, currentUserId, currentProfileId);
            for (String packageId : packageIds) {
                packageId = packageId.trim();
                for (String elementId : elementIds) {
                    elementId = elementId.trim();

					if (!licenseConfig.NotAvailableWithRCV__c) {
                        if (String.isBlank(licenseConfig.AvailableForUsers__c) || isAvailableUserOrProfile) {
                            result.addDiscountSettings(packageId, elementId, licenseConfig.AllowedDiscountType__c);
                        }else{
                            result.addDiscountSettings(packageId, elementId, 'none');
                        }
                    }

                    Boolean isHiddenBypassed = bypassLicenses.contains(elementId);

                    /* new/existing separation currently doesn't work on QOP/LC properly
                    since there is always no Account field in settings json for those pages */
                    if (licenseConfig.IsHidden__c && !isHiddenBypassed && !isBypassConfig && !isAvailableUserOrProfile) {
                        if (licenseConfig.NotAvailableWithRCV__c && licenseConfig.NotAvailableWithNoneVideoProvider__c) {
                            result.addHiddenLargeMeetingsLicenses(packageId, elementId);
                        } else {
                            result.addHiddenSettings(packageId, elementId);
                        }
                    }
                    if (licenseConfig.ShowLicenseName__c) {
                        result.addShowNameSettings(packageId, elementId);
                    }
                    if (licenseConfig.Show_Edition__c) {
                        result.addShowEditionSettings(packageId, elementId);
                    }
                    if (licenseConfig.CheckChildLicenseQuantities__c) {
                        result.addCheckChildAssignmentSettings(packageId, elementId);
                    }
                    if (licenseConfig.UnavailableWithoutContract__c) {
                        result.addUnavailableWithoutContractSettings(packageId, elementId);
                    }
                    if (licenseConfig.AvailableForLBO__c) {
                        result.addUnavailableSettingsNonLBO(packageId, elementId);
                    }
                    if (licenseConfig.UnAvailableForLBO__c) {
                        result.addUnavailableSettingsLBO(packageId, elementId);
                    }
                    if (licenseConfig.MinimumLicenseCategoryQuantity__c != null) {
                        result.addMinimumLicenseOrCategoryQuantitySettings(
                            packageId,
                            elementId,
                            licenseConfig.MinimumLicenseCategoryQuantity__c
                        );
                    }
                    if (licenseConfig.SkipLicenseCreation__c) {
                        result.addSkipLicenseCreationSettings(packageId, elementId);
                    }
                    if (licenseConfig.NotAvailableWithRCV__c) {
                        result.addNotAvailableWithRCVLicense(elementId);
                    }
                    if (String.isNotBlank(licenseConfig.LicenseMinPrice__c)) {
                        result.addLicenseMinPrice(packageId, elementId, licenseConfig.LicenseMinPrice__c);
                    }
                    if (licenseConfig.UseCategoryCodeAsExtIdInOrderAPI__c) {
                        result.addCategoryCodesForExternalIdInOrderAPI(elementId);
                    }
                    if (licenseConfig.NotAvailableForPRM__c) {
                        result.addUnavailableSettingsPRM(packageId, elementId);
                    }
                }

            }
        }

        for (NGBS_Licenses_Dependencies__c licenseDependency : NGBS_Licenses_Dependencies__c.getAll().values()) {
            if (String.isBlank(licenseDependency.Depends_on_licenses__c) || String.isBlank(licenseDependency.Affected_licenses__c)) {
                continue;
            }

            Set<String> dependsOnSet = new Set<String>(licenseDependency.Depends_on_licenses__c.split(';'));
            List<String> affectedList = licenseDependency.Affected_licenses__c.split(';');
            Set<String> packageIds = String.isNotBlank(licenseDependency.PackageIds__c) 
                ? new Set<String>(licenseDependency.PackageIds__c.split(';'))
                : new Set<String>{ ALL };
            Set<String> ignoredPackageIds = String.isNotBlank(licenseDependency.IgnoreForPackageIDs__c)
                ? new Set<String>(licenseDependency.IgnoreForPackageIDs__c.split(';'))
                : new Set<String>();

            // PackageIds__c values have priority over IgnoreForPackageIDs__c
            ignoredPackageIds.removeAll(packageIds);

            // For "All" packages: keep "All" and process ignores separately with "!" prefix
            // For specific packages: filter out the ignored ones directly
            if (!packageIds.contains(ALL) && !ignoredPackageIds.isEmpty()) {
                packageIds.removeAll(ignoredPackageIds);
                ignoredPackageIds.clear();
            }

            // Add dependencies for target package IDs
            for (String packageId : packageIds) {
                result.addLicenseDependencies(packageId, affectedList, dependsOnSet);
            }

            // Add ignored dependencies for ignored packages (only when "All" is used)
            if (!ignoredPackageIds.isEmpty()) {
                Set<String> ignoredDependencies = new Set<String>();
                for (String dep : dependsOnSet) {
                    ignoredDependencies.add('!' + dep);
                }
                for (String packageId : ignoredPackageIds) {
                    result.addLicenseDependencies(packageId, affectedList, ignoredDependencies);
                }
            }
        }
        return result;
    }

    public static Map<String, Set<String>> getNGBSLicensesDescription() {
        Map<String, Set<String>> result = new Map<String, Set<String>>();

        NGBS_License_Description__mdt[] descriptions = [SELECT ElementId__c, Description__c FROM NGBS_License_Description__mdt];
        for (NGBS_License_Description__mdt descriptionConfig : descriptions) {
            List<String> elementIds = descriptionConfig.ElementId__c.split(ITEM_DELIMITER);
            String description = descriptionConfig.Description__c;
            for (String elementId : elementIds) {
                elementId = elementId.trim();

                if (String.isBlank(description) || String.isBlank(elementId)) {
                    continue;
                }

                if (!result.containsKey(elementId)) {
                    result.put(elementId, new Set<String>());
                }

                result.get(elementId).add(description);
            }
        }

        return result;
    }

    public static Map<String, Map<String, Boolean>> getNGBSOpptyPageLicenses() {
        Map<String, Map<String, Boolean>> result = new Map<String, Map<String, Boolean>>();

        for (NGBSOpptyPageLicenses__c opptyPageLicenses : NGBSOpptyPageLicenses__c.getAll().values()) {
            List<String> packageIds = opptyPageLicenses.AffectedPackage__c != null
                ? opptyPageLicenses.AffectedPackage__c.split(ITEM_DELIMITER)
                : new List<String>{ ALL };
            List<String> elementIds = opptyPageLicenses.ElementId__c.split(ITEM_DELIMITER);
            Boolean isShowChildren = opptyPageLicenses.ShowChildren__c;

            for (String packageId : packageIds) {
                packageId = packageId.trim();
                for (String elementId : elementIds) {
                    elementId = elementId.trim();
                    if (String.isBlank(packageId) || String.isBlank(elementId)) {
                        continue;
                    }
                    if (!result.containsKey(packageId)) {
                        result.put(packageId, new Map<String, Boolean>());
                    }
                    result.get(packageId).put(elementId, isShowChildren);
                }
            }
        }

        return result;
    }

    @TestVisible
    private static String getDefaultPackageForLeadConvert() {
        Set<String> brandsSet = new Set<String>{
            OpportunityController.BRAND_RING_CENTRAl,
            OpportunityController.BRAND_RING_CENTRAL_CANADA
        };
        List<DefaultPackage> packagesList = new List<DefaultPackage>();
        List<DefaultPackagesForLeadConvert__c> defaultPackages = DefaultPackagesForLeadConvert__c.getAll().values();
        for (DefaultPackagesForLeadConvert__c pkg : defaultPackages) {
            packagesList.add(
                new DefaultPackage(
                    pkg.Brand__c,
                    pkg.Id__c,
                    pkg.Version__c,
                    pkg.Service__c,
                    pkg.Currency__c
                )
            );
        }
        return JSON.serialize(packagesList);
    }

    public class DefaultPackage {
        public String brand;
        public String id;
        public String version;
        public String service;
        public String currencyCode;

        public DefaultPackage(String Brand, String Id, String Version, String Service, String CurrencyCode) {
            this.brand = Brand;
            this.id = Id;
            this.version = Version;
            this.service = Service;
            this.currencyCode = CurrencyCode;
        }
    }

    public static Map<String, String> getCountryCodes() {

        Map<String, String> resultMap = new Map<String, String>();

        for (CountryCodes__c countryCodeRecord : CountryCodes__c.getAll().values()) {
            for (String countryName : countryCodeRecord.CountryName__c.split(ITEM_DELIMITER)) {
                resultMap.put(countryName.toLowerCase(), countryCodeRecord.Name);
            }
        }

        return resultMap;
    }

    /**
     * Get alpha-2 (Two-letter) code list by vatType
     * @param vatType - vat type (VAT, GST and other)
     *
     * @return alpha-2 code list
     */
    public static List<String> getAlpha2CountryCodesByVatType(String vatType) {
        List<String> countryCodes = new List<String>();
        for (CountryCodes__c countryCode : CountryCodes__c.getAll().values()) {
            if (String.isNotBlank(countryCode.VATNumbersByName__c) && countryCode.VATNumbersByName__c == vatType && !countryCode.IsDeleted) {
                for (String countryName : countryCode.CountryName__c.split(ITEM_DELIMITER)) {
                    countryCodes.add(countryCode.CountryNameShort__c);
                }
            }
        }
        return countryCodes;
    }

    /**
     * get alpha-2 (Two-letter) country code
     * @param country country name
     *
     * @return aalpha-2 code or null
     */
    public static String getAlpha2CountryCode(String country) {
        Map<String, String> countryCodesMap = new Map<String, String>();
        for (CountryCodes__c countryCode : CountryCodes__c.getAll().values()) {
            if (countryCode.CountryNameShort__c != null) {
                for (String countryName : countryCode.CountryName__c.split(ITEM_DELIMITER)) {
                    countryCodesMap.put(countryName, countryCode.CountryNameShort__c);
                }
                countryCodesMap.put(countryCode.CountryNameShort__c.toLowerCase(), countryCode.CountryNameShort__c);
            }
        }
        return (country != null) ? countryCodesMap.get(country.toLowerCase()) : null;
    }

    /**
     * Get object CountryCodes__c by country name
     * @param country country name
     *
     * @return CountryCodes__c
     */
    public static CountryCodes__c getCountryCodeSetting(String country) {
        Map<String, CountryCodes__c> countryCodesMap = new Map<String, CountryCodes__c>();
        for (CountryCodes__c countryCode : CountryCodes__c.getAll().values()) {
            if (countryCode.CountryName__c != null) {
                for (String countryName : countryCode.CountryName__c.split(ITEM_DELIMITER)) {
                    countryCodesMap.put(countryName, countryCode);
                }
                if (countryCode.CountryNameFull__c != null) {
                    countryCodesMap.put(countryCode.CountryNameFull__c.toLowerCase(), countryCode);
                }
                if (countryCode.CountryNameShort__c != null) {
                    countryCodesMap.put(countryCode.CountryNameShort__c.toLowerCase(), countryCode);
                }
            }
        }
        return String.isNotBlank(country) ? countryCodesMap.get(country.toLowerCase()) : null;
    }

    /**
     * Method checks that it is switzerland
     * @param country country name
     *
     * @return true or false
     */
    public static Boolean isSwitzerland(String country) {
        Set<String> countryNames = new Set<String>{'switzerland', 'che', 'ch'};
        Boolean result = false;
        if (String.isNotBlank(country) && countryNames.contains(country.toLowerCase()) && countryCodes.containsKey(country.toLowerCase())) {
            result = true;
        }

        return result;
    }

    public static Boolean isTaiwan(String country) {
        Set<String> countryNames = new Set<String>{'taiwan', 'twn', 'tw'};
        Boolean result = false;
        if (String.isNotBlank(country) && countryNames.contains(country.toLowerCase()) && countryCodes.containsKey(country.toLowerCase())) {
            result = true;
        }

        return result;
    }

    public static Map<String, String> getCountryCodeToCountryMapping() {
        Map<String, String> resultMap = new Map<String, String>();

        Map<String, String> countryToCountryCodeMapping = getCountryCodes();

        for (String key: countryToCountryCodeMapping.keySet()) {
            if (!countryToCountryCodeMapping.get(key).equalsIgnoreCase(key)) {
                resultMap.put(countryToCountryCodeMapping.get(key).toLowerCase(), key.toLowerCase());
            }
        }

        // Add full names of countries as keys
        for (String val : resultMap.values()) {
            resultMap.put(val, val);
        }

        return resultMap;
    }

    public static String getSessionId() {
        String sId = UserInfo.getSessionId();
        NGBS_Settings__c settings = NGBS_Settings__c.getInstance();
        String key = settings.HerokuSecretKey__c;

        if (isProduction() && key == null && !Test.isRunningTest()) {
            AquivaHelper.throwAquivaException('Secret key must be populated');
        }

        if (key != null) {
            sId = getEncryptedSessionId(sId, key);
        }

        return sId;
    }

    public static String getEncryptedSessionId(String sId, String key) {
        Blob secretKey = EncodingUtil.base64Decode(key);
        Blob data = Blob.valueOf(sId);
        return EncodingUtil.base64Encode( Crypto.encryptWithManagedIV('AES128', secretKey, data) );
    }

    public static Boolean isProduction() {
        Organization org = (Organization) new OrganizationSelector()
            .selectOrg()
            .setQueryCaching(true)
            .executeQuery()[0];
        return !org.IsSandbox;
    }

    @testVisible
    private class PackageBusinessIdentityMapping implements Comparable {
        public String biId;
        public String biName;
        public String cur;
        public Boolean isPreselectedSalesLead;
        public Boolean isPreselectedPartnerLead;
        public String leadRecordType;
        public String defaultBrand;
        public Integer sortOrder;

        public PackageBusinessIdentityMapping() {}
        public PackageBusinessIdentityMapping(PackageBusinessIdentityMapping__c mappingItem) {
            this.biId = mappingItem.BiId__c;
            this.biName = mappingItem.BiName__c;
            this.cur = mappingItem.Currency__c;
            this.isPreselectedSalesLead = mappingItem.IsPreselectedSalesLead__c;
            this.isPreselectedPartnerLead = mappingItem.IsPreselectedPartnerLead__c;
            this.leadRecordType = mappingItem.LeadRecordType__c;
            this.defaultBrand = mappingItem.DefaultBrand__c;
            this.sortOrder = mappingItem.SortOrder__c != null ? mappingItem.SortOrder__c.intValue() : null;
        }

        public Integer compareTo(Object compareTo) {
            PackageBusinessIdentityMapping comareToMappingInstance = (PackageBusinessIdentityMapping) compareTo;
            if (this.sortOrder != null && comareToMappingInstance.sortOrder != null) {
                return this.sortOrder - comareToMappingInstance.sortOrder;
            } else if (this.sortOrder == null && comareToMappingInstance.sortOrder != null) {
                return 1;
            } else if (comareToMappingInstance.sortOrder == null && this.sortOrder != null) {
                return -1;
            } else {
                return this.biName.compareTo(comareToMappingInstance.biName);
            }
        }
    }

    @testVisible
    private static List<PackageBusinessIdentityMapping> getBusinessIdentityMapping() {
        return getBusinessIdentityMapping(null);
    }

    @testVisible
    private static List<PackageBusinessIdentityMapping> getBusinessIdentityMapping(String leadId) {

        User currentUser = getUser();
        Lead currentLead = getLead(leadId);

        List<PackageBusinessIdentityMapping> result = new List<PackageBusinessIdentityMapping>();
        Set<String> permissionSetsAssigneeToUser = getPermissionSetsAssigneeToUser(currentUser.Id);

        for (PackageBusinessIdentityMapping__c item : PackageBusinessIdentityMapping__c.getAll().values()) {
            Boolean isActive = item.Active__c;
            Boolean isAvailableForLeadRecordType = currentLead == null;
            Boolean isAvailableForProfile = false;
            Boolean isAvailableForPermissionSet = false;

            if (currentLead != null) {
                if (!String.isBlank(item.LeadRecordType__c)) {
                    Set<String> availableForLeadTypes = new Set<String>(item.LeadRecordType__c.split(','));
                    Schema.RecordTypeInfo info = LeadHelper.RT_INFO_BY_ID.get(currentLead.RecordTypeId);
                    isAvailableForLeadRecordType = availableForLeadTypes.contains(info.getName());
                } else {
                    isAvailableForLeadRecordType = true;
                }
            }

            if (!String.isBlank(item.Profile__c)) {
                Set<String> availableForProfiles = new Set<String>(item.Profile__c.split(','));
                isAvailableForProfile = availableForProfiles.contains(currentUser.Profile.Name);
            } else {
                isAvailableForProfile = true;
            }

            if (!String.isBlank(item.PermissionSet__c)) {
                Set<String> availableForPermissionSets = new Set<String>(item.PermissionSet__c.split(','));
                for (String permissionSetLabel : availableForPermissionSets) {
                    if (permissionSetsAssigneeToUser.contains(permissionSetLabel)) {
                        isAvailableForPermissionSet = true;
                        break;
                    }
                }
            } else {
                isAvailableForPermissionSet = true;
            }

            if (isActive
                && isAvailableForLeadRecordType
                && isAvailableForProfile
                && isAvailableForPermissionSet
            ) {
                result.add(
                    new PackageBusinessIdentityMapping(item)
                );
            }
        }

        result.sort();

        return result;
    }

    public static Lead getLead(String leadId) {
        if (String.isBlank(leadId)) {
            return null;
        }

        List<Lead> leadList = (List<Lead>) new LeadSelector()
                .selectLeadsByIds(new List<Object> { new List<String> { leadId } })
                .executeQuery();

        return leadList.size() > 0 ? leadList.get(0) : null;
    }

    public static String getBusinessIdentityMappingJSON() {
        return getBusinessIdentityMappingJSON(null);
    }

    public static String getBusinessIdentityMappingJSON(String leadId) {
        List<PackageBusinessIdentityMapping> mappingList = getBusinessIdentityMapping(leadId);
        return JSON.serialize(mappingList);
    }

    @testVisible
    private class PackageLabelsMapping {
        public String accountType;
        public String[] SIGNUP_SFDC;
        public String[] SIGNUP_SFDCVAR;
        public String[] UpgradeWizardExpiration;
        public Integer businessIdentity;

        public PackageLabelsMapping() {}
        public PackageLabelsMapping(PackageLabelsMapping__c mappingItem) {
            this.accountType = mappingItem.AccountType__c;
            this.SIGNUP_SFDC = splitLabels(mappingItem.SIGNUP_SFDC__c);
            this.SIGNUP_SFDCVAR = splitLabels(mappingItem.SIGNUP_SFDCVAR__c);
            this.UpgradeWizardExpiration = splitLabels(mappingItem.UpgradeWizardExpiration__c);
            this.businessIdentity = Integer.valueOf(mappingItem.BusinessIdentityId__c);
        }

        private String[] splitLabels(String labelsToSplit) {
            if (String.isBlank(labelsToSplit)) {
                return null;
            }
            return labelsToSplit.split(',');
        }
    }

    @testVisible
    private static List<PackageLabelsMapping> getPackageLabelsMapping() {

        User currentUser = getUser();

        List<PackageLabelsMapping> result = new List<PackageLabelsMapping>();

        for (PackageLabelsMapping__c item : PackageLabelsMapping__c.getAll().values()) {

            if (!item.Active__c || String.isBlank(item.Profile__c)) {
                continue;
            }

            Set<String> availableForProfiles = new Set<String>(item.Profile__c.split(','));
            if (availableForProfiles.contains(currentUser.Profile.Name)) {
                result.add(
                    new PackageLabelsMapping(item)
                );
            }
        }

        return result;
    }

    public static String getPackageLabelsMappingJSON() {
        List<PackageLabelsMapping> mappingList = getPackageLabelsMapping();
        return JSON.serialize(mappingList);
    }

    public static Set<String> getPermissionSetsAssigneeToUser (Id userId) {
        Set<String> permissionSetNames = new Set<String>();
        List<Id> psasPermissionIds = new List<Id>();
        List<PermissionSetAssignment> psas = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssignee(new List<Object>{userId})
            .executeQuery();

        for (PermissionSetAssignment psa : psas) {
            psasPermissionIds.add(psa.PermissionSetId);
        }

        if (!psasPermissionIds.isEmpty()) {
            List<PermissionSet> pss = (List<PermissionSet>) new PermissionSetSelector()
                .selectPermissionSetsByPSAssignment(new List<Object>{psasPermissionIds})
                .executeQuery();

            for (PermissionSet ps: pss) {
                permissionSetNames.add(ps.Label);
            }
        }

        return permissionSetNames;
    }

    public static Approval__c getLastApprovedKYCApproval(List<Approval__c> accountApprovals) {
        if (accountApprovals == null || accountApprovals.isEmpty()) {
            return null;
        }

        Approval__c lastApprovedKYCApproval;
        for (Approval__c appr: accountApprovals) {
            if (appr.RecordTypeId == ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST
                && appr.Status__c == ApprovalHelper.STATUS_APPROVED
                && (lastApprovedKYCApproval == null
                    || appr.StatusLastModifiedDate__c > lastApprovedKYCApproval.StatusLastModifiedDate__c)
            ) {
                lastApprovedKYCApproval = appr;
            }
        }
        return lastApprovedKYCApproval;
    }

    public static List<Approval__c> getAccountApprovals(Opportunity opp) {
        return new NoSharing().getAccountApprovals(opp);
    }

    public static List<TargetPricingKey__c> getTargetPricingKeys() {
        return TargetPricingKey__c.getall().values();
    }

    public static List<TargetPricingPotentialRaters__c> getTargetPricingPotentialRaters() {
        return TargetPricingPotentialRaters__c.getall().values();
    }

    public static List<TargetPricingGlobalRaters__c> getTargetPricingGlobalRaters() {
        return TargetPricingGlobalRaters__c.getall().values();
    }

    public static List<DiscountCeilingCBox__mdt> getDiscountCeilingCBox() {
        return DiscountCeilingCBox__mdt.getall().values();
    }

    public static List<DiscountCeilingCategory__mdt> getDiscountCeilingCategory() {
        return DiscountCeilingCategory__mdt.getall().values();
    }

    public static List<DiscountCeilingLicense__mdt> getDiscountCeilingLicense() {
        return DiscountCeilingLicense__mdt.getall().values();
    }

    public static List<PackageBasePriceMapping__c> getPackageBasePriceMapping() {
        return PackageBasePriceMapping__c.getall().values();
    }

    public static Boolean isAvailableUserOrProfile(String userProfileIds, String userId, String profileId) {
        Boolean result = false;

        if (String.isNotBlank(userProfileIds)) {
            List<String> idStrings = userProfileIds.split(';');
            result = idStrings.contains(userId) || idStrings.contains(profileId);
        }
        return result;
    }

    public static List<LanguageCodeMapping> getLanguageCodeMap() {
        List<NGBSLanguageCodeMapping__mdt> mappings = (List<NGBSLanguageCodeMapping__mdt>) new NGBSLanguageCodeMappingSelector()
            .selectActiveLanguageCodeMappings()
            .executeQuery();
        List<LanguageCodeMapping> result = new List<LanguageCodeMapping>();
        for (NGBSLanguageCodeMapping__mdt mapping: mappings) {
            result.add(new LanguageCodeMapping(mapping));
        }
        return result;
    }

    @TestVisible
    private class DqProductCategories {
        public String salesCategoriesJson = '';
        public String ccCategoriesJson = '';
        public String allCategoriesJson = '';
        public DqProductCategories(String salesCategoriesJson, String ccCategoriesJson, String allCategoriesJson) {
            this.salesCategoriesJson = salesCategoriesJson;
            this.ccCategoriesJson = ccCategoriesJson;
            this.allCategoriesJson = allCategoriesJson;
        }
    }

    @TestVisible
    private static DqProductCategories getDqProductCategoryOptions() {
        List<PicklistController.Option> salesProductCategoriesOptions = new List<PicklistController.Option>();
        List<PicklistController.Option> ccProductCategoriesOptions = new List<PicklistController.Option>();
        List<PicklistController.Option> allProductCategoriesOptions = new List<PicklistController.Option>();
        if (Test.isRunningTest()) {
            salesProductCategoriesOptions = new List<PicklistController.Option>{
                new PicklistController.Option('', '--None--'),
                new PicklistController.Option('Test_Product_Category_Sales', 'Test Product Category Sales')
            };
            ccProductCategoriesOptions = new List<PicklistController.Option>{
                new PicklistController.Option('', '--None--'),
                new PicklistController.Option('Test_Product_Category_Contact_Center', 'Test Product Category Contact Center')
            };

            allProductCategoriesOptions.add(new PicklistController.Option('', '--None--'));
            allProductCategoriesOptions.add(new PicklistController.Option('Test_Product_Category_Contact_Center', 'Test Product Category Contact Center'));
        } else {
            List<PicklistController.Picklist> salesProductCategories = SFDescribeHelper.getPicklistOptions(
                'DQ_Deal_Qualification_Discounts__c',
                'Sales Quote',
                'Product_Category__c'
            );
            List<PicklistController.Picklist> ccProductCategories = SFDescribeHelper.getPicklistOptions(
                'DQ_Deal_Qualification_Discounts__c',
                'Contact Center',
                'Product_Category__c'
            );
            if (!salesProductCategories.isEmpty()) {
                salesProductCategoriesOptions = salesProductCategories.get(0).Options;
            }
            if (!ccProductCategories.isEmpty()) {
                ccProductCategoriesOptions = ccProductCategories.get(0).Options;
            }
            List<Schema.PicklistEntry> allProductCategories = SFDescribeHelper.getOptions(
                'DQ_Deal_Qualification_Discounts__c',
                'Product_Category__c');
            for(Schema.PicklistEntry productCategory : allProductCategories) {
                allProductCategoriesOptions.add(new PicklistController.Option(productCategory.Value, productCategory.Label));
            }
        }
        String salesCategoriesJson = JSON.serialize(salesProductCategoriesOptions);
        String ccCategoriesJson = JSON.serialize(ccProductCategoriesOptions);
        String allProductCategoriesJson = JSON.serialize(allProductCategoriesOptions);
        return new DqProductCategories(salesCategoriesJson, ccCategoriesJson, allProductCategoriesJson);
    }

    @TestVisible
    private static List<String> getNonEmptyBIPackages() {
        List<String> result = new List<String>();

        for (NGBSPurchaseSettingsByBI__c config : NGBSPurchaseSettingsByBI__c.getAll().values()) {
            if (String.isNotBlank(config.NonEmptyBIPackages__c)) {
                result.addAll(config.NonEmptyBIPackages__c.split(ITEM_DELIMITER));
            }
        }

        return result;
    }

    @TestVisible
    private static List<Schema.PicklistEntry> getAccessibleTerms(List<Schema.PicklistEntry> termValues) {
        if (FeatureManagement.checkPermission('ExtendedInitialRenewalTerms')) {
            return termValues;
        }
        List<Schema.PicklistEntry> accessibleTerms = new List<Schema.PicklistEntry>();
        Set<String> basicValues = new Set<String>{ '12', '24', '36', '48', '60' };
        for (Schema.PicklistEntry item : termValues) {
            if (basicValues.contains(item.getValue())) {
                accessibleTerms.add(item);
            }
        }
        return accessibleTerms;
    }

    @TestVisible
    private static List<Schema.PicklistEntry> getAccessibleSpecialTerms(Map<String,Schema.PicklistEntry> specialTermsMap) {
        List<NGBSExtendedSpecialTerms__c> specialTermsExtendedVals = NGBSExtendedSpecialTerms__c.getAll().values();
        Map<String, List<String>> permSetNameToExtendedValuesMap = new Map<String, List<String>>();
        for (NGBSExtendedSpecialTerms__c nterm : specialTermsExtendedVals) {
            if (nterm.ExtendedValues__c != null && nterm.PermissionSet__c != null) {
                permSetNameToExtendedValuesMap.put(nterm.PermissionSet__c, nterm.ExtendedValues__c.split(';'));
            }
        }
        if (permSetNameToExtendedValuesMap.isEmpty()) {
            return specialTermsMap.values();
        }
        for (String psName : permSetNameToExtendedValuesMap.keySet()) {
            if (!FeatureManagement.checkPermission(psName)) {
                for (String s : permSetNameToExtendedValuesMap.get(psName)) {
                    specialTermsMap.remove(s + ' Free Months of Service');
                }
            }
        }
        return specialTermsMap.values();
    }

    public static Map<String, String> getSubBrandAndDefaultBI(Lead leadRec, Id accId) {
        return new NoSharing().getSubBrandAndDefaultBI(leadRec, accId);
    }

    public static List<String> getAvailableBusinessIdentities(String defaultBI, String subBrand, String country, String brand) {
        return new NoSharing().getAvailableBusinessIdentities(defaultBI, subBrand, country, brand);
    }

    public static List<Default_Business_Identity_Mapping__mdt> getDefaultBusinessIdentityMapping() {
            return new NoSharing().getDefaultBusinessIdentityMapping();
    }

    public without sharing class NoSharing {
        public Map<String, String> getSubBrandAndDefaultBI(Lead leadRec, Id accId) {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            Map<String, String> result = new Map<String, String>{
                'subBrand' => '',
                'defaultBI' => '',
                'country' => '',
                'brand' => ''
            };
            String defaultBI = '';
            String subBrand = '';
            String ultimateAcc = '';
            String parentAccId = '';
            List<Default_Business_Identity_Mapping__mdt> defaultBIMap = getDefaultBusinessIdentityMapping();
            List<SubBrandsMapping__c> subBrandsMap = (List<SubBrandsMapping__c>) new SubBrandsMappingSelector()
                .selectSubBrandsMappingRecords()
                .executeQuery();
            Map<String, String> subBrandToDefaultBIMap = getSubBrandToDefaultBIMap();
            Account accountRec = new Account();
            if (accId != null) {
                accountRec = [SELECT Partner_ID__c, ParentId, Partner_Account__c, Ultimate_Account__c, RC_Brand__c, BillingCountry FROM Account WHERE Id = :accId];
            }
            parentAccId = leadRec != null ? leadRec.Partner_Account__r.Parent_Partner_Account__c : accountRec.Partner_Account__c;
            String country = leadRec != null ? leadRec.Country__c : accountRec.BillingCountry;
            String brand = leadRec != null ? leadRec.Lead_Brand_Name__c : accountRec.RC_Brand__c;
            String partnerId = leadRec != null ? leadRec.LeadPartnerID__c : accountRec.Partner_ID__c;
            for (SubBrandsMapping__c record : subBrandsMap) {
                if (record.PartnerID__c == partnerId && record.Country__c == country && record.Brand__c == brand) {
                    subBrand = record.Sub_Brand__c;
                    result.put('subBrand', subBrand);
                    break;
                }
            }
            while (String.isBlank(subBrand) && String.isNotBlank(parentAccId)) {
                Account acc = [SELECT Partner_ID__c, Partner_Account__c FROM Account WHERE Id = :parentAccId];
                parentAccId = acc.Partner_Account__c;
                for (SubBrandsMapping__c record : subBrandsMap) {
                    if (record.PartnerID__c == acc.Partner_ID__c && record.Country__c == country && record.Brand__c == brand) {
                        subBrand = record.Sub_Brand__c;
                        result.put('subBrand', subBrand);
                        break;
                    }
                }
            }
            if (!featureToggle.EnableBusinessIdentityMapping__c) {
                return result;
            }
            defaultBI = subBrandToDefaultBIMap.get(subBrand);
            result.put('defaultBI', defaultBI);
            if (String.isBlank(defaultBI)) {
                for (Default_Business_Identity_Mapping__mdt record : defaultBIMap) {
                    if (record.Country__c == country && record.Brand__c == brand && String.isBlank(record.Sub_Brand__c)) {
                        defaultBI = record.Default_Business_Identity__c;
                        result.put('defaultBI', defaultBI);
                        break;
                    }
                }
            }
            result.put('country', country);
            result.put('brand', brand);
            return result;
        }

        public Map<String, String> getSubBrandToDefaultBIMap() {
            List<Default_Business_Identity_Mapping__mdt> defaultBIMap = getDefaultBusinessIdentityMapping();
            Map<String, String> resultMap = new Map<String, String>();
            for (Default_Business_Identity_Mapping__mdt record : defaultBIMap) {
                if (String.isNotBlank(record.Sub_Brand__c)) {
                    resultMap.put(record.Sub_Brand__c, record.Default_Business_Identity__c);
                }
            }
            return resultMap;
        }

        public List<Default_Business_Identity_Mapping__mdt> getDefaultBusinessIdentityMapping() {
        	return Default_Business_Identity_Mapping__mdt.getall().values();
    	}

        public List<String> getAvailableBusinessIdentities(String defaultBI, String subBrand, String country, String brand) {
            Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
            if (!featureToggle.EnableBusinessIdentityMapping__c || String.isBlank(defaultBI)) {
                return new List<String>();
            }
            if (String.isBlank(subBrand)) {
                subBrand = null;
            }
            List<Default_Business_Identity_Mapping__mdt> defaultBIMap = getDefaultBusinessIdentityMapping();
            List<String> availableBIs = new List<String>();
            for (Default_Business_Identity_Mapping__mdt record : defaultBIMap) {
                if (record.Default_Business_Identity__c == defaultBI
                    && record.Sub_Brand__c == subBrand
                    && record.Country__c == country
                    && record.Brand__c == brand
                    && String.isNotBlank(record.Available_Business_Identities__c)
                ) {
                    availableBIs = record.Available_Business_Identities__c.split(';');
                    break;
                }
            }
            return availableBIs;
        }

        public Approval__c getSecondaryDLApproval(Opportunity opp) {
            List<Approval__c> approvals = new List<Approval__c>();
            if (opp != null) {
                approvals = (List<Approval__c>) new ApprovalSelector()
                    .selectSecondaryDLApprovalsForAccounts(new List<String>{opp.AccountId})
                    .setQueryCaching(true)
                    .setLimit(1)
                    .executeQuery();
                if (!approvals.isEmpty()) {
                    return approvals.get(0);
                }
            }
            return null;
        }

        public List<Approval__c> getAccountApprovals (Opportunity opp) {
            List<Approval__c> approvals = new List<Approval__c>();

            if (opp != null) {
                approvals = (List<Approval__c>) new ApprovalSelector()
                    .selectTaxExemptAndKYCApprovalsForAccount(new List<Object>{opp.accountId})
                    .executeQuery();
            }

            return approvals;
        }
    }

    public class GSPPartnerSetup {
        public Boolean isDisablePOC = false;
        public Boolean isDisableProServ = false;
        public Boolean isDisablePDF = false;
        public Boolean isDisableCommercialQuoting = false;
        public Boolean hasNGBSPackages = false;
        public Boolean isContractedPackages;

        private Id gspPartnerSetupId = null;

        private GSPPartnerSetup(GSP_Partner_Setup__c partnerSetup) {
            this.gspPartnerSetupId = partnerSetup.Id;
            this.isDisablePOC = partnerSetup.Disable_POC__c;
            this.isDisableProServ = partnerSetup.Disable_ProServ__c;
            this.isDisablePDF = partnerSetup.Disable_PDF__c;
            this.isDisableCommercialQuoting = partnerSetup.Disable_Commercial_Quoting__c;
            this.hasNGBSPackages = partnerSetup.Has_NGBS_Packages__c;
            this.isContractedPackages = partnerSetup.ContractedPackages__c;
        }

        public GSPPartnerSetup(Opportunity opp) {
            if (opp == null || opp.Account?.GSP__c != true) {
                return;
            }

            for (GSP_Partner_Setup__c partner : GSP_Partner_Setup__c.getAll().values()) {
                if (partner.Validate_by_Brand__c) {
                    if (partner.Validation_name__c == opp.Brand_Name__c) {
                        this(partner);
                        return;
                    }
                } else {
                    if (String.isBlank(opp.BusinessIdentity__c)) {
                        continue;
                    }
                    BillingWrappers.QuoteBusinessIdentity oppBi = (BillingWrappers.QuoteBusinessIdentity) JSON.deserialize(opp.BusinessIdentity__c, BillingWrappers.QuoteBusinessIdentity.class);
                    if (oppBi?.biId == partner.BusinessIdentityId__c) {
                        this(partner);
                        return;
                    }
                }
            }
        }

        public Boolean isQuotingNotSupported() {
            return this.isDisablePOC
                && this.isDisableProServ
                && this.isDisablePDF
                && this.isDisableCommercialQuoting
                && this.hasNGBSPackages;
        }

        public Boolean exist() {
            return this.gspPartnerSetupId != null;
        }
    }

    //Access Control Settings
    public class AccessControlSettingsWrapper {
        public Map<String, AccessControlSettings__c> mapBrandSetting {get; set;}
        public Map<String, AccessControlSettings__c> mapBISetting {get; set;}
        public Map<String, AccessControlSettings__c> mapPIDSetting {get; set;}
        public Set<String> allBrands {get; set;}
        public Set<String> allGroups {get; set;}
        public Map<String, Id> mapGroups {get; set;}
        public Map<String, AccessControlSettings__c> mapBIdentifierSetting {get; set;}
        public Set<String> allIdentifiers {get; set;}
        public Map<String, AccessControlSettings__c> mapBrandIdSetting {get; set;}
        public Map<String, AccessControlSettings__c> mapDirectBrandSetting {get; set;}
        public Map<String, AccessControlSettings__c> mapDirectBIToSetting {get; set;}
        public Map<String, AccessControlSettings__c> mapDirectBrandToSettingForLead {get; set;}
        public Set<String> otherBrands {get; set;}
        public Set<String> otherBIs {get; set;}
        public String nonGSPGroup {get; set;}
        public String directGroup {get; set;}
        public Set<String> allPartnerIds {get; set;}
        public Set<String> parentFromSetting {get; set;}

        public AccessControlSettingsWrapper() {
        	Map<String, AccessControlSettings__c> mapOfACSettings = AccessControlSettings__c.getall();
            Set<String> allGroupsFromSetting = new Set<String>();
            Map<String, AccessControlSettings__c> mapBrandToSetting = new Map<String, AccessControlSettings__c>();
            Map<String, AccessControlSettings__c> mapBIToSetting = new Map<String, AccessControlSettings__c>();
            Map<String, AccessControlSettings__c> mapPIDToSetting = new Map<String, AccessControlSettings__c>();
            Set<String> brandsFromSetting = new Set<String>();
            Set<String> otherBrandsFromSetting = new Set<String>();
            Set<String> otherBIsFromSetting = new Set<String>();
            Set<String> parentFromSetting = new Set<String>();
            Set<String> directBrandsFromSetting = new Set<String>();
            String nonGSPGroup = '';
            String directGroup = '';
            Set<String> allPartnerIds = new Set<String>();
            Map<String, AccessControlSettings__c> mapBIdentifierToSetting = new Map<String, AccessControlSettings__c>();
            Set<String> allIdentifiers = new Set<String>();
            Map<String, AccessControlSettings__c> mapBrandIdToSetting = new Map<String, AccessControlSettings__c>();
            Map<String, AccessControlSettings__c> mapDirectBrandToSetting = new Map<String, AccessControlSettings__c>();
            Map<String, AccessControlSettings__c> mapDirectBIToSetting = new Map<String, AccessControlSettings__c>();
            Map<String, AccessControlSettings__c> mapDirectBrandToSettingForLead = new Map<String, AccessControlSettings__c>();

            if (!mapOfACSettings.isEmpty()) {
                for (AccessControlSettings__c setting : mapOfACSettings.values()) {
                    allGroupsFromSetting.add(setting.Public_Group_Name__c);
                    if (setting.Brand__c != null && !setting.Direct_Non_GSP__c) {
                        otherBrandsFromSetting.add(setting.Brand__c);
                    }
                    if (setting.BusinessIdentity__c != null && !setting.Direct_Non_GSP__c) {
                        otherBIsFromSetting.add(setting.BusinessIdentity__c);
                    }
                    if (setting.Partner_ID__c != null) {
                        allPartnerIds.add(setting.Partner_ID__c);
                    }
                    if (setting.ParentBrand__c != null) {
                        parentFromSetting.add(setting.ParentBrand__c);
                    }
                    if (setting.isActive__c && !setting.Direct_Non_GSP__c) {
                        if (setting.Brand__c != null) {
                            mapBrandToSetting.put(setting.Brand__c, setting);
                            brandsFromSetting.add(setting.Brand__c);
                        }
                        if (setting.BusinessIdentity__c != null) {
                            mapBIToSetting.put(setting.BusinessIdentity__c, setting);
                            brandsFromSetting.add(setting.BusinessIdentity__c);
                        }
                        if (setting.Partner_ID__c != null) {
                            mapPIDToSetting.put(setting.Partner_ID__c, setting);
                            brandsFromSetting.add(setting.Partner_ID__c);
                        }
                    } else if (setting.isActive__c && setting.Direct_Non_GSP__c) {//10-29
                        if(setting.Identifier__c != null) {
                            mapBIdentifierToSetting.put(setting.Identifier__c, setting);//10-13
                        	allIdentifiers.add(setting.Identifier__c);//10-13
                        }
                        if(setting.Brand_ID__c != null && setting.isParent__c) {
                            mapBrandIdToSetting.put(setting.Brand_ID__c, setting);
                        }
                        if (setting.Brand__c != null && !setting.isParent__c) {
                            mapDirectBrandToSetting.put(setting.Brand__c, setting);
                        }
                        if (setting.Brand__c != null && setting.isParent__c) {
                            mapDirectBrandToSettingForLead.put(setting.Brand__c, setting);
                        }
                        if (setting.BusinessIdentity__c != null && setting.isParent__c){
                             mapDirectBIToSetting.put(setting.BusinessIdentity__c, setting);
                        }
                    }
                    nonGSPGroup = System.Label.Non_GSP_Public_Group;
                    allGroupsFromSetting.add(nonGSPGroup);
                    directGroup = System.Label.Direct_User_Group;
                    allGroupsFromSetting.add(directGroup);
                }
                this.mapBrandSetting = mapBrandToSetting;
                this.mapBISetting = mapBIToSetting;
                this.allBrands = brandsFromSetting;
                this.allGroups = allGroupsFromSetting;
                this.otherBrands = otherBrandsFromSetting;
                this.otherBIs = otherBIsFromSetting;
                this.nonGSPGroup = nonGSPGroup;
               	this.directGroup = directGroup;
                this.mapPIDSetting = mapPIDToSetting;
                this.allPartnerIds = allPartnerIds;
                this.parentFromSetting = parentFromSetting;
                this.mapBIdentifierSetting = mapBIdentifierToSetting;
                this.allIdentifiers = allIdentifiers;
                this.mapBrandIdSetting = mapBrandIdToSetting;
                this.mapDirectBrandSetting = mapDirectBrandToSetting;
                this.mapDirectBIToSetting = mapDirectBIToSetting;
                this.mapDirectBrandToSettingForLead = mapDirectBrandToSettingForLead;
            }
        }

        public Map<String, Id> getMapOfGroups(Set<String> allGroupsFromSetting) {
            mapGroups = new Map<String, Id>();
            if (!allGroupsFromSetting.isEmpty()) {
                for (Group grp : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN: allGroupsFromSetting AND Type = 'Regular' AND Name != null]) {
                    mapGroups.put(grp.DeveloperName, grp.Id);
                }
            }
            return mapGroups;
        }
    }

    public static Boolean onlyProServQuotesAvailable(Opportunity opp) {
        GSPPartnerSetup gspPartnerSetup = new GSPPartnerSetup(opp);
        return gspPartnerSetup.exist()
            && gspPartnerSetup.isDisableCommercialQuoting
            && !gspPartnerSetup.isDisableProServ;
    }

    public static Boolean oppTeamMembersWithSERole(String oppId) {
        return oppTeamMembersWithRole(oppId, 'Solutions Engineer (Primary)');
    }

    public static Boolean oppTeamMembersWithCESERole(String oppId) {
        return oppTeamMembersWithRole(oppId, 'Customer Experience SE');
    }

    private static Boolean oppTeamMembersWithRole(String oppId, String roleName) {
        List<String> oppIdSet = new List<String>{oppId};  
        List<String> teamRolesList = new List<String>{roleName};
                
        List<OpportunityTeamMember> oppTeamMembersList = (List<OpportunityTeamMember>) new OpportunityTeamMemberSelector()
                .selectByOpportunityIdsAndRoles(new List<Object> {oppIdSet, teamRolesList})
                .executeQuery();
        
        return !oppTeamMembersList.isEmpty();
    }
}