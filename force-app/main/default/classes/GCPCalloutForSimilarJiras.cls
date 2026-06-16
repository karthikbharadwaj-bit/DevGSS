public with sharing class GCPCalloutForSimilarJiras {
    
    private static GCP_Endpoint_Settings__c getConfig() { 
        GCP_Endpoint_Settings__c cfg = GCP_Endpoint_Settings__c.getInstance();
        if (cfg == null) {
            throw new CalloutException('Missing GCP Endpoint configuration');
        }
        if (String.isBlank(cfg.Similar_Jiras_Endpoint__c)) {
            throw new CalloutException('Missing Similar Jiras Endpoint');
        }
        
        if (String.isBlank(cfg.Similar_Jiras_Summary_Endpoint__c)) {
            throw new CalloutException('Missing Similar Jiras Summary Endpoint');
        }
        return cfg;
    }
    
    @AuraEnabled(cacheable=false)
    public static String makeGCPCallout(String userId, String subject, String description, String recordId) {
        try {
            // Fetch case
            Case c = [
                SELECT Id, Subject, Description,
                ProductType__c, ProductType_CS__c,
                OpenCustomerSupportLevel1__c, CloseCustomerSupportLevel1__c,
                Jira__c
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            String mappedProduct = getMatchingProductName(c);
            if (mappedProduct == null) {
                // No product mapping — do not call n8n; LWC shows a message to the user
                return JSON.serializePretty(new Map<String, Object>{
                    'success' => true,
                        'jiras' => new List<Object>(),
                        'productMatched' => false
                        });
            }
            
            if (String.isBlank(userId)) {
                throw new AuraHandledException('Invalid user.');
            }
            
            List<User> users = [SELECT Username FROM User WHERE Id = :userId LIMIT 1];
            
            if (users.isEmpty() || String.isBlank(users[0].Username)) {
                throw new AuraHandledException('Invalid username.');
            }
            
            String username = users[0].Username;
            return callCloudRun(subject, username, description, mappedProduct);
            
        } catch (CalloutException ce) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Callout error: ' + ce.getMessage() });
        } catch (QueryException qe) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Database query error: ' + qe.getMessage() });
        } catch (Exception e) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Unexpected error: ' + e.getMessage() });
        }
    }
    
    private static String callCloudRun(String subject, String username, String description, String mappedProduct) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint('callout:N8n_Similar_Jiras'+getConfig().Similar_Jiras_Endpoint__c);
        
        Map<String, String> payload = new Map<String, String>{
            'username' => username,
                'subject' => subject,
                'description' => String.isBlank(description) ? '' : description,
                    'label' => mappedProduct
                    };
                        
                        System.debug('Payload::'+payload);
        req.setBody(JSON.serialize(payload));
        req.setTimeout(120000);
        
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug('Response::'+res);
        System.debug('Response body::'+res.getBody());
        
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Cloud Run call failed. Status: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
        
        String responseBody = res.getBody();
        if (String.isBlank(responseBody)) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Something went wrong while fetching jira tickets , Please contact administrator if issue persists.' });
        }
        
        Object raw = JSON.deserializeUntyped(responseBody);
        List<Object> tickets = extractTickets(raw);
        if (tickets != null) {
            return JSON.serializePretty(new Map<String, Object>{
                'success' => true,
                    'jiras' => tickets,
                    'productMatched' => true
                    });
        }
        
        if (raw instanceof Map<String, Object>) {
            Object body = ((Map<String, Object>) raw).get('body');
            if (body instanceof String) {
                // n8n signals that the product has no indexed Jira tickets.
                // Treat this as a "no results" data state, not an error.
                return JSON.serializePretty(new Map<String, Object>{
                    'success'        => true,
                        'jiras'          => new List<Object>(),
                        'productMatched' => true
                        });
            }
        }
        
        return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Unexpected response format' });
    }
    
    private static List<Object> extractTickets(Object raw) {
        if (raw instanceof List<Object>) {
            List<Object> arr = (List<Object>) raw;
            if (!arr.isEmpty() && arr[0] instanceof Map<String, Object>) {
                Map<String, Object> wrapper = (Map<String, Object>) arr[0];
                Object body = wrapper.get('body');
                if (body instanceof Map<String, Object>) {
                    Object tickets = ((Map<String, Object>) body).get('similar_jira_tickets');
                    if (tickets instanceof List<Object>) {
                        return (List<Object>) tickets;
                    }
                }
            }
            return arr;
        }
        if (raw instanceof Map<String, Object>) {
            Map<String, Object> parsed = (Map<String, Object>) raw;
            Object body = parsed.get('body');
            if (body instanceof Map<String, Object>) {
                Object tickets = ((Map<String, Object>) body).get('similar_jira_tickets');
                if (tickets instanceof List<Object>) {
                    return (List<Object>) tickets;
                }
            }
            if (body instanceof List<Object>) {
                return (List<Object>) body;
            }
        }
        return null;
    }
    
    @AuraEnabled(cacheable=false)
    public static String generateJiraSummary(String jiraPayloadJson) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:N8n_Similar_Jiras'+getConfig().Similar_Jiras_Summary_Endpoint__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            req.setBody(JSON.serialize(jiraPayloadJson));
            req.setTimeout(120000);
            
            System.debug('Jira Summary Payload::' + jiraPayloadJson);
            
            Http h = new Http();
            HttpResponse res = h.send(req);
            
            System.debug('Jira Summary Response::' + res);
            System.debug('Jira Summary Response body::' + res.getBody());
            
            if (res.getStatusCode() != 200) {
                return JSON.serializePretty(new Map<String, Object>{
                    'success' => false,
                        'message' => 'Summary call failed. Status: ' + res.getStatusCode()
                        });
            }
            
            String responseBody = res.getBody();
            if (String.isBlank(responseBody)) {
                return JSON.serializePretty(new Map<String, Object>{
                    'success' => false,
                        'message' => 'Error in fetching similar jiras'
                        });
            }
            
            Object raw = JSON.deserializeUntyped(responseBody);
            Map<String, Object> bodyMap = null;
            
            if (raw instanceof Map<String, Object>) {
                Object bodyObj = ((Map<String, Object>) raw).get('body');
                if (bodyObj instanceof Map<String, Object>) {
                    bodyMap = (Map<String, Object>) bodyObj;
                }
            } else if (raw instanceof List<Object>) {
                List<Object> arr = (List<Object>) raw;
                if (!arr.isEmpty() && arr[0] instanceof Map<String, Object>) {
                    Object nestedBody = ((Map<String, Object>) arr[0]).get('body');
                    if (nestedBody instanceof Map<String, Object>) {
                        bodyMap = (Map<String, Object>) nestedBody;
                    }
                }
            }
            
            if (bodyMap != null && bodyMap.containsKey('ai_summary')) {
                return JSON.serializePretty(new Map<String, Object>{
                    'success' => true,
                        'ai_summary' => bodyMap.get('ai_summary')
                        });
            }
            
            return JSON.serializePretty(new Map<String, Object>{
                'success' => false,
                    'message' => 'No summary found in response'
                    });
            
        } catch (CalloutException ce) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Callout error: ' + ce.getMessage() });
        } catch (Exception e) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Unexpected error: ' + e.getMessage() });
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean isSimilarJirasEnabled() {
        GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
        return (setting != null && setting.Enable_Similar_Jiras__c == true);
    }
    
    @AuraEnabled(cacheable=true)
    public static String getJiraBaseUrl() {
        GCP_Feature_Toggle__c setting = GCP_Feature_Toggle__c.getInstance();
        return (setting != null && !String.isBlank(setting.JiraURL__c)) ? setting.JiraURL__c : '';
    }
    
    @AuraEnabled(cacheable=false)
    public static void logAIHEvent(String eventType, String subfeature, String feedback) {
        Set<String> allowed = new Set<String>{ 'aih_view', 'aih_like', 'aih_dislike', 'aih_feedback' };
            if (String.isBlank(eventType) || !allowed.contains(eventType)) {
                return;
            }
        
        String safeSubfeature = String.isBlank(subfeature) ? 'Unknown' : subfeature.left(80);
        String safeFeedback   = String.isBlank(feedback) ? null : feedback.left(1000);
        
        Map<String, Object> payload = new Map<String, Object>{ 'subfeature' => safeSubfeature };
            if (safeFeedback != null) {
                payload.put('feedback', safeFeedback);
            }
        
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{ eventType }, JSON.serialize(payload)));
    }
    
    // ----------PRODUCT LOGIC-------------//
    public static String getMatchingProductName(Case c) {
        List<Similar_Jira_Product_Mapping__c> mappings = Similar_Jira_Product_Mapping__c.getAll().values();
        
        for (Similar_Jira_Product_Mapping__c m : mappings) {
            Boolean isMatch = false;
            
            if (!String.isBlank(m.ProductType__c) && equalsIgnoreCase(c.ProductType__c, m.ProductType__c)) {
                system.debug('isMatch01'+isMatch);
                isMatch = true;
                system.debug('isMatch1'+isMatch);
            }
            
            if (!String.isBlank(m.ProductType_CS__c)) {
                List<String> csParts = m.ProductType_CS__c.split(',');
                for (String part : csParts) {
                    if (containsIgnoreCase(c.ProductType_CS__c, part.trim())) {
                        isMatch = true;
                        system.debug('isMatch2'+isMatch);
                        break;
                    }
                }
            }
            
            if (!String.isBlank(m.OpenCustomerSupportLevel1__c)) {
                List<String> openParts = m.OpenCustomerSupportLevel1__c.split(',');
                for (String part : openParts) {
                    if (containsIgnoreCase(c.OpenCustomerSupportLevel1__c, part.trim())) {
                        isMatch = true;
                        system.debug('isMatch3'+isMatch);
                        break;
                    }
                }
            }
            
            if (!String.isBlank(m.CloseCustomerSupportLevel1__c)) {
                List<String> closeParts = m.CloseCustomerSupportLevel1__c.split(',');
                for (String part : closeParts) {
                    if (containsIgnoreCase(c.CloseCustomerSupportLevel1__c, part.trim())) {
                        isMatch = true;
                        break;
                    }
                }
            }
            
            if (isMatch) {
                system.debug('m.Product_Name__c::'+m.Product_Name__c);
                return m.Product_Name__c;
            }
        }
        return null;
    }
    
    private static Boolean equalsIgnoreCase(String a, String b) {
        return (a != null && b != null && a.toLowerCase() == b.toLowerCase());
    }
    
    private static Boolean containsIgnoreCase(String text, String search) {
        return (text != null && search != null && text.toLowerCase().contains(search.toLowerCase()));
    }
}