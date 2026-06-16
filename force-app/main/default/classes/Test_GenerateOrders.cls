@isTest
private class Test_GenerateOrders {

    private static Opportunity opp;
    private static Account testAccount;
    private static Quote testQuote;
    private static Quote proservTestQuote;
    private static Quote billingTestQuote;
    private static Quote ccTestQuote;
    private static QuoteLineItem testQuoteLineItem;
    private static QuoteLineItem testServiceQuoteLineItem;
    private static QuoteLineItem testEntitlementQuoteLineItem1;
    private static QuoteLineItem testEntitlementQuoteLineItem2;
    private static List<QuoteLineItem> testQuoteLineItems = new List<QuoteLineItem>();
    private static Product2 productTestEntitlement;
    private static PriceBook2 testPriceBook;

    private static void CreateTestData(Id standardPriceBookId, String oppStageName) {

        Triggers.switchOff();
        testAccount = new Account(Name = 'Test Account', Number_of_DL_s__c = 10, BillingCity = 'TestCity', BillingStreet = 'TestStreet', Payment_Method__c = 'Invoice', SignupType__c = 'Direct');
        insert testAccount;

        Contact testContact = new Contact(AccountId = testAccount.Id, LastName = 'Golovanov', FirstName = 'Fedor', Email = 'fgolovanov@newmarketinc.com');
        insert testContact;
        Area_Codes__c areaCode = new Area_Codes__c(Name = '999', Area_Code__c = 999, City__c = 'TestCity', State_Abbreviation__c = 'ST', StateID__c = 99);
        insert areaCode;

        schedulerConfiguration__c scc = new schedulerConfiguration__c(Name='RingCentral');
        insert scc;

        testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', Tier_ID__c = '999', Plan__c = 'Annual', IsActive = true, Line_Range_Min__c = 5, Line_Range_Max__c = 10, Service__c = 'Office', Brand__c = scc.Id);
        insert testPriceBook;

        //Create products
        List<Product2> testProducts = new List<Product2>();
        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', Family = 'Office', IsActive = true, Sub_Category__c = 'Main');
        testProducts.add(testProduct);
        Product2 testServiceProduct = new Product2(Name = 'Connect Pro - Annual Fee2', Family = 'Service', IsActive = true, Sub_Category__c = 'Contact Center');
        testProducts.add(testServiceProduct);
        Product2 testEntitlementProduct1 = new Product2(Name = 'Connect Pro - Annual Fee', Family = 'CC Service', Product_Type__c = 'Seat', IsActive = true, Sub_Category__c = 'Contact Center', Edition__c = 'testEntitlementProduct1');
        testProducts.add(testEntitlementProduct1);
        Product2 testEntitlementProduct2 = new Product2(Name = 'Connect Pro - Annual Fee2', Family = 'CC Service', Product_Type__c = 'Seat', IsActive = true, Sub_Category__c = 'Contact Center', Edition__c = 'testEntitlementProduct2');
        testProducts.add(testEntitlementProduct2);
        insert testProducts;
        productTestEntitlement = testProducts.get(3);

        //Create prices
        List<PricebookEntry> testPricebookEntrys = new List<PricebookEntry>();

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testProduct.Id, UnitPrice = 50, IsActive = true, UseStandardPrice = false);
        testPricebookEntrys.add(standardPrice);
        PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id, UnitPrice = 50, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        testPricebookEntrys.add(testPrice);

        PricebookEntry standardServicePrice = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testServiceProduct.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        testPricebookEntrys.add(standardServicePrice);
        PricebookEntry testServicePrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testServiceProduct.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        testPricebookEntrys.add(testServicePrice);

        PricebookEntry standardEntitlementPrice1 = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testEntitlementProduct1.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        testPricebookEntrys.add(standardEntitlementPrice1);
        PricebookEntry testEntitlementPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testEntitlementProduct1.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        testPricebookEntrys.add(testEntitlementPrice1);

