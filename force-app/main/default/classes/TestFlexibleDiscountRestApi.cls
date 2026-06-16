@isTest
private class TestFlexibleDiscountRestApi
{
    private static RestRequest req = new RestRequest();

    private static Quote testQuote;
    private static Opportunity testOpp;
    private static PriceBook2 testPriceBook;
    //private static User salesrepUser = createUser('sr'); // salesrepUser
    //private static User salesmanagerUser = createUser('sm'); //salesmanagerUser
    //private static User salesmanagermanagerUser = createUser('smm'); //salesmanagermanagerUser
    //private static User salesVPUser = createUser('svp'); //salesmanagermanagerUser

    private static void CreateTestData(String rcUserId, String priceBookPlan, Decimal discount, Boolean quoteApproved, boolean isProduct17ChargeTermAnnual){
        Account acc = new Account(Name = rcUserId, RC_User_ID__c = rcUserId);
        insert acc;

        testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products', IsActive = true, Line_Range_Min__c = 5, Plan__c = priceBookPlan, Tier_Id__c = '123456789');
        insert testPriceBook;

        List<Product2> products = new List<Product2>();

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true, Charge_Term__c = 'Monthly - Contract', GOA_Group__c = 'DEVICES_B_STOCK', Feature__c = 1234);
        products.add(testProduct);

        Product2 testProduct1 = new Product2(Name = 'Test Product1', IsActive = true, GOA_Group__c = 'DEVICES_B_STOCK');
        products.add(testProduct1);

        Product2 testProduct2 = new Product2(Name = 'Test Product2', IsActive = true, Charge_Term__c = 'Monthly - Contract', GOA_Group__c = 'DEVICES_B_STOCK', Family = 'Tier', Feature__c = 58);
        products.add(testProduct2);

        Product2 testProduct3 = new Product2(Name = 'Test Product3', IsActive = true, Charge_Term__c = isProduct17ChargeTermAnnual ? 'Annual' : 'Monthly - Contract',
            GOA_Group__c = 'DEVICES_B_STOCK', Feature__c = 18);
        products.add(testProduct3);

        Product2 testProduct4 = new Product2(Name = 'Test Product4', IsActive = true, Charge_Term__c = 'Annual', Family = 'Rental Phones');
        products.add(testProduct4);

        insert products;

        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPrice);

        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct1.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false
        );
        pbEntries.add(standardPrice1);

        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct3.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 1,  Max_Quantity__c = 100
        );
        pbEntries.add(standardPrice2);

        PricebookEntry standardPrice3 = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(), Product2Id = testProduct4.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 1,  Max_Quantity__c = 100
        );
        pbEntries.add(standardPrice3);


        PricebookEntry testPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct.Id,
            UnitPrice = 10000, IsActive = true, UseStandardPrice = false, Per_Line__c = false, Min_Quantity__c = 5,  Max_Quantity__c = 100, Monthly_Contract_Discount__c = 1
        );
        pbEntries.add(testPrice);

        PricebookEntry testPrice1 = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct1.Id,
            UnitPrice = 1000, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 5,  Max_Quantity__c = 100
        );
        pbEntries.add(testPrice1);

        PricebookEntry testPrice2 = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct3.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 1,  Max_Quantity__c = 100
        );
        pbEntries.add(testPrice2);

        PricebookEntry testPrice3 = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct4.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false, Per_Line__c = true, Min_Quantity__c = 1,  Max_Quantity__c = 100
        );
        pbEntries.add(testPrice3);

        insert pbEntries;

        testOpp = new Opportunity(Name = 'Test Opportunity 2016', Type = 'Syndicated - New', StageName = 'Planning', CloseDate = system.today(), AccountId = acc.Id);
        insert testOpp;

        testQuote = new Quote (Name = 'qoutetest' , OpportunityId = testOpp.id , Pricebook2Id = testPriceBook.id, Total_Number_of_Digital_Lines__c = 5, Initial_Term_months__c = '24');
        if(quoteApproved){
            testQuote.Approved_Status__c = 'Approved';
            testQuote.QuoteType__c = 'Agreement';
        }
        insert testQuote;

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        QuoteLineItem testQuoteLineItem = new QuoteLineItem (
            ServiceDate = date.today(), Description = 'TestLineItem', UnitPrice = testPrice.UnitPrice, Quantity = 25,
            QuoteId = testQuote.Id, PriceBookEntryId = testPrice.Id, Product2Id = testProduct.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, Discount_number__c = discount
        );
        qliList.add(testQuoteLineItem);
        QuoteLineItem testQuoteLineItem1 = new QuoteLineItem (
            ServiceDate = date.today(), Description = 'TestLineItem1', UnitPrice = testPrice1.UnitPrice, Quantity = 15,
            QuoteId = testQuote.Id, PriceBookEntryId = testPrice1.Id, Product2Id = testProduct.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, Discount_number__c = discount
        );
        qliList.add(testQuoteLineItem1);

        QuoteLineItem testQuoteLineItem2 = new QuoteLineItem (
            ServiceDate = date.today(), Description = 'TestLineItem2', UnitPrice = testPrice3.UnitPrice, Quantity = 20,
            QuoteId = testQuote.Id, PriceBookEntryId = testPrice3.Id, Product2Id = testProduct4.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, Discount_number__c = 0
        );
        qliList.add(testQuoteLineItem2);

        QuoteLineItem testQuoteLineItem3 = new QuoteLineItem (
            ServiceDate = date.today(), Description = 'TestLineItem3', UnitPrice = testPrice2.UnitPrice, Quantity = 20,
            QuoteId = testQuote.Id, PriceBookEntryId = testPrice2.Id, Product2Id = testProduct3.Id, Discount_type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, Discount_number__c = discount
        );
        qliList.add(testQuoteLineItem3);

        insert qliList;
    }


    private static void prepareRESTMessage(String reqBody){
        req = new RestRequest();
        req.requestURI = URL.getOrgDomainUrl() + '/FlexibleDiscountRestApi';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(reqBody);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }


    @IsTest
    private static void testWithNullParams(){
        FlexibleDiscountRestApi.GWRequestCall params = new FlexibleDiscountRestApi.GWRequestCall(null, null, null, null);
        prepareRESTMessage(JSON.serialize(params));

        FlexibleDiscountRestApi.getDiscountApproval();
        RestResponse res = RestContext.response;

        FlexibleDiscountRestApi.ApprovalWrapper wrapperObj = (FlexibleDiscountRestApi.ApprovalWrapper)JSON.deserialize(res.responseBody.toString(), FlexibleDiscountRestApi.ApprovalWrapper.class);

        System.assertEquals('application/json', res.headers.get('Content-Type'));
        System.assertEquals(true, wrapperObj.errorExists);
        System.assertEquals('Invalid Quote Number or Opportunity Id.', wrapperObj.description);
    }


    @IsTest
    private static void testCommon(){
        CreateTestData('123456789', 'Monthly - Contract', 10, true, false);

        Test.startTest();

        String quoteNumber = [SELECT QuoteNumber FROM Quote WHERE Id = :testQuote.Id limit 1].QuoteNumber;


        FlexibleDiscountRestApi.GWRequestCall params = new FlexibleDiscountRestApi.GWRequestCall('123456789', '123456789', quoteNumber, testQuote.Id);
        prepareRESTMessage(JSON.serialize(params));

        FlexibleDiscountRestApi.getDiscountApproval();
        RestResponse res = RestContext.response;

        FlexibleDiscountRestApi.ApprovalWrapper wrapperObj = (FlexibleDiscountRestApi.ApprovalWrapper)JSON.deserialize(res.responseBody.toString(), FlexibleDiscountRestApi.ApprovalWrapper.class);

        System.assertEquals('application/json', res.headers.get('Content-Type'));
        System.assertEquals(null, wrapperObj.errorExists);
        System.assertNotEquals(null, wrapperObj.products);

        Test.stopTest();

    }

    @IsTest
    private static void testCommon_notTierId(){
        CreateTestData('123456789', 'Monthly - Contract', null, true, false);

        Test.startTest();

        String quoteNumber = [SELECT QuoteNumber FROM Quote WHERE Id = :testQuote.Id limit 1].QuoteNumber;


        FlexibleDiscountRestApi.GWRequestCall params = new FlexibleDiscountRestApi.GWRequestCall('123456789', '987654321', quoteNumber, testQuote.Id);
        prepareRESTMessage(JSON.serialize(params));

        FlexibleDiscountRestApi.getDiscountApproval();
        RestResponse res = RestContext.response;

        FlexibleDiscountRestApi.ApprovalWrapper wrapperObj = (FlexibleDiscountRestApi.ApprovalWrapper)JSON.deserialize(res.responseBody.toString(), FlexibleDiscountRestApi.ApprovalWrapper.class);

        System.assertEquals('application/json', res.headers.get('Content-Type'));
        System.assertEquals(null, wrapperObj.errorExists);
        System.assertEquals('Quote doesnt have Tier Product.', wrapperObj.description);

        Test.stopTest();

    }

    static void prepareVirtualExtensionProduct_CustomDiscountTest(string chargeTerm,
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item17Map,
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item58Map,
        Map<Id, QuoteLineItem> qliMap)
     {
        CreateTestData('123456789', chargeTerm, 25, true, true);

        Test.startTest();

        String quoteNumber = [
            SELECT QuoteNumber
            FROM Quote
            WHERE Id = :testQuote.Id
            LIMIT 1
        ].QuoteNumber;

        FlexibleDiscountRestApi.GWRequestCall params = new FlexibleDiscountRestApi.GWRequestCall('123456789', '987654321', quoteNumber, testQuote.Id);

        prepareRESTMessage(JSON.serialize(params));

        FlexibleDiscountRestApi.getDiscountApproval();
        RestResponse res = RestContext.response;

        FlexibleDiscountRestApi.ApprovalWrapper wrapperObj = (FlexibleDiscountRestApi.ApprovalWrapper)JSON.deserialize(res.responseBody.toString(), FlexibleDiscountRestApi.ApprovalWrapper.class);

        qliMap.putAll(
            new Map<Id, QuoteLineItem>([
                SELECT Discount
                FROM QuoteLineItem
                WHERE QuoteId = :testQuote.Id]));

        Test.stopTest();

        for (FlexibleDiscountRestApi.productInfo product : wrapperObj.products)  {
            if (product.productFeature == 17) {
                for (FlexibleDiscountRestApi.lineItemInfo lineItem : product.lineItems) {
                    item17Map.put(lineItem.lineItemId, lineItem);
                }
            } else if (product.productFeature == 58) {
                for (FlexibleDiscountRestApi.lineItemInfo lineItem : product.lineItems) {
                    item58Map.put(lineItem.lineItemId, lineItem);
                }
            }
        }
     }

     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
     private static void virtualExtensionProduct_CustomDiscountWillAppliedToAnnual()
     {
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item17Map = new Map<Id, FlexibleDiscountRestApi.lineItemInfo>();
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item58Map = new Map<Id, FlexibleDiscountRestApi.lineItemInfo>();
        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>();
        prepareVirtualExtensionProduct_CustomDiscountTest('Annual', item17Map, item58Map, qliMap);
        virtualExtensionProduct_ValidateDiscount(qliMap, item17Map, item58Map);
     }

     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
     private static void virtualExtensionProduct_CustomDiscountWillAppliedToMonthly()
     {
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item17Map = new Map<Id, FlexibleDiscountRestApi.lineItemInfo>();
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item58Map = new Map<Id, FlexibleDiscountRestApi.lineItemInfo>();
        Map<Id, QuoteLineItem> qliMap = new Map<Id, QuoteLineItem>();

        prepareVirtualExtensionProduct_CustomDiscountTest('Monthly - Contract', item17Map, item58Map, qliMap);
        virtualExtensionProduct_ValidateDiscount(qliMap, item17Map, item58Map);
     }

     private static void virtualExtensionProduct_ValidateDiscount(Map<Id, QuoteLineItem> qliMap,
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item17Map,
        Map<Id, FlexibleDiscountRestApi.lineItemInfo> item58Map)
     {
        for (Id item17Id : item17Map.keyset()) {
            System.assert(qliMap.containsKey(item17Id), 'Could not find QuoteLineItem by LineItem Id of feature 17');
            System.assert(item58Map.containsKey(item17Id), 'Could not find lineItem of type 58 by LineItem Id of feature 17');

            System.assertEquals(qliMap.get(item17Id).Discount, item58Map.get(item17Id).discount,
                'Discount on feature 58 must be equal to corresponding Discount on QuoteLineItem');

            System.assertEquals(QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, item58Map.get(item17Id).discountType,
                'Type of discount on lineItem of 58 type should be Percentage');
        }
     }

    /*@IsTest
    private static void testCreateVirtualExtensionForFeature17(){

        String rcUserId = '123456789';

        Account acc = new Account(
            Name = rcUserId,
            RC_User_ID__c = rcUserId
        );
        insert acc;

        List<Product2> products = new List<Product2>();
        Product2 testProduct = new Product2(
            Name = 'Connect Pro - Annual Fee',
            IsActive = true,
            GOA_Group__c = 'DEVICES_B_STOCK',
            Family = 'Discounted Phones',
            Charge_Term__c = 'Monthly - Contract'
        );
        products.add(testProduct);

        Product2 testProduct1 = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Family = 'Service',
            Feature__c = 17,
            GOA_Group__c = 'DEVICES_B_STOCK'
        );
        products.add(testProduct1);
        insert products;

        System.debug('[select Id from Product2] >>> ' + [select Id from Product2]);


        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        for(Product2 item : products) {
            pbEntries.add(
                new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = item.Id,
                    UnitPrice = 5000,
                    IsActive = true
                )
            );
        }
        insert pbEntries;

        Opportunity myTestOpp = new Opportunity(
            Name = 'Test Opportunity 2017',
            Type = 'Syndicated - New',
            StageName = 'Planning',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert myTestOpp;

        Quote myTestQuote = new Quote(
            Name = 'myTestQuote',
            OpportunityId = myTestOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Initial_Term_months__c = '24',
            Approved_Status__c = 'Approved',
            QuoteType__c = 'Agreement'
        );
        insert myTestQuote;

        List<QuoteLineItem> qliList = new List<QuoteLineItem>();

        for(PricebookEntry item : pbEntries) {

            QuoteLineItem testQuoteLineItem = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem',
                UnitPrice = 300,
                Quantity = 1,
                QuoteId = myTestQuote.Id,
                PriceBookEntryId = item.Id,
                Product2Id = item.Product2Id
            );
            qliList.add(testQuoteLineItem);
        }
        insert qliList;

        String testTierId = '123456789';

        update new Pricebook2(
            Id = Test.getStandardPricebookId(),
            Plan__c = testTierId,
            Tier_Id__c = testTierId
        );


        Quote reselectedQuote = [SELECT
                                    Approved_Status__c,
                                    InvalidDiscountedPhonesQuantity__c,
                                    InvalidGlobalOfficePhonesQuantity__c,
                                    InvalidLimitedExtensionPhonesQuantity__c,
                                    InvalidCommonPhonesQuantity__c,
                                    QuoteNumber
                                FROM Quote
                                WHERE Id = :myTestQuote.Id
                                LIMIT 1];

        System.debug('reselectedQuote >>> ' + reselectedQuote);

        String quoteNumber = reselectedQuote.QuoteNumber;

        Test.startTest();

            FlexibleDiscountRestApi.GWRequestCall params = new FlexibleDiscountRestApi.GWRequestCall(rcUserId, testTierId, quoteNumber, myTestOpp.Id);
            prepareRESTMessage(JSON.serialize(params));

            FlexibleDiscountRestApi.getDiscountApproval();
            RestResponse res = RestContext.response;

            FlexibleDiscountRestApi.ApprovalWrapper wrapperObj = (FlexibleDiscountRestApi.ApprovalWrapper)JSON.deserialize(res.responseBody.toString(), FlexibleDiscountRestApi.ApprovalWrapper.class);
            System.debug('wrapperObj >>> ' + wrapperObj);

            System.assertEquals(res.headers.get('Content-Type'), 'application/json');
            System.assertEquals(wrapperObj.errorExists, null);
            System.assertNotEquals(wrapperObj.products, null);

            // verify virtual extension was created
            FlexibleDiscountRestApi.productInfo feature17Product;
            Boolean productWithFeature17Exist = false;

            for(FlexibleDiscountRestApi.productInfo item : wrapperObj.products) {

                if( item.productFeature == 17 ) {
                    productWithFeature17Exist = true;
                    feature17Product = item;
                    break;
                }
            }

            FlexibleDiscountRestApi.productInfo createdVirtualExtension;
            Boolean virtualExtensionExist = false;

            if( productWithFeature17Exist ) {

                for(FlexibleDiscountRestApi.productInfo item : wrapperObj.products) {

                    if( item.productFullName == FlexibleDiscountRestApi.VIRTUAL_PRODUCT_FULL_NAME ) {
                        virtualExtensionExist = true;
                        createdVirtualExtension = item;
                        break;
                    }
                }
            }

            System.assert( virtualExtensionExist == true, 'virtual extension don\'t exist FlexibleDiscountRestApi response(this extension must be generated if Product with feature=17 exist in quote)' );

            System.assert( createdVirtualExtension.productFullName == FlexibleDiscountRestApi.VIRTUAL_PRODUCT_FULL_NAME, createdVirtualExtension.productFullName + ' != ' + FlexibleDiscountRestApi.VIRTUAL_PRODUCT_FULL_NAME );
            System.assert( createdVirtualExtension.productCategory == FlexibleDiscountRestApi.VIRTUAL_PRODUCT_CATEGORY, createdVirtualExtension.productCategory + ' != ' + FlexibleDiscountRestApi.VIRTUAL_PRODUCT_CATEGORY );
            System.assert( createdVirtualExtension.productFeature == FlexibleDiscountRestApi.VIRTUAL_PRODUCT_FAETURE, createdVirtualExtension.productFeature + ' != ' + FlexibleDiscountRestApi.VIRTUAL_PRODUCT_FAETURE );
            System.assert( createdVirtualExtension.serviceType == FlexibleDiscountRestApi.VIRTUAL_SERVICE_TYPE, createdVirtualExtension.serviceType + ' != ' + FlexibleDiscountRestApi.VIRTUAL_SERVICE_TYPE );

        Test.stopTest();
    }*/


    @isTest
    static void testCommonWithEntitlements() {
        CreateTestData('123456789', 'Monthly - Contract', 10, true, false);

        // create entitlements for existing quotelinitems
        List<QuoteLineItem> qliList = [select Id, Product2Id, Quantity, Discount_type__c, Discount_number__c from QuoteLineItem where QuoteId = :testQuote.Id];

        Set<Id> productsWithEntitlements = new Set<Id>();
        List<Entitlement__c> entlList = new List<Entitlement__c>();
        for(QuoteLineItem qli :qliList) {
            entlList.add(
                new Entitlement__c(
                    Account__c = testOpp.AccountId,
                    Product__c = qli.Product2Id,
                    Active__c = true,
                    Discount_Type__c = qli.Discount_type__c,
                    Quantity__c = qli.Quantity,
                    Discount__c = qli.Discount_number__c
                )
            );

            productsWithEntitlements.add(qli.Product2Id);
        }

        // add additional entitlement for remaining Products
        Map<Id, Product2> productMap = new Map<Id, Product2>([select Id from Product2]);

        for(Id prodId :productMap.keySet()) {
            if(!productsWithEntitlements.contains(prodId)) {
                entlList.add(
                    new Entitlement__c(
                        Account__c = testOpp.AccountId,
                        Product__c = prodId,
                        Active__c = true,
                        Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                        Quantity__c = 7,
                        Discount__c = 5
                    )
                );
            }
        }
        insert entlList;

        Test.startTest();

        String quoteNumber = [SELECT QuoteNumber FROM Quote WHERE Id = :testQuote.Id limit 1].QuoteNumber;


        FlexibleDiscountRestApi.GWRequestCall params = new FlexibleDiscountRestApi.GWRequestCall('123456789', '123456789', quoteNumber, testQuote.Id);
        prepareRESTMessage(JSON.serialize(params));

        FlexibleDiscountRestApi.getDiscountApproval();
        RestResponse res = RestContext.response;

        FlexibleDiscountRestApi.ApprovalWrapper wrapperObj = (FlexibleDiscountRestApi.ApprovalWrapper)JSON.deserialize(res.responseBody.toString(), FlexibleDiscountRestApi.ApprovalWrapper.class);

        System.assertEquals('application/json', res.headers.get('Content-Type'));
        System.assertEquals(null, wrapperObj.errorExists);
        System.assertNotEquals(null, wrapperObj.products);

        Test.stopTest();
    }
}