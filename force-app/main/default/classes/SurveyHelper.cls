public with sharing class SurveyHelper {
    public static final String SURVEY_TYPE_PORTING = 'Porting';
    public static final String SURVEY_TYPE_SUPPORT_CSAT = 'Support CSAT';
    public static final String SURVEY_TYPE_VAR_SUPPORT_CSAT = 'VAR Support CSAT';
    public static final String SURVEY_TYPE_PORTING_PHONE_SUPPORT = 'Porting Phone Support';
    public static final String SURVEY_TYPE_BIZ_SERV_CRM = 'BizServ CRM';
    public static final String SURVEY_TYPE_IT_HELPDESC_CSAT = 'IT Helpdesk CSAT';
    public static final String SURVEY_TYPE_IT_HELPDESK_SUPPORT = 'IT Deskside Support';
    public static final String SURVEY_TYPE_IT_INFRASTRUCTURE = 'IT Infrastructure';
    public static final String SURVEY_TYPE_MEDALLIA_SUPPORT = 'Support';
    public static final Set<String> SURVEY_TYPES_FOR_PORTING_AND_CSAT_CASE = new Set<String> {
        SURVEY_TYPE_PORTING,
        SURVEY_TYPE_SUPPORT_CSAT,
        SURVEY_TYPE_VAR_SUPPORT_CSAT,
        SURVEY_TYPE_PORTING_PHONE_SUPPORT
    };
    public static final Set<String> SURVEY_TYPES_FOR_SUPPORT_TO_SEND_SURVEYS = new Set<String> {
        SURVEY_TYPE_SUPPORT_CSAT,
        SURVEY_TYPE_PORTING_PHONE_SUPPORT,
        SURVEY_TYPE_VAR_SUPPORT_CSAT
    };
    public static final Set<String> SURVEY_TYPES_FOR_BIZSERV_TO_SEND_SURVEYS = new Set<String> {
        SURVEY_TYPE_BIZ_SERV_CRM
    };
    public static Set<String> SURVEY_TYPES_FOR_IT_TO_SEND_SURVEYS = new Set<String> {
        SURVEY_TYPE_IT_HELPDESC_CSAT,
        SURVEY_TYPE_IT_HELPDESK_SUPPORT,
        SURVEY_TYPE_IT_INFRASTRUCTURE
    };

    @TestVisible
    private static final String SURVEY_AGENT_EMAIL = 'surveyagent';

    public static Survey__c buildSurveyForCase(Case caseObj, String surveyType, Map<Id, User> usersMap, Map<Id, Contact> caseContactMap) {
        Boolean isPortingSurveyType = surveyType == SURVEY_TYPE_PORTING;
        Boolean isSurveyTypeFound = SURVEY_TYPES_FOR_PORTING_AND_CSAT_CASE.contains(surveyType);
        User ownerUser = usersMap.get(caseObj.OwnerId);
        return (Survey__c) new SObjectBuilder(Survey__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Survey__c.Case__c => caseObj.Id,
                Survey__c.Contact__c => caseObj.ContactId,
                Survey__c.Contact_Email__c => caseContactMap.get(caseObj.ContactId)?.Email,
                Survey__c.Name => surveyType + ' - ' + Datetime.now().format(),
                Survey__c.SurveyType__c => surveyType,
                Survey__c.Agent_Email__c => isPortingSurveyType ? getAgentEmail(caseObj, usersMap) : ownerUser?.Email,
                Survey__c.Agent__c => ownerUser?.Id,
                Survey__c.Agent_Name__c => ownerUser?.Name,
                Survey__c.Agent_Team__c => ownerUser?.Team__c,
                Survey__c.Account__c => caseObj.AccountId,
                Survey__c.Agent_Manager_Email__c => ownerUser?.Manager?.Email,
                Survey__c.Agent_Manager_Name__c => ownerUser?.Manager?.Name,
                Survey__c.OwnerId => BooleanHelper.toBoolean(usersMap.get(caseObj.CreatedById)?.IsActive) && isSurveyTypeFound ? caseObj.CreatedById : UserInfo.getUserId()
            })
            .build()
            .getRecord();
    }

    @TestVisible
    private static String getAgentEmail(Case caseObj, Map<Id, User> usersMap) {
        return usersMap.containskey(caseObj.OwnerId) ? usersMap.get(caseObj.OwnerId).Email : Emails__c.getValues(SURVEY_AGENT_EMAIL)?.Email_Address__c;
    }
}