@IsTest
private class Test_CaseCreateServiceICB {

    private static IcbHelper.ICBCaseRequest generateCaseParams() {
        IcbHelper.ICBCaseRequest params = new IcbHelper.ICBCaseRequest();
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.CloseDate => Date.today() + 2
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        params.opportunityId = opp.Id;
        params.caseType = 'create';
        IcbHelper.ICBRequestCaseBody caseBody = new IcbHelper.ICBRequestCaseBody();
        caseBody.subject = 'NBU The Original Cottage Company';
        caseBody.defaultTimeZone = 'GMT';
        caseBody.geoRegion = CaseHelper.EMEA_CASE_GEOREGION;
        caseBody.inContactSegment = '1-50 Seats';
        caseBody.customerNotification = true;
        caseBody.contactEmail = 'test@test.com';
        caseBody.implementationTeam = 'Ringcentral';
        caseBody.description = 'Description';
        params.caseBody = caseBody;

        return params;
    }

    @IsTest
    private static void testNotValidRequest() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"opportunityId":""}');
        RestContext.request = req;

        CaseCreateServiceICB.createCase();

        Test.startTest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();
        IcbHelper.IcbResponseParams resp = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        System.assertEquals(IcbHelper.STATUS_ERROR, resp.status, 'It should be validation error');
        System.assert(!resp.messages.isEmpty(), 'Response should contain validation messages');
        System.assertEquals(CaseCreateServiceICB.BAD_REQUEST_MESSAGE, resp.messages[0].message,
            'It should be message about empty request');
    }

    @IsTest
    private static void testError() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('not valid json');
        RestContext.request = req;

        CaseCreateServiceICB.createCase();

        Test.startTest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParams resp = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        System.assertEquals(IcbHelper.STATUS_ERROR, resp.status, 'It should be caught error');
        System.assert(!resp.messages.isEmpty(), 'Response should contain stack trace');
    }

    @isTest
    static void testCreateCaseNoOpportunityIsFound() {
        IcbHelper.ICBCaseRequest params = generateCaseParams();

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        delete new Opportunity(Id = params.opportunityId);

        Test.startTest();
            CaseCreateServiceICB.createCase();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();
        IcbHelper.IcbResponseParams resp = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        System.assertEquals(IcbHelper.STATUS_ERROR, resp.status, 'Status should be error');
        System.assert(!resp.messages.isEmpty(), 'Response should contain stack trace');
    }

    @isTest
    static void testCreateCaseReturnExistingCase() {
        IcbHelper.ICBCaseRequest params = generateCaseParams();
        String existingCaseSubject = params.caseBody.subject + ' Existing';
        
        Triggers.switchOff();
        Case existingIcbCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Origin => CaseHelper.CASE_ORIGIN_WEB,
                Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.Subject => existingCaseSubject,
                Case.Opportunity_Reference__c => params.opportunityId
            })
            .create()
            .getRecord();

        update new Opportunity(Id = params.opportunityId, isSyncedToICB__c = true);
        Triggers.switchOn();

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();
            CaseCreateServiceICB.createCase();

            List<Case> icbCases = new CaseSelector()
                .selectCasesByRecordTypeAndOpportunityIds(CaseHelper.RT_ID_INCONTACT_ORDER, new Set<Id>{params.opportunityId})
                .executeQuery();
            System.assert(icbCases.size() == 1, 'The createCase method should not create a new icbCase');
            System.assertEquals(
                existingCaseSubject,
                icbCases.get(0).Subject,
                'The createCase method should not change existing case'
            );

            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();
        IcbHelper.IcbResponseParamsData resp = (IcbHelper.IcbResponseParamsData)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParamsData.class);
        System.assertEquals(IcbHelper.STATUS_SUCCESS, resp.status, 'Response should be successful');
        System.assertEquals(
            existingIcbCase.Id,
            resp.data.caseBody.caseId,
            'Response should return existing ICB case'
        );
    }

    @isTest
    static void testCreateCaseNoCaseIsFound() {
        IcbHelper.ICBCaseRequest params = generateCaseParams();
        String existingCaseSubject = params.caseBody.subject + ' Existing';

        Triggers.switchOff();
        Case existingIcbCase = (Case) new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Origin => CaseHelper.CASE_ORIGIN_WEB,
                Case.RecordTypeId => CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.Subject => existingCaseSubject
            })
            .create()
            .getRecord();

        update new Opportunity(Id = params.opportunityId, isSyncedToICB__c = true);
        Triggers.switchOn();

        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));

        Test.startTest();
            CaseCreateServiceICB.createCase();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParamsData resp = (IcbHelper.IcbResponseParamsData) 
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParamsData.class);
        Assert.areEqual(IcbHelper.STATUS_ERROR, resp.status, 'Response should be error');
        Assert.isTrue(resp.messages.get(0).messageDetails.contains(CaseCreateServiceICB.BAD_REQUEST_CASE_NOT_FOUND), 'Response should contain correct message');
    }
}