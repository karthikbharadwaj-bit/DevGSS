/**
 * This is helper class for Product2 standard object
 * Keep all static variables and helper methods related to it here
 *
 * It's might be better to keep here helper methods that do not do any SOQL
 * so they could be reused in triggers or controllers
 */
public class Product2Helper {

    public class ProductDataException extends Exception {}

    // Product_Type__c
    public final static String PRODUCT_TYPE_SEAT = 'Seat';
    public final static String PRODUCT_TYPE_PORT = 'Port';
    public final static String PRODUCT_TYPE_TRANSPORT = 'Transport';
    public final static String PRODUCT_TYPE_OUTBOUND_CALLS = 'Outbound Calls to Local Numbers and Mobile';
    public final static String PRODUCT_TYPE_INBOUND_CALLS = 'Inbound Calls';

    public final static String PRODUCT_TYPE_INCOMING_SMS = 'IncomingSMS';
    public final static String PRODUCT_TYPE_OUTGOING_SMS = 'OutgoingSMS';
    public final static String PRODUCT_TYPE_OUTGOING_SMS_RATE = 'OutgoingSMSRate';
    public final static String PRODUCT_TYPE_SMS_TF_LONG_RATE = 'SmsTfLongRate';
    public final static String PRODUCT_TYPE_AI = 'AI';
    public final static String PRODUCT_TYPE_SESSIONS = 'Sessions Bundle';
    public final static String PRODUCT_TYPE_CALLS = 'Calls Bundle';
    public final static String PRODUCT_TYPE_MESSAGES = 'Messages Bundle';
    public final static String PRODUCT_TYPE_ENGAGEMENT = 'Engagement Bundle';
    public final static String PRODUCT_TYPE_BILLING_PRODUCT = 'Product';

    public final static List<String> PRODUCT_TYPES_EU_TRANSPORT;
    public final static List<String> PRODUCT_TYPES_US_UK_TRANSPORT = new List<String> {
        PRODUCT_TYPE_TRANSPORT,
        PRODUCT_TYPE_INBOUND_CALLS,
        PRODUCT_TYPE_OUTBOUND_CALLS
    };
    public final static List<String> PRODUCT_TYPES_BUNDLES = new List<String> {
        PRODUCT_TYPE_SESSIONS,
        PRODUCT_TYPE_CALLS,
        PRODUCT_TYPE_MESSAGES,
        PRODUCT_TYPE_ENGAGEMENT
    };

    //used in UpsellType__c and InitialOrderType__c 
    public static final String PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE = 'autoWithCase';
    public static final String PRODUCT_PROVISIONING_TYPE_MANUAL = 'manual';

    //used in DownsellType__c 
    public static final String PRODUCT_DOWNSELL_TYPE_AUTO = 'auto';
    public static final String PRODUCT_DOWNSELL_TYPE_AUTO_WITH_CASE = 'autoWithCase';

    //B-1753 common overages is no longer matching by parent
    public final static Set<String> COMMON_OVERAGE_TYPES = new Set<String>{
            'IVN',
            'International',
            'Storage Usage',
            'ProServOnDemand',
            'Non-emergency Service Short Code UK',
            'Premium Short Code 118 Number UK',
            'Premium Short Code UK',
            'Premium Range UK',
            'SpeechRecognition',
            PRODUCT_TYPE_INCOMING_SMS,
            PRODUCT_TYPE_OUTGOING_SMS,
            PRODUCT_TYPE_OUTGOING_SMS_RATE,
            PRODUCT_TYPE_SMS_TF_LONG_RATE
    };

    public final static Set<String> SMS_OVERAGE_TYPES = new Set<String>{
        PRODUCT_TYPE_INCOMING_SMS,
        PRODUCT_TYPE_OUTGOING_SMS,
        PRODUCT_TYPE_OUTGOING_SMS_RATE,
        PRODUCT_TYPE_SMS_TF_LONG_RATE
    };

