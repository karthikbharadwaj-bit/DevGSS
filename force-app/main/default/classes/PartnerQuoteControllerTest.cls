@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
public class PartnerQuoteControllerTest {
    @isTest static void test_method_one() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            PartnerQuoteController obj = new PartnerQuoteController();
            PartnerQuoteController.addQuoteASFav(quoteList[0].Id,'Test FAV 1');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_two() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
        List<User> userList = [Select Id,Contact.AccountId FROM User Limit 1 ];
        Test.startTest();
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            PartnerQuoteController obj = new PartnerQuoteController();
            PartnerQuoteController.CheckAccountListExist(userList[0].Contact.AccountId);
            // IF Account Checklist Exist
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            insert accList;
            Account_Checklist__c objAcc = new Account_Checklist__c();
            objAcc.Account__c = accList[0].Id;
            objAcc.Type__c = 'Tax Exemptions';
            insert objAcc;
            PartnerQuoteController.CheckAccountListExist(accList[0].Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_three() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
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
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            PartnerQuoteController obj = new PartnerQuoteController();
            PartnerQuoteController.getQuoteLinesWithCalculation(quoteList[0].Id);
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_four() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
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
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            PartnerQuoteController obj = new PartnerQuoteController();
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_five() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
            List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
            insert quoteList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            insert quoteLineList;
            Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
            System.currentPageReference().getParameters().put('id', quoteList[0].Id);
            
            PartnerQuoteController obj = new PartnerQuoteController();
            PartnerQuoteController.updateQuoteLines(JSON.serialize(quoteLineList));
            PartnerQuoteController.deleteQuoteLine(quoteList[0].id,quoteLineList[0].Id);
            PartnerQuoteController.updateQuotes(null,quoteList);
            
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_six() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
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
        
        Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
        System.currentPageReference().getParameters().put('id', quoteList[0].Id);
        PartnerQuoteController obj = new PartnerQuoteController();
        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;
        
        PartnerQuoteController.updateQuote(quoteList[0],true,'test');
        PartnerQuoteController.getQuotes(opp.Id);
        PartnerQuoteController.deleteQuote(quoteList[0].Id);
        
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest static void test_method_seven() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
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
        
        Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
        System.currentPageReference().getParameters().put('id', quoteList[0].Id);
        PartnerQuoteController obj = new PartnerQuoteController();
        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;
        
        PartnerQuoteController.createPartnerQuoteForUpsell(accList[0].Id);
        
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_Eight() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
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
        List<Partner_Contract__c> listOfPartnerContract = Quote_TestDataFactory.generatePartnerContract(1,quoteList[0].Id);
        insert listOfPartnerContract;
        List<Partner_Contract_Service__c> listOfPartnerContractService = Quote_TestDataFactory.getPartnerContractService(1,listOfPartnerContract[0].Id);
        insert listOfPartnerContractService;
        Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
        System.currentPageReference().getParameters().put('id', quoteList[0].Id);
        PartnerQuoteController obj = new PartnerQuoteController();
        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;
      }
      @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_nine() {
        Quote_TestDataFactory factory = new Quote_TestDataFactory();
        factory.createUsersWithAyavaE2ECustomerProfile(1);
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
        List<Partner_Contract__c> listOfPartnerContract = Quote_TestDataFactory.generatePartnerContract(1,quoteList[0].Id);
        insert listOfPartnerContract;
        List<Partner_Contract_Service__c> listOfPartnerContractService = Quote_TestDataFactory.getPartnerContractService(1,listOfPartnerContract[0].Id);
        insert listOfPartnerContractService;
        Test.setCurrentPageReference(new PageReference('Page.QuoteTool')); 
        System.currentPageReference().getParameters().put('id', quoteList[0].Id);
        PartnerQuoteController obj = new PartnerQuoteController();
        PartnerQuoteController.checkPOCRequestExist(opp.Id);
        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;
        Deal_Support__c objDS1 = new Deal_Support__c();
        objDS1.Partner_Quote__c = quoteList[0].Id;
        objDS1.Type__c = 'Discount Request';
        
        PartnerQuoteController.createPOCRequest(objDS1,opp.Id);
      }

