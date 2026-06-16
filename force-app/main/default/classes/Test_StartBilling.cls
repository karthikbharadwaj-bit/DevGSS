@isTest
public with sharing class Test_StartBilling {
	private static OrderItem testOrderItem;
	private static Opportunity testOpp;
	private static Product2 testProduct;
	private static Order testOrder;
	private static Account testAcc;

	private static final String SANDBOX_NAME = 'box35';
    private static final String USER_NAME = 'asuser@aquivalabs.com';

	private static void prepareData(String chargeTerm, DateTime timeStamp, String subCategory) {
       //Insert basic test objects
        testAcc = new Account (
            Name = 'testAccount'
        );
        insert testAcc;

        testOpp = new Opportunity (
            Name = 'MyTestOpportunity',
            Type = 'Existing Business',
            Brand_Name__c = 'RingCentral',
            Tier_Name__c = 'Professional',
            StageName = '1. Qualify',
            CloseDate = System.today(),
            CurrencyIsoCode = 'USD'
        );
        insert testOpp;

        Quote testQuote = new Quote (Name='testQuote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(), 
            RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert testQuote;
        //Create test product
        testProduct = new Product2(
                Name = 'TestProduct',
                Family = 'Add - Ons',
                Charge_Term__c = chargeTerm,
                IsActive = true,
                Sub_Category__c = subCategory);
        insert testProduct;
        //Create price book entry for product
        PricebookEntry testPrice = new PricebookEntry (
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = testProduct.Id,
                UnitPrice = 50,
                IsActive = true,
                UseStandardPrice = false,
                Per_Line__c = false,
                Min_Quantity__c = 1,
                Max_Quantity__c = 100
        );
        insert testPrice;
        //Create quote line item
        QuoteLineItem qli = new QuoteLineItem (
                ServiceDate = Date.today(),
                Description = 'TestLineItem1',
                Quantity = 3,
                QuoteId = testQuote.Id,
                UnitPrice = 50,
                Product2Id = testProduct.Id,
                PricebookEntryId = testPrice.Id
        );
        insert qli;
        //Create test order
        testOrder = new Order (
            AccountId = testAcc.Id,
            QuoteId = testQuote.Id,
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            EffectiveDate = System.today(),
            Status = 'Requested');
        insert testOrder;
        //Create test order item
        testOrderItem = new OrderItem (
            OrderId = testOrder.Id,
            PriceBookEntryId = testPrice.Id,
            Quantity = 3,
            UnitPrice = 50, 
            QuoteLineItemId = qli.Id,
            Billing_Start_Date__c = timeStamp);
        insert testOrderItem;
       
        
	}

	private static User createUser(){
		User user = new User(
			Username = USER_NAME + '.' + SANDBOX_NAME,
			LastName = 'testUser',
			Email = 'testUser@gmail.com',
			Alias = 'testUser',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
			LanguageLocaleKey = 'en_US'
		);
		insert user;
		return user;
	}

	@isTest
	public static void Test_WithValidationErrorsNoPermissions() {
		User testUser = createUser();
		Datetime currentDate = System.now();

		//Imitate 'Start Billing' button push
		prepareData('One - Time', currentDate, Product2Helper.SUBCATEGORY_RINGCENTRAL);
		System.runAs(testUser) {
			Test.startTest();
				String result = StartBilling.processData(testOrderItem.Id);
			Test.stopTest();
			List <String> errorMessagesList = (List<String>)JSON.deserialize(result, List<String>.class);
			//Check if all error messages are shown
			System.assertEquals(1, errorMessagesList.size());
		} 
	}

	@isTest
	public static void Test_WithValidationErrorsWithPernissions() {
		User testUser = createUser();
		Datetime currentDate = System.now();

		//Imitate 'Start Billing' button push
		prepareData('One - Time', currentDate, Product2Helper.SUBCATEGORY_RINGCENTRAL);
		System.runAs(testUser) {
			PermissionSet testPermissionSet = new PermissionSet (
				Name = 'Test_Start_Billing_for_Recurring_ProServ',
				Label = 'Test_Start_Billing_for_Recurring_ProServ');
			insert testPermissionSet;

			//Assign custom permission to permission set
			SetupEntityAccess testEntityAccess = new SetupEntityAccess (
				ParentId = testPermissionSet.Id,
				SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CustomPermissionHelper.PERMISSION_START_BILLING].Id);
			insert testEntityAccess;

			//Assign permission set to user
			PermissionSetAssignment testPermissionSetAssignment = new PermissionSetAssignment (
			        AssigneeId = UserInfo.getUserId(),
			        PermissionSetId = testPermissionSet.Id);
			insert testPermissionSetAssignment;
			Test.startTest();
				String result = StartBilling.processData(testOrderItem.Id);
                 StartBilling.updateOrderItemFields(testOrderItem);
        		 StartBilling.createApproval(testOrderItem);
			Test.stopTest();
			List <String> errorMessagesList = (List<String>)JSON.deserialize(result, List<String>.class);
			//Check if all error messages are shown
			System.assertEquals(3, errorMessagesList.size());
		} 
	}
}