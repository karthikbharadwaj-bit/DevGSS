@isTest
class Test_SWNSyncCCBHelper {
    static final String OPP_NAME = 'oppName';
    static final String CCB_ENDPOINT = 'https://fake-icb-api';
    @TestSetup
    static void makeData() {
        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.BaseEndpoint__c => CCB_ENDPOINT,
                CCB_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.ChangePath__c => '/changeCCBPath'
            })
            .create();
        
    }
    @isTest
    static void testCollectAndTransformDataMPL() {     
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME + '1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Opportunity childOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => OPP_NAME + '2',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.isMultiproductTechnicalOpportunity__c => true,
                Opportunity.Sub_Brand__c => '6010.JenneUS',
                Opportunity.MasterOpportunity__c => masterOpp.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        Quote childQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => childOpp.Id,
                Quote.MasterQuote__c => masterQt.Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();
        Triggers.switchOn();


        Test.startTest();
            POWrappers.SignUpParams res = SWNSyncCCBHelper.collectAndTransformData(childQt, false);
        Test.stopTest();

        Assert.areEqual(childQt.Id, res.targetQuote.Id, 'Wrong target quote for MPL flow');
        Assert.areEqual(childQt.OpportunityId, res.opportunity.Id, 'Wrong opportunity for MPL flow');
    }

    @isTest
    static void testCollectAndTransformDataMPUB() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Triggers.switchOff();
        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        Quote childQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterOpp.Id,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_VOICE_LEGACY,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => childQt.Id,
                Order.TechnicalQuoteId__c => childQt.Id,
                Order.AccountId => masterOpp.AccountId,
                Order.EffectiveDate => System.today(),
                Order.Status => OrderHelper.STATUS_NEW,
                Order.RecordTypeId => OrderHelper.RT_ID_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            POWrappers.SignUpParams res = SWNSyncCCBHelper.collectAndTransformData(childQt, true);
        Test.stopTest();

        Assert.areEqual(childQt.Id, res.targetQuote.Id, 'Wrong target quote for MPUB flow');
        Assert.areEqual(childQt.OpportunityId, res.opportunity.Id, 'Wrong opportunity for MPUB flow');
    }

    @isTest
    static void testBuildSyncWithFunnelErrorMessage() {
        String jsonResponseFull = '{"messages":[{"message":"Error 1","messageDetails":"Details 1"},{"message":"Error 2","messageDetails":"Details 2"}]}';
        String jsonResponseNull = '{"messages":[{"message":null,"messageDetails":null}]}';
        String jsonResponsePartial = '{"messages":[{"message":" ","messageDetails":" "},{"message":"Error 3","messageDetails":""}]}';
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody(jsonResponseFull);
        
        Test.startTest();
            String resultFull = SWNSyncCCBHelper.buildSyncWithFunnelErrorMessage(mockResponse);
            mockResponse.setBody(jsonResponseNull);
            String resultNull = SWNSyncCCBHelper.buildSyncWithFunnelErrorMessage(mockResponse);
            mockResponse.setBody(jsonResponsePartial);
            String resultPartial = SWNSyncCCBHelper.buildSyncWithFunnelErrorMessage(mockResponse);
        Test.stopTest();
        

        Assert.areEqual('Error 1\nDetails 1\nError 2\nDetails 2', resultFull, 'Wrong message for full response');
        Assert.areEqual('', resultNull, 'Wrong message for null response');
        Assert.areEqual('Error 3', resultPartial, 'Wrong message for partial response with missing message');
    }

    @isTest
    static void testBuildSyncWithFunnelExceptionMessageValidResponse() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatus('Success');
        mockResponse.setBody('{"error":"Internal Server Error"}');
        
        SWNSyncCCBHelper.SyncWithFunnelParams params = new SWNSyncCCBHelper.SyncWithFunnelParams();
        params.res = mockResponse;
        params.endpoint = CCB_ENDPOINT;

        Test.startTest();
            String result = SWNSyncCCBHelper.buildSyncWithFunnelExceptionMessage(params);
        Test.stopTest();

        String expected = 'Success. Please Contact Your Administrator.\nTechnical Details: {"error":"Internal Server Error"}.\nRequest endpoint: ' + CCB_ENDPOINT;
        Assert.areEqual(expected, result, 'Wrong message for valid response');
    }

    @isTest
    static void testBuildSyncWithFunnelExceptionMessageNullStatus() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"error":"Internal Server Error"}');
        
        SWNSyncCCBHelper.SyncWithFunnelParams params = new SWNSyncCCBHelper.SyncWithFunnelParams();
        params.res = mockResponse;
        params.endpoint = CCB_ENDPOINT;

        Test.startTest();
            String result = SWNSyncCCBHelper.buildSyncWithFunnelExceptionMessage(params);
        Test.stopTest();

        String expected = 'Technical Details: {"error":"Internal Server Error"}.\nRequest endpoint: ' + CCB_ENDPOINT;
        Assert.areEqual(expected, result, 'Wrong message for null status response');
    }

    @isTest
    static void testBuildSyncWithFunnelExceptionMessageNullBody() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatus('Error');
        
        SWNSyncCCBHelper.SyncWithFunnelParams params = new SWNSyncCCBHelper.SyncWithFunnelParams();
        params.res = mockResponse;
        params.endpoint = CCB_ENDPOINT;

        Test.startTest();
            String result = SWNSyncCCBHelper.buildSyncWithFunnelExceptionMessage(params);
        Test.stopTest();

        String expected = 'Error. Please Contact Your Administrator.\n\nRequest endpoint: ' + CCB_ENDPOINT;
        Assert.areEqual(expected, result, 'Wrong message for null body response');
    }

    @isTest
    static void testBuildSyncWithFunnelExceptionMessageNullEndpoint() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatus('Error');
        mockResponse.setBody('{"error":"Forbidden"}');
        
        SWNSyncCCBHelper.SyncWithFunnelParams params = new SWNSyncCCBHelper.SyncWithFunnelParams();
        params.res = mockResponse;

        Test.startTest();
            String result = SWNSyncCCBHelper.buildSyncWithFunnelExceptionMessage(params);
        Test.stopTest();

        String expected = 'Error. Please Contact Your Administrator.\nTechnical Details: {"error":"Forbidden"}.\nRequest endpoint: null';
        Assert.areEqual(expected, result, 'Wrong message for null endpoint response');
    }

    @isTest
    static void testGetBodyStringEngageUILessSettingsOn() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProduct__c => true,
                Feature_Toggle__c.EnableUILessProcessOrderEngage__c => true
            })
            .create();

        Map<String, Object> requestBodyMap = new Map<String, Object> {
            'isOverride' => true,
            'limitType' => 'someType'
        };

        Test.startTest();
            String result = SWNSyncCCBHelper.getBodyString(requestBodyMap);
        Test.stopTest();

        Assert.isTrue(result.contains('override'), 'Expected "override" in the result');
        Assert.isTrue(result.contains('type'), 'Expected "type" in the result');
    }
    
    @isTest
    static void testGetBodyStringEngageUILessSettingsOff() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableUILessProcessOrderEngage__c, false)
            .create();

        Map<String, Object> requestBodyMap = new Map<String, Object> {
            'isOverride' => true,
            'limitType' => 'someType'
        };

        Test.startTest();
            String result = SWNSyncCCBHelper.getBodyString(requestBodyMap);
        Test.stopTest();

        Assert.isTrue(result.contains('isOverride=true'), 'Expected "isOverride=true" in the result');
        Assert.isTrue(result.contains('limitType=someType'), 'Expected "limitType=someType" in the result');
    }

    @isTest
    static void testGetFilteredQlisUpsell() {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, ValueProviderBuilder.provideList(new List<Integer> {1, 0}))
            .quantity(2)
            .build()
            .getRecords();

        Quote qt = (Quote) Test_Utils.putIntoUnwritableField(new Quote(), Quote.class, 'QuoteLineItems', qlis);

        Assert.areEqual(2, qlis.size(), 'Must be 2 qli before test execution');
        Test.startTest();
            List<QuoteLineItem> result = SWNSyncCCBHelper.getFilteredQlis(qt, SWNStep.UP_SELL, null);
        Test.stopTest();

        Assert.areEqual(1, result.size(), '1 quote line item should be filtered');
        Assert.areEqual(1, result[0].NewQuantity__c, 'Wrong quote line item');
    }

    @isTest
    static void testGetFilteredQlisUpgrade() {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, ValueProviderBuilder.provideList(new List<Integer> {1, 0}))
            .quantity(2)
            .build()
            .getRecords();

        Quote qt = (Quote) Test_Utils.putIntoUnwritableField(new Quote(), Quote.class, 'QuoteLineItems', qlis);

        Assert.areEqual(2, qlis.size(), 'Must be 2 qli before test execution');
        Test.startTest();
            List<QuoteLineItem> result = SWNSyncCCBHelper.getFilteredQlis(qt, SWNStep.UPGRADE, null);
        Test.stopTest();

        Assert.areEqual(1, result.size(), '1 quote line item should be filtered');
        Assert.areEqual(1, result[0].NewQuantity__c, 'Wrong quote line item');
    }

    @isTest
    static void testGetFilteredQlisDownsell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableSimplifiedDownsellForRingCX__c, true)
            .create();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Quantity__c, 2)
            .build()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, ValueProviderBuilder.provideList(new List<Integer> {3, 1}))
            .quantity(2)
            .build()
            .getRecords();

        qlis[0] = (QuoteLineitem) Test_Utils.putIntoUnwritableField(qlis[0], QuoteLineitem.class, 'Entitlement__r', ent);
        Quote qt = (Quote) Test_Utils.putIntoUnwritableField(new Quote(), Quote.class, 'QuoteLineItems', qlis);

        Assert.areEqual(2, qlis.size(), 'Must be 2 qli before test execution');
        Test.startTest();
            List<QuoteLineItem> result = SWNSyncCCBHelper.getFilteredQlis(qt, SWNStep.DOWN_SELL, new List<Cost_Center__c> {new Cost_Center__c()});
        Test.stopTest();

        Assert.areEqual(1, result.size(), '1 quote line item should be filtered');
        Assert.areEqual(2, result[0].NewQuantity__c, 'Wrong quote line item');
    }

    @isTest
    static void testGetFilteredQlisUnexpectedAction() {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, ValueProviderBuilder.provideList(new List<Integer> {3, 1}))
            .quantity(2)
            .build()
            .getRecords();
        Quote qt = (Quote) Test_Utils.putIntoUnwritableField(new Quote(), Quote.class, 'QuoteLineItems', qlis);

        Assert.areEqual(2, qlis.size(), 'Must be 2 qli before test execution');
        Test.startTest();
            List<QuoteLineItem> result = SWNSyncCCBHelper.getFilteredQlis(qt, SWNStep.REPRICE_SYNC, null);
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'Should be empty');
    }

    @isTest
    static void testSyncWithFunnelSuccess() {
        List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/changeCCBPath', HttpHelper.RESPONSE_STATUS_COMPLETED, '{}', 200, HttpHelper.METHOD_POST)
        };
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock(mockInfos));

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        Test.startTest();
            Response result = SWNSyncCCBHelper.syncWithFunnel(qt, '{}');
        Test.stopTest();

        Assert.areEqual(
            SWNSyncCCBHelper.SUCCESS_STATUS,
            result.data.get(SWNSyncCCBHelper.STATUS_KEY),
            'Success response should be returned'
        );
        Assert.areEqual(
            SWNSyncCCBHelper.SYNC_CCB_HEADER_SUCCESS_MESSAGE,
            result.data.get(SWNSyncCCBHelper.HEADER_KEY),
            'Correct success message should be returned'
        );
    }

    @isTest
    static void testSyncWithFunnelError() {
        List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/changeCCBPath', 'Error', '{"messages":[]}', 400, HttpHelper.METHOD_POST)
        };
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock(mockInfos));

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        Test.startTest();
            Response result = SWNSyncCCBHelper.syncWithFunnel(qt, '{}');
        Test.stopTest();

        Assert.areEqual(1, result.messages.size(), 'Only 1 error message should be returned');
        Assert.areEqual(result.messages[0].message, CCBAPI.SYNC_CCB_FAILED, 'Correct error message should be returned');
    }

    @isTest
    static void testSyncWithFunnelErrorWithException() {
        List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/changeCCBPath', 'Error', '{}', 400, HttpHelper.METHOD_POST)
        };
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock(mockInfos));

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        Test.startTest();
            try {
                SWNSyncCCBHelper.syncWithFunnel(qt, '{}');
                Assert.Fail('Exception should be thrown');
            } catch (AquivaHelper.AquivaException ex) {
                Assert.isTrue(ex.getMessage().contains(CCBAPI.REQUEST_CCB_EXCEPTION_MESSAGE), 'Wrong exception message');
            }
        Test.stopTest();
    }
}