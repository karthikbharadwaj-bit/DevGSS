public with sharing class CCBAPI {
    public static final CCB_Settings__c CCB_SETTINGS = CCB_Settings__c.getInstance();
    public static final String DIRECT_BASE_ENDPOINT_V2 = CCB_SETTINGS.DirectBaseEndpoint__c + CCB_SETTINGS.APIVersion2Path__c;
    public static final String DIRECT_BASE_ENDPOINT_V3 = CCB_SETTINGS.DirectBaseEndpoint__c + CCB_SETTINGS.APIVersion3Path__c;
    public static final String STATUS_SUBMITTED = 'submitted';
    public static final Integer TEXT_CHARACTER_LIMIT = 255;

    @TestVisible
    class CCBAPIException extends Exception {}

    private static final String CCB_PREFIX = 'Error from CCB: ';
    private static final String UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE = 'Not expected: parameter empty. Parameter name: ';
    public static final String REQUEST_CCB_EXCEPTION_MESSAGE = 'Failed to make CCB request. ' + '\n' + 'Got status: ';
    public static final String SYNC_CCB_FAILED = 'Failed to sync with CCB';
    public static final String SUBMIT_ENGAGE_FAILED = 'Failed to Submit Engage';
    public static final String ENGAGE_SUBMITTED_WITH_ERROR = 'Service is submitted but billing information was not updated. Please, contact your administrator. Billing Id: {0}, Enterprise Account Id: {1}.';
    public static final String ACCOUNT_UPDATE_FAILED = 'An error occured during account update';
    public static final String STATUS_ERROR = 'error';

    public class CCBResponse {
        public String status;
        public List<CCBResponseMessage> messages;
    }

    public class CCBResponseMessage {
        public String severity;
        public String message;
        public String messageDetails;
    }

    /*
    * @description: makes request to CCB with given method, body, Content Type and headers
     */
    public static HttpResponse requestCCB(String endpoint, String method) {
        return requestCCB(endpoint, method, null);
    }

    public static HttpResponse requestCCB(String endpoint, String method, String body) {
        String header = POHelper.isEngageUILessSettingsOn
            ? HttpHelper.prepareJWTAuthHeader(HttpHelper.CERT_DEV_NAME_CCB)
            : HttpHelper.prepareBasicAuthHeader(
                CCB_SETTINGS.Login__c,
                CCB_SETTINGS.Password__c
            );
        return requestCCB(endpoint, method, body, HttpHelper.CONTENT_TYPE_APPLICATION_JSON, header);
    }

    public static HttpResponse requestCCB(String endpoint, String method, String body, String contentTypeValue, String headers) {
        StringHelper.validateStrict(endpoint, UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + ' endpoint');
        StringHelper.validateStrict(method, UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + ' method');
        if (method == HttpHelper.METHOD_GET && String.isNotBlank(body)) {
            throw new HttpHelper.HttpHelperException('GET method should have no body on Http request');
        }
        String authorizationHeader = headers;
        HttpRequest request = HttpHelper.prepareBasicAuthRequest(endpoint, method, authorizationHeader, body, contentTypeValue);
        request.setHeader('X-TokenId', HttpHelper.formXTokenId());
        request.setHeader('Referer', URL.getOrgDomainUrl().toExternalForm());
        request.setTimeout(HttpHelper.MAX_TIMEOUT_MS);
        System.debug('CCB request endpoint: ' + endpoint + '\n' + 'CCB request body: ' + body);
        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch(Exception e) {
            if (e.getMessage().contains('Authorization token is invalid')) {
                throwCCBException('Authorization token is invalid - make sure that credentials are correct');
            }
            throwCCBException(e.getMessage());
        }
        return response;
    }

    public static Response validateBillingAddress(BillingWrappers.BillingAddress billingAddress) {
        String endpoint = DIRECT_BASE_ENDPOINT_V2 + CCB_SETTINGS.ValidatePath__c;
        Response response = new Response();
        try {
            HttpResponse httpResp = requestCCB(endpoint, HttpHelper.METHOD_POST, JSON.serialize(billingAddress));
            if (HttpHelper.isSuccess(httpResp)) {
                response.setData('body', JSON.deserializeUntyped(httpResp.getBody()));
            } else {
                response.error(addCCBPrefix('An error occurred while validating the address. ' + getErrorMessage(httpResp, endpoint)));
            }
        } catch (Exception ex) {
            throwCCBException('An error occurred while validating the address. (' + ex.getMessage() + ')');
        }
        return response;
    }

    public static Response getEngagePlatforms(Boolean isEngageVoice) {
        Response resp = new Response();
        String platformsPath = isEngageVoice ? CCB_SETTINGS.EVPlatformsPath__c : CCB_SETTINGS.EDPlatformsPath__c;
        String endpoint = DIRECT_BASE_ENDPOINT_V2 + platformsPath;
        try {
            HttpResponse httpResp = requestCCB(endpoint, HttpHelper.METHOD_GET);
            if (HttpHelper.isSuccess(httpResp)) {
                resp.setData('body', JSON.deserializeUntyped(httpResp.getBody()));
            } else {
                resp.error(addCCBPrefix('An error occurred while getting platforms. ' + getErrorMessage(httpResp, endpoint)));
            }
        } catch (Exception ex) {
            throwCCBException('An error occurred while getting platforms. (' + ex.getMessage() + ')');
        }
        return resp;
    }

    public static Response submitEngage(BillingWrappers.RequestSubmitParams params) {
        HttpResponse httpResp = requestCCB(getDirectBaseEndpointCCB(params), HttpHelper.METHOD_POST, JSON.serialize(params.data));
        return handleSubmitResponse(httpResp, params);
    }

    private static Response handleSubmitResponse(HttpResponse httpResp, BillingWrappers.RequestSubmitParams params) {
        return HttpHelper.isSuccess(httpResp)
            ? handleSubmitSuccess(httpResp.getBody(), params)
            : handleSubmitError(httpResp, getDirectBaseEndpointCCB(params));
    }

    private static Response handleSubmitSuccess(String responseBody, BillingWrappers.RequestSubmitParams params) {
        Response resp = new Response();
        BillingWrappers.EngageAccount engageAcc;

        try {
            BillingWrappers.SubmitEngageResponse engageResp = (BillingWrappers.SubmitEngageResponse) JSON.deserialize(
                responseBody,
                BillingWrappers.SubmitEngageResponse.class
            );

            engageAcc = params.isEngageVoice ? engageResp.engageVoiceAccount : engageResp.engageDigitalAccount;

            updateAccountBillingInfo(params, engageAcc);
            resp.setData('status', STATUS_SUBMITTED);
        } catch (Exception e) {
            resp.error(addCCBPrefix(ACCOUNT_UPDATE_FAILED), getErrorMessage(engageAcc, e.getMessage()));
            resp.setData('engageResponse', responseBody);

            System.debug('Engage response: ' + responseBody);
            System.debug('Exception message: ' + e.getMessage() + '/n' + e.getStackTraceString());
        }
        return resp;
    }

    private static void updateAccountBillingInfo(BillingWrappers.RequestSubmitParams params, BillingWrappers.EngageAccount engageAcc) {
        Account acc = new Account(
            Id = params.accountId,
            RC_Engage_Account_ID__c = engageAcc?.engageAccountId
        );

        if (!params.isMPUB || !params.isMultiProductTechnicalQuote) {
            acc.Billing_ID__c = engageAcc?.ngbsAccount?.id;
            acc.RC_User_ID__c = engageAcc?.enterpriseAccountId;
        }

        if (params.isEngageVoice) {
            acc.EV_Platform__c = StringHelper.safeSubstring(params.data?.platformId, TEXT_CHARACTER_LIMIT);
            acc.EV_Account_ID__c = StringHelper.safeSubstring(engageAcc?.mainAccountId, TEXT_CHARACTER_LIMIT);
        } else {
            acc.ED_Platform__c = StringHelper.safeSubstring(params.data?.platformId, TEXT_CHARACTER_LIMIT);
            acc.ED_Account_ID__c = StringHelper.safeSubstring(engageAcc?.id, TEXT_CHARACTER_LIMIT);
            acc.Engage_Domain__c = StringHelper.safeSubstring(params.data?.engageDomain, TEXT_CHARACTER_LIMIT);
        }

        update acc;
    }

    private static Response handleSubmitError(HttpResponse httpResp, String baseLocalEndpoint) {
        Response resp = new Response();
        try {
            BillingWrappers.SubmitEngageError responseParams = (BillingWrappers.SubmitEngageError) JSON.deserialize(
                httpResp.getBody(),
                BillingWrappers.SubmitEngageError.class
            );
            resp.error(SUBMIT_ENGAGE_FAILED, responseParams.message);
        } catch (Exception e) {
            throwCCBException(REQUEST_CCB_EXCEPTION_MESSAGE + getErrorMessage(httpResp, baseLocalEndpoint));
        }
        return resp;
    }

    public static String getErrorMessage(HttpResponse httpResp, String endpoint) {
        String reqToLog = 'Request endpoint: ' + endpoint;
        String errorMessage = (httpResp.getStatus() != null ? httpResp.getStatus() + '. Please Contact Your Administrator.' : '')
        + '\n' + (httpResp.getBody() != null && httpResp.getBody() != ''  ? '\n' + 'Technical Details: ' + httpResp.getBody() + '.' : '')
        + '\n' + reqToLog;
        return errorMessage;
    }

    @AuraEnabled
    public static String getCountries() {
        String endpoint = DIRECT_BASE_ENDPOINT_V2 + CCB_SETTINGS.CountriesPath__c;
        Response resp = new Response();
        try {
            HttpResponse httpResp = requestCCB(endpoint, HttpHelper.METHOD_GET);
            if (HttpHelper.isSuccess(httpResp)) {
                List<BillingWrappers.Country> countries = (List<BillingWrappers.Country>) JSON.deserialize(httpResp.getBody(), List<BillingWrappers.Country>.class);
                resp.setData('countries', countries);
            } else {
                resp.error(addCCBPrefix('An error occurred while getting the list of countries. ' + getErrorMessage(httpResp, endpoint)));
            }
        } catch (Exception ex) {
            throwCCBException('An error occurred while getting the list of countries. (' + ex.getMessage() + ')');
        }
        return JSON.serialize(resp);
    }

    public static Response handleResponse(HttpResponse httpResp) {
        Response resp = new Response();
        CCBResponse ccbResp = (CCBResponse) JSON.deserialize(
            httpResp.getBody(), CCBResponse.class
        );

        for (CCBResponseMessage m : ccbResp?.messages != null
                ? ccbResp.messages
                : new List<CCBResponseMessage>()) {
            if (m.severity == STATUS_ERROR) {
                resp.addMessage(
                    SYNC_CCB_FAILED,
                    StringHelper.safeString(m.message) + '\n' + StringHelper.safeString(m.messageDetails),
                    m.severity
                );
            }
        }

        if (ccbResp?.status == STATUS_ERROR) {
            resp.error();
        }

        return resp;
    }

    public static String getSignUpUILessEndpoint(Boolean isMPUBAccount) {
        String baseEndpoint = isMPUBAccount ? DIRECT_BASE_ENDPOINT_V3 : DIRECT_BASE_ENDPOINT_V2;
        return baseEndpoint + CCB_SETTINGS.SignUpPath__c;
    }

    @TestVisible
    private static String addCCBPrefix(String message) {
        return CCB_PREFIX + message;
    }

    private static void throwCCBException(String errorMessage) {
        throw new CCBAPIException(addCCBPrefix(errorMessage));
    }

    private static String getErrorMessage(BillingWrappers.EngageAccount engageAcc, String eMessage) {
        return engageAcc?.ngbsAccount?.id != null
            ? String.format(ENGAGE_SUBMITTED_WITH_ERROR, new List<Object> {
                engageAcc.ngbsAccount.id,
                engageAcc.enterpriseAccountId
            })
            : eMessage;
    }

    private static String getDirectBaseEndpointCCB(BillingWrappers.RequestSubmitParams params) {
        String submitPath = params.isEngageVoice ? CCB_SETTINGS.EVSubmit__c : CCB_SETTINGS.EDSubmit__c;
        String baseEndpoint = params.isMPUB == true
            ? DIRECT_BASE_ENDPOINT_V3
            : DIRECT_BASE_ENDPOINT_V2;
        return baseEndpoint + submitPath + '/' + params.targetId;
    }
}