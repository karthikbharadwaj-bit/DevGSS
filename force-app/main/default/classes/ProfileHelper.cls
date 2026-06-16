public class ProfileHelper {

    // Profile IDs
    public static final Id PROFILE_ID_SYSADMIN = HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ');
    public static final Id PROFILE_ID_AUTOMATED_PROCESS_USER = HardcodedIdsMapper.getMatchedObjectId('00e80000001FhcFAAS');
    public static final Id PROFILE_ID_SUPPORT_T1 = HardcodedIdsMapper.getMatchedObjectId('00e2H000001OYUQ');
    //Overage High Volume Customer Portal License
    public static final Id PROFILE_ID_CUSTOMER_PORTAL_USER = HardcodedIdsMapper.getMatchedObjectId('00e80000001OK6k');
    //Customer Community Login License
    public static final Id PROFILE_ID_CUSTOMER_COMMUNITY_LOGIN_USER_CUSTOM = HardcodedIdsMapper.getMatchedObjectId('00e4F000000Dfmk');

    public static final String SYSTEM_ADMIN = 'System Administrator';
    public static final String IT_HELPDESK_COMMUNITY_LOGIN = 'IT Helpdesk Community Login';
    // obsolete profile

    public static final Set<String> IT_HELPDESK_PROFILES = new Set<String>{
        IT_HELPDESK_COMMUNITY_LOGIN
    };

    // Profile Names
    public static final String PROFILE_NAME_DEAL_DESK_LIGHTNING = 'Deal Desk Lightning';
    public static final String PROFILE_NAME_DEAL_DESK_LIGHTNING_EU_RESTRICTED = 'Deal Desk Lightning - EU Restricted';
    public static final String PROFILE_NAME_DEAL_DESK = 'Deal Desk';
    public static final String PROFILE_NAME_CERT_LIGHTNING = 'CERT - Lightning';
    public static final String PROFILE_NAME_CERT_WINBACK_LIGHTNING = 'CERT Winback - Lightning';
    public static final String PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING = 'Channel Sales Manager - Lightning';
    public static final String PROFILE_NAME_CHANNEL_SALES_LIGHTNING = 'Channel Sales - Lightning';
    public static final String PROFILE_NAME_CHANNEL_OPERATIONS_LIGHTNING = 'Channel Operations - Lightning';
    public static final String PROFILE_NAME_SALES_OPERATIONS_LIGHTNING = 'Sales Operations Lightning';
    public static final String PROFILE_NAME_SALES_OPERATIONS_LIGHTNING_EU_RESTRICTED = 'Sales Operations Lightning - EU Restricted';
    public static final String PROFILE_NAME_CRM_DEV_TEAM_ADMINISTRATOR = 'CRM Dev Team Administrator';
    public static final String PROFILE_NAME_CRM_SUPPORT_ENGINEER = 'CRM Support Engineer';
    public static final String PROFILE_NAME_CRM_QA_ENGINEER = 'CRM QA Engineer';
    public static final String PROFILE_NAME_CRM_DEVELOPER = 'CRM Developer';
    public static final String PROFILE_NAME_RELAYWARE = 'API Relayware V2';
    public static final String PROFILE_NAME_PROSERV_LIGHTNING = 'ProServ -Lightning';
    public static final String PROFILE_NAME_PROSERV_LIGHTNING_EU_RESTRICTED = 'ProServ -Lightning - EU Restricted'; // Added for EU Privacy Phase 3 - GSS Profile Changes
    public static final String PROFILE_NAME_CC_PROFESSIONAL_SERVICES = 'CC Professional Services';
    public static final String PROFILE_NAME_PRO_SERVICES = 'Professional Services Lightning';  //Added as part of profile consolidation of Professional Services
    public static final String PROFILE_NAME_SUPPORT_BACK_OFFICE = 'Support Back Office';   //Added as part of profile consolidation of Support Agent profiles - T1
    public static final String PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING = 'Sales Manager - Business Processing';
    public static final String PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES = 'Sales Manager w Insidesales';
    public static final String PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES = 'Sales Agent SDR w Insidesales';
    public static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = SYSTEM_ADMIN;
    public static final String PROFILE_NAME_SUPPORT_IMPLEMENTATIONS = 'Support Implementations';//added as part of  Profile  consolidation for Support Implementations
    public static final String PROFILE_NAME_SALES_4_IN_CONTACT_ORDER_LIGHTNING = 'Sales 4.0 inContact Order Lightning';
    public static final String PROFILE_NAME_SALES_4_IN_CONTACT_ORDER_LIGHTNING_EU_RESTRICTED = 'Sales 4.0 inContact Order Lightning - EU Restricted';
    public static final String PROFILE_NAME_SALES_ENGINEER_LIGHTNING = 'Sales Engineer Lightning';
    public static final String PROFILE_NAME_WWFS_REP_LIGHTNING = 'WWFS Rep - Lightning';
    public static final String PROFILE_NAME_SALES_ENGINEER_LIGHTNING_EU_RESTRICTED = 'Sales Engineer Lightning - EU Restricted';
    public static final String PROFILE_NAME_SALES_REP_LIGHTNING = 'Sales Rep - Lightning';
    public static final String PROFILE_NAME_SALES_REP_LIGHTNING_EU_RESTRICTED = 'Sales Rep - Lightning - EU Restricted';
    public static final String PROFILE_NAME_SALES_10_PLUS = 'Sales 10+';
    public static final String PROFILE_NAME_SALES_AGENT = 'Sales Agent';
    public static final String PROFILE_NAME_EXPANSION_LIGHTNING = 'Expansion - Lightning';
    public static final String PROFILE_NAME_PARTNER_SALES_SPECIALISTS_LIGHTNING = 'Partner Sales Specialists - Lightning';
    public static final String PROFILE_NAME_API_BIGDATA = 'API BigData';
    public static final String PROFILE_NAME_API_EVENTS_USER = 'API Events User';
    public static final String PROFILE_NAME_API_NOC = 'API NOC';
    public static final String PROFILE_NAME_API_ONLY_KNOWLEDGE_ARTICLES = 'API Only - Knowledge Articles';
    public static final String PROFILE_NAME_API_READ_ONLY = 'API Read-Only';
    public static final String PROFILE_NAME_API_STANDARD = 'API Standard';
    public static final String PROFILE_NAME_ANALYTICS_CLOUD_INTEGRATION_USER = 'Analytics Cloud Integration User';
    public static final String PROFILE_NAME_BUSINESS_SERVICES_ADVANCED = 'Business Services - Advanced';
    public static final String PROFILE_NAME_BUSINESS_SERVICES_EU_RESTRICTED = 'Business Services - EU Restricted'; // Deprecated as of EU Privacy Phase 3 - IT Profile Changes
    public static final String PROFILE_NAME_FINANCE_ADMIN = 'Finance Admin';
    public static final String PROFILE_NAME_COM_INTEGRATION_PROFILE = 'Com Integration Profile';//added as part of Biz Migration project
    public static final String PROFILE_NAME_BIZ_INTEGRATION_PROFILE = 'Biz Integration Profile';//added as part of Biz Migration project
    public static final String PROFILE_NAME_GW_API = 'GW API';
    public static final String PROFILE_NAME_MARKETO_INTEGRATION_PROFILE = 'Marketo Integration Profile';
    public static final String PROFILE_NAME_MINIMUM_ACCESS_SALESFORCE = 'Minimum Access - Salesforce';
    public static final String PROFILE_NAME_PROSERV_API = 'ProServ API';
    public static final String PROFILE_NAME_RC_ADMIN_USER = 'RC Admin User';
    public static final String PROFILE_NAME_READ_ONLY = 'Read Only';
    // Start of EU Privacy Phase 3 Sales Profile Changes
    public static final String PROFILE_NAME_CHANNEL_SALES_LIGHTNING_EU_RESTRICTED='Channel Sales - Lightning - EU Restricted';
    public static final String PROFILE_NAME_EXPANSION_LIGHTNING_EU_RESTRICTED = 'Expansion - Lightning - EU Restricted';
    public static final String PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING_EU_RESTRICTED = 'Sales Manager - Business Processing - EU Restricted';
    public static final String PROFILE_NAME_WWFS_REP_LIGHTNING_EU_RESTRICTED = 'WWFS Rep - Lightning - EU Restricted';
    public static final String PROFILE_NAME_SUPPORT_T1 = 'Support T1';

    public static final Set<String> INSIDE_SALES_PROFILES = new Set<String>{
        PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES,
        PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES,
        PROFILE_NAME_WWFS_REP_LIGHTNING,
        PROFILE_NAME_WWFS_REP_LIGHTNING_EU_RESTRICTED,
        PROFILE_NAME_SALES_REP_LIGHTNING,
        PROFILE_NAME_SALES_REP_LIGHTNING_EU_RESTRICTED
    };

  // EU Privacy Phase 3 IT Profile changes - START
    public static final String PROFILE_NAME_CRM_SUPPORT_ENGINEER_EU_RESTRICTED = 'CRM Support Engineer - EU Restricted';
    public static final String PROFILE_NAME_CRM_QA_ENGINEER_EU_RESTRICTED = 'CRM QA Engineer - EU Restricted';
    public static final String PROFILE_NAME_FINANCE_ADMIN_EU_RESTRICTED = 'Finance Admin - EU Restricted';
    public static final String PROFILE_NAME_BUSINESS_SERVICES_ADVANCED_EU_RESTRICTED = 'Business Services - Advanced - EU Restricted';
    // EU Privacy Phase 3 IT Profile changes - END

    public static final Set<String> ALL_SALES_PROFILES = new Set<String>{
        PROFILE_NAME_CHANNEL_SALES_LIGHTNING,
        PROFILE_NAME_SALES_10_PLUS,
        PROFILE_NAME_SALES_AGENT,
        PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES,
        PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING,
        PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING_EU_RESTRICTED,
        PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES,
        PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING,
        PROFILE_NAME_WWFS_REP_LIGHTNING,
        PROFILE_NAME_PROSERV_LIGHTNING,
        PROFILE_NAME_PROSERV_LIGHTNING_EU_RESTRICTED, // Added for EU Privacy Phase 3 - GSS Profile Changes
        PROFILE_NAME_SALES_ENGINEER_LIGHTNING,
        PROFILE_NAME_SALES_ENGINEER_LIGHTNING_EU_RESTRICTED,
        PROFILE_NAME_SALES_REP_LIGHTNING,
        PROFILE_NAME_SALES_REP_LIGHTNING_EU_RESTRICTED,
        PROFILE_NAME_EXPANSION_LIGHTNING,
        PROFILE_NAME_EXPANSION_LIGHTNING_EU_RESTRICTED,
        PROFILE_NAME_PARTNER_SALES_SPECIALISTS_LIGHTNING,
        PROFILE_NAME_SALES_OPERATIONS_LIGHTNING,
        PROFILE_NAME_CHANNEL_SALES_LIGHTNING_EU_RESTRICTED,
        PROFILE_NAME_SALES_OPERATIONS_LIGHTNING_EU_RESTRICTED,
        PROFILE_NAME_WWFS_REP_LIGHTNING_EU_RESTRICTED
    };

    public static final Set<String> ADMIN_OR_CRM_PROFILES = new Set<String> {
        PROFILE_NAME_API_BIGDATA,
        PROFILE_NAME_API_EVENTS_USER,
        PROFILE_NAME_API_NOC,
        PROFILE_NAME_API_ONLY_KNOWLEDGE_ARTICLES,
        PROFILE_NAME_API_READ_ONLY,
        PROFILE_NAME_RELAYWARE,
        PROFILE_NAME_API_STANDARD,
        PROFILE_NAME_ANALYTICS_CLOUD_INTEGRATION_USER,
        PROFILE_NAME_BUSINESS_SERVICES_ADVANCED,
        // Removing the below as this profile is renamed to PROFILE_NAME_BUSINESS_SERVICES_ADVANCED_EU_RESTRICTED as part of EU Privacy Phase 3 - IT Profile Changes  
        //PROFILE_NAME_BUSINESS_SERVICES_EU_RESTRICTED,
        PROFILE_NAME_BUSINESS_SERVICES_ADVANCED_EU_RESTRICTED, // Added for EU Privacy Phase 3 - IT Profile Changes
        PROFILE_NAME_CRM_DEV_TEAM_ADMINISTRATOR,
        PROFILE_NAME_CRM_DEVELOPER,
        PROFILE_NAME_CRM_QA_ENGINEER,
        PROFILE_NAME_CRM_QA_ENGINEER_EU_RESTRICTED, // Added for EU Privacy Phase 3 - IT Profile Changes         
        PROFILE_NAME_FINANCE_ADMIN,
        PROFILE_NAME_FINANCE_ADMIN_EU_RESTRICTED, // Added for EU Privacy Phase 3 - IT Profile Changes 
        PROFILE_NAME_GW_API,
        PROFILE_NAME_MARKETO_INTEGRATION_PROFILE,
        PROFILE_NAME_MINIMUM_ACCESS_SALESFORCE,
        PROFILE_NAME_PROSERV_API,
        PROFILE_NAME_RC_ADMIN_USER,
        PROFILE_NAME_READ_ONLY,
        PROFILE_NAME_SALES_ENGINEER_LIGHTNING,
        PROFILE_NAME_SALES_ENGINEER_LIGHTNING_EU_RESTRICTED
    };
    public static final Set<String> CRM_PROFILES = new Set<String> {
        PROFILE_NAME_CRM_DEVELOPER,
        PROFILE_NAME_CRM_DEV_TEAM_ADMINISTRATOR,
        PROFILE_NAME_CRM_QA_ENGINEER,
        PROFILE_NAME_CRM_QA_ENGINEER_EU_RESTRICTED, // Added for EU Privacy Phase 3 - IT Profile Changes                                                
        PROFILE_NAME_CRM_SUPPORT_ENGINEER,
        PROFILE_NAME_CRM_SUPPORT_ENGINEER_EU_RESTRICTED, // Added for EU Privacy Phase 3 - IT Profile Changes 
        PROFILE_NAME_COM_INTEGRATION_PROFILE // Added New Integration Profile to Skip Validation
    };

    public static final Set<String> EXCLUSION_PROFILES = new Set<String> {
        PROFILE_NAME_SYSTEM_ADMINISTRATOR,
        PROFILE_NAME_CRM_DEVELOPER,
        PROFILE_NAME_CRM_QA_ENGINEER,                                             
        PROFILE_NAME_CRM_SUPPORT_ENGINEER
    };

    public static Map<Id, String> ADMIN_OR_SALES_PROFILE_ID_TO_NAME {
        get {
            if (ADMIN_OR_SALES_PROFILE_ID_TO_NAME != null) {
                return ADMIN_OR_SALES_PROFILE_ID_TO_NAME;
            }

            ADMIN_OR_SALES_PROFILE_ID_TO_NAME = new Map<Id, String>();
            List<Profile> adminOrSalesProfiles = (List<Profile>) new ProfileSelector()
                .selectProfilesByNames(new List<Object>{ADMIN_OR_CRM_PROFILES})
                .executeQuery();
            for (Profile profile : adminOrSalesProfiles) {
                ADMIN_OR_SALES_PROFILE_ID_TO_NAME.put(profile.Id, profile.Name);
            }
            return ADMIN_OR_SALES_PROFILE_ID_TO_NAME;
        }
        private set;
    }

    public static final Set<String> DEAL_DESK_PROFILES = new Set<String> {
        PROFILE_NAME_DEAL_DESK_LIGHTNING,
        PROFILE_NAME_DEAL_DESK
    };

    public static final Map<Id, Profile> CRM_PROFILES_MAP = new Map<Id, Profile>(
        (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object> {CRM_PROFILES})
            .executeQuery()
    );

    /**
     * Checks if current User is System Administrator
     *
     * @return true || false
     */
    public static Boolean isCurrentUserSysAdmin() {
        return isSysAdmin(UserInfo.getProfileId());
    }

    /**
     * Checks if specified profile Id is System Administrator
     *
     * @param userProfileId
     *
     * @return true || false
     */
    public static Boolean isSysAdmin(Id userProfileId) {
        return PROFILE_ID_SYSADMIN == userProfileId;
    }

    /**
     * Checks if specified profile Id is Support T1
     *
     * @param userProfileId
     *
     * @return true || false
     */
    public static Boolean isSupportT1Profile(Id userProfileId) {
        return PROFILE_ID_SUPPORT_T1 == userProfileId;
    }

    public static Boolean isCrmProfile(Id userProfileId) {
        return CRM_PROFILES_MAP.containsKey(userProfileId);
    }

    public static Profile getCurrentUserProfile() {
        return (Profile) new ProfileSelector()
            .selectProfileById(new List<Id>{UserInfo.getProfileId()})
            .executeQuery()
            .get(0);
    }
    
    public static Profile getCurrentUserProfileWithCache() {
        Profile currentUserProfileRecord = null;
        String profileId = UserInfo.getProfileId();
        if(PlatformCacheUtility.contains(PlatformCacheUtility.SESSION_CACHE,profileId,PlatformCacheUtility.CURRENT_USER_SESSION_DATA)){
            currentUserProfileRecord = (Profile)PlatformCacheUtility.getDynamicRecord(PlatformCacheUtility.SESSION_CACHE,UserInfo.getProfileId(),PlatformCacheUtility.CURRENT_USER_SESSION_DATA,Constants.CONST_PROFILE);
        }
        else {
            List<Profile> profiles = (List<Profile>) new ProfileSelector()
                .selectProfileById(new List<Object>{profileId})
                .executeQuery();
            if(!profiles.isEmpty()){
                currentUserProfileRecord = profiles.get(0);
                if(currentUserProfileRecord != null){
                    PlatformCacheUtility.put(PlatformCacheUtility.SESSION_CACHE,profileId,currentUserProfileRecord,PlatformCacheUtility.CURRENT_USER_SESSION_DATA);
                }
            }
        }
        return currentUserProfileRecord;
    }
    
}