@isTest
private class Test_OpportunityCreationFormController
{

    @isTest
    static void testCreations()
    {
        Triggers.switchOff();

        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPriceBook;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Product2 testProduct1 = new Product2(Name = 'Test Softphone', IsActive = true, Sub_Category__c = 'Main',
                Feature__c = 11, Sub_Feature__c = -1, Family = 'Discounted Phones');
        insert testProduct1;


        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct1.Id, UnitPrice = 0, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook.Id,
                Product2Id = testProduct1.Id, UnitPrice = 0, IsActive = true, UseStandardPrice = false);
        insert new List<PricebookEntry>{
                standardPrice1, testPrice1
        };

        String recordTypeId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName()
                .get('New Sales Opportunity').getRecordTypeId();

        Contact testContact1 = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        insert testContact1;

        Area_Codes__c ac = new Area_Codes__c(
            Name = '123',
            Area_Code__c = 123
        );
        insert ac;

            // Given
        Boolean isBil = false;
        Map < String, String > opptyParams = new Map < String, String > {
                'name'              =>'Test',
                'closeDate'         => String.valueOf(Date.today()),
                'stageName'         => '1. Qualify',
                'recordTypeId'      => recordTypeId,
                'forecastedUsers'   =>'0',
                'isBillingOpportunity' => String.valueOf(false),
                'contactId'         => testContact1.Id,
                'contactRole'       => 'Signatory'
        };

        Map < String, String > quoteParams = new Map < String, String > {
                'tierId'=> testPriceBook.Id,
                'lines' => '1',
                'mainAreaCodeId' => ac.Id
        };

        //When
        Triggers.switchOn();
        Test.startTest();

        Map < String, String > opptyResult = OpportunityCreationFormController.createOppty(opptyParams);

        quoteParams.put('opportunityId', opptyResult.get('opportunityId'));
        Map < String, String > quoteResult = OpportunityCreationFormController.createQuote(quoteParams);

        OpportunityCreationFormController.createAdditionalSoftphoneQLIs( new Map<String, String>{
            'quoteId'       => quoteResult.get('quoteId'),
            'quantity'      => '5',
            'pricebook2Id'  => testPriceBook.Id
        });

        Test.stopTest();

        //Then
        System.assertEquals(opptyResult.get('status'), 'success');
        System.assertEquals(quoteResult.get('status'), 'success');

        Opportunity createdOpportunity = [SELECT Id, (SELECT Id, AreaCode__c, FaxAreaCode__c FROM Quotes) FROM Opportunity];
        System.assertEquals(opptyResult.get('opportunityId'), createdOpportunity.Id);
        System.assertEquals(createdOpportunity.Quotes.size(), 1);
        Quote createdQuote = createdOpportunity.Quotes.get(0);
        System.assertEquals(quoteResult.get('quoteId'),createdQuote.Id );
        System.assertEquals(ac.Id, createdQuote.AreaCode__c);
        System.assertEquals(ac.Id, createdQuote.FaxAreaCode__c);
        System.assertEquals(1,[SELECT COUNT() FROM OpportunityContactRole WHERE Role = :opptyParams.get('contactRole')]);

        Integer softphonesNumber = [SELECT COUNT() FROM QuoteLineItem WHERE PricebookEntryId = :testPrice1.Id];
        System.assertEquals(1, softphonesNumber );

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testController()
    {
        Triggers.switchOff();
        // Create Test Data
        Account testAcc = new Account(Name='Test Account');
        insert testAcc;

        Contact testContact = new Contact(
                AccountId = testAcc.Id,
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'johnDoe@example.tld'
        );
        insert testContact;

        Id recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' LIMIT 1].get(0).Id;
        Opportunity testOpp = new Opportunity (RecordTypeId = recordTypeId);

        // Init Controller
        PageReference OpportunityCreationFormPage = Page.OpportunityCreationForm;
        Test.setCurrentPage(OpportunityCreationFormPage);

        // Set Controller Params
        ApexPages.currentPage().getParameters().put('accid', testAcc.Id);
        ApexPages.currentPage().getParameters().put('conid', testContact.Id);
        ApexPages.currentPage().getParameters().put('RecordType', recordTypeId);
        ApexPages.currentPage().getParameters().put('fromContact', '1');
        ApexPages.currentPage().getParameters().put('fromContactId', testContact.Id);
        ApexPages.currentPage().getParameters().put('contactCenterUsers', '10');
        ApexPages.currentPage().getParameters().put('engageDigitalUsers', '20');
        ApexPages.currentPage().getParameters().put('engageVoiceUsers', '30');
        ApexPages.currentPage().getParameters().put('globalOfficeUsers', '40');
        ApexPages.currentPage().getParameters().put('officeUsers', '50');
        ApexPages.currentPage().getParameters().put('rcVideoUsers', '60');
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);

        // When
        Test.startTest();
        OpportunityCreationFormController ctr = new OpportunityCreationFormController(sc);
        OpportunityCreationFormController.checkRecordType();
        Test.stopTest();

        // Then
    }

    @isTest
    static void testAddEntitlementsAsLineItems(){

        //Create Account
        Account testAccount = new Account( Name = 'Test Account');
        insert testAccount;

        // Create PriceBook
        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
                IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPriceBook;

        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
                CloseDate = System.today(), AccountId = testAccount.Id);
        insert testOpportunity;

        // Create Quote
        Quote testQuote = new Quote (Name = 'Test Quote', OpportunityId = testOpportunity.Id,
            Pricebook2Id = testPriceBook.id,
            RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert testQuote;

        // Create Products
        Product2 testProduct1 = new Product2(Name = 'Test Softphone', IsActive = true, Sub_Category__c = 'Main',
                Feature__c = 11, Sub_Feature__c = -1, Family = 'Discounted Phones',
                Cart_Tab_Availability__c = QuoteHelper.RT_NAME_SALES);
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
        Entitlement__c testEntitlement1 = new Entitlement__c( Account__c = testAccount.Id,
                Product__c = testProduct1.Id, Active__c = true, Quantity__c = 5);
        insert new List<Entitlement__c>{
                testEntitlement1
        };

        Test.startTest();
        List<QuoteLineItem> createdQuoteLineItems = OpportunityCreationFormController.addEntitlementsAsLineItems(new Map<String, String>{
                'quoteId' => testQuote.Id,
                'additionalForecastedUsers' => '10'
        });
        Test.stopTest();

        System.assertEquals(1,createdQuoteLineItems.size());

    }

    @isTest
    static void testGetTaskUrl() {
        Triggers.switchOff();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
                AccountId = testAccount.Id,
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'johnDoe@example.tld'
        );
        insert testContact;

        Task tsk = new Task();
        tsk.WhoId = testContact.Id;
        insert tsk;
        Triggers.switchOn();

        String result = OpportunityCreationFormController.getUrlForTask(testContact.Id, tsk.Id);

        Map<String, String> resMap = (Map<String, String>) JSON.deserialize(result, Map<String, String>.class);

        Map <String, Schema.RecordTypeInfo> mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
        Id rtId = mapRT.get('New Sales Opportunity').getRecordTypeId();

        String checkUrl = '/apex/OpportunityCreationForm?RecordType=' + rtId +
                '&ent=Opportunity&save_new=1&sfdc.override=1&taskId=' + tsk.Id +'&accid=' + testAccount.Id +
                '&conid=' + testContact.Id;

        System.assertEquals(checkUrl, resMap.get('redirectUrl'));
        System.assertEquals('success', resMap.get('status'));

        result = OpportunityCreationFormController.getUrlForTask(null, null);
        resMap = (Map<String, String>) JSON.deserialize(result, Map<String, String>.class);

        System.assertEquals('success', resMap.get('status'));
    }

    @isTest
    static void testGetRetentionUrl() {
        Triggers.switchOff();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johnDoe@example.tld'
        );
        insert testContact;

        String result = OpportunityCreationFormController.getUrlForRetention((String)testAccount.Id);

        Map<String, String> resMap = (Map<String, String>) JSON.deserialize(result, Map<String, String>.class);

        Map <String, Schema.RecordTypeInfo> mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
        Id rtId = mapRT.get('New Sales Opportunity').getRecordTypeId();

        String checkUrl = '/apex/OpportunityCreationForm?RecordType=' + rtId + '&ent=Opportunity&save_new=1&sfdc.override=1' +
            '&accid=' + testAccount.Id;

        System.assertEquals(checkUrl, resMap.get('redirectUrl'));
        System.assertEquals('success', resMap.get('status'));

        result = OpportunityCreationFormController.getUrlForRetention(null);
        resMap = (Map<String, String>) JSON.deserialize(result, Map<String, String>.class);

        System.assertEquals('success', resMap.get('status'));
    }

    @isTest
    static void testUpdateTask() {
        Triggers.switchOff();
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
                AccountId = testAccount.Id,
                FirstName = 'John',
                LastName = 'Doe',
                Email = 'johnDoe@example.tld'
        );
        insert testContact;

        Task tsk = new Task();
        tsk.WhoId = testContact.Id;
        insert tsk;

        Map <String, Schema.RecordTypeInfo> mapRT = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
        Id rtId = mapRT.get('New Sales Opportunity').getRecordTypeId();

        Opportunity opp = new Opportunity(
                Name='Test Opportunity',
                CurrencyIsoCode='USD',
                AccountId=testAccount.Id,
                StageName='4. Proof',
                RecordTypeId= rtId,
                Primary_Opportunity_Contact__c = testContact.Id,
                Tier_Name__c='Fax1000',
                Brand_Name__c='RingCentral',
                Forecasted_Users__c=23,
                CloseDate = System.today()
        );
        insert opp;

        Triggers.switchOn();

        Map<String, String> params = new Map<String, String>();
        params.put('taskId', tsk.Id);
        params.put('opportunityId', opp.Id);

        OpportunityCreationFormController.updateTask(params);

        tsk = [SELECT WhoId, WhatId, Id FROM Task WHERE Id = :tsk.Id];

        System.assertEquals(opp.Id, tsk.WhatId);
    }

    @isTest static void testGetProducts(){
        // Create Custom setting
        upsert new List<OpportunityCreationProductsAvailability__c>{
            new OpportunityCreationProductsAvailability__c(
                Name = '1',
                Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Family__c = 'TEST Family'
            ),
            new OpportunityCreationProductsAvailability__c(
                Name = '2',
                Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Family__c = 'TEST2'
            ),
            new OpportunityCreationProductsAvailability__c(
                Name = '3',
                Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Family__c = 'TEST Family'
            ),
            new OpportunityCreationProductsAvailability__c(
                Name = '4',
                Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Family__c = 'TEST2'
            )
        };

        // Create Products
        List <Product2> testProds = new List <Product2>();

        Product2 testProd1 = new Product2(Name = 'Test product 1', IsActive = true);
        testProds.add(testProd1);

        Product2 testProd2 = new Product2(Name = 'Test product 2', IsActive = true, Family = 'TEST Family', Sub_Category__c = Product2Helper.SUBCATEGORY_RINGCENTRAL, Charge_Term__c = Product2Helper.CHARGE_TERM_ONE_TIME);
        testProds.add(testProd2);
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
        insert testPbes;


        Test.startTest();
        List <PricebookEntry> getProductsResult = OpportunityCreationFormController.getProducts(testPrBook.Id, OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY);
        Test.stopTest();

        System.assertEquals(1, getProductsResult.size(), 'There should be only filtered products returned');
    }

    private static Map<String, Id> prepareAddProductsData(){
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
        Product2 testProduct1 = new Product2(Name = 'Some Product 1', IsActive = true, Family = 'RingCentral', Sub_Category__c = 'Main', Feature__c = 99);
        insert new List<Product2>{
            testProduct1
        };

        // Create Price Book Entries
        String stdPriceBookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = stdPriceBookId, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
        PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPrBook.Id, Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 1,  Max_Quantity__c = 100);
        insert new List <PricebookEntry>{
            standardPrice1,
            testPrice1
        };

        return new Map<String, Id>{
            'testQuote1Id' => testQuote1.Id,
            'testPrice1Id' => testPrice1.Id
        };
    }

    @isTest static void testAddProducts(){
        Triggers.switchOff();

        Map<String, Id> data = prepareAddProductsData();

        Triggers.switchOn();

        String quoteId = '"quoteId":"' + data.get('testQuote1Id') + '"';

        String product1Pricebook = '"pricebookEntryId":"' + data.get('testPrice1Id') + '"';
        String product1Quantity = '"quantity":2';
        String product1AreaCodes = '"areaCodesToAdd":[]';
        String product1 = '{' + product1Pricebook + ', ' + product1Quantity + ', ' + product1AreaCodes + '}';

        String p = '{' + quoteId + ', "productsToAdd":[' + product1 + ']}';

        Test.startTest();
        OpportunityCreationFormController.addProductsWrapper(p);
        Test.stopTest();

        List<QuoteLineItem> result = [
            SELECT Id, Quantity, NewQuantity__c
            FROM QuoteLineItem
            WHERE QuoteId = :data.get('testQuote1Id')
        ];
        System.assertEquals(1, result.size());

        QuoteLineItem qli = result.get(0);
        System.assertEquals(2, qli.Quantity);
        System.assertEquals(2, qli.NewQuantity__c);
    }

    @isTest static void testAddProductsWithAreaCodes(){
        Triggers.switchOff();

        Map<String, Id> data = prepareAddProductsData();
        Area_Codes__c areaCode = new Area_Codes__c(
            Name = '999',
            Area_Code__c = 999,
            City__c = 'TestCity',
            State_Abbreviation__c = 'ST',
            StateID__c = 99
        );
        insert areaCode;

        Triggers.switchOn();

        String quoteId = '"quoteId":"' + data.get('testQuote1Id') + '"';

        String product1Pricebook = '"pricebookEntryId":"' + data.get('testPrice1Id') + '"';
        String product1Quantity = '"quantity":2';
        String product1AreaCodes = '"areaCodesToAdd":[{"areaCodeId":"' + areaCode.Id + '", "quantity":2}]';
        String product1 = '{' + product1Pricebook + ', ' + product1Quantity + ', ' + product1AreaCodes + '}';

        String p = '{' + quoteId + ', "productsToAdd":[' + product1 + ']}';

        Test.startTest();
        OpportunityCreationFormController.addProductsWrapper(p);
        Test.stopTest();

        List<QuoteLineItem> QLIresult = [
            SELECT Id, Quantity, NewQuantity__c
            FROM QuoteLineItem
            WHERE QuoteId = :data.get('testQuote1Id')
        ];
        System.assertEquals(1, QLIresult.size());

        QuoteLineItem qli = QLIresult.get(0);
        System.assertEquals(2, qli.Quantity);
        System.assertEquals(2, qli.NewQuantity__c);

        List<Area_Code_Line_Item__c> ACLIresult = [
            SELECT Id, Name, Quote_Line_Item__c, Quantity__c, Area_Code__c
            FROM Area_Code_Line_Item__c
        ];
        System.assertEquals(1, ACLIresult.size());

        Area_Code_Line_Item__c acli = ACLIresult.get(0);
        System.assertEquals(2, acli.Quantity__c);
        System.assertEquals(qli.Id, acli.Quote_Line_Item__c);
        System.assertEquals(areaCode.Id, acli.Area_Code__c);
    }

    @isTest static void testAddProductsByFeatureConfiguration() {
        Triggers.switchOff();

        Map<String, Id> data = prepareAddProductsData();
        Area_Codes__c areaCode = new Area_Codes__c(
            Name = '999',
            Area_Code__c = 999,
            City__c = 'TestCity',
            State_Abbreviation__c = 'ST',
            StateID__c = 99
        );
        insert areaCode;

        Triggers.switchOn();

        String quoteId = '"quoteId":"' + data.get('testQuote1Id') + '"';

        String p = '{' + quoteId + ', "productsToAdd":[], "featureToQuantityMap": {"99":2}}';

        Test.startTest();
        OpportunityCreationFormController.addProductsWrapper(p);
        Test.stopTest();

        List<QuoteLineItem> QLIresult = [
            SELECT Id, Quantity, NewQuantity__c, Product2.Feature__c
            FROM QuoteLineItem
            WHERE QuoteId = :data.get('testQuote1Id')
        ];
        System.assertEquals(1, QLIresult.size());

        QuoteLineItem qli = QLIresult.get(0);
        System.assertEquals(2, qli.Quantity);
        System.assertEquals(2, qli.NewQuantity__c);
        System.assertEquals(99, qli.Product2.Feature__c);
    }

    @isTest static void testConfirmAndCloseOppty() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c(ModifiedCloseOpportunityFlow__c = true);
        insert featureToggle;

        // Create PriceBook
        PriceBook2 testPrBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
            IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
        insert testPrBook;

        // Create Account
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        // Create Opportunity
        Opportunity testOppty = new Opportunity(
            Name = 'Test Opportunity',
            StageName='1. Qualify',
            AccountId = testAcc.Id,
            CloseDate = System.today(),
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            Total_MRR__c = 1
        );
        insert testOppty;

        // Create Quotes
        Quote testQuote1 = new Quote(
            Name='Test Primary 1',
            Pricebook2Id = testPrBook.Id,
            OpportunityId = testOppty.Id,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE,
            RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert new List <Quote> {
            testQuote1
        };

        Test.startTest();
        OpportunityCreationFormController.confirmAndCloseOppty(testOppty.Id, testQuote1.Id);
        Test.stopTest();

        Quote quoteResult = [
            SELECT Id, Status, Opportunity.ConfirmAndClose__c, Opportunity.StageName
            FROM Quote
            WHERE Id = :testQuote1.Id
        ];

        System.assertEquals(QuoteHelper.QUOTE_STATUS_PRESENTED, quoteResult.Status);
        System.assertEquals(OpportunityHelper.STAGE_NAME_ORDER, quoteResult.Opportunity.StageName);
        System.assertEquals(true, quoteResult.Opportunity.ConfirmAndClose__c);
    }

    @isTest static void testContactRoleRoleUpdate() {
        Account testAcc = TestDataGenerator.createAccount('TestAcc');
        Contact testContact1 = new Contact(
            AccountId = testAcc.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        insert testContact1;

        String recordTypeId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName()
                .get('New Sales Opportunity').getRecordTypeId();

        Map < String, String > opptyParams = new Map < String, String > {
                'name'              =>'Test',
                'closeDate'         => String.valueOf(Date.today()),
                'stageName'         => '1. Qualify',
                'recordTypeId'      => recordTypeId,
                'forecastedUsers'   =>'0',
                'isBillingOpportunity' => String.valueOf(false),
                'contactId'         => testContact1.Id,
                'contactRole'       => 'Signatory'
        };

        Test.startTest();
            Map < String, String > opptyResult = OpportunityCreationFormController.createOppty(opptyParams);
        Test.stopTest();

        List<OpportunityContactRole> ocrList = [
            SELECT Role
            FROM OpportunityContactRole
            WHERE contactId = :testContact1.Id
        ];

        System.assertEquals(1, ocrList.size());
        System.assertEquals(OpportunityHelper.CONTACT_ROLE_SIGNATORY, ocrList[0].Role);
    }

    @isTest static void testGetDataOnInit() {
        Test.startTest();
        Response r = OpportunityCreationFormController.getDataOnInit();
        Test.stopTest();

        Feature_Toggle__c ftResult = (Feature_Toggle__c) r.data.get('Feature_Toggle__c');

        System.assertNotEquals(null, ftResult);
    }

    @isTest
    static void testGetServicePricebookEntryByAccountEnts() {
        Account testAccount = (Account)new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Account testAccountWithoutEntitlments = (Account)new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        Product2 notServiceProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Family, Product2Helper.FAMILY_DISCOUNTED_PHONES)
            .setField(Product2.Feature__c, Product2Helper.FEATURE_DISCOUNTED_PHONES)
            .setField(Product2.IsActive, true)
            .create()
            .getRecord();

        Product2 serviceProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Family, Product2Helper.FAMILY_SERVICE)
            .setField(Product2.Feature__c, Product2Helper.FEATURE_SERVICE_PLAN)
            .setField(Product2.IsActive, true)
            .create()
            .getRecord();

        PricebookEntry notServiceProductPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, notServiceProduct.Id)
            .setField(PricebookEntry.UnitPrice, 100)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        PricebookEntry serviceProductPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, serviceProduct.Id)
            .setField(PricebookEntry.UnitPrice, 200)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .create()
            .getRecord();

        Entitlement__c notServiceProductEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Product__c, notServiceProduct.Id)
            .setField(Entitlement__c.Quantity__c, 1)
            .setField(Entitlement__c.Price__c, 100)
            .setField(Entitlement__c.ChargeTerm__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Entitlement__c.Active__c, true)
            .create()
            .getRecord();

        Entitlement__c serviceProductEnt = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setField(Entitlement__c.Account__c, testAccount.Id)
            .setField(Entitlement__c.Product__c, serviceProduct.Id)
            .setField(Entitlement__c.Quantity__c, 2)
            .setField(Entitlement__c.Price__c, 200)
            .setField(Entitlement__c.ChargeTerm__c, Product2Helper.CHARGE_TERM_MONTHLY)
            .setField(Entitlement__c.Active__c, true)
            .create()
            .getRecord();

        Test.startTest();
        List<PricebookEntry> resultWithData = OpportunityCreationFormController.getServicePricebookEntryByAccountEnts(testAccount.Id);
        List<PricebookEntry> resultWithoutData = OpportunityCreationFormController.getServicePricebookEntryByAccountEnts(testAccountWithoutEntitlments.Id);
        Test.stopTest();

        System.assert(resultWithData != null, 'It is expected to get a list of pricebook entries instead of null');
        System.assertEquals(1, resultWithData.size(), 'It is expected to get a list of pricebook entries with 1 element');
        System.assertEquals(serviceProductPbe.Id, resultWithData[0].Id, 'Unexpected pricebook entry was found');

        System.assert(resultWithoutData == null, 'It is expected to get null instead of List<T> due not existing entitlements');
    }

    @isTest
    static void test_validateContactDowngradedNotOwner(){
        Profile p = [select id from profile where name='System Administrator'];
    
        User testUser = new User(alias = 'u111', email='u111@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing11', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id, country='United States',
        timezonesidkey='America/Los_Angeles', username='u111@testorg.com');
        insert testUser;

        Account testAccount = new Account(Name = 'Test Account', OwnerId = testUser.Id);
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld',
            Contact_Status__c = '0. Downgraded'
        );
        insert testContact;

        
        String retString = OpportunityCreationFormController.validateContact(testContact.Id);        

        Map<String,String> retMap = (Map<String,String>) JSON.deserialize(retString, Map<String,String>.class);
        System.assertEquals(2, retMap.size(), 'It is expected to get a map with 2 elements');        
        System.assertEquals(true, retMap.containsKey('ERROR'), 'It is expected to have a ERROR key in the map');
        System.assertEquals(true, retMap.containsKey('WARNING'), 'It is expected to have a WARNING key in the map');
    }

    @isTest
    static void test_validateContactRecord(){        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        insert testContact;        
        
        String retString = OpportunityCreationFormController.validateContact(testContact.Id);

        Map<String,String> retMap = (Map<String,String>) JSON.deserialize(retString, Map<String,String>.class);
        System.assertEquals(1, retMap.size(), 'It is expected to get a map with 1 element');
        System.assertEquals(true, retMap.containsKey('RECORD'), 'It is expected to have a RECORD key in the map');
    }

    @isTest
    static void test_checkAcctContactRoleNoAcr(){        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        insert testContact;        
        
        OpportunityCreationFormController.checkAcctContactRole(testAccount.Id, testContact.Id);

        List<AccountContactRole> acrList = [SELECT Id FROM AccountContactRole WHERE AccountId =:testAccount.Id AND ContactId = :testContact.Id AND IsPrimary = true];
        System.assertEquals(1, acrList.size(), 'It is expected to get a list with 1 element');
    }

    @isTest
    static void test_checkAcctContactRoleNoPrimary(){        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        insert testContact;
        
        AccountContactRole acr = new AccountContactRole(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Role = 'RC Admin User'
        );
        insert acr;
        
        OpportunityCreationFormController.checkAcctContactRole(testAccount.Id, testContact.Id);
        
        List<AccountContactRole> acrList = [SELECT Id FROM AccountContactRole WHERE AccountId =:testAccount.Id AND ContactId = :testContact.Id AND IsPrimary = true];
        System.assertEquals(1, acrList.size(), 'It is expected to get a list with 1 element');
    }

    @isTest
    static void test_checkAcctContactRolePrimary(){        
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'contact1@ringcentral.tld'
        );
        insert testContact;
        
        AccountContactRole acr = new AccountContactRole(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Role = 'RC Admin User',
            IsPrimary = true
        );
        insert acr;
        
        OpportunityCreationFormController.checkAcctContactRole(testAccount.Id, testContact.Id);
        
        List<AccountContactRole> acrList = [SELECT Id FROM AccountContactRole WHERE AccountId =:testAccount.Id AND ContactId = :testContact.Id AND IsPrimary = true];
        System.assertEquals(1, acrList.size(), 'It is expected to get a list with 1 element');
    }

    @isTest
    static void test_getPartnerSettings(){  

        GSP_Partner_Setup__c gspPartnerSetup = (GSP_Partner_Setup__c) new SObjectBuilder(GSP_Partner_Setup__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                GSP_Partner_Setup__c.Name => 'Apple',
                GSP_Partner_Setup__c.Validate_by_Brand__c => true,
                GSP_Partner_Setup__c.Disable_PDF__c => false,
                GSP_Partner_Setup__c.Disable_POC__c => false,
                GSP_Partner_Setup__c.Has_NGBS_Packages__c => true,
                GSP_Partner_Setup__c.Disable_ProServ__c => false,
                GSP_Partner_Setup__c.Validation_name__c => 'Apple',
                GSP_Partner_Setup__c.ContractedPackages__c => true
            })
            .create()
            .getRecord();

            Test.startTest();
            List<GSP_Partner_Setup__c> gspPartnerSetupValues = OpportunityCreationFormController.getPartnerSettings();
            Test.stopTest();

            System.assertEquals(gspPartnerSetupValues.size() > 0, true, 'gspPartnerSetup values not empty');
    }
}