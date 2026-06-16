@RestResource(UrlMapping='/FedRampSyncAccountWS/*')
global with sharing class FedRampSyncAccountWS {

    @HttpPost
    global static void handleRequest() {
        PlatformLog__c log;

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }
        Response resp = new Response();

        String body = RestContext.request.requestBody.toString();
        RequestParams params;
        try {
            params = (RequestParams) JSON.deserialize(body, RequestParams.class);
            switch on params.action {
                when 'SyncAccountWs.synAccountNew' {
                    if (!params.syncAcctInputParam.isEmpty()) {
                        resp.setData(
                            'SyncAccountWs.synAccountNew',
                            SyncAccountWS.synAccountNew(params.syncAcctInputParam[0])
                        );
                    }
                }
                when 'SyncAccountWs.synAccountCreateUser' {
                    if (!params.syncAcctInputParam.isEmpty()) {
                        resp.setData(
                            'SyncAccountWs.synAccountCreateUser',
                            SyncAccountWS.synAccountCreateUser(params.syncAcctInputParam[0])
                        );
                    }
                }
                when 'SyncAccountWs.synAccountCreateUsers' {
                    resp.setData(
                        'SyncAccountWs.synAccountCreateUsers',
                        SyncAccountWS.synAccountCreateUsers(params.syncAcctInputParam)
                    );
                }
                when 'SyncAccountWsBilling.applyBillingIdAndPackages' {
                    resp.setData(
                        'SyncAccountWsBilling.applyBillingIdAndPackages',
                        SyncAccountWSBilling.applyBillingIdAndPackages(params.billingAcctInfo)
                    );
                }
                when 'SyncAccountWsBilling.synAccountNew' {
                    resp.setData(
                        'SyncAccountWsBilling.synAccountNew',
                        SyncAccountWSBilling.synAccountNew(params.syncAcctInputParamBilling)
                    );
                }
                when 'SyncAccountWsBilling.synAccountCreateUser' {
                    resp.setData(
                        'SyncAccountWsBilling.synAccountCreateUser',
                        SyncAccountWSBilling.synAccountCreateUser(params.syncAcctInputParamBilling)
                    );
                }
            }

        } catch(Exception ex) {
            System.debug('///FedRamp SyncAccountWS exception ' + ex);

            String errorMessage = 'Sync failed on ' + params?.action + ' action: ' + ex.getMessage();
            log = PlatformLog.buildLog('FedRampSyncAccountWs', errorMessage, ex.getStackTraceString(), '', '');
            insert log;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(log));
        }
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(resp));
    }

    public class RequestParams {
        public String action;
        /* SyncAccountWs params */
        public SyncAccountWS.syncAcctInputParam[] syncAcctInputParam;
        /* SyncAccountWsBilling params */
        public SyncAccountWsBilling.BillingAcctInfo billingAcctInfo;
        public SyncAccountWsBilling.syncAcctInputParamBilling syncAcctInputParamBilling;
    }
}