    // Family__c
    public final static String FAMILY_OVERAGE = 'Overage';
    public final static String FAMILY_TAXES = 'Taxes';
    public final static String FAMILY_SERVICE = 'Service';
    public final static String FAMILY_TECHNICAL = 'Technical License';
    public final static String FAMILY_TIER = 'Tier';
    public final static String FAMILY_ADDONS = 'Add - Ons';
    public final static String FAMILY_CCSERVICE = 'CC Service';
    public final static String FAMILY_SMS= 'SMS';
    public final static String FAMILY_WFO = 'Workforce Optimization';
    public final static String FAMILY_FEE = 'Fee';
    public final static String FAMILY_DISCOUNTED_PHONES = 'Discounted Phones';
    public final static String FAMILY_RENTAL_PHONES = 'Rental Phones';
    public final static String FAMILY_REFURBISHED_PHONES = 'Refurbished Phones';
    public final static String FAMILY_PHONE = 'Phones';
    public final static String FAMILY_COMMON_PHONE = 'Common Phones';
    public final static String FAMILY_MINUTES_BUNDLE = 'Minutes Bundle';
    public final static String FAMILY_OUTBOUND_MINUTES_BUNDLE = 'Outbound Minutes Bundle';
    public final static String FAMILY_INBOUND_MINUTES_BUNDLE = 'Inbound Minutes Bundle';
    public final static String FAMILY_SUPPORT_PACKAGE = 'Support Package';
    public final static String FAMILY_GLOBAL_OFFICE_RENTAL = 'Global Office Rental Phones';
    public final static String FAMILY_LIMITED_EXTENSION_RENTAL_PHONE = 'Limited Extension Rental Phones';
    public final static String FAMILY_COMMON_RENTAL_PHONES = 'Common Rental Phones';
    public final static String FAMILY_GLOBAL_OFFICE_LIMITED_EXTENSION_RENTAL_PHONE = 'Global Office - Limited Extension Rental Phones';
    public final static String FAMILY_SERVICE_FREE_OF_CHARGE = 'FreeOfChargeService';
    public final static String FAMILY_TECHNICAL_LICENSE = 'Technical License';

    public final static String SUBSCRIPTION_LICENSE = 'LC_SC_29';
    public final static String SHIPPING_CATEGORY = 'SHP';

    public final static Set<String> FAMILY_MINUTES_BUNDLE_LIST = new Set<String> {
        FAMILY_MINUTES_BUNDLE,
        FAMILY_OUTBOUND_MINUTES_BUNDLE,
        FAMILY_INBOUND_MINUTES_BUNDLE
    };

    public static final Set<String> DISCOUNTED_PHONES_FAMILIES = new Set<String>{
        FAMILY_DISCOUNTED_PHONES,
        FAMILY_RENTAL_PHONES,
        FAMILY_REFURBISHED_PHONES
    };

    public static final Set<String> SHIPPING_PHONES = new Set<String>{
        'HDRF',
        'HD',
        'HDR',
        'HDRD'
    };

    public static final Set<String> DL_CATEGORIES = new Set<String>{
        'DL-UNL',
        'DL-BAS',
        'DL-UNL-CC',
        'DL-HDSK'
    };

    public static final Set<String> ORDER_API_EXCEPTION_LICENSES = new Set<String> {
        'LC_CRF_43',
        'LC_CRO_574',
        'LC_MU_281',
        'LC_SC_29'};

    // Product_Category_Name__c
    public static final String DEFAULT_CATEGORY = 'Default';

    // Sub_Category__c
    public static final String SUBCATEGORY_RINGCENTRAL = 'Main';
    public static final String SUBCATEGORY_PROSERV = 'Professional Services';
    public static final String SUBCATEGORY_CC_PROSERV = 'CC Professional Services';
    public static final String SUBCATEGORY_CONTACT_CENTER = 'Contact Center';
    public static final String SUBCATEGORY_RC_CONTACT_CENTER = 'RingCentral Contact Center';
    public static final String SUBCATEGORY_CLOUDCONNECT = 'CloudConnect';
    public static final String GROUP_PROSERV = '[800] Professional Services';
    public static final String SUBGROUP_PROSERV = '[805] Implementation';

    public static final Set <String> CONTACT_CENTER_SUBCATEGORIES=
        new Set <String> {SUBCATEGORY_CONTACT_CENTER,SUBCATEGORY_RC_CONTACT_CENTER};

    //SOW_Type__c
    public static final String SOW_TYPE_PROSERV = 'ProServ';
    public static final String SOW_TYPE_CC_PROSERV = 'CC ProServ';

    // Feature__c
    public static final Decimal FEATURE_SERVICE_PLAN      = 17;
    public static final Decimal FEATURE_SERVICE_PLAN_FAX  = 28;
    public static final Decimal FEATURE_LIMITED_EXTENSION = 12;
    public static final Decimal FEATURE_GLOBAL_OFFICE     = 47;
    public static final Decimal FEATURE_IVN_LOCAL = 41;
    public static final Decimal FEATURE_IVN_TOLL_FREE = 42;
    public static final Decimal FEATURE_DIGITAL_LINE_HOT_DESKING = 50;
    public static final Decimal FEATURE_GLOBAL_OFFICE_LIMITED_EXTENSION = 63;
    public static final Decimal FEATURE_CC_EXTENDED_ENTERPRISE_SUPPORT = 69;
    public static final Decimal FEATURE_EXTENDED_ENTERPRISE_SUPPORT;
    public static final Set<Decimal> FEATURE_NUMBERS = new Set<Decimal>{2, 3};
    public static final Decimal FEATURE_ADDITIONAL_LOCAL_NUMBER = 3;
    public static final Set<Decimal> NUMBER_SETUP = new Set<Decimal>{4, 5};
    public static final Decimal FEATURE_REFURBISHED_PHONES = 39;
    public static final Decimal FEATURE_DISCOUNTED_PHONES = 11;

