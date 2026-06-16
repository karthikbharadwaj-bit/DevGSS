public class ClayAccountWebHookHandler implements Queueable, Database.AllowsCallouts {
    private List<Account> accounts;

    public ClayAccountWebHookHandler( List<Account> accts) {
        this.accounts = accts;
    }

    public void execute(QueueableContext context) {
        Gating_Process_Stage__c customSetting = Gating_Process_Stage__c.getInstance();
        if (customSetting == NULL || String.isBlank(customSetting.Clay_Account_WebHook_URL__c)) {
            System.debug('WebHook URL not available.');
            return;
        }
        String acctEndpoint = customSetting.Clay_Account_WebHook_URL__c;
        for (Account acct : accounts) {
            HttpRequest request = createHttpRequest(acct, acctEndpoint);
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug('SLED Response: ' + response);
        }
    }

    private HttpRequest createHttpRequest(Account acct, String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'Id' => acct.Id,
            'Name' => acct.Name,
            'Website' => acct.Website,
            'BillingStreet' => acct.BillingStreet,
            'BillingState' => acct.BillingState,
            'BillingCity' => acct.BillingCity,
            'BillingCountry' => acct.BillingCountry,
            'BillingPostalCode' => acct.BillingPostalCode
        };

        String jsonPayload = JSON.serialize(payload);
        req.setBody(jsonPayload);

        System.debug('SLED Request: ' + req);
        System.debug('SLED Request Body: ' + req.getBody());

        return req;
    }
}