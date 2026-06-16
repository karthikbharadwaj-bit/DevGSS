@isTest
public class Quote_TestDataFactoryTest {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest static void test_method_one() {
        List<Account> accountList = Quote_TestDataFactory.generateAccounts(1);
        insert accountList;
        Quote_TestDataFactory.generateContactsForAccounts(accountList,1);
        new Quote_TestDataFactory().createUsersWithAyavaE2ECustomerProfile(1);
        
        List<Opportunity> oppList = Quote_TestDataFactory.generateOpportunities(accountList[0].Id,'1. Qualify',system.today(),1);
        insert oppList;
        Quote_TestDataFactory.generateOpportunity('Testing',accountList[0].Id,system.today(),'1. Qualify',system.today(),system.today());
    	List<Partner_Quote__c> quoteList = Quote_TestDataFactory.generateQuotes(1);
        insert quoteList;
        Quote_TestDataFactory.generateQuoteLines(1,quoteList[0].Id);
        Quote_TestDataFactory.generateProductCatalouge(1);
        Quote_TestDataFactory.generateProductCatalougeRule(1);
        List<Subscription__c> subList = Quote_TestDataFactory.generateSubscription(1,accountList[0].Id,oppList[0].Id,null);
        Quote_TestDataFactory.generateDealRegistration(1,accountList[0].Id,null);
        Quote_TestDataFactory.generateLead(1);
        Quote_TestDataFactory.generateAttachment(1,null);
        List<Partner_Contract__c> partnerConList = Quote_TestDataFactory.generatePartnerContract(1,quoteList[0].Id);
        insert partnerConList;
        Quote_TestDataFactory.generateProductTierPrice(1,null);
        Quote_TestDataFactory.generateAccountChangeRequest(1,accountList[0].Id);
        Quote_TestDataFactory.getPartnerContractService(1,partnerConList[0].Id);
    }
}