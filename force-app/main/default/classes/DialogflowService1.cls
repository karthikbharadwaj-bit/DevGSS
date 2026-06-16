public class DialogflowService1 {
    // Constants
    private static final String BASE_URL = 'https://us-central1-dialogflow.googleapis.com/v3/';
    private static final String LANGUAGE_CODE = 'en';
    private static final String TIMEZONE = 'America/Los_Angeles';
    private static final String PROJECT_ID = 'quantiphiandgss';
    private static final String LOCATION = 'us-central1';
    private static final Integer TIMEOUT = 120000;
    
    // Cache for responses to avoid redundant API calls
    private static Map<String, String> responseCache = new Map<String, String>();
    private static final Integer CACHE_TTL = 3600000; // 1 hour in milliseconds
    
    public class DialogflowException extends Exception {}
    
    @AuraEnabled
    public static String sendMessage(String userMessage) {
        try {
            // Input validation
            if (String.isBlank(userMessage)) {
                throw new DialogflowException('User message cannot be empty');
            }
            
            // Check cache first
            String cacheKey = generateCacheKey(userMessage);
            if (responseCache.containsKey(cacheKey)) {
                return responseCache.get(cacheKey);
            }
            
            String userId = UserInfo.getUserId();
            String sessionId = UserInfo.getSessionId();
            
            String matchedAgentId = getAgentId();
            String response = makeDialogflowRequest(userMessage, userId, sessionId, matchedAgentId);
            
            // Cache the response
            responseCache.put(cacheKey, response);
            
            return response;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to process message: ' + e.getMessage());
        }
    }
    
    private static String getAgentId() {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm().toLowerCase();
        Boolean isSandbox = baseUrl.contains('sandbox');
        
        try {
            if (isSandbox) {
                return getSandboxAgentId(baseUrl);
            }
            return getProductionAgentId();
        } catch (Exception e) {
            throw new DialogflowException('Failed to retrieve agent ID: ' + e.getMessage());
        }
    }
    
    private static String getSandboxAgentId(String baseUrl) {
        List<Support_Agent_AI_Assist__c> sandboxConfigs = [
            SELECT Org__c, Agent_Id__c 
            FROM Support_Agent_AI_Assist__c 
            WHERE Is_Sandbox__c = true
            WITH SECURITY_ENFORCED
        ];
        
        for (Support_Agent_AI_Assist__c config : sandboxConfigs) {
            if (Test.isRunningTest() || (!String.isEmpty(config.Org__c) && baseUrl.contains(config.Org__c.toLowerCase())) ){
                return config.Agent_Id__c;
            }
        }
        throw new DialogflowException('No matching sandbox org found for URL: ' + baseUrl);
    }
    
    private static String getProductionAgentId() {
        Support_Agent_AI_Assist__c prodConfig = [
            SELECT Agent_Id__c 
            FROM Support_Agent_AI_Assist__c 
            WHERE Is_Sandbox__c = false AND Org__c = 'Production'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (prodConfig == null) {
            throw new DialogflowException('Production agent id not configured.');
        }
        return prodConfig.Agent_Id__c;
    }
    
    private static String makeDialogflowRequest(String userMessage, String userId, String sessionId, String agentId) {
        String endpoint = String.format('{0}projects/{1}/locations/{2}/agents/{3}/sessions/{4}:detectIntent',
            new String[]{BASE_URL, PROJECT_ID, LOCATION, agentId, sessionId});
            
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'queryInput' => new Map<String, Object>{
                'text' => new Map<String, String>{'text' => userMessage},
                'languageCode' => LANGUAGE_CODE
            },
            'queryParams' => new Map<String, Object>{
                'timeZone' => TIMEZONE,
                'parameters' => new Map<String, String>{'SalesforceUserId' => userId}
            }
        });
        
        HttpRequest req = buildHttpRequest(endpoint, jsonBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            return processCXResponse(res.getBody());
        } else {
            throw new DialogflowException('API Error: ' + res.getBody());
        }
    }
    
    private static HttpRequest buildHttpRequest(String endpoint, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        req.setTimeout(TIMEOUT);
        req.setHeader('Authorization', 'Bearer ' + getAccessToken());
        return req;
    }
    
    private static String processCXResponse(String responseBody) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> queryResult = (Map<String, Object>) responseMap.get('queryResult');
            
            if (queryResult == null) {
                throw new DialogflowException('Invalid response structure: queryResult is null');
            }
            
            List<Object> responseMessages = (List<Object>) queryResult.get('responseMessages');
            if (responseMessages == null || responseMessages.isEmpty()) {
                throw new DialogflowException('No response messages found');
            }
            
            for (Object messageObj : responseMessages) {
                Map<String, Object> message = (Map<String, Object>) messageObj;
                if (message.containsKey('text')) {
                    Map<String, Object> textResponse = (Map<String, Object>) message.get('text');
                    List<Object> textList = (List<Object>) textResponse.get('text');
                    if (textList != null && !textList.isEmpty()) {
                        return String.valueOf(textList[0]);
                    }
                }
            }
            
            throw new DialogflowException('No text response found in the message');
        } catch (Exception e) {
            throw new DialogflowException('Failed to process response: ' + e.getMessage());
        }
    }
    
    private static String generateCacheKey(String userMessage) {
        return EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', Blob.valueOf(userMessage)));
    }
    
    private static String getAccessToken() {
        return DialogFlowAuth.getAccessToken();
    }
  @AuraEnabled(cacheable=true)
    public static Id getCaseIdByCaseNumber(String caseNumber) {
        if (String.isBlank(caseNumber)) {
            throw new AuraHandledException('Case number cannot be empty');
        }
        
        Case caseRecord = CaseSelectorDialogflow.getInstance().getCaseByCaseNumber(caseNumber);
        if (caseRecord == null) {
            throw new AuraHandledException('Case not found for number: ' + caseNumber);
        }
        return caseRecord.Id;
    }
    
    @AuraEnabled(cacheable=true)
    public static Id getKnowledgeIdByArticleNumber(String articleNumber) {
        if (String.isBlank(articleNumber)) {
            throw new AuraHandledException('Article number cannot be empty');
        }
        
        Knowledge__kav article = KnowledgeArticleSelectorDialogflow.getInstance().getArticleByNumber(articleNumber);
        if (article == null) {
            throw new AuraHandledException('Knowledge Article not found for articleNumber: ' + articleNumber);
        }
        return article.Id;
    }
}