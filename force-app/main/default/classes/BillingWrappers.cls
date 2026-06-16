public class BillingWrappers {

    public static final Integer DISCOUNT_START_DATE_OFFSET = -2;

    public static final String BILLING_CHARGE_TERM_ONE_TIME = 'OneTime';

    public static final String OPPORTUNITY_TYPE_ACCOUNT_TERMINATION = 'Account Termination';

    public static final String SHIPPING_LABEL_VALUE_AUTO = 'auto';
    public static final String SHIPPING_LABEL_VALUE_MANUAL = 'manual';

    public static final String SUPPORT_TYPE_LABEL_NAME = 'support_type';

    public static final String DATE_TIME_FORMAT = 'yyyyMMddhhmmss';

    //Account Info
    public class NGBSAccount {
        public String id;
        public String status;
        public NGBSAccountPackage[] packages;

        // This method is deprecated, please use getPackageById() instead
        // Or for POC case when there is only one package under NGBS Account
        public NGBSAccountPackage getPackage() {
            return packages?.get(0);
        }

        public NGBSAccountPackage getPackageById(String packageId) {
            if (String.isBlank(packageId) || packages == null || packages.isEmpty()) {
                return null;
            }

            for (NGBSAccountPackage ngbsAccPackage : packages) {
                if (ngbsAccPackage.id == packageId) {
                    return ngbsAccPackage;
                }
            }
            return null;
        }
    }

    public class NGBSPackage {
        public String id;
        public String offerType;
        public String catalogId;
        public String version;
        public String currencyCode;
        public NGBSLicense[] licenses;
        public BillingLabels labels;

        public Boolean isPOC() {
            return offerType == QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        }
        public Boolean isRegular() {
            return offerType == 'Regular';
        }

        public List<GlobalPackageLimits> globalPackageLimits;

        public Boolean isAboutToExpire(Boolean isNewBusiness, Boolean isPartner) {
            String label = this.labels.getLabel(isNewBusiness, isPartner);
            return label?.replace(' ', '') == EXPIRATION_TYPE_ABOUT_TO_EXPIRE.replace(' ', '');
        }
        public Boolean isExpired(Boolean isNewBusiness, Boolean isPartner) {
            String label = this.labels.getLabel(isNewBusiness, isPartner);
            return isNewBusiness
                ? (String.isBlank(label) || label == EXPIRATION_TYPE_EXPIRED)
                : label == EXPIRATION_TYPE_EXPIRED;
        }
    }

    public class SearchPackagesParams {
        public List<Integer> businessIdentityIds;
        public Boolean isVersioned;
        public List<String> currencyIds;
        public Map<String, List<String>> labels;
        public String productName;
    }

    public class NGBSAccountPackage {
        public String id;
        public String offerType;
        public String catalogId;
        public String version;
        public String currencyCode;
        public NGBSLicense[] licenses;
        public BillingLabels labels;
        public String masterDuration;
        public String status;
        public String product;

        public Boolean isPOC() {
            return offerType == QuoteHelper.PACKAGE_OFFER_TYPE_POC;
        }
        public Boolean isRegular() {
            return offerType == 'Regular';
        }
        public Boolean isActive() {
            return status == 'Active';
        }

        public Boolean isActiveRegular() {
            return isActive() && isRegular();
        }
    }

    public class NGBSLicense {
        public String id;
        public String catalogId;
        public String billingType;
        public String description;
        public String billingCycleDuration;
        public Integer qty;
        public NGBSLicense[] subLicenses;
        public Boolean scheduledForRemoval;
        public Boolean batch;
    }

    public class BillingDiscount {
        public Decimal value;
        public String type;
    }

    public class BusinessIdentities {
        public BusinessIdentity defaultBi;
        public BusinessIdentity selectedBi;
        public BusinessIdentity approvedBi;
    }

    public class BusinessIdentity {
        public String id;
        public String name;
        public BIAddress address;
        public Boolean isDefault;
    }

    public class QuoteBusinessIdentity {
        public String biId;
        public String biCurrency;

        public QuoteBusinessIdentity(String biId, String biCurrency) {
            this.biId = biId;
            this.biCurrency = biCurrency;
        }
    }

    public class BIAddress {
        public String label;
        public String firstName;
        public String lastName;
        public String phone;
        public String street1;
        public String street2;
        public String city;
        public String county;
        public String state;
        public String zip;
        public String country;
    }

    public class LicensesRequestBody {
        public String catalogId;

        public LicensesRequestBody(String catalogId) {
            this.catalogId = catalogId;
        }
    }

    public class LicensesCounterResponse {
        public String catalogId {get;set;}
        public String categoryId {get;set;}
        public Integer billingCodeId {get;set;}
        public Integer batchQty {get;set;}
        public Integer instanceQty {get;set;}
    }

    public static final String SIGNUP_SFDC = 'SIGNUP_SFDC';
    public static final String SIGNUP_SFDCVAR = 'SIGNUP_SFDCVAR';
    public static final String EXPIRATION_TYPE_ACTIVE = 'Active';
    public static final String EXPIRATION_TYPE_ACTIVE_TESTING = 'Active Testing';
    public static final String EXPIRATION_TYPE_EXPIRED = 'Expired';
    public static final String EXPIRATION_TYPE_ABOUT_TO_EXPIRE = 'About to Expire';
    public static final String EXPIRATION_TYPE_NOT_EXPIRED = 'Not Expired';

    public class BillingLabels {
        public List<String> signup_sfdc;
        public List<String> signup_sfdcvar;
        public List<String> upgradeWizardExpiration;

        public String getLabel(Boolean isNewBusiness, Boolean isPartner) {
            String result = this.upgradeWizardExpiration?.get(0);
            if (isNewBusiness) {
                result = isPartner ? this.signup_sfdcvar?.get(0) : this.signup_sfdc?.get(0);
            }
            return result;
        }
    }

    public class BillingInfo {
        public Integer accountId;
        public Integer packageId;
        public String packageDescription;
        public String productLine;
        public String nextBillingDate;
        public Integer creditBalance;
        public List<License> licenses;
        public Object packageDuration;
        public Object packageExpirationDate;
    }

    public class BillingInfoLicenses {
        public String accountId;
        public String packageId;
        public String packageDescription;
        public String productLine;
        public String nextBillingDate;
        public Integer creditBalance;
        public List<LicenseRequested> licenses;
        public Object packageDuration;
        public Object packageExpirationDate;

        public BillingInfoLicenses(Map<String, Object> deserializedData) {
            if (!deserializedData.isEmpty()) {
                this.accountId = String.valueOf(deserializedData.get('accountId'));
                this.packageId = String.valueOf(deserializedData.get('packageId'));
                this.packageDescription = String.valueOf(deserializedData.get('packageDescription'));
                this.productLine = String.valueOf(deserializedData.get('productLine'));
                this.nextBillingDate = String.valueOf(deserializedData.get('nextBillingDate'));
                this.creditBalance = Integer.valueOf(deserializedData.get('creditBalance'));
                this.packageDuration = deserializedData.get('packageDuration');
                this.packageExpirationDate = String.valueOf(deserializedData.get('packageExpirationDate'));
                List<LicenseRequested> licenses = new List<LicenseRequested>();
                for (Object dd : (List<Object>) deserializedData.get('licenses')) {
                    Map<String, Object> license = (Map<String, Object>) dd;
                    LicenseRequested lr = new LicenseRequested(license);
                    licenses.add(lr);
                }
                this.licenses = licenses;
            }
        }
    }

    public class BillingInfo2 {
        public String accountId;
        public String packageId;
        public String packageDescription;
        public String productLine;
        public String nextBillingDate;
        public Decimal creditBalance;
        public List<LicenseRequested2> licenses;
        public PackageDuration2 packageDuration;
        public String packageExpirationDate;
        public String product;
    }

    public class PackageDuration2 {
        public String unit;
        public Integer value;
    }

    public class License {
        public Integer licenseId;
        public String catalogId;
        public String categoryId;
        public String description;
        public String billingCycleDuration;
        public Integer qty;
        public Double price;
        public String billingStartDate;
        public String billingEndDate;
        public Boolean scheduledForRemoval;
        public Object replacement;
        public Discount discount;
        public LicenseLabels labels;
    }

    public class LicenseLabels {
        public String GOA;
        public String serviceCategory;
    }

    public class LicenseRequested {
        public String licenseId;
        public String topLicenseId;
        public String catalogId;
        public String categoryId;
        public String description;
        public String billingCycleDuration;
        public Integer qty;
        public Double price;
        public String billingStartDate;
        public Boolean batch;
        public String billingEndDate;
        public String licenseTypeId;
        public Boolean scheduledForRemoval;
        public Object replacement;
        public Discount discount;

        public LicenseRequested(Map<String, Object> deserializedData) {
            if (!deserializedData.isEmpty()) {
                this.licenseId = String.valueOf(deserializedData.get('licenseId'));
                this.topLicenseId = String.valueOf(deserializedData.get('topLicenseId'));
                this.catalogId = String.valueOf(deserializedData.get('catalogId'));
                this.categoryId = String.valueOf(deserializedData.get('categoryId'));
                this.description = String.valueOf(deserializedData.get('description'));
                this.billingCycleDuration = String.valueOf(deserializedData.get('billingCycleDuration'));
                this.qty = Integer.valueOf(deserializedData.get('qty'));
                this.price = Double.valueOf(deserializedData.get('price'));
                this.billingStartDate = String.valueOf(deserializedData.get('billingStartDate'));
                if (deserializedData.get('batch') != null) {
                    this.batch = Boolean.valueOf(deserializedData.get('batch'));
                }
                this.billingEndDate = String.valueOf(deserializedData.get('billingEndDate'));
                if (deserializedData.get('scheduledForRemoval') != null) {
                    this.scheduledForRemoval = Boolean.valueOf(deserializedData.get('scheduledForRemoval'));
                }
                if (deserializedData.get('props') != null) {
                    Map<String, Object> licenseId = (Map<String, Object>) deserializedData.get('props');
                    if (licenseId.containsKey('LicenseTypeId')) {
                        this.licenseTypeId = String.valueOf(licenseId.get('LicenseTypeId'));
                    }
                }
                this.replacement = String.valueOf(deserializedData.get('replacement'));
                this.discount = deserializedData.get('discount') != null ? (Discount) JSON.deserialize(String.valueOf(JSON.serialize(deserializedData.get('discount'))), Discount.class): null;
            }
        }
    }

    public class LicenseRequested2 {
        public String licenseId;
        public String topLicenseId;
        public String catalogId;
        public String categoryId;
        public String description;
        public String billingCycleDuration;
        public Integer qty;
        public Double price;
        public String billingStartDate;
        public String billingEndDate;
        public Boolean scheduledForRemoval;
        public String activeState;
        public String billingType;
        public Boolean batch;
        public LicenseLabels2 labels;
        public Discount discount;

        public LicenseRequested2(String catalogId, String licenseId, Boolean scheduledForRemoval) {
            this.catalogId = catalogId;
            this.licenseId = licenseId;
            this.scheduledForRemoval = scheduledForRemoval;
        }
    }

    public class LicenseLabels2 {
        public String[] quotingGroup;
        public String[] GOA;
        public String[] quotingSubGroup;
    }

    public class BillingInfoSummaryLicense {
        public Double amount;
        public String catalogId;
        public Double discountAmount;
        public DiscountValue discountValue;
        public Integer qty;
        public String billingType;
        public String billingCycleDuration;
        public String dateRangeStart;
        public String dateRangeEnd;
        public String description;
        public String descriptionKey;
        public Boolean scheduledForRemoval;
    }

    public class BillingLicense {
        public String elementID;
        public BillingPlan[] billingPlan;
    }

    public class BillingPlan {
        public String duration;
        public String delayRemoval;
    }

    public class Discount {
        public DiscountValue value;
    }

    //Contract && Billing Info
    public class GWContract {
        public String name;
        public Date startDate;
        public Decimal term;
        public String duration;
        public String description;
        public String packageVersion;
        public List<String> licences;
        public List<GWDiscount> discounts;
        public List<String> availableInPackages;
        public List<String> billingCountries;
        public List<String> businessIdentitiesCountries;
        public String id;
        public String extId;
        public Boolean isActive;

        public GWContract() {
            licences = new List<String>();
            discounts = new List<GWDiscount>();
        }
    }

    public class GWDiscount {
        public String id;
        public String description;
        public String priority;
        public String promoCode;
        public Boolean visible;
        public Datetime addedAt;
        public List<GWDiscountTemplate> discountTemplates;
        public DiscountTarget target;

        public GWDiscount() {
            description = 'discount description';
            priority = 'A';
            visible = true;
            discountTemplates = new List<GWDiscountTemplate>();
            target = new DiscountTarget();
        }
    }

    public class GWDiscountTemplate {
        public Decimal id;
        public String description;
        public GWTemplateApplication applicableTo;
        public GWTemplateApplicationTerms applicationTerms;
        public Map<String, GWDiscountValue> values;

        public GWDiscountTemplate() {
            description = 'discount template';
            applicableTo = new GWTemplateApplication();
            applicationTerms = new GWTemplateApplicationTerms();
            values = new Map<String, GWDiscountValue>();
        }
    }

    public class GWTemplateApplication {
        public String type;
        public String id;

        public GWTemplateApplication() {
            type = 'CatalogId';
        }
    }

    public class GWTemplateApplicationTerms {
        public Datetime startDate;
        public Datetime endDate;
        public String licenseScope;
        public String maxLicenses;

        public GWTemplateApplicationTerms() {
            startDate = System.today().addMonths(-1);
            endDate = null;
            licenseScope = 'All';
        }
    }

    public class GWDiscountValue {
        public String unit;
        public Decimal value;
        public GWRecurringTerms recurringTerms;

        public GWDiscountValue() {
            unit = 'Money';
        }
    }

    public class GWRecurringTerms {
        public String unit;
        public Decimal value;

        public GWRecurringTerms() {
            unit = 'Months';
            value = 1;
        }
    }

    public class DiscountTarget {
        public String catalogId;
        public String version;
    }

    //Package Info on Quote
    public class QuotePackageInfoWrapper {
        private List<QuotePackageInfo> packagesInfo;

        public QuotePackageInfoWrapper() {}

        public QuotePackageInfoWrapper(String packagesInfo) {
            this.packagesInfo = parseQuotePackageInfo(packagesInfo);
        }

        public QuotePackageInfo getPackageInfo() {
            return this.packagesInfo[0];
        }

        public Boolean isMP() {
            return this.packagesInfo.size() > 1;
        }

        public void setPackageInfo(QuotePackageInfo pInfo) {
            this.packagesInfo = new List<QuotePackageInfo>{pInfo};
        }

        public List<QuotePackageInfo> parseQuotePackageInfo(String packagesInfo) {
            List<QuotePackageInfo> result = null;
            try {
                result = (List<QuotePackageInfo>) JSON.deserialize(packagesInfo, List<QuotePackageInfo>.class);
            } catch (Exception e) {
                AquivaHelper.throwAquivaException(
                    String.format('Failed to parse packagesInfo ({0})', new List<Object>{e.getMessage()})
                );
            }
            return result;
        }

        override public String toString() {
            return JSON.serialize(this.packagesInfo);
        }

    }

    public class QuotePackageInfo {

        // TODO depricate
        public String id;
        public String version;

        // TODO make main
        public PackageInfo packageInfo;

        public String productName;
        public String productId;
        public String duration;
        public String permissions;
        public String offerType;
        public Trial trial;
        public POC poc;
        public Contract contract;
        public List<GlobalPackageLimits> globalPackageLimits;
        public Edition edition;
        public BusinessIdentities packageBusinessIdentities;
        public ExistingPackageInfo existingPackageInfo;
        public PartnerPackageInfo partnerPackage;
        public PreferredLanguage preferredLanguage;

        public QuotePackageInfo() {
            packageInfo = new PackageInfo();
            trial = new Trial();
            contract = new Contract();
            globalPackageLimits = new List<GlobalPackageLimits>();
            edition = new Edition();
            packageBusinessIdentities = new BusinessIdentities();
        }

        public Boolean isPOC() {
            return QuoteHelper.OFFER_TYPE_POC.equalsIgnoreCase(offerType);
        }
    }

    public class BillingContract {
        public String id;
        public Integer startBillingCycleNumber;
        public Integer term;
        public Integer renewalTerm;
        public Date startDate;
        public String description;
        public FunnelPackage[] packages;

        public Boolean isActiveContract() {
            if (startBillingCycleNumber == null) {
                return false;
            }

            if (startBillingCycleNumber < 0) {
                return false;
            }

            return true;
        }

        public Date getEndDate() {
            return startDate != null && term != null
                ? startDate.addMonths(term)
                : null;
        }

        public Boolean isDateInContract(Date dateToCheck) {
            return (dateToCheck == null || getEndDate() == null)
                ? null
                : dateToCheck >= startDate && dateToCheck <= getEndDate();
        }
    }

    public static List<BillingWrappers.BillingContract> findActiveContracts(List<BillingWrappers.BillingContract> billingContracts) {

        if (billingContracts == null || billingContracts.isEmpty()) {
            return null;
        }

        List<BillingWrappers.BillingContract> activeContracts = new List<BillingWrappers.BillingContract>();

        for (BillingWrappers.BillingContract contract : billingContracts) {
            if (contract.isActiveContract()) {
                activeContracts.add(contract);
            }
        }

        return activeContracts;
    }

    public static BillingWrappers.BillingContract findClosestContractToDate(List<BillingWrappers.BillingContract> billingContracts, Date quoteStartDate) {

        if (billingContracts == null || billingContracts.isEmpty() || quoteStartDate == null) {
            return null;
        }

        BillingWrappers.BillingContract closestActiveContract = null;

        for (BillingWrappers.BillingContract contract : billingContracts) {
            if (contract.isDateInContract(quoteStartDate) != null && contract.isDateInContract(quoteStartDate)) {
                closestActiveContract = contract;
            }
        }

        if (closestActiveContract == null) {
            for (BillingWrappers.BillingContract contract : billingContracts) {

                Boolean isContractStartDateCloser = (contract.startDate > quoteStartDate &&
                    (closestActiveContract == null || contract.startDate < closestActiveContract.startDate));

                if (isContractStartDateCloser) {
                    closestActiveContract = contract;
                }
            }
        }

        return closestActiveContract;
    }

    /*
        @deprecated - Use QuotePackageInfoWrapper.parseQuotePackageInfo
    */
    public static QuotePackageInfo parseQuotePackageInfo(String packageInfo){
        QuotePackageInfo result = null;
        List<QuotePackageInfo> pInfos = (List<QuotePackageInfo>)
            JSON.deserialize(packageInfo, List<QuotePackageInfo>.class);
        if (pInfos.size() > 0) {
            result = pInfos[0];
        }
        return result;
    }

    public static QLIPackageInfo parseQLIPackageInfo(String packageInfo) {
        try {
            return (QLIPackageInfo) JSON.deserialize(packageInfo, QLIPackageInfo.class);
        } catch(Exception e) {
            System.debug(LoggingLevel.Error, 'Incorrect JSON payload in QLI PackageInfo__c field: ' + e.getMessage());
            return null;
        }
    }

    public static String getShortQLIPackageInfo(String packageInfoJson) {
        if (String.isBlank(packageInfoJson)) {
            return '';
        }
        QLIPackageInfo packageInfo = parseQLIPackageInfo(packageInfoJson);
        packageInfo.lbox = null;
        packageInfo.lboxes = null;
        packageInfo.originalDiscount = null;
        packageInfo.partnerInfo = null;
        packageInfo.isPhoneLeasingEnabled = null;
        packageInfo.targetPriceCalculations = null;

        return JSON.serialize(packageInfo, true);
    }

    public class Trial {
        public String id;
        public String version;
        public String offerType;
        public String name;
        public Integer duration;
        public String durationUnits;
    }

    public class POC {
        public String catalogId;
        public String version;
    }

    public class PackageInfo {
        public String id;
        public String catalogId;
        public String version;
        public String name;
        public String displayName;
        public String oldPackageName;
    }

    public class ExistingPackageInfo {
        public String id;
        public String version;
        public String offerType;
        public String productName;
    }

    public class PartnerPackageInfo {
        public String id;
        public Decimal version;
        public String settlementType;
    }

    public class Contract {
        public String id;
        public String extId;
        public String billingId;
        public String status;
    }

    public class GlobalPackageLimits {
        public String value;
        public String code;
        public String name;
        public String limitType;
        public String scope;
        public String transactionType;
        public String target;
        public String isOverride;
    }

    public class NGBSPackageLimit {
        public String id;
        public Integer value;
        public String overriddenLimitId;
        public NGBSPackageLimit limitOverride;
    }

    public class Edition {
        public String id;
        public String name;
    }

    public class PreferredLanguage {
        public String localeCode;
        public Integer languageId;
    }

    //Discount template groups for sign up
    public class DiscountPromoType {
        public Integer id;

        public DiscountPromoType(){
            id = 2;
        }
    }

    public class DiscountAvailability{
        public String type;
        public String availableTo;

        public DiscountAvailability(String opptyId){
            type='Opportunity';
            availableTo=String.valueOf(opptyId);

        }
    }

    public class DiscountTemplateGroup {
        public String id;
        public String name;
        public DiscountTemplate[] discountTemplates;

        public DiscountPromoType promoType;
        public DiscountAvailability[] availability;
        public String promoCode;
        public String description;
        public String startDate;
        public String endDate;
        public String priority;
        public DiscountTarget target;

        public DiscountTemplateGroup(String opptyId) {
            discountTemplates = new List<DiscountTemplate>();
            promoType = new DiscountPromoType();
            availability=new DiscountAvailability[]{new DiscountAvailability(opptyId)};
            Datetime dtn = Datetime.now().addDays(DISCOUNT_START_DATE_OFFSET);
            promoCode = String.valueOf(opptyId) + dtn.format(DATE_TIME_FORMAT);
            startDate = getUTCDateTimeStr(dtn);
            endDate = getUTCDateTimeStr(dtn.addYears(300));
            priority = 'Z';
            target = new DiscountTarget();
        }

        public String getUTCDateTimeStr(Datetime dt) {
            return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');
        }
    }

    public class DiscountTemplate {
        public String id;
        public String name;
        public String description;
        public DiscountApplication applicableTo;
        public DiscountApplicationTerms applicationTerms;
        public Map<String, DiscountValue> values;

        public DiscountTemplate() {
            applicableTo = new DiscountApplication();
            applicationTerms = new DiscountApplicationTerms();
            values = new Map<String, DiscountValue>();
        }
    }

    public class DiscountApplication {
        public String type;
        public String id;
    }

    public class DiscountApplicationTerms {
        public String licenseScope;
        public Decimal licenseCount;
    }

    public class DiscountValue {
        public String unit;
        public Decimal value;
        public DiscountRecurringTerms recurringTerms;

        public DiscountValue() {
            recurringTerms = new DiscountRecurringTerms();
        }
    }

    public class DiscountRecurringTerms {
        public String unit;
        public Decimal value;
    }

    public class QLIPackageInfo {
        public String id;
        public String version;
        public String duration;
        public String categoryCode;
        public Decimal price;
        public QLIPackageInfoDiscount discount;
        public LBox lbox;
        public List<LBox> lboxes;
        public String categoryPath;
        public String parent;
        public QLIPackageInfoOriginalDiscount originalDiscount;
        public QLIPartnerInfo partnerInfo;
        public String isCore;

        /* ContractualQty - temporary name until change field type */
        public Integer q;

        public Integer isPhoneLeasingEnabled;
        public TargetPriceCalculations targetPriceCalculations;

        public QLIPackageInfo() {}

        public QLIPackageInfo(String pInfo) {
            try {
                QLIPackageInfo result   = (QLIPackageInfo) JSON.deserialize(pInfo, QLIPackageInfo.class);
                this.id                 = result.id;
                this.version            = result.version;
                this.duration           = result.duration;
                this.categoryCode       = result.categoryCode;
                this.price              = result.price;
                this.discount           = (result.discount != null) ? result.discount : new QLIPackageInfoDiscount();
                this.categoryPath       = result.categoryPath;
                this.parent             = result.parent;
                this.originalDiscount   = result.originalDiscount;
                this.isCore             = result.isCore;

                if (result.lbox != null) {
                    this.lbox = new LBox(
                        result.lbox.elementID,
                        result.lbox.min,
                        result.lbox.max
                    );
                }
                if (result.lboxes != null && !result.lboxes.isEmpty()) {
                    this.lboxes = result.lboxes;
                }
                this.targetPriceCalculations = result.targetPriceCalculations;
            } catch(Exception e) {
                throw new DmlException(e.getMessage() + e.getStackTraceString());
            }
        }

        public String getBillingDuration() {
            if (this.duration == Product2Helper.CHARGE_TERM_ONE_TIME) {
                return BILLING_CHARGE_TERM_ONE_TIME;
            }
            return this.duration;
        }

        public Boolean isCommissionable() {
            return this.partnerInfo != null;
        }
    }

    public class TargetPriceCalculations {
        public String targetPrice;
        public Decimal recommendedDiscount;
    }

    public class QLIPackageInfoDiscount {
        public String Type;
        public Decimal Value;
    }

    public class QLIPackageInfoOriginalDiscount {
        public DiscountApplication applicableTo;
        public Map<String, BillingDiscount> values;
    }

    public class QLIPartnerInfo {
        public List<PartnerPackageLicenseBillingPlan> billingPlan;
    }

    public class BillingProduct {
        public String catalogId {get;set;}
        public String categoryName {get;set;}
        public String currencyIsoCode {get;set;}
        public String displayName {get;set;}
        public String goa {get;set;}
        public String name {get;set;}
        public String categoryCode {get;set;}
        public String itemType {get;set;}
        public String billingType {get;set;}
        public String licenseGroup {get;set;}
        public String quotingGroup {get;set;}
        public String quotingSubGroup {get;set;}
        public String serviceCategory {get;set;}
        public String upsellType {get;set;}
        public String initialOrderType {get;set;}
        public String shippingType {get;set;}
        public String supportType {get;set;}
        public String downsellType {get;set;}
    }

    public class BillingEntitlement {
        public String elementId;
        public String name;
        public Integer quantity;
        public Decimal unitPrice;
        public Decimal effectivePrice;
        public String duration;
        public BillingDiscount discount;
        public NGBSAccountPackage billingPackage;
        public String displayName;
        public Integer sortOrder;
        public Boolean isPrimaryLicenseType;
        public String partnerConfig;
    }

    public class PartnerPackageConfig {
        public String partnerPackageId;
        public Decimal partnerPackageVersion;
        public PartnerPackageLicenseBillingPlan[] billingPlan;
        public Decimal ngbsPartnerId;
    }

    public class PartnerPackageLicenseBillingPlan {
        public String duration;
        public PartnerPackageLicenseBillingPlanRater wholesaleRater;
        public PartnerPackageLicenseBillingPlanRater revShareRater;
        public String startDate;
    }

    public class PartnerPackageLicenseBillingPlanRater {
        public String type;
        public String config;
    }

    public class PartnerPackageLicenseBillingPlanRaterConfig {
        public Double fromQuantity;
        public Double toQuantity;
        public String value;
    }

    public class CartItem {
        public String catalogId {get;set;}
        public String name {get;set;}
        public String billingCycleDuration {get;set;}
        public Integer quantity {get;set;}
        public Decimal unitPrice {get;set;}
        public Decimal discount {get;set;}
        public String discountType {get;set;}
        public String currencyIsoCode {get;set;}
        public String packageInfo {get;set;}
        public String id {get;set;}
        public Boolean isDeleted {get;set;}
        public String itemType {get;set;}
        public String guid {get;set;}
        public String goa {get;set;}
        public String displayName {get;set;}
        public Integer sortOrder {get;set;}
        public PackageInfo billingPackage {get;set;}
        public DateTime salesEndDate {get;set;}
        public String billingType {get;set;}
        public String sfPromoCodeId {get;set;}
        public String productName {get;set;}
    }

    public class AreaCodeLineItem {
        public String id {get;set;}
        public String cartItemCatalogId {get;set;}
        public Integer quantity {get;set;}
        public String areaCodeId {get;set;}
        public Boolean isDeleted {get;set;}
        public AreaCodeData areaCodeInfo {get;set;}
    }

    public class AreaCodeData {
        public String country {get;set;}
        public String state {get;set;}
        public String city {get;set;}
        public String type {get;set;}
        public Integer areaCode {get;set;}
    }

    public class Promotion {
        public String id {get;set;}
        public String promoCodeId {get;set;}
        public String promoCode {get;set;}
        public String name {get;set;}
        public String discountTemplates {get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        public String description {get;set;}
        public String quoteId {get;set;}
        public String priority {get;set;}
    }

    public class GOA {
        public String regular;
        public String contracted;
    }

    public class ApprovalParams {
        @AuraEnabled
        public String accountId {get;set;}
        public String masterAccountId {get;set;}
        public AccountPartner accountPartner {get;set;}
        @AuraEnabled
        public String accountPartnerId {get;set;}
        @AuraEnabled
        public String action {get;set;}
        @AuraEnabled
        public String recordType {get;set;}
    }

    public class AccountPartner {
        public String id;
        public String name;
        public String partnerId;
        public String partnerType;
        public String ultimatePartnerName;
    }

    public class Params {
        public String action {get;set;}

        public String opportunityId {get;set;}
        public String selectedQuoteId {get;set;}
        public String recordType {get;set;}
        public String quoteId {get;set;}
        public String templateId {get;set;}
        public Map<String, String> templateParameters {get;set;}
        public String initialTerm {get;set;}
        public String renewalTerm {get;set;}
        public String initialTermCC {get;set;}
        public String specialTerms {get;set;}
        public Boolean updateContractTerms {get;set;}
        public String specialTermsCC {get;set;}
        public String freeShippingTerms {get;set;}
        public String accountId {get;set;}

        public String packageInfo {get;set;}
        public String subAction {get;set;}
        public String actionComment {get;set;}
        public String status {get;set;}
        public String brand {get;set;}
        public String subBrand {get;set;}

        public QuoteWrapper quote {get;set;}
        public List<CartItem> items {get;set;}
        public List<AreaCodeLineItem> areaCodeLineItems {get;set;}
        public List<BillingEntitlement> entitlements {get;set;}
        public List<BillingProduct> products {get;set;}
        public Map<String, String> qliMap {get;set;}

        public Map<String,String> data {get;set;}
        public List<StepUp> stepUps {get;set;}
        public Boolean isUserCanApprove {get;set;}
        public Boolean isWizardHasErrors {get;set;}
        public Boolean enabledLBO {get;set;}
        public Boolean isPrimaryQuote {get;set;}
        public Boolean isRemoveAreaCodes {get;set;}
        public Boolean isPRMQuote {get;set;}
        public Boolean hasRCCC {get;set;}

        public List<BillingCode> billingCodes {get;set;}

        public List<Id> selectedDocsIds {get;set;}
        public TaxLocationsResponse taxLocations {get;set;}

        // single area code sync parameter
        public AreaCodeData areaCodeItem {get;set;}

        // docusign status override envelope id
        public Id envelopeId {get;set;}
        // set of parent quote Ids
        public Set<Id> quoteIdSet {get;set;}
        public List<Promotion> promotionList {get;set;}
        public String paymentMethod {get;set;}

        public ApprovalParams approvalParams {get;set;}
        public String partnerInfo {get;set;}
        public DQApprover dqApprover {get;set;}
        public String dqAction {get;set;}

        public List<String> serviceNames {get;set;}
        public Map<String, BillingWrappers.CartItem[]> cartItemsByService {get;set;}
        public Map<String, BillingWrappers.QuoteWrapper> quotesByService {get;set;}
        public String masterQuoteId {get;set;}
        public String dataRetentionDuration {get;set;}
        public Set<String> catalogIds {get;set;}
        public Map<String, Boolean> terminationMap {get;set;}

        //populating during the change order initialization process for Proserv
        public Id orderId {get;set;}
        public Boolean isProServChangeOrderOpp {get;set;}
        public NGBSAccountPackage proServPackage {get;set;}
    }

    public class ParamsShipping {
        public String action {get;set;}

        public String selectedQuoteId {get;set;}
        public String opportunityId {get;set;}
        public Map<String, List<ShippingItemsInfo>> shippingItemsMap {get;set;}
    }

    public class ShippingItemsInfo {
        public ShippingLocation location {get;set;}
        public String locationID {get;set;}
        public String junctionID {get;set;}
        public Integer quantity {get;set;}
        public Boolean isDeleted {get;set;}
        public String quoteLineItemId {get;set;}
        public String assignmentLineItemId {get;set;}
        public String deviceUniqId {get;set;}
        public String qliProductId {get;set;}
    }

    public class ShippingLocation {
        public ShippingAddress address {get;set;}
        public String attentionTo {get;set;}
        public String id {get;set;}
        public String shippingMethod {get;set;}
        public String shippingLicensesTree {get;set;}
        public String shippingBillingCodeId {get;set;}
    }

    public class ShippingAddress {
        public String additionalAddressLine {get;set;}
        public String addressLine {get;set;}
        public String city {get;set;}
        public String country {get;set;}
        public String state {get;set;}
        public String zipCode {get;set;}
        public String id {get;set;}
    }

    public class TaxLocationsResponse {
        public List<Address> addresses {get;set;}
    }

    public class StepUp {
        public String stepUpDate {get;set;}
        public Decimal stepDLs {get;set;}
    }

    public class Data {
        public BillingCode[] Data {get;set;}
    }

    public class QuoteWrapper {
        public String id {get;set;}
        public String packageInfo {get;set;}
        public String name {get;set;}
        public Decimal totalQuoteSummary {get;set;}
        public Decimal deltaMRR {get;set;}
        public Decimal deltaARR {get;set;}
        public String expirationDate {get;set;}
        public String quoteType {get;set;}
        public String status {get;set;}
        public String initialTerm {get;set;}
        public String initialTermPOC {get;set;}
        public String renewalTerm {get;set;}
        public Boolean autoRenewal {get;set;}
        public String startDate {get;set;}
        public String endDate {get;set;}
        public Boolean updateContractTerms {get;set;}
        public String specialTerms {get;set;}
        public String freeShippingTerms {get;set;}
        public String upsellStatus {get;set;}
        public Boolean isTaxesAdded {get;set;}
        public Boolean enabledLBO {get;set;}
        public Boolean isLBODealDeskProvision {get;set;}
        public Boolean isWizardHasErrors {get;set;}
        public Boolean doNotSendOrderToNGBS {get;set;}
        public String justification {get;set;}
        public String mainAreaCodeId {get;set;}
        public String faxAreaCodeId {get;set;}
        public String opportunityProvisioningDetails {get;set;}
        public String shippingShipAttentionTo {get;set;}
        public String shippingCountry {get;set;}
        public String shippingCity {get;set;}
        public String shippingState {get;set;}
        public String shippingAddressLine {get;set;}
        public String shippingPostalCode {get;set;}
        public String shippingAdditionalAddressLine {get;set;}
        public String shippingCustomerName {get;set;}
        public String shippingShippingOption {get;set;}
        public Boolean shippingMultipleLocations {get;set;}
        public Boolean opportunitySelfProvisioned {get;set;}
        public AreaCodeData faxAreaCodeInfo {get;set;}
        public AreaCodeData mainAreaCodeInfo {get;set;}
        public Decimal creditAmount {get;set;}
        public Decimal freeServiceTaxes {get;set;}
        public Boolean isFullCalculationFSC {get;set;}
        public Id parentQuoteId {get;set;}
        public String paymentMethod {get;set;}
        public String dataRetentionDuration {get;set;}
        public String rcAccountNumber {get;set;}
        public String ccAccountNumber {get;set;}
        public String noteToCustomer {get;set;}
        public Boolean isTerminationOpportunity {get;set;}
        public Decimal overallDiscretion {get;set;}
        public Decimal averageDiscount {get;set;}
        public Boolean isTermination {get;set;}
        public Boolean isDeselected {get;set;}
        public Decimal totalFirstYearCost {get;set;}
    }

    public class BillingCode {
        public String Id {get;set;}
        public String parentId {get;set;}
        public String guid {get;set;}
        public String parentXid {get;set;}
        public String billingId {get;set;}
        public String name {get;set;}
        public Decimal depth {get;set;}
        public String parentBillingId {get;set;}
        public String addressId {get;set;}
        public TaxLocation location {get;set;}
        public Bundle[] bundles {get;set;}
        public BillingCode[] child {get;set;}
        public String billingCodePath {get;set;}
    }

    public class Bundle {
        public String elementID {get;set;}
        public AreaCodeData areaCode {get;set;}
        public String areaCodeId {get;set;}
        public Integer qty {get;set;}
        public BundleItem[] licenses {get;set;}
        public String id {get;set;}
        public Integer sortOrder {get;set;}
        public String costCenterId {get;set;}

        public Bundle() {
            this.licenses = new List<BundleItem>();
        }
        public Bundle(Cost_Center_Line_Item__c costCenterLineItem) {
            this.costCenterId = costCenterLineItem.Cost_Center__c;
            this.id = costCenterLineItem.Id;
            this.elementID = costCenterLineItem.ElementId__c;
            this.areaCodeId = costCenterLineItem.AreaCode__c;
            if (costCenterLineItem.AreaCode__c != null) {
                AreaCodeData areaCode = new AreaCodeData();
                areaCode.country = costCenterLineItem.AreaCode__r.Country__c;
                areaCode.state = costCenterLineItem.AreaCode__r.State__c;
                areaCode.city = costCenterLineItem.AreaCode__r.City__c;
                areaCode.type = costCenterLineItem.AreaCode__r.Type__c;
                areaCode.areaCode = costCenterLineItem.AreaCode__r.Area_Code__c.intValue();

                this.areaCode = areaCode;
            }
            this.qty = costCenterLineItem.Quantity__c.intValue();
            if (costCenterLineItem.SortOrder__c != null) {
                this.sortOrder = costCenterLineItem.SortOrder__c.intValue();
            }
            this.licenses = new List<BundleItem>();
        }

        public Cost_Center_Line_Item__c buildCostCenterLineItem(Id costCenterId, QuoteLineItem qli, Id areaCodeId) {
            String name = qli != null ? qli.Product2.Name : this.elementID;
            Id qliId = qli != null ? qli.Id : null;
            String bundleElementId = buildBundleElementId(costCenterId);
            Cost_Center_Line_Item__c instance = new Cost_Center_Line_Item__c(
                Name = name.length() > 79 ? name.substring(0, 76) + '...' : name,
                Cost_Center__c = costCenterId,
                Quantity__c = this.qty,
                ElementId__c = this.elementID,
                BundleElementId__c = bundleElementId,
                Quote_Line_Item__c = qliId,
                AreaCode__c = areaCodeId,
                SortOrder__c = this.sortOrder
            );

            if (this.id != null) {
                instance.Id = this.id;
            }

            return instance;
        }

        public String buildBundleElementId(Id costCenterId) {
            String bundleElementId = '' + this.elementID;
            if (costCenterId != null) {
                bundleElementId += costCenterId;
            }
            if (this.areaCode != null) {
                bundleElementId += AreaCodeService.getAreaId(this.areaCode);
            }
            if (this.licenses == null) {
                return bundleElementId;
            }
            for (BillingWrappers.BundleItem license : this.licenses) {
                bundleElementId += license.elementID;
                bundleElementId += AreaCodeService.getAreaId(license.areaCode);
            }
            return bundleElementId;
        }
    }

    public class BundleItem {
        public String id {get;set;}
        public String elementID {get;set;}
        public AreaCodeData areaCode {get;set;}
        public String areaCodeId {get;set;}

        public BundleItem() {}
        public BundleItem(Cost_Center_Line_Item__c costCenterLineItem) {
            this.id = costCenterLineItem.Id;
            this.elementID = costCenterLineItem.ElementId__c;
            this.areaCodeId = costCenterLineItem.AreaCode__c;
            if (costCenterLineItem.AreaCode__c != null) {
                AreaCodeData areaCode = new AreaCodeData();
                areaCode.country = costCenterLineItem.AreaCode__r.Country__c;
                areaCode.state = costCenterLineItem.AreaCode__r.State__c;
                areaCode.city = costCenterLineItem.AreaCode__r.City__c;
                areaCode.type = costCenterLineItem.AreaCode__r.Type__c;
                areaCode.areaCode = costCenterLineItem.AreaCode__r.Area_Code__c.intValue();

                this.areaCode = areaCode;
            }
        }

        public Cost_Center_Line_Item__c buildCostCenterLineItem(Id costCenterId, Id parentId, QuoteLineItem qli, Id areaCodeId) {
            String name = qli != null ? qli.Product2.Name : this.elementID;
            Id qliId = qli != null ? qli.Id : null;
            Cost_Center_Line_Item__c instance = new Cost_Center_Line_Item__c(
                Name = name.length() > 79 ? name.substring(0, 76) + '...' : name,
                Cost_Center__c = costCenterId,
                Parent__c = parentId,
                ElementId__c = this.elementID,
                AreaCode__c = areaCodeId,
                Quote_Line_Item__c = qliId
            );

            if (this.id != null) {
                instance.Id = this.id;
            }

            return instance;
        }
    }

    public class TaxLocation {
        public String id {get;set;}
        public String label {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String phone {get;set;}
        public String street1 {get;set;}
        public String street2 {get;set;}
        public String county {get;set;}
        public String city {get;set;}
        public String state {get;set;}
        public String zip {get;set;}
        public String country {get;set;}

        public String hashCode() {
            String length = id + label + street1 + street2 + country + state;
            return label != null ? String.valueOf(label.charAt(0) * length.length() * 37) : '0';
        }
    }

    public class Address {
        public String id {get;set;}
        public String externalId {get;set;}
        public TaxLocation address {get;set;}
    }

    public class BillingArray {
        public BillingCode[] arrays;
    }

    public class LBox {
        public String elementID;
        public Decimal min;
        public Decimal max;

        public LBox() {}

        public LBox(String elementID, Decimal min, Decimal max) {
            this.elementID = elementID;
            this.min = min;
            this.max = max;
        }
    }

    public class OpportunityServiceParams {
        public String action {get;set;}
        public OpportunityWrapper opportunityWrapper {get;set;}
        public DQParams dealQualificationParams {get;set;}
        public String opportunityId {get;set;}
        public Map<String, Account> serviceAccounts {get;set;}
        public Map<String, BillingWrappers.QuoteWrapper> quotesByService {get;set;}
        public List<String> services;
    }

    public class AssignmentLineItem {
        public String id;
        public String parentId;
        public String childId;
        public String areaCodeId;
        public Decimal quantity;
        public Boolean isDelete;
        public AreaCodeData areaCodeInfo;
    }

    public class OpportunityWrapper {
        public String id;
        public String name;
        public String accId;
        public String accOwnerId;
        public String contId;
        public String conversionContId;
        public String contactRole;
        public String recordTypeId;
        public String leadSource;
        public String closedDate;
        public String currencyCode;

        public String type;
        public String service;
        public String brand;
        public String subBrand;
        public String provisioningDetails;
        public String selfProvisioned;
        public Integer newUsers;
        public String opportunityType;
        public Boolean isFedRamp;
        public Integer businessIdentityId;
        public String businessIdentityCurrency;
        public String fromContact;
        public String fromContactId;
        public String fromConversionContact;
        public String fromConversionContactId;
        public String contactCenterUsers;
        public String engageDigitalUsers;
        public String rcEventUsers;
        public String engageVoiceUsers;
        public String globalOfficeUsers;
        public String officeUsers;
        public String rcVideoUsers;
        public String oppCreationFlow;
        public String campaignId;
        public String parentOrderId;
        public Boolean isChnageOrder;

        public String quoteId;

        private Opportunity newOppty;

        public Opportunity createOpportunityRecord() {
            newOppty = new Opportunity(
                Name                            = this.name.length() > 119 ? this.name.substring(0, 119) : this.name,
                AccountId                       = this.accId,
                RecordTypeId                    = this.recordTypeId,
                LeadSource                      = this.leadSource,
                CloseDate                       = Date.valueOf(this.closedDate),
                Is_Billing_Opportunity__c       = true,
                StageName                       = '1. Qualify',
                Primary_Opportunity_Contact__c  = (this.fromContact == '1' && !this.fromContactId.equals(this.conversionContId)) ? this.fromContactId :
                                                  (this.fromContact == '1' && this.fromContactId.equals(this.conversionContId)) ? this.contId :this.contId,
                Conversion_Contact__c           = this.conversionContId,
                CurrencyIsoCode                 = this.currencyCode,
                Type                            = this.type,
                Tier_Name__c                    = this.service,
                Brand_Name__c                   = this.brand,
                Sub_Brand__c                    = this.subBrand,
                ProvisioningDetails__c          = this.provisioningDetails,
                SelfProvisioned__c              = this.selfProvisioned == null
                                                    ? false
                                                    : Boolean.valueOf(this.selfProvisioned),

                ForcastedDimeloUsers__c         = this.fromContact == '1' && this.engageDigitalUsers != 'null' ? Decimal.ValueOf(this.engageDigitalUsers) : OpportunityHelper.getForecastedDigitalUsers(this.service, this.newUsers),
                Forecast_Connect_First_Users__c = this.fromContact == '1' && this.engageVoiceUsers != 'null' ? Decimal.ValueOf(this.engageVoiceUsers) : OpportunityHelper.getForecastedVoiceUsers(this.service, this.newUsers),
                Forecasted_Users__c             = this.fromContact == '1' && this.officeUsers != 'null' ? Decimal.ValueOf(this.officeUsers) : OpportunityHelper.getForecastedOfficeUsers(this.service, this.newUsers),
                Forecast_Contact_Center_Users__c = this.fromContact == '1' && this.contactCenterUsers != 'null' ? Decimal.ValueOf(this.contactCenterUsers) : OpportunityHelper.getForecastedRCCCUsers(this.service, this.newUsers),
                Forecasted_Events_Users__c      = this.fromContact == '1' && this.rcEventUsers != 'null' ? Decimal.ValueOf(this.rcEventUsers) : OpportunityHelper.getForecastedRCEventUsers(this.service, this.newUsers),
                Forecasted_Global_Office_Users__c = this.fromContact == '1' && this.globalOfficeUsers != 'null' ? Decimal.ValueOf(this.globalOfficeUsers) : null,
                Forecasted_RingCentral_Video_Users__c = this.fromContact == '1' && this.rcVideoUsers != 'null' ? Decimal.ValueOf(this.rcVideoUsers) : null,
                isTermination__c                = this.opportunityType == OPPORTUNITY_TYPE_ACCOUNT_TERMINATION,
                isFedRamp__c                    = this.isFedRamp,
                BusinessIdentity__c             = OpportunityHelper.businessIdentitySerialize(this.businessIdentityId, this.businessIdentityCurrency),
                CampaignId                      = this.campaignId
            );

            if (OpportunityHelper.OPPORTUNITY_CREATION_FLOW_SOLVE_THEN_SELL.equalsIgnoreCase(this.oppCreationFlow)) {
                newOppty.OwnerId = this.accOwnerId;
            }

            insert newOppty;

            if (this.fromContact == '1') {
                String contactIdToUse = (this.fromContactId != this.conversionContId) ? this.fromContactId : this.contId;
                OpportunityCreationFormController.updateOpportunityFromContact(newOppty.Id, contactIdToUse);
            }
            return newOppty;
        }

        public Opportunity createPSChangeOrderOpportunityRecord() {
            newOppty = new Opportunity(
                Name                            = this.name.length() > 119 ? this.name.substring(0, 119).unescapeHtml4() : this.name.unescapeHtml4(),
                AccountId                       = this.accId,
                StageName                       = '1. Qualify',
                OwnerId                         = this.accOwnerId,
                RecordTypeId                    = OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Type                            = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                CloseDate                       = System.today(),
                Is_Billing_Opportunity__c       = true,
                Parent_Order__c                 = parentOrderId,
                BusinessIdentity__c             = OpportunityHelper.businessIdentitySerialize(this.businessIdentityId, this.businessIdentityCurrency),
                CurrencyIsoCode                 = this.currencyCode,
                Tier_Name__c                    = OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                Brand_Name__c                   = this.brand,
                Sub_Brand__c                    = this.subBrand,
                Primary_Opportunity_Contact__c   = this.contId
            );

            insert newOppty;

            return newOppty;
        }

        public void updateContactRole () {
            OpportunityContactRole newOppContactRole = new OpportunityContactRole(
                ContactId = (this.fromContact == '1' && !this.fromContactId.equals(this.conversionContId)) ? this.fromContactId :
                            (this.fromContact == '1' && this.fromContactId.equals(this.conversionContId)) ? this.contId : this.contId,
                Role = this.contactRole,
                OpportunityId = this.newOppty.Id
            );
            List<OpportunityContactRole> rolesFound = [
                SELECT Id
                FROM OpportunityContactRole
                WHERE OpportunityId = :newOppty.Id
                AND Role = :OpportunityHelper.CONTACT_ROLE_SIGNATORY
                LIMIT 1
            ];

            if(!rolesFound.isEmpty()) {
                newOppContactRole.Id = rolesFound[0].Id;
            }
            OpportunityTriggerHelperRefactored.skipOpportunityContactRoleValidations = true;
            upsert newOppContactRole;

        }

        public String confirmAndClose() {
            if (String.isBlank(this.id) || String.isBlank(this.quoteId)) {
                AquivaHelper.throwAquivaException('Confirm and close request invalid');
            }

            OpportunityCreationFormController.confirmAndCloseOppty(this.id, this.quoteId);
            return 'OK';
        }
    }

    public class DQParams {
        public Id quoteId;
        public Id opportunityId;
        public Id dqOrOppId;
        public String status;
        public DealQualification dqRecord;
        public List<DealQualificationDiscount> dqDiscounts = new List<DealQualificationDiscount>();
        public List<DealQualificationServiceDiscount> dqServiceDiscounts = new List<DealQualificationServiceDiscount>();
        public Boolean isPrmFlow;
    }

    public class DealQualification {
        public Id dqId;
        public Id opportunityId;
        public String name;
        public String status;
        public String chargeTerm;
        public String renewalTerm;
        public String initialTerm;
        public String initialTermCC;
        public String specialTerms;
        public String specialTermsCC;
        public Decimal dealSize;
        public Decimal newAnnualRecurringCharges;
        public String freeShippingTermsOptions;
        public Boolean isDQCreatedFromCPQ;
        public String ela;
        public Decimal costOneTimeItems;
        public String justification;
        public Boolean autoRenewal;
        public Decimal overallDiscount;
        public Decimal overallDiscountOneTime;
        public Decimal overallDiscountRecurring;
        public Date startDate;
        public String additionalInfo;
        public Decimal minimumBaseline;
        public Decimal maximumPotential;
        public String elaInitialTerms;
        public String trueUpTerms;
        public String globalOfficeLocation;
        public String opportunityOwnerEmail;
        private Boolean isDataExist = false;

        public DealQualification(DQ_Deal_Qualification__c dqRecord) {
            if (dqRecord != null) {
                this.dqId = dqRecord.Id;
                this.opportunityId = dqRecord.Opportunity__c;
                this.name = dqRecord.Name;
                this.status = dqRecord.Status__c;
                this.chargeTerm = dqRecord.Charge_Term__c;
                this.renewalTerm = dqRecord.Renewal_Term__c;
                this.initialTerm = dqRecord.Initial_Term__c;
                this.initialTermCC = dqRecord.CC_Initial_Term__c;
                this.specialTerms = dqRecord.Special_Terms__c;
                this.specialTermsCC = dqRecord.CC_Special_Terms__c;
                this.dealSize = dqRecord.Deal_Size__c;
                this.newAnnualRecurringCharges = dqRecord.New_Annual_Recurring_Charges__c;
                this.freeShippingTermsOptions = dqRecord.Free_Shipping_Terms_Options__c;
                this.isDQCreatedFromCPQ = dqRecord.IsDQCreatedFromCPQOpp__c;
                this.ela = dqRecord.Is_ELA__c;
                this.costOneTimeItems = dqRecord.Cost_of_One_Time_items__c;
                this.justification = dqRecord.Justification_Description__c;
                this.autoRenewal = dqRecord.Auto_Renewal__c;
                this.overallDiscount = dqRecord.Overall_Discount__c;
                this.overallDiscountOneTime = dqRecord.Overall_Discount_One_Time__c;
                this.overallDiscountRecurring = dqRecord.Overall_Discount_Recurring__c;
                this.startDate = dqRecord.Start_Date__c;
                this.additionalInfo = dqRecord.Additional_Info__c;
                this.minimumBaseline = dqRecord.Minimum_Baseline__c;
                this.maximumPotential = dqRecord.Maximum_Potential__c;
                this.elaInitialTerms = dqRecord.ELA_Initial_Terms__c;
                this.trueUpTerms = dqRecord.True_Up_Terms__c;
                this.globalOfficeLocation = dqRecord.Global_Office_Location__c;
                this.opportunityOwnerEmail = dqRecord.Opportunity_Owner_s_Email__c;
                this.isDataExist = true;
            }
        }

        public DQ_Deal_Qualification__c buildSobject() {
            if (this.isDataExist != null && !this.isDataExist) {
                return null;
            }
            return new DQ_Deal_Qualification__c(
                Id = this.dqId,
                Opportunity__c = this.opportunityId,
                Status__c = this.status,
                Charge_Term__c = this.chargeTerm,
                Renewal_Term__c = this.renewalTerm,
                Initial_Term__c = this.initialTerm,
                CC_Initial_Term__c = this.initialTermCC,
                Special_Terms__c = this.specialTerms,
                CC_Special_Terms__c = this.specialTermsCC,
                Deal_Size__c = this.dealSize,
                New_Annual_Recurring_Charges__c = this.newAnnualRecurringCharges,
                Free_Shipping_Terms_Options__c = this.freeShippingTermsOptions,
                IsDQCreatedFromCPQOpp__c = this.isDQCreatedFromCPQ,
                Is_ELA__c = this.ela,
                Cost_of_One_Time_items__c = this.costOneTimeItems,
                Justification_Description__c = this.justification,
                Auto_Renewal__c = this.autoRenewal,
                Overall_Discount_One_Time__c = this.overallDiscountOneTime,
                Overall_Discount_Recurring__c = this.overallDiscountRecurring,
                Start_Date__c = this.startDate,
                Additional_Info__c = this.additionalInfo,
                Minimum_Baseline__c = this.minimumBaseline,
                Maximum_Potential__c = this.maximumPotential,
                ELA_Initial_Terms__c = this.elaInitialTerms,
                True_Up_Terms__c = this.trueUpTerms,
                Global_Office_Location__c = this.globalOfficeLocation
            );
        }
    }

    public class DealQualificationDiscount {
        public Id dqId;
        public Id dqDiscountId;
        public Id recordTypeId;
        public Id product2Id;
        public String productName;
        public String originalPackageId;
        public String originalPackageVersion;
        public String originalPackageName;
        public String packageName;
        public String productCategory;
        public String discountType;
        public Decimal discount;
        public Decimal quantity;
        public DateTime createdDate;
        public String service;
        public String groupName;
        public String subGroup;

        @TestVisible
        private Boolean isDataExist = false;

        @TestVisible
        private DealQualificationDiscount() {}

        public DealQualificationDiscount(DQ_Deal_Qualification_Discounts__c dqDiscount) {
            if (dqDiscount != null) {
                this.dqId = dqDiscount.Deal_Qualification__c;
                this.dqDiscountId = dqDiscount.Id;
                this.recordTypeId = dqDiscount.RecordTypeId;
                this.product2Id = dqDiscount.Product__c;
                this.productName = dqDiscount.Product__r.Name;
                this.originalPackageId = dqDiscount.OriginalPackageId__c;
                this.originalPackageVersion = dqDiscount.OriginalPackageVersion__c;
                this.originalPackageName = dqDiscount.OriginalPackageName__c;
                this.packageName = dqDiscount.PackageName__c;
                this.productCategory = dqDiscount.Product_Category__c;
                this.discountType = dqDiscount.Discount_Type__c;
                this.discount = dqDiscount.Discount__c;
                this.quantity = dqDiscount.Quantity__c;
                this.createdDate = dqDiscount.CreatedDate;
                this.service = dqDiscount.Service__c;
                this.groupName = dqDiscount.Group__c;
                this.subGroup = dqDiscount.Subgroup__c;
                this.isDataExist = true;
            }
        }

        public DQ_Deal_Qualification_Discounts__c updateSobjectFields(DQ_Deal_Qualification_Discounts__c dqDiscount, Id dqId) {
            if (this.isDataExist != null && !this.isDataExist) {
                return null;
            }
            if (dqDiscount == null) {
                dqDiscount = new DQ_Deal_Qualification_Discounts__c(
                    Deal_Qualification__c = dqId
                );
            }
            dqDiscount.Id = this.dqDiscountId;
            dqDiscount.Product__c = this.product2Id;
            dqDiscount.RecordTypeId = this.recordTypeId;
            dqDiscount.OriginalPackageId__c = this.originalPackageId;
            dqDiscount.OriginalPackageVersion__c = this.originalPackageVersion;
            dqDiscount.OriginalPackageName__c = this.originalPackageName;
            dqDiscount.PackageName__c = this.packageName;
            dqDiscount.Product_Category__c = this.productCategory;
            dqDiscount.Discount_Type__c = this.discountType;
            dqDiscount.Discount__c = this.discount;
            dqDiscount.Quantity__c = this.quantity;
            dqDiscount.Service__c = this.service;
            dqDiscount.Group__c = this.groupName;
            dqDiscount.Subgroup__c = this.subGroup;

            return dqDiscount;
        }
    }

    public class DealQualificationServiceDiscount {
        public Id dqId;
        public Id dqServiceDiscountId;
        public DateTime createdDate;
        public String service;
        public String freeServiceCredit;
        public Decimal discretion;
        public Decimal weightedDiscount;
        public Boolean eesRemoval;


        @TestVisible
        private Boolean isDataExist = false;

        @TestVisible
        private DealQualificationServiceDiscount() {
        }

        public DealQualificationServiceDiscount(DQ_Deal_Qualification_Service_Discount__c dqServiceDiscount) {
            if (dqServiceDiscount != null) {
                this.dqId = dqServiceDiscount.Deal_Qualification__c;
                this.dqServiceDiscountId = dqServiceDiscount.Id;
                this.service = dqServiceDiscount.Service__c;
                this.freeServiceCredit = dqServiceDiscount.FreeServiceCredit__c;
                this.discretion = dqServiceDiscount.Discretion__c;
                this.weightedDiscount = dqServiceDiscount.WeightedDiscount__c;
                this.eesRemoval = dqServiceDiscount.EESRemoval__c;
                this.createdDate = dqServiceDiscount.CreatedDate;
                this.isDataExist = true;
            }
        }
    }

    public class CaseCreateParams {
        public String action;
        public String subject;
        public String accountId;
        public String contactId;
        public String description;
        public String opportunityId;
        public String origin;
        public String status;
        public String quoteApprovalId;
        public String opportunityOwnerEmail;
        public String partnerContact;
        public String category;
        public Boolean isFromProServ;
        public String caseCategory;
        public String segment;
    }

    public class EngageCCBTerminationResponseParams {
        public String status;
        public List<EngageTerminationMessages> messages;
        public EngageTerminationData data;
    }

    public class EngageTerminationMessages {
        public String severity;
        public String message;
        public String messageDetails;
    }

    public class EngageTerminationData {
        public Boolean engageAccountTerminated;
        public Boolean ngbsAccountTerminated;
    }

    public class NGBSShippingLicense {
        public String elementID;
        public String name;
        public String displayName;
        public String billingType;
        public List<SearchCategories> searchCategories;
    }

    public class SearchCategories {
        public String key;
        public String value;
    }

    public class CountryStates {
        public String stateName;
        public String alpha2Code;
        public String primaryTaxCode;
        public String alternateTaxCode;
    }

    public class DeviceAvailabilityBody {
        public String method;
        public DeviceAvailabilityParams params;

        public DeviceAvailabilityBody(String packageId, String packageVersion, List<String> deviceIds, List<String> countryIds){
            this.method = 'licenseAvailabilityQualifier.getDevicesAllocationOnShippingCountriesEx';
            this.params = new DeviceAvailabilityParams(packageId, packageVersion, deviceIds, countryIds);
        }
    }

    public class DeviceAvailabilityParams {
        public BrandContext brandContext;
        public List<String> deviceLicenseIds;
        public List<String> countriesAlpha3;

        public DeviceAvailabilityParams(String packageId, String packageVersion, List<String> deviceIds, List<String> countryIds){
            this.brandContext = new BrandContext(packageId, packageVersion);
            deviceLicenseIds = deviceIds;
            countriesAlpha3 = countryIds;
        }
    }

    public class TimezoneBody {
        public String method;
        public TimezoneParams params;

        public TimezoneBody(String packageId, String packageVersion) {
            this.method = 'brand.listTimeZones';
            this.params = new TimezoneParams(packageId, packageVersion);
        }
    }

    public class TimezoneParams {
        public BrandContext brandContext;

        public TimezoneParams(String packageId, String packageVersion) {
            this.brandContext = new BrandContext(packageId, packageVersion);
        }
    }

    public class BrandContext {
        public FunnelPackage funnelPackage;

        public BrandContext(String packageId, String packageVersion){
            this.funnelPackage = new FunnelPackage(packageId, packageVersion);
        }
    }

    public class FunnelPackage {
        public String packageId;
        public String packageVersion;
        public String description;

        public FunnelPackage(String packageId, String packageVersion){
            this.packageId = packageId;
            this.packageVersion = packageVersion;
        }
    }

    public class DeviceAvailabilityResponse {
        public Map<String,Map<String, DeviceAvailabilityResponseRules>> devices;
        public Map<String,DeviceAvailabilityResponseCountry> countries;

        public DeviceAvailabilityResponse(Map<String, Object> deserializedData) {
            Map<String, Object> devicesMapResponse = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(deserializedData.get('devices')));
            Map<String,Map<String, DeviceAvailabilityResponseRules>> devicesMap = new Map<String,Map<String, DeviceAvailabilityResponseRules>>();
            for (String deviceId : devicesMapResponse.keySet()) {
                Map<String, Object> deviceCountryMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(devicesMapResponse.get(deviceId)));
                if (!devicesMap.containsKey(deviceId)) {
                    devicesMap.put(deviceId, new Map<String, DeviceAvailabilityResponseRules>());
                }
                if (deviceCountryMap != null) {
                    for (String deviceCountry : deviceCountryMap.keySet()) {
                        if (!devicesMap.get(deviceId).containsKey(deviceCountry)) {
                            devicesMap.get(deviceId).put(deviceCountry, deviceCountryMap.get(deviceCountry) != null ? (DeviceAvailabilityResponseRules) JSON.deserialize(JSON.serialize(deviceCountryMap.get(deviceCountry)), DeviceAvailabilityResponseRules.class) : null);
                        }
                    }
                }
            }
            this.countries = (Map<String,DeviceAvailabilityResponseCountry>) JSON.deserialize(JSON.serialize(deserializedData.get('countries')), Map<String,DeviceAvailabilityResponseCountry>.class);
            this.devices = devicesMap;
        }
    }

    public class DeviceAvailabilityResponseRules {
        public String endOfSalesDate;
        public Integer ruleType;
    }

    public class DeviceAvailabilityResponseCountry {
        public String name;
        public Boolean hasStates;
        public List<String> shippingLicenseIds;
    }

    public class DQApprover {
        public String approverId;
        public String status;
        public String comments;
        public String ownerId;
    }

    public class SubmitEngageResponse {
        public EngageAccount engageDigitalAccount;
        public EngageAccount engageVoiceAccount;
    }

    public class EngageAccount {
        public NGBSAccount ngbsAccount;
        public String enterpriseAccountId;
        public String engageAccountId;
        public String id;
        public String mainAccountId;
    }

    public class SubmitEngageError {
        public String message;
        public String status;
    }

    public class BillingAddress {
        public String address1;
        public String address2;
        public String city;
        public String state;
        public String country;
        public String zip;
        public String firstName;
        public String lastName;
        public String phoneNumber;
        public Boolean skipValidation;
        public Boolean stateIsRequired;
    }

    public class Dictionaries{
        public List<Country> countries;
	    public List<CaseProvisioningParameter> timeZones;
	    public List<CaseProvisioningParameter> nicSegments;
	    public List<CaseProvisioningParameter> geoRegions;
	    public List<CaseProvisioningParameter> implementationTeams;
    }

    public class State {
        public String name;
        public String code;
    }

    public class CaseProvisioningParameter {
		public String id;
		public String name;
	}

    public class Country {
		public Integer id;
		public String name;
		public String code;
		public String codeAlpha2;
		public Boolean stateIsRequired;
		public List<State> states;
		public String abbreviation;
	}

    public class RequestSubmitParams {
        public String action;
        public String targetId;
        public Boolean isEngageVoice;
        public SubmitWrapper data;
        public String tier;
        public Boolean isChangeOrder;
        public String accountId;
        public String caseNumber;
        public String quoteId;
        public Boolean isMPUB;
        public Boolean isMultiProductTechnicalQuote;
    }

    public class SubmitWrapper {
        public BillingAddress billingAddress;
        public String packageLocation;
        public String engageShardName;
        public String engageDomain;
        public String timeZone;
        public String locale;
        public Boolean locationNotFoundByPackage;
        public Boolean migration;
        public Date lastBillingDate;
        public Boolean packageIsLegacy;
        public String rcAccountId;
        public Boolean provisionUserAccount;
        public Date contractStartDate;
        public String location;
        public Boolean testerFlag;
        public String platformId;
        public AccountParams accountParams;
        public NicLicenses nicLicenses;
        public Boolean skipAddressValidation;
        public Boolean isNicLicensesChanged;
        public String caseDescription;
    }

    public class AccountParams {
        public String contactCenterNumber;
        public String geoRegionId;
        public String implementationTeamId;
        public String nicSegmentId;
        public String timeZoneId;
        public String geoRegionValue;
        public String implementationTeamValue;
        public String nicSegmentValue;
        public String timeZoneValue;
    }

    public class NicLicenses {
        public List<NicLicensesItem> items;
        public String quoteDescription;
    }

    public class NicLicensesItem {
        public String vendorSKU;
        public Double priceToVendor;
        public Integer newQuantity;
    }

    public class Phase {
        public String phaseId {get;set;}
        public String opportunityId {get;set;}
        public String name {get;set;}
        public String status {get;set;}
        public String uniqueId {get;set;}
        public String quoteId {get;set;}
        public String currencyIsoCode {get;set;}
        public Integer phaseNumber {get;set;}
        public String description {get;set;}
        public String phaseType {get;set;}
        public String suborderId {get;set;}
    }

    public class PhasesParams {
        public String action {get;set;}
        public String selectedQuoteId {get;set;}
        public String opportunityId {get;set;}
        public String orderId {get;set;}
        public List<Phase> phases {get;set;}
    }

    public class PhaseLineItemsParams {
        public String action {get;set;}
        public String selectedQuoteId {get;set;}
        public String orderId {get;set;}
        public List<Phase> phases {get;set;}
        public Map<String, List<PhaseLineItem>> phaseLineItemsMap {get;set;}
    }

    public class PhaseLineItem {
        public String phaseLineItemId {get;set;}
        public Integer quantity {get;set;}
        public String productElementId {get;set;}
        public Integer existingQuantity {get;set;}
    }

    public class SubordersParams {
        public String action {get;set;}
        public String orderId {get;set;}
        public String suborderName {get;set;}
        public String suborderId {get;set;}
        public String opportunityId {get;set;}
        public String billingAccountId {get;set;}
        public String billingPackageId {get;set;}
        public List<Suborder> suborders {get;set;}
        public String quoteNumber {get;set;}
    }

    public class OrdersParams {
        public String action {get;set;}
        public String orderId {get;set;}
        public String opportunityId {get;set;}
        public String status {get;set;}
    }

    public class OrderWrapper {
        public String status {get;set;}
        public String billingAccountProServPackageId {get;set;}
        public Datetime initialOrderCreatedDateUTC {get;set;}
        public String orderNumber {get;set;}
        public Integer maxPhaseNUmber {get;set;}
        public Double ccTotal{get;set;}
        public Double ucTotal {get;set;}
        public String currencyIsoCode {get;set;}


        public OrderWrapper(order Order) {
            this.status = order?.Status;
            this.billingAccountProServPackageId = order?.PackageId__r?.Account_Package_Id__c;
            this.initialOrderCreatedDateUTC = order?.ProServProject__r?.Order__r?.CreatedDate;
            this.orderNumber = order?.OrderNumber;
            this.maxPhaseNUmber = (Integer) order?.MaxPhaseNumber__c;
            this.ccTotal = (Double) order?.CCSubTotal__c;
            this.ucTotal = (Double) order?.UCSubtotal__c;
            this.currencyIsoCode = order?.CurrencyIsoCode;
        }
    }

    public class Suborder {
        public String phaseId {get;set;}
        public String name {get;set;}
        public String status {get;set;}
        public String uniqueId {get;set;}
        public String orderId {get;set;}
        public String currencyIsoCode {get;set;}
        public Integer phaseNumber {get;set;}
        public String signoffLink {get;set;}
        public String revenueCategory {get;set;}
        public String billingMethod {get;set;}
        public String billingDate {get;set;}
        public String phaseType {get;set;}
        public String suborderId {get;set;}
        public String orderNumber {get;set;}
    }

    public class SuborderLineItemsParams {
        public String action {get;set;}
        public String orderId {get;set;}
        public String quoteId {get;set;}
        public List<Suborder> suborders {get;set;}
        public Map<String, List<SuborderLineItem>> suborderLineItemsMap {get;set;}
        public List<BillingAccountLocation> accountLocations {get;set;}
    }

    public class SuborderLineItem {
        public String phaseLineItemId {get;set;}
        public Integer quantity {get;set;}
        public String productElementId {get;set;}
        public List<SuborderLineItemLocation> locations {get;set;}
    }

    public class SuborderLineItemLocation {
        public String locationId {get;set;}
        public String billingLocationId {get;set;}
        public String billingCodeId {get;set;}
        public Integer quantity {get;set;}
    }

    public class BillingAccountLocation {
        public String uniqueId {get;set;}
        public String accountId {get;set;}
    }

    public class PackageConsolidationSettings {
        public Boolean billingAlignmentEnabled;
        public Boolean invoiceConsolidationEnabled;
        public PackageConsolidationSettings(Boolean billingAlignmentEnabled, Boolean invoiceConsolidationEnabled) {
            this.billingAlignmentEnabled = billingAlignmentEnabled;
            this.invoiceConsolidationEnabled = invoiceConsolidationEnabled;
        }
    }

    public class CostCenter {
        public String id {get;set;}
    }

    public class PaymentParams {
        public String salesOrderId {get;set;}
        public List<PaymentOrderItem> itemsToAdd {get;set;}
        public OrderMetadata orderMetadata {get;set;}
    }

    public class OrderMetadata {
        public String sowNumber {get;set;}
        public String subOrderNumber {get;set;}
    }

    public class PaymentOrderItem {
        public String catalogId {get;set;}
        public String billingCodeId {get;set;}
        public Integer qty {get;set;}
        public String billingCycleDuration {get;set;}
    }

     public class ProservParam {
        public boolean isSignUpCompleted {get;set;}
        public String accountPackageId {get;set;}

        public ProservParam(String accountPackageId) {
            this.isSignUpCompleted = String.isNotBlank(accountPackageId) ? true : false;
            this.accountPackageId = accountPackageId;
        }
    }
}