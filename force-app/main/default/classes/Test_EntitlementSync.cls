/**
 * Created by capitan on 12/1/17.
 */

@IsTest
private class Test_EntitlementSync {

    @TestSetup
    static void createData() {
        Triggers.switchOff();
        Account testAccount = new Account(
                Name = 'Test Account',
                Number_of_DL_s__c = 10,
                BillingCity = 'TestCity',
                BillingStreet = 'TestStreet',
                Payment_Method__c = 'Invoice',
                SignupType__c = 'Direct',
                RC_User_ID__c = '12345'
        );
        insert testAccount;

        Contact testContact = new Contact(
                AccountId = testAccount.Id,
                LastName = 'John',
                FirstName = 'Doe',
                Email = 'testeetrst@testtestets.tld'
        );
        insert testContact;
        Triggers.switchOn();
        Area_Codes__c areaCode = new Area_Codes__c(
                Name = '999',
                Area_Code__c = 999,
                City__c = 'TestCity',
                State_Abbreviation__c = 'ST',
                StateID__c = 99
        );
        insert areaCode;

        schedulerConfiguration__c scc = new schedulerConfiguration__c(Name='RingCentral');
        insert scc;

        Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Description ='Test Price Book Products',
                Tier_ID__c = '4422',
                Plan__c = 'Monthly',
                IsActive = true,
                Line_Range_Min__c = 5,
                Line_Range_Max__c = 10,
                Service__c = 'Office',
                Brand__c = scc.Id
        );
        insert testPriceBook;

        //Create products
        List<Product2> testProducts = new List<Product2>();
        Product2 testProduct = new Product2(
                Name = 'Test bundle',
                Family = 'Office',
                IsActive = true,
                Sub_Category__c = 'Main',
                ExtID__c = '4780_36_Test bundle_null_Annual_null_null_null_false',
                Feature__c = 36,
                Charge_Term__c = 'Monthly',
                Number_of_Minutes__c = 1000
        );
        testProducts.add(testProduct);
        Product2 testServiceProduct = new Product2(
                Name = 'Connect Pro - Annual Fee2',
                Family = 'Service',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                ExtID__c = '4780_17_DigitalLine Unlimited_null_Annual_null_null_null_false',
                Feature__c = 17,
                Charge_Term__c = 'Monthly'
        );
        testProducts.add(testServiceProduct);
        Product2 testEntitlementProduct1 = new Product2(
                Name = 'Connect Pro - Annual Fee',
                Family = 'CC Service',
                Product_Type__c = 'Seat',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                ExtID__c = '4780_36_Connect Pro - Annual Fee_null_Annual_null_null_null_false',
                Edition__c = 'testEntitlementProduct1'
        );
        testProducts.add(testEntitlementProduct1);
        Product2 testEntitlementProduct2 = new Product2(
                Name = 'Connect Pro - Annual Fee2',
                Family = 'CC Service',
                Product_Type__c = 'Seat',
                IsActive = true,
                Sub_Category__c = 'Contact Center',
                ExtID__c = '4780_36_Connect Pro - Annual Fee2_null_Annual_null_null_null_false',
                Edition__c = 'testEntitlementProduct2'
        );
        testProducts.add(testEntitlementProduct2);

        Product2 product33 = new Product2(
                Name = 'Extended Enterprise Support - Platinum - price per DL',
                Dependent_on_Feature__c = 28,
                Family = 'Office',
                IsActive = true,
                Charge_Term__c = 'Monthly',
                ExtID__c = '4780_36_Extended Enterprise Support - Platinum - price per DL_null_Annual_null_null_null_false',
                Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT
        );
        testProducts.add(product33);

        insert testProducts;
        Product2 productTestEntitlement = testProducts.get(3);

        //Create prices
        List<PricebookEntry> testPricebookEntrys = new List<PricebookEntry>();

        PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false
        );
        testPricebookEntrys.add(standardPrice);
        PricebookEntry testPrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        testPricebookEntrys.add(testPrice);

        PricebookEntry standardServicePrice = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testServiceProduct.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
        );
        testPricebookEntrys.add(standardServicePrice);
        PricebookEntry testServicePrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testServiceProduct.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        testPricebookEntrys.add(testServicePrice);

        PricebookEntry standardEntitlementPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testEntitlementProduct1.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
        );
        testPricebookEntrys.add(standardEntitlementPrice1);
        PricebookEntry testEntitlementPrice1 = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testEntitlementProduct1.Id,
                UnitPrice = 100, IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        testPricebookEntrys.add(testEntitlementPrice1);

        PricebookEntry standardEntitlementPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testEntitlementProduct2.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
        );
        testPricebookEntrys.add(standardEntitlementPrice2);
        PricebookEntry testEntitlementPrice2 = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id,
                Product2Id = testEntitlementProduct2.Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        testPricebookEntrys.add(testEntitlementPrice2);

        insert testPricebookEntrys;

        Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                Type = 'Syndicated - New',
                StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
                CloseDate = system.today(),
                Brand_Name__c = 'RingCentral',
                PriceBook2Id = testPriceBook.Id,
                Primary_Opportunity_Contact__c = testContact.Id,
                Tier_Name__c = '999',
                AccountId = testAccount.Id
        );
        Triggers.switchOff();
        insert opp;
        Triggers.switchOn();

        Quote testQuote = new Quote(
            Name = 'testQuote',
            OpportunityId = opp.id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testServiceProduct.Id,
            Quantity = 2,
            UnitPrice = standardServicePrice.UnitPrice,
            PricebookEntryId = standardServicePrice.Id
        );
        Triggers.switchOff();
        insert qli1;
        Triggers.switchOn();

        List<Entitlement__c> entls = new List<Entitlement__c>();
        Entitlement__c entl = new Entitlement__c();
        entl.Account__c = testAccount.Id;
        entl.Product__c = testEntitlementProduct1.Id;
        entl.Price__c = 9.99;
        entl.Active__c = true;
        entl.Quantity__c = 10;
        entl.Discount__c = 10;
        entl.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        entl.Start_Date__c = System.today();
        entl.Name = testEntitlementProduct1.Name;

        entls.add(entl);

        entl = new Entitlement__c();
        entl.Account__c = testAccount.Id;
        entl.Product__c = testEntitlementProduct2.Id;
        entl.Price__c = 19.99;
        entl.Active__c = true;
        entl.Quantity__c = 5;
        entl.Discount__c = 5;
        entl.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        entl.Start_Date__c = System.today();
        entl.Name = testEntitlementProduct2.Name;

        entls.add(entl);

        entl = new Entitlement__c();
        entl.Account__c = testAccount.Id;
        entl.Product__c = testProduct.Id;
        entl.Price__c = 19.99;
        entl.Active__c = true;
        entl.Quantity__c = 5;
        entl.Discount__c = 5;
        entl.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        entl.Start_Date__c = System.today();
        entl.Name = testProduct.Name;

        entls.add(entl);

        entl = new Entitlement__c();
        entl.Account__c = testAccount.Id;
        entl.Product__c = testServiceProduct.Id;
        entl.Price__c = 19.99;
        entl.Active__c = true;
        entl.Quantity__c = 5;
        entl.Discount__c = 5;
        entl.Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE;
        entl.Start_Date__c = System.today();
        entl.Name = testServiceProduct.Name;

        entls.add(entl);

        Triggers.switchOff();
        insert entls;
        Triggers.switchOn();

        Order ord = new Order(
                Name = 'test order',
                OpportunityId = opp.Id,
                BillToContactId = testContact.Id,
                CurrencyIsoCode = 'USD',
                Type = 'New',
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = GenerateOrders.getSObjectTypes('Order').get('Contact Center').getRecordTypeId(),
                AccountId = testAccount.Id,
                Status = 'New',
                EffectiveDate = System.today()
        );

        insert ord;

        List<OrderItem> oItems = new List<OrderItem>();
        OrderItem newOrderItem = new OrderItem(
                PricebookEntryId = testEntitlementPrice1.Id,
                Quantity = 3,
                Threshold__c = 0,
                UnitPrice = 9.89,
                UnitPriceWithoutDiscount__c = 9.99,
                Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Discount_Number__c = 0.1,
                Active__c = true,
                BillingStatus__c='Active',
                Zero_Quantity__c = false,
                OrderId = ord.Id
        );

        oItems.add(newOrderItem);

        newOrderItem = new OrderItem(
                PricebookEntryId = testEntitlementPrice2.Id,
                Quantity = 1,
                Threshold__c = 0,
                UnitPrice = 19.89,
                UnitPriceWithoutDiscount__c = 19.99,
                Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Discount_Number__c = 0.1,
                Active__c = true,
                BillingStatus__c='Active',
                Zero_Quantity__c = false,
                OrderId = ord.Id
        );

        oItems.add(newOrderItem);

        Triggers.switchOff();
        insert oItems;
        Triggers.switchOn();

        DWHEntitlementEndpoint__c dwhEndpoint = new DWHEntitlementEndpoint__c();
        dwhEndpoint.URL__c = 'https://esb.ringcentral.com/service/restapi/entitlements/currentEntitlement/dwh?rcUserId=';

        insert dwhEndpoint;
    }


    @isTest
    static void testEntitlementActions() {
        List<Entitlement__c> entitlements = [
                SELECT Id, Name, Product__c, Discount__c, Discount_Type__c, Quantity__c, Active__c,
                        Product__r.Family, Product__r.Name, Product__r.Product_Type__c, Product__r.ExtID__c,
                        Product__r.Edition__c, Product__r.Number_of_minutes__c
                FROM Entitlement__c
        ];

        Order ord = [SELECT Id, AccountId FROM Order LIMIT 1];
        List<OrderItem> rcOrderItems = [
                SELECT Id, Active__c, RC_Entitlement__c, Insert_Entitlement__c, Pricebookentry.Product2Id,
                        Pricebookentry.Product2.Family, UnitPrice, Pricebookentry.Product2.Name, Pricebookentry.Product2.Feature__c,
                        Pricebookentry.Product2.Edition__c, Pricebookentry.CurrencyIsoCode,CurrencyIsoCode,
                        UnitPriceWithoutDiscount__c, Quantity, Discount_Number__c, Discount_Type__c,
                        Zero_Quantity__c, ServiceDate, Matcher_Formula__c, QuantityOrThreshold__c
                FROM OrderItem
        ];

        OrderItem oItem;
        for (OrderItem itm : rcOrderItems) {
            if (itm.PricebookEntry.Product2.Name == 'Connect Pro - Annual Fee'){
                oItem = itm;
                break;
            }
        }
        Entitlement__c entl = EntitlementSync.findEntitlement(entitlements, ord, oItem);

        System.assertNotEquals(null, entl);
        System.assertEquals('Connect Pro - Annual Fee', entl.Product__r.Name);
        System.assertEquals(10, entl.Quantity__c);

        EntitlementSync.updateEntitlement(oItem, entl);

        System.assertEquals(10, entl.Quantity__c);

        entl = EntitlementSync.insertNewEntitlement(oItem, ord.AccountId, ord);

        System.assertNotEquals(null, entl);
        System.assertEquals(oItem.PricebookEntry.Product2.Id, entl.Product__c);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testEntitlementSync() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new EntitlementSync());

        EntitlementSync.syncWithDWH(acc.Id);

        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testCreateQlisFromEntitlements() {
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = false LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Entitlement__c> entitlements = [
                SELECT Id, Name, Product__c, Discount__c, Discount_Type__c, Quantity__c, DisplayQuantity__c, Active__c,
                        Product__r.Family, Product__r.Name, Product__r.Product_Type__c, Product__r.ExtID__c,
                        Product__r.Edition__c, Product__r.Number_of_minutes__c, Product__r.Charge_Term__c, Price__c
                FROM Entitlement__c
        ];
        List<PricebookEntry> pricebookEntries = [
                SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                        Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                        Product2.Seat_Range_Max__c, CurrencyIsoCode, Product2.Supported_Countries__c, Product2.Parent__c,
                        Product2.Matcher_Formula__c, Product2.ExtID__c, Product2.Advanced_Matcher_Formula__c,
                        Product2.Product_Tab_Availability__c, Product2.Dependent_on_Feature__c, Product2.Feature__c,
                        Product2.Add_Overages__c, Product2.Product_Type__c, Product2.Number_of_Minutes__c, Pricebook2Id,
                        Pricebook2.isStandard, isActive
                FROM PricebookEntry
                WHERE Pricebook2Id = :pb.Id
                AND isActive = true
        ];

        Quote qt = new Quote(
                Pricebook2Id = pb.Id,
                OpportunityId = opp.Id,
                Name = 'Test'
        );
        Triggers.switchOff();
        insert qt;
        Triggers.switchOn();

        EntitlementSync.EntitlementsParams params = new EntitlementSync.EntitlementsParams();
        params.additionalLines = 10;
        params.quoteId = qt.Id;
        params.entitlements = entitlements;
        params.pricebook2Id = pb.Id;
        params.pricebookEntries = pricebookEntries;

        EntitlementSync.createLineItemsFromEntitlements(params);
    }

    @isTest
    static void testCreateQlisFromEntitlementsUpgrade() {
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsStandard = false LIMIT 1];
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([SELECT Id, UnitPrice FROM PriceBookEntry WHERE Pricebook2Id = :pb.Id]);
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Entitlement__c> entitlements = [
                SELECT Id, Name, Product__c, Discount__c, Discount_Type__c, Quantity__c, DisplayQuantity__c, Active__c,
                        Product__r.Family, Product__r.Name, Product__r.Product_Type__c, Product__r.ExtID__c,
                        Product__r.Edition__c, Product__r.Number_of_minutes__c, Product__r.Charge_Term__c, Price__c
                FROM Entitlement__c
        ];
        List<PricebookEntry> pricebookEntries = [
                SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                        Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                        Product2.Seat_Range_Max__c, CurrencyIsoCode, Product2.Supported_Countries__c, Product2.Parent__c,
                        Product2.Matcher_Formula__c, Product2.ExtID__c, Product2.Advanced_Matcher_Formula__c,
                        Product2.Product_Tab_Availability__c, Product2.Dependent_on_Feature__c, Product2.Feature__c,
                        Product2.Add_Overages__c, Product2.Product_Type__c, Product2.Number_of_Minutes__c, Pricebook2Id,
                        Pricebook2.isStandard, isActive
                FROM PricebookEntry
                WHERE Pricebook2Id = :pb.Id
                AND isActive = true
        ];

        Quote qt = new Quote(
                Pricebook2Id = pb.Id,
                OpportunityId = opp.Id,
                Name = 'Test'
        );
        Triggers.switchOff();
        insert qt;
        Triggers.switchOn();

        EntitlementSync.EntitlementsParams params = new EntitlementSync.EntitlementsParams();
        params.additionalLines = 10;
        params.quoteId = qt.Id;
        params.entitlements = entitlements;
        params.pricebook2Id = pb.Id;
        params.pricebookEntries = pricebookEntries;

        // for Quotes with Upsell_Status = 'Upgrade' frice should be taken from PricebookEntry
        params.quoteUpsellStatus = QuoteHelper.STATUS_UPGRADE;

        List<QuoteLineItem> createdQli = EntitlementSync.createLineItemsFromEntitlements(params);

        for(QuoteLineItem qli : createdQli) {
                PricebookEntry pbe = pbeMap.get(qli.PriceBookEntryId);
                System.assertEquals(pbe.UnitPrice, qli.UnitPrice);
        }
    }

    // Verify that Entitlements for Global Office products created with 'Monthly - Contract' chargeTerm
    @isTest
    static void syncGlobalOfficeProducts() {
        Product2 testGlobalOfficeProduct = new Product2(
            Name = 'Global Office - NETHERLANDS',
            Family = 'Add - Ons',
            IsActive = true,
            Sub_Category__c = 'Main',
            Feature__c = 47,
            Charge_Term__c = 'Monthly - Contract'
        );
        insert testGlobalOfficeProduct;

        Opportunity testOpp = [select Id, PriceBook2Id from Opportunity limit 1];
        Id pbId = testOpp.PriceBook2Id == null ? null : testOpp.PriceBook2Id;

        // set pricebook's charge term as 'Monthly - Contract'
        update new Pricebook2(
            Id = pbId,
            Plan__c = 'Monthly - Contract'
        );

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testGlobalOfficeProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false
        );

        PricebookEntry testPrice = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = testGlobalOfficeProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );

        insert new List<PricebookEntry>{ standardPrice, testPrice };

        // for creating entitlement for monthly-contract product
        // account should have active agreement with diff between start and end dates more than 363 days
        Date testStartDate = System.today();
        Date testEndDate = testStartDate.addYears(2);

        Quote testAgreement = new Quote(
            Name = 'My Test Agreement',
            OpportunityId = testOpp.Id,
            Status = 'Active',
            Pricebook2Id = pbId,
            QuoteType__c = 'Agreement',
            Start_Date__c = testStartDate,
            End_Date__c = testEndDate,
            Initial_Term_months__c = '12'
        );
        Test.startTest();
        insert testAgreement;
        Test.stopTest();


            EntitlementSync.mockDWHJsonResponce = '{"rcUserID":129389020,"brandId":1210,"serviceId":1,"editionId":6,' +
                '"tierId":4422,"currency":"USD","currencyId":1,"accountStatus":"Test","accountStatusId":13,' +
                '"rcProducts":[{"countryName":"FRANCE","countryId":75,"featureId":28,"subFeatureId":1,"fullPhoneName":"Test Phone",' +
                '"numberOfMinutes":1000,"feeType":null,"productName":"Test bundle","productId":2071916,"chargeTerm":"Monthly",' +
                '"quantity":1,"itemListPrice":14.99,"itemDiscountPrice":119.96},' +
                '{"countryName":"FRANCE","countryId":75,"featureId":28,"subFeatureId":1,"fullPhoneName":"Test Phone",' +
                '"numberOfMinutes":1000,"feeType":"Fee","productName":"Test bundle","productId":2071916,' +
                '"chargeTerm":"Monthly","quantity":1,"itemListPrice":14.99,"itemDiscountPrice":119.96},' +
                '{"countryName":"FRANCE","countryId":75,"featureId":52,"subFeatureId":1,"fullPhoneName":"Test Phone",' +
                '"numberOfMinutes":1000,"feeType":null,"productName":"Test bundle","productId":2071916,"chargeTerm":"Monthly",' +
                '"quantity":1,"itemListPrice":14.99,"itemDiscountPrice":119.96},' +
                '{"countryName":"NETHERLANDS","countryId":157,"featureId":47,"productName":"DigitalLine International",' +
                '"productId":2070337,"chargeTerm":"Monthly","quantity":1,"itemListPrice":59.98,"itemDiscountPrice":59.98}],' +
                '"nonRcProducts":[{"productName":"Monthly - 119.96 - RC Office 4","productId":2071916,' +
                '"chargeTerm":"Monthly","quantity":1,"itemListPrice":14.99,"itemDiscountPrice":119.96}]}';

            Test.setMock(HttpCalloutMock.class, new EntitlementSync());

            Account acc = [SELECT Id, Sales_Agreement_Start_Date__c, Sales_Agreement_End_Date__c FROM Account LIMIT 1];
            EntitlementSync.syncWithDWH(acc.Id);

            List<Entitlement__c> entitlementForGlobalProduct = [SELECT Id, Name, Product__r.Charge_Term__c FROM Entitlement__c WHERE Product__c = :testGlobalOfficeProduct.Id];

            // verify Entitlement for globalOffice product is created
            System.assertEquals(1, entitlementForGlobalProduct.size());

            Entitlement__c globalOfficeEntl = entitlementForGlobalProduct.get(0);
            System.assertEquals(testGlobalOfficeProduct.Name, globalOfficeEntl.Name);

            System.assertEquals(testGlobalOfficeProduct.Charge_Term__c, globalOfficeEntl.Product__r.Charge_Term__c);

    }

    @IsTest
    static void checkIsDwhRespContainsNbsProd() {
        String jsonDwhResp = '{' +
            '"rcUserID": 12345678,' +
            '"brandId": 1210,' +
            '"serviceId": 1,' +
            '"tierId": 4999,' +
            '"currency": "USD",' +
            '"currencyId": 1,' +
            '"accountStatus": "Paid",' +
            '"accountStatusId": 7,' +
             '"rcProducts": [{' +
                '"productId": 1000999,' +
                '"productName": "Active [NBS]",' +
                '"quantity": 1,' +
                '"itemListPrice": 0,' +
                '"itemDiscountPrice": 0,' +
                '"featureId": 28' +
            '}]' +
        '}';

        EntitlementSync.DWHResponse dwhResp = EntitlementSync.parseDWHResponse(jsonDwhResp);

        Test.startTest();
            System.assertEquals(true, EntitlementSync.isDwhRespContainsNbsProd(dwhResp));
        Test.stopTest();
    }

    @IsTest
    static void testAccPendingSyngWithNGBS() {

        String jsonDwhResp = '{' +
            '"rcUserID": 12345678,' +
            '"brandId": 1210,' +
            '"serviceId": 1,' +
            '"tierId": 4999,' +
            '"currency": "USD",' +
            '"currencyId": 1,' +
            '"accountStatus": "Paid",' +
            '"accountStatusId": 7,' +
             '"rcProducts": [{' +
                '"productId": 1000999,' +
                '"productName": "Active [NBS]",' +
                '"quantity": 1,' +
                '"itemListPrice": 0,' +
                '"itemDiscountPrice": 0,' +
                '"featureId": 28' +
            '}]' +
        '}';

        EntitlementSync.mockDWHJsonResponce = jsonDwhResp;

        Test.setMock(HttpCalloutMock.class, new EntitlementSync());

        Account acc = [
                SELECT Id, Sales_Agreement_Start_Date__c, Sales_Agreement_End_Date__c, Billing_ID__c
                FROM Account
                LIMIT 1];

        Test.startTest();
            Response resp = EntitlementSync.syncWithDWH(acc.Id);

            String exHeader = 'Entitlement Sync Failed. Account is pending Sync with NGBS. ';
            String exBody = 'Please wait at least 1 hour and try again.';

            System.assertEquals(exHeader+exBody, resp.messages[0].message);
        Test.stopTest();
    }

    @IsTest
    static void testSyncEntitlementsWithDifferentDLFeatureId() {

        // Create test data
        Account testAccount = new Account(
            Name = 'My Test Account',
            Number_of_DL_s__c = 10,
            BillingCity = 'TestCity',
            BillingStreet = 'TestStreet',
            Payment_Method__c = 'Invoice',
            SignupType__c = 'Direct',
            RC_User_ID__c = '54321'
        );
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'testeetrst@testtestets.tld'
        );
        insert testContact;

        List<Product2> productList = new List<Product2>();

        Product2 testDLBasicProduct = new Product2(
            Name = 'DigitalLine Basic',
            Family = 'Add - Ons',
            IsActive = true,
            Sub_Category__c = 'Main',
            Feature__c = 12,
            Charge_Term__c = 'Monthly'
        );
        productList.add(testDLBasicProduct);

        Product2 testDLUnlimitedProduct = new Product2(
            Name = 'DigitalLine Unlimited',
            Family = 'Add - Ons',
            IsActive = true,
            Sub_Category__c = 'Main',
            Feature__c = 17,
            Charge_Term__c = 'Monthly'
        );
        productList.add(testDLUnlimitedProduct);

        Product2 testPolycomProduct = new Product2(
            Name = 'Polycom VVX311 - Rental',
            Family = 'Rental Phones',
            IsActive = true,
            Sub_Category__c = 'Main',
            Feature__c = 34,
            Sub_Feature__c = 66,
            Charge_Term__c = 'Monthly'
        );
        productList.add(testPolycomProduct);

        Product2 testPolycomProduct2 = new Product2(
            Name = 'Polycom VVX311 - Rental',
            Family = 'Limited Extension Rental Phones',
            IsActive = true,
            Sub_Category__c = 'Main',
            Feature__c = 34,
            Sub_Feature__c = 66,
            Charge_Term__c = 'Monthly'
        );
        productList.add(testPolycomProduct2);

        Product2 testMeetingsLicenseProduct = new Product2(
            Name = 'Meetings License',
            Family = 'Add - Ons',
            IsActive = true,
            Sub_Category__c = 'Main',
            Feature__c = 64,
            Charge_Term__c = 'Monthly'
        );
        productList.add(testMeetingsLicenseProduct);

        insert productList;


        Opportunity testOpp = [select Id, PriceBook2Id from Opportunity limit 1];
        Id pbId = testOpp.PriceBook2Id == null ? null : testOpp.PriceBook2Id;


        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        for(Product2 pr : productList) {
            PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = pr.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false
            );
            pbeList.add(standardPrice);

            PricebookEntry testPrice = new PricebookEntry(
                Pricebook2Id = pbId,
                Product2Id = pr.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
            );
            pbeList.add(testPrice);
        }
        insert pbeList;

        // JSON for mock DWH response
        // contains 5 products: 2 DigitalLine products and 2 Polycom VVX311 and 1 Meeting License
        // Polycom VVX311 has same Feature and SubFeature, but different digitalLineFeatureId
        // EntitlementSync.syncWithDWH should create 5 Entitlement__c(and if 2 Polycom products has same digitalLineFeatureId
        // it should create 3 entitlements(create 1 Entitlement__c with quantity 2 from 2 Polycom products)
        String jsonDwhResp = '{' +
            '"rcUserID": 54321,' +
            '"brandId": 1210,' +
            '"serviceId": 1,' +
            '"editionId": 6,' +
            '"tierId": 4422,' +
            '"currency": "USD",' +
            '"currencyId": 1,' +
            '"accountStatus": "Paid",' +
            '"accountStatusId": 7,' +
            '"rcProducts": [' +
                '{' +
                    '"productId": 2237922,' +
                    '"productName": "DigitalLine Basic",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 14.99,' +
                    '"itemDiscountPrice": 14.99,' +
                    '"featureId": 12' +
                '},' +
                '{' +
                    '"productId": 2237924,' +
                    '"productName": "DigitalLine Unlimited",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 0,' +
                    '"itemDiscountPrice": 0,' +
                    '"featureId": 17' +
                '},' +
                '{' +
                    '"productId": 2238018,' +
                    '"productName": "Polycom VVX311 - Leasing",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 9,' +
                    '"itemDiscountPrice": 6,' +
                    '"featureId": 34,' +
                    '"subFeatureId": 66,' +
                    '"digitalLineFeatureId": 12' +
                '},' +
                '{' +
                    '"productId": 2238018,' +
                    '"productName": "Polycom VVX311 - Leasing",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 9,' +
                    '"itemDiscountPrice": 6,' +
                    '"featureId": 34,' +
                    '"subFeatureId": 66,' +
                    '"digitalLineFeatureId": 17' +
                '},'+
                '{' +
                    '"productId": 2310655,' +
                    '"productName": "Meetings License",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 14.99,' +
                    '"itemDiscountPrice": 14.99,' +
                    '"featureId": 64' +
                '}]}';

        // mock DWH response
        EntitlementSync.mockDWHJsonResponce = jsonDwhResp;

        Test.setMock(HttpCalloutMock.class, new EntitlementSync());

        Test.startTest();

            List<Entitlement__c> entitlementList = [SELECT Id FROM Entitlement__c WHERE Account__c = :testAccount.Id];
            System.assertEquals(0, entitlementList.size());

            Response resp = EntitlementSync.syncWithDWH(testAccount.Id);

            entitlementList = [SELECT Id FROM Entitlement__c WHERE Account__c = :testAccount.Id];
            System.assertEquals(
                5, entitlementList.size(),
                'should create 5 entitlements during sync(equal to products count in mocked DWH Response(jsonDwhResp)), but got: ' + entitlementList.size()
            );
        Test.stopTest();
    }

    @IsTest
    static void testChargeTermForTrialAccounts() {

        // if account statius contains 'trial' in DWH response and
        // chargeTerm is null for product with feature 28 - set chargeTerm to Monthly

        // json with Trial Account
        String jsonDwhResp = '{' +
            '"rcUserID": 12345,' +
            '"brandId": 1210,' +
            '"serviceId": 1,' +
            '"editionId": 5,' +
            '"tierId": 5104,' +
            '"currency": "USD",' +
            '"currencyId": 1,' +
            '"accountStatus": "Trial 15 CC",' +
            '"accountStatusId": 15,' +
            '"rcProducts": [' +
                '{' +
                    '"productId": 1005146,' +
                    '"productName": "15 days-54.99-O_P_1_L-9.2",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 54.99,' +
                    '"itemDiscountPrice": 54.99,' +
                    '"featureId": 28' +
                '},' +
                '{' +
                    '"productId": 2236798,' +
                    '"productName": "DigitalLine Unlimited",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 0,' +
                    '"itemDiscountPrice": 0,' +
                    '"featureId": 17' +
                '},' +
                '{' +
                    '"productId": 4000042,' +
                    '"productName": "e911 Service Fee",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 1,' +
                    '"itemDiscountPrice": 1,' +
                    '"featureId": 17,' +
                    '"feeType": 911' +
                '},' +
                '{' +
                    '"productId": 4000405,' +
                    '"productName": "Compliance and Administrative Cost Recovery Fee",' +
                    '"chargeTerm": "Monthly",' +
                    '"quantity": 1,' +
                    '"itemListPrice": 4,' +
                    '"itemDiscountPrice": 4,' +
                    '"featureId": 17,' +
                    '"feeType": "CRF"' +
                '}' +
            ']' +
        '}';

        Test.startTest();

            EntitlementSync.DWHResponse dwhResp = EntitlementSync.parseDWHResponse(jsonDwhResp);

            for(EntitlementSync.DWHProduct dwhProduct : dwhResp.rcProducts) {
                if(dwhProduct.featureId == Product2Helper.FEATURE_SERVICE_PLAN_FAX) {
                    System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY, dwhProduct.chargeTerm);
                }
            }

        Test.stopTest();
    }

    @isTest
    static void Test_ItemListPriceForFeature17MustBeAlignedToPbLineRangeMin() {
        //This mockup contains product with feature 28 and itemListPrice
        //equals to 1000 and 4 products with feature 17 and itemListPrice = 0
        String mock = '{"rcUserID":2189686008,"brandId":1210,"serviceId":1,"editionId":5,"tierId":4422,"currency":"USD","currencyId":1,"accountStatus":"Paid","accountStatusId":7,"rcProducts":[{"productId":1003299,"productName":"Monthly-839.8-Pre 20 line","chargeTerm":"Monthly","quantity":1,"itemListPrice":1000,"itemDiscountPrice":1000,"featureId":28},{"productId":2191069,"productName":"DigitalLine Unlimited","chargeTerm":"Monthly","quantity":1,"itemListPrice":41.99,"itemDiscountPrice":34.62,"featureId":17},{"productId":2191069,"productName":"DigitalLine Unlimited","chargeTerm":"Monthly","quantity":1,"itemListPrice":0,"itemDiscountPrice":0,"featureId":17},{"productId":2191069,"productName":"DigitalLine Unlimited","chargeTerm":"Monthly","quantity":1,"itemListPrice":0,"itemDiscountPrice":0,"featureId":17},{"productId":2191069,"productName":"DigitalLine Unlimited","chargeTerm":"Monthly","quantity":1,"itemListPrice":0,"itemDiscountPrice":0,"featureId":17},{"productId":2191069,"productName":"DigitalLine Unlimited","chargeTerm":"Monthly","quantity":1,"itemListPrice":0,"itemDiscountPrice":0,"featureId":17},{"productId":2191069,"productName":"DigitalLine Unlimited","chargeTerm":"Monthly","quantity":1,"itemListPrice":41.99,"itemDiscountPrice":34.62,"featureId":17},{"productId":4000042,"productName":"e911 Service Fee","chargeTerm":"Monthly","quantity":1,"itemListPrice":1,"itemDiscountPrice":1,"featureId":17,"feeType":911},{"productId":4000042,"productName":"e911 Service Fee","chargeTerm":"Monthly","quantity":1,"itemListPrice":1,"itemDiscountPrice":1,"featureId":17,"feeType":911},{"productId":4000042,"productName":"e911 Service Fee","chargeTerm":"Monthly","quantity":1,"itemListPrice":1,"itemDiscountPrice":1,"featureId":17,"feeType":911},{"productId":4000042,"productName":"e911 Service Fee","chargeTerm":"Monthly","quantity":1,"itemListPrice":1,"itemDiscountPrice":1,"featureId":17,"feeType":911},{"productId":4000042,"productName":"e911 Service Fee","chargeTerm":"Monthly","quantity":1,"itemListPrice":1,"itemDiscountPrice":1,"featureId":17,"feeType":911},{"productId":4000042,"productName":"e911 Service Fee","chargeTerm":"Monthly","quantity":1,"itemListPrice":1,"itemDiscountPrice":1,"featureId":17,"feeType":911}]}';

        // DHW:Product:Feature28:itemListPrice / Pricebook2.Line_Range_Min__c
        Decimal alignedPriceByLineRangeMin = 200;

        EntitlementSync.mockDWHJsonResponce = mock;
        Test.setMock(HttpCalloutMock.class, new EntitlementSync());
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        EntitlementSync.syncWithDWH(acc.Id);

        Test.stopTest();

        List<Entitlement__c> entitlements = [
            SELECT Price__c
            FROM Entitlement__c
            WHERE Account__c = :acc.Id AND Product__r.Feature__c = 17];

        System.assert(entitlements.isEmpty() == false, 'Expected to find at least one record');

        for(Entitlement__c entry : entitlements) {
            System.assertEquals(200, entry.Price__c, 'Expected to find 200 as price on the entitlement');
        }
    }


    @isTest
    static void test_ChargeTermWillbeSwitchedToMonthlyIfPbNotExists_Positive() {
        String mock = '{"rcUserID":1448853020,"brandId":1210,"serviceId":2,"tierId":4422,' +
            '"currency":"USD","currencyId":1,"accountStatus":"Paid","accountStatusId":7,' +
            '"rcProducts":[{"productId":1002669,"productName":"Monthly - 29.99 - ProPlus","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":29.99,"itemDiscountPrice":29.99,"featureId":28},{"productId":4000400,' +
            '"productName":"Compliance and Administrative Cost Recovery Fee","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":2,"itemDiscountPrice":2,"featureId":28,"feeType":"CRF"},' +
            '{"productId":2378170,"productName":"Large Meeting 100","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":14.99,"itemDiscountPrice":14.99,"featureId":56},' +
            '{"productId":2378170,"productName":"Large Meeting 100","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":14.99,"itemDiscountPrice":14.99,"featureId":56}]}';

        EntitlementSync.mockDWHJsonResponce = mock;
        Test.setMock(HttpCalloutMock.class, new EntitlementSync());

        Date agreementStartDate = Date.newInstance(2000, 1, 1);
        Quote q = new Quote();
        q.Name = 'Test Quote 1';
        q.OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        q.Start_Date__c = agreementStartDate;
        q.End_Date__c = agreementStartDate.addDays(367);
        insert q;

        Test.startTest();

        Account acc = [SELECT Id FROM Account LIMIT 1];
        EntitlementSync.syncWithDWH(acc.Id);

        Test.stopTest();

        List<Entitlement__c> entitlements = [
            SELECT Product__r.Charge_Term__c
            FROM Entitlement__c
            WHERE Account__c = :acc.Id AND Product__r.Feature__c = 17];

        System.assert(entitlements.isEmpty() == false, 'Expected to find at least one record');

        for(Entitlement__c entry : entitlements) {
            System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY, entry.Product__r.Charge_Term__c,
                'It is expected to find Monthly charge term even if account under agreement');
        }
    }

   @isTest
    static void test_ChargeTermWillbeSwitchedToMonthlyIfPbNotExists_Negative() {
        String mock = '{"rcUserID":1448853020,"brandId":1210,"serviceId":2,"tierId":4422,' +
            '"currency":"USD","currencyId":1,"accountStatus":"Paid","accountStatusId":7,' +
            '"rcProducts":[{"productId":1002669,"productName":"Monthly - 29.99 - ProPlus","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":29.99,"itemDiscountPrice":22.99,"featureId":28},{"productId":4000400,' +
            '"productName":"Compliance and Administrative Cost Recovery Fee","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":2,"itemDiscountPrice":2,"featureId":28,"feeType":"CRF"},' +
            '{"productId":2378170,"productName":"Large Meeting 100","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":14.99,"itemDiscountPrice":7.99,"featureId":56},' +
            '{"productId":2378170,"productName":"Large Meeting 100","chargeTerm":"Monthly","quantity":1,' +
            '"itemListPrice":14.99,"itemDiscountPrice":7.99,"featureId":56}]}';

        EntitlementSync.mockDWHJsonResponce = mock;
        Test.setMock(HttpCalloutMock.class, new EntitlementSync());

        Date agreementStartDate = Date.newInstance(2000, 1, 1);
        Quote q = new Quote();
        q.Name = 'Test Quote 1';
        q.OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        q.Start_Date__c = agreementStartDate;
        q.End_Date__c = agreementStartDate.addDays(367);
        insert q;

        Account acc = [SELECT Active_Sales_Agreement__c FROM Account LIMIT 1];
        acc.Active_Sales_Agreement__c = q.Id;
        update acc;

        Pricebook2 monthlyPb = [
            SELECT Name, Description, Tier_ID__c, Plan__c, IsActive,
                Line_Range_Min__c, Line_Range_Max__c, Service__c, Brand__c
            FROM Pricebook2
            WHERE Tier_ID__c = '4422'];
        Pricebook2 monthlyContractPb = monthlyPb.clone();
        monthlyContractPb.Plan__c = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
        monthlyContractPb.Line_Range_Min__c = 1;
        insert monthlyContractPb;

        List<PricebookEntry> montlyPbes = [
            SELECT UnitPrice, IsActive, UseStandardPrice, Per_Line__c,
                Min_Quantity__c, Max_Quantity__c,
                Product2.Name, Product2.Family, Product2.IsActive,
                Product2.Sub_Category__c, Product2.Feature__c,
                Product2.Charge_Term__c, Product2.ExtID__c
            FROM PricebookEntry
            WHERE Pricebook2Id = :monthlyPb.Id
        ];

        Map<Id, Product2> montlyProductIdToMonthlyContract = new Map<Id, Product2>();
        for (PricebookEntry mPbe : montlyPbes) {
            Product2 clonedPrd = mPbe.Product2.clone();
            clonedPrd.Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT;
            clonedPrd.ExtId__c = mPbe.Product2.ExtId__c + '_cloned';
            montlyProductIdToMonthlyContract.put(mPbe.Product2Id, clonedPrd);
        }
        insert montlyProductIdToMonthlyContract.values();

        Id stdPbId = Test.getStandardPricebookId();
        List<PricebookEntry> stdPbes = new List<PricebookEntry>();
        List<PricebookEntry> mcPbes = new List<PricebookEntry>();
        for (PricebookEntry mPbe : montlyPbes) {
            PricebookEntry mcPbe = mPbe.clone();
            mcPbe.Pricebook2Id = monthlyContractPb.Id;
            mcPbe.Product2Id = montlyProductIdToMonthlyContract.get(mPbe.Product2Id).Id;
            mcPbe.Monthly_Contract_Discount__c = 7;
            mcPbes.add(mcPbe);

            PricebookEntry stdPbe = mPbe.clone();
            stdPbe.Pricebook2Id = stdPbId;
            stdPbe.Product2Id = montlyProductIdToMonthlyContract.get(mPbe.Product2Id).Id;
            stdPbes.add(stdPbe);
        }
        insert stdPbes;
        insert mcPbes;

        Test.startTest();

        EntitlementSync.syncWithDWH(acc.Id);

        List<Entitlement__c> entitlements = [
            SELECT Product__r.Charge_Term__c
            FROM Entitlement__c
            WHERE Account__c = :acc.Id AND Product__r.Feature__c = 17];

        System.assert(entitlements.isEmpty() == false, 'Expected to find at least one record');

        for(Entitlement__c entry : entitlements) {
            System.assertEquals(Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
            entry.Product__r.Charge_Term__c, 'It is expected to find Monthly-Contract charge term');
        }

        Test.stopTest();
    }

    @IsTest
    static void checkThatEntsAreCreatedForNonServiceProdsWithServiceFeatures() {
        final String jsonDwhResp = '{' +
            '"rcUserID": 12345678,' +
            '"brandId": 1210,' +
            '"serviceId": 1,' +
            '"tierId": 4423,' +
            '"currency": "USD",' +
            '"currencyId": 1,' +
            '"accountStatus": "Paid",' +
            '"accountStatusId": 7,' +
            ' "rcProducts": [{' +
            '    "featureId": 28,' +
            '    "itemDiscountPrice": 99.99,' +
            '    "itemListPrice": 99.99,' +
            '    "quantity": 1,' +
            '    "chargeTerm": "Monthly",' +
            '    "productName": "Monthly - 99.99 - ProPremium",' +
            '    "productId": 1002719' +
            '},{' +
            '    "featureId": 17,' +
            '    "itemDiscountPrice": 29.99,' +
            '    "itemListPrice": 29.99,' +
            '    "quantity": 1,' +
            '    "chargeTerm": "Monthly",' +
            '    "productName": "DigitalLine Unlimited",' +
            '    "productId": 2233427' +
            '}]' +
        '}';

        Product2 testServiceProductFeature28 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'ProPremium',
                    Product2.Family => 'Service',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.ExtID__c => '4458_28_Subscription Fee_null_Monthly_null_null_null_false',
                    Product2.Feature__c => 28,
                    Product2.Charge_Term__c => 'Monthly'}
            )
            .create()
            .getRecord();

        Product2 testNonServiceProductFeature17 = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'DigitalLine Unlimited',
                    Product2.Family => 'Add - Ons',
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.ExtID__c => '17_DigitalLine Unlimited_null_Monthly_null_null_null_false',
                    Product2.Feature__c => 17,
                    Product2.Charge_Term__c => 'Monthly'
                }
            )
            .create()
            .getRecord();

        schedulerConfiguration__c scc = (schedulerConfiguration__c) new SObjectBuilder(schedulerConfiguration__c.SObjectType)
            .setField(schedulerConfiguration__c.Name, 'RingCentral')
            .create()
            .getRecord();

        Pricebook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBook2.Tier_ID__c => '4423',
                    PriceBook2.Plan__c => 'Monthly',
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Line_Range_Max__c => 10,
                    PriceBook2.Service__c => 'Office',
                    PriceBook2.Brand__c => scc.Id
                }
            )
            .create()
            .getRecord();

        // create PBEs for testServiceProductFeature28
        new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(
                        new List<Id>{ Test.getStandardPricebookId(), testPriceBook.Id }
                    ),
                    PricebookEntry.Product2Id => testServiceProductFeature28.Id,
                    PricebookEntry.UnitPrice => 99.99,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.Per_Line__c => false,
                    PricebookEntry.Min_Quantity__c => 1,
                    PricebookEntry.Max_Quantity__c => 100
                }
            )
            .create();

        // create PBEs for testNonServiceProductFeature17
        new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(
                        new List<Id>{ Test.getStandardPricebookId(), testPriceBook.Id }
                    ),
                    PricebookEntry.Product2Id => testNonServiceProductFeature17.Id,
                    PricebookEntry.UnitPrice => 29.99,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.Per_Line__c => false,
                    PricebookEntry.Min_Quantity__c => 1,
                    PricebookEntry.Max_Quantity__c => 100
                }
            )
            .create();

        EntitlementSync.DWHResponse dwhResp = EntitlementSync.parseDWHResponse(jsonDwhResp);
        EntitlementSync.DWHProducts dwhProducts = new EntitlementSync.DWHProducts(dwhResp.rcProducts);
        dwhProducts.normalize('Monthly');
        List<Entitlement__c> currentEntls = new List<Entitlement__c>();
        Map<String, Entitlement__c> currentEntMap = new Map<String, Entitlement__c>();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        EntitlementSync.ProductsMatcher pMatcher = new EntitlementSync.ProductsMatcher(dwhResp, dwhProducts);
        Test.startTest();
            List<Entitlement__c> ents = pMatcher.fallbackToMonthly()
                                                .matchBySFProduct(currentEntls)
                                                .matchBySFPbe()
                                                .matchEntToProd(currentEntls, currentEntMap, acc);
        Test.stopTest();

        System.assertEquals(2, ents.size(), 'Entitlements creation from DWH products worked incorrectly');

        Set<Id> testProdIds = new Set<Id> {
            testServiceProductFeature28.Id,
            testNonServiceProductFeature17.Id
        };

        Set<Id> entProdIds = new Set<Id> {
            ents[0].Product__c,
            ents[1].Product__c
        };

        System.assert(
            testProdIds.containsAll(entProdIds),
            'Products on new entitlements are different from test products'
        );
    }

    @isTest
    private static void testPDtoDeactivateEntitlement() {
        QuoteLineItem  testQli   = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        PricebookEntry testPBE2  = [SELECT Id FROM PricebookEntry LIMIT 1];
        Opportunity    testOpp   = [SELECT Id FROM Opportunity LIMIT 1];
        Account        testAcc   = [SELECT Id FROM Account LIMIT 1];
        Quote          testQuote = [SELECT Id FROM Quote LIMIT 1];

        Id contactCenterRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Contact Center').getRecordTypeId();

        Order testOrder = new Order(
            AccountId = testAcc.Id,
            Status = 'New',
            EffectiveDate = System.today(),
            inContact_Cluster__c = 'C20',
            inContact_account_ID__c = 'testInContactAccountId',
            Provision_Date__c = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            QuoteId = testQuote.Id,
            OpportunityId = testOpp.Id,
            TotalBandwidthOnQuote__c = 2,
            RecordTypeId = contactCenterRecTypeId,
            Is_Cancel_Order__c = true
        );
        insert testOrder;

        Entitlement__c entitlement = new Entitlement__c(
            Account__c = testAcc.Id,
            Quantity__c = 10,
            Active__c = true
        );
        insert entitlement;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPBE2.Id,
            Quantity = 0,
            RC_Entitlement__c = entitlement.Id,
            UnitPrice = testQli.UnitPrice,
            Active__c = true
        );
        insert testOrderItem;

        ProductDetail__c productDetail = new ProductDetail__c(
            QuantityOrThreshold__c = 2,
            Entitlement__c = Entitlement.Id
        );

        insert productDetail;

        testOrder.Status = 'Submitted';
        update testOrder;

        List<ProductDetail__c> listProductDetails = [SELECT Id FROM ProductDetail__c WHERE Entitlement__c = :Entitlement.Id];
        System.assertEquals(listProductDetails.size(), 1);
    }

    @isTest
    private static void testPDtoEntitlement() {
        QuoteLineItem  testQli   = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        PricebookEntry testPBE2  = [SELECT Id FROM PricebookEntry LIMIT 1];
        Opportunity    testOpp   = [SELECT Id FROM Opportunity LIMIT 1];
        Account        testAcc   = [SELECT Id FROM Account LIMIT 1];
        Quote          testQuote = [SELECT Id FROM Quote LIMIT 1];

        Id contactCenterRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Contact Center').getRecordTypeId();

        Order testOrder = new Order(
            AccountId = testAcc.Id,
            Status = 'New',
            EffectiveDate = System.today(),
            inContact_Cluster__c = 'C20',
            inContact_account_ID__c = 'testInContactAccountId',
            Provision_Date__c = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            QuoteId = testQuote.Id,
            OpportunityId = testOpp.Id,
            TotalBandwidthOnQuote__c = 2,
            RecordTypeId = contactCenterRecTypeId
        );
        insert testOrder;

        Entitlement__c entitlement = new Entitlement__c(
            Account__c = testAcc.Id,
            Quantity__c = 10,
            Active__c = true
        );
        insert entitlement;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPBE2.Id,
            Quantity = 0,
            RC_Entitlement__c = entitlement.Id,
            UnitPrice = testQli.UnitPrice,
            Active__c = true
        );
        insert testOrderItem;

        List<ProductDetail__c> listProductDetails = new List<ProductDetail__c>();

        ProductDetail__c productDetail = new ProductDetail__c(
            QuantityOrThreshold__c = 2,
            Entitlement__c = Entitlement.Id
        );
        ProductDetail__c productDetail2 = new ProductDetail__c(
            QuantityOrThreshold__c = 0,
            OrderItem__c = testOrderItem.Id
        );
        ProductDetail__c productDetail3 = new ProductDetail__c(
            QuantityOrThreshold__c = -1,
            OrderItem__c = testOrderItem.Id
        );

        listProductDetails.add(productDetail);
        listProductDetails.add(productDetail2);
        listProductDetails.add(productDetail3);

        insert listProductDetails;

        ProductDetail__c productDetail4 = new ProductDetail__c(
            QuantityOrThreshold__c = 0,
            OrderItem__c = testOrderItem.Id,
            ProductDetail__c = productDetail.Id,
            RampUp__c = '30'
        );

        insert productDetail4;

        testOrder.Status = 'Submitted';
        update testOrder;

        List<ProductDetail__c> listEnProductDetails = [SELECT Id FROM ProductDetail__c WHERE Entitlement__c = :Entitlement.Id];
        System.assertEquals(listEnProductDetails.size(), 1);
    }

    @isTest
    private static void testPDtoOrderItem() {
        QuoteLineItem  testQli   = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        PricebookEntry testPBE2  = [SELECT Id FROM PricebookEntry LIMIT 1];
        Opportunity    testOpp   = [SELECT Id FROM Opportunity LIMIT 1];
        Account        testAcc   = [SELECT Id FROM Account LIMIT 1];
        Quote          testQuote = [SELECT Id FROM Quote LIMIT 1];

        Id contactCenterRecTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Contact Center').getRecordTypeId();

        Order testOrder = new Order(
            AccountId = testAcc.Id,
            Status = 'New',
            EffectiveDate = System.today(),
            inContact_Cluster__c = 'C20',
            inContact_account_ID__c = 'testInContactAccountId',
            Provision_Date__c = System.today(),
            Pricebook2Id = Test.getStandardPricebookId(),
            QuoteId = testQuote.Id,
            OpportunityId = testOpp.Id,
            TotalBandwidthOnQuote__c = 2,
            RecordTypeId = contactCenterRecTypeId
        );
        insert testOrder;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPBE2.Id,
            Quantity = 0,
            UnitPrice = testQli.UnitPrice,
            Active__c = true
        );
        insert testOrderItem;

        ProductDetail__c productDetail = new ProductDetail__c(
            QuantityOrThreshold__c = 2,
            OrderItem__c = testOrderItem.Id
        );
        insert productDetail;

        testOrder.Status = 'Submitted';
        update testOrder;

        List<ProductDetail__c> listProductDetails = [SELECT Id FROM ProductDetail__c WHERE OrderItem__c = :testOrderItem.Id];
        System.assertEquals(listProductDetails.size(), 1);
    }
}