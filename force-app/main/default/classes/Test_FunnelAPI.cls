@IsTest
private class Test_FunnelAPI {

    @testSetup
    static void generateData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
        })
        .create();

        new SObjectBuilder(GW_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                GW_Settings__c.BaseEndpoint__c => 'https://testfsgapi',
                GW_Settings__c.BaseEndpoint_EUR__c => 'https://testfsgapi',
                GW_Settings__c.Source__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.SignUpPath__c => '/wsx/signup/v1.0/',
                GW_Settings__c.SFAPath__c => '/api/projects/ws/saf_auxiliary_services/'
            })
            .create();

        Triggers.switchOff();
        List<Opportunity> oppList = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideList(new List<String>{
                    'Euro Opportunity', 'USD Opportunity'
                }),
                Opportunity.CloseDate => Date.today()
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Quote> quoteList = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideList(new List<String>{
                    'Euro Quote', 'USD Quote'
                }),
                Quote.OpportunityId => ValueProviderBuilder.provideParents(oppList),
                Quote.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String>{
                    'EUR', 'USD'
                }),
                Quote.Approved_Status__c => 'Approved',
                Quote.Status => 'Draft',
                Quote.isPrimary__c => true,
                Quote.Initial_Term_months__c => '12',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.QuoteType__c => 'Quote',
                Quote.Payment_Plan__c => 'Monthly'
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();
    }

    @isTest
    private static void testGetDeviceAvailabilitySuccess() {
        Test.setMock(HttpCalloutMock.class, new FunnelApiMock());

        Test.startTest();
        Response res = FunnelAPI.getDevicesAvailability('18', '3', new List<String> {'LC_HD_523'}, new List<String> {'AUT', 'USA'});
        Test.stopTest();

        BillingWrappers.DeviceAvailabilityResponse deviceAvailability = (BillingWrappers.DeviceAvailabilityResponse) res.data.get('deviceAvailability');
        System.assertEquals(true, res.isSuccess(), 'Response must be with success status');
        System.assertEquals(true, deviceAvailability != null, 'Response must contains data about device availability');
        System.assertEquals(1, deviceAvailability.devices.size(), 'Devices must have 1 record');
        System.assertEquals(2, deviceAvailability.devices.get('LC_HD_523').size(), 'Device must have 2 countries');
        System.assertEquals(2, deviceAvailability.devices.get('LC_HD_523').get('AUT').ruleType, 'Device country AUT must have ruleType "2"');
        System.assertEquals('11/20/2021', deviceAvailability.devices.get('LC_HD_523').get('AUT').endOfSalesDate, 'Device country AUT must have end sales date "11/20/2021"');
        System.assertEquals(null, deviceAvailability.devices.get('LC_HD_523').get('USA'), 'Device country USA must have no rules');

        System.assertEquals(2, deviceAvailability.countries.size(), 'Countries must have 2 records');
        System.assertEquals(true, deviceAvailability.countries.containsKey('AUT'), 'Countries must have "AUT" key');
        System.assertEquals(1, deviceAvailability.countries.get('AUT').shippingLicenseIds.size(), '"AUT" must have 1 shipping license');
        System.assertEquals('Austria', deviceAvailability.countries.get('AUT').name, '"AUT" must have name "Austria"');
        System.assertEquals(false, deviceAvailability.countries.get('AUT').hasStates, '"AUT" must have false in hasStates param');
        System.assertEquals(true, deviceAvailability.countries.containsKey('USA'), 'Countries must have "USA" key');
        System.assertEquals(3, deviceAvailability.countries.get('USA').shippingLicenseIds.size(), '"USA" must have 3 shipping licenses');
        System.assertEquals('United States', deviceAvailability.countries.get('USA').name, '"USA" must have name "United States"');
        System.assertEquals(true, deviceAvailability.countries.get('USA').hasStates, '"USA" must have true in hasStates param');
    }

    @isTest
    private static void testGetDeviceAvailabilityError() {
        FunnelApiMock testMock = new FunnelApiMock();
        testMock.statusCode = 404;
        testMock.status = 'Error';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
        Response res = FunnelAPI.getDevicesAvailability('18', '3', new List<String> {'LC_HD_523'}, new List<String> {'AUT', 'USA'});
        Test.stopTest();

        System.assertEquals(
            FunnelAPI.addSafPrefix('An error occurred during get device availability info'),
            res.messages[0].message, 'Response must be with message "'
                + FunnelAPI.addSafPrefix('An error occurred during get device availability info"')
        );
    }

    @isTest
    private static void testGetTimezonesSuccess() {
        FunnelApiMock testMock = new FunnelApiMock();
        testMock.response = '{"result":[{"bias": -720,"biasFormatted": "-12:00","deprecated": false,"description": "International Date Line West","id": 62,"label": "(GMT-12:00) International Date Line West","name": "Etc/GMT+12"}],"SAFAS_SID": "a866bbebe61b9e839c73714f87ede52c60ad2378b9011a147abe6c0c4e1937cc","id": null}';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
        String stringResponse = FunnelAPI.getTimezones('1950', '2');
        Test.stopTest();

        Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(stringResponse);
        System.assert(res.containsKey('status'), 'Status parameter is missed');
        System.assertEquals(Response.STATUS_SUCCESS, res.get('status'), 'Response must be with success status');
        System.assert(res.containsKey('data'), 'Data parameter is missed');
        Map<String, Object> data = (Map<String, Object>) res.get('data');
        System.assert(data.containsKey('timezones'), 'Timezones parameter is missed');
        List<Object> timezones = (List<Object>) data.get('timezones');
        System.assertEquals(1, timezones.size(), 'Timezones must have 1 record');
        Map<String, Object> timezone = (Map<String, Object>) timezones.get(0);
        System.assert(timezone.containsKey('label'), 'Id parameter is missed');
        System.assert(timezone.containsKey('label'), 'Label parameter is missed');
        System.assertEquals(62, timezone.get('id'), 'Timezone must have "62" id');
        System.assertEquals('(GMT-12:00) International Date Line West', timezone.get('label'), 'Timezone record must have "(GMT-12:00) International Date Line West" label');
    }

    @isTest
    private static void testGetTimezonesError() {
        FunnelApiMock testMock = new FunnelApiMock();
        testMock.response = '{"error": {"code": 1,"message": "Requested package id and version are not supported by SAF.","data": {"type": "App\\\\ViewModels\\\\Exceptions"}},"SAFAS_SID": "4fe8a81c8c8dd21c4f02949eaf05170c3830623bf1c61b86b8a266180c4ba6d0","id": null}';
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
        String stringResponse = FunnelAPI.getTimezones('errorId', 'errorVersion');
        Test.stopTest();

        Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(stringResponse);
        System.assert(res.containsKey('status'), 'Status parameter is missed');
        System.assertEquals(Response.STATUS_ERROR, res.get('status'), 'Response must be with error status');
        System.assert(res.containsKey('messages'), 'Messages parameter is missed');
        List<Object> messages = (List<Object>) res.get('messages');
        System.assertEquals(1, messages.size(), 'Messages must have 1 record');
        Map<String, Object> message = (Map<String, Object>) messages.get(0);
        System.assert(message.containsKey('message'), 'Message parameter is missed');
        System.assert(message.containsKey('severity'), 'Severity parameter is missed');
        System.assertEquals(FunnelAPI.addSafPrefix('An error occurred during get timezones info'), message.get('message'));
        System.assertEquals(Response.SEVERITY_ERROR, message.get('severity'));
    }

    @isTest
    private static void testMultiProductMVPSignUpUSD() {
        FunnelApiMock testMock = new FunnelApiMock();
        testMock.response = '{"result": {"orderStatus": "IN_PROCESS"},"FSG_SID": "770fd3777c5cc6f42148f809fea34bbbf952563730a25ae661bbf5ea580f23e9_rcprod0","id": null}';
        Test.setMock(HttpCalloutMock.class, testMock);

        Opportunity testOpp = (Opportunity) new OpportunitySelector().selectOpportunities()
            .selectFields(new List<String>{'Id', 'PrimaryQuote__r.CurrencyIsoCode'})
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{'USD Opportunity'})
            .executeQuery()
            .get(0);

        POWrappers.SignUpRequestBody reqBody = new POWrappers.SignUpRequestBody();
        reqBody.requestBodyMap = new Map<String, Object> ();
        Test.startTest();
        FunnelAPI.FunnelResponse resp = FunnelAPI.multiProductMVPSignUp(testOpp, reqBody);
        Test.stopTest();

        System.assertEquals('IN_PROCESS', resp.result.orderStatus, 'Successful Response should contain orderStatus');
    }

    private static void testMultiProductMVPSignUpEUR() {
        FunnelApiMock testMock = new FunnelApiMock();
        testMock.response = '{"result": {"orderStatus": "IN_PROCESS"},"FSG_SID": "770fd3777c5cc6f42148f809fea34bbbf952563730a25ae661bbf5ea580f23e9_rcprod0","id": null}';
        Test.setMock(HttpCalloutMock.class, testMock);

        Opportunity testOpp = (Opportunity) new OpportunitySelector().selectOpportunities()
            .selectFields(new List<String>{'Id', 'PrimaryQuote__r.CurrencyIsoCode'})
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{'EUR Opportunity'})
            .executeQuery()
            .get(0);

        POWrappers.SignUpRequestBody reqBody = new POWrappers.SignUpRequestBody();
        Test.startTest();
        FunnelAPI.FunnelResponse resp = FunnelAPI.multiProductMVPSignUp(testOpp, reqBody);
        Test.stopTest();

        System.assertEquals('IN_PROCESS', resp.result.orderStatus, 'Successful Response should contain orderStatus');
    }

    @isTest
    private static void testMultiProductProServSignUp() {
        FunnelApiProServMock testMock = new FunnelApiProServMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Opportunity testOpp = (Opportunity) new OpportunitySelector().selectOpportunities()
            .selectFields(new List<String>{'Id', 'PrimaryQuote__r.CurrencyIsoCode'})
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object>{'USD Opportunity'})
            .executeQuery()
            .get(0);

        POWrappers.SignUpRequestBody reqBody = new POWrappers.SignUpRequestBody();
        Test.startTest();
            FunnelAPI.FunnelResponse resp = FunnelAPI.multiProductProServSignUp(testOpp, reqBody);
        Test.stopTest();
        Assert.areEqual(null, resp.result, 'Successful Response should not have result');
        Assert.areEqual(null, resp.error, 'Successful Response should not have error');
    }
}