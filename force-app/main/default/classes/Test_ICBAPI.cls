@IsTest
private class Test_ICBAPI {
    private static final String TEST_ADDRESS_1 = '1 Test Str';
    private static final String TEST_CITY = 'Test City';
    private static final String TEST_STATE = 'Test State';
    private static final String TEST_COUNTRY = 'Test Country';
    private static final String TEST_ZIP = '00000';
    private static final String TEST_FIRST_NAME = 'First Name';
    private static final String TEST_LAST_NAME = 'Last Name';

    @TestSetup
    static void setup() {
        new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.BaseEndpoint__c => 'https://fake-icb-api',
                ICB_Settings__c.ChangePath__c => '/change',
                ICB_Settings__c.ValidatePath__c => '/address/validate',
                ICB_Settings__c.CasePath__c => '/sign-up/case',
                ICB_Settings__c.SignUpPath__c => '/sign-up',
                ICB_Settings__c.DictionariesPath__c => '/dictionaries',
                ICB_Settings__c.APIVersion1Path__c => '/v1/sfdc',
                ICB_Settings__c.APIVersion2Path__c => '/v2/sfdc',
                ICB_Settings__c.ChangeCasePath__c => '/change/case'
        })
            .create();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test account'
        })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_LEGACY,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .create();
    }

    @isTest
    static void testRequestICBExceptionGetMethodBodySpecified() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        Boolean httpExceptionCaught = false;
        Test.startTest();
        try {
            ICBAPI.requestICB('test', HttpHelper.METHOD_GET, 'Test Body is not blank');
        } catch (HttpHelper.HttpHelperException httpExc) {
            httpExceptionCaught = true;
            System.assertEquals(
                ICBAPI.addICBPrefix('GET method should have no body on Http request'),
                httpExc.getMessage(),
                'Wrong exception message received for GET method with a body'
            );
        }
        Test.stopTest();

        System.assert(httpExceptionCaught, 'The HttpHelper.HttpHelperException should have been fired');
    }

    @isTest
    static void testRequestOrderToVendor() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        Opportunity opp = selectOpportunity();
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = opp.Id;

        Test.startTest();
        Response resp = ICBAPI.requestOrderToVendor(params);
        Test.stopTest();

        System.assertEquals(true, resp.isSuccess(), 'Response should be successful');
    }

    @isTest
    static void testRequestOrderToVendorFail() {
        ICBAPIMock testMock = new ICBAPIMock();
        testMock.statusCode = 400;
        testMock.code = 'NOT_AUTH';
        testMock.errorMessage = 'Error while getting order to vendor';
        testMock.errorDescription = 'No data available for order to vendor';
        Test.setMock(HttpCalloutMock.class, testMock);

        Opportunity opp = selectOpportunity();
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = opp.Id;

        Test.startTest();
        Response resp = ICBAPI.requestOrderToVendor(params);
        Test.stopTest();

        System.assertEquals(Response.STATUS_ERROR, resp.status, 'Status is not "error"');
        System.assert(!resp.messages.isEmpty(), 'An error message is missing');

        Response.ResponseMessage message = resp.messages[0];
        System.assertEquals(ICBAPI.addICBPrefix(testMock.code), message.message, 'Wrong message');

        String expectedDetails = StringHelper.safeString(testMock.errorMessage) + '\n' + StringHelper.safeString(testMock.errorDescription);
        System.assertEquals(expectedDetails, message.messageDetails, 'Wrong message details');
    }

    @isTest
    static void testValidateBillingAddress() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        BillingWrappers.BillingAddress billingAddress = new BillingWrappers.BillingAddress();
        billingAddress.address1 = TEST_ADDRESS_1;
        billingAddress.city = TEST_CITY;
        billingAddress.state = TEST_STATE;
        billingAddress.country = TEST_COUNTRY;
        billingAddress.firstName = TEST_FIRST_NAME;
        billingAddress.lastName = TEST_LAST_NAME;
        billingAddress.zip = TEST_ZIP;

        Test.startTest();
        Response resp = ICBAPI.validateBillingAddress(billingAddress);
        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'A successful callout should not have any messages');

        Map<String, Object> body = (Map<String, Object>) resp.getData('body');
        System.assertEquals('valid', (String) body.get('status'), 'Expected "valid" status');
    }

    @isTest
    static void testGetDictionaries() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        Test.startTest();
        Response resp = ICBAPI.getDictionaries();
        Test.stopTest();

        Assert.isTrue(resp.isSuccess(), 'Status is not "error"');
    }

    @isTest
    static void testGetDictionariesFail() {
        ICBAPIMock testMock = new ICBAPIMock();
        testMock.statusCode = 500;
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
        Response resp = ICBAPI.getDictionaries();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Status is not "error"');
        Assert.isFalse(resp.messages.isEmpty(), 'An error message is missing');

        Response.ResponseMessage message = resp.messages[0];
        Assert.areEqual(ICBAPI.addICBPrefix(testMock.code), message.message, 'Wrong message');

        String expectedDetails = StringHelper.safeString(testMock.errorMessage) + '\n' + StringHelper.safeString(testMock.errorDescription);
        Assert.areEqual(expectedDetails, message.messageDetails, 'Wrong message details');
    }

    @isTest
    static void testsubmitRCCCPatchRequest() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        Opportunity opp = selectOpportunity();
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        BillingWrappers.SubmitWrapper sWrapper = new BillingWrappers.SubmitWrapper();
        sWrapper.accountParams = new BillingWrappers.AccountParams();
        sWrapper.accountParams.geoRegionValue = CaseHelper.EMEA_CASE_GEOREGION;
        sWrapper.accountParams.implementationTeamValue = 'RingCentral';
        sWrapper.accountParams.nicSegmentValue = '1-50 Seats';
        sWrapper.accountParams.timeZoneValue = 'GMT';

        params.targetId = opp.Id;
        params.data = sWrapper;

        Test.startTest();
        Response resp = ICBAPI.submitRCCCPatchRequest(params);
        Test.stopTest();

        Assert.areEqual(ICBAPI.STATUS_SUBMITTED, resp.getData('status'), 'Wrong response status');
        Assert.isNotNull(resp.getData(CaseHelper.CASE_NUMBER), 'Case number is missing');

        Case cs = (Case) new CaseSelector()
            .selectCasesIcbByNumber(new List<String> { (String) resp.getData(CaseHelper.CASE_NUMBER) })
            .executeQuery()
            .get(0);

        Assert.areEqual(cs.Default_Time_Zone__c, sWrapper.accountParams.timeZoneValue, 'DefaultTimeZone must be correct');
        Assert.areEqual(cs.Geo_Region__c, sWrapper.accountParams.geoRegionValue, 'GeoRegion must be correct');
        Assert.areEqual(cs.inContact_Segment__c, sWrapper.accountParams.nicSegmentValue, 'NIC Segment must be correct');
        Assert.areEqual(cs.Implementation_Team__c, sWrapper.accountParams.implementationTeamValue, 'ImplementationTeam must be correct');
    }

    @isTest
    static void testSubmitRCCCPostRequest() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        Opportunity opp = selectOpportunity();
        Quote qt = selectQuote();

        Triggers.switchOff();
        new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Opportunity_Reference__c => opp.Id,
                Case.Provision_Date__c => System.today().addDays(1),
                Case.inContact_BU_ID__c => 10,
                Case.inContact_Cluster__c => 'test claster',
                Case.RecordTypeId=> CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.Description => 'CASE_DESCRIPTION'
            })
            .create();
        Triggers.switchOn();

        Assert.isFalse(opp.isSyncedToICB__c, 'Opportunity should not be synced to ICB');
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = opp.Id;
        params.quoteId = qt.Id;
        params.isMPUB = false;
        params.isChangeOrder = false;
        params.data = new BillingWrappers.SubmitWrapper();

        Test.startTest();
        Response resp = ICBAPI.submitRCCCPostRequest(params);
        opp = selectOpportunity();
        Test.stopTest();

        Assert.areEqual(ICBAPI.STATUS_SUBMITTED, resp.getData('status'), 'Wrong response status');
        Assert.isTrue(opp.isSyncedToICB__c, 'Opportunity should be synced to ICB');
    }

    @isTest
    static void testSkipCreateICBCaseForChangeOrder() {
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.isChangeOrder = true;
        String respBody = '{"isNicLicensesChanged":false}';

        Test.startTest();
        String caseNumber = ICBAPI.processCase(respBody, params);
        Test.stopTest();

        Assert.isNull(caseNumber, 'Case should not be created');
    }

    @isTest
    static void testGetCaseEndpointGetMethod() {
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = 'testId';
        Test.startTest();
        String endpoint = ICBAPI.getCaseEndpoint(params, HttpHelper.METHOD_GET);
        Test.stopTest();

        ICB_Settings__c settings = ICB_Settings__c.getInstance();
        String expectedEndpoint = settings.BaseEndpoint__c + settings.APIVersion1Path__c + settings.CasePath__c;
        Assert.areEqual(
            expectedEndpoint + ICBAPI.OPP_ID_PARAM + params.targetId,
            endpoint,
            'Wrong endpoint'
        );
    }

    @isTest
    static void testGetCaseEndpointPatchMethod() {
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = 'testId';
        params.isChangeOrder = true;
        params.isMPUB = true;
        Test.startTest();
        String endpoint = ICBAPI.getCaseEndpoint(params, HttpHelper.METHOD_PATCH);
        Test.stopTest();

        ICB_Settings__c settings = ICB_Settings__c.getInstance();
        String expectedEndpoint = settings.BaseEndpoint__c + settings.APIVersion1Path__c + settings.ChangeCasePath__c;
        Assert.areEqual(
            expectedEndpoint + ICBAPI.OPP_ID_PARAM + params.targetId,
            endpoint,
            'Wrong endpoint'
        );
    }

    @isTest
    static void testGetCaseEndpointPostMethod() {
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = 'testId';
        params.isMPUB = true;
        Test.startTest();
        String endpoint = ICBAPI.getCaseEndpoint(params, HttpHelper.METHOD_POST);
        Test.stopTest();

        ICB_Settings__c settings = ICB_Settings__c.getInstance();
        String expectedEndpoint = settings.BaseEndpoint__c + settings.APIVersion2Path__c + settings.CasePath__c;
        Assert.areEqual(
            expectedEndpoint + ICBAPI.OPP_ID_PARAM + params.targetId,
            endpoint,
            'Wrong endpoint'
        );
    }

    @isTest
    static void testSubmitRCCCPostRequestFailed() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.isMPUB = false;
        params.data = new BillingWrappers.SubmitWrapper();

        Test.startTest();
        try {
            Response resp = ICBAPI.submitRCCCPostRequest(params);
            Assert.fail('Exception should be thrown');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Error from ICB:'), 'Exception message is wrong');
        }
        Test.stopTest();
    }

    @isTest
    static void testProcessCaseExisting() {
        Opportunity oppty = selectOpportunity();
        BillingWrappers.RequestSubmitParams params = new BillingWrappers.RequestSubmitParams();
        params.targetId = oppty.Id;
        params.data = new BillingWrappers.SubmitWrapper();
        params.data.accountParams = new BillingWrappers.AccountParams();
        params.data.accountParams.geoRegionValue = CaseHelper.EMEA_CASE_GEOREGION;
        String respBody = '{"caseDescription":"new description"}';

        Triggers.switchOff();
        Case testCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Opportunity_Reference__c => oppty.Id,
                Case.Provision_Date__c => System.today().addDays(1),
                Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.Geo_Region__c => CaseHelper.EMEA_CASE_GEOREGION,
                Case.Description => 'CASE_DESCRIPTION'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        String caseNumber = ICBAPI.processCase(respBody, params);
        Test.stopTest();

        Case resultCase = (Case) new CaseSelector()
            .selectCasesIcbByNumber(new List<String> { caseNumber })
            .withoutSelectorFieldsIncluded()
            .selectField(Case.Description)
            .executeQuery()
            .get(0);

        Assert.areEqual(resultCase.Id, testCase.Id, 'New case should not be created');
        Assert.areEqual(resultCase.Description, 'new description', 'Description should be updated');
    }

    @IsTest
    static void testHandleICBErrors() {
        String ERROR_MESSAGE1 = 'Error Message 1';
        String ERROR_MESSAGE2 = 'Error Message 2';
        String ERROR_DESCRIPTION1 = 'Error Description 1';
        String ERROR_DESCRIPTION2 = 'Error Description 2';

        IcbHelper.ICBResponseError submitResp1 = new IcbHelper.ICBResponseError();
        submitResp1.message = ERROR_MESSAGE1;
        submitResp1.description = ERROR_DESCRIPTION1;

        IcbHelper.ICBResponseError submitResp2 = new IcbHelper.ICBResponseError();
        submitResp2.message = ERROR_MESSAGE2;
        submitResp2.description = ERROR_DESCRIPTION2;

        Response resp1 = new Response();
        Response resp2 = new Response();
        Test.startTest();
            ICBAPI.handleICBErrors(resp1, submitResp1);
            submitResp1.messages = new List<IcbHelper.ICBResponseError> { submitResp2 };
            submitResp1.message = null;

            ICBAPI.handleICBErrors(resp2, submitResp1);
        Test.stopTest();

        Assert.areEqual(ERROR_MESSAGE1 + '\n' + ERROR_DESCRIPTION1, resp1.messages[0].messageDetails, 'Wrong error message is returned');
        Assert.areEqual(ERROR_MESSAGE2 + '\n' + ERROR_DESCRIPTION2, resp2.messages[0].messageDetails, 'Wrong error message is returned');
    }

    private static Opportunity selectOpportunity() {
        return (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .selectField(Opportunity.isSyncedToICB__c)
            .executeQuery()
            .get(0);
    }

    private static Quote selectQuote() {
        return (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);
    }
}