        PricebookEntry standardEntitlementPrice2 = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testEntitlementProduct2.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false);
        testPricebookEntrys.add(standardEntitlementPrice2);
        PricebookEntry testEntitlementPrice2 = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testEntitlementProduct2.Id, UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        testPricebookEntrys.add(testEntitlementPrice2);

        insert testPricebookEntrys;

        opp = new Opportunity(Name = 'Test Opportunity', Type = 'Syndicated - New', StageName = oppStageName, CloseDate = system.today(), Brand_Name__c = 'RingCentral',
                PriceBook2Id = testPriceBook.Id, Primary_Opportunity_Contact__c = testContact.Id, Tier_Name__c = '999', AccountId = testAccount.Id);
        insert opp;

        testQuote = new Quote (Name = 'qoutetest', OpportunityId = opp.id, Status = 'Draft', Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 5, FaxAreaCode__c = areaCode.Id, AreaCode__c = areaCode.Id);
        proservTestQuote = new Quote (Name='proservTestQuote', Pricebook2Id = Test.getStandardPricebookId(), OpportunityId = opp.Id,
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV, ProServ_Status__c = 'Synced');

        billingTestQuote = new Quote (Name='billingTestQuote', Pricebook2Id = Test.getStandardPricebookId(), OpportunityId = opp.Id,
            RecordTypeId = QuoteHelper.RT_ID_BILLING);
        ccTestQuote = new Quote (Name='ccTestQuote', Pricebook2Id = Test.getStandardPricebookId(), OpportunityId = opp.Id,
            RecordTypeId = QuoteHelper.RT_ID_CC);

        insert (new List <Quote>{testQuote, proservTestQuote, billingTestQuote, ccTestQuote});

        Triggers.switchOn();

        //Create line items
        testQuoteLineItems = new List<QuoteLineItem>();

        testQuoteLineItem = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice, Quantity = 5,
                QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id);
        testQuoteLineItems.add(testQuoteLineItem);

        testServiceQuoteLineItem =  new QuoteLineItem (ServiceDate = date.today(), Description = 'TestServiceLineItem', UnitPrice = testServicePrice.UnitPrice, Quantity = 5,
                QuoteId = testQuote.Id, PriceBookEntryId = testServicePrice.Id, Product2Id = testProduct.Id);
        testQuoteLineItems.add(testServiceQuoteLineItem);

        testEntitlementQuoteLineItem1 =  new QuoteLineItem (ServiceDate = date.today(), Description = 'TestEntitlementLineItem1', UnitPrice = testEntitlementPrice1.UnitPrice, Quantity = 5,
                QuoteId = testQuote.Id, PriceBookEntryId = testEntitlementPrice1.Id, Product2Id = testEntitlementProduct1.Id, Deactivated__c = true);
        testQuoteLineItems.add(testEntitlementQuoteLineItem1);

        testEntitlementQuoteLineItem2 =  new QuoteLineItem (ServiceDate = date.today(), Description = 'TestEntitlementLineItem2', UnitPrice = testEntitlementPrice2.UnitPrice, Quantity = 5,
                QuoteId = testQuote.Id, PriceBookEntryId = testEntitlementPrice2.Id, Product2Id = testEntitlementProduct2.Id, Deactivated__c = true);

        DWHEntitlementEndpoint__c dwhEndpoint = new DWHEntitlementEndpoint__c();
        dwhEndpoint.URL__c = 'https://esb.ringcentral.com/service/restapi/entitlements/currentEntitlement/dwh?rcUserId=';

        insert dwhEndpoint;
    }

    //Test that by default no orders will be created
    @isTest static void testInitials() {
        Test.startTest();
        CreateTestData(Test.getStandardPricebookId(), 'Planning');
        Test.stopTest();
        System.assertEquals([SELECT Id FROM Order WHERE OpportunityId =: opp.Id].size(), 0);
    }

    //Test that the error will be raised if there is an incorrect opportunity Id
    @isTest static void testOpportunityException() {
        Test.startTest();
        CreateTestData(Test.getStandardPricebookId(), 'Planning');
        Test.stopTest();

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData('XXXXXXXXX', '1234567890', '0987654321'); //pass fake opportunity Id
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        System.assert(exceptionMessage.contains('Invalid id: XXXXXXXXX'));
        System.assertEquals(result, '');
    }

    //Test that the error will be raised if there stage is planning
    @isTest static void testOpportunityStageException() {
        Test.startTest();
        CreateTestData(Test.getStandardPricebookId(), 'Planning');
        Test.stopTest();

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        System.assert(result.contains(Label.GenerateOrderNotificationOnlyOpptiesInCloseWonStage));
        System.assertEquals(exceptionMessage,'');
    }

    //Test that the error will be raised if there are no quote line items
    @isTest static void testOpportunityNoItemsCreation() {
        Test.startTest();
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);
        Test.stopTest();

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        System.assert(result.contains(Label.GenerateOrderNotificationNoQuoteLineItems));
        System.assertEquals(exceptionMessage,'');
    }

    //Test that the order will be created if there is no error occured
    @isTest static void testOpportunityOrdersCreation() {
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);
        Test.startTest();

        Triggers.SwitchOff();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{'Test Product', 'Test CC Product'}),
                Product2.Charge_Term__c => 'Annual',
                Product2.IsActive => true,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{'Main', 'Contact Center'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{'null_testid1', 'null_testid'}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{'', 'CC Service'}),
                Product2.Product_Type__c => ValueProviderBuilder.provideList(new List<String>{'', 'Seat'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id>{Test.getStandardPricebookId(), ccTestQuote.Pricebook2Id}),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id}),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> testQuoteLineItems = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => 'TestLineItem',
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id>{billingTestQuote.Id, ccTestQuote.Id, ccTestQuote.Id}),
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id, testProducts.get(0).Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{pbeList.get(0).Id, pbeList.get(1).Id, pbeList.get(0).Id}),
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}',
                QuoteLineItem.Package_Info_QLI__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}'
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.SwitchOn();

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        System.assert(result.contains(Label.GenerateOrderNotificationSuccessfullyCreated));
        System.assertEquals([SELECT Id FROM Order WHERE OpportunityId =: opp.Id].size(), 2);
        Test.stopTest();

    }

    //Test that the order and entitlement will be created if there is no error occured
    @isTest static void testOpportunityOrdersAndEntitlementCreation() {
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);
        Test.startTest();
        Triggers.SwitchOff();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{'Test Product', 'Test CC Product'}),
                Product2.Charge_Term__c => 'Annual',
                Product2.IsActive => true,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{'Main', 'Contact Center'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{'null_testid1', 'null_testid'}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{'', 'CC Service'}),
                Product2.Product_Type__c => ValueProviderBuilder.provideList(new List<String>{'', 'Seat'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id>{Test.getStandardPricebookId(), ccTestQuote.Pricebook2Id}),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id}),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> testQuoteLineItems = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => 'TestLineItem',
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id>{billingTestQuote.Id, ccTestQuote.Id, ccTestQuote.Id}),
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id, testProducts.get(0).Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{pbeList.get(0).Id, pbeList.get(1).Id, pbeList.get(0).Id}),
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}',
                QuoteLineItem.Package_Info_QLI__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}'
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.SwitchOn();

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        System.assert(result.contains(Label.GenerateOrderNotificationSuccessfullyCreated));
        System.assertEquals([SELECT Id FROM Order WHERE OpportunityId =: opp.Id].size(), 2);

        Test.stopTest();
    }

    //Test that the case to bizServ will be created if there is error occured during generateOrders process
    @isTest static void testEmailingBizServ() {

        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);
        Test.startTest();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{'Test Product', 'Test CC Product'}),
                Product2.Charge_Term__c => 'Annual',
                Product2.IsActive => true,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{'Main', 'Contact Center'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{'null_testid1', 'null_testid'}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{'', 'CC Service'}),
                Product2.Product_Type__c => ValueProviderBuilder.provideList(new List<String>{'', 'Seat'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id>{Test.getStandardPricebookId(), ccTestQuote.Pricebook2Id}),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id}),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> testQuoteLineItems = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => 'TestLineItem',
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id>{billingTestQuote.Id, ccTestQuote.Id, ccTestQuote.Id}),
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id, testProducts.get(0).Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{pbeList.get(0).Id, pbeList.get(1).Id, pbeList.get(0).Id}),
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}',
                QuoteLineItem.Package_Info_QLI__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}'
            })
            .quantity(3)
            .create()
            .getRecords();

        String exceptionMessage = '';
        String result = '';
        try{

            OrderAfterTriggerHandler.throwTestError = true;

            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }

        Test.stopTest();

        System.debug('result >>>> ' + result);

        System.assertEquals(exceptionMessage, '');

        Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.debug('deserializedResult >>>> ' + deserializedResult);

        System.assertEquals(deserializedResult.get('status'), 'error');
        System.assertEquals(deserializedResult.get('message'), GenerateOrders.EXCEPTION_CATCHED_ERROR_MESSAGE);

        System.assertEquals([SELECT Id FROM Order WHERE OpportunityId =: opp.Id].size(), 0);
    }

    // Test that the order with 'CC Professional Services' recordType will be created
    // if there is product with Sub_Category__c = 'CC Professional Services' and Charge_Term__c = 'One - Time' exist in quote
    @isTest static void testCCProServOrdersCreation() {
        Triggers.switchOff();
        Account testAccount = new Account(
            Name = 'Test Account',
            Number_of_DL_s__c = 10,
            BillingCity = 'TestCity',
            BillingStreet = 'TestStreet',
            Payment_Method__c = 'Invoice',
            SignupType__c = 'Direct');
        insert testAccount;
        Triggers.switchOn();

        Pricebook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            Tier_ID__c = '999',
            Plan__c = 'Annual',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 10,
            Service__c = 'Office');
        insert testPriceBook;

        //Create products
        Product2 testProduct = new Product2(
            Name = 'Connect Pro - Annual Fee',
            Family = 'Office',
            IsActive = true,
            Sub_Category__c = 'Main');

        Product2 testCCProservProduct = new Product2(
                Name = 'Test_CC_PROSERV',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'CC Professional Services',
                CatID__c = 'test1',
                InContact_Name__c = 'test incontact name'
        );
        insert new List<Product2>{testProduct, testCCProservProduct};
        //Create prices
        List<PricebookEntry> testPricebookEntrys = new List<PricebookEntry>();

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false);
        PricebookEntry testPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100);
        PricebookEntry testCcPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testCCProservProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100);
        insert new List<PricebookEntry>{standardPrice, testPrice, testCcPrice};
        Triggers.switchOff();

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Type = 'Syndicated - New',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = system.today(),
            Brand_Name__c = 'RingCentral',
            PriceBook2Id = Test.getStandardPricebookId(),
            Tier_Name__c = '999',
            AccountId = testAccount.Id);
        insert opp;
        Triggers.switchOn();

        Quote testQuote = new Quote (
            Name = 'qoutetest',
            OpportunityId = opp.id,
            Status = 'Draft',
            Pricebook2Id = testPriceBook.id,
            Total_Number_of_Digital_Lines__c = 5);
        Quote proservTestQuote = new Quote (
            Name='proservTestQuote',
            Pricebook2Id = Test.getStandardPricebookId(),
            OpportunityId = opp.Id,
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
            ProServ_Status__c = 'Synced');
        insert (new List <Quote>{testQuote, proservTestQuote});
        //Create line items
        testQuoteLineItems = new List<QuoteLineItem>();

        Test.startTest();
        QuoteLineItem testQuoteLineItem = new QuoteLineItem (
            ServiceDate = date.today(),
            Description = 'TestLineItem',
            UnitPrice = testPrice.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = testPrice.Id,
            Product2Id = testProduct.Id);
        QuoteLineItem testCcQuoteLineItem = new QuoteLineItem (
            ServiceDate = Date.today(),
            Description = 'TestLineItem',
            Quantity = 5,
            QuoteId = proservTestQuote.Id,
            UnitPrice = 50,
            Product2Id = testCCProservProduct.Id,
            PricebookEntryId = testCcPrice.Id);
        insert new List<QuoteLineItem>{testQuoteLineItem, testCcQuoteLineItem};

        proservTestQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
        Triggers.switchOff();
        update proservTestQuote;
        Triggers.switchOn();

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals('', exceptionMessage);

        Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(result.contains(Label.GenerateOrderNotificationSuccessfullyCreated));

        List<Order> orderList = [SELECT Id, RecordTypeId FROM Order WHERE OpportunityId =: opp.Id];

        System.assertEquals(2, orderList.size());

        Set<String> createdOrdersRecordTypeNames = new Set<String>();

        for(Order ord : orderList) {
            String orderRTName = Order.SObjectType.getDescribe().getRecordTypeInfosById().get(ord.RecordTypeId).getName();
            createdOrdersRecordTypeNames.add(orderRTName);
        }
        System.assert(createdOrdersRecordTypeNames.contains('CC Professional Services') == true);
    }


    // Test that the order with 'CC Professional Services' recordType will be created
    // if there is product with Sub_Category__c = 'CC Professional Services' and Charge_Term__c = 'One - Time' exist in quote
    @isTest static void testCCQuoteOrdersCreation() {

        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);

        List<Product2> prodList = new List<Product2>();

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Charge_Term__c = 'Annual',
            IsActive = true,
            Sub_Category__c = 'Main',
            Edition__c = 'Basic',
            ExtID__c = 'null_testid1'
        );
        prodList.add(testProduct);

        Product2 testCCProduct = new Product2(
            Name = 'Test CC Product',
            Charge_Term__c = 'Annual',
            IsActive = true,
            Sub_Category__c = 'Contact Center',
            Product_Type__c = 'Seat',
            Family = 'CC Service',
            Edition__c = 'Basic',
            ExtID__c = 'null_testid'
        );
        prodList.add(testCCProduct);
        insert prodList;


        List<PricebookEntry> pbeList = new List<PricebookEntry>();

        PricebookEntry testPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        pbeList.add(testPrice);

        PricebookEntry testPrice2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testCCProduct.Id,
            UnitPrice = 50,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        pbeList.add(testPrice2);
        insert pbeList;

        QuoteLineItem billingQli = new QuoteLineItem (
            ServiceDate = Date.today(),
            Description = 'TestLineItem',
            Quantity = 5,
            QuoteId = billingTestQuote.Id,
            PackageInfo__c = '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}',
            Package_Info_QLI__c = '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}',
            UnitPrice = 50,
            Product2Id = testProduct.Id,
            PricebookEntryId = testPrice.Id
        );
        testQuoteLineItems.add(billingQli);

        QuoteLineItem qli = new QuoteLineItem (
            ServiceDate = Date.today(),
            Description = 'TestLineItem',
            Quantity = 5,
            QuoteId = ccTestQuote.Id,
            UnitPrice = 50,
            Product2Id = testCCProduct.Id,
            PricebookEntryId = testPrice.Id
        );
        testQuoteLineItems.add(qli);

        Test.startTest();
            insert testQuoteLineItems;
            String exceptionMessage = '';
            String result = '';
            List<Quote> ccQuotes = [SELECT Id, Credit_Amount__c, CurrencyIsoCode, IsPrimary__c, Upsell_Status__c, ProServ_Status__c,
            InvalidGlobalOfficePhonesQuantity__c,InvalidLimitedExtensionPhonesQuantity__c, Pricebook2.Plan__c, Payment_Plan__c,
            LastModifiedDate, Pricebook2Id, End_Date__c, InvalidDiscountedPhonesQuantity__c, SOW_Type__c, Signed_SOW__c,
            Invalid_GO_LE_Phones_Quantity__c, CreatedById, CreatedBy.ManagerId, RecordTypeId,Opportunity.StageName,Brand__c,
            Pricebook2.AllowedRecordType__c,Opportunity.Is_Billing_Opportunity__c,Package_Info__c,Account.Billing_ID__c,
                (SELECT Id, ListPrice, Product2Id, PriceBookEntryId, PricebookEntry.Pricebook2Id,Discount,
                QuoteRecordType__c,Sub_Category__c, Product_Type__c, Charge_Term__c,
                Quantity, UnitPrice, Product2.Product_Type__c, Product2.ExtID__c, EffectivePrice__c,
                Discount_type__c, Discount_number__c, Product2.Sub_Category__c, Matcher_Fields__c, Entitlement__c,
                Entitlement__r.Discount__c, Entitlement__r.Discount_Type__c, Entitlement__r.Quantity__c,
                Zero_Quantity__c, Deactivated__c, Product2.Edition__c, Product2.Number_of_Minutes__c, Package_Info_QLI__c,
                Product2.Family, Product2.Charge_Term__c, Product2.Name, Threshold__c, PackageInfo__c,Product2.Matcher_Formula__c,
                BillingStatus__c, Quantity_or_Threshold__c, Overage_parent__c, Quote.CurrencyIsoCode,
                Quote.InvalidGlobalOfficePhonesQuantity__c,Quote.InvalidLimitedExtensionPhonesQuantity__c,
                Quote.Upsell_Status__c, Quote.End_Date__c, Quote.Pricebook2Id, Quote.Credit_Amount__c,
                Quote.CreatedById, Quote.CreatedBy.ManagerId, Quote.Account.Id, Quote.IsPrimary__c, Quote.Special_Terms__c,
                Quote.SOW_Type__c, Quote.Signed_SOW__c, Quote.RecordTypeId, NewQuantity__c, Asset__c, Quote.Free_Service_Taxes__c,
                Entitlement__r.Product__c
                FROM QuoteLineItems
                WHERE Product2.Sub_Category__c != null
                AND Product2.Family !='Taxes')
                FROM Quote WHERE Name = 'ccTestQuote'];
            try{
                result = GenerateOrders.processDataUniversal(opp.Id, '1234567890', '0987654321', ccQuotes, false);
            }catch(Exception ex){
                exceptionMessage = ex.getMessage();
            }
        Test.stopTest();

        System.assertEquals(exceptionMessage, '');
        List<Order> orderList = [SELECT Id, RecordTypeId FROM Order WHERE OpportunityId =: opp.Id];
        System.assertEquals(1, orderList.size(), 'order should be created only for Contact Center Quote');

        Set<String> createdOrdersRecordTypeNames = new Set<String>();

        for(Order ord : orderList) {
            String orderRTName = Order.SObjectType.getDescribe().getRecordTypeInfosById().get(ord.RecordTypeId).getName();
            createdOrdersRecordTypeNames.add(orderRTName);
        }
        System.assert(createdOrdersRecordTypeNames.contains('Contact Center') == true, 'Contact Center order should be created');
    }


    //Is used to test if assets are properly created when there were no assets previously
    @isTest static void test_AssetCreation() {
        //Create basic test data: opportunities, accounts, quotes..
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);

        Triggers.switchOff();
        //Create proserv products
        Product2 testProservProduct1 = new Product2(
                Name = 'TestProserv1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'CC Professional Services'
        );
        Product2 testProservProduct2 = new Product2(
                Name = 'TestProserv2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'CC Professional Services'
        );
        insert (new List<Product2>{testProservProduct1,testProservProduct2});
        //Create pricebook entries for proserv products
        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{testPrice1, testPrice2});
        //Create quote line items with proserv products
        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 5,
                NewQuantity__c = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct1.Id,
                PricebookEntryId = testPrice1.Id
        );
        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 5,
                NewQuantity__c = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct2.Id,
                PricebookEntryId = testPrice2.Id
        );

        insert (new List<QuoteLineItem>{qli1, qli2});

        proservTestQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
        update proservTestQuote;
        //Create phases
        Phase__c testPhase1 = new Phase__c(
            Name = 'testPhase1',
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
        );
        Phase__c testPhase2 = new Phase__c(
            Name = 'testPhase2',
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
        );
        insert (new List<Phase__c>{testPhase1, testPhase2});
        //Distribute quote line items between phases
        Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = qli1.Id,
                Quantity__c = 3
        );
        Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = qli2.Id,
                Quantity__c = 3
        );
        insert (new List<Hardware_Line_Item__c>{testHLI1, testHLI2});

        Triggers.switchOn();

        Test.startTest();

            //Implement button click "Generate order"
            GenerateOrders.processData(opp.Id, '1234567890', '0987654321');

        Test.stopTest();

        //Check if asset record fields are populated correctly
        Asset createdAssetRecord = [SELECT id, Name, SOW_Type__c, Discount_Type__c, Discount_Number__c, Unit_Price__c, Quantity, AccountId,                        Product2Id, Total_Price__c, Start_Date__c, Delivered_Quantity__c
                                    FROM Asset WHERE Name =: testProservProduct1.Name LIMIT 1];
        System.AssertEquals(createdAssetRecord.SOW_Type__c, 'CC ProServ');
        System.AssertEquals(createdAssetRecord.Discount_Type__c, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY);
        System.AssertEquals(createdAssetRecord.Discount_Number__c, 0);
        System.AssertEquals(createdAssetRecord.Unit_Price__c, 50);
        System.AssertEquals(createdAssetRecord.Quantity, 5);
        System.AssertEquals(createdAssetRecord.AccountId, testAccount.Id);
        System.AssertEquals(createdAssetRecord.Product2Id, testProservProduct1.Id);
        System.AssertEquals(createdAssetRecord.Total_Price__c, 250);
        System.AssertEquals(createdAssetRecord.Start_Date__c, System.today());
        System.AssertEquals(createdAssetRecord.Delivered_Quantity__c, 0);
    }

    @isTest static void test_AssetCreationWithExistingAsset() {
        //Create basic test data: opportunities, accounts, quotes..
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);

        Triggers.switchOff();
        //Create proserv products
        Product2 testProservProduct1 = new Product2(
                Name = 'TestProserv1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'CC Professional Services'
        );
        Product2 testProservProduct2 = new Product2(
                Name = 'TestProserv2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'CC Professional Services'
        );
        insert (new List<Product2>{testProservProduct1,testProservProduct2});
        //Create pricebook entries for proserv products
        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{testPrice1, testPrice2});
        //Create quote line items with proserv products
        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 5,
                NewQuantity__c = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct1.Id,
                PricebookEntryId = testPrice1.Id
        );
        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 5,
                NewQuantity__c = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct2.Id,
                PricebookEntryId = testPrice2.Id
        );

        //Create an asset to check if it will be updated after order generation
        Asset testAsset = new Asset(
            Name = testProservProduct1.Name,
            Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
            Discount_Number__c = 10,
            Unit_Price__c = 200,
            Quantity = 10,
            AccountId = testAccount.Id,
            Product2Id = testProservProduct1.Id,
            Total_Price__c = 2000,
            Start_Date__c = System.today() - 10,
            Delivered_Quantity__c = 0
        );
        insert testAsset;
        //Insert quote line items
        qli1.Asset__c = testAsset.Id;

        insert (new List<QuoteLineItem>{qli1, qli2});

        proservTestQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
        update proservTestQuote;
        //Create phases
        Phase__c testPhase1 = new Phase__c(
            Name = 'testPhase1',
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
        );
        Phase__c testPhase2 = new Phase__c(
            Name = 'testPhase2',
            RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
        );
        insert (new List<Phase__c>{testPhase1, testPhase2});
        //Distribute quote line items by phases
        Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = qli1.Id,
                Quantity__c = 3
        );
        Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
                RingCentral_Hardware_Phase__c = testPhase1.Id,
                Quote_Line_Item__c = qli2.Id,
                Quantity__c = 3
        );
        insert (new List<Hardware_Line_Item__c>{testHLI1, testHLI2});

        Triggers.switchOn();

        Test.startTest();

            //Implement button click "Generate order"
            GenerateOrders.processData(opp.Id, '1234567890', '0987654321');

        Test.stopTest();

        //Check if asset record fields are populated correctly
        Asset createdAssetRecord = [SELECT id, Name, SOW_Type__c, Discount_Type__c, Discount_Number__c, Unit_Price__c,
                                    Quantity, AccountId, Product2Id, Total_Price__c, Start_Date__c, Delivered_Quantity__c
                                    FROM Asset WHERE Name =: testProservProduct1.Name LIMIT 1];
        System.AssertEquals(createdAssetRecord.Discount_Type__c, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY);
        System.AssertEquals(createdAssetRecord.Discount_Number__c,
            qli1.Discount_number__c != null ? qli1.Discount_number__c : 0);
        System.AssertEquals(createdAssetRecord.Unit_Price__c, qli1.UnitPrice);
        System.AssertEquals(createdAssetRecord.Quantity, qli1.NewQuantity__c);
        System.AssertEquals(createdAssetRecord.AccountId, testAccount.Id);
        System.AssertEquals(createdAssetRecord.Product2Id, testProservProduct1.Id);
        System.AssertEquals(createdAssetRecord.Total_Price__c,
            (qli1.UnitPrice == null ? 0 : qli1.UnitPrice) * qli1.NewQuantity__c);
        System.AssertEquals(createdAssetRecord.Start_Date__c, System.today());
        System.AssertEquals(createdAssetRecord.Delivered_Quantity__c, 0);
    }

    @isTest
    static void OrderName_WillNotBeCutted() {
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);

        Test.startTest();
        GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        Test.stopTest();

        List<Order> orders = [
            SELECT Name, RecordType.Name
            FROM Order
            WHERE OpportunityId = :opp.Id
        ];

        for (Order o : orders) {
            System.AssertEquals(opp.Name + ' ' + o.RecordType.Name, o.Name,
                'Unexpected order name: have you changed the way it generated?');
        }
    }

    @isTest
    static void OrderName_WillBeCutted() {
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);
        Triggers.switchOff();
        opp.Name = ('X').leftPad(GenerateOrders.ORDER_NAME_MAX_LENGTH - 1, 'Y');
        update opp;
        Triggers.switchOn();

        Test.startTest();
        GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        Test.stopTest();

        List<Order> orders = [
            SELECT Name, RecordType.Name
            FROM Order
            WHERE OpportunityId = :opp.Id
        ];

        for (Order o : orders) {
            Integer charsToCopyCount = GenerateOrders.ORDER_NAME_MAX_LENGTH - o.RecordType.Name.length() - GenerateOrders.ORDER_NAME_MORE_QUIALIFIER.length();
            System.AssertEquals(opp.Name.substring(0, charsToCopyCount) + GenerateOrders.ORDER_NAME_MORE_QUIALIFIER + o.RecordType.Name, o.Name,
                'Unexpected order name: it should be cutted to satisfy order name field length');
        }
    }

    //Test that the SOW_Type__c filed value will be copied to Order from quote during order Generation
    @isTest
    static void testSOWTypeCopying() {
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);
        Test.startTest();

        Triggers.SwitchOff();

        List<Product2> testProducts = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{'Test Product', 'Test CC Product'}),
                Product2.Charge_Term__c => 'Annual',
                Product2.IsActive => true,
                Product2.Sub_Category__c => ValueProviderBuilder.provideList(new List<String>{'Main', 'Contact Center'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{'null_testid1', 'null_testid'}),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{'', 'CC Service'}),
                Product2.Product_Type__c => ValueProviderBuilder.provideList(new List<String>{'', 'Seat'})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(new List<Id>{Test.getStandardPricebookId(), ccTestQuote.Pricebook2Id}),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id}),
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> testQuoteLineItems = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.ServiceDate => Date.today(),
                QuoteLineItem.Description => 'TestLineItem',
                QuoteLineItem.Quantity => 5,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id>{billingTestQuote.Id, ccTestQuote.Id, ccTestQuote.Id}),
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{testProducts.get(0).Id, testProducts.get(1).Id, testProducts.get(0).Id}),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{pbeList.get(0).Id, pbeList.get(1).Id, pbeList.get(0).Id}),
                QuoteLineItem.PackageInfo__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}',
                QuoteLineItem.Package_Info_QLI__c => '{"categoryCode":"SC","discount":{"value":0,"type":"Money"},"duration":"Annual","id":"5","price":0,"version":"3"}'
            })
            .quantity(3)
            .create()
            .getRecords();

        Triggers.SwitchOn();

        proservTestQuote.SOW_Type__c = 'Single Phase';
        update proservTestQuote;

        String exceptionMessage = '';
        String result = '';
        try{
            result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
        }catch(Exception ex){
            exceptionMessage = ex.getMessage();
        }

        System.assert(result.contains('Orders were successfully created'));

        List<Order> orderList = [SELECT Id, QuoteId, SOW_Type__c FROM Order WHERE OpportunityId =: opp.Id];

        System.assertEquals(2, orderList.size());

        for(Order ord : orderList) {
            if(ord.QuoteId == proservTestQuote.Id) {
                System.assertEquals(ord.SOW_Type__c, proservTestQuote.SOW_Type__c);
            }
        }

        Test.stopTest();
    }

    @isTest
    static void testPopulateChangeOrderLookup() {
        CreateTestData(Test.getStandardPricebookId(), OpportunityHelper.STAGE_NAME_CLOSED_WON);

        Test.startTest();
        List<Order> ordersList = new List<Order>();

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = opp.Id,
            Status = 'Submitted',
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            RecordTypeId = OrderHelper.RT_ID_PROSERV
        );
        insert testOrder;

        Opportunity changeOrderOpp = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Change Order opportuinty',
            StageName = '1. Qualify',
            Parent_Order__c = testOrder.Id,
            RecordTypeId = OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY
        );
        insert changeOrderOpp;

        Order changeOrder = new Order(
            AccountId = testAccount.Id,
            OpportunityId = changeOrderOpp.Id,
            Status = 'Submitted',
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            RecordTypeId = OrderHelper.RT_ID_PROSERV
        );
        insert changeOrder;

        GenerateOrders.OrderWrapper orderWrapper = new GenerateOrders.OrderWrapper(changeOrder, false);
        List<GenerateOrders.OrderWrapper> orderWrapperList = new List<GenerateOrders.OrderWrapper>{orderWrapper};
        Map<String, List<GenerateOrders.OrderWrapper>> ordersMap = new Map<String, List<GenerateOrders.OrderWrapper>>{
            'test' => orderWrapperList
        };
            Order updatedOrder = GenerateOrders.fillChangeOrderLookup(testOrder.Id, ordersMap);

        System.assertNotEquals(null, updatedOrder);
        System.assert(updatedOrder.Change_Order__c != null);
        System.assert(updatedOrder.Change_Order_18DigitId__c != null);
        System.assert(updatedOrder.Change_Order__c == changeOrder.Id);
        System.assert(updatedOrder.Change_Order_18DigitId__c == changeOrder.Id);
        Test.stopTest();
    }

    // Is used to test if contact center order will be created when there are no entitlements for cc products
    @isTest static void test_ContactCenterOrderCreation() {
        // Create basic test data: opportunities, accounts, quotes..
        Triggers.switchOff();
        Account acc = new Account(
            Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = system.today(),
            AccountId = acc.Id);
        insert opp;
        Triggers.switchOn();

        Quote quote = new Quote(Name = 'testQuote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId());
        insert quote;
        //Create contact center products
        Product2 testCCProduct1 = new Product2(
                Name = 'test1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_RC_CONTACT_CENTER);
        Product2 testCCProduct2 = new Product2(
                Name = 'test2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER);
        insert (new List<Product2>{testCCProduct1,testCCProduct2});

        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testCCProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testCCProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert (new List<PricebookEntry>{testPrice1, testPrice2});

        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 5,
                QuoteId = quote.Id,
                UnitPrice = 50,
                Product2Id = testCCProduct1.Id,
                PricebookEntryId = testPrice1.Id);

        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 5,
                QuoteId = quote.Id,
                UnitPrice = 50,
                Product2Id = testCCProduct2.Id,
                PricebookEntryId = testPrice2.Id);
        insert (new List<QuoteLineItem>{qli1, qli2});

        Test.startTest();
            // Implement button click "Generate order"
            GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
            Integer ordersCreatedQuantity = [SELECT count() FROM Order];
            // Verify that orders were created
            System.assertNotEquals(0, ordersCreatedQuantity);
            Integer orderItemsCreatedQuantity = [SELECT count() FROM OrderItem];
            // Verify that order items were created
            System.assertNotEquals(0, orderItemsCreatedQuantity);
        Test.stopTest();
    }

    // Is used to test if contact center order will be created when there are entitlements for cc products
    // and qlis have changes
    @isTest static void test_ContactCenterOrderCreationWithEntitlements() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
            }
        )
        .create()
        .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId()
            }
        )
        .create()
        .getRecord();

        Triggers.switchOff();

        Product2 ccProd = (Product2) new SObjectBuilder(Product2.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Product2.Family => Product2Helper.FAMILY_CCSERVICE,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                Product2.IsActive => true,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            }
        )
        .create()
        .getRecord();

        PricebookEntry ccPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ccProd.Id,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false,
                PricebookEntry.Per_Line__c => false,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.Min_Quantity__c => 1,
                PricebookEntry.Max_Quantity__c => 100
            }
        )
        .create()
        .getRecord();

        Entitlement__c ccEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                Entitlement__c.Product__c => ccProd.Id,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Price__c => 0
            }
        )
        .create()
        .getRecord();

        QuoteLineItem ccQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => ccProd.Id,
                QuoteLineItem.PricebookEntryId => ccPbe.Id,
                QuoteLineItem.Entitlement__c => ccEnt.Id,
                QuoteLineItem.QuoteId => q.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount_number__c => 0,
                QuoteLineItem.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.NewQuantity__c => 2
            }
        )
        .create()
        .getRecord();

        Triggers.switchOn();

        Test.startTest();
            //Implement button click "Generate order"
            GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
            Integer ordersCreatedQuantity = [SELECT count() FROM Order];
            // Verify that orders were created
            System.assertNotEquals(0, ordersCreatedQuantity);
            Integer orderItemsCreatedQuantity = [SELECT count() FROM OrderItem];
            // Verify that order items were created
            System.assertNotEquals(0, orderItemsCreatedQuantity);
        Test.stopTest();
    }

    // // Is used to test if contact center order will be created when there are entitlements for cc products
    // // and qlis have NO changes
    // @isTest static void test_ContactCenterOrderNotCreatedIfQLIsSameAsEnts() {
    //     Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
    //     .setFields(
    //         new Map<SObjectField, Object> {
    //             Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
    //             Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
    //             Opportunity.CloseDate => system.today(),
    //             Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
    //         }
    //     )
    //     .create()
    //     .getRecord();

    //     Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
    //     .setFields(
    //         new Map<SObjectField, Object> {
    //             Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
    //             Quote.OpportunityId => opp.Id,
    //             Quote.Pricebook2Id => Test.getStandardPricebookId()
    //         }
    //     )
    //     .create()
    //     .getRecord();

    //     Product2 ccProd = (Product2) new SObjectBuilder(Product2.SObjectType)
    //     .setFields(
    //         new Map<SObjectField, Object> {
    //             Product2.Family => Product2Helper.FAMILY_CCSERVICE,
    //             Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
    //             Product2.IsActive => true,
    //             Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
    //         }
    //     )
    //     .create()
    //     .getRecord();

    //     PricebookEntry ccPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
    //     .setFields(
    //         new Map<SObjectField, Object> {
    //             PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
    //             PricebookEntry.Product2Id => ccProd.Id,
    //             PricebookEntry.IsActive => true,
    //             PricebookEntry.UseStandardPrice => false,
    //             PricebookEntry.Per_Line__c => false,
    //             PricebookEntry.Min_Quantity__c => 1,
    //             PricebookEntry.Max_Quantity__c => 100
    //         }
    //     )
    //     .create()
    //     .getRecord();

    //     Entitlement__c ccEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
    //     .setFields(
    //         new Map<SObjectField, Object> {
    //             Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
    //             Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
    //             Entitlement__c.Product__c => ccProd.Id,
    //             Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
    //             Entitlement__c.Discount__c => 0,
    //             Entitlement__c.Quantity__c => 1
    //         }
    //     )
    //     .create()
    //     .getRecord();

    //     QuoteLineItem ccQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
    //     .setFields(
    //         new Map<SObjectField, Object> {
    //             QuoteLineItem.Product2Id => ccProd.Id,
    //             QuoteLineItem.PricebookEntryId => ccPbe.Id,
    //             QuoteLineItem.Entitlement__c => ccEnt.Id,
    //             QuoteLineItem.QuoteId => q.Id,
    //             QuoteLineItem.Quantity => 1,
    //             QuoteLineItem.Zero_Quantity__c => true,
    //             QuoteLineItem.UnitPrice => 10,
    //             QuoteLineItem.Discount_number__c => 0,
    //             QuoteLineItem.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
    //             QuoteLineItem.NewQuantity__c => 1
    //         }
    //     )
    //     .create()
    //     .getRecord();
    //     Test.startTest();
    //         GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
    //         Integer ordersCreatedQuantity = [SELECT count() FROM Order];
    //         // No orders should be generated
    //         System.assertEquals(
    //             0,
    //             ordersCreatedQuantity,
    //             'CC Order should not be generated if QLI from Ent isn\'t changed'
    //         );

    //     Test.stopTest();
    // }

    // Is used to test if cancel order will be created for not matched entitlements
