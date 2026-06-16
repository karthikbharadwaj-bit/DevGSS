@isTest
private class TestEstimatedTaxesRestApi {

    private static RestRequest req = new RestRequest();
    private static Id CreateTestDataAndGetQouteId() {
        String rcUserId = '123456789';
        String priceBookPlan = 'Monthly - Contract';
        Boolean quoteApproved = True;

        Triggers.switchOff();

        schedulerConfiguration__c scc = new schedulerConfiguration__c(Name='RingCentral', Brand_Id__c='1111');
        insert scc;

        Account acc = new Account(Name = rcUserId, RC_User_ID__c = rcUserId, Tax_Exempt__c=true);
        insert acc;

        PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description = 'Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Plan__c = priceBookPlan, Tier_Id__c = '123456789', Brand__c=scc.id);
        insert testPriceBook;

        List<Product2> products = new List<Product2>();
        Product2 testProduct = new Product2(Name = 'Connect Pro - Annual Fee', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'Service', Charge_Term__c = 'Monthly - Contract', Feature__c=23);
        products.add(testProduct);
        Product2 testProduct1 = new Product2(Name = 'Test Product', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK', Family = 'Discounted Phones', Feature__c=11);
        products.add(testProduct1);
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
        insert pbEntries;

        Opportunity testOpp = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = acc.Id);
        insert testOpp;

        Quote testQuote = new Quote(Name = 'qoutetest', OpportunityId = testOpp.id, Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 5, Initial_Term_months__c = '24');
        if (quoteApproved) {
            testQuote.Approved_Status__c = 'Approved';
            testQuote.QuoteType__c = 'Agreement';
        }
        insert testQuote;

        Triggers.switchOn();

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
        insert listQli;

        return testQuote.Id;

    }
    private static void prepareRESTMessageEstimatedTaxesRestApi(String quoteIdString){
        EstimatedTaxesRestApi.requestParams reqPrm = new EstimatedTaxesRestApi.requestParams();
        reqPrm.quoteId = quoteIdString;

        req = new RestRequest();
        req.requestURI = URL.getOrgDomainUrl() + '/EstimatedTaxesRestApi';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(reqPrm));

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    private static void testGetEstimatedTaxesDTO(){
        Id quoteId = CreateTestDataAndGetQouteId();

        Test.startTest();
            EstimatedTaxesRestApi.estimatedTaxesWrapper data = new EstimatedTaxesRestApi.estimatedTaxesWrapper();
            EstimatedTaxesRestApi.estimatedTaxesDTO result = data.getEstimatedTaxesDTO(quoteId);
            System.debug('!## taxExempt = ' + String.valueOf(result.taxExempt));
            System.assertEquals(result.taxExempt, True);
        Test.stopTest();
    }

    @IsTest
    private static void testWrongQuoteId(){
        Id quoteId = CreateTestDataAndGetQouteId();
        Account anyAcc = [SELECT Id FROM Account LIMIT 1];
        Id wrongId = anyAcc.Id;

        Test.startTest();
            EstimatedTaxesRestApi.estimatedTaxesWrapper data = new EstimatedTaxesRestApi.estimatedTaxesWrapper();
            EstimatedTaxesRestApi.estimatedTaxesDTO result = data.getEstimatedTaxesDTO(wrongId);
            System.debug('!## taxExempt = ' + String.valueOf(result.taxExempt));
            System.assertEquals(result.taxExempt, Null);
        Test.stopTest();
    }

    @IsTest
    private static void testRestService() {
        Id quoteId = CreateTestDataAndGetQouteId();
        prepareRESTMessageEstimatedTaxesRestApi(String.valueOf(quoteId));

        Test.startTest();
            EstimatedTaxesRestApi.getEstimatedTaxes();
            RestResponse res = RestContext.response;

            EstimatedTaxesRestApi.estimatedTaxesDTO estTaxDto = (EstimatedTaxesRestApi.estimatedTaxesDTO)JSON.deserialize(res.responseBody.toString(), EstimatedTaxesRestApi.estimatedTaxesDTO.class);
            System.assertEquals(res.headers.get('Content-Type'), 'application/json');
            System.assertEquals(estTaxDto.taxExempt, True);
        Test.stopTest();
    }
}