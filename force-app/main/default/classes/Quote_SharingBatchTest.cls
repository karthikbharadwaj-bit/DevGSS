@isTest
public class Quote_SharingBatchTest {
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_one() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;
            
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Opportunity__c = opp.Id;
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
       	String querystr = 'Select Id from Partner_Quote__c';
        Quote_SharingBatch obj = new Quote_SharingBatch(querystr,'Partner_Quote__c');
        DataBase.executeBatch(obj); 
	}
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_two() {
        String querystr = 'Select Id from Account';
     	Quote_SharingBatch obj = new Quote_SharingBatch(querystr, 'Account');
        DataBase.executeBatch(obj); 
        
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_three() {
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
        insert quoteLineList;
        //If Deal Support Exists...
        Deal_Support__c objDS = new Deal_Support__c();
        objDS.Partner_Quote__c = quoteList[0].Id;
        objDS.Type__c = 'Discount Request';
        insert objDS;
        Test.startTest();
        String querystr = 'Select Id from Deal_Support__c';
        Quote_SharingBatch obj = new Quote_SharingBatch(querystr,'Deal_Support__c');
        DataBase.executeBatch(obj); 
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_four() {
        String querystr = 'Select Id from Lead';
        Quote_SharingBatch obj = new Quote_SharingBatch(querystr,'Lead');
        DataBase.executeBatch(obj); 
  	}
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_five() {
        String querystr = 'Select Id from Deal_Registration__c';
        Quote_SharingBatch obj = new Quote_SharingBatch(querystr,'Deal_Registration__c');
        DataBase.executeBatch(obj); 
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest static void test_method_six() {
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        System.RunAs(PartnerRecordsUtil.runAsSysAdmin){
            PartnerRecordsUtil.createAvayaDeal();
            Test.startTest();
            String querystr = 'Select Id from Deal_Registration__c';
            Quote_SharingBatch obj = new Quote_SharingBatch(querystr,'Deal_Registration__c');
            DataBase.executeBatch(obj); 
            Test.stopTest();
		}
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void test_method_seven() {
        String querystr = 'Select Id from Lead';
		Quote_SharingBatch obj = new Quote_SharingBatch(querystr,'Existing Lead');
        DataBase.executeBatch(obj); 
  	}
	
}