      @isTest static void test_method_Ten() {
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User userSysAdmin = new User(
            ProfileId = profile1.Id,
            Username = 'testUserName12334@gmail.com',
            Alias = 'batndfw',
            Email='bruce.wayne@wayneenterprises2f234.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        System.runAs(userSysAdmin) {
            Account portalAccount = new Account(                    
                    Name = 'TestAccount4',
                    RC_Brand__c ='Avaya Cloud Office');
            insert portalAccount;
            List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
            accList[0].Partner_Type__c = 'Atos - Wholesale-Reseller';
            insert accList;
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = new Opportunity();
            opp1.Name = 'test';
            opp1.Partner_Account__c = accList[0].Id;
            opp1.AccountId = portalAccount.Id;
            opp1.StageName = '1. Qualify';
            opp1.CloseDate = Date.today().addDays(5);
            Opportunity opp2 = new Opportunity();
            opp2.Name = 'test1';
            opp2.AccountId = accList[0].Id;
            opp2.Partner_Account__c = portalAccount.Id;
            opp2.StageName = '1. Qualify';
            opp2.CloseDate = Date.today().addDays(5);
            oppList.add(opp1);
            oppList.add(opp2);
            insert oppList;
            
            List<Product2> productList = Quote_TestDataFactory.generateProducts(1);
            insert productList;
            
            List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(2);
            packageList.get(0).Name = 'Product Package Name';
            packageList.get(0).Active__c = true;
            packageList.get(0).Description__c = 'Test Description';
            packageList.get(0).Package_Edition__c = 'Standard';
            packageList.get(1).Package_Edition__c = 'Standard';
            insert packageList;
            Wholesale_Partner_Package__c wholesalePackg = new Wholesale_Partner_Package__c();
            wholesalePackg.Wholesale_Partner_Account__c = accList[0].Id;
            wholesalePackg.Product_Package__c = packageList.get(0).Id;
            wholesalePackg.Parent_Product_Package__c = packageList.get(1).Id;
            insert wholesalePackg;
            List<String> editions = new List<String>();
            List<String> editionsNull = new List<String>();
            Test.startTest();    
            editions = PartnerQuoteController.checkAndGetWholesalePartnerPackageEditions(oppList[0].Id);
            editionsNull = PartnerQuoteController.checkAndGetWholesalePartnerPackageEditions(oppList[1].Id);
            Test.stopTest();
            System.assert(editions.size() == 1, editions + ' Expected 1 value - Standard');
            System.assert(editionsNull == null, ' Expected null ');
      }
    }
    @isTest static void test_method_eleven() {
        Test.startTest();   
        List<Product_Package__c> packageList = Quote_TestDataFactory.generateProductPackage(1);
        packageList.get(0).Name = 'Standard';
        packageList.get(0).Active__c = true;
        packageList.get(0).Description__c = 'Test Description';
        packageList.get(0).currencyIsoCode = 'CHF';
        packageList.get(0).Brand_Name__c = 'Avaya Cloud Office';
        insert packageList;

        List<Product_Tier_Price__c> priceList = new List<Product_Tier_Price__c>();
        Product_Tier_Price__c ptp = new Product_Tier_Price__c();
        ptp.currencyIsoCode = 'CHF';
        ptp.Monthly_Price__c = 20;
        ptp.To_Value__c = 10;
        ptp.Product_Package__c = packageList[0].Id;
        ptp.From_Value__c = 0;
        ptp.No_of_Licenses__c = 10;
        priceList.add(ptp);
        insert priceList;

        Id packageId = PartnerQuoteController.getProductPackgeId('Avaya Cloud Office','Standard','CHF');
        System.assertEquals(packageId,packageList[0].Id);
        Test.stopTest();
    }
}