@isTest
private class Test_OrderHistoryViewController {

	private static Account testAccount;
	private static Order testOrder;
	private static OrderItem testOrderItem;

	private static void CreateTestData(Id standardPriceBookId) {


		Triggers.switchOff();

		testAccount = new Account(
			Name = 'Test Account',
			Number_of_DL_s__c = 10,
			BillingCity = 'TestCity',
			BillingStreet = 'TestStreet',
			Payment_Method__c = 'Invoice',
			SignupType__c = 'Direct'
		);
		insert testAccount;


		Contact testContact = new Contact(
			AccountId = testAccount.Id,
			LastName = 'Golofaev',
			FirstName = 'Dmitry',
			Email = 'dgolofaev@test.com'
		);
		insert testContact;


		Opportunity testOpportunity = new Opportunity(
			Name = 'Test Opportunity',
			Type = 'Syndicated - New',
			StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
			CloseDate = system.today(),
			Brand_Name__c = 'RingCentral',
			PriceBook2Id = standardPriceBookId,
			Primary_Opportunity_Contact__c = testContact.Id,
			Tier_Name__c = '999',
			AccountId = testAccount.Id
		);
		insert testOpportunity;


		Quote testQuote = new Quote (
			Name = 'qoutetest',
			OpportunityId = testOpportunity.id,
			Status = 'Draft',
			Pricebook2Id = standardPriceBookId,
			Total_Number_of_Digital_Lines__c = 5
		);
		insert testQuote;

		Triggers.switchOn();

		Product2 testProduct = new Product2(
			Name = 'Connect Pro - Annual Fee',
			IsActive = true,
			Family = 'Device',
			CurrencyIsoCode = 'USD'
		);
		insert testProduct;


		PricebookEntry testPrice = new PricebookEntry(
			Pricebook2Id = standardPriceBookId,
			Product2Id = testProduct.Id,
			UnitPrice = 200,
			IsActive = true,
			UseStandardPrice = false,
			Per_Line__c = false,
			Min_Quantity__c = 2,
			Max_Quantity__c = 5,
			Max_DIscount__c = 10,
			CurrencyIsoCode = 'USD');
		insert testPrice;


		QuoteLineItem testQuoteLineItem = new QuoteLineItem (
			ServiceDate = date.today(),
			Description = 'TestLineItem',
			UnitPrice = testPrice.UnitPrice,
			Quantity = 3,
			Discount_number__c = 0,
			QuoteId = testQuote.Id,
			PriceBookEntryId = testPrice.Id,
			Product2Id = testProduct.Id);
		insert testQuoteLineItem;


		testOrder = new Order(
				AccountId = testOpportunity.AccountId,
				OpportunityId = testOpportunity.Id,
				Name = testOpportunity.Name,
				QuoteId = testQuote.Id,
				EffectiveDate = testOpportunity.CloseDate,
				Status = 'New',
				Pricebook2Id = standardPriceBookId
		);
		insert testOrder;


		testOrderItem = new OrderItem(
			OrderId = testOrder.Id,
			PriceBookEntryId = testPrice.Id,
			Quantity = 1,
			UnitPrice = 200
		);
		insert testOrderItem;
	}

	@isTest static void test_getConstructor() {
		Account testAccount2 = new Account();
		testAccount2.Name = 'Test Account 2';
		insert testAccount2;

		ApexPages.StandardController sc = new ApexPages.standardController(testAccount2);
		OrderHistoryViewController controller = new OrderHistoryViewController(sc);

		system.assertEquals(controller.acc.Id, testAccount2.Id);
	}

	@isTest static void test_getOrders() {

		List<Order> orderList;
		List<Order> orderList2;

		Test.startTest();
		CreateTestData(Test.getStandardPricebookId());
		orderList = OrderHistoryViewController.getOrders(testAccount.Id);

		orderList2 = OrderHistoryViewController.getOrders('');
		Test.stopTest();

		System.assertEquals(orderList.size(), 1);
		System.assertEquals(orderList[0].Id, testOrder.Id);
		System.assertEquals(orderList[0].OrderItems.size(), 1);
		System.assertEquals(orderList[0].OrderItems[0].Id, testOrderItem.Id);
		System.assertEquals(orderList2, null);
	}

}