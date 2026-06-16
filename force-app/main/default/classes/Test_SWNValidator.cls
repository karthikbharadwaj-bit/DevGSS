@isTest
private class Test_SWNValidator {
    static final String OPP_NAME = 'oppName';

    class Mock implements HttpCalloutMock {
        private String body;

        public Mock(String body) {
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(body);

            return res;
        }
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
                Opportunity.Name => OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON
            })
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Package_Info__c => '[{"id":"1","packageInfo":{"id":"2222"}}]'
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

    static void setMock(String body) {
        Test.setMock(HttpCalloutMock.class, new Mock(body));
    }

    @TestSetup
    static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://test.com',
                NGBS_Settings__c.AccountManagerPath__c => 'http://test.com/test_manager',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();
    }
    @isTest
    static void testValidateSyncWithNGBS() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.NGBSPackagesExpirationFiltration__c, true)
            .create();

        setMock('{"id":"1","packages":[{"id":"2222"}]}');
        SWNDataCollector sdc = buildDataColector();

        Test.startTest();
            String result = SWNValidator.validateSyncWithNGBS(sdc, false);
        Test.stopTest();

        List<Response.ResponseMessage> deserializedResult =
            (List<Response.ResponseMessage>) JSON.deserialize(result, List<Response.ResponseMessage>.class);

        for (Response.ResponseMessage r : deserializedResult) {
            Assert.areEqual('', r.messageDetails, 'No returned messages should be');
        }

        Assert.areEqual(0, deserializedResult.size(), 'Validation should be passed and no errors should be handled');
    }

    @isTest
    static void testValidateSuspendedAccount() {
        setMock('{"id":1, "packages":[{"id":2222,"status":"Suspended"}]}');
        SWNDataCollector sdc = buildDataColector();

        Test.startTest();
            String result = SWNValidator.validateSyncWithNGBS(sdc, false);
        Test.stopTest();

        List<Response.ResponseMessage> deserializedResult =
            (List<Response.ResponseMessage>) JSON.deserialize(result, List<Response.ResponseMessage>.class);

        Assert.areEqual(1, deserializedResult.size(), 'Validation shouldn\'t be passed and message should be handled');
        Assert.areEqual(SWNMessageHelper.SUSPENDED_NGBS_STATUS_MSG, deserializedResult[0].messageDetails, 'Validation shouldn\'t be passed and message should be handled');
    }
}