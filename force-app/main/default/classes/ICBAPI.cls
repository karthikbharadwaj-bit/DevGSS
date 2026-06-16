public with sharing class ICBAPI {
    class ICBAPIException extends Exception {}

    private static final String ICB_PREFIX = 'Error from ICB: ';
    private static final String UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE = 'Not expected: parameter empty. Parameter name: ';
    private static final String ADDRESS_VALIDATION_ERROR = 'An error occurred while address validating.';
    private static final String ORDER_TO_VENDOR_GETTING_ERROR = 'An error occurred while getting order to vendor catalog.';
    private static final String DICTIONARIES_GETTING_ERROR = 'An error occurred while getting dictionaries.';
    private static final String ICB_CASE_CREATION_ERROR = 'An error occurred while ICB case creation. Try again.';
    @TestVisible
    private static final String OPP_ID_PARAM = '?opportunityId=';
    public static final String SYNC_ICB_FAILED = 'Failed to sync with ICB';
    public static final String STATUS_ERROR = 'error';
    public static final String STATUS_SUBMITTED = 'submitted';
    public static final ICB_Settings__c ICB_SETTINGS = ICB_Settings__c.getInstance();
    public static final String BASE_ENDPOINT_V1 = ICB_SETTINGS.BaseEndpoint__c + ICB_SETTINGS.APIVersion1Path__c;
    public static final String BASE_ENDPOINT_V2 = ICB_SETTINGS.BaseEndpoint__c + ICB_SETTINGS.APIVersion2Path__c;

    /*
    * @description: makes request to ICB with given method, body, Content Type and headers
     */
    public static HttpResponse requestICB(String endpoint, String method) {
        return requestICB(endpoint, method, null);
    }

    public static HttpResponse requestICB(String endpoint, String method, String body) {
        String header = HttpHelper.prepareJWTAuthHeader(HttpHelper.CERT_DEV_NAME_ICB);
        return requestICB(endpoint, method, body, HttpHelper.CONTENT_TYPE_APPLICATION_JSON, header);
    }

    public static HttpResponse requestICB(String endpoint, String method, String body, String contentTypeValue, String headers) {
        StringHelper.validateStrict(endpoint, UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + ' endpoint');
        StringHelper.validateStrict(method, UNEXPECTED_PARAMETER_EMPTY_EXCEPTION_MESSAGE + ' method');
        if (method == HttpHelper.METHOD_GET && String.isNotBlank(body)) {
            throw new HttpHelper.HttpHelperException(addICBPrefix('GET method should have no body on Http request'));
        }

        String authorizationHeader = headers;

        HttpRequest request = HttpHelper.prepareBasicAuthRequest(endpoint, method, authorizationHeader, body, contentTypeValue);
        request.setHeader('X-TokenId', HttpHelper.formXTokenId());
        request.setTimeout(HttpHelper.MAX_TIMEOUT_MS);
        System.debug('ICB request endpoint: ' + endpoint + '\n' + 'ICB request body: ' + body);
        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch(Exception e) {
            String errorMessage = e.getMessage().contains('Authorization token is invalid')
                ? 'Authorization token is invalid - make sure that credentials are correct'
                : e.getMessage();

            throwICBException(errorMessage);
        }

        return response;
    }

    public static Response requestOrderToVendor(BillingWrappers.RequestSubmitParams params) {
        String endpoint = getCaseEndpoint(params, HttpHelper.METHOD_GET);
        return handleICBRequest(endpoint, ORDER_TO_VENDOR_GETTING_ERROR, HttpHelper.METHOD_GET, null);
    }

    public static Response validateBillingAddress(BillingWrappers.BillingAddress billingAddress) {
        String endpoint = getBaseV1Endpoint(ICB_SETTINGS.ValidatePath__c);
        return handleICBRequest(endpoint, ADDRESS_VALIDATION_ERROR, HttpHelper.METHOD_POST, JSON.serialize(billingAddress));
    }

    public static Response getDictionaries() {
        String endpoint = getBaseV1Endpoint(ICB_SETTINGS.DictionariesPath__c);
        return handleICBRequest(endpoint, DICTIONARIES_GETTING_ERROR, HttpHelper.METHOD_GET, null);
    }

    private static Response handleICBRequest(String endpoint, String errorMessage, String method, String body) {
        Response resp = new Response();
        try {
            HttpResponse httpResp = requestICB(endpoint, method, body);
            if (!HttpHelper.isSuccess(httpResp)) {
                return handleICBResponse(httpResp);
            }

            resp.setData('body', JSON.deserializeUntyped(httpResp.getBody()));
        } catch (Exception ex) {
            throwICBException(errorMessage, ex);
        }
        return resp;
    }

    public static Response submitRCCCPatchRequest(BillingWrappers.RequestSubmitParams params) {
        String endpoint = getCaseEndpoint(params, HttpHelper.METHOD_PATCH);
        HttpResponse httpResp = requestICB(endpoint, HttpHelper.METHOD_PATCH, JSON.serialize(params.data));

        return HttpHelper.isSuccess(httpResp)
            ? handleRCCCPatchResponse(httpResp, params)
            : handleICBResponse(httpResp);
    }

    private static Response handleRCCCPatchResponse(HttpResponse httpResp, BillingWrappers.RequestSubmitParams params) {
        Response resp = new Response();
        try {
            String caseNumber = processCase(httpResp.getBody(), params);
            resp.setData(CaseHelper.CASE_NUMBER, caseNumber);
        } catch (Exception ex) {
            throwICBException(ICB_CASE_CREATION_ERROR, ex);
        }

        return handleICBResponse(httpResp, resp);
    }

    @TestVisible
    private static String processCase(String responseBody, BillingWrappers.RequestSubmitParams params) {
        BillingWrappers.SubmitWrapper submitResp = parseSubmitResponseBody(responseBody);
        if (skipCaseCreationForChangeOrder(params, submitResp)) {
            return null;
        }
        Opportunity opp = IcbHelper.selectOpportunityForInContactCaseSharing(params.targetId);
        Case icbCase = IcbHelper.selectICBCase(opp);

        return icbCase == null
            ? createICBCase(opp, submitResp.caseDescription, params)
            : updateICBCase(icbCase, params.data.accountParams, submitResp.caseDescription);
    }

    private static String updateICBCase(
        Case icbCase,
        BillingWrappers.AccountParams accParams,
        String description
    ) {
        if (isUpdateCase(icbCase, accParams, description)) {
            update new Case(
                Id = icbCase.Id,
                Default_Time_Zone__c = accParams.timeZoneValue,
                Geo_Region__c = accParams.geoRegionValue,
                Contact_Center_Number__c = accParams.contactCenterNumber,
                Implementation_Team__c = accParams.implementationTeamValue,
                inContact_Segment__c = accParams.nicSegmentValue,
                Description = description
            );
        }
        return icbCase.CaseNumber;
    }

    private static Boolean isUpdateCase(
        Case icbCase,
        BillingWrappers.AccountParams accParams,
        String description
    ) {
        return icbCase.Default_Time_Zone__c != accParams.timeZoneValue
            || icbCase.Geo_Region__c != accParams.geoRegionValue
            || icbCase.Contact_Center_Number__c != accParams.contactCenterNumber
            || icbCase.Implementation_Team__c != accParams.implementationTeamValue
            || icbCase.inContact_Segment__c != accParams.nicSegmentValue
            || icbCase.Description != description;
    }

    @TestVisible
    private static String createICBCase(Opportunity opp, String caseDescription, BillingWrappers.RequestSubmitParams params) {
        Id icbCaseId = CaseHelper.createICBCase(opp, params.data.accountParams, caseDescription);

        Case icbCase = (Case) new ListOptional(new CaseSelector()
            .selectCasesByIds(new Set<Id> { icbCaseId })
            .withoutSelectorFieldsIncluded()
            .selectField(Case.CaseNumber)
            .executeQuery()
        ).getFirst();

        return icbCase?.CaseNumber;
    }

    private static Boolean skipCaseCreationForChangeOrder(BillingWrappers.RequestSubmitParams params, BillingWrappers.SubmitWrapper submitResp) {
        return params.isChangeOrder == true && submitResp.isNicLicensesChanged != true;
    }

    public static Response submitRCCCPostRequest(BillingWrappers.RequestSubmitParams params) {
        String endpoint = getCaseEndpoint(params, HttpHelper.METHOD_POST);
        HttpResponse httpResp = requestICB(endpoint, HttpHelper.METHOD_POST, '{"' + CaseHelper.CASE_NUMBER + '":"' + params.caseNumber + '"}');   

        return HttpHelper.isSuccess(httpResp)
            ? handleRCCCPostResponse(httpResp, params)
            : handleICBResponse(httpResp);
    }

    private static Response handleRCCCPostResponse(HttpResponse httpResp, BillingWrappers.RequestSubmitParams params) {
        try {
            BillingWrappers.SubmitWrapper submitResp = parseSubmitResponseBody(httpResp.getBody());
            Opportunity opp = IcbHelper.selectOpportunityForInContactCaseSharing(params.targetId);
            NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(params.isMPUB, params.quoteId, null);
            Case icbCase = IcbHelper.selectICBCase(opp);
            syncable.setICBSynced();
            if (icbCase != null && (!params.isChangeOrder || submitResp.isNicLicensesChanged)) {
                shareCaseWithInContact(icbCase, opp);
            } else {
                syncable.setICBProvisioning();
                startAutoSync(params, submitResp, icbCase, opp);
            }
            syncable.updateSObject();
        } catch (Exception e) {
            throwICBException(e.getMessage(), e);
        }
        return handleICBResponse(httpResp);
    }

    private static void shareCaseWithInContact(Case icbCase, Opportunity opp) {
        PartnerNetworkConnectionHelper.shareSObject(
            InContactConnectionId__c.getInstance().Id__c,
            icbCase.Id,
            'CaseComment,Attachment',
            opp.Id
        );
    }

    private static void startAutoSync(
        BillingWrappers.RequestSubmitParams params, 
        BillingWrappers.SubmitWrapper submitResp,
        Case icbCase,
        Opportunity opp
    ) {
        if (!skipCaseCreationForChangeOrder(params, submitResp)) {
            return;
        }

        try {
            IcbHelper.startAutoSync(params.quoteId);
        } catch (Exception ex) {
            System.enqueueJob(new ICBNotificationQueueable(opp, icbCase, ex));
        }
    }

    public static Response handleICBResponse(HttpResponse httpResp) {
        return handleICBResponse(httpResp, new Response());
    }

    public static Response handleICBResponse(HttpResponse httpResp, Response resp) {
        IcbHelper.ICBResponseError submitResp = (IcbHelper.ICBResponseError) JSON.deserialize(
            httpResp.getBody(), IcbHelper.ICBResponseError.class
        );

        System.debug(httpResp.getBody());
        System.debug(submitResp);

        if (HttpHelper.isSuccess(httpResp)) {
            resp.setData('status', STATUS_SUBMITTED);
        } else {
            handleICBErrors(resp, submitResp);
        }

        return resp;
    }

    @TestVisible
    private static void handleICBErrors(Response resp, IcbHelper.ICBResponseError submitResp) {
        if (String.isNotBlank(submitResp.message)) {
            handleICBError(resp, submitResp);
        } else if (submitResp.messages?.isEmpty() == false) {
            for (IcbHelper.ICBResponseError sr : submitResp.messages) {
                handleICBErrors(resp, sr);
            }
        }
    }

    private static void handleICBError(Response resp, IcbHelper.ICBResponseError submitResp) {
        resp.error(
            addICBPrefix(submitResp.code),
            StringHelper.safeString(submitResp.message) + '\n' + StringHelper.safeString(submitResp.description)
        );
    }

    public static Response handleResponse(HttpResponse httpResp) {
        Response resp = new Response();
        IcbHelper.ICBChangeOrderResponse icbResp = parseChangeOrderResponseBody(httpResp.getBody());

        System.debug(httpResp.getBody());
        System.debug(icbResp);

        addICBMessages(resp, icbResp?.messages);

        if (icbResp?.status == STATUS_ERROR) {
            resp.error();
        }

        return resp;
    }

    @TestVisible
    private static String addICBPrefix(String message) {
        return ICB_PREFIX + message;
    }

    private static void throwICBException(String errorMessage) {
        throw new ICBAPIException(addICBPrefix(errorMessage));
    }

    private static void throwICBException(String errorMessage, Exception ex) {
        throwICBException(String.format(errorMessage + ' ({0})', new List<String> { ex.getStackTraceString() }));
    }

    @TestVisible
    private static String getCaseEndpoint(BillingWrappers.RequestSubmitParams params, String method) {
        String urlParam = OPP_ID_PARAM + params.targetId;
        Boolean isChangeOrder = params.isChangeOrder == true;
        String path = (isChangeOrder ? ICB_SETTINGS.ChangeCasePath__c : ICB_SETTINGS.CasePath__c) + urlParam;
        
        if (HttpHelper.METHOD_GET.equals(method) || HttpHelper.METHOD_PATCH.equals(method) && isChangeOrder) {
            return getBaseV1Endpoint(path);
        }
        
        return BooleanHelper.toBoolean(params.isMPUB) ? getBaseV2Endpoint(path) : getBaseV1Endpoint(path);
    }

    private static String getBaseV1Endpoint(String path) {
        return BASE_ENDPOINT_V1 + path;
    }

    private static String getBaseV2Endpoint(String path) {
        return BASE_ENDPOINT_V2 + path;
    }

    private static void addICBMessages(Response resp, List<IcbHelper.ICBResponseMessage> messages) {
        for (IcbHelper.ICBResponseMessage m : new List<IcbHelper.ICBResponseMessage>(messages)) {
            resp.addMessage(
                SYNC_ICB_FAILED,
                StringHelper.safeString(m.message) + '\n' + StringHelper.safeString(m.messageDetails),
                m.severity
            );
        }
    }

    private static BillingWrappers.SubmitWrapper parseSubmitResponseBody(String body) {
        return (BillingWrappers.SubmitWrapper) JSON.deserialize(body, BillingWrappers.SubmitWrapper.class);
    }

    private static IcbHelper.ICBChangeOrderResponse parseChangeOrderResponseBody(String body) {
        return (IcbHelper.ICBChangeOrderResponse) JSON.deserialize(body, IcbHelper.ICBChangeOrderResponse.class);
    }
}