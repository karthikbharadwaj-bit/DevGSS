public class LeadSpaceSvc implements ILeadSpaceSvc {

    public static final String LEAD_SPACE_RESPONSE_BATCH_POLLING_JSON = '{' +
                                                        '"id": "/v3/enrichment/results/6382c184-529d-4b61-9dd8-08fc9299ce21"' +
                                                        '}';
    public static final String LEAD_SPACE_ENRICHMENT_SUCCESS_BATCH_JSON =              
        '{"results": [' +
        '{ ' +
            '"status": "success",' +
            '"external_id": "' + '' + '",' +
            '"data": { ' +
                '"person": {' +
                ' "first_name": "testPersonFirstName",' +
                    '"address": {' +
                        '"country": "testPersonAddressCountry"' +
                    '}' +
                '},' +
                '"company": {' +
                    '"client_id":"DunsTest",' +
                    '"website": "www.testwebsite.com",' +
                    '"family_tree": {' +
                        '"companies": [' +
                            '{' +
                                '"type": "DU",' +
                                '"address": {' +
                                    '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                                '},' +
                                '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                            '}' +
                        ']' +
                    '}' +
                '},' +
                '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
                '"enrichment_status": "testEnrichmentStatus"' +
            '}' +
        '},' +
        '{ ' +
            '"status": "success",' +
            '"external_id": "' + '' + '",' +
            '"data": { ' +
                '"person": {' +
                ' "first_name": "testPersonFirstName",' +
                    '"address": {' +
                        '"country": "testPersonAddressCountry"' +
                    '}' +
                '},' +
                '"company": {' +
                    '"client_id":"DunsTest",' +
                    '"website": "www.testwebsite.com",' +
                    '"family_tree": {' +
                        '"companies": [' +
                            '{' +
                                '"type": "DU",' +
                                '"address": {' +
                                    '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                                '},' +
                                '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                            '}' +
                        ']' +
                    '}' +
                '},' +
                '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
                '"enrichment_status": "testEnrichmentStatus"' +
            '}' +
        '}' +
        ']}';
    
    public static final String LEAD_SPACE_ENRICHMENT_SUCCESS_JSON = '{ ' +
                '"status": "success",' +
                '"data": { ' +
                    '"person": {' +
                    ' "first_name": "testPersonFirstName",' +
                        '"address": {' +
                            '"country": "testPersonAddressCountry"' +
                        '},' +
                        '"analytics": {' +
                            '"job_functions": [' +
                                '"testJobFunction"' +
                            '],' +
                            '"scores": [' +
                                '{' +
                                    '"score": {' +
                                        '"value": 0' +
                                    '},' +
                                    '"profile_name": "testPersonAnalyticsScoreProfileName"' +
                                '}' +
                            ']' +
                        '}' +
                    '},' +
                    '"company": {' +
                        '"client_id":"DunsTest",' +
                        '"industry": "testIndustry",' +
                        '"website": "www.testwebsite.com",' +
                        '"address": {' +
                            '"country": "testCompanyCountry"' +
                        '},' +
                        '"size": {' +
                            '"range": "testCompanySizeRange",' +
                            '"exact": 1' +
                        '},' +
                        '"revenue": {' +
                            '"range": "testCompanyRevenueRange"' +
                        '},' +
                        '"analytics": {' +
                            '"installed_base_technologies":["testCompanyAnalyticsInstalledBaseTechnologies"]' +
                        '},' +
                        '"family_tree": {' +
                            '"companies": [' +
                                '{' +
                                    '"type": "DU",' +
                                    '"address": {' +
                                        '"country": "testCompanyFamilyTreeCompaniesAddressCountry"' +
                                    '},' +
                                    '"duns": "testCompanyFamilyTreeCompaniesDuns"' +
                                '}' +
                            ']' +
                        '}' +
                    '},' +
                    '"total_scores": [' +
                        '{' +
                            '"score": {' +
                                '"value": "10"' +
                            '},' +
                            '"profile_name": "testTotalScoresProfileName"' +
                        '}' +
                    '],' +
                    '"max_positive_total_score_profiles":["testMaxPositiveTotalScoreProfiles"],' +
                    '"enrichment_status": "testEnrichmentStatus"' +
                '}' +
            '}';

    public Interface ILeadSpaceSvc {
        LeadSpaceResponse callLeadspaceAPI(LeadSpaceRequest leadSpaceRequest);
        LeadSpaceResponseBatch callLeadspaceBatchPollingAPI(String pollingId);
        LeadSpaceResponseBatchPolling callLeadspaceBatchRequestAPI(LeadSpaceRequestBatch leadSpaceRequestBatch);
    }

    static String apiKey = RingCentralVariousSettings__c.getInstance().LeadspaceAPIKey__c;
    static String endpointUrlBase = 'https://apigw.leadspace.com';
    static String endPointUrlSingle = '/enrichment/enrich/single';
    static String endPointUrlBatch = '/enrichment/enrich/bulk';

    private HttpRequest createPostRequest(String body, String endpointUrl){
        HttpRequest request = new HttpRequest();
        request = getRequestHeaderAndCommonParams(request);
        request.setEndpoint(endPointUrl); 
        request.setMethod('POST');
        request.setBody(body);
        return request;
    }

    private HttpRequest createGetRequest(String endpointUrl){
        HttpRequest request = new HttpRequest();
        request = getRequestHeaderAndCommonParams(request);
        //System.Debug('endpointurl:::' + endpointUrl);
        request.setEndpoint(endPointUrl); 
        request.setMethod('GET');
        return request;
    }

    private HttpRequest getRequestHeaderAndCommonParams(HttpRequest request){
        request.setTimeout(120000);
        request.setHeader('Authorization', apiKey);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json; charset=utf8');
        return request;
    }

    public LeadSpaceResponseBatchPolling callLeadspaceBatchRequestAPI(LeadSpaceRequestBatch leadSpaceRequestBatch) {
        
        String body = leadSpaceRequestBatch.getAPIRequest();
        //system.debug('body:::' + body);
                
        String serializedResponse = '';
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        
        HttpRequest request = createPostRequest(body, endpointUrlBase + endPointUrlBatch);
        if(!Test.isRunningTest()){
            try {               
                response = http.send(request);
                //System.debug('response.getBody():::' + response.getBody());
                //System.Debug('response.getStatusCode():::' + response.getStatusCode());
                if(response.getStatusCode() == 202 && String.isNotBlank(response.getBody())){
                    serializedResponse = response.getBody();
                } else {
                    return null;
                }
            } catch(System.CalloutException e) {
                System.Debug('Exception calling LeadSpaceSvc.cls..callLeadspaceBatchAPI_Post==' + e);
                return null;
            }
        } else {
            serializedResponse = LEAD_SPACE_RESPONSE_BATCH_POLLING_JSON;
        }
        //System.debug('serializedResponse:::' + serializedResponse);

        LeadSpaceResponseBatchPolling leadSpaceResponseBatchPolling = 
            ((LeadSpaceResponseBatchPolling)System.JSON.deserialize(serializedResponse, LeadSpaceResponseBatchPolling.class)); 
            
        //System.debug('leadSpaceResponseBatchPolling:::' + leadSpaceResponseBatchPolling);

        return leadSpaceResponseBatchPolling;
    }

    public LeadSpaceResponseBatch callLeadspaceBatchPollingAPI(String pollingId) {
        String serializedResponse = '';
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        
        HttpRequest request = createGetRequest(endpointUrlBase + pollingId);
        if(!Test.isRunningTest()){
            try {               
                response = http.send(request);
                //System.debug('response.getBody():::' + response.getBody());
                //System.Debug('response.getStatusCode():::' + response.getStatusCode());
                if(response.getStatusCode() == 200 && String.isNotBlank(response.getBody())){
                    serializedResponse = response.getBody();
                } else {
                    return null;
                }
            } catch(System.CalloutException e) {
                System.Debug('Exception calling LeadSpaceSvc.cls..callLeadspaceBatchAPI_Get==' + e);
                return null;
            }
        } else {
            serializedResponse = LEAD_SPACE_ENRICHMENT_SUCCESS_BATCH_JSON;
        }
        //System.debug('serializedResponse:::' + serializedResponse);

        LeadSpaceResponseBatch leadSpaceResponseBatch = 
            ((LeadSpaceResponseBatch)System.JSON.deserialize(serializedResponse, LeadSpaceResponseBatch.class)); 
            
        //System.debug('leadSpaceResponseBatch:::' + leadSpaceResponseBatch);

        leadSpaceResponseBatch.serializedResponse = serializedResponse;
        //System.debug('leadSpaceResponse == ' + leadSpaceResponseBatch);
        return leadSpaceResponseBatch;
    }

    public LeadSpaceResponse callLeadspaceAPI(LeadSpaceRequest leadSpaceRequest) {
        String body = leadSpaceRequest.getAPIRequest();
        system.debug('LeadSpaceRequest_body:' + body);

        String serializedResponse = '';
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        HttpRequest request = createPostRequest(body, endpointUrlBase + endPointUrlSingle);
       
        if(!Test.isRunningTest()){
            try {
                response = http.send(request); 
                if(response.getStatusCode() == 200 && String.isNotBlank(response.getBody())){
                    serializedResponse = response.getBody();
                } else {
                    return null;
                }
            } catch(System.CalloutException e) {
                System.Debug('Exception calling LeadSpaceSvc.cls..callLeadspaceAPI' + e);
                return null;
            }
        } else {
            serializedResponse = LEAD_SPACE_ENRICHMENT_SUCCESS_JSON;
        }
        System.debug('LeadSpaceSvc.cls...serializedResponse==' + serializedResponse);

        LeadSpaceResponse leadSpaceResponse = ((LeadSpaceResponse) System.JSON.deserialize(serializedResponse, 
            LeadSpaceResponse.class)); 
        leadSpaceResponse.serializedResponse = serializedResponse;
        System.debug('LeadSpaceSvc.cls...leadSpaceResponse==' + leadSpaceResponse);
        return leadSpaceResponse;
    }

    public class LeadSpaceSvcMock implements ILeadSpaceSvc {
        public LeadSpaceResponse leadSpaceResponseToReturn;
        public LeadSpaceResponseBatch leadSpaceResponseBatchToReturn;
        public LeadSpaceResponseBatchPolling leadSpaceResponseBatchPollingToReturn;

        public LeadSpaceResponse callLeadspaceAPI(LeadSpaceRequest leadSpaceRequest) {
            return leadSpaceResponseToReturn;
        }

        public LeadSpaceResponseBatch callLeadspaceBatchPollingAPI(String pollingId){
            return leadSpaceResponseBatchToReturn;
        }
        
        public LeadSpaceResponseBatchPolling callLeadspaceBatchRequestAPI(LeadSpaceRequestBatch leadSpaceRequestBatch){
            return leadSpaceResponseBatchPollingToReturn;
        }
    }
}