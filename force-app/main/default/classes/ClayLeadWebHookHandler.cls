public class ClayLeadWebHookHandler implements Queueable, Database.AllowsCallouts {
    private List<Lead> leads;

    public ClayLeadWebhookHandler(List<Lead> leads) {
        this.leads = leads;
    }

    public void execute(QueueableContext context) {
        Gating_Process_Stage__c customSetting = Gating_Process_Stage__c.getInstance();
        if (customSetting == NULL || String.isBlank(customSetting.Clay_Lead_WebHook_URL__c)) {
            System.debug('WebHook URL not available.');
            return;
        }
        String endpoint = customSetting.Clay_Lead_WebHook_URL__c;
        
        for (Lead lead : leads) {
            HttpRequest req = createHttpRequest(lead, endpoint);
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('SLED Response: ' + res);
        }
    }

    private HttpRequest createHttpRequest(Lead lead, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'id' => lead.Id,
            'Email' => lead.Email,
            'FirstName' => lead.FirstName,
            'LastName' => lead.LastName,
            'Phone' => lead.Phone,
            'Company' => lead.Company,
            'Website' => lead.Website,
            'Title' => lead.Website,
            'Street' => lead.Street,
            'City' => lead.City,
            'State' => lead.State,
            'Country' => lead.Country, 
            'PostalCode' => lead.PostalCode
        };

        String jsonPayload = JSON.serialize(payload);
        req.setBody(jsonPayload);

        System.debug('SLED Request: ' + req);
        System.debug('SLED Request Body: ' + req.getBody());

        return req;
    }
}