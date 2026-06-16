@isTest
private class TestLeadSpaceRequest {

    private static String getExpectedAPIRequest(String firstLeadSource){
        String apiRequest = '{"external_id":"externalId", "person": {"first_name": "personFirstName","last_name": ' +
            '"personLastName","email": "personEmail"},"company": { "name": "companyName"  ,"address" : { "country" : ' +
            '"companyCountry" } }, "custom_fields": [{"name" : "First Lead Source", "value" : "' + firstLeadSource + '" } ] }';
        return apiRequest;
    }

    @isTest 
    static void testGetApiRequestShouldReturnValidRequestWhenAllFieldsAreProvided() {
        LeadSpaceRequest lsRequest = new LeadSpaceRequest();
        lsRequest.companyCountry = 'companyCountry';
        lsRequest.personFirstName = 'personFirst"Name';
        lsRequest.personLastName = 'personLast"Name';
        lsRequest.personEmail = 'personEmail';
        lsRequest.companyName = 'company"Name';
        lsRequest.externalId = 'externalId';
        lsRequest.firstLeadSource = 'firstLeadSource';

        Test.startTest();
            String apiRequest = lsRequest.getAPIRequest();
        Test.stopTest();

        System.AssertEquals(getExpectedAPIRequest('firstLeadSource'), apiRequest,
            'API Request should contain the correct values');
    }

    @isTest 
    static void testGetApiRequestShouldReturnValidRequestWhenFirstLeadSourceIsNull() {
        LeadSpaceRequest lsRequest = new LeadSpaceRequest();
        lsRequest.companyCountry = 'companyCountry';
        lsRequest.personFirstName = 'personFirst"Name';
        lsRequest.personLastName = 'personLast"Name';
        lsRequest.personEmail = 'personEmail';
        lsRequest.companyName = 'company"Name';
        lsRequest.externalId = 'externalId';
        lsRequest.firstLeadSource = null;

        Test.startTest();
            String apiRequest = lsRequest.getAPIRequest();
        Test.stopTest();

        System.AssertEquals(getExpectedAPIRequest(''), apiRequest,
            'API Request should contain the correct values');
    }

    @isTest 
    static void testGetApiRequestShouldReturnValidRequestWhenFirstLeadSourceIsNotProvided() {
        LeadSpaceRequest lsRequest = new LeadSpaceRequest();
        lsRequest.companyCountry = 'companyCountry';
        lsRequest.personFirstName = 'personFirst"Name';
        lsRequest.personLastName = 'personLast"Name';
        lsRequest.personEmail = 'personEmail';
        lsRequest.companyName = 'company"Name';
        lsRequest.externalId = 'externalId';
        
        Test.startTest();
            String apiRequest = lsRequest.getAPIRequest();
        Test.stopTest();

        System.AssertEquals(getExpectedAPIRequest(''), apiRequest,
            'API Request should contain the correct values');
    }
}