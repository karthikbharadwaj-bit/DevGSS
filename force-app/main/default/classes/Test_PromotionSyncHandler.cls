@IsTest
private class Test_PromotionSyncHandler {

    @IsTest
    static void testExecuteSuccess_FullFlow() {
        // Given - Create test data: Account, Opportunity, Quote, Products, and QuoteLineItems
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

        // Create test quote
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => testOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        // Create test products with ExtID__c values
        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Test Product 1',
                    'Test Product 2'
                }),
                Product2.IsActive => true,
                Product2.Family => 'Test Family',
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String> {
                    'CATALOG_001',
                    'CATALOG_002'
                })
            })
            .quantity(2)
            .create()
            .getRecords();

        // Create pricebook entries for each product
        List<PricebookEntry> pricebookEntries = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<String> {
                    testProducts[0].Id,
                    testProducts[1].Id
                }),
                PricebookEntry.IsActive => true,
                PricebookEntry.UnitPrice => 100
            })
            .quantity(2)
            .create()
            .getRecords();

        // Create test quote line items
        List<QuoteLineItem> testQLIs = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<String> {
                    pricebookEntries[0].Id,
                    pricebookEntries[1].Id
                }),
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 100
            })
            .quantity(2)
            .create()
            .getRecords();

        // Create a promotion to delete (simulate existing promotion)
        Promotion__c existingPromotion = (Promotion__c) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Promotion__c.Name => 'Old Promo',
                Promotion__c.Quote__c => testQuote.Id,
                Promotion__c.Promo_Code__c => 'OLD_CODE',
                Promotion__c.Promo_Code_Id__c => 'OLD_PROMO_ID',
                Promotion__c.Description__c => 'Old Promotion',
                Promotion__c.Priority__c => '1'
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        // Prepare request data
        BillingWrappers.Promotion promoToDelete = new BillingWrappers.Promotion();
        promoToDelete.id = existingPromotion.Id;

        BillingWrappers.Promotion promoToCreate1 = new BillingWrappers.Promotion();
        promoToCreate1.name = 'New Promo 1';
        promoToCreate1.promoCode = 'NEW_CODE_1';
        promoToCreate1.promoCodeId = 'NEW_PROMO_ID_1';
        promoToCreate1.description = 'New Promotion 1';
        promoToCreate1.quoteId = testQuote.Id;
        promoToCreate1.priority = '10';
        promoToCreate1.discountTemplates = 'Template1';
        promoToCreate1.startDate = '2025-01-01 00:00:00';
        promoToCreate1.endDate = '2025-12-31 23:59:59';

        BillingWrappers.Promotion promoToCreate2 = new BillingWrappers.Promotion();
        promoToCreate2.name = 'New Promo 2';
        promoToCreate2.promoCode = 'NEW_CODE_2';
        promoToCreate2.promoCodeId = 'NEW_PROMO_ID_2';
        promoToCreate2.description = 'New Promotion 2';
        promoToCreate2.quoteId = testQuote.Id;
        promoToCreate2.priority = '20';
        promoToCreate2.discountTemplates = 'Template2';

        BillingWrappers.CartItem item1 = new BillingWrappers.CartItem();
        item1.catalogId = 'CATALOG_001';
        item1.sfPromoCodeId = 'NEW_PROMO_ID_1';

        BillingWrappers.CartItem item2 = new BillingWrappers.CartItem();
        item2.catalogId = 'CATALOG_002';
        item2.sfPromoCodeId = 'NEW_PROMO_ID_2';

        Map<String, Object> requestData = new Map<String, Object> {
            'promotionsToDelete' => new List<BillingWrappers.Promotion> { promoToDelete },
            'promotionsToCreate' => new List<BillingWrappers.Promotion> { promoToCreate1, promoToCreate2 },
            'items' => new List<BillingWrappers.CartItem> { item1, item2 }
        };

        ApiRequest request = new ApiRequest();
        request.requestBody = JSON.serialize(requestData);

        PromotionSyncHandler handler = new PromotionSyncHandler();

        Test.startTest();

        // When
        ApiResponse response = handler.execute(request);

        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Should return success status code');

        // Verify old promotion was deleted
        List<Promotion__c> deletedPromos = [SELECT Id FROM Promotion__c WHERE Id = :existingPromotion.Id];
        System.assertEquals(0, deletedPromos.size(), 'Old promotion should be deleted');

        // Verify new promotions were created
        List<Promotion__c> createdPromos = [
            SELECT Id, Name, Promo_Code__c, Promo_Code_Id__c, Description__c, Priority__c,
                   Start_Date__c, End_Date__c, Discount_Templates__c, Quote__c
            FROM Promotion__c
            WHERE Promo_Code_Id__c IN ('NEW_PROMO_ID_1', 'NEW_PROMO_ID_2')
            ORDER BY Priority__c
        ];
        System.assertEquals(2, createdPromos.size(), 'Should create 2 new promotions');

        // Verify first promotion details
        System.assertEquals('New Promo 1', createdPromos[0].Name, 'First promotion name should match');
        System.assertEquals('NEW_CODE_1', createdPromos[0].Promo_Code__c, 'First promotion code should match');
        System.assertEquals('NEW_PROMO_ID_1', createdPromos[0].Promo_Code_Id__c, 'First promotion code ID should match');
        System.assertEquals('New Promotion 1', createdPromos[0].Description__c, 'First promotion description should match');
        System.assertEquals('10', createdPromos[0].Priority__c, 'First promotion priority should match');
        System.assertEquals('Template1', createdPromos[0].Discount_Templates__c, 'First promotion discount templates should match');
        System.assertEquals(testQuote.Id, createdPromos[0].Quote__c, 'First promotion should be linked to quote');
        System.assertEquals(Datetime.valueOfGmt('2025-01-01 00:00:00'), createdPromos[0].Start_Date__c, 'First promotion start date should match');
        System.assertEquals(Datetime.valueOfGmt('2025-12-31 23:59:59'), createdPromos[0].End_Date__c, 'First promotion end date should match');

        // Verify second promotion details
        System.assertEquals('New Promo 2', createdPromos[1].Name, 'Second promotion name should match');
        System.assertEquals('NEW_CODE_2', createdPromos[1].Promo_Code__c, 'Second promotion code should match');
        System.assertEquals('NEW_PROMO_ID_2', createdPromos[1].Promo_Code_Id__c, 'Second promotion code ID should match');
        System.assertEquals('Template2', createdPromos[1].Discount_Templates__c, 'Second promotion discount templates should match');

        // Verify quote line items were updated with promotions
        List<QuoteLineItem> updatedQLIs = [
            SELECT Id, Product2.ExtID__c, Promotion__c
            FROM QuoteLineItem
            WHERE QuoteId = :testQuote.Id
            ORDER BY Product2.ExtID__c
        ];
        System.assertEquals(2, updatedQLIs.size(), 'Should have 2 quote line items');
        System.assertEquals(createdPromos[0].Id, updatedQLIs[0].Promotion__c, 'First QLI should be linked to first promotion');
        System.assertEquals(createdPromos[1].Id, updatedQLIs[1].Promotion__c, 'Second QLI should be linked to second promotion');
    }
}