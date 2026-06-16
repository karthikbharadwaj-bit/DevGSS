@isTest
public class Quote_PartnerQuoteUtilTest {

    @isTest
    static void test_method_one() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;


            quoteList[0].opportunity__c = opp.Id;
            update quoteList;
            Quote_PartnerQuoteUtil objUtil = new Quote_PartnerQuoteUtil();
            Partner_Quote__c objQuote = Quote_PartnerQuoteUtil.getQuote(quoteList[0].Id);
            Quote_PartnerQuoteUtil.getQuoteLinesForSummary(quoteList[0].Id);
            List<Partner_Quote__c> listOfPartnerQuote = Quote_PartnerQuoteUtil.getQuotes(opp.Id);
            Quote_PartnerQuoteUtil.getQuoteLinesForOutput(opp.Id);
            String oppName = Quote_PartnerQuoteUtil.getOpportunity(opp.Id);
            Quote_PartnerQuoteUtil.getAccount(accList[0].Id);
            System.assertEquals('test', oppName);
            System.assertEquals(true, objQuote.Id != null);
            //System.assertEquals(1, listOfPartnerQuote.size());
        //}
    }

    @isTest
    static void test_method_two() {
        // IF Account Checklist Exist
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;

            List<Account_Change_Request__c> listOfAccountChangeRequest = Quote_TestDataFactory.generateAccountChangeRequest(1,accList[0].Id);
            insert listOfAccountChangeRequest;

            Account_Change_Request__c acrRec = Quote_PartnerQuoteUtil.getAccountChangeRequest(listOfAccountChangeRequest[0].Id);
            Quote_PartnerQuoteUtil.createAccountChangeRequest(new Account_Change_Request__c(), accList[0].Id);
            System.assertEquals(true, acrRec.Id != null);

    }

    @isTest
    static void test_method_three() {
       List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            String cloneQuoteId = Quote_PartnerQuoteUtil.cloneQuote(quoteList[0].Id);
            System.assertEquals(true, cloneQuoteId != null);
            Quote_PartnerQuoteUtil.deleteQuote(cloneQuoteId);
            Quote_PartnerQuoteUtil.getProductsFromQuote(quoteList[0].Id);


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
     static void test_method_four() {
       List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_Term__c = 'Monthly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).Show_Header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(3);
            catalogueList[0].Product_Package__c = packageList.get(0).Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[0].Product__c = productList.get(0).Id;

            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[0].Has_child__c = true;

            insert catalogueList;
            catalogueList[0].parent__c = catalogueList[2].Id;
            catalogueList[1].parent__c = catalogueList[0].Id;
            catalogueList[2].parent__c = catalogueList[1].Id;
            catalogueList[1].Product_Package__c = packageList.get(0).Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[1].Product__c = productList.get(0).Id;
            // catalogueList[1].Parent__c = catalogueList[0].Id;
            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[0].Has_child__c = true;

            update catalogueList;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                if (count == 3) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;

            Quote_PartnerQuoteUtil.getProductCategories(packageList[0].Id,quoteList[0]);
            List<String> subCategoryList = new List<String>{'Implementation'};
            Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers','Add-Ons',true,subCategoryList);
            Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers','',true,subCategoryList);
            Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers','test',false,null);
            Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers','test',false,subCategoryList);
    }


    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_five() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            insert quoteList;
            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            Quote_PartnerQuoteUtil.getPhoneProductFROMQuoteLine(quoteList[0].Id);
            //Quote_PartnerQuoteUtil.createPOCRequest(quoteList[0]);
            Quote_PartnerQuoteUtil.calculateEndDate(quoteList[0]);
            Quote_PartnerQuoteUtil.getFiles(quoteList[0].Id);
            Quote_PartnerQuoteUtil.addAddressRow(JSON.serialize((new List<Account_Checklist_Address__c>())));
            //Quote_PartnerQuoteUtil.checkSuperUser();
            Quote_PartnerQuoteUtil.getQueueId('Avaya_Queue');
            Quote_PartnerQuoteUtil.createDealSupport();
            List<Partner_Quote__c> quoteList2 = Quote_TestDataFactory.generateQuotes(1);
            Quote_PartnerQuoteUtil.createOrderRequest(quoteList2[0],opp.Id);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_Six() {
         List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            opp.Brand_Name__c='RingCentral';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            insert listofAccountChecklist;

            Area_Codes__c areaCode=new Area_Codes__c();
            areaCode.Account_Checklist__c=listofAccountChecklist[0].Id;
            insert areaCode;

        	Quote_PartnerQuoteUtil.getAreaCodeListsForAccountChecklists(listofAccountChecklist[0].Id);
            Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            objDealSupp.Type__c = 'Initial Order';
            insert objDealSupp;

            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quote.Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',false,true,null,true,quote);
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quote.Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',true,true,null,true,quote);


            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quote.Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',false,true,null,false,quote);


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_Seven() {
        Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;
            Quote_PartnerDetailController.updateQuoteLines(JSON.serialize(quoteLineList));
            Quote_PartnerDetailController.deleteQuoteLine(quoteList[0].id,quoteLineList[0].Id);
            Quote_PartnerDetailController.updateQuotes(null,quoteList);


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_Eight() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Opportunity__c = opp.id;
        insert quoteList;

        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;

        Quote_PartnerDetailController.updateQuote(quoteList[0],true,2.0,'test',true,true,'test','Amt');
        Quote_PartnerDetailController.getQuotes(opp.Id);
        Quote_PartnerDetailController.deleteQuote(quoteList[0].Id);
        //}


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_Eight_A() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Opportunity__c = opp.id;
        insert quoteList;

        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;

        Quote_PartnerDetailController.updateQuote(quoteList[0],true,2.0,'test',true,true,'test','%');
        Quote_PartnerDetailController.getQuotes(opp.Id);
        Quote_PartnerDetailController.deleteQuote(quoteList[0].Id);
        //}


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_ten() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[1].Product__c = productList.get(0).Id;

            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;

            update catalogueList;


            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            //quoteLinesItem.get(0).Quantity__c = null;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                if (count == 3) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;


            Quote_PartnerQuoteUtil.getProductCategories(packageList[0].Id,quoteList[0]);
            List<String> subCategoryList = new List<String>{'Implementation'};

                Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers',null,true,subCategoryList);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_eleven() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[1].Product__c = productList.get(0).Id;

            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            //catalogueList[0].Parent__c = catalogueList[1].Id;
            update catalogueList;


            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                if (count == 3) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;


            Quote_PartnerQuoteUtil.getProductCategories(packageList[0].Id,quoteList[0]);
            List<String> subCategoryList = new List<String>{'Implementation'};

                Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers',null,true,subCategoryList);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testValidateRules() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'EU - Parent dependent quantity';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].Product_Catalogue_Rule__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[0].Parent__c = catalogueList[1].Id;
            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[1].Product__c = productList.get(0).Id;

            catalogueList[1].Product_Catalogue_Rule__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[1].Parent__c = catalogueList[0].Id;
            update catalogueList;

            productCatalougeRuleList.get(0).Count_Dependent_On__c = catalogueList[0].Id;
            update productCatalougeRuleList;

            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                if (count == 3) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;
            List<QuotePlanAndPricingController.ProductWrapper> wrapper = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
            //System.assert(false,wrapper);
            //wrapper[0].objRule = productCatalougeRuleList[0];
            Test.startTest();
            List<QuotePlanAndPricingController.ProductWrapper> result = Quote_PartnerQuoteUtil.validateRules(quoteList[0].Id, wrapper);
            Map<Id,List<QuotePlanAndPricingController.ProductWrapper>> mapObj = new Map<Id,List<QuotePlanAndPricingController.ProductWrapper>>();
            mapObj.put(productList.get(0).Id,new List<QuotePlanAndPricingController.ProductWrapper>{result[0]});
            Map<Id, QuotePlanAndPricingController.ProductWrapper> mapofIdVSCatalogue = new Map<Id, QuotePlanAndPricingController.ProductWrapper>();
            mapofIdVSCatalogue.put(catalogueList[0].Id,result[0]);
            Map<Id, Set<Id>> objParentMap = new Map<Id, Set<Id>>();
            objParentMap.put(catalogueList[0].Id,new set<Id>{catalogueList[0].Id});
            Quote_PartnerQuoteUtil.addRelationship(objParentMap,catalogueList[0].Id,catalogueList[0].Id);
            Test.stopTest();


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testCreateUpdatePartnerQuote() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[1].Product__c = productList.get(0).Id;

            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            //catalogueList[0].Parent__c = catalogueList[1].Id;
            update catalogueList;


            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                if (count == 3) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;
            List<QuotePlanAndPricingController.ProductWrapper> wrapper = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
            Test.startTest();
            //Partner_Quote__c result = Quote_PartnerQuoteUtil.createUpdatePartnerQuote(oppList.get(0).Id, quoteList.get(0), wrapper, true, true);
             Test.stopTest();
            //System.assert(false, result);


    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testCreateUpdatePartnerQuoteNewRecord() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).CurrencyIsoCode = 'USD';
            quoteList.get(0).Number_of_Licenses__c = 5;
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Default';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Default';
            catalogueList[1].Product__c = productList.get(0).Id;
            catalogueList[1].Default_Quantity__c = 3;
            catalogueList[0].Default_Quantity__c = 3;
            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            //catalogueList[0].Parent__c = catalogueList[1].Id;
            update catalogueList;


            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.CurrencyIsoCode = 'USD';
                pp.Yearly_Price__c = 1500;
                pp.No_of_Licenses__c = 12;
                if (count == 3 && count == 2) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;
            List<QuotePlanAndPricingController.ProductWrapper> wrapper = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
            Test.startTest();
            Partner_Quote__c result = Quote_PartnerQuoteUtil.createUpdatePartnerQuote(oppList.get(0).Id, quoteList.get(0).clone(false, true), wrapper, true, true);
             Test.stopTest();



    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testCalculateNetPrice() {
        Double listPrice = 12.123;
        Test.startTest();
            Quote_PartnerQuoteUtil.calculateNetPrice(listPrice, 5.0, 2.0, '%');
            Quote_PartnerQuoteUtil.calculateNetPrice(listPrice, 5.0, 2.0, 'Amt');
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
        @isTest
    private static void testPopulateRuleInfo() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).Number_of_Licenses__c = 5;
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Default';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Default';
            catalogueList[1].Product__c = productList.get(0).Id;
            catalogueList[1].Default_Quantity__c = 3;
            catalogueList[0].Default_Quantity__c = 3;
            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            //catalogueList[0].Parent__c = catalogueList[1].Id;
            update catalogueList;


            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                pp.No_of_Licenses__c = 12;
                if (count == 3 && count == 2) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;
            List<QuotePlanAndPricingController.ProductWrapper> wrapper = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
            System.debug('wrapper>>>'+wrapper);
            //QuotePlanAndPricingController.ProductWrapper objClone = wrapper[0];
            //objClone.objProduct = productList.get(0);
            Map<Id, Decimal> mapOfParentIdDLMSVsQuantity = new Map<Id, Decimal>();
            QuotePlanAndPricingController.ProductWrapper objCloneWrapp = new QuotePlanAndPricingController.ProductWrapper();
            objCloneWrapp.objProduct = productList.get(0);
            Map<Id, List<QuotePlanAndPricingController.ProductWrapper>> mapOfParentIdVsChildProducts = new Map<Id, List<QuotePlanAndPricingController.ProductWrapper>>();
            mapOfParentIdVsChildProducts.put(catalogueList[1].Id,wrapper);
            Map<Id, QuotePlanAndPricingController.ProductWrapper> mapOfCatalogueIdVsRecord = new Map<Id, QuotePlanAndPricingController.ProductWrapper>();
            mapOfCatalogueIdVsRecord.put(catalogueList[0].Id,objCloneWrapp);
            Test.startTest();
            Quote_PartnerQuoteUtil.populateRuleInfo( wrapper, true);
            Quote_PartnerQuoteUtil.updateQuoteProduct(quoteList.get(0).Id,wrapper,mapOfParentIdVsChildProducts,mapOfCatalogueIdVsRecord,mapOfParentIdDLMSVsQuantity);
             Test.stopTest();



    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_twelve() {
         List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            //insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/

            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[1].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',false,true,null,true,quoteList[1]);
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[1].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',true,true,new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()},true,quoteList[1]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_thirteen() {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/
            List<Deal_Support__c> dealSupportList = [Select Id,Partner_Quote__c FROM Deal_Support__c];
            delete dealSupportList;
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',true,true,new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()},true,quoteList[0]);

    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_fourteen() {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/
            List<Deal_Support__c> dealSupportList = [Select Id,Partner_Quote__c FROM Deal_Support__c];
            delete dealSupportList;
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',false,true,new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()},true,quoteList[0]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_fifteen() {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            //insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/
            List<Deal_Support__c> dealSupportList = [Select Id,Partner_Quote__c FROM Deal_Support__c];
            delete dealSupportList;
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',false,true,new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()},true,quoteList[0]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_sixteen() {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            //insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/
            List<Deal_Support__c> dealSupportList = [Select Id,Partner_Quote__c FROM Deal_Support__c];
            delete dealSupportList;
            List<Account_Checklist_Address__c> addRessList = new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()};
             insert addRessList;
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',false,true,addRessList,true,quoteList[0]);
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',true,true,addRessList,true,quoteList[0]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_seventeen() {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            //insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/
            List<Deal_Support__c> dealSupportList = [Select Id,Partner_Quote__c FROM Deal_Support__c];
            delete dealSupportList;
            List<Account_Checklist_Address__c> addRessList = new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()};
             insert addRessList;
            List<Area_Codes__c> areaCodeList = new List<Area_Codes__c>{new Area_Codes__c()};
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,areaCodeList
                                                          ,'Yes',false,true,addRessList,true,quoteList[0]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void test_method_ninteen() {
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(2);
            quoteList[0].Start_Date__c = System.today();
            quoteList[0].Opportunity__c = opp.Id;
            quoteList[0].Initial_Term__c = '12';
            quoteList[1].Start_Date__c = System.today();
            quoteList[1].Opportunity__c = opp.Id;
            quoteList[1].Initial_Term__c = '12';

            insert quoteList;


            Partner_Quote__c quote = quoteList[0];


            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            catalogueList[0].Category_Name__c = 'Phones';
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quote.Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
            List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            //insert listofAccountChecklist;
            //Quote_PartnerQuoteUtil.updateAccountChecklist(new Account_Checklist__c(),accList[0].Id);
            //Quote_PartnerQuoteUtil.updateAccountChecklist(listofAccountChecklist[0],accList[0].Id);

            /*Deal_Support__c objDealSupp = new Deal_Support__c();
            objDealSupp.partner_Quote__c = quote.Id;
            insert objDealSupp;*/
            List<Deal_Support__c> dealSupportList = [Select Id,Partner_Quote__c FROM Deal_Support__c];
            delete dealSupportList;
            List<Account_Checklist_Address__c> addRessList = new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()};
             insert addRessList;
            Quote_PartnerQuoteUtil.updateAccountChecklist(false,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null
                                                          ,'Yes',true,true,addRessList,true,quoteList[0]);

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void test_method_twenty() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).Number_of_Licenses__c = 5;
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Default';
            catalogueList[0].Product__c = productList.get(0).Id;
            //catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            /*catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Default';
            catalogueList[1].Product__c = productList.get(0).Id;
            catalogueList[1].Default_Quantity__c = 3;
            catalogueList[0].Default_Quantity__c = 3;
            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            //catalogueList[0].Parent__c = catalogueList[1].Id;
            update catalogueList;
            */

            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                pp.No_of_Licenses__c = 12;
                if (count == 3 && count == 2) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;
            List<QuotePlanAndPricingController.ProductWrapper> wrapper = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
            Test.startTest();
            Partner_Quote__c result = Quote_PartnerQuoteUtil.createUpdatePartnerQuote(oppList.get(0).Id, quoteList.get(0), wrapper, true, true);
             Test.stopTest();
        }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void test_method_twentyone() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).Payment_term__c = 'Monthly';
            quoteList.get(0).CurrencyIsoCode = 'USD';
            quoteList.get(0).Number_of_Licenses__c = 5;
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Default';
            catalogueList[0].Product__c = productList.get(0).Id;
            //catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            /*catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Default';
            catalogueList[1].Product__c = productList.get(0).Id;
            catalogueList[1].Default_Quantity__c = 3;
            catalogueList[0].Default_Quantity__c = 3;
            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            //catalogueList[0].Parent__c = catalogueList[1].Id;
            update catalogueList;
            */

            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            quoteLinesItem.get(0).Quantity__c = 333;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.Yearly_Price__c = 1500;
                pp.CurrencyIsoCode = 'USD';
                pp.No_of_Licenses__c = 12;
                if (count == 3 && count == 2) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                count++;
            }

            insert priceTireList;
            List<QuotePlanAndPricingController.ProductWrapper> wrapper = QuotePlanAndPricingController.getProductsFromQuote(quoteList.get(0).Id);
            Test.startTest();
            Partner_Quote__c result = Quote_PartnerQuoteUtil.createUpdatePartnerQuote(oppList.get(0).Id, quoteList.get(0), wrapper, true, true);
            Partner_Quote__c result1 = Quote_PartnerQuoteUtil.createUpdatePartnerQuote(oppList.get(0).Id, quoteList.get(0), wrapper, true, false);
             Test.stopTest();
        }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_twentyTwo() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
        insert productList;


        List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
        packageList.get(0).Name = 'Product Package Name';
        packageList.get(0).Active__c = true;
        packageList.get(0).Description__c = 'Test Description';
        packageList.get(0).Active__c = true;

        insert packageList;
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        accList[0].BillingCountry = 'United States';
        insert accList;

        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
        insert oppList;

        List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
            1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
        insert subsList;

        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
        quoteList.get(0).Opportunity__c = oppList.get(0).Id;
        quoteList.get(0).User__c = UserInfo.getUserId();
        quoteList.get(0).Subscription__c = subsList.get(0).Id;
        quoteList.get(0).Payment_Term__c = 'Monthly';
        quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

        insert quoteList;

        List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
        productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
        productCatalougeRuleList.get(0).Rule_type__c= 'LB';
        productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
        productCatalougeRuleList.get(0).Show_Header__c = true;
        insert productCatalougeRuleList;

        List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(3);
        catalogueList[0].Product_Package__c = packageList.get(0).Id;
        catalogueList[0].Category_Name__c = 'Add-Ons';
        catalogueList[0].Active__c= true;
        catalogueList[0].Sub_Category_Name__c = 'Implementation';
        catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
        catalogueList[0].Product__c = productList.get(0).Id;

        catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
        catalogueList[0].Has_child__c = true;

        insert catalogueList;
        catalogueList[0].parent__c = catalogueList[2].Id;
        catalogueList[1].parent__c = catalogueList[0].Id;
        catalogueList[2].parent__c = catalogueList[1].Id;
        catalogueList[1].Product_Package__c = packageList.get(0).Id;
        catalogueList[1].Category_Name__c = 'Add-Ons';
        catalogueList[1].Active__c= true;
        catalogueList[1].Sub_Category_Name__c = 'Implementation';
        catalogueList[1].Package_Product_Type__c = 'Pick Your Numbers';
        catalogueList[1].Product__c = productList.get(0).Id;
        // catalogueList[1].Parent__c = catalogueList[0].Id;
        catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
        catalogueList[0].Has_child__c = true;

        update catalogueList;

        List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
        priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
        Integer count = 1;
        for(Product_Tier_Price__c pp : priceTireList) {
            pp.No_of_Licenses__c = 9999;
            pp.Monthly_Price__c = 150;
            pp.Yearly_Price__c = 1500;
            if (count == 3) {
                pp.Monthly_Price__c = 0;
                pp.Yearly_Price__c = 0;
            }

              count++;
        }

        insert priceTireList;

        Quote_PartnerQuoteUtil.getProductCategories(packageList[0].Id,quoteList[0]);
        Quote_PartnerQuoteUtil.getCountryStateMap('Avaya Cloud Office');
        //Quote_PartnerQuoteUtil.getCountryStateMap('');
        List<String> subCategoryList = new List<String>{'Implementation'};
        Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers',null,false,subCategoryList);
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_twentyThird() {
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).CurrencyIsoCode = 'USD';
            quoteList.get(0).Payment_term__c = 'Yearly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;

            List<Product_Catalogue_Rule__c> productCatalougeRuleList = Quote_TestDataFactory.generateProductCatalougeRule(1);
            productCatalougeRuleList.get(0).Name = 'Product Catalouge Rule';
            productCatalougeRuleList.get(0).Rule_type__c= 'LB';
            productCatalougeRuleList.get(0).Product_Package__c = packageList.get(0).Id;
            productCatalougeRuleList.get(0).show_header__c = true;
            insert productCatalougeRuleList;

            List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(2);
            catalogueList[0].Product_Package__c = packageList[0].Id;
            catalogueList[0].Category_Name__c = 'Add-Ons';
            catalogueList[0].Active__c= true;
            catalogueList[0].Sub_Category_Name__c = 'Implementation';
            catalogueList[0].Package_Product_Type__c = 'Pick Your Numbers';
            catalogueList[0].Product__c = productList.get(0).Id;
            catalogueList[1].Has_child__c = true;
            catalogueList[0].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;

            insert catalogueList;

            catalogueList[1].Product_Package__c = packageList[0].Id;
            catalogueList[1].Category_Name__c = 'Add-Ons';
            catalogueList[1].Active__c= true;
            catalogueList[1].Sub_Category_Name__c = 'Implementation';
            catalogueList[1].Package_Product_Type__c = 'Header';
            catalogueList[1].Product__c = productList.get(0).Id;

            catalogueList[1].LBOX_Rule_Lookup__c = productCatalougeRuleList.get(0).Id;
            catalogueList[1].Has_child__c = true;

            update catalogueList;


            List<Partner_Quote_Line__c> quoteLinesItem = Quote_TestDataFactory.generateQuoteLines(1, quoteList.get(0).Id);
            quoteLinesItem.get(0).Product__c = productList.get(0).Id;
            quoteLinesItem.get(0).Product_Catalogue__c = catalogueList.get(0).Id;
            //quoteLinesItem.get(0).Quantity__c = null;
            insert quoteLinesItem;

            List<Product_Tier_Price__c> priceTireList = Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(0).Id);
            priceTireList.addAll(Quote_TestDataFactory.generateProductTierPrice(2, catalogueList.get(1).Id));
            Integer count = 1;
            for(Product_Tier_Price__c pp : priceTireList) {
                pp.No_of_Licenses__c = 9999;
                pp.Monthly_Price__c = 150;
                pp.CurrencyIsoCode = 'USD';
                pp.Yearly_Price__c = 1500;
                if (count == 3) {
                    pp.Monthly_Price__c = 0;
                    pp.Yearly_Price__c = 0;
                }

                   count++;
            }

            insert priceTireList;

            Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
            Quote_PartnerQuoteUtil.getProductCategories(packageList[0].Id,quoteList[0]);
            List<String> subCategoryList = new List<String>{'Implementation'};

            Quote_PartnerQuoteUtil.getProductsForEdition(quoteList[0].Id,'Pick Your Numbers',null,true,subCategoryList);

    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void test_method_twentyFour() {
        //Deal_Support__c dealSupport= Quote_PartnerQuoteUtil.createDealSupport();
        //dealSupport.Promo_Code__c='test';
        //insert dealSupport;
        //Partner_Quote_Promo_Detail__c promo=new Partner_Quote_Promo_Detail__c();
        //promo.name='test';
        //insert promo;
        List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;


            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Active__c = true;

            insert packageList;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            //accList[0].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),1);
            insert oppList;

            List<Subscription__c> subsList = Quote_TestDataFactory.generateSubscription(
                1, accList.get(0).Id, oppList.get(0).Id, packageList.get(0).Id);
            insert subsList;

            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList.get(0).Product_Edition__c = packageList.get(0).Id;
            quoteList.get(0).Opportunity__c = oppList.get(0).Id;
            quoteList.get(0).User__c = UserInfo.getUserId();
            quoteList.get(0).Subscription__c = subsList.get(0).Id;
            quoteList.get(0).CurrencyIsoCode = 'USD';
            quoteList.get(0).Payment_term__c = 'Yearly';
            quoteList.get(0).RecordTypeId = Schema.SObjectType.Partner_Quote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();

            insert quoteList;
        Test.startTest();
        //Quote_PartnerQuoteUtil.checkSuperUser();
        //Quote_PartnerQuoteUtil.applyPromoCodeToQuote(dealSupport.id);
        Quote_PartnerQuoteUtil.getCountryAndCommunityForCustAcct(accList[0].id,oppList.get(0).Id);
        Quote_PartnerQuoteUtil.getCountryStateMap('test',accList[0].id);
        Quote_PartnerQuoteUtil.getCountriesAvailableForCommunity('');
        Test.stopTest();
    }
    @isTest
    static void test_createChangeOrderRequest() {
         List<Account> accList = Quote_TestDataFactory.generateAccounts(2);
            accList[0].BillingCountry = 'United States';
        	accList[1].BillingCountry = 'United States';
            insert accList;

            List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accList.get(0).Id, 'Qualify', Date.today().addDays(15),2);
            insert oppList;
        	
         	List<Account_Checklist__c > listofAccountChecklist = Quote_TestDataFactory.generateAccountCheckList(1,accList[0].Id);
            insert listofAccountChecklist;
        	
        	List<Account_Checklist_Address__c> addRessList = new List<Account_Checklist_Address__c>{new Account_Checklist_Address__c()};
            insert addRessList;
        
        	List<Quote> quoteList = new List<Quote>();
			Quote quote1 = TestDataFactory.createQuote(oppList[0],false);
        	quoteList.add(quote1);
        	Quote quote2 = TestDataFactory.createQuote(oppList[1],false);
        	quoteList.add(quote2);
        	insert quoteList;
         	Test.startTest();
       		Quote_PartnerQuoteUtil.updateAccountChecklist(true,quoteList[0].Id,listofAccountChecklist[0],accList[0].Id,null,'Yes',true,true,addRessList,true,null);
        	Deal_Support__c dealsupport2 = [Select id,name,Type__c from Deal_Support__c where Opportunity__c =: oppList[0].Id limit 1];
        	System.assertEquals('Initial Order', dealsupport2.Type__c);
        	
        	Quote_PartnerQuoteUtil.createChangeOrderRequest(true,true,quoteList[1].id,accList[1].Id);
        	Deal_Support__c dealsupport1 = [Select id,name,Type__c from Deal_Support__c where Opportunity__c =: oppList[1].Id limit 1];
        	System.assertEquals('Change Order', dealsupport1.Type__c);
        	Test.stopTest();
        	
    }
}