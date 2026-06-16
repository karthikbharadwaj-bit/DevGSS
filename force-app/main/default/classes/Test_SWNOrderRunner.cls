@isTest
private class Test_SWNOrderRunner {
    private static final String OPP_NAME = 'OPP_NAME';
    private static final String NGBS_RESPONSE = '{"invoice": {"id": "12345"}}';
    private static final String NGBS_BILLING_INFO_RESPONSE = '[{"amount":0.08,"catalogId":"LC_DL_75","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Disconnect Scrub, per 10 scrubs","descriptionKey":"E528A917D99E9C0E7976FE2F7301474B"},{"amount":0.03,"catalogId":"LC_DL-UNL_50","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Automated speech recognition, per minute","descriptionKey":"0C87BF8CA6D34E48BBA4228C91DCD275"},{"amount":0.03,"catalogId":"LC_DID_53","discountAmount":0,"qty":3,"billingType":"Recurring","billingCycleDuration":"Monthly","dateRangeStart":"2020-08-09","dateRangeEnd":"2020-09-08","description":"Automated speech recognition, per minute","descriptionKey":"0C87BF8CA6D34E48BBA4228C91DCD275"}]';
    private static final String PACKAGE_INFO = '[{"id":"18","version":"1","packageInfo":{"id":116477002,"catalogId":"18","version":"1","name":"Office Standard 1/2/100/1000+ Lines - 5100/5101/5102/5103","displayName":"RingCentral Office Standard","oldPackageName":"RingCentral Office Standard"},"productName":"Office","productId":"2","duration":"Monthly","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular","poc":null,"globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"RingCentral Inc.","isDefault":true,"id":"4","address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}},"existingPackageInfo":{"id":"18","version":"1","offerType":"Regular","productName":"Office"}}]';
    private static final String PACKAGE_INFO_QLI = '{"Version":"1","q":null,"Price":0,"parent":null,"lboxes":null,"Id":"18","duration":"Monthly","Discount":{"Value":0,"Type":"Percent"},"categoryPath":null,"CategoryCode":"DL"}';
    private static final List<String> CATALOG_IDS = new List<String> {
        'LC_DL_75', 'LC_ALN_38', 'LC_CRF_51', 'LC_HD_139', 'LC_DL_BAS_178', 'LC_DL_UNL_50', 'LC_ATN_39', 'LC_E911_52', 'LC_HD_140', 'LC_EES_489', 'LC_EES_TAM_949', 'LC_SIP3P_941'
    };

    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
    
