@isTest
private class Test_ExtendedEnterpriseSupport {

    private static User createUser(String name) {
        User user = new User(
                Username = name + '!user@gmail.com',
                LastName = 'Test' + name,
                Email = name + '_user@gmail.com',
                Alias = 'test' + name,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    private static PricebookEntry digitalLinePbe;
    private static PricebookEntry testEESPbeBronze;
    private static PricebookEntry testEESPbeSilver;
    private static PricebookEntry testEESPbeGold;
    private static Quote testQuote;

    @testSetup
    static void setup() {

        // wrap testSetup in start/stopTest to avoid 101 soql exception
        Test.startTest();

        createUser('test'); // testUser with admin profile

        Account testAccount = new Account(
                Name = 'myTestAccount',
                Permitted_Brands__c = 'RingCentral'
        );
        insert testAccount;

        Contact testContact = new Contact(
                AccountId = testAccount.Id,
                Email = 'fake@email.com',
                LastName = 'testLastName',
                Phone = '9910106804'
        );
        insert testContact;

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

        Pricebook2 testPriceBook = new Pricebook2(
                Name = 'Test_PriceBook',
                Service__c = 'Office',
                Description = 'test PriceBook',
                IsActive = true,
                Line_Range_Min__c = 1,
                Line_Range_Max__c = 9999,
                CurrencyIsoCode = 'USD'
        );
        insert testPriceBook;

        Quote testQuote = new Quote(
                Name = 'testSalesQuote',
                OpportunityId = testOpp.Id,
                Pricebook2Id = testPriceBook.Id,
                RecordTypeId = QuoteHelper.RT_ID_SALES
        );
        insert testQuote;

        Test.stopTest();
    }

    private static void createTestData(){
        testQuote = [SELECT Id, Pricebook2Id, AccountId FROM Quote LIMIT 1];

        // Create Products
        Product2 digitalLineProduct = new Product2(
                Name = 'Office 2 line',
                IsActive = true,
                Sub_Category__c = 'Main',
                Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY,
                Family = Product2Helper.FAMILY_SERVICE,
                Feature__c = Product2Helper.FEATURE_SERVICE_PLAN
        );

        Product2 eeSupportProductBronze = new Product2(
                Name = Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT + ' Bronze',
                IsActive = true,
                Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
                Seat_Range_Min__c = 1,
                Seat_Range_Max__c = 500
        );

        Product2 eeSupportProductSilver = new Product2(
                Name = Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT + ' Silver',
                IsActive = true,
                Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
                Seat_Range_Min__c = 500,
                Seat_Range_Max__c = 999
        );

        Product2 eeSupportProductGold = new Product2(
                Name = Product2Helper.NAME_EXTENDED_ENTERPRISE_SUPPORT + ' Gold',
                IsActive = true,
                Feature__c = Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT,
                Seat_Range_Min__c = 1000,
                Seat_Range_Max__c = 1499
        );

        insert new List<Product2>{
                digitalLineProduct, eeSupportProductBronze,
                eeSupportProductSilver, eeSupportProductGold
        };

        // Create Pricebook Entries

        // Service Plan
        PricebookEntry digitalLineStandardPbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = digitalLineProduct.Id,
                UnitPrice = 1000,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                CurrencyIsoCode = 'USD'
        );

        digitalLinePbe = new PricebookEntry(
                Pricebook2Id = testQuote.Pricebook2Id,
                Product2Id = digitalLineProduct.Id,
                UnitPrice = 1000,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        // Bronze
        PricebookEntry standartEESPbeBronze = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = eeSupportProductBronze.Id,
                UnitPrice = 500,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        testEESPbeBronze = new PricebookEntry(
                Pricebook2Id = testQuote.Pricebook2Id,
                Product2Id = eeSupportProductBronze.Id,
                UnitPrice = 700,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        // Silver
        PricebookEntry standartEESPbeSilver = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = eeSupportProductSilver.Id,
                UnitPrice = 500,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        testEESPbeSilver = new PricebookEntry(
                Pricebook2Id = testQuote.Pricebook2Id,
                Product2Id = eeSupportProductSilver.Id,
                UnitPrice = 700,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        // Gold
        PricebookEntry standartEESPbeGold = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = eeSupportProductGold.Id,
                UnitPrice = 500,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        testEESPbeGold = new PricebookEntry(
                Pricebook2Id = testQuote.Pricebook2Id,
                Product2Id = eeSupportProductGold.Id,
                UnitPrice = 700,
                IsActive = true,
                UseStandardPrice = false,
                CurrencyIsoCode = 'USD'
        );

        insert new List<PricebookEntry>{
                digitalLineStandardPbe, digitalLinePbe,
                standartEESPbeBronze, testEESPbeBronze,
                standartEESPbeSilver, testEESPbeSilver,
                standartEESPbeGold, testEESPbeGold
        };
    }

    /**
     * Test change Quantity on the same level for New Customers (Quantity manipulations)
     * Also test call from QuotingToolQuoteApexController
     *
     * B-3578 Extended enterprise support to match # of DLs
     * https://rc.my.salesforce.com/a203400000464Gi
     */
    @isTest static void testNewCustomerSameLevelScenario(){
        createTestData();

        QuoteLineItem testDLQLI = QuoteLineItemHelper.createFromPBE(digitalLinePbe);
        testDLQLI.QuoteId = testQuote.Id;
        testDLQLI.Quantity = 510;

        QuoteLineItem testEESPbeSilverQLI = QuoteLineItemHelper.createFromPBE(testEESPbeSilver);
        testEESPbeSilverQLI.QuoteId = testQuote.Id;
        testEESPbeSilverQLI.Quantity = 10;

        insert new List<QuoteLineItem> {
                testDLQLI, testEESPbeSilverQLI
        };
        // For some reason quantity is dropped to 1 on Service Plan Product on Insert
        // Update Quantity for Service Plan
        update testDLQLI;

        Test.startTest();
        QuotingToolQuoteApexController.handleExtendedEnterpriseSupport(testQuote.Id);
        Test.stopTest();

        Map<Id, QuoteLineItem> resultQLIsMap = new Map<Id, QuoteLineItem>([SELECT Id, Quantity FROM QuoteLineItem]);
        QuoteLineItem resultEESPbeSilverQLI = resultQLIsMap.get(testEESPbeSilverQLI.Id);


        System.assertNotEquals(null, resultEESPbeSilverQLI);
        System.assertEquals(testDLQLI.Quantity, resultQLIsMap.get(testEESPbeSilverQLI.Id).Quantity);

    }

    /**
     * Test change Quantity on the same level for Existing Customers (New Quantity manipulations)
     * Also test call from OpportunityCreationFormController
     *
     * B-3578 Extended enterprise support to match # of DLs
     * https://rc.my.salesforce.com/a203400000464Gi
     */
    @isTest static void testExistingCustomerSameLevelScenario(){
        createTestData();

        // Create Entitlements
        Entitlement__c testDLEnt = new Entitlement__c(
                Account__c = testQuote.AccountId,
                Active__c = true,
                Product__c = digitalLinePbe.Product2Id,
                Quantity__c = 510
        );

        Entitlement__c testEESPbeSilverEnt = new Entitlement__c(
                Account__c = testQuote.AccountId,
                Active__c = true,
                Product__c = testEESPbeSilver.Product2Id,
                Quantity__c = 510
        );

        insert new List<Entitlement__c> {
                testDLEnt, testEESPbeSilverEnt
        };

        // Create QuoteLineItems
        QuoteLineItem testDLQLI = QuoteLineItemHelper.createFromPBE(digitalLinePbe);
        testDLQLI.QuoteId = testQuote.Id;
        testDLQLI.Quantity = 190;
        testDLQLI.Zero_Quantity__c = false;
        testDLQLI.NewQuantity__c = 700;
        testDLQLI.Entitlement__c = testDLEnt.Id;

        QuoteLineItem testEESPbeSilverQLI = QuoteLineItemHelper.createFromPBE(testEESPbeSilver);
        testEESPbeSilverQLI.QuoteId = testQuote.Id;
        testEESPbeSilverQLI.Quantity = 1;
        testEESPbeSilverQLI.Zero_Quantity__c = true;
        testEESPbeSilverQLI.NewQuantity__c = 510;
        testEESPbeSilverQLI.Entitlement__c = testEESPbeSilverEnt.Id;

        QuoteTriggerHelper.byPassProServStatusUpdate = true;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
        insert new List<QuoteLineItem> {
                testDLQLI, testEESPbeSilverQLI
        };

        Test.startTest();
            // For some reason quantity is dropped to 1 on Service Plan Product on Insert
            // Update Quantity for Service Plan
            QuoteTriggerHelper.byPassProServStatusUpdate = true;
            QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
            QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
            update testDLQLI;
            QuoteTriggerHelper.byPassProServStatusUpdate = false;
            QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = false;
            QuoteLineItemTriggerHelper.byPassQuoteUpdate = false;


            OpportunityCreationFormController.handleExtendedEnterpriseSupport(testQuote.Id);
        Test.stopTest();

        Map<Id, QuoteLineItem> resultQLIsMap = new Map<Id, QuoteLineItem>([
            SELECT Id, Quantity, NewQuantity__c
            FROM QuoteLineItem
        ]);
        QuoteLineItem resultEESPbeSilverQLI = resultQLIsMap.get(testEESPbeSilverQLI.Id);

        System.assertNotEquals(null, resultEESPbeSilverQLI);
        System.assertEquals(testDLQLI.NewQuantity__c, resultEESPbeSilverQLI.NewQuantity__c);

    }

    /**
     * Test change Quantity out of range level for Existing Customers
     * Old Product should be deactivated and new added for customer
     * Also test call from QuoteLineItemHelper Directly
     *
     * B-3578 Extended enterprise support to match # of DLs
     * https://rc.my.salesforce.com/a203400000464Gi
     */
    @isTest static void testExistingCustomerNewLevelScenario(){
        createTestData();

        // Create Entitlements
        Entitlement__c testDLEnt = new Entitlement__c(
                Account__c = testQuote.AccountId,
                Active__c = true,
                Product__c = digitalLinePbe.Product2Id,
                Quantity__c = 510
        );

        Entitlement__c testEESPbeSilverEnt = new Entitlement__c(
                Account__c = testQuote.AccountId,
                Active__c = true,
                Product__c = testEESPbeSilver.Product2Id,
                Quantity__c = 510
        );

        insert new List<Entitlement__c> {
                testDLEnt, testEESPbeSilverEnt
        };

        // Create QuoteLineItems
        QuoteLineItem testDLQLI = QuoteLineItemHelper.createFromPBE(digitalLinePbe);
        testDLQLI.QuoteId = testQuote.Id;
        testDLQLI.Quantity = 690;
        testDLQLI.Zero_Quantity__c = false;
        testDLQLI.NewQuantity__c = 1200;
        testDLQLI.Entitlement__c = testDLEnt.Id;

        QuoteLineItem testEESPbeSilverQLI = QuoteLineItemHelper.createFromPBE(testEESPbeSilver);
        testEESPbeSilverQLI.QuoteId = testQuote.Id;
        testEESPbeSilverQLI.Quantity = 1;
        testEESPbeSilverQLI.Zero_Quantity__c = true;
        testEESPbeSilverQLI.NewQuantity__c = 510;
        testEESPbeSilverQLI.Entitlement__c = testEESPbeSilverEnt.Id;

        QuoteTriggerHelper.byPassProServStatusUpdate = true;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
        insert new List<QuoteLineItem> {
                testDLQLI, testEESPbeSilverQLI
        };

        Test.startTest();
            // For some reason quantity is dropped to 1 on Service Plan Product on Insert
            // Update Quantity for Service Plan
            QuoteTriggerHelper.byPassProServStatusUpdate = true;
            QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
            QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
            update testDLQLI;
            QuoteTriggerHelper.byPassProServStatusUpdate = false;
            QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = false;
            QuoteLineItemTriggerHelper.byPassQuoteUpdate = false;

            Quote quote = [
                SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, RecordType.Name, (
                    SELECT Id, Product2Id, Product_Type__c, Product2.Feature__c, Product2.Family, Quantity,
                        QuoteId, Zero_Quantity__c, NewQuantity__c, Product2.Seat_Range_Min__c,
                        Product2.Seat_Range_Max__c, Entitlement__r.Id, Deactivated__c,
                        Entitlement__r.Quantity__c, Product2.Name
                    FROM QuoteLineItems
                )
                FROM Quote
                WHERE Id = :testQuote.Id
            ];

            List<PricebookEntry> pricebookEntriesFromSF = [
                SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                    Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                    Product2.Seat_Range_Max__c, Product2.Feature__c, Pricebook2Id, Pricebook2.isStandard, isActive
                FROM PricebookEntry
                WHERE Pricebook2Id = :quote.Pricebook2Id
            ];

            Map<String, List<QuoteLineItem>> result =
                QuoteLineItemHelper.handleExtendedEnterpriseSupport(quote.QuoteLineItems, pricebookEntriesFromSF);

        Test.stopTest();

        QuoteLineItem resultEESPbeSilverQLI = null;
        QuoteLineItem resultEESPbeGoldQLI = null;
        for (QuoteLineItem qli : result.get(QuoteLineItemHelper.ACTION_UPSERT)) {
            if (qli.Id == testEESPbeSilverQLI.Id) {
                resultEESPbeSilverQLI = qli;

            } else if (qli.Id == null) {
                resultEESPbeGoldQLI = qli;
            }
        }

        System.assertNotEquals(null, resultEESPbeSilverQLI);
        System.assertEquals(0, resultEESPbeSilverQLI.NewQuantity__c);
        System.assertEquals(true, resultEESPbeSilverQLI.Deactivated__c);
        System.assertEquals(-testEESPbeSilverEnt.Quantity__c, resultEESPbeSilverQLI.Quantity);

        System.assertNotEquals(null, resultEESPbeGoldQLI);
        System.assertEquals(testDLQLI.NewQuantity__c, resultEESPbeGoldQLI.Quantity);
    }

    /**
     * Test change Quantity out of range level for Existing Customers
     * New Product should be deleted and existing restored with ServicePlan Quantity
     * Also test call from QuoteLineItemHelper Directly
     *
     * B-3578 Extended enterprise support to match # of DLs
     * https://rc.my.salesforce.com/a203400000464Gi
     */
    @isTest static void testExistingCustomerRestoreLevelScenario(){
        createTestData();

        // Create Entitlements
        Entitlement__c testDLEnt = new Entitlement__c(
                Account__c = testQuote.AccountId,
                Active__c = true,
                Product__c = digitalLinePbe.Product2Id,
                Quantity__c = 510
        );

        Entitlement__c testEESPbeSilverEnt = new Entitlement__c(
                Account__c = testQuote.AccountId,
                Active__c = true,
                Product__c = testEESPbeSilver.Product2Id,
                Quantity__c = 510
        );

        insert new List<Entitlement__c> {
                testDLEnt, testEESPbeSilverEnt
        };

        // Create QuoteLineItems
        QuoteLineItem testDLQLI = QuoteLineItemHelper.createFromPBE(digitalLinePbe);
        testDLQLI.QuoteId = testQuote.Id;
        testDLQLI.Quantity = 100;
        testDLQLI.Zero_Quantity__c = false;
        testDLQLI.NewQuantity__c = 610;
        testDLQLI.Entitlement__c = testDLEnt.Id;

        // Deactivated EES product
        QuoteLineItem testEESPbeSilverQLI = QuoteLineItemHelper.createFromPBE(testEESPbeSilver);
        testEESPbeSilverQLI.QuoteId = testQuote.Id;
        testEESPbeSilverQLI.Entitlement__r = testEESPbeSilverEnt;
        testEESPbeSilverQLI.Entitlement__c = testEESPbeSilverEnt.Id;
        QuoteLineItemHelper.deactivate(testEESPbeSilverQLI);

        QuoteLineItem testEESPbeGoldQLI = QuoteLineItemHelper.createFromPBE(testEESPbeGold);
        testEESPbeGoldQLI.QuoteId = testQuote.Id;
        testEESPbeGoldQLI.Quantity = 1100;

        Triggers.switchOff();
        insert new List<QuoteLineItem> {
                testDLQLI, testEESPbeSilverQLI, testEESPbeGoldQLI
        };
        Triggers.switchOn();

        Test.startTest();
        Quote quote = [
                SELECT Id, AccountId, Pricebook2Id, CurrencyIsoCode, RecordType.Name, (
                        SELECT Id, Product2Id, Product_Type__c, Product2.Feature__c, Product2.Family, Quantity,
                                QuoteId, Zero_Quantity__c, NewQuantity__c, Product2.Seat_Range_Min__c,
                                Product2.Seat_Range_Max__c, Entitlement__r.Id, Deactivated__c,
                                Entitlement__r.Quantity__c, Entitlement__r.DisplayQuantity__c, Product2.Name
                        FROM QuoteLineItems
                )
                FROM Quote
                WHERE Id = :testQuote.Id
        ];
        System.debug(quote.QuoteLineItems);

        List<PricebookEntry> pricebookEntriesFromSF = [
                SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Charge_Term__c, UnitPrice,
                        Product2.Description, Product2.Sub_Category__c, Product2.Edition__c, Product2.Seat_Range_Min__c,
                        Product2.Seat_Range_Max__c, Product2.Feature__c, Pricebook2Id, Pricebook2.isStandard, isActive
                FROM PricebookEntry
                WHERE Pricebook2Id = :quote.Pricebook2Id
        ];

        Map<String, List<QuoteLineItem>> result =
                QuoteLineItemHelper.handleExtendedEnterpriseSupport(quote.QuoteLineItems, pricebookEntriesFromSF);

        Test.stopTest();


        Map<Id, QuoteLineItem> resultQLIsUpsertMap = new Map<Id, QuoteLineItem>(result.get(QuoteLineItemHelper.ACTION_UPSERT));
        Map<Id, QuoteLineItem> resultQLIsDeleteMap = new Map<Id, QuoteLineItem>(result.get(QuoteLineItemHelper.ACTION_DELETE));

        QuoteLineItem resultEESPbeGoldQLI = resultQLIsDeleteMap.get(testEESPbeGoldQLI.Id);
        QuoteLineItem resultEESPbeSilverQLI = resultQLIsUpsertMap.get(testEESPbeSilverQLI.Id);

        System.assertNotEquals(null, resultEESPbeSilverQLI);
        System.assertEquals(testDLQLI.NewQuantity__c, resultEESPbeSilverQLI.NewQuantity__c);
        System.assertEquals(false, resultEESPbeSilverQLI.Deactivated__c);
        System.assertEquals(testDLQLI.Quantity, resultEESPbeSilverQLI.Quantity);

        System.assertNotEquals(null, resultEESPbeGoldQLI);

        System.assertEquals(1, resultQLIsUpsertMap.values().size());
        System.assertEquals(1, resultQLIsDeleteMap.values().size());
    }

    /**
     * Test add EESBronze - quantity for EESBronze product should be fixed at 1
     *
     * B-5501 Move Extended Enterprise Support logic to new Feature
     * https://rc.my.salesforce.com/a20340000059lFC
     */
    @isTest
    static void testInsertEESBronze() {

        insert new Feature_Toggle__c (
            UseFeature70ForEES__c = true
        );

        createTestData();

        QuoteLineItem testDLQLI = QuoteLineItemHelper.createFromPBE(digitalLinePbe);
        testDLQLI.QuoteId = testQuote.Id;
        testDLQLI.Quantity = 400;

        QuoteLineItem testEESPbeBronzeQLI = QuoteLineItemHelper.createFromPBE(testEESPbeBronze);
        testEESPbeBronzeQLI.QuoteId = testQuote.Id;
        testEESPbeBronzeQLI.Quantity = 10;

        insert new List<QuoteLineItem> {
                testDLQLI, testEESPbeBronzeQLI
        };
        // For some reason quantity is dropped to 1 on Service Plan Product on Insert
        // Update Quantity for Service Plan
        update testDLQLI;

        Test.startTest();
        QuotingToolQuoteApexController.handleExtendedEnterpriseSupport(testQuote.Id);
        Test.stopTest();

        Map<Id, QuoteLineItem> resultQLIsMap = new Map<Id, QuoteLineItem>([SELECT Id, Quantity FROM QuoteLineItem]);
        QuoteLineItem resultEESPbeBronzeQLI = resultQLIsMap.get(testEESPbeBronzeQLI.Id);


        System.assertNotEquals(null, resultEESPbeBronzeQLI);
        System.assertEquals(1, resultQLIsMap.get(testEESPbeBronzeQLI.Id).Quantity);
    }
}