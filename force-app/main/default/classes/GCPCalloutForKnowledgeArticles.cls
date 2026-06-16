public with sharing class GCPCalloutForKnowledgeArticles {

    @AuraEnabled
    public static String makeGCPCallout(
        String userId,
        String subject,
        String description,
        String recordId,
        String functionVal,
        String specificIssue,
        String issueOccurrence,
        String product,
        String modelVersionPlatform
    ) {
        User userRecord = [SELECT Username FROM User WHERE Id = :userId LIMIT 1];
        String username = userRecord.Username;

        GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig('article');
        String jwt = GCPAuthUtil.createSignedJWT(config);
        String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);
        Boolean redactionFlag = GCPAuthUtil.getRedactionFlag();

        Map<String, String> payload = new Map<String, String>{
            'username' => username,
            'subject' => subject,
            'description' => String.isBlank(description) ? '' : description,
            'function' => String.isBlank(functionVal) ? '' : functionVal,
            'specific_issue' => String.isBlank(specificIssue) ? '' : specificIssue,
            'issue_occurrence' => String.isBlank(issueOccurrence) ? '' : issueOccurrence,
            'product' => String.isBlank(product) ? '' : product,
            'model_version_platform' => String.isBlank(modelVersionPlatform) ? '' : modelVersionPlatform,
            'redactRequired' => String.valueOf(redactionFlag)
        };

        return callCloudRun(payload, idToken, config.cloudRunEndpoint);
    }

    private static String callCloudRun(Map<String, String> payload, String idToken, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + idToken);
        req.setBody(JSON.serialize(payload));
        req.setTimeout(120000);

        Http h = new Http();
        HttpResponse res = h.send(req);
        
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Object body = parsed.get('body');

        if (body instanceof List<Object>) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => true, 'articles' => body });
        } else if (body instanceof String) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => body });
        } else {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Unexpected response format' });
        }
    }

    public class ApplicationException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getArticleIdsByArticleNumbers(List<String> articleNumbers) {
        return KnowledgeArticleSelectorDialogflow.getArticleIdsByArticleNumbers(articleNumbers);
    }
    
    // Subfeature-specific logger on purpose: will diverge soon (new tracking fields/payload).
    @AuraEnabled(cacheable=false)
    public static void logAIHEvent(String eventType, String subfeature, String feedback) {
        Set<String> allowed = new Set<String>{ 'aih_view','aih_like','aih_dislike','aih_feedback' };
        if (String.isBlank(eventType) || !allowed.contains(eventType)) {
            return;
        }
        
        String safeSub = String.isBlank(subfeature) ? 'Unknown' : subfeature.left(80);
        String safeFb  = String.isBlank(feedback) ? null : feedback.left(1000);
        
        Map<String,Object> payload = new Map<String,Object>{ 'subfeature' => safeSub };
        if (safeFb != null) {
            payload.put('feedback', safeFb);
        }
        
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{ eventType }, JSON.serialize(payload)));        
    }

}