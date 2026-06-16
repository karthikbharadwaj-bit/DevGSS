@isTest
private class Quote_QuotePDFControllerTest {
    
    @testSetup
    private static void testSetup() {
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
        productCatalogueList.get(0).plan__c = 'One - Time';
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
    private static void testQuote_QuotePDF() {
        Partner_Quote__c quoteRec = [SELECT Id FROM Partner_Quote__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('Id',quoteRec.Id);
         Test.startTest();
        	Quote_QuotePDFController result = new Quote_QuotePDFController();
        Test.stopTest();
        
        System.assertNotEquals(null, result.objPartnerQuotePDF, 'result can not be null');
        System.assertNotEquals(null, result.objPartnerQuotePDF.quoteLineList, 'quote line item can not be null');
        System.assertNotEquals(null, result.objPartnerQuotePDF.quoteRec, 'quote result can not be null');
    }
    
    @isTest
    private static void testGetPDFData() {
        Partner_Quote__c quoteRec = [SELECT Id FROM Partner_Quote__c LIMIT 1];
        
        Test.startTest();
        	Quote_QuotePDFController.QuotePDFWrapper result = Quote_QuotePDFController.getPDFData(quoteRec.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'result can not be null');
        System.assertNotEquals(null, result.quoteLineList, 'quote line item can not be null');
        System.assertNotEquals(null, result.quoteRec, 'quote result can not be null');
    }
}