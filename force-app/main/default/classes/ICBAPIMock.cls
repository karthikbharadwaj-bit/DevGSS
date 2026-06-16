@IsTest
public class ICBAPIMock implements HttpCalloutMock {
    private static final String TEST_ADDRESS_1 = '1 Test Str';
    private static final String TEST_CITY = 'Test City';
    private static final String TEST_STATE = 'Test State';
    private static final String TEST_COUNTRY = 'Test Country';
    private static final String TEST_ZIP = '00000';
    private static final String TEST_FIRST_NAME = 'First Name';
    private static final String TEST_LAST_NAME = 'Last Name';

    private class ICBAPIMockException extends Exception {}

    private final ICB_Settings__c ICB_SETTINGS = ICB_Settings__c.getInstance();
    private final String BASE_ENDPOINT_V1 = ICBAPI.BASE_ENDPOINT_V1;
    private final String BASE_ENDPOINT_V2 = ICBAPI.BASE_ENDPOINT_V2;
    private final String CASE_PATH_OPPORTUNITY_ENDPOINT = BASE_ENDPOINT_V1 + ICB_SETTINGS.CasePath__c + '?opportunityId=';
    private String body;

    public String status = Response.STATUS_SUCCESS;
    public Integer statusCode = 200;
    public String errorMessage = 'Internal Server Error';
    public String errorDescription = 'Internal Server Error';
    public String validationStatus = 'valid';
    public String code = String.valueOf(statusCode);

    public HTTPResponse respond(HTTPRequest req) {
        if (isError()) {
            return respondError();
        }

        String endpoint = req.getEndpoint();
        String method = req.getMethod();

        if (endpoint == BASE_ENDPOINT_V1 + ICB_SETTINGS.DictionariesPath__c
            && method == HttpHelper.METHOD_GET) {
            this.body = getDictionaries();
        } else if (endpoint.contains(CASE_PATH_OPPORTUNITY_ENDPOINT) && method == HttpHelper.METHOD_GET) {
            // requestOrderToVendor
            this.body = getOrderToVendorResponseBody();
        } else if (endpoint == BASE_ENDPOINT_V1 + ICB_SETTINGS.ChangePath__c
            && method == HttpHelper.METHOD_POST) {
            // requestChangeOrder
            this.body = getRequestBody(req);
        } else if (endpoint == BASE_ENDPOINT_V1 + ICB_SETTINGS.ValidatePath__c
            && method == HttpHelper.METHOD_POST) {
            this.body = getBillingAddressValidationResponseBody();
        } else if (endpoint.contains(CASE_PATH_OPPORTUNITY_ENDPOINT) && method == HttpHelper.METHOD_POST) {
            this.body = getSubmitCCDataPostResponse(endpoint.removeStart(CASE_PATH_OPPORTUNITY_ENDPOINT));
        } else if (endpoint.contains(CASE_PATH_OPPORTUNITY_ENDPOINT) && method == HttpHelper.METHOD_PATCH) {
            this.body = getSubmitCCDataPatchResponse(endpoint.removeStart(CASE_PATH_OPPORTUNITY_ENDPOINT));
        } else if (endpoint == BASE_ENDPOINT_V1 + ICBAPI.ICB_SETTINGS.SignUpPath__c) {
            this.body = getSignUpResponseMPL();
        } else if (endpoint == BASE_ENDPOINT_V2 + ICBAPI.ICB_SETTINGS.SignUpPath__c) {
            this.body = getSignUpResponseMPUB();
        } else {
            throw new ICBAPIMockException('Error: there is no handler for ' +
                method + ' ' + endpoint + ' ' +
                'endpoint in ICBAPIMock');
        }

        return createResponse();
    }

    private HttpResponse respondError() {
        this.status = Response.STATUS_ERROR;
        IcbHelper.ICBResponseError error = new IcbHelper.ICBResponseError();
        error.code = this.code;
        error.message = this.errorMessage;
        error.description = this.errorDescription;
        this.body = JSON.serialize(error);

        return createResponse();
    }

    private HttpResponse createResponse() {
        HTTPResponse res = new HTTPResponse();
        res.setStatus(this.status);
        res.setStatusCode(this.statusCode);
        res.setBody(this.body);

        return res;
    }

