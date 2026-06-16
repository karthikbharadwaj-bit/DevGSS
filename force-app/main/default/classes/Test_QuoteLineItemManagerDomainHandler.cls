@IsTest
private class Test_QuoteLineItemManagerDomainHandler {

    // Mock handler for testing invocation
    private class MockResourceHandler implements IResourceHandler {
        public Boolean wasExecuted = false;
        public ApiRequest receivedRequest;

        public ApiResponse execute(ApiRequest request) {
            wasExecuted = true;
            receivedRequest = request;
            return ApiResponse.success(new Map<String, String>{'result' => 'mock executed'});
        }
    }

    @IsTest
    static void testConstructorRegistration_QuoteLineItems() {
        Test.startTest();
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();
        Test.stopTest();

        Map<String, Map<String, Map<String, Type>>> resourceHandlers = handler.resourceHandlers;
        System.assert(resourceHandlers.containsKey('v1'), 'v1 version should be registered');
        Map<String, Map<String, Type>> v1Resources = resourceHandlers.get('v1');
        System.assert(v1Resources.containsKey('quote-line-items'), 'quote-line-items resource should be registered');
        System.assertEquals(
            QuoteLineItemUpsertHandler.class,
            v1Resources.get('quote-line-items').get('POST'),
            'QuoteLineItemUpsertHandler should be registered for POST quote-line-items'
        );
    }

    @IsTest
    static void testConstructorRegistration_QuoteLineItemsMissingBulk() {
        Test.startTest();
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();
        Test.stopTest();

        Map<String, Map<String, Map<String, Type>>> resourceHandlers = handler.resourceHandlers;
        System.assert(resourceHandlers.containsKey('v1'), 'v1 version should be registered');
        Map<String, Map<String, Type>> v1Resources = resourceHandlers.get('v1');
        System.assert(v1Resources.containsKey('quote-line-items/missing/bulk'), 'quote-line-items/missing/bulk resource should be registered');
        System.assertEquals(
            QuoteLineItemManagerDomainHandler.QuoteLineItemRemoveMissingHandler.class,
            v1Resources.get('quote-line-items/missing/bulk').get('POST'),
            'QuoteLineItemRemoveMissingHandler should be registered for POST quote-line-items/missing/bulk'
        );
    }

    @IsTest
    static void testConstructorRegistration_Promotions() {
        Test.startTest();
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();
        Test.stopTest();

        Map<String, Map<String, Map<String, Type>>> resourceHandlers = handler.resourceHandlers;
        System.assert(resourceHandlers.containsKey('v1'), 'v1 version should be registered');
        Map<String, Map<String, Type>> v1Resources = resourceHandlers.get('v1');
        System.assert(v1Resources.containsKey('promotions'), 'promotions resource should be registered');
        System.assertEquals(
            PromotionSyncHandler.class,
            v1Resources.get('promotions').get('POST'),
            'PromotionSyncHandler should be registered for POST promotions'
        );
    }

    @IsTest
    static void testConstructorRegistration_AreaCodes() {
        Test.startTest();
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();
        Test.stopTest();

        Map<String, Map<String, Map<String, Type>>> resourceHandlers = handler.resourceHandlers;
        System.assert(resourceHandlers.containsKey('v1'), 'v1 version should be registered');
        Map<String, Map<String, Type>> v1Resources = resourceHandlers.get('v1');
        System.assert(v1Resources.containsKey('area-codes'), 'area-codes resource should be registered');
        System.assertEquals(
            SyncAreaCodesHandler.class,
            v1Resources.get('area-codes').get('POST'),
            'SyncAreaCodesHandler should be registered for POST area-codes'
        );
    }

    @IsTest
    static void testConstructorRegistration_AssignmentLineItems() {
        Test.startTest();
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();
        Test.stopTest();

        Map<String, Map<String, Map<String, Type>>> resourceHandlers = handler.resourceHandlers;
        System.assert(resourceHandlers.containsKey('v1'), 'v1 version should be registered');
        Map<String, Map<String, Type>> v1Resources = resourceHandlers.get('v1');
        System.assert(v1Resources.containsKey('assignment-line-items'), 'assignment-line-items resource should be registered');
        System.assertEquals(
            SyncAssignmentLineItemsHandler.class,
            v1Resources.get('assignment-line-items').get('POST'),
            'SyncAssignmentLineItemsHandler should be registered for POST assignment-line-items'
        );
    }

    @IsTest
    static void testFindHandlerSuccess() {
        // Given
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();

        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = 'quote-line-items';
        request.httpMethod = 'POST';

        Test.startTest();

        // When
        Type foundHandler = handler.findHandler(request);

        Test.stopTest();

        // Then
        System.assertEquals(QuoteLineItemUpsertHandler.class, foundHandler,
                           'Should find QuoteLineItemUpsertHandler for v1/quote-line-items POST');
    }

