/**
 * Test class for QuoteLineItemUpsertHandler
 * Tests upserting quote line items for master and technical quotes
 */
@isTest
private class Test_QuoteLineItemUpsertHandler {

    /**
     * Test empty scenario - validates error handling when no quote IDs are provided
     */
    @isTest
    static void testEmptyScenario() {
        // Arrange
        ApiRequest request = new ApiRequest();
        request.requestBody = '{}';

        QuoteLineItemUpsertHandler handler = new QuoteLineItemUpsertHandler();

        // Act
        Test.startTest();
        ApiResponse response = handler.execute(request);
        Test.stopTest();

        // Assert
        System.assertEquals(400, response.statusCode, 'Expected error status code for empty request');
        System.assert(response.responseBody.contains('QuoteIdToCartItems cannot be null or empty'),
            'Expected error message about empty input');
    }

    /**
     * Test scenario with 1 master quote and 2 technical quotes
     * Validates that master QLI is created and technical QLIs reference it via MasterQLI__c
     */
    @isTest
    static void testMasterAndTechnicalQuotes() {
        // Arrange - Create test data
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpportunity = TestDataGenerator.createOpportunity(testAccount);

        // Create master quote
        Quote masterQuote = new Quote(
            Name = 'Master Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsPrimary__c = true,
            IsMultiProductTechnicalQuote__c = false
        );
        insert masterQuote;

        // Create 2 technical quotes
        Quote techQuote1 = new Quote(
            Name = 'Technical Quote 1',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsPrimary__c = false,
            IsMultiProductTechnicalQuote__c = true,
            ServiceName__c = 'RingCentral Office',
            MasterQuote__c = masterQuote.Id
        );

        Quote techQuote2 = new Quote(
            Name = 'Technical Quote 2',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsPrimary__c = false,
            IsMultiProductTechnicalQuote__c = true,
            ServiceName__c = 'Contact Center',
            MasterQuote__c = masterQuote.Id
        );
        insert new List<Quote>{ techQuote1, techQuote2 };

        // Create products with catalog IDs
        Product2 product1 = new Product2(
            Name = 'Test Product 1',
            IsActive = true,
            ExtID__c = 'CAT-001',
            Sub_Category__c = 'Main'
        );

        Product2 product2 = new Product2(
            Name = 'Test Product 2',
            IsActive = true,
            ExtID__c = 'CAT-002',
            Sub_Category__c = 'Main'
        );
        insert new List<Product2>{ product1, product2 };

        // Create pricebook entries
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product1.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );

        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product2.Id,
            UnitPrice = 200.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert new List<PricebookEntry>{ pbe1, pbe2 };

        // Create cart items for master quote
        List<BillingWrappers.CartItem> masterCartItems = new List<BillingWrappers.CartItem>();

        BillingWrappers.CartItem cartItem1 = createCartItem('CAT-001', 'Product 1', 10, 100.00);
        BillingWrappers.CartItem cartItem2 = createCartItem('CAT-002', 'Product 2', 5, 200.00);

        masterCartItems.add(cartItem1);
        masterCartItems.add(cartItem2);

        // Create cart items for technical quotes (same catalog IDs to link to master)
        List<BillingWrappers.CartItem> tech1CartItems = new List<BillingWrappers.CartItem>();
        tech1CartItems.add(createCartItem('CAT-001', 'Product 1', 10, 100.00));

        List<BillingWrappers.CartItem> tech2CartItems = new List<BillingWrappers.CartItem>();
        tech2CartItems.add(createCartItem('CAT-002', 'Product 2', 5, 200.00));

        // Build request payload
        Map<Id, List<BillingWrappers.CartItem>> quoteIdToCartItems = new Map<Id, List<BillingWrappers.CartItem>>();
        quoteIdToCartItems.put(masterQuote.Id, masterCartItems);
        quoteIdToCartItems.put(techQuote1.Id, tech1CartItems);
        quoteIdToCartItems.put(techQuote2.Id, tech2CartItems);

        ApiRequest request = new ApiRequest();
        request.requestBody = JSON.serialize(quoteIdToCartItems);

        QuoteLineItemUpsertHandler handler = new QuoteLineItemUpsertHandler();

        // Act
        Test.startTest();
        ApiResponse response = handler.execute(request);
        Test.stopTest();

        System.debug('response: ' + response);

        // Assert
        System.assertEquals(200, response.statusCode, 'Expected success status code');