    private Boolean isError() {
        return this.statusCode < 200 || this.statusCode >= 300;
    }

    private String getRequestBody(HTTPRequest req) {
        String body = '{"messages":[{"message":"test"}],"fullRedirectUrl": "fullRedirectUrl"}';
        return body;
    }

    private String getBillingAddressValidationResponseBody() {
        Map<String, Object> responseBody = new Map<String, Object>();
        responseBody.put('status', this.validationStatus);

        if (this.validationStatus == 'ambiguous') {
            responseBody.put('suggestedAddresses', new List<BillingWrappers.BillingAddress>{getBillingAddress()});
        }

        return JSON.serialize(responseBody);
    }

    private String getDictionaries() {
        BillingWrappers.Dictionaries dictionaries = new BillingWrappers.Dictionaries();

        BillingWrappers.Country country = new BillingWrappers.Country();
        country.id = 1;
        country.Name = TEST_COUNTRY;
        country.code = 'TST';
        country.codeAlpha2 = 'TS';
        country.stateIsRequired = false;
        country.states = new List<BillingWrappers.State>();
        country.abbreviation = 'TST';

        dictionaries.countries = new List<BillingWrappers.Country>{country};
        dictionaries.timeZones = createMockParameters('1', 'Test Timezone');
        dictionaries.nicSegments = createMockParameters('1', 'Test Nic Segment');
        dictionaries.geoRegions = createMockParameters('1', 'Test Geo Region');
        dictionaries.implementationTeams = createMockParameters('1', 'Test Implementation Teams');

        return JSON.serialize(dictionaries);
    }

    private List<BillingWrappers.CaseProvisioningParameter> createMockParameters(String Id, String name) {
        BillingWrappers.CaseProvisioningParameter parameter = new BillingWrappers.CaseProvisioningParameter();
        parameter.id = id;
        parameter.name = name;
        return new List<BillingWrappers.CaseProvisioningParameter>{parameter};
    }

    private String getOrderToVendorResponseBody() {
        return '{"messages":[{"message":"test"}],"fullRedirectUrl": "fullRedirectUrl"}';
    }

    private String getSubmitCCDataPatchResponse(String opportunityId) {
        Map<String, Object> body = new Map<String, Object>();

        body.put('status', 'SIGNUP_READY_FOR_SUBMIT');
        body.put('billingAddress', getBillingAddress());
        body.put('sfdcOppId', opportunityId);
        body.put('ngbsBillingAccountId', '2927902002');
        body.put('enterpriseAccountId', '90886695');
        body.put('rcAccountId', '75289011');
        body.put('updateDate', '1661433849814');
        body.put('nicWaitingExpirationSeconds', 0);
        body.put('skipAddressValidation', false);
        body.put('caseDescription', 'ADD PRODUCTS:\n\r0.00[3880-1539-000] - CXone Business Intelligence Viewer License (per Concurrent User) $2.80\n\r0.00[309-565-000] - Long Term Storage (per GB) $0.03\n\r0.00[308-8-540] - CXone Additional Concurrent Universal Port (Beyond 3 ports included) $22.50\n\r0.00[309-566-000] - Long Term Storage Retrieval (per GB) $0.41\n\r2.00[12658-1728-000] - CXone Core Suite (per Concurrent User) $94.00\n\r0.00[309-1499-000] - Active Storage (Per GB) up to 1TB $0.30\n\r1.00[1561-55-000] - CXsuccess Premier Package $2550.00\n\r\n\rSERVICES:\n\r\n\rNOTES:\n\r\n\r\n\r\n\rTELECOM CHARGES:\n\r12619-328-000-XX Domestic Toll-Free Number - Setup $0.50\n\r1051-371-000-XX Domestic Toll-Free Number - Account Activation $0.00\n\r1270-136-000 Domestic Toll-Free Number - Monthly Recurring Charge $0.40\n\rDOM_TF_FLAT_48INTRA_MIN Domestic Toll-Free Number - Flat Per-minute (Intrastate for 48 States) $0.008\n\rDOM_TF_FLAT_INTER_MIN Domestic Toll-Free Number - Flat Per-minute (Interstate) $0.008\n\r12619-333-000 Domestic Local Number - Setup $0.00\n\r1051-372-000-XX Domestic Local Number - Account Activation $0.00\n\r1012-150-000 Domestic Local Number - Monthly Recurring Charge $0.40\n\rDOM_LN_MIN Domestic Local Number - Per-minute Charge $0.008\n\rDOM_TERM_FLAT_INTER_MIN Domestic Termination - Flat Per-minute (Interstate) $0.008\n\rDOM_TERM_FLAT_48INTRA_MIN Domestic Termination - Flat Standard Per-minute (Intrastate for 48 States) $0.008\n\r');
        body.put('icbAccountId', '166143384942989');

        return JSON.serialize(body);
    }

