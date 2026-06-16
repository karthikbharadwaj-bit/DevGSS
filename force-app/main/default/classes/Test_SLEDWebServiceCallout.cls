@isTest
private class Test_SLEDWebServiceCallout {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSLEDWebServiceCallout() {
        Lead testLead = (Lead) new SObjectBuilder(Lead.SobjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'Test',
                    Lead.LastName => 'Lead',
                    Lead.Company => 'Test Company',
                    Lead.Email => 'mail@gmail.com',
                    Lead.Website => 'https://www.example.com',
                    Lead.Lead_Created_via_Smart_Search__c => true,
                    Lead.RecordTypeId => LeadHelper.RT_ID_SALES_LEADS,
                    Lead.Systems_Process_Stage__c => 'SFDC Enriched',
                    Lead.Sector__c => 'Technology',
                    Lead.Country => 'United States'
                }
            )
            .create()
            .getRecord();

        // Create a test Custom Setting
        Gating_Process_Stage__c sledWsUrl = new Gating_Process_Stage__c(
            Name = 'SLED_WS_URL',
            SLED_WS_URL__c = 'https://example.com/api/endpoint'
        );
        insert sledWsUrl;

        // Setup a mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new SLEDWebServiceCalloutMock());

        // Create a Map with Lead ID to Country mapping
        Map<Id, String> mapSMCountriesToLeads = new Map<Id, String>{testLead.Id => testLead.Country};

        // Test the Queueable job
        Test.startTest();
        SLEDWebServiceCallout queueableJob = new SLEDWebServiceCallout(new List<Lead>{testLead}, mapSMCountriesToLeads);
        System.enqueueJob(queueableJob);
        Test.stopTest();

        // Add any assertions needed to verify the expected results
    }
}