        // Verify master QLIs were created
        List<QuoteLineItem> masterQLIs = [
            SELECT Id, QuoteId, Product2.ExtID__c, IsMultiProductTechnicalQLI__c, MasterQLI__c
            FROM QuoteLineItem
            WHERE QuoteId = :masterQuote.Id
            ORDER BY Product2.ExtID__c
        ];
        System.assertEquals(2, masterQLIs.size(), 'Expected 2 master QLIs');
        System.assertEquals(false, masterQLIs[0].IsMultiProductTechnicalQLI__c, 'Master QLI should not be technical');
        System.assertEquals(null, masterQLIs[0].MasterQLI__c, 'Master QLI should not have MasterQLI__c reference');

        // Verify technical QLIs were created and linked to master QLIs
        List<QuoteLineItem> tech1QLIs = [
            SELECT Id, QuoteId, Product2.ExtID__c, IsMultiProductTechnicalQLI__c, MasterQLI__c
            FROM QuoteLineItem
            WHERE QuoteId = :techQuote1.Id
        ];
        System.assertEquals(1, tech1QLIs.size(), 'Expected 1 technical QLI for tech quote 1');
        System.assertEquals(true, tech1QLIs[0].IsMultiProductTechnicalQLI__c, 'Technical QLI should be marked as technical');
        System.assertNotEquals(null, tech1QLIs[0].MasterQLI__c, 'Technical QLI must have MasterQLI__c populated');

        // Find the corresponding master QLI by catalog ID (stored in Product2.ExtID__c)
        QuoteLineItem correspondingMasterQLI = null;
        for (QuoteLineItem masterQLI : masterQLIs) {
            if (masterQLI.Product2.ExtID__c == tech1QLIs[0].Product2.ExtID__c) {
                correspondingMasterQLI = masterQLI;
                break;
            }
        }
        System.assertNotEquals(null, correspondingMasterQLI, 'Should find corresponding master QLI');
        System.assertEquals(correspondingMasterQLI.Id, tech1QLIs[0].MasterQLI__c,
            'Technical QLI MasterQLI__c should reference correct master QLI');

        // Verify second technical quote QLIs
        List<QuoteLineItem> tech2QLIs = [
            SELECT Id, QuoteId, Product2.ExtID__c, IsMultiProductTechnicalQLI__c, MasterQLI__c
            FROM QuoteLineItem
            WHERE QuoteId = :techQuote2.Id
        ];
        System.assertEquals(1, tech2QLIs.size(), 'Expected 1 technical QLI for tech quote 2');
        System.assertEquals(true, tech2QLIs[0].IsMultiProductTechnicalQLI__c, 'Technical QLI should be marked as technical');
        System.assertNotEquals(null, tech2QLIs[0].MasterQLI__c, 'Technical QLI must have MasterQLI__c populated');

        // Verify the master QLI link for tech quote 2
        QuoteLineItem correspondingMasterQLI2 = null;
        for (QuoteLineItem masterQLI : masterQLIs) {
            if (masterQLI.Product2.ExtID__c == tech2QLIs[0].Product2.ExtID__c) {
                correspondingMasterQLI2 = masterQLI;
                break;
            }
        }
        System.assertNotEquals(null, correspondingMasterQLI2, 'Should find corresponding master QLI for tech quote 2');
        System.assertEquals(correspondingMasterQLI2.Id, tech2QLIs[0].MasterQLI__c,
            'Technical QLI 2 MasterQLI__c should reference correct master QLI');

        // Verify response structure
        Map<String, Object> fullResponse = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody);
        System.assertEquals('success', fullResponse.get('status'), 'Response status should be success');
        System.assert(fullResponse.containsKey('data'), 'Response should contain data property');

        Map<String, Object> responseData = (Map<String, Object>) fullResponse.get('data');
        System.assert(responseData.containsKey('masterQuote'), 'Response data should contain masterQuote');
        System.assert(responseData.containsKey('techQuotes'), 'Response data should contain techQuotes');

        Map<String, Object> techQuotes = (Map<String, Object>) responseData.get('techQuotes');
        System.assertEquals(2, techQuotes.size(), 'Should have 2 technical quotes in response');
    }

    /**
     * Helper method to create a cart item
     */
    private static BillingWrappers.CartItem createCartItem(String catalogId, String name, Integer quantity, Decimal unitPrice) {
        BillingWrappers.CartItem item = new BillingWrappers.CartItem();
        item.catalogId = catalogId;
        item.name = name;
        item.quantity = quantity;
        item.unitPrice = unitPrice;
        item.billingCycleDuration = 'Monthly';
        item.discount = 0;
        item.discountType = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        item.currencyIsoCode = 'USD';
        item.packageInfo = TestDataGenerator.TEST_PACKAGE_INFO;
        item.isDeleted = false;
        return item;
    }
}