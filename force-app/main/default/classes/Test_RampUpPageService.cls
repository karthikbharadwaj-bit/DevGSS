@isTest
private class Test_RampUpPageService {

    private static Id accountId {
        get {
            if (accountId == null) {
                accountId = (Id) new ValueProvider.GenericParentProvider(Account.SObjectType).getValue();
            }
            return accountId;
        }
        private set;
    }

    private static Id testOrderId {
        get {
            if (testOrderId == null) {
                testOrderId = new SOBjectBuilder(Order.sObjectType)
                    .setFields(new Map<SObjectField, Object>{
                        Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                        Order.Pricebook2Id => Test.getStandardPricebookId(),
                        Order.QuoteId => testQuoteId,
                        Order.RecordTypeId => OrderHelper.RT_ID_CC,
                        Order.AccountId => accountId,
                        Order.EffectiveDate => System.today(),
                        Order.Status => 'New'
                    })
                    .create()
                    .getRecord()
                    .Id;
            }
            return testOrderId;
        }
        private set;
    }

    private static Id testQuoteId {
        get {
            if (testQuoteId == null) {

                Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
                    .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
                    .setField(Opportunity.AccountId, accountId)
                    .create()
                    .getRecord();

                testQuoteId = new SObjectBuilder(Quote.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object> {
                            Quote.OpportunityId => opp.Id,
                            Quote.Pricebook2Id => Test.getStandardPricebookId(),
                            Quote.End_Date__c => Date.today().addDays(90),
                            Quote.Auto_Renewal__c => true
                        })
                    .create()
                    .getRecord()
                    .Id;
            }
            return testQuoteId;
        }
        private set;
    }

    private static List<Product2> createProducts(Integer qty, Boolean withOverages) {

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_CCSERVICE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SEAT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .quantity(qty)
            .getRecords();
        if (withOverages) {
            products.addAll(
                (List<Product2>) new SObjectBuilder(Product2.SObjectType)
                    .setFields(new Map<SObjectField, Object> {
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                        Product2.Family => Product2Helper.FAMILY_OVERAGE,
                        Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                        Product2.Parent__c => ValueProviderBuilder.provideList(
                            new List<Id>(new Map<Id, Product2>(products).keySet())
                        )
                    })
                    .create()
                    .quantity(qty)
                    .getRecords()
            );
        }
        return products;
    }

    private static OrderItem addProductToOrder(Integer qty, Id productId) {

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productId,
                PricebookEntry.UnitPrice => 210,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();
        OrderItem oi = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrderId,
                OrderItem.PricebookEntryId => standardPricebookEntry.Id,
                OrderItem.Quantity => qty,
                OrderItem.UnitPrice => 210
            })
            .create()
            .getRecord();

        return oi;
    }

    private static ProductDetail__c createEntitlementWithPD(Integer qty, Id productId, String rampUpPeriod, Date startDate) {

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => accountId,
                Entitlement__c.Product__c => productId,
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.Price__c => 1000,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Active__c => true
            })
            .create()
            .getRecord();
        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productId,
                PricebookEntry.UnitPrice => 210,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuoteId,
                    QuoteLineItem.Product2Id => productId,
                    QuoteLineItem.Entitlement__c => ent.Id,
                    QuoteLineItem.Quantity => 20,
                    QuoteLineItem.UnitPrice => 210,
                    QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id
                })
            .create()
            .getRecord();

        ProductDetail__c newPD = (ProductDetail__c)  new SObjectBuilder(ProductDetail__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    ProductDetail__c.Entitlement__c => ent.Id,
                    ProductDetail__c.RampUp__c => rampUpPeriod,
                    ProductDetail__c.QuantityOrThreshold__c => qty
                    // ProductDetail__c.RampUpStartDate__c => startDate
                })
            .create()
            .getRecord();

        Map<Id, ProductDetail__c> allPDs = new Map<Id, ProductDetail__c>((List<ProductDetail__c>) new ProductDetailSelector()
            .selectEntitlementProductDetailsByAccountIds(new List<Object>{new List<Id>{accountId}})
            .executeQuery());

        return allPDs.get(newPD.Id);
    }

    @isTest
    static void testGetRampUpPageItems_singleItem() {

        Integer productQuantity = 5;
        Product2 productOne = createProducts(1, false)[0];
        OrderItem orderItemOne = addProductToOrder(productQuantity, productOne.Id);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.params.put('orderId', testOrderId);

        Test.startTest();
        RampUpPageService.getRampUpPageItems();
        Test.stopTest();
        List<RampUpPageService.RampUpPageItem> result = (List<RampUpPageService.RampUpPageItem>) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            List<RampUpPageService.RampUpPageItem>.class
        );
        System.assertNotEquals(null, result, 'Got null response');
        System.assertEquals(1, result.size(), 'Item list size does not match');
        System.assertEquals(productOne.Family, result[0].family, 'Family does not match');
        System.assertEquals(productQuantity, result[0].quantity, 'Quantity does not match');
    }

    @isTest
    static void testGetRampUpPageItems_singleItemWithOverage() {

        Integer productQuantity = 5;
        List<Product2> products = createProducts(1, true);
        OrderItem orderItemOne = addProductToOrder(productQuantity, products[0].Id);
        OrderItem orderItemTwo = addProductToOrder(productQuantity, products[1].Id);

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.params.put('orderId', testOrderId);

        Test.startTest();
        RampUpPageService.getRampUpPageItems();
        Test.stopTest();
        List<RampUpPageService.RampUpPageItem> result = (List<RampUpPageService.RampUpPageItem>) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            List<RampUpPageService.RampUpPageItem>.class
        );
        System.assertNotEquals(null, result, 'Got null response');
        System.assertEquals(1, result.size(), 'Item list size does not match');
        System.assertEquals(products[0].Family, result[0].family, 'Family does not match');
        System.assertEquals(productQuantity, result[0].quantity, 'Quantity does not match');
        System.assertNotEquals(null, result[0].overage, 'No overage in response');
        System.assertEquals(products[1].Family, result[0].overage.family, 'Overage family does not match');
        System.assertEquals(productQuantity, result[0].overage.quantity, 'Threshold does not match');
    }

    @isTest
    static void testSaveChanges_sellingItemRampUpIncreasing() {

        String newRampUpValue = '45';
        Product2 productOne = createProducts(1, false)[0];
        OrderItem orderItemOne = addProductToOrder(5, productOne.Id);
        ProductDetail__c pd = (ProductDetail__c) new ProductDetailSelector()
            .selectOrderProductDetailsByOrderIds(new List<Object>{new List<Id>{testOrderId}})
            .executeQuery()[0];

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.params.put('orderId', testOrderId);

        pd.RampUp__c = newRampUpValue;
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(
            new List<RampUpPageService.RampUpPageItem>{new RampUpPageService.RampUpPageItem(pd)},
            true
        ));

        Test.startTest();
        RampUpPageService.saveChanges();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Status code is not 200');
        ProductDetail__c newPD = (ProductDetail__c) new ProductDetailSelector()
            .selectOrderProductDetailsByOrderIds(new List<Object>{new List<Id>{testOrderId}})
            .executeQuery()[0];
        System.assertEquals(newRampUpValue, newPD.RampUp__c, 'RampUp update went wrong');
    }

    @isTest
    static void testSaveChanges_EntitlementRampUpChange() {
        String newRampUpValue = '120';
        Product2 productOne = createProducts(1, false)[0];
        ProductDetail__c pd = createEntitlementWithPD(1, productOne.Id, '45', System.today().addDays(-10));
        RampUpPageService.RampUpPageItem pageItem = new RampUpPageService.RampUpPageItem(pd);
        pageItem.rampUpPeriod = newRampUpValue;

        Test.startTest();

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.params.put('orderId', testOrderId);
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(

            new List<RampUpPageService.RampUpPageItem>{
                pageItem
            },

            true

        ));
        RampUpPageService.saveChanges();

        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Status code is not 200');

        List<ProductDetail__c> newPDs = (List<ProductDetail__c>) new ProductDetailSelector()

            .selectOrderProductDetailsByOrderIds(new List<Object>{
                new List<Id>{
                    testOrderId
                }
            })

            .executeQuery();

        System.assertEquals(1, newPDs.size(), 'Incorrect number of product details got created');
        System.assertEquals(newRampUpValue, newPDs[0].RampUp__c, 'Ramp Up period not updated');
    }
}