//     @isTest static void test_ContactCenterCancelOrderCreation() {
// Test.startTest();
// Triggers.switchOff();
//     //Create basic test data: opportunities, accounts, quotes..
//     Account acc = TestDataFactory.createAccount();

//     Contact cont = TestDataFactory.createContact(acc);

//     Opportunity annualOpp = TestDataFactory.createOppty(acc, cont);

//     Pricebook2 annualPb = TestDataFactory.getAnnualPriceBook();

//     Quote annualQuote = TestDataFactory.createQuote(annualOpp);

//     Product2 prod = TestDataFactory.createCcProduct();

//     PriceBookEntry annualPbe = TestDataFactory.getTestPrice(prod);

//     QuoteLineItem annualQli = TestDataFactory.createQuoteLineItem(annualQuote, prod);

//     annualOpp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
//     update annualOpp;

//     Entitlement__c ent = new Entitlement__c(
//         Active__c = true,
//         Account__c = acc.Id,
//         Product__c = prod.Id,
//         Discount__c = 0,
//         Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
//         Quantity__c = 5);
//     insert ent;

//     Order testOrder = new Order(
//         QuoteId = annualQuote.Id,
//         AccountId = acc.Id,
//         OpportunityId = annualOpp.Id,
//         Status = 'Submitted',
//         Pricebook2Id = annualQuote.PriceBook2Id,
//         EffectiveDate = System.today()
//     );
//     insert testOrder;

