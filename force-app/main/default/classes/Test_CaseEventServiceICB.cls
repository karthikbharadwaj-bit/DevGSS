@IsTest
private class Test_CaseEventServiceICB {
    private static final Integer CASE_BU_ID = 123456;
    private static final String TEST_ACCOUNT_NAME = 'testAcc';
    private static final String TEST_OPP_NAME = 'testOpp';
    private static final String TEST_OPP_NAME_2 = 'testOpp2';
    private static final String TEST_CASE_SUBJECT = 'Test Case';
    private static final Date TODAY = Date.today();

    private static Blob createRequestBody(String eventType) {
        return createRequestBody(eventType, selectTestOpportunity().Id);
    }

    private static Blob createRequestBody(String eventType, Id oppId) {
        String caseNumber = selectTestCase().CaseNumber;
        return Blob.valueOf('{\n'
            + '  "type": "' + eventType + '",\n'
            + '  "message": "test message",\n' +
            + '  "messageDetails": "test details",\n'
            + '  "oppId": "' + oppId + '",\n'
            + '  "caseNumber": "' + caseNumber + '"\n'
            + '}'
        );
    }

    private static Case selectTestCase() {
        return (Case) new ListOptional(
            new CaseSelector()
                .newQueryFactory()
                .withoutSelectorFieldsIncluded()
                .selectField(Case.CaseNumber)
                .setCondition('inContact_BU_ID__c = :bind0')
                .setQueryBindings(CASE_BU_ID)
                .executeQuery()
        ).getFirst();
    }

    private static Opportunity selectTestOpportunity() {
        return (Opportunity) new ListOptional(
            new OpportunitySelector()
                .selectOpportunityByName(TEST_OPP_NAME)
                .withoutSelectorFieldsIncluded()
                .selectFields(new Set<SObjectField> {
                    Opportunity.Id,
                    Opportunity.Name,
                    Opportunity.AccountId,
                    Opportunity.isICBProvisioningComplete__c,
                    Opportunity.RCCCSyncStatus__c,
                    Opportunity.isSyncedToICB__c
                })
                .selectField('Account.inContact_account_ID__c')
                .executeQuery()
        ).getFirst();
    }

    private static Account selectTestAccount() {
        return (Account) new ListOptional(
            new AccountSelector()
                .selectAccountByName(new List<Object> {TEST_ACCOUNT_NAME})
                .withoutSelectorFieldsIncluded()
                .selectFields(new Set<SObjectField> {
                    Account.Id,
                    Account.Name,
                    Account.inContact_account_ID__c
                })
                .executeQuery()
        ).getFirst();
    }

