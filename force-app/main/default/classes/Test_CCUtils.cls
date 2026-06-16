@isTest
private class Test_CCUtils {

    @isTest
    private static void testSortOveragesByProducts_parentLookupMatching() {

        Product2 seatProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_CCSERVICE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SEAT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Product2 seatOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_OVERAGE,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Parent__c => seatProduct.Id
            })
            .create()
            .getRecord();

        Product2 minutesProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_TRANSPORT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Product2 minutesOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_OVERAGE,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_TRANSPORT,
                Product2.Parent__c => seatProduct.Id
            })
            .create()
            .getRecord();

        Product2 portProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_ADDONS,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_PORT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Product2 portOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_OVERAGE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_PORT,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Parent__c => seatProduct.Id
            })
            .create()
            .getRecord();

        Product2 inCallsProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_INBOUND_CALLS,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Product2 inCallsOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_OVERAGE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_INBOUND_CALLS,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Parent__c => seatProduct.Id
            })
            .create()
            .getRecord();

        Product2 outCallsProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_MINUTES_BUNDLE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Product2 outCallsOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_OVERAGE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_OUTBOUND_CALLS,
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER,
                Product2.Parent__c => seatProduct.Id
            })
            .create()
            .getRecord();

        Map<Id, Id> result = CCUtils.sortOveragesByProducts(new List<Product2>{seatProduct, seatOverageProduct,
            minutesProduct, minutesOverageProduct, portProduct, portOverageProduct, inCallsProduct, inCallsOverageProduct,
            outCallsProduct, outCallsOverageProduct});
        System.assertEquals(5, result.size(), 'Wrong result size');
        System.assert(result.containsKey(seatProduct.Id), 'No key returned for seat product');
        System.assertEquals(seatOverageProduct.Id, result.get(seatProduct.Id), 'Overage not matched with parent seat');
    }

    @isTest
    private static void testSortOveragesByProducts_extIdMatching() {

        Product2 seatProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Product_Type__c => Product2Helper.PRODUCT_TYPE_SEAT,
                Product2.ExtId__c => 'null_Advanced Seat',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Product2 seatOverageProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_OVERAGE,
                Product2.ExtId__c => 'Overage_Advanced Seat',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_CONTACT_CENTER
            })
            .create()
            .getRecord();
        Map<Id, Id> result = CCUtils.sortOveragesByProducts(new List<Product2>{seatProduct, seatOverageProduct});
        System.assertEquals(1, result.size(), 'Wrong result size');
        System.assert(result.containsKey(seatProduct.Id), 'No key returned for seat product');
        System.assertEquals(seatOverageProduct.Id, result.get(seatProduct.Id), 'Overage not matched with parent seat');
        new QuoteLineItemSelector()
            .selectQuoteLineItemsForSyncCostCenterLineItems(new List<Object>{'000000000', new List<String>{'1','2'}})
            .executeQuery();
        new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(new List<Id>{(Id) new ValueProvider.DummyIdProvider(QuoteLineItem.sObjectType).getValue()})
            .executeQuery();
        new QuoteLineItemSelector()
            .selectQuoteLineItemsForPOCApproval()
            .executeQuery();
        new QuoteLineItemSelector()
            .selectQuoteLineItemsForSignUp()
            .executeQuery();
    }
}