@isTest
public class Test_SnapInsChatScriptController {
    
	@TestSetup
	private static void initCustomSettings() {
 		SnapInsSettings__c snapInsSettings = new SnapInsSettings__c(
			BaseCoreURL__c = 'https://www.test.com',
			BaseLiveAgentContentURL__c = 'https://www.test.com/content',
            LiveAgentAvailabilityURL__c = 'https://www.test.com/chat/rest/Visitor/Availability',
            USTeamAllButtonID__c = (String) ValueProviderBuilder.provideUniqueFixedLengthString(15).getValue(),
            CommunityEndpointURL__c = 'https://www.test.com/support',
            DeploymentID__c = (String) ValueProviderBuilder.provideUniqueFixedLengthString(15).getValue(), 
            OrgID__c = (String) ValueProviderBuilder.provideUniqueFixedLengthString(15).getValue()
		);
        upsert snapInsSettings;

        upsert new SnapInsIndividualSettings__c(
            Name = 'GW',
            ButtonID__c = (String) ValueProviderBuilder.provideUniqueFixedLengthString(15).getValue(),
            ESW_LiveAgentDevName__c = 'EmbeddedServiceLiveAgent_Test',
            ESW_ConfigDevName__c = 'Support_Community_Snap_In_GW'            
        );       
	}
    
	@isTest static void testFixContentLabels() {
		SnapInsChatScriptController snapInsChat = new SnapInsChatScriptController();
        System.assertEquals(snapInsChat.fixContentLabels('Test'), 'Test', 'The result of fix content labels is not equals Test'); 
	}
}