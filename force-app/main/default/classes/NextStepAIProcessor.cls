public without sharing class NextStepAIProcessor implements Queueable, Database.AllowsCallouts{
    private List<NextStepRequest> requests;
    public static Boolean isImmediateNextStepProcessed = false;
    private static final String apiMixedErrorMsg = 'BATCH FAILED: MIXED ERRORS';
    private static final String apiSameErrorMsg = 'BATCH FAILED: SAME ERRORS';

    public NextStepAIProcessor(List<NextStepRequest> requests) {
        this.requests = requests;
    }

    public void execute(QueueableContext context) {
        isImmediateNextStepProcessed = true;
        if (requests == null || requests.isEmpty()) {
            return;
        }
        try {

            GCPAuthUtil.GCPConfig config = GCPAuthUtil.loadConfig('nextSteps');
            String jwt = GCPAuthUtil.createSignedJWT(config);
            String idToken = GCPAuthUtil.exchangeJWTForIdentityToken(jwt, config.identityTokenUrl);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(config.cloudRunEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + idToken);
            req.setBody(JSON.serialize(requests));
            req.setTimeout(120000);

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                processResponse(res.getBody());
            } else {
                PlatformLog.logResult('NextStepAIProcessor','API Error: Status ' + res.getStatusCode() + ' Body: ' + res.getBody(),'','','',true);
            }
        } catch (System.CalloutException e) {
            PlatformLog.logException('CalloutException-NextStepAIProcessor' , e);
        } catch (Exception e) {
            PlatformLog.logException('GeneralException-NextStepAIProcessor' , e);
        }
    }

    private void processResponse(String responseBody) {
        if (String.isBlank(responseBody)) {
            return;
        }
        try {
            ApiResponseWrapper responseWrapper = (ApiResponseWrapper) JSON.deserialize(responseBody, ApiResponseWrapper.class);
           
            if (responseWrapper.statusCode != 200) {
                processWrapperErrorMsg(responseWrapper);
                return; 
            }
            List<Opportunity> oppsToUpdate = new List<Opportunity>();

            if (responseWrapper.result != null) {
                for (NextStepResponse item : responseWrapper.result) {
                    // Check if the individual item was successful (Status 200 or 304). If 304, no updates needed
                    if (item.status == '200') {
                        oppsToUpdate.add(new Opportunity(
                            Id = item.oppId,
                            Next_Steps_Last_Modified__c = item.immediateNextStepValue
                        ));
                    } else if (item.status != '304') {
                        PlatformLog.logResult('NextStepAIProcessor','Error in opp Id - ' + item.oppId + '. Reason - ' + item.errorMsg,'','','',true);
                    }
                }
            }

            if (!oppsToUpdate.isEmpty()) {
                isImmediateNextStepProcessed = true;
                List<Database.SaveResult> updateResults = Database.update(oppsToUpdate, false);
                PlatformLog.logErrors('NextStepAIProcessor - processResponse', updateResults, oppsToUpdate);
            }

        } catch (Exception e) {
            PlatformLog.logException('Parsing/DML Error in processing next Steps Response' , e);
        }
    }

    private void processWrapperErrorMsg(ApiResponseWrapper responseWrapper) {
        if (String.isBlank(responseWrapper.errorMsg)) {
            return;
        }
        if (responseWrapper.errorMsg.contains(apiSameErrorMsg)) {
            PlatformLog.logResult('NextStepAIProcessor', 'Common GCP App Error: ' + responseWrapper.errorMsg, '', '', '', true);
        } else if (responseWrapper.errorMsg.contains(apiMixedErrorMsg)) {
            if (responseWrapper.result != null) {
                for (NextStepResponse item : responseWrapper.result) {
                    PlatformLog.logResult('NextStepAIProcessor','Error in opp Id - ' + item.oppId + '. Reason - ' + item.errorMsg,'','','',true);
                }
            }
        }
    }


    public class NextStepRequest {
        public String oppId;
        public String oldNextStepVal;
        public String newNextStepVal;
        public String lastImmediateNextStepVal;
        public String modifiedByUserName;
    }

    public class NextStepResponse {
        public String oppId; 
        public String immediateNextStepValue;
        public String status; //(304 => Not modified, I dont have to process, If 200 => I will process , if any other code, then i will process errorMsg)
        public String errorMsg; 
    }

    public class ApiResponseWrapper {
        public Integer statusCode;
        public String errorMsg;
        public List<NextStepResponse> result;
    }

}