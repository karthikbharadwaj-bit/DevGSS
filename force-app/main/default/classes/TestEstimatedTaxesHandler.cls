@isTest
private class TestEstimatedTaxesHandler {

    public static Map<String, Map<String,Decimal>> sumTaxes;
    public static Id quoteId;
    public static EstimatedTaxesHandler.messageDTO msg;
    public static String body;
    public static final String REQUEST_BODY =
        '{"status": {"success": true, "code": 0, "message": ""}, ' +
        '"result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
        '"discount": 0, "totalTaxes": 15, "taxDetails": ' +
        '[{"availableOnBrand": true, "description": "State and local taxes and fees", "type": "VARIABLE", ' +
        '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}, ' +
        '{"availableOnBrand": true, "description": "State and local taxes and fees", "type": "FIXED", ' +
        '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}, ' +
        '{"availableOnBrand": true, "description": "E911_SERVICE_FEE", "type": "FIXED", ' +
        '"descriptionId": "E911_SERVICE_FEE", "amount": 4}] }, {}]}}';

    private static Id CreateTestDataAndGetQouteId() {
        String rcUserId = '123456789';
        String priceBookPlan = 'Monthly - Contract';
        Boolean quoteApproved = True;

        schedulerConfiguration__c scc = new schedulerConfiguration__c(Name='RingCentral', Brand_Id__c='1111');
        insert scc;

        EstimatedTaxesLinkSetting__c etls = new EstimatedTaxesLinkSetting__c(Name='RingCentral', EstimatedTaxesLink__c='https://devorigin101.secure.ringcentral.com/ws/tax-estimates-for-quotes.php');
        insert etls;
        Triggers.switchOff();
        Account acc = new Account(Name = rcUserId, RC_User_ID__c = rcUserId, Tax_Exempt__c=true, BillingCity='Moscow', BillingPostalCode='111234', BillingState='Moscow prov', BillingCountry='Russia');
        insert acc;
        Triggers.switchOn();

        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Plan__c = priceBookPlan, Tier_Id__c = '123456789', Brand__c=scc.id);
        insert testPriceBook;

        List<Product2> products = new List<Product2>();
        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'Service', Charge_Term__c = 'Monthly - Contract', Feature__c=23);
        products.add(testProduct);
        Product2 testProduct1 = new Product2(Name = 'Test Product', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'Discounted Phones', Feature__c=11);
        products.add(testProduct1);
        Product2 testProduct2 = new Product2(Name = 'Test Product2', FeatureName__c='Test Product2', FDescription__c='Some Description3' ,IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'Strange family', Feature__c=12);
        products.add(testProduct2);

        Product2 federalTaxProduct = new Product2(Name='Federal Universal Service Fund', Charge_Term__c = 'One - Time',  Family='Taxes');
        products.add(federalTaxProduct);
        Product2 stateLocalTaxProduct = new Product2(Name='State and local taxes and fees', Charge_Term__c = 'One - Time',  Family='Taxes');
        products.add(stateLocalTaxProduct);

        insert products;

        List<PricebookEntry> pbEntries = new List<PricebookEntry>();

        PricebookEntry standardPrice = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPrice);
        PricebookEntry testPrice = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id,
                UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 5, Max_Quantity__c = 100
        );
        pbEntries.add(testPrice);
        PricebookEntry standardPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPrice1);
        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id, Product2Id = testProduct1.Id,
                UnitPrice = 1000, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 5, Max_Quantity__c = 100
        );
        pbEntries.add(testPrice1);

        PricebookEntry standardPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPrice2);
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = testPriceBook.Id, Product2Id = testProduct2.Id,
                UnitPrice = 1000, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 5, Max_Quantity__c = 100
        );
        pbEntries.add(testPrice2);


        PricebookEntry standardPriceFed = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = federalTaxProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPriceFed);

        PricebookEntry standardPriceLoc = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(), Product2Id = stateLocalTaxProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPriceLoc);

        PricebookEntry fedPbe = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = federalTaxProduct.Id,
                UnitPrice = 0, IsActive = true, Min_Quantity__c = 5, Max_Quantity__c = 100, UseStandardPrice = false);
        pbEntries.add(fedPbe);

        PricebookEntry locPbe = new PricebookEntry(Pricebook2Id = testPriceBook.Id, Product2Id = stateLocalTaxProduct.Id,
                UnitPrice = 0, IsActive = true, Min_Quantity__c = 5, Max_Quantity__c = 100, UseStandardPrice = false);
        pbEntries.add(locPbe);

        insert pbEntries;
        Triggers.switchOff();

        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = acc.Id);
        insert testOpp;
        Triggers.switchOn();

        Quote testQuote = new Quote(Name = 'qoutetest', OpportunityId = testOpp.id, Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 5, Initial_Term_months__c = '24');
        if (quoteApproved) {
            testQuote.Approved_Status__c = 'Approved';
            testQuote.QuoteType__c = 'Agreement';
        }
        insert testQuote;

        List<QuoteLineItem> listQli = new List<QuoteLineItem>();
        QuoteLineItem testQli = new QuoteLineItem (
                ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice,
                QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id,
                Quantity = 5);
        listQli.add(testQli);
        QuoteLineItem testQli1 = new QuoteLineItem (
                ServiceDate = date.today(), Description = 'TestLineItem1', UnitPrice = testPrice1.UnitPrice,
                QuoteId = testQuote.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct1.Id,
                Quantity = 5);
        listQli.add(testQli1);
        QuoteLineItem testQli2 = new QuoteLineItem (
                ServiceDate = date.today(), Description = 'TestLineItemFedTax', UnitPrice = fedPbe.UnitPrice,
                QuoteId = testQuote.Id, PriceBookEntryId = fedPbe.Id, Product2Id = federalTaxProduct.Id,
                Quantity = 5);
        listQli.add(testQli2);
        QuoteLineItem testQli3 = new QuoteLineItem (
                ServiceDate = date.today(), Description = 'TestLineItem2', UnitPrice = testPrice2.UnitPrice,
                QuoteId = testQuote.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct2.Id,
                Quantity = 5);
        listQli.add(testQli3);

        QuoteLineItem testQli4 = new QuoteLineItem (
                ServiceDate = date.today(), Description = 'TestLineItemLocTax', UnitPrice = locPbe.UnitPrice,
                QuoteId = testQuote.Id, PriceBookEntryId = locPbe.Id, Product2Id = stateLocalTaxProduct.Id,
                Quantity = 5);
        listQli.add(testQli4);
        insert testQli4;

        return testQuote.Id;
    }

    private static EstimatedTaxesHandler.estimatedTaxesDTO prepareExistingItems(EstimatedTaxesHandler.estimatedTaxesDTO estTaxesDto) {
        if (estTaxesDto != null) {
            for (EstimatedTaxesHandler.FeatureDTO dto : estTaxesDto.featuresList) {
                dto.entDiscountType = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;
                dto.existingQuantity = Math.round(Math.random());
                dto.entPrice = Math.round(Math.random()) * 100;
                dto.entDiscount = Math.round(Math.random());
                dto.hasEntitlement = true;
            }
        }
        return estTaxesDto;
    }

    @IsTest
    private static void testAddTaxesQliToQuote(){
        quoteId = CreateTestDataAndGetQouteId();
        sumTaxes = new Map<String, Map<String,Decimal>>();
        Map<String, Integer> ppTaxes = new Map<String, Integer>();
        ppTaxes.put('STATE_AND_LOCAL_TAXES_AND_FEES', 5);
        ppTaxes.put('FEDERAL_UNIVERSAL_SERVICE_FUND', 6);
        sumTaxes.put('One - Time', ppTaxes);

        Test.startTest();
        EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
        msg = helper.addTaxesQliToQuoteAndReturnMessageDto(quoteId, sumTaxes, null);
        Test.stopTest();

        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice FROM QuoteLineItem WHERE Product2.Name='Federal Universal Service Fund' OR Product2.Name='State and local taxes and fees'];
        System.assertEquals(qliList.size(), 2);
        for (QuoteLineItem qli : qliList) {
            System.debug('Qli Product2.Name = '+qli.Product2.Name+', UnitPrice='+String.valueOf(qli.UnitPrice));
        }
        System.assertEquals(msg.message, 'OK');

    }

    @IsTest
    private static void testWrongIdAddTaxesQliToQuote(){
        quoteId = CreateTestDataAndGetQouteId();
        sumTaxes = new Map<String, Map<String,Decimal>>();
        Map<String, Integer> ppTaxes = new Map<String, Integer>();
        ppTaxes.put('STATE_AND_LOCAL_TAXES_AND_FEES', 5);
        ppTaxes.put('FEDERAL_UNIVERSAL_SERVICE_FUND', 6);
        sumTaxes.put('One - Time', ppTaxes);

        Product2 wrong = [SELECT Id FROM Product2 LIMIT 1];
        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            Boolean qliTaxesRemoved = EstimatedTaxesHandler.removeTaxesQli(quoteId);
            msg = helper.addTaxesQliToQuoteAndReturnMessageDto(wrong.Id, sumTaxes, null);
        Test.stopTest();

        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice FROM QuoteLineItem WHERE Product2.Name='Federal Universal Service Fund' OR Product2.Name='State and local taxes and fees'];
        System.assertEquals(qliList.size(), 0);
    }

    @IsTest
    private static void testOneZeroTaxAddTaxesQliToQuote(){
        quoteId = CreateTestDataAndGetQouteId();
        sumTaxes = new Map<String, Map<String,Decimal>>();
        Map<String, Integer> ppTaxes = new Map<String, Integer>();
        ppTaxes.put('FEDERAL_UNIVERSAL_SERVICE_FUND', 0);
        sumTaxes.put('One - Time', ppTaxes);

        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            msg = helper.addTaxesQliToQuoteAndReturnMessageDto(quoteId, sumTaxes, null);
        Test.stopTest();

        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice FROM QuoteLineItem WHERE Product2.Name='Federal Universal Service Fund' OR Product2.Name='State and local taxes and fees'];
        System.assertEquals(qliList.size(), 1);
        System.assertEquals(qliList[0].UnitPrice, 0);
        System.assertEquals(msg.message, 'OK');
    }

    @IsTest
    private static void testEmptyMapAddTaxesQliToQuote(){
        quoteId = CreateTestDataAndGetQouteId();
        sumTaxes = new Map<String, Map<String,Decimal>>();


        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            msg = helper.addTaxesQliToQuoteAndReturnMessageDto(quoteId, sumTaxes, null);
        Test.stopTest();

        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice FROM QuoteLineItem WHERE Product2.Name='Federal Universal Service Fund' OR Product2.Name='State and local taxes and fees'];
        System.assertEquals(qliList.size(), 0);
        System.assertEquals(msg.message, 'Map size is zero');
    }

    @IsTest
    private static void testResponseEstimatedTaxesDTOCasting(){
        body = '{"status": {"success": true, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": [{"availableOnBrand": true, "description": "State and local taxes and fees", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 6 }] }, {}]}}';
        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            EstimatedTaxesHandler.responseEstimatedTaxesDTO estTaxDto = helper.responseMapping('NOT A VALID JSON');
            System.assertEquals(estTaxDto, null);
            estTaxDto = helper.responseMapping(body);
            System.debug('##! ' + String.valueOf(estTaxDto.status.success));
            System.debug('##! ' + String.valueOf(estTaxDto.status.code));
            System.debug('##! ' + String.valueOf(estTaxDto.result));
            System.debug('##! ' + String.valueOf(estTaxDto.result.billingItems));
            System.assertEquals(estTaxDto.status.success, true);
        Test.stopTest();

    }

    @IsTest
    private static void testProcessRespondMappingAndQliAddingBodyEmpty(){
        quoteId = CreateTestDataAndGetQouteId();
        body = 'NOT A VALID JSON';
        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            msg = helper.processRespondMappingAndQliAdding(quoteId, body, null);
            System.assertEquals(msg.message, 'Response is not correct');
        Test.stopTest();

    }

    @IsTest
    private static void testProcessRespondMappingAndQliAddingSuccessFalse(){
        quoteId = CreateTestDataAndGetQouteId();
        body = '{"status": {"success": false, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": [{"availableOnBrand": true, "description": "State and local taxes and fees", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 6 }] }, {}]}}';
        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            msg = helper.processRespondMappingAndQliAdding(quoteId, body, null);
            System.assertEquals(msg.message, 'Status is not success');
        Test.stopTest();

    }

    @IsTest
    private static void testProcessRespondMappingAndQliAddingTaxDetailEmpty(){
        quoteId = CreateTestDataAndGetQouteId();
        body = '{"status": {"success": true, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": []}, {}]}}';
        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            msg = helper.processRespondMappingAndQliAdding(quoteId, body, null);
            System.assertEquals(msg.message, 'No taxes need to be added');
        Test.stopTest();

    }

    @IsTest
    private static void testProcessRespondMappingAndQliAdding(){
        quoteId = CreateTestDataAndGetQouteId();
        body = '{"status": {"success": true, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "requestedItemInfo": {"item": {}, "sectionType": "featuresList"}, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": [{"availableOnBrand": true, "description": "State and local taxes and fees", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}, {"availableOnBrand": true, "description": "State and local taxes and fees", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}] }, {}]}}';
        Test.startTest();
            EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
            msg = helper.processRespondMappingAndQliAdding(quoteId, body, null);
            System.assertEquals(msg.message, 'OK');
        Test.stopTest();
        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice FROM QuoteLineItem WHERE Product2.Name='Federal Universal Service Fund' OR Product2.Name='State and local taxes and fees'];
        System.assertEquals(qliList.size(), 1);
    }

    @isTest
    public static void testEstimateTaxesAndAddQliPhase1() {
        TestHttpCalloutMock fakeResponse = new TestHttpCalloutMock(200,
                'Complete', '{"status": {"success": true, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": [{"availableOnBrand": true, "description": "State and local taxes and fees", "type": "VARIABLE", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}, {"availableOnBrand": true, "description": "State and local taxes and fees", "type": "FIXED", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}, {"availableOnBrand": true, "description": "E911_SERVICE_FEE", "type": "FIXED", ' +
                '"descriptionId": "E911_SERVICE_FEE", "amount": 4}] }, {}]}}');
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        quoteId = CreateTestDataAndGetQouteId();
        Test.startTest();
            EstimatedTaxesHandler handler = new EstimatedTaxesHandler();
            EstimatedTaxesHandler.messageDTO res = handler.estimateTaxesAndAddQli(quoteId);
        Test.stopTest();
        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice, Variable_Taxes_Amount__c,
                                        Fixed_Taxes_Amount__c, Taxes__c
                                        FROM QuoteLineItem];
        Integer qliAmount = 0;
        for (QuoteLineItem qli : qliList) {
            if((new Set <String>{'Federal Universal Service Fund', 'State and local taxes and fees'}).contains(qli.Product2.Name)) {
                qliAmount++;
            }
        }
        System.assertEquals(1, qliAmount);

        //Check if qli fields are populated correctly
        System.assertEquals(4, qliList.get(0).Variable_Taxes_Amount__c);
        System.assertEquals(4, qliList.get(0).Fixed_Taxes_Amount__c);
        System.assertEquals(8, qliList.get(0).Taxes__c);
    }

    @isTest
    //Test when amountVariable and amountFixed values are returned by "Estimated taxes" service
    public static void testEstimateTaxesAndAddQliPhase2() {
        TestHttpCalloutMock fakeResponse = new TestHttpCalloutMock(200,
                'Complete', '{"status": {"success": true, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": [{"availableOnBrand": true, "description": "State and local taxes and fees", "type": "VARIABLE", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4, "amountVariable": 4, "amountFixed": 0}, {"availableOnBrand": true, "description": "State and local taxes and fees", "type": "FIXED", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4, "amountVariable": 0, "amountFixed": 4}] }, {}]}}');
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        quoteId = CreateTestDataAndGetQouteId();
        Test.startTest();
            EstimatedTaxesHandler handler = new EstimatedTaxesHandler();
            EstimatedTaxesHandler.messageDTO res = handler.estimateTaxesAndAddQli(quoteId);
        Test.stopTest();
        List<QuoteLineItem> qliList = [SELECT Product2.Name, UnitPrice, Variable_Taxes_Amount__c,
                                        Fixed_Taxes_Amount__c, Taxes__c
                                        FROM QuoteLineItem];
        //Check if qli fields are populated correctly
        System.assertEquals(4, qliList.get(0).Variable_Taxes_Amount__c);
        System.assertEquals(4, qliList.get(0).Fixed_Taxes_Amount__c);
    }

    @isTest
    public static void testEstimateTaxesAndAddQliWithoutAccBillingAdress() {
        TestHttpCalloutMock fakeResponse = new TestHttpCalloutMock(200,
                'Complete', '{"status": {"success": true, "code": 0, "message": ""}, "result": {"billingItems": [{"billingItemId": 1, "price": 59.99, ' +
                '"discount": 0, "totalTaxes": 15, "taxDetails": [{"availableOnBrand": true, "description": "State and local taxes and fees", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}, {"availableOnBrand": true, "description": "State and local taxes and fees", ' +
                '"descriptionId": "STATE_AND_LOCAL_TAXES_AND_FEES", "amount": 4}] }, {}]}}');
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        quoteId = CreateTestDataAndGetQouteId();

        Test.startTest();
        Account acc = [SELECT BillingCity, BillingPostalCode, BillingState FROM Account LIMIT 1];
        acc.BillingPostalCode = '';
        acc.BillingCity = '';
        acc.BillingState = '';
        update acc;

        EstimatedTaxesHandler handler = new EstimatedTaxesHandler();
        msg = handler.estimateTaxesAndAddQli(quoteId);
        Test.stopTest();

        System.assertEquals(msg.status, 202);
        System.assertEquals(msg.message, 'Please fill Account Billing Address fields');
    }

    @IsTest
    private static void testGetEstimatedTaxesDTO(){
        quoteId = CreateTestDataAndGetQouteId();

        Test.startTest();
        EstimatedTaxesHandler.estimatedTaxesWrapper data = new EstimatedTaxesHandler.estimatedTaxesWrapper();
        EstimatedTaxesHandler.estimatedTaxesDTO result = data.getEstimatedTaxesDTO(quoteId);
        System.debug('!## exemptFromStateAndLocalTaxes = ' + String.valueOf(result.exemptFromStateAndLocalTaxes));
        System.assertEquals(result.exemptFromStateAndLocalTaxes, True);
        Test.stopTest();
    }

    @IsTest
    private static void testWrongQuoteIdDataCollection(){
        quoteId = CreateTestDataAndGetQouteId();
        Account anyAcc = [SELECT Id FROM Account LIMIT 1];
        Id wrongId = anyAcc.Id;

        Test.startTest();
        EstimatedTaxesHandler.estimatedTaxesWrapper data = new EstimatedTaxesHandler.estimatedTaxesWrapper();
        EstimatedTaxesHandler.estimatedTaxesDTO result = data.getEstimatedTaxesDTO(wrongId);
        System.debug('!## exemptFromStateAndLocalTaxes = ' + String.valueOf(result.exemptFromStateAndLocalTaxes));
        System.assertEquals(result.exemptFromStateAndLocalTaxes, Null);
        Test.stopTest();
    }

    @IsTest
    private static void testConvertorFromFlexWrapperToFilteredFlexWrapper() {
        EstimatedTaxesHandler.DeviceInfoDTO testConstructor = new EstimatedTaxesHandler.DeviceInfoDTO();
        FlexibleDiscountRestApi.ApprovalWrapper aprWr = new FlexibleDiscountRestApi.ApprovalWrapper();
        List<FlexibleDiscountRestApi.productInfo> products = new List<FlexibleDiscountRestApi.productInfo>();
        FlexibleDiscountRestApi.lineItemInfo li = new FlexibleDiscountRestApi.lineItemInfo('lineItemId', 'lineItemName', 1, 1, 1, 'subCategory', 1, 1, 1, 'str_category', 'discountType', 1, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY, 3);
        List<FlexibleDiscountRestApi.lineItemInfo> liList = new List<FlexibleDiscountRestApi.lineItemInfo>();
        liList.add(li);
        FlexibleDiscountRestApi.productInfo prod1 = new FlexibleDiscountRestApi.productInfo('productFullName', 'productId', 'productCategory', 'productSubCategory', 'Montly', 'productType', 'serviceType', 51, 32, liList);
        products.add(prod1);
        aprWr.products = products;

        EstimatedTaxesHandler.ApprovalWrapperForEstimatedTaxesDTO filtAprWr = new EstimatedTaxesHandler.ApprovalWrapperForEstimatedTaxesDTO(aprWr);
        System.assertEquals(filtAprWr.products.size(), 1);
        System.assertEquals(filtAprWr.products[0].chargeTerm, 'Montly');
    }

    @IsTest
    private static void testPayCountryExistInRequest() {
        quoteId = CreateTestDataAndGetQouteId();
        Account acc = [SELECT Id, Name, BillingCountry FROM Account LIMIT 1];

        Test.startTest();

        EstimatedTaxesHandler.estimatedTaxesWrapper estTaxeswrapper = new EstimatedTaxesHandler.estimatedTaxesWrapper();
        EstimatedTaxesHandler.estimatedTaxesDTO estTaxesDto = estTaxeswrapper.getEstimatedTaxesDTO(quoteId);

        Test.stopTest();

        System.assertEquals(estTaxesDto.payCountry, acc.BillingCountry);

    }

    @IsTest
    private static void testPrepareExistingHttpRequest(){
        TestHttpCalloutMock fakeResponse = new TestHttpCalloutMock(
            200,
            'Complete',
            REQUEST_BODY
        );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        quoteId = CreateTestDataAndGetQouteId();

        Test.startTest();

        EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
        EstimatedTaxesHandler.estimatedTaxesWrapper estTaxeswrapper = new EstimatedTaxesHandler.estimatedTaxesWrapper();
        EstimatedTaxesHandler.estimatedTaxesDTO estTaxesDto = estTaxeswrapper.getEstimatedTaxesDTO(quoteId);
        EstimatedTaxesHandler.estimatedTaxesDTO currentTaxes = prepareExistingItems(estTaxesDto);

            HttpResponse response = helper.prepareExistingRequest(currentTaxes, helper);
        Test.stopTest();

        EstimatedTaxesHandler.responseEstimatedTaxesDTO mappedResponse = helper.responseMapping(response.getBody());

        System.assert(mappedResponse.status.success, 'HttpRequest was failed.');
        System.assert(!mappedResponse.result.billingItems.isEmpty(), 'Billing Items was not received.');
    }

    @IsTest
    private static void testPrepareExistingTaxes(){
        TestHttpCalloutMock fakeResponse = new TestHttpCalloutMock(
            200,
            'Complete',
            REQUEST_BODY
        );
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        quoteId = CreateTestDataAndGetQouteId();

        Test.startTest();

        EstimatedTaxesHandler.EstimatedTaxesHandlerHelper helper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
        EstimatedTaxesHandler.estimatedTaxesWrapper estTaxeswrapper = new EstimatedTaxesHandler.estimatedTaxesWrapper();
        EstimatedTaxesHandler.estimatedTaxesDTO estTaxesDto = estTaxeswrapper.getEstimatedTaxesDTO(quoteId);
        EstimatedTaxesHandler.estimatedTaxesDTO currentTaxes = prepareExistingItems(estTaxesDto);

            HttpResponse response = helper.prepareExistingRequest(currentTaxes, helper);
            Map<String, Map<String, Decimal>> existingTaxes = helper.prepareExistingTaxes(response.getBody());
        Test.stopTest();

        System.assert(!existingTaxes.isEmpty(), 'Existing Taxes was not calculated.');
        System.assertEquals(
            existingTaxes.get(Product2Helper.CHARGE_TERM_ONE_TIME)
                        .get(EstimatedTaxesHandler.localTaxesExtId),
            8,
            'Local Taxes was calculated incorrectly.'
        );
    }

    @IsTest
    private static void testEstimatedTaxesWithEqualsEntFeature(){
        SObjectFactory factory = new SObjectFactory();

        EstimatedTaxesHandler.EstimatedTaxesHandlerHelper taxesHelper = new EstimatedTaxesHandler.EstimatedTaxesHandlerHelper();
        EstimatedTaxesHandler.estimatedTaxesWrapper taxesWrapper = new EstimatedTaxesHandler.estimatedTaxesWrapper();

        Account acc = (Account) factory
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {
                    Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                    Account.BillingCountry => ValueProviderBuilder.provideUniqueString(),
                    Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                    Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                    Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString()
                }
            );

        Opportunity opportunity = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => acc.Id,
                    Opportunity.CloseDate => System.today()
                }
            );

        schedulerConfiguration__c brand = (schedulerConfiguration__c) factory
            .create(
                schedulerConfiguration__c.SObjectType,
                new Map<SObjectField, Object> {
                    schedulerConfiguration__c.Brand_Id__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        PriceBook2 pricebook = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object> {
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.Brand__c => brand.Id,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 5,
                    PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        Quote quote = (Quote) factory
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => opportunity.Id,
                    Quote.Pricebook2Id => pricebook.Id
                }
            );

        Product2 product = (Product2) factory
            .create(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Feature__c => 17
                }
            );

        List<Entitlement__c> ent = (List<Entitlement__c>) factory
            .create(
                Entitlement__c.SObjectType,
                3,
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => acc.Id,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Product__c => product.Id
                }
            );

        PricebookEntry standartPricebookEntry = (PricebookEntry) factory
            .create(
                PricebookEntry.SObjectType,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        PricebookEntry currentPricebookEntry = (PricebookEntry) factory
            .create(
                PricebookEntry.SObjectType,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => pricebook.Id,
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        QuoteLineItem qli = (QuoteLineItem) factory
            .create(
                QuoteLineItem.SObjectType,
                new Map<SObjectField, Object> {
                    QuoteLineItem.Product2Id => product.Id,
                    QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                    QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.QuoteId => quote.Id,
                    QuoteLineItem.Quantity => 1,
                    QuoteLineItem.UnitPrice => 10
                }
            );

        Test.startTest();
            EstimatedTaxesHandler.estimatedTaxesDTO taxesDto = taxeswrapper.getEstimatedTaxesDTO(quote.Id);
        Test.stopTest();

        System.assertEquals(
            1,
            taxesDto.featuresList.size(),
            'Estimated Taxes was retrieved incorrectly.'
        );
        System.assertEquals(
            pricebook.Tier_ID__c,
            String.valueOf(taxesDto.featuresList.get(0).idTier),
            'Correct Entitlement was not retrived.'
        );
    }
}