    public static final Set<Decimal> FEATURE_SERVICES = new Set<Decimal>{
        FEATURE_LIMITED_EXTENSION,
        FEATURE_SERVICE_PLAN,
        18, // legacy thing, don't know what feature is it
        FEATURE_SERVICE_PLAN_FAX
    };

    static {

        Integer featureForEES = 38;

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();

        if(featureToggle != null && featureToggle.UseFeature70ForEES__c == true) {
            featureForEES = 70;
        }

        FEATURE_EXTENDED_ENTERPRISE_SUPPORT = featureForEES;

        PRODUCT_TYPES_EU_TRANSPORT = QuoteLineItemHelper.getEuropeTransportTypes();
    }
    public static final Decimal FEATURE_LIVE_REPORTS = 60;
    public static final Decimal FEATURE_INCONTACT_INTERCONNECT = 65;
    public static final Decimal FEATURE_CONTACT_CENTER_EXTENDED_ENTERPRISE = 69;

    public static final Set<Integer> ONE_TIME_FEATURE_SET = new Set<Integer>{
        11, 39, 22, 45, 43, 5, 46, 4, 29, 37
    };
    public static final Map<String, Integer> RC_MINUTES_BUNDLE_FEATURES = new Map<String, Integer>{
        'rcMinutesBundle24' => 24,
        'rcMinutesBundle52' => 52,
        'rcMinutesBundle56' => 56,
        'rcMinutesBundle59' => 59,
        'rcMinutesBundle36' => 36
    };

    // Name
    public static final String NAME_CC_INBOUND_SMS_APPLICATION_FEE = 'Contact Center: Inbound SMS Application Fee';
    public static final String NAME_CC_OUTBOUND_SMS_APPLICATION_FEE = 'Contact Center: Outbound SMS Application Fee';
    public static final String NAME_EXTENDED_ENTERPRISE_SUPPORT = 'Extended Enterprise Support';
    public static final String NAME_EXTENDED_ENTERPRISE_SUPPORT_GOLD = 'Extended Enterprise Support - Gold - price per DL';
    public static final String NAME_EXTENDED_ENTERPRISE_SUPPORT_PLATINUM = 'Extended Enterprise Support - Platinum - price per DL';
    public static final String NAME_EXTENDED_ENTERPRISE_SUPPORT_SILVER = 'Extended Enterprise Support - Silver - price per DL';
    public static final String NAME_SEAT = 'Seat';

    // Charge_Term__c
    public static final String CHARGE_TERM_ONE_TIME = 'One - Time';
    public static final String CHARGE_TERM_ANNUAL = 'Annual';
    public static final String CHARGE_TERM_MONTHLY = 'Monthly';
    public static final String CHARGE_TERM_ANNUAL_CONTRACT = 'Annual - Contract';
    public static final String CHARGE_TERM_MONTHLY_CONTRACT = 'Monthly - Contract';
    public static final String CHARGE_TERM_QUATERLY = 'Quarterly';
    public static final String CHARGE_TERM_SEMI_ANNUAL = 'SemiAnnual';

    public static final Set<String> CHARGE_TERMS_SET_MONTHLY = new Set<String> {
        CHARGE_TERM_MONTHLY,
        CHARGE_TERM_MONTHLY_CONTRACT
    };

    public static final Set<String> CHARGE_TERMS_SET_ANNUAL = new Set<String> {
        CHARGE_TERM_ANNUAL,
        CHARGE_TERM_ANNUAL_CONTRACT
    };

    public static final String MOBILE_USER_ELEMENT_ID = 'LC_MU_281';
    public static final String DL_UNL_ELEMENT_ID = 'LC_DL-UNL_50';
    public static final String DID_ELEMENT_ID = 'LC_DID_53';

