@IsTest
private class Test_SyncAssignmentLineItemsHandler {

    @TestSetup
    static void testData() {
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

        // Create parent product
        Product2 parentProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Parent Product',
                Product2.IsActive => true,
                Product2.ExtID__c => 'PARENT-001'
            })
            .create()
            .getRecord();

        // Create child product
        Product2 childProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Child Product',
                Product2.IsActive => true,
                Product2.ExtID__c => 'CHILD-001'
            })
            .create()
            .getRecord();

        // Create another child product for testing
        Product2 childProduct2 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Child Product 2',
                Product2.IsActive => true,
                Product2.ExtID__c => 'CHILD-002'
            })
            .create()
            .getRecord();

        // Create pricebook entries
        PricebookEntry parentPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                PricebookEntry.Product2Id => parentProduct.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry childPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                PricebookEntry.Product2Id => childProduct.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry childPBE2 = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Pricebook2Helper.getStandardPricebookId(),
                PricebookEntry.Product2Id => childProduct2.Id,
                PricebookEntry.UnitPrice => 75,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        // Create quote line items
        QuoteLineItem parentQLI = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => parentProduct.Id,
                QuoteLineItem.PricebookEntryId => parentPBE.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 100
            })
            .create()
            .getRecord();

        QuoteLineItem childQLI1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => childProduct.Id,
                QuoteLineItem.PricebookEntryId => childPBE.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();

        QuoteLineItem childQLI2 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => childProduct2.Id,
                QuoteLineItem.PricebookEntryId => childPBE2.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 75
            })
            .create()
            .getRecord();

        // Create area codes
        Area_Codes__c areaCode1 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '212',
                Area_Codes__c.Country__c => 'USA',
                Area_Codes__c.State__c => 'CA',
                Area_Codes__c.City__c => 'San Francisco',
                Area_Codes__c.Area_Code__c => 212,
                Area_Codes__c.Type__c => 'Local'
            })
            .create()
            .getRecord();

        Area_Codes__c areaCode2 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
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

        Area_Codes__c areaCode3 = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => '628',
                Area_Codes__c.Country__c => 'USA',
                Area_Codes__c.State__c => 'NY',
                Area_Codes__c.City__c => 'New York',
                Area_Codes__c.Area_Code__c => 628,
                Area_Codes__c.Type__c => 'Local'
            })
            .create()
            .getRecord();

        // Create Area_Code_Line_Item__c records to associate area codes with the quote
        // This is required for the area code sync logic to find existing area codes
        Area_Code_Line_Item__c areaCodeLineItem1 = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => areaCode1.Id,
                Area_Code_Line_Item__c.Quote_Line_Item__c => childQLI1.Id,
                Area_Code_Line_Item__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        Area_Code_Line_Item__c areaCodeLineItem2 = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => areaCode2.Id,
                Area_Code_Line_Item__c.Quote_Line_Item__c => childQLI1.Id,
                Area_Code_Line_Item__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        Area_Code_Line_Item__c areaCodeLineItem3 = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => areaCode3.Id,
                Area_Code_Line_Item__c.Quote_Line_Item__c => childQLI2.Id,
                Area_Code_Line_Item__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        // Create existing assignment line items (one to update, one to delete)
        AssignmentLineItem__c existingALI1 = (AssignmentLineItem__c) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.AreaCode__c => areaCode1.Id,
                AssignmentLineItem__c.Child__c => childQLI1.Id,
                AssignmentLineItem__c.Parent__c => parentQLI.Id,
                AssignmentLineItem__c.Quantity__c => 5
            })
            .create()
            .getRecord();

        AssignmentLineItem__c existingALI2 = (AssignmentLineItem__c) new SObjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.AreaCode__c => areaCode2.Id,
                AssignmentLineItem__c.Child__c => childQLI1.Id,
                AssignmentLineItem__c.Parent__c => parentQLI.Id,
                AssignmentLineItem__c.Quantity__c => 10
            })
            .create()
            .getRecord();

        Triggers.switchOn();
    }

    @IsTest
    static void shouldSyncAssignmentLineItemsWhenValidDataProvided() {
        // Given
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        List<Area_Codes__c> areaCodes = [
            SELECT Id, Area_Code__c, Country__c, State__c, City__c, Type__c
            FROM Area_Codes__c
            WHERE Area_Code__c IN (212, 415, 628)
            ORDER BY Area_Code__c
        ];

        List<AssignmentLineItem__c> existingALIs = [
            SELECT Id, AreaCode__r.Area_Code__c, Quantity__c
            FROM AssignmentLineItem__c
            ORDER BY AreaCode__r.Area_Code__c
        ];

        Assert.areEqual(2, existingALIs.size(), 'Should have 2 existing assignment line items');

        // Verify area codes are properly created and linked
        List<Area_Code_Line_Item__c> areaCodeLineItems = [
            SELECT Id, Area_Code__r.Area_Code__c, Quote_Line_Item__r.Product2.ExtID__c
            FROM Area_Code_Line_Item__c
            ORDER BY Area_Code__r.Area_Code__c
        ];
        Assert.areEqual(3, areaCodeLineItems.size(), 'Should have 3 area code line items');

        // Prepare request: update existing item, create new item, delete existing item
        Map<String, List<BillingWrappers.AssignmentLineItem>> quoteIdToAlisMap =
            new Map<String, List<BillingWrappers.AssignmentLineItem>>();

        // Item 1: Update existing assignment line item (212) - change quantity from 5 to 20
        Assert.areEqual(212, areaCodes[0].Area_Code__c, 'Area code 212 should exist');
        BillingWrappers.AssignmentLineItem updateItem = buildAssignmentLineItem(
            'CHILD-001', 'PARENT-001', 20, areaCodes[0]
        );

        // Item 2: Create new assignment line item (212) - uses existing area code and different child
        Assert.areEqual(628, areaCodes[2].Area_Code__c, 'Area code 628 should exist');
        BillingWrappers.AssignmentLineItem newItem = buildAssignmentLineItem(
            'CHILD-002', 'PARENT-001', 15, areaCodes[2]
        );

        // Note: Item with area code 628 is not included, so it should be deleted

        quoteIdToAlisMap.put(testQuote.Id, new List<BillingWrappers.AssignmentLineItem>{
            updateItem,
            newItem
        });

        String requestBody = JSON.serialize(quoteIdToAlisMap);
        ApiRequest apiRequest = new ApiRequest();
        apiRequest.requestBody = requestBody;

        SyncAssignmentLineItemsHandler handler = new SyncAssignmentLineItemsHandler();

        // When
        Test.startTest();
        ApiResponse response = handler.execute(apiRequest);
        Test.stopTest();

        // Then
        Assert.isNotNull(response, 'Response should not be null');
        Assert.areEqual(200, response.statusCode, 'Response should be successful');

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.responseBody);
        Map<String, Object> responseData = (Map<String, Object>) responseBody.get('data');

        Assert.isNotNull(responseData.get('upsertedAssignmentLineItems'), 'Should have upsertedAssignmentLineItems count');
        Assert.isNotNull(responseData.get('deletedAssignmentLineItems'), 'Should have deletedAssignmentLineItems count');

        Integer upsertedCount = Integer.valueOf(responseData.get('upsertedAssignmentLineItems'));
        Integer deletedCount = Integer.valueOf(responseData.get('deletedAssignmentLineItems'));

        // Verify: 2 upserts (update existing 212 + new 628), 1 delete (415)
        Assert.areEqual(2, upsertedCount, 'Should have 2 upserted records (1 update + 1 new)');
        Assert.areEqual(1, deletedCount, 'Should have 1 deleted record (415 area code)');

        // Verify final state in database
        List<AssignmentLineItem__c> finalALIs = [
            SELECT Id, AreaCode__r.Area_Code__c, Quantity__c, Child__r.Product2.ExtID__c, Parent__r.Product2.ExtID__c
            FROM AssignmentLineItem__c
            ORDER BY AreaCode__r.Area_Code__c
        ];

        // Should have 2 records: updated 212 (quantity 20) and new 628 (quantity 15)
        // 415 should be deleted
        Assert.areEqual(2, finalALIs.size(), 'Should have 2 assignment line items after sync');

        // Verify updated item (212)
        AssignmentLineItem__c updatedItem = null;
        AssignmentLineItem__c newCreatedItem = null;
        for (AssignmentLineItem__c ali : finalALIs) {
            if (ali.AreaCode__r.Area_Code__c == 212) {
                updatedItem = ali;
            } else if (ali.AreaCode__r.Area_Code__c == 628) {
                newCreatedItem = ali;
            }
        }

        Assert.isNotNull(updatedItem, 'Updated item (212) should exist');
        Assert.areEqual(20, updatedItem.Quantity__c, 'Updated item should have quantity 20');
        Assert.areEqual('CHILD-001', updatedItem.Child__r.Product2.ExtID__c, 'Updated item should have correct child product');
        Assert.isNotNull(newCreatedItem, 'New item (628) should exist');
        Assert.areEqual(15, newCreatedItem.Quantity__c, 'New item should have quantity 15');
        Assert.areEqual('CHILD-002', newCreatedItem.Child__r.Product2.ExtID__c, 'New item should have correct child product');

        // Verify deleted item (415) no longer exists
        List<AssignmentLineItem__c> deletedItems = [
            SELECT Id
            FROM AssignmentLineItem__c
            WHERE AreaCode__r.Area_Code__c = 415
        ];

        String deletedItemMessage = 'Deleted item (415) should not exist';
        Assert.areEqual(0, deletedItems.size(), deletedItemMessage);
    }

    /**
     * Builds BillingWrappers.AssignmentLineItem with required fields
     */
    private static BillingWrappers.AssignmentLineItem buildAssignmentLineItem(
        String childId,
        String parentId,
        Integer quantity,
        Area_Codes__c areaCode
    ) {
        BillingWrappers.AssignmentLineItem item = new BillingWrappers.AssignmentLineItem();
        item.childId = childId;
        item.parentId = parentId;
        item.quantity = quantity;

        BillingWrappers.AreaCodeData areaCodeInfo = new BillingWrappers.AreaCodeData();
        areaCodeInfo.country = areaCode.Country__c;
        areaCodeInfo.state = areaCode.State__c;
        areaCodeInfo.city = areaCode.City__c;
        areaCodeInfo.areaCode = Integer.valueOf(areaCode.Area_Code__c);
        areaCodeInfo.type = areaCode.Type__c;

        item.areaCodeInfo = areaCodeInfo;
        return item;
    }
}