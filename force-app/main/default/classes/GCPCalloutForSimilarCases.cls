public with sharing class GCPCalloutForSimilarCases {

    @AuraEnabled(cacheable=false)
    public static String makeGCPCallout(String userId, String subject, String description, String recordId) {
        try {
            List<User> userList = (List<User>) new UserSelector()
                .selectUserById(new List<Object>{ (Id) userId })
                .executeQuery();
            String username = userList.isEmpty() ? null : userList[0].Username;

            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig('similar');
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);

            return callCloudRun(subject, username, description, recordId, idToken, config.cloudRunEndpoint);

        } catch (CalloutException ce) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Callout error: ' + ce.getMessage() });
        } catch (QueryException qe) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Database query error: ' + qe.getMessage() });
        } catch (GCPAuthUtil.GCPCalloutException ae) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Configuration error: ' + ae.getMessage() });
        } catch (Exception e) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Unexpected error: ' + e.getMessage() });
        }
    }

    private static String callCloudRun(String subject, String username, String description, String recordId, String idToken, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + idToken);
        Boolean redactionFlag = GCPAuthUtil.getRedactionFlag();
        
        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectJiraCaseById((Id) recordId)
            .executeQuery();
        String recordtypeName = caseList.isEmpty() ? null : caseList[0].RecordTypeName__c;
        
        Map<String, String> payload = new Map<String, String>{
            'username' => username,
            'subject' => subject,
            'recordId' => recordId,
            'description' => String.isBlank(description) ? '' : description,
            'redactRequired' => String.valueOf(redactionFlag),
            'recordtypename' => recordtypeName 
        };
		system.debug('payload::'+payload);
        req.setBody(JSON.serialize(payload));
        req.setTimeout(120000);

        Http h = new Http();
        HttpResponse res = h.send(req);
		system.debug('Response::'+res);
        system.debug('Response Body::'+res.getBody());
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Cloud Run call failed. Status: ' + res.getStatusCode() + ' - ' + res.getBody());
        }

        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Object body = parsed.get('body');

        if (body instanceof List<Object>) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => true, 'cases' => body });
        } else if (body instanceof String) {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => body });
        } else {
            return JSON.serializePretty(new Map<String, Object>{ 'success' => false, 'message' => 'Unexpected response format' });
        }
    }

    public class ApplicationException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCaseIdsByCaseNumbers(List<String> caseNumbers) {
        return CaseSelectorDialogflow.getInstance().getCaseIdsByCaseNumbers(caseNumbers);
    }
    
    // Subfeature-specific logger on purpose: will diverge soon (new tracking fields/payload).
    @AuraEnabled(cacheable=false)
    public static void logAIHEvent(String eventType, String subfeature, String feedback) {
        // Allow only the supported AIH events
        Set<String> allowed = new Set<String>{ 'aih_view', 'aih_like', 'aih_dislike', 'aih_feedback' };
            if (String.isBlank(eventType) || !allowed.contains(eventType)) {
                return;
            }
        
        // Normalize subfeature; keep it short for field length safety in helper
        String safeSubfeature = String.isBlank(subfeature) ? 'Unknown' : subfeature.left(80);
        String safeFeedback   = String.isBlank(feedback) ? null : feedback.left(1000);
        
        Map<String, Object> payload = new Map<String, Object>{ 'subfeature' => safeSubfeature };
            if (safeFeedback != null) {
                payload.put('feedback', safeFeedback);
            }
        
        System.enqueueJob(new AIUsageLogQueueable(new List<String>{ eventType }, JSON.serialize(payload)));
        
    }

}