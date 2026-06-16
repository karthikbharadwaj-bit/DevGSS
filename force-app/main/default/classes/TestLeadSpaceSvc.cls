@isTest
private class TestLeadSpaceSvc {

    @isTest 
    static void testEnrichLeadDataShouldEnrichLeadSuccessfully() {

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10
            }
        )
        .create();

        LeadSpaceSvc leadSpaceSvc = new LeadSpaceSvc();
        LeadSpaceRequest lsRequest = new LeadSpaceRequest();
        lsRequest.companyCountry = 'anyCountry';
        lsRequest.personFirstName = 'anyFirstName';
        lsRequest.personLastName = 'anyLastName';
        lsRequest.personEmail = 'anyEmail';
        lsRequest.companyName = 'anyCompanyName';
        lsRequest.firstLeadSource = 'anyFieldLeadSource';
        LeadSpaceResponse lsResponse;

        Test.startTest();
            lsResponse = leadSpaceSvc.callLeadspaceAPI(lsRequest);
        Test.stopTest();

        System.AssertEquals('testPersonFirstName', lsResponse.data.person.first_name,
            'Response should have the expected person first name');

        System.AssertEquals('www.testwebsite.com', lsResponse.data.company.website,
            'Response should have the expected company website');

    }

    @isTest 
    static void testCallLeadspaceBatchRequestAPIShouldReturnBatchPollingIdSuccessfully() {

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10
            }
        )
        .create();

        LeadSpaceSvc leadSpaceSvc = new LeadSpaceSvc();
        LeadSpaceRequestBatch lsRequestBatch = new LeadSpaceRequestBatch();

        LeadSpaceRequest lsRequest1 = new LeadSpaceRequest();
        lsRequest1.companyCountry = 'United States';
        lsRequest1.personFirstName = 'Bill';
        lsRequest1.personLastName = 'Gates';
        lsRequest1.personEmail = 'bill.gates@microsoft.com';
        lsRequest1.companyName = 'Microsoft';
        lsRequest1.firstLeadSource = 'Inbound Call';
        lsRequestBatch.leadSpaceRequests.add(lsRequest1);

        LeadSpaceRequest lsRequest2 = new LeadSpaceRequest();
        lsRequest2.companyCountry = 'United States';
        lsRequest2.personFirstName = 'Jeff';
        lsRequest2.personLastName = 'Bezos';
        lsRequest2.personEmail = 'jeff.bezos@amazon.com';
        lsRequest2.companyName = 'Amazon';
        lsRequest2.firstLeadSource = 'Inbound Call';
        lsRequestBatch.leadSpaceRequests.add(lsRequest2);

        LeadSpaceResponseBatchPolling lsResponseBatchPolling;

        Test.startTest();
            lsResponseBatchPolling = leadSpaceSvc.callLeadspaceBatchRequestAPI(lsRequestBatch);
        Test.stopTest();

        System.Assert(lsResponseBatchPolling.id != null,
            'Response should have the id of the batch requested');

    }

    @isTest 
    static void testCallLeadspaceBatchPollingAPIShouldEnrichLeadSuccessfully() {

        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object>{
                RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10
            }
        )
        .create();

        LeadSpaceSvc leadSpaceSvc = new LeadSpaceSvc();
        
        LeadSpaceResponseBatch lsResponseBatch;

        Test.startTest();
            lsResponseBatch = leadSpaceSvc.callLeadspaceBatchPollingAPI('anyTestPollingId');
        Test.stopTest();

        System.Debug('lsResponseBatch:::' + lsResponseBatch);
        System.AssertEquals(2, lsResponseBatch.results.size(),
            'Response should contain enrichment data for two requests');

    }
}