public class SquidOpportunityWebhookHandler {
    @InvocableMethod(label='Send Opportunity Webhook' description='Sends a webhook when Discovery_Next_Steps__c is changed on an Opportunity.')
    public static void sendWebhook(List<ID> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return;
        }

        for (ID opportunityId : opportunityIds) {
            sendAsyncWebhook(opportunityId);
        }
    }

    @future(callout=true)
    private static void sendAsyncWebhook(ID opportunityId) {
        String namedCredential = 'SquidOpportunityWebhook';
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + namedCredential + '/webhooks/opportunityChangedWebhook?id=' + opportunityId);
        request.setMethod('GET');
        Http http = new Http();
        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 200) {
            List<PlatformLog__c> logs = new List<PlatformLog__c>();
           	logs.add(PlatformLog.buildLog(
                    'SquidOpportunityWebhookHandler',
                    'Webhook request failed with status code: ' + response.getStatusCode() + ' and Response body: ' + response.getBody(),
                    null,
                    null,
                    null
                )
          	);
            PlatformLog.logResults(logs);
        }
    }
}