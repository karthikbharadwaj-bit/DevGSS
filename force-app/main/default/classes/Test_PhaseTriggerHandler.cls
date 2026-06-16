/**
 * Created by alexandersavickiy on 13/12/17.
 */
@isTest
private class Test_PhaseTriggerHandler {
    private final static String TEST_STRING = 'TestString';

	@isTest
	public static void test_AssetUpdate() {
        Test.startTest();
		//Create basic test objects
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
		//Prepare proserv quote
		Quote proservTestQuote = new Quote (Name='proservTestQuote',
			OpportunityId = testOpp.Id,
			Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_PROSERV,
            ProServ_Status__c = 'In Progress');
		insert (new List<Quote>{proservTestQuote});
		//Add a couple of test products
		Product2 testProservProduct1 = new Product2(
                Name = 'TestProserv1',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true
        );
        Product2 testProservProduct2 = new Product2(
                Name = 'TestProserv2',
                Family = 'Add - Ons',
                Charge_Term__c = 'One - Time',
                IsActive = true
        );
        insert (new List<Product2>{testProservProduct1,testProservProduct2});
        //Create price book entries
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
        insert (new List<PricebookEntry>{testPrice1, testPrice2});
        //Create quote line items for products in the cart
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
        insert (new List<QuoteLineItem>{qli1, qli2});
        Test.stopTest();
        //Create two phases with empty completion date
		Phase__c testPhase1 = new Phase__c(
			Name = 'testPhase1',
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
			Quote__c = proservTestQuote.Id
		);
		Phase__c testPhase2 = new Phase__c(
			Name = 'testPhase2',
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
			Quote__c = proservTestQuote.Id
		);
		insert (new List<Phase__c>{testPhase1, testPhase2});
		//Distribute quote line items between phases
		Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
			RingCentral_Hardware_Phase__c = testPhase1.Id,
			Quote_Line_Item__c = qli1.Id,
			Quantity__c = 3,
			Address_Validated__c = true
		);
		Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
			RingCentral_Hardware_Phase__c = testPhase1.Id,
			Quote_Line_Item__c = qli2.Id,
			Quantity__c = 3,
			Address_Validated__c = true
		);
		insert (new List<Hardware_Line_Item__c>{testHLI1, testHLI2});

		//Create Asset for both test products
		Asset testAsset1 = new Asset (
			Name = String.valueOf(qli1.Product2Id),
			AccountId = testAcc.Id,
			Unit_Price__c = qli1.UnitPrice,
			Product2Id = testProservProduct1.Id
		);
		Asset testAsset2 = new Asset (
			Name = String.valueOf(qli2.Product2Id),
			AccountId = testAcc.Id,
			Unit_Price__c = qli2.UnitPrice,
			Product2Id = testProservProduct2.Id
		);
		insert (new List<Asset>{testAsset1, testAsset2});

		//Create test order
        Order testOrder = new Order(
            AccountId = testAcc.Id,
            QuoteId = proservTestQuote.Id,
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId(),
            Status = 'Requested');
        insert (new List<Order>{testOrder});
        //Create order items for every quote line item
        OrderItem testOrderItem1 = new OrderItem(
            OrderId = testOrder.Id,
            PriceBookEntryId = testPrice1.Id,
            Quantity = 3,
            UnitPrice = 50,
            QuoteLineItemId = qli1.Id,
            Asset__c = testAsset1.Id
        );
        OrderItem testOrderItem2 = new OrderItem(
            OrderId = testOrder.Id,
            PriceBookEntryId = testPrice2.Id,
            Quantity = 3,
            UnitPrice = 50,
            QuoteLineItemId = qli2.Id,
            Asset__c = testAsset2.Id
        );
        insert (new List<OrderItem>{testOrderItem1, testOrderItem2});

		//Before phase update delivered quantity on asset records is equal to null
		System.assertEquals(null,testAsset1.Delivered_Quantity__c);
		System.assertEquals(null,testAsset2.Delivered_Quantity__c);

			//change completion date on phase object
			testPhase1.Completed_Date__c = system.now();
			testPhase1.BillingStatus__c = PhaseHelper.BILLING_STATUS_MANUAL;
			testPhase2.Completed_Date__c = system.now();
			testPhase2.BillingStatus__c = PhaseHelper.BILLING_STATUS_SUBMITTED;
			update(new List<Phase__c>{testPhase1, testPhase2});
		Asset assetRecord = [SELECT Id, Delivered_Quantity__c, Product2Id FROM Asset LIMIT 1];
		//Test if delivered quantity is calculated correclty
		System.assertEquals(3,assetRecord.Delivered_Quantity__c);
	}


	@isTest
	public static void testDeleteRelatedPLI() {

		Account testAcc = new Account(
			Name = 'testAccount'
		);
		insert testAcc;

		Order ord = new Order(
			AccountId = testAcc.Id,
			Status = 'New',
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
			Name = 'testPhase',
			RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
			Order__c = ord.Id
		);
		insert testPhase;

		Hardware_Line_Item__c testHLI1 = new Hardware_Line_Item__c(
			RingCentral_Hardware_Phase__c = testPhase.Id,
			Order_Line_Item__c = oi.Id,
			RecordTypeId = Schema.SObjectType.Hardware_Line_Item__c.getRecordTypeInfosByName().get('ProServ Line Item').getRecordTypeId(),
			Quantity__c = 3
		);
		Hardware_Line_Item__c testHLI2 = new Hardware_Line_Item__c(
			RingCentral_Hardware_Phase__c = testPhase.Id,
			Order_Line_Item__c = oi.Id,
			RecordTypeId = Schema.SObjectType.Hardware_Line_Item__c.getRecordTypeInfosByName().get('ProServ Line Item').getRecordTypeId(),
			Quantity__c = 3
		);
		insert (new List<Hardware_Line_Item__c>{testHLI1, testHLI2});

		Test.startTest();

			// if Phase was deleted - we need to delete related PhaseLineItem too
			delete testPhase;

			List<Hardware_Line_Item__c> reselectedHLI = [select Id from Hardware_Line_Item__c];
			System.assertEquals(0, reselectedHLI.size(), 'PhaseLineItem should have been deleted');

		Test.stopTest();
	}

	@isTest
	public static void testPhaseFieldsPrepopulation() {

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

		Test.startTest();

			Phase__c testPhase1 = new Phase__c(
				Name = 'testPhase1',
				RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get(PhaseHelper.RT_NAME_PROSERV_PHASE).getRecordTypeId(),
				Initial_Payment__c = 20,
				Order__c = ord.Id
			);

			Phase__c testPhase2 = new Phase__c(
				Name = 'testPhase2',
				RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get(PhaseHelper.RT_NAME_PROSERV_PHASE).getRecordTypeId(),
				Initial_Payment__c = 80,
				Order__c = ord.Id
			);
			insert (new List <Phase__c> {testPhase1, testPhase2});

			Phase__c phaseToCheck = [SELECT Id, Name, Initial_Payment__c, Percentage__c, Status__c FROM Phase__c WHERE Name = 'testPhase1' LIMIT 1];
			//Check if phase fileds are correctly prepopulated
			System.assertEquals(20, phaseToCheck.Initial_Payment__c, 'Initial payment in Phase should have been 20');
			System.assertEquals(20, phaseToCheck.Percentage__c, 'Percentage in Phase should have been 20');
			System.assertEquals('New', phaseToCheck.Status__c, 'Phase status should have been New');

		Test.stopTest();
	}

	@isTest
	public static void testPopulateMaxPhaseNumberOnInsert() {

		Account testAcc = new Account(
			Name = 'testAccount'
		);
		insert testAcc;

		List<Order> ordersList = new List<Order>();
		Order ord = new Order(
			AccountId = testAcc.Id,
			Status = 'New',
			EffectiveDate = System.today(),
			Provision_Date__c = System.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			RecordTypeId = OrderHelper.RT_ID_PROSERV
		);
		ordersList.add(ord);
		insert ordersList;

		List<Phase__c> phasesList = new List<Phase__c>();
		Phase__c ph1 = new Phase__c(
			Name = 'testPhase_1',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 1
		);
		phasesList.add(ph1);

		Phase__c ph2 = new Phase__c(
			Name = 'testPhase_2',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 2
		);
		phasesList.add(ph2);

		Phase__c ph3 = new Phase__c(
			Name = 'testPhase_3',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 5
		);
		phasesList.add(ph3);

		Test.startTest();
			insert phasesList;

			Order reselectedOrder = [SELECT Id, MaxPhaseNumber__c from Order WHERE Id = :ord.Id];
			System.assertEquals(ph3.Phase_Number__c, reselectedOrder.MaxPhaseNumber__c);

		Test.stopTest();
	}


	@isTest
	public static void testPopulateMaxPhaseNumberOnUpdate() {

		Account testAcc = new Account(
			Name = 'testAccount'
		);
		insert testAcc;

		List<Order> ordersList = new List<Order>();
		Order ord = new Order(
			AccountId = testAcc.Id,
			Status = 'New',
			EffectiveDate = System.today(),
			Provision_Date__c = System.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			RecordTypeId = OrderHelper.RT_ID_PROSERV
		);
		ordersList.add(ord);
		insert ordersList;

		List<Phase__c> phasesList = new List<Phase__c>();
		Phase__c ph1 = new Phase__c(
			Name = 'testPhase_1',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 1
		);
		phasesList.add(ph1);

		Phase__c ph2 = new Phase__c(
			Name = 'testPhase_2',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 2
		);
		phasesList.add(ph2);

		Phase__c ph3 = new Phase__c(
			Name = 'testPhase_3',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 3
		);
		phasesList.add(ph3);
		insert phasesList;

		Test.startTest();

			// we should clear cache for getting updated data
			ObjectCache.removeKey(ObjectCache.Partition.QUERIES, 'SelectOrderWithPhases');

			ph3.Phase_Number__c = 8;
			update ph3;

			Order reselectedOrder = [SELECT Id, MaxPhaseNumber__c from Order WHERE Id = :ord.Id];
			System.assertEquals(ph3.Phase_Number__c, reselectedOrder.MaxPhaseNumber__c);

		Test.stopTest();
	}


	@isTest
	public static void testPopulateMaxPhaseNumberOnDelete() {

		Account testAcc = new Account(
			Name = 'testAccount'
		);
		insert testAcc;

		List<Order> ordersList = new List<Order>();
		Order ord = new Order(
			AccountId = testAcc.Id,
			Status = 'New',
			EffectiveDate = System.today(),
			Provision_Date__c = System.today(),
			Pricebook2Id = Test.getStandardPricebookId(),
			RecordTypeId = OrderHelper.RT_ID_PROSERV
		);
		ordersList.add(ord);
		insert ordersList;

		List<Phase__c> phasesList = new List<Phase__c>();
		Phase__c ph1 = new Phase__c(
			Name = 'testPhase_1',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 1
		);
		phasesList.add(ph1);

		Phase__c ph2 = new Phase__c(
			Name = 'testPhase_2',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 2
		);
		phasesList.add(ph2);

		Phase__c ph3 = new Phase__c(
			Name = 'testPhase_3',
			Order__c = ord.Id,
			RecordTypeId = PhaseHelper.RT_ID_PROSERV_PHASE,
			Phase_Number__c = 3
		);
		phasesList.add(ph3);
		insert phasesList;

		Test.startTest();

			delete ph3;

			// Order.MaxPhaseNumber__c should be equal to maxPhaseNumber even if phase with MaxNumber was deleted
			// if previous maxPhaseNumber > new maxPhaseNumber - field value should be saved as is(as previous maxPhaseNumber)
			Order reselectedOrder = [SELECT Id, MaxPhaseNumber__c from Order WHERE Id = :ord.Id];
			System.assertEquals(ph3.Phase_Number__c, reselectedOrder.MaxPhaseNumber__c);

		Test.stopTest();
	}

    @IsTest
    private static void testPopulateOriginalQuoteNumberOnInsert() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCon.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => testAcc.Id,
                    Order.EffectiveDate => System.today(),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);

        Test.startTest();
            Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Phase__c.Name => 'testPhase_1',
                        Phase__c.Status__c => 'New',
                        Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                        Phase__c.Account__c => testAcc.Id,
                        Phase__c.Opportunity__c => testOpp.Id,
                        Phase__c.Quote__c => testQuote.Id,
                        Phase__c.Order__c => testOrder.Id,
                        Phase__c.Initial_Payment__c => 10,
                        Phase__c.Phase_Number__c => 1
                    }
                )
                .create()
                .getRecord();
        Quote checkQuote = [SELECT Id FROM Quote WHERE Id =: testQuote.Id];
        Phase__c checkPhase = [SELECT Id, OriginalQuoteNumber__c, Name FROM Phase__c WHERE Name = 'testPhase_1'];

        System.assert(checkPhase.OriginalQuoteNumber__c != null, 'OriginalQuoteNumber__c should be populated');
        System.assertEquals(
            checkPhase.OriginalQuoteNumber__c,
            checkQuote.Id,
            'Phase trigger logic haven\'t updated the field OriginalQuoteNumber__c'
        );

        Test.stopTest();
    }

    @isTest
    private static void testMavenlinkIntegrationUnsuccessful() {
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => testAcc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCon.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .create()
            .getRecord();
        Phase__c phase = new Phase__c();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);

        Test.startTest();
            phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Phase__c.Status__c => 'New',
                        Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                        Phase__c.Account__c => testAcc.Id,
                        Phase__c.Opportunity__c => testOpp.Id,
                        Phase__c.Quote__c => testQuote.Id,
                        Phase__c.Initial_Payment__c => 10,
                        Phase__c.Original_Phase__c => null
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecords = [SELECT PhaseId__c
                                                    FROM Mavenlink_Integrator__c
                                                    WHERE PhaseId__c = :phase.Id];
        System.assertEquals(mlRecords.size(),
                            0,
                            'Mavenlink Integrator was created unsuccesfully.');
    }

    @isTest
    private static void testMavenlinkIntegrationSuccessful() {
        Phase__c originalPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId()
                }
            )
            .create()
            .getRecord();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTest',
                    User.Username => 'Test!user@gmail.com',
                    User.Email => 'Test_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();

        Test.startTest();

        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('CC Professional Services').getRecordTypeId(),
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);
        Phase__c phase = new Phase__c();
            phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Phase__c.Name => 'testPhase_1',
                        Phase__c.Status__c => 'New',
                        Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                        Phase__c.Account__c => acc.Id,
                        Phase__c.Opportunity__c => oppty.Id,
                        Phase__c.Quote__c => q.Id,
                        Phase__c.Order__c => ord.Id,
                        Phase__c.Initial_Payment__c => 10,
                        Phase__c.Phase_Number__c => 1,
                        Phase__c.Estimated_Completion_Date__c => System.today() + 1
                    }
                )
                .create()
                .getRecord();
            phase.Last_Phase__c = originalPhase.Id;
            update phase;
        Test.stopTest();

        MavenlinkIntegratorSelector mlIntegratorSelector = new MavenlinkIntegratorSelector();
        List<Mavenlink_Integrator__c> mlRecords = (List<Mavenlink_Integrator__c>) mlIntegratorSelector
                                                                                        .selectMavenlinkIntegrator()
                                                                                        .executeQuery();

        Set<Id> objIds = new Set<Id>();
        objIds.add(phase.Id);
        List<Object> bindings = new List<Object>();
        bindings.add(objIds);
        PhaseSelector phaseSelector = new PhaseSelector();
        phase = (Phase__c) phaseSelector.selectPhaseById(bindings)
                                       .executeQuery()
                                       .get(0);

        System.assertEquals(false,
                            mlRecords.isEmpty(),
                            'Mavenlink Integrator was not created.');
        System.assertNotEquals(2,
                               mlRecords.size(),
                               'Wrong amount of Mavenlink Integrators were created.');
        System.assertEquals(phase.Account__c,
                            mlRecords.get(0).Account__c,
                            'Account lookup field was assigned incorrectly.');
        System.assertEquals(phase.Account__r.Name,
                            mlRecords.get(0).AccountId__c,
                            'Account lookup field was assigned incorrectly.');
        System.assertEquals(phase.Id,
                            mlRecords.get(0).PhaseId__c,
                            'Phase Id field was assigned incorrectly.');
        System.assertEquals(phase.Initial_Payment__c,
                            mlRecords.get(0).Initial_Payment__c,
                            'Phase Initial Payment field was assigned incorrectly.');
        System.assertEquals(phase.Account__r.Name,
                            mlRecords.get(0).Name,
                            'Name field was assigned incorrectly.');
        System.assertEquals(phase.Estimated_Completion_Date__c,
                            mlRecords.get(0).Estimated_Completion_Date__c,
                            'Estimated Completion Date field was assigned incorrectly.');
        System.assertEquals([
                                SELECT CurrencyIsoCode
                                FROM Opportunity
                                WHERE Id = :oppty.Id
                            ].CurrencyIsoCode,
                            mlRecords.get(0).EstimatedProfessionalServices12Month__c,
                            'Opportunity Currency Code was assigned incorrectly.');
    }

    @isTest
    private static void testMavenlinkIntegrationInsertUnsuccessful() {
        Phase__c phase = new Phase__c();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestUser1',
                    User.Username => 'TestUser1!user@gmail.com',
                    User.Email => 'TestUser1_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('Contact Center').getRecordTypeId(),
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);

        Test.startTest();
            phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Phase__c.Name => 'testPhase_1',
                        Phase__c.Status__c => 'New',
                        Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                        Phase__c.Account__c => acc.Id,
                        Phase__c.Opportunity__c => oppty.Id,
                        Phase__c.Quote__c => q.Id,
                        Phase__c.Order__c => ord.Id,
                        Phase__c.Initial_Payment__c => 10,
                        Phase__c.Phase_Number__c => 1,
                        Phase__c.Estimated_Completion_Date__c => System.today() + 1
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecords = [SELECT Id
                                                    FROM Mavenlink_Integrator__c];
        phase = [SELECT MavenlinkIntegrationStatus__c
                FROM Phase__c
                LIMIT 1];
        System.assertEquals(mlRecords.size(),
                            0,
                            'Mavenlink Integrator was created unsuccesfully.');
    }

    @isTest
    private static void testMavenlinkIntegrationAccountUpdateSuccessful() {
        Phase__c phase = new Phase__c();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestUser5',
                    User.Username => 'TestUser5!user@gmail.com',
                    User.Email => 'TestUser5_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();
        
        Test.startTest();
        
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId(),
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.OpportunityId => oppty.Id
                }
            )
            .create()
            .getRecord();

        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);
        phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'testPhase_1',
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => acc.Id,
                    Phase__c.Opportunity__c => oppty.Id,
                    Phase__c.Quote__c => q.Id,
                    Phase__c.Order__c => ord.Id,
                    Phase__c.Initial_Payment__c => 10,
                    Phase__c.Phase_Number__c => 1,
                    Phase__c.Estimated_Completion_Date__c => System.today() + 1
                }
            )
            .create()
            .getRecord();
        acc.RC_User_ID__c = us.Id;

            update acc;
        Test.stopTest();

        List<Phase__c> phaseRecords = [SELECT MavenlinkIntegrationStatus__c
                                        FROM Phase__c];
        System.assertEquals(phaseRecords.size(),
                            1,
                            'Mavenlink Integrator was not created.');
        System.assert(phaseRecords.get(0).MavenlinkIntegrationStatus__c.containsIgnoreCase('Record was created'),
                        'Mavenlink Integrator was created without sucess status.');
    }

    @isTest
    private static void testMavenlinkIntegrationWithoutChangeOrder() {
        Phase__c phase = new Phase__c();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestUser1',
                    User.Username => 'TestUser1!user@gmail.com',
                    User.Email => 'TestUser1_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Test.startTest();

        DateTime dateNow = System.now();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId(),
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.OpportunityId => oppty.Id
                }
            )
            .create()
            .getRecord();

        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = false);
        phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'testPhase_1',
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => acc.Id,
                    Phase__c.Opportunity__c => oppty.Id,
                    Phase__c.Quote__c => q.Id,
                    Phase__c.Order__c => ord.Id,
                    Phase__c.Initial_Payment__c => 10,
                    Phase__c.Phase_Number__c => 1,
                    Phase__c.Estimated_Completion_Date__c => System.today() + 1
                }
            )
            .create()
            .getRecord();
        oppty.Parent_Order__c = ord.Id;
        phase.Initial_Payment__c = 10;
        update phase;

            update oppty;
        Test.stopTest();

        List<Mavenlink_Integrator__c> mlRecords = [SELECT Id
                                                    FROM Mavenlink_Integrator__c];
        System.assertEquals(0, mlRecords.size(),
                            'Mavenlink Integrator record was created unsuccesfully.');
    }

    @isTest
    private static void testMavenlinkIntegrationWithChangeOrder() {
        Phase__c phase = new Phase__c();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestUser5',
                    User.Username => 'TestUser5!user@gmail.com',
                    User.Email => 'TestUser5_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        User manager  = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestmanagerUser',
                    User.Username => 'managerUser!user@gmail.com',
                    User.Email => 'managerUser_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        us.ManagerId = manager.id;
        update us;
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();

        Test.startTest();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId(),
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.OpportunityId => oppty.Id
                }
            )
            .create()
            .getRecord();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);
        phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => acc.Id,
                    Phase__c.Opportunity__c => oppty.Id,
                    Phase__c.Quote__c => q.Id,
                    Phase__c.Order__c => ord.Id
                }
            )
            .create()
            .getRecord();
        oppty.Parent_Order__c = ord.Id;
        update oppty;
        phase.Initial_Payment__c = null;
        phase.Status__c = PhaseHelper.STATUS_DELETED;
        phase.Completed_Date__c = System.today();
        update phase;
        Test.stopTest();

        MavenlinkIntegratorSelector mlIntegratorSelector = new MavenlinkIntegratorSelector();
        List<Mavenlink_Integrator__c> mlRecords = mlIntegratorSelector.selectMavenlinkIntegrator().executeQuery();

        System.assertEquals(1, mlRecords.size(),
                            'Mavenlink Integrator record should have been created.');
        System.assertEquals(PhaseHelper.STATUS_COMPLETED, mlRecords[0].PhaseStatus__c,
                            'Mavenlink Integrator record should be in Status ' + PhaseHelper.STATUS_COMPLETED);
    }

    @isTest
    private static void testMavenlinkIntegrationCurrenciesConvertion() {
        Test.startTest();
        Phase__c phase = new Phase__c();
        User us = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'TestTestUser1',
                    User.Username => 'TestUser1!user@gmail.com',
                    User.Email => 'TestUser1_user@gmail.com',
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .create()
            .getRecord();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Current_Owner__c => us.Id,
                    Account.Name => 'testAcc',
                    Account.Current_Owner_Name__c => TEST_STRING,
                    Account.RC_User_ID__c => us.Id,
                    Account.Sales_Segment__c => TEST_STRING
                }
            )
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();
        DateTime dateNow = System.now();
        Opportunity oppty = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Opportunity.AccountId => acc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => contact.Id,
                    Opportunity.EstimatedProfessionalServices12Month__c => 10
                }
            )
            .create()
            .getRecord();
        Quote q = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'quotetest',
                    Quote.OpportunityId => oppty.Id,
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => oppty.AccountId,
                    Quote.ProServ_Sold_Date__c => System.now(),
                    Quote.ProServSalesRep__c => us.Id,
                    Quote.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();
        Test.stopTest();
        Order ord = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.Status => 'New',
                    Order.RecordTypeId => Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId(),
                    Order.SOW_Type__c => 'Single Phase',
                    Order.Signed_SOW__c => TEST_STRING,
                    Order.AccountId => acc.Id,
                    Order.EffectiveDate => Date.newInstance(dateNow.year(), dateNow.month(), dateNow.day()),
                    Order.Provision_Date__c => System.today(),
                    Order.Pricebook2Id => Test.getStandardPricebookId(),
                    Order.OpportunityId => oppty.Id
                }
            )
            .create()
            .getRecord();
        insert new Feature_Toggle__c(Mavenlink_Integration__c = true, IsSynchronizeChangeOrders__c = true);
            phase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Phase__c.Name => 'testPhase_1',
                        Phase__c.Status__c => 'New',
                        Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                        Phase__c.Account__c => acc.Id,
                        Phase__c.Opportunity__c => oppty.Id,
                        Phase__c.Quote__c => q.Id,
                        Phase__c.Order__c => ord.Id,
                        Phase__c.Initial_Payment__c => 10,
                        Phase__c.Phase_Number__c => 1,
                        Phase__c.CurrencyIsoCode => 'CAD'
                    }
                )
                .create()
                .getRecord();

        List<Mavenlink_Integrator__c> mlRecords = [SELECT Initial_Payment__c
                                                    FROM Mavenlink_Integrator__c];
        List<Phase__c> phaseRecords = [SELECT Initial_Payment__c
                                        FROM Phase__c];
        System.assertEquals(mlRecords.get(0).Initial_Payment__c,
                            phaseRecords.get(0).Initial_Payment__c
                            / [SELECT ConversionRate
                                FROM CurrencyType
                                WHERE isActive = true
                                AND IsoCode = :phase.CurrencyIsoCode
                                LIMIT 1].ConversionRate,
                            'Phase OTP field was not converted.');
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testUpdateOrderCompletedPhasesOTPSummary() {

		Feature_Toggle__c featureToggle = Feature_Toggle__c.getOrgDefaults();
        featureToggle.NewChangeOrderFlow__c = true;
        insert featureToggle;

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, ValueProviderBuilder.provideUniqueString())
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_CC_PROSERV)
            .setField(Product2.IsActive, true)
            .setField(Product2.Family, Product2Helper.FAMILY_REFURBISHED_PHONES)
            .setField(Product2.Product_Type__c, Product2Helper.PRODUCT_TYPE_SEAT)
            .setField(Product2.Edition__c, 'testEntitlementProduct')
            .create()
            .getRecord();

        PricebookEntry testPricebookentryStandard = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPriceBookId())
            .setField(PricebookEntry.Product2Id, testProduct.Id)
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.provideUniqueNumber(100))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.Per_Line__c, false)
            .setField(PricebookEntry.Min_Quantity__c, 1)
            .setField(PricebookEntry.Max_Quantity__c, 100)
            .create()
            .getRecord();

        Account testAcc = (Account) new SObjectFactory()
            .create(
                Account.SObjectType,
                new Map<SObjectField, Object> {Account.Name => ValueProviderBuilder.provideUniqueString()}
            );

        Contact testCon = (Contact) new SObjectFactory()
            .create(
                Contact.SObjectType,
                new Map<SObjectField, Object> {
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.AccountId => testAcc.Id
                }
            );
		
        Test.startTest();
        Order testOrder = (Order) new SObjectFactory()
            .create(
                Order.SObjectType,
                new Map<SObjectField, Object> {
                    Order.AccountId => testAcc.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.PriceBook2Id => Test.getStandardPricebookId(),
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                    Order.Booked_ProServ_OTP__c => 1000
                }
            );

        Opportunity testOpp = (Opportunity) new SObjectFactory()
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object> {
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCon.Id,
                    Opportunity.Parent_Order__c => testOrder.Id
                }
            );

        Quote testQuote = (Quote) new SObjectFactory()
            .create(
                Quote.SObjectType,
                new Map<SObjectField, Object> {
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Total_Number_of_Digital_Lines__c => 10,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_IN_PROGRESS
                }
            );

        Order testOrder2 = (Order) new SObjectFactory()
            .create(
                Order.SObjectType,
                new Map<SObjectField, Object> {
                    Order.AccountId => testAcc.Id,
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.PriceBook2Id => Test.getStandardPricebookId(),
                    Order.QuoteId => testQuote.Id,
                    Order.OpportunityId => testOpp.Id,
                    Order.EffectiveDate => System.today(),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                    Order.Booked_ProServ_OTP__c => 400
                }
            );

        Map<String, Schema.RecordTypeInfo> PHASE_RECORD_TYPE_MAP =
            Schema.SObjectType.Phase__c.getRecordTypeInfosByName();

        Phase__c testPhase = (Phase__c) new SObjectFactory()
            .create(
                Phase__c.SObjectType,
                new Map<SObjectField, Object> {
                    Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                    Phase__c.Status__c => PhaseHelper.STATUS_NEW,
                    Phase__c.Estimated_Completion_Date__c => System.today(),
                    Phase__c.PhaseDescription__c => 'Test Phase Desc',
                    Phase__c.Opportunity__c => testOpp.Id,
                    Phase__c.Order__c => testOrder.Id,
                    Phase__c.RecordTypeId => PHASE_RECORD_TYPE_MAP.get(PhaseHelper.RT_NAME_PROSERV_PHASE).getRecordTypeId()
                }
            );
			
        Test.stopTest();
            QuoteLineItem testQuoteLineItem = (QuoteLineItem) new SObjectFactory()
                .create(
                    QuoteLineItem.SObjectType,
                    new Map<SObjectField, Object> {
                        QuoteLineItem.QuoteId => testQuote.Id,
                        QuoteLineItem.Product2Id => testProduct.Id,
                        QuoteLineItem.PricebookEntryId => testPricebookentryStandard.Id,
                        QuoteLineItem.Quantity => 5,
                        QuoteLineItem.UnitPrice => testPricebookentryStandard.UnitPrice
                    }
                );

            Hardware_Line_Item__c testPhaseLineItem = (Hardware_Line_Item__c) new SObjectFactory()
                .create(
                    Hardware_Line_Item__c.SObjectType,
                    new Map<SObjectField, Object> {
                        Hardware_Line_Item__c.Name => ValueProviderBuilder.provideUniqueString(),
                        Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                        Hardware_Line_Item__c.Quote_Line_Item__c => testQuoteLineItem.Id,
                        Hardware_Line_Item__c.Address_Validated__c => true,
                        Hardware_Line_Item__c.Total_Price__c => 300,
                        Hardware_Line_Item__c.Quantity__c => 5
                    }
                );

            testPhase.Initial_Payment__c = 300;
            testPhase.Completed_Date__c = System.today();
            update testPhase;


        OrderSelector selector = new OrderSelector();
        List<Object> bindings = new List<Object>();
        bindings.add(new Set<Id>{ testOrder.Id, testOrder2.Id });
        List<Order> orderList = selector.selectOrdersByIdsWithAmounts(bindings).executeQuery();

        /*System.assertEquals(300, orderList[0].Completed_Phases_OTP_Summary__c,
                                 'Order Completed Phases OTP Summary was not updated correctly');
        System.assertEquals(-300, orderList[1].Incremental_Order_Amount__c,
                                 'Order Incremental Order Amount was not updated correctly');*/

    }

    @isTest
    static void testCurrentOwnerFieldsAreNotRequired() {
        new SObjectFactory().create(Feature_Toggle__c.SObjectType,
            new Map<SObjectField, Object> {
                Feature_Toggle__c.Mavenlink_Integration__c => true
            }
        );

        User us = (User) new SObjectFactory().create(User.SObjectType,
            new Map<SObjectField, Object> {
                User.Username => 'PhaseTrigger@gmail.com',
				User.LastName => 'PhaseTrigger',
				User.Email => 'PhaseTriggeruser@gmail.com',
				User.Alias => 'phase',
				User.TimeZoneSidKey => 'America/Los_Angeles',
				User.ManagerId => UserInfo.getUserId(),
				User.LocaleSidKey => 'en_US',
				User.EmailEncodingKey => 'UTF-8',
				User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
				User.LanguageLocaleKey => 'en_US',
                User.Hierarchy_Role__c => UserHelper.SALES_REP_ROLE
            }
        );

        Account acc = (Account) new SObjectFactory().create(Account.SObjectType,
            new Map<SObjectField, Object> {
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Sales_Segment__c => TEST_STRING
            }
        );

        Contact con = (Contact) new SObjectFactory().create(Contact.SObjectType,
            new Map<SObjectField, Object> {
                Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                Contact.AccountId => acc.Id
            }
        );

        Opportunity oppty = (Opportunity) new SObjectFactory().create(Opportunity.SObjectType,
            new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
				Opportunity.Type => 'Syndicated - New',
				Opportunity.StageName => 'Planning',
				Opportunity.CloseDate => System.today().addMonths(1),
				Opportunity.AccountId => acc.Id,
                Opportunity.Primary_Opportunity_Contact__c => con.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.EstimatedProfessionalServices12Month__c => 10
            }
        );

        Quote quote = (Quote) new SObjectFactory().create(Quote.SObjectType,
            new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
				Quote.OpportunityId => oppty.Id,
				Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Total_Number_of_Digital_Lines__c => 10,
                Quote.ProServ_Sold_Date__c => System.now(),
                Quote.ProServSalesRep__c => us.Id
            }
        );

        Order ord = (Order) new SObjectFactory().create(Order.SObjectType,
            new Map<SObjectField, Object> {
                Order.Status => OrderHelper.STATUS_NEW,
                Order.SOW_Type__c => 'Single Phase',
                Order.Signed_SOW__c => TEST_STRING,
                Order.AccountId => acc.Id,
                Order.EffectiveDate => Date.today(),
                Order.RecordTypeId => OrderHelper.RT_ID_CC_PROSERV
            }
        );

        Phase__c phase = (Phase__c) new SObjectFactory().build(Phase__c.SObjectType,
            new Map<SObjectField, Object> {
                Phase__c.Status__c => PhaseHelper.STATUS_NEW,
                Phase__c.RecordTypeId => PhaseHelper.RT_ID_PROSERV_PHASE,
                Phase__c.Account__c => acc.Id,
                Phase__c.Opportunity__c => oppty.Id,
                Phase__c.Quote__c => quote.Id,
                Phase__c.Order__c => ord.Id,
                Phase__c.Initial_Payment__c => 10,
                Phase__c.Estimated_Completion_Date__c => System.today() + 1
            }
        );

        Test.startTest();
            insert phase;
        Test.stopTest();

        List<Mavenlink_Integrator__c> mavenlinkIntegrations = (List<Mavenlink_Integrator__c>) new MavenlinkIntegratorSelector()
            .selectMavenlinkIntegrator()
            .executeQuery();

        System.assertEquals(1, mavenlinkIntegrations.size(), 'One Mavenlink Integrator record should be created');
        System.assert(String.isEmpty(mavenlinkIntegrations.get(0).Current_Owner_Name__c),
            'Current_Owner_Name__c on Mavenlink_Integrator__c record should be blank (as on Account)');
        System.assert(String.isEmpty(mavenlinkIntegrations.get(0).Current_Owner_Manager_Name__c),
            'Current_Owner_Manager_Name__c on Mavenlink_Integrator__c record should be blank (as on Account)');
    }
}