public with sharing class ContactHelper {
    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Contact.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }


    public static Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID {
        get {
            if(RT_INFO_BY_ID == null) {
                RT_INFO_BY_ID = DESCRIBE.getRecordTypeInfosById();
            }
            return RT_INFO_BY_ID;
        }
        set;
    }

    public static final String RT_NAME_VAR_VISIBLE = 'VAR Visible';
    public static final String RT_NAME_INTERNAL = 'Internal';

    public static final Id RT_ID_VAR_VISIBLE = RT_INFO_BY_NAME.get(RT_NAME_VAR_VISIBLE).getRecordTypeId();
    public static final Id RT_ID_INTERNAL = RT_INFO_BY_NAME.get(RT_NAME_INTERNAL).getRecordTypeId();

    public static final String PREFERRED_LANGUAGE_EN_US = 'en_US';

    // Contact_Funnel_Type__c
    public static final String FUNNEL_TYPE_ACQUISITION = 'Acquisition';

    // Contact_Status__c
    public static final String CONTACT_STATUS_WORKING_OPP = '3. Working Opp';
    public static final String CONTACT_STATUS_DOWNGRADED = '0. Downgraded';
    public static final String CONTACT_STATUS_SUSPECT = 'X. Suspect';

    public static final Set<String> INVALID_CONTACT_STATUSES = new Set<String> {
        CONTACT_STATUS_DOWNGRADED,
        CONTACT_STATUS_SUSPECT,
        null
    };
    
    public static Boolean IS_DO_NOT_CONTACT_EVENT = false;

    public static final String CONTACT_PHONE_NOT_IN_RANGE = 'Contact Phone Length should be between 7 and 32 symbols, please update Contact Phone.';

    public static Boolean isPartnerSoldEnterpriseSupport(Contact contactRecord) {

        Boolean accountBrandBelongsToPartnerSupportBrands = false;
        for (Partner_Support_brand__mdt partnerSupportBrand : Partner_Support_brand__mdt.getAll().values()) {
            if (partnerSupportBrand.value__c.equalsIgnoreCase(contactRecord.Account.RC_Brand__c)) {
                accountBrandBelongsToPartnerSupportBrands = true;
                break;
            }
        }

        List<Entitlement> activeEntitlements = (List<Entitlement>) new SupportEntitlementSelector()
            .selectSupportEntitlementsByAccountIds(new Set<Id>{contactRecord.AccountId}).executeQuery();

        return contactRecord.Account.Total_MRR__c > 0
            && accountBrandBelongsToPartnerSupportBrands
            && !activeEntitlements.isEmpty();
    }

    @InvocableMethod(label='Set Reset Global Variable'
                     description='This method sets or resets Do not contact Global variable value')
    public static void setResetGlobalVariable(List<Boolean> fieldValues) {
        if (fieldValues != null && !fieldValues.IsEmpty()) {
            IS_DO_NOT_CONTACT_EVENT = fieldValues[0];
        }
    }
}