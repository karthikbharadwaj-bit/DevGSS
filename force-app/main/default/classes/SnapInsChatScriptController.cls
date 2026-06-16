public with sharing class SnapInsChatScriptController {
	public Boolean showContent {get {return true;} set;}
    public String content {get; set;}

    private String source {
        get {
            if (source == null) {
                source = 'GW';
            }
            return source;
        } set;
    }

    private final String SOURCE_ARCHIVE = 'SnapInsScripts';

    public SnapInsChatScriptController() {
        try {
           source = ApexPages.currentPage().getParameters().get('source');
        } catch(Exception ex) {
            System.debug('Source is not specified, set the script to the default value');
        }

        try {
            StaticResource sr = [SELECT Id, NamespacePrefix, SystemModstamp
                            FROM StaticResource
                            WHERE Name = 'SnapInsScripts'
                            LIMIT 1];

            String prefix = sr.NamespacePrefix;

            if( String.isEmpty(prefix) ) {
                prefix = '';
            } else {
                prefix += '__';
            }
            String srPath = '/resource/' + sr.SystemModstamp.getTime() +
                            '/' + prefix + SOURCE_ARCHIVE + '/' + String.escapeSingleQuotes(source) + '.js';
            PageReference pg = new PageReference( srPath );
            if (Test.IsRunningTest()) {
                if(source == 'NOTEXISTS') {
                    content = '';
                } else {
                    content = fixContentLabels('TEST CONTENT');
                }
            } else {
                content = fixContentLabels(pg.getContent().toString());
            }
        } catch (Exception ex) {
            content = '';
        }
    }

    @TestVisible
    private String fixContentLabels(String content) {
        /* Fixing Labels and change firstname*/
        if(content != null) {
            List<SnapInsIndividualSettings__c> allSnapInsSettings = SnapInsIndividualSettings__c.getall().values();          
            String nameSnapInsSetting = 'GW'; // default is GW
            for (SnapInsIndividualSettings__c settings: allSnapInsSettings) {
                if(settings.Name == source) {
                    nameSnapInsSetting = source;
                    break;
                }
            }            
            SnapInsIndividualSettings__c snapInsIndividualSettings = SnapInsIndividualSettings__c.getValues(nameSnapInsSetting);            
       
            SnapInsSettings__c snapInsSettings = SnapInsSettings__c.getInstance();
            String BASE_LIVE_AGENT_URL = SnapInsSettings__c.getInstance().LiveAgentAvailabilityURL__c;
            try {
            	BASE_LIVE_AGENT_URL = BASE_LIVE_AGENT_URL.substring(0, BASE_LIVE_AGENT_URL.indexOf('/rest/Visitor/Availability')); 
            } catch(Exception ex) {
                System.debug('LiveAgentAvailabilityURL__c is not in right: should contains /rest/Visitor/Availability');
            }            
          
            /* change custom settings */
            content = content.replace('BASE_CORE_URL__c', snapInsSettings.BaseCoreURL__c);            
            content = content.replace('BASE_LIVE_AGENT_CONTENT_URL__c', snapInsSettings.BaseLiveAgentContentURL__c);
            content = content.replace('BASE_LIVE_AGENT_URL__c', BASE_LIVE_AGENT_URL);
            content = content.replace('BUTTON_ID_US_Team_All__c', snapInsSettings.USTeamAllButtonID__c);
            content = content.replace('COMMUNITY_ENDPOINT_URL__c', snapInsSettings.CommunityEndpointURL__c);            
            content = content.replace('DEPLOYMENT_ID__c', snapInsSettings.DeploymentID__c);
            content = content.replace('ORG_ID__c', snapInsSettings.OrgID__c);            
            
            content = content.replace('BUTTON_ID__c', snapInsIndividualSettings.ButtonID__c);
            content = content.replace('ESW_CONFIG_DEV_NAME__c', snapInsIndividualSettings.ESW_ConfigDevName__c);            
            content = content.replace('ESW_LIVE_AGENT_DEV_NAME__c', snapInsIndividualSettings.ESW_LiveAgentDevName__c);
            
            /* Change FirstName For Adaptive snap-ins invitation*/
            content = content.replace('PLACEHOLDER_FIRSTNAME', getName() == null ? 'Guest' : getName());
        }
        return content;
    }

    @TestVisible
    private static String getName(){
        if(UserInfo.getUserType() == 'Guest'){
            return 'Guest';
        }else{
            return UserInfo.getFirstName();
        }
    }
}