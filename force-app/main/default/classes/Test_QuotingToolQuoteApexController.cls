@isTest
private class Test_QuotingToolQuoteApexController {

    private static Quote testQuote;
    private static Account testAccount;
    private static QuoteLineItem testQuoteLineItem;
    private static Opportunity testOpportunity;
    private static PriceBook2 testPriceBook;
    private static User salesrepUser = createUser('sr', false, true); // salesrepUser
    private static User salesmanagerUser = createUser('sm', false); //salesmanagerUser
    private static User salesmanagermanagerUser = createUser('smm', false); //salesmanagermanagerUser
    private static User salesVPUser = createUser('svp', false); //salesmanagermanagerUser

    private static final Map<String, Schema.RecordTypeInfo> QUOTE_RT_INFO_BY_NAME =
        Quote.SObjectType.getDescribe().getRecordTypeInfosByName();

    private static final String PROSERV_QUOTE_RT_NAME = 'ProServ Quote';
    private static final String CC_PROSERV_QUOTE_RT_NAME = 'CC ProServ Quote';

    private static final Id CC_PROSERV_QUOTE_RT_ID = QUOTE_RT_INFO_BY_NAME.get(CC_PROSERV_QUOTE_RT_NAME).getRecordTypeId();

    static {
        insert new List<User>{salesrepUser, salesmanagerUser, salesmanagermanagerUser, salesVPUser};System.debug('insert users');
        QuoteLineItemTotals.bypassQuoteLineItemTotals = true;
    }

    private static void CreateTestData(Id standardPriceBookId, Decimal discount, String other, String range, String srr, String smr, String smmr, String svpr, String rcUserId){
         //Assign approvers
        assignManager(salesrepUser, salesmanagerUser);
        assignManager(salesmanagerUser, salesmanagermanagerUser);

        //Insert Sales VP
        upsert new RingCentralVariousSettings__c(
            SVP_WWS_User_ID__c = salesVPUser.Id,
            SetupOwnerId = salesrepUser.Id
        );
        testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPriceBook;

        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'RingCentral', Sub_Category__c = 'Main', Charge_Term__c = 'Monthly');
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        insert standardPrice;

        PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        insert testPrice;
        Triggers.switchOff();
        testAccount = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral',
                                    RC_User_ID__c = rcUserId);
        insert testAccount;

        testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'Test Package',
                Package__c.Package_Catalog_Id__c => '123',
                Package__c.Package_Version__c => '1',
                Package__c.Account__c => testAccount.Id,
                Package__c.Account_Package_Id__c => '1231231231'
            })
            .create()
            .getRecord();

        testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'qoutetest',
                Quote.OpportunityId => testOpportunity.id,
                Quote.Pricebook2Id => testPriceBook.id,
                Quote.BillingPackage__c => testPackage.Id,
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        testQuoteLineItem = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice, Quantity = 5,
                                                QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = discount);
        insert testQuoteLineItem;
    }

    private static User createUser(String name, Boolean insertUser){
        return createUser(name, insertUser, false);
    }

    private static User createUser(String name, Boolean insertUser, Boolean addManager){
        User user = new User(
            Username = name+'!user@gmail.com',
            LastName = 'Test'+name,
            Email = name+'_user@gmail.com',
            Alias = 'test'+name,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
            LanguageLocaleKey = 'en_US'
        );
        if(addManager){
            user.ManagerId = UserInfo.getUserId();
        }
        if(insertUser) {
            insert user;
        }
        return user;
    }

    private static void assignManager(User u, User manager){
        u.ManagerId = manager.Id;
        update u;
    }

    private static Account createAccount(String name){
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    @isTest static void testSelections() {
        Map<String, String> params = new Map<String, String>();

        Triggers.switchOff();
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id,
            CloseDate = System.today());
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote2 = new Quote(Name='Test Primary 2', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
                isPrimary__c = true);
        insert new List <Quote> {
                testQuote1, testQuote2
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c= 17);
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        insert new List<Product2>{
                testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
                standardPrice1, standardPrice2,
                testPrice1, testPrice2
        };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 1', UnitPrice = testPrice1.UnitPrice, Quantity = 5,
                QuoteId = testQuote1.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 2', UnitPrice = testPrice2.UnitPrice, Quantity = 5,
                QuoteId = testQuote2.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
        insert new List <QuoteLineItem>{
                qli1, qli2
        };

        // Create Order
        Order testOrder = new Order(Name = 'Test Order', AccountId=testAcc.Id, EffectiveDate = System.today(),
                Status = 'New', QuoteId=testQuote1.Id, Pricebook2Id=testPrBook.Id);
        insert testOrder;

        // Create Order Items
        OrderItem testOrderItem1 = new OrderItem(
                QuoteLineItemId = qli1.Id,
                OrderId = testOrder.Id,
                Quantity = 1,
                PricebookEntryId = testPrice1.Id,
                UnitPrice = testPrice1.UnitPrice);
        insert new List <OrderItem> {
                testOrderItem1
        };

        Triggers.switchOn();

        List<Quote> resultQuotes = new List<Quote>();
        Quote quoteResult1 = new Quote();
        Quote quoteResult2 = new Quote();
        List<QuoteLineItem> resultQuoteLineItems = new List<QuoteLineItem>();
        List<OrderItem> resultOrderItems = new List<OrderItem>();
        system.runAs(salesrepUser){
            Test.startTest();

            quoteResult1 = QuotingToolQuoteApexController.getQuote(testQuote1.Id);
            quoteResult2 = QuotingToolQuoteApexController.getQuote(null, testOppty.Id);

            resultQuotes = QuotingToolQuoteApexController.getQuotes(testOppty.Id);

            resultQuoteLineItems = QuotingToolQuoteApexController.getQuoteLineItems(testQuote1.Id);
            resultOrderItems = QuotingToolQuoteApexController.getOrderItems(qli1.Id);
            QuotingToolQuoteApexController.getTiers(new Map<String, String>{
                'CurrencyIsoCode' => 'USD',
                'recordTypeName' => 'Sales Quote'
            });

            QuotingToolQuoteApexController.getTiers(new Map<String, String>{
                'CurrencyIsoCode' => 'GBP',
                'recordTypeName' => 'Sales Quote',
                'isBTBusiness' => 'true'
            });

            QuotingToolQuoteApexController.getTiers(new Map<String, String>{
                'CurrencyIsoCode' => 'GBP',
                'recordTypeName' => 'Sales Quote'
            });

            QuotingToolQuoteApexController.getTiers(new Map<String, String>{
                'CurrencyIsoCode' => 'CAD',
                'recordTypeName' => 'Sales Quote',
                'isTelus' => 'true'
            });

            QuotingToolQuoteApexController.getTiers(new Map<String, String>{
                'CurrencyIsoCode' => 'CAD',
                'recordTypeName' => 'Sales Quote',
                'isActivePricebook' => 'true'
            });
            Test.stopTest();
        }

        System.assertEquals(2, resultQuotes.size());
        System.assertEquals(1, resultQuoteLineItems.size());
        System.assertEquals(1, resultOrderItems.size());
        System.assertEquals(testQuote1.Name, quoteResult1.Name);
        System.assertEquals(testQuote2.Name, quoteResult2.Name, 'Get Quote should return Primary quote from opportunity');
    }

    @isTest static void testSetQuotePrimary(){
        Triggers.switchOff();
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;
        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', CloseDate = System.today().addDays(30), AccountId = testAcc.Id);
        insert testOppty;

        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote2 = new Quote(Name='Test Primary 2', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote3 = new Quote(Name='Test Primary 3', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            ProServ_Status__c = 'Synced');
        Quote testQuote4 = new Quote(Name='Test Primary 4', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
            ProServ_Status__c = 'Synced');
        insert new List <Quote> {
                testQuote1, testQuote2
        };
        Triggers.switchOn();
        Test.startTest();
        System.runAs(salesrepUser) {
            QuotingToolQuoteApexController.setQuotePrimary(testQuote1.Id, testQuote3.Id, null);
            System.assertEquals(true, [SELECT Id, isPrimary__c FROM Quote WHERE Id = :testQuote1.Id].isPrimary__c);

            QuotingToolQuoteApexController.setQuotePrimary(testQuote2.Id, null, null);
            System.assertEquals(true, [SELECT Id, isPrimary__c FROM Quote WHERE Id = :testQuote2.Id].isPrimary__c);

            QuotingToolQuoteApexController.setQuotePrimary(null, testQuote3.Id, null);
            System.assertEquals(true, [SELECT Id, isPrimary__c FROM Quote WHERE Id = :testQuote2.Id].isPrimary__c);

            QuotingToolQuoteApexController.setQuotePrimary(testQuote2.Id, null, null);
            System.assertEquals(true, [SELECT Id, isPrimary__c FROM Quote WHERE Id = :testQuote2.Id].isPrimary__c);
        }
        Test.stopTest();
    }

    @isTest static void testSaveQuote(){
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account', RC_User_ID__c='12345');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id);
        insert testOppty;

        Pricebook2 pb = [SELECT Id FROM Pricebook2].get(0);

        Map<String, String> params = new Map<String, String>{
                'pricebook2Id'   => pb.Id,
                'opportunityId' => testOppty.Id,
                'lines'     => '20',
                'upsellStatus'   => 'Upsell'
        };

        Test.startTest();
        String quoteId = null;
        System.runAs(salesrepUser) {

            quoteId = QuotingToolQuoteApexController.saveQuote(params);

        }
        Test.stopTest();

        System.assert(quoteId != null );
        Quote quoteResult = [SELECT Id, Pricebook2Id, ExpirationDate FROM Quote WHERE Id = :quoteId];
        System.assert(quoteResult != null );
        System.assertEquals(quoteResult.Pricebook2Id, pb.Id);
        System.assertEquals(System.today().addDays(30), quoteResult.ExpirationDate, 'Incorrect Expiration Date');
    }

    @isTest static void testDeleteQuoteQlis(){
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account', RC_User_ID__c='12345');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify');
        insert testOppty;

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c= 17);
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        insert new List<Product2>{
            testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
                standardPrice1, standardPrice2,
                testPrice1, testPrice2
        };

        Quote testQuote = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        insert testQuote;

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 1', UnitPrice = testPrice1.UnitPrice, Quantity = 5,
                QuoteId = testQuote.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 2', UnitPrice = testPrice2.UnitPrice, Quantity = 5,
                QuoteId = testQuote.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);

        insert new List <QuoteLineItem>{
                qli1, qli2
        };

        Test.startTest();
        System.runAs(salesrepUser) {
            QuotingToolQuoteApexController.deleteQuoteQlis(testQuote.Id);
        }
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM QuoteLineItem WHERE QuoteId = :testQuote.Id]);
    }

    @isTest static void testDeleteQuote(){

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify');
        insert testOppty;

        // Create Quotes
        Quote testQt = new Quote(
                Name = 'First Quote',
                OpportunityId = testOppty.Id,
                Pricebook2Id = testPrBook.id);

        Quote testQt2 = new Quote(
                Name = 'Second Quote',
                OpportunityId = testOppty.Id,
                Pricebook2Id = testPrBook.id);

        insert new List <Quote>{
                testQt, testQt2
        };

        Map<String, String> deleteSecondQuote = new Map<String, String>{
                'quoteId' => testQt2.Id
        };
        Map<String, String> deleteFirstQuote = new Map<String, String>{
                'quoteId' => testQt.Id
        };

        Integer quotesAfterSecondDelete = null;
        Integer quotesAfterFirstDelete = null;
        Triggers.switchOn();

        Test.startTest();
        System.runAs(salesrepUser) {
            QuotingToolQuoteApexController.deleteQuote(deleteSecondQuote);

            quotesAfterSecondDelete = [SELECT COUNT() FROM Quote];

            try {
                QuotingToolQuoteApexController.deleteQuote(deleteFirstQuote);
            } catch (Exception e) {
                System.assert(e.getMessage().containsIgnoreCase('not allowed'), 'Last quote can\'t be deleted');
            }

            quotesAfterFirstDelete = [SELECT COUNT() FROM Quote];
        }
        Test.stopTest();

        System.assertEquals(1, quotesAfterSecondDelete, 'Second Quote should be deleted');
        System.assertEquals(1, quotesAfterFirstDelete, 'Last quote can\'t be deleted');
    }

    @isTest static void testSaveSummary(){

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify');
        insert testOppty;

        // Create Quotes
        Quote testQt = new Quote(
                Name = 'Test Quote',
                OpportunityId = testOppty.Id,
                Pricebook2Id = testPrBook.id);
        insert testQt;

        String testQuoteName = 'Test Quote Updated';
        Quote updatedQuote = new Quote(
                Id = testQt.Id,
                Name = testQuoteName,
                Start_Date__c = System.today(),
                End_Date__c = System.today(),
                Auto_Renewal__c = true,
                Initial_Term_months__c = '12',
                Term_months__c = '12'
        );

        Test.startTest();
        System.runAs(salesrepUser) {
            QuotingToolQuoteApexController.updateQuote(updatedQuote);

            // try cause an exception
            updatedQuote.Name = '';
            try {
                QuotingToolQuoteApexController.updateQuote(updatedQuote);
            } catch (Exception e) {
                System.assertEquals('Required fields are missing: [Name]', e.getMessage());
            }
        }
        Test.stopTest();

        Quote actualQuote = [
                SELECT Id, Name, Start_Date__c, Auto_Renewal__c, Initial_Term_months__c, End_Date__c
                FROM Quote
                WHERE Id = :testQt.Id
        ];

        System.assertEquals(testQuoteName,actualQuote.Name, 'Quote Should be properly updated');
        System.assertEquals(updatedQuote.Start_Date__c,actualQuote.Start_Date__c, 'Quote Should be properly updated');
        System.assertEquals(updatedQuote.Auto_Renewal__c,actualQuote.Auto_Renewal__c, 'Quote Should be properly updated');
        System.assertEquals(updatedQuote.Initial_Term_months__c,actualQuote.Initial_Term_months__c, 'Quote Should be properly updated');
    }

    @isTest static void testGetProducts(){
        // Create Products
        List <Product2> testProds = new List <Product2>();

        Product2 testProd1 = new Product2(Name = 'Test product 1', IsActive = true);
        testProds.add(testProd1);

        Product2 testProd2 = new Product2(Name = 'Test product 2', IsActive = true, Feature__c = 2);
        testProds.add(testProd2);

        Product2 testProd3Inactive = new Product2(Name = 'Test product 3 Inactive', IsActive = false);
        testProds.add(testProd3Inactive);

        Product2 testProd4 = new Product2(Name = 'Test product 4', IsActive = true);
        testProds.add(testProd4);

        Product2 testProd5 = new Product2(Name = 'Test product 4', IsActive = true, Feature__c = 1);
        testProds.add(testProd5);

        insert testProds;

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create PriceBookEntries
        List <PricebookEntry> testPbes = new List <PricebookEntry>();
        Id stdPbId = Test.getStandardPricebookId();

        //Product 1
        PricebookEntry stdPrice1 = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = testProd1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        testPbes.add(stdPrice1);

        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        testPbes.add(testPrice1);

        //Product 2
        PricebookEntry stdPrice2 = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = testProd2.Id, UnitPrice = 21000, IsActive = true, UseStandardPrice = false);
        testPbes.add(stdPrice2);

        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd2.Id, UnitPrice = 11000, IsActive = true, UseStandardPrice = false);
        testPbes.add(testPrice2);

        // Product 3 should be excluded because Product is inactive
        PricebookEntry stdPrice3 = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = testProd3Inactive.Id, UnitPrice = 2000, IsActive = true, UseStandardPrice = false);
        testPbes.add(stdPrice3);

        PricebookEntry testPrice3 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd3Inactive.Id, UnitPrice = 1000, IsActive = true, UseStandardPrice = false);
        testPbes.add(testPrice3);

        // Product 4 should be excluded because Pricebook is inactive
        PricebookEntry stdPrice4Inactive = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = testProd4.Id, UnitPrice = 200, IsActive = false, UseStandardPrice = false);
        testPbes.add(stdPrice4Inactive);

        PricebookEntry testPrice4Inactive = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd4.Id, UnitPrice = 150, IsActive = false, UseStandardPrice = false);
        testPbes.add(testPrice4Inactive);
        insert testPbes;


        // Opportunity Record Type
        String oppRTName = 'VAR Opportunity';
        Id oppRTId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName().get(oppRTName).getRecordTypeId();

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', RecordTypeId = oppRTId);
        insert testOppty;

        // Create Quote
        Quote testQt = new Quote (
                Name = 'testGetProducts',
                OpportunityId = testOppty.Id,
                Pricebook2Id = testPrBook.id);
        insert testQt;

        //Create Custom Settings
        Opportunity_Record_Type_Availability__c opportunityRecordTypeAvailability = new Opportunity_Record_Type_Availability__c(
                Name = 'excludeByCustomSetting',
                RecordType__c = oppRTName,
                Feature__c = 1
        );
        insert opportunityRecordTypeAvailability;

        Map<String, String> paramsInside = new Map<String, String>{
                'id'   => '15780001',
                'catalogId' => '1',
                'version' => '1'
        };

        Map<String, String> params = new Map<String, String>{
                'id'   => '1',
                'version' => '1',
                'packageInfo'  => JSON.serialize(paramsInside),
                'duration' => 'Annual'
        };

        Test.startTest();
            List <PricebookEntry> getProductsResult = new List <PricebookEntry>();
            System.runAs(salesrepUser) {
                getProductsResult = QuotingToolQuoteApexController.getProducts(testQt.Id, JSON.serialize(params));
            }
        Test.stopTest();

        System.debug('getProductsResult' + getProductsResult);
        System.assertEquals(2, getProductsResult.size(), 'There should be only active products returned');
    }

    @isTest static void testCreations() {
        Map<String, String> params = new Map<String, String>();

        system.runAs(salesrepUser){
            Test.startTest();
            CreateTestData(Test.getStandardPricebookId(), 20, 'NA', '1-9999999', '1-25', '26-50', '51-100', '101-9999999', '1234');

            QuoteLineItem qli = [SELECT Id, PricebookEntryId, Product2Id, QuoteId FROM QuoteLineItem WHERE QuoteId=:testQuote.Id].get(0);
            Test.stopTest();

            params.put('productId', qli.Product2Id);
            params.put('pbeId', qli.PriceBookEntryId);
            params.put('quoteId', testQuote.Id);
            params.put(qli.Id+'%%discount', '2');
            params.put(qli.Id+'%%quantity', '2');
            params.put(qli.Id+'%%isDeactivated', 'false');

            QuotingToolQuoteApexController.updateCartItems(testQuote.Id, params);
            Decimal qliQuantity = [SELECT Id, Quantity FROM QuoteLineItem WHERE QuoteId=:testQuote.Id].get(0).Quantity;

            System.assertEquals(qliQuantity, 2);
        }
    }

    @isTest static void testCreationsAdditional() {
        Map<String, String> params = new Map<String, String>();

        system.runAs(salesrepUser){
            Test.startTest();
            CreateTestData(Test.getStandardPricebookId(), 20, 'NA', '1-9999999', '1-25', '26-50', '51-100', '101-9999999', '1234');

            QuoteLineItem qli = [SELECT Id, PricebookEntryId, Product2Id, QuoteId FROM QuoteLineItem WHERE QuoteId=:testQuote.Id].get(0);
            Test.stopTest();

            params.put('productId', qli.Product2Id);
            params.put('pbeId', qli.PriceBookEntryId);
            params.put('quoteId', testQuote.Id);
            params.put(qli.Id+'%%discount', '2');
            params.put(qli.Id+'%%quantity', '2');
            params.put(qli.Id+'%%isDeactivated', 'false');

            QuotingToolQuoteApexController.updateCartItems(testQuote.Id, params);

            Decimal qliQuantity = [SELECT Id, Quantity FROM QuoteLineItem WHERE QuoteId=:testQuote.Id].get(0).Quantity;

            System.assertEquals(qliQuantity, 2);

        }
    }

    @isTest static void testCreateQuoteLineItems(){
        Triggers.switchOff();
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id,
                CloseDate = System.today());
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        insert new List <Quote> {
                testQuote1
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Some Product 1', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        Product2 testProduct2 = new Product2(Name = 'Some Product 2', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        insert new List<Product2>{
                testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
                standardPrice1, standardPrice2,
                testPrice1, testPrice2
        };

        // Create Entitlements
        Entitlement__c testEntitlement1 = new Entitlement__c(Account__c = testAcc.Id, Active__c = true, Product__c = testProduct1.Id, Quantity__c = 5);
        insert new List <Entitlement__c> {
                testEntitlement1
        };
        Triggers.switchOn();

        System.runAs(salesrepUser) {
            Test.startTest();
            QuotingToolQuoteApexController.createQuoteLineItems(testQuote1.Id, new List <Id>{
                    testPrice1.Id, testPrice2.Id
            });
            Test.stopTest();
        }

        System.assertEquals(2, [SELECT COUNT() FROM QuoteLineItem WHERE quoteId = :testQuote1.Id]);
    }

    @isTest static void testDontCreateQuoteLineItemsForOverages_overageProdInactive() {
        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'ACME Inc. Opportunity',
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Opportunity.StageName => '1. Qualify',
                Opportunity.CloseDate => System.today()
            })
            .create()
            .getRecord();

        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'Primary Quote',
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.OpportunityId => opportunity.Id
            })
            .create()
            .getRecord();

        List<Product2> productsList = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideList(new List<String>{
                    'Active Overage', 'Inactive Overage', 'Contact Center: Seat'
                }),
                Product2.IsActive => ValueProviderBuilder.provideList(new List<Boolean>{
                    true, false, true
                }),
                Product2.Family => ValueProviderBuilder.provideList(new List<String>{
                    Product2Helper.FAMILY_OVERAGE, Product2Helper.FAMILY_OVERAGE, Product2Helper.FAMILY_CCSERVICE
                }),
                Product2.Product_Type__c => ValueProviderBuilder.provideList(new List<String> {
                    '', '', Product2Helper.PRODUCT_TYPE_SEAT
                }),
                Product2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    'OVERAGE1', 'OVERAGE2', 'SEAT1'
                })
            })
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .quantity(3)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productsList),
                PricebookEntry.IsActive => true
            })
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        System.runAs(salesrepUser) {
            Test.startTest();

            qliList = QuotingToolQuoteApexController.createQuoteLineItems(quote.Id, new Map<Id, Decimal>{
                pbeList.get(2).Id => 1
            }, null, null);

            Test.stopTest();
        }

        System.assertEquals(2, qliList.size(), 'Must contain 2 items: 1 Seat and 1 Overage');

        QuoteLineItem ccActive = null;
        QuoteLineItem overage = null;

        for(QuoteLineItem qli : qliList) {
            if('SEAT1'.equalsIgnoreCase(qli.Product2.ExtId__c)) {
                ccActive = qli;
            } else if ('OVERAGE1'.equalsIgnoreCase(qli.Product2.ExtId__c)) {
                overage = qli;
            } else {
                System.assert(
                    false,
                    'QLIs for wrong products have been created: Product2.ExtID__c is ' + qli.Product2.ExtID__c
                );
            }
        }

        System.assert(ccActive != null, 'Active CC is Null');
        System.assert(overage != null, 'Active overage is Null');
    }

    @isTest static void testDeleteQuoteLineItem(){

        Triggers.switchOff();
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id,
                CloseDate = System.today());
        insert testOppty;

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Some Product 1', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c = 1);
        Product2 testProduct2 = new Product2(Name = 'Some Product 2', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Dependent_on_Feature__c = 1);
        insert new List<Product2>{
                testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
                standardPrice1, standardPrice2,
                testPrice1, testPrice2
        };

        // Create Entitlements
        Entitlement__c testEnt1 = new Entitlement__c(Product__c = testProduct1.Id, Account__c = testAcc.Id, Active__c = true, Quantity__c = 8);
        Entitlement__c testEnt2 = new Entitlement__c(Product__c = testProduct2.Id, Account__c = testAcc.Id, Active__c = true, Quantity__c = 8);
        insert new List<Entitlement__c> {
                testEnt1, testEnt2
        };

        // Create Quotes
        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        insert new List <Quote> {
                testQuote1
        };


        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 1', UnitPrice = testPrice1.UnitPrice, Quantity = 5, QuoteId = testQuote1.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100, Entitlement__c = testEnt1.Id);

        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 2', UnitPrice = testPrice2.UnitPrice, Quantity = 5, QuoteId = testQuote1.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0, Entitlement__c = testEnt1.Id);
        insert new List<QuoteLineItem> {
                qli1, qli2
        };

        Triggers.switchOn();

        System.runAs(salesrepUser) {
            Test.startTest();
                QuotingToolQuoteApexController.deleteQuoteLineItem(qli1);
            Test.stopTest();
        }

        System.assertEquals(0, [SELECT COUNT() FROM QuoteLineItem WHERE quoteId = :testQuote1.Id]);
    }

    @IsTest
    private static void testDeleteQuoteLineItemWithParentOrderItem() {
        Triggers.switchOff();

        new SObjectBuilder(ByPassTrigger__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    ByPassTrigger__c.Bypass_Account_Trigger__c => true
                }
            )
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Feature_Toggle__c.NewChangeOrderFlow__c => true
                }
            )
            .create();

        Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setField(Pricebook2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Pricebook2.Description, ValueProviderBuilder.provideUniqueString())
            .setField(Pricebook2.IsActive, true)
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Family, Product2Helper.FAMILY_SERVICE)
            .setField(Product2.Charge_Term__c, null)
            .create()
            .getRecord();

        PricebookEntry testPricebookEntryStandard = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, 0)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        PricebookEntry testPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, testPriceBook.Id)
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.provideUniqueNumber(1))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.CloseDate, ValueProviderBuilder.provideUniqueDate())
            .setField(Opportunity.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .create()
            .getRecord();

        Quote testInitialQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.OpportunityId, testOpportunity.Id)
            .setField(Quote.Start_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.End_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_AGREEMENT)
            .setField(Quote.PriceBook2Id, testPriceBook.Id)
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectFactory()
            .create(
                Order.SObjectType,
                new Map<SObjectField, Object>{
                    Order.AccountId => testAccount.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.PriceBook2Id => Test.getStandardPricebookId(),
                    Order.QuoteId => testInitialQuote.Id,
                    Order.OpportunityId => testOpportunity.Id,
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV
                }
            );

        Asset testAsset = (Asset) new SObjectBuilder(Asset.SObjectType)
            .setField(Asset.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Asset.AccountId, testAccount.Id)
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SObjectFactory()
            .create(
                OrderItem.SObjectType,
                new Map<SObjectField, Object>{
                    OrderItem.PricebookEntryId => testPricebookEntryStandard.Id,
                    OrderItem.Quantity => 1,
                    OrderItem.Threshold__c => 0,
                    OrderItem.UnitPrice => 19.89,
                    OrderItem.UnitPriceWithoutDiscount__c => 19.99,
                    OrderItem.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    OrderItem.Discount_Number__c => 0.1,
                    OrderItem.Active__c => true,
                    OrderItem.BillingStatus__c => 'Active',
                    OrderItem.Zero_Quantity__c => false,
                    OrderItem.OrderId => testOrder.Id
                }
            );

        Opportunity testOpportunityWithParent = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, testAccount.Id)
            .setField(Opportunity.Parent_Order__c, testOrder.Id)
            .setField(Opportunity.CloseDate, ValueProviderBuilder.provideUniqueDate())
            .setField(Opportunity.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Quote.OpportunityId, testOpportunityWithParent.Id)
            .setField(Quote.Start_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.End_Date__c, ValueProviderBuilder.provideUniqueDate())
            .setField(Quote.IsPrimary__c, true)
            .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_AGREEMENT)
            .setField(Quote.PriceBook2Id, testPriceBook.Id)
            .create()
            .getRecord();

        Triggers.switchOn();
        Test.startTest();
        QuoteLineItem testQuoteLineItem = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Product2Id, testProduct.Id)
            .setField(QuoteLineItem.QuoteId, testQuote.Id)
            .setField(QuoteLineItem.PricebookEntryId, testPricebookEntry.Id)
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.Zero_Quantity__c, false)
            .setField(QuoteLineItem.OriginalOrderLineItem__c, testOrderItem.Id)
            .setField(QuoteLineItem.UnitPrice, testPricebookEntry.UnitPrice)
            .setField(QuoteLineItem.Asset__c, testAsset.Id)
            .create()
            .getRecord();

        QuotingToolQuoteApexController.deleteQuoteLineItem(testQuoteLineItem);

        testOrderItem = [SELECT Id, Asset__c FROM OrderItem WHERE Id = :testOrderItem.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals(testAsset.Id, testOrderItem.Asset__c);
    }

    /**
     * Test Change Order Sorting
     */
    @isTest static void testPdfTemplates(){
        List<RC_Quote_Template__c> templates;
        String link;
        system.runAs(salesrepUser){
            Account acc = new Account(
                    Name='Opty test account',
                    RC_User_ID__c = '12345'
            );
            insert acc;

            Opportunity opp = new Opportunity(
                    Name = 'Test Opportunity',
                    Type = 'Syndicated - New',
                    StageName = 'Planning',
                    CloseDate = system.today(),
                    AccountId = acc.Id);
            insert opp;

            Quote qt = new Quote (
                    Name = 'qoutetest',
                    OpportunityId = opp.id,
                    Approved_Status__c = 'Approved',
                    Products__c='RingCentral;');
            insert qt;

            Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();
            featureCS.PDF_Engine_1_0__c = true;
            featureCS.PDF_Engine_2_0__c = true;
            upsert featureCS;

            RC_Quote_Template__c temp = new RC_Quote_Template__c(
                    Name = 'Quote',
                    Sorting_Order__c = 1.0,
                    Description__c = 'Quote',
                    Brand__c = 'RingCentral',
                    Opportunity_Record_Type__c = 'Sales Opportunity;New Sales Opportunity',
                    Type__c = 'Quote',
                    Active__c = true,
                    Order_Type__c = 'Change Order',
                    Quote_Record_Type__c = 'Sales Quote',
                    Products__c = 'RingCentral');
            insert temp;

            Test.startTest();
            templates = QuotingToolQuoteApexController.getPdfTemplates(new Map<String, String>{
                    'opportunityId' => opp.Id,
                    'quoteId' => qt.Id
            });
            Test.stopTest();

        }

        System.assertEquals(1, templates.size());
    }

    /**
     * Test New Order Sorting
     * When Quote.Account.RC_User_ID__c == null
     */
    @isTest static void testPdfTemplatesNullAcc(){
        List<RC_Quote_Template__c> templates;
        system.runAs(salesrepUser){
            Account acc = new Account(
                    Name='Opty test account'
            );
            insert acc;

            Opportunity opp = new Opportunity(
                    Name = 'Test Opportunity',
                    Type = 'Syndicated - New',
                    StageName = 'Planning',
                    CloseDate = system.today(),
                    AccountId = acc.Id);
            insert opp;

            Quote qt = new Quote (
                    Name = 'qoutetest',
                    OpportunityId = opp.id,
                    Approved_Status__c = 'Approved',
                    Products__c='RingCentral;');
            insert qt;

            Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();
            featureCS.PDF_Engine_1_0__c = true;
            featureCS.PDF_Engine_2_0__c = true;
            upsert featureCS;

            RC_Quote_Template__c temp = new RC_Quote_Template__c(
                    Name = 'Quote',
                    Sorting_Order__c = 1.0,
                    Description__c = 'Quote',
                    Brand__c = 'RingCentral',
                    Opportunity_Record_Type__c = 'Sales Opportunity;New Sales Opportunity',
                    Type__c = 'Quote',
                    Active__c = true,
                    Order_Type__c = OrderHelper.TYPE_NEW_ORDER,
                    Quote_Record_Type__c = 'Sales Quote' ,
                    Products__c = 'RingCentral');
            insert temp;

            Test.startTest();
            templates = QuotingToolQuoteApexController.getPdfTemplates(new Map<String, String>{
                    'opportunityId' => opp.Id,
                    'quoteId' => qt.Id
            });
            Test.stopTest();
        }
        System.assertEquals(1, templates.size());
    }
    /**
     *   When Order_Type__c doesn't match
     */
    @isTest static void testPdfTemplatesOrderType(){
        List<RC_Quote_Template__c> templates;
        String link;
        system.runAs(salesrepUser){
            Account acc = new Account(
                    Name='Opty test account',
                    RC_User_ID__c = '12345'
            );
            insert acc;

            Opportunity opp = new Opportunity(
                    Name = 'Test Opportunity',
                    Type = 'Syndicated - New',
                    StageName = 'Planning',
                    CloseDate = system.today(),
                    AccountId = acc.Id);
            insert opp;

            Quote qt = new Quote (
                    Name = 'qoutetest',
                    OpportunityId = opp.id,
                    Approved_Status__c = 'Approved',
                    Products__c='RingCentral;');
            insert qt;

            RC_Quote_Template__c temp = new RC_Quote_Template__c(
                    Name = 'Quote',
                    Sorting_Order__c = 1.0,
                    Description__c = 'Quote',
                    Brand__c = 'RingCentral',
                    Opportunity_Record_Type__c = 'Sales Opportunity;New Sales Opportunity',
                    Type__c = 'Quote',
                    Active__c = true,
                    Order_Type__c = '',
                    Quote_Record_Type__c = 'Sales Quote',
                    Products__c = 'RingCentral'
            );
            insert temp;

            Test.startTest();
            templates = QuotingToolQuoteApexController.getPdfTemplates(new Map<String, String>{
                    'opportunityId' => opp.Id,
                    'quoteId' => qt.Id
            });
            Test.stopTest();
        }

        System.assertEquals(0, templates.size());
    }

    // When Products__c doesn't match
    @isTest static void testPdfTemplatesProducts(){
        List<RC_Quote_Template__c> templates;
        String link;
        system.runAs(salesrepUser){
            Account acc = new Account(
                    Name='Opty test account',
                    RC_User_ID__c = '12345'
            );
            insert acc;

            Opportunity opp = new Opportunity(
                    Name = 'Test Opportunity',
                    Type = 'Syndicated - New',
                    StageName = 'Planning',
                    CloseDate = system.today(),
                    AccountId = acc.Id);
            insert opp;

            Quote qt = new Quote (
                    Name = 'qoutetest',
                    OpportunityId = opp.id,
                    Approved_Status__c = 'Approved',
                    Products__c='RingCentral;');
            insert qt;

            RC_Quote_Template__c temp = new RC_Quote_Template__c(
                    Name = 'Quote',
                    Sorting_Order__c = 1.0,
                    Description__c = 'Quote',
                    Brand__c = 'RingCentral',
                    Opportunity_Record_Type__c = 'Sales Opportunity;New Sales Opportunity',
                    Type__c = 'Quote',
                    Active__c = true,
                    Order_Type__c = 'Change Order',
                    Quote_Record_Type__c = 'Sales Quote',
                    Products__c = 'Contact Center'
            );
            insert temp;

            Test.startTest();
            templates = QuotingToolQuoteApexController.getPdfTemplates(new Map<String, String>{
                    'opportunityId' => opp.Id,
                    'quoteId' => qt.Id
            });
            Test.stopTest();
        }

        System.assertEquals(0, templates.size());
    }


    @isTest static void testPDFAttachment(){
        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPriceBook;

        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK');
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(), Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        insert standardPrice;

        PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        insert testPrice;

        testAccount = new Account(Name='Opty test account',
                                    Partner_ID__c='testID',
                                    Permitted_Brands__c='RingCentral',
                                    RC_User_ID__c = '1234');
        insert testAccount;

        testOpportunity = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id , Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
        insert testQuote;

        Test.startTest();

        testQuoteLineItem = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice, Quantity = 5,
                                                QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 10);
        insert testQuoteLineItem;

        RC_Quote_Template__c temp = new RC_Quote_Template__c(Name = 'Quote',
                                                            Sorting_Order__c = 1.0,
                                                            Description__c = 'Quote',
                                                            Brand__c = 'RingCentral',
                                                            Opportunity_Record_Type__c = 'Sales Opportunity;New Sales Opportunity',
                                                            Type__c = 'Quote',
                                                            Active__c = true,
                                                            Template_Engine__c = TemplateEngine.PDF_ENGINE_2_0);
        insert temp;

        Map< String, String> params = new Map<String, String>();
        params.put('quoteId', String.valueOf(testQuote.Id));
        params.put('opportunityId', testOpportunity.Id);
        params.put('templateId', temp.Id);
        String link = QuotingToolQuoteApexController.AttachPdfToOpportunity(params);
        Test.stopTest();

        System.assertNotEquals(null, link);
    }

    @isTest static void testApprovals(){
        system.runAs(salesrepUser){

            insert new GOA_V2__c(
                Name = '1',
                Quantity_Range__c = '1-99',
                Contract_Initial_Term_Range__c = '',
                Sales_Rep__c = '0-0',
                Direct_Manager__c = '0.01-2.00',
                Segment_Leader__c = '2.01-3.00',
                SVP_WWS_Directs__c = '3.01-5.00',
                SVP_WWS__c = '5.01-99999999',
                Group__c = 'RC_Office_Standard_Monthly_Contract',
                Currency__c = 'USD'
            );

            insert new Products_taken_into_account_in_GOA__c(
                Name = 'test',
                Quote_Record_Type__c = 'Sales Quote',
                Sub_Categories__c = 'Main, Contact Center'
            );

            salesrepUser.Hierarchy_Role__c = 'Direct Manager';
            salesmanagerUser.Hierarchy_Role__c = 'Segment Leader';
            salesmanagermanagerUser.Hierarchy_Role__c = 'SVP WWS Directs';
            update new List<User>{ salesrepUser, salesmanagerUser, salesmanagermanagerUser };

            Test.startTest();
            CreateTestData(Test.getStandardPricebookId(), 999, 'SalesVP', '1-9999999', '0-0', '0-0', '0-0', '0-0', '1234');
            testQuote = [SELECT Id, Approved_Status__c, Level_1_Approver__r.Name FROM Quote WHERE Id=:testQuote.Id];
            Test.stopTest();

            // System.assertEquals(testQuote.Approved_Status__c, 'Required');
            Map< String, String> params = new Map<String, String>();
            params.put('quoteId', String.valueOf(testQuote.Id));

            testQuote = QuotingToolQuoteApexController.submitApprovalRequest(params);
            params.put('comment', 'some comment');
            params.put('action', 'Approve');
            testQuote = QuotingToolQuoteApexController.setApprovalAction(params);

            System.assertEquals(testQuote.Approved_Status__c, 'Pending L2 Approval');
        }
    }

    /* -------------------------------
     * Test Professional Services Flow
     * -------------------------------
     *
     * Documentation: https://aquiva.atlassian.net/wiki/spaces/RC/pages/113999918/Professional+Services
     */
    private static Quote testPrimaryQuote;
    private static Quote testProServQuote;
    private static Quote testCCProServQuote;
    private static QuoteLineItem testPrimaryQli1;
    private static QuoteLineItem testPrimaryQli2;
    private static QuoteLineItem testProServQli1;
    private static QuoteLineItem testProServQli2;
    private static QuoteLineItem testCCProServQli1;
    private static QuoteLineItem testCCProServQli2;
    private static Product2 testProduct1;
    private static Product2 testProduct2;
    private static Product2 testProduct3;
    private static Product2 testProduct4;

    /**
     * Test Engagement Process
     * ProServ + CC ProServ
     */
    @isTest static void testEngageProServ() {
        Triggers.switchOff();
        // Create Brand
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Name = 'RingCentral');
        insert testBrand;

        // Create PriceBook
        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c='Office',
            Plan__c = 'Monthly',
            ExtId__c = 'ProServ_Universal_USD'
        );
        insert testPriceBook;

        PriceBook2 testPriceBook2 = new Pricebook2(
            Name = 'Test Service Billing ProServ',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c = 'Office',
            Plan__c = 'Monthly',
            ExtId__c = 'CC_ProServ_Universal_USD'
        );
        insert testPriceBook2;

        // create Account
        testAccount = new Account(Name='Opty test account', Number_of_DL_s__c = 20);
        insert testAccount;

        // create Opportunity
        testOpportunity = new Opportunity(Name = 'Test Opportunity ProServ', Brand_Name__c = testBrand.Name,
                StageName = '1. Qualify', CloseDate = system.today(), AccountId = testAccount.Id,
                Number_of_Employees__c = '20', Forecasted_Users__c = 20);
        insert testOpportunity;

        // Create Quote
        testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id ,
                Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
        insert testQuote;



        Test.startTest();

        String testDetails1 = 'First Engagement Details';
        String testDetails2 = 'Second Engagement Details';
        List<Quote> resultProServQuotes1 = new List<Quote>();
        List<Quote> resultCCProServQuotes1 = new List<Quote>();
        List<Quote> resultProServQuotes2 = new List<Quote>();
        List<Quote> resultCCProServQuotes2 = new List<Quote>();

        System.runAs(salesrepUser) {

            Triggers.switchOn();

            // Engage Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails1, QuotingToolQuoteApexController.PROSERV, false);
            resultProServQuotes1 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_PROSERV
            ];

            // Engage Contact Center Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails1, QuotingToolQuoteApexController.CC_PROSERV, false);
            resultCCProServQuotes1 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
            ];

            // Check if Quotes Created
            System.assertEquals(1, resultProServQuotes1.size(), 'ProServ Quote should be created');
            System.assertEquals(1, resultCCProServQuotes1.size(), 'CC ProServ Quote should be created');

            Quote proServQuote1 = resultProServQuotes1.get(0);
            Quote ccProServQuote1 = resultCCProServQuotes1.get(0);

            // Check Pricebook
            System.assertEquals(testPriceBook.Id, proServQuote1.Pricebook2Id, 'ProServ Quote should have Same Service Plan as Primary Quote');
            System.assertEquals(testPriceBook.Id, ccProServQuote1.Pricebook2Id, 'CC ProServ Quote should have Same Service Plan as Primary Quote');

            // Check ProServ Details
            System.assertEquals(testDetails1, proServQuote1.ProServ_Details__c, 'ProServ details should be populated');
            System.assertEquals(testDetails1, ccProServQuote1.ProServ_Details__c, 'CC ProServ details should be populated');

            // Check ProServ Status
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, proServQuote1.ProServ_Status__c, 'Default ProServ Status should be set');
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, ccProServQuote1.ProServ_Status__c, 'Default CC ProServ Status should be set');


            // Check Engagement when ProServ has been cancelled
            Triggers.switchOff();

            proServQuote1.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            ccProServQuote1.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            update new List<Quote>{ proServQuote1, ccProServQuote1 };

            Triggers.switchOn();

            // Engage Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails2, QuotingToolQuoteApexController.PROSERV, false);
            resultProServQuotes2 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_PROSERV
            ];

            // Engage Contact Center Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails2, QuotingToolQuoteApexController.CC_PROSERV, false);
            resultCCProServQuotes2 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
            ];

            // Check that no new quote has been created
            System.assertEquals(1, resultProServQuotes2.size());
            System.assertEquals(1, resultCCProServQuotes2.size());

            Quote proServQuote2 = resultProServQuotes2.get(0);
            Quote ccProServQuote2 = resultCCProServQuotes2.get(0);

            System.assertEquals(proServQuote1.Id, proServQuote2.Id, 'ProServ Quote should be the same');
            System.assertEquals(ccProServQuote1.Id, ccProServQuote2.Id, 'ProServ Quote should the same');

            // Check ProServ Details
            System.assertEquals(testDetails2, proServQuote2.ProServ_Details__c, 'ProServ details should be populated');
            System.assertEquals(testDetails2, ccProServQuote2.ProServ_Details__c, 'CC ProServ details should be populated');

            // Check ProServ Status
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, proServQuote2.ProServ_Status__c, 'Default ProServ Status should be set');
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, ccProServQuote2.ProServ_Status__c, 'Default CC ProServ Status should be set');

        }

        Test.stopTest();

    }

    @isTest static void testEngageProServMPUB() {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getOrgDefaults();
        featureToggle.EnableMultiProductUnifiedBilling__c = true;
        insert featureToggle;

        Triggers.switchOff();

        // Create PriceBook
        List<PriceBook2> testPriceBooks = (List<PriceBook2>) new sObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideList(new List<String>{'Test Price Book', 'ProServ GBP'}),
                PriceBook2.Description => 'Test Price Book Products',
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Service__c => 'Office',
                PriceBook2.Plan__c => 'Monthly',
                Pricebook2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{null, 'Test_ProServ_GBP'}),
                Pricebook2.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(PriceBookAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookAssignments__c.Name => ValueProviderBuilder.provideUniqueString('test_setting_'),
                PriceBookAssignments__c.Active__c => true,
                PriceBookAssignments__c.BrandName__c => OpportunityHelper.BRAND_AVAYA,
                PriceBookAssignments__c.SubBrandName__c => null,
                PriceBookAssignments__c.PSPriceBookExtID__c => testPriceBooks[1].ExtID__c,
                PriceBookAssignments__c.CCPSPriceBookExtID__c => testPriceBooks[1].ExtID__c,
                PriceBookAssignments__c.Currency__c => RingCentralHelper.GBP
            })
            .create();

        // create Account
        testAccount = (Account) new sObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Opty test account',
                Account.Number_of_DL_s__c => 20
            })
            .create()
            .getRecord();

        // create Opportunity
        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAccount.Id,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                Opportunity.Number_of_Employees__c => '20',
                Opportunity.Forecasted_Users__c => 20
            })
            .create()
            .getRecord();

        // Create Quote
        testQuote = (Quote) new sObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => 'qoutetest',
                Quote.OpportunityId => testOpportunity.id,
                Quote.Pricebook2Id => testPriceBooks[0].Id,
                Quote.Total_Number_of_Digital_Lines__c => 10
            })
            .create()
            .getRecord();

        Test.startTest();

        String testDetails1 = 'First Engagement Details';
        String testDetails2 = 'Second Engagement Details';
        List<Quote> resultProServQuotes1 = new List<Quote>();
        List<Quote> resultCCProServQuotes1 = new List<Quote>();
        List<Quote> resultProServQuotes2 = new List<Quote>();
        List<Quote> resultCCProServQuotes2 = new List<Quote>();

        System.runAs(salesrepUser) {

            Triggers.switchOn();

            // Engage Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails1, QuotingToolQuoteApexController.PROSERV, false);
            resultProServQuotes1 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_PROSERV
            ];

            // Engage Contact Center Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails1, QuotingToolQuoteApexController.CC_PROSERV, false);
            resultCCProServQuotes1 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
            ];

            // Check if Quotes Created
            System.assertEquals(1, resultProServQuotes1.size(), 'ProServ Quote should be created');
            System.assertEquals(1, resultCCProServQuotes1.size(), 'CC ProServ Quote should be created');

            Quote proServQuote1 = resultProServQuotes1.get(0);
            Quote ccProServQuote1 = resultCCProServQuotes1.get(0);

            // Check Pricebook
            System.assertEquals(testPriceBooks[0].Id, proServQuote1.Pricebook2Id, 'ProServ Quote should have Same Service Plan as Primary Quote');
            System.assertEquals(testPriceBooks[0].Id, ccProServQuote1.Pricebook2Id, 'CC ProServ Quote should have Same Service Plan as Primary Quote');

            // Check ProServ Details
            System.assertEquals(testDetails1, proServQuote1.ProServ_Details__c, 'ProServ details should be populated');
            System.assertEquals(testDetails1, ccProServQuote1.ProServ_Details__c, 'CC ProServ details should be populated');

            // Check ProServ Status
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, proServQuote1.ProServ_Status__c, 'Default ProServ Status should be set');
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, ccProServQuote1.ProServ_Status__c, 'Default CC ProServ Status should be set');


            // Check Engagement when ProServ has been cancelled
            Triggers.switchOff();

            proServQuote1.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            ccProServQuote1.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            update new List<Quote>{ proServQuote1, ccProServQuote1 };

            Triggers.switchOn();

            // Engage Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails2, QuotingToolQuoteApexController.PROSERV, false);
            resultProServQuotes2 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_PROSERV
            ];

            // Engage Contact Center Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails2, QuotingToolQuoteApexController.CC_PROSERV, false);
            resultCCProServQuotes2 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
            ];

            // Check that no new quote has been created
            System.assertEquals(1, resultProServQuotes2.size());
            System.assertEquals(1, resultCCProServQuotes2.size());

            Quote proServQuote2 = resultProServQuotes2.get(0);
            Quote ccProServQuote2 = resultCCProServQuotes2.get(0);

            System.assertEquals(proServQuote1.Id, proServQuote2.Id, 'ProServ Quote should be the same');
            System.assertEquals(ccProServQuote1.Id, ccProServQuote2.Id, 'ProServ Quote should the same');

            // Check ProServ Details
            System.assertEquals(testDetails2, proServQuote2.ProServ_Details__c, 'ProServ details should be populated');
            System.assertEquals(testDetails2, ccProServQuote2.ProServ_Details__c, 'CC ProServ details should be populated');

            // Check ProServ Status
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, proServQuote2.ProServ_Status__c, 'Default ProServ Status should be set');
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, ccProServQuote2.ProServ_Status__c, 'Default CC ProServ Status should be set');

        }

        Test.stopTest();
    }

    static void createTestData_testSyncProServ(){
        // Create Brand
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Name = 'RingCentral');
        insert testBrand;

        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly', Brand__c = testBrand.Id);
        PriceBook2 testPriceBook2 = new Pricebook2(Name = 'Test Price Book 2',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly', Brand__c = testBrand.Id);

        insert new List<Pricebook2>{
                testPriceBook1, testPriceBook2
        };

        // create Account
        testAccount = new Account(Name = 'Opty test account');
        insert testAccount;

        // create Opportunity
        testOpportunity = new Opportunity(Name = 'Test Opportunity ProServ', Brand_Name__c = testBrand.Name,
                StageName = '1. Qualify', CloseDate = system.today(), AccountId = testAccount.Id,
                Number_of_Employees__c = '20', Forecasted_Users__c = 20);
        insert testOpportunity;

        // Create Quotes
        testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, Total_Number_of_Digital_Lines__c = 10);

        testProServQuote = new Quote(Name = 'Test ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, Total_Number_of_Digital_Lines__c = 10,
                RecordTypeId = QuoteHelper.RT_ID_PROSERV);

        testCCProServQuote = new Quote(Name = 'Test CC ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook2.id, Total_Number_of_Digital_Lines__c = 10,
                RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV);

        insert new List<Quote>{
                testPrimaryQuote, testProServQuote, testCCProServQuote
        };

        // Create Products
        // ProServ
        testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
                Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY);
        testProduct2 = new Product2(Name = 'Test Product 2', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_PROSERV,
                Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY);
        // CC ProServ
        testProduct3 = new Product2(Name = 'Test Product 3', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV,
                Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY);
        testProduct4 = new Product2(Name = 'Test Product 4', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV,
                Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY);
        insert new List<Product2>{
                testProduct1, testProduct2, testProduct3, testProduct4
        };

        // Create PricebookEntries
        // Pricebook 1
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

        // Pricebook 2
        // CC ProServ
        PricebookEntry testPrice4 = new PricebookEntry(Pricebook2Id = testPriceBook2.Id, Product2Id = testProduct3.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);

        PricebookEntry standardPrice4 = new PricebookEntry(Pricebook2Id = Test.getStandardPriceBookId(),
                Product2Id = testProduct4.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice5 = new PricebookEntry(Pricebook2Id = testPriceBook2.Id, Product2Id = testProduct4.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
                Max_Quantity__c = 100);

        insert new List<PricebookEntry>{
                standardPrice1, standardPrice2, standardPrice3, standardPrice4,
                testPrice1, testPrice2, testPrice3, testPrice4, testPrice5
        };

        // Create Quote Line Items
        // ProServ Quote
        testProServQli1 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        testProServQli2 = new QuoteLineItem(
                QuoteId = testProServQuote.Id,
                PricebookEntryId = testPrice2.Id,
                Product2Id = testProduct2.Id,
                UnitPrice = testPrice2.UnitPrice,
                Quantity = 6
        );
        // CC ProServ Quote
        testCCProServQli1 = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                PricebookEntryId = testPrice4.Id,
                Product2Id = testProduct3.Id,
                UnitPrice = testPrice4.UnitPrice,
                Quantity = 7
        );
        testCCProServQli2 = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                PricebookEntryId = testPrice5.Id,
                Product2Id = testProduct4.Id,
                UnitPrice = testPrice5.UnitPrice,
                Quantity = 8
        );
        insert new List<QuoteLineItem>{
                testProServQli1, testProServQli2, testCCProServQli1, testCCProServQli2
        };
    }
    /**
     * Test ProServ->Primary quote synchronisation
     */
    @isTest static void testSyncProServ() {
        createTestData_testSyncProServ();

        Test.startTest();

        QuotingToolQuoteApexController.syncProServWithSales(testOpportunity.Id, false, QuotingToolQuoteApexController.PROSERV);

        Test.stopTest();

        List<QuoteLineItem> resultQLIs1 = [
                SELECT Id, QuoteId, Quantity, PricebookEntryId
                FROM QuoteLineItem
                WHERE quoteId = :testPrimaryQuote.Id
                ORDER BY Product2.Name ASC
        ];

        Quote resultProServQuote = [
                SELECT Id, ProServ_Status__c
                FROM Quote
                WHERE Id = :testProServQuote.Id
        ];

        // Check sync
        System.assertEquals(QuoteHelper.PROSERVSTATUS_SYNCED, resultProServQuote.ProServ_Status__c, 'ProServ Quote Status should be updated');
        System.assertEquals(2, resultQLIs1.size(), 'ProServ Products Should be synced to Primary Quote');

        // Check Quantity
        System.assertEquals(testProServQli1.Quantity, resultQLIs1.get(0).Quantity, 'ProServ Products Should be synced with Quantity');
        System.assertEquals(testProServQli2.Quantity, resultQLIs1.get(1).Quantity, 'ProServ Products Should be synced with Quantity');

        // Check PricebookEntry
        System.assertEquals(testProServQli1.PricebookEntryId, resultQLIs1.get(0).PricebookEntryId, 'ProServ Products Should have same PricebookEntry');
        System.assertEquals(testProServQli2.PricebookEntryId, resultQLIs1.get(1).PricebookEntryId, 'ProServ Products Should have same PricebookEntry');
    }

    @isTest static void testSyncProServUnavailable() {
        createTestData_testSyncProServ();

        Test.startTest();

        List<QuoteLineItem> resultQLIs1 = [
                SELECT Id, QuoteId, Quantity, PricebookEntryId
                FROM QuoteLineItem
                WHERE quoteId = :testPrimaryQuote.Id
                ORDER BY Product2.Name ASC
        ];


        // Check Sync with CC proServ Type and case when there are unavailable products between Pricebooks
        Map<String, String> result2 = QuotingToolQuoteApexController.syncProServWithSales(testOpportunity.Id, false, QuotingToolQuoteApexController.CC_PROSERV);


        List<QuoteLineItem> resultQLIs2 = [
                SELECT Id, QuoteId, Quantity, PricebookEntryId
                FROM QuoteLineItem
                WHERE quoteId = :testPrimaryQuote.Id
                ORDER BY Product2.Name ASC
        ];
        // Check sync
        System.assertEquals(resultQLIs1, resultQLIs2, 'Products should stay untouched');

        // Check unavailable products
        System.assertEquals('action required', result2.get('status'));
        System.assert(String.isNotBlank(result2.get('unavailableProducts')), 'Unavailable Products should be listed');
        System.assert(result2.get('unavailableProducts').containsIgnoreCase(testProduct4.Id), 'Unavailable Products should be listed');


        // Sync only available products
        Map<String, String> result3 = QuotingToolQuoteApexController.syncProServWithSales(testOpportunity.Id, true, QuotingToolQuoteApexController.CC_PROSERV);

        List<QuoteLineItem> resultQLIs3 = [
                SELECT Id, Quantity
                FROM QuoteLineItem
                WHERE quoteId = :testPrimaryQuote.Id
        ];

        Quote resultProServQuote = [
                SELECT Id, ProServ_Status__c
                FROM Quote
                WHERE Id = :testCCProServQuote.Id
        ];

        Test.stopTest();

        // Check Sync
        System.assertEquals(QuoteHelper.PROSERVSTATUS_SYNCED, resultProServQuote.ProServ_Status__c, 'ProServ Quote Status should be updated');
        System.assertEquals(1, resultQLIs3.size(), 'CC ProServ Products should be synced to Primary Quote');

        // Check Quantity
        System.assertEquals(testCCProServQli1.Quantity, resultQLIs3.get(0).Quantity, 'CC ProServ Products should be synced with Quantity');
    }

    @isTest static void testSyncProServUpdate() {
        createTestData_testSyncProServ();

        Triggers.switchOff();

        QuoteLineItem newSalesProd1 = new QuoteLineItem(
                Product2Id         = testProServQli1.Product2Id,
                QuoteId            = testPrimaryQuote.Id,
                PriceBookEntryId   = testProServQli1.PriceBookEntryId,
                Description        = testProServQli1.Description,
                Quantity           = testProServQli1.Quantity,
                Zero_Quantity__c   = testProServQli1.Zero_Quantity__c,
                UnitPrice          = testProServQli1.UnitPrice,
                Discount_number__c = testProServQli1.Discount_number__c,
                Discount_type__c   = testProServQli1.Discount_type__c,
                Entitlement__c     = testProServQli1.Entitlement__c,
                NewQuantity__c     = testProServQli1.NewQuantity__c,
                Deactivated__c     = testProServQli1.Deactivated__c
        );
        QuoteLineItem newSalesProd2 = new QuoteLineItem(
                Product2Id         = testProServQli2.Product2Id,
                QuoteId            = testPrimaryQuote.Id,
                PriceBookEntryId   = testProServQli2.PriceBookEntryId,
                Description        = testProServQli2.Description,
                Quantity           = testProServQli2.Quantity,
                Zero_Quantity__c   = testProServQli2.Zero_Quantity__c,
                UnitPrice          = testProServQli2.UnitPrice,
                Discount_number__c = testProServQli2.Discount_number__c,
                Discount_type__c   = testProServQli2.Discount_type__c,
                Entitlement__c     = testProServQli2.Entitlement__c,
                NewQuantity__c     = testProServQli2.NewQuantity__c,
                Deactivated__c     = testProServQli2.Deactivated__c
        );
        insert new List<QuoteLineItem> { newSalesProd1, newSalesProd2 };

        // Test Update Existing Products
        QuoteLineItem testUpdateQLI = [SELECT Id, Quantity FROM QuoteLineItem WHERE QuoteId = :testProServQuote.Id AND Product2.Name = 'Test Product 1'];
        testUpdateQLI.Quantity = 10;
        update testUpdateQLI;

        Triggers.switchOn();


        Test.startTest();
        QuotingToolQuoteApexController.syncProServWithSales(testOpportunity.Id, false, QuotingToolQuoteApexController.PROSERV);

        List<QuoteLineItem> resultQLIs4 = [
                SELECT Id, QuoteId, Quantity
                FROM QuoteLineItem
                WHERE quoteId = :testPrimaryQuote.Id
                ORDER BY Product2.Name ASC
        ];

        Quote resultProServQuote = [
                SELECT Id, ProServ_Status__c
                FROM Quote
                WHERE Id = :testProServQuote.Id
        ];

        Test.stopTest();

        // Check Sync
        System.assertEquals(QuoteHelper.PROSERVSTATUS_SYNCED, resultProServQuote.ProServ_Status__c, 'ProServ Quote Status should be updated');
        System.debug(resultQLIs4);
        System.assertEquals(2, resultQLIs4.size(), 'Products Should be only updated on Primary Quote');

        // Product
        System.assertEquals(testUpdateQLI.Quantity, resultQLIs4.get(0).Quantity, 'ProServ Product should be updated');
    }

    @isTest static void testSyncProServOneTimeChargeTerm() {
        createTestData_testSyncProServ();
        testProduct1.Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME;
        update testProduct1;
        Test.startTest();

        QuotingToolQuoteApexController.syncProServWithSales(testOpportunity.Id, false, QuotingToolQuoteApexController.PROSERV);

        Test.stopTest();

        List<QuoteLineItem> resultQLIs = [
                SELECT Id, QuoteId, Quantity, PricebookEntryId
                FROM QuoteLineItem
                WHERE quoteId = :testPrimaryQuote.Id
                ORDER BY Product2.Name ASC
        ];

        // Check sync
        // testProduct1 will be skipped, testProduct2 will be synced with Primary Quote
        System.assertEquals(1, resultQLIs.size(), 'Works incorrectly with products of Charge Term "One - Time"');
    }

    /**
     * Test ProServ Cancellation
     */
    @isTest static void testRemoveProServ() {
        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');

        insert new List<Pricebook2>{
                testPriceBook1
        };

        // create Account
        testAccount = new Account(Name = 'Test account');
        insert testAccount;

        // create Opportunity
        testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
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
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
                ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED);

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

        QuoteTriggerHelper.byPassProServStatusUpdate = true;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;

        Test.startTest();
        insert new List<QuoteLineItem>{
                testPrimaryQli1, testPrimaryQli2, testPrimaryQli3, testPrimaryQli4,
                testSalesQli1, testSalesQli2, testSalesQli3, testSalesQli4,
                testProServQli1, testProServQli2,
                testCCProServQli1, testCCProServQli2
        };
        QuoteTriggerHelper.byPassProServStatusUpdate = false;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = false;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = false;


        // -------------------------------
        // 1) Cancel Professional Services
        QuotingToolQuoteApexController.removeProServProds(testOpportunity.Id, QuotingToolQuoteApexController.PROSERV, true, true, false);
        Map<Id, Quote> resultQuotesMap1 = new Map<Id, Quote>();
        List<Quote> resultQuotes1 = [
                SELECT Id, Name, ProServ_Status__c, ProServ_Details__c, RecordTypeId, LastModifiedDate,
                (SELECT Id, Quantity, Zero_Quantity__c, NewQuantity__c FROM QuoteLineItems)
                FROM Quote
                WHERE Opportunity.Id = :testOpportunity.Id
        ];
        for (Quote q: resultQuotes1){
            resultQuotesMap1.put(q.Id, q);
        }
        Map<Id, Map<Id, QuoteLineItem>> resultQLIsMap1 = new Map<Id, Map<Id, QuoteLineItem>>();
        for (Quote q: resultQuotes1){
            resultQLIsMap1.put(q.Id, new Map<Id, QuoteLineItem>());
            for (QuoteLineItem qli: q.QuoteLineItems){
                resultQLIsMap1.get(q.Id).put(qli.Id, qli);
            }
        }

        // Check Quote Line Items Deletion
        System.assertEquals(3, resultQuotesMap1.get(testPrimaryQuote.Id).QuoteLineItems.size(), 'ProServ Products should be deleted from Primary Quote');
        System.assertEquals(3, resultQuotesMap1.get(testSalesQuote.Id).QuoteLineItems.size(), 'ProServ Products should be deleted from Sales Quotes');
        System.assertEquals(2, resultQuotesMap1.get(testProServQuote.Id).QuoteLineItems.size(), 'ProServ Products should not be deleted from ProServ Quote');
        System.assertEquals(2, resultQuotesMap1.get(testCCProServQuote.Id).QuoteLineItems.size(), 'Products should not be deleted from CC ProServ Quote');

        // Check Quote Line Items Update
        System.assertEquals(testEnt1.Quantity__c, resultQLIsMap1.get(testPrimaryQuote.Id).get(testPrimaryQli2.Id).Quantity);
        System.assertEquals(testEnt1.Quantity__c, resultQLIsMap1.get(testSalesQuote.Id).get(testSalesQli2.Id).Quantity);
        System.assertEquals(true, resultQLIsMap1.get(testPrimaryQuote.Id).get(testPrimaryQli2.Id).Zero_Quantity__c);
        System.assertEquals(true, resultQLIsMap1.get(testSalesQuote.Id).get(testSalesQli2.Id).Zero_Quantity__c);
        System.assertEquals(testEnt1.Quantity__c, resultQLIsMap1.get(testPrimaryQuote.Id).get(testPrimaryQli2.Id).NewQuantity__c);
        System.assertEquals(testEnt1.Quantity__c, resultQLIsMap1.get(testSalesQuote.Id).get(testSalesQli2.Id).NewQuantity__c);

        Test.stopTest();

        // ------------------------------------------------------------------
        // 3) Cancel Professional Services when it has already been cancelled
        QuotingToolQuoteApexController.removeProServProds(testOpportunity.Id, QuotingToolQuoteApexController.PROSERV, true, true, false);
        Map<Id, Quote> resultQuotesMap3 = new Map<Id, Quote>();
        List<Quote> resultQuotes3 = [
                SELECT Id, Name, ProServ_Status__c, ProServ_Details__c, RecordTypeId, LastModifiedDate
                FROM Quote
                WHERE Opportunity.Id = :testOpportunity.Id
        ];
        for (Quote q: resultQuotes3){
            resultQuotesMap3.put(q.Id, q);
        }

        // Check Quote Line Items Deletion
        System.assertEquals(3, resultQuotesMap1.get(testPrimaryQuote.Id).QuoteLineItems.size());
        System.assertEquals(3, resultQuotesMap1.get(testSalesQuote.Id).QuoteLineItems.size());
        System.assertEquals(2, resultQuotesMap1.get(testProServQuote.Id).QuoteLineItems.size(), 'ProServ Products should not be deleted from ProServ Quote');
        System.assertEquals(2, resultQuotesMap1.get(testCCProServQuote.Id).QuoteLineItems.size(), 'Products should not be deleted from CC ProServ Quote');
    }

    /**
     * Test CCProServ Cancellation
     * The test is moved from "Test ProServ Cancellation" to separate test to escape 101 SOQL queries
     */
    @isTest static void testRemoveCCProServ() {
        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');

        insert new List<Pricebook2>{
                testPriceBook1
        };

        // create Account
        testAccount = new Account(Name = 'Test account');
        insert testAccount;

        // create Opportunity
        testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
                CloseDate = system.today(), AccountId = testAccount.Id, Number_of_Employees__c = '20',
                Forecasted_Users__c = 20);
        insert testOpportunity;

        // Create Quotes
        Quote testPrimaryQuote = new Quote(Name = 'Test Primary Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, IsPrimary__c = true);

        Quote testSalesQuote = new Quote(Name = 'Test Sales Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id);

        Quote testCCProServQuote = new Quote(Name = 'Test CC ProServ Quote', OpportunityId = testOpportunity.id,
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
                ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED);

        insert new List<Quote>{
                testPrimaryQuote, testSalesQuote, testCCProServQuote
        };

        // Create Products
        // CC ProServ
        Product2 testProduct1 = new Product2(Name = 'Test Product 3', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV);
        Product2 testProduct2 = new Product2(Name = 'Test Product 4', IsActive = true,
                Sub_Category__c = Product2Helper.SUBCATEGORY_CC_PROSERV);
        Product2 testProduct3 = new Product2(Name = 'Test Product 5', IsActive = true);
        insert new List<Product2>{
                testProduct1, testProduct2, testProduct3
        };

        // Create PricebookEntries
        // CC ProServ
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

        insert new List<PricebookEntry>{
                standardPrice1, standardPrice2,
                testPrice1, testPrice2
        };

        // Create Entitlements
        Entitlement__c testEnt1 = new Entitlement__c(
                Product__c = testProduct3.Id,
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

        Test.startTest();
        // CC ProServ Quote
        QuoteLineItem testCCProServQli1 = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                PricebookEntryId = testPrice1.Id,
                Product2Id = testProduct1.Id,
                UnitPrice = testPrice1.UnitPrice,
                Quantity = 5
        );
        QuoteLineItem testCCProServQli2 = new QuoteLineItem(
                QuoteId = testCCProServQuote.Id,
                PricebookEntryId = testPrice2.Id,
                Product2Id = testProduct2.Id,
                UnitPrice = testPrice2.UnitPrice,
                Quantity = 5
        );

        QuoteTriggerHelper.byPassProServStatusUpdate = true;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = true;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = true;
        insert new List<QuoteLineItem>{
                testPrimaryQli1, testPrimaryQli2,
                testSalesQli1, testSalesQli2,
                testCCProServQli1, testCCProServQli2
        };
        QuoteTriggerHelper.byPassProServStatusUpdate = false;
        QuoteLineItemTriggerHelper.bypassQuoteApprovedStatusChangeLogic = false;
        QuoteLineItemTriggerHelper.byPassQuoteUpdate = false;
            // ----------------------------------------------
            // 2) Cancel Contact Center Professional Services
            QuotingToolQuoteApexController.removeProServProds(testOpportunity.Id, QuotingToolQuoteApexController.CC_PROSERV, true, true, false);
            Map<Id, Quote> resultQuotesMap = new Map<Id, Quote>();
            List<Quote> resultQuotes = [
                    SELECT Id, Name, ProServ_Status__c, ProServ_Details__c, RecordTypeId, LastModifiedDate,
                    (SELECT Id, Quantity, Zero_Quantity__c, NewQuantity__c FROM QuoteLineItems)
                    FROM Quote
                    WHERE Opportunity.Id = :testOpportunity.Id
            ];
            for (Quote q: resultQuotes){
                resultQuotesMap.put(q.Id, q);
            }
            Map<Id, Map<Id, QuoteLineItem>> resultQLIsMap = new Map<Id, Map<Id, QuoteLineItem>>();
            for (Quote q: resultQuotes){
                resultQLIsMap.put(q.Id, new Map<Id, QuoteLineItem>());
                for (QuoteLineItem qli: q.QuoteLineItems){
                    resultQLIsMap.get(q.Id).put(qli.Id, qli);
                }
            }

            // Check Quote Line Items Deletion
            System.assertEquals(1, resultQuotesMap.get(testPrimaryQuote.Id).QuoteLineItems.size(), 'CC ProServ Products should be deleted from Primary Quote');
            System.assertEquals(1, resultQuotesMap.get(testSalesQuote.Id).QuoteLineItems.size(), 'CC ProServ Products should be deleted from Sales Quotes');
            System.assertEquals(2, resultQuotesMap.get(testCCProServQuote.Id).QuoteLineItems.size(), 'Products should not be deleted from CC ProServ Quote');

            // Check Quote Line Items Update
            System.assertEquals(testEnt1.Quantity__c, resultQLIsMap.get(testPrimaryQuote.Id).get(testPrimaryQli2.Id).Quantity);
            System.assertEquals(testEnt1.Quantity__c, resultQLIsMap.get(testSalesQuote.Id).get(testSalesQli2.Id).Quantity);
            System.assertEquals(true, resultQLIsMap.get(testPrimaryQuote.Id).get(testPrimaryQli2.Id).Zero_Quantity__c);
            System.assertEquals(true, resultQLIsMap.get(testSalesQuote.Id).get(testSalesQli2.Id).Zero_Quantity__c);
            System.assertEquals(testEnt1.Quantity__c, resultQLIsMap.get(testPrimaryQuote.Id).get(testPrimaryQli2.Id).NewQuantity__c);
            System.assertEquals(testEnt1.Quantity__c, resultQLIsMap.get(testSalesQuote.Id).get(testSalesQli2.Id).NewQuantity__c);

        Test.stopTest();
    }







    /**
    * Test ProServ Cancellation
    */
    @isTest static void testCancelProServ() {
        // Create PriceBook
        PriceBook2 testPriceBook1 = new Pricebook2(Name = 'Test Price Book',
                Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5,
                Service__c = 'Office', Plan__c = 'Monthly');

        insert new List<Pricebook2>{
                testPriceBook1
        };

        // create Account
        testAccount = new Account(Name = 'Test account');
        insert testAccount;

        // create Opportunity
        testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
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
                Pricebook2Id = testPriceBook1.id, RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
                ProServ_Status__c = QuoteHelper.PROSERVSTATUS_SYNCED);

        insert new List<Quote>{
                testPrimaryQuote, testSalesQuote, testProServQuote, testCCProServQuote
        };

        String details = 'Details';


        Test.startTest();
        // -------------------------------
        // 1) Cancel Professional Services
        QuotingToolQuoteApexController.cancelProServ(testOpportunity.Id, details, QuotingToolQuoteApexController.PROSERV, false);
        Map<Id, Quote> resultQuotesMap1 = new Map<Id, Quote>();
        List<Quote> resultQuotes1 = [
                SELECT Id, Name, ProServ_Status__c, ProServ_Details__c, RecordTypeId, LastModifiedDate
                FROM Quote
                WHERE Opportunity.Id = :testOpportunity.Id
        ];
        for (Quote q: resultQuotes1){
            resultQuotesMap1.put(q.Id, q);
        }

        // Check Statuses
        System.assertEquals(QuoteHelper.PROSERVSTATUS_CANCELLED, resultQuotesMap1.get(testProServQuote.Id).ProServ_Status__c, 'ProServ Status should be changed on ProServ Quote');
        System.assertEquals(QuoteHelper.PROSERVSTATUS_SYNCED, resultQuotesMap1.get(testCCProServQuote.Id).ProServ_Status__c, 'ProServ Status should not be dropped on CC ProServ Quote');

        // Check Details
        System.assertEquals(details, resultQuotesMap1.get(testProServQuote.Id).ProServ_Details__c, 'Details should be updated ProServ Quote');
        System.assertEquals(null, resultQuotesMap1.get(testCCProServQuote.Id).ProServ_Details__c, 'Details should not be updated on CC ProServ Quote');


        // ----------------------------------------------
        // 2) Cancel Contact Center Professional Services
        QuotingToolQuoteApexController.cancelProServ(testOpportunity.Id, details, QuotingToolQuoteApexController.CC_PROSERV, false);
        Map<Id, Quote> resultQuotesMap2 = new Map<Id, Quote>();
        List<Quote> resultQuotes2 = [
                SELECT Id, Name, ProServ_Status__c, ProServ_Details__c, RecordTypeId, LastModifiedDate
                FROM Quote
                WHERE Opportunity.Id = :testOpportunity.Id
        ];
        for (Quote q: resultQuotes2){
            resultQuotesMap2.put(q.Id, q);
        }

        // Check Statuses
        System.assertEquals(QuoteHelper.PROSERVSTATUS_CANCELLED, resultQuotesMap2.get(testProServQuote.Id).ProServ_Status__c, 'ProServ Status should not be changed on ProServ Quote');
        System.assertEquals(QuoteHelper.PROSERVSTATUS_CANCELLED, resultQuotesMap2.get(testCCProServQuote.Id).ProServ_Status__c, 'ProServ Status should be changed on ProServ Quote');

        // Check Details
        System.assertEquals(details, resultQuotesMap2.get(testProServQuote.Id).ProServ_Details__c, 'Details should not be updated ProServ Quote');
        System.assertEquals(details, resultQuotesMap2.get(testCCProServQuote.Id).ProServ_Details__c, 'Details should be updated on CC ProServ Quote');

        Test.stopTest();
        // ------------------------------------------------------------------
        // 3) Cancel Professional Services when it has already been cancelled
        QuotingToolQuoteApexController.cancelProServ(testOpportunity.Id, details, QuotingToolQuoteApexController.PROSERV, false);
        Map<Id, Quote> resultQuotesMap3 = new Map<Id, Quote>();
        List<Quote> resultQuotes3 = [
                SELECT Id, Name, ProServ_Status__c, ProServ_Details__c, RecordTypeId, LastModifiedDate
                FROM Quote
                WHERE Opportunity.Id = :testOpportunity.Id
        ];
        for (Quote q: resultQuotes3){
            resultQuotesMap3.put(q.Id, q);
        }

        // Check Statuses
        System.assertEquals(QuoteHelper.PROSERVSTATUS_CANCELLED, resultQuotesMap2.get(testProServQuote.Id).ProServ_Status__c, 'ProServ Status should not be changed on ProServ Quote');
        System.assertEquals(QuoteHelper.PROSERVSTATUS_CANCELLED, resultQuotesMap2.get(testCCProServQuote.Id).ProServ_Status__c, 'ProServ Status should not be changed on СС ProServ Quote');

        // Check Details
        System.assertEquals(details, resultQuotesMap2.get(testProServQuote.Id).ProServ_Details__c, 'Details should not be updated ProServ Quote');
        System.assertEquals(details, resultQuotesMap2.get(testCCProServQuote.Id).ProServ_Details__c, 'Details should not be updated on CC ProServ Quote');


    }


    /* -------------------------------
     * Test Area Code Line Items Flow
     * ------------------------------- */


    @isTest static void testGetAreaCodeItems(){
        System.runAs(salesrepUser){
            // Prepare data
            Product2 testProd = new Product2(Name = 'Test product', IsActive = true);
            insert testProd;

            PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
            insert testPrBook;

            List <PricebookEntry> testPbes = new List <PricebookEntry>();
            PricebookEntry stdPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProd.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(stdPrice);

            PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
            testPbes.add(testPrice);
            insert testPbes;

            Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify');
            insert testOppty;

            Quote testQt = new Quote (
                    Name = 'qoutetest',
                    OpportunityId = testOppty.Id,
                    Pricebook2Id = testPrBook.id);
            insert testQt;

            List <QuoteLineItem> testQlis = new List <QuoteLineItem>();
            QuoteLineItem testQli = new QuoteLineItem (
                    QuoteId=testQt.Id,
                    Product2Id = testProd.Id,
                    PricebookEntryId = testPrice.Id,
                    Quantity = 5,
                    UnitPrice = testPrice.UnitPrice);
            testQlis.add(testQli);
            QuoteLineItem testQli2 = new QuoteLineItem (
                    QuoteId=testQt.Id,
                    Product2Id = testProd.Id,
                    PricebookEntryId = testPrice.Id,
                    Quantity = 5,
                    UnitPrice = testPrice.UnitPrice);
            testQlis.add(testQli2);
            insert testQlis;

            Area_Codes__c testAreaCode = new Area_Codes__c ();
            insert testAreaCode;

            List <Area_Code_Line_Item__c> testAclis = new List <Area_Code_Line_Item__c> ();
            Area_Code_Line_Item__c testAcli = new Area_Code_Line_Item__c(
                    Quote_Line_Item__c = testQli.Id,
                    Area_Code__c = testAreaCode.Id,
                    Quantity__c = 5
            );
            testAclis.add(testAcli);
            Area_Code_Line_Item__c testAcli2 = new Area_Code_Line_Item__c(
                    Quote_Line_Item__c = testQli2.Id,
                    Area_Code__c = testAreaCode.Id,
                    Quantity__c = 5
            );
            testAclis.add(testAcli2);
            insert testAclis;

            List <QuoteLineItem> qlisToFetchFor = new List <QuoteLineItem>{testQli};
            Test.startTest();
            List <Area_Code_Line_Item__c> aclis = QuotingToolQuoteApexController.getAreaCodeItems(qlisToFetchFor);
            Test.stopTest();

            System.assertEquals(1, aclis.size());
            System.assertEquals(testQli.Id, aclis.get(0).Quote_Line_Item__c, 'Should Get Area Code Line Items only for specified QLIs');

        }
    }

    @isTest static void saveAreaCodeItems(){
        System.runAs(salesrepUser){
            // Prepare data
            Product2 testProd = new Product2(Name = 'Test product', IsActive = true);
            insert testProd;

            PriceBook2 testPrBook = new Pricebook2(
                    Name = 'Test Price Book',
                    Description = 'Test Price Book Products',
                    IsActive = true,
                    Line_Range_Min__c = 5,
                    Service__c = 'Office');
            insert testPrBook;

            List <PricebookEntry> testPbes = new List <PricebookEntry>();
            PricebookEntry standardPrice = new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = testProd.Id,
                    UnitPrice = 10000,
                    IsActive = true,
                    UseStandardPrice = false);
            testPbes.add(standardPrice);

            PricebookEntry testPrice = new PricebookEntry(
                    Pricebook2Id = testPrBook.Id,
                    Product2Id = testProd.Id,
                    UnitPrice = 10000,
                    IsActive = true,
                    UseStandardPrice = false,
                    Per_Line__c = false,
                    Min_Quantity__c = 1,
                    Max_Quantity__c = 100);
            testPbes.add(testPrice);
            insert testPbes;

            Opportunity testOppty = new Opportunity(
                    Name = 'Test Opportunity',
                    StageName = '1. Qualify');
            insert testOppty;

            Quote testQt = new Quote(
                    Name = 'qoutetest',
                    OpportunityId = testOppty.Id,
                    Pricebook2Id = testPrBook.id);
            insert testQt;

            QuoteLineItem testQli = new QuoteLineItem(
                    QuoteId = testQt.Id,
                    Product2Id = testProd.Id,
                    PricebookEntryId = testPrice.Id,
                    Quantity = 5,
                    UnitPrice = testPrice.UnitPrice);
            insert testQli;

            Area_Codes__c testAreaCode = new Area_Codes__c(
                    Name= '555',
                    Country__c='USA'
            );
            insert testAreaCode;

            List<Area_Code_Line_Item__c> aclisToSave = new List<Area_Code_Line_Item__c> {
                new Area_Code_Line_Item__c(
                    Quote_Line_Item__c = testQli.Id,
                    Area_Code__c = testAreaCode.Id,
                    Quantity__c = 5
            )};

            Test.startTest();
            QuotingToolQuoteApexController.saveAreaCodeItems(aclisToSave);
            Test.stopTest();

            List <Area_Code_Line_Item__c> aclis = [SELECT Id, Quote_Line_Item__c, Area_Code__c, Quantity__c
            FROM Area_Code_Line_Item__c];

            System.assertEquals(1, aclis.size());
            System.assertEquals(aclis.get(0).Quantity__c, aclisToSave.get(0).Quantity__c);
            System.assertEquals(aclis.get(0).Area_Code__c, aclisToSave.get(0).Area_Code__c);
            System.assertEquals(aclis.get(0).Quote_Line_Item__c, aclisToSave.get(0).Quote_Line_Item__c);

        }
    }

    @isTest static void testDeleteAreaCodeItems() {
        System.runAs(salesrepUser) {
            // Prepare data
            Product2 testProd = new Product2(Name = 'Test product', IsActive = true);
            insert testProd;

            PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
            insert testPrBook;

            List <PricebookEntry> testPbes = new List <PricebookEntry>();
            PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProd.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(standardPrice);

            PricebookEntry testPrice = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProd.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1, Max_Quantity__c = 100);
            testPbes.add(testPrice);
            insert testPbes;

            Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify');
            insert testOppty;

            Quote testQt = new Quote(
                    Name = 'qoutetest',
                    OpportunityId = testOppty.Id,
                    Pricebook2Id = testPrBook.id);
            insert testQt;

            QuoteLineItem testQli = new QuoteLineItem(
                    QuoteId = testQt.Id,
                    Product2Id = testProd.Id,
                    PricebookEntryId = testPrice.Id,
                    Quantity = 5,
                    UnitPrice = testPrice.UnitPrice);
            insert testQli;

            Area_Codes__c testAreaCode = new Area_Codes__c();
            insert testAreaCode;

            Area_Code_Line_Item__c acliToDelete = new Area_Code_Line_Item__c(
                    Quote_Line_Item__c = testQli.Id,
                    Area_Code__c = testAreaCode.Id,
                    Quantity__c = 5
            );
            insert acliToDelete;

            Test.startTest();
            QuotingToolQuoteApexController.deleteAreaCodeItem(acliToDelete.Id);
            Test.stopTest();

            List <Area_Code_Line_Item__c> aclis = [
                    SELECT Id, Quote_Line_Item__c, Area_Code__c, Quantity__c
                    FROM Area_Code_Line_Item__c
            ];

            System.assertEquals(aclis.size(), 0);

        }
    }

    @isTest
    private static void TestLegalRequestCreation() {
        TestDataFactory.createTestData();
        Map<String, String> params = new Map<String, String>();
        Quote q = (Quote)TestDataFactory.getTestObject(TestDataFactory.TestObject.Quote);
        String specialAsk = 'Test special ask';
        String testLegalType = ApprovalHelperCls.LEGAL_REQUEST_TYPE_AMENDMENT;
        String testAddons = 'BAA';
        String testAccommodation = 'Payment Terms - Net 45';
        String testFeatureAddons = 'Cost Center Management';
        String testContractLink = 'testContractLink.com';
        params.put('quoteId', q.Id);
        params.put('askByCustomer', specialAsk);
        params.put('legalEngagementType', testLegalType);
        params.put('addOns', testAddons);
        params.put('accommodations', testAccommodation);
        params.put('featureAddOns', testFeatureAddons);
        params.put('contractLink', testContractLink);

        User testUser = TestDataFactory.createUser('TestLegalRequestCreation');
        System.runAs(testUser) {
            Test.startTest();
            q = QuotingToolQuoteApexController.submitSpecialToSApprovalRequest(params);
        }


        q = (Quote)TestDataFactory.selectTestObject(TestDataFactory.TestObject.Quote);

        Opportunity oppty = [SELECT Id, Special_ToS_Approval__c, AccountId FROM Opportunity WHERE Id =: q.OpportunityId];

        System.assertNotEquals(null, q.Special_TOS_Approval__c);
        RecordType stosRt = [SELECT id FROM RecordType WHERE SObjectType = 'Approval__c' AND DeveloperName = 'Special_ToS_Approval'];
        Approval__c legalApproval = [SELECT Id, Quote__c, Account__c,
                Ask_By_Customer__c, Type__c, RecordTypeId, Opportunity__c, Add_ons__c,
                Accomodations__c, Feature_Add_ons__c, Contract_Link__c
            FROM Approval__c
            WHERE Id =: oppty.Special_TOS_Approval__c];
        Test.stopTest();
        System.assertEquals(q.Id, legalApproval.Quote__c);
        System.assertEquals(stosRt.Id, legalApproval.RecordTypeId);
        System.assertEquals(q.OpportunityId, legalApproval.Opportunity__c);
        System.assertEquals(oppty.AccountId, legalApproval.Account__c);
        System.assertEquals(specialAsk, legalApproval.Ask_By_Customer__c);
        System.assertEquals(testLegalType, legalApproval.Type__c);
        System.assertEquals(testAddons, legalApproval.Add_ons__c);
        System.assertEquals(testAccommodation, legalApproval.Accomodations__c);
        System.assertEquals(testFeatureAddons, legalApproval.Feature_Add_ons__c);
        System.assertEquals(testContractLink, legalApproval.Contract_Link__c);
    }

    @isTest
    static void testUpdateDependentItems() {
        System.runAs(salesrepUser) {
            Triggers.switchOff();
            TestDataFactory.createTestData();
            Quote testQuote = (Quote)TestDataFactory.getTestObject(TestDataFactory.TestObject.Quote);
            PriceBook2 testPrBook = (PriceBook2)TestDataFactory.getTestPriceBook();

            // Prepare data
            List<Product2> testProds = new List<Product2>();
            Product2 testProdParent = new Product2(Name = 'Parent', IsActive = true, Feature__c = 99);
            testProds.add(testProdParent);
            Product2 testProdDependent = new Product2(Name = 'Dependent', IsActive = true, Dependent_on_Feature__c = 99);
            testProds.add(testProdDependent);
            insert testProds;

            List <PricebookEntry> testPbes = new List <PricebookEntry>();
            testPbes.add(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProdParent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false));
            testPbes.add(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProdDependent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false));

            PricebookEntry testPriceParent = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProdParent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(testPriceParent);
            PricebookEntry testPriceDependent = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProdDependent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(testPriceDependent);
            insert testPbes;

            List<QuoteLineItem> testQlis = new List<QuoteLineItem>();
            QuoteLineItem qliParent = new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    Product2Id = testProdParent.Id,
                    PricebookEntryId = testPriceParent.Id,
                    Quantity = 8,
                    UnitPrice = testPriceParent.UnitPrice,
                    Zero_Quantity__c = false);
            testQlis.add(qliParent);
            QuoteLineItem qliDependent = new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    Product2Id = testProdDependent.Id,
                    PricebookEntryId = testPriceDependent.Id,
                    Quantity = 5,
                    UnitPrice = testPriceDependent.UnitPrice,
                    Zero_Quantity__c = true);
            testQlis.add(qliDependent);

            insert testQlis;
            Triggers.switchOff();

            Test.startTest();
                QuotingToolQuoteApexController.updateDependentItems(testQuote.Id, testQuote.Pricebook2Id);
            Test.stopTest();

            List <QuoteLineItem> checkQlis = [SELECT Id, Quantity, Product2.Name FROM QuoteLineItem WHERE Product2.Name = 'Dependent'];
            Assert.areEqual(qliParent.Quantity,checkQlis[0].Quantity, 'Dependent items should be updated on parent update');
        }
    }

    @isTest static void commonPhonesDependencyUpdate() {
        system.runAs(salesrepUser) {

            Triggers.switchOff();
            TestDataFactory.createTestData();
            Quote testQuote = (Quote)TestDataFactory.getTestObject(TestDataFactory.TestObject.Quote);
            PriceBook2 testPrBook = (PriceBook2)TestDataFactory.getTestPriceBook();

            // Prepare data
            List<Product2> testProds = new List<Product2>();
            Product2 testProdParent = new Product2(Name = 'Parent', IsActive = true, Family = 'Common Phones');
            testProds.add(testProdParent);
            Product2 testProdDependent = new Product2(Name = 'Dependent', IsActive = true, Feature__c = 50);
            testProds.add(testProdDependent);
            insert testProds;

            List <PricebookEntry> testPbes = new List <PricebookEntry>();
            testPbes.add(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProdParent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false));
            testPbes.add(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProdDependent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false));

            PricebookEntry testPriceParent = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProdParent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(testPriceParent);
            PricebookEntry testPriceDependent = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProdDependent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(testPriceDependent);
            insert testPbes;

            List<QuoteLineItem> testQlis = new List<QuoteLineItem>();
            QuoteLineItem qliParent = new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    Product2Id = testProdParent.Id,
                    PricebookEntryId = testPriceParent.Id,
                    Quantity = 8,
                    UnitPrice = testPriceParent.UnitPrice);
            testQlis.add(qliParent);

            insert testQlis;

            Triggers.switchOn();

            // Test insert
            Test.startTest();
            QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
            Test.stopTest();



            // Test Update

            Triggers.switchOff();
            List <QuoteLineItem> checkQlis = [SELECT Id, Quantity, Product2.Name FROM QuoteLineItem WHERE Product2.Name = 'Dependent'];
            System.assert(checkQlis.size() > 0, 'Dependent items should be added');
            System.assertEquals(qliParent.Quantity,checkQlis[0].Quantity, 'Dependent items should be inserted parent insert');

            List<QuoteLineItem> testQlis2 = new List<QuoteLineItem>();
            QuoteLineItem qliParent2 = new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    Product2Id = testProdParent.Id,
                    PricebookEntryId = testPriceParent.Id,
                    Quantity = 5,
                    UnitPrice = testPriceParent.UnitPrice);
            testQlis2.add(qliParent2);

            QuoteLineItem oldQliParent = new QuoteLineItem(
                    id = qliParent.Id,
                    Quantity = 10);
            testQlis2.add(oldQliParent);

            upsert testQlis2;


            Triggers.switchOn();
            QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
            Triggers.switchOff();

            // Test Delete

            List <QuoteLineItem> checkQlis2 = [SELECT Id, Quantity, Product2.Name FROM QuoteLineItem WHERE Product2.Name = 'Dependent'];
            System.assertEquals(15,checkQlis2[0].Quantity, 'Dependent items should be updated on parents update/insert');

            delete testQlis2;

            Triggers.switchOn();
            QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
            Triggers.switchOff();

            List <QuoteLineItem> checkQlisDeleted = [SELECT Id, Quantity, Product2.Name FROM QuoteLineItem WHERE Product2.Name = 'Dependent'];
            System.assertEquals(0,checkQlisDeleted.size(), 'Dependent items should be deleted on parents delete');


        }
    }

    @isTest static void commonPhonesDependencyUpdateWithEntitlements() {
        system.runAs(salesrepUser) {

            Triggers.switchOff();
            TestDataFactory.createTestData();
            Account testAccount = (Account)TestDataFactory.getTestObject(TestDataFactory.TestObject.Account);
            Quote testQuote = (Quote)TestDataFactory.getTestObject(TestDataFactory.TestObject.Quote);
            PriceBook2 testPrBook = (PriceBook2)TestDataFactory.getTestPriceBook();

            // Prepare data
            List<Product2> testProds = new List<Product2>();
            Product2 testProdParent = new Product2(Name = 'Parent', IsActive = true, Family = 'Common Phones');
            testProds.add(testProdParent);
            Product2 testProdDependent = new Product2(
                    Name = 'Dependent',
                    IsActive = true,
                    Feature__c = 50,
                    Sub_Category__c = 'Main');
            testProds.add(testProdDependent);
            insert testProds;

            List <PricebookEntry> testPbes = new List <PricebookEntry>();
            testPbes.add(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProdParent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false));
            testPbes.add(new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProdDependent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false));

            PricebookEntry testPriceParent = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProdParent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(testPriceParent);
            PricebookEntry testPriceDependent = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProdDependent.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            testPbes.add(testPriceDependent);
            insert testPbes;

            // Test With Entitlements
            List <Entitlement__c> entitlements = new List <Entitlement__c>();
            Entitlement__c ent = new Entitlement__c(
                    Product__c = testProdDependent.Id,
                    Account__c = testAccount.Id
            );
            entitlements.add(ent);
            insert entitlements;

            System.debug(testAccount.Id);
            System.debug([SELECT AccountId FROM Quote WHERE Id = :testQuote.Id]);

            List<QuoteLineItem> testQlis = new List<QuoteLineItem>();
            QuoteLineItem qliParent = new QuoteLineItem(
                    QuoteId = testQuote.Id,
                    Product2Id = testProdParent.Id,
                    PricebookEntryId = testPriceParent.Id,
                    Quantity = 8,
                    UnitPrice = testPriceParent.UnitPrice);
            testQlis.add(qliParent);

            insert testQlis;

            Triggers.switchOn();

            // Test insert
            Test.startTest();
            QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
            Test.stopTest();

            Triggers.switchOff();

            List <QuoteLineItem> checkQlis = [
                    SELECT Id, Quantity, Product2.Name, Entitlement__c
                    FROM QuoteLineItem
                    WHERE Product2.Name = 'Dependent'
            ];
            System.assert(checkQlis.size() > 0, 'Dependent items should be added');
            System.assertEquals(qliParent.Quantity,checkQlis[0].Quantity, 'Dependent items should be inserted on parent insert');

            // Test delete

            update new QuoteLineItem(
                    Id = checkQlis[0].Id,
                    Entitlement__c = ent.Id
            );

            delete qliParent;

            update new Quote(
                    Id = testQuote.Id,
                    Upsell_Status__c = 'Upsell'
            );


            Triggers.switchOn();
            QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
            Triggers.switchOff();

            List <QuoteLineItem> checkQlisAfterDelete = [
                    SELECT Id, Quantity, Product2.Name, Entitlement__c, Zero_Quantity__c
                    FROM QuoteLineItem
                    WHERE Product2.Name = 'Dependent'
            ];
            System.assert(checkQlisAfterDelete.size() > 0, 'Dependent items should not be deleted');
            System.assertEquals(1,checkQlisAfterDelete[0].Quantity, 'Dependent item "Quantity"(Quantity=1,Zero_Quantity__c=true) should be zero');
            System.assertEquals(true,checkQlisAfterDelete[0].Zero_Quantity__c, 'Dependent item "Quantity"(Quantity=1,Zero_Quantity__c=true should be zero');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testGetQuoteTotalValues(){
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id,
                CloseDate = System.today());
        insert testOppty;
        Test.startTest();
        // Create Quotes
        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        insert new List <Quote> {
                testQuote1
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c= 17);
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        insert new List<Product2>{
                testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
                standardPrice1, standardPrice2,
                testPrice1, testPrice2
        };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 1', UnitPrice = testPrice1.UnitPrice, Quantity = 5,
                QuoteId = testQuote1.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 2', UnitPrice = testPrice2.UnitPrice, Quantity = 5,
                QuoteId = testQuote1.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
        List <QuoteLineItem> testQlis = new List <QuoteLineItem>{
                qli1, qli2
        };
        insert testQlis;

        Quote resultQuote = new Quote();
        System.runAs(salesrepUser){
            resultQuote = QuotingToolQuoteApexController.getQuoteTotalValues( testQuote1.Id,[
                    SELECT Id, Subtotal, TotalPrice, EffectivePrice__c, NewQuantity__c,
                           TotalInitialPrice__c, Discount_type__c,
                           Product2.Family, QuoteId, Product2.Sub_Category__c, Product2.Name,
                           Product2.Charge_Term__c, Zero_Quantity__c, CurrencyIsoCode,
                           Discount_number__c, ListPrice,
                           Quote.RecordTypeId, QuoteRecordType__c, Discount, UnitPrice
                    FROM QuoteLineItem
                    WHERE id IN :testQlis
            ]);
        }
        Test.stopTest();

        System.debug(resultQuote);
    }

    @isTest static void testGetEntitlements(){
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id,
                CloseDate = System.today());
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        insert new List <Quote> {
                testQuote1
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral');
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral');
        insert new List<Product2> {
                testProduct1, testProduct2
        };

        Test.startTest();

            // Create Price Book Entries
            String stdPriceBookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
            PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);

            PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
            PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
            insert new List <PricebookEntry>{
                    standardPrice1, standardPrice2,
                    testPrice1, testPrice2
            };

            // Create Quote Line Items
            QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 1', UnitPrice = testPrice1.UnitPrice, Quantity = 5,
                    QuoteId = testQuote1.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
            QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 2', UnitPrice = testPrice2.UnitPrice, Quantity = 5,
                    QuoteId = testQuote1.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
            insert new List <QuoteLineItem>{
                    qli1, qli2
            };

            // Create Entitlements
            Entitlement__c testEntitlement1 = new Entitlement__c(Account__c = testAcc.Id, Active__c = true, Product__c = testProduct1.Id);
            Entitlement__c testEntitlement2 = new Entitlement__c(Account__c = testAcc.Id, Active__c = true, Product__c = testProduct2.Id);
            List<Entitlement__c> testEntitlementsList = new List <Entitlement__c> {
                    testEntitlement1, testEntitlement2
            };
            insert testEntitlementsList;

            List<Entitlement__c> resultEntitlements = new List<Entitlement__c>();
            Boolean resultHasActiveEntitlements = null;
            Entitlement__c resultMatchEntitlement = null;
            Entitlement__c resultGetEntitlementForProduct = null;

            Product2 productToTest = QuotingToolQuoteApexController.getProducts(testQuote1.Id, null).get(0).Product2;

            System.runAs(salesrepUser) {
                resultEntitlements = QuotingToolQuoteApexController.getEntitlements(testAcc.Id);
                List<QuoteLineItem> testQlis = QuotingToolQuoteApexController.getQuoteLineItems(testQuote1.Id);
                resultHasActiveEntitlements = QuotingToolQuoteApexController.hasActiveEntitlements(
                        resultEntitlements,
                        testQlis
                );

                resultMatchEntitlement = QuotingToolQuoteApexController.matchEntitlement(
                        resultEntitlements,
                        productToTest
                );

                resultGetEntitlementForProduct = QuotingToolQuoteApexController.getEntitlementForProduct(
                        resultEntitlements,
                        productToTest
                );
            }
        Test.stopTest();
        System.assertEquals(2, resultEntitlements.size());
        System.assertEquals(true, resultHasActiveEntitlements);
        System.assertEquals(testProduct1.Id, resultMatchEntitlement.Product__c);
        System.assertEquals(testProduct1.Id, resultGetEntitlementForProduct.Product__c);
    }

    /**
     * Test if entitlements can successfully be added to ProServ Quote and that ProServ Quote will not be changed
     */
    @isTest
    static void testAddEntitlementsAsLineItems() {

        //Create Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create PriceBook
        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPriceBook;

        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
                CloseDate = System.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        // Create Quote
        Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = testOpportunity.Id,
                Pricebook2Id = testPriceBook.id, RecordTypeId = QuoteHelper.RT_ID_PROSERV);
        insert testQuote;

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Test Softphone', IsActive = true, Sub_Category__c = 'Main',
                Feature__c = 11, Sub_Feature__c = -1, Family = 'Discounted Phones',
                Cart_Tab_Availability__c = QuoteHelper.RT_NAME_PROSERV);
        insert testProduct1;

        // Create PriceBookEntries
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct1.Id, UnitPrice = 0, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook.Id,
                Product2Id = testProduct1.Id, UnitPrice = 0, IsActive = true, UseStandardPrice = false);
        insert new List<PricebookEntry>{
                standardPrice1, testPrice1
        };

        // Create Entitlements
        Entitlement__c testEntitlement1 = new Entitlement__c(Account__c = testAccount.Id,
                Product__c = testProduct1.Id, Active__c = true, Quantity__c = 5);
        insert new List<Entitlement__c>{
                testEntitlement1
        };

        Test.startTest();
        QuotingToolQuoteApexController.addEntitlementsAsLineItems(testQuote.Id);
        Test.stopTest();

        Quote quoteResult = [
                SELECT Id, Name, ProServ_Status__c, (SELECT Id, PricebookEntryId FROM QuoteLineItems)
                FROM Quote
                WHERE Id = :testQuote.Id
        ];

        System.assertEquals(1, quoteResult.QuoteLineItems.size());
        System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, quoteResult.ProServ_Status__c);
    }

    @isTest
    static void testSoldProServQuote() {

        Account testAcc = new Account(
                Name = 'testAcc'
        );
        insert testAcc;

        Opportunity opp = new Opportunity(
                Name = 'MyTestOpportunity',
                AccountId = testAcc.Id,
                StageName = '1. Qualify'
        );
        insert opp;

        Quote testQuote = new Quote(
                OpportunityId = opp.Id,
                Name = 'testProServQuote',
                RecordTypeId = QuoteHelper.RT_ID_PROSERV
        );
        insert testQuote;

        Test.startTest();
            QuotingToolQuoteApexController.soldProServQuote(testQuote.Id);

            Quote reselectedQuote = [SELECT Id, ProServ_Status__c, ProServ_Sold_Date__c FROM Quote WHERE Id = :testQuote.Id];

            System.assertEquals(QuoteHelper.PROSERVSTATUS_SOLD, reselectedQuote.ProServ_Status__c);
            System.assertNotEquals(null, reselectedQuote.ProServ_Sold_Date__c);

            try {
                QuotingToolQuoteApexController.soldProServQuote(null);
            } catch (Exception e) {
                System.assert(e.getMessage().equals('Quote Id is required'));
            }
        Test.stopTest();
    }

    @isTest
    static void testOutForSignatureProServQuote() {

        Account testAcc = new Account(
                Name = 'testAcc'
        );
        insert testAcc;

        Opportunity opp = new Opportunity(
                Name = 'MyTestOpportunity',
                AccountId = testAcc.Id,
                StageName = '1. Qualify'
        );
        insert opp;

        Quote testQuote = new Quote(
                OpportunityId = opp.Id,
                Name = 'testProServQuote',
                RecordTypeId = QuoteHelper.RT_ID_PROSERV
        );
        insert testQuote;

        Test.startTest();
        QuotingToolQuoteApexController.outForSignatureProServQuote(testQuote.Id);

        Quote reselectedQuote = [SELECT Id, ProServ_Status__c, ProServ_Sold_Date__c FROM Quote WHERE Id = :testQuote.Id];

        System.assertEquals(QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE, reselectedQuote.ProServ_Status__c);

        try {
            QuotingToolQuoteApexController.outForSignatureProServQuote(null);
        } catch (Exception e) {
            System.assert(e.getMessage().equals('Quote Id is required'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetEntitlemetsSync () {
        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Products
        Product2 testProduct = new Product2(
            Name = 'Some Product 1',
            IsActive = true,
            Family = 'RingCentral',
            Sub_Category__c = 'Main'
        );
        insert new List<Product2>{testProduct};

        // Create PriceBookEntry
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false
        );
        insert new List <PricebookEntry>{standardPrice1};

        // Create Entitlement
        Entitlement__c testEntitlement = new Entitlement__c(
            Account__c = testAcc.Id,
            Active__c = true,
            Product__c = testProduct.Id,
            Quantity__c = 5
        );
        insert new List <Entitlement__c> {testEntitlement};

        Test.startTest();
            insert (new Feature_Toggle__c(Opportunity_Creation_Entitlement_Based__c = true));
            List<Entitlement__c> entsObtained = QuotingToolQuoteApexController.getEntitlementsSync(testAcc.Id);
        Test.stopTest();

        System.assertEquals(1, entsObtained.size());
        System.assertEquals(testEntitlement.Id, entsObtained.get(0).Id);
    }

     @isTest
    static void testGetPriceBookEntry() {
        // Create Brand
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Name = 'RingCentral');
        insert testBrand;

        // Create PriceBook
        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description = 'Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Line_Range_Max__c = 20,
            Service__c = 'Office',
            Plan__c = 'Monthly',
            Brand__c = testBrand.Id
        );
        insert (new List<PriceBook2>{testPriceBook});
        // Create product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY);
        insert new List<Product2>{testProduct};
        // Create PriceBookEntries
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 0,
            IsActive = true,
            UseStandardPrice = false
        );
        PricebookEntry testPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,//Test.getStandardPriceBookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false
        );
        insert (new List<PricebookEntry>{standardPrice, testPrice});

        Test.startTest();
            List<PriceBookEntry> pricebookEnties = QuotingToolQuoteApexController.getPriceBookEntry(
                new List<Id>{testProduct.Id}
            );
        Test.stopTest();

        System.assertEquals(1, pricebookEnties.size());
        System.assertEquals('RingCentral', pricebookEnties.get(0).PriceBook2.Brand__r.Name);
        System.assertEquals(testProduct.Id, pricebookEnties.get(0).Product2.Id);

    }

    @isTest
    static void testChangeProservType() {
        CreateTestData(Test.getStandardPricebookId(), 999, 'SalesVP', '1-9999999', '0-0', '0-0', '0-0', '0-0', '1234');
        testQuote = [SELECT Id, Approved_Status__c, Level_1_Approver__r.Name FROM Quote WHERE Id=:testQuote.Id];
        testQuote.ProServ_Type__c = 'Contact Center';
        Emails__c email = new Emails__c(Name ='ccproserv', Email_Address__c = 'qwe@example.com');
        insert email;
        update testQuote;

        Response resp;
        Test.startTest();
        resp = QuotingToolQuoteApexController.changeProservType(testQuote, 'RingCentral Contact Center');
        Test.stopTest();
        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals( 'RingCentral Contact Center', testQuote.ProServ_Type__c);
        System.assertEquals(Response.STATUS_SUCCESS, resp.status);
    }

    @isTest
    // tests QuotingToolQuoteApexController.commonPhonesDependencyUpdate
    static void checkAddingItemsDependentOnCommonPhoneOnInsert() {

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

      Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Qualify',
        AccountId = testAccount.Id);
        insert opp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testCommonPhoneProduct = new Product2(
                Name = 'Test Common Phone',
                Family = Product2Helper.FAMILY_COMMON_PHONE,
                IsActive = true);

        // DigitalLine Hot Desking product
        Product2 testDLHDproduct = new Product2(
                Name = 'Test Digital Line Hot Desking',
                Family = Product2Helper.FAMILY_ADDONS,
                Feature__c = 50,
                IsActive = true);

        Product2 testFeature50Fee = new Product2(
                Name = 'Test Feature 50 Fee',
                Family = Product2Helper.FAMILY_FEE,
                Dependent_on_Feature__c = 50,
                IsActive = true);
        insert new List<Product2>{testCommonPhoneProduct, testDLHDproduct, testFeature50Fee};

        Test.startTest();

        PricebookEntry commonPhonePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testCommonPhoneProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry dlhdPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testDLHDproduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry feature50FeePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testFeature50Fee.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{commonPhonePbe, dlhdPbe, feature50FeePbe});

        QuoteLineItem commonPhoneQLI = new QuoteLineItem (
            UnitPrice = commonPhonePbe.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = commonPhonePbe.Id,
            Product2Id = testCommonPhoneProduct.Id
        );
        insert commonPhoneQLI;

        Entitlement__c ent = new Entitlement__c(Account__c = testAccount.Id, Active__c = true, Product__c = testFeature50Fee.Id, Quantity__c = 5);
        insert ent;



        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);

        Test.stopTest();

        QuoteLineItem commonPhoneQLIcheck = [SELECT Quantity FROM QuoteLineItem WHERE Id = :commonPhoneQLI.Id LIMIT 1];
        QuoteLineItem dlhdCheck = [SELECT Quantity FROM QuoteLineItem WHERE Product2.Id = :testDLHDproduct.Id LIMIT 1];
        QuoteLineItem feature50FeeCheck = [SELECT Quantity FROM QuoteLineItem WHERE Product2.Id = :testFeature50Fee.Id LIMIT 1];

        System.assertEquals(5, commonPhoneQLIcheck.Quantity);
        System.assertEquals(commonPhoneQLIcheck.Quantity, dlhdCheck.Quantity);
        System.assertEquals(dlhdCheck.Quantity, feature50FeeCheck.Quantity);
    }

    @isTest
    // tests QuotingToolQuoteApexController.commonPhonesDependencyUpdate
    static void checkAddingItemsDependentOnCommonPhoneOnUpdate() {
        Triggers.switchOff();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
      Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Qualify',
        CloseDate = System.today(),
        AccountId = testAccount.Id);
        insert opp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testCommonPhoneProduct = new Product2(
                Name = 'Test Common Phone',
                Family = Product2Helper.FAMILY_COMMON_PHONE,
                IsActive = true);

        // DigitalLine Hot Desking product
        Product2 testDLHDproduct = new Product2(
                Name = 'Test Digital Line Hot Desking',
                Family = Product2Helper.FAMILY_ADDONS,
                Feature__c = 50,
                IsActive = true);

        Product2 testFeature50Fee = new Product2(
                Name = 'Test Feature 50 Fee',
                Family = Product2Helper.FAMILY_FEE,
                Dependent_on_Feature__c = 50,
                IsActive = true);
        insert new List<Product2>{testCommonPhoneProduct, testDLHDproduct, testFeature50Fee};


        PricebookEntry commonPhonePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testCommonPhoneProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry dlhdPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testDLHDproduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry feature50FeePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testFeature50Fee.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{commonPhonePbe, dlhdPbe, feature50FeePbe});

        QuoteLineItem commonPhoneQLI = new QuoteLineItem (
            UnitPrice = commonPhonePbe.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = commonPhonePbe.Id,
            Product2Id = testCommonPhoneProduct.Id
        );
        insert commonPhoneQLI;
        Triggers.switchOn();
        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);

        Test.startTest();

        QuoteLineItem commonPhoneOnQuote = [SELECT Id, Quantity FROM QuoteLineItem WHERE Id = :commonPhoneQLI.Id LIMIT 1];
        QuoteLineItemHelper.setQuantity(commonPhoneOnQuote, 10);
        update commonPhoneOnQuote;
        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);

        Test.stopTest();

        QuoteLineItem commonPhoneQLIcheck = [SELECT Quantity FROM QuoteLineItem WHERE Id = :commonPhoneQLI.Id LIMIT 1];
        QuoteLineItem dlhdCheck = [SELECT Quantity FROM QuoteLineItem WHERE Product2.Id = :testDLHDproduct.Id LIMIT 1];
        QuoteLineItem feature50FeeCheck = [SELECT Quantity FROM QuoteLineItem WHERE Product2.Id = :testFeature50Fee.Id LIMIT 1];

        System.assertEquals(10, commonPhoneQLIcheck.Quantity);
        System.assertEquals(commonPhoneQLIcheck.Quantity, dlhdCheck.Quantity);
        System.assertEquals(dlhdCheck.Quantity, feature50FeeCheck.Quantity);
    }

    @isTest
    // tests QuotingToolQuoteApexController.commonPhonesDependencyUpdate
    static void checkAddingItemsDependentOnCommonPhoneOnDelete() {
        Triggers.switchOff();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

      Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Qualify',
        CloseDate = System.today(),
        AccountId = testAccount.Id);
        insert opp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testCommonPhoneProduct = new Product2(
                Name = 'Test Common Phone',
                Family = Product2Helper.FAMILY_COMMON_PHONE,
                IsActive = true);

        // DigitalLine Hot Desking product
        Product2 testDLHDproduct = new Product2(
                Name = 'Test Digital Line Hot Desking',
                Family = Product2Helper.FAMILY_ADDONS,
                Feature__c = 50,
                IsActive = true);

        Product2 testFeature50Fee = new Product2(
                Name = 'Test Feature 50 Fee',
                Family = Product2Helper.FAMILY_FEE,
                Dependent_on_Feature__c = 50,
                IsActive = true);
        insert new List<Product2>{testCommonPhoneProduct, testDLHDproduct, testFeature50Fee};


        PricebookEntry commonPhonePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testCommonPhoneProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry dlhdPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testDLHDproduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry feature50FeePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testFeature50Fee.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{commonPhonePbe, dlhdPbe, feature50FeePbe});

        QuoteLineItem commonPhoneQLI = new QuoteLineItem (
            UnitPrice = commonPhonePbe.UnitPrice,
            Quantity = 5,
            QuoteId = testQuote.Id,
            PriceBookEntryId = commonPhonePbe.Id,
            Product2Id = testCommonPhoneProduct.Id
        );
        insert commonPhoneQLI;
        Triggers.switchOn();

        Triggers.switchOn();

        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
        Test.startTest();

        QuoteLineItem commonPhoneOnQuote = [SELECT Id, Quantity FROM QuoteLineItem WHERE Id = :commonPhoneQLI.Id LIMIT 1];
        delete commonPhoneOnQuote;
        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);

        Test.stopTest();

        List<QuoteLineItem> testQuoteQLIs = [SELECT Quantity FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];

        System.assert(testQuoteQLIs.isEmpty());
    }

    @isTest
    // tests QuotingToolQuoteApexController.commonPhonesDependencyUpdate
    static void checkUpdatingItemsDependentOnCommonPhoneOnDelete() {
        Triggers.switchOff();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

      Opportunity opp = new Opportunity(
        Name = 'Test Opportunity',
        StageName = 'Qualify',
        CloseDate = System.today(),
        AccountId = testAccount.Id);
        insert opp;

        Quote testQuote = new Quote (
                Name = 'Test Quote',
                OpportunityId = opp.id,
                Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;

        Product2 testCommonPhoneProduct = new Product2(
                Name = 'Test Common Phone',
                Family = Product2Helper.FAMILY_COMMON_PHONE,
                IsActive = true);

        Product2 anotherCommonPhoneProduct = new Product2(
                Name = 'Another Common Phone',
                Family = Product2Helper.FAMILY_COMMON_PHONE,
                IsActive = true);

        // DigitalLine Hot Desking product
        Product2 testDLHDproduct = new Product2(
                Name = 'Test Digital Line Hot Desking',
                Family = Product2Helper.FAMILY_ADDONS,
                Feature__c = 50,
                IsActive = true);

        Product2 testFeature50Fee = new Product2(
                Name = 'Test Feature 50 Fee',
                Family = Product2Helper.FAMILY_FEE,
                Dependent_on_Feature__c = 50,
                IsActive = true);
        insert new List<Product2>{testCommonPhoneProduct, anotherCommonPhoneProduct, testDLHDproduct, testFeature50Fee};


        PricebookEntry commonPhonePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testCommonPhoneProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry anotherCommonPhonePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = anotherCommonPhoneProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry dlhdPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testDLHDproduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        PricebookEntry feature50FeePbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testFeature50Fee.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{commonPhonePbe, anotherCommonPhonePbe, dlhdPbe, feature50FeePbe});

        QuoteLineItem commonPhoneQLI = new QuoteLineItem (
            UnitPrice = commonPhonePbe.UnitPrice,
            Quantity = 5,
            Zero_Quantity__c = false,
            QuoteId = testQuote.Id,
            PriceBookEntryId = commonPhonePbe.Id,
            Product2Id = testCommonPhoneProduct.Id
        );

        QuoteLineItem anotherCommonPhoneQLI = new QuoteLineItem (
            UnitPrice = anotherCommonPhonePbe.UnitPrice,
            Quantity = 5,
            Zero_Quantity__c = false,
            QuoteId = testQuote.Id,
            PriceBookEntryId = anotherCommonPhonePbe.Id,
            Product2Id = anotherCommonPhoneProduct.Id
        );
        insert new List<QuoteLineItem>{commonPhoneQLI, anotherCommonPhoneQLI};
        Triggers.switchOn();
        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);
        Test.startTest();

        QuoteLineItem commonPhoneOnQuote = [SELECT Id FROM QuoteLineItem WHERE Id = :commonPhoneQLI.Id LIMIT 1];
        delete commonPhoneOnQuote;
        QuotingToolQuoteApexController.commonPhonesDependencyUpdate(testQuote.Id);

        Test.stopTest();

        List<QuoteLineItem> testQuoteQLIs = [SELECT Quantity, Zero_Quantity__c
                                             FROM QuoteLineItem
                                             WHERE QuoteId = :testQuote.Id
                                             AND Product2.Family = :Product2Helper.FAMILY_COMMON_PHONE];
        Decimal commonPhonesQtySum = 0;
        for(QuoteLineItem q : testQuoteQLIs) {
                commonPhonesQtySum += QuoteLineItemHelper.getQuantity(q);
        }

        QuoteLineItem dlhdCheck = [SELECT Quantity, Zero_Quantity__c
                                   FROM QuoteLineItem
                                   WHERE Product2.Id = :testDLHDproduct.Id
                                   LIMIT 1];

        QuoteLineItem feature50FeeCheck = [SELECT Quantity, Zero_Quantity__c
                                           FROM QuoteLineItem
                                           WHERE Product2.Id = :testFeature50Fee.Id
                                           LIMIT 1];

        System.assertEquals(5, commonPhonesQtySum);
        System.assertEquals(commonPhonesQtySum, QuoteLineItemHelper.getQuantity(dlhdCheck));
        System.assertEquals(commonPhonesQtySum, QuoteLineItemHelper.getQuantity(feature50FeeCheck));
    }

    @isTest
    static void testGeneratePackageInfoForQLI() {
        String quotePackageInfo = '[{"id":"5","version":"3","packageInfo":{"version":"3"},"productName":"Office",' +
            '"duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":null,"offerType":"Regular",' +
            '"globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT",' +
            '"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle",' +
            '"transactionType":"Any","target":"Global","override":false}],"permissions":null}]';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, quotePackageInfo)
            .build()
            .getRecord();

        Product2 testCommonPhoneProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_ANNUAL)
            .build()
            .getRecord();

        QuoteLineItem commonPhoneQLI = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
            })
            .build()
            .getRecord();

        commonPhoneQLI.putSObject(QuoteLineItem.Product2Id, testCommonPhoneProduct);

        Test.startTest();
            BillingWrappers.QLIPackageInfo result = QuotingToolQuoteApexController.generatePackageInfoForQLI(testQuote, commonPhoneQLI);
        Test.stopTest();

        Assert.areEqual('Annual', result.duration, 'Incorrect duration');
        Assert.areEqual('Money', result.Discount.Type,  'Incorrect discount type');
        Assert.areEqual(commonPhoneQLI.Discount_Value__c, result.Discount.Value, 'Incorrect discount value');
        Assert.areEqual(commonPhoneQLI.UnitPrice, result.Price, 'Incorrect unit price');
        Assert.areEqual('5', result.Id, 'Incorrect Id');
        Assert.areEqual('3', result.Version, 'Incorrect version');

    }

    @isTest
    static void testDeleteProductsDependentOnSeat() {
        CreateTestData(Test.getStandardPricebookId(), null, null, null, null, null, null, null, null);

        Test.startTest();
        Product2 seatProduct = new Product2(
            Name = 'testSeat',
            Family = Product2Helper.FAMILY_CCSERVICE,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_SEAT
        );

        Product2 additionalPort = new Product2(
            Name = 'testAdditionalPort',
            Family = Product2Helper.FAMILY_ADDONS,
            Product_Type__c = Product2Helper.PRODUCT_TYPE_PORT,
            Sub_Category__c = QuoteLineItemHelper.CC_CATEGORIES.get('Contact Center')
        );

        insert new List<Product2>{seatProduct, additionalPort};

        Id testStandardPriceBookId = Test.getStandardPricebookId();

        PricebookEntry seatStandardProductPbe = new PricebookEntry(
            Pricebook2Id = testStandardPriceBookId,
            Product2Id = seatProduct.Id,
            UnitPrice = 1,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );

        PricebookEntry additionalPortStandardPbe = new PricebookEntry(
            Pricebook2Id = testStandardPriceBookId,
            Product2Id = additionalPort.Id,
            UnitPrice = 1,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );
        insert new List<PricebookEntry>{seatStandardProductPbe, additionalPortStandardPbe};


        PricebookEntry seatProductPbe = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = seatProduct.Id,
            UnitPrice = 1,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );

        PricebookEntry additionalPortPbe = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id,
            Product2Id = additionalPort.Id,
            UnitPrice = 1,
            IsActive = true,
            UseStandardPrice = false,
            Per_Line__c = false,
            Min_Quantity__c = 1,
            Max_Quantity__c = 100
        );

        insert new List<PricebookEntry>{seatProductPbe, additionalPortPbe};

        QuoteLineItem seatQli = new QuoteLineItem(
            Product2 = seatProduct,
            Product2Id = seatProduct.Id,
            QuoteId = testQuote.Id,
            PriceBookEntryId = seatProductPbe.Id,
            Quantity = 1,
            UnitPrice = 1
        );

        QuoteLineItem additionalPortQli = new QuoteLineItem(
            Product2 = additionalPort,
            Product2Id = additionalPort.Id,
            QuoteId = testQuote.Id,
            PriceBookEntryId = additionalPortPbe.Id,
            Quantity = 1,
            UnitPrice = 1
        );

        insert new List<QuoteLineItem>{seatQli, additionalPortQli};

        QuotingToolQuoteApexController.deleteQuoteLineItem(seatQli);

        List<QuoteLineItem> itemToDelete = [SELECT Id FROM QuoteLineItem WHERE Id =:additionalPortQli.Id];
        System.assert(itemToDelete.isEmpty(), 'Products dependant on seat should be deleted');
        Test.stopTest();

    }

    @IsTest
    static void testUnlockOrderAndPhases() {
        Feature_Toggle__c featureToggle = Feature_Toggle__c.getOrgDefaults();
        featureToggle.NewChangeOrderFlow__c = true;
        insert featureToggle;

        Triggers.switchOff();
        // Create PriceBook
        Pricebook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify', AccountId = testAcc.Id,
            CloseDate = System.today());
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name = 'Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote2 = new Quote(Name = 'Test Primary 2', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
            isPrimary__c = true);
        insert new List <Quote>{
            testQuote1, testQuote2
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c = 17);
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        insert new List<Product2>{
            testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
            Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
            standardPrice1, standardPrice2,
            testPrice1, testPrice2
        };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 1',
            UnitPrice = testPrice1.UnitPrice, Quantity = 5, QuoteId = testQuote1.Id, PricebookEntryId = testPrice1.Id,
            Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 2',
            UnitPrice = testPrice2.UnitPrice, Quantity = 5, QuoteId = testQuote2.Id, PricebookEntryId = testPrice2.Id,
            Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
        insert new List <QuoteLineItem>{
            qli1, qli2
        };

        // Create Order
        Order testOrder = new Order(Name = 'Test Order', AccountId = testAcc.Id, EffectiveDate = System.today(),
            Status = 'New', QuoteId = testQuote1.Id, Pricebook2Id = testPrBook.Id, RelatedChangeOpportunity__c = testOppty.Id);
        insert testOrder;

        OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, PricebookEntryId = testPrice1.Id,
            UnitPrice = testPrice1.UnitPrice, Quantity = 40);
        insert testOrderItem;

        // Create Opportunity
        Opportunity testOppty2 = new Opportunity(Name = 'Test Opportunity2', StageName = '1. Qualify', AccountId = testAcc.Id,
            Parent_Order__c = testOrder.Id, CloseDate = System.today());
        insert testOppty2;

        Phase__c testPhase = new Phase__c(
            Name = 'testPhase1',
            Opportunity__c = testOppty.Id,
            Order__c = testOrder.Id,
            Status__c = 'Locked'
        );
        insert testPhase;

        Asset testAsset = new Asset(
            Name = 'TestAsset',
            AccountId = testAcc.Id,
            Quantity = 15,
            Active__c = true);
        insert testAsset;

        Quote changedQuote = new Quote(Name = 'Test Changed', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty2.Id);
        insert changedQuote;

        QuoteLineItem changedQuoteLineItem = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 1',
            UnitPrice = testPrice1.UnitPrice, Quantity = 5, Asset__c = testAsset.Id, QuoteId = changedQuote.Id,
            PricebookEntryId = testPrice1.Id, Product2Id = testProduct1.Id, OriginalOrderLineItem__c = testOrderItem.Id,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        insert changedQuoteLineItem;

        Test.startTest();
        QuotingToolQuoteApexController.unlockOrderAndPhases(testOppty2.Id);
        Test.stopTest();

        List<OrderItem> orderItems = [SELECT Id, Asset__c FROM OrderItem WHERE Id = :changedQuoteLineItem.OriginalOrderLineItem__c];
        for (OrderItem orderItem : orderItems) {
            System.assertEquals(changedQuoteLineItem.Asset__c, orderItem.Asset__c, 'Wrong value was populated to asset field');
        }
        System.assertEquals(OpportunityHelper.STAGE_NAME_DOWNGRADED, [SELECT Id, StageName FROM Opportunity WHERE Id = :testOppty2.Id].StageName);
    }

    @isTest
    static void test_getIsNewChangeOrder() {
        insert new Feature_Toggle__c (NewChangeOrderFlow__c = true);
        Test.startTest();
        Boolean isNewChangeOrder = QuotingToolQuoteApexController.getIsNewChangeOrder();
        Test.stopTest();

        System.assertEquals(true, isNewChangeOrder, 'Could not get new change order feature toggle value');

    }

    @isTest
    private static void testSendMailWithProservAutomatedEmailTemplateNewCc() {
        Boolean isSuccess = testSendMailWithProservAutomatedEmailTemplate(true);
        System.assert(isSuccess, 'Test should be passed successfully.');
    }

    @isTest
    private static void testSendMailWithProservAutomatedEmailTemplateOldCc() {
        Boolean isSuccess = testSendMailWithProservAutomatedEmailTemplate(false);
        System.assert(isSuccess, 'Test should be passed successfully.');
    }

    @isTest
    private static void testFetchOriginalSOWPositive() {

        Triggers.switchOff();
        String stdPriceBookId = Test.getStandardPricebookId();

        Account acc = new Account(
            Name='test account',
            RC_User_ID__c = '12345'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Original Opportunity',
            Type = 'Syndicated - New',
            StageName = 'Planning',
            CloseDate = system.today(),
            AccountId = acc.Id
        );
        insert opp;

        Quote qt = new Quote (
            Name = 'qoutetest',
            OpportunityId = opp.id,
            Approved_Status__c = 'Approved',
            Products__c = 'RingCentral',
            Pricebook2Id = stdPriceBookId
        );
        insert qt;

        // Create Products
        Product2 testProduct = new Product2(
            Name = 'Service Plan',
            IsActive = true,
            Family = 'RingCentral',
            Sub_Category__c = 'Main',
            Feature__c= 17
        );
        insert testProduct;

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = stdPriceBookId,
            Product2Id = testProduct.Id,
            UnitPrice = 10000,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPrice;

        // Create Quote Line Items
        QuoteLineItem qli = new QuoteLineItem (
            ServiceDate = date.today(),
            Description = 'TestLineItem 1',
            UnitPrice = standardPrice.UnitPrice,
            Quantity = 5,
            QuoteId = qt.Id,
            PriceBookEntryId = standardPrice.Id,
            Product2Id = testProduct.Id,
            Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
            Discount_number__c = 100
        );
        insert qli;

        // Create Order
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            Status = 'New',
            QuoteId = qt.Id,
            Pricebook2Id = stdPriceBookId,
            Signed_SOW__C = 'testlink.com',
            OpportunityId = opp.id
        );
        insert testOrder;


        Test.startTest();
            system.assertEquals(QuotingToolQuoteApexController.fetchOriginalSOW(acc.id), 'testlink.com', 'The logic to fetch the original SOW doesnt meet required criteria, check opportunity and order tied to account');
        Test.stopTest();
    }

    @isTest
    private static void testFetchOriginalSOWNegative() {

        Triggers.switchOff();

        Account acc = new Account(
            Name='test account',
            RC_User_ID__c = '12345'
        );
        insert acc;

        Test.startTest();
            //When method is used without opportunities or that doesnt meet criteria
            system.assertEquals(QuotingToolQuoteApexController.fetchOriginalSOW(acc.id), null, 'Operation must fail (return null) since there was no opportunity tied to the account');
            Opportunity opp = new Opportunity(
                Name = 'Test Original Opportunity',
                Type = 'Syndicated - New',
                StageName = 'Planning',
                CloseDate = system.today(),
                AccountId = acc.Id
            );
            insert opp;
            //When method is used without orders or that doesnt meet criteria
            system.assertEquals(QuotingToolQuoteApexController.fetchOriginalSOW(acc.id), null, 'Operation must fail (return null) since there was no order tied to the account and opportunity provided');
        Test.stopTest();
    }

    @isTest
    private static void testSubjectPopulationWhenSendMailWithEngageProservEmailTemplate() {
        Emails__c emailsSetting = (Emails__c) new SObjectBuilder(Emails__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Emails__c.Name => 'proservsow',
                Emails__c.Email_Address__c => new ValueProvider.UniqueEmailProvider()
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.OwnerId => UserInfo.getUserId()
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_PROSERV)
            .create()
            .getRecord();

        Test.startTest();
        Map<String, String> params = new Map<String, String>{
            'opportunityId' => opp.Id,
            'templateApiName' => QuotingToolQuoteApexController.PROSERV_ENGAGED_EMAIL_API_NAME,
            'Primary_Opportunity_Contact__c' => opp.Primary_Opportunity_Contact__c,
            'Current_Owner__c' => acc.Current_Owner__c,
            'Inside_Sales_Rep__c' => acc.Inside_Sales_Rep__c
        };
        QuotingToolQuoteApexController.sendMail(params);
        Test.stopTest();

        Messaging.SingleEmailMessage emailToSend = QuotingToolQuoteApexController.emailToSend;

        EmailTemplate template = (EmailTemplate) new EmailTemplateSelector()
            .selectEmailTemplateByDeveloperName(new List<String>{QuotingToolQuoteApexController.PROSERV_ENGAGED_EMAIL_API_NAME})
            .executeQuery()
            .get(0);

        opp = (Opportunity) new OpportunitySelector()
            .selectOpptys()
            .selectFields(new List<String>{
                'Owner.Name'
            })
            .executeQuery()
            .get(0);

        String expectedEmailSubject = template.Subject + ' [Owner: ' + opp?.Owner?.Name + ']';
        System.assertEquals(emailToSend.getSubject(), expectedEmailSubject);
    }

    private static Boolean testSendMailWithProservAutomatedEmailTemplate(Boolean withNewCcInProservAutomatedEmail) {
        if (withNewCcInProservAutomatedEmail) {
            new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setField(Feature_Toggle__c.NewCcInProservAutomatedEmail__c, true)
                .create();
        }

        List<User> users = new SObjectBuilder(User.SObjectType)
            .setField(User.Email, new ValueProvider.UniqueEmailProvider())
            .quantity(8)
            .create()
            .getRecords();

        List<String> oppTeamMembersIds = new List<String>();
        for (Integer i = 4; i < 8; ++i) {
            oppTeamMembersIds.add(users[i].Id);
        }

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Current_Owner__c, users[0].Id)
            .setField(Account.Inside_Sales_Rep__c, users[1].Id)
            .setField(Account.CSM__c, users[2].Id)
            .create()
            .getRecord();

        Contact primaryOppContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.LastName, 'testLastName')
            .setField(Contact.FirstName, 'testFirstName')
            .setField(Contact.Email, new ValueProvider.UniqueEmailProvider())
            .setField(Contact.AccountId, acc.Id)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Primary_Opportunity_Contact__c, primaryOppContact.Id)
            .create()
            .getRecord();

        List<OpportunityTeamMember> oppTeamMembers = new SObjectBuilder(OpportunityTeamMember.SObjectType)
            .quantity(4)
            .setField(OpportunityTeamMember.OpportunityId, opp.Id)
            .setField(OpportunityTeamMember.UserId,
                new ValueProvider.ListProvider(oppTeamMembersIds))
            .setField(OpportunityTeamMember.TeamMemberRole,
                new ValueProvider.ListProvider(new List<String>(OpportunityTeamHelper.ENGINEER_ROLES)))
            .create()
            .getRecords();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.RecordTypeId, QuoteHelper.RT_ID_PROSERV)
            .setField(Quote.ProServSalesRep__c, users[7].Id)
            .create()
            .getRecord();

        System.assertEquals(null, QuotingToolQuoteApexController.emailToSend,
            'emailToSend variable should be null initially.');

        Test.startTest();

            Map<String, String> params = new Map<String, String>{
                'opportunityId' => opp.Id,
                'templateApiName' => QuotingToolQuoteApexController.PROSERV_AUTOMATED_EMAIL,
                'Primary_Opportunity_Contact__c' => opp.Primary_Opportunity_Contact__c,
                'Current_Owner__c' => acc.Current_Owner__c,
                'Inside_Sales_Rep__c' => acc.Inside_Sales_Rep__c
            };
            QuotingToolQuoteApexController.sendMail(params);

        Test.stopTest();

        Messaging.SingleEmailMessage emailToSend = QuotingToolQuoteApexController.emailToSend;

        System.assertNotEquals(null, emailToSend, 'SingleEmailMessage was not created.');
        System.assert(emailToSend.getToAddresses().contains(primaryOppContact.Email.toLowerCase()),
            'Primary_Opportunity_Contact__c is not in email toAddresses list.');

        Set<String> ccAddresses = new Set<String>(emailToSend.getCcAddresses());
        System.assert(ccAddresses.contains(users[0].Email.toLowerCase()),
            'Current_Owner__c of Account is not in email CC addresses list.');
        System.assert(ccAddresses.contains(users[1].Email.toLowerCase()),
            'Inside_Sales_Rep__c of Account is not in email CC addresses list.');
        if (withNewCcInProservAutomatedEmail) {
            System.assert(ccAddresses.contains(users[2].Id),
                'CSM__c of Account is not in email CC addresses list.');
            System.assert(ccAddresses.contains(users[7].Id),
                'ProServSalesRep__c of Quote is not in email CC addresses list.');
            System.assert(ccAddresses.containsAll(oppTeamMembersIds),
                'Some of OpportunityTeamMembers with engineer role  are missing in CC addresses list.');
        } else {
            System.assert(!ccAddresses.contains(users[2].Id),
                'CSM__c of Account should not be in email CC addresses list.');
            System.assert(!ccAddresses.contains(users[7].Id),
                'ProServSalesRep__c of Quote should not be in email CC addresses list.');
            for (Id oppTeamMemberId : oppTeamMembersIds) {
                System.assert(!ccAddresses.contains(oppTeamMemberId),
                    'None of OpportunityTeamMembers with engineer role should be in CC addresses list.');
            }
        }

        Pattern placeholderPattern = Pattern.compile('(?i)\\$\\{(ContactName|AccountName)\\}');
        // looks for placeholders in HtmlBody. All of them should be replaced.
        System.assert(!placeholderPattern.matcher(emailToSend.getHtmlBody()).find(),
            'Some \'${...}\' placeholders in HtmlBody were not replaced with  data.');

        // looks for placeholders in PlainTextBody. All of them should be replaced.
        System.assert(!placeholderPattern.matcher(emailToSend.getPlainTextBody()).find(),
            'Some \'${...}\' placeholders in PlainTextBody were not replaced with  data.');

        return true;
    }

    @isTest
    private static void testGetRecordTypeNameOnEngage() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Tier_Name__c, OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE)
            .build()
            .getRecord();

        Test.startTest();

        String rtName = QuotingToolQuoteApexController.getQuoteRecordTypeName(opp, CC_PROSERV_QUOTE_RT_ID);

        Test.stopTest();

        System.assertEquals(
            PROSERV_QUOTE_RT_NAME,
            rtName,
            'Incorrect Quote Name on Engage'
        );
    }

    @isTest
    private static void testGetRecordTypeNameWoEngage() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .build()
            .getRecord();

        Test.startTest();

        String rtName = QuotingToolQuoteApexController.getQuoteRecordTypeName(opp, CC_PROSERV_QUOTE_RT_ID);

        Test.stopTest();

        System.assertEquals(
            CC_PROSERV_QUOTE_RT_NAME,
            rtName,
            'Incorrect Quote Name without Engage'
        );
    }

    @isTest
    private static void testGetPackageDurationWithAnnualPlan() {
        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        packageInfo.duration = Pricebook2Helper.PLAN_ANNUAL;

        Test.startTest();

        String duration = QuotingToolQuoteApexController.getPackageDuration(packageInfo);

        Test.stopTest();

        System.assertEquals(
            Pricebook2Helper.PLAN_ANNUAL,
            duration,
            'Incorrect Package duration with Annual plan'
        );
    }

    @isTest
    private static void testGetPackageDurationWithMonthlyPlan() {
        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        packageInfo.duration = Pricebook2Helper.PLAN_MONTHLY_CONTRACT;

        Test.startTest();

        String duration = QuotingToolQuoteApexController.getPackageDuration(packageInfo);

        Test.stopTest();

        System.assertEquals(
            Pricebook2Helper.PLAN_MONTHLY_CONTRACT,
            duration,
            'Incorrect Package duration with Monthly Contract plan'
        );
    }

    @isTest
    static void test_engageProServProcess_selectPricebookByCurrency() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        schedulerConfiguration__c brand = (schedulerConfiguration__c) new SObjectBuilder(schedulerConfiguration__c.SObjectType)
            .setField(schedulerConfiguration__c.Name, OpportunityHelper.BRAND_AVAYA)
            .create()
            .getRecord();

        List<PriceBook2> pricebook = (List<PriceBook2>) new SObjectBuilder(PriceBook2.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_PROSERV,
                PriceBook2.AllowedRecordType__c => Pricebook2Helper.ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV,
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString(),
                PriceBook2.ExtID__c => ValueProviderBuilder.provideList(new List<String>{
                    'ProServ_Universal_USD', 'ProServ_Universal_GBP'
                }),
                PriceBook2.CurrencyIsoCode => ValueProviderBuilder.provideList(new List<String>{
                    RingCentralHelper.USD, RingCentralHelper.GBP
                }),
                PriceBook2.Brand__c => brand.Id
            })
            .create()
            .getRecords();

        Test.startTest();
            QuotingToolQuoteApexController.engageProServProcess(
                opp.Id,
                opp.AccountId,
                'testDetails',
                QuotingToolQuoteApexController.PROSERV
            );
        Test.stopTest();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByOppIds(new List<Id> {opp.Id})
            .selectFields(
                new List<String>{
                    'Id',
                    'PriceBook2.ExtID__c',
                    'PriceBook2.CurrencyIsoCode',
                    'RecordTypeId',
                    'Enabled_LBO__c'
                }
            )
            .executeQuery();

        Quote primaryQuote = QuoteHelper.getPrimaryQuote(quotes, opp.Is_Billing_Opportunity__c);
        Quote proServQuote = QuoteHelper.getProServQuote(quotes);

        System.assert(proServQuote != null, 'No ProServ quotes created');
        System.assert(primaryQuote != null, 'No Primary quotes created');

        System.assertEquals(
            RingCentralHelper.GBP,
            proServQuote.PriceBook2.CurrencyIsoCode,
            'Incorrect pricebook for quote selected: wrong CurrencyIsoCode'
        );

        System.assertEquals(
            'ProServ_Universal_GBP',
            proServQuote.Pricebook2.ExtID__c,
            'Incorrect pricebook for quote selected: wrong ExtID__c'
        );
    }

    @isTest
    static void testSourceIsPopulatedOnApproval() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA
            })
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Approval__c.Name => 'plainApproval',
                        Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                        Approval__c.Account__c => acc.Id,
                        Approval__c.Opportunity__c => opp.Id
                    }
                )
                .create()
                .getRecord();

            Map<String, String> params = new Map<String, String>{
                'quoteId' => q.Id,
                'approvalId' => app.Id,
                'source' => ApprovalHelper.SOURCE_AUTO_GENERATED_FROM_PDF
            };

            System.runAs(salesrepUser) {
                QuotingToolQuoteApexController.submitSpecialToSApprovalRequest(params);
            }
        Test.stopTest();

        Approval__c updatedApp = ((List<Approval__c>) new QueryFactory(Approval__c.sObjectType)
            .selectFields(new List<String>{'Source__c'})
            .setCondition('Id = \'' + app.Id + '\'')
            .executeQuery())
            .get(0);

        System.assertEquals(ApprovalHelper.SOURCE_AUTO_GENERATED_FROM_PDF, updatedApp.Source__c,
            'Source__c field should be populated with \'Auto-Generated from PDF\'');
    }

  @isTest
    static void testIsAllowedtoEditDiscount(){
    Test.startTest();
      Boolean isAllowed = QuotingToolQuoteApexController.isAllowedtoEditDiscount();
        Test.stopTest();

    System.assertEquals(false,isAllowed);
  }

  @isTest
    static void testOppty3(){
    // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify', AccountId = testAcc.Id,
            CloseDate = System.today());
        insert testOppty;

    Test.startTest();
      Opportunity oppty = QuotingToolQuoteApexController.getOpportunity(testOppty.Id);
      oppty.Brand_Name__c = OpportunityHelper.BRAND_AVAYA;
      QuotingToolQuoteApexController.updateOpp(oppty);
        Test.stopTest();

    System.assertEquals('1. Qualify', oppty.StageName);
  }

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
    static void testTaxes_Qli_Approval(){
    Triggers.switchOff();
        // Create PriceBook
        Pricebook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify', AccountId = testAcc.Id,
            CloseDate = System.today());
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name = 'Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote2 = new Quote(Name = 'Test Primary 2', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
            isPrimary__c = true);
        insert new List <Quote>{
            testQuote1, testQuote2
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c = 17);
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main');
        insert new List<Product2>{
            testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
            Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
            standardPrice1, standardPrice2,
            testPrice1, testPrice2
        };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 1',
            UnitPrice = testPrice1.UnitPrice, Quantity = 5, QuoteId = testQuote1.Id, PricebookEntryId = testPrice1.Id,
            Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 2',
            UnitPrice = testPrice2.UnitPrice, Quantity = 5, QuoteId = testQuote2.Id, PricebookEntryId = testPrice2.Id,
            Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
        insert new List <QuoteLineItem>{
            qli1, qli2
        };

        // Create Order
        Order testOrder = new Order(Name = 'Test Order', AccountId = testAcc.Id, EffectiveDate = System.today(),
            Status = 'New', QuoteId = testQuote1.Id, Pricebook2Id = testPrBook.Id, RelatedChangeOpportunity__c = testOppty.Id);
        insert testOrder;

        OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id, PricebookEntryId = testPrice1.Id,
            UnitPrice = testPrice1.UnitPrice, Quantity = 40);
        insert testOrderItem;

        // Create Opportunity
        Opportunity testOppty2 = new Opportunity(Name = 'Test Opportunity2', StageName = '1. Qualify', AccountId = testAcc.Id,
            Parent_Order__c = testOrder.Id, CloseDate = System.today());
        insert testOppty2;

        Phase__c testPhase = new Phase__c(
            Name = 'testPhase1',
            Opportunity__c = testOppty.Id,
            Order__c = testOrder.Id,
            Status__c = 'Locked'
        );
        insert testPhase;

        Asset testAsset = new Asset(
            Name = 'TestAsset',
            AccountId = testAcc.Id,
            Quantity = 15,
            Active__c = true);
        insert testAsset;

    Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Name => 'plainApproval',
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_ENGAGE_LEGAL,
                    Approval__c.Account__c => testAcc.Id,
                    Approval__c.Opportunity__c => testOppty.Id
                }
            )
            .create()
            .getRecord();

    Triggers.switchOn();

    Test.startTest();
      Response resp = QuotingToolQuoteApexController.getTaxes(testQuote1.Id);
      QuotingToolQuoteApexController.removeTaxes(testQuote1.Id);
      QuotingToolQuoteApexController.updateQuoteBillingAddress(testQuote1.Id, testAcc.Id);
      List<Asset> assetList = QuotingToolQuoteApexController.getAssets(testAcc.Id);

      List<String> qliList = new List<String>{testQuote1.Id, testQuote2.Id};
      Map<Id, Boolean> phaseMap = QuotingToolQuoteApexController.getQliPhaseMap(qliList);

      Boolean isLocked = QuotingToolQuoteApexController.isLockedInApproval(app.Id);
        Test.stopTest();

  }

  @isTest static void testSaveQuote2(){
        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Service__c='BT Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account', RC_User_ID__c='12345');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id);
        insert testOppty;

        Pricebook2 pb = [SELECT Id FROM Pricebook2].get(0);

        Map<String, String> params = new Map<String, String>{
                'pricebook2Id'   => pb.Id,
                'opportunityId' => testOppty.Id,
                'lines'     => '20',
                'upsellStatus'   => 'Upsell',
                'isCC'   => 'Contact Center'
        };

        Test.startTest();
        String quoteId = null;
        System.runAs(salesrepUser) {

            quoteId = QuotingToolQuoteApexController.saveQuote(params);

        }
        Test.stopTest();

        System.assert(quoteId != null );
        Quote quoteResult = [SELECT Id, Pricebook2Id, ExpirationDate FROM Quote WHERE Id = :quoteId];
        System.assert(quoteResult != null );
        System.assertEquals(quoteResult.Pricebook2Id, pb.Id);
        System.assertEquals(System.today().addDays(30), quoteResult.ExpirationDate, 'Incorrect Expiration Date');
    }

    @isTest static void testSaveQuote3(){
        Triggers.switchOff();
        // Create PriceBook
        Pricebook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify', AccountId = testAcc.Id,
            CloseDate = System.today(), Brand_Name__c = OpportunityHelper.BRAND_BT_BUSINESS);
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name = 'Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote2 = new Quote(Name = 'Test Primary 2', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
            isPrimary__c = true, ExpirationDate = System.today().addDays(30));
        insert new List <Quote>{
            testQuote1, testQuote2
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Sub_Category__c = 'Main', Feature__c = 17, Family = 'Rental Phones');
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Sub_Category__c = 'Main', Charge_Term__c = 'One - Time', ExtID__c = 'test', Family = 'Global Office Rental Phones');
        insert new List<Product2>{
            testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
            Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
            standardPrice1, standardPrice2,
            testPrice1, testPrice2
        };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 1',
            UnitPrice = testPrice1.UnitPrice, Quantity = 5, QuoteId = testQuote1.Id, PricebookEntryId = testPrice1.Id,
            Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 2',
            UnitPrice = testPrice2.UnitPrice, Quantity = 5, QuoteId = testQuote2.Id, PricebookEntryId = testPrice2.Id,
            Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
        insert new List <QuoteLineItem>{
            qli1, qli2
        };

    Triggers.switchOn();

        Map<String, String> params = new Map<String, String>{
                'pricebook2Id'   => testPrBook.Id,
                'opportunityId' => testOppty.Id,
                'lines'     => '20',
                'upsellStatus'   => 'Upsell',
                'isCC'   => 'Contact Center',
                'quoteId' => testQuote2.Id,
                'recordTypeId' => QuoteHelper.RT_ID_PROSERV
        };

        Test.startTest();
        String quoteId = null;
        System.runAs(salesrepUser) {

            quoteId = QuotingToolQuoteApexController.saveQuote(params);

        }
        Test.stopTest();

        System.assert(quoteId != null );
        Quote quoteResult = [SELECT Id, Pricebook2Id, ExpirationDate FROM Quote WHERE Id = :quoteId];
        System.assert(quoteResult != null );
        System.assertEquals(quoteResult.Pricebook2Id, testPrBook.Id);
        System.assertEquals(System.today().addDays(30), quoteResult.ExpirationDate, 'Incorrect Expiration Date');
    }

  @isTest static void testGenerateQuoteDetails(){

    Triggers.switchOff();
        // Create PriceBook
        Pricebook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c = 'Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify', AccountId = testAcc.Id,
            CloseDate = System.today());
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(Name = 'Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        Quote testQuote2 = new Quote(Name = 'Test Primary 2', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id,
            isPrimary__c = true);
        insert new List <Quote>{
            testQuote1, testQuote2
        };

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Service Plan', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c = 17);
        Product2 testProduct2 = new Product2(Name = 'Some Product', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Charge_Term__c = 'One - Time', ExtID__c = 'test');
        insert new List<Product2>{
            testProduct1, testProduct2
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,
            Max_Quantity__c = 100);

        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
            standardPrice1, standardPrice2,
            testPrice1, testPrice2
        };

        // Create Quote Line Items
        QuoteLineItem qli1 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 1',
            UnitPrice = testPrice1.UnitPrice, Quantity = 5, QuoteId = testQuote1.Id, PricebookEntryId = testPrice1.Id,
            Product2Id = testProduct1.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 100);
        QuoteLineItem qli2 = new QuoteLineItem (ServiceDate = Date.today(), Description = 'TestLineItem 2',
            UnitPrice = testPrice2.UnitPrice, Quantity = 5, QuoteId = testQuote2.Id, PricebookEntryId = testPrice2.Id,
            Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0);
        insert new List <QuoteLineItem>{
            qli1, qli2
        };

    Triggers.switchOn();

        Map<String, String> params = new Map<String, String>{
                'pricebook2Id'   => testPrBook.Id,
                'opportunityId' => testOppty.Id,
                'lines'     => '20',
                'upsellStatus'   => 'Upsell',
                'isCC'   => 'Contact Center',
                'quoteId' => testQuote2.id,
                'currency' => 'USA'
        };

        Test.startTest();
        String quoteId = null;
        Map<String,Decimal> monthlyContract;
        Map<String,String> sli;
        System.runAs(salesrepUser) {

            QuotingToolQuoteApexController.generateQuoteDetails(params);
            monthlyContract = QuotingToolQuoteApexController.getMonthlyContractDiscounts(params);
            sli = QuotingToolQuoteApexController.updateListQli(new List <QuoteLineItem>{qli1, qli2});
            QuotingToolQuoteApexController.handleExtendedEnterpriseSupport(testQuote2.Id);
        }
        Test.stopTest();

        system.assert(monthlyContract != null);
        system.assert(sli != null);

    }

    @isTest static void testUpdate() {
        Map<String, String> params = new Map<String, String>();

        Triggers.switchOff();

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(Name = 'Test Opportunity', StageName='1. Qualify', AccountId = testAcc.Id,
                CloseDate = System.today());
        insert testOppty;

        // Create Products
        Product2 testProduct2 = new Product2(Name = 'Some Product 3', IsActive = true, Family = 'Overage', Sub_Category__c = 'Main', Dependent_on_Feature__c = 69, Product_Type__c = 'Seat');
        insert  testProduct2;

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice2 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct2.Id, UnitPrice = 5000, IsActive = true, UseStandardPrice = false, Per_Line__c = false);
        insert new List <PricebookEntry>{
                standardPrice2, testPrice2
        };

        // Create Entitlements
        Entitlement__c testEnt2 = new Entitlement__c(Product__c = testProduct2.Id, Account__c = testAcc.Id, Active__c = true, Quantity__c = 8);
        insert testEnt2;

        // Create Quotes
        Quote testQuote1 = new Quote(Name='Test Primary 1', Pricebook2Id = testPrBook.Id, OpportunityId = testOppty.Id);
        insert testQuote1;


        // Create Quote Line Items
        QuoteLineItem qli = new QuoteLineItem (ServiceDate = date.today(), Description = 'TestLineItem 2', UnitPrice = testPrice2.UnitPrice, Quantity = 2, QuoteId = testQuote1.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, Discount_number__c = 0, Entitlement__c = testEnt2.Id);
        insert qli;

        Triggers.switchOn();

        params.put('productId', qli.Product2Id);
        params.put('pbeId', qli.PriceBookEntryId);
        params.put('quoteId', testQuote1.Id);
        params.put(qli.Id+'%%discount', '2');
        params.put(qli.Id+'%%quantity', '2');
        params.put(qli.Id+'%%isDeactivated', 'false');

        Test.startTest();
        system.runAs(salesrepUser){
            QuotingToolQuoteApexController.updateCartItems(testQuote1.Id, params);
            Decimal qliQuantity = [SELECT Id, Quantity FROM QuoteLineItem WHERE QuoteId=:testQuote1.Id].get(0).Quantity;

            System.assertEquals(qliQuantity, 2);

            params.put(qli.Id+'%%newQuantity', '4');
            params.put(qli.Id+'%%discountType', 'Currency');
            params.put(qli.Id+'%%provisionedByInContact', 'true');
            params.put(qli.Id+'%%quantity', '4');
            QuotingToolQuoteApexController.updateCartItems(testQuote1.Id, params);
        }
        Test.stopTest();

    }

    @isTest
    static void testSoldProServQuote2() {

        Account testAcc = new Account(
                Name = 'testAcc'
        );
        insert testAcc;

        Opportunity opp = new Opportunity(
                Name = 'MyTestOpportunity',
                AccountId = testAcc.Id,
                StageName = '1. Qualify'
        );
        insert opp;

        Quote testQuote = new Quote(
                OpportunityId = opp.Id,
                Name = 'testProServQuote'
        );
        insert testQuote;

        Test.startTest();
            try{
                QuotingToolQuoteApexController.soldProServQuote(testQuote.Id);

                Quote reselectedQuote = [SELECT Id, ProServ_Status__c, ProServ_Sold_Date__c FROM Quote WHERE Id = :testQuote.Id];

                System.assertEquals(QuoteHelper.PROSERVSTATUS_SOLD, reselectedQuote.ProServ_Status__c);
                System.assertNotEquals(null, reselectedQuote.ProServ_Sold_Date__c);
            } catch (Exception e) {
                System.assert(e.getMessage().containsIgnoreCase('bad value'), e.getMessage());
            }


        Test.stopTest();
    }

    @isTest static void testSyncProServOneTimeChargeTerm2() {
        createTestData_testSyncProServ();
        testProduct1.Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME;
        update testProduct1;
        Test.startTest();

        QuotingToolQuoteApexController.syncProServWithSales(testOpportunity.Id, false, QuotingToolQuoteApexController.CC_PROSERV);

        Test.stopTest();

        List<QuoteLineItem> resultQLIs = [
                SELECT Id, QuoteId, Quantity, PricebookEntryId
                FROM QuoteLineItem
                WHERE quoteId = :testCCProServQuote.Id
                ORDER BY Product2.Name ASC
        ];

        // Check sync
        // testProduct1 will be skipped, testProduct2 will be synced with Primary Quote
        System.assertEquals(2, resultQLIs.size(), 'Works incorrectly with products of Charge Term "One - Time"');
    }



    @isTest
    static void testGetFreeServiceTaxes() {
        CreateTestData(Test.getStandardPricebookId(), 20, 'NA', '1-9999999', '1-25', '26-50', '51-100', '101-9999999', '1234');

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setField(CountryCodes__c.CountryName__c, 'usa;united states')
            .setField(CountryCodes__c.Name, 'USA')
            .create();

        Contact_Center_FSC__c ccFscSettings = Contact_Center_FSC__c.getOrgDefaults();
        ccFscSettings.Taxes_Endpoint__c = 'testendpoint';
        upsert ccFscSettings Contact_Center_FSC__c.Id;

        List<Product2> products = new List<Product2>();
        for (Product2 product : [SELECT Avalara_Service_Type__c, Avalara_Transaction_Type__c FROM Product2]) {
            product.Avalara_Service_Type__c = 6;
            product.Avalara_Transaction_Type__c = 59;
            product.RC_Tax_Category__c = 'VoIP Service';
            products.add(product);
        }
        update products;

        testAccount.BillingCity = 'New York';
        testAccount.BillingState = 'NY';
        testAccount.BillingPostalCode = '10013';
        testAccount.BillingCountry = 'USA';
        update testAccount;

        Test.setMock(HttpCalloutMock.class, new TaxesHttpCalloutMock());
        Test.startTest();
        QuotingToolQuoteApexController.TaxesAmountWrapper taxesAmount = QuotingToolQuoteApexController.getFreeServiceTaxes(testQuote.Id);
        Test.stopTest();

        Decimal expectedFixedAmount = 3683.01;
        Decimal expectedVariableAmount = 288.71;
        System.assertEquals(taxesAmount.fixedTaxesAmount, expectedFixedAmount);
        System.assertEquals(taxesAmount.variableTaxesAmount, expectedVariableAmount);
    }

    @isTest
    static void testUpdateCC_FSC_QuoteWithQLIsWithoutTerms() {
        CreateTestData(Test.getStandardPricebookId(), 20, 'NA', '1-9999999', '1-25', '26-50', '51-100', '101-9999999', '1234');
        testQuote.Special_Terms__c = '';

        testQuoteLineItem.FSC_Line_Tax_Amount__c = 100;
        testQuoteLineItem.FSC_Line_Amount__c = 200;
        update testQuoteLineItem;

        Test.startTest();
        QuotingToolQuoteApexController.updateCC_FSC_QuoteWithQLIs(testQuote, '');
        Test.stopTest();

        List<QuoteLineItem> qlis = [SELECT FSC_Line_Tax_Amount__c, FSC_Line_Amount__c FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];
        for (QuoteLineItem qli : qlis) {
            System.assertEquals(qli.FSC_Line_Tax_Amount__c, 0);
            System.assertEquals(qli.FSC_Line_Amount__c, 0);
        }
    }

    @isTest
    static void testUpdateCC_FSC_QuoteWithQLIsWithTerms() {
        CreateTestData(Test.getStandardPricebookId(), 20, 'NA', '1-9999999', '1-25', '26-50', '51-100', '101-9999999', '1234');
        String jsonResponse = '{"responseData":{"userId":"400131698004","quoteId":"' + testQuote.Id + '","status":"success","message":" ","itemList":[{"taxData":[{"taxType":161,"taxLevel":2,"taxAmount":43.0,"TaxableMeasure":0.0,"rate":1.0,"description":"E911 (VoIP)","categoryId":7,"categoryDescription":"E-911 CHARGES"}],"RCTaxType":"Fixed","lineStatus":"Success","lineMessage":" ","lineId":"' + testQuoteLineItem.Id + '"}]},"requestType":"quote","responseTimestamp":"2021-04-23 02:28:20"}';
        testQuote.Special_Terms__c = '2 Free Month of Service';
        testQuote.Taxes_Response__c = jsonResponse;

        Test.startTest();
        QuotingToolQuoteApexController.updateCC_FSC_QuoteWithQLIs(testQuote, jsonResponse);
        Test.stopTest();

        List<QuoteLineItem> qlis = [SELECT FSC_Line_Tax_Amount__c, FSC_Line_Amount__c FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];
        for (QuoteLineItem qli : qlis) {
            System.assertEquals(86, qli.FSC_Line_Tax_Amount__c);
            System.assertEquals(0, qli.FSC_Line_Amount__c);
        }
    }

    /**
     * Test Engagement Process
     * ProServ + CC ProServ
     */
    @isTest static void testEngageProServ_Vodafone() {
        Triggers.switchOff();
        // Create Brand
        schedulerConfiguration__c testBrand = new schedulerConfiguration__c(Name = 'Vodafone Business with RingCentral');
        insert testBrand;

        // Create PriceBook
        PriceBook2 testPriceBook = new Pricebook2(
            Name = 'Test Price Book',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c='Office',
            Plan__c = 'Monthly',
            ExtId__c = 'ProServ_Universal_USD'
        );
        insert testPriceBook;

        PriceBook2 testPriceBook2 = new Pricebook2(
            Name = 'Test Service Billing ProServ',
            Description ='Test Price Book Products',
            IsActive = true,
            Line_Range_Min__c = 5,
            Service__c = 'Office',
            Plan__c = 'Monthly',
            ExtId__c = 'CC_ProServ_Universal_USD'
        );
        insert testPriceBook2;

        // create Account
        testAccount = new Account(Name='Opty test account', Number_of_DL_s__c = 20);
        insert testAccount;

        // create Opportunity
        testOpportunity = new Opportunity(Name = 'Test Opportunity ProServ', Brand_Name__c = testBrand.Name,
                StageName = '1. Qualify', CloseDate = system.today(), AccountId = testAccount.Id,
                Number_of_Employees__c = '20', Forecasted_Users__c = 20);
        insert testOpportunity;

        // Create Quote
        testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpportunity.id ,
                Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 10);
        insert testQuote;




        String testDetails1 = 'First Engagement Details';
        String testDetails2 = 'Second Engagement Details';
        List<Quote> resultProServQuotes1 = new List<Quote>();
        List<Quote> resultCCProServQuotes1 = new List<Quote>();
        List<Quote> resultProServQuotes2 = new List<Quote>();
        List<Quote> resultCCProServQuotes2 = new List<Quote>();

        System.runAs(salesrepUser) {

            Triggers.switchOn();

            // Engage Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails1, QuotingToolQuoteApexController.PROSERV, false);
            resultProServQuotes1 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_PROSERV
            ];

            // Engage Contact Center Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails1, QuotingToolQuoteApexController.CC_PROSERV, false);
            resultCCProServQuotes1 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
            ];

            // Check if Quotes Created
            System.assertEquals(1, resultProServQuotes1.size(), 'ProServ Quote should be created');
            System.assertEquals(1, resultCCProServQuotes1.size(), 'CC ProServ Quote should be created');

            Quote proServQuote1 = resultProServQuotes1.get(0);
            Quote ccProServQuote1 = resultCCProServQuotes1.get(0);

            // Check Pricebook
            System.assertEquals(testPriceBook.Id, proServQuote1.Pricebook2Id, 'ProServ Quote should have Same Service Plan as Primary Quote');
            System.assertEquals(testPriceBook.Id, ccProServQuote1.Pricebook2Id, 'CC ProServ Quote should have Same Service Plan as Primary Quote');

            // Check ProServ Details
            System.assertEquals(testDetails1, proServQuote1.ProServ_Details__c, 'ProServ details should be populated');
            System.assertEquals(testDetails1, ccProServQuote1.ProServ_Details__c, 'CC ProServ details should be populated');

            // Check ProServ Status
            final List<String> PROSERV_STATUSES_AFTER_CREATE = new List<String>{QuoteHelper.PROSERVSTATUS_CREATED, QuoteHelper.PROSERVSTATUS_IN_PROGRESS};
            System.assert(PROSERV_STATUSES_AFTER_CREATE.contains(proServQuote1.ProServ_Status__c), 'Default ProServ Status should be set');
            System.assert(PROSERV_STATUSES_AFTER_CREATE.contains(proServQuote1.ProServ_Status__c), 'Default CC ProServ Status should be set');


            // Check Engagement when ProServ has been cancelled
            Triggers.switchOff();

            proServQuote1.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            ccProServQuote1.ProServ_Status__c = QuoteHelper.PROSERVSTATUS_CANCELLED;
            update new List<Quote>{ proServQuote1, ccProServQuote1 };

            Triggers.switchOn();
            Test.startTest();
            // Engage Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails2, QuotingToolQuoteApexController.PROSERV, false);
            resultProServQuotes2 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_PROSERV
            ];

            // Engage Contact Center Professional Services
            QuotingToolQuoteApexController.engageProServ(testOpportunity.Id, testAccount.Id, testDetails2, QuotingToolQuoteApexController.CC_PROSERV, false);
            resultCCProServQuotes2 = [
                    SELECT Id, Name, Pricebook2Id, ProServ_Details__c, ProServ_Status__c
                    FROM Quote
                    WHERE OpportunityId = :testOpportunity.id
                    AND RecordTypeId = :QuoteHelper.RT_ID_CC_PROSERV
            ];

            // Check that no new quote has been created
            System.assertEquals(1, resultProServQuotes2.size());
            System.assertEquals(1, resultCCProServQuotes2.size());

            Quote proServQuote2 = resultProServQuotes2.get(0);
            Quote ccProServQuote2 = resultCCProServQuotes2.get(0);

            System.assertEquals(proServQuote1.Id, proServQuote2.Id, 'ProServ Quote should be the same');
            System.assertEquals(ccProServQuote1.Id, ccProServQuote2.Id, 'ProServ Quote should the same');

            // Check ProServ Details
            System.assertEquals(testDetails2, proServQuote2.ProServ_Details__c, 'ProServ details should be populated');
            System.assertEquals(testDetails2, ccProServQuote2.ProServ_Details__c, 'CC ProServ details should be populated');

            // Check ProServ Status
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, proServQuote2.ProServ_Status__c, 'Default ProServ Status should be set');
            System.assertEquals(QuoteHelper.PROSERVSTATUS_CREATED, ccProServQuote2.ProServ_Status__c, 'Default CC ProServ Status should be set');

        }

        Test.stopTest();

    }

    @IsTest
    private static void testParseRequestParametersToQuoteForUpdatingTargetPriceContactCenterARR() {
        final Id MOCK_ID = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();
        final Integer CC_ARR = 1000;

        Map<String, Object> ccQuoteParams = new Map<String, Object>{
            'id' => MOCK_ID,
            'opportunityId' => MOCK_ID,
            'targetPriceContactCenterARR' => CC_ARR
        };

        Test.startTest();
            Quote resultQuote = QuotingToolQuoteApexController.parseRequestParametersToQuoteForUpdatingTargetPriceContactCenterARR(ccQuoteParams);
        Test.stopTest();

        System.assertEquals(MOCK_ID, resultQuote.Id,
            'Id should be correctly parsed from params');
        System.assertEquals(MOCK_ID, resultQuote.OpportunityId,
            'OpportunityId should be correctly parsed from params');
        System.assertEquals(CC_ARR, resultQuote.TargetPriceContactCenterARR__c,
            'CC ARR should be correctly parsed from params');
    }

    @IsTest
    private static void testFailedParseRequestParametersToQuoteForUpdatingTargetPriceContactCenterARR() {

        Map<String, Object> ccQuoteParams = new Map<String, Object>{
            'id' =>  ValueProviderBuilder.provideUniqueString(),
            'opportunityId' => ValueProviderBuilder.provideUniqueString(),
            'targetPriceContactCenterARR' => ValueProviderBuilder.provideUniqueDecimal()
        };

        Test.startTest();
            Quote resultQuote = QuotingToolQuoteApexController.parseRequestParametersToQuoteForUpdatingTargetPriceContactCenterARR(ccQuoteParams);
        Test.stopTest();

        System.assertEquals(null, resultQuote,
            'Quote can\'t be build with wrong values');
    }

    @IsTest
    private static void testUpdateTargetPriceContactCenterARR() {
        final Integer CC_ARR = 1000;

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                    Opportunity.AccountId => testAccount.Id})
            .create()
            .getRecord();

        Triggers.switchOff();
        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                Quote.OpportunityId => testOpportunity.Id,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{false, true}
                )
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        Id ccQuoteId = testQuotes[0].Id;

        Map<String, Object> ccQuoteParams = new Map<String, Object>{
            'id' => ccQuoteId,
            'opportunityId' => testOpportunity.Id,
            'targetPriceContactCenterARR' => CC_ARR
        };

        Test.startTest();
            QuotingToolQuoteApexController.updateTargetPriceContactCenterARR(ccQuoteParams);
        Test.stopTest();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .selectFields(new List<SObjectField>{
                Quote.TargetPriceContactCenterARR__c
            })
            .executeQuery();

        Quote selectedCCQuote = !quotes.get(0).isPrimary__c
            ? quotes.get(0)
            : quotes.get(1);
        Quote selectedPrimaryQuote = quotes.get(0).isPrimary__c
            ? quotes.get(0)
            : quotes.get(1);

        System.assertEquals(CC_ARR, selectedCCQuote?.TargetPriceContactCenterARR__c,
            'Target Price CC ARR should be updated');
    }

    @IsTest
    static void testCreatePSCase() {
        BillingWrappers.CaseCreateParams params = new BillingWrappers.CaseCreateParams();
        params.subject = 'subject';
        params.accountId = (String) ValueProviderBuilder.provideCommonParent(Account.SObjectType).getValue();
        params.contactId = (String) ValueProviderBuilder.provideCommonParent(Contact.SObjectType).getValue();
        params.description = 'Description';
        params.opportunityOwnerEmail = 'test@test.com';
        params.isFromProServ = true;
        String serializedParams = JSON.serialize(params);

        Test.startTest();
            QuotingToolQuoteApexController.createPSCase(serializedParams);
            List<Case> cases = new CaseSelector().selectCasesDefault().executeQuery();
        Test.stopTest();
        System.assertEquals(
            1,
            cases.size(),
            'Case was created'
        );
    }

    @isTest
    static void testEnableLBOForPrimaryQuote() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                Opportunity.AccountId => acc.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .create()
            .getRecord();

        List<Quote> testQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(
                    new List<Boolean>{false, true}
                )
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            QuotingToolQuoteApexController.enableLBOForPrimaryQuote(opp.Id);
        Test.stopTest();

        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotesByOppIds(new List<Id> {opp.Id})
            .selectFields(new List<String>{'Enabled_LBO__c'})
            .executeQuery();

        Quote reselectedPrimaryQuote = QuoteHelper.getPrimaryQuote(quotes, opp.Is_Billing_Opportunity__c);

        for (Quote qt : quotes) {
            if (qt.isPrimary__c) {
                System.assertEquals(
                    true,
                    qt.Enabled_LBO__c,
                    'Enabled_LBO__c for primary quote should be true when proserv was engaged'
                );
            } else {
                System.assertEquals(
                    false,
                    qt.Enabled_LBO__c,
                    'Enabled_LBO__c for non primary quote should be false when proserv was engaged'
                );
            }
        }
    }

    @isTest
    static void testDeleteQlisDuringEngageCancelledProServQuote() {
       	Pricebook2 testProservPricebook = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Pricebook2.Name => 'ProServ GBP',
                Pricebook2.IsActive => true,
                Pricebook2.ExtID__c => 'Test_ProServ_GBP',
                Pricebook2.CurrencyIsoCode => RingCentralHelper.GBP
            })
            .create()
            .getRecord();

        new SObjectBuilder(PriceBookAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBookAssignments__c.Name => ValueProviderBuilder.provideUniqueString('test_setting_'),
                PriceBookAssignments__c.Active__c => true,
                PriceBookAssignments__c.BrandName__c => OpportunityHelper.BRAND_AVAYA,
                PriceBookAssignments__c.SubBrandName__c => null,
                PriceBookAssignments__c.PSPriceBookExtID__c => testProservPricebook.ExtID__c,
                PriceBookAssignments__c.Currency__c => RingCentralHelper.GBP
            })
            .create();

       Account testAcc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => testAcc.Id,
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA
            })
            .create()
            .getRecord();

        PriceBook2 testPriceBook = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
                PriceBook2.Description => ValueProviderBuilder.provideUniqueString(),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => ValueProviderBuilder.provideUniqueNumber(1),
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => testOpp.Id,
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.IsPrimary__c => true,
                Quote.PriceBook2Id => testPriceBook.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString(),
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        List<PricebookEntry> testPricebookentries = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id =>  ValueProviderBuilder.provideList(new List<Id> {
                    Test.getStandardPriceBookId(),
                    testPriceBook.Id
                }),
                PricebookEntry.Product2Id => testProduct.Id,
                PricebookEntry.UnitPrice => ValueProviderBuilder.provideUniqueNumber(100),
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => testProduct.Id,
                QuoteLineItem.QuoteId => proServQuote.Id,
                QuoteLineItem.PricebookEntryId => testPricebookentries[1].Id,
                QuoteLineItem.UnitPrice => testPricebookentries[1].UnitPrice,
                QuoteLineItem.Quantity => ValueProviderBuilder.provideUniqueNumber(2),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideUniqueNumber(2),
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create();

        Test.startTest();
            QuotingToolQuoteApexController.engageProServProcess(
                testOpp.Id,
                testAcc.Id,
                'testDetails',
                QuotingToolQuoteApexController.PROSERV
            );
        Test.stopTest();

        List<Quote> reselectedQuotes = (List<Quote>) new QuoteSelector()
            .selectQuotesForDQSync(new Set<Id>{proServQuote.Id})
            .executeQuery();

        Assert.areEqual(0, reselectedQuotes[0].QuoteLineItems.size(), 'QuoteLineItems should be deleted');
    }
}