    @IsTest
    static void testFindHandlerError_InvalidVersion() {
        // Given
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();

        ApiRequest request = new ApiRequest();
        request.version = 'v2';
        request.resourcePath = 'quote-line-items';
        request.httpMethod = 'POST';

        Test.startTest();

        // When & Then
        try {
            handler.findHandler(request);
            System.assert(false, 'Should throw ApiVersionException');
        } catch (ApiGateway.ApiVersionException e) {
            System.assert(e.getMessage().contains('Version not found: v2'), 'Should have correct error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testFindHandlerError_InvalidResource() {
        // Given
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();

        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = 'invalid-resource';
        request.httpMethod = 'POST';

        Test.startTest();

        // When & Then
        try {
            handler.findHandler(request);
            System.assert(false, 'Should throw ApiResourceNotFoundException');
        } catch (ApiGateway.ApiResourceNotFoundException e) {
            System.assert(e.getMessage().contains('Resource not found: invalid-resource'), 'Should have correct error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testFindHandlerError_InvalidMethod() {
        // Given
        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();

        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = 'quote-line-items';
        request.httpMethod = 'DELETE';

        Test.startTest();

        // When & Then
        try {
            handler.findHandler(request);
            System.assert(false, 'Should throw ApiMethodNotAllowedException');
        } catch (ApiGateway.ApiMethodNotAllowedException e) {
            System.assert(e.getMessage().contains('Method not allowed: DELETE'), 'Should have correct error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testHandleRequestSuccess_QuoteLineItemRemoveMissing() {
        // Given - Create test data: 2 quotes, 1 QLI for first quote, 2 QLIs for second quote

        Triggers.switchOff();

        // Create test account
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        // Create test opportunity
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => Date.today().addDays(30)
            })
            .create()
            .getRecord();

        // Create two test quotes
        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Test Quote 1',
                    'Test Quote 2'
                }),
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
            })
            .quantity(2)
            .create()
            .getRecords();

        // Create test products with ExtID__c values
        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Test Product 1',
                    'Test Product 2',
                    'Test Product 3'
                }),
                Product2.IsActive => true,
                Product2.Family => 'Test Family',
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {
                    'CATALOG_001',
                    'CATALOG_002',
                    'CATALOG_003'
                })
            })
            .quantity(3)
            .create()
            .getRecords();

        // Create pricebook entries for each product
        List<PricebookEntry> pricebookEntries = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<String> {
                    testProducts[0].Id,
                    testProducts[1].Id,
                    testProducts[2].Id
                }),
                PricebookEntry.IsActive => true
            })
            .quantity(3)
            .create()
            .getRecords();

        // Create test quote line items: 1 for first quote, 2 for second quote
        List<QuoteLineItem> testQLIs = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<String> {
                    testQuotes[0].Id,
                    testQuotes[1].Id,
                    testQuotes[1].Id
                }),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<String> {
                    pricebookEntries[0].Id,
                    pricebookEntries[1].Id,
                    pricebookEntries[2].Id
                }),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer> {1, 2, 3}),
                QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Integer> {100, 150, 200})
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.switchOn();

        // Create request body - keep only CATALOG_001 for first quote and CATALOG_002 for second quote
        // This will remove 0 QLIs from first quote and 1 QLI (CATALOG_003) from second quote
        Map<Id, Set<String>> quoteIdToCatalogIds = new Map<Id, Set<String>>{
            testQuotes[0].Id => new Set<String>{'CATALOG_001'},
            testQuotes[1].Id => new Set<String>{'CATALOG_002'}
        };

        QuoteLineItemManagerDomainHandler handler = new QuoteLineItemManagerDomainHandler();

        ApiRequest request = new ApiRequest();
        request.version = 'v1';
        request.resourcePath = 'quote-line-items/missing/bulk';
        request.httpMethod = 'POST';
        request.requestBody = JSON.serialize(quoteIdToCatalogIds);

        Test.startTest();

        // When
        ApiResponse response = handler.handleRequest(request);

        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Should return success status code');

        // Verify response structure
        Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('success', responseData.get('status'), 'Response should indicate success');
        System.assert(responseData.containsKey('data'), 'Response should contain data field');

        Map<String, Object> data = (Map<String, Object>)responseData.get('data');
        List<Object> removedQLIs = (List<Object>)data.get('qlisToRemove');
        System.assertEquals(1, removedQLIs.size(), 'Should remove 1 quote line item (CATALOG_003)');

        // Verify database state: first quote should have 1 QLI, second quote should have 1 QLI
        List<QuoteLineItem> firstQuoteQLIs = [SELECT Product_Lic_Id__c FROM QuoteLineItem WHERE QuoteId = :testQuotes[0].Id];
        System.assertEquals(1, firstQuoteQLIs.size(), 'First quote should have 1 remaining QLI');
        System.assertEquals('CATALOG_001', firstQuoteQLIs[0].Product_Lic_Id__c, 'First quote should keep CATALOG_001');

        List<QuoteLineItem> secondQuoteQLIs = [SELECT Product_Lic_Id__c FROM QuoteLineItem WHERE QuoteId = :testQuotes[1].Id];
        System.assertEquals(1, secondQuoteQLIs.size(), 'Second quote should have 1 remaining QLI');
        System.assertEquals('CATALOG_002', secondQuoteQLIs[0].Product_Lic_Id__c, 'Second quote should keep CATALOG_002');
    }

}