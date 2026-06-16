@isTest
public with sharing class Test_ProcessOrder {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String OPP_NAME = 'Test Opportunity';
    private static final String DICTIONARIES_RESPONSE_BODY = '{"countries": [{"id": 109,"name": "Italy","code": "ITA"}],' +
        '"timeZones": [{"id": "GMT","name": "Casablanca, Monrovia, Reykjavik"}],"nicSegments": [],"geoRegions": [],"implementationTeams": []}';

    private static final String ORDER_TO_VENDOR_RESPONSE_BODY = '{"status": "SIGNUP_BEGIN","statusChanges": [{"dateTime": 1625661635868,"status": "SIGNUP_BEGIN"' +
        '}],"administratorInfo": {}, "accountrams": {},"billingAddress": {},"ngbsLicenses": {},"nicLicenses": {"items": [{"name": "Contact Center1",' +
        '"changeAction": "New","vendorSKU": "2","listPrice": 120.01,"priceToVendor": 0.1,"quantity": 30,' +
        '"numberOfLicenses": 10,"totalPrice": 3000}],"currency": "USD","totalPrice": 110}}';

    private static final String VALIDATE_ADDRESS_RESPONSE_BODY = '{"status": "VALID","suggestedAddresses": [' +
        '{"country": "USA","state": "CALIFORNIA","city": "Belmont","address1": "20 Davis Drive","zip": "94002"}]}';

    private static final String ENGAGE_VOICE_PLATFORMS_RESPONSE_BODY = '[{"id":"aws91-l16","title":"aws91-l16 env lab","vpcNames":"aws91",' +
        '"vpcIds":"vpc-02c87b7c99471ed9f","group":"US1","order":1},{"id":"aws91zz-l16","title":"aws91zz-l16 env lab","vpcNames":"aws91",' +
        '"vpcIds":"vpc-02c87b7c99471ed9f","group":"CA1","order":1}]';

    private static final String ENGAGE_DIGITAL_PLATFORMS_RESPONSE_BODY = '[{"name":"ed-eup-us1-s1-fra20","title":"AWS26-EUP, \'Europe (Frankfurt) WRONG\'",' +
        '"vpcNames":"aws26","vpcIds":"vpc-0f57e9ee384c3b8d1","group":"US1","order":1},{"name":"ed-eup-us1-s1","title":"AWS26-EUP, \'Europe (Frankfurt)\'",' +
        '"vpcNames":"aws26","vpcIds":"vpc-0f57e9ee384c3b8d1","group":"US1","order":2}]';

    private static final String ENGAGE_VOICE_SUBMIT_RESPONSE_BODY = '{"subscriptionType":"voice_standalone","opportunityId":"0065g00000D1Z2zAAF",' +
        '"signedUpBefore":false,"agentInfo":{"id":"123","name":"Test Agent"},"engageVoiceAccount":{"mainAccountId":"22500000","mainAccountName":"Package 650 - EV SA concurrent seats",' +
        '"ngbsAccount":{"id":2922797002,"package_id":2920992002,"packageDescription":"Engage Voice Standalone (USD) 21.1"},"rcAccount":{"id":"66437887"},' +
        '"engageAccountId":"7295","enterpriseAccountId":"133314"}}';

    private static final String ENGAGE_DIGITAL_SUBMIT_RESPONSE_BODY = '{"subscriptionType":"digital_standalone","opportunityId":"0065g00000D1Z2zAAF",' +
        '"signedUpBefore":false,"agentInfo":{"id":"00534000009vqzbAAA","name":"Test Agent"},"engageDigitalAccount":{"id":"12344321",' +
        '"appBase":"https://test.com","name":"domainengagedigitaltest","ngbsAccount":{"id":2907704002,"package_id":2905906002,"packageDescription":"Engage Digital Standalone concurrent seat based (EUR)"},' +
        '"rcAccount":{"id":"47935034"},"engageAccountId":"7282","enterpriseAccountId":"53453453"}}';

    private static final String SUBMIT_CONTACT_CENTER_PATCH_RESPONSE_BODY = '{"status": "SIGNUP_READY_FOR_SUBMIT","statusChanges": [{"dateTime": 1661433849814,' +
        '"status": "SIGNUP_READY_FOR_SUBMIT"}],"administratorInfo": {},"accountParams": {"timeZoneId": "GMT","geoRegionId": "1","nicSegmentId": "1-50 Seats",' +
        '"implementationTeamId": "1","contactCenterNumber": "123"},"billingAddress": {},"ngbsLicenses": {"items": [{"name": "Inbound International","type": "Usage",' +
        '"ngbsPackageId": "822","ngbsElementId": "CC_ICIBINT_123","quantity": 1}]},"nicLicenses": {"items": [{"name": "CXone Business Intelligence Viewer License (per Concurrent User)",' +
        '"ngbsPackageId": "822","ngbsElementId": "CC_RPRTVO_96","vendorSKU": "3880-1539-000","listPrice": 2.8,"priceToVendor": 2.8}]},"ngbsBillingAccountId": "2927902002",' +
        '"enterpriseAccountId": "90886695","rcAccountId": "75289011","caseDescription": "Test Case Description"}';

    private static final String SUBMIT_CONTACT_CENTER_POST_RESPONSE_BODY = '{"status": "SIGNUP_READY_FOR_SUBMIT","statusChanges": [{"dateTime": 1661433849814,' +
        '"status": "SIGNUP_READY_FOR_SUBMIT"}],"administratorInfo": {},"accountParams": {},"billingAddress": {},"ngbsLicenses": {"items": [{}]},"nicLicenses": ' +
        '{"items": [{}]},"ngbsBillingAccountId": "2927902002","enterpriseAccountId": "90886695","rcAccountId": "75289011","caseDescription": "Test Case Description"}';

    private static Account selectAccount() {
        return (Account) new ListOptional(new AccountSelector()
            .selectAccountByName(new List<Object> {ACCOUNT_NAME})
            .executeQuery()
        ).getFirst();
    }

    private static Opportunity selectOpportunity(String name) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<String> {
                'isSyncedToICB__c',
                'RCCCSyncStatus__c',
                'Account.RC_User_ID__c',
                'Account.isMultiProductTechnicalAccount__c'
            })
            .setCondition('Name = :bind0')
            .setQueryBindings(new List<Object> {name})
            .executeQuery()
        ).getFirst();
    }

    private static BillingHttpRequestMock populateAppropriateMock(BillingHttpRequestMock.MockInfo mockInfo, String endpoint) {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo> {
            endpoint => mockInfo
        };
        return testMock;
    }

    private static void setAppropriateMock(String resBody, String endpoint, String method) {
        BillingHttpRequestMock.MockInfo mockInfo = new BillingHttpRequestMock.MockInfo(
            'Completed',
            resBody,
            200,
            method
        );

        BillingHttpRequestMock testMock = populateAppropriateMock(mockInfo, endpoint);
        Test.setMock(HttpCalloutMock.class, testMock);
    }

    private static List<QuoteLineItem> buildQLIs(Id quoteId, List<Product2> prodList, List<PricebookEntry> pbeList) {
        return new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => quoteId,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(prodList),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => true,
                QuoteLineItem.NewQuantity__c => 5
            })
            .quantity(4)
            .build()
            .getRecords();
    }

    @testSetup
    static void createInitialData() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        // The NGBS_Settings__c record without fields was created to populate it with an appropriate data in BillingHttpRequestMock class static block
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .create();

        new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.BaseEndpoint__c => 'https://test.com/api',
                ICB_Settings__c.APIVersion1Path__c => '/v1/sfdc',
                ICB_Settings__c.APIVersion2Path__c => '/v2/sfdc',
                ICB_Settings__c.DictionariesPath__c => '/dictionaries',
                ICB_Settings__c.ValidatePath__c => '/address/validate',
                ICB_Settings__c.CasePath__c => '/sign-up/case',
                ICB_Settings__c.SignUpPath__c => '/sign-up'
            })
            .create();

        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.DirectBaseEndpoint__c => 'https://test.com/restapi',
                CCB_Settings__c.APIVersion2Path__c => '/v2.0/ccb',
                CCB_Settings__c.APIVersion3Path__c => '/v3.0/ccb',
                CCB_Settings__c.EVPlatformsPath__c => '/engage-voice/platforms',
                CCB_Settings__c.EDPlatformsPath__c => '/engage-digital/platforms',
                CCB_Settings__c.EVSubmit__c => '/engage-voice/sign-up/opportunity',
                CCB_Settings__c.EDSubmit__c => '/engage-digital/sign-up/opportunity'
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ACCOUNT_NAME)
            .create()
            .getRecord();

        new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => OPP_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create();
    }

    @isTest
    static void testCreateOrdersForSignUpMultiProducts() {
        Triggers.switchOff();
        Account acc = selectAccount();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
            })
            .create()
            .getRecord();

        opp.PrimaryQuote__c = masterQuote.Id;
        update opp;

        // create technical quote with a new service that should be processed in the sign up
        Quote technicalQuoteWithNewService = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test Quote New Service',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoRCCC(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.ServiceName__c => QuoteHelper.NGBS_RCCC_PRODUCT
            })
            .create()
            .getRecord();

        // all orders related to new service quotes that haven't been acquired yet will be deleted
        List<Order> ordersThatWillBeDeleted = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => acc.Id,
                Order.QuoteId => technicalQuoteWithNewService.Id,
                Order.OpportunityId => opp.Id,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.EffectiveDate => System.today(),
                Order.Status => OrderHelper.STATUS_NEW,
                Order.NumberOfMainLicenses__c => 25,
                Order.TechnicalAccountId__c => acc.Id,
                Order.TechnicalOpportunityId__c => opp.Id,
                Order.TechnicalQuoteId__c => technicalQuoteWithNewService.Id,
                Order.Provisioning__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        OrderHelper.PROVISIONING_AUTO,
                        OrderHelper.PROVISIONING_MANUAL
                    }
                )
            })
            .quantity(2)
            .create()
            .getRecords();

        // create technical quote with a new service that has already been processed in the sign up
        Quote technicalQuoteWithAcquiredService = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test Quote Existing Service',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoEngage(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.ServiceName__c => QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT,
                Quote.PackageNameNew__c => 'testPackageName'
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        technicalQuoteWithAcquiredService.Id,
                        technicalQuoteWithNewService.Id
                    }
                ),
                ServiceInfo__c.IsProcessOrderSent__c => ValueProviderBuilder.provideList(new List<Boolean> {true, false})
            })
            .quantity(2)
            .create();


        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RC_CONTACT_CENTER,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.InitialOrderType__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                        'manual',
                        'testUpsellType',
                        null
                    }
                )
            })
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(prodList),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliListForNewServiceQuote = buildQLIs(technicalQuoteWithNewService.Id, prodList, pbeList);

        List<QuoteLineItem> qliListForExistingServiceQuote = buildQLIs(technicalQuoteWithAcquiredService.Id, prodList, pbeList);

        qliListForNewServiceQuote.addAll(qliListForExistingServiceQuote);

        insert new List<QuoteLineItem>(qliListForNewServiceQuote);
        Triggers.switchOn();

        Test.startTest();
            List<String> targetIds = new List<String> { 
                String.valueOf(technicalQuoteWithNewService.Id),
                String.valueOf(technicalQuoteWithAcquiredService.Id)
            };
            ProcessOrder.createOrders(opp.Id, targetIds);
        Test.stopTest();

        List<Order> orders = (List<Order>) new OrderSelector()
            .selectOrders()
            .selectFields(new List<SObjectField> {Order.Id, Order.TechnicalQuoteId__c})
            .executeQuery();

        Boolean noOrdersForAcquiredServiceAreCreated = true;
        Integer numberOfOrdersForNewService = 0;
        for (Order existingOrder : orders) {
            for (Order orderToDelete : ordersThatWillBeDeleted) {
                if (existingOrder.Id.equals(orderToDelete.Id)) {
                    break;
                }
            }
            if (existingOrder.TechnicalQuoteId__c == technicalQuoteWithAcquiredService.Id) {
                noOrdersForAcquiredServiceAreCreated = false;
            }
            if (existingOrder.TechnicalQuoteId__c == technicalQuoteWithNewService.Id) {
                numberOfOrdersForNewService++;
            }
        }

        Assert.isTrue(noOrdersForAcquiredServiceAreCreated, 'Orders should not be created there for a signed service.');
        Assert.areEqual(2, numberOfOrdersForNewService, 'There should be 2 orders created for the new service quote.');
    }

    @isTest
    static void testGetOppBillingDetail() {
        Triggers.switchOff();
        Opportunity opp = selectOpportunity(OPP_NAME);

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
            })
            .create()
            .getRecord();

        Quote technicalQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, technicalQuote.Id)
            .create();
        Triggers.switchOn();

        Test.startTest();
            POWrappers.OppDetailWrapper oppWrapper = ProcessOrder.getOppBillingDetail(opp.Id);
        Test.stopTest();

        Assert.areEqual(opp.Id, oppWrapper.opportunity.Id, 'Opportunity Id should be the same');
        Assert.areEqual(2, oppWrapper.masterAndTechQuotes.size(), 'There should be master and technical quotes');
        Assert.areEqual(true, oppWrapper.isMPUB, 'IsMPUB should be true');
        Assert.isNull(oppWrapper.ngbsAccountStatus, 'ngbsAccountStatus should be null');
        Assert.areEqual(new Map<String, Boolean>(), oppWrapper.productNameToPackageIsActiveStatusMap, 'productNameToPackageIsActiveStatusMap should be empty');
        Assert.areEqual(new Map<Id, POWrappers.SyncableWrapper> (), oppWrapper.qtIdToSyncInfoMap, 'qtIdToSyncInfoMap should be empty');
    }

    @isTest
    static void testGetOppBillingDetailError() {
        Triggers.switchOff();
        Account acc = selectAccount();
        // in order to test catch section set Billing_ID__c field that the error was thrown in getNGBSAccount() method
        acc.Billing_ID__c = '12345';
        update acc;

        Opportunity opp = selectOpportunity(OPP_NAME);
        Triggers.switchOn();

        Test.startTest();
            POWrappers.OppDetailWrapper oppWrapper = ProcessOrder.getOppBillingDetail(opp.Id);
        Test.stopTest();

        Assert.isTrue(oppWrapper.message.contains('Error'), 'Exception message should contain the correct message');
    }

    @isTest
    static void testGetDictionariesHandleSubmit() {
        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'get dictionaries';

        setAppropriateMock(DICTIONARIES_RESPONSE_BODY, '/dictionaries', HttpHelper.METHOD_GET);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        Map<String, Object> bodyMap = (Map<String, Object>) dataMap.get('body');
        List<Object> countries = (List<Object>) bodyMap.get('countries');
        List<Object> timeZones = (List<Object>) bodyMap.get('timeZones');

        Assert.areEqual(Response.STATUS_SUCCESS, responseBodyMap.get('status'), 'Status should be success');
        Assert.areEqual(1, countries.size(), 'Countries should be returned');
        Assert.areEqual(1, timeZones.size(), 'Timezones should be returned');
    }

    @isTest
    static void testValidateAddressHandleSubmit() {
        BillingWrappers.SubmitWrapper wrapper = new BillingWrappers.SubmitWrapper();
        wrapper.billingAddress = new BillingWrappers.BillingAddress();
        wrapper.billingAddress.address1 = '20 Davis Drive';
        wrapper.billingAddress.city = 'Belmont';
        wrapper.billingAddress.country = 'USA';
        wrapper.billingAddress.state = 'CALIFORNIA';
        wrapper.billingAddress.zip = '94002';
        wrapper.billingAddress.skipValidation = true;

        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'validate address';
        requestParams.tier = OpportunityHelper.TIER_RC_CONTACT_CENTER;
        requestParams.data = wrapper;

        setAppropriateMock(VALIDATE_ADDRESS_RESPONSE_BODY, '/address/validate', HttpHelper.METHOD_POST);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        Map<String, Object> bodyMap = (Map<String, Object>) dataMap.get('body');
        List<Object> addresses = (List<Object>) bodyMap.get('suggestedAddresses');
        Map<String, Object> addressesMap = (Map<String, Object>) addresses.get(0);

        Assert.areEqual(Response.STATUS_SUCCESS, responseBodyMap.get('status'), 'Status should be success');
        Assert.areEqual(1, addresses.size(), 'SuggestedAddresses should be returned');
        Assert.areEqual('Belmont', addressesMap.get('city'), 'City parameter should be returned');
        Assert.areEqual('USA', addressesMap.get('country'), 'Country parameter should be returned');
    }

    @isTest
    static void testRequestOrderToVendorHandleSubmit() {
        Opportunity opp = selectOpportunity(OPP_NAME);

        String endpoint = '/sign-up/case' + ICBAPI.OPP_ID_PARAM + opp.Id;
        setAppropriateMock(ORDER_TO_VENDOR_RESPONSE_BODY, endpoint, HttpHelper.METHOD_GET);

        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'request order to vendor';
        requestParams.targetId = opp.Id;
        requestParams.isChangeOrder = false;

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        Map<String, Object> bodyMap = (Map<String, Object>) dataMap.get('body');
        String status = (String) bodyMap.get('status');
        Map <String, Object> nicLicenses = (Map<String, Object>) bodyMap.get('nicLicenses');

        Assert.areEqual(Response.STATUS_SUCCESS, responseBodyMap.get('status'), 'Status should be success');
        Assert.areEqual('SIGNUP_BEGIN', status, 'Status should be SIGNUP_BEGIN');
        Assert.isNotNull(nicLicenses.get('items'), 'nicLicenses items parameter should not be null');
    }

    @isTest
    static void testRequestEngageVoicePlatformsHandleSubmit() {
        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'request engage platforms';
        requestParams.isEngageVoice = true;

        setAppropriateMock(ENGAGE_VOICE_PLATFORMS_RESPONSE_BODY, '/engage-voice/platforms', HttpHelper.METHOD_GET);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        List<Object> bodyMap = (List<Object>) dataMap.get('body');

        Assert.areEqual(Response.STATUS_SUCCESS, responseBodyMap.get('status'), 'Status should be success');
        Assert.areEqual(2, bodyMap.size(), 'Body should contain 2 engage voice platforms');
    }

    @isTest
    static void testRequestEngageDigitalPlatformsHandleSubmit() {
        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'request engage platforms';
        requestParams.isEngageVoice = false;

        setAppropriateMock(ENGAGE_DIGITAL_PLATFORMS_RESPONSE_BODY, '/engage-digital/platforms', HttpHelper.METHOD_GET);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        List<Object> bodyMap = (List<Object>) dataMap.get('body');

        Assert.areEqual(Response.STATUS_SUCCESS, responseBodyMap.get('status'), 'Status should be success');
        Assert.areEqual(2, bodyMap.size(), 'Body should contain 2 engage digital platforms');
    }

    @isTest
    static void testSubmitEngageVoiceMPUB() {
        Id accId = selectAccount().Id;
        Opportunity opp = selectOpportunity(OPP_NAME);
        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'submit engage voice';
        requestParams.isEngageVoice = true;
        requestParams.targetId = opp.Id;
        requestParams.isMPUB = true;
        requestParams.isMultiProductTechnicalQuote = true;
        requestParams.accountId = accId;

        String endpoint = '/v3.0/ccb/engage-voice/sign-up/opportunity/' + opp.Id;
        setAppropriateMock(ENGAGE_VOICE_SUBMIT_RESPONSE_BODY, endpoint, HttpHelper.METHOD_POST);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Account updatedAcc = selectAccount();
        Assert.areEqual('22500000', updatedAcc.EV_Account_ID__c, 'EV Account ID should be updated');
        Assert.areEqual(dataMap.get('status'), ICBAPI.STATUS_SUBMITTED, 'Status should be submitted');
    }

    @isTest
    static void testSubmitEngageDigitalMP() {
        Id accId = selectAccount().Id;
        Opportunity opp = selectOpportunity(OPP_NAME);
        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'submit engage digital';
        requestParams.isEngageVoice = false;
        requestParams.targetId = opp.Id;
        requestParams.isMPUB = false;
        requestParams.accountId = accId;

        String endpoint = '/v2.0/ccb/engage-digital/sign-up/opportunity/' + opp.Id;
        setAppropriateMock(ENGAGE_DIGITAL_SUBMIT_RESPONSE_BODY, endpoint, HttpHelper.METHOD_POST);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Account updatedAcc = selectAccount();
        Assert.areEqual('12344321', updatedAcc.ED_Account_ID__c, 'ED Account ID should be updated');
        Assert.areEqual('2907704002', updatedAcc.Billing_ID__c, 'Account Billing_ID__c field should be updated');
        Assert.areEqual('7282', updatedAcc.RC_Engage_Account_ID__c, 'Account RC_Engage_Account_ID__c field should be updated');
        Assert.areEqual(ICBAPI.STATUS_SUBMITTED, dataMap.get('status'), 'Status should be submitted');
    }

    @isTest
    static void testSubmitPatchContactCenterMPUB() {
        Opportunity opp = selectOpportunity(OPP_NAME);

        BillingWrappers.AccountParams accParams =  new BillingWrappers.AccountParams();
        accParams.timeZoneId = 'GMT';
        accParams.geoRegionId = '1';
        accParams.nicSegmentId = '1-50 Seats';
        accParams.implementationTeamId = '1';
        accParams.contactCenterNumber = '123';

        BillingWrappers.SubmitWrapper wrapper = new BillingWrappers.SubmitWrapper();
        wrapper.accountParams = accParams;

        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'submit contact center';
        requestParams.isChangeOrder = false;
        requestParams.targetId = opp.Id;
        requestParams.isMPUB = true;
        requestParams.data = wrapper;

        String endpoint = '/v2/sfdc/sign-up/case' + ICBAPI.OPP_ID_PARAM + opp.Id;
        setAppropriateMock(SUBMIT_CONTACT_CENTER_PATCH_RESPONSE_BODY, endpoint, HttpHelper.METHOD_PATCH);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Case caseObj = (Case) new ListOptional(new CaseSelector()
                .selectCases()
                .setCondition('CaseNumber = :bind0')
                .setQueryBindings(new List<Object> {dataMap.get('caseNumber')})
                .executeQuery()
            ).getFirst();

        Assert.areEqual(ICBAPI.STATUS_SUBMITTED, dataMap.get('status'), 'Status should be submitted');
        Assert.isNotNull(caseObj, 'Case should be created');
    }

    @isTest
    static void testSubmitPostContactCenterMP() {
        Id accId = selectAccount().Id;
        Opportunity opp = selectOpportunity(OPP_NAME);

        Triggers.switchOff();
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Name => 'Test Quote'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Case.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Opportunity_Reference__c => opp.Id,
                Case.Provision_Date__c => System.today().addDays(1),
                Case.inContact_BU_ID__c => 10,
                Case.inContact_Cluster__c => 'test claster',
                Case.RecordTypeId=> CaseHelper.RT_ID_INCONTACT_ORDER,
                Case.Description => 'Test Case Description'
            })
            .create();
        Triggers.switchOn();

        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'submit post contact center';
        requestParams.isChangeOrder = false;
        requestParams.targetId = opp.Id;
        requestParams.quoteId = qt.Id;
        requestParams.isMPUB = false;
        requestParams.data = new BillingWrappers.SubmitWrapper();

        String endpoint = '/v1/sfdc/sign-up/case' + ICBAPI.OPP_ID_PARAM + opp.Id;
        setAppropriateMock(SUBMIT_CONTACT_CENTER_POST_RESPONSE_BODY, endpoint, HttpHelper.METHOD_POST);

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Opportunity updatedOpp = selectOpportunity(OPP_NAME);

        Assert.areEqual(ICBAPI.STATUS_SUBMITTED, dataMap.get('status'), 'Status should be submitted');
        Assert.isTrue(updatedOpp.isSyncedToICB__c, 'Opportunity should be synced to ICB');
    }

    @isTest
    static void testHandleSubmitWithError() {
        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.action = 'error';

        Test.startTest();
            String resp = ProcessOrder.handleSubmit(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Assert.areEqual(ProcessOrder.ERROR_ACTION, dataMap.get('error'), 'Incorrect action was passed inside handleSubmit() method');
    }

    @isTest
    static void testHandleQueryDataActionWithFakeIds() {
        Id quoteId = (Id) ValueProviderBuilder.provideDummyId(Quote.SObjectType, 15).getValue();

        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.QUERY_DATA;
        requestParams.targetIds = new List<String> {quoteId};

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        List<Object> services = (List<Object>) dataMap.get('services');

        Assert.isTrue(services.isEmpty(), 'There should be no services');
    }

    @isTest
    static void testHandleQueryDataActionWithEmptyIds() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.QUERY_DATA;
        requestParams.targetIds = new List<String>();

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        List<Object> services = (List<Object>) dataMap.get('services');

        Assert.isTrue(services.isEmpty(), 'There should be no services');
    }

    @isTest
    static void testHandleIncorrectAction() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.ERROR;

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Assert.areEqual(ProcessOrder.ERROR_ACTION, dataMap.get('error'), 'Incorrect action was passed inside handleSignUp() method');
    }

    @isTest
    static void testHandleValidateDataWithEmptyData() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.VALIDATE_DATA;
        requestParams.dataArr = new List<POWrappers.SignUpParams>();

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        List<Object> messages = (List<Object>) responseBodyMap.get('messages');
        Map<String, Object> message = (Map<String, Object>) messages[0];

        Assert.areEqual(1, messages.size(), 'There should be 1 error message');
        Assert.areEqual(ProcessOrderValidator.ERROR_MESSAGE, message.get('messageDetails'), 'The message details should contain the same text as the label');
    }

    @isTest
    static void testHandleValidateDataAction() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.opportunity = new Opportunity();
        signUpParams.opportunity.Account = new Account();
        signUpParams.approvals = new List<Approval__c>();
        signUpParams.accRelations = new List<AccountRelation__c>();
        signUpParams.promotions = new List<Promotion__c>();
        signUpParams.boundAccs = new List<Account>();
        signUpParams.isProServQuotesNotCancelled = false;
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoNoBI()
            })
            .build()
            .getRecord();

        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.VALIDATE_DATA;
        requestParams.dataArr = new List<POWrappers.SignUpParams> {signUpParams};

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        List<Object> messages = (List<Object>) responseBodyMap.get('messages');
        Map<String, Object> message = (Map<String, Object>) messages[0];

        Assert.areEqual(1, messages.size(), 'There should be 1 error message');
        Assert.areEqual(Label.QW_Notification_Empty_Cart_help_text, message.get('messageDetails'), 'The message details should contain the same text as the label');
    }

    @isTest
    static void testHandlePresignUpActionsWithEmptyData() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.EXECUTE_PRESIGNUP_ACTIONS;
        requestParams.dataArr = new List<POWrappers.SignUpParams>();

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');
        List<Object> updatedData = (List<Object>) dataMap.get('updatedData');

        Assert.isTrue(updatedData.isEmpty(), 'There should be no updated data');
    }

    //TODO: we should base it on quote.service_name in MPUB instead opty.tier_name
    @isTest
    static void testHandleValidateProcessOrderAction() {
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        Opportunity opp = selectOpportunity(OPP_NAME);
        signUpParams.opportunity = opp;

        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo(),
                Quote.BusinessIdentity__c => '{"currency":"USD","biId":"62005"}'
            })
            .build()
            .getRecord();

        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.VALIDATE_PROCESS_ORDER;
        requestParams.data = signUpParams;

        Test.startTest();
            String resp = ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(resp);
        Map<String, Object> dataMap = (Map<String, Object>) responseBodyMap.get('data');

        Assert.isTrue(dataMap.isEmpty(), 'Data should be empty');
    }

    @isTest
    static void testHandleSignUpWithEmptyData() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.SIGNUP;

        Test.startTest();
            try {
                ProcessOrder.handleSignUp(JSON.serialize(requestParams));
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.areEqual(QuoteHelper.CAN_NOT_PACKAGE_INFO_ERROR, ex.getMessage(), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testHandleBodyPreviewWithEmptyData() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.BODY_PREVIEW;

        Test.startTest();
        try {
            ProcessOrder.handleSignUp(JSON.serialize(requestParams));
            Assert.fail('Exception should be thrown');
        } catch (Exception ex) {
            Assert.areEqual(QuoteHelper.CAN_NOT_PACKAGE_INFO_ERROR, ex.getMessage(), 'Exception message should be the same');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateOrdersForProServ() {
        Triggers.switchOff();
        Account acc = selectAccount();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => acc.Id,
                Opportunity.Tier_Name__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo(),
                Quote.Signed_SOW__c => 'test SOW'
            })
            .create()
            .getRecord();

        opp.PrimaryQuote__c = masterQuote.Id;
        update opp;

        Quote technicalQuoteWithNewService = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test Quote New Service',
                Quote.OpportunityId => opp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoProServ(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => technicalQuoteWithNewService.Id,
                ServiceInfo__c.IsProcessOrderSent__c => false
            })
            .create();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test product',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RC_CONTACT_CENTER,
                Product2.IsActive => true,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.InitialOrderType__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                        'manual',
                        'testUpsellType',
                        null
                    }
                )
            })
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(prodList),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(4)
            .create()
            .getRecords();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => technicalQuoteWithNewService.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(prodList),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => true,
                QuoteLineItem.DeliveredQuantity__c => 3
            })
            .quantity(4)
            .create();
        Triggers.switchOn();

        Test.startTest();
            List<String> targetIds = new List<String> { 
                String.valueOf(technicalQuoteWithNewService.Id)
            };
            ProcessOrder.createOrders(opp.Id, targetIds);
        Test.stopTest();

        Order reselectedOrder = (Order) new ListOptional(
           new OrderSelector()
               .selectOrders()
               .selectFields(new List<SObjectField> {Order.Id, Order.RecordTypeId, Order.Signed_SOW__c})
               .executeQuery()
           )
           .getFirst();

        Assert.areEqual(true, reselectedOrder != null, 'reselectedOrder should not be null');
        Assert.areEqual(OrderHelper.RT_ID_PROSERV, reselectedOrder.RecordTypeId, 'record type of reselectedOrder should be Professional Services');
        Assert.areEqual(masterQuote.Signed_SOW__c, reselectedOrder.Signed_SOW__c, 'Signed_SOW__c should be copied from Master Quote');
    }

    @IsTest
    static void testHandleSignUpCreateDealDeskCaseDescriptions() {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getInstance();
        featureToggle.Shipping_Tab_New_Business__c = true;
        upsert featureToggle;

        LicensesLabelsOverride__c licensesLabelsOverride = (LicensesLabelsOverride__c) new SObjectBuilder(LicensesLabelsOverride__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                LicensesLabelsOverride__c.Name => 'Amazon US Initial Order Type',
                LicensesLabelsOverride__c.BusinessIdentityId__c => '62005',
                LicensesLabelsOverride__c.Label__c => 'initialOrderType'
        })
            .create()
            .getRecord();

        DealDeskCaseDescriptionHelper.templatesMetadata = new SObjectBuilder(NGBSProcessOrderCaseTemplate__mdt.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                NGBSProcessOrderCaseTemplate__mdt.Id => ValueProviderBuilder.provideDummyId(NGBSProcessOrderCaseTemplate__mdt.SObjectType),
                NGBSProcessOrderCaseTemplate__mdt.IsActive__c => true,
                NGBSProcessOrderCaseTemplate__mdt.Type__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.ShippingReq__c => Product2Helper.SHIPPING_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL,
                NGBSProcessOrderCaseTemplate__mdt.LicenceIdOrCategoryCode__c => 'L1',
                NGBSProcessOrderCaseTemplate__mdt.Subject__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
                }),
                NGBSProcessOrderCaseTemplate__mdt.Owner__c => ValueProviderBuilder.provideList(new List<String>{
                    UserInfo.getUserId(),
                    '005_who_pretends_to_be_a_user_id'
                }),
                NGBSProcessOrderCaseTemplate__mdt.Description__c => ValueProviderBuilder.provideUniqueString('Test Template')
            })
            .quantity(2)
            .build()
            .getRecords();

        DealDeskCaseDescriptionHelper.initializeTemplatesMap();

        new SObjectBuilder(CaseDescriptionTemplate__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CaseDescriptionTemplate__c.Name => ValueProviderBuilder.provideUniqueString('Setting Name'),
                CaseDescriptionTemplate__c.Active__c => true,
                CaseDescriptionTemplate__c.Type__c => ValueProviderBuilder.provideList(new List<String>{
                    DealDeskCaseDescriptionHelper.SHIPPING_CASE_TEMPLATE_TYPE,
                    DealDeskCaseDescriptionHelper.INITIAL_ORDER_CASE_TEMPLATE_TYPE
                }),
                CaseDescriptionTemplate__c.LicensesCatalogId__c => 'L1',
                CaseDescriptionTemplate__c.DescriptionTemplate__c => 'Test Template'
            })
            .quantity(2)
            .create();

        Account acc = (Account) new AccountSelector()
            .selectAccounts()
            .executeQuery()
            .get(0);

        Opportunity opp = (Opportunity) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery()
            .get(0);

        Triggers.SwitchOff();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Test product',
                Product2.IsActive => true,
                Product2.ExtID__c => 'L1',
                Product2.InitialOrderType__c => Product2Helper.ORDER_TYPE_MANUAL,
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_MANUAL
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Account__c => acc.Id,
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo(),
                Quote.BusinessIdentity__c => '{"currency":"USD","biId":"62005"}'
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.Quantity => -11,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.UnitPrice => pbe.UnitPrice,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => '{"Version":"1","q":null,"Price":null,"parent":null,"lbox":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Money"},"categoryPath":"ATN","categoryCode":"ATN"}',
                QuoteLineItem.Display_Name__c => 'Additional Toll-Free Number'
            })
            .create()
            .getRecord();

        Triggers.SwitchOn();

        qt = (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByQuoteId(qt.Id)
            .executeQuery()
            .get(0);

        POWrappers.SignUpParams data = new POWrappers.SignUpParams();
        data.targetQuote = qt;

        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.CREATE_DEAL_DESK_CASE_DESCRIPTION;
        requestParams.dataArr = new List<POWrappers.SignUpParams>{data};

        Test.startTest();
        ProcessOrder.handleSignUp(JSON.serialize(requestParams));

        List<DealDeskCaseDescription__c> dealDeskCaseDescriptions = (List<DealDeskCaseDescription__c>) new DealDeskCaseDescriptionSelector()
            .selectDealDeskCaseDescriptionsForAccounts(new List<Object> {new Set<Id> {acc.Id}})
            .executeQuery();
        Test.stopTest();

        Assert.areEqual(2, dealDeskCaseDescriptions.size(),
            'ProcessOrder.handleSignUp() should create two DealDeskCaseDescription__c records');
    }

    @IsTest
    private static void testCheckIsMainCostCenterExist() {
        NGBS_Settings__c settings = NGBS_Settings__c.getOrgDefaults();
        settings.BaseEndpoint__c = 'https://testapi';
        settings.AccountManagerPath__c = '/restapi/account-manager/v1.0';
        update settings;
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
            String result = ProcessOrder.checkIsMainCostCenterExist('{"billingId":"123"}');
        Test.stopTest();
        Assert.isTrue(result.contains('"isMainCostCenterExist":true'), 'Main Cost Center should exist');
    }

    @IsTest
    private static void testCreateMainCostCenter() {
        NGBS_Settings__c settings = NGBS_Settings__c.getOrgDefaults();
        settings.BaseEndpoint__c = 'https://testapi';
        settings.AccountManagerPath__c = '/restapi/account-manager/v1.0';
        update settings;
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
        String result = ProcessOrder.createMainCostCenter('{"billingId":"123"}');
        Test.stopTest();
        Assert.isTrue(result.contains('"isMainCostCenterCreated":true'), 'Main Cost Center should be created');
    }

    @isTest
    static void testUpdateProcessOrderCCSyncStatus() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.action = POWrappers.SIGNUP_ACTION.UPDATE_PROCESS_ORDER_CC_SYNC_STATUS;
        requestParams.rcccSyncStatus = IcbHelper.CC_SYNC_STATUS_STARTED;
        requestParams.data = new POWrappers.SignUpParams();
        requestParams.data.opportunity = selectOpportunity(OPP_NAME);

        Test.startTest();
            ProcessOrder.handleSignUp(JSON.serialize(requestParams));
        Test.stopTest();

        Opportunity resultOpp = selectOpportunity(OPP_NAME);
        Assert.areEqual(IcbHelper.CC_SYNC_STATUS_STARTED, resultOpp.RCCCSyncStatus__c, 'Process Order Sync Status should be marked as Started');
    }
}