    public static final String ELEMENT_ID_DL_UNL_CC = 'LC_DL-UNL-CC_737';
    public static final String ELEMENT_ID_DL = 'LC_DL_75';
    public static final String ELEMENT_ID_DL_CC = 'LC_DL-CC_735';
    public static final String ELEMENT_ID_DL_BASIC = 'LC_DL-BAS_178';
    public static final String ELEMENT_ID_E911_FEE = 'LC_E911_52';
    public static final String ELEMENT_ID_E911_FEE_CC = 'LC_E911-CC_740';
    public static final String ELEMENT_ID_COMPLIANCE_FEE = 'LC_CRF_51';
    public static final String ELEMENT_ID_COMPLIANCE_FEE_CC = 'LC_CRF-CC_739';
    public static final String ELEMENT_ID_GLOBAL_OFFICE = 'LC_DLI_282';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_US_CANADA = 'LC_IBO_696';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_US_CANADA_CC = 'LC_IBO-CC_706';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_EMEA = 'LC_IBO_284';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_EMEA_CC = 'LC_IBO-CC_594';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_UK = 'LC_IBO_286';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_APAC = 'LC_IBO_288';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_APAC_CC = 'LC_IBO-CC_598';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_LATAM = 'LC_IBO_290';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_LATAM_CC = 'LC_IBO-CC_600';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_PREMIUM = 'LC_IBO_292';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_PREMIUM_CC = 'LC_IBO-CC_602';
    public static final String ELEMENT_ID_GLOBAL_OFFICE_INTERNATIONAL = 'LC_IBO-BAS_496';
    public static final String ELEMENT_ID_COMMON_PHONE = 'LC_DL-HDSK_177';
    public static final String ELEMENT_ID_IVN_US_CANADA = 'LC_IVN_697';
    public static final String ELEMENT_ID_RC_VIDEO = 'LC_SM_405';
    public static final String ELEMENT_ID_RC_CC_SEAT = 'CC_RCCCSEAT_1';
    public static final String ELEMENT_ID_FAX_NUMBER = 'LC_MLFN_45';
    public static final String ELEMENT_ID_DOMESTIC_ROOMS_PHONE_LINE_ADDON = 'LC_DL-ROOMS_969';
    public static final String ELEMENT_ID_BYOC_DOMESTIC = 'LC_DL-BYOCD_942';
    public static final String ELEMENT_ID_BYOC_INTERNATIONAL = 'LC_DL-BYOCI_942';
    public static final String EVNT_EO_2589005 = 'EVNT_EO_2589005';
    
    public static final Set<String> OFFICE_DL = new Set<String> {
        DL_UNL_ELEMENT_ID,
        ELEMENT_ID_DL_BASIC,
        ELEMENT_ID_GLOBAL_OFFICE
    };
    public static final Set<String> RC_EVENT_LICENSES = new Set<String> {
        'EVNT_EO_2589005'
    };


    public static final Set<String> ENGAGE_DIGITAL_LICENSE_EXT_IDS = new Set<String> {
        'SA_SEAT_1',
        'SA_SEAT_3',
        'SA_SEAT_5',
        'LC_CAS_7'
    };

    public static final Set<String> ENGAGE_VOICE_LICENSE_EXT_IDS = new Set<String> {
        'SA_SEAT_2',
        'SA_SEAT_4',
        'LC_SEAT_23',
        'LC_SEAT_24'
    };

    public static final Set<String> FEES_PRODUCTS_EXT_IDS = new Set<String> {
        'LC_CRF_43',
        'LC_CRF_51',
        'LC_E911_52',
        'LC_E911_403'
    };

    public static final String MINUTE_BUNDLE_EXT_ID = 'CC_ICIBTF25KB_129';
    public static final Integer MINUTE_BUNDLE_CC_QUANTITY = 25000;

    public static final Set<String> NON_ASSIGNABLE_LICENSES = new Set<String>{
        ELEMENT_ID_DOMESTIC_ROOMS_PHONE_LINE_ADDON,
        ELEMENT_ID_BYOC_DOMESTIC,
        ELEMENT_ID_BYOC_INTERNATIONAL
    };

    public static final String PRODUCT_MEETINGS = 'Meetings';
    public static final String PRODUCT_OFFICE = 'Office';
    public static final String PRODUCT_FAX = 'Fax';
    /* TODO: Need to specify real product ids */
    public static final String PRODUCT_ID_ENGAGE_VOICE_LEGACY = '8';
    public static final String PRODUCT_ID_ENGAGE_VOICE_STANDALONE = '9';
    public static final String PRODUCT_ID_ENGAGE_DIGITAL_LEGACY = '6';
    public static final String PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE = '7';
    public static final String PRODUCT_ID_ENGAGE_UNIFIED = '10';
    public static final String PRODUCT_ID_ENGAGE_OMNICHANNEL = '11';
    public static final String PRODUCT_ID_CONTACT_CENTER = '22';