    private String getSignUpResponseMPL() {
        return '{"messages":[{"message":"MPL endpoint is used"}],"fullRedirectUrl": "fullRedirectUrl"}';
    }

    private String getSignUpResponseMPUB() {
        return '{"messages":[{"message":"MPUB endpoint is used"}],"fullRedirectUrl": "fullRedirectUrl"}';
    }

    private String getSubmitCCDataPostResponse(String opportunityId) {
        Map<String, Object> body = new Map<String, Object>();

        body.put('status', 'SIGNUP_BEGIN');
        body.put('billingAddress', getBillingAddress());
        body.put('sfdcOppId', opportunityId);
        body.put('nicBUID', 'string');
        body.put('ngbsBillingAccountId', '2927902002');
        body.put('sfdcCaseNumber', 'string');
        body.put('enterpriseAccountId', '90886695');
        body.put('rcAccountId', '75289011');
        body.put('updateDate', '1661433849814');
        body.put('nicWaitingExpirationSeconds', 0);
        body.put('skipAddressValidation', false);
        body.put('caseDescription', 'ADD PRODUCTS:\n\r0.00[3880-1539-000] - CXone Business Intelligence Viewer License (per Concurrent User) $2.80\n\r0.00[309-565-000] - Long Term Storage (per GB) $0.03\n\r0.00[308-8-540] - CXone Additional Concurrent Universal Port (Beyond 3 ports included) $22.50\n\r0.00[309-566-000] - Long Term Storage Retrieval (per GB) $0.41\n\r2.00[12658-1728-000] - CXone Core Suite (per Concurrent User) $94.00\n\r0.00[309-1499-000] - Active Storage (Per GB) up to 1TB $0.30\n\r1.00[1561-55-000] - CXsuccess Premier Package $2550.00\n\r\n\rSERVICES:\n\r\n\rNOTES:\n\r\n\r\n\r\n\rTELECOM CHARGES:\n\r12619-328-000-XX Domestic Toll-Free Number - Setup $0.50\n\r1051-371-000-XX Domestic Toll-Free Number - Account Activation $0.00\n\r1270-136-000 Domestic Toll-Free Number - Monthly Recurring Charge $0.40\n\rDOM_TF_FLAT_48INTRA_MIN Domestic Toll-Free Number - Flat Per-minute (Intrastate for 48 States) $0.008\n\rDOM_TF_FLAT_INTER_MIN Domestic Toll-Free Number - Flat Per-minute (Interstate) $0.008\n\r12619-333-000 Domestic Local Number - Setup $0.00\n\r1051-372-000-XX Domestic Local Number - Account Activation $0.00\n\r1012-150-000 Domestic Local Number - Monthly Recurring Charge $0.40\n\rDOM_LN_MIN Domestic Local Number - Per-minute Charge $0.008\n\rDOM_TERM_FLAT_INTER_MIN Domestic Termination - Flat Per-minute (Interstate) $0.008\n\rDOM_TERM_FLAT_48INTRA_MIN Domestic Termination - Flat Standard Per-minute (Intrastate for 48 States) $0.008\n\r');
        body.put('icbAccountId', '166143384942989');

        return JSON.serialize(body);
    }

    private BillingWrappers.BillingAddress getBillingAddress() {
        BillingWrappers.BillingAddress address = new BillingWrappers.BillingAddress();
        address.zip = TEST_ZIP;
        address.country = TEST_COUNTRY;
        address.state = TEST_STATE;
        address.city = TEST_CITY;
        address.address1 = TEST_ADDRESS_1;
        address.firstName = TEST_FIRST_NAME;
        address.lastName = TEST_LAST_NAME;
        return address;
    }
}