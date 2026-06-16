@isTest
public class QuotePlanAndPricingControllerTest {

    @isTest
    private static void testGetCurrentUser() {
    // When

    Test.startTest();
    User result = QuotePlanAndPricingController.getCurrentUser();
        Test.stopTest();

        // Then
        System.assertNotEquals(null, result, 'Must return logged in user');
        System.assertEquals(UserInfo.getUserId(), result.Id, 'User Id must be logged in user Id');
    }

    @isTest
    private static void testCheckSuperUser() {
        // When

    Test.startTest();
        Boolean result = QuotePlanAndPricingController.checkSuperUser();
        Test.stopTest();

        // Then
        System.assertEquals(true, result, 'Super user must be true');
    }

    @isTest
    private static void testGetProductEditions() {

        // When
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

        insert productPackage;

        Product_Tier_Price__c objTier = new Product_Tier_Price__c();
        objTier.No_of_Licenses__c = 9999;
        objTier.Monthly_Price__c = 150;
        objTier.Yearly_Price__c = 1500;
        objTier.Product_Package__c = productPackage.get(0).Id;
        objTier.CurrencyIsoCode = 'USD';
        insert objTier;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;


        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        oppList[0].CurrencyIsoCode = 'USD';
        insert oppList;
        String brand = QuotePlanAndPricingController.getBrandNameFromOppOrQuote(oppList[0].Id);
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId();
        }
        insert quoteList;

        Test.startTest();
          QuotePlanAndPricingController.topMasterWrapper topresult = QuotePlanAndPricingController.checkIsTopMaster(brand);
          List<QuotePlanAndPricingController.productEditionWrapper> result = QuotePlanAndPricingController.getProductEditions(oppList[0].Id,'');
        List<QuotePlanAndPricingController.productEditionWrapper> result2 = QuotePlanAndPricingController.getProductEditions(quoteList[0].Id,'');
        Test.stopTest();