//     // Order Items
//     OrderItem annualOrderItem = new OrderItem(
//         OrderId = testOrder.Id,
//         Quantity = annualQli.Quantity,
//         UnitPrice = annualQli.UnitPrice,
//         RC_Entitlement__c = ent.Id,
//         PriceBookEntryId = annualPbe.Id,
//         QuoteLineItemId = annualQli.Id
//     );
//     insert annualOrderItem;

//     Opportunity monthlyOpp = TestDataFactory.createOppty(acc, cont);

//     Pricebook2 monthlyPb = TestDataFactory.getMonthlyPriceBook();

//     Quote monthlyQuote = TestDataFactory.createQuote(monthlyOpp);
//     monthlyQuote.IsPrimary__c = true;
//     monthlyQuote.RecordTypeId = QuoteHelper.RT_ID_SALES;
//     update monthlyQuote;

//     Product2 prod2 = TestDataFactory.createProduct();
//     PriceBookEntry monthlyPbe = TestDataFactory.getTestPrice(prod2);
//     QuoteLineItem monthlyQli = TestDataFactory.createQuoteLineItem(monthlyQuote, prod2);

//     monthlyOpp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
//     update monthlyOpp;

// Triggers.switchOn();
//         //Implement button click "Generate order"
//         GenerateOrders.processData(monthlyOpp.Id, '1234567890', '0987654321');
//         // Submit newly created cancel order to deactivate entitlement
//         Order ordToSubmit = [
//             SELECT Status, Is_Cancel_Order__c
//             FROM Order
//             WHERE Quote.Id = :annualQuote.Id
//                 AND Opportunity.Id = :monthlyOpp.Id
//         ];