    public static final Set<String> PRODUCT_ID_ENGAGE_STANDALONE = new Set<String> {
        PRODUCT_ID_ENGAGE_VOICE_STANDALONE,
        PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE,
        PRODUCT_ID_ENGAGE_UNIFIED
    };

    public static final Set<String> PRODUCT_ID_ENGAGE = new Set<String> {
        PRODUCT_ID_ENGAGE_VOICE_LEGACY,
        PRODUCT_ID_ENGAGE_VOICE_STANDALONE,
        PRODUCT_ID_ENGAGE_DIGITAL_LEGACY,
        PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE,
        PRODUCT_ID_ENGAGE_UNIFIED,
        PRODUCT_ID_ENGAGE_OMNICHANNEL
    };

    public static final String BILLING_TYPE_USAGE = 'Usage';
    public static final String BILLING_TYPE_RECURRING = 'Recurring';
    public static final String BILLING_TYPE_ONE_TIME = 'OneTime';
    public static final Map<String, Decimal> VOLUME_BY_STRING = new Map<String, Decimal> {
        '10K' => 10000,
        '15K' => 15000,
        '20K' => 20000,
        '50K' => 50000,
        '100K' => 100000,
        '200K' => 200000,
        '1M' => 10000000
    };
    public static final Map<String, String> BUNDLE_STRING_BY_VOLUME = new Map<String, String> {
        '5000' => '5K',
        '10000' => '10K',
        '25000' => '25K',
        '50000' => '50K',
        '100000' => '100K',
        '250000' => '250K',
        '500000' => '500K',
        '750000' => '750K',
        '1000000' => '1M',
        '2000000' => '2M'
    };
    public static final Pattern BUNDLE_VOLUME_PATTERN = Pattern.compile('[0-9][0-9,]+');

    public static final String CATID_STORAGE_RETRIEVAL = '309-566-000';
    public static final String CATID_AMELIA_TTS = '1506-2067-000';
    public static final String CATID_ADDITIONAL_STORAGE = '309-1499-000';
    public static final String CATID_ADDITIONAL_STORAGE_OLD = '309-11-172';
    public static final Set<String> CATID_ADDITIONAL_STORAGES = new Set<String>{
        CATID_ADDITIONAL_STORAGE,
        CATID_ADDITIONAL_STORAGE_OLD
    };
    public static final Set<String> CATID_GLOBAL_SEATS = new Set<String>{
        '12653-1704-000',
        '12654-1705-000',
        '12656-1723-000',
        '12657-1725-000',
        '12658-1727-000',
        '12659-1729-000',
        '12654-1706-000',
        '12656-1724-000',
        '12657-1726-000',
        '12658-1728-000',
        '12659-1730-000',
        '307-6-676'
    };

    public static final String ORDER_TYPE_MANUAL = 'manual';
    public static final String ORDER_TYPE_AUTO = 'autoWithCase';
    public static final String SHIPPING_TYPE_AUTO = 'auto';
    public static final String SHIPPING_TYPE_MANUAL = 'manual';

    @TestVisible
    private static final String LICENSES_LABELS_OVERRIDE_INITIAL_ORDER_TYPE = 'initialOrderType';
    @TestVisible
    private static final String LICENSES_LABELS_OVERRIDE_UPSELL_TYPE = 'upsellType';
    private static final String PRODUCT_INITIAL_ORDER_TYPE_FIELD_NAME = 'InitialOrderType__c';
    private static final String PRODUCT_UPSELL_TYPE_FIELD_NAME = 'UpsellType__c';

    private static final Map<String, String> LICENSES_LABELS_OVERRIDE_ORDER_TYPES = new Map<String, String>{
        LICENSES_LABELS_OVERRIDE_INITIAL_ORDER_TYPE => PRODUCT_INITIAL_ORDER_TYPE_FIELD_NAME,
        LICENSES_LABELS_OVERRIDE_UPSELL_TYPE => PRODUCT_UPSELL_TYPE_FIELD_NAME
    };

    public static Boolean isMonthly(String chargeTerm) {
        return chargeTerm != null && CHARGE_TERMS_SET_MONTHLY.contains(chargeTerm);
    }

    /**
     * Check if product is Extended Enterprise Support
     *
     * @param product
     *
     * @return
     */
    public static Boolean isExtendedEnterprise(Product2 product) {
        return product != null
            && product.Feature__c == FEATURE_EXTENDED_ENTERPRISE_SUPPORT
            && product.Name.containsIgnoreCase(NAME_EXTENDED_ENTERPRISE_SUPPORT);
    }

