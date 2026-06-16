@isTest
public class Test_SupportCommunityLoginController {
    @TestSetup
    private static void initCustomSetting() {
        upsert new SCLoginDomains__c(
            Name = 'Test',
            Domain__c = 'https://www.test.com'
        );
    }
    
    @isTest static void testGetDomains() {
        List<String> outDomains = new List<String>();
        outDomains.add('https://www.test.com');
        System.assertEquals(SupportCommunityLoginController.getDomains(), outDomains, 'Result getDomains() should be list with value https://www.test.com');
    }
}