//         System.assertEquals(true, ordToSubmit.Is_Cancel_Order__c);

//         ordToSubmit.Status = 'Submitted';
//         update ordToSubmit;

//         // Verify that orders were created
//         Integer ordersCreatedQuantity = [SELECT count() FROM Order];
//         System.assertNotEquals(0, ordersCreatedQuantity);

//         // Verify that order items were created
//         Integer orderItemsCreatedQuantity = [SELECT count() FROM OrderItem];
//         System.assertNotEquals(0, orderItemsCreatedQuantity);

//         Entitlement__c entToCheck = [SELECT Active__c FROM Entitlement__c WHERE Id = :ent.Id LIMIT 1];
//         System.assertEquals(false, entToCheck.Active__c);
//     Test.stopTest();
// }

    @isTest static void test_ContactCenterOrderCreationNGBS() {
        Triggers.switchOff();
        // Create basic test data: opportunities, accounts, quotes..
        Account acc = new Account(
            Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
            CloseDate = system.today(),
            AccountId = acc.Id);
        insert opp;
        Triggers.switchOn();

        Quote quote = new Quote(Name = 'testQuote',
            RecordTypeId = QuoteHelper.RT_ID_CC,
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId());
        insert quote;
        //Create contact center products
        Product2 testCCProduct1 = new Product2(
                Name = 'test1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_RC_CONTACT_CENTER);
        Product2 testCCProduct2 = new Product2(
                Name = 'test2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CONTACT_CENTER);
        insert (new List<Product2>{testCCProduct1,testCCProduct2});

        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testCCProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testCCProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100);
        insert (new List<PricebookEntry>{testPrice1, testPrice2});

        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 5,
                QuoteId = quote.Id,
                UnitPrice = 50,
                Product2Id = testCCProduct1.Id,
                PricebookEntryId = testPrice1.Id);

        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 5,
                QuoteId = quote.Id,
                UnitPrice = 50,
                Product2Id = testCCProduct2.Id,
                PricebookEntryId = testPrice2.Id);
        insert (new List<QuoteLineItem>{qli1, qli2});

        Test.startTest();
            // Implement button click "Generate order"
            GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
            List<Order> ordersCreated = [SELECT RecordTypeId, RecordType.Name FROM Order];
            Order ccOrder = null;
            for(Order o : ordersCreated) {
                if(o.RecordTypeId == OrderHelper.RT_ID_CC) {
                    ccOrder = o;
                }
            }
            // Verify that orders were created
            System.assertNotEquals(0, ordersCreated.size());
            System.assertNotEquals(null, ccOrder);
            Integer orderItemsCreatedQuantity = [SELECT count() FROM OrderItem];
            // Verify that order items were created
            System.assertNotEquals(0, orderItemsCreatedQuantity);
        Test.stopTest();
    }

    @isTest static void test_ContactCenterOrderCreationNGBSUpsell() {

        Triggers.switchOff();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.CloseDate => system.today(),
                    Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
                }
            )
            .create()
            .getRecord();

        // Create primary billing quote
        new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.CurrencyIsoCode => 'USD',
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                    Quote.isPrimary__c => true
                }
            )
            .create();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 ccProd = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Family => Product2Helper.FAMILY_CCSERVICE,
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
                }
            )
            .create()
            .getRecord();

        PricebookEntry ccPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ccProd.Id,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.Per_Line__c => false,
                    PricebookEntry.Min_Quantity__c => 1,
                    PricebookEntry.Max_Quantity__c => 100
                }
            )
            .create()
            .getRecord();

        Entitlement__c ccEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT,
                    Entitlement__c.Product__c => ccProd.Id,
                    Entitlement__c.Price__c => 10,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.Quantity__c => 1
                }
            )
            .create()
            .getRecord();

        QuoteLineItem ccQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.Product2Id => ccProd.Id,
                    QuoteLineItem.PricebookEntryId => ccPbe.Id,
                    QuoteLineItem.Entitlement__c => ccEnt.Id,
                    QuoteLineItem.QuoteId => q.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.Zero_Quantity__c => false,
                    QuoteLineItem.UnitPrice => 10,
                    QuoteLineItem.Discount_number__c => 0,
                    QuoteLineItem.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    QuoteLineItem.NewQuantity__c => 2
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            //Implement button click "Generate order"
            GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
            List<Order> ordersCreated = [SELECT Type, RecordTypeId, RecordType.Name FROM Order];
            Order ccOrder = null;
            for(Order o : ordersCreated) {
                if(o.RecordTypeId == OrderHelper.RT_ID_CC) {
                    ccOrder = o;
                }
            }

            // Verify that CC order was created correctly
            System.assertNotEquals(0, ordersCreated.size());
            System.assertEquals(OrderHelper.CC_ORDER_TYPE_UPSELL, ccOrder.Type, 'Wrong CC Order type');

            // Verify that order items were created
            Integer orderItemsCreatedQuantity = [SELECT count() FROM OrderItem];
            System.assertNotEquals(0, orderItemsCreatedQuantity);
        Test.stopTest();
    }

    @isTest
    static void test_CcProServOrderTypeOnCreationOnUpsell_NewChangeOrderFlow() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.NewChangeOrderFlow__c => false
            })
            .create();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Product2.Family => 'Office',
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'Main'
            }
        )
        .create()
        .getRecord();

        Product2 testCCProservProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Product2.Family => 'Add - Ons',
                Product2.Charge_Term__c => 'One - Time',
                Product2.IsActive => true,
                Product2.Sub_Category__c => 'CC Professional Services',
                Product2.CatID__c => 'test1',
                Product2.InContact_Name__c => 'test incontact name'
            }
        )
        .create()
        .getRecord();

        List<PricebookEntry> testPrices = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideList(
                        new List<Id>{ testProduct.Id, testCCProservProduct.Id }
                    ),
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.UnitPrice => 50,
                    PricebookEntry.Per_Line__c => false,
                    PricebookEntry.Min_Quantity__c => 1,
                    PricebookEntry.Max_Quantity__c => 100
                }
            )
            .create()
            .getRecords();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => system.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType)
            }
        )
        .create()
        .getRecord();
        Triggers.switchOn();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
                }
            )
            .create()
            .getRecord();

        Quote proservTestQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV,
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.ProServ_Status__c => 'Synced'
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        // Create test QLIs
        new SObjectBuilder(QuoteLineItem.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.ServiceDate => Date.today(),
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(
                        new List<Id>{ testQuote.Id, proservTestQuote.Id }
                    ),
                    QuoteLineItem.UnitPrice => 50,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(
                        new List<Id>{ testProduct.Id, testCCProservProduct.Id }
                    ),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(
                        new List<Id>{ testPrices[0].Id, testPrices[1].Id }
                    )
                }
            )
            .create();

            proservTestQuote.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SOLD;
            Triggers.switchOff();
            update proservTestQuote;
            Triggers.switchOn();

            String exceptionMessage = '';
            String result = '';
            try{
                result = GenerateOrders.processData(opp.Id, '1234567890', '0987654321');
            }catch(Exception ex){
                exceptionMessage = ex.getMessage();
            }

        Test.stopTest();

        System.assertEquals('', exceptionMessage);

        Map<String, Object> deserializedResult = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(result.contains(Label.GenerateOrderNotificationSuccessfullyCreated));

        List<Order> orderList = [SELECT Id, RecordTypeId, Type FROM Order WHERE OpportunityId =: opp.Id];

        System.assertEquals(2, orderList.size());

        Order ccProServOrder = null;
        for(Order o : orderList) {
            if(o.RecordTypeId == OrderHelper.RT_ID_CC_PROSERV) {
                ccProServOrder = o;
            }
        }

        System.assertEquals(OrderHelper.TYPE_INITIAL_ORDER, ccProServOrder.Type, 'Wrong CC Order type');
    }

    @IsTest
    private static void testReusingPhases() {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getOrgDefaults();
        featureToggle.NewChangeOrderFlow__c = true;
        insert featureToggle;

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setField(PriceBook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(PriceBook2.IsActive, true)
            .setField(PriceBook2.Line_Range_Min__c, ValueProviderBuilder.provideUniqueNumber(1))
            .setField(PriceBook2.Service__c, Pricebook2Helper.SERVICE_OFFICE)
            .setField(PriceBook2.Plan__c, Pricebook2Helper.PLAN_MONTHLY)
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_CC_PROSERV)
            .setField(Product2.IsActive, true)
            .setField(Product2.Family, Product2Helper.FAMILY_REFURBISHED_PHONES)
            .setField(Product2.Product_Type__c, Product2Helper.PRODUCT_TYPE_SEAT)
            .setField(Product2.Edition__c, 'testEntitlementProduct')
            .create()
            .getRecord();

        PricebookEntry testPricebookentryStandard = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPriceBookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.provideUniqueNumber(100))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.Per_Line__c, false)
            .setField(PricebookEntry.Min_Quantity__c, 1)
            .setField(PricebookEntry.Max_Quantity__c, 100)
            .create()
            .getRecord();
        Triggers.switchOff();

        Account testAcc = (Account) new SObjectFactory()
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {Account.Name => ValueProviderBuilder.provideUniqueString()}
            );

        Contact testCon = (Contact) new SObjectFactory()
            .create(
                Contact.SObjectType,
                new Map<SObjectField, Object> {
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.AccountId => testAcc.Id
                }
            );

        Opportunity testOpp = (Opportunity) new SObjectFactory()
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCon.Id
                }
            );
        Triggers.switchOn();

        Quote testQuote = (Quote) new SObjectFactory()
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_IN_PROGRESS
                }
            );

        Order testOrder = (Order) new SObjectFactory()
            .create(
                Order.SObjectType,
                new Map<SObjectField, Object> {
                    Order.AccountId => testAcc.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.PriceBook2Id => Test.getStandardPricebookId(),
                    Order.QuoteId => testQuote.Id,
                    Order.OpportunityId => testOpp.Id,
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
                }
            );

        Asset testAsset = (Asset) new SObjectFactory()
            .create(
                Asset.SObjectType,
                new Map<SObjectField, Object> {
                    Asset.Name => 'Test Asset',
                    Asset.AccountId => testAcc.Id,
                    Asset.Quantity => 8,
                    Asset.Delivered_Quantity__c => 3
                }
            );

        OrderItem testOrderItem = (OrderItem) new SObjectFactory()
            .create(
                OrderItem.SObjectType,
                new Map<SObjectField, Object> {
                    OrderItem.PricebookEntryId => testPricebookentryStandard.Id,
                    OrderItem.Quantity => 1,
                    OrderItem.Threshold__c => 0,
                    OrderItem.UnitPrice => 19.89,
                    OrderItem.UnitPriceWithoutDiscount__c => 19.99,
                    OrderItem.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    OrderItem.Discount_Number__c => 0.1,
                    OrderItem.Active__c => true,
                    OrderItem.BillingStatus__c => 'Active',
                    OrderItem.Zero_Quantity__c => false,
                    OrderItem.OrderId => testOrder.Id,
                    OrderItem.Asset__c => testAsset.Id
                }
            );

        Map<String, Schema.RecordTypeInfo> PHASE_RECORD_TYPE_MAP =
            Schema.SObjectType.Phase__c.getRecordTypeInfosByName();

        Triggers.switchOff();
        Phase__c testPhase = (Phase__c) new SObjectFactory()
            .create(
                Phase__c.SObjectType,
                new Map<SObjectField, Object> {
                    Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                    Phase__c.Status__c => PhaseHelper.STATUS_NEW,
                    Phase__c.Estimated_Completion_Date__c => System.today(),
                    Phase__c.PhaseDescription__c => 'Test Phase Desc',
                    Phase__c.Opportunity__c => testOpp.Id,
                    Phase__c.Order__c => testOrder.Id,
                    Phase__c.RecordTypeId => PHASE_RECORD_TYPE_MAP.get(PhaseHelper.RT_NAME_PROSERV_PHASE).getRecordTypeId()
                }
            );

        testPhase.Status__c = PhaseHelper.STATUS_LOCKED;
        update testPhase;

        QuoteLineItem testQuoteLineItem = (QuoteLineItem) new SObjectFactory()
            .create(
                QuoteLineItem.SObjectType,
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => testPricebookentryStandard.Id,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.UnitPrice => testPricebookentryStandard.UnitPrice
                }
            );

        Hardware_Line_Item__c testPhaseLineItem = (Hardware_Line_Item__c) new SObjectFactory()
            .create(
                Hardware_Line_Item__c.SObjectType,
                new Map<SObjectField, Object> {
                    Hardware_Line_Item__c.Name => ValueProviderBuilder.provideUniqueString(),
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                    Hardware_Line_Item__c.Quote_Line_Item__c => testQuoteLineItem.Id
                }
            );

        //Test.startTest() is here because otherwise getting 101 soql error while setting up test data
        Test.startTest();
        Opportunity changeOrderOpportunity = (Opportunity) new SObjectFactory()
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'testChangeOrderOpportunity',
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.Parent_Order__c => testOrder.Id,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCon.Id
                }
            );

        Quote changeOrderQuote = (Quote) new SObjectFactory()
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => changeOrderOpportunity.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_IN_PROGRESS
                }
            );

        Order testChangeOrder = (Order) new SObjectFactory()
            .create(
                Order.SObjectType,
                new Map<SObjectField, Object> {
                    Order.AccountId => testAcc.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.PriceBook2Id => Test.getStandardPricebookId(),
                    Order.QuoteId => changeOrderQuote.Id,
                    Order.OpportunityId => changeOrderOpportunity.Id,
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
                }
            );

        Phase__c clonedPhase = (Phase__c) new SObjectFactory()
            .create(
                Phase__c.SObjectType,
                new Map<SObjectField, Object> {
                    Phase__c.Name => 'Cloned Phase',
                    Phase__c.Status__c => PhaseHelper.STATUS_NEW,
                    Phase__c.Estimated_Completion_Date__c => System.today().addDays(2),
                    Phase__c.PhaseDescription__c => 'cloned Phase',
                    Phase__c.Opportunity__c => changeOrderOpportunity.Id,
                    Phase__c.Order__c => testChangeOrder.Id,
                    Phase__c.Last_Phase__c => testPhase.Id,
                    Phase__c.RecordTypeId => PhaseHelper.RT_ID_PROSERV_PHASE
                }
            );

        Phase__c changePhase = (Phase__c) new SObjectFactory()
            .create(
                Phase__c.SObjectType,
                new Map<SObjectField, Object> {
                    Phase__c.Name => 'New Phase',
                    Phase__c.Status__c => PhaseHelper.STATUS_NEW,
                    Phase__c.Estimated_Completion_Date__c => System.today().addDays(2),
                    Phase__c.PhaseDescription__c => 'new Phase',
                    Phase__c.Opportunity__c => changeOrderOpportunity.Id,
                    Phase__c.Order__c => testChangeOrder.Id,
                    Phase__c.RecordTypeId => PhaseHelper.RT_ID_PROSERV_PHASE
                }
            );

        QuoteLineItem clonedQuoteLineItem = (QuoteLineItem) new SObjectFactory()
            .create(
                QuoteLineItem.SObjectType,
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => changeOrderQuote.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => testPricebookentryStandard.Id,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.UnitPrice => testPricebookentryStandard.UnitPrice
                }
            );

        QuoteLineItem changeQuoteLineItem = (QuoteLineItem) new SObjectFactory()
            .create(
                QuoteLineItem.SObjectType,
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => changeOrderQuote.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.PricebookEntryId => testPricebookentryStandard.Id,
                    QuoteLineItem.Quantity => 5,
                    QuoteLineItem.UnitPrice => testPricebookentryStandard.UnitPrice
                }
            );

        Hardware_Line_Item__c newPhaseLineItem = (Hardware_Line_Item__c) new SObjectFactory()
            .create(
                Hardware_Line_Item__c.SObjectType,
                new Map<SObjectField, Object> {
                    Hardware_Line_Item__c.Name => 'Test new for cloned',
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => clonedPhase.Id,
                    Hardware_Line_Item__c.Quote_Line_Item__c => clonedQuoteLineItem.Id
                }
            );

        Hardware_Line_Item__c changePhaseLineItem = (Hardware_Line_Item__c) new SObjectFactory()
            .create(
                Hardware_Line_Item__c.SObjectType,
                new Map<SObjectField, Object> {
                    Hardware_Line_Item__c.Name => 'Test new',
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => changePhase.Id,
                    Hardware_Line_Item__c.Quote_Line_Item__c => changeQuoteLineItem.Id
                }
            );

        changeOrderOpportunity = GenerateOrders.getOpportunityRecord(changeOrderOpportunity.Id);
        QuoteSelector quoteSelector = new QuoteSelector();
        List<Object> binds = new List<Object>();
        binds.add(changeOrderQuote.Id);
        List<Quote> selectedQuotes = (List<Quote>) quoteSelector.selectQuoteById(binds).executeQuery();

        Triggers.switchOn();
        GenerateOrders.reuseOriginalPhases(changeOrderOpportunity, selectedQuotes, testChangeOrder);

        PhaseSelector phaseSelector = new PhaseSelector();
        List<Phase__c> phases = phaseSelector.selectPhases().executeQuery();
        Test.stopTest();

        System.assertEquals(2, phases.size(), 'Wrong amount of phases for change order');

        Set<Id> phaseIds = new Set<Id>();
        for (Phase__c phase : phases) {
            phaseIds.add(phase.Id);
            if (phase.Id == clonedPhase.Id) {
                System.assert(false, 'Cloned phase should be deleted');
            }
            if (phase.Id == testPhase.Id) {
                System.assertEquals(clonedPhase.Estimated_Completion_Date__c, phase.Estimated_Completion_Date__c,
                    'Phase Estimated Completion Date was not updated');
            }
        }

        MavenlinkIntegratorSelector mlIntegratorSelector = new MavenlinkIntegratorSelector();
        List<Mavenlink_Integrator__c> mlRecords = (List<Mavenlink_Integrator__c>) mlIntegratorSelector
                                                                                        .selectMavenlinkIntegrator()
                                                                                        .executeQuery();
        AssetSelector selector = new AssetSelector();
        List<Object> bindings = new List<Object>();
        bindings.add(new Set<Id>{ testAsset.Id });
        Asset asst = (Asset) selector.selectAssetsByIds(bindings).executeQuery().get(0);
        System.assertEquals(3, asst.Quantity, 'Asset Quantity was not updated correctly');
        System.assertEquals(true,
                            mlRecords.isEmpty(),
                            'Mavenlink Integrator should NOT be created.');
    }

    @IsTest
    private static void testValidationErrorsOnBillingQuote() {
        Account testAcc = (Account) new SObjectFactory()
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {Account.Name => ValueProviderBuilder.provideUniqueString()}
            );

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.InvalidDiscountedPhonesQuantity__c => true,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        GenerateOrders.opp = testOpp;

        String error = GenerateOrders.getValidationErrors(new List<Quote>{testQuote});
        System.assertEquals(
            null,
            error,
            'old legacy validations shouldn\'t affect Billing Opportunity Quotes'
        );
    }

    @IsTest
    private static void testValidationErrorsOnLegacySalesQuote() {
        Account testAcc = (Account) new SObjectFactory()
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {Account.Name => ValueProviderBuilder.provideUniqueString()}
            );

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.InvalidDiscountedPhonesQuantity__c => true,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                }
            )
            .create()
            .getRecord();

        GenerateOrders.opp = testOpp;

        String error = GenerateOrders.getValidationErrors(new List<Quote>{testQuote});
        System.assertEquals(
            '{' +
                '"details":' +
                    '"Make sure that primary quote has the same number of Phones and DigitalLines in the Cart. ' +
                    'Only after that you can generate orders",' +
                '"message":' +
                    '"Primary quote has different number of Phones and DigitalLines",' +
                '"status":' +
                    '"error"' +
            '}',
            error,
            'legacy validations should affect old Sales Quotes'
        );
    }

    @IsTest
    private static void testValidationErrorsOnProServQuote() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .build()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsMultiProductTechnicalQuote__c => new ValueProvider.ListProvider(new List<Boolean> { true, false }),
                Quote.ServiceName__c => new ValueProvider.ListProvider(new List<String> {
                    OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                    OpportunityHelper.TIER_OFFICE
                }),
                Quote.RecordTypeId => new ValueProvider.ListProvider(new List<String> {
                    QuoteHelper.RT_ID_BILLING,
                    QuoteHelper.RT_ID_CC_PROSERV
                })
            })
            .quantity(2)
            .build()
            .getRecords();

        testOpp = (Opportunity) Test_Utils.putIntoUnwritableField(
            testOpp,
            Opportunity.class,
            'Quotes',
            quotes
        );
        Test.startTest();
            String error = GenerateOrders.getValidationErrors(new List<Opportunity> { testOpp });
            Assert.isNull(error, 'No validation message about missing proserv should be');

            testOpp = (Opportunity) Test_Utils.putIntoUnwritableField(
                testOpp,
                Opportunity.class,
                'Quotes',
                new List<Quote> { quotes[1] }
            );
            error = GenerateOrders.getValidationErrors(new List<Opportunity> { testOpp });

            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(error);
            Assert.areEqual(Label.GenerateOrderNotificationNoCCOrProServQuotes, resultMap.get('message'), 'Wrong error message about missing cc proserv');
        Test.stopTest();
    }
}