    /**
     * Check if product is CCSeat
     *
     * @param product
     *
     * @return Boolean
     */
    public static Boolean isCCSeat(Product2 product) {
        return product != null
            && product.Family == FAMILY_CCSERVICE
            && product.Name.containsIgnoreCase(NAME_SEAT);
    }

    public static Boolean isCCProduct(Product2 product) {
        return product != null
            && CONTACT_CENTER_SUBCATEGORIES.contains(product.Sub_Category__c);
    }

    /**
     * Check if product is Extended Enterprise Support Bronze
     *
     * @param product | feature, productName
     *
     * @return
     */
    public static Boolean isExtendedEnterpriseBronze(Product2 product) {
        return isExtendedEnterprise(product) && product.Name.containsIgnoreCase('Bronze');
    }
    public static Boolean isExtendedEnterpriseBronze(Decimal feature, String productName) {
        return feature == FEATURE_EXTENDED_ENTERPRISE_SUPPORT
            && productName.containsIgnoreCase(NAME_EXTENDED_ENTERPRISE_SUPPORT)
            && productName.containsIgnoreCase('Bronze');
    }

    /**
     * Check if product is Service Plan
     *
     * @param product
     *
     * @return
     */
    public static Boolean isServicePlan(Product2 product) {
        return product != null
            && (((product.Feature__c == FEATURE_SERVICE_PLAN || product.Feature__c == FEATURE_SERVICE_PLAN_FAX ||
            product.Feature__c == FEATURE_LIMITED_EXTENSION)
            && FAMILY_SERVICE.equalsIgnoreCase(product.Family)));
    }

    /**
     * Check if product is Contact Center Service Product
     *
     * @param product
     *
     * @return
     */
    public static Boolean isCcService(Product2 product) {
        return product != null && FAMILY_CCSERVICE.equalsIgnoreCase(product.Family);
    }

    public static Boolean isPortProduct(Product2 product) {
        return product != null && isSameProductType(product.Product_Type__c, PRODUCT_TYPE_PORT);
    }

    public static Boolean isSeatProduct(Product2 product) {
        return product != null && isSameProductType(product.Product_Type__c, PRODUCT_TYPE_SEAT);
    }

    public static Boolean isSameProductType(String productType, String typeForCheck) {
        return productType != null && typeForCheck != null && typeForCheck.equalsIgnoreCase(productType);
    }

    /**
     * Check if Extended Enterprise Support product Level is supported on selected number of digital lines on Account
     *
     * @param eesQLI
     * @param serviceQLI
     *
     * @return
     */
    public static Boolean isExtendedEnterpriseSupportInRange(Product2 eesProduct, QuoteLineItem serviceQLI) {
        if (eesProduct == null || serviceQLI == null) {
            return false;
        }
        Decimal servcePlanResultingQuantity = QuoteLineItemHelper.getResultingQuantity(serviceQLI);

        return eesProduct.Seat_Range_Min__c <= servcePlanResultingQuantity
            && eesProduct.Seat_Range_Max__c >= servcePlanResultingQuantity;
    }

    /**
     * Check if product family is "Taxes"
     *
     * @param product
     *
     * @return
     */
    public static Boolean isTaxes(Product2 product) {
        return product != null && product.Family == FAMILY_TAXES;
    }

    public static Boolean isTaxes(QuoteLineItem qli) {
        return qli != null && qli.Product_Family__c == FAMILY_TAXES;
    }

    public static Boolean isTechnical(Product2 product) {
        return product != null && product.Family == Product2Helper.FAMILY_TECHNICAL;
    }

    /**
     * Returns a Set of Features that shouldn't be available for Opportunity with provided Record Type Name
     * Uses Opportunity Record Type Availability Custom Setting
     *
     * @param opportunityRecordTypeName
     *
     * @return
     */
    public static Set<Decimal> getFeaturesUnavailableForOpportunity(String opportunityRecordTypeName) {
        Map<String, Opportunity_Record_Type_Availability__c> opportunityRecordTypeAvailability =
                Opportunity_Record_Type_Availability__c.getAll();
        Set<Decimal> featuresToExcludeSet = new Set<Decimal>();

        // Exclude Products by feature using Opportunity Record Type Availability custom setting
        if (String.isNotBlank(opportunityRecordTypeName)) {
            for (String itemName : opportunityRecordTypeAvailability.keySet()) {
                Opportunity_Record_Type_Availability__c item = opportunityRecordTypeAvailability.get(itemName);

                List<String> recordTypes = item.RecordType__c.split(';');

                for (String rtToDisable : recordTypes) {

                    if (String.isNotBlank(rtToDisable) &&
                            item.Feature__c != null &&
                            rtToDisable.trim().equalsIgnoreCase(opportunityRecordTypeName)) {
                        featuresToExcludeSet.add(item.Feature__c);
                    }

                }
            }
        }

        return featuresToExcludeSet;
    }

