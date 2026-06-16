@isTest
public class PartnerQuoteTrigger_Test {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test_method_one() {
        List<Account> accList = Quote_TestDataFactory.generateAccounts(1);
        insert accList;
            
        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.AccountId = accList[0].Id;
        opp.StageName = '5. Agreement';
        insert opp;
        
        List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        quoteList[0].Integration_Quote__c = true;
        quoteList[0].Opportunity__c = opp.id;
        quoteList[0].Primary__c = true;//Added for PRM-15
        insert quoteList;
        
        //Added for PRM-15 - start
        quoteList[0].Integration_Quote__c = true;
        quoteList[0].Opportunity__c = opp.id;
        quoteList[0].Primary__c = false;
        update quoteList;
        
        quoteList[0].Integration_Quote__c = true;
        quoteList[0].Opportunity__c = opp.id;
        quoteList[0].Primary__c = true;
        update quoteList;
        //Added for PRM-15 - end            
    }
}