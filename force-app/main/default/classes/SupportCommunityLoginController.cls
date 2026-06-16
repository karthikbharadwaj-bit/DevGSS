global without sharing class SupportCommunityLoginController {
    @RemoteAction
    global static List<String> getDomains() {
        List<String> outDomains = new List<String>();
        List<SCLoginDomains__c> domains = SCLoginDomains__c.getall().values();
        for (SCLoginDomains__c domain: domains) {
            outDomains.add(domain.Domain__c);
        }
        return outDomains;
    }
}