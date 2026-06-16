@isTest
public class DealSupportCommentTrigger_test {
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
            insert quoteList;
            
        	List<Product_Catalogue__c> catalogueList = Quote_TestDataFactory.generateProductCatalouge(1);
            insert catalogueList;
            List<Partner_Quote_Line__c> quoteLineList = Quote_TestDataFactory.generateQuoteLines(2,quoteList[0].Id);
            quoteLineList[0].Product_Catalogue__c = catalogueList[0].Id;
            quoteLineList[0].List_Price__c = 10;
            quoteLineList[1].List_Price__c = 10;
            quoteLineList[1].Product_Catalogue__c = catalogueList[0].Id;
            insert quoteLineList;
        
        	Deal_Support__c objDealSupp = new Deal_Support__c();
        	objDealSupp.partner_Quote__c = quoteList[0].Id;
        	objDealSupp.Type__c = 'Initial Order';
        	insert objDealSupp;
        	Deal_Support_Comments__c objDealSupportComm = new Deal_Support_Comments__c();
        	objDealSupportComm.Deal_Support__c = objDealSupp.Id;
        	///objDealSupportComm.Comm = 'Testing';
        	insert objDealSupportComm;
		}
}