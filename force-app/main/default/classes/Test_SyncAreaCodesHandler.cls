@IsTest
private class Test_SyncAreaCodesHandler {

    @TestSetup
    static void setup() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => Date.today().addDays(30),
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Account__c => testAccount.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => 'Draft',
                Quote.Pricebook2Id => Pricebook2Helper.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test Product',
                Product2.IsActive => true,
                Product2.ExtID__c => 'CATALOG-001'
            })
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem testQLI = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => testPBE.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 100
            })
            .create()
            .getRecord();

        // Create existing area codes
        Area_Codes__c existingAreaCode1 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '415',
                Area_Codes__c.Country__c => 'USA',
                Area_Codes__c.State__c => 'CA',
                Area_Codes__c.City__c => 'San Francisco',
                Area_Codes__c.Area_Code__c => 415,
                Area_Codes__c.Type__c => 'Local'
            })
            .create()
            .getRecord();

        Area_Codes__c existingAreaCode2 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '628',
                Area_Codes__c.Country__c => 'USA',
                Area_Codes__c.State__c => 'CA',
                Area_Codes__c.City__c => 'San Francisco',
                Area_Codes__c.Area_Code__c => 628,
                Area_Codes__c.Type__c => 'Local'
            })
            .create()
            .getRecord();

        Area_Codes__c existingAreaCode3 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '212',
                Area_Codes__c.Country__c => 'USA',
                Area_Codes__c.State__c => 'NY',
                Area_Codes__c.City__c => 'New York',
                Area_Codes__c.Area_Code__c => 212,
                Area_Codes__c.Type__c => 'Local'
            })
            .create()
            .getRecord();

        // Create existing area code line items (one to update, one to delete)
        Area_Code_Line_Item__c existingACLI1 = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Quote_Line_Item__c => testQLI.Id,
                Area_Code_Line_Item__c.Area_Code__c => existingAreaCode1.Id,
                Area_Code_Line_Item__c.Quantity__c => 5
            })
            .create()
            .getRecord();

        Area_Code_Line_Item__c existingACLI2 = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Quote_Line_Item__c => testQLI.Id,
                Area_Code_Line_Item__c.Area_Code__c => existingAreaCode2.Id,
                Area_Code_Line_Item__c.Quantity__c => 10
            })
            .create()
            .getRecord();

        Triggers.switchOn();
    }

    @IsTest
    static void testUpsertAndDeleteAreaCodeLineItems() {
        // Given
        // Combine SOQL queries into a single query to reduce the number of SOQL calls
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        QuoteLineItem testQLI = [SELECT Id, Product_Lic_Id__c FROM QuoteLineItem WHERE Product_Lic_Id__c = 'CATALOG-001' LIMIT 1];
        List<Area_Codes__c> areaCodes = [
            SELECT Id, Area_Code__c, Country__c, State__c, City__c, Type__c
            FROM Area_Codes__c
            WHERE Area_Code__c IN (415, 628, 212)
            ORDER BY Area_Code__c
        ];

        List<Area_Code_Line_Item__c> existingACLIs = [
            SELECT Id, Area_Code__r.Area_Code__c, Quantity__c
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__c = :testQLI.Id
            ORDER BY Area_Code__r.Area_Code__c
        ];

        System.assertEquals(2, existingACLIs.size(), 'Should have 2 existing area code line items');

        // Prepare request: update existing item, delete existing item, create new item
        Map<String, List<BillingWrappers.AreaCodeLineItem>> quoteToAreaCodes = new Map<String, List<BillingWrappers.AreaCodeLineItem>>();

        // Item 1: Update existing area code line item (415) - change quantity
        BillingWrappers.AreaCodeLineItem updateItem = buildAreaCodeLineItem('CATALOG-001', 20, false, areaCodes[1]);

        // Item 2: Delete existing area code line item (628) - mark as deleted
        BillingWrappers.AreaCodeLineItem deleteItem = buildAreaCodeLineItem('CATALOG-001', 10, true, areaCodes[2]);

        // Item 3: Create new area code line item (212) - uses existing area code
        BillingWrappers.AreaCodeLineItem newItem = buildAreaCodeLineItem('CATALOG-001', 15, false, areaCodes[0]);

        // Item 4: Create completely new area code (310) - area code doesn't exist in database
        BillingWrappers.AreaCodeLineItem newAreaCodeItem = buildAreaCodeLineItem('CATALOG-001', 25, false, 'USA', 'CA', 'Los Angeles', 310, 'Local');

        quoteToAreaCodes.put(testQuote.Id, new List<BillingWrappers.AreaCodeLineItem>{
            updateItem,
            deleteItem,
            newItem,
            newAreaCodeItem
        });

        String requestBody = JSON.serialize(quoteToAreaCodes);
        ApiRequest apiRequest = new ApiRequest();
        apiRequest.requestBody = requestBody;

        SyncAreaCodesHandler handler = new SyncAreaCodesHandler();

        // When
        Test.startTest();
        ApiResponse response = handler.execute(apiRequest);
        Test.stopTest();

        // Then
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.statusCode, 'Response should be successful');

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody);
        Map<String, Object> responseData = (Map<String, Object>) responseBody.get('data');
        System.assertNotEquals(null, responseData.get('upsertedRecords'), 'Should have upsertedRecords count');
        System.assertNotEquals(null, responseData.get('deletedRecords'), 'Should have deletedRecords count');

        Integer upsertedCount = Integer.valueOf(responseData.get('upsertedRecords'));
        Integer deletedCount = Integer.valueOf(responseData.get('deletedRecords'));

        // Verify: 3 upserts (update existing 415 + new 212 + new 310), 1 delete (628)
        System.assertEquals(3, upsertedCount, 'Should have 3 upserted records');
        System.assertEquals(1, deletedCount, 'Should have 1 deleted record');

        // Verify final state in database
        List<Area_Code_Line_Item__c> finalACLIs = [
            SELECT Id, Area_Code__r.Area_Code__c, Quantity__c, Quote_Line_Item__c
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__c = :testQLI.Id
            ORDER BY Area_Code__r.Area_Code__c
        ];

        // Should have 3 records: updated 415 (quantity 20), new 212 (quantity 15), and new 310 (quantity 25)
        // 628 should be deleted
        System.assertEquals(3, finalACLIs.size(), 'Should have 3 area code line items after sync');

        // Verify updated item (415)
        Area_Code_Line_Item__c updatedItem = null;
        Area_Code_Line_Item__c newCreatedItem = null;
        Area_Code_Line_Item__c newAreaCodeCreatedItem = null;
        for (Area_Code_Line_Item__c acli : finalACLIs) {
            if (acli.Area_Code__r.Area_Code__c == 415) {
                updatedItem = acli;
            } else if (acli.Area_Code__r.Area_Code__c == 212) {
                newCreatedItem = acli;
            } else if (acli.Area_Code__r.Area_Code__c == 310) {
                newAreaCodeCreatedItem = acli;
            }
        }

        System.assertNotEquals(null, updatedItem, 'Updated item (415) should exist');
        System.assertEquals(20, updatedItem.Quantity__c, 'Updated item should have quantity 20');

        System.assertNotEquals(null, newCreatedItem, 'New item (212) should exist');
        System.assertEquals(15, newCreatedItem.Quantity__c, 'New item should have quantity 15');

        System.assertNotEquals(null, newAreaCodeCreatedItem, 'New area code item (310) should exist');
        System.assertEquals(25, newAreaCodeCreatedItem.Quantity__c, 'New area code item should have quantity 25');

        // Verify the new area code was created in the database
        List<Area_Codes__c> newAreaCodes = [
            SELECT Id, Area_Code__c, Country__c, State__c, City__c, Type__c
            FROM Area_Codes__c
            WHERE Area_Code__c = 310
        ];
        System.assertEquals(1, newAreaCodes.size(), 'New area code (310) should be created');
        System.assertEquals('USA', newAreaCodes[0].Country__c, 'New area code country should match');
        System.assertEquals('CA', newAreaCodes[0].State__c, 'New area code state should match');
        System.assertEquals('Los Angeles', newAreaCodes[0].City__c, 'New area code city should match');
        System.assertEquals('Local', newAreaCodes[0].Type__c, 'New area code type should match');

        // Verify deleted item (628) no longer exists
        List<Area_Code_Line_Item__c> deletedItems = [
            SELECT Id
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__c = :testQLI.Id
            AND Area_Code__r.Area_Code__c = 628
        ];
        System.assertEquals(0, deletedItems.size(), 'Deleted item (628) should not exist');
    }

    /**
     * Builds BillingWrappers.AreaCodeLineItem with all required fields from Area_Codes__c
     */
    private static BillingWrappers.AreaCodeLineItem buildAreaCodeLineItem(
        String catalogId,
        Integer quantity,
        Boolean isDeleted,
        Area_Codes__c areaCode
    ) {
        return buildAreaCodeLineItem(
            catalogId,
            quantity,
            isDeleted,
            areaCode.Country__c,
            areaCode.State__c,
            areaCode.City__c,
            Integer.valueOf(areaCode.Area_Code__c),
            areaCode.Type__c
        );
    }

    /**
     * Builds BillingWrappers.AreaCodeLineItem with all required fields from individual parameters
     */
    private static BillingWrappers.AreaCodeLineItem buildAreaCodeLineItem(
        String catalogId,
        Integer quantity,
        Boolean isDeleted,
        String country,
        String state,
        String city,
        Integer areaCode,
        String type
    ) {
        BillingWrappers.AreaCodeLineItem item = new BillingWrappers.AreaCodeLineItem();
        item.cartItemCatalogId = catalogId;
        item.quantity = quantity;
        item.isDeleted = isDeleted;

        BillingWrappers.AreaCodeData areaCodeInfo = new BillingWrappers.AreaCodeData();
        areaCodeInfo.country = country;
        areaCodeInfo.state = state;
        areaCodeInfo.city = city;
        areaCodeInfo.areaCode = areaCode;
        areaCodeInfo.type = type;

        item.areaCodeInfo = areaCodeInfo;
        return item;
    }
}