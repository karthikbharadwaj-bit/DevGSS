@isTest
private class Test_SWNValidatorManager {
    static SWNValidatorManager generateManager() {
        SWNValidatorManager manager = new SWNValidatorManager();
        manager.sdc = new SWNDataCollector();
        manager.sdc.opp = new Opportunity();
        manager.sdc.qt = new Quote();
        manager.sdc.acc = new Account();
        manager.sdc.syncable = new NGBSSyncables.OpportunitySync(manager.sdc.opp);
        return manager;
    }

    static SWNDataCollector buildDataColector() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => '123'
            })
            .build()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'OPP_NAME',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON
            })
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"18","version":"1","packageInfo":{"id":9710001}}]'
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Display_Name__c, 'QUOTELINEITEM_NAME')
            .build()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Id, ValueProviderBuilder.provideDummyId(ServiceInfo__c.SObjectType))
            .build()
            .getRecord();

        qt = (Quote) Test_Utils.putIntoUnwritableFields(
            qt,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'Opportunity' => opp
            }
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'ServiceInfo__r',
            new List<ServiceInfo__c> { serviceInfo }
        );

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.syncable = new NGBSSyncables.ServiceInfoSync(serviceInfo);
        return sdc;
    }

    @isTest
    static void testInitializeValidators() {
        SWNValidatorManager manager = generateManager();
        Test.startTest();
            manager.initializeValidators();
        Test.stopTest();

        Assert.isNotNull(manager.validators, 'validators should be defined');
        Assert.areEqual(10, manager.validators.size(), '10 validators should be defined defined without engage termination');
    }

    @isTest
    static void testChainValidators() {
        SWNValidatorManager manager = generateManager();
        manager.initializeValidators();
        for (Validator v : manager.validators) {
            Assert.isNull(v.nextValidator, 'Next validator should not be defined');
        }

        Test.startTest();
            manager.chainValidators();
        Test.stopTest();

        for (Integer i = 0; i < manager.validators.size() - 1; i++) {
            Assert.areEqual(manager.validators[i + 1], manager.validators[i].nextValidator, 'Validators should match');
        }
    }

    @isTest
    static void testAddAdditionalValidators() {
        SWNValidatorManager manager = generateManager();
        manager.validators = new List<Validator>();
        Assert.areEqual(0, manager.validators.size(), 'Should be empty before testing');

        Test.startTest();
            manager.addAdditionalValidators();
        Test.stopTest();
        Assert.areEqual(2, manager.validators.size(), '2 validators should be added');
    }

    @isTest
    static void testHandleException() {
        String errorMessage = 'errorMessage';
        SWNValidatorManager manager = generateManager();
        Response resp = new Response();

        Test.startTest();
            manager.handleException(resp, errorMessage);
        Test.stopTest();

        Assert.areEqual(1, resp.messages.size(), 'Response should contain one message');
        Assert.areEqual(Label.IsNotAvailableToSyncWithNGBS, resp.messages[0].message, 'Message label should match');
        Assert.areEqual(errorMessage, resp.messages[0].messageDetails, 'Message detail should match the error message');
    }

    @isTest
    static void testValidate() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        SWNDataCollector sdc = buildDataColector();

        Test.startTest();
            SWNValidatorManager manager = new SWNValidatorManager(sdc, false);
            Response resp = manager.validate();
        Test.stopTest();

        for (Response.ResponseMessage r : resp.messages) {
            Assert.areEqual('', r.messageDetails, 'No returned messages should be');
        }

        Assert.areEqual(0, resp.messages.size(), 'Response should not contain messages');
    }
}