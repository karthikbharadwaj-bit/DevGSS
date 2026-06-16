public class SLEDWebServiceCallout implements Queueable, Database.AllowsCallouts {
    private List<Lead> leads;
    private Map<Id, String> mapSMCountriesToLeads;

    public SLEDWebServiceCallout(List<Lead> leads, Map<Id, String> mapSMCountriesToLeads) {
        this.leads = leads;
        this.mapSMCountriesToLeads = mapSMCountriesToLeads;
    }

    public void execute(QueueableContext context) {
        Gating_Process_Stage__c customSetting = Gating_Process_Stage__c.getInstance();
        String endpoint = customSetting.SLED_WS_URL__c;
        
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
            'email' => lead.Email,
            'website' => lead.Website,
            'company' => lead.Company,
            'sector' => lead.Sector__c,
            'country' => mapSMCountriesToLeads.get(lead.Id)
        };

        String jsonPayload = JSON.serialize(payload);
        req.setBody(jsonPayload);

        System.debug('SLED Request: ' + req);
        System.debug('SLED Request Body: ' + req.getBody());

        return req;
    }
}