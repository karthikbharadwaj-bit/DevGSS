public with sharing class LeadHelper {

    public static final Set<String> SYSTEM_USERS = new Set<String>{'lar system user','leandata queue'};

    public static final String LEAD_SOURCE_INBOUND_CALL = 'Inbound Call';
    public static final String LEAD_SOURCE_INBOUND_CHAT = 'Inbound Chat';
    public static final String LEAD_SYSTEM_SOURCE_INBOUND_CALL = 'Smart Search – Inbound Call';
    public static final String LEAD_SYSTEM_SOURCE_INBOUND_CHAT = 'Smart Search – Inbound Chat';

    public static final String INVOCA = 'Invoca';

    public static final String CAMPAIGNBROKENATTRIBUTION= 'Broken Attribution';
    public static final String CAMPAIGNINVOCAWALKON = 'Digital_Invoca_WalkOn';
    public static final String CAMPAIGNINVOCAMISSINGATTRIBUTION = 'Digital_Invoca_Missing_Attribution';
    public static final String CAMPAIGNSALESGENERATED = 'Sales Generated';

    public static final String STATUS_DOWNGRADED = '0. Downgraded';
    public static final String STATUS_RENEW = '.5 Re-New';
    public static final String STATUS_NEW = '1. New';
    public static final String STATUS_CALL_OUT = '1.5 Call Out';

    public static final String RT_NAME_SALES_LEADS = 'Sales Leads';
    public static final String RT_NAME_PARTNER_LEADS = 'Partner Leads';

    public final static String DEFAULT_COUNTRY = 'United States';

    public static final String ATBC_STAGE_CANCELLED = 'Canceled';
    public static final String ATBC_STAGE_CLOSED = 'Closed';

    public static final String DOWNGRADE_LOW_POTENTIAL = 'Low Potential - Save For Notes';
    public static final String DOWNGRADE_RETENTION_LEAD_CLOSED = 'Retention Lead Closed';
    public static final String ERROR_MESSAGE_MERGE_TO_CONTACT_PROCESS = 'An error has ocurred during the merge to contact process. Please contact your salesforce administrator.';

    public static List<String> listOfStatusLessThan2Contacted {
        get {
            if (listOfStatusLessThan2Contacted != null ) {
                return listOfStatusLessThan2Contacted;
            }
            listOfStatusLessThan2Contacted = new List<String>();
            List<PreContactedStatus__mdt> preContactedStatusList = PreContactedStatus__mdt.getAll().values();
            for (PreContactedStatus__mdt preContactedStatus : preContactedStatusList) {
                listOfStatusLessThan2Contacted.add(preContactedStatus.label);
            }
            return listOfStatusLessThan2Contacted;
        }
        private set;
    }

    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Lead.SObjectType.getDescribe();
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

    public static final Id RT_ID_SALES_LEADS = RT_INFO_BY_NAME.get(RT_NAME_SALES_LEADS).getRecordTypeId();
    public static final Id RT_ID_PARTNER_LEADS = RT_INFO_BY_NAME.get(RT_NAME_PARTNER_LEADS).getRecordTypeId();

    public static void updateLeadSystemSource(Lead sourceLead, Lead leadToUpdate) {
        if(!String.isBlank(sourceLead.LeadSource) && leadToUpdate.Lead_System_Source__c==null) {
            if(sourceLead.LeadSource.equals(LEAD_SOURCE_INBOUND_CALL)) {
                leadToUpdate.Lead_System_Source__c = LEAD_SYSTEM_SOURCE_INBOUND_CALL;
            }

            if(sourceLead.LeadSource.equals(LEAD_SOURCE_INBOUND_CHAT)) {
                leadToUpdate.Lead_System_Source__c = LEAD_SYSTEM_SOURCE_INBOUND_CHAT;
            }
        }

        if(String.isBlank(leadToUpdate.Lead_System_Source__c)){
            leadToUpdate.Lead_System_Source__c = UserInfo.getName();
		}
        if(leadToUpdate.isClone()){
            leadToUpdate.Lead_System_Source__c = 'Lead Clone Button';
        }
	}

    public static Boolean isAvaya(Lead lead) {
        return lead != null && lead.Lead_Brand_Name__c == RingCentralHelper.BRAND_AVAYA;
    }

    @AuraEnabled
    public static Response getLeadNameById(Id leadId){
        Response res = new Response();
        Lead lead = (Lead) new LeadSelector()
            .selectLeadById(new List<Id>{ leadId })
            .executeQuery()
            .get(0);

        res.setData('Name', lead.Name);
        return res;
    }
    
    public static Boolean isValidWebsite(String inputString) {
        if (String.isNotBlank(inputString)) {
            inputString = inputString.toLowerCase();
            String blockedDomains = '(facebook\\.com|google\\.com|microsoft\\.com|apple\\.com|youtube\\.com|wikipedia\\.org|amazon\\.com|instagram\\.com|tiktok\\.com|linkedin\\.com|twitter\\.com|reddit\\.com|bbc\\.com|netflix\\.com|example\\.com|test\\.com|demo\\.com|sample\\.com|placeholder\\.com|mywebsite\\.com|yourwebsite\\.com)';
            String websiteRegex = '^(https?:\\/\\/)?(www\\.)?[a-zA-Z0-9]+(\\.[a-zA-Z0-9-]+)+(?!\\.\\.)' +
                                  '(\\:\\d+)?(\\/(?!.*[\\/\\.\\%\\$&@*]{2,})([^?\\s\\/]*[^?\\s\\/\\.\\%\\$&]))*(\\?[a-zA-Z0-9=&]*)?$';
            String blockedRegex = '^(https?:\\/\\/)?(www\\.)?' + blockedDomains + '$';
            Pattern websitePattern = Pattern.compile(websiteRegex);
            Matcher websiteMatcher = websitePattern.matcher(inputString);
            Pattern blockedPattern = Pattern.compile(blockedRegex);
            Matcher blockedMatcher = blockedPattern.matcher(inputString);
            if (!websiteMatcher.matches() || blockedMatcher.matches()) {
                return false;
            }
        }
        return true;
    }

}