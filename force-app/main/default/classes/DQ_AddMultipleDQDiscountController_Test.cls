@isTest
private class DQ_AddMultipleDQDiscountController_Test {

    @testSetup
    private static void testSetup() {
        DQApprovalTestDataFactory.generateDealQualificationWithConfig();
        List<Product2> listofProduct = [SELECT Id FROM Product2];
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Standard';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Product_Categories__c = 'International';

        insert productPackage;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
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
            cat.Approval__c = true;
            cat.Package_Product_Type__c = 'Fixed Quantity';
            cat.Sub_Category_Name__c = 'Bundles';
        }
        productCatalogueList.addAll(Quote_TestDataFactory.generateProductCatalouge(3));
        productCatalogueList[2].Product__c = listofProduct[0].Id;
        productCatalogueList[2].Product_Package__c = productPackage.get(0).Id;
        productCatalogueList[2].Category_Name__c = 'International';
        productCatalogueList[2].Active__c = true;
        productCatalogueList[2].Approval__c = true;
        productCatalogueList[2].Package_Product_Type__c = 'Fixed Quantity';
        productCatalogueList[2].Sub_Category_Name__c = 'Bundles';

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

    private static List<DQ_Deal_Qualification__c> getDealQualification() {
        return [SELECT Id,Brand__c,Deal_Type__c,Region__c,Segment__c,Name,Minimum_Package_s__c,opportunity__r.Name, Type__c, Special_Terms__c, Sub_Region__c,
                Charge_Term__c,Initial_Term__c,Opportunity__c,Renewal_Term__c,Status__c, Deal_Size__c, Overall_Discount__c, Justification_Description__c
                FROM DQ_Deal_Qualification__c ];
    }

    @isTest
    private static void testGetProductCategories() {
        Test.startTest();
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        Product_Package__c prodPackageRec = [SELECT Id, Name FROM Product_Package__c LIMIT 1];
        DQ_AddMultipleDQDiscountController.CategoryWrapper result =
            DQ_AddMultipleDQDiscountController.getProductCategories(prodPackageRec.Id,listOfDealQualification[0].Id, null, false,'Sales Quote');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result can not be null');
        System.assertNotEquals(null, result.objPartnerQuoteRec, 'Partner record can not be null');
        System.assertNotEquals(null, result.parentCategoryWrapperList, 'Partner Category can not be null');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void createDQDiscountwithoutExisting() {
        Test.startTest();
        List<DQ_Deal_Qualification__c> listOfDealQualification = getDealQualification();
        Product2 productRec = [SELECT Id, Name FROM Product2 LIMIT 1];
        Product_Catalogue__c catalogueRec = [SELECT Id, Name FROM Product_Catalogue__c LIMIT 1];
        String categoryString = generateWrapperString(productRec.Id, catalogueRec.Id);
        DQ_AddMultipleDQDiscountController.createDQDiscount(categoryString,listOfDealQualification[0].Id, 'Sales Quote');
        Test.stopTest();
    }

    private static String generateWrapperString (String productId, String catalougeId) {
        DQ_AddMultipleDQDiscountController.ProductWrapper product1 = new DQ_AddMultipleDQDiscountController.ProductWrapper();
        product1.ProductId = productId;
        product1.catalogueId = catalougeId;
        product1.isSelected = true;
        product1.productName = 'Product - 1';
        product1.quantity = 90;
        product1.actionType = 'Add';
        product1.isExisting = false;
        product1.buttonLabel = 'Create';
        DQ_AddMultipleDQDiscountController.ProductWrapper product2 = new DQ_AddMultipleDQDiscountController.ProductWrapper();
        product2.ProductId = productId;
        product2.catalogueId = catalougeId;
        product2.isSelected = true;
        product2.productName = 'Product - 2';
        product2.quantity = 10;
        product2.isExisting = true;
        product2.actionType = 'Add';
        product2.buttonLabel = 'Sub Create';
        product2.objDQDiscount = [SELECT Id FROM DQ_Deal_Qualification_Discounts__c LIMIT 1].Id;

        DQ_AddMultipleDQDiscountController.SubCategoryWrapper sub = new DQ_AddMultipleDQDiscountController.SubCategoryWrapper();
        sub.subCategoryName = 'Sub Category';
        sub.productList = new List<DQ_AddMultipleDQDiscountController.productWrapper> {product1, product2};

        DQ_AddMultipleDQDiscountController.parentCategoryWrapper parent = new DQ_AddMultipleDQDiscountController.parentCategoryWrapper();
        parent.CategoryName = 'Category';
        parent.subCategoryList = new List<DQ_AddMultipleDQDiscountController.SubCategoryWrapper> {sub};

        return JSON.serialize(new List<DQ_AddMultipleDQDiscountController.parentCategoryWrapper>{parent});
    }
}