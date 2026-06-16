public with sharing class FunnelAPI {

    class FunnelAPIException extends Exception {}

    private static final GW_Settings__c GW_SETTINGS = GW_Settings__c.getInstance();

    public final static String ERROR_MESSAGE_TO_ADMINISTRATOR = 'An error occurred. Please try again later or contact your system administrator.';
    public final static String ERROR_MESSAGE_DEVICES = 'An error occurred during get device availability info';
    public final static String ERROR_MESSAGE_TIMEZONES = 'An error occurred during get timezones info';
    private final static String SAF_PREFIX = 'Error from SAF: ';

    private virtual class FunnelRequestFactory extends HttpRequestFactory {
        protected FunnelRequestFactory() {
            super();
            this.method = HttpHelper.METHOD_POST;
            this.headers.put('Authorization', HttpHelper.prepareBasicAuthHeader(GW_SETTINGS.Login__c, GW_SETTINGS.Password__c));
            this.headers.put('Referer', URL.getOrgDomainUrl().toExternalForm());
            this.headers.put('X-TokenId', HttpHelper.formXTokenId().replace('Salesforce', GW_SETTINGS.Source__c));
            this.timeout = HttpHelper.MAX_TIMEOUT_MS;
        }
    }

    private class AuxiliaryRequestFactory extends FunnelRequestFactory {
        public AuxiliaryRequestFactory(String body) {
            super();
            this.endpoint = GW_SETTINGS.BaseEndpoint__c + GW_SETTINGS.SFAPath__c;
            this.body = body;
            System.debug('SAF request endpoint: ' + this.endpoint + '\n' + 'SAF request body: ' + this.body);
        }
    }

    private class SignUpRequestFactory extends FunnelRequestFactory {
        public SignUpRequestFactory(String endpoint, String body, String xRequestId) {
            super();
            this.endpoint = endpoint + GW_SETTINGS.SignUpPath__c;
            this.body = body;
            this.headers.put('X-RequestId', xRequestId);
            System.debug('SAF request endpoint: ' + this.endpoint + '\n' + 'SAF request body: ' + this.body);
        }
    }

    private class SignUpProServRequestFactory extends FunnelRequestFactory {
        public SignUpProServRequestFactory(String body) {
            super();
            this.endpoint = GW_SETTINGS.BaseEndpoint__c + GW_SETTINGS.SignUpProServPath__c;
            this.body = body;
            System.debug('SAF ProServ request endpoint: ' + this.endpoint + '\n' + 'SAF ProServ request body: ' + this.body);
        }
    }

    private class SignUpEventsRequestFactory extends FunnelRequestFactory {
        public SignUpEventsRequestFactory(String body) {
            super();
            this.endpoint = GW_SETTINGS.BaseEndpoint__c + GW_SETTINGS.SignUpEventsPath__c;
            this.body = body;
            System.debug('SAF ProServ request endpoint: ' + this.endpoint + '\n' + 'SAF ProServ request body: ' + this.body);
        }
    }

    public class MultiProductMVPRequestBody {
        @TestVisible
        private Map<String, Object> requestBodyMap = new Map<String, Object>();

        public MultiProductMVPRequestBody() {}

        public MultiProductMVPRequestBody(POWrappers.SignUpRequestBody body) {
            requestBodyMap.put('method', 'fsg.processOrder');
            body.requestBodyMap.put('orderProcessingOptions', new OrderProcessingOptions());
            requestBodyMap.put('params', body.requestBodyMap);
        }
    }

    public class OrderProcessingOptions {
        public Boolean showDetailedResponse = false;
        public Boolean deferred = true;
        public Boolean useClientCallBackUrl = true;

        public orderProcessingOptions() {}
    }

    // SignUp Response

    public class FunnelResponse {
        public FunnelResult result;
        public String FSG_SID;
        public String id;
        public FunnelError error;
    }

    public class FunnelError {
        public String code;
        public String message;
        public ErrorData data;
    }

    public class ErrorData {
        public String OPPID;
        public List<ClientCallBackUsageInfo> clientCallBackUsageInfo;
    }

    // SignUp Callback

    public class FunnelCallback {
        public FunnelResult result;
        public FunnelError error;
        public String FSG_SID;
        public String id;
    }

    public class FunnelResult {
        public String orderStatus;
        public String userId;
        public String billingId;
        public String test_confirmation_url;
        public String detailedResponse;
        public String OPPID;
        public String billingPackageId;
        public List<ClientCallBackUsageInfo> clientCallBackUsageInfo;
        public List<CallBackInfo> warningInfo;
    }

    public class ClientCallBackUsageInfo {
        public Boolean success;
        public String callBackUrl;
        public CallBackInfo errorInfo;
    }

    public class CallBackInfo {
        public String code;
        public String message;
    }

    public class CallbackServiceBuilder{
        public string chatterMessage;
        public string oppId;
        public string orderStatus;
        public string billingId;
        public string enterpriseAccountId;
        public string errorMessage;
        public string billingPackageId;
        public string serviceName;
        public string serviceOrderId;
        
        public CallbackServiceBuilder(String body){
            Map<string,object> callbackBodyMap = (Map<String, Object>) JSON.deserializeUntyped(body);
            if(!callbackBodyMap.containskey('serviceOrderId')){
                setOfficeCallbackParams(body);
            }else{
                setUnifiedCallbackParams(body);
            }
        }
        
        public void setOfficeCallbackParams(String body){
            FunnelAPI.FunnelCallback callback = (FunnelAPI.FunnelCallback) JSON.deserialize(body, FunnelAPI.FunnelCallback.class);
            oppId = callback.result != null ? callback.result.OPPID : callback.error?.data?.OPPID;
            orderStatus = callback.result?.orderStatus;
            billingId = callback.result?.billingId;
            billingPackageId = callback.result?.billingPackageId;
            enterpriseAccountId = callback.result?.userId;
            errorMessage = callback.error?.message;
            serviceName = 'MVP';
        }
        
        public void setUnifiedCallbackParams(String body){
            FunnelAPI.UnifiedCallbackFunnel callback = (FunnelAPI.UnifiedCallbackFunnel) JSON.deserialize(body, FunnelAPI.UnifiedCallbackFunnel.class);
            oppId = callback.salesOrderId;
            orderStatus = callback.signupResult?.status;
            billingId = callback.signupResult?.data?.billingId;
            billingPackageId = callback.signupResult?.data?.billingPackageId;
            enterpriseAccountId = callback.signupResult?.data?.enterpriseAccountId;
            errorMessage = callback.signupResult?.error?.message;
            serviceOrderId = callback.serviceOrderId;
            serviceName = getServiceName(serviceOrderId);
        }

        public string getServiceName(String quoteId){
            String serviceName = '';
            Quote callbackQuote = (Quote) new ListOptional(new QuoteSelector()
                .selectQuoteById(new List<Object> {quoteId})
                .executeQuery()).getFirst();
                List<object> pInfo = (List<object>)Json.deserializeUntyped((String)callbackQuote?.get('Package_Info__c'));
                Map<String, Object> packageInfo = (Map<String, Object>)(pInfo[0]);
                if(!packageInfo.isEmpty() && packageInfo.containsKey('productName')){
                    serviceName = (string)packageInfo.get('productName');
                }
            return serviceName;
        }
    }

    public class UnifiedCallbackFunnel{
        public string salesAgentId;
        public string salesOrderId;
        public string serviceOrderId;
        public SignupResult signupResult;
    }

    public class signupResult{
        public string status; 
        public Data data;
        public Error error;
    }

    public class Data{
        public string enterpriseAccountId;
        public string serviceAccountId;
        public string billingId;
        public string billingPackageId;
    }

    public class Error{
        public string code;
        public string message;
    }

    public class ErrorDetail {
        public String errorCode;
        public String message;
        public String parameterName;
    }

    public class ErrorWrapper {
        public List<ErrorDetail> errors;
    }


    public static Response getDevicesAvailability(String packageId, String packageVersion, List<String> deviceIds, List<String> countryIds) {
        String body = JSON.serialize(new BillingWrappers.DeviceAvailabilityBody(packageId, packageVersion, deviceIds, countryIds)).replace('funnelPackage','package');
        HttpRequest request = new AuxiliaryRequestFactory(body).createRequest();
        HttpResponse httpResponse = sendRequest(request);
        Response res = new Response();
        if (HttpHelper.isSuccess(httpResponse) && httpResponse.getBody() != null) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
            if (responseMap?.containsKey('result')) {
                BillingWrappers.DeviceAvailabilityResponse dar = new BillingWrappers.DeviceAvailabilityResponse((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(responseMap.get('result'))));
                res.setData('deviceAvailability', dar);
            } else {
                res.error(addSafPrefix(ERROR_MESSAGE_DEVICES));
            }
        } else {
            res.error(addSafPrefix(ERROR_MESSAGE_DEVICES));
        }
        return res;
    }

    @AuraEnabled
    public static String getTimezones(String packageId, String packageVersion) {
        String body = JSON.serialize(new BillingWrappers.TimezoneBody(packageId, packageVersion)).replace('funnelPackage','package');
        HttpRequest request = new AuxiliaryRequestFactory(body).createRequest();
        HttpResponse httpResponse = sendRequest(request);
        Response res = new Response();
        if (HttpHelper.isSuccess(httpResponse) && httpResponse.getBody() != null) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
            if (responseMap?.containsKey('result')) {
                res.setData('timezones', responseMap.get('result'));
            } else if (responseMap.containsKey('error')) {
                res.error(addSafPrefix(ERROR_MESSAGE_TIMEZONES));
            }
        } else {
            res.error(addSafPrefix(ERROR_MESSAGE_TIMEZONES));
        }
        return JSON.serialize(res);
    }

    public static FunnelResponse multiProductMVPSignUp(Opportunity opp, POWrappers.SignUpRequestBody body) {
        MultiProductMVPRequestBody mvpBody = new FunnelAPI.MultiProductMVPRequestBody(body);
        String xRequestId = getXRequestId(opp.Id, opp.AccountId);
        String endpoint = (GW_SETTINGS.BaseEndpoint_EUR__c != null && opp.CurrencyIsoCode == 'EUR') ? GW_SETTINGS.BaseEndpoint_EUR__c : GW_SETTINGS.BaseEndpoint__c;

        return signUpMVPRequest(xRequestId, JSON.serialize(mvpBody.requestBodyMap), endpoint);
    }

    public static FunnelResponse signUpMVPRequest(String xRequestId, String body, String endpoint) {
        HttpRequest request = new SignUpRequestFactory(endpoint, body, xRequestId).createRequest();
        String responseBody = sendRequest(request).getBody();
        FunnelResponse gwResponse = (FunnelResponse) JSON.deserialize(responseBody, FunnelResponse.class);
        return gwResponse;
    }

    public static FunnelResponse multiProductProServSignUp(Opportunity opp, POWrappers.SignUpRequestBody body) {
        FunnelResponse gwResponse = new FunnelResponse();
        String requestBody = JSON.serialize(body.requestBodyMap);
        HttpRequest request = new SignUpProServRequestFactory(requestBody).createRequest();
        HttpResponse response = sendRequest(request);
        if (response.getStatusCode() != 202) {
            String responseBody = response.getBody();
            gwResponse = (FunnelResponse) JSON.deserialize(responseBody, FunnelResponse.class);
        }
        return gwResponse;
    }

    public static HttpResponse multiProductEventsSignUp(Opportunity opp, POWrappers.SignUpRequestBody body) {
        
        String requestBody = JSON.serialize(body.requestBodyMap);
        HttpRequest request = new SignUpEventsRequestFactory(requestBody).createRequest();
        HttpResponse response = sendRequest(request);
        
        Id orgId = UserInfo.getOrganizationId();
        RCSequence__c rcSequence = [
        SELECT SubSequence__c, SandboxNumber__c
        FROM RCSequence__c
        WHERE SetupOwnerId =: orgId FOR UPDATE
        ].get(0);
        Integer sq = NumberHelper.toNumber((Integer) rcSequence.SubSequence__c) + 1;
        rcSequence.SubSequence__c = sq;
        update rcSequence;   
        
        return response;
       
    }

    private static HttpResponse sendRequest(HttpRequest request) {
        HttpResponse httpResponse;
        try {
            httpResponse = new Http().send(request);
        } catch (Exception e) {
            if (e.getMessage().contains('Authorization token is invalid')) {
                throwFunnelAPIException('Authorization token is invalid - make sure that credentials are correct');
            }
            throwFunnelAPIException(e.getMessage());
        }
        return httpResponse;
    }

    private static String getXRequestId (String oppId, String accId) {
        return GW_SETTINGS.Source__c + ':' + accId + '_' + oppId + '_' + String.valueOf(DateTime.now()).replaceAll('[ :]', '_');
    }

    @TestVisible
    private static String addSafPrefix(String message) {
        return SAF_PREFIX + message;
    }

    private static void throwFunnelAPIException(String errorMessage) {
        throw new FunnelAPIException(addSafPrefix(errorMessage));
    }
}