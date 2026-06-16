public without sharing class RCPlatformAPICallout {
    public static List<ErrorResponseWrapper> errorResponse;
    
    public static List<ErrorResponseWrapper> makeCalloutToSCP(List <Case> newCases, RC_Platform_API_setting__mdt setting) {
        errorResponse = new List<ErrorResponseWrapper>();
        String accessToken = '';
        List<String> extensionIds = new List<String>();
        
        for (Case newCase: newCases) {
            try{
                accessToken = getAccessToken(newCase.CaseUID__c, setting.Client_ID__c, setting.PrivateKey__c, setting.BaseURL__c);
                if (String.isNotBlank(accessToken)) {
                    // Call 2nd API
                    extensionIds = callDirectorySearchAPI(setting.BaseURL__c, accessToken, newCase.CaseUID__c, newCase.ContactEmail);
                    
                    if (!extensionIds.isEmpty()) {
                        if (extensionIds.size() == 1) {
                            // If only one extension ID, directly set the clock
                            callSetClockAPI(setting.BaseURL__c, accessToken, newCase.CaseUID__c, extensionIds[0]);
                        } 
                        else if (extensionIds.size() > 1) {
                            // Call 3rd API for multiple extension IDs
                            String selectedExtId = getFilteredExtensionId(setting.BaseURL__c, accessToken, newCase.CaseUID__c, extensionIds, newCase.ContactEmail);
                            
                            if (String.isNotBlank(selectedExtId)) {
                                callSetClockAPI(setting.BaseURL__c, accessToken, newCase.CaseUID__c, selectedExtId);
                            }
                        }
                    }
                }
            } catch(Exception ex) {
                errorResponse.add(new ErrorResponseWrapper(newCase, ex.getMessage(), ex.getStackTraceString()));
            }
        }
        return errorResponse;
    }
    
    public static void callSetClockAPI(String baseURL, String accessToken, String UID, String extensionId) {
        String setClockEndpoint = baseURL + '/restapi/v2/accounts/' + UID + '/extensions/' + extensionId + '/support-period';
       	
        Map <String,String> header =  new Map <String, String> {
             'Authorization' => 'Bearer ' + accessToken,
             'Content-Type' => 'application/json'
        }; 
        
        Map <String, Object> requestBody = new Map <String, Object> {
            'durationInHours' => 168,
            'comment' => 'case creation via Salesforce'
        };

        HttpResponse response = APIUtility.makeHTTPRequest(setClockEndpoint, 'PUT', header, JSON.serialize(requestBody));

        if (response.getStatusCode() == 200) {
            Map <String, Object> responseMap = (Map <String, Object> ) JSON.deserializeUntyped(response.getBody());
            if (responseMap.get('status') != 'Created' && responseMap.get('status') != 'Updated') {
                throw new CalloutException('Clock was not set in SCP :  \nStatus =' + response.getStatusCode() +'\n Response = '+response.getBody()+'\n RCRequestId = ' + response.getHeader('RCRequestId'));
            }
        } else {
            throw new CalloutException('Error Setting clock in SCP : \nStatus =' + response.getStatusCode() +'\n Response = '+response.getBody()+'\n RCRequestId = ' + response.getHeader('RCRequestId'));
        }
    }

    // 2nd API call to get extension IDs
    public static List<String> callDirectorySearchAPI(String baseURL, String accessToken, String UID, String email) {

        String directortSearchEndpoint = baseURL + '/restapi/v1.0/account/' + UID + '/directory/entries/search';
        
        Map <String,String> header =  new Map <String, String> {
             'Authorization' => 'Bearer ' + accessToken,
             'Content-Type' => 'application/json'
        };
            
        Map <String, Object> requestBody = new Map <String, Object> {
            'searchString' => email,
            'orderBy' => new List <Map<String, String>> {
                new Map <String,String> {
                    'fieldName' => 'email'
                }
            }
        };
        
        HttpResponse response = APIUtility.makeHTTPRequest(directortSearchEndpoint, 'POST', header, JSON.serialize(requestBody));

        if (response.getStatusCode() == 200) {
            List<String> extensionIds = new List<String>();
            Map <String, Object> responseMap = (Map <String, Object> ) JSON.deserializeUntyped(response.getBody());

            if (responseMap != null && responseMap.containsKey('records')) {
                List<Object> records = (List<Object>) responseMap.get('records');
                Map<String, Object> record = new Map<String, Object>();
                if (records != null && !records.isEmpty()) {
                    for (Object recordObj : records) {
                        record = (Map<String, Object>) recordObj;
                        if (record != null && record.containsKey('type') && 'User'.equalsIgnoreCase((String) record.get('type')) &&
                            record.containsKey('email') && ((String) record.get('email')).equalsIgnoreCase(email) &&
                            record.containsKey('id')) {
                                extensionIds.add((String) record.get('id'));
                    }
                }
            }
            }
            // Throw an exception if no extension IDs are found
            if (extensionIds.isEmpty()) {
                throw new CalloutException('Extension Id not found in Directory: \nStatus =' + response.getStatusCode() +'\n Response = '+response.getBody()+'\n RCRequestId = ' + response.getHeader('RCRequestId'));
            }            
            return extensionIds;
        } else {
            throw new CalloutException('Error getting Extension Id: \nStatus =' + response.getStatusCode() +'\n Response = '+response.getBody()+'\n RCRequestId = ' + response.getHeader('RCRequestId'));
        }
    }
    
    // 3rd API call to filter and fetch the valid extension ID with emailAsLoginName : 'true' and type : 'User'
    public static String getFilteredExtensionId(String baseURL, String accessToken, String UID, List<String> extensionIds, String email) {
        String extensions = String.join(extensionIds, ',');
        String filterEndpoint = baseURL + '/restapi/v1.0/account/' + UID + '/extension/' + extensions;
        
        
        Map<String, String> header = new Map<String, String>{
            'Authorization' => 'Bearer ' + accessToken,
                'Content-Type' => 'application/json'
                };
                    
                    HttpResponse response = APIUtility.makeHTTPRequest(filterEndpoint, 'GET', header, '');
        
        if (response.getStatusCode() == 207) {
            // Extract boundary-separated response
            String responseBody = response.getBody();
            List<String> jsonParts = splitBoundaryResponses(responseBody);
            if (jsonParts == null || jsonParts.isEmpty()) {
                throw new CalloutException('No valid parts found in the boundary-separated response for UID: ' + UID + ' and email: ' + email +
                           '\nStatus = ' + response.getStatusCode() + 
                           '\nResponse = ' + response.getBody() + 
                           '\nRCRequestId = ' + response.getHeader('RCRequestId'));

            }
            Map<String, Object> extensionData = new Map<String, Object>();
            Map<String, Object> contactData = new Map<String, Object>();
            // Iterate through each part and process valid JSON
            for (String jsonPart : jsonParts) {
                extensionData = (Map<String, Object>) JSON.deserializeUntyped(jsonPart);
                
                if (extensionData != null && extensionData.containsKey('contact')) {
                    contactData = (Map<String, Object>) extensionData.get('contact');
                    
                    // Validate email, emailAsLoginName, and type
                    if (
                        contactData.containsKey('emailAsLoginName') &&
                        Boolean.valueOf(contactData.get('emailAsLoginName')) &&
                        contactData.containsKey('email') &&
                        String.valueOf(contactData.get('email')).equalsIgnoreCase(email) &&
                        extensionData.containsKey('type') &&
                        'User'.equalsIgnoreCase(String.valueOf(extensionData.get('type')))
                    ) {
                        return String.valueOf(extensionData.get('id')); 
                    }
                }
            }
            throw new CalloutException('No valid extension ID found after filtering for UID: ' + UID + ' and email: ' + email +
                           '\nStatus = ' + response.getStatusCode() + 
                           '\nResponse = ' + response.getBody() + 
                           '\nRCRequestId = ' + response.getHeader('RCRequestId'));
        } else {
            throw new CalloutException('Error filtering Extension IDs' +
                           '\nStatus = ' + response.getStatusCode() + 
                           '\nResponse = ' + response.getBody() + 
                           '\nRCRequestId = ' + response.getHeader('RCRequestId'));

        }
    }
    
    // Helper method to split boundary-separated responses
    public static List<String> splitBoundaryResponses(String responseBody) {
        List<String> jsonParts = new List<String>();
        String boundaryPattern = '--Boundary_'; // Adjust if boundaries vary
        List<String> parts = responseBody.split(boundaryPattern);
        
        for (String part : parts) {
            if (part.contains('{') && part.contains('}')) {
                // Extract the JSON portion from the part
                Integer startIndex = part.indexOf('{');
                Integer endIndex = part.lastIndexOf('}');
                if (startIndex >= 0 && endIndex > startIndex) {
                    String jsonPart = part.substring(startIndex, endIndex + 1);
                    jsonParts.add(jsonPart); 
                }
            }
        }
        return jsonParts;
    }

    public static String getAccessToken(String UID, String clientId, String privateKey, String baseUrl) {

        String accessTokenURL = baseUrl + '/restapi/oauth/token';

        Map <String, Object> header = new Map <String, Object> ();
        header.put('alg', 'RS256');
        header.put('typ', 'JWT');
        header.put('kid', 'sf-default-key');

        Map <String, Object> claims = new Map <String, Object> ();
        claims.put('iss', clientId);
        claims.put('aud', accessTokenURL);
        claims.put('exp', ((DateTime.now().getTime() / 1000) + 300));
        claims.put('iat', ((DateTime.now().getTime() / 1000) + 1));
        claims.put('jti', clientId + DateTime.now().getTime());

        claims.put('sub', UID);
        String assertion = createJWTToken(header, claims, privateKey);

        claims.put('sub', clientId);
        string client_assertion = createJWTToken(header, claims, privateKey);
        
        Map <String,String> requestHeader =  new Map <String, String> {
             'Content-Type' => 'application/x-www-form-urlencoded'
        };
        
        String requestBody = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' +
            assertion +
            '&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=' +
            client_assertion;

        HttpResponse response = APIUtility.makeHTTPRequest(accessTokenURL, 'POST', requestHeader, requestBody);
        
        if (response.getStatusCode() == 200) {
            Map <String, Object> responseMap = (Map <String, Object> ) JSON.deserializeUntyped(response.getBody());
            return (String) responseMap.get('access_token');
        } else {
            throw new CalloutException('Error fetching access token: \nStatus =' + response.getStatusCode() +'\n Response = '+response.getBody() +'\nRCRequestId = ' + response.getHeader('RCRequestId'));
        }
    }

    public static String createJWTToken(Map <String, Object> header, Map <String, Object> claims, String privateKey) {

        String headerEncoded = base64URLencode(Blob.valueOf(JSON.serialize(header)));
        String claimsEncoded = base64URLencode(Blob.valueOf(JSON.serialize(claims)));

        String signingInput = headerEncoded + '.' + claimsEncoded;
        Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
        Blob signature = Crypto.sign('RSA-SHA256', Blob.valueOf(signingInput), privateKeyBlob);

        String token = signingInput + '.' + base64URLencode(signature);
        return token;
    }

    public static String base64URLencode(Blob input) {
        String output = '';
        if (input != null) {
            output = EncodingUtil.base64Encode(input);
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while (output.endsWith('=')) {
                output = output.subString(0, output.length() - 1);
            }
        }
        return output;
    }
    
    public class ErrorResponseWrapper{
        public Case erroredRecord;
        public String exceptionMessage;
        public String stackTrace;
        
        public ErrorResponseWrapper(Case erroredRecord, String exceptionMessage, String stackTrace){
            this.erroredRecord = erroredRecord;
            this.exceptionMessage = exceptionMessage;
            this.stackTrace = stackTrace;
        }
    }
}