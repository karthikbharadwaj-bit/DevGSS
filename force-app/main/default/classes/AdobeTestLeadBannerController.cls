public with sharing class AdobeTestLeadBannerController {   
    @AuraEnabled(cacheable=true)
    public static Marketing_Testing__c isAdobeTest(String objectId, String objectType) {
        List<Marketing_Testing__c> adobeTargets = new List<Marketing_Testing__c>();
        if (ObjectType == 'Lead') {
            Lead currentLead = (Lead) new LeadSelector()
            .selectLeadById(new List<Object>{ objectId })
            .selectFields(new List<String> {'Adobe_Target_Id__c'})
            .executeQuery()[0];

            if (currentLead != null) {
                adobeTargets = (List<Marketing_Testing__c>) new MarketingTestSelector()
                    .selectAdobeTargetIdBasedOnIdAndDates(
                        new List<Object>{ 
                            currentLead.Adobe_Target_Id__c, System.today()
                        }).executeQuery();
            }
        } else if (ObjectType == 'Contact') {

            Contact currentContact = (Contact) new ContactSelector()
            .selectContactByIdForMergeToContactInLeadSearchExtension(new List<Object>{ objectId })
            .selectFields(new List<String> {'Adobe_Target_Id__c'})
            .executeQuery()[0];

            if (currentContact != null) {
                adobeTargets = (List<Marketing_Testing__c>) new MarketingTestSelector()
                    .selectAdobeTargetIdBasedOnIdAndDates(
                        new List<Object>{ 
                            currentContact.Adobe_Target_Id__c, System.today()
                        }).executeQuery();
            }

        }
        return !adobeTargets.isEmpty() ? adobeTargets[0] : null;
    }
}