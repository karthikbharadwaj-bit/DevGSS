@isTest
private class Test_DealQuoteInfoController {
       
	@isTest
	private static void initDealQuoteInfoTest() {
		DealQuoteInfoController.DealQuoteInfoWrappper result = DealQuoteInfoController.initDealQuoteInfo();
		System.assertNotEquals(null, result);
	}

	@isTest
	private static void refreshValueFromQuoteTest() {
		Map<sObjectType, sObject>  testData = prepareData();
		DealQuoteInfoController.DealQuoteDetailWrapper result = DealQuoteInfoController.refreshValueFromQuote(null, testData.get(Quote.sObjectType).Id);
		System.assertNotEquals(null, result);
	}


	@isTest
	private static void getDealQuotingInfoByIdTest() {
		Map<sObjectType, sObject>  testData = prepareData();
		DealQuoteInfoController.DealQuoteDetailWrapper result = DealQuoteInfoController.getDealQuotingInfoById(testData.get(Deal_Quoting_Info__c.sObjectType).Id);
		System.assertNotEquals(null, result);
	}

    @isTest
	private static void getDealQuotingInfoByIdOpportunityTest() {
		Map<sObjectType, sObject>  testData = prepareData();
        Test.startTest();
		    DealQuoteInfoController.DealQuoteDetailWrapper result = DealQuoteInfoController.getDealQuotingInfoById(testData.get(Opportunity.sObjectType).Id);
        Test.stopTest();
		System.assertNotEquals(null, result);
	}

	@isTest
	private static void getOpportunityDetailTest() {
		Map<sObjectType, sObject>  testData = prepareData();
		Opportunity result = DealQuoteInfoController.getOpportunityDetail(testData.get(Opportunity.sObjectType).Id);
		System.assertNotEquals(null, result);
	}

	
	@isTest
	private static void getQuoteInfoByIdTest() {
		Map<sObjectType, sObject>  testData = prepareData();
		Quote result = DealQuoteInfoController.getQuoteInfoById(testData.get(Quote.sObjectType).Id);
		System.assertNotEquals(null, result);
	}

	@isTest
	private static void createDealQuoteInfoRecordTest() {
		Map<sObjectType, sObject>  testData = prepareData();
		Deal_Quoting_Info__c dealQuotingInfo = (Deal_Quoting_Info__c)testData.get(Deal_Quoting_Info__c.sObjectType);
		String result = DealQuoteInfoController.createDealQuoteInfoRecord(JSON.serialize(dealQuotingInfo));
		System.assertNotEquals(null, result);
	}
	
	private static Map<sObjectType, sObject>  prepareData () {
        Triggers.switchOff();
        Map<sObjectType, sObject> testData = TestDataFactory.createTestData(true);
		QuoteLineItem quoteLine = TestDataFactory.createQuoteLineItem((Quote)testData.get(Quote.sObjectType), (Product2) testData.get(Product2.sObjectType)); 
		testData.put(Deal_Quoting_Info__c.sObjectType, createDealQuoteInfo(testData.get(Opportunity.sObjectType).Id, testData.get(Quote.sObjectType).Id)); 
        Triggers.switchOn();
		return testData;
    }

	private static Deal_Quoting_Info__c createDealQuoteInfo (String oppId, String quoteId) {
		Deal_Quoting_Info__c dealQuoteInfo = new Deal_Quoting_Info__c();
		if (oppId != null) {
			dealQuoteInfo.Opportunity__c = oppId;
		}
		if (quoteId != null) {
			dealQuoteInfo.Sales_Agreement__c = quoteId;
		}
		insert dealQuoteInfo;
		return dealQuoteInfo;
	}
	
}