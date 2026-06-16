@isTest
private class Test_AreaCodeLineItemTriggerHelper {

    @isTest static void testQuantity(){
        // Prepare data
        Product2 testProduct = new Product2(Name = 'Test product', IsActive = true);
		insert testProduct;

        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
		insert testPriceBook;

        List <PricebookEntry> testPbes = new List <PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
		testPbes.add(standardPrice);

		PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
		testPbes.add(testPrice);
        insert testPbes;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify');
		insert testOpportunity;

        Quote testQuote = new Quote (
            Name = 'qoutetest',
        	OpportunityId = testOpportunity.Id,
        	Pricebook2Id = testPriceBook.id);
		insert testQuote;

        QuoteLineItem testQli = new QuoteLineItem (
            QuoteId=testQuote.Id,
        	Product2Id = testProduct.Id,
        	PricebookEntryId = testPrice.Id,
            Quantity = 5,
            UnitPrice = testPrice.UnitPrice);
        insert testQli;

        Area_Codes__c testAreaCode = new Area_Codes__c (Name='Test');
		insert testAreaCode;

		// Test on insert
		Test.startTest();
        List<Area_Code_Line_Item__c> aclis = new List<Area_Code_Line_Item__c>();
        for (Integer i = 0; i < 3; i++){
            aclis.add(new Area_Code_Line_Item__c(
                    Quote_Line_Item__c = testQli.Id,
                    Area_Code__c = testAreaCode.Id,
                    Quantity__c = 10
            ));
        }
		insert aclis;

        QuoteLineItem TestqliOnInsert = [SELECT Id, Quantity FROM QuoteLineItem].get(0);
        System.assertEquals(TestqliOnInsert.Quantity, 30, 'B-1850 On Area Code Line Item insert: QLI Quantity should be updated as sum of Quantities of all related Area Code Line Items' );

        // Test on update

        Area_Code_Line_Item__c aqliToUpdate = [SELECT Id, Quantity__c FROM Area_Code_Line_Item__c].get(0);
        aqliToUpdate.Quantity__c = 5;
        update aqliToUpdate;


        QuoteLineItem TestqliOnUpdate = [SELECT Id, Quantity FROM QuoteLineItem].get(0);
        System.assertEquals(TestqliOnUpdate.Quantity, 25, 'B-1850 On Area Code Line Item update: QLI Quantity should be updated as sum of Quantities of all related Area Code Line Items' );

        // Test on delete

        Area_Code_Line_Item__c aqliToDelete = [SELECT Id, Quantity__c FROM Area_Code_Line_Item__c WHERE Quantity__c = 5].get(0);
        delete aqliToDelete;


        QuoteLineItem TestqliOnDelete = [SELECT Id, Quantity FROM QuoteLineItem].get(0);
        System.assertEquals(TestqliOnDelete.Quantity, 20, 'B-1850 On Area Code Line Item delete: QLI Quantity should be updated as sum of Quantities of all related Area Code Line Items' );

        Test.stopTest();

        // Test on delete all
        delete [SELECT Id FROM Area_Code_Line_Item__c];

        QuoteLineItem TestqliOnDeleteAll = [SELECT Id, Quantity FROM QuoteLineItem].get(0);
        System.assertEquals(TestqliOnDeleteAll.Quantity, 20, 'B-1850 don\'t update QLI when no related Area Code Line Items left' );

    }

    @isTest static void testQuantitySeveralQlisWithSameAreaCode(){
        // Prepare data
        Product2 testProduct1 = new Product2(Name = 'Test product 1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test product 2', IsActive = true);
        Product2 testProduct3 = new Product2(Name = 'Test product 3', IsActive = true);
		insert new List<Product2> {testProduct1, testProduct2, testProduct3};

        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
		insert testPriceBook;

        List <PricebookEntry> testPbes = new List <PricebookEntry>();
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false
        );
		testPbes.add(standardPrice1);
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false
        );
		testPbes.add(standardPrice2);
        PricebookEntry standardPrice3 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct3.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false
        );
		testPbes.add(standardPrice3);

		PricebookEntry testPrice1 = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
		testPbes.add(testPrice1);
        PricebookEntry testPrice2 = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
		testPbes.add(testPrice2);
        PricebookEntry testPrice3 = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testProduct3.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
		testPbes.add(testPrice3);
        insert testPbes;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify');
		insert testOpportunity;

        Quote testQuote = new Quote (
            Name = 'qoutetest',
        	OpportunityId = testOpportunity.Id,
        	Pricebook2Id = testPriceBook.id);
		insert testQuote;

        List<QuoteLineItem> qlisToAdd = new List<QuoteLineItem>();

        QuoteLineItem testQli1 = new QuoteLineItem (
            QuoteId=testQuote.Id,
        	Product2Id = testProduct1.Id,
        	PricebookEntryId = testPrice1.Id,
            Quantity = 5,
            Zero_Quantity__c = false,
            UnitPrice = testPrice1.UnitPrice);

        QuoteLineItem testQli2 = new QuoteLineItem (
            QuoteId=testQuote.Id,
        	Product2Id = testProduct2.Id,
        	PricebookEntryId = testPrice2.Id,
            Quantity = 5,
            Zero_Quantity__c = false,
            UnitPrice = testPrice2.UnitPrice);

        QuoteLineItem testQli3 = new QuoteLineItem (
            QuoteId=testQuote.Id,
        	Product2Id = testProduct3.Id,
        	PricebookEntryId = testPrice3.Id,
            Quantity = 5,
            Zero_Quantity__c = false,
            UnitPrice = testPrice3.UnitPrice);
        insert new List<QuoteLineItem> {testQli1, testQli2, testQli3};

        Area_Codes__c testAreaCode = new Area_Codes__c ();
		insert testAreaCode;

        Area_Code_Line_Item__c acli1 = new Area_Code_Line_Item__c(
                        Quote_Line_Item__c = testQli1.Id,
                        Area_Code__c = testAreaCode.Id,
                        Quantity__c = 10
            );
        Area_Code_Line_Item__c acli2 = new Area_Code_Line_Item__c(
                        Quote_Line_Item__c = testQli2.Id,
                        Area_Code__c = testAreaCode.Id,
                        Quantity__c = 10
            );
        Area_Code_Line_Item__c acli3 = new Area_Code_Line_Item__c(
                        Quote_Line_Item__c = testQli3.Id,
                        Area_Code__c = testAreaCode.Id,
                        Quantity__c = 10
            );

		// Test on insert
		Test.startTest();
		insert new List<Area_Code_Line_Item__c> {acli1, acli2, acli3};

        List<QuoteLineItem> checkQlisList = [SELECT Id, Quantity, Zero_Quantity__c FROM QuoteLineItem];

        Decimal totalQty = 0;
        for(QuoteLineItem qli : checkQlisList) {
            totalQty += QuoteLineItemHelper.getQuantity(qli);
        }

        System.assertEquals(30, totalQty);
    }

    @isTest
    static void testCopyOneLineItemFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
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

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;
        Triggers.switchOn();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Test.startTest();
            Area_Code_Line_Item__c acli = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Code_Line_Item__c.Area_Code__c => ac.Id,
                    Area_Code_Line_Item__c.Quantity__c => 1,
                    Area_Code_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .create()
                .getRecord();

            List<Area_Code_Line_Item__c> technicalAreaCodeItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAreaCodeItems.size() == 1, 'Only one technical Area Code Line Item should be created');
        System.assertEquals(techQli.Id, technicalAreaCodeItems.get(0).Quote_Line_Item__c, 'Technical Area Code Line Item is related to the wrong QLI');
    }

    @isTest
    static void testCopyTwoLineItemsFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
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

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;
        Triggers.switchOn();

        List<Area_Codes__c> ac = (List<Area_Codes__c>) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => ValueProviderBuilder.provideList(new List<String> {'test area code1', 'test area code2'})
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
        List<Area_Code_Line_Item__c> aclis = (List<Area_Code_Line_Item__c>) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Code_Line_Item__c.Area_Code__c => ValueProviderBuilder.provideList(new List<String> {ac.get(0).Id, ac.get(1).Id}),
                    Area_Code_Line_Item__c.Quantity__c => 1,
                    Area_Code_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .quantity(2)
                .create()
                .getRecords();

            List<Area_Code_Line_Item__c> technicalAreaCodeItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAreaCodeItems.size() == 2, 'Two technical Area Code Line Items should be created');
        System.assertEquals(techQli.Id, technicalAreaCodeItems.get(0).Quote_Line_Item__c, 'Technical Area Code Line Item is related to the wrong QLI');
        System.assertEquals(techQli.Id, technicalAreaCodeItems.get(1).Quote_Line_Item__c, 'Technical Area Code Line Item is related to the wrong QLI');
    }

    @isTest
    static void testUpdateLineItemFromMasterToTechnicalQli() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
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

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;
        Triggers.switchOn();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Test.startTest();
            Area_Code_Line_Item__c masterAcli = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Code_Line_Item__c.Area_Code__c => ac.Id,
                    Area_Code_Line_Item__c.Quantity__c => 1,
                    Area_Code_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .create()
                .getRecord();

            masterAcli.Quantity__c = 100;
            update masterAcli;

            List<Area_Code_Line_Item__c> technicalAreaCodeItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAreaCodeItems.size() == 1, 'Only one technical Area Code Line Item should be created');
        System.assertEquals(techQli.Id, technicalAreaCodeItems.get(0).Quote_Line_Item__c, 'Technical Area Code Line Item is related to the wrong QLI');
        System.assertEquals(masterAcli.Quantity__c, technicalAreaCodeItems.get(0).Quantity__c,
            'Quantity on technical Area Code Line Item should be the same as on master Area Code Line Item');
    }

    @isTest
    static void testDeleteLineItemsOnTechnicalQlisOnMasterDelete() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
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

        QuoteLineItem masterQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => mpStruct.masterQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.IsMultiProductTechnicalQLI__c => false
            })
            .create()
            .getRecord();

        QuoteLineItem techQli = mpStruct.technicalQLIs.values().get(0).get(0);
        techQli.MasterQLI__c = masterQli.Id;
        update techQli;
        Triggers.switchOn();

        Area_Codes__c ac = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'test area code'
            })
            .create()
            .getRecord();

        Test.startTest();
            Area_Code_Line_Item__c masterAcli = (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Area_Code_Line_Item__c.Area_Code__c => ac.Id,
                    Area_Code_Line_Item__c.Quantity__c => 1,
                    Area_Code_Line_Item__c.Quote_Line_Item__c => masterQli.Id
                })
                .create()
                .getRecord();

            delete masterAcli;

            List<Area_Code_Line_Item__c> technicalAreaCodeItems = (List<Area_Code_Line_Item__c>) new AreaCodeLineItemSelector()
                .selectTechnicalItemsByMasterQliId(new List<Object> {new List<Id> {masterQli.Id}})
                .executeQuery();
        Test.stopTest();

        System.assert(technicalAreaCodeItems.isEmpty(), 'Technical Area Code Line Item should be created');
    }
}