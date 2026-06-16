@isTest
private class  Test_QuoteLineItemHelper {

    private static Integer lastRandomKey = 1;
    public static String getFakeId(Schema.SObjectType sot){
        String result = String.valueOf(lastRandomKey++);
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
    }

    @isTest static void getDependentItemsToAdd() {
        Triggers.switchOff();
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Products
        Product2 testProd1 = new Product2(Name = 'Test product 1', IsActive = true, Feature__c = 1);
        Product2 testProd2 = new Product2(Name = 'Test product 2', IsActive = true, Feature__c = 1);
        Product2 testProd3 = new Product2(Name = 'Test product 3', IsActive = true, Dependent_on_Feature__c = 1);
        Product2 testProd4 = new Product2(Name = 'Test product 4', IsActive = true, Dependent_on_Feature__c = 1);
        Product2 testProd5 = new Product2(Name = 'Test product 5', IsActive = true);
        insert new List<Product2>{
                testProd1, testProd2, testProd3, testProd4, testProd5
        };

        // Create PriceBook Entries
        String stdPBId = Test.getStandardPricebookId();

        PricebookEntry stdPrice1 = new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = testProd1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);

        PricebookEntry stdPrice2 = new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = testProd2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);

        PricebookEntry stdPrice3 = new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = testProd3.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice3 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd3.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);

        PricebookEntry stdPrice4 = new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = testProd4.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice4 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd4.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);

        PricebookEntry stdPrice5 = new PricebookEntry(Pricebook2Id = stdPBId, Product2Id = testProd5.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice5 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd5.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);

        insert new List<PricebookEntry> {
            stdPrice1,  stdPrice2,  stdPrice3,  stdPrice4,
            testPrice1, testPrice2, testPrice3, testPrice4
        };

        // create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', CloseDate=System.today());
        insert testOppty;

        // Create Quote
        Quote testQt = new Quote (
                Name = 'Test Quote',
                OpportunityId = testOppty.Id,
                Pricebook2Id = testPrBook.id);
        insert testQt;

        // Create Quote Line Items
        QuoteLineItem testQli1 = new QuoteLineItem (
                QuoteId=testQt.Id,
                Product2Id = testProd1.Id,
                PricebookEntryId = testPrice1.Id,
                Quantity = 5,
                UnitPrice = testPrice1.UnitPrice);

        QuoteLineItem testQli2 = new QuoteLineItem (
                QuoteId=testQt.Id,
                Product2Id = testProd2.Id,
                PricebookEntryId = testPrice2.Id,
                Quantity = 6,
                UnitPrice = testPrice2.UnitPrice);

        List<QuoteLineItem> itemsToInsert1 = new List<QuoteLineItem>{testQli1};

        List<PricebookEntry> priceBookEntries = [
                SELECT Id, Name, Product2.Dependent_on_Feature__c, Product2.Feature__c, Pricebook2Id, CurrencyIsoCode,
                       Product2.Description, UnitPrice
                FROM PricebookEntry
                WHERE Pricebook2Id = :testPrBook.Id
        ];

        List<Entitlement__c> entitlements = new List<Entitlement__c> ();
        List<QuoteLineItem> existingQli = new List<QuoteLineItem> ();
        List<Quote> testQuotes = [SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Id = :testQt.Id];


        //
        // Test Insert of Quote Line Items 1
        //


        Test.startTest();
        // Test Insert Dependent items
        List<QuoteLineItem> resultDependentItems1 = QuoteLineItemHelper.getDependentOnFeatureItemsOnInsert(
                itemsToInsert1,
                priceBookEntries,
                entitlements,
                existingQli,
                testQuotes);

        System.assertEquals(2, resultDependentItems1.size());
        System.assertEquals(5, resultDependentItems1[0].Quantity);
        System.assertEquals(5, resultDependentItems1[1].Quantity);

        itemsToInsert1.addAll(resultDependentItems1);
        insert itemsToInsert1;

        //
        // Test Insert of Quote Line Items 2
        //

        List<QuoteLineItem> existingQuoteLineItems2 = [
                SELECT Id, Product2Id, CurrencyIsoCode, Quantity, Product2.Feature__c, Product2.Dependent_on_Feature__c,
                        QuoteId, Quote.Pricebook2Id, Zero_Quantity__c, Product2.Matcher_Formula__c
                FROM QuoteLineItem
                WHERE QuoteId = :testQt.Id
        ];

        List<QuoteLineItem> itemsToInsert2 = new List<QuoteLineItem>{testQli2};

        // Test update items
        List<QuoteLineItem> resultDependentItems2 = QuoteLineItemHelper.getDependentOnFeatureItemsOnInsert(
                itemsToInsert2,
                priceBookEntries,
                entitlements,
                existingQuoteLineItems2,
                testQuotes);

        System.assertEquals(2, resultDependentItems2.size());

        System.assert(resultDependentItems2[0].Id != null);
        System.assert(resultDependentItems2[1].Id != null);

        System.assertEquals(11, resultDependentItems2[0].Quantity);
        System.assertEquals(11, resultDependentItems2[1].Quantity);


        List<QuoteLineItem> insertItems2 = new List<QuoteLineItem>(itemsToInsert2);
        insertItems2.addAll(resultDependentItems2);
        upsert insertItems2;



        //
        // Test Update of Quote Line Items
        //


        List<QuoteLineItem> existingQuoteLineItems3 = [
                SELECT Id, Product2Id, CurrencyIsoCode, Quantity, Product2.Feature__c, Product2.Dependent_on_Feature__c,
                        QuoteId, Quote.Pricebook2Id, Zero_Quantity__c, Product2.Matcher_Formula__c
                FROM QuoteLineItem
                WHERE QuoteId = :testQt.Id
        ];

        List<QuoteLineItem> testQLIsToUpdate = new List<QuoteLineItem>();
        for (QuoteLineItem qli : existingQuoteLineItems3){
            if (new Set<Id>{testQli1.Id, testQli2.Id}.contains(qli.Id)){
                qli.Quantity = 7;
                testQLIsToUpdate.add(qli);
            }
        }


        // Test update items
        List<QuoteLineItem> resultUpdateDependentItems1 = QuoteLineItemHelper.getDependentOnFeatureItemsOnUpdate(
                testQLIsToUpdate,
                existingQuoteLineItems3
        );

        System.assertEquals(2, resultUpdateDependentItems1.size());

        System.assertEquals(14, resultUpdateDependentItems1[0].Quantity);
        System.assertEquals(14, resultUpdateDependentItems1[1].Quantity);


        List<QuoteLineItem> updateDependentItems1 = new List<QuoteLineItem>(testQLIsToUpdate);
        updateDependentItems1.addAll(resultUpdateDependentItems1);
        update updateDependentItems1;

        //
        // Test Deletion of Quote Line Items 1
        //

        List<QuoteLineItem> existingQuoteLineItems4 = [
                SELECT Id, Product2Id, CurrencyIsoCode, Quantity, Product2.Feature__c, Product2.Dependent_on_Feature__c,
                        QuoteId, Quote.Pricebook2Id, Zero_Quantity__c, Product2.Matcher_Formula__c
                FROM QuoteLineItem
                WHERE QuoteId = :testQt.Id
        ];

        List<QuoteLineItem> itemsToDelete1 = new List<QuoteLineItem>();
        for (QuoteLineItem qli: existingQuoteLineItems4){
            if ( testQli1.Id == qli.Id ){
                itemsToDelete1.add(qli);
            }
        }

        // Test delete items
        Map<String, List<QuoteLineItem>> resultDeleteDependentItems1 = QuoteLineItemHelper.getDependentOnFeatureItemsOnDelete(
                itemsToDelete1,
                existingQuoteLineItems4);

        System.assertEquals(0, resultDeleteDependentItems1.get('delete').size());
        System.assertEquals(2, resultDeleteDependentItems1.get('update').size());

        System.assertEquals(7, resultDeleteDependentItems1.get('update')[0].Quantity);
        System.assertEquals(7, resultDeleteDependentItems1.get('update')[1].Quantity);

        delete itemsToDelete1;
        update resultDeleteDependentItems1.get('update');

        //
        // Test Deletion of Quote Line Items 2
        //

        List<QuoteLineItem> existingQuoteLineItems5 = [
                SELECT Id, Product2Id, CurrencyIsoCode, Quantity, Product2.Feature__c, Product2.Dependent_on_Feature__c,
                        QuoteId, Quote.Pricebook2Id, Zero_Quantity__c, Product2.Matcher_Formula__c
                FROM QuoteLineItem
                WHERE QuoteId = :testQt.Id
        ];

        List<QuoteLineItem> itemsToDelete2 = new List<QuoteLineItem>();
        for (QuoteLineItem qli: existingQuoteLineItems5){
            if ( testQli2.Id == qli.Id ){
                itemsToDelete2.add(qli);
            }
        }

        Map<String, List<QuoteLineItem>> resultDeleteDependentItems2 = QuoteLineItemHelper.getDependentOnFeatureItemsOnDelete(
                itemsToDelete2,
                existingQuoteLineItems5);

        System.assertEquals(0, resultDeleteDependentItems2.get('update').size());
        System.assertEquals(2, resultDeleteDependentItems2.get('delete').size());

        Test.stopTest();

    }

    @isTest static void getProServItemsToRemove() {
        Triggers.switchOff();
        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');

        insert new List<Pricebook2>{
                testPriceBook1
        };

        // create Account
        Account testAccount = new Account(Name = 'Test account');
        insert testAccount;

        // create Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
                CloseDate = system.today(), AccountId = testAccount.Id, Number_of_Employees__c = '20',
                Forecasted_Users__c = 20);
        insert testOpportunity;

        // Create Quotes
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);

        Quote testSalesQuote = new Quote(Name = 'Test Sales Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id);

        Quote testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);

        Quote testCCProServQuote = new Quote(Name = 'Test CC ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV);

        insert new List<Quote>{
                testPrimaryQuote, testSalesQuote, testProServQuote, testCCProServQuote
        };

        // Create Products
        // ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV);
        // CC ProServ
        Product2 testProduct3 = new Product2(Name = 'Test Product 3', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV);
        Product2 testProduct4 = new Product2(Name = 'Test Product 4', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV);
        Product2 testProduct5 = new Product2(Name = 'Test Product 5', IsActive = true);
        insert new List<Product2>{
                testProduct1, testProduct2, testProduct3, testProduct4, testProduct5
        };

        // Create PricebookEntries
        // ProServ
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct1.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct2.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);

        // CC ProServ
        PricebookEntry standardPrice3 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct3.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice3 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct3.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);

        PricebookEntry standardPrice4 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct4.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice4 = new PricebookEntry(Pricebook2Id = testPriceBook1.Id, Product2Id = testProduct4.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);

        insert new List<PricebookEntry>{
                standardPrice1, standardPrice2, standardPrice3, standardPrice4,
                testPrice1, testPrice2, testPrice3, testPrice4
        };

        // Create Entitlements
        Entitlement__c testEnt1 = new Entitlement__c(
                Product__c = testProduct5.Id,
                Account__c = testAccount.Id,
                Active__c = true,
                Quantity__c = 8

        );
        insert new List<Entitlement__c> {
                testEnt1
        };

        // Create Quote Line Items
        // Primary Quote
        QuoteLineItem testPrimaryQli1 = new QuoteLineItem(
                QuoteId = testPrimaryQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testPrimaryQli2 = new QuoteLineItem(
                QuoteId = testPrimaryQuote.Id,
                PricebookEntryId = testPrice2.Id,
                Product2Id = testProduct2.Id,
                UnitPrice = testPrice2.UnitPrice,
                Quantity = 5,
                Entitlement__c = testEnt1.Id
        );
        QuoteLineItem testPrimaryQli3 = new QuoteLineItem(
                QuoteId = testPrimaryQuote.Id,
                PricebookEntryId = testPrice3.Id,
                Product2Id = testProduct3.Id,
                UnitPrice = testPrice3.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testPrimaryQli4 = new QuoteLineItem(
                QuoteId = testPrimaryQuote.Id,
                PricebookEntryId = testPrice4.Id,
                Product2Id = testProduct4.Id,
                UnitPrice = testPrice4.UnitPrice,
                Quantity = 5,
                Entitlement__c = testEnt1.Id
        );

        // Sales Quote
        QuoteLineItem testSalesQli1 = new QuoteLineItem(
                QuoteId = testSalesQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testSalesQli2 = new QuoteLineItem(
                QuoteId = testSalesQuote.Id,
                PricebookEntryId = testPrice2.Id,
                Product2Id = testProduct2.Id,
                UnitPrice = testPrice2.UnitPrice,
                Quantity = 5,
                Entitlement__c = testEnt1.Id
        );
        QuoteLineItem testSalesQli3 = new QuoteLineItem(
                QuoteId = testSalesQuote.Id,
                PricebookEntryId = testPrice3.Id,
                Product2Id = testProduct3.Id,
                UnitPrice = testPrice3.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testSalesQli4 = new QuoteLineItem(
                QuoteId = testSalesQuote.Id,
                PricebookEntryId = testPrice4.Id,
                Product2Id = testProduct4.Id,
                UnitPrice = testPrice4.UnitPrice,
                Quantity = 5,
                Entitlement__c = testEnt1.Id
        );

        // ProServ Quote
        QuoteLineItem testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testProServQli2 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice2.Id,
                Product2Id = testProduct2.Id,
                UnitPrice = testPrice2.UnitPrice,
                Quantity = 5
        );

        // CC ProServ Quote
        QuoteLineItem testCCProServQli1 = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                PricebookEntryId = testPrice3.Id,
                Product2Id = testProduct3.Id,
                UnitPrice = testPrice3.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testCCProServQli2 = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                PricebookEntryId = testPrice4.Id,
                Product2Id = testProduct4.Id,
                UnitPrice = testPrice4.UnitPrice,
                Quantity = 5
        );
        insert new List<QuoteLineItem>{
                testPrimaryQli1, testPrimaryQli2, testPrimaryQli3, testPrimaryQli4,
                testSalesQli1, testSalesQli2, testSalesQli3, testSalesQli4,
                testProServQli1, testProServQli2,
                testCCProServQli1, testCCProServQli2
        };

        Test.startTest();


        List<QuoteLineItem> testQLIs = [
                SELECT Id, Product2.Name, Entitlement__c, Sub_Category__c, Quote.RecordTypeId, QuoteRecordType__c,
                        QuoteId, Zero_Quantity__c, Entitlement__r.Quantity__c, Quantity, NewQuantity__c,
                        Discount_type__c, Discount_number__c, Item_type__c,
                        Entitlement__r.Discount_Type__c, Entitlement__r.Discount__c, Entitlement__r.DisplayQuantity__c
                FROM QuoteLineItem
                WHERE quote.OpportunityId = :testOpportunity.Id
        ];


        // -------------------------------
        // 1) Remove Professional Services
        Map<String, List<QuoteLineItem>> resultQLIs1 = QuoteLineItemHelper.getProServItemsToRemove(testQLIs);
        Map<Id, QuoteLineItem> resultQLIsUpdateMap1 = new Map<Id, QuoteLineItem>();
        Map<Id, QuoteLineItem> resultQLIsDeleteMap1 = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli: resultQLIs1.get('update')){
            resultQLIsUpdateMap1.put(qli.Id, qli);
        }
        for (QuoteLineItem qli: resultQLIs1.get('delete')){
            resultQLIsDeleteMap1.put(qli.Id, qli);
        }


        // Check Quote Line Items Deletion
        System.assertEquals(2, resultQLIsUpdateMap1.values().size());
        System.assertEquals(2, resultQLIsDeleteMap1.values().size());

        // Quote Line Items to delete
        System.assert(resultQLIsDeleteMap1.containsKey(testPrimaryQli1.Id), 'Quote Line Items without Entitlements should be deleted');
        System.assert(resultQLIsDeleteMap1.containsKey(testSalesQli1.Id), 'Quote Line Items without Entitlements should be deleted');

        // Quote Line Items to update
        System.assert(resultQLIsUpdateMap1.containsKey(testPrimaryQli2.Id), 'Quote Line Items with Entitlements should be updated');
        System.assert(resultQLIsUpdateMap1.containsKey(testSalesQli2.Id), 'Quote Line Items with Entitlements should be updated');

        System.assertEquals(testEnt1.Quantity__c, resultQLIsUpdateMap1.get(testPrimaryQli2.Id).Quantity);
        System.assertEquals(testEnt1.Quantity__c, resultQLIsUpdateMap1.get(testSalesQli2.Id).Quantity);
        System.assertEquals(true, resultQLIsUpdateMap1.get(testPrimaryQli2.Id).Zero_Quantity__c);
        System.assertEquals(true, resultQLIsUpdateMap1.get(testSalesQli2.Id).Zero_Quantity__c);

        System.assertEquals(8, resultQLIsUpdateMap1.get(testPrimaryQli2.Id).NewQuantity__c);
        System.assertEquals(8, resultQLIsUpdateMap1.get(testSalesQli2.Id).NewQuantity__c);

        // -------------------------------
        // 1) Remove CC Professional Services
        Map<String, List<QuoteLineItem>> resultQLIs2 = QuoteLineItemHelper.getCCProServItemsToRemove(testQLIs);
        Map<Id, QuoteLineItem> resultQLIsUpdateMap2 = new Map<Id, QuoteLineItem>();
        Map<Id, QuoteLineItem> resultQLIsDeleteMap2 = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli: resultQLIs2.get('update')){
            resultQLIsUpdateMap2.put(qli.Id, qli);
        }
        for (QuoteLineItem qli: resultQLIs2.get('delete')){
            resultQLIsDeleteMap2.put(qli.Id, qli);
        }


        // Check Quote Line Items Deletion
        System.assertEquals(2, resultQLIsUpdateMap2.values().size());
        System.assertEquals(2, resultQLIsDeleteMap2.values().size());

        // Quote Line Items to delete
        System.assert(resultQLIsDeleteMap2.containsKey(testPrimaryQli3.Id), 'Quote Line Items without Entitlements should be deleted');
        System.assert(resultQLIsDeleteMap2.containsKey(testSalesQli3.Id), 'Quote Line Items without Entitlements should be deleted');

        // Quote Line Items to update
        System.assert(resultQLIsUpdateMap2.containsKey(testPrimaryQli4.Id), 'Quote Line Items with Entitlements should be updated');
        System.assert(resultQLIsUpdateMap2.containsKey(testSalesQli4.Id), 'Quote Line Items with Entitlements should be updated');

        System.assertEquals(testEnt1.Quantity__c, resultQLIsUpdateMap2.get(testPrimaryQli4.Id).Quantity);
        System.assertEquals(testEnt1.Quantity__c, resultQLIsUpdateMap2.get(testSalesQli4.Id).Quantity);
        System.assertEquals(true, resultQLIsUpdateMap2.get(testPrimaryQli4.Id).Zero_Quantity__c);
        System.assertEquals(true, resultQLIsUpdateMap2.get(testSalesQli4.Id).Zero_Quantity__c);

        System.assertEquals(8, resultQLIsUpdateMap2.get(testPrimaryQli4.Id).NewQuantity__c);
        System.assertEquals(8, resultQLIsUpdateMap2.get(testSalesQli4.Id).NewQuantity__c);


        Test.stopTest();
    }

    /* #2 qli with empty fields */
    @isTest static void getChargeTerm_empty_qli() {
        QuoteLineItem qli = new QuoteLineItem();
        Test.startTest();

        String result1 = QuoteLineItemHelper.getChargeTerm(qli);
        System.assertEquals(null, result1);

        Test.stopTest();
    }
    /* #4 qli has all required fields */
    @isTest
    static void getChargeTerm_withAllData() {
        Opportunity opp = TestDataGenerator.createOpportunity(null);
        Quote testQuote = TestDataGenerator.createQuote(opp);
        Test.startTest();

        Product2 product = TestDataGenerator.createProduct2();
        product.Charge_Term__c = 'Annual';
        update product;

        QuoteLineItem testQli1 = TestDataGenerator.createQuoteLineItem(testQuote, product);
        testQuote.RecordTypeId = QuoteHelper.RT_ID_SALES;
        update testQuote;

        testQli1 = (QuoteLineItem) new ListOptional(new QuoteLineItemSelector()
            .selectQuoteLineItemsByIds(new List<Id> {testQli1.Id})
            .executeQuery())
            .getFirst();

        QuoteLineItem testQli2 = TestDataGenerator.createQuoteLineItem(testQuote, product);
        testQli2 = (QuoteLineItem) new ListOptional(new QuoteLineItemSelector()
            .selectQuoteLineItemsByIds(new List<Id> {testQli2.Id})
            .executeQuery())
            .getFirst();
        Test.stopTest();

        String result1 = QuoteLineItemHelper.getChargeTerm(testQli1);
        String result2 = QuoteLineItemHelper.getChargeTerm(testQli2);
        System.assertEquals('Annual', result1);
        System.assertEquals('Monthly', result2);
    }

    @isTest
    static void testGetEESProductsOnDelete() {

        // System.assertEquals(new List<QuoteLineItem>(), QuoteLineItemHelper.getEESProductsOnDelete(null, null));
        System.assertEquals(new List<QuoteLineItem>(), QuoteLineItemHelper.getEESProducts(null));
        System.assertEquals(false, QuoteLineItemHelper.isContainsCCSeat(null));

        Product2 ccEesProduct = new Product2(
            Name = 'CC Enterprise Support - Gold',
            IsActive = true,
            Feature__c = Product2Helper.FEATURE_CONTACT_CENTER_EXTENDED_ENTERPRISE
        );

        Product2 ccSeatProduct = new Product2(
            Name = 'Contact Center Seat',
            IsActive = true,
            Family = Product2Helper.FAMILY_CCSERVICE
        );

        insert new List<Product2>{
            ccEesProduct, ccSeatProduct
        };

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 1,
            Line_Range_Max__c = 50,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;


        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        PricebookEntry ccEesProductStdPBE = new PricebookEntry(
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = ccEesProduct.Id
        );
        pbeList.add(ccEesProductStdPBE);

        PricebookEntry ccSeatProductStdPBE = new PricebookEntry(
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = ccSeatProduct.Id
        );
        pbeList.add(ccSeatProductStdPBE);

        PricebookEntry ccEesProductPBE = new PricebookEntry(
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = testPriceBook.Id,
            Product2Id = ccEesProduct.Id
        );
        pbeList.add(ccEesProductPBE);

        PricebookEntry ccSeatProductPBE = new PricebookEntry(
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = testPriceBook.Id,
            Product2Id = ccSeatProduct.Id
        );
        pbeList.add(ccSeatProductPBE);

        insert pbeList;

        Opportunity opp = TestDataGenerator.createOpportunity(null);

        Quote testQuote = new Quote (
            Name = 'testSalesQuote',
            OpportunityId = opp.Id,
            Pricebook2Id = testPriceBook.Id,
            CurrencyIsoCode = 'USD',
            RecordTypeId = QuoteHelper.RT_ID_SALES
        );

        Quote testCCProServQuote = new Quote (
            Name = 'testCCProServQuote',
            OpportunityId = opp.Id,
            Pricebook2Id = testPriceBook.Id,
            CurrencyIsoCode = 'USD',
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV
        );

        insert new List<Quote>{testQuote, testCCProServQuote};

        Test.startTest();

            QuoteLineItem ccEesQli = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                Quantity = 1,
                UnitPrice = ccEesProductPBE.UnitPrice,
                PricebookEntryId = ccEesProductPBE.Id,
                Product2Id = ccEesProduct.Id
            );

            QuoteLineItem ccSeatQli = new QuoteLineItem(
                QuoteId = testQuote.Id,
                Product2Id = ccSeatProduct.Id,
                Quantity = 1,
                UnitPrice = ccSeatProductPBE.UnitPrice,
                PricebookEntryId = ccSeatProductPBE.Id
            );

            insert new List<QuoteLineItem>{
                ccEesQli, ccSeatQli
            };

            List<QuoteLineItem> allQlis = [select Id, Product2Id,
                Product2.Feature__c, Product2.Family, Product2.Name
                from QuoteLineItem
                where Quote.OpportunityId = :opp.Id];


            List<QuoteLineItem> qliToDel = new List<QuoteLineItem>();
            for(QuoteLineItem qli : allQlis) {
                if(qli.Id == ccSeatQli.Id) {
                    qliToDel.add(qli);
                }
            }

            Boolean isDeletingCCSeat = QuoteLineItemHelper.isContainsCCSeat(qliToDel);
            System.assertEquals(true, isDeletingCCSeat);

            Set<Id> productsToDeleteIdSet = new Set<Id>();
            for(QuoteLineItem qli : QuoteLineItemHelper.getEESProducts(allQlis)) {
                productsToDeleteIdSet.add(qli.Id);
            }
            System.assertEquals(new Set<Id>{ccEesQli.Id}, productsToDeleteIdSet);

        Test.stopTest();
    }

    @isTest
    static void testGetEffectivePrice() {
        Test.startTest();
        Decimal result = QuoteLineItemHelper.getEffectivePrice(null);
        System.assertEquals(0, result);

        result = QuoteLineItemHelper.getEffectivePrice(new QuoteLineItem());
        System.assertEquals(0, result);

        QuoteLineItem testQLI = new QuoteLineItem(
            EffectivePriceNew__c = 20
        );
        result = QuoteLineItemHelper.getEffectivePrice(testQLI);
        System.assertEquals(20, result);
        Test.stopTest();
    }

    @isTest
    static void testGetTotalAndYourPrice() {
        // Validate null value
        Cost_Center_Line_Item__c ccli;
        Decimal zeroYourPrice = QuoteLineItemHelper.getYourPrice(ccli);
        System.assertEquals(0, zeroYourPrice);

        Decimal zeroTotalPrice = QuoteLineItemHelper.getTotalPrice(ccli);
        System.assertEquals(0, zeroTotalPrice);
        // Validate positive scenario
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity 2016',
            StageName = 'Planning',
            CloseDate = System.today()
        );
        insert opp;

        Quote testQuote = new Quote (
            Name = 'testQuote' ,
            OpportunityId = opp.id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testProduct1 = new Product2(
            Name = 'testProduct1',
            IsActive = true,
            Family = 'CC Service',
            Sub_Category__c = 'Contact Center',
            Edition__c = 'Ultimate',
            Charge_Term__c = 'Annual'
        );
        insert testProduct1;

        PricebookEntry testPBE1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true,
            UnitPrice = 1000,
            Product2Id = testProduct1.Id
        );
        insert testPBE1;

        QuoteLineItem testQli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testProduct1.Id,
            Quantity = 6,
            UnitPrice = testPBE1.UnitPrice,
            PricebookEntryId = testPBE1.Id
        );
        insert testQli;

        Cost_Center__c testCostCenter = TestDataGenerator.createCostCenter('Cost Center', testQuote);
        Cost_Center_Line_Item__c testCostCenterLineItem = new Cost_Center_Line_Item__c(
            Cost_Center__c = testCostCenter.Id,
            Quote_Line_Item__r = testQli,
            Quantity__c = testQli.Quantity
        );
        insert testCostCenterLineItem;

        Decimal resultYourPrice = QuoteLineItemHelper.getYourPrice(testCostCenterLineItem);
        System.assertEquals(1000, resultYourPrice);

        Decimal resultTotalPrice = QuoteLineItemHelper.getTotalPrice(testCostCenterLineItem);
        System.assertEquals(6000, resultTotalPrice);
    }

    @isTest
    static void testGetCurrentTotal() {
        Decimal zeroCurrentTotal = QuoteLineItemHelper.getCurrentTotal(null);
        System.assertEquals(0, zeroCurrentTotal);

        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;
        // Validate positive scenario
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity 2016',
            StageName = 'Planning',
            CloseDate = System.today()
        );
        insert opp;

        Quote testQuote = new Quote (
            Name = 'testQuote' ,
            OpportunityId = opp.id ,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testNonBillingProduct = new Product2(
            Name = 'testNonBillingProduct',
            IsActive = true,
            Family = 'CC Service',
            Sub_Category__c = 'Contact Center',
            Edition__c = 'Ultimate',
            Charge_Term__c = 'Annual'
        );
        Product2 testBillingProduct = new Product2(
            Name = 'testBillingProduct',
            IsActive = true,
            Family = 'CC Service',
            Sub_Category__c = 'Contact Center',
            Edition__c = 'Ultimate',
            Charge_Term__c = 'Annual'
        );
        insert (new List<Product2>{testNonBillingProduct, testBillingProduct});

        PricebookEntry testNonBillingPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true,
            UnitPrice = 1000,
            Product2Id = testNonBillingProduct.Id
        );
        PricebookEntry testBillingPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true,
            UnitPrice = 1000,
            Product2Id = testBillingProduct.Id
        );
        insert (new List<PricebookEntry>{testNonBillingPBE, testBillingPBE});

        QuoteLineItem testNonBillingQli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testNonBillingProduct.Id,
            Quantity = 6,
            UnitPrice = testNonBillingPBE.UnitPrice,
            PricebookEntryId = testNonBillingPBE.Id,
            EffectivePriceNew__c = 10
        );

        QuoteLineItem testBillingQli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testBillingProduct.Id,
            Quantity = 6,
            Package_Info_QLI__c = TestDataGenerator.TEST_PACKAGE_INFO,
            PackageInfo__c = TestDataGenerator.TEST_PACKAGE_INFO,
            UnitPrice = testBillingPBE.UnitPrice,
            PricebookEntryId = testBillingPBE.Id,
            EffectivePriceNew__c = 10
        );
        insert (new List<QuoteLineItem>{testNonBillingQli, testBillingQli});

        // Create Entitlements
        Entitlement__c testBillingEnt = new Entitlement__c(
            Product__c = testBillingProduct.Id,
            Active__c = true,
            Quantity__c = 8,
            Price__c = 10,
            Discount__c = 0,
            Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
            Account__c = testAcc.Id

        );
        insert new List<Entitlement__c> {testBillingEnt};

        Decimal currentBillingTotal = QuoteLineItemHelper.getCurrentTotal(testBillingQli);
        System.assertEquals(0, currentBillingTotal);
        Decimal currentNonBillingTotal = QuoteLineItemHelper.getCurrentTotal(testNonBillingQli);
        System.assertEquals(60, currentNonBillingTotal);
    }

    @isTest()
    static void verifyMinutesBundleProductType() {
        insert new ContactCenterEUMinuteBundlesTypes__c(
        	Name = 'Landline outbound minutes',
            Product_Type__c = 'Landline outbound minutes'
        );

        List<String> euType = QuoteLineItemHelper.getEuropeTransportTypes();

        // USA or UK Part
        System.assert(QuoteLineItemHelper.isMinutesBundleProduct('transport', euType), '"transport type" should be true');
        System.assert(QuoteLineItemHelper.isMinutesBundleProduct('Outbound Calls to Local Numbers and Mobile', euType), '"Outbound Calls to Local Numbers and Mobile" type should be true');
        System.assert(QuoteLineItemHelper.isMinutesBundleProduct('Inbound Calls', euType), '"Inbound Calls" type should be true');
        System.assert(!QuoteLineItemHelper.isMinutesBundleProduct('seat', euType), '"seat" type should be false');

        // Europe Part
        System.assert(QuoteLineItemHelper.isMinutesBundleProduct('Landline outbound minutes FR', euType), '"Landline outbound minutes FR" type should be true');
        System.assert(QuoteLineItemHelper.isMinutesBundleProduct('Landline outbound minutes IE', euType), '"Landline outbound minutes IE" type should be true');
        System.assert(QuoteLineItemHelper.isMinutesBundleProduct('Landline outbound minutes NL', euType), '"Landline outbound minutes NL" type should be true');
        System.assert(!QuoteLineItemHelper.isEuropeTransportType('Inbound Calls', euType), '"Inbound Calls" type should be false');
    }

    @isTest()
    static void verifyFamilyWithOverage() {
        System.assert(QuoteLineItemHelper.isFamilyWithOverage('Add - Ons'), '"Add - Ons" should be true');
        System.assert(QuoteLineItemHelper.isFamilyWithOverage('SMS'), '"SMS" type should be true');
        System.assert(QuoteLineItemHelper.isFamilyWithOverage('Workforce Optimization'), '"Workforce Optimization" type should be true');
        System.assert(!QuoteLineItemHelper.isFamilyWithOverage('Service'), '"Service" type should be false');
    }

    @isTest
    private static void testOveragesParentsMatcher() {

        IValueProvider productIdsProvider = new ValueProvider.DummyIdProvider(Product2.sObjectType);
        IValueProvider qliIdsProvider = new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType);

        // parent products
        Product2[] parentProducts = (Product2[]) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, new ValueProvider.UniqueStringProvider('Sample Parent Product Name'))
            .setField(Product2.Family, Product2Helper.FAMILY_ADDONS)
            .setField(Product2.Product_Type__c, new ValueProvider.UniqueStringProvider('Sample Product Type'))
            .setField(Product2.ExtId__c, new ValueProvider.UniqueStringProvider('null_sample ext id_false'))
            .quantity(5)
            .build()
            .getRecords();
        QuoteLineItem[] parentQlis = (QuoteLineItem[]) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .quantity(5)
            .build()
            .getRecords();
        for (Integer i = 0; i < parentQlis.size(); ++i) {
            parentQlis[i].Product2 = parentProducts[i];
        }

        // child overages
        Product2[] overageProducts = (Product2[]) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Id, productIdsProvider)
            .setField(Product2.Name, new ValueProvider.UniqueStringProvider('Sample Overage Name'))
            .setField(Product2.Family, Product2Helper.FAMILY_OVERAGE)
            .setField(Product2.Product_Type__c, new ValueProvider.UniqueStringProvider('Sample Overage Type'))
            .setField(Product2.ExtId__c, new ValueProvider.UniqueStringProvider('overage_some overage_false'))
            .quantity(5)
            .build()
            .getRecords();
        QuoteLineItem[] overageQlis = (QuoteLineItem[]) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.Id, qliIdsProvider)
            .quantity(5)
            .build()
            .getRecords();
        for (Integer i = 0; i < overageQlis.size(); ++i) {
            overageQlis[i].Product2 = overageProducts[i];
        }

        // Parent__c matching logic
        overageProducts[0].Parent__c = parentProducts[0].Id;

        // seat child matching logic
        parentProducts[1].Family = Product2Helper.FAMILY_CCSERVICE;
        parentProducts[1].Name = 'Contact Center: Service: Basic Edition Seat';
        overageProducts[1].Name = 'International Minutes Overage';

        // ExtId__c matching logic
        String extIdString = 'Contact Center: Spice White Labeling (per BU)_null_Annual_null_null_null_false';
        parentProducts[2].ExtId__c = 'null_' + extIdString;
        overageProducts[2].ExtId__c = 'Overage_' + extIdString;

        // MinuteBundles matching logic
        parentProducts[3].Product_Type__c = 'Landline outbound minutes US';
        overageProducts[3].Product_Type__c = parentProducts[3].Product_Type__c;
        parentProducts[4].Product_Type__c = 'Landline outbound minutes FR';
        overageProducts[4].Product_Type__c = parentProducts[4].Product_Type__c;

        Test.startTest();

            QuoteLineItemHelper.OveragesParentsMatcher matcher = new QuoteLineItemHelper.OveragesParentsMatcher(parentQlis);
            matcher.addToSearchScope(overageQlis);

            System.assertEquals(parentQlis[0], matcher.getParent(overageQlis[0]),
                'Wrong parent for overage with non-null Parent__c.');
            System.assertEquals(parentQlis[1], matcher.getParent(overageQlis[1]),
                'Wrong parent for seat overage.');
            System.assertEquals(parentQlis[2], matcher.getParent(overageQlis[2]),
                'Wrong parent for matching by ExtId__c');
            System.assertEquals(parentQlis[3], matcher.getParent(overageQlis[3]),
                'Wrong parent for MinuteBundle overage.');
            System.assertEquals(parentQlis[4], matcher.getParent(overageQlis[4]),
                'Wrong parent for MinuteBundle overage.');

        Test.stopTest();

    }

    @isTest
    private static void testIsQLIApplicableForSyncWithNGBS() {
        Triggers.switchOff();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'OPP_NAME',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Map<SObjectField, Object> productDigitalLineUnlimitedMap = new Map<SObjectField, Object> {
            Product2.Name => 'DigitalLine Unlimited',
            Product2.ExtId__c => Product2Helper.DL_UNL_ELEMENT_ID,
            Product2.Family => Product2Helper.FAMILY_SERVICE,
            Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
            Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CLOUDCONNECT
        };
        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(productDigitalLineUnlimitedMap).create().getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        QuoteLineItem qliDigitalLineUnlimited = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.IsHiddenLicense__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncWithNGBS()
            .executeQuery();
        Test.startTest();
        System.assert(
            QuoteLineItemHelper.isQLIApplicableForSyncWithNGBS(qlis[0]),
            'Method should return positive value'
        );
        Test.stopTest();
    }
    @isTest
    private static void testIsUsageLicense() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Billing_Type__c => Product2Helper.BILLING_TYPE_USAGE
                }
            )
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        Test.startTest();
            List<QuoteLineItem> qliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<String>{'Product2.Billing_Type__c'})
                .setCondition('Id = \'' + qli.Id + '\'')
                .executeQuery();

            Boolean isUsage = QuoteLineItemHelper.isUsageLicense(qliList[0]);
        Test.stopTest();

        System.assert(
            isUsage,
            'QLI should have Usage Billing Type'
        );
    }

    @isTest
    private static void testIsNonUsageLicense() {

        Test.startTest();

        Boolean isUsage = QuoteLineItemHelper.isUsageLicense(null);

        Test.stopTest();

        System.assert(
            !isUsage,
            'QLI should have not Usage Billing Type'
        );
    }

    @isTest
    private static void verifyGetAnyQuoteLineItemWithEntitlementReturnCorrectValue() {
        QuoteLineItem[] qlis = new List<QuoteLineItem>{
            new QuoteLineItem(Display_Name__c = 'one'),
            new QuoteLineItem(Display_Name__c = 'two'),
            new QuoteLineItem(Display_Name__c = 'three', Entitlement__r = new Entitlement__c())
        };
        QuoteLineItem qli = QuoteLineItemHelper.getAnyQuoteLineItemWithEntitlement(qlis);
        System.assertEquals(qli.Display_Name__c, 'three', 'should have entitlement');
    }

    @isTest
    private static void verifyGetAnyQuoteLineItemWithEntitlementReturnNull() {
        QuoteLineItem[] qlis = new List<QuoteLineItem>{
            new QuoteLineItem(Display_Name__c = 'one'),
            new QuoteLineItem(Display_Name__c = 'two'),
            new QuoteLineItem(Display_Name__c = 'three')
        };
        QuoteLineItem qli = QuoteLineItemHelper.getAnyQuoteLineItemWithEntitlement(qlis);
        System.assertEquals(qli, null, 'should be null');
    }

    @isTest
    private static void testDigitalStorageOverage() {

        Product2 storageOverageOld = new Product2(
            CatID__c = Product2Helper.CATID_ADDITIONAL_STORAGE_OLD,
            Family = Product2Helper.FAMILY_OVERAGE,
            Id = getFakeId(Product2.sObjectType)
        );
        Product2 storageAddOnOld = new Product2(
            CatID__c = Product2Helper.CATID_ADDITIONAL_STORAGE_OLD,
            Family = Product2Helper.FAMILY_ADDONS,
            Id = getFakeId(Product2.sObjectType)
        );
        Product2 seatOld = new Product2(
            Family = Product2Helper.FAMILY_CCSERVICE,
            Id = getFakeId(Product2.sObjectType)
        );

        Product2 storageOverage = new Product2(
            CatID__c = Product2Helper.CATID_ADDITIONAL_STORAGE,
            Family = Product2Helper.FAMILY_OVERAGE,
            Id = getFakeId(Product2.sObjectType)
        );
        Product2 storageAddOn = new Product2(
            CatID__c = Product2Helper.CATID_ADDITIONAL_STORAGE,
            Family = Product2Helper.FAMILY_ADDONS,
            Id = getFakeId(Product2.sObjectType)
        );
        Product2 seatGlobal = new Product2(
            CatID__c = new List<String>(Product2Helper.CATID_GLOBAL_SEATS)[0],
            Family = Product2Helper.FAMILY_CCSERVICE,
            Id = getFakeId(Product2.sObjectType)
        );

        List<PriceBookEntry> priceBookEntries = new List<PriceBookEntry>();
        priceBookEntries.add(new PricebookEntry(Product2Id = seatOld.Id, Product2 = seatOld));
        priceBookEntries.add(new PricebookEntry(Product2Id = seatGlobal.Id, Product2 = seatGlobal));
        priceBookEntries.add(new PricebookEntry(Product2Id = storageOverageOld.Id, Product2 = storageOverageOld));
        priceBookEntries.add(new PricebookEntry(Product2Id = storageAddOnOld.Id, Product2 = storageAddOnOld));
        priceBookEntries.add(new PricebookEntry(Product2Id = storageAddOn.Id, Product2 = storageAddOn));

        QuoteLineItem qliSeatOld = new QuoteLineItem(Product2 = seatOld, Product2Id = seatOld.Id, Id = getFakeId(QuoteLineItem.sObjectType), Quantity = 100, NewQuantity__c = 100);
        QuoteLineItem qliSeatGlobal = new QuoteLineItem(Product2 = seatGlobal, Product2Id = seatGlobal.Id, Id = getFakeId(QuoteLineItem.sObjectType), Quantity = 100, NewQuantity__c = 100);
        QuoteLineItem qliStorageAddOnOld = new QuoteLineItem(Product2 = storageAddOnOld, Product2Id = storageAddOnOld.Id, Id = getFakeId(QuoteLineItem.sObjectType), Quantity = 1, NewQuantity__c = 1);
        QuoteLineItem qliStorageAddOn = new QuoteLineItem(Product2 = storageAddOn, Product2Id = storageAddOn.Id, Id = getFakeId(QuoteLineItem.sObjectType), Quantity = 1, NewQuantity__c = 1);
        QuoteLineItem qliStorageOverageOld = new QuoteLineItem(Product2 = storageOverageOld, Product2Id = storageOverageOld.Id, Id = getFakeId(QuoteLineItem.sObjectType), Threshold__c = 0);
        QuoteLineItem qliStorageOverage = new QuoteLineItem(Product2 = storageOverage, Product2Id = storageOverage.Id, Id = getFakeId(QuoteLineItem.sObjectType), Threshold__c = 0);

        List<QuoteLineItem> itemsToInsert = new List<QuoteLineItem>();
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
        Map<Id, QuoteLineItem> itemsToUpdateMap = new Map<Id, QuoteLineItem>();
        List<QuoteLineItem> currentQLIs = new List<QuoteLineItem>();

        // 1. Test the handleDigitalOveragesOnUpdate()
        //   1.1. handleDigitalOveragesOnUpdate() for Common (old) seat edition
        currentQLIs.add(qliSeatOld);
        currentQLIs.add(qliStorageAddOnOld);
        currentQLIs.add(qliStorageOverageOld);

        QuoteLineItemHelper.handleDigitalOveragesOnUpdate(itemsToUpdate, currentQLIs);
        System.assert(!itemsToUpdate.isEmpty());
        System.assertEquals(1, itemsToUpdate[0].Threshold__c);
        itemsToUpdate.clear();
        currentQLIs.clear();

        //   1.2. handleDigitalOveragesOnUpdate() for Global (new) seat edition
        currentQLIs.add(qliSeatGlobal);
        currentQLIs.add(qliStorageAddOn);
        currentQLIs.add(qliStorageOverage);

        QuoteLineItemHelper.handleDigitalOveragesOnUpdate(itemsToUpdate, currentQLIs);
        System.debug(itemsToUpdate);
        System.assert(!itemsToUpdate.isEmpty());
        System.assertEquals(1, itemsToUpdate[0].Threshold__c);
        itemsToUpdate.clear();
        currentQLIs.clear();

        // 2. Test the handleDigitalOveragesOnCreate()
        //   2.1. handleDigitalOveragesOnCreate() for Common (old) seat edition
        currentQLIs.add(qliSeatOld);
        itemsToInsert.add(qliStorageOverageOld);
        itemsToInsert.add(qliStorageAddOnOld);
        itemsToInsert.add(qliStorageAddOn);
        try {
            QuoteLineItemHelper.handleDigitalOveragesOnCreate(itemsToInsert, currentQLIs, priceBookEntries);
            System.assert(false, 'No exception when trying to add global-seat-specific add-on with common seat');
        } catch (Exception e) {}

        itemsToInsert.remove(2); // remove the qliStorageAddOn

        QuoteLineItemHelper.handleDigitalOveragesOnCreate(itemsToInsert, currentQLIs, priceBookEntries);
        System.assertEquals(1, qliStorageOverageOld.Threshold__c);
        itemsToInsert.clear();
        currentQLIs.clear();

        //   2.2. handleDigitalOveragesOnCreate() for Global (new) seat edition
        currentQLIs.add(qliSeatGlobal);
        itemsToInsert.add(qliStorageOverage);
        itemsToInsert.add(qliStorageAddOn);
        itemsToInsert.add(qliStorageAddOnOld);

        try {
            QuoteLineItemHelper.handleDigitalOveragesOnCreate(itemsToInsert, currentQLIs, priceBookEntries);
            System.assert(false, 'No exception when trying to add common-seat-specific add-on with global seat');
        } catch (Exception e) {}

        itemsToInsert.remove(2); // remove the qliStorageAddOnOld

        QuoteLineItemHelper.handleDigitalOveragesOnCreate(itemsToInsert, currentQLIs, priceBookEntries);
        System.assertEquals(1, qliStorageOverage.Threshold__c);
        itemsToInsert.clear();
        currentQLIs.clear();

        // 3. Test the handleDigitalOveragesOnDelete()
        //   3.1. handleDigitalOveragesOnDelete() for Common (old) seat edition & no update required
        currentQLIs.add(qliStorageAddOnOld);
        currentQLIs.add(qliStorageOverageOld);

        QuoteLineItemHelper.handleDigitalOveragesOnDelete(qliSeatOld, currentQLIs, itemsToUpdateMap);
        System.assert(itemsToUpdateMap.isEmpty());
        currentQLIs.clear();
        itemsToUpdateMap.clear();

        //   3.2. handleDigitalOveragesOnDelete() for Global (new) seat edition & update required
        currentQLIs.add(qliSeatGlobal);
        currentQLIs.add(qliStorageAddOn);
        currentQLIs.add(qliStorageOverage); // threshold is already 1 since Part 2.2 above

        QuoteLineItemHelper.handleDigitalOveragesOnDelete(qliStorageAddOn, currentQLIs, itemsToUpdateMap);
        System.assert(itemsToUpdateMap.containsKey(qliStorageOverage.Id));
        System.assertEquals(0, itemsToUpdateMap.get(qliStorageOverage.Id).Threshold__c);
    }

    @isTest
    private static void testIsCLMChangeOrderFormRequired() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.PriceBook2Id => Test.getStandardPricebookId()
                })
                .create()
                .getRecord();

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.packageInfo.catalogId = '1';
        pInfo.packageInfo.version = '2';
        pInfo.duration = 'Monthly';
        pInfo.partnerPackage = new BillingWrappers.PartnerPackageInfo();
        pInfo.partnerPackage.id = '3';
        pInfo.partnerPackage.version = 4;

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Quote.Name => 'Test quote',
                        Quote.OpportunityId => opp.Id,
                        Quote.isPrimary__c => true,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo})
                })
                .create()
                .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Product2.Name => 'Service',
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                        Product2.IsActive => true,
                        Product2.Charge_Term__c => 'Monthly'
                })
                .create()
                .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Entitlement__c.Account__c => acc.Id,
                        Entitlement__c.Quote__c => qt.Id,
                        Entitlement__c.Product__c => prod.Id,
                        Entitlement__c.Discount__c => 5,
                        Entitlement__c.Discount_Type__c => 'Currency',
                        Entitlement__c.Price__c => 45,
                        Entitlement__c.PackageCatalogId__c => '222',
                        Entitlement__c.PackageVersion__c => '1',
                        Entitlement__c.ChargeTerm__c => 'Annual'
                })
                .create()
                .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => prod.Id,
                        PricebookEntry.UnitPrice => 50,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => prod.Id,
                        QuoteLineItem.QuoteId => qt.Id,
                        QuoteLineItem.PricebookEntryId => standardPrice.Id,
                        QuoteLineItem.PackageCatalogId__c => '111',
                        QuoteLineItem.PackageVersion__c => '1',
                        QuoteLineItem.Quantity => -1,
                        QuoteLineItem.UnitPrice => 50,
                        QuoteLineItem.Discount_Number__c => 10,
                        QuoteLineItem.Discount_type__c => 'Currency',
                        QuoteLineItem.ChargeTerm__c => 'Monthly',
                        QuoteLineItem.Entitlement__c => ent.Id
                })
                .create()
                .getRecord();
        Triggers.switchOn();

        Test.startTest();
        List<String> fieldsToQuery = new List<String> {
                'Entitlement__r.PackageCatalogId__c',
                'Entitlement__r.PackageDuration__c',
                'Entitlement__r.PackageVersion__c',
                'PackageCatalogId__c',
                'PackageVersion__c'
        };
        QuoteLineItem testQli = (QuoteLineItem) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(new Set<Id>{qt.Id})
                .selectFields(fieldsToQuery)
                .executeQuery()
                .get(0);

        Boolean isPlanChange = QuoteLineItemHelper.isPaymentPlanChange(testQli);
        Boolean isPackageChange = QuoteLineItemHelper.isPackageChange(testQli);
        Boolean isDiscountChange = QuoteLineItemHelper.isDiscountChange(testQli);
        Boolean isDownsell = QuoteLineItemHelper.isDownsell(testQli);
        Boolean isPriceChange = QuoteLineItemHelper.isPriceChange(testQli);
        Test.stopTest();

        System.assertEquals(true, isPlanChange, 'isPaymentPlanChange Method should return true if Payment Plan changed');
        System.assertEquals(true, isPackageChange, 'isPackageChange Method should return true if Package changed');
        System.assertEquals(true, isDiscountChange, 'isDiscountChange Method should return true if Discount changed');
        System.assertEquals(true, isDownsell, 'isDownsell Method should return true if Quantity less then 0');
        System.assertEquals(true, isPriceChange, 'isPriceChange Method should return true if UnitPrice changed');
    }


    @isTest
    private static void testIsPaymentPlanChangeForUsageLicenses() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'TestAccount')
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.AccountId => acc.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.PriceBook2Id => Test.getStandardPricebookId()
                })
                .create()
                .getRecord();

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.packageInfo.catalogId = '1';
        pInfo.packageInfo.version = '2';
        pInfo.duration = 'Monthly';
        pInfo.partnerPackage = new BillingWrappers.PartnerPackageInfo();
        pInfo.partnerPackage.id = '3';
        pInfo.partnerPackage.version = 4;

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Quote.Name => 'Test quote',
                        Quote.OpportunityId => opp.Id,
                        Quote.isPrimary__c => true,
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo>{pInfo})
                })
                .create()
                .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Product2.Name => 'Service',
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                        Product2.IsActive => true,
                        Product2.Charge_Term__c => 'Monthly',
                        Product2.Billing_Type__c => Product2Helper.BILLING_TYPE_USAGE
                })
                .create()
                .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Entitlement__c.Account__c => acc.Id,
                        Entitlement__c.Quote__c => qt.Id,
                        Entitlement__c.Product__c => prod.Id,
                        Entitlement__c.Discount__c => 5,
                        Entitlement__c.Discount_Type__c => 'Currency',
                        Entitlement__c.Price__c => 45,
                        Entitlement__c.PackageCatalogId__c => '222',
                        Entitlement__c.PackageVersion__c => '1',
                        Entitlement__c.ChargeTerm__c => 'Annual'
                })
                .create()
                .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => prod.Id,
                        PricebookEntry.UnitPrice => 50,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false
                })
                .create()
                .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => prod.Id,
                        QuoteLineItem.QuoteId => qt.Id,
                        QuoteLineItem.PricebookEntryId => standardPrice.Id,
                        QuoteLineItem.PackageCatalogId__c => '111',
                        QuoteLineItem.PackageVersion__c => '1',
                        QuoteLineItem.Quantity => -1,
                        QuoteLineItem.UnitPrice => 50,
                        QuoteLineItem.Discount_Number__c => 10,
                        QuoteLineItem.Discount_type__c => 'Currency',
                        QuoteLineItem.ChargeTerm__c => 'Monthly',
                        QuoteLineItem.Entitlement__c => ent.Id
                })
                .create()
                .getRecord();
        Triggers.switchOn();

        Test.startTest();
        QuoteLineItem testQli = (QuoteLineItem) new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(new Set<Id>{qt.Id})
                .executeQuery()
                .get(0);

        Boolean isPlanChange = QuoteLineItemHelper.isPaymentPlanChange(testQli);
        Test.stopTest();

        System.assertEquals(false, isPlanChange, 'isPaymentPlanChange Method should return false for Usage Licenses');
    }

    @isTest
    private static void testGetPrimaryQuoteLineItem() {
        getDependentItemsToAdd();

        Quote primaryQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .executeQuery()
            .get(0);

        QuoteLineItem linkedQuoteLineItem = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .executeQuery()
            .get(0);

        Triggers.switchOff();

        primaryQuote.isPrimary__c = true;
        linkedQuoteLineItem.Package_Info__c = '{"Version":null,"q":1,"Price":null,"parent":null,' +
            '"lbox":null,"isCore":"true","Id":null,"duration":"Monthly","Discount":null,' +
            '"categoryPath":"RCCCSEAT","categoryCode":"RCCCSEAT"}';

        update primaryQuote;
        update linkedQuoteLineItem;

        Triggers.switchOn();

        primaryQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Id>{primaryQuote.Id})
            .subselect(new QuoteLineItemSelector().selectQuoteLineItems())
            .executeQuery()
            .get(0);

        System.assertEquals(
            linkedQuoteLineItem.Id,
            QuoteLineItemHelper.getPrimaryQuoteLineItem(primaryQuote).Id,
            'Method should return core QuoteLineItem'
        );
    }

    @isTest
    private static void testGetOverallDiscount() {
        System.assertEquals(
            0,
            QuoteLineItemHelper.getOverallDiscount(null),
            'method getOverallDiscount should return 0 if passed list is empty'
        );
        System.assertEquals(
            0,
            QuoteLineItemHelper.getOverallDiscount(new List<QuoteLineItem>()),
            'method getOverallDiscount should return 0 if passed list is empty'
        );

        Triggers.switchOff();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.PriceBook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        List<Product2> productsList = (List<Product2>) new SobjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test_product_')
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<PriceBookEntry> pbeList = (List<PriceBookEntry>) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.Product2Id => ValueProviderBuilder.provideParents(productsList),
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        List<Promotion__c> testPromotions = (List<Promotion__c>) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Promotion__c.Name => ValueProviderBuilder.provideUniqueString('test_promo_')
            })
            .quantity(1)
            .build()
            .getRecords();

        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => 50,
                    QuoteLineItem.Discount => ValueProviderBuilder.provideList(new List<Decimal>{
                        50, 20, 10
                    }),
                    QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal>{
                        1000, 700, 1500
                    }),
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productsList),
                    QuoteLineItem.PriceBookEntryId => ValueProviderBuilder.provideParents(pbeList),
                    QuoteLineItem.Promotion__c => ValueProviderBuilder.provideParents(testPromotions)
                }
            )
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.startTest();

            List<QuoteLineItem> qliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<Schema.SObjectField> {
                    QuoteLineItem.Discount,
                    QuoteLineItem.UnitPrice,
                    QuoteLineItem.Promotion__c
                })
                .setCondition('QuoteId = \'' + testQuote.Id + '\'')
                .executeQuery();

            Decimal overallDiscount = QuoteLineItemHelper.getOverallDiscount(qliList);
            System.assertEquals(
                24.69,
                overallDiscount.setScale(2),
                'overall discount should be "24.69"'
            );

        Test.stopTest();
    }

    @IsTest
    private static void testCreateTechnicalLineItems() {
        Triggers.switchOff();
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createQuote(masterOpp);

        Product2 pOffice1 = TestDataGenerator.createProduct2('OFFICE1');
        Product2 pOffice2 = TestDataGenerator.createProduct2('OFFICE2');
        Product2 pCC1 = TestDataGenerator.createProduct2('CC1');

        QuoteLineItem masterQLI1 = TestDataGenerator.createQuoteLineItem(masterQuote, pOffice1);
        QuoteLineItem masterQLI2 = TestDataGenerator.createQuoteLineItem(masterQuote, pOffice2);
        QuoteLineItem masterQLI3 = TestDataGenerator.createQuoteLineItem(masterQuote, pCC1);

        Pricebook2 pbOffice = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Pricebook2 pbCC = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_RCCC_PRODUCT);
        Pricebook2 pbEV = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Pricebook2 pbED = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        PricebookEntry spbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, null);
        PricebookEntry spbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, null);
        PricebookEntry spbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, null);

        PricebookEntry pbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, pbOffice);
        PricebookEntry pbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, pbOffice);
        PricebookEntry pbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, pbCC);

        BillingWrappers.Params params = new BillingWrappers.Params();
        BillingWrappers.CartItem office1 = TestDataGenerator.createCartItemBilling(
            'Office 1',
            'OFFICE1',
            false,
            null
        );
        BillingWrappers.CartItem office2 = TestDataGenerator.createCartItemBilling(
            'Office 2',
            'OFFICE2',
            false,
            null
        );
        BillingWrappers.CartItem rcc1 = TestDataGenerator.createCartItemBilling(
            'CC 1',
            'CC1',
            false,
            null
        );

        Map<String, BillingWrappers.CartItem[]> items = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>{
                office1, office2
            },
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>{
                rcc1
            },
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new List<BillingWrappers.CartItem>()
        };

        BillingWrappers.QuoteWrapper officeQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper edQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper evQuoteInfo = new BillingWrappers.QuoteWrapper();

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => officeQuoteInfo,
            QuoteHelper.NGBS_RCCC_PRODUCT => rccQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => evQuoteInfo
        };

        List<String> serviceNames = new List<String>(items.keySet());

        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceNames);
        Map<String, Quote> serviceQuotes = QuoteHelper.upsertTechnicalQuotes(masterQuote, quoteInfoByService, serviceOpportunities);

        Triggers.switchOn();

        Test.startTest();
        Map<String, List<QuoteLineItem>> result = QuoteLineItemHelper.upsertTechnicalQuoteLineItems(masterQuote, items, serviceQuotes);
        Test.stopTest();

        System.assert(!result.isEmpty(), 'result should not be empty');
        System.assert(result.size() == 4, 'result should contain 4 entries');

        QuoteLineItem[] qliOffice = result.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        System.assert(qliOffice.size() == 2, 'office quote should contain 2 line items');
        System.assert(qliOffice.get(0).IsMultiProductTechnicalQLI__c == true, 'office quote first item id should be correct');
        System.assert(qliOffice.get(0).Product2.ExtID__c == 'OFFICE1', 'office quote first item id should be correct');
        System.assert(
            qliOffice.get(0).MasterQLI__c == masterQLI1.Id,
            String.format('technical quote line item linked to master: {0} == {1}', new List<Object> { qliOffice.get(0).MasterQLI__c, masterQLI1.Id })
        );
        System.assert(qliOffice.get(1).IsMultiProductTechnicalQLI__c == true, 'office quote second item id should be correct');
        System.assert(qliOffice.get(1).Product2.ExtID__c == 'OFFICE2', 'office quote second item id should be correct');
        System.assert(
            qliOffice.get(1).MasterQLI__c == masterQLI2.Id,
            String.format('technical quote line item linked to master: {0} == {1}', new List<Object> { qliOffice.get(1).MasterQLI__c, masterQLI2.Id })
        );
        QuoteLineItem[] qliCC = result.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        System.assert(qliCC.size() == 1, 'cc quote should contain 1 line item');
        System.assert(qliCC.get(0).IsMultiProductTechnicalQLI__c == true, 'cc quote second item id should be correct');
        System.assert(qliCC.get(0).Product2.ExtID__c == 'CC1', 'cc quote first item id should be correct');
        System.assert(
            qliCC.get(0).MasterQLI__c == masterQLI3.Id,
            String.format('technical quote line item linked to master: {0} == {1}', new List<Object> { qliCC.get(0).MasterQLI__c, masterQLI3.Id })
        );


        QuoteLineItem[] qliED = result.get(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        System.assert(qliED.size() == 0, 'ed quote should contain 0 line item');

        QuoteLineItem[] qliEV = result.get(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);
        System.assert(qliEV.size() == 0, 'ev quote should contain 0 line item');
    }

    @IsTest
    private static void testCopyQuoteLineItemsToMasterQuote() {
        Triggers.switchOff();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
        TriggerHandler.BY_PASS_QUOTE_ON_UPDATE = true;
        TriggerHandler.BY_PASS_QUOTE_ON_INSERT = true;

        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createQuote(masterOpp);

        Product2 pOffice1 = TestDataGenerator.createProduct2('OFFICE1');
        Product2 pOffice2 = TestDataGenerator.createProduct2('OFFICE2');
        Product2 pCC1 = TestDataGenerator.createProduct2('CC1');

        Pricebook2 pbOffice = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Pricebook2 pbCC = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_RCCC_PRODUCT);
        Pricebook2 pbEV = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Pricebook2 pbED = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT);

        PricebookEntry spbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, null);
        PricebookEntry spbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, null);
        PricebookEntry spbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, null);

        PricebookEntry pbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, pbOffice);
        PricebookEntry pbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, pbOffice);
        PricebookEntry pbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, pbCC);

        BillingWrappers.Params params = new BillingWrappers.Params();
        BillingWrappers.CartItem office1 = TestDataGenerator.createCartItemBilling(
            'Office 1',
            'OFFICE1',
            false,
            null
        );
        BillingWrappers.CartItem office2 = TestDataGenerator.createCartItemBilling(
            'Office 2',
            'OFFICE2',
            false,
            null
        );
        BillingWrappers.CartItem rcc1 = TestDataGenerator.createCartItemBilling(
            'CC 1',
            'CC1',
            false,
            null
        );

        Map<String, BillingWrappers.CartItem[]> items = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>{
                office1, office2
            },
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>{
                rcc1
            },
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => new List<BillingWrappers.CartItem>(),
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => new List<BillingWrappers.CartItem>()
        };

        BillingWrappers.QuoteWrapper officeQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper edQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper evQuoteInfo = new BillingWrappers.QuoteWrapper();

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => officeQuoteInfo,
            QuoteHelper.NGBS_RCCC_PRODUCT => rccQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT => edQuoteInfo,
            QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT => evQuoteInfo
        };

        List<String> serviceNames = new List<String>(items.keySet());
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceNames);
        Map<String, Quote> serviceQuotes = QuoteHelper.upsertTechnicalQuotes(masterQuote, quoteInfoByService, serviceOpportunities);
        Map<String, List<QuoteLineItem>> serviceQuoteLineItems = QuoteLineItemHelper.upsertTechnicalQuoteLineItems(masterQuote, items, serviceQuotes);
        Triggers.switchOn();

        Test.startTest();
        List<QuoteLineItem> result = QuoteLineItemHelper.copyQuoteLineItemsToMasterQuote(masterQuote.Id);
        TriggerHandler.BY_PASS_QUOTE_ON_UPDATE = false;
        TriggerHandler.BY_PASS_QUOTE_ON_INSERT = false;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;

        Test.stopTest();

        System.assert(!result.isEmpty(), 'result should not be empty');
        System.assert(result.size() == 3, 'result should contain 3 entries');

        List<QuoteLineItem> officeItems = serviceQuoteLineItems.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        List<QuoteLineItem> ccItems = serviceQuoteLineItems.get(QuoteHelper.NGBS_RCCC_PRODUCT);

        System.assert(
            result.get(0).QuoteId == masterQuote.Id,
            'quote line item 1 must belong to master quote'
        );
        System.assert(
            result.get(0).Product2.ExtID__c == officeItems.get(0).Product2.ExtID__c,
            'quote line item 1 product external id should match with the one from technical quote'
        );
        System.assert(
            result.get(0).IsMultiProductTechnicalQLI__c == false,
            'quote line item 1 should be technical qli'
        );
        System.assert(
            result.get(1).QuoteId == masterQuote.Id,
            'quote line item 2 must belong to master quote'
        );
        System.assert(
            result.get(1).Product2.ExtID__c == officeItems.get(1).Product2.ExtID__c,
            'quote line item 2 product external id should match with the one from technical quote'
        );
        System.assert(
            result.get(1).IsMultiProductTechnicalQLI__c == false,
            'quote line item 2 should be technical qli'
        );
        System.assert(
            result.get(2).QuoteId == masterQuote.Id,
            'quote line item 3 must belong to master quote'
        );
        System.assert(
            result.get(2).Product2.ExtID__c == ccItems.get(0).Product2.ExtID__c,
            'quote line item 3 product external id should match with the one from technical quote'
        );
        System.assert(
            result.get(2).IsMultiProductTechnicalQLI__c == false,
            'quote line item 3 should be technical qli'
        );
    }

    @IsTest
    private static void testUpdateQuoteLineItems() {
        Triggers.switchOff();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
        TriggerHandler.BY_PASS_QUOTE_ON_UPDATE = true;
        TriggerHandler.BY_PASS_QUOTE_ON_INSERT = true;
        Account masterAccount = TestDataGenerator.createAccount('Master');
        Opportunity masterOpp = TestDataGenerator.createOpportunity(masterAccount);
        Quote masterQuote = TestDataGenerator.createQuote(masterOpp);

        Product2 pOffice1 = TestDataGenerator.createProduct2('OFFICE1');
        Product2 pOffice2 = TestDataGenerator.createProduct2('OFFICE2');
        Product2 pCC1 = TestDataGenerator.createProduct2('CC1');

        QuoteLineItem masterQLI1 = TestDataGenerator.createQuoteLineItem(masterQuote, pOffice1);
        QuoteLineItem masterQLI2 = TestDataGenerator.createQuoteLineItem(masterQuote, pOffice2);
        QuoteLineItem masterQLI3 = TestDataGenerator.createQuoteLineItem(masterQuote, pCC1);

        Pricebook2 pbOffice = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Pricebook2 pbCC = TestDataGenerator.createPricebook2(QuoteHelper.NGBS_RCCC_PRODUCT);

        PricebookEntry spbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, null);
        PricebookEntry spbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, null);
        PricebookEntry spbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, null);

        PricebookEntry pbeOffice1 = TestDataGenerator.createPricebookEntry(pOffice1, pbOffice);
        PricebookEntry pbeOffice2 = TestDataGenerator.createPricebookEntry(pOffice2, pbOffice);
        PricebookEntry pbeCC1 = TestDataGenerator.createPricebookEntry(pCC1, pbCC);

        BillingWrappers.Params params = new BillingWrappers.Params();
        BillingWrappers.CartItem office1 = TestDataGenerator.createCartItemBilling(
            'Office 1',
            'OFFICE1',
            false,
            null
        );
        BillingWrappers.CartItem office2 = TestDataGenerator.createCartItemBilling(
            'Office 2',
            'OFFICE2',
            false,
            null
        );
        BillingWrappers.CartItem rcc1 = TestDataGenerator.createCartItemBilling(
            'CC 1',
            'CC1',
            false,
            null
        );

        Map<String, BillingWrappers.CartItem[]> items = new Map<String, BillingWrappers.CartItem[]> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => new List<BillingWrappers.CartItem>{
                office1, office2
            },
            QuoteHelper.NGBS_RCCC_PRODUCT => new List<BillingWrappers.CartItem>{
                rcc1
            }
        };

        BillingWrappers.QuoteWrapper officeQuoteInfo = new BillingWrappers.QuoteWrapper();
        BillingWrappers.QuoteWrapper rccQuoteInfo = new BillingWrappers.QuoteWrapper();

        Map<String, BillingWrappers.QuoteWrapper> quoteInfoByService = new Map<String, BillingWrappers.QuoteWrapper> {
            QuoteHelper.NGBS_OFFICE_PRODUCT => officeQuoteInfo,
            QuoteHelper.NGBS_RCCC_PRODUCT => rccQuoteInfo
        };

        List<String> serviceNames = new List<String>(items.keySet());
        Map<String, Account> serviceAccounts = AccountHelper.createTechnicalAccounts(masterAccount.Id, serviceNames);
        Map<String, Opportunity> serviceOpportunities = OpportunityHelper.createTechnicalOpportunities(masterOpp.Id, serviceAccounts, serviceNames);
        Map<String, Quote> serviceQuotes = QuoteHelper.upsertTechnicalQuotes(masterQuote, quoteInfoByService, serviceOpportunities);

        Map<String, List<QuoteLineItem>> qlis = QuoteLineItemHelper.upsertTechnicalQuoteLineItems(masterQuote.Id, items);
        System.debug(qlis);

        Triggers.switchOn();
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = false;
        TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = false;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = false;
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = false;
        TriggerHandler.BY_PASS_QUOTE_ON_UPDATE = false;
        TriggerHandler.BY_PASS_QUOTE_ON_INSERT = false;

        Test.startTest();
        List<QuoteLineItem> masterQlis = QuoteLineItemHelper.copyQuoteLineItemsToMasterQuote(masterQuote.Id);

        List<QuoteLineItem> officeQuoteItems = qlis.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        List<QuoteLineItem> ccQuoteItems = qlis.get(QuoteHelper.NGBS_RCCC_PRODUCT);

        System.assert(
            !officeQuoteItems.isEmpty(),
            'has office quote line items: ' + officeQuoteItems.size()
        );
        System.assert(
            !ccQuoteItems.isEmpty(),
            'has cc quote line items: ' + ccQuoteItems.size()
        );
        System.assert(
            masterQlis.size() == officeQuoteItems.size() + ccQuoteItems.size(),
            'number of master qlis is sum of service qlis: ' + masterQlis.size() + ' == '
                + officeQuoteItems.size() + ' + '
                + ccQuoteItems.size()
        );
        Test.stopTest();
    }

    @isTest
    private static void testSetOverageThresholdOnInsert() {

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.IsActive => true,
                    Product2.Family => ValueProviderBuilder.provideList(new List<String>{
                        Product2Helper.FAMILY_ADDONS, Product2Helper.FAMILY_CCSERVICE, Product2Helper.FAMILY_OVERAGE
                    }),
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                    Product2.Product_Type__c => ValueProviderBuilder.provideList(new List<String>{
                        null, Product2Helper.PRODUCT_TYPE_SEAT, null
                    }),
                    Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{
                        'null_test', 'test_seat', 'Overage_test'
                    })
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        Product2 testSeatProduct;
        Product2 testAddOnProduct;
        Product2 testOverageProduct;
        for (Product2 p : testProducts) {
            if (p.Family == Product2Helper.FAMILY_ADDONS) {
                testAddOnProduct = p;
            } else if (p.Family == Product2Helper.FAMILY_CCSERVICE) {
                testSeatProduct = p;
            } else if (p.Family == Product2Helper.FAMILY_OVERAGE) {
                testOverageProduct = p;
            }
        }

        Pricebook2 testCCPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Pricebook2.Name => ValueProviderBuilder.provideUniqueString('Test Contact Center Price Book'),
                    Pricebook2.IsActive => true,
                    Pricebook2.Service__c => 'Contact Center',
                    Pricebook2.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 100,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .quantity(3)
            .create();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testCCPriceBook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 100,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        PricebookEntry testSeatPbe;
        PricebookEntry testAddOnPbe;
        PricebookEntry testOveragePbe;
        for (PricebookEntry pbe : pbeList) {
            if (pbe.Product2Id == testAddOnProduct.Id) {
                testAddOnPbe = pbe;
            } else if (pbe.Product2Id == testSeatProduct.Id) {
                testSeatPbe = pbe;
            } else if (pbe.Product2Id == testOverageProduct.Id) {
                testOveragePbe = pbe;
            }
        }

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => testOpp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                    Quote.PriceBook2Id => testCCPriceBook.Id
                }
            )
            .create()
            .getRecord();
        OpportunityTotals.bypassOpportnuityUpdate = true;
        QuoteLineItem testSeatQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.Product2Id => testSeatProduct.Id,
                    QuoteLineItem.UnitPrice => testSeatPbe.UnitPrice,
                    QuoteLineItem.PricebookEntryId => testSeatPbe.Id
                }
            )
            .create()
            .getRecord();
        OpportunityTotals.bypassOpportnuityUpdate = false;
        QuoteLineItem testAddOnQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => 3,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.Product2Id => testAddOnProduct.Id,
                    QuoteLineItem.UnitPrice => testAddOnPbe.UnitPrice,
                    QuoteLineItem.PricebookEntryId => testAddOnPbe.Id
                }
            )
            .build()
            .getRecord();

        Test.startTest();

        List<QuoteLineItem> reselectedSeat = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String>{
                'Quantity', 'UnitPrice', 'QuoteId', 'PricebookEntryId', 'Deactivated__c', 'Product_Type__c',
                'Product2Id', 'Product2.Add_Overages__c', 'Product2.Product_Type__c', 'Product2.Family'
            })
            .setCondition('Id = \'' + testSeatQli.Id + '\'')
            .executeQuery();

        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>(
            (List<PricebookEntry>) new PricebookEntrySelector()
                .getContactCenterPBEs('Pricebook2Id = \'' + testCCPriceBook.Id + '\'')
                .selectFields(new List<String>{
                    'Product2.CatId__c'
                })
                .executeQuery()
        );
        List<QuoteLineItem> result = QuoteLineItemHelper.getOveragesOnInsert(
            new List<QuoteLineItem>{testAddOnQli},
            pbeMap,
            new List<Entitlement__c>(),
            reselectedSeat,
            new List<Quote>{testQuote}
        );
        System.assert(result != null && result.size() == 1, 'method should return 1 overage');

        QuoteLineItem overageForInsert = result.get(0);
        System.assertEquals(1, overageForInsert.Quantity, 'Quantity should be 1');
        System.assertEquals(testAddOnQli.Quantity, overageForInsert.Threshold__c, 'Threshold__c should be equal to Addon Quantity');

        Product2 storageRetrieval = new Product2(
            CatID__c = Product2Helper.CATID_STORAGE_RETRIEVAL,
            Family = Product2Helper.FAMILY_OVERAGE,
            Id = getFakeId(Product2.sObjectType)
        );
        Product2 ccSeatProduct = new Product2(
            Name = 'Contact Center Seat',
            IsActive = true,
            Product_Type__c = 'Seat',
            CatID__c = new List<String>(Product2Helper.CATID_GLOBAL_SEATS)[0],
            Family = Product2Helper.FAMILY_CCSERVICE,
            Id = getFakeId(Product2.sObjectType)
        );
        Formula.recalculateFormulas(new List<SObject>{storageRetrieval, ccSeatProduct});
        PricebookEntry storageRetrievalPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPriceBookId(),
            Product2Id = storageRetrieval.Id,
            Product2 = storageRetrieval,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false,
            Id = getFakeId(PricebookEntry.sObjectType));
        PricebookEntry ccSeatProductStdPBE = new PricebookEntry(
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = ccSeatProduct.Id,
            Product2 = ccSeatProduct,
            Id = getFakeId(PricebookEntry.sObjectType)
        );

        QuoteLineItem testGlobalSeatQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.Product2Id => ccSeatProduct.Id,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.PricebookEntryId => ccSeatProductStdPBE.Id
                }
            )
            .build()
            .getRecord();

        result = QuoteLineItemHelper.getOveragesOnInsert(
            new List<QuoteLineItem>{testGlobalSeatQli},
            new Map<Id, PricebookEntry>{
                ccSeatProductStdPBE.Id => ccSeatProductStdPBE,
                storageRetrievalPBE.Id => storageRetrievalPBE
            },
            new List<Entitlement__c>(),
            new List<QuoteLineItem>(),
            new List<Quote>{testQuote}
        );
        System.assert(result != null && result.isEmpty(), 'Default Storage retrieval should not be added with global seat');

        Test.stopTest();
    }

    @isTest
    static void testIsChangePackageFromCCLegacyToStandalone() {
        String quotePackageInfo = '[{"id":"1956","version":"2","packageInfo":{"id":81591013,"catalogId":"1956","version":"2","name":"RingCentral MVP Premium - Global Unlimited",'
            + '"displayName":"RingCentral MVP Premium - Global Unlimited","oldPackageName":"RingCentral MVP Premium - Global Unlimited"},"productName":"Office",'
            + '"existingPackageInfo":{"id":"1956","version":"2","offerType":"Regular","productName":"Office"}},{"id":"803","version":"2","packageInfo":{"id":84421013,"catalogId":"803",'
            + '"version":"2","name":"Premium Edition (3 ports) Named Seat (USD)","displayName":"Premium Edition (3 ports) Named Seat (USD)","oldPackageName":"Migrated Legacy (USD)"},'
            + '"productName":"RingCentral Contact Center","productId":"22","existingPackageInfo":{"id":"880","version":"1","productName":"RingCentral Contact Center"}}]';

        Triggers.switchOff();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Package_Info__c => quotePackageInfo
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Product2.ExtID__c => QuoteLineItemHelper.RCCC_EES_BRONZE
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => testPbe.Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.PackageInfo__c => TestDataGenerator.TEST_DEVICE_PACKAGE_INFO
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        List<QuoteLineItem> reselectedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(
                new Set<String>{
                    'Quote.Package_Info__c'
                }
            )
            .executeQuery();

        Test.startTest();
        Boolean isChangePackageFromCCLegacyToStandalone = QuoteLineItemHelper.isChangePackageFromCCLegacyToStandalone(reselectedQlis);
        Test.stopTest();

        Assert.areEqual(isChangePackageFromCCLegacyToStandalone, true, 'Package changing is from CC Legacy to CC Standalone');
    }

    @IsTest
    private static void testGetProvisioningToQLIListMap_null() {
        Test.startTest();
        Map<String, List<QuoteLineItem>> provisioningToQLIListMap = QuoteLineItemHelper.getProvisioningToQLIListMap(null, false);
        Test.stopTest();

        System.assertEquals(
            true,
            provisioningToQLIListMap.isEmpty(),
            'return value should be empty map'
        );
    }

    @IsTest
    private static void testGetProvisioningToQLIListMap_emptyList() {
        Test.startTest();
        Map<String, List<QuoteLineItem>> provisioningToQLIListMap = QuoteLineItemHelper.getProvisioningToQLIListMap(new List<QuoteLineItem>(), false);
        Test.stopTest();

        for (String provisioning : provisioningToQLIListMap.keySet()) {
            System.assertEquals(
                true,
                provisioningToQLIListMap.get(provisioning).isEmpty(),
                'should be no QuoteLineItems for each provisioning'
            );
        }
    }

    @IsTest
    private static void testGetProvisioningToQLIListMap() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, 'Monthly')
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> reselectedQLIList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForOrderCreationProcess()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{
                qliList
            })
            .executeQuery();

        Test.startTest();
        Map<String, List<QuoteLineItem>> provisioningToQLIListMap = QuoteLineItemHelper.getProvisioningToQLIListMap(reselectedQLIList, false);
        Test.stopTest();

        System.assertEquals(
            2,
            provisioningToQLIListMap.keySet().size(),
            'QuoteLineItems should be distributed into 2 provisioning'
        );

        Map<String, String> upsellTypeToProvisioning = new Map<String, String>{
            Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE => OrderHelper.PROVISIONING_AUTO,
            'manual' => OrderHelper.PROVISIONING_MANUAL,
            'testUpsellType' => OrderHelper.PROVISIONING_MANUAL,
            null => OrderHelper.PROVISIONING_AUTO
        };

        for (String provisioning : provisioningToQLIListMap.keySet()) {
            System.assertEquals(
                2,
                provisioningToQLIListMap.get(provisioning).size(),
                'QuoteLineItems should be distributed into correct provisioning'
            );

            for (QuoteLineItem qli : provisioningToQLIListMap.get(provisioning)) {
                System.assertEquals(
                    provisioning,
                    upsellTypeToProvisioning.get(qli.Product2.UpsellType__c),
                    'QuoteLineItems should be distributed into correct provisioning'
                );
            }
        }
    }

    @isTest
    static void testGetTaxesAndFeesTable() {
        Id standardPricebookId = Test.getStandardPricebookId();
         Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => standardPricebookId,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, 'Test Product')
            .setField(Product2.Family, 'Test Family')
            .setField(Product2.ExtID__c, Product2Helper.ELEMENT_ID_E911_FEE)
            .create()
            .getRecord();

        PricebookEntry testPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, standardPricebookId)
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 100)
            .setField(PricebookEntry.IsActive, true)
            .create()
            .getRecord();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => testPBE.Id,
                QuoteLineItem.Display_Name__c => ValueProviderBuilder.provideUniqueString('test display name'),
                QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal>{
                    100, 100, 100, 200
                }),
                QuoteLineItem.Quantity => 1
            })
            .quantity(4)
            .create()
            .getRecords();

        Test.startTest();
        List<QuoteLineItem> reselectedQliList = new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<String> {
                    'NewQuantity__c',
                    'EffectivePriceNew__c',
                    'Product2.ExtID__c',
                    'Product2.Family',
                    'Display_Name__c'
                })
                .setCondition('Product2.Id = \'' + testProduct.Id + '\'')
                .executeQuery();
        List<QuoteLineItem> result = QuoteLineItemHelper.getTaxesAndFeesTable(reselectedQliList);
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'There should be 2 combined QuoteLineItems');
        for (QuoteLineItem qli : result) {
            if (qli.EffectivePriceNew__c == 100) {
                Assert.areEqual(3, qli.NewQuantity__c, 'The combined quantity for EffectivePriceNew__c 100 should be 3');
            } else if (qli.EffectivePriceNew__c == 200) {
                Assert.areEqual(1, qli.NewQuantity__c, 'The combined quantity for EffectivePriceNew__c 200 should be 1');
            }
        }
    }

    @IsTest
    static void testUpdateServiceInfo() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.IsProcessOrderSent__c => true
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Product2.Name => 'test'
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => prod.Id,
                        PricebookEntry.IsActive => true
                        // PricebookEntry.UnitPrice => 50,
                })
                .create()
                .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => prod.Id,
                        QuoteLineItem.QuoteId => qt.Id,
                        QuoteLineItem.Quantity => 1,
                        QuoteLineItem.PricebookEntryId => standardPrice.Id,
                        QuoteLineItem.UnitPrice => 10
                })
                .create()
                .getRecord();
        Triggers.switchOn();

        Test.startTest();
        qli.Quantity = 2;
        update qli;
        Test.stopTest();

        List<ServiceInfo__c> serviceInfos = (List<ServiceInfo__c>) new ServiceInfoSelector()
            .newQueryFactory()
            .selectFields(new List<String>{ 'Id', 'IsProcessOrderSent__c' })
            .setCondition('Quote__c = :bind0')
            .setQueryBindings(new List<Object>{ qt.Id })
            .executeQuery();

        System.assertEquals(1, serviceInfos.size(), 'Only one service info should be created');
        System.assertEquals(false, serviceInfos[0].IsProcessOrderSent__c, 'IsProcessOrderSent__c should be reset to false');
    }

    @IsTest
    static void testManageQuotesMapStatic() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Product2.Name => 'test'
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => prod.Id,
                        PricebookEntry.IsActive => true
                        // PricebookEntry.UnitPrice => 50,
                })
                .create()
                .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => prod.Id,
                        QuoteLineItem.QuoteId => qt.Id,
                        QuoteLineItem.Quantity => 1,
                        QuoteLineItem.PricebookEntryId => standardPrice.Id,
                        QuoteLineItem.UnitPrice => 10
                })
                .create()
                .getRecord();
        Triggers.switchOn();

        Test.startTest();
        qli.Quantity = 2;
        update qli;
        Test.stopTest();

        System.assertNotEquals(null, QuoteLineItemTriggerHelper.quotesMapStatic.get(qt.Id), 'quote should be added into static map');
    }

    @isTest
    static void testIsUpsell() {

        System.assertEquals(
            false,
            QuoteLineItemHelper.isUpsell(null),
            'QuoteLineItemHelper.isUpsell should return false if passed argument is null'
        );

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.Zero_Quantity__c => true
                }
            )
            .build()
            .getRecord();
        System.assertEquals(
            false,
            QuoteLineItemHelper.isUpsell(testQli),
            'QuoteLineItemHelper.isUpsell should return false if passed QuoteLineItem has positive Quantity and Zero_Quantity__c is true'
        );

        testQli.Quantity = -10;
        testQli.Zero_Quantity__c = false;
        System.assertEquals(
            false,
            QuoteLineItemHelper.isUpsell(testQli),
            'QuoteLineItemHelper.isUpsell should return false if passed QuoteLineItem has negative Quantity and Zero_Quantity__c is false'
        );

        testQli.Quantity = 10;
        System.assertEquals(
            true,
            QuoteLineItemHelper.isUpsell(testQli),
            'QuoteLineItemHelper.isUpsell should return true if passed QuoteLineItem has positive Quantity and Zero_Quantity__c is false'
        );
    }
}