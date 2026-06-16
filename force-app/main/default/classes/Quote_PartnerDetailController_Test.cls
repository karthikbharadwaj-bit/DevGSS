@isTest
public class Quote_PartnerDetailController_Test {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_one() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            Quote_PartnerDetailController.addQuoteASFav(quoteList[0].Id,'Test FAV 1');
        	Quote_PartnerDetailController.createPOCRequest(quoteList[0]);
        	
        //}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_two() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User Limit 1];
        //WHERE Profile.Name = 'Partner Community - Partner Admin'
        //System.RunAs(userList[0]){
        Test.startTest();
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            Quote_PartnerDetailController.CheckAccountListExist(userList[0].Contact.AccountId);
            // IF Account Checklist Exist
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;
            Account_Checklist__c objAcc = new Account_Checklist__c();
            objAcc.Account__c = accList[0].Id;
            objAcc.Type__c = 'Tax Exemptions';
            insert objAcc;
            Quote_PartnerDetailController.CheckAccountListExist(accList[0].Id);
        	Quote_PartnerDetailController.isValidServiceLineOnQuote(quoteList[0].Id);
        Test.stopTest();
        //}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_three() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            Quote_PartnerDetailController.checkSuperUser(quoteList[0].Id);
            
            //If Deal Support Exists...
            Deal_Support__c objDS = new Deal_Support__c();
            objDS.Partner_Quote__c = quoteList[0].Id;
            objDS.Type__c = 'Discount Request';
            insert objDS;
            Quote_PartnerDetailController.checkSuperUser(quoteList[0].Id);
        //}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_four() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController.isCommunity();
        //}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_five() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
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
            Quote_PartnerDetailController.getQuoteLinesWithCalculation(quoteList[0].Id);
        //}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_Six() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList[0].Opportunity__c = opp.id;
            insert quoteList;
            Quote_PartnerDetailController.updateQuote(quoteList[0],true,2.0,'test',true,true,'test', 'Amt');
        //}
       
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_Six_A() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;
            Opportunity opp = new Opportunity();
            opp.Name = 'test';
            opp.AccountId = accList[0].Id;
            opp.StageName = '5. Agreement';
            insert opp;
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            quoteList[0].Opportunity__c = opp.id;
            insert quoteList;
            Quote_PartnerDetailController.updateQuote(quoteList[0],true,2.0,'test',true,true,'test', '%');
        //}
       
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_Seven() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;
            Quote_PartnerDetailController.updateQuoteLines(JSON.serialize(quoteLineList));
            Quote_PartnerDetailController.deleteQuoteLine(quoteList[0].id,quoteLineList[0].Id);
            Quote_PartnerDetailController.updateQuotes(null,quoteList);
           
        //}
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest static void test_method_Eight() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
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
            /*Deal_Support__c objDS = new Deal_Support__c();
            objDS.Partner_Quote__c = quoteList[0].Id;
            objDS.Type__c = 'Discount Request';
            insert objDS;*/
         
         	Quote_PartnerDetailController.createDealSprtForEngageProServ(quoteList[0].Id,true,'Test ProServ');
            Quote_PartnerDetailController.updateQuote(quoteList[0],true,2.0,'test',true,true,'test', 'Amt');
         	Quote_PartnerDetailController.getQuotes(opp.Id);
         	Quote_PartnerDetailController.deleteQuote(quoteList[0].Id);
         	
        //}
        
       
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_Eight_A() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User WHERE Profile.Name = 'Partner Community - Partner Admin'];
        //System.RunAs(userList[0]){
            Quote_PartnerDetailController obj = new Quote_PartnerDetailController();
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
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
            /*Deal_Support__c objDS = new Deal_Support__c();
            objDS.Partner_Quote__c = quoteList[0].Id;
            objDS.Type__c = 'Discount Request';
            insert objDS;*/
         
         	Quote_PartnerDetailController.createDealSprtForEngageProServ(quoteList[0].Id,true,'Test ProServ');
            Quote_PartnerDetailController.updateQuote(quoteList[0],true,2.0,'test',true,true,'test', '%');
         	Quote_PartnerDetailController.getQuotes(opp.Id);
         	Quote_PartnerDetailController.deleteQuote(quoteList[0].Id);
         	
        //}
        
       
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_Nine() {
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        //Quote_PartnerDetailController.isValidServiceLineOnQuote(quoteList.get(0).Id);
    }
    
}