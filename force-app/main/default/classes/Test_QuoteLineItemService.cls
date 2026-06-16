@isTest
private class Test_QuoteLineItemService {

    private static List<String> CURRENCY_LIST = new List<String>{'USD', 'EUR', 'CAD', 'GBP', 'AUD', 'SGD', 'INR'};

    @isTest static void test_insertQuoteLineItems() {
        Opportunity opp = TestDataGenerator.createOpportunity(null);
        Quote quote = TestDataGenerator.createQuote(opp);

        List<BillingWrappers.BillingProduct> products = new List<BillingWrappers.BillingProduct>();
        products.add(TestDataGenerator.createBillingProduct('Subscription', 'LC_SC_1', 'SC'));
        products.add(TestDataGenerator.createBillingProduct('Subscription 2', 'LC_SC_2', 'SC'));

        List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();
        cartItems.add(TestDataGenerator.createCartItemBilling('Subscription', 'LC_SC_1', false, null));
        cartItems.add(TestDataGenerator.createCartItemBilling('Subscription 2', 'LC_SC_2', false, null));

        RestContext.request = new RestRequest();

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.quoteId = quote.Id;
                            params.items = cartItems;
                            params.products = products;

        Test.startTest();
        params.action = 'syncProducts';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        params.action = 'insertQuoteLineItems';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();
        Test.stopTest();

        List<QuoteLineItem> listQli = [select Id, Product2.Name, Product2.ExtID__c from QuoteLineItem where QuoteId =: quote.Id];

        System.assertEquals(2, listQli.size());
    }

    @isTest static void test_deleteQuoteLineItems() {
        Opportunity opp = TestDataGenerator.createOpportunity(null);
        Quote quote = TestDataGenerator.createQuote(opp);

        List<BillingWrappers.BillingProduct> products = new List<BillingWrappers.BillingProduct>();
        products.add(TestDataGenerator.createBillingProduct('Subscription', 'LC_SC_1', 'SC'));
        products.add(TestDataGenerator.createBillingProduct('Subscription 2', 'LC_SC_2', 'SC'));


        List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();
        cartItems.add(TestDataGenerator.createCartItemBilling('Subscription', 'LC_SC_1', false, null));
        cartItems.add(TestDataGenerator.createCartItemBilling('Subscription 2', 'LC_SC_2', false, null));

        RestContext.request = new RestRequest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.quoteId = quote.Id;
        params.items = cartItems;
        params.products = products;
        params.catalogIds = new Set<String> { 'LC_SC_1' };

        Triggers.switchOff();
        params.action = 'syncProducts';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        params.action = 'insertQuoteLineItems';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        List<QuoteLineItem> list1 = [select Id, Product2.Name, Product2.ExtID__c from QuoteLineItem where QuoteId =: quote.Id];

        Triggers.switchOn();
        Test.startTest();

        params.action = 'crop';
        params.isProServChangeOrderOpp = false;
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        List<QuoteLineItem> list2 = [select Id, Product2.Name, Product2.ExtID__c from QuoteLineItem where QuoteId =: quote.Id];

        params.action = 'delete';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        List<QuoteLineItem> list3 = [select Id, Product2.Name, Product2.ExtID__c from QuoteLineItem where QuoteId =: quote.Id];

        Test.stopTest();

        System.assertEquals(2, list1.size());
        System.assertEquals(1, list2.size());
        System.assertEquals(0, list3.size());
    }

    @isTest
    static void test_FeatureFamilyIsPrepopulated() {

        Opportunity opp = TestDataGenerator.createOpportunity(null);
        Quote quote = TestDataGenerator.createQuote(opp);

        String additionalTollFreeNumber = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"ATN","discount":{"type":"Percent","value":"3.48"},"price":"40"}';

        NGBS_New_Products_Mapping__c additionalTollFreeMapping = new NGBS_New_Products_Mapping__c(
            Name = '1',
            Feature__c = 1,
            Family__c = 'Add - Ons',
            Category_Code__c = 'ATN'
        );
        insert additionalTollFreeMapping;

        List<BillingWrappers.BillingProduct> products = new List<BillingWrappers.BillingProduct>();
        products.add(TestDataGenerator.createBillingProduct('Subscription', 'LC_SC_1', 'ATN'));

        // List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();
        // cartItems.add(TestDataGenerator.createCartItemBilling('Subscription', 'LC_SC_1', false, additionalTollFreeNumber));

        RestContext.request = new RestRequest();

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.opportunityId = opp.Id;
                            params.quoteId = quote.Id;
                            params.products = products;

        Test.startTest();
        List<Product2> productList = [SELECT Id, Feature__c, Family FROM Product2];

        params.action = 'syncProducts';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        Product2 product = [SELECT Id, Feature__c, Family FROM Product2 LIMIT 1];
        Test.stopTest();

        System.assertEquals(0, productList.size());
        System.assertEquals(1, product.Feature__c);
        System.assertEquals('Add - Ons', product.Family);
    }

    /* new tests */
    @isTest
    private static void verifyProductsIsSynced() {
        /* allow rewrite goa from cart item */
        insert new Feature_Toggle__c (GOA_Population_from_NGBS__c = true);

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType))
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, 'E911')
            .setField(Product2.ExtID__c, 'LC_E911_52')
            .setField(Product2.IsActive, false)
            .create()
            .getRecord();

        List<PricebookEntry> pbes = new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(6)
            .setField(PricebookEntry.Pricebook2Id, quote.Pricebook2Id)
            .setField(PricebookEntry.Product2Id, product.Id)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.CurrencyIsoCode, ValueProviderBuilder.provideList(CURRENCY_LIST))
            .create()
            .getRecords();

        List<String> elementIds = new List<String> {'LC_SC_29', 'LC_DL_75', 'LC_E911_52'};

        List<BillingWrappers.BillingProduct> billingProducts = new List<BillingWrappers.BillingProduct>();
        billingProducts.add(TestDataGenerator.createBillingProduct('Subscription', 'LC_SC_29', 'SC'));
        billingProducts.add(TestDataGenerator.createBillingProduct('Digital Line', 'LC_DL_75', 'SC'));
        billingProducts.add(TestDataGenerator.createBillingProduct('E911', 'LC_E911_52', 'SC'));


        // List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();
        // cartItems.add(TestDataGenerator.createCartItemBilling('Subscription', elementIds[0], false, null));
        // cartItems.add(TestDataGenerator.createCartItemBilling('Digital Line', elementIds[1], false, null));
        // cartItems.add(TestDataGenerator.createCartItemBilling('E911', elementIds[2], false, null));

        /* add incorrect goa */
        billingProducts.get(1).goa = '{"regular": "test"}';

        Response result = QuoteLineItemService.syncProducts(quote.Id, billingProducts);

        List<Product2> products = [SELECT Id, IsActive, Name, ExtID__c FROM Product2 WHERE ExtID__c IN :elementIds];
        pbes = [SELECT Id, IsActive, CurrencyIsoCode FROM PricebookEntry WHERE Product2.ExtID__c IN :elementIds];

        /* Prod depoy fix pbe.size is wrong */
        System.assertEquals(3, products.size());
        System.assertNotEquals(22, pbes.size());

        for (Product2 prod : products) {
            System.assert(prod.IsActive);
        }
        Map<String, PricebookEntry> pbeCurrencyMap = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : pbes) {
            System.assert(pbe.IsActive);
            pbeCurrencyMap.put(pbe.CurrencyIsoCode, pbe);
        }
        for (String currencyValue : CURRENCY_LIST) {
            System.assert(pbeCurrencyMap.get(currencyValue) != null);
        }
    }

    @isTest
    private static void verifyEntitlementsIsSynced() {
        Test.startTest();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId,  acc.Id)
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            // .setField(Quote.OpportunityId, ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType))
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .quantity(1)
            // .setField(Product2.Name, ValueProviderBuilder.provideList(names))
            // .setField(Product2.ExtID__c, ValueProviderBuilder.provideList(elementIds))
            .setField(Product2.Name, 'Subscription')
            .setField(Product2.ExtID__c, 'LC_SC_29')
            .setField(Product2.IsActive, true)
            .create()
            .getRecords();
        Test.stopTest();


        List<BillingWrappers.BillingEntitlement> billingEnts = new List<BillingWrappers.BillingEntitlement>();

        BillingWrappers.BillingDiscount discount = new BillingWrappers.BillingDiscount();
                        discount.value = 0;
                        discount.type = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

        BillingWrappers.NGBSAccountPackage ngbsPackage = new BillingWrappers.NGBSAccountPackage();
                        ngbsPackage.catalogId = '5';
                        ngbsPackage.version = '1';
                        ngbsPackage.currencyCode = 'USD';

        final String entFullName = 'Yealink T48S Gigabit Color Touchscreen Business Phone with 1 Expansion Module - Rental';
        final String entShortName = entFullName.abbreviate(80);
        BillingWrappers.BillingEntitlement ent = new BillingWrappers.BillingEntitlement();
        ent.elementId = 'LC_SC_29';
        ent.name = entFullName;
        ent.quantity = 1;
        ent.unitPrice = 3.50;
        // ent.effectivePrice = ;
        ent.duration = 'Monthly';
        ent.discount = discount;
        ent.billingPackage = ngbsPackage;
        ent.displayName = 'Subscription';
        ent.sortOrder = 1;

        billingEnts.add(ent);

        QuoteLineItemService.syncEntitlements(quote.Id, billingEnts);

        List<Entitlement__c> ents = new EntitlementSelector()
            .selectActiveEntitlementsForAccount(new List<Object>{new List<Id>{ acc.Id }})
            .selectField('Name')
            .executeQuery();

        System.assertEquals(1, ents.size(), 'Expected 1 entitlement, got ' + String.valueOf(ents.size()));
        System.assertEquals(entShortName, ents[0].Name, 'Entitlement name should be <= 80 symbols');
    }

    @isTest
    private static void verifyQuoteLineItemsIsUpdated() {
        List<String> names = new List<String> {'Subscription', 'Digital Line', 'E911'};
        List<String> elementIds = new List<String> {'LC_SC_29', 'LC_DL_75', 'LC_E911_52'};

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        List<Product2> products = new SObjectBuilder(Product2.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(names),
                Product2.ExtID__c => ValueProviderBuilder.provideList(elementIds),
                Product2.IsActive => true
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for (Product2 product : products) {
            pbes.addAll(
                (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
                    .quantity(4)
                    .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => quote.Pricebook2Id,
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(CURRENCY_LIST),
                        PricebookEntry.UnitPrice => 0,
                        PricebookEntry.UseStandardPrice => false
                    })
                    .build()
                    .getRecords()
            );
        }
        insert pbes;

        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (PriceBookEntry pbe : pbes) {
            if (pbe.CurrencyIsoCode == 'USD') {
                qlis.add(
                    (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                        .setFields(new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => quote.Id,
                            QuoteLineItem.PricebookEntryId => pbe.Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => 3.50
                        })
                        .build()
                        .getRecord()
                );
            }
        }
        insert qlis;

        Test.startTest();

            final Integer updatedQuantity = 5;

            // create cartItems for update(change Quantity)
            List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();

            BillingWrappers.CartItem subscriptionItem = TestDataGenerator.createCartItemBilling('Subscription', elementIds[0], false, null);
            subscriptionItem.quantity = updatedQuantity;
            cartItems.add(subscriptionItem);

            BillingWrappers.CartItem digitalLineItem = TestDataGenerator.createCartItemBilling('Digital Line', elementIds[1], false, null);
            digitalLineItem.quantity = updatedQuantity;
            cartItems.add(digitalLineItem);

            BillingWrappers.CartItem e911Item = TestDataGenerator.createCartItemBilling('E911', elementIds[2], false, null);
            e911Item.quantity = updatedQuantity;
            cartItems.add(e911Item);

            List<QuoteLineItem> result = QuoteLineItemService.insertQuoteLineItems(quote.Id, cartItems);
        Test.stopTest();

        for (QuoteLineItem qli : result) {
            System.assertEquals(updatedQuantity, qli.Quantity, 'QuoteLineItem quantity should be updated');
        }
    }

    @isTest
    private static void verifyMobileUserDiscountIsUpdatedByDLUnlimitedOnMonthlyCurrency() {
        List<String> names = new List<String> {'Digital Line Unlimited', 'Mobile User'};
        List<String> elementIds = new List<String> {Product2Helper.DL_UNL_ELEMENT_ID, Product2Helper.MOBILE_USER_ELEMENT_ID};

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        List<Product2> products = new SObjectBuilder(Product2.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(names),
                Product2.ExtID__c => ValueProviderBuilder.provideList(elementIds),
                Product2.IsActive => true
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for (Product2 product : products) {
            pbes.addAll(
                (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
                    .quantity(4)
                    .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => quote.Pricebook2Id,
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(CURRENCY_LIST),
                        PricebookEntry.UnitPrice => 0,
                        PricebookEntry.UseStandardPrice => false
                    })
                    .build()
                    .getRecords()
            );
        }
        insert pbes;

        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (PriceBookEntry pbe : pbes) {
            if (pbe.CurrencyIsoCode == 'USD') {
                qlis.add(
                    (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                        .setFields(new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => quote.Id,
                            QuoteLineItem.PricebookEntryId => pbe.Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => 49.99
                        })
                        .build()
                        .getRecord()
                );
            }
        }
        insert qlis;

        Test.startTest();

            final Integer updatedQuantity = 2;

            // create cartItems for update(change Quantity)
            List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();

            BillingWrappers.CartItem digitalLineItem = TestDataGenerator.createCartItemBilling(names[0], elementIds[0], false, null);
            digitalLineItem.quantity = updatedQuantity;
            digitalLineItem.unitPrice = 27.99;
            digitalLineItem.discount = 27.99;
            digitalLineItem.discountType = 'Currency';
            digitalLineItem.packageInfo = '{' +
                '"categoryCode":"DL-UNL",' +
                '"discount":{"value":27.99,"type":"Currency"},' +
                '"duration":"Monthly","id":"24","price":0,"version":"1","parent":"LC_DL_75","q":2,"categoryPath":"DL:DL-UNL"}';
            cartItems.add(digitalLineItem);

            BillingWrappers.CartItem mobileUserItem = TestDataGenerator.createCartItemBilling(names[1], elementIds[1], false, null);
            mobileUserItem.quantity = updatedQuantity;
            mobileUserItem.unitPrice = 34.99;
            mobileUserItem.discount = 50;
            mobileUserItem.discountType = 'Percentage';
            cartItems.add(mobileUserItem);

            List<QuoteLineItem> result = QuoteLineItemService.insertQuoteLineItems(quote.Id, cartItems);
        Test.stopTest();

        for (QuoteLineItem qli : result) {
            if (Product2Helper.isMobileUser(qli)) {
                System.assertEquals(27.99, qli.Discount_number__c, 'Discount value should be the same as on DL Unlimited');
                System.assertEquals('Currency', qli.Discount_type__c, 'Discount type should be the same as on DL Unlimited');
            }
        }
    }

    @isTest
    private static void verifyMobileUserDiscountIsUpdatedByDLUnlimitedOnAnnualCurrency() {
        List<String> names = new List<String> {'Digital Line Unlimited', 'Mobile User'};
        List<String> elementIds = new List<String> {Product2Helper.DL_UNL_ELEMENT_ID, Product2Helper.MOBILE_USER_ELEMENT_ID};

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        List<Product2> products = new SObjectBuilder(Product2.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(names),
                Product2.ExtID__c => ValueProviderBuilder.provideList(elementIds),
                Product2.IsActive => true
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for (Product2 product : products) {
            pbes.addAll(
                (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
                    .quantity(4)
                    .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => quote.Pricebook2Id,
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(CURRENCY_LIST),
                        PricebookEntry.UnitPrice => 0,
                        PricebookEntry.UseStandardPrice => false
                    })
                    .build()
                    .getRecords()
            );
        }
        insert pbes;

        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (PriceBookEntry pbe : pbes) {
            if (pbe.CurrencyIsoCode == 'USD') {
                qlis.add(
                    (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                        .setFields(new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => quote.Id,
                            QuoteLineItem.PricebookEntryId => pbe.Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => 49.99
                        })
                        .build()
                        .getRecord()
                );
            }
        }
        insert qlis;

        Test.startTest();

            final Integer updatedQuantity = 2;

            // create cartItems for update(change Quantity)
            List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();

            BillingWrappers.CartItem digitalLineItem = TestDataGenerator.createCartItemBilling(names[0], elementIds[0], false, null);
            digitalLineItem.quantity = updatedQuantity;
            digitalLineItem.unitPrice = 451;
            digitalLineItem.discount = 36;
            digitalLineItem.discountType = 'Currency';
            digitalLineItem.packageInfo = '{' +
                '"categoryCode":"DL-UNL",' +
                '"discount":{"value":36,"type":"Currency"},' +
                '"duration":"Annual","id":"24","price":0,"version":"1","parent":"LC_DL_75","q":2,"categoryPath":"DL:DL-UNL"}';
            cartItems.add(digitalLineItem);

            BillingWrappers.CartItem mobileUserItem = TestDataGenerator.createCartItemBilling(names[1], elementIds[1], false, null);
            mobileUserItem.quantity = updatedQuantity;
            mobileUserItem.unitPrice = 34.99;
            mobileUserItem.discount = 50;
            mobileUserItem.discountType = 'Percentage';
            cartItems.add(mobileUserItem);

            List<QuoteLineItem> result = QuoteLineItemService.insertQuoteLineItems(quote.Id, cartItems);
        Test.stopTest();

        for (QuoteLineItem qli : result) {
            if (Product2Helper.isMobileUser(qli)) {
                System.assertEquals(3, qli.Discount_number__c, 'Discount value should be the same as on DL Unlimited');
                System.assertEquals('Currency', qli.Discount_type__c, 'Discount type should be the same as on DL Unlimited');
            }
        }
    }


    @isTest
    private static void verifyMobileUserDiscountIsUpdatedByDLUnlimitedOnPercentage() {
        List<String> names = new List<String> {'Digital Line Unlimited', 'Mobile User'};
        List<String> elementIds = new List<String> {Product2Helper.DL_UNL_ELEMENT_ID, Product2Helper.MOBILE_USER_ELEMENT_ID};

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        List<Product2> products = new SObjectBuilder(Product2.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(names),
                Product2.ExtID__c => ValueProviderBuilder.provideList(elementIds),
                Product2.IsActive => true
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new List<PricebookEntry>();
        for (Product2 product : products) {
            pbes.addAll(
                (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
                    .quantity(4)
                    .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => quote.Pricebook2Id,
                        PricebookEntry.Product2Id => product.Id,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(CURRENCY_LIST),
                        PricebookEntry.UnitPrice => 0,
                        PricebookEntry.UseStandardPrice => false
                    })
                    .build()
                    .getRecords()
            );
        }
        insert pbes;

        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        for (PriceBookEntry pbe : pbes) {
            if (pbe.CurrencyIsoCode == 'USD') {
                qlis.add(
                    (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
                        .setFields(new Map<SObjectField, Object>{
                            QuoteLineItem.QuoteId => quote.Id,
                            QuoteLineItem.PricebookEntryId => pbe.Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => 49.99
                        })
                        .build()
                        .getRecord()
                );
            }
        }
        insert qlis;

        Test.startTest();

            final Integer updatedQuantity = 2;

            // create cartItems for update(change Quantity)
            List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();

            BillingWrappers.CartItem digitalLineItem = TestDataGenerator.createCartItemBilling(names[0], elementIds[0], false, null);
            digitalLineItem.quantity = updatedQuantity;
            digitalLineItem.unitPrice = 451;
            digitalLineItem.discount = 18;
            digitalLineItem.discountType = 'Percentage';
            digitalLineItem.packageInfo = '{' +
                '"categoryCode":"DL-UNL",' +
                '"discount":{"value":18,"type":"Percentage"},' +
                '"duration":"Annual","id":"24","price":0,"version":"1","parent":"LC_DL_75","q":2,"categoryPath":"DL:DL-UNL"}';
            cartItems.add(digitalLineItem);

            BillingWrappers.CartItem mobileUserItem = TestDataGenerator.createCartItemBilling(names[1], elementIds[1], false, null);
            mobileUserItem.quantity = updatedQuantity;
            mobileUserItem.unitPrice = 34.99;
            mobileUserItem.discount = 24.99;
            mobileUserItem.discountType = 'Currency';
            cartItems.add(mobileUserItem);

            List<QuoteLineItem> result = QuoteLineItemService.insertQuoteLineItems(quote.Id, cartItems);
        Test.stopTest();

        for (QuoteLineItem qli : result) {
            if (Product2Helper.isMobileUser(qli)) {
                System.assertEquals(18, qli.Discount_number__c, 'Discount value should be the same as on DL Unlimited');
                System.assertEquals('Percentage', qli.Discount_type__c, 'Discount type should be the same as on DL Unlimited');
            }
        }
    }

    @isTest
    private static void test_populateNGBSEntitlementTotals() {

        Triggers.switchOff();

        Opportunity opp = TestDataGenerator.createOpportunity(null);
        Quote quote = TestDataGenerator.createQuote(
            opp,
            null,
            QuoteHelper.STATUS_UPSELL,
            false
        );

        QuoteLineItem testQli = TestDataGenerator.createQuoteLineItem(quote);

        Entitlement__c entl = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Account__c => opp.AccountId,
                    Entitlement__c.Quote__c => quote.Id,
                    Entitlement__c.Product__c => testQli.Product2Id,
                    Entitlement__c.Quantity__c => 1,
                    Entitlement__c.Price__c => 10
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        testQli.Entitlement__c = entl.Id;
        update testQli;

        RestContext.request = new RestRequest();

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.quoteId = quote.Id;

        Test.startTest();
            params.action = 'populateNGBSEntitlementTotals';
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteLineItemService.handleRequest();
        Test.stopTest();

        List<Quote> reselectedQuotes = [select Id, Entitlement_Total_ARR__c, Entitlement_Total_MRR__c from Quote where Id =: quote.Id];
        Quote reselectedTestQuote = reselectedQuotes.get(0);
        System.assert(
            reselectedTestQuote.Entitlement_Total_ARR__c != null,
            'Quote.Entitlement_Total_ARR__c shouldbe populated'
        );
        System.assert(
            reselectedTestQuote.Entitlement_Total_MRR__c != null,
            'Quote.Entitlement_Total_MRR__c shouldbe populated'
        );
    }

    @isTest
    private static void verifyCurrentServiceIsFilledAfterSyncEntitlements() {

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .quantity(1)
            .setField(Product2.Name, 'Engage Digital named seat')
            .setField(Product2.ExtID__c, 'SA_SEAT_3')
            .setField(Product2.IsActive, true)
            .create()
            .getRecords();

        List<BillingWrappers.BillingEntitlement> billingEnts = new List<BillingWrappers.BillingEntitlement>();

        BillingWrappers.BillingDiscount discount = new BillingWrappers.BillingDiscount();
        discount.value = 0;
        discount.type = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

        BillingWrappers.NGBSAccountPackage ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        ngbsPackage.catalogId = '581';
        ngbsPackage.version = '1';
        ngbsPackage.currencyCode = 'USD';

        BillingWrappers.BillingEntitlement ent = new BillingWrappers.BillingEntitlement();
        ent.elementId = 'SA_SEAT_3';
        ent.isPrimaryLicenseType = true;
        ent.name = 'Engage Digital named seat';
        ent.quantity = 1;
        ent.unitPrice = 3.50;
        ent.duration = 'Monthly';
        ent.discount = discount;
        ent.billingPackage = ngbsPackage;
        ent.displayName = 'Engage Digital named seat';
        ent.sortOrder = 1;

        billingEnts.add(ent);

        Test.startTest();
            QuoteLineItemService.syncEntitlements(testQuote.Id, billingEnts);
        Test.stopTest();

        List<Entitlement__c> ents = new EntitlementSelector()
            .selectActiveEntitlementsForAccount(new List<Object>{new List<Id>{ acc.Id }})
            .selectField('Name')
            .executeQuery();

        System.assertEquals(1, ents.size(), 'Expected 1 entitlement, got ' + String.valueOf(ents.size()));
        Entitlement__c createdEntitlement = ents.get(0);

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotes()
            .selectFields(
                new Set<Schema.SObjectField>{
                    Quote.CurrentService__c
                }
            )
            .setCondition('Id = :bind0')
            .setQueryBindings(
                new List<Object>{ testQuote.Id }
            )
            .executeQuery()
            .get(0);

        System.assertEquals(
            createdEntitlement.Id,
            reselectedQuote.CurrentService__c,
            'Quote.CurrentService__c should be equal to entitlement with isPrimaryLicenseType = true, but got "' + reselectedQuote.CurrentService__c + '"'
        );
    }

    @isTest
    private static void testFindPrimaryLicenseEntitlementId() {

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('testProduct'),
                Product2.ExtID__c => ValueProviderBuilder.provideList(
                    new List<String>{ 'SA_SEAT_3', 'SA_SFDCAPP_9' }
                ),
                Product2.IsActive => true
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Entitlement__c> testEntitlements = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => ValueProviderBuilder.provideUniqueString('testEntitlement'),
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Entitlement__c.Price__c => 10,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Product__c => ValueProviderBuilder.provideParents(products),
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();

            System.assertEquals(
                null,
                QuoteLineItemService.findPrimaryLicenseEntitlementId(null, null),
                'findPrimaryLicenseEntitlementId method should return null if parameters is null'
            );

            Product2 seatProduct = products.get(0);

            Entitlement__c seatEntitlement = testEntitlements.get(0);

            System.assertEquals(
                seatEntitlement.Id,
                QuoteLineItemService.findPrimaryLicenseEntitlementId(seatProduct.Id, testEntitlements),
                'findPrimaryLicenseEntitlementId method should return null if parameters is null'
            );

        Test.stopTest();
    }

    @isTest
    private static void testFindPrimaryLicenseProductId() {

        System.assertEquals(
            null,
            QuoteLineItemService.findPrimaryLicenseProductId(null, null),
            'findPrimaryLicenseProductId method should return null if parameters is null'
        );

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_BILLING)
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(
                    new List<String>{ 'Engage Digital named seat', 'Salesforce connector' }
                ),
                Product2.ExtID__c => ValueProviderBuilder.provideList(
                    new List<String>{ 'SA_SEAT_3', 'SA_SFDCAPP_9' }
                ),
                Product2.IsActive => true
            })
            .quantity(2)
            .create()
            .getRecords();

        Product2 seatProduct = products.get(0);

        Map<String, Product2> catalogIdToProduct = new Map<String, Product2>();
        for (Product2 prod : products) {
            catalogIdToProduct.put(prod.ExtID__c, prod);
        }

        List<BillingWrappers.BillingEntitlement> billingEnts = new List<BillingWrappers.BillingEntitlement>();

        BillingWrappers.BillingEntitlement seatEntl = new BillingWrappers.BillingEntitlement();
        seatEntl.elementId = 'SA_SEAT_3';
        seatEntl.isPrimaryLicenseType = true;
        billingEnts.add(seatEntl);

        BillingWrappers.BillingEntitlement connectorEntl = new BillingWrappers.BillingEntitlement();
        connectorEntl.elementId = 'SA_SFDCAPP_9';
        connectorEntl.isPrimaryLicenseType = false;
        billingEnts.add(connectorEntl);

        Test.startTest();

            Id primaryLicenseProductId = QuoteLineItemService.findPrimaryLicenseProductId(
                billingEnts,
                catalogIdToProduct
            );

            System.assertEquals(
                seatProduct.Id,
                primaryLicenseProductId,
                'method should return an Id of Product2 with Product2.ExtID__c equal to BillingEntitlement.elementId with isPrimaryLicenseType = true'
            );

        Test.stopTest();
    }

    static void test_catchDuplicatedQuoteLineItems() {
        Opportunity opp = TestDataGenerator.createOpportunity(null);
        Quote quote = TestDataGenerator.createQuote(opp);

        List<BillingWrappers.BillingProduct> products = new List<BillingWrappers.BillingProduct>();
        products.add(TestDataGenerator.createBillingProduct('Subscription', 'LC_SC_1', 'SC'));

        List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>();
        cartItems.add(TestDataGenerator.createCartItemBilling('Subscription', 'LC_SC_1', false, null));

        RestContext.request = new RestRequest();

        BillingWrappers.Params params = new BillingWrappers.Params();
                            params.quoteId = quote.Id;
                            params.items = cartItems;
                            params.products = products;

        Test.startTest();
        params.action = 'syncProducts';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        params.action = 'insertQuoteLineItems';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();

        params.action = 'insertQuoteLineItems';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
        QuoteLineItemService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Response parsedBody = (Response) JSON.deserialize(body, Response.class);
        List<Response.ResponseMessage> responseMessages = (List<Response.ResponseMessage>) parsedBody.messages;
        System.assertEquals(true, responseMessages[0].message.contains(QuoteLineItemService.DUPLICATED_QLI_MESSAGE),
        'Duplicated QLIs should be catched during insert');
    }

    @isTest
    private static void testQuoteLineItemsTargetPriceInfoIsUpdated() {
        String name = 'Digital Line Unlimited';
        String elementId = 'LC_DL-UNL_50';

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => ValueProviderBuilder.provideGenericParent(Opportunity.SObjectType),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString(name),
                Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(elementId),
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => quote.Pricebook2Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.IsActive => true,
                PricebookEntry.CurrencyIsoCode => ValueProviderBuilder.provideList(CURRENCY_LIST),
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => quote.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.UnitPrice => 29.00,
                QuoteLineItem.PackageInfo__c => '{}',
                QuoteLineItem.Package_Info_QLI__c => '{}',
                QuoteLineItem.Package_Info__c => '{}'
            })
            .create()
            .getRecord();

        Test.startTest();
            String testPackageInfo = '{"categoryCode":"DL-UNL","discount":{"value":0,"type":"Money"},"duration":"Monthly","id":"1952","version":"2","q":100,"lbox":{"elementID":null,"min":null,"max":null},"categoryPath":"DL:DL-UNL","partnerInfo":null,"targetPriceCalculations":{"targetPrice":"USD 17.26","recommendedDiscount":"33.59"}}';
            BillingWrappers.CartItem digitalLineItem = TestDataGenerator.createCartItemBilling(name, elementId, false, testPackageInfo);
            digitalLineItem.id = qli.Id;
            List<BillingWrappers.CartItem> cartItems = new List<BillingWrappers.CartItem>{ digitalLineItem };

            RestContext.request = new RestRequest();

            BillingWrappers.Params params = new BillingWrappers.Params();
            params.quoteId = quote.Id;
            params.items = cartItems;
            params.action = 'updateTargetPriceInfo';
            RestContext.request.requestBody = Blob.valueOf(JSON.serialize(params));
            QuoteLineItemService.handleRequest();

            List<QuoteLineItem> updatedQlis = new QuoteLineItemSelector()
                .selectQuoteLineItemsByQuoteIds(quote.Id)
                .executeQuery();
        Test.stopTest();

        System.assert(!updatedQlis.isEmpty(), 'List of Quote Line Items are not empty');
        QuoteLineItem updatedQli = updatedQlis.get(0);
        System.assertNotEquals(null, updatedQli, 'Quote Line Items was selected');
        BillingWrappers.QLIPackageInfo pInfo = BillingWrappers.parseQLIPackageInfo(updatedQli.PackageInfo__c);
        System.assert(!String.isEmpty(pInfo.targetPriceCalculations.targetPrice), 'Target Price must be populated in Package info');
        System.assertEquals('USD 17.26', pInfo.targetPriceCalculations.targetPrice, 'Target Price should be the same');
    }

    @isTest
    private static void testCreateOneTimeProservQLIForChangeOrder(){
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .quantity(2)
            .create()
            .getRecords();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => ValueProviderBuilder.provideList(new List<Id>{
                    opps[0].Id,
                    opps[1].Id
                }),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
            })
            .quantity(2)
            .create()
            .getRecords();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuotes[0].Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 10,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.EffectivePriceNew__c => 50
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuotes[0].Id,
                Order.OpportunityId => opps[0].Id
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    OrderItem.OrderId => testOrder.Id,
                    OrderItem.Quantity => qli.Quantity,
                    OrderItem.UnitPrice => qli.UnitPrice,
                    OrderItem.PriceBookEntryId => standardPricebookEntry.Id,
                    OrderItem.Product2Id => product.Id,
                    OrderItem.QuoteLineItemId => qli.Id,
                    OrderItem.Not_Shipped_Phones__c => 8
                })
                .create()
                .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_BILLED
            })
            .create()
            .getRecord();

        SuborderLineItem__c testSuborderLineItem = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c	 => testSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 5
            })
            .create()
            .getRecord();

        BillingWrappers.NGBSAccountPackage ngbsPackage = new BillingWrappers.NGBSAccountPackage();
        ngbsPackage.catalogId = '581';
        ngbsPackage.version = '10';
        ngbsPackage.currencyCode = 'USD';

        Triggers.switchOn();

        BillingWrappers.NGBSAccountPackage testProServPackage = new BillingWrappers.NGBSAccountPackage();
        testProServPackage.id = (String) ValueProviderBuilder.provideUniqueString().getValue();
        testProServPackage.catalogId = '5';
        testProServPackage.version = '1';

        BillingWrappers.Params params = new BillingWrappers.Params();
        params.action = 'createQuoteLineItemsForChangeOrder';
        params.orderId = testOrder.Id;
        params.quoteId = testQuotes[1].Id;

        params.proServPackage = testProServPackage;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            QuoteLineItemService.handleRequest();
        Test.stopTest();

        List<QuoteLineItem> result = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(testQuotes[1].Id)
            .executeQuery();

        Assert.areEqual(1, result.size(), 'QuoteLineItem should be created');
        Assert.areEqual(7, result[0].DeliveredQuantity__c, 'Delivered quantity should be 7');
        Assert.areEqual(1, result[0].Quantity, 'Quantity should be 1');
    }
}