            res.setStatus('BAD');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));
    
            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';
            String endpoint = req.getEndpoint();

            if (endpoint.contains('billinginfo/summary/license')) {
                body = NGBS_BILLING_INFO_RESPONSE;
            } else {
                body = NGBS_RESPONSE;
            }

            return body;
        }
    }

    private static Quote getQuote() {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(OPP_NAME)
            .selectFields(new List<String> {
                'Opportunity.BusinessIdentity__c',
                'Opportunity.isOrderStepCompleted__c',
                'Opportunity.IsManualProvisionCaseCreated__c'
            })
            .executeQuery()
        ).getFirst();
    }

    private static List<QuoteLineItem> generateQlisToAccessCallOrder() {
        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_AUTO
            })
            .build()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .quantity(1)
            .build()
            .getRecords();

        qlis[0].putSObject(QuoteLineItem.Product2Id, product);
        return qlis;
    }

    static void generateData() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States'
            })
            .create()
            .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.IsTermination__c => false,
                Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                Quote.PackageNameNew__c => 'Test',
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'DigitalLine','Additional Local Number', 'Compliance and Administrative Cost Recovery Fee', 'Polycom VVX501 with 1 Expansion Module', 'DigitalLine Basic', 'DigitalLine Unlimited', 'Additional Toll-Free Number', 'e911 Service Fee', 'Polycom VVX501 with 1 Expansion Module', 'Extended Enterprise Support - Platinum Tier - Office', 'Extended Enterprise Support - Platinum Tier - Office - Additional TAM', 'SIP Connection to 3rd Party Provider'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(CATALOG_IDS),
                Product2.Charge_Term__c => ValueProviderBuilder.provideList(new List<String> {Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_ONE_TIME, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY, Product2Helper.CHARGE_TERM_MONTHLY}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String> {Product2Helper.FAMILY_TECHNICAL_LICENSE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null, Product2Helper.FAMILY_SERVICE, Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_DISCOUNTED_PHONES, null, null, null}),
                Product2.IsActive => true,
                Product2.ShippingType__c => ValueProviderBuilder.provideList(new List<String> {'', '', '', '', '', '', '', '', Product2Helper.SHIPPING_TYPE_MANUAL, '', '', ''})
            })
            .quantity(12)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(11)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id> {products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id, products[8].Id, products[9].Id, products[10].Id, products[11].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {1,3,20}),
                Entitlement__c.Product__c => ValueProviderBuilder.provideList(new List<Id> {products[9].Id, products[10].Id, products[11].Id})
            })
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id> {products[0].Id, products[1].Id, products[2].Id, products[3].Id, products[4].Id, products[5].Id, products[6].Id, products[7].Id, products[8].Id, products[9].Id, products[10].Id, products[11].Id}),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {10,10,10,10,10,10,10,10,10,1,1,1}),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(new List<Integer> {10,10,10,10,10,10,10,10,10,1,1,1}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id, pbe[2].Id, pbe[3].Id, pbe[4].Id, pbe[5].Id, pbe[6].Id, pbe[7].Id, pbe[8].Id, pbe[9].Id, pbe[10].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .quantity(12)
            .create()
            .getRecords();

        new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .create();
        Triggers.switchOn();
    }

    @TestSetup
    static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://185.23.251.118:8080',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => 'login',
                NGBS_Settings__c.Password__c => 'password'
            })
            .create();

        new SObjectBuilder(NGBS_Order_API_Settings__c.SObjectType)
            .setField(NGBS_Order_API_Settings__c.Batch_False_Licenses_Codes__c, 'GLP;LR;ICI;RCRM;RCON;NM;MS;EES;CC;CCES;ATN')
            .create();

        generateData();
    }

    @isTest
    static void testIsOrderingAvailable() {
        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('PROD'),
                Product2.IsActive => true,
                Product2.Id => new ValueProvider.DummyIdProvider(Product2.sObjectType),
                Product2.Family => ValueProviderBuilder.provideUniqueString('PFAMILY'),
                Product2.UpsellType__c => Product2Helper.ORDER_TYPE_AUTO,
                Product2.ProductCode => ValueProviderBuilder.provideUniqueString('PCODE')
            })
            .build()
            .getRecord();

        PricebookEntry priceBook = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.Id => new ValueProvider.DummyIdProvider(PricebookEntry.sObjectType),
                PricebookEntry.IsActive => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => priceBook.Id,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .build()
            .getRecord();
        qli.putSObject(QuoteLineItem.Product2Id, product);
        qli.putSObject(QuoteLineItem.PriceBookEntryId, priceBook);

        Test.startTest();
            SWNOrderRunner runner = new SWNOrderRunner();
            Boolean resultPositive = runner.isOrderingAvailable(qli, null);
            Boolean resultNegative = runner.isOrderingAvailable(null, null);
        Test.stopTest();

        Assert.isTrue(resultPositive, 'Ordering should be available');
        Assert.isFalse(resultNegative, 'Ordering should not be available');
    }

    @isTest
    static void testGetLBOBillingExceptionsWithLabels() {
        String testBI = '{"currency":"USD","biId":"4"}';
        String categoryCode1 = 'test_category_code_1';
        String categoryCode2 = 'test_category_code_2';
        String categoryCode3 = 'test_category_code_3';

        new SObjectBuilder(NGBSLBOBillingLimits__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBSLBOBillingLimits__c.Name => 'test_1',
                NGBSLBOBillingLimits__c.Categories__c => categoryCode2,
                NGBSLBOBillingLimits__c.Quantity__c => 0,
                NGBSLBOBillingLimits__c.Manual_Upsell__c => true,
                NGBSLBOBillingLimits__c.Only_LBO__c => true
            })
            .create();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('test_product'),
                Product2.UpsellType__c => ValueProviderBuilder.provideList(new List<String> {
                    'autoWithCase', 
                    null, 
                    'manual'
                })
            })
            .quantity(3)
            .build()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.PackageInfo__c, ValueProviderBuilder.provideList(new List<String> {
                '{"categoryCode":"' + categoryCode1 + '"}',
                '{"categoryCode":"' + categoryCode2 + '"}',
                '{"categoryCode":"' + categoryCode3 + '"}'
            }))
            .quantity(3)
            .build()
            .getRecords();

        List<QuoteLineItem> testQuoteLineItems = new List<QuoteLineItem>();
        for (Integer i = 0; i < qlis.size(); i++) {
            QuoteLineItem qli = qlis.get(i);
            qli.putSObject(QuoteLineItem.Product2Id, products.get(i));
            testQuoteLineItems.add((QuoteLineItem) Test_Utils.putIntoUnwritableField(qli, QuoteLineItem.class, 'Product_Lic_Id__c', 'LC_' + (i + 1)));
        }

        Test.startTest();
            Map<String, String> result = new SWNOrderRunner().getLBOBillingExceptionsWithLabels(testBI, testQuoteLineItems, new List<String>());
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'There should be 2 records in the result map');
        Assert.isTrue(result.containsKey('LC_2'), 'The map should contain LC_2');
        Assert.isTrue(result.containsKey('LC_3'), 'The map should contain LC_3');
    }

    @isTest
    static void testHasAccessToCallOrder() {
        List<QuoteLineItem> qlis = generateQlisToAccessCallOrder();

        Test.startTest();
            SWNOrderRunner runner = new SWNOrderRunner();
            Boolean resultPositive = runner.hasAccessToCallOrder(qlis);
        Test.stopTest();

        Assert.isTrue(resultPositive, 'Access should be granted');
    }

    @isTest
    static void testCollectQliIds() {
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Id, new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType))
            .quantity(1)
            .build()
            .getRecords();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.IsTermination__c => true,
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .build()
            .getRecord();

        testQuote = (Quote) Test_Utils.putIntoUnwritableField(
            testQuote,
            Quote.class,
            'QuoteLineItems',
            qlis
        );

        Test.startTest();
            SWNOrderRunner runner = new SWNOrderRunner();
            Set<Id> resultNegative = runner.collectQliIds(testQuote);

            testQuote.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
            Set<Id> resultPositive = runner.collectQliIds(testQuote);
        Test.stopTest();

        Assert.areEqual(0, resultNegative.size(), 'Should be empty list of id');
        Assert.areEqual(1, resultPositive.size(), '1 qli should be return');
    }

    @isTest
    static void testGetNGBSOrderInfo() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = getQuote();

        Test.startTest();
            SWNOrderRunner runner = new SWNOrderRunner();
            NGBSOrderRequest.OrderRequestInfo result = runner.getNGBSOrderInfo(sdc);
        Test.stopTest();

        Assert.isNotNull(result.salesOrderId, 'salesOrderId should be defined');
    }

    static void testValidateCallOrderAPINoShippingPermission() {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = getQuote();
        SWNOrderRunner runner = new SWNOrderRunner();
        runner.sdc = sdc;
        sdc.qt = (Quote) Test_Utils.putIntoUnwritableField(
            sdc.qt,
            Quote.class,
            'QuoteLineItems',
            generateQlisToAccessCallOrder()
        );

        Test.startTest();
            NGBSOrderRequest.OrderRequestInfo result = runner.validateCallOrderAPI(sdc);
        Test.stopTest();
        Assert.isNull(result, 'OrderRequestInfo should be null');
        Assert.areEqual(CaseHelper.CASE_REASON_PERMISSION, runner.res.messages[0].message, 'Wrong error message');
    }

    @isTest
    static void testValidateCallOrderAPIQuoteAlreadySynced() {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = getQuote();
        SWNOrderRunner runner = new SWNOrderRunner();
        runner.sdc = sdc;
        Triggers.switchOff();
        update new Quote(Id = sdc.qt.Id, InvoiceId__c = 'Test Id');
        Triggers.switchOn();

        Test.startTest();
            NGBSOrderRequest.OrderRequestInfo result = runner.validateCallOrderAPI(sdc);
        Test.stopTest();

        Assert.isNull(result, 'OrderRequestInfo should be null');
        Assert.areEqual(SWNOrderRunner.QUOTE_ALREADY_SYNCED, runner.res.messages[0].message, 'Wrong error message');
    }

    @isTest
    static void testHandleResponseSuccess() {
        SWNOrderRunner runner = new SWNOrderRunner();
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(NGBS_RESPONSE);

        Test.startTest();
            runner.handleResponse(response);
        Test.stopTest();
        
        Assert.areEqual('12345', runner.res.getData(SWNOrderRunner.ORDERS), 'The order ID should be set correctly.');
    }
    
    @isTest
    static void testHandleResponseError() {
        SWNOrderRunner runner = new SWNOrderRunner();
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500); 
        
        Test.startTest();
            runner.handleResponse(response);
        Test.stopTest();
        
        Assert.areEqual(SWNOrderRunner.ERROR_DURING_ORDER_SYNC, runner.res.messages[0].message, 'The error message should be set correctly.');
    }

    @isTest
    static void testCallOrderAPI() {
        Test.setMock(HttpCalloutMock.class, new Mock());

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = getQuote();
        SWNOrderRunner runner = new SWNOrderRunner();
        runner.sdc = sdc;

        Test.startTest();
            runner.callOrderAPI(sdc);
        Test.stopTest();

        Assert.areEqual('12345', runner.res.getData(SWNOrderRunner.ORDERS), 'The order ID should be set correctly.');
    }

    @isTest
    static void testSyncOrderWhenLBOIsDisabled() {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = new Quote();
        sdc.qt.Enabled_LBO__c = false;
        sdc.qt.ServiceName__c = 'test';
        sdc.qt.IsMultiProductTechnicalQuote__c = true;
        sdc.qt.package_info__c= NGBSTestDataGenerator.generateQuotePackageInfo();
        SWNOrderRunner runner = new SWNOrderRunner();
        runner.sdc = sdc;

        Test.startTest();
            runner.syncOrder();
        Test.stopTest();

        Assert.isFalse(runner.isSkipFinalize, 'isSkipFinalize should be false when LBO is disabled');
    }

    @isTest
    static void testSyncOrderWhenInvoiceIdIsNotNull() {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(new Opportunity(isOrderStepCompleted__c = false));
        sdc.qt = new Quote(InvoiceId__c = 'Test Id', Enabled_LBO__c = true);
        SWNOrderRunner runner = new SWNOrderRunner();
        runner.sdc = sdc;

        Test.startTest();
            runner.syncOrder();
        Test.stopTest();

        Assert.isTrue(runner.isSkipFinalize, 'isSkipFinalize should be true when InvoiceId is not null');
    }

    @isTest
    static void testSyncOrderSuccessful() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Quote qt = getQuote();
        SWNOrderRunner runner = new SWNOrderRunner(qt.Id, SWNStep.ORDER);
        runner.sdc.qt = qt;
        runner.sdc.currentStep = SWNStep.buildOrderSyncStep();

        Test.startTest();
            runner.syncOrder();
        Test.stopTest();

        Assert.isFalse(runner.isSkipFinalize, 'isSkipFinalize should be false on successful sync');
        Assert.isNotNull(runner.sdc.syncable.getSObjFieldsToUpdate().get(Opportunity.OrderDate__c), 'Order date should be set');
        Assert.areEqual('12345', runner.res.getData(SWNOrderRunner.ORDERS), 'The order ID should be set correctly.');
        Assert.areEqual('12345', runner.sdc.currentStep.quoteFieldsToUpdate.get(Quote.InvoiceId__c.toString()), 'The InvoiceId__c should be set correctly.');
    }
}