        System.assertNotEquals(null, result, 'result must not be null');
        //System.assertEquals(1, result.size(), 'result must contain one record');
        //System.assertNotEquals(null, result.get(0).listOfPickValue, 'result must contain pick value');
    }

    @isTest
    private static void testGetProductEdition() {

        // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;
        insert productPackage;

        Test.startTest();
          Product_Package__c result = QuotePlanAndPricingController.getProductEdition(productPackage.get(0).Id);
        Test.stopTest();

        //THEN
        System.assertNotEquals(null, result, 'Product Package must be available');
        System.assertEquals('Product Package Name', result.Name, 'Result record must have same name');
    }

    @isTest
    private static void testGetQuote() {
       // When
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

        insert productPackage;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;

        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        insert oppList;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId();
        }
        insert quoteList;

        Test.startTest();
          Partner_Quote__c result = QuotePlanAndPricingController.getQuote(quoteList.get(0).Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Quote record must be fetched');
        System.assertEquals(oppList.get(0).Id, result.Opportunity__c, 'Must have same Opp Id');
    }

    @isTest
    private static void testCloneQuote() {
       // When
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

        insert productPackage;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;

        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        insert oppList;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId();
        }
        insert quoteList;

        User userSysAdmin = createSysAdminUser();

        Test.startTest();
          Id result = QuotePlanAndPricingController.cloneQuote(quoteList.get(0).Id);
          System.runAs(userSysAdmin) {
            QuotePlanAndPricingController.loadHideDiscountFlag(quoteList.get(0).Id);
          }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Quote record must be created');
    }

    @isTest
    private static void testGetCurrentUserInfo() {
        // WHEN
        Test.startTest();
          User result = QuotePlanAndPricingController.getCurrentUserInfo();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Logged in user can not be null');
        System.assertEquals(UserInfo.getUserType(), result.UserType, 'User type fetched as per result');
    }

    @isTest
    private static void testDeleteQuoteLine() {

        // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

        insert productPackage;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;

        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        insert oppList;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
    insert quoteList;

        List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
        insert quoteLinesItem;

        //THEN
        Test.startTest();
          List<QuotePlanAndPricingController.ProductWrapper> result = QuotePlanAndPricingController.deleteQuoteLine(quoteList.get(0).Id, quoteLinesItem.get(0).Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not contain any product catelogue');
        System.assertEquals(0, result.size(), 'Result must have any records');
    }

    @isTest
    private static void testDeleteQuoteLineFromProductId() {
            // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

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
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
    insert quoteList;

        List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
        quoteLinesItem.get(0).Product__c = productList.get(0).Id;
        insert quoteLinesItem;

        Test.startTest();
          QuotePlanAndPricingController.deleteQuoteLineFromProductId(quoteList.get(0).Id, productList.get(0).Id);
        Test.stopTest();

        List<Partner_Quote_Line__c> quoteLineRecord = [SELECT Id, Name FROM Partner_Quote_Line__c WHERE Id=:quoteLinesItem.get(0).Id];
        System.assertEquals(0, quoteLineRecord.size(), 'No record fetch');
    }

    @isTest
    private static void testGetProductsFromQuote() {
        // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

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
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
    insert quoteList;

        List<Product_Catalogue__c> productCatalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
        productCatalogueList.get(0).Product__c = productList.get(0).Id;
        productCatalogueList.get(0).Package_Product_Type__c = 'Fixed Quantity';
        insert productCatalogueList;

        List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
        productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
        productCatalougeRuleList.get(0).Product_Package__c = productPackage.get(0).Id;
        insert productCatalougeRuleList;

        List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
        quoteLinesItem.get(0).Product__c = productList.get(0).Id;
        quoteLinesItem.get(0).Product_Catalogue__c = productCatalogueList.get(0).Id;
        insert quoteLinesItem;

        Test.startTest();
          List<QuotePlanAndPricingController.ProductWrapper> result = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must be prsent');
        System.assertEquals(1, result.size(), 'Must present 1 record');
    }

    @isTest
    private static void testGetProductsForEdition() {
         // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

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
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
    insert quoteList;

        List<Product_Catalogue__c> productCatalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
        productCatalogueList.get(0).Product__c = productList.get(0).Id;
        productCatalogueList.get(0).Package_Product_Type__c = 'Fixed Quantity';
        insert productCatalogueList;

        List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
        productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
        productCatalougeRuleList.get(0).Product_Package__c = productPackage.get(0).Id;
        insert productCatalougeRuleList;

        List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
        quoteLinesItem.get(0).Product__c = productList.get(0).Id;
        quoteLinesItem.get(0).Product_Catalogue__c = productCatalogueList.get(0).Id;
        insert quoteLinesItem;

        Test.startTest();
          List<QuotePlanAndPricingController.ProductWrapper> result = QuotePlanAndPricingController.getProductsForEdition(
                quoteList.get(0).Id, null, null, false, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result can not must be null');
        System.assertEquals(0, result.size(), 'No record fetched');
    }

    @isTest
    private static void testValidateRules() {
             // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

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
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
    insert quoteList;

        Test.startTest();
        List<QuotePlanAndPricingController.ProductWrapper> result = QuotePlanAndPricingController.validateRules(quoteList.get(0).Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result can not be null');
        System.assertEquals(0, result.size(), 'Result can not be fetched');
    }

    @isTest
    private static void testCreateUpdatePartnerQuote() {
        // WHEN
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

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
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        }
    insert quoteList;

        Test.startTest();
        Partner_Quote__c result = QuotePlanAndPricingController.createUpdatePartnerQuote(oppList.get(0).Id,
                                                                                         quoteList.get(0),
                                                                                         null, true,
                                                                                         false);
        Test.stopTest();

        QuotePlanAndPricingController.getInfo(oppList.get(0).Id);
        System.assertNotEquals(null, result, 'Partner Quote must be create');
        System.assertEquals(oppList.get(0).Id, result.Opportunity__c, 'Opportunity id must be linked with created record');
    }

    @isTest
    private static void testGetProductCategories() {
           // WHEN
List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Standard';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

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
            //cat.Package_Product_Type__c = 'Quantity same as parent';
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

        Test.startTest();
          List<QuotePlanAndPricingController.AdditionalProductWrapper> result = QuotePlanAndPricingController.getProductCategories(
                productPackage.get(0).Id,quoteList.get(0));
        Test.stopTest();

        System.assertNotEquals(null, result, 'List can not be null');
        System.assertEquals(1, result.size(), 'Record Fetched');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetProductEditionsWholesale() {

        // When
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

        insert productPackage;

        Product_Tier_Price__c objTier = new Product_Tier_Price__c();
        objTier.No_of_Licenses__c = 9999;
        objTier.Monthly_Price__c = 150;
        objTier.Yearly_Price__c = 1500;
        objTier.Product_Package__c = productPackage.get(0).Id;
        objTier.CurrencyIsoCode = 'USD';
        insert objTier;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].Partner_Type__c='Wholesale-Reseller';
        insert accList;


        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        oppList[0].CurrencyIsoCode = 'USD';
        oppList[0].Partner_Account__c=accList[0].id;
        insert oppList;
        String brand = QuotePlanAndPricingController.getBrandNameFromOppOrQuote(oppList[0].Id);
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId();
        }
        insert quoteList;
        Wholesale_Partner_Package__c wpp= new Wholesale_Partner_Package__c();
        wpp.Product_Package__c=productPackage[0].id;
        wpp.Parent_Product_Package__c=productPackage[0].id;
        wpp.Start_Date__c=Date.today();
        wpp.End_Date__c= Date.today().addDays(15);
        wpp.Wholesale_Partner_Account__c=accList[0].id;
        insert wpp;

        Test.startTest();
          QuotePlanAndPricingController.topMasterWrapper topresult = QuotePlanAndPricingController.checkIsTopMaster(brand);
          List<QuotePlanAndPricingController.productEditionWrapper> result = QuotePlanAndPricingController.getProductEditions(oppList[0].Id,productPackage[0].id);
        List<QuotePlanAndPricingController.productEditionWrapper> result2 = QuotePlanAndPricingController.getProductEditions(quoteList[0].Id,'');
        Test.stopTest();

        System.assertNotEquals(null, result, 'result must not be null');
        //System.assertEquals(1, result.size(), 'result must contain one record');
        //System.assertNotEquals(null, result.get(0).listOfPickValue, 'result must contain pick value');
    }

    private static User createSysAdminUser() {

        List<Profile> profilesByNames = (List<Profile>) new ProfileSelector()
            .selectProfilesByNames(new List<Object>{new Set<String>{'System Administrator'}})
            .executeQuery();

        User userSysAdmin = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.ProfileId => profilesByNames[0].Id,
                    User.Username => System.now().millisecond()+ 'test21351521456@test.com',
                    User.Alias => 'batndfw',
                    User.Email => 'John.Doe@testemail.com',
                    User.EmailEncodingKey => 'UTF-8',
                    User.Firstname => 'John',
                    User.Lastname => 'Doe',
                    User.LanguageLocaleKey => 'en_US',
                    User.LocaleSidKey => 'en_US',
                    User.TimeZoneSidKey => 'America/Chicago',
                    User.Country__c => 'United States'
                }
            )
            .create()
            .getRecord();
        return userSysAdmin;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetOpportunityCurrency() {

        // When
        List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
        productPackage.get(0).Name = 'Product Package Name';
        productPackage.get(0).Active__c = true;
        productPackage.get(0).Description__c = 'Test Description';
        productPackage.get(0).Active__c = true;

        insert productPackage;

        Product_Tier_Price__c objTier = new Product_Tier_Price__c();
        objTier.No_of_Licenses__c = 9999;
        objTier.Monthly_Price__c = 150;
        objTier.Yearly_Price__c = 1500;
        objTier.Product_Package__c = productPackage.get(0).Id;
        objTier.CurrencyIsoCode = 'USD';
        insert objTier;

        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].Partner_Type__c='Wholesale-Reseller';
        insert accList;


        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        oppList[0].CurrencyIsoCode = 'USD';
        oppList[0].Partner_Account__c=accList[0].id;
        insert oppList;
        String brand = QuotePlanAndPricingController.getOpportunityCurrency(oppList[0].Id);
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
        for(Partner_Quote__c quoteRecord : quoteList) {
            quoteRecord.Product_Edition__c = productPackage.get(0).Id;
            quoteRecord.Opportunity__c = oppList.get(0).Id;
            quoteRecord.User__c = UserInfo.getUserId();
            quoteRecord.RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote Template').getRecordTypeId();
        }
        insert quoteList;
        Wholesale_Partner_Package__c wpp= new Wholesale_Partner_Package__c();
        wpp.Product_Package__c=productPackage[0].id;
        wpp.Parent_Product_Package__c=productPackage[0].id;
        wpp.Start_Date__c=Date.today();
        wpp.End_Date__c= Date.today().addDays(15);
        wpp.Wholesale_Partner_Account__c=accList[0].id;
        insert wpp;

        Test.startTest();
          QuotePlanAndPricingController.topMasterWrapper topresult = QuotePlanAndPricingController.checkIsTopMaster(brand);
          List<QuotePlanAndPricingController.productEditionWrapper> result = QuotePlanAndPricingController.getProductEditions(oppList[0].Id,productPackage[0].id);
        List<QuotePlanAndPricingController.productEditionWrapper> result2 = QuotePlanAndPricingController.getProductEditions(quoteList[0].Id,'');
        Test.stopTest();

        System.assertNotEquals(null, result, 'result must not be null');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')   
	@isTest
    static void testGetOtherDetails() {
        // Create a test user with a unique username
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1]; 
        String uniqueUsername = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        User testUser = new User(
            Alias = 'standt',
            Email = 'u123@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert testUser;
        
        System.runAs(testUser) {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;

        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        insert oppList;

        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;
            
            List<Product_Package__c> productPackage = Quote_TestDataFactory.generateProductPackage(1);
            productPackage.get(0).Name = 'Standard';
            productPackage.get(0).Active__c = true;
            productPackage.get(0).Description__c = 'Test Description';
            productPackage.get(0).Active__c = true;
    
            insert productPackage;
            
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
            
            Test.startTest();
            QuotePlanAndPricingController.UserInformationWrapper result = QuotePlanAndPricingController.getOtherDetails(quoteList[0].Id);
            Test.stopTest();
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')    
    @isTest
    private static void testGetQuoteMain() {
        Account testAccount = new Account(Name = 'Test Account', BillingCountry = 'United States');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert testQuote;

        Test.startTest();
        List<Quote> result = Quote_PartnerQuoteUtil.getQuoteMain(testOpportunity.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Result size should be 1');
        System.assertEquals(testQuote.Id, result[0].Id, 'Quote ID should match');

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testCreateDealSprtForEngageProServ() {
        Account testAccount = new Account(Name = 'Test Account', BillingCountry = 'United States');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert testQuote;
        String quoteId = testQuote.Id;
        Boolean availProServ = true;
        String proServNotes = 'Test ProServ Notes';

        Test.startTest();
        String result = Quote_PartnerDetailController.createDealSprtForEngageProServ(quoteId, availProServ, proServNotes);
        Test.stopTest();
    }

}