    public static Boolean isPhone(QuoteLineItem qli) {
        return qli != null && qli.Product2 != null && ((new Set<Decimal>{FEATURE_REFURBISHED_PHONES, FEATURE_DISCOUNTED_PHONES}).contains(qli.Product2.Feature__c));
    }

    public static Boolean isRentalPhone(QuoteLineItem qli) {
        return qli != null && qli.Product2 != null && ((new Set<String>{
            FAMILY_RENTAL_PHONES,
            FAMILY_GLOBAL_OFFICE_RENTAL,
            FAMILY_LIMITED_EXTENSION_RENTAL_PHONE,
            FAMILY_COMMON_RENTAL_PHONES,
            FAMILY_GLOBAL_OFFICE_LIMITED_EXTENSION_RENTAL_PHONE})
        .contains(qli.Product2.Family));
    }

    public static Boolean isMobileUser(QuoteLineItem qli) {
        return qli != null && qli.Product2 != null && qli.Product2.ExtID__c == MOBILE_USER_ELEMENT_ID;
    }

    public static Boolean isProductApplicableForSyncWithNGBS(Product2 product) {
        Set <String> PRODUCT_SUBCATEGORIES = new Set <String> {
            SUBCATEGORY_CC_PROSERV,
            SUBCATEGORY_CONTACT_CENTER,
            SUBCATEGORY_RC_CONTACT_CENTER
        };
        Set <String> PRODUCT_FAMILIES = new Set <String> {
            FAMILY_FEE,
            FAMILY_TAXES,
            FAMILY_OVERAGE,
            FAMILY_TECHNICAL_LICENSE
        };
        return product != null
            && !PRODUCT_SUBCATEGORIES.contains(product.Sub_Category__c)
            && !(product.Sub_Category__c == SUBCATEGORY_PROSERV && product.Charge_Term__c == CHARGE_TERM_ONE_TIME)
            && !PRODUCT_FAMILIES.contains(product.Family);
    }

    public static Boolean isUsageLicense(Product2 prod) {
        return prod != null && BILLING_TYPE_USAGE.equalsIgnoreCase(prod.Billing_Type__c);
    }

    public static Boolean isRecurringLicense(Product2 prod) {
        return prod != null && BILLING_TYPE_RECURRING.equalsIgnoreCase(prod.Billing_Type__c);
    }

    public static String getGoaGroup(String goaGroupJson) {
        String goaGroup = 'Default';
        if (String.isBlank(goaGroupJson)) {
            return goaGroup;
        }
        Map<String, String> goaGroupInfo = new Map<String, String>();
        try {
            goaGroupInfo = (Map<String, String>) JSON.deserialize(
                goaGroupJson,
                Map<String, String>.class
            );
        } catch (Exception ex) {
            // TODO: handle different goa v3 structures(e.g. "Calling Credits Package 2000")
            // throw new ProductDataException('Error during GOA_Group_V3__c deserialization.', ex);
        }
        if (goaGroupInfo.containsKey('regular')) {
            goaGroup = goaGroupInfo.get('regular');
        }
        return goaGroup;
    }

    public static Boolean isOverage(Product2 product) {
        return FAMILY_OVERAGE.equalsIgnoreCase(product?.Family);
    }

    public static Boolean isActiveStorage(Product2 product) {
        return CATID_ADDITIONAL_STORAGES.contains(product?.CatID__c);
    }

    public static Boolean isGlobalSeat(Product2 product) {
        return CATID_GLOBAL_SEATS.contains(product?.CatID__c);
    }

    public static String getCCBundleTypeName(Product2 product) {
        if (!isCCProduct(product)) {
            return null;
        }
        if (product.Product_Type__c == PRODUCT_TYPE_AI) {
            return 'Inbenta';
        } else if (PRODUCT_TYPES_US_UK_TRANSPORT.contains(product.Product_Type__c)
                || QuoteLineItemHelper.isEuropeTransportType(product.Product_Type__c, PRODUCT_TYPES_EU_TRANSPORT)) {
            return 'Minutes';
        } else if (PRODUCT_TYPES_BUNDLES.contains(product.Product_Type__c)) {
            return product.Product_Type__c;
        }
        return null;
    }

    public static Decimal getCCBundleVolume(Product2 product) {
        if (!isCCProduct(product) || product.Name == null) {
            return null;
        }
        final Matcher matcher = BUNDLE_VOLUME_PATTERN.matcher(product.Name);
        if (!matcher.find()) {
            return null;
        }
        return Decimal.valueOf(matcher.group()?.remove(','));
    }

    public static Boolean isShippingTypeAuto(Product2 prod) {
        return prod != null && prod.ShippingType__c == SHIPPING_TYPE_AUTO;
    }

    public static Boolean isShippingTypeManual(Product2 prod) {
        return prod != null && prod.ShippingType__c == SHIPPING_TYPE_MANUAL;
    }

    // businessIdentity is a string from BusinessIdentity__c field of Quote or Opportunity with format {"currency":"USD","biId":"123"}
    public static List<LicensesLabelsOverride__c> getLicensesLabelsOverridesForBusinessIdentity(String businessIdentity) {
        String businessIdentityId = QuoteHelper.getBusinessIdentity(businessIdentity)?.biId;
        return getLicensesLabelsOverrideMap()?.get(businessIdentityId);
    }

    public static Boolean isInitialOrderTypeManual(Product2 prod, List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings) {
        String initialOrderType = getOrderTypeByLabelsOverrideSetting(LICENSES_LABELS_OVERRIDE_INITIAL_ORDER_TYPE, prod, licensesLabelsOverrideSettings);
        return isOrderTypeManual(initialOrderType);
    }

    public static Boolean isInitialOrderTypeAuto(Product2 prod, List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings) {
        String initialOrderType = getOrderTypeByLabelsOverrideSetting(LICENSES_LABELS_OVERRIDE_INITIAL_ORDER_TYPE, prod, licensesLabelsOverrideSettings);
        return isOrderTypeAuto(initialOrderType);
    }

    public static Boolean isUpsellTypeManual(Product2 prod, List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings) {
        String upsellType = getOrderTypeByLabelsOverrideSetting(LICENSES_LABELS_OVERRIDE_UPSELL_TYPE, prod, licensesLabelsOverrideSettings);
        return isOrderTypeManual(upsellType);
    }

    public static Boolean isUpsellTypeAuto(Product2 prod, List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings) {
        String upsellType = getOrderTypeByLabelsOverrideSetting(LICENSES_LABELS_OVERRIDE_UPSELL_TYPE, prod, licensesLabelsOverrideSettings);
        return isOrderTypeAuto(upsellType);
    }

    private static Map<String, List<LicensesLabelsOverride__c>> getLicensesLabelsOverrideMap() {
        Map<String, List<LicensesLabelsOverride__c>> licensesLabelsOverrideMap = new Map<String, List<LicensesLabelsOverride__c>>();
        for (LicensesLabelsOverride__c record : LicensesLabelsOverride__c.getAll().values()) {
            if (!licensesLabelsOverrideMap.containsKey(record.BusinessIdentityId__c)) {
                licensesLabelsOverrideMap.put(record.BusinessIdentityId__c, new List<LicensesLabelsOverride__c>());
            }
            licensesLabelsOverrideMap.get(record.BusinessIdentityId__c).add(record);
        }
        return licensesLabelsOverrideMap;
    }

    private static String getOrderTypeByLabelsOverrideSetting(String orderType, Product2 prod, List<LicensesLabelsOverride__c> licensesLabelsOverrideSettings) {
        String productOrderTypeValue = StringHelper.safeString(prod?.get(LICENSES_LABELS_OVERRIDE_ORDER_TYPES.get(orderType)));
        String orderTypeValue = productOrderTypeValue;

        if (licensesLabelsOverrideSettings == null || licensesLabelsOverrideSettings.isEmpty()) {
            return orderTypeValue;
        }

        for (LicensesLabelsOverride__c setting : licensesLabelsOverrideSettings) {
            if (setting.Label__c == orderType && setting.OriginalValue__c == productOrderTypeValue) {
                orderTypeValue = setting.OverrideValue__c;
            }
        }

        return orderTypeValue;
    }

    private static Boolean isOrderTypeManual(String orderType) {
        return orderType == ORDER_TYPE_MANUAL;
    }

    private static Boolean isOrderTypeAuto(String orderType) {
        return orderType == ORDER_TYPE_AUTO;
    }

    public static Boolean isProfessionalServiceProduct(Product2 product) {
        if (product == null) {
            return false;
        }
        String productGroup = StringHelper.safeString(product.Group__c);
        String productSubGroup = StringHelper.safeString(product.Subgroup__c);
        return productGroup.equalsIgnoreCase(GROUP_PROSERV) && productSubGroup.equalsIgnoreCase(SUBGROUP_PROSERV);
    }
}