public without sharing class SlapFiveQueueable
        implements Queueable, Database.AllowsCallouts {

    private String jsonPayload;

    public SlapFiveQueueable(String jsonPayload) {
        this.jsonPayload = jsonPayload;
    }

    public void execute(QueueableContext context) {

        SlapFiveFormURL__c setting = SlapFiveFormURL__c.getInstance('FormURL');
        if (setting == null || String.isBlank(setting.URL__c)) {
            throw new CalloutException('SlapFive endpoint is not configured.');
        }

        String payload = cleanHtml(jsonPayload);

        Id contactId = extractContactId(payload);
        if (contactId == null) {
            throw new CalloutException(
                'Contact Id not found or invalid in payload JSON (expected key "Id").'
            );
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(setting.URL__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('SlapFive Payload: ' + payload);
        System.debug('SlapFive StatusCode: ' + res.getStatusCode());
        System.debug('SlapFive Response: ' + res.getBody());

        if (res == null || res.getStatusCode() != 200) {
            throw new CalloutException(
                'SlapFive callout failed. StatusCode=' +
                (res == null ? 'NULL' : String.valueOf(res.getStatusCode())) +
                ', Response=' +
                safeBody(res)
            );
        }
        
    }

    private static Id extractContactId(String jsonPayload) {
        if (String.isBlank(jsonPayload)) {
            return null;
        }

        Object raw = JSON.deserializeUntyped(jsonPayload);
        if (!(raw instanceof Map<String, Object>)) {
            return null;
        }

        Map<String, Object> payloadMap = (Map<String, Object>) raw;
        Object idVal = payloadMap.get('Id');
        if (idVal == null) {
            return null;
        }

        try {
            return (Id) String.valueOf(idVal).trim();
        } catch (Exception e) {
            return null;
        }
    }

    private static String safeBody(HttpResponse res) {
        try {
            return (res == null || res.getBody() == null) ? '' : res.getBody();
        } catch (Exception e) {
            return '';
        }
    }

    public static String cleanHtml(String payload) {
        if (String.isNotBlank(payload)) {
            payload = payload.replaceAll('<[^>]*>', '');
            payload = payload.replaceAll('&nbsp;', ' ');
            payload = payload.replaceAll('&lt;', '<')
                             .replaceAll('&gt;', '>')
                             .replaceAll('&amp;', '&');
        }
        return payload;
    }
}