    static void assertHandleChangeNGBSError(String responseBody, Opportunity opp) {
        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_ERROR, responseParams.status, 'Wrong status is returned');
        Assert.areEqual(1, responseParams.messages.size(), '1 error message should be returned');
        Assert.areEqual(IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED, responseParams.messages[0].message, 'Wrong error message is returned');
        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'Post to chatter should be made');
        Assert.areEqual(opp.OwnerId, ((ConnectApi.MentionSegmentInput) ChatterHelper.lastFeedItemInput.body.messageSegments[0]).id, 'Id should match the provided userId');    

        Case problemCase = (Case) new ListOptional(new CaseSelector()
            .newQueryFactory()
            .withoutSelectorFieldsIncluded()
            .selectField(Case.OwnerId)
            .setCondition('Opportunity_Reference__c = :bind0 AND RecordTypeId = :bind1')
            .setQueryBindings(new List<Object> { opp.Id, CaseHelper.RT_ID_INTERNAL_BUSINESS_SERVICES })
            .executeQuery()
        ).getFirst();

        Assert.isNotNull(problemCase, 'Problem Case was not created');
        Assert.areEqual(DealDeskCaseGenerator.BIZ_SERV_INNOVATION_QUEUE.QueueId, problemCase.OwnerId, 'Case Owner should be sustaining team');
    }

    @TestSetup
    static void setup() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Name, TEST_ACCOUNT_NAME)
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => TEST_OPP_NAME,
                Opportunity.AccountId => testAcc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.isSyncedToICB__c => false,
                Opportunity.CloseDate => TODAY.addDays(5)
            })
            .create()
            .getRecord();

        new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => TEST_CASE_SUBJECT,
                Case.Opportunity_Reference__c => testOpp.Id,
                Case.Provision_Date__c => TODAY,
                Case.inContact_BU_ID__c => CASE_BU_ID
            })
            .create();
        Triggers.switchOn();
    }

    @IsTest
    static void testHandleEvent() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody('CHANGE_ICB_SUCCESS');
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_SUCCESS, responseParams.status, 'An error occurred while feed creation');
        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'Post to chatter should be made');
    }

    @IsTest
    static void testHandleEventBadRequest() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('Some Bad Request');
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_ERROR, responseParams.status, 'Bad request was not handled properly');
    }

    @IsTest
    static void testHandleEventMissingParams() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"type": "' + IcbHelper.ICBEventType.CHANGE_NIC_OK + '"}');
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();


        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_ERROR, responseParams.status, 'Missing params were not handled properly');
        Assert.isTrue(responseParams.messages.size() > 0, 'Missing params message should be added');
    }

    @IsTest
    static void testHandleEventMissingParamsNoMessage() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{\n' +
            '  "type": "CHANGE_NIC_WAITING_TOO_LONG",\n' +
            '  "oppId": "' + selectTestOpportunity().Id + '"' +
            '}'
        );
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();


        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_ERROR, responseParams.status, 'Missing params were not handled properly');
        Assert.isTrue(responseParams.messages.size() > 0, 'Missing params message should be added');
    }

    @IsTest
    static void testHandleEventMissingParamsNoOpp() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(IcbHelper.ICBEventType.CHANGE_NIC_SKIP.name());
        RestContext.request = req;

        Triggers.switchOff();
        delete selectTestOpportunity();
        Triggers.switchOn();

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();


        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_ERROR, responseParams.status, 'Missing oppty were not handled properly');
        Assert.isTrue(responseParams.messages.size() > 0, 'Missing params message should be added');
    }

    @IsTest
    static void testHandleChangeNicError() {
        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(IcbHelper.ICBEventType.CHANGE_NIC_ERROR.name());
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_SUCCESS, responseParams.status, 'Wrong status is returned');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testHandleChangeNGBSErrorMPUB() {
        Triggers.switchOff();
        Opportunity testOpp2 = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => TEST_OPP_NAME_2,
                Opportunity.AccountId => selectTestAccount().Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.isSyncedToICB__c => true,
                Opportunity.isICBProvisioningComplete__c => true,
                Opportunity.OwnerId => UserInfo.getUserId(),
                Opportunity.CloseDate => TODAY.addDays(5)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.OpportunityId => testOpp2.Id,
                Quote.CurrencyIsoCode => RingCentralHelper.USD,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.ServiceName__c => QuoteHelper.NGBS_RCCC_PRODUCT,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => testQuote.Id,
                ServiceInfo__c.ICBSyncStepStatus__c => true,
                ServiceInfo__c.ICBProvisioningStepStatus__c => true
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(IcbHelper.ICBEventType.CHANGE_SFDC_NGBS_ERROR.name(), testOpp2.Id);
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        assertHandleChangeNGBSError(responseBody, testOpp2);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testHandleChangeNGBSErrorMPL() {
        Opportunity mOpp = selectTestOpportunity();
        Triggers.switchOff();
        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Master_Account__c => mOpp.AccountId,
                Account.isMultiproductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity techOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.MasterOpportunity__c => mOpp.Id,
                Opportunity.isMultiproductTechnicalOpportunity__c => true,
                Opportunity.CloseDate => Date.today(),
                Opportunity.isSyncedToICB__c => true,
                Opportunity.isICBProvisioningComplete__c => true,
                Opportunity.AccountId => techAcc.Id
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(IcbHelper.ICBEventType.CHANGE_SFDC_NGBS_ERROR.name(), techOpp.Id);
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        assertHandleChangeNGBSError(responseBody, mOpp);
    }

    @isTest
    static void testCreateOppChatterPostForOrderManagementOwner() {
        Triggers.switchOff();
        User orderManagementOwnerUser = TestDataFactory.createUser();
        Triggers.switchOn();

        Opportunity opp = selectTestOpportunity();
        opp.Order_Management_Owner__c = orderManagementOwnerUser.Id;
        update opp;

        Test.startTest();
            CaseEventServiceICB.createOppChatterPostForOrderManagementOwner(opp, 'Test Exception: ', 'Test Exception');
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'Post to chatter should be made');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0].toString().contains(orderManagementOwnerUser.Id), 'Message should mention Order Management Owner user');
    }

    @isTest
    static void testCreateOppChatterPostForOrderManagementOwnerWithOpportunityOwnerId() {
        Opportunity opp = selectTestOpportunity();

        Test.startTest();
            CaseEventServiceICB.createOppChatterPostForOrderManagementOwner(opp, 'Test Exception: ', 'Test Exception');
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'Post to chatter should be made');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0].toString().contains(opp.OwnerId), 'Message should mention Order Management Owner user');
    }

    @IsTest
    static void testHandleErrorEvent() {
        Triggers.switchOff();
        Opportunity opp = selectTestOpportunity();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .create()
            .getRecord();

        opp.Order_Management_Owner__c = testUser.Id;
        update opp;
        Triggers.switchOn();

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(IcbHelper.ICBEventType.SIGNUP_ICB_ACCOUNT_CREATION_ERROR.name(), opp.Id);
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_ERROR, responseParams.status, 'An error status should be returned');
        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'Post to chatter should be made');
        Assert.areEqual(testUser.Id, ((ConnectApi.MentionSegmentInput) ChatterHelper.lastFeedItemInput.body.messageSegments[0]).id, 'Id should match the provided userId');    

        opp = selectTestOpportunity();
        Assert.areEqual(
            IcbHelper.SIGNUP_ICB_ACCOUNT_CREATION_ERROR,
            opp.RCCCSyncStatus__c,
            'Wrong Process Order CC Sync Status'
        );
    }

    @IsTest
    static void testHandleSignUpCompleted() {
        Opportunity opp = selectTestOpportunity();

        RestRequest req = new RestRequest();
        req.requestBody = createRequestBody(IcbHelper.ICBEventType.SIGNUP_END_OK.name(), opp.Id);
        RestContext.request = req;

        Test.startTest();
            CaseEventServiceICB.handleEventRequest();
            String responseBody = RestContext.response.responseBody.toString();
        Test.stopTest();

        IcbHelper.IcbResponseParams responseParams = (IcbHelper.IcbResponseParams)
            JSON.deserialize(responseBody, IcbHelper.IcbResponseParams.class);

        Assert.areEqual(IcbHelper.STATUS_SUCCESS, responseParams.status, 'An success status should be returned');
        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'Post to chatter should be made');

        opp = selectTestOpportunity();
        Assert.areEqual(
            IcbHelper.CC_SYNC_STATUS_COMPLETED,
            opp.RCCCSyncStatus__c,
            'Wrong Process Order CC Sync Status'
        );
    }
}