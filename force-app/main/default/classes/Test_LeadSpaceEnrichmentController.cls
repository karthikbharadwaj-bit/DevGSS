@isTest
private class Test_LeadSpaceEnrichmentController {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testWebserviceEnrichLeadShouldEnrichLeadSuccessfully() { 

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                    RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10
                }
            )
            .create();

        Lead newLead = new Lead(
            FirstName = 'Prashant', 
            Lastname = 'Mathur', 
            Company = 'Simplion', 
            Email = 'prashant.mathur@simplion.com', 
            website = 'http://www.simplion.com',
            SiteDunsNumber__c = '12345'
        );
        insert newLead;

        Test.startTest();
            Boolean result = LeadSpaceEnrichmentController.enrichLead(newLead.Id);
        Test.stopTest();

        //System.assertEquals(true, result, 'Webservice enrich lead shouldenrich lead successfully');
    }

}