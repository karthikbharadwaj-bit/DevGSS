@isTest
private class Test_HardwareLineItemTriggerHandler {

	private static User testUser = createUser('test', null); // testUser with admin profile

	private static User createUser(String name, Id profileId) {
		User user = new User(
			Username = name+'!user@gmail.com',
			LastName = 'Test'+name,
			Email = name+'_user@gmail.com',
			Alias = 'test'+name,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US'
		);

		if(profileId != null) {
			user.ProfileId = profileId;
		}else{
			user.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id;
		}

		insert user;
		return user;
	}

	private static final Map<String, Schema.RecordTypeInfo> HARDWARE_LINE_ITEM_RT_INFO_BY_NAME = Hardware_Line_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
	private static final Map<String, Schema.RecordTypeInfo> ORDER_RT_INFO_BY_NAME = Order.SObjectType.getDescribe().getRecordTypeInfosByName();


	private static final String ORDER_PROF_SERVICE_RT_NAME = 'Professional Services';
	private static final String ORDER_RC_RT_NAME = 'RingCentral';
	private static final String HARDWARE_LINE_ITEM_RT_NAME = 'Hardware Line Item';


	private static final Id ORDER_PROF_SERVICE_RT_ID = ORDER_RT_INFO_BY_NAME.get(ORDER_PROF_SERVICE_RT_NAME).getRecordTypeId();
	private static final Id ORDER_RC_RT_ID = ORDER_RT_INFO_BY_NAME.get(ORDER_RC_RT_NAME).getRecordTypeId();
	private static final Id HARDWARE_LINE_ITEM_RT = HARDWARE_LINE_ITEM_RT_INFO_BY_NAME.get(HARDWARE_LINE_ITEM_RT_NAME).getRecordTypeId();

	private static Map<Schema.SObjectType, SObject> insertTestData() {

		Account testAcc = new Account(
			Name = 'testAccount'
		);
		insert testAcc;

		Opportunity testOpp = new Opportunity(
			Name = 'MyTestOpportunity',
			Type = 'Existing Business',
			Brand_Name__c = 'RingCentral',
			Tier_Name__c = 'Professional',
			StageName = '1. Qualify',
			CloseDate = System.today(),
			CurrencyIsoCode = 'USD'
		);
		insert testOpp;

		return new Map<Schema.SObjectType, SObject>{
			testAcc.getSObjectType() => testAcc,
			testOpp.getSObjectType() => testOpp
		};
	}

	private static Integer getRandomNumber(Integer upLimit) {
		Integer randInt = Math.mod( Math.round(Math.random()*1000), upLimit );
		if(randInt == 0) {
			randInt = 1;
		}
		return randInt;
	}

	private static Map<Schema.SObjectType, Object> generateOrderItems(Integer count, Id orderId, String productChargeTerm, Double productFeature, Boolean insertOrders) {

		List<Product2> products = new List<Product2>();

		for(Integer i = 0; i < count; i++) {
			Product2 testProduct = new Product2(
				Name = 'myTestProduct__' + i,
				IsActive = true,
				Sub_Category__c = 'CloudConnect',
				Charge_Term__c = productChargeTerm,
				Feature__c = productFeature
			);
			products.add(testProduct);
		}
		if( products.size() > 0 ) {
			insert products;
		}


		List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();

		for(Product2 item : products) {
			PricebookEntry testPBE = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				IsActive = true,
				UnitPrice = getRandomNumber(2000),
				Product2Id = item.Id
			);
			priceBookEntries.add(testPBE);
		}
		if( priceBookEntries.size() > 0 ) {
			insert priceBookEntries;
		}


		List<OrderItem> orderItems = new List<OrderItem>();

		for(PricebookEntry pbe : priceBookEntries) {
			OrderItem testOrderItem = new OrderItem(
				OrderId = orderId,
				PricebookEntryId = pbe.Id,
				Quantity = 50,
				UnitPrice = getRandomNumber(200)
			);
			orderItems.add(testOrderItem);
		}
		if( (orderItems.size() > 0) && insertOrders ) {
			insert orderItems;
		}

		return new Map<Schema.SObjectType, Object>{
			Product2.SObjectType => products,
			PricebookEntry.SObjectType => priceBookEntries,
			OrderItem.SObjectType => orderItems
		};

	}


	@isTest
	public static void test_updateOrderProducts_ProServPhaseRT() {

		System.runAs(testUser) {

			Map<Schema.SObjectType, SObject> myTestDataMap = insertTestData();

			Account testAcc = (Account) myTestDataMap.get( Account.SObjectType );
			Opportunity testOpp = (Opportunity) myTestDataMap.get( Opportunity.SObjectType );

			Id stdPricebookId = Test.getStandardPricebookId();

			Order testOrder = new Order(
				AccountId = testAcc.Id,
				OpportunityId = testOpp.Id,
				Status = 'New',
				EffectiveDate = Date.today(),
				Pricebook2Id = stdPricebookId,
				RecordTypeId = ORDER_PROF_SERVICE_RT_ID
			);
			insert testOrder;

			// generate Product, priceBookEntry, OrderItem with 'Monthly' charge term
			Map<Schema.SObjectType, Object> orderItemsMonthlyTestData = generateOrderItems(2, testOrder.Id, 'Monthly', 34, true);
			List<OrderItem> orderItemsMonthlyList = (List<OrderItem>) orderItemsMonthlyTestData.get( OrderItem.SObjectType );


			// generate Product, priceBookEntry, OrderItem with 'One - Time' charge term
			Map<Schema.SObjectType, Object> orderItemsOneTimeTestData = generateOrderItems(1, testOrder.Id, 'One - Time', 11, true);
			List<OrderItem> orderItemsOneTimeList = (List<OrderItem>) orderItemsOneTimeTestData.get( OrderItem.SObjectType );

			Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>();
			for(OrderItem item : orderItemsMonthlyList) {
				orderItemsMap.put(item.Id, item);
			}

			for(OrderItem item : orderItemsOneTimeList) {
				orderItemsMap.put(item.Id, item);
			}


			Phase__c testPhase = new Phase__c(
				Order__c = testOrder.Id,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Phase__c' and DeveloperName = 'ProServ_Phase'].Id
			);
			insert testPhase;


			Test.startTest();

				update orderItemsMap.values();

			Test.stopTest();


			List<Order> orderList = [select Id, Estimated_ProServ_OTP__c, Estimated_ProServ_MRR__c from Order where Id =: testOrder.Id];

			Order reselectedOrder = orderList[0];

			System.debug('reselectedOrder >>> ' + reselectedOrder);

			Double monthlyTotalPriceSumm = 0;
			for(OrderItem item : orderItemsMonthlyList) {
				monthlyTotalPriceSumm += ((item.UnitPrice == null) ? 0 : item.UnitPrice) * ((item.Quantity == null) ? 0 : item.Quantity);
			}

			Double oneTimeTotalPriceSumm = 0;
			for(OrderItem item : orderItemsOneTimeList) {
				oneTimeTotalPriceSumm += ((item.UnitPrice == null) ? 0 : item.UnitPrice) * ((item.Quantity == null) ? 0 : item.Quantity);
			}

			System.assert( reselectedOrder.Estimated_ProServ_OTP__c == oneTimeTotalPriceSumm, reselectedOrder.Estimated_ProServ_OTP__c + ' != ' + oneTimeTotalPriceSumm );
			//System.assert( reselectedOrder.Estimated_ProServ_MRR__c == monthlyTotalPriceSumm, reselectedOrder.Estimated_ProServ_MRR__c + ' != ' + monthlyTotalPriceSumm );

		}

	}



	@isTest
	public static void test_updatePhase_ProServPhaseRT() {

		System.runAs(testUser) {

			Map<Schema.SObjectType, SObject> myTestDataMap = insertTestData();

			Account testAcc = (Account) myTestDataMap.get( Account.SObjectType );
			Opportunity testOpp = (Opportunity) myTestDataMap.get( Opportunity.SObjectType );

			Id stdPricebookId = Test.getStandardPricebookId();

			Order testOrder = new Order(
				AccountId = testAcc.Id,
				OpportunityId = testOpp.Id,
				Status = 'New',
				EffectiveDate = Date.today(),
				Pricebook2Id = stdPricebookId,
				RecordTypeId = ORDER_PROF_SERVICE_RT_ID
			);
			insert testOrder;

			// generate Product, priceBookEntry, OrderItem with 'Monthly' charge term
			Map<Schema.SObjectType, Object> orderItemsMonthlyTestData = generateOrderItems(2, testOrder.Id, 'Monthly', 34, true);
			List<OrderItem> orderItemsMonthlyList = (List<OrderItem>) orderItemsMonthlyTestData.get( OrderItem.SObjectType );


			// generate Product, priceBookEntry, OrderItem with 'One - Time' charge term
			Map<Schema.SObjectType, Object> orderItemsOneTimeTestData = generateOrderItems(1, testOrder.Id, 'One - Time', 11, true);
			List<OrderItem> orderItemsOneTimeList = (List<OrderItem>) orderItemsOneTimeTestData.get( OrderItem.SObjectType );

			Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>();
			for(OrderItem item : orderItemsMonthlyList) {
				orderItemsMap.put(item.Id, item);
			}

			for(OrderItem item : orderItemsOneTimeList) {
				orderItemsMap.put(item.Id, item);
			}


			Phase__c testPhase = new Phase__c(
				Order__c = testOrder.Id,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Phase__c' and DeveloperName = 'ProServ_Phase'].Id
			);
			insert testPhase;


			Test.startTest();

				update testPhase;

			Test.stopTest();


			List<Phase__c> phaseList = [select Id, Order__c, Account__c, Opportunity__c from Phase__c where Id =: testPhase.Id];

			Phase__c reselectedPhase = phaseList[0];

			System.debug('reselectedPhase >>> ' + reselectedPhase);


			System.assert( reselectedPhase.Account__c == testOrder.AccountId, reselectedPhase.Account__c + ' != ' + testOrder.AccountId );
			System.assert( reselectedPhase.Opportunity__c == testOrder.OpportunityId, reselectedPhase.Opportunity__c + ' != ' + testOrder.OpportunityId );

		}

	}


	@isTest
	public static void test_validatePLIRelatedToProservPhase_onUpdateFields() {

		System.runAs(testUser) {

			Map<Schema.SObjectType, SObject> myTestDataMap = insertTestData();

			Account testAcc = (Account) myTestDataMap.get( Account.SObjectType );
			Opportunity testOpp = (Opportunity) myTestDataMap.get( Opportunity.SObjectType );

			Id stdPricebookId = Test.getStandardPricebookId();

			Test.startTest();
			Quote testQuote = new Quote (
				Name = 'testQuote' ,
				OpportunityId = testOpp.id,
				Products__c = 'Professional Services',
				Pricebook2Id = stdPricebookId
			);
	        insert testQuote;

	        Product2 testProduct1 = new Product2(
				Name = 'myTestProduct1',
				IsActive = true,
				Sub_Category__c = 'Professional Services',
				Charge_Term__c = 'One - Time',
				Feature__c = 11
			);
			insert testProduct1;

			PricebookEntry testPBE1 = new PricebookEntry(
				Pricebook2Id = stdPricebookId,
				IsActive = true,
				UnitPrice = 1000,
				Product2Id = testProduct1.Id
			);
			insert testPBE1;

			insert new QuoteLineItem(
				QuoteId = testQuote.Id,
				Quantity = 1,
				UnitPrice = testPBE1.UnitPrice,
				PricebookEntryId = testPBE1.Id,
				Product2Id = testProduct1.Id
			);

			String ORDER_PROF_SERVICE_RT_NAME = 'Professional Services';
			Map<String, Schema.RecordTypeInfo> ORDER_RT_INFO_BY_NAME = Order.SObjectType.getDescribe().getRecordTypeInfosByName();
			Id ORDER_PROF_SERVICE_RT_ID = ORDER_RT_INFO_BY_NAME.get(ORDER_PROF_SERVICE_RT_NAME).getRecordTypeId();

			Order testOrder = new Order(
				AccountId = testAcc.Id,
				OpportunityId = testOpp.Id,
				Status = 'New',
				EffectiveDate = Date.today(),
				QuoteId = testQuote.Id,
				Pricebook2Id = stdPricebookId,
				RecordTypeId = ORDER_PROF_SERVICE_RT_ID
			);
			insert testOrder;

	        Phase__c testPhase = new Phase__c(
				Order__c = testOrder.Id,
				RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Phase__c' AND DeveloperName = 'ProServ_Phase'].Id
			);
			insert testPhase;

			OrderItem testOrderItem = new OrderItem(
				OrderId = testOrder.Id,
				PricebookEntryId = testPBE1.Id,
				Quantity = 5,
				UnitPrice = 74
			);
			insert testOrderItem;

			String PLI_PHASE_LINE_ITEM_RT_NAME = 'ProServ Line Item';
			Map<String, Schema.RecordTypeInfo> PHASE_LINE_ITEM_RT_INFO_BY_NAME = Hardware_Line_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
			Id PLI_PHASE_LINE_ITEM_RT_ID = PHASE_LINE_ITEM_RT_INFO_BY_NAME.get(PLI_PHASE_LINE_ITEM_RT_NAME).getRecordTypeId();

			Hardware_Line_Item__c testHLI = new Hardware_Line_Item__c(
				RingCentral_Hardware_Phase__c = testPhase.Id,
				Order_Line_Item__c = testOrderItem.Id,
				Quantity__c = 2,
				RecordTypeId = PLI_PHASE_LINE_ITEM_RT_ID,
				Address_Validated__c = true
			);

			insert testHLI;
			Test.stopTest();

			testPhase.Completed_Date__c = Date.today();
			update testPhase;

			try {
				testHLI.Quantity__c = 1;
				update testHLI;
			} catch(Exception ex) {
				System.assert(ex.getMessage().contains(System.Label.Changes_are_not_allowed_Completed_Phase));
			}

		}
	}

	@isTest
	public static void test_autoCreateProServPhases() {

		System.runAs(testUser) {

			Map<Schema.SObjectType, SObject> myTestDataMap = insertTestData();

			Account testAcc = (Account) myTestDataMap.get( Account.SObjectType );
			Opportunity testOpp = (Opportunity) myTestDataMap.get( Opportunity.SObjectType );

			Id stdPricebookId = Test.getStandardPricebookId();

			Id ccProServQuoteRtId = Quote.SObjectType.getDescribe().getRecordTypeInfosByName().get('CC ProServ Quote').getRecordTypeId();

			List<Quote> quoteList = new List<Quote>();

			Quote testQuote = new Quote (
				Name = 'test Quote',
				OpportunityId = testOpp.Id,
				Products__c = 'RingCentral;Contact Center;CC Professional Services',
				Pricebook2Id = stdPricebookId
			);
			quoteList.add(testQuote);

			Quote testCCProServQuote = new Quote (
				Name = 'test proserv Quote',
				OpportunityId = testOpp.Id,
				Products__c = 'CC Professional Services',
				Pricebook2Id = stdPricebookId,
				Number_of_ProServ_Phases__c = 3,
				RecordTypeId = ccProServQuoteRtId
			);
			quoteList.add(testCCProServQuote);

			insert quoteList;

			Id ccProServOrderRtId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('CC Professional Services').getRecordTypeId();

			Test.startTest();

				Order testOrder = new Order(
					AccountId = testAcc.Id,
					OpportunityId = testOpp.Id,
					Status = 'New',
					EffectiveDate = Date.today(),
					QuoteId = testQuote.Id,
					Pricebook2Id = stdPricebookId,
					RecordTypeId = ccProServOrderRtId
				);
				insert testOrder;

			Test.stopTest();

			List<Phase__c> createdPhases = [select Id, RecordTypeId from Phase__c];

			System.assertEquals(createdPhases.size(), testCCProServQuote.Number_of_ProServ_Phases__c);
		}
	}
	//Is used to check total price field value on phase line items and Initial_Payment__c field value on phase object when
	//phase line items are inserted/updated/deleted
	@isTest
	public static void test_PopulatePhaseFields() {
		//Create basic test objects
		Map<Schema.SObjectType, SObject> myTestDataMap = insertTestData();
		Account testAcc = (Account) myTestDataMap.get( Account.SObjectType );
		Opportunity testOpp = (Opportunity) myTestDataMap.get( Opportunity.SObjectType );
		//Create proserv quote
		Quote proservTestQuote = new Quote (Name='proservTestQuote',
			OpportunityId = testOpp.Id,
			Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
            ProServ_Status__c = 'In Progress');
		insert (new List<Quote>{proservTestQuote});
		//Create 4 test products
		Product2 testProservProduct1 = new Product2(
                Name = 'TestProserv1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        Product2 testProservProduct2 = new Product2(
                Name = 'TestProserv2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        Product2 testProservProduct3 = new Product2(
                Name = 'TestProserv3',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        Product2 testProservProduct4 = new Product2(
                Name = 'TestProserv4',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        insert (new List<Product2>{testProservProduct1,testProservProduct2,testProservProduct3,testProservProduct4});
        //Create 4 test price books
        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice3 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct3.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice4 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct4.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{testPrice1, testPrice2, testPrice3, testPrice4});
        //Create 4 test quote line items
        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct1.Id,
                PricebookEntryId = testPrice1.Id
        );
        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct2.Id,
                PricebookEntryId = testPrice2.Id
        );
        QuoteLineItem qli3 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem3',
                Quantity = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct3.Id,
                PricebookEntryId = testPrice3.Id
        );
        QuoteLineItem qli4 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem4',
                Quantity = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct4.Id,
                PricebookEntryId = testPrice4.Id
        );
        insert (new List<QuoteLineItem>{qli1, qli2, qli3, qli4});

        //Test scenario when phase line item is created after the order is generated
        Id proServOrderRTId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

        // Orders
        Order testOrder = new Order (
            AccountId = testAcc.Id,
            OpportunityId = testOpp.Id,
            Status = 'Submitted',
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            RecordTypeId = proServOrderRTId
        );
        insert testOrder;

        // Order Items
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            Quantity = qli4.Quantity,
            UnitPrice = qli4.UnitPrice,
            PriceBookEntryId = testPrice4.Id
        );
        insert testOrderItem;

        //Create a couple of test phases
		Phase__c testPhase1 = new Phase__c(
			Name = 'testPhase1',
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
		);
		Phase__c testPhase2 = new Phase__c(
			Name = 'testPhase2',
			Order__c = testOrder.Id,
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
		);
		insert (new List<Phase__c>{testPhase1, testPhase2});

		Test.startTest();
			//Distribute quote line items between phases
			Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
					RingCentral_Hardware_Phase__c = testPhase1.Id,
					Quote_Line_Item__c = qli1.Id,
					RecordTypeId = HARDWARE_LINE_ITEM_RT,
					Quantity__c = 3
				);
			Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
					RingCentral_Hardware_Phase__c = testPhase1.Id,
					Quote_Line_Item__c = qli2.Id,
					RecordTypeId = HARDWARE_LINE_ITEM_RT,
					Quantity__c = 3
				);
			Hardware_Line_Item__c testHLI3 = new Hardware_Line_Item__c(
					RingCentral_Hardware_Phase__c = testPhase2.Id,
					Quote_Line_Item__c = qli3.Id,
					RecordTypeId = HARDWARE_LINE_ITEM_RT,
					Quantity__c = 3
				);
			Hardware_Line_Item__c testHLI4 = new Hardware_Line_Item__c(
					RingCentral_Hardware_Phase__c = testPhase2.Id,
					Quote_Line_Item__c = qli4.Id,
					RecordTypeId = HARDWARE_LINE_ITEM_RT,
					Quantity__c = 3
				);
			//Phase line item inserted after orders were generated
			Hardware_Line_Item__c testHLI5 = new Hardware_Line_Item__c(
					RingCentral_Hardware_Phase__c = testPhase2.Id,
					Order_Line_Item__c = testOrderItem.Id,
					RecordTypeId = HARDWARE_LINE_ITEM_RT,
					Quantity__c = 3
				);
			//Test on insert
			insert (new List<Hardware_Line_Item__c>{testHLI1, testHLI2, testHLI3, testHLI4, testHLI5});
			//Check if Total_Price__c on phase line item is populated correctly
			List <Hardware_Line_Item__c> insertedPhaseLineItemList = [SELECT id, Total_Price__c FROM Hardware_Line_Item__c];
			for (Hardware_Line_Item__c hli : insertedPhaseLineItemList) {
				System.AssertEquals(hli.Total_Price__c, 150);
			}
			//Check if Initial_Payment__c on phase is populated correctly
			List <Phase__c> phaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			for (Phase__c p : phaseList) {
				System.assertEquals(p.Initial_Payment__c, 300);
			}
			//Test on update
			testHLI1.Quantity__c = 1;
			testHLI2.Quantity__c = 1;
			testHLI3.Quantity__c = 1;
			testHLI4.Quantity__c = 1;
			testHLI5.Quantity__c = 1;
			update (new List<Hardware_Line_Item__c>{testHLI1, testHLI2, testHLI3, testHLI4, testHLI5});
			List <Hardware_Line_Item__c> updatedPhaseLineItemList = [SELECT id, Total_Price__c FROM Hardware_Line_Item__c];
			for (Hardware_Line_Item__c hli : updatedPhaseLineItemList) {
				System.AssertEquals(hli.Total_Price__c, 50);
			}
			List <Phase__c> reselectedPhaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			for (Phase__c p : reselectedPhaseList) {
				System.assertEquals(p.Initial_Payment__c, 100);
			}

			//Test on delete
			List <Hardware_Line_Item__c> hliList = [SELECT Id, RingCentral_Hardware_Phase__c FROM Hardware_Line_Item__c];
			//Arrange phase line items by phases
			Map <Id, List <Hardware_Line_Item__c>>  phaseIdToHliListMap= new Map<Id, List <Hardware_Line_Item__c>>();
			for (Hardware_Line_Item__c hli : hliList) {
				if (!phaseIdToHliListMap.keyset().contains(hli.RingCentral_Hardware_Phase__c)) {
					phaseIdToHliListMap.put(hli.RingCentral_Hardware_Phase__c, new List <Hardware_Line_Item__c>());
				}
				phaseIdToHliListMap.get(hli.RingCentral_Hardware_Phase__c).add(hli);
			}
			List <Hardware_Line_Item__c> hliListForDelete = new List <Hardware_Line_Item__c>();
			for (Id phId : phaseIdToHliListMap.keyset()) {
				List <Hardware_Line_Item__c> hliListBeforeDelete = new List <Hardware_Line_Item__c>();
				for (Hardware_Line_Item__c hli : phaseIdToHliListMap.get(phId)) {
					hliListBeforeDelete.add(hli);
				}
				hliListForDelete.add(hliListBeforeDelete.get(0));
			}
			delete hliListForDelete;
			List <Phase__c> reselectedPhaseListAfterDelete = [SELECT Id, Initial_Payment__c FROM Phase__c];
			for (Phase__c p : reselectedPhaseListAfterDelete) {
				System.assertEquals(p.Initial_Payment__c, 50);
			}

			//Delete all phase line items from phases, left them empty
			DELETE [SELECT Id FROM Hardware_Line_Item__c];
			List <Phase__c> reselectedEmptyPhase = [SELECT Id, Initial_Payment__c FROM Phase__c];
			for (Phase__c p : reselectedEmptyPhase) {
				System.assertEquals(p.Initial_Payment__c, null);
			}
		Test.stopTest();
	}

	@isTest
	public static void test_InitialPaymentRecalculation() {
		Map<Schema.SObjectType, SObject> myTestDataMap = insertTestData();
		Account testAcc = (Account) myTestDataMap.get( Account.SObjectType );
		Opportunity testOpp = (Opportunity) myTestDataMap.get( Opportunity.SObjectType );

		// Creation of proserv quote
		Quote proservTestQuote = new Quote (Name='proservTestQuote',
			OpportunityId = testOpp.Id,
			Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV,
            ProServ_Status__c = 'In Progress');
		insert (new List<Quote>{ proservTestQuote });

		// Creation of test products
		Product2 testProservProduct1 = new Product2(
                Name = 'TestProduct1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        Product2 testProservProduct2 = new Product2(
                Name = 'TestProduct2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        Product2 testProservProduct3 = new Product2(
                Name = 'TestProduct3',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true,
                Sub_Category__c = 'Professional Services'
        );
        insert (new List<Product2>{ testProservProduct1, testProservProduct2, testProservProduct3 });

        // Creation of pricebookentries
        PricebookEntry testPrice1 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct1.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice2 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct2.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        PricebookEntry testPrice3 = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProservProduct3.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        insert (new List<PricebookEntry>{ testPrice1, testPrice2, testPrice3 });

        // Creation of QLIs
        QuoteLineItem qli1 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct1.Id,
                PricebookEntryId = testPrice1.Id
        );
        QuoteLineItem qli2 = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem2',
                Quantity = 5,
                QuoteId = proservTestQuote.Id,
                UnitPrice = 50,
                Product2Id = testProservProduct2.Id,
                PricebookEntryId = testPrice2.Id
        );
		QuoteLineItem qli3 = new QuoteLineItem (
			ServiceDate = Date.today(),
			Description = 'TestLineItem3',
			Quantity = 1,
			QuoteId = proservTestQuote.Id,
			UnitPrice = 50,
			Product2Id = testProservProduct2.Id,
			PricebookEntryId = testPrice2.Id
		);
        insert (new List<QuoteLineItem>{ qli1, qli2, qli3 });

		// Creation of phase (before creation of order, when Order lookup fields are empty)
		Phase__c testPhase1 = new Phase__c(
			Name = 'testPhase1',
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId()
		);
		insert testPhase1;

		Test.startTest();
			List <Phase__c> phaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			// As soon as a phase is created, the initial payment should be null
			System.AssertEquals(phaseList[0].Initial_Payment__c, null);

			// We add a PLI for $150, so the initial payment should be $150
			Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
				RingCentral_Hardware_Phase__c = phaseList[0].Id,
				Quote_Line_Item__c = qli1.Id,
				RecordTypeId = HARDWARE_LINE_ITEM_RT,
				Quantity__c = 3
			);
			insert testHLI1;

			phaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			System.AssertEquals(150, phaseList[0].Initial_Payment__c);

			// We decrease the quantity, so initial payment should be updated to $50
			testHLI1.Quantity__c = 1;
			update testHLI1;

			// Creation of order
			Order testOrder = new Order (
				AccountId = testAcc.Id,
				OpportunityId = testOpp.Id,
				Status = 'Submitted',
				Pricebook2Id = Test.getStandardPricebookId(),
				EffectiveDate = System.today(),
				RecordTypeId = Order.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId()
			);
			insert testOrder;

			// This orderItem should not contribute to the sum of Initial_Payment__c
			OrderItem testOrderItem = new OrderItem(
				OrderId = testOrder.Id,
				Quantity = qli3.Quantity,
				UnitPrice = qli3.UnitPrice,
				PriceBookEntryId = testPrice3.Id
			);
			insert testOrderItem;

			// We add one more PLI with a cost of $50, so the initial payment should be $100
			Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
				RingCentral_Hardware_Phase__c = phaseList[0].Id,
				Quote_Line_Item__c = qli2.Id,
				RecordTypeId = HARDWARE_LINE_ITEM_RT,
				Quantity__c = 1
			);
			Hardware_Line_Item__c testHLI3 = new Hardware_Line_Item__c(
				RingCentral_Hardware_Phase__c = phaseList[0].Id,
				Order_Line_Item__c = testOrderItem.Id,
				RecordTypeId = HARDWARE_LINE_ITEM_RT,
				Quantity__c = 1
			);

			insert (new List<Hardware_Line_Item__c>{ testHLI2, testHLI3 });
		
			phaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			System.AssertEquals(100, phaseList[0].Initial_Payment__c);

			delete testHLI1;
			phaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			System.AssertEquals(50, phaseList[0].Initial_Payment__c);

			delete (new List<Hardware_Line_Item__c>{ testHLI2, testHLI3 });
			phaseList = [SELECT Id, Initial_Payment__c FROM Phase__c];
			System.AssertEquals(null, phaseList[0].Initial_Payment__c);
		Test.stopTest();
	}
	
	@isTest
	public static void test_validatePliChangeWhenPhaseInApproval() {
		Account testAcc = new Account(
			Name = 'testAccount'
		);
		insert testAcc;

		Order ord = new Order(
			AccountId = testAcc.Id,
			Status = 'New',
			Booked_ProServ_OTP__c = 100,
			EffectiveDate = System.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			RecordTypeId = OrderHelper.RT_ID_PROSERV
		);
		insert ord;

		Product2 testProduct = new Product2(
			Name = 'TestProserv1',
			Family = 'Add - Ons',
			Charge_Term__c = 'One - Time',
			Sub_Category__c = 'Professional Services',
			IsActive = true
		);
		insert testProduct;

		PricebookEntry testPbe = new PricebookEntry(
			Pricebook2Id = Test.getStandardPricebookId(),
			Product2Id = testProduct.Id,
			UnitPrice = 50,
			IsActive = true,
			UseStandardPrice = false,
			Per_Line__c = false,
			Min_Quantity__c = 1,
			Max_Quantity__c = 100
		);
		insert testPbe;

		OrderItem oi = new OrderItem(
			OrderId = ord.Id,
			PricebookEntryId = testPbe.Id,
			Quantity = 10,
			UnitPrice = 50
		);
		insert oi;

		Phase__c testPhase = new Phase__c(
			Name = 'testPhase1',
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get(PhaseHelper.RT_NAME_PROSERV_PHASE).getRecordTypeId(),
			Initial_Payment__c = 20,
			Order__c = ord.Id
		);
		insert testPhase;

		Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
			RingCentral_Hardware_Phase__c = testPhase.Id,
			Order_Line_Item__c = oi.Id,
			RecordTypeId = Schema.SObjectType.Hardware_Line_Item__c.getRecordTypeInfosByName().get('ProServ Line Item').getRecordTypeId(),
			Quantity__c = 3
		);
		insert testHLI1;


		Test.startTest();
			//Emulate approval process
			testPhase.Status__c = PhaseHelper.STATUS_PENDING_APPROVAL;
			update testPhase;
			testHLI1.Quantity__c = 5;
			try{
				update testHLI1;
			} catch(Exception e) {
				String error = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ':');
				System.assertEquals('You can\'t make any changes when Phase is in approval process',error);
			}

			try{
				delete testHLI1;
			} catch(Exception e) {
				String error = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ':');
				System.assertEquals('You can\'t make any changes when Phase is in approval process',error);
			}

		Test.stopTest();
	}
}