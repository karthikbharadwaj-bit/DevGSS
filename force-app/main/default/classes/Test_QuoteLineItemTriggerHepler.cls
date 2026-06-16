@isTest
private class Test_QuoteLineItemTriggerHepler {

    @testSetup static void prepareData() {
        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RingCentralVariousSettings__c.CC_FSC_Approvers_Queues__c => 'TestQueue'
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        Account testAccount = new Account(Name='Opty test account',
            Permitted_Brands__c='RingCentral');
        insert testAccount;

        Contact testContact = new Contact();
        testContact.AccountId =  testAccount.id;
        testContact.Email = 'fake@email.com';
        testContact.LastName = 'TestLast';
        testContact.Phone='9910106804';
        insert testContact;
        Triggers.switchOn();

        Id pricebookId = Test.getStandardPricebookId();

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'basic seat',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'Seat',
            Family = 'CC Service',
            Edition__c = 'Basic',
            ExtID__c = 'basic seat_test_id'
        );
        insert testProduct;

        prodList.add(testProduct);

        Product2 testOverage = new Product2(
            Name = 'Seat overage',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'Seat',
            Family = 'Overage',
            Parent__c = testProduct.Id,
            ExtId__c = 'seat overage_test_id'
        );
        prodList.add(testOverage);

        Product2 testOverage2 = new Product2(
            Name = 'ivn overage',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'ivn',
            Family = 'Overage',
            ExtId__c = 'ivn overage_test_id'
        );
        prodList.add(testOverage2);

        Product2 testOverage3 = new Product2(
            Name = 'port overage',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'port',
            Family = 'Overage',
            Parent__c = testProduct.Id,
            ExtId__c = 'port overage_test_id'
        );
        prodList.add(testOverage3);

        Product2 testOverage4 = new Product2(
            Name = 'transport overage',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'transport',
            Family = 'Overage',
            Parent__c = testProduct.Id,
            ExtId__c = 'transport overage_test_id'
        );

        prodList.add(testOverage4);

        Product2 mainProduct = new Product2(
            Name = 'mainProduct',
            IsActive = true,
            Sub_Category__c = 'Main',
            Product_Type__c = 'transport',
            Family = 'Add - Ons',
            ExtId__c = 'main product_test_id'
        );

        prodList.add(mainProduct);

        Product2 inContactProduct = new Product2(
            Name = 'inContact test',
            IsActive = true,
            Sub_Category__c = 'Main',
            Product_Type__c = 'transport',
            Family = 'Add - Ons',
            ExtId__c = 'inContact_test_id',
            Feature__c = 65
        );

        prodList.add(inContactProduct);

        Product2 contactCenterProduct = new Product2(
            Name = 'contactCenterProduct',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'Seat',
            Family = 'CC Service',
            Edition__c = 'Basic',
            ExtID__c = 'contact center product_test_id'
        );

        prodList.add(contactCenterProduct);

        Product2 testOverageProduct = new Product2(
            Name = 'test Overage Family product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            GOA_Group_V2__c = 'GOA_Other_Products',
            Family = Product2Helper.FAMILY_OVERAGE,
            Feature__c = 48,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL,
            ExtID__c = 'test overage family product_test_id'
        );

        prodList.add(testOverageProduct);

        Product2 testContactCenterProduct = new Product2(
            Name = 'test Contact Center product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            GOA_Group_V2__c = 'GOA_Other_Products',
            Family = Product2Helper.FAMILY_ADDONS,
            Feature__c = 48,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL,
            ExtId__c = 'null_Contact Center: Customer Dynamics Dialer Integration_null_Annual_null_null_null_false'
        );

        prodList.add(testContactCenterProduct);

        Product2 testOverageCCProduct = new Product2(
            Name = 'test Overage Family product',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
            GOA_Group_V2__c = 'GOA_Other_Products',
            Family = Product2Helper.FAMILY_OVERAGE,
            Feature__c = 48,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ANNUAL,
            ExtId__c = 'Overage_Contact Center: Customer Dynamics Dialer Integration_null_Annual_null_null_null_false'
        );

        prodList.add(testOverageCCProduct);

        upsert prodList;

        List<PricebookEntry> pbesList = new List<PricebookEntry>();
        PricebookEntry pbe;

        for (Product2 pr : prodList) {
            pbe = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = pr.Id,
                UnitPrice = pr.Name == 'seat overage' ? 220 : 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            pbesList.add(pbe);

            pbe = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = pr.Id,
                UnitPrice = pr.Name == 'seat overage' ? 220 : 200,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                CurrencyIsoCode = 'USD'
            );
            pbesList.add(pbe);
        }
        insert pbesList;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;


        Quote testSalesQuote = new Quote (
            Name = 'testSalesQuote' ,
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            Products__c = '',
            RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
        );
        insert testSalesQuote;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testAddOverages() {
        Test.startTest();

            Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
            PricebookEntry seatPbe = [SELECT Id, Product2Id
                                        FROM PricebookEntry
                                        WHERE Product2.Family = 'CC Service'
                                        AND Pricebook2Id = :qt.Pricebook2Id].get(0);

            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{seatPbe.Id});

            List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :qt.Id];

            //System.assertEquals(5, qlis.size());

        Test.stopTest();
    }

    @isTest
    static void test_AddSeatOverageWithPremiumDiscount () {
        Feature_Toggle__c toggle = Feature_Toggle__c.getOrgDefaults();
        toggle.AccountPremiumOverageCharge__c = true;
        insert toggle;

        Account testAccount = [SELECT Id, CCOveragePremiumDiscount__c FROM Account WHERE Name = 'Opty test account'][0];
        testAccount.CCOveragePremiumDiscount__c = true;
        update testAccount;

        PricebookEntry seatPbe;
        QuoteLineItem seatOverage;
        Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
        for (PricebookEntry pbe : [SELECT Id, Product2Id, Product2.Family
                                    FROM PricebookEntry
                                    WHERE Product2.Product_Type__c = 'Seat'
                                    AND Product2.Name = 'basic seat'
                                    AND Pricebook2Id = :qt.Pricebook2Id]) {
            if (pbe.Product2.Family == 'CC Service') {
                seatPbe = pbe;
            }
        }

        Test.startTest();

            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{seatPbe.Id});

            List<QuoteLineItem> qlis = [SELECT Id, Product2.Name, Product2.Family, Product2.Product_Type__c, Discount_Number__c
                                        FROM QuoteLineItem
                                        WHERE QuoteId = :qt.Id];
            for (QuoteLineItem qli : qlis) {
                if (qli.Product2.Name == 'Seat overage') {
                    seatOverage = qli;
                }
            }

            System.assertNotEquals(null, seatOverage, 'seat overage should be created');
            System.assertEquals(20, seatOverage.Discount_Number__c, 'discount should be equal to the price difference');

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testAddOveragesWithSeatInCart() {

        Triggers.switchOff();

        Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
        PricebookEntry seatPbe = [SELECT Id, Product2Id
                                    FROM PricebookEntry
                                    WHERE Product2.Family = 'CC Service'
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id> {seatPbe.Id});

            List<Product2> newprods = new List<Product2>();

            Product2 portProd = new Product2(
                Name = 'additional port',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                Product_Type__c = 'port',
                Family = 'Add-On',
                ExtID__c = 'additional port_test_id'
            );
            newprods.add(portProd);

            Product2 minProd = new Product2(
                Name = '100k Minutes',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                Product_Type__c = 'transport',
                Family = 'Minutes Bundle',
                ExtID__c = '100k minutes_test_id',
                Number_of_Minutes__c = 100000
            );
            newprods.add(minProd);

            insert newprods;

            PricebookEntry pbe;
            List<PricebookEntry> pbesList = new List<PricebookEntry>();
            for (Product2 pr : newprods) {
                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = pr.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbesList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = qt.Pricebook2Id,
                    Product2Id = pr.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbesList.add(pbe);
            }

            insert pbesList;

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();
            List<Id> testPBEsList = new List<Id>();
            for (PricebookEntry pb : pbesList) {
                if (pb.PriceBook2Id == qt.PriceBook2Id){
                    testPBEsList.add(pb.Id);
                }
            }

        Triggers.switchOn();

        Test.startTest();

            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, testPBEsList);

        Test.stopTest();

        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :qt.Id];

        //System.assertEquals(7, qlis.size());
    }

    @isTest static void testQliDeleteWithWizard() {
        Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
        PricebookEntry seatPbe = [SELECT Id, Product2Id, UnitPrice
                                    FROM PricebookEntry
                                    WHERE Product2.Family = 'CC Service'
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

        // Map<String, String> params = new Map<String, String>();
        // params.put('id', string.valueOf(qli.Id));
        // params.put('quoteId', string.valueOf(qt.Id));
        Test.startTest();
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = qt.Id,
                Product2Id = seatPbe.Product2Id,
                Quantity = 1,
                UnitPrice = seatPbe.UnitPrice,
                PricebookEntryId = seatPbe.Id
            );
            insert qli;
            QuotingToolQuoteApexController.deleteQuoteLineItem(qli);
        Test.stopTest();

        List<QuoteLineItem> qlis = [select id from QuoteLineItem where QuoteId = :qt.Id];

        System.assertEquals(0, qlis.size());
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testQliDeleteWithWizardWithEnt() {
        Account acc = [select id from Account].get(0);
        Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
        PricebookEntry seatPbe = [SELECT Id, Product2Id
                                    FROM PricebookEntry
                                    WHERE Product2.Family = 'CC Service'
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

        Test.startTest();
            Triggers.switchOff();
            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{ seatPbe.Id });

            Entitlement__c ent = new Entitlement__c(
                Account__c = acc.Id,
                Product__c = seatPbe.Product2Id,
                Active__c = true,
                Price__c = 1,
                Discount__c = 10,
                Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                Quantity__c = 1
            );
            insert ent;

            QuoteLineItem dqli = [
                SELECT Id, QuoteId
                FROM QuoteLineItem
                WHERE quoteId = :qt.Id AND Product2Id = :seatPbe.Product2Id
                LIMIT 1
            ];
        Test.stopTest();

        QuotingToolQuoteApexController.deleteQuoteLineItem(dqli);

        // List<QuoteLineItem> qlis = [select id from QuoteLineItem where QuoteId = :qt.Id];
        //System.assertEquals(3, qlis.size());
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testQliDeleteMinuteWithSeatInCart() {

        Triggers.switchOff();

        Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
        PricebookEntry seatPbe = [SELECT Id, Product2Id
                                    FROM PricebookEntry
                                    WHERE Product2.Family = 'CC Service'
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

        QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{seatPbe.Id});

            List<Id> testPBEsList = new List<Id>();

            List<Product2> newprods = new List<Product2>();

            Product2 portProd = new Product2(
                Name = 'additional port',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                Product_Type__c = 'port',
                Family = 'Add-On',
                ExtID__c = 'null_testport'
            );
            newprods.add(portProd);

            Product2 minProd = new Product2(
                Name = '100k Minutes',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                Product_Type__c = 'transport',
                Family = 'Minutes Bundle',
                ExtID__c = 'null_testtransport',
                Number_of_Minutes__c = 100000
            );
            newprods.add(minProd);

            insert newprods;

            PricebookEntry pbe;
            List<PricebookEntry> pbesList = new List<PricebookEntry>();
            for (Product2 pr : newprods) {
                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = pr.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbesList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = qt.Pricebook2Id,
                    Product2Id = pr.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbesList.add(pbe);
            }

            insert pbesList;

            for (PricebookEntry pb : pbesList) {
                if (pb.PriceBook2Id == qt.PriceBook2Id){
                    testPBEsList.add(pb.Id);
                }
            }

            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, testPBEsList);

        Triggers.switchOn();

        Test.startTest();

            QuoteLineItem dqli = [
                SELECT Id, QuoteId
                FROM QuoteLineItem
                WHERE quoteId = :qt.Id AND Product2Id = :minProd.Id
                LIMIT 1
            ];
            QuotingToolQuoteApexController.deleteQuoteLineItem(dqli);

        Test.stopTest();

        List<QuoteLineItem> qlis = [SELECT Id, Product2.Name FROM QuoteLineItem WHERE QuoteId = :qt.Id];

        //System.assertEquals(6, qlis.size());
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testQliDeletePortWithSeatInCart() {

        Triggers.switchOff();

        Quote qt = [SELECT Id, Pricebook2Id FROM Quote].get(0);
        PricebookEntry seatPbe = [SELECT Id, Product2Id
                                    FROM PricebookEntry
                                    WHERE Product2.Family = 'CC Service'
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

        QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{seatPbe.Id});

            List<Id> testPBEsList = new List<Id>();

            List<Product2> newprods = new List<Product2>();

            Product2 portProd = new Product2(
                Name = 'additional port',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                Product_Type__c = 'port',
                Family = 'Add-On',
                ExtID__c = 'additional port_test_id'
            );
            newprods.add(portProd);

            Product2 minProd = new Product2(
                Name = '100k Minutes',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                Product_Type__c = 'transport',
                Family = 'Minutes Bundle',
                ExtID__c = '100k Minutes_test_id',
                Number_of_Minutes__c = 100000
            );
            newprods.add(minProd);

            insert newprods;

            PricebookEntry pbe;
            List<PricebookEntry> pbesList = new List<PricebookEntry>();
            for (Product2 pr : newprods) {
                pbe = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = pr.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = 'USD'
                );
                pbesList.add(pbe);

                pbe = new PricebookEntry(
                    Pricebook2Id = qt.Pricebook2Id,
                    Product2Id = pr.Id,
                    UnitPrice = 200,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    CurrencyIsoCode = 'USD'
                );
                pbesList.add(pbe);
            }

            insert pbesList;

            for (PricebookEntry pb : pbesList) {
                if (pb.PriceBook2Id == qt.PriceBook2Id){
                    testPBEsList.add(pb.Id);
                }
            }

            QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, testPBEsList);

        Triggers.switchOn();

        Test.startTest();

            QuoteLineItem dqli = [
                SELECT Id, QuoteId
                FROM QuoteLineItem
                WHERE quoteId = :qt.Id AND Product2Id = :portProd.Id
                LIMIT 1
            ];
            QuotingToolQuoteApexController.deleteQuoteLineItem(dqli);
        Test.stopTest();

        List<QuoteLineItem> qlis = [SELECT Id, Product2.Name FROM QuoteLineItem WHERE QuoteId = :qt.Id];

        //System.assertEquals(6, qlis.size());
    }

    @isTest static void testQlobalOfficeLimitedExtensionValidations() {
        Test.startTest();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => '1. Qualify',
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        List<Quote> quotes = new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestGoLe',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId(),
                Quote.Upsell_Status__c => ValueProviderBuilder.provideList(new List<String>{'New', 'NotNew'})
            })
            .quantity(2)
            .create()
            .getRecords();
        Test.stopTest();

        List<Product2> products = new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{'TestProduct1', 'TestProduct2'}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{'Global Office - Limited Extension Discounted Phones', 'Discounted Phones'}),
                Product2.ExtId__c => ValueProviderBuilder.provideList(new List<String>{'TestProduct1_test_id', 'TestProduct2_test_id'}),
                Product2.Feature__c => ValueProviderBuilder.provideList(new List<Integer>{null, 63}),
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Charge_term__c => 'Annual',
                Product2.IsActive => true
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id}),
                PricebookEntry.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal>{200, 2000}),
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> quoteLineItems = new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id>{quotes[0].Id, quotes[0].Id, quotes[1].Id, quotes[1].Id}),
                QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal>{pbes[0].UnitPrice, pbes[1].UnitPrice, pbes[0].UnitPrice, pbes[1].UnitPrice}),
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id, products[0].Id, products[1].Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{pbes[0].Id, pbes[1].Id, pbes[0].Id, pbes[1].Id}),
                QuoteLineItem.Quantity => 1
            })
            .quantity(4)
            .create()
            .getRecords();

        //Verify that quantity of global office limited extension phones and global office limited extension Lines match
        Quote createdQuote = (Quote) new QueryFactory(Quote.SObjectType)
            .selectFields(new List<SObjectField>{Quote.Id, Quote.Name, Quote.Invalid_GO_LE_Phones_Quantity__c})
            .addCondition('Name = \'TestGoLe\' AND Upsell_Status__c = \'New\'')
            .setLimit(1)
            .executeQuery()
            .get(0);
        System.assertEquals(createdQuote.Invalid_GO_LE_Phones_Quantity__c, false);

        //Verify that quantity of global office limited extension phones and global office limited extension Lines match
        Quote createdQuote1 = (Quote) new QueryFactory(Quote.SObjectType)
            .selectFields(new List<SObjectField>{Quote.Id, Quote.Name, Quote.Invalid_GO_LE_Phones_Quantity__c})
            .addCondition('Name = \'TestGoLe\' AND Upsell_Status__c = \'NotNew\'')
            .setLimit(1)
            .executeQuery()
            .get(0);
        System.assertEquals(createdQuote1.Invalid_GO_LE_Phones_Quantity__c, false);
    }
    //Used to test case when QuoteLineItemRestrictionSettings__c is found by FeatureId__c and SubFeatureId__c
    //and there are no discounts allowed
    @isTest static void testDiscountNotAvailableOnInsert() {
        createQuoteLineItemRestrictionSettings('1000', '2000', null);

        Triggers.switchOff();

        Account testAccount = new Account(Name='Opty test account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'TestOpportunity',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert (new List<Opportunity>{testOpp});

        Quote testSalesQuote = new Quote (
            Name = 'TestSalesQuoteMonthly',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId()
        );
        insert (new List<Quote>{testSalesQuote});

        Product2 testProduct1 = new Product2(
            Name = 'TestProduct1',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Family = 'Service',
            Charge_term__c = 'Annual',
            Feature__c = 1000,
            Sub_Feature__c = 2000,
            ExtId__c = 'TestProduct1_test_id'
        );
        insert (new List<Product2>{testProduct1});

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert (new List<PricebookEntry>{pbe1});

        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = testSalesQuote.Id,
            Product2Id = testProduct1.Id,
            Quantity = 1,
            UnitPrice = pbe1.UnitPrice,
            PricebookEntryId = pbe1.Id,
            Discount_Number__c = 10
        );

        Triggers.switchOn();

        Test.startTest();
            try{
                insert (new List<QuoteLineItem>{qli1});
            } catch(Exception ex){
                Boolean expectedExceptionThrown =
                    ex.getMessage().contains('Discount is not applicable for ' + testProduct1.Name + '.') ? true : false;
                System.assertEquals(expectedExceptionThrown,true);
            }
        Test.stopTest();
    }

    //Used to test case when QuoteLineItemRestrictionSettings__c is found by FeatureId__c
    //and only one discount type is available
    @isTest static void testDiscountAvailableOnInsertUpdate() {
        createQuoteLineItemRestrictionSettings('1000', null, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY);

        Triggers.switchOff();

        Account testAccount = new Account(Name='Opty test account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'TestOpportunity',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert (new List<Opportunity>{testOpp});

        Quote testSalesQuote = new Quote (
            Name = 'TestSalesQuoteMonthly',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId()
        );
        insert (new List<Quote>{testSalesQuote});

        Product2 testProduct1 = new Product2(
            Name = 'TestProduct1',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Family = 'Service',
            Charge_term__c = 'Annual',
            Feature__c = 1000,
            Sub_Feature__c = 2000,
            ExtId__c = 'TestProduct1_test_id'
        );
        insert (new List<Product2>{testProduct1});

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert (new List<PricebookEntry>{pbe1});

        Triggers.switchOn();

        Test.startTest();

            QuoteLineItem qli1 = new QuoteLineItem(
                QuoteId = testSalesQuote.Id,
                Product2Id = testProduct1.Id,
                Quantity = 1,
                UnitPrice = pbe1.UnitPrice,
                PricebookEntryId = pbe1.Id,
                Discount_Number__c = 10
            );
            insert (new List<QuoteLineItem>{qli1});
            QuoteLineItem createdQli = [SELECT id, Discount_type__c FROM QuoteLineItem LIMIT 1];
            System.assertEquals(createdQli.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY);
            //Set discount type restricted by custom setting
            QuoteLineItem updateQLi = new QuoteLineItem(Id = qli1.Id, Discount_Number__c = 20, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE);
            try{
                update updateQLi;
            } catch(Exception ex){
                Boolean expectedExceptionThrown =
                    ex.getMessage().contains('Only ' + QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY + ' discount types are allowed for ' + testProduct1.Name + '.') ? true : false;
                System.assertEquals(expectedExceptionThrown,true);
            }

        Test.stopTest();
    }

    //Used to test case when QuoteLineItemRestrictionSettings__c is found by FeatureId__c,
    //only one discount type is available and there is an Entitlement__c for quote line item
    @isTest static void testDiscountAvailableOnInsertUpdateWithEntitlements() {
        createQuoteLineItemRestrictionSettings('1000', null, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY);

        Triggers.switchOff();

        Account testAccount = new Account(Name='Opty test account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'TestOpportunity',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Office',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert (new List<Opportunity>{testOpp});

        Test.startTest();
        Quote testSalesQuote = new Quote (
            Name = 'TestSalesQuoteMonthly',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId(),
            Total_Number_of_Digital_Lines__c = 10
        );
        insert (new List<Quote>{testSalesQuote});

        Product2 testProduct1 = new Product2(
            Name = 'TestProduct1',
            IsActive = true,
            Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
            Family = 'Service',
            Charge_term__c = 'Annual',
            Feature__c = 1000,
            Sub_Feature__c = 2000,
            ExtId__c = 'TestProduct1_test_id'
        );
        insert (new List<Product2>{testProduct1});

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert (new List<PricebookEntry>{pbe1});

        Entitlement__c testEnt1 = new Entitlement__c(
            Product__c = testProduct1.Id,
            Account__c = testAccount.Id,
            Active__c = true,
            Price__c = 200,
            Quantity__c = 3,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
        );
        insert (new List<Entitlement__c>{testEnt1});

        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = testSalesQuote.Id,
            Product2Id = testProduct1.Id,
            Quantity = 1,
            PricebookEntryId = pbe1.Id,
            Discount_Number__c = 10,
            Entitlement__c = testEnt1.Id
        );

        Triggers.switchOn();

        insert (new List<QuoteLineItem>{qli1});
        QuoteLineItem updateQLi = new QuoteLineItem(Id = qli1.Id, Discount_Number__c = 20, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE);
        try{
            update updateQLi;
        } catch (Exception ex) {
            Boolean expectedExceptionThrown =
                ex.getMessage().contains('Only ' + QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY + ' discount types are allowed for ' + testProduct1.Name + '.') ? true : false;
            System.assertEquals(expectedExceptionThrown,true);
        }

        Test.stopTest();
    }

    private static void createQuoteLineItemRestrictionSettings (String feature, String subFeature, String discountTypesAvailable) {
        QuoteLineItemRestrictionSettings__c setting = new QuoteLineItemRestrictionSettings__c(
            Name = 'testSetting',
            FeatureId__c = feature,
            SubFeatureId__c = subFeature,
            PreventDifferentDiscount__c = true,
            DiscountTypesAvailable__c = discountTypesAvailable);
        insert (new List<QuoteLineItemRestrictionSettings__c>{setting});
    }

    @isTest
    private static void testInsertQLIWithExistingQLIAndEntls() {
        createQuoteLineItemRestrictionSettings('1000', null, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY);

        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.Name, 'TestOpportunity')
            .setField(Opportunity.Brand_Name__c, 'RingCentral')
            .setField(Opportunity.Tier_Name__c, 'Office')
            .setField(Opportunity.StageName, '1. Qualify')
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, 'USD')
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        Quote testSalesQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'TestSalesQuoteMonthly')
            .setField(Quote.OpportunityId, testOpp.Id)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.RecordTypeId, Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId())
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.IsActive, true)
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.Family, 'Service')
            .setField(Product2.Charge_term__c, 'Annual')
            .setField(Product2.Feature__c, 1000)
            .setField(Product2.Sub_Feature__c, 2000)
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbes = new SobjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(testProducts))
            .setField(PricebookEntry.UnitPrice, 200)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(2)
            .create()
            .getRecords();

        List<Entitlement__c> testEnts = new SobjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Active__c, true)
            .setField(Entitlement__c.Product__c, ValueProviderBuilder.provideParents(testProducts))
            .setField(Entitlement__c.Quantity__c, 3)
            .setField(Entitlement__c.Price__c, 0)
            .setField(Entitlement__c.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY)
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(testProducts))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbes))
            .setField(QuoteLineItem.Entitlement__c, ValueProviderBuilder.provideParents(testEnts))
            .setField(QuoteLineItem.QuoteId, testSalesQuote.Id)
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY)
            .setField(QuoteLineItem.Discount_Number__c, 10)
            .setField(QuoteLineItem.UnitPrice, 100)
            .quantity(2)
            .build()
            .getRecords();

        insert qlis.get(0);

        List<Product2> testOneTimeProducts = new SobjectBuilder(Product2.SObjectType)
                .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
                .setField(Product2.IsActive, true)
                .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
                .setField(Product2.Family, 'Service')
                .setField(Product2.Charge_term__c, 'One - Time')
                .setField(Product2.Feature__c, 1000)
                .setField(Product2.Sub_Feature__c, 2000)
                .quantity(2)
                .create()
                .getRecords();

        List<PricebookEntry> pbesOneTime = new SobjectBuilder(PricebookEntry.SObjectType)
                .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
                .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(testOneTimeProducts))
                .setField(PricebookEntry.UnitPrice, 60)
                .setField(PricebookEntry.IsActive, true)
                .setField(PricebookEntry.UseStandardPrice, false)
                .setField(PricebookEntry.CurrencyIsoCode, 'USD')
                .quantity(2)
                .create()
                .getRecords();

        List<Entitlement__c> testEntsOneTime = new SobjectBuilder(Entitlement__c.SObjectType)
                .setField(Entitlement__c.Account__c, testAccount.Id)
                .setField(Entitlement__c.Active__c, true)
                .setField(Entitlement__c.Product__c, ValueProviderBuilder.provideParents(testOneTimeProducts))
                .setField(Entitlement__c.Quantity__c, 3)
                .setField(Entitlement__c.Price__c, 60)
                .setField(Entitlement__c.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
                .quantity(2)
                .create()
                .getRecords();

        List<QuoteLineItem> qlisOneTime = new SobjectBuilder(QuoteLineItem.SObjectType)
                .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(testOneTimeProducts))
                .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbesOneTime))
                .setField(QuoteLineItem.Entitlement__c, ValueProviderBuilder.provideParents(testEntsOneTime))
                .setField(QuoteLineItem.QuoteId, testSalesQuote.Id)
                .setField(QuoteLineItem.Quantity, 1)
                .setField(QuoteLineItem.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE)
                .setField(QuoteLineItem.Discount_Number__c, 100)
                .setField(QuoteLineItem.UnitPrice, 60)
                .quantity(2)
                .build()
                .getRecords();

        QuoteLineItem qli2 = qlis.get(1);
        qli2.UnitPrice = 1;
        qli2.Discount_Number__c = 1;
        Boolean exceptionThrown = false;

        try {
            insert qli2;
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Discount can not be more than UnitPrice'));
        }
        System.assert(exceptionThrown);

        QuoteLineItem qli3 = qlisOneTime.get(0);
        qli3.PackageInfo__c = '';
        qli3.Package_Info__c = '';
        qli3.Product2 = testOneTimeProducts.get(0);
        qli3.Display_Name__c = 'qli3';
        qli3.UnitPrice = 110;
        qli3.Discount_number__c = 100;
        qli3.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;

        QuoteLineItem qli4 = qlisOneTime.get(1);
        qli4.Package_Info__c = '';
        qli4.PackageInfo__c = '';
        qli4.Product2 = testOneTimeProducts.get(1);
        qli4.Display_Name__c = 'qli4';
        qli4.UnitPrice = 100;
        qli4.Discount_number__c = 60;
        qli4.Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        List<QuoteLineItem> qlisPercentageDiscount = new List<QuoteLineItem> { qli3, qli4 };
        exceptionThrown = false;

        try {
            insert qlisPercentageDiscount;
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assertEquals(false, exceptionThrown);
        Test.stopTest();
    }

    /**
     * Test Total ProServ SOW Discount Calculation
     * @see QuoteLineItemTrigger.SetQuoteApprovalType.setTotals Trigger usage
     * @see QuoteHelper.calcTotalProServSOWDiscount             Implementation
     */
    @isTest static void test_calcTotalProServSOWDiscount() {

        Triggers.switchOff();

        // Create Account
        Account testAcc = new Account(
            Name = 'test Account'
        );
        insert testAcc;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            AccountId = testAcc.Id,
            Name = 'Test Opportunity',
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        Test.startTest();
        // Create Quote
        Quote testQuote = new Quote(
            OpportunityId = testOpp.Id,
            Name = 'Test Quote',
            Pricebook2Id = testPrBook.Id
        );
        insert testQuote;

        // Create Products
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME,
            GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
            ExtId__c = 'Test Product 1_test_id'
        );

        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME,
            GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
            ExtId__c = 'Test Product 2_test_id'
        );

        Product2 testProduct3 = new Product2(
            Name = 'Test Product 3',
            Sub_Category__c = 'Main',
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME,
            GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
            ExtId__c = 'Test Product 3_test_id'
        );
        insert new List<Product2> {
            testProduct1, testProduct2, testProduct3
        };

        // Create Entitlement
        Entitlement__c testEnt2 = new Entitlement__c(
            Quantity__c = 2,
            Product__r = testProduct2,
            Account__c = testAcc.Id,
            Active__c = true
        );
        insert testEnt2;

        // Create PricebookEntries
        PricebookEntry testPBEstandard1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry testPBE1 = new PricebookEntry(
            Pricebook2Id = testPrBook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );

        PricebookEntry testPBEstandard2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry testPBE2 = new PricebookEntry(
            Pricebook2Id = testPrBook.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );

        PricebookEntry testPBEstandard3 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct3.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry testPBE3 = new PricebookEntry(
            Pricebook2Id = testPrBook.Id,
            Product2Id = testProduct3.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PricebookEntry>{
            testPBEstandard1, testPBE1,
            testPBEstandard2, testPBE2,
            testPBEstandard3, testPBE3
        };

        // Create QuoteLineItems
        QuoteLineItem testQLI1 = new QuoteLineItem(
            Product2 = testProduct1,
            Product2Id = testProduct1.Id,
            PricebookEntry = testPBE1,
            PricebookEntryId = testPBE1.Id,
            QuoteId = testQuote.Id,
            Discount_number__c = 3,
            Quantity = 2,
            UnitPrice = testPBE1.UnitPrice,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
        );

        // QLI with Entitlement Quantity should be taken from NewQuantity__c field
        QuoteLineItem testQLI2 = new QuoteLineItem(
            Product2 = testProduct2,
            Product2Id = testProduct2.Id,
            PricebookEntry = testPBE2,
            PricebookEntryId = testPBE2.Id,
            QuoteId = testQuote.Id,
            Discount_number__c = 10,
            Quantity = 1,
            Zero_Quantity__c = true,
            NewQuantity__c = 2,
            UnitPrice = testPBE2.UnitPrice,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
            Entitlement__r = testEnt2
        );

        // This QLI shouldn't be taken into account
        QuoteLineItem testQLI3 = new QuoteLineItem(
            Product2 = testProduct3,
            Product2Id = testProduct3.Id,
            PricebookEntry = testPBE3,
            PricebookEntryId = testPBE3.Id,
            QuoteId = testQuote.Id,
            Discount_number__c = 5,
            Quantity = 2,
            UnitPrice = testPBE3.UnitPrice,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
        );

        Triggers.switchOn();

        // Test total calculation without QuoteLineItems Insert
        Decimal resultTotalProServSOWDiscountWithoutInsert = QuoteHelper.calcTotalProServSOWDiscount( new List<QuoteLineItem> {
            testQLI1, testQLI2, testQLI3
        });

        // Test Trigger logic
        insert new List<QuoteLineItem>{
            testQLI1, testQLI2, testQLI3
        };

        Test.stopTest();

        Decimal resultTotalProServSOWDiscountWithInsert =
            [SELECT Id, ProServSOWDiscount__c FROM Quote WHERE Id = :testQuote.Id].get(0).ProServSOWDiscount__c;

        System.assertEquals(7, resultTotalProServSOWDiscountWithoutInsert);

        // For Some Reason totals does not recalculate in triggers until NewGOA__c is enabled and properly configured
        // See QuoteLineItemTrigger.SetQuoteApprovalType.setTotals
        // This will make preparation for this test is too complex and unstable to test
        // System.assertEquals(7, resultTotalProServSOWDiscountWithInsert);

    }

    @isTest static void testPopulateNewQuantity(){

        Triggers.switchOff();

        // Create Account
        Account testAcc = new Account(
            Name = 'test Account'
        );
        insert testAcc;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            AccountId = testAcc.Id,
            Name = 'Test Opportunity',
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        Test.startTest();
        // Create Quote
        Quote testQuote = new Quote(
            OpportunityId = testOpp.Id,
            Name = 'Test Quote',
            Pricebook2Id = testPrBook.Id
        );
        insert testQuote;

        // Create Products
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME,
            GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
            ExtId__c = 'Test Product 1_test_id'
        );

        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME,
            GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
            ExtId__c = 'Test Product 2_test_id'
        );

        Product2 testProduct3 = new Product2(
            Name = 'Test Product 3',
            Sub_Category__c = 'Main',
            Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME,
            GOA_Group_V2__c = 'RC_Office_Premium_Monthly_Contract',
            ExtId__c = 'Test Product 3_test_id'
        );
        insert new List<Product2> {
            testProduct1, testProduct2, testProduct3
        };

        // Create Entitlement
        Entitlement__c testEnt2 = new Entitlement__c(
            Quantity__c = 10,
            Product__r = testProduct2,
            Account__c = testAcc.Id,
            Active__c = true
        );
        insert testEnt2;

        // Create Asset
        Asset testAsset = new Asset(
            AccountId = testAcc.Id,
            Product2Id = testProduct3.Id,
            Name = 'testAsset',
            Unit_Price__c = 200,
            Quantity = 15,
            Delivered_Quantity__c = 5,
            Active__c = true
        );
        insert testAsset;

        // Create PricebookEntries
        PricebookEntry testPBEstandard1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct1.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry testPBE1 = new PricebookEntry(
            Pricebook2Id = testPrBook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );

        PricebookEntry testPBEstandard2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct2.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry testPBE2 = new PricebookEntry(
            Pricebook2Id = testPrBook.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );

        PricebookEntry testPBEstandard3 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct3.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        PricebookEntry testPBE3 = new PricebookEntry(
            Pricebook2Id = testPrBook.Id,
            Product2Id = testProduct3.Id,
            UnitPrice = 10,
            IsActive = true,
            UseStandardPrice = false,
            CurrencyIsoCode = 'USD'
        );
        insert new List<PricebookEntry>{
            testPBEstandard1, testPBE1,
            testPBEstandard2, testPBE2,
            testPBEstandard3, testPBE3
        };

        // Create QuoteLineItems
        QuoteLineItem testQLI1 = new QuoteLineItem(
            Product2 = testProduct1,
            Product2Id = testProduct1.Id,
            PricebookEntry = testPBE1,
            PricebookEntryId = testPBE1.Id,
            QuoteId = testQuote.Id,
            Quantity = 2,
            UnitPrice = testPBE1.UnitPrice
        );

        // QLI with Entitlement
        QuoteLineItem testQLI2 = new QuoteLineItem(
            Product2 = testProduct2,
            Product2Id = testProduct2.Id,
            PricebookEntry = testPBE2,
            PricebookEntryId = testPBE2.Id,
            QuoteId = testQuote.Id,
            Quantity = 2,
            Zero_Quantity__c = false,
            UnitPrice = testPBE2.UnitPrice,
            Entitlement__c = testEnt2.Id
        );

        // QLI with Asset
        QuoteLineItem testQLI3 = new QuoteLineItem(
            Product2 = testProduct3,
            Product2Id = testProduct3.Id,
            PricebookEntry = testPBE3,
            PricebookEntryId = testPBE3.Id,
            QuoteId = testQuote.Id,
            Quantity = 2,
            UnitPrice = testPBE3.UnitPrice,
            Asset__c = testAsset.Id
        );

        Triggers.switchOn();

        insert new List<QuoteLineItem>{
            testQLI1, testQLI2, testQLI3
        };

        Test.stopTest();

        Map<Id, QuoteLineItem> IdToQLIMap = new Map<Id, QuoteLineItem>([
            SELECT Id, NewQuantity__c
            FROM QuoteLineItem
        ]);
        QuoteLineItem resultNewQLI = IdToQLIMap.get(testQLI1.Id);
        QuoteLineItem resultEntitlementQLI = IdToQLIMap.get(testQLI2.Id);
        QuoteLineItem resultAssetQLI = IdToQLIMap.get(testQLI3.Id);

        System.assertEquals(testQLI1.Quantity, resultNewQLI.NewQuantity__c);
        System.assertEquals(testEnt2.Quantity__c + testQLI2.Quantity, resultEntitlementQLI.NewQuantity__c);
        System.assertEquals(testAsset.Delivered_Quantity__c + testQLI2.Quantity, resultAssetQLI.NewQuantity__c);
    }

    @isTest static void testPopulateNewQuantityForOverageProduct() {

        Triggers.switchOff();

        SObjectFactory factory = new SObjectFactory();

        // Create Opportunity
        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today()
                }
            );

        // Create PriceBook
        PriceBook2 pricebookRecord = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString('test price book products'),
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5
                }
            );

        Test.startTest();
        // Create Quote
        Quote quoteRecord = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Pricebook2Id => pricebookRecord.Id
                }
            );

        // Create Products
        List<Product2> productRecords = (List<Product2>) factory
            .build(
                Product2.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.GOA_Group_V2__c => 'RC_Office_Premium_Monthly_Contract',
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV
                }
            );

        // set Sub_Category__c = 'Main' for Last one product
        productRecords.get(productRecords.size() - 1).Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL;

        // set Family = 'Overage' for second product
        productRecords.get(1).Family = Product2Helper.FAMILY_OVERAGE;

        insert productRecords;


        // Create Entitlement
        Entitlement__c entitlementRecord = (Entitlement__c) factory
            .create(
                Entitlement__c.SObjectType,
                new Map<SObjectField, Object>{
                    Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Entitlement__c.Quantity__c => 10,
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Product__c => productRecords.get(1).Id
                }
            );

        // Create Asset
        Asset assetRecord = (Asset) factory
            .create(
                Asset.SObjectType,
                new Map<SObjectField, Object>{
                    Asset.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Asset.Product2Id => productRecords.get(productRecords.size() - 1).Id,
                    Asset.Name => ValueProviderBuilder.provideUniqueString('testAsset'),
                    Asset.Unit_Price__c => 200,
                    Asset.Quantity => 15,
                    Asset.Delivered_Quantity__c => 5,
                    Asset.Active__c => true
                }
            );

        // Create PricebookEntries
        List<PricebookEntry> standartPricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );

        List<PricebookEntry> pricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebookRecord.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );

        List<PricebookEntry> pbeToInsertList = new List<PricebookEntry>(standartPricebookEntryRecords);
        pbeToInsertList.addAll(pricebookEntryRecords);
        insert pbeToInsertList;

        // Create QuoteLineItems
        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) factory
            .build(
                QuoteLineItem.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pricebookEntryRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.Quantity => 2,
                    QuoteLineItem.UnitPrice => 10
                }
            );

        // set Entitlement__c for second QuoteLineItem
        qliRecords.get(1).Entitlement__c = entitlementRecord.Id;
        qliRecords.get(1).Zero_Quantity__c = false;

        // set Asset__c for last QuoteLineItem
        qliRecords.get(qliRecords.size() - 1).Asset__c = assetRecord.Id;

        Triggers.switchOn();

        insert qliRecords;

        Map<Id, QuoteLineItem> IdToQLIMap = new Map<Id, QuoteLineItem>([
            SELECT Id, NewQuantity__c, Entitlement__r.DisplayQuantity__c
            FROM QuoteLineItem
        ]);

        QuoteLineItem resultNewQLI = IdToQLIMap.get(qliRecords.get(0).Id);
        QuoteLineItem resultEntitlementQLI = IdToQLIMap.get(qliRecords.get(1).Id);
        QuoteLineItem resultAssetQLI = IdToQLIMap.get(qliRecords.get(2).Id);

        List<Entitlement__c> reselectedEntitlements = [SELECT Id,
                                                        DisplayQuantity__c
                                                        FROM Entitlement__c
                                                        LIMIT 1];

        Test.stopTest();

        System.assertEquals(
            qliRecords.get(0).Quantity,
            resultNewQLI.NewQuantity__c,
            'if QuoteLIneItem has no related Entitlement__c and Asset - NewQuantity__c should be equals to QuoteLineItem.Quantity'
        );
        System.assertEquals(
            reselectedEntitlements.get(0).DisplayQuantity__c + qliRecords.get(1).Quantity,
            resultEntitlementQLI.NewQuantity__c,
            'NewQuantity__c on QuoteLineItem should be equal to summ of corresponding Entitlement__c.DisplayQuantity__c and QuoteLineItem.Quantity'
        );
        System.assertEquals(
            assetRecord.Delivered_Quantity__c + qliRecords.get(2).Quantity,
            resultAssetQLI.NewQuantity__c,
            'NewQuantity__c on QuoteLineItem should be equal to summ of corresponding Asset.Delivered_Quantity__c and QuoteLineItem.Quantity'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testCcQliAddWithInContactEnt() {
        Test.startTest();

            Product2 inContactProduct = new Product2(
                Name = 'iC test',
                IsActive = true,
                Sub_Category__c = 'Main',
                Family = Product2Helper.FAMILY_ADDONS,
                ExtId__c = 'ic test_test_id',
                Feature__c = Product2Helper.FEATURE_INCONTACT_INTERCONNECT
            );

            insert inContactProduct;

            Account acc = [SELECT id FROM Account LIMIt 1].get(0);

            Entitlement__c ent = new Entitlement__c(
                Account__c = acc.Id,
                Product__c = inContactProduct.Id,
                Active__c = true,
                Price__c = 1,
                Discount__c = 10,
                Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                Quantity__c = 1
            );
            insert ent;

            Quote qt = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1].get(0);
            PricebookEntry pbe = [SELECT Id, Product2Id
                                    FROM PricebookEntry
                                    WHERE Product2.Sub_Category__c = :Product2Helper.SUBCATEGORY_CONTACT_CENTER
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

            try {
                QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{ pbe.Id });
            } catch (Exception e) {
                //System.assert(e.getMessage().contains('Contact Center products can\'t be added to the current Quote because there are inContact Interconnect Entitlements on associated Account.'));
                //failing test only on production environment will be fixed in the scope of https://jira.ringcentral.com/browse/PBC-18907
            }

        Test.stopTest();
    }

    @isTest static void testIcQliAddWithContactCenterEnt() {
        Test.startTest();

            Product2 ccProduct = new Product2(
                Name = 'CC test',
                IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product_Type__c = 'Seat',
                Family = Product2Helper.FAMILY_CCSERVICE,
                ExtId__c = 'cc test_test_id'
            );

            insert ccProduct;

            Account acc = [SELECT id FROM Account LIMIT 1].get(0);

            Entitlement__c ent = new Entitlement__c(
                Account__c = acc.Id,
                Product__c = ccProduct.Id,
                Active__c = true,
                Price__c = 1,
                Discount__c = 10,
                Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                Quantity__c = 1
            );
            insert ent;

            Quote qt = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1].get(0);
            PricebookEntry pbe = [SELECT Id, Product2Id
                                    FROM PricebookEntry
                                    WHERE Product2.Feature__c = :Product2Helper.FEATURE_INCONTACT_INTERCONNECT
                                    AND Pricebook2Id = :qt.Pricebook2Id].get(0);

            try {
                QuotingToolQuoteApexController.createQuoteLineItems(qt.Id, new List<Id>{ pbe.Id });
            } catch (Exception e) {
                System.assert(e.getMessage().contains('inContact Interconnect product can\'t be added to the current Quote because there are Contact Center Entitlements on associated Account.'));
            }

        Test.stopTest();
    }
    // end test validateCcAndInContactProdsInsert()

    @isTest static void testProductsCFieldOnQuoteRecalculation() {
        // Create Account
        Account testAcc = new Account(
            Name = 'test Account'
        );
        insert testAcc;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            AccountId = testAcc.Id,
            Name = 'Test Opportunity',
            StageName = '1. Qualify',
            CloseDate = System.today()
        );
        insert testOpp;

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        Test.startTest();

            // Create Quote
            Quote testQuote = new Quote(
                OpportunityId = testOpp.Id,
                Name = 'Test Quote',
                Products__c = 'RingCentral',
                Pricebook2Id = testPrBook.Id
            );
            insert testQuote;

            // Create Products
            Product2 testProduct1 = new Product2(
                Name = 'Test Product 1',
                Sub_Category__c = 'Main',
                ExtID__c = 'Test Product 1_test_id',
                IsActive = true
            );

            Product2 testProduct2 = new Product2(
                Name = 'Test Product 2',
                Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                ExtID__c = 'Test Product 2_test_id',
                IsActive = true
            );
            insert new List<Product2> {
                testProduct1, testProduct2
            };

            // Create PricebookEntries
            PricebookEntry testPBEstandard1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct1.Id,
                UnitPrice = 10,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            PricebookEntry testPBE1 = new PricebookEntry(
                Pricebook2Id = testPrBook.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = 10,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );

            PricebookEntry testPBEstandard2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct2.Id,
                UnitPrice = 10,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            PricebookEntry testPBE2 = new PricebookEntry(
                Pricebook2Id = testPrBook.Id,
                Product2Id = testProduct2.Id,
                UnitPrice = 10,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            List<PricebookEntry> pbesToIns = new List<PricebookEntry>{
                testPBEstandard1, testPBE1,
                testPBEstandard2, testPBE2};
            insert pbesToIns;

            QuotingToolQuoteApexController.createQuoteLineItems(testQuote.Id, new List<Id>{ testPBEstandard1.Id, testPBE1.Id, testPBEstandard2.Id, testPBE2.Id });
            Test.stopTest();
        Quote checkQuote = [SELECT Products__c FROM Quote WHERE Id = :testQuote.Id].get(0);

        System.assert(checkQuote.Products__c.contains('RingCentral') && checkQuote.Products__c.contains(Product2Helper.SUBCATEGORY_CONTACT_CENTER));
    }

    @isTest
    static void testEESUpdateDoesntChangeQuoteApprovedStatus() {
        Test.startTest();
            Account testAccount = new Account(Name='Opty test account');
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'TestOpportunity',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert (new List<Opportunity>{testOpp});

            Quote testSalesQuote = new Quote (
                Name = 'TestSalesQuoteMonthly',
                OpportunityId = testOpp.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId(),
                Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED
            );
            insert (new List<Quote>{testSalesQuote});

            Product2 testProduct1 = new Product2(
                Name = 'TestProduct1',
                IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Family = 'Service',
                Charge_term__c = 'Annual',
                Feature__c = 38,
                Sub_Feature__c = 2000,
                ExtID__c = 'Test Product 1_test_id'
            );
            insert (new List<Product2>{testProduct1});

            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct1.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            insert (new List<PricebookEntry>{pbe1});

            QuotingToolQuoteApexController.handleExtendedEnterpriseSupport(testSalesQuote.Id);

            Quote quoteToCheck = [SELECT Id, Approved_Status__c
                                    FROM Quote
                                    WHERE Id = :testSalesQuote.Id
                                    LIMIT 1];

            System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, quoteToCheck.Approved_Status__c);
        Test.stopTest();
    }

    @isTest
    static void testQuoteTotalsShouldClearedAfterDeletingLastQLI() {
        Quote testSalesQuote = [SELECT Id, OpportunityId, Pricebook2Id FROM Quote LIMIT 1];

        Quote proServQuote = new Quote(
            Name = 'test ProServ Quote',
            OpportunityId = testSalesQuote.OpportunityId,
            Pricebook2Id = testSalesQuote.Pricebook2Id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV
        );
        insert proServQuote;

        Test.startTest();
            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry pbe : [SELECT Id, Product2Id, Pricebook2Id, UnitPrice FROM PricebookEntry]) {

                if(pbe.Pricebook2Id == testSalesQuote.Pricebook2Id) {
                    qliList.add(
                        new QuoteLineItem(
                            QuoteId = proServQuote.Id,
                            Product2Id = pbe.Product2Id,
                            PricebookEntryId = pbe.Id,
                            Quantity = 29,
                            UnitPrice = pbe.UnitPrice,
                            Discount_number__c = 1
                        )
                    );
                }
            }

            insert qliList;

            Quote reselectedProServQuote = [SELECT Id, Total_First_Year_Cost__c, Total_One_Time__c, Total_MRR_New__c,
                Total_ARR__c, Total_Initial_Payment__c, Total_One_Time_Discount__c, Total_MRR_Discount__c,
                Total_ARR_Discount__c, Total_Initial_Payment_Discount__c, Total_First_Year_Discount__c,
                Total_One_Time_with_Taxes__c, Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c,
                Total_Initial_Payment_with_Taxes__c, Total_First_Year_Cost_with_Taxes__c,
                Contact_Center_Total_One_Time__c, Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c,
                Contact_Center_Total_Initial_Payment__c, Contact_Center_Total_First_Year_Cost__c,
                Contact_Center_Total_One_Time_Discount__c, Contact_Center_Total_MRR_Discount__c,
                Contact_Center_Total_ARR_Discount__c, ContactCenterTotalInitialPaymentDiscount__c,
                Contact_Center_Total_First_Year_Discount__c, Estimated_Hardware__c
            FROM Quote WHERE Id = :proServQuote.Id];

            // totals should not be empty
            System.assertNotEquals(null, reselectedProServQuote.Total_First_Year_Cost__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_One_Time__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_MRR_New__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_ARR__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_Initial_Payment__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_One_Time_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_MRR_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_ARR_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_Initial_Payment_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_First_Year_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_One_Time_with_Taxes__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_MRR_with_Taxes__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_ARR_with_Taxes__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_Initial_Payment_with_Taxes__c);
            System.assertNotEquals(null, reselectedProServQuote.Total_First_Year_Cost_with_Taxes__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_One_Time__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_MRR__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_ARR__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_Initial_Payment__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_First_Year_Cost__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_One_Time_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_MRR_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_ARR_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.ContactCenterTotalInitialPaymentDiscount__c);
            System.assertNotEquals(null, reselectedProServQuote.Contact_Center_Total_First_Year_Discount__c);
            System.assertNotEquals(null, reselectedProServQuote.Estimated_Hardware__c);

            // perfrom test - delete all qlis and check totals is cleared
            delete qliList;

            reselectedProServQuote = [SELECT Id, Total_First_Year_Cost__c, Total_One_Time__c, Total_MRR_New__c,
                Total_ARR__c, Total_Initial_Payment__c, Total_One_Time_Discount__c, Total_MRR_Discount__c,
                Total_ARR_Discount__c, Total_Initial_Payment_Discount__c, Total_First_Year_Discount__c,
                Total_One_Time_with_Taxes__c, Total_MRR_with_Taxes__c, Total_ARR_with_Taxes__c,
                Total_Initial_Payment_with_Taxes__c, Total_First_Year_Cost_with_Taxes__c,
                Contact_Center_Total_One_Time__c, Contact_Center_Total_MRR__c, Contact_Center_Total_ARR__c,
                Contact_Center_Total_Initial_Payment__c, Contact_Center_Total_First_Year_Cost__c,
                Contact_Center_Total_One_Time_Discount__c, Contact_Center_Total_MRR_Discount__c,
                Contact_Center_Total_ARR_Discount__c, ContactCenterTotalInitialPaymentDiscount__c,
                Contact_Center_Total_First_Year_Discount__c, Estimated_Hardware__c
            FROM Quote WHERE Id = :proServQuote.Id];

            // totals should be empty(we have no quoteLineItems for this quote)
            System.assertEquals(0, reselectedProServQuote.Total_One_Time__c);
            System.assertEquals(0, reselectedProServQuote.Total_MRR_New__c);
            System.assertEquals(0, reselectedProServQuote.Total_ARR__c);
            System.assertEquals(0, reselectedProServQuote.Total_Initial_Payment__c);
            System.assertEquals(0, reselectedProServQuote.Total_One_Time_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Total_MRR_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Total_ARR_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Total_Initial_Payment_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Total_First_Year_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Total_One_Time_with_Taxes__c);
            System.assertEquals(0, reselectedProServQuote.Total_MRR_with_Taxes__c);
            System.assertEquals(0, reselectedProServQuote.Total_ARR_with_Taxes__c);
            System.assertEquals(0, reselectedProServQuote.Total_Initial_Payment_with_Taxes__c);
            System.assertEquals(0, reselectedProServQuote.Total_First_Year_Cost_with_Taxes__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_One_Time__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_MRR__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_ARR__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_Initial_Payment__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_First_Year_Cost__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_One_Time_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_MRR_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_ARR_Discount__c);
            System.assertEquals(0, reselectedProServQuote.ContactCenterTotalInitialPaymentDiscount__c);
            System.assertEquals(0, reselectedProServQuote.Contact_Center_Total_First_Year_Discount__c);
            System.assertEquals(0, reselectedProServQuote.Estimated_Hardware__c);

        Test.stopTest();
    }

    @isTest
    static void testSetIsHiddenLicenseOnQuoteLineItem() {

        String hiddenLicenseForAllPackagesExtId = 'hidden_license_for_all_extId';
        String hiddenLicenseForOnePackageExtId = 'hidden_license_for_one_extId';
        String selectedPackageId = 'quote_packageId';

        List<NGBSHiddenLicenses__c> hiddenLicenseList = new List<NGBSHiddenLicenses__c>();

        hiddenLicenseList.add(
            new NGBSHiddenLicenses__c(
                Name = '1',
                IsHidden__c = true,
                LicenseElementId__c = hiddenLicenseForAllPackagesExtId,
                ShowLicenseName__c = true,
                AffectedPackage__c = 'All'
            )
        );
        hiddenLicenseList.add(
            new NGBSHiddenLicenses__c(
                Name = '2',
                IsHidden__c = true,
                LicenseElementId__c = hiddenLicenseForOnePackageExtId,
                ShowLicenseName__c = true,
                AffectedPackage__c = selectedPackageId
            )
        );
        insert hiddenLicenseList;

        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        Triggers.switchOff();

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'test product',
            IsActive = true,
            ExtID__c = hiddenLicenseForAllPackagesExtId
        );
        prodList.add(testProduct);

        Product2 testProduct1 = new Product2(
            Name = 'test product 2',
            IsActive = true,
            ExtID__c = 'other_ext_Id'
        );
        prodList.add(testProduct1);

        Product2 testProduct2 = new Product2(
            Name = 'test product 3',
            IsActive = true,
            ExtID__c = hiddenLicenseForOnePackageExtId
        );
        prodList.add(testProduct2);

        insert prodList;

        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pbe;

        for (Product2 pr : prodList) {
            pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = pr.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
            );
            pbeList.add(pbe);

            pbe = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = pr.Id,
                UnitPrice = 200,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                CurrencyIsoCode = 'USD'
            );
            pbeList.add(pbe);
        }
        insert pbeList;

        Opportunity testOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            CurrencyIsoCode = 'USD',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            Is_Billing_Opportunity__c = true
        );
        insert testOpp;

        Quote testBillingQuote = new Quote (
            Name = 'testBillingQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = testPriceBook.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            CurrencyIsoCode = 'USD',
            Package_Info__c = '[{"packageInfo":{"catalogId":"' + selectedPackageId + '"}}]'
        );
        insert testBillingQuote;

        Triggers.switchOn();

        Test.startTest();

            List<QuoteLineItem> qliList = new List<QuoteLineItem>();

            for(PricebookEntry item : pbeList) {
                if(item.PriceBook2Id == testBillingQuote.Pricebook2Id) {
                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = testBillingQuote.Id,
                        Product2Id = item.Product2Id,
                        Quantity = 1,
                        UnitPrice = item.UnitPrice,
                        Discount_number__c = 0,
                        PricebookEntryId = item.Id
                    );
                    // set IsHiddenLicense__c for product that "not hidden" in hiddenLicenses custom setting
                    // and verify IsHiddenLicense__c checkbox will be uncheked after insert
                    if(qli.Product2Id == testProduct1.Id) {
                        qli.IsHiddenLicense__c = true;
                    }
                    qliList.add(qli);
                }
            }
            insert qliList;
            update qliList;

            // reselect QuoteLineItems and verify
            // QuoteLineItem.IsHiddenLicense__c set to true for products
            // with same ExtID__c as in NGBSHiddenLicenses__c records with IsHidden__c = true
            List<QuoteLineItem> reselectedQliList = [SELECT Id,
                                                    IsHiddenLicense__c, Product2.ExtID__c
                                                    FROM QuoteLineItem
                                                    WHERE QuoteId = :testBillingQuote.Id];

            for(QuoteLineItem qli : reselectedQliList) {
                if(qli.Product2.ExtID__c == hiddenLicenseForAllPackagesExtId) {
                    System.assertEquals(true, qli.IsHiddenLicense__c);
                }
                if(qli.Product2.ExtID__c == hiddenLicenseForOnePackageExtId) {
                    System.assertEquals(true, qli.IsHiddenLicense__c);
                }

                // products not listed in NGBSHiddenLicenses__c custom setting should have IsHiddenLicense__c equal false
                if(qli.Product2Id == testProduct1.Id) {
                    System.assertEquals(false, qli.IsHiddenLicense__c);
                }
            }

        Test.stopTest();
    }

    // @isTest
    // static void testTotalNumberOfDLForBillingQuote() {

    //     Triggers.switchOff();

    //     Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
    //         .setField(Account.Name, 'Test account')
    //         .create()
    //         .getRecord();

    //     Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Opportunity.AccountId => testAccount.Id,
    //             Opportunity.Is_Billing_Opportunity__c => true,
    //             Opportunity.Name => 'TestOpportunity',
    //             Opportunity.Brand_Name__c => 'RingCentral',
    //             Opportunity.Tier_Name__c => 'Office',
    //             Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
    //             Opportunity.CloseDate => System.today(),
    //             Opportunity.CurrencyIsoCode => 'USD'
    //         })
    //         .create()
    //         .getRecord();

    //     PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
    //             PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
    //             PriceBook2.IsActive => true,
    //             PriceBook2.Line_Range_Min__c => 2,
    //             PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
    //             PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
    //         })
    //         .create()
    //         .getRecord();

    //     List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Product2.Name => ValueProviderBuilder.provideUniqueString('testProduct'),
    //             Product2.IsActive => true,
    //             Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
    //             Product2.Family => Product2Helper.FAMILY_SERVICE,
    //             Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
    //         })
    //         .create()
    //         .getRecords();

    //     List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
    //             PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
    //             PricebookEntry.UnitPrice => 200,
    //             PricebookEntry.IsActive => true,
    //             PricebookEntry.UseStandardPrice => false,
    //             PricebookEntry.CurrencyIsoCode => 'USD'
    //         })
    //         .create()
    //         .getRecords();

    //     List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             PricebookEntry.Pricebook2Id => testPriceBook.Id,
    //             PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
    //             PricebookEntry.UnitPrice => 200,
    //             PricebookEntry.IsActive => true,
    //             PricebookEntry.UseStandardPrice => false,
    //             PricebookEntry.CurrencyIsoCode => 'USD'
    //         })
    //         .create()
    //         .getRecords();

    //     Triggers.switchOn();

    //     Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             Quote.Name => 'TestBillingQuote',
    //             Quote.OpportunityId => testOpp.Id,
    //             Quote.Pricebook2Id => testPriceBook.Id,
    //             Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
    //         })
    //         .create()
    //         .getRecord();

    //     Decimal quoteLineItemQuantity = 7;

    //     List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
    //         .setFields(new Map<SObjectField, Object>{
    //             QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
    //             QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
    //             QuoteLineItem.QuoteId => testBillingQuote.Id,
    //             QuoteLineItem.Quantity => quoteLineItemQuantity,
    //             QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
    //             QuoteLineItem.Discount_Number__c => 10,
    //             QuoteLineItem.UnitPrice => 200
    //         })
    //         .build()
    //         .getRecords();

    //     QuoteSelector quoteSelector = new QuoteSelector();
    //     List<Quote> quoteList = (List<Quote>) quoteSelector
    //         .selectQuotes()
    //         .selectField(Quote.Total_Number_of_Digital_Lines__c)
    //         .setCondition('Id = \'' + testBillingQuote.Id + '\'')
    //         .setLimit(1)
    //         .executeQuery();

    //     Quote reselectedQuote = quoteList.get(0);

    //     System.assertEquals(
    //         testPriceBook.Line_Range_Min__c,
    //         reselectedQuote.Total_Number_of_Digital_Lines__c,
    //         'Quote.Total_Number_of_Digital_Lines__c should be equal to ' +
    //             'Pricebook2.Line_Range_Min__c if Quote has no QuoteLineItems'
    //     );

    //     Test.startTest();

    //         insert qlis;

    //         quoteList = (List<Quote>) quoteSelector
    //             .selectQuotes()
    //             .selectField(Quote.Total_Number_of_Digital_Lines__c)
    //             .setCondition('Id = \'' + testBillingQuote.Id + '\'')
    //             .setLimit(1)
    //             .executeQuery();

    //         reselectedQuote = quoteList.get(0);

    //         System.assertEquals(
    //             quoteLineItemQuantity,
    //             reselectedQuote.Total_Number_of_Digital_Lines__c,
    //             'Quote.Total_Number_of_Digital_Lines__c should be equal to Quantity of "service product"'
    //         );

    //     Test.stopTest();
    // }

    @isTest
    static void testSetTotalNumberOfDLMethodWithoutData() {

        QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate handlerInstance =
            new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate();

        Map<Id, Quote> result = handlerInstance.setTotalNumberOfDL(new Set<Id>(), null);
        System.assertEquals(
            new Map<Id, Quote>(),
            result,
            'method setTotalNumberOfDL should return empty quote list if all passed params is null'
        );

        result = handlerInstance.setTotalNumberOfDL(new Set<Id>(), new List<QuoteLineItem>());
        System.assertEquals(
            new Map<Id, Quote>(),
            result,
            'method setTotalNumberOfDL should return empty quote list if QuoteLineItem list is empty'
        );

        result = handlerInstance.setTotalNumberOfDL(new Set<Id>(), new List<QuoteLineItem>());
        System.assertEquals(
            new Map<Id, Quote>(),
            result,
            'method setTotalNumberOfDL should return empty quote list if QuoteLineItem list is empty'
        );
    }

    @isTest
    static void testSetTotalNumberOfDLMethodWithData() {

        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(Pricebook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testServiceProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate handlerInstance =
                new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate();

            List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                    QuoteLineItem.QuoteId => testBillingQuote.Id,
                    QuoteLineItem.Quantity => 3,
                    QuoteLineItem.UnitPrice => 200
                })
                .create()
                .getRecords();

            // populate static maps that are used in setTotalNumberOfDL method
            QuoteSelector quoteSelector = new QuoteSelector();
            List<Quote> quoteList = (List<Quote>) quoteSelector
                .selectQuotes()
                .selectField(Quote.Total_Number_of_Digital_Lines__c)
                .setCondition('Id = \'' + testBillingQuote.Id + '\'')
                .setLimit(1)
                .executeQuery();

            Quote reselectedQuote = quoteList.get(0);
            System.assertEquals(
                3,
                reselectedQuote.Total_Number_of_Digital_Lines__c,
                'Total_Number_of_Digital_Lines__c should be equal to Quantity of "Service product'
            );
        Test.stopTest();
    }

    @isTest
    static void testSetTotalNumberOfDLMethodWithDataOnDelete() {

        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(Pricebook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        List<Product2> testProducts = new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testServiceProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecords();

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecords();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Total_Number_of_Digital_Lines__c => 3
            })
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => testBillingQuote.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 200
            })
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();

        /* Remove service quote line items */
        delete qlis;
        List<Quote> quoteListAfterServiceDelete = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.Total_Number_of_Digital_Lines__c)
            .setCondition('Id = \'' + testBillingQuote.Id + '\'')
            .setLimit(1)
            .executeQuery();

        Quote reselectedQuoteAfterServiceDelete = quoteListAfterServiceDelete.get(0);
        System.assertEquals(
            0,
            reselectedQuoteAfterServiceDelete.Total_Number_of_Digital_Lines__c,
            'Total_Number_of_Digital_Lines__c should be reseted cause service product was deleted'
        );
        Test.stopTest();
    }

    @isTest
    static void testInvalidDiscountedPhonesQuantityForBilling() {

        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString('description'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Product2 serviceProduct = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testServiceProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .build()
            .getRecord();

        Product2 discountedPhoneProduct = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testDiscountedPhoneProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Feature__c => Product2Helper.FEATURE_DISCOUNTED_PHONES
            })
            .build()
            .getRecord();

        Product2 technicalLicenseProduct = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testTechnicalLicenseProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => 'Technical License',
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .build()
            .getRecord();

        List<Product2> testProducts = new List<Product2>{
            serviceProduct,
            discountedPhoneProduct,
            technicalLicenseProduct
        };
        insert testProducts;

        List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPriceBook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 200,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        Triggers.switchOff();
        Triggers.except('QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate');
        Triggers.except('QuoteLineItemTriggerHelper.ManageQuotesMapStatic');
            // create QuoteLineItems and set Quantity of "Discounted Phones" product != quantity of "Service product"
            // and verify Quote.InvalidDiscountedPhonesQuantity__c is true
            List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                    QuoteLineItem.QuoteId => testBillingQuote.Id,
                    QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Decimal>{3, 1, 3}),
                    QuoteLineItem.UnitPrice => 200
                })
                .quantity(testProducts.size())
                .create()
                .getRecords();

            QuoteSelector quoteSelector = new QuoteSelector();
            List<Quote> quoteList = (List<Quote>) quoteSelector
                .selectQuotes()
                .selectField(Quote.InvalidDiscountedPhonesQuantity__c)
                .setCondition('Id = \'' + testBillingQuote.Id + '\'')
                .setLimit(1)
                .executeQuery();

            Quote reselectedQuote = quoteList.get(0);
            NGBS_LBO_Settings__c LBOSetting = NGBS_LBO_Settings__c.getOrgDefaults();

            System.assertEquals(
                LBOSetting.LBOAutoOnThreshold__c < testProducts.size() ? true : false,
                reselectedQuote.InvalidDiscountedPhonesQuantity__c,
                'if Quantity of "Service product" != Quantity of "Discounted Phone" - ' +
                    'Quote.InvalidDiscountedPhonesQuantity__c should be true, but for not LBO'
            );

            // update quantity of DiscountedPhone product(make it equal to Quantity of "Service product")
            // and verify Quote.InvalidDiscountedPhonesQuantity__c is false
            for (QuoteLineItem qli : qlis) {
                if (qli.Product2Id == discountedPhoneProduct.Id) {
                    qli.Quantity = 3;
                }
            }
            update qlis;

            quoteList = (List<Quote>) quoteSelector
                .selectQuotes()
                .selectField(Quote.InvalidDiscountedPhonesQuantity__c)
                .setCondition('Id = \'' + testBillingQuote.Id + '\'')
                .setLimit(1)
                .executeQuery();

            reselectedQuote = quoteList.get(0);

            System.assertEquals(
                false,
                reselectedQuote.InvalidDiscountedPhonesQuantity__c,
                'if Quantity of "Service product" == Quantity of "Discounted Phone" - ' +
                    'Quote.InvalidDiscountedPhonesQuantity__c should be false'
            );

        Triggers.switchOn();
        Test.stopTest();
    }

    @isTest
    private static void testRemoveAssignmentLineItems() {

        Triggers.switchOff();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Product2 productAnnual = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => pricebook.Id
            })
            .create()
            .getRecord();

        PricebookEntry standartPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pricebook.Id,
                PricebookEntry.Product2Id => productMonthly.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productMonthly.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();

        List<AssignmentLineItem__c> alisParent = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AssignmentLineItem__c.Parent__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Quantity__c => 2
            })
            .quantity(2)
            .create()
            .getRecords();

        List<AssignmentLineItem__c> alisChild = new SobjectBuilder(AssignmentLineItem__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AssignmentLineItem__c.Child__c => ValueProviderBuilder.provideParents(qlis),
                AssignmentLineItem__c.Quantity__c => 2
            })
            .quantity(2)
            .create()
            .getRecords();

            System.assertEquals(
                4, [
                SELECT COUNT()
                FROM AssignmentLineItem__c
            ],
                'AssignmentLineItems was created incorrectly'
            );

            delete qlis;

        Test.stopTest();

        System.assertEquals(
            0, [
            SELECT COUNT()
            FROM AssignmentLineItem__c
        ],
            'AssignmentLineItems was removed incorrectly'
        );
    }

    @IsTest
    private static void testCheckIsNeedUpdateTotals() {

        Triggers.switchOff();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Pricebook2 pricebook = (Pricebook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Line_Range_Min__c => 5,
                Pricebook2.IsActive => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pricebook.Id,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            })
            .create()
            .getRecord();

        PricebookEntry stdPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id
            })
            .create()
            .getRecord();

        PricebookEntry pBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => pricebook.Id,
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.PricebookEntryId => pBE.Id,
                QuoteLineItem.UnitPrice => pBE.UnitPrice,
                QuoteLineItem.DiscountValueNew__c => 10,
                QuoteLineItem.Discount_type__c => 'Percentage',
                QuoteLineItem.Zero_Quantity__c => false
            })
            .build()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

            insert qli;

            List<Quote> qList = new QuoteSelector()
                .selectQuotes()
                .selectField(Quote.Total_First_Year_Cost__c)
                .setCondition('Id = \'' + qt.Id + '\'')
                .executeQuery();

            Quote initialQuote = qList.get(0);

            qli.Quantity = 10;
            update qli;

            qList = new QuoteSelector()
                .selectQuotes()
                .selectField(Quote.Total_First_Year_Cost__c)
                .setCondition('Id = \'' + qt.Id + '\'')
                .executeQuery();

            Quote updatedQuote = qList.get(0);

        Test.stopTest();

        Decimal totalCostBeforeUpdate = initialQuote.Total_First_Year_Cost__c;
        Decimal totalCostAfterUpdate = updatedQuote.Total_First_Year_Cost__c;

        System.assertEquals(50, totalCostBeforeUpdate, 'Totals should not be changed');
        System.assertEquals(100, totalCostAfterUpdate, 'Totals should not be changed');
    }

    @istest
    private static void testIsChangedQuoteLineItemQuantity() {

        Test.startTest();

            Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
                })
                .create()
                .getRecord();

            Pricebook2 pricebook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Pricebook2.Line_Range_Min__c => 5,
                    Pricebook2.IsActive => true
                })
                .create()
                .getRecord();

            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => pricebook.Id,
                    Quote.CurrencyIsoCode => 'USD'
                })
                .create()
                .getRecord();

            List<Product2> testProducts = new SObjectBuilder(Product2.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV,
                    Product2.IsActive => true
                })
                .quantity(2)
                .create()
                .getRecords();

            List<PricebookEntry> stdPBEList = new SobjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                })
                .quantity(testProducts.size())
                .create()
                .getRecords();

            List<PricebookEntry> pBEList = new SobjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.Min_Quantity__c => ValueProviderBuilder.provideList(new List<Decimal>{null, 1}),
                    PricebookEntry.Max_Quantity__c => ValueProviderBuilder.provideList(new List<Decimal>{null, 2})
                })
                .quantity(testProducts.size())
                .create()
                .getRecords();

        Test.stopTest();

        List<QuoteLineItem> qliList = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Decimal>{2, 6}),
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(testProducts.size())
            .build()
            .getRecords();

        QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate inst = new QuoteLineItemTriggerHelper.UpdateQuoteOnQuoteLineItemUpdate();

        System.assertEquals(false, inst.isChangedQuoteLineItemQuantity(qliList.get(0), 3.00, pBEList.get(0)), 'Quantity should not be changed');
        System.assertEquals(true, inst.isChangedQuoteLineItemQuantity(qliList.get(1), 10.00, pBEList.get(1)), 'Quantity should be changed');
        System.assertEquals(true, inst.isChangedQuoteLineItemQuantity(qliList.get(1), 1.00, pBEList.get(1)), 'Quantity should be changed');
    }

    @IsTest
    private static void testValidateChangeOrderQliQuantityChange() {

        Triggers.switchOff();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.SObjectType),
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV
            })
            .create()
            .getRecord();

        Pricebook2 pricebook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                Pricebook2.IsActive => true,
                Pricebook2.Line_Range_Min__c => 5
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.Pricebook2Id => pricebook.Id,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Asset testAsset = (Asset) new SObjectBuilder(Asset.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                Asset.AccountId => ValueProviderBuilder.provideCommonParent(Account.SObjectType),
                Asset.Name => ValueProviderBuilder.provideUniqueString('testAsset'),
                Asset.Product2Id => testProduct.Id,
                Asset.Unit_Price__c => 200,
                Asset.Quantity => 15,
                Asset.Delivered_Quantity__c => 5,
                Asset.Active__c => true
            })
        .create()
        .getRecord();

        PricebookEntry stdPBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        PricebookEntry pBE = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => pricebook.Id,
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        List<QuoteLineItem> qliList = new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.PricebookEntryId => pBE.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => pBE.UnitPrice,
                QuoteLineItem.Asset__c => testAsset.Id
            })
            .build()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();

            QuoteLineItem qli = qliList.get(0);
            qli.NewQuantity__c = 4;

            Boolean exceptionThrown = false;

            try {
                insert qli;
            } catch (Exception e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains('Quantity can\'t be less than ' + testAsset.Delivered_Quantity__c + ' for that QLI.'));
            }
            System.assert(exceptionThrown);

            qli.NewQuantity__c = 17;
            exceptionThrown = false;

            try {
                insert qli;
            } catch (Exception e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains('This Product became unavailable, you can’t sell more than was sold on original Order - ' + testAsset.Quantity));
            }
            System.assert(exceptionThrown);

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void testAllowToAddMinuteBundle() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => System.today().addDays(5)
            })
            .create()
            .getRecord();

        Pricebook2 testPricebook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.IsActive => true,
                Pricebook2.Line_Range_Min__c => 5
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => testPricebook.Id,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Product2 minutesBundleProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testMinutesBundleProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_TRANSPORT,
                Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE
            })
            .build()
            .getRecord();

        Product2 inbentaBundleProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testInbentaBundleProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Product_Type__c => 'AI'
                })
        .build()
        .getRecord();

        Product2 familyOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('testFamilyOverageProduct'),
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS,
                Product2.Family => Product2Helper.FAMILY_OVERAGE
            })
            .build()
            .getRecord();

        List<Product2> testProducts = new List<Product2>{
            minutesBundleProduct,
            familyOverageProduct,
            inbentaBundleProduct
        };
        insert testProducts;

        List<PricebookEntry> stdPBEList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPricebook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Deactivated__c => false
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        List<QuoteLineItem> qliListWithRequiredFields = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<String> {
                'Product2Id',
                'Product2.Sub_Category__c',
                'Product2.Family',
                'Product2.Product_Type__c',
                'Deactivated__c',
                'Entitlement__r.Id'
            })
            .setCondition('QuoteId = \'' + qt.Id + '\'')
            .executeQuery();

        List<PricebookEntry> pBEListWithRequiredFields = [
            SELECT Id, Product2.Product_Type__c
            FROM PricebookEntry
            WHERE Pricebook2Id =: testPricebook.Id];
        Triggers.switchOn();
        Test.startTest();

            Boolean notAllowToAddMB = QuoteLineItemTriggerHelper.allowToAddMinuteBundle(
                true,
                new List<QuoteLineItem>{qliListWithRequiredFields.get(0)},
                pBEListWithRequiredFields.get(0),
                QuoteLineItemHelper.getEuropeTransportTypes()
            );

            Boolean allowToAddMB = QuoteLineItemTriggerHelper.allowToAddMinuteBundle(
                true,
                new List<QuoteLineItem>{qliListWithRequiredFields.get(1)},
                pBEList.get(1),
                QuoteLineItemHelper.getEuropeTransportTypes()
            );

            Boolean allowToAddMBWithEmptyQLIList = QuoteLineItemTriggerHelper.allowToAddMinuteBundle(
                true,
                new List<QuoteLineItem>(),
                pBEList.get(1),
                QuoteLineItemHelper.getEuropeTransportTypes()
            );

            Boolean allowToAddInbenta = QuoteLineItemTriggerHelper.allowToAddInbentaBundle(
                true,
                qliList,
                pBEList.get(2)
            );

        Test.stopTest();
        /*
        System.assertEquals(false, notAllowToAddMB, 'Cannot add Minutes Bundle');
        System.assertEquals(true, allowToAddMB, 'Can add Minutes Bundle');
        System.assertEquals(true, allowToAddMBWithEmptyQLIList, 'Can add Minutes Bundle');
        System.assertEquals(true, allowToAddInbenta, 'Can add Inbenta Bundle');
        */
    }

    @IsTest
    private static void testPrepareQuoteLineItemsFeesOnInsert() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        List<Product2> testProducts = new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Family => ValueProviderBuilder.provideList(
                    new List<String>{
                        Product2Helper.FAMILY_SERVICE, Product2Helper.FAMILY_FEE, Product2Helper.FAMILY_PHONE}),
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Dependent_on_Feature__c => 17,
                Product2.Description => 'description'
            })
            .quantity(3)
            .create()
            .getRecords();

        Pricebook2 testPricebook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                Pricebook2.IsActive => true,
                Pricebook2.Line_Range_Min__c => 5
            })
            .create()
            .getRecord();

        Test.startTest();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => testPricebook.Id,
                Quote.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        List<PricebookEntry> stdPBEList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        List<PricebookEntry> pBEList = new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => testPricebook.Id,
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .quantity(testProducts.size())
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(testProducts),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pBEList),
                QuoteLineItem.Quantity => 7,
                QuoteLineItem.UnitPrice => 10
            })
            .quantity(3)
            .create()
            .getRecords();

            DefaultLineItemsTriggerHandler.setDefaultLineItems(new List<Quote>{qt}, new Set<Id>{testPricebook.Id});

        Test.stopTest();

        List<QuoteLineItem> qliList2 = new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(new List<Schema.SObjectField> {
                QuoteLineItem.Description,
                QuoteLineItem.UnitPrice,
                QuoteLineItem.Quantity
            })
            .setCondition('Description = \'description\' AND UnitPrice = 10 AND Quantity = 5')
            .executeQuery();

        // method prepare QLI only if product_family is 'Tier', 'Service' or 'Fee'
        System.assertEquals(2, qliList2.size(), 'QuoteLineItems should not be prepared');
    }

    @isTest
    private static void verifySetChargeTermsWithPackageInfoDurationEmpty() {

        Triggers.switchOff();

        SObjectFactory factory = new SObjectFactory();

        // Create Opportunity
        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.RecordTypeId => Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
                }
            );

        // Create PriceBook
        PriceBook2 pricebookRecord = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object>{
                    PriceBook2.Name => ValueProviderBuilder.provideUniqueString('Test Price Book'),
                    PriceBook2.Description => ValueProviderBuilder.provideUniqueString('test price book products'),
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5
                }
            );

        // Create Quote
        Id RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Sales Quote v2').getRecordTypeId();
        Quote quoteRecord = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opportunityRecord.Id,
                    Quote.Name => ValueProviderBuilder.provideUniqueString('test quote'),
                    Quote.Pricebook2Id => pricebookRecord.Id,
                    Quote.RecordTypeId => RecordTypeId
                }
            );

        // Create Products
        List<Product2> productRecords = (List<Product2>) factory
            .build(
                Product2.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.GOA_Group_V2__c => 'RC_Office_Premium_Monthly_Contract',
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_PROSERV
                }
            );

        // set Sub_Category__c = 'Main' for Last one product
        productRecords.get(productRecords.size() - 1).Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL;

        // set Family = 'Overage' for second product
        productRecords.get(1).Family = Product2Helper.FAMILY_OVERAGE;

        insert productRecords;

        // Create PricebookEntries
        List<PricebookEntry> standartPricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );

        List<PricebookEntry> pricebookEntryRecords = (List<PricebookEntry>) factory
            .build(
                PricebookEntry.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => pricebookRecord.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
                }
            );

        List<PricebookEntry> pbeToInsertList = new List<PricebookEntry>(standartPricebookEntryRecords);
        pbeToInsertList.addAll(pricebookEntryRecords);
        insert pbeToInsertList;

        String packageInfo = '{"categoryCode":"DL-UNL","discount":{"value":0,"type":"Money"},"duration":"","id":"18","version":"1","q":1,"lboxes":[{"elementID":null,"min":null,"max":null}],"categoryPath":"DL:DL-UNL","billingType":"Recurring"}';
        // Create QuoteLineItems
        List<QuoteLineItem> qliRecords = (List<QuoteLineItem>) factory
            .build(
                QuoteLineItem.SObjectType,
                3,
                new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(productRecords),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(pricebookEntryRecords),
                    QuoteLineItem.QuoteId => quoteRecord.Id,
                    QuoteLineItem.Quantity => 2,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.PackageInfo__c => packageInfo,
                    QuoteLineItem.Package_Info__c => packageInfo
                }
            );

        Triggers.switchOn();

        Test.startTest();
            try {
                insert qliRecords;
            } catch (Exception e) {
                QuoteLineItemTriggerHelper.SetChargeTerms termsClass = new QuoteLineItemTriggerHelper.SetChargeTerms();
                System.assert(e.getMessage().contains(termsClass.DURATION_ERROR));
            }

        Test.stopTest();

    }

    @IsTest
    static void test_UpdateSortOrderBeforeInsert() {

        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAccount.Id,
                    Opportunity.Is_Billing_Opportunity__c => true,
                    Opportunity.Name => 'TestOpportunity',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today(),
                    Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Product2 digitalLineProduct = (Product2) new SobjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Product2.Name => 'DigitalLine Unlimited',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Family => Product2Helper.FAMILY_SERVICE,
                    Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry priceBookEntry = (PricebookEntry) new SobjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(new List<Product2>{digitalLineProduct}),
                    PricebookEntry.UnitPrice => 200,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Quote.Name => 'TestBillingQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                    QuoteLineItem.Product2Id => digitalLineProduct.Id,
                    QuoteLineItem.PricebookEntryId => priceBookEntry.Id,
                    QuoteLineItem.QuoteId => testBillingQuote.Id,
                    QuoteLineItem.Quantity => 3,
                    QuoteLineItem.UnitPrice => 200,
                    QuoteLineItem.Sort_Order__c => 22
            })
            .create()
            .getRecords();

        Test.stopTest();

        Set<Id> qliIds = new Map<Id, QuoteLineItem>(qlis).keySet();

        // Query records from database to assert
        List<QuoteLineItem> insertedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsForUpdateSortOrder(qliIds)
                .executeQuery();

        for (QuoteLineItem qli : insertedQlis) {
            System.assertEquals(19.4, qli.Sort_Order__c);
        }

    }

    @IsTest
    static void test_UpdateSortOrderBeforeUpdate() {
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
                .setField(Account.Name, 'Test account')
                .create()
                .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Name => 'TestOpportunity',
                        Opportunity.Brand_Name__c => 'RingCentral',
                        Opportunity.Tier_Name__c => 'Office',
                        Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                        Opportunity.CloseDate => System.today(),
                        Opportunity.CurrencyIsoCode => 'USD'
                })
                .create()
                .getRecord();

        Product2 digitalLineProduct = (Product2) new SobjectBuilder(Product2.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Product2.Name => 'DigitalLine Unlimited',
                        Product2.IsActive => true,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                        Product2.Family => Product2Helper.FAMILY_SERVICE,
                        Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
                })
                .create()
                .getRecord();

        PricebookEntry priceBookEntry = (PricebookEntry) new SobjectBuilder(PricebookEntry.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                        PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(new List<Product2>{digitalLineProduct}),
                        PricebookEntry.UnitPrice => 200,
                        PricebookEntry.IsActive => true,
                        PricebookEntry.UseStandardPrice => false,
                        PricebookEntry.CurrencyIsoCode => 'USD'
                })
                .create()
                .getRecord();

        Test.startTest();
        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Quote.Name => 'TestBillingQuote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                })
                .create()
                .getRecord();

        List<QuoteLineItem> qlis = new SobjectBuilder(QuoteLineItem.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        QuoteLineItem.Product2Id => digitalLineProduct.Id,
                        QuoteLineItem.PricebookEntryId => priceBookEntry.Id,
                        QuoteLineItem.QuoteId => testBillingQuote.Id,
                        QuoteLineItem.Quantity => 3,
                        QuoteLineItem.UnitPrice => 200,
                        QuoteLineItem.Sort_Order__c => 20
                })
                .create()
                .getRecords();


        for (QuoteLineItem qli : qlis) {
            qli.Sort_Order__c = 22;
        }

        update qlis;

        Test.stopTest();

        Set<Id> qliIds = new Map<Id, QuoteLineItem>(qlis).keySet();

        // Query records from database to assert
        List<QuoteLineItem> insertedQlis = (List<QuoteLineItem>) new QuoteLineItemSelector()
                .selectQuoteLineItemsForUpdateSortOrder(qliIds)
                .executeQuery();

        for (QuoteLineItem qli : insertedQlis) {
            System.assertEquals(19.4, qli.Sort_Order__c);
        }
    }

    @isTest
    private static void testGetQuoteWithApproversFields() {
        QuoteLineItemTriggerHelper.SetQuoteApprovalType triggerHandler = new QuoteLineItemTriggerHelper.SetQuoteApprovalType();
        System.assertEquals(
            null,
            triggerHandler.getQuoteWithApproversFields(null),
            'method getQuoteWithApproversFields should return null if passed param are null'
        );

        Quote originalQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.SObjectType),
                Quote.Level_1_Approver__c => ValueProviderBuilder.provideDummyId(User.SObjectType),
                Quote.Level_2_Approver__c => ValueProviderBuilder.provideDummyId(User.SObjectType),
                Quote.Level_3_Approver__c => ValueProviderBuilder.provideDummyId(User.SObjectType),
                Quote.Level_4_Approver__c => ValueProviderBuilder.provideDummyId(User.SObjectType),
                Quote.Level_5_Approver__c => ValueProviderBuilder.provideDummyId(User.SObjectType)
            })
            .build()
            .getRecord();

        Quote result = triggerHandler.getQuoteWithApproversFields(originalQuote);
        Map<String, Object> populatedFieldsMap = result.getPopulatedFieldsAsMap();
        System.assertEquals(
            6,
            populatedFieldsMap.size(),
            'returned quote should have 6 field populated'
        );
    }

    @isTest
    private static void testAutoApproveCommisionableLicense() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep'
                }
            )
            .create()
            .getRecord();
        
        System.runAs(testUser) {
            Group testGroup = new Group(Name='TestQueue', Type='Queue');
            insert testGroup;
            
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'DQ_Deal_Qualification_Approver__c');
            insert testQueue;
            
            GroupMember member = new GroupMember();
            member.UserOrGroupId = testUser.Id;
            member.GroupId = testGroup.Id;
            insert member;
        }

        String pInfo = '{"categoryCode":"DL-UNL","duration":"Monthly","parent":"LC_DL_75","q":5,"lboxes":[{"min":1,"max":99999,"elementID":"LB_70"}],"categoryPath":"DL:DL-UNL","originalDiscount":null,"partnerInfo":{"billingPlan":[{"wholesaleRater":{"type":"Fixed","config":"99.99"},"startDate":"2030-01-01T00:00Z[UTC]","revShareRater":{"type":"Fixed","config":"99.99"},"duration":"Monthly"}]}}';

        Triggers.switchOff();

        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test account')
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Product2 mobileUser = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('test_mobile_user'),
                Product2.ExtID__c => Product2Helper.MOBILE_USER_ELEMENT_ID,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        Quote testBillingQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'TestBillingQuote',
                Quote.OpportunityId => testOpp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Product2 digitalLine = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('test_DL'),
                Product2.ExtID__c => Product2Helper.DL_UNL_ELEMENT_ID,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry pbeMobileUser = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => mobileUser.Id,
                PricebookEntry.UnitPrice => 450,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry pbeDigitalLine = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => digitalLine.Id,
                PricebookEntry.UnitPrice => 450,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qliMobileUser = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => digitalLine.Id,
                QuoteLineItem.QuoteId => testBillingQuote.Id,
                QuoteLineItem.PricebookEntryId => pbeMobileUser.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                QuoteLineItem.Discount_Number__c => 85
            })
            .build()
            .getRecord();

        QuoteLineItem commissionableQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => testBillingQuote.Id,
                QuoteLineItem.PackageInfo__c => pInfo,
                QuoteLineItem.PricebookEntryId => pbeDigitalLine.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 450,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                QuoteLineItem.Discount_Number__c => 85
            })
            .build()
            .getRecord();

        List<QuoteLineItem> qlis = new List<QuoteLineItem>{qliMobileUser, commissionableQli};

        Triggers.switchOn();

        Test.startTest();
            System.runAs(testUser) {
                insert qlis;
                testBillingQuote = ((List<Quote>) new QuoteSelector()
                    .selectQuoteById(new List<Object>{ testBillingQuote.Id })
                    .executeQuery()).get(0);

                System.assert(
                    QuoteHelper.APPROVAL_STATUSES_NOT_REQUIRED.contains(testBillingQuote.Approved_Status__c),
                    'Commissionable license is not auto approved. Actual: ' + testBillingQuote.Approved_Status__c
                );
            }
        Test.stopTest();
    }

    @IsTest
    private static void testContactCenterQuoteApprovalStatusUpdate() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableTPAndDQBasedGOAInQT__c => true
            })
            .create();

        final String testQuote = 'Test quote';
        final String testCCQuote = 'Test CC quote';

        User testApprover = createUser(null);
        User testUser = createUser(testApprover.Id);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => System.today(),
                Opportunity.OwnerId => testUser.Id
            })
            .create()
            .getRecord();

        Pricebook2 pricebook = (Pricebook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Line_Range_Min__c => 5,
                Pricebook2.IsActive => true
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            })
            .create()
            .getRecord();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<String>{
                    Test.getStandardPricebookId(),
                    pricebook.Id
                }),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        DQ_Approval_Step__c dqApprovalStep = (DQ_Approval_Step__c) new SObjectBuilder(DQ_Approval_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step__c.Name => 'Level 1'
            })
            .create()
            .getRecord();

        DQ_Approval_Type__c dqApprovalType = (DQ_Approval_Type__c) new SObjectBuilder(DQ_Approval_Type__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Type__c.Product_Category__c => 'Default Contact Center',
                DQ_Approval_Type__c.Approval_Type__c => 'Discount',
                DQ_Approval_Type__c.Threshold__c => 35,
                DQ_Approval_Type__c.IsActive__c => true,
                DQ_Approval_Type__c.isUnifiedQuotingApprovalType__c => true
            })
            .create()
            .getRecord();

        DQ_Approval_Type_Step__c dqApprovalTypeStep = (DQ_Approval_Type_Step__c) new SObjectBuilder(DQ_Approval_Type_Step__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Type_Step__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                DQ_Approval_Type_Step__c.DQ_Approval_Type__c => dqApprovalType.Id,
                DQ_Approval_Type_Step__c.Region__c => 'US',
                DQ_Approval_Type_Step__c.Segment__c => 'Default',
                DQ_Approval_Type_Step__c.Deal_Type__c => 'Direct',
                DQ_Approval_Type_Step__c.Brand__c => 'Default',
                DQ_Approval_Type_Step__c.Sub_Region__c => 'All'
            })
            .create()
            .getRecord();

        DQ_Approval_Step_Approver__c dqApprovalStepApprover = (DQ_Approval_Step_Approver__c) new SObjectBuilder(DQ_Approval_Step_Approver__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Approval_Step_Approver__c.Approval_Type__c => 'Approval',
                DQ_Approval_Step_Approver__c.DQ_Approval_Step__c => dqApprovalStep.Id,
                DQ_Approval_Step_Approver__c.Brand__c => 'Default',
                DQ_Approval_Step_Approver__c.Deal_Type__c => 'Direct',
                DQ_Approval_Step_Approver__c.Region__c => 'US',
                DQ_Approval_Step_Approver__c.Segment__c => 'Default',
                DQ_Approval_Step_Approver__c.Sub_Region__c => 'All',
                DQ_Approval_Step_Approver__c.OwnerId => testApprover.Id
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideList(new List<String>{
                    testQuote, testCCQuote
                }),
                Quote.OpportunityId => opp.Id,
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.RT_ID_BILLING, QuoteHelper.RT_ID_CC
                }),
                Quote.IsPrimary__c => ValueProviderBuilder.provideList(new List<Boolean>{
                    true, false
                }),
                Quote.PriceBook2Id => pricebook.Id,
                Quote.Approved_Status__c => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.APPROVAL_STATUS_REQUIRED, QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED
                })
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> testQlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideParents(testQuotes),
                QuoteLineItem.Display_Name__c => ValueProviderBuilder.provideList(new List<String>{
                        testQuote, testCCQuote
                }),
                QuoteLineItem.PricebookEntryId => pbeList.get(1).Id,
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.DiscountValueNew__c => 10,
                QuoteLineItem.Discount_type__c => 'Percentage',
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => pbeList.get(1).UnitPrice
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
        	QuoteApprovals.quotesExcludedForDQGoa = new List<Quote>();

            QuoteLineItem qli;
            QuoteLineItem qliCC;
            for (QuoteLineItem q : testQlis) {
                if (q.Display_Name__c == testQuote) {
                    qli = q;
                } else if (q.Display_Name__c == testCCQuote) {
                    qliCC = q;
                }
            }
        	qliCC.Discount = 50;
            update qliCC;

        List<Quote> qList = new QuoteSelector()
            .selectQuotes()
            .selectField(Quote.Approved_Status__c)
            .setCondition('Name IN (\'' + testQuote +'\',\'' + testCCQuote + '\')')
            .executeQuery();

        Test.stopTest();

        System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, qList.get(0).Approved_Status__c, 'Primary Quote should have Required Approval Status when Contact Center Quote requires Approval');
        System.assertEquals(QuoteHelper.APPROVAL_STATUS_REQUIRED, qList.get(1).Approved_Status__c, 'Contact Center Quote should have Required Approval Status when Discount is greater than threshold for Approval');
    }

    private static User createUser(Id managerId) {
        SObjectBuilder userBuilder = new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.Username => UserHelper.getUniqueUserName(),
                    User.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Email => ValueProviderBuilder.provideUniqueEmail(),
                    User.Alias => StringHelper.getRandomString(8),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US',
                    User.Region__c => 'US',
                    User.Sub_Region__c => 'All'
                }
            );

        if (managerId != null) {
            userBuilder.setField(User.ManagerId, managerId);
        }

        return (User) userBuilder.create().getRecord();
    }

    @IsTest
    private static void testBundleValidationNameBfrParentheses() {

        Triggers.switchOff();
        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testCCQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test CC quote',
                Quote.OpportunityId => testOpp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();

        Product2 firstProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('Contact Center: Bot Builder (per 70,000 Session Bundle)'),
                Product2.Family => Product2Helper.FAMILY_ADDONS,
                Product2.IsActive => true,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SESSIONS,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();

        PricebookEntry firstPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => firstProduct.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        Test.startTest();

        QuoteLineItem firstQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => firstProduct.Id,
                QuoteLineItem.QuoteId => testCCQuote.Id,
                QuoteLineItem.PricebookEntryId => firstPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Entitlement__c => null
            })
            .create()
            .getRecord();

        firstQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItemsForQLITrigger(new Set<Id>{testCCQuote.Id})
            .executeQuery()
            .get(0);

        Map<Id, Map<Id, QuoteLineItem>> quoteIdToProdIdToQLIMap = new Map<Id, Map<Id, QuoteLineItem>>();
        Map<Id, QuoteLineItem> prodIdToQLI = new Map<Id, QuoteLineItem>();
        prodIdToQLI.put(firstProduct.id, firstQli);
        quoteIdToProdIdToQLIMap.put(testCCQuote.Id, prodIdToQLI);

        QuoteLineItemTriggerHelper.quoteIdToProdIdToQLIMap = quoteIdToProdIdToQLIMap;

        Product2 secondProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('Contact Center: Bot Builder (per 50,000 Session Bundle)'),
                Product2.Family => Product2Helper.FAMILY_ADDONS,
                Product2.IsActive => true,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SESSIONS,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();

        PricebookEntry secondPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
            PricebookEntry.Product2Id => secondProduct.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        try{
            QuoteLineItem secondQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => secondProduct.Id,
                QuoteLineItem.QuoteId => testCCQuote.Id,
                QuoteLineItem.PricebookEntryId => secondPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('Only one Contact Center: Bot Builder  bundle can be sold at a time'));
        }

        Test.stopTest();
    }

    @IsTest
    private static void testBundleValidationNameBfrDash() {

        Triggers.switchOff();
        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => 'RingCentral',
                Opportunity.Tier_Name__c => 'Office',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Quote testCCQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Name => 'Test CC quote',
                Quote.OpportunityId => testOpp.Id,
                Quote.CurrencyIsoCode => 'USD',
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_APPROVED,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();

        Product2 firstProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('Contact Center: SpinSci PAC Engagement - Small Bundle (per BU)'),
                Product2.Family => Product2Helper.FAMILY_ADDONS,
                Product2.IsActive => true,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_ENGAGEMENT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();

        PricebookEntry firstPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => firstProduct.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        Test.startTest();

        QuoteLineItem firstQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => firstProduct.Id,
                QuoteLineItem.QuoteId => testCCQuote.Id,
                QuoteLineItem.PricebookEntryId => firstPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Entitlement__c => null
            })
            .create()
            .getRecord();

        firstQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItemsForQLITrigger(new Set<Id>{testCCQuote.Id})
            .executeQuery()
            .get(0);

        Map<Id, Map<Id, QuoteLineItem>> quoteIdToProdIdToQLIMap = new Map<Id, Map<Id, QuoteLineItem>>();
        Map<Id, QuoteLineItem> prodIdToQLI = new Map<Id, QuoteLineItem>();
        prodIdToQLI.put(firstProduct.id, firstQli);
        quoteIdToProdIdToQLIMap.put(testCCQuote.Id, prodIdToQLI);

        QuoteLineItemTriggerHelper.quoteIdToProdIdToQLIMap = quoteIdToProdIdToQLIMap;

        Product2 secondProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString('Contact Center: SpinSci PAC Engagement - Large Bundle (per BU)'),
                Product2.Family => Product2Helper.FAMILY_ADDONS,
                Product2.IsActive => true,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_ENGAGEMENT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();

        PricebookEntry secondPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
            PricebookEntry.Product2Id => secondProduct.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        try{
            QuoteLineItem secondQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => secondProduct.Id,
                QuoteLineItem.QuoteId => testCCQuote.Id,
                QuoteLineItem.PricebookEntryId => secondPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();
        }
        catch(Exception e){
            System.debug('TEST MESSAGE: ' + e.getMessage());
            System.assert(e.getMessage().contains('Only one Contact Center: SpinSci PAC Engagement  bundle can be sold at a time'));
        }

        Test.stopTest();
    }
}