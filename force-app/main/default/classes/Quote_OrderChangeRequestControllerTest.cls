@isTest
private class Quote_OrderChangeRequestControllerTest {
    
    @testSetup
    private static void testSetup() {
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Standard';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Product_Categories__c = 'Add-Ons;International;Phones;Conferencing;Service;Bundles';
        productPackage.get(0).Brand_Name__c = 'Avaya Cloud Office';
                              
        insert productPackage;
        
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        accList[0].Licenses_Purchased__c = 34;//Added for BZS-7926
        insert accList;
        
        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        insert oppList;
        
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.Change_Edition__c = 'Standard';
            quoteRecord.Status__c = 'Approved';
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
        insert quoteList;        
        
        List<Product_Catalogue__c> productCatalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
        for (Product_Catalogue__c cat: productCatalogueList) {
            cat.Product__c = productList.get(0).Id;
            cat.Product_Package__c = productPackage.get(0).Id;
            cat.Category_Name__c = 'International';
            cat.Active__c = true;
            cat.Package_Product_Type__c = 'Fixed Quantity';
            cat.Sub_Category_Name__c = 'Bundles';
        }
       
        insert productCatalogueList;
        
        List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
        productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
        productCatalougeRuleList.get(0).Product_Package__c = productPackage.get(0).Id;
        insert productCatalougeRuleList;
        
        List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
        quoteLinesItem.get(0).Product__c = productList.get(0).Id;
        quoteLinesItem.get(0).Product_Catalogue__c = productCatalogueList.get(0).Id;
        insert quoteLinesItem;
    }
    
    @isTest
    private static void testGetProductCategories() {
      //Added Licenses_Purchased__c for BZS-7926
        Account acc = [SELECT Id,name,Number_of_DL_s__c,Package_Name__c,Licenses_Purchased__c FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id,Name FROM Opportunity LIMIT 1];
        Partner_Quote__c quoteRec = [SELECT Id, Change_Edition__c, Product_Edition__c, Name FROM Partner_Quote__c LIMIT 1];
        Product_Package__c prodPackageRec = [SELECT Id, Name FROM Product_Package__c LIMIT 1];
        
        List<Product_Tier_Price__c> productTierPricesList = new List<Product_Tier_Price__c>();
        Product_Tier_Price__c productTierPrice = new Product_Tier_Price__c();
        productTierPrice.Monthly_Price__c = 1;
        productTierPrice.Yearly_Price__c = 12;
        productTierPrice.No_of_Licenses__c = 99;
        productTierPrice.CurrencyIsoCode = 'USD';
        productTierPrice.product_package__c = prodPackageRec.Id;
        productTierPricesList.add(productTierPrice);
        insert productTierPricesList;
        
        Test.startTest();
        Quote_OrderChangeRequestController.CategoryWrapper result = 
            Quote_OrderChangeRequestController.getProductCategories(prodPackageRec.Id, true, quoteRec.Id, false);
        Quote_OrderChangeRequestController.CategoryWrapper result1 = 
            Quote_OrderChangeRequestController.getProductCategories(prodPackageRec.Id, false, opp.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result can not be null');
        System.assertNotEquals(null, result.objPartnerQuoteRec, 'Partner record can not be null');
        System.assertNotEquals(null, result.parentCategoryWrapperList, 'Partner Category can not be null');
       // System.assertEquals(1, result.parentCategoryWrapperList.size(), 'Must contain single Record'); 
    }
    
    @isTest
    private static void testCreateOrderRequest() {
        Partner_Quote__c quoteRec = [SELECT Id, Change_Edition__c, Product_Edition__c, Name, Status__c, Opportunity__c FROM Partner_Quote__c LIMIT 1];
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        Product2 productRec = [SELECT Id, Name FROM Product2 LIMIT 1];
        Product_Catalogue__c catalogueRec = [SELECT Id, Name FROM Product_Catalogue__c LIMIT 1];
        String categoryString = generateWrapperString(productRec.Id, catalogueRec.Id);
        Test.startTest();
        Quote_OrderChangeRequestController.createOrderRequest(categoryString, quoteRec, true, quoteRec.Id, accRec.Id);
        Test.stopTest();
        
        List<Partner_Quote_Line__c> result = [SELECT Id FROM Partner_Quote_Line__c];
        System.assert(result.size() > 1, 'Must contain more than 1 record');
    }
    
    private static String generateWrapperString (String productId, String catalougeId) {
        Quote_OrderChangeRequestController.ProductWrapper product1 = new Quote_OrderChangeRequestController.ProductWrapper();
        product1.ProductId = productId;
        product1.catalogueId = catalougeId;
        product1.isSelected = true;
        product1.productName = 'Product - 1';
        product1.quantity = 90;
        product1.actionType = 'Add';
        product1.buttonLabel = 'Create';
        Quote_OrderChangeRequestController.ProductWrapper product2 = new Quote_OrderChangeRequestController.ProductWrapper();
        product2.ProductId = productId;
        product2.catalogueId = catalougeId;
        product2.isSelected = true;
        product2.productName = 'Product - 2';
        product2.quantity = 10;
        product2.actionType = 'Add';
        product2.buttonLabel = 'Sub Create'; 
        
        Quote_OrderChangeRequestController.SubCategoryWrapper sub = new Quote_OrderChangeRequestController.SubCategoryWrapper();
        sub.subCategoryName = 'Sub Category';
        sub.productList = new List<Quote_OrderChangeRequestController.productWrapper> {product1, product2};
            
        Quote_OrderChangeRequestController.parentCategoryWrapper parent = new Quote_OrderChangeRequestController.parentCategoryWrapper();
        parent.CategoryName = 'Category';
        parent.subCategoryList = new List<Quote_OrderChangeRequestController.SubCategoryWrapper> {sub};
            
        return JSON.serialize(new List<Quote_OrderChangeRequestController.parentCategoryWrapper>{parent});
    }
    @isTest
    private static void testGetProductCategoriesWholesale() {
      //Added Licenses_Purchased__c for BZS-7926
        Account acc = [SELECT Id,name,Number_of_DL_s__c,Package_Name__c,Licenses_Purchased__c FROM Account LIMIT 1];
        acc.Partner_Type__c = 'Wholesale-Reseller';
        update acc;
        Opportunity opp = [SELECT Id,Name FROM Opportunity LIMIT 1];
        opp.Partner_Account__c=acc.id;
        update opp;
        Partner_Quote__c quoteRec = [SELECT Id, Change_Edition__c, Product_Edition__c, Name FROM Partner_Quote__c LIMIT 1];
        Product_Package__c prodPackageRec = [SELECT Id, Name FROM Product_Package__c LIMIT 1];
         Wholesale_Partner_Package__c wpp= new Wholesale_Partner_Package__c();
        wpp.Product_Package__c=prodPackageRec.id;
        wpp.Parent_Product_Package__c=prodPackageRec.id;
        wpp.Start_Date__c=Date.today();
        wpp.End_Date__c= Date.today().addDays(15);
        wpp.Wholesale_Partner_Account__c=acc.id;
        insert wpp;
        
        List<Product_Tier_Price__c> productTierPricesList = new List<Product_Tier_Price__c>();
        Product_Tier_Price__c productTierPrice = new Product_Tier_Price__c();
        productTierPrice.Monthly_Price__c = 1;
        productTierPrice.Yearly_Price__c = 12;
        productTierPrice.No_of_Licenses__c = 99;
        productTierPrice.CurrencyIsoCode = 'USD';
        productTierPrice.product_package__c = prodPackageRec.Id;
        productTierPricesList.add(productTierPrice);
        insert productTierPricesList;
        
        Test.startTest();
        Quote_OrderChangeRequestController.CategoryWrapper result = 
            Quote_OrderChangeRequestController.getProductCategories(prodPackageRec.Id, true, quoteRec.Id, false);
        Quote_OrderChangeRequestController.CategoryWrapper result1 = 
            Quote_OrderChangeRequestController.getProductCategories(prodPackageRec.Id, false, opp.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result can not be null');
        System.assertNotEquals(null, result.objPartnerQuoteRec, 'Partner record can not be null');
        System.assertNotEquals(null, result.parentCategoryWrapperList, 'Partner Category can not be null');
       // System.assertEquals(1, result.parentCategoryWrapperList.size(), 'Must contain single Record'); 
    }
}