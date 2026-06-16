@isTest
private class Test_PartnerAccountEmailDomainSelector {

    @isTest
    private static void testSelectPartnerAccountEmailDomainRecords(){
        new SObjectBuilder(PartnerAccountEmailDomain__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PartnerAccountEmailDomain__c.Name => 'GMAIL',
                PartnerAccountEmailDomain__c.Email_Domain__c => 'gmail.com'
            })
            .create();

        List<PartnerAccountEmailDomain__c> partnerAccountEmailDomainList = (List<PartnerAccountEmailDomain__c>) new PartnerAccountEmailDomainSelector()
            .selectPartnerAccountEmailDomainRecords()
            .executeQuery();

        System.assert(partnerAccountEmailDomainList.size() > 0, 'List size should be more than 0');
        System.assertEquals(partnerAccountEmailDomainList[0].Email_Domain__c,'gmail.com', 'Email domain should be "gmail.com"');
    }
}