@IsTest
public class CCBAPIMock implements HttpCalloutMock {
    public static final String SUBMIT_ERROR_MESSAGE = 'Test Error Message';
    private static final String VALIDATION_STATUS_AMBIGUOUS = 'ambiguous';
    private static final String VALIDATION_STATUS_VALID = 'valid';

    private class CCBAPIMockException extends Exception {}

    // Different multi-product flows use different endpoints.
    // With this Enum we can simulate different flows from the CCB side
    public enum MPFlow {
        MP_LITE,
        MPUB
    }

    private final String DIRECT_BASE_ENDPOINT;
    private final String EV_SUBMIT_START;
    private final String ED_SUBMIT_START;
    private final MPFlow MP_FLOW;
    private String body = '';

    public Boolean raiseException = false;
    public Integer statusCode = 200;
    public String errorMessage = 'Internal Server Error. Please, try again later';

    // validateBillingAddress
    public String validationStatus = VALIDATION_STATUS_VALID;

    public CCBAPIMock() {
        this(MPFlow.MP_LITE);
    }

    public CCBAPIMock(MPFlow flow) {
        switch on flow {
            when MP_LITE {
                DIRECT_BASE_ENDPOINT = CCBAPI.DIRECT_BASE_ENDPOINT_V2;
            }
            when MPUB {
                DIRECT_BASE_ENDPOINT = CCBAPI.DIRECT_BASE_ENDPOINT_V3;
            }
            when else {
                throw new CCBAPIMockException('Error: ' + flow + ' is not implemented for CCBAPIMock');
            }
        }

        MP_FLOW = flow;
        EV_SUBMIT_START = DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.EVSubmit__c + '/';
        ED_SUBMIT_START = DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.EDSubmit__c + '/';
    }

    public HttpResponse respond(HttpRequest req) {
        validateRequest(req);
        handleRequest(req);

        return createResponse();
    }

    private void validateRequest(HttpRequest req) {
        if (!req.getEndpoint().startsWith(DIRECT_BASE_ENDPOINT)) {
            throw new CCBAPIMockException('Error: Unexpected base endpoint is used for ' + MP_FLOW + ' flow: ' + req.getEndpoint());
        }
    }

    private void handleRequest(HttpRequest req) {
        String endpoint = req.getEndpoint();
        String method = req.getMethod();

        if (method == HttpHelper.METHOD_GET) {
            handleGet(endpoint);
        } else if (method == HttpHelper.METHOD_POST) {
            handlePost(endpoint);
        } else {
            raiseHandlerNotFoundException(method);
        }
    }

    private void handleGet(String endpoint) {
        if (endpoint == DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.EVPlatformsPath__c) {
            // getEngagePlatforms isEngageVoice == true
            setResponseBody(getEngagePlatformsBody(true));
        } else if (endpoint == DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.EDPlatformsPath__c) {
            // getEngagePlatforms isEngageVoice == false
            setResponseBody(getEngagePlatformsBody(false));
        } else if (endpoint == DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.CountriesPath__c) {
            // getCountries
            setResponseBody(getCountriesBody());
        } else {
            raiseHandlerNotFoundException(HttpHelper.METHOD_GET, endpoint);
        }
    }

    private void handlePost(String endpoint) {
        if (endpoint == DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.ValidatePath__c) {
            // validateBillingAddress
            setResponseBody(validateBillingAddressBody());
        } else if (endpoint.startsWith(EV_SUBMIT_START)) {
            // submitEngage isEngageVoice == true
            setResponseBody(
                getEngageSubmitResponse(null, true),
                submitEngageErrorBody()
            );
        } else if (endpoint.startsWith(ED_SUBMIT_START)) {
            // submitEngage isEngageVoice == false
            setResponseBody(
                getEngageSubmitResponse(endpoint.removeStart(ED_SUBMIT_START), false),
                submitEngageErrorBody()
            );
        } else if (endpoint == DIRECT_BASE_ENDPOINT + CCBAPI.CCB_SETTINGS.SignUpPath__c) {
            setResponseBody(
                ccbResponseBody('', '', CCBAPI.STATUS_SUBMITTED),
                ccbResponseBody(SUBMIT_ERROR_MESSAGE, SUBMIT_ERROR_MESSAGE, CCBAPI.STATUS_ERROR)
            );
        } else {
            raiseHandlerNotFoundException(HttpHelper.METHOD_POST, endpoint);
        }
    }

    private void raiseHandlerNotFoundException(String method) {
        raiseHandlerNotFoundException(method, null);
    }

    private void raiseHandlerNotFoundException(String method, String endpoint) {
        String endpointPart = String.isBlank(endpoint) ? '' : ' ' + endpoint + ' endpoint';
        throw new CCBAPIMockException(
            'Error: there is no handler for ' + method + endpointPart + ' in CCBAPIMock'
        );
    }

    private HttpResponse createResponse() {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.statusCode);
        res.setBody(this.body);

        return res;
    }

    private void setResponseBody(String successBody) {
        setResponseBody(successBody, '');
    }

    private void setResponseBody(String successBody, String errorBody) {
        this.body = isError() ? errorBody : successBody;
    }

    private String validateBillingAddressBody() {
        Map<String, Object> responseBody = new Map<String, Object>();
        responseBody.put('status', this.validationStatus);

        if (this.validationStatus == VALIDATION_STATUS_AMBIGUOUS) {
            responseBody.put(
                'suggestedAddresses',
                new List<BillingWrappers.BillingAddress> {getBillingAddress()}
            );
        }

        return JSON.serialize(responseBody);
    }

    private String getEngagePlatformsBody(Boolean isEngageVoice) {
        return JSON.serialize(isEngageVoice ? getVoiceEngagePlatforms() : getDigitalEngagePlatforms());
    }

    private String getCountriesBody() {
        BillingWrappers.Country country1 = new BillingWrappers.Country();
        country1.id = 54;
        country1.name = 'Croatia';
        country1.code = 'HRV';
        country1.codeAlpha2 = 'HR';
        country1.stateIsRequired = false;
        country1.states = new List<BillingWrappers.State>();

        BillingWrappers.Country country2 = new BillingWrappers.Country();
        country2.id = 56;
        country2.name = 'Cyprus';
        country2.code = 'CYP';
        country2.codeAlpha2 = 'CY';
        country2.stateIsRequired = false;
        country2.states = new List<BillingWrappers.State>();

        return JSON.serialize(new List<BillingWrappers.Country> {country1, country2});
    }

    private String ccbResponseBody(String message, String messageDetails, String status) {
        CCBAPI.CCBResponseMessage ccbMessage = new CCBAPI.CCBResponseMessage();
        ccbMessage.message = message;
        ccbMessage.messageDetails = messageDetails;
        ccbMessage.severity = status;

        CCBAPI.CCBResponse response = new CCBAPI.CCBResponse();
        response.status = status;
        response.messages = new List<CCBAPI.CCBResponseMessage> {ccbMessage};

        return JSON.serialize(response);
    }

    private String submitEngageErrorBody() {
        if (this.raiseException) {
            return this.errorMessage;
        }

        BillingWrappers.SubmitEngageError responseParams = new BillingWrappers.SubmitEngageError();
        responseParams.message = SUBMIT_ERROR_MESSAGE;
        responseParams.status = Response.STATUS_ERROR;

        return JSON.serialize(responseParams);
    }

    private Boolean isError() {
        return this.statusCode < 200 || this.statusCode >= 300;
    }

    private List<Map<String, Object>> getVoiceEngagePlatforms() {
        Map<String, Object> platform1 = new Map<String, Object> {
            'id' => 'aws91-l16',
            'title' => 'aws91-l16 env lab',
            'vpcNames' => 'aws91',
            'vpcIds' => 'vpc-02c87b7c99471ed9f',
            'group' => 'US1',
            'pci' => true,
            'newAccountsAllowed' => true,
            'order' => 1
        };

        Map<String, Object> platform2 = new Map<String, Object> {
            'id' => 'aws91new-l16',
            'title' => 'aws91new-l16 env lab',
            'vpcNames' => 'aws91',
            'vpcIds' => 'vpc-02c87b7c99471ed9f',
            'group' => 'US1',
            'pci' => true,
            'newAccountsAllowed' => true,
            'order' => 2
        };

        return new List<Map<String, Object>> {platform1, platform2};
    }

    private List<Map<String, Object>> getDigitalEngagePlatforms() {
        Map<String, Object> platform1 = new Map<String, Object> {
            'name' => 'ed-eup-us1-s1-fra20',
            'title' => 'AWS26-EUP, \'Europe (Frankfurt) WRONG\'',
            'vpcNames' => 'aws26',
            'vpcIds' => 'vpc-0f57e9ee384c3b8d1',
            'group' => 'US1',
            'pci' => true,
            'newAccountsAllowed' => true,
            'order' => 1
        };

        Map<String, Object> platform2 = new Map<String, Object> {
            'name' => 'ed-eup-us1-s1',
            'title' => 'AWS26-EUP, \'Europe (Frankfurt)\'',
            'vpcNames' => 'aws26',
            'vpcIds' => 'vpc-0f57e9ee384c3b8d1',
            'group' => 'US1',
            'pci' => true,
            'newAccountsAllowed' => true,
            'order' => 1
        };

        return new List<Map<String, Object>> {platform1, platform2};
    }

    private String getEngageSubmitResponse(String opportunityId, Boolean isEngageVoice) {
        return JSON.serialize(new Map<String, Object> {
            'opportunityId' => opportunityId != null ? opportunityId : generateOpportunityId(),
            isEngageVoice ? 'engageVoiceAccount' : 'engageDigitalAccount' => new Map<String, Object> {
                'ngbsAccount' => new Map<String, Object> { 'id' => 'billing_id' },
                'enterpriseAccountId' => 'enterprise_id',
                'engageAccountId' => 'engage_account_id',
                isEngageVoice ? 'mainAccountId' : 'id' => isEngageVoice ? 'engage_voice_account_id' : 'engage_digital_account_id'
            }
        });
    }

    private Id generateOpportunityId() {
        return (Id) ValueProviderBuilder.provideDummyId(Opportunity.SObjectType, 15).getValue();
    }

    public static BillingWrappers.BillingAddress getBillingAddress() {
        BillingWrappers.BillingAddress address = new BillingWrappers.BillingAddress();
        address.zip = '1 Test Str';
        address.country = 'Test City';
        address.state = 'Test State';
        address.city = 'Test Country';
        address.address1 = '00000';
        address.firstName = 'First Name';
        address.lastName = 'Last Name';
        return address;
    }
}