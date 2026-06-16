@isTest
private class Test_Order_Before {

	private static User testUser = createUser('test'); // testUser with admin profile

	private static User createUser(String name) {
		User user = new User(
			Username = name+'!user@gmail.com',
			LastName = 'Test'+name,
			Email = name+'_user@gmail.com',
			Alias = 'test'+name,
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
	static void test_method_one() {

		System.runAs(testUser) {

			// create test Quote && QuoteLineItem

			Opportunity opp = new Opportunity(
				Name = 'Test Opportunity 2016',
				Type = 'Syndicated - New',
				StageName = 'Planning',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert opp;

			Quote testQuote = new Quote (
				Name = 'testQuote' ,
				OpportunityId = opp.id ,
				Pricebook2Id = Test.getStandardPricebookId()
			);
	        insert testQuote;



	        // create test Order
			Account testAcc = new Account(
				Name = 'testAcc',
				InContact_Service__c = 'Contact Center Basic',
				No_of_InContact_Seats__c = 3
			);
			insert testAcc;


			Id contactCenterRecordTypeId = [select Id from RecordType where SobjectType = 'Order' AND Name = 'Contact Center'].Id;

			Order testOrder = new Order(
				AccountId = testAcc.Id,
				EffectiveDate = System.today(),
				Status = 'New',
				inContact_Cluster__c = 'C20',
				inContact_account_ID__c = 'testInContactAccountId',
				Provision_Date__c = System.today(),
				Pricebook2Id = Test.getStandardPricebookId(),
				QuoteId = testQuote.Id,
				RecordTypeId = contactCenterRecordTypeId
			);
			insert testOrder;
			System.debug('testOrder.Id >>> ' + testOrder.Id);


			// create test OrderItem
			Product2 testProduct = new Product2(
				Name = 'testProduct',
				IsActive = true,
				Family = 'CC Service',
				Edition__c = 'Basic',
                Sub_Category__c = 'Contact Center',
				Charge_Term__c = 'Monthly - Contract'
			);
			insert testProduct;
			System.debug('testProduct.Id >>> ' + testProduct.Id);

			PricebookEntry testPBE = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				IsActive = true,
				UnitPrice = 1000,
				Product2Id = testProduct.Id
			);
			insert testPBE;
			System.debug('testPBE.Id >>> ' + testPBE.Id);

			OrderItem testOrderItem = new OrderItem(
				OrderId = testOrder.Id,
				PricebookEntryId = testPBE.Id,
				UnitPrice = 100,
				Quantity = 1
			);
			insert testOrderItem;
			System.debug('testOrderItem.Id >>> ' + testOrderItem.Id);


			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testQuote.Id,
				Product2Id = testProduct.Id,
				Quantity = 1,
				UnitPrice = testPBE.UnitPrice,
				PricebookEntryId = testPBE.Id
			);
			insert qli;


			Test.startTest();

				testOrder.Status = 'Provisioned';
				update testOrder;

			Test.stopTest();


			Account reselectedAcc =  [select id, Service_Status__c, inContact_Cluster__c,
				InContact_Service__c, Provision_Date__c, inContact_account_ID__c,
				Additional_Products_MRR__c,
				No_of_InContact_Seats__c from Account where Id =: testAcc.Id];
			System.debug('reselected account >>> ' + reselectedAcc);

			QuoteLineItem reselectedQLI = [select Id, EffectivePrice__c, TotalPrice from QuoteLineItem where Id = : qli.Id];
			System.debug('reselectedQLI >>> ' + reselectedQLI);

			System.assert(reselectedAcc.Service_Status__c == 'Contract Complete', reselectedAcc.Service_Status__c + ' != "Contract Complete"');
			System.assert(reselectedAcc.inContact_Cluster__c == testOrder.inContact_Cluster__c, reselectedAcc.inContact_Cluster__c + ' != ' + testOrder.inContact_Cluster__c);
			System.assert(reselectedAcc.InContact_Service__c == 'Contact Center ' + testProduct.Edition__c, reselectedAcc.InContact_Service__c + ' != ' + 'Contact Center ' + testProduct.Edition__c);

			System.assert(reselectedAcc.No_of_InContact_Seats__c == testOrderItem.Quantity + testAcc.No_of_InContact_Seats__c, reselectedAcc.No_of_InContact_Seats__c + ' != ' + testOrderItem.Quantity + testAcc.No_of_InContact_Seats__c);
			System.assert(reselectedAcc.Provision_Date__c == testOrder.Provision_Date__c, reselectedAcc.Provision_Date__c + ' != ' + testOrder.Provision_Date__c);
			System.assert(reselectedAcc.inContact_account_ID__c == testOrder.inContact_account_ID__c, reselectedAcc.inContact_account_ID__c + ' != ' + testOrder.inContact_account_ID__c);
			//System.assert(reselectedAcc.Additional_Products_MRR__c == reselectedQLI.TotalPrice, reselectedAcc.Additional_Products_MRR__c + ' != ' + reselectedQLI.TotalPrice);

		}

	}


	@isTest
	static void test_method_two() {

		System.runAs(testUser) {

			// create test Quote && QuoteLineItem

			Opportunity opp = new Opportunity(
				Name = 'Test Opportunity 2016',
				Type = 'Syndicated - New',
				StageName = 'Planning',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert opp;

			Quote testQuote = new Quote (
				Name = 'testQuote' ,
				OpportunityId = opp.id ,
				Pricebook2Id = Test.getStandardPricebookId()
			);
	        insert testQuote;


	        // create test Order
			Account testAcc = new Account(
				Name = 'testAcc',
				inContact_Cluster__c = 'C15',
				inContact_account_ID__c = 'new test InContactAccountId',
				No_of_InContact_Seats__c = 3
			);
			insert testAcc;


			Id contactCenterRecordTypeId = [select Id from RecordType where SobjectType = 'Order' AND Name = 'Contact Center'].Id;

			Order testOrder = new Order(
				AccountId = testAcc.Id,
				EffectiveDate = System.today(),
				Status = 'New',
				inContact_Cluster__c = 'C20',
				inContact_account_ID__c = 'testInContactAccountId',
				Provision_Date__c = System.today(),
				Pricebook2Id = Test.getStandardPricebookId(),
				QuoteId = testQuote.Id,
				RecordTypeId = contactCenterRecordTypeId
			);
			insert testOrder;
			System.debug('testOrder.Id >>> ' + testOrder.Id);


			List<Product2> productList = new List<Product2>();

			Product2 testProduct1 = new Product2(
				Name = 'testProduct1',
				IsActive = true,
				Family = 'CC Service',
                Sub_Category__c = 'Contact Center',
                Edition__c = 'Ultimate',
				Charge_Term__c = 'Annual'
			);
			productList.add(testProduct1);

			Product2 testProduct2 = new Product2(
				Name = 'testProduct2',
				IsActive = true,
				Family = 'Minutes Bundle',
				Number_of_Minutes__c = 250000,
				Edition__c = 'Ultimate',
                Sub_Category__c = 'Contact Center',
                Charge_Term__c = 'Annual'
			);
			productList.add(testProduct2);

			Product2 testProduct3 = new Product2(
				Name = 'testProduct3',
				IsActive = true,
				Family = 'Add - Ons',
				Number_of_Minutes__c = 250000,
				Edition__c = 'Ultimate',
				Sub_Category__c = 'Contact Center',
				Charge_Term__c = 'Annual'
			);
			productList.add(testProduct3);

			insert productList;


			List<PricebookEntry> pbeList = new List<PricebookEntry>();

			PricebookEntry testPBE1 = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				IsActive = true,
				UnitPrice = 1000,
				Product2Id = testProduct1.Id
			);
			pbeList.add(testPBE1);

			PricebookEntry testPBE2 = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				IsActive = true,
				UnitPrice = 1000,
				Product2Id = testProduct2.Id
			);
			pbeList.add(testPBE2);

			PricebookEntry testPBE3 = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				IsActive = true,
				UnitPrice = 1000,
				Product2Id = testProduct3.Id
			);
			pbeList.add(testPBE3);

			insert pbeList;


			List<QuoteLineItem> qliList = new List<QuoteLineItem>();

			QuoteLineItem qli1 = new QuoteLineItem(
				QuoteId = testQuote.Id,
				Product2Id = testProduct1.Id,
				Quantity = 6,
				UnitPrice = testPBE1.UnitPrice,
				PricebookEntryId = testPBE1.Id
			);
			qliList.add(qli1);

			QuoteLineItem qli2 = new QuoteLineItem(
				QuoteId = testQuote.Id,
				Product2Id = testProduct2.Id,
				Quantity = 6,
				UnitPrice = testPBE2.UnitPrice,
				PricebookEntryId = testPBE2.Id
			);
			qliList.add(qli2);

			QuoteLineItem qli3 = new QuoteLineItem(
				QuoteId = testQuote.Id,
				Product2Id = testProduct3.Id,
				Quantity = 6,
				UnitPrice = testPBE3.UnitPrice,
				PricebookEntryId = testPBE3.Id
			);
			qliList.add(qli3);

			insert qliList;


			List<OrderItem> orderItemList = new List<OrderItem>();

			OrderItem testOrderItem1 = new OrderItem(
				OrderId = testOrder.Id,
				PricebookEntryId = testPBE1.Id,
				UnitPrice = 100,
				Quantity = 7
			);
			orderItemList.add(testOrderItem1);

			OrderItem testOrderItem2 = new OrderItem(
				OrderId = testOrder.Id,
				PricebookEntryId = testPBE2.Id,
				UnitPrice = 100,
				Quantity = 7
			);
			orderItemList.add(testOrderItem2);

			OrderItem testOrderItem3 = new OrderItem(
				OrderId = testOrder.Id,
				PricebookEntryId = testPBE3.Id,
				UnitPrice = 100,
				Quantity = 7
			);
			orderItemList.add(testOrderItem3);


			insert orderItemList;


			Test.startTest();

				testOrder.Status = 'Provisioned';
				update testOrder;

				Account reselectedAcc =  [select id, Service_Status__c, inContact_Cluster__c,
					InContact_Service__c, Provision_Date__c, inContact_account_ID__c, Minute_Bundle__c,
					No_of_InContact_Seats__c from Account where Id =: testAcc.Id];
				System.debug('reselected account >>> ' + reselectedAcc);

				QuoteLineItem reselectedQLI1 = [select Id, EffectivePrice__c, TotalPrice from QuoteLineItem where Id = : qli1.Id];
				System.debug('reselectedQLI1 >>> ' + reselectedQLI1);

				QuoteLineItem reselectedQLI2 = [select Id, EffectivePrice__c, TotalPrice from QuoteLineItem where Id = : qli2.Id];
				System.debug('reselectedQLI2 >>> ' + reselectedQLI2);

				QuoteLineItem reselectedQLI3 = [select Id, EffectivePrice__c, TotalPrice from QuoteLineItem where Id = : qli3.Id];
				System.debug('reselectedQLI3 >>> ' + reselectedQLI3);

			Test.stopTest();

			System.assert(reselectedAcc.Service_Status__c == 'Contract Complete', reselectedAcc.Service_Status__c + ' != "Contract Complete"');
			System.assert(reselectedAcc.inContact_Cluster__c == testAcc.inContact_Cluster__c, reselectedAcc.inContact_Cluster__c + ' != ' + testAcc.inContact_Cluster__c);
			System.assert(reselectedAcc.InContact_Service__c == 'Contact Center ' + testProduct1.Edition__c, reselectedAcc.InContact_Service__c + ' != ' + 'Contact Center ' + testProduct1.Edition__c);
			System.assert(reselectedAcc.No_of_InContact_Seats__c == testOrderItem1.Quantity+3, reselectedAcc.No_of_InContact_Seats__c + ' != ' + testOrderItem1.Quantity);
			System.assert(reselectedAcc.Provision_Date__c == testOrder.Provision_Date__c, reselectedAcc.Provision_Date__c + ' != ' + testOrder.Provision_Date__c);
			System.assert(reselectedAcc.inContact_account_ID__c == testAcc.inContact_account_ID__c, reselectedAcc.inContact_account_ID__c + ' != ' + testAcc.inContact_account_ID__c);
			System.assert(reselectedAcc.Minute_Bundle__c == 0, reselectedAcc.Minute_Bundle__c + ' != 0');

		}

	}

	/**
	 * Check if Live Reports (B-1196) fields are updated
	 */
	@isTest
	static void test_method_four() {

		System.runAs(testUser) {
			Triggers.switchOff();
	        // create test Order
			Account testAcc = new Account(
				Name = 'testAcc'
			);
			insert testAcc;

			Opportunity opp = new Opportunity(
				Name = 'Test Opportunity Live Reports',
				StageName = '1. Qualify',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD',
				AccountId = testAcc.Id
			);
			insert opp;

			Quote testQuote = new Quote (
				Name = 'testQuote' ,
				OpportunityId = opp.id ,
				Pricebook2Id = Test.getStandardPricebookId()
			);
	        insert testQuote;
	        System.debug('testQuote.Id >>> ' + testQuote.Id);
	        System.debug('testQuote >>> ' + testQuote);

			Product2 testProduct = new Product2(
				Name = 'Live Reports Add-On',
				IsActive = true,
				Sub_Category__c = 'Main'
			);
			insert testProduct;
			System.debug('testProduct.Id >>> ' + testProduct.Id);
			System.debug('testProduct >>> ' + testProduct);

			PricebookEntry testPBE = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				IsActive = true,
				UnitPrice = 1000,
				Product2Id = testProduct.Id
			);
			insert testPBE;
			System.debug('testPBE.Id >>> ' + testPBE.Id);

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testQuote.Id,
				Product2Id = testProduct.Id,
				Quantity = 5,
				UnitPrice = testPBE.UnitPrice,
				PricebookEntryId = testPBE.Id
			);
			insert qli;
			System.debug('qli.Id >>> ' + qli.Id);
			System.debug('qli >>> ' + qli);

			Id ringCentralRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RingCentral').getRecordTypeId();
			Triggers.switchOn();

			Test.startTest();

				Order testOrder = new Order(
					Status = 'New',
					EffectiveDate = System.today(),
					Pricebook2Id = Test.getStandardPricebookId(),
					QuoteId = testQuote.Id,
					RecordTypeId = ringCentralRecordTypeId,
					AccountId = testAcc.Id
				);
				insert testOrder;
				System.debug('testOrder.Id >>> ' + testOrder.Id);

			Test.stopTest();

			Order orderToCheck = [SELECT Id, Name, Live_Reports_Sign_Up_Date__c,
									Number_of_Live_Reports_Licenses__c, Price_per_Live_Report_License__c
									FROM Order
									WHERE Id = :testOrder.Id
			 						LIMIT 1];

			System.assert(orderToCheck.Live_Reports_Sign_Up_Date__c == System.today());
			System.assert(orderToCheck.Number_of_Live_Reports_Licenses__c == 5);
			System.assert(orderToCheck.Price_per_Live_Report_License__c == testPBE.UnitPrice,
                          orderToCheck.Price_per_Live_Report_License__c + ' != ' + testPBE.UnitPrice);
		}
	}


	@isTest
	static void testDeleteRelatedSitesAndPhases() {

		System.runAs(testUser) {

			Account testAcc = new Account(
				Name = 'testAcc'
			);
			insert testAcc;

			Id ringCentralRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

			Order testOrder = new Order(
				Status = 'New',
				EffectiveDate = System.today(),
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = ringCentralRecordTypeId,
				AccountId = testAcc.Id
			);
			insert testOrder;

			Phase__c testPhase = new Phase__c(
				Name = 'testPhase',
				RecordTypeId = Schema.SObjectType.Phase__c.getRecordTypeInfosByName().get('ProServ Phase').getRecordTypeId(),
				Order__c = testOrder.Id
			);
			insert testPhase;

			Site__c testSite = new Site__c(
				Order__c = testOrder.Id
			);
			insert testSite;

			Test.startTest();

				// if Order was deleted - we need to delete related Phases And Sites too
				delete testOrder;

				List<Phase__c> phasesList = [select Id, IsDeleted from Phase__c];
				System.assertEquals(phasesList.size(), 0);

				List<Site__c> sitesList = [select Id from Site__c];
				System.assertEquals(sitesList.size(), 0);

			Test.stopTest();
		}
	}

    @isTest
    static void testCalcMinutesBundleWithoutEntitlements() {
        System.runAs(testUser) {
            Order ord = createTestDataWithMinutesBundleProduct(0);
            Account accBeforeOrderUpdate = getAccount(ord.AccountId);
            Triggers.switchOff();

            List<Package__c> pkgs = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Package__c.Account__c => accBeforeOrderUpdate.Id,
                        Package__c.Enterprise_Account_ID__c => accBeforeOrderUpdate.Id,
                        Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19'}),
                        Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{
                            QuoteHelper.NGBS_OFFICE_PRODUCT,
                            QuoteHelper.NGBS_RCCC_PRODUCT
                        })
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            Triggers.switchOn();
            Assert.areEqual(null, accBeforeOrderUpdate.Minute_Bundle__c, 'Minute Bundle should be empty');

            Test.startTest();
                ord.Status = 'Provisioned';
                update ord;
            Test.stopTest();

            Account accAfterOrderUpdate = getAccount(ord.AccountId);
            Package__c officePkgAfterUpdate = getPackageByAccIdAndServiceType(accAfterOrderUpdate.Id, AccountHelper.SERVICE_TYPE_RCCC);
            Assert.areEqual(0, accAfterOrderUpdate.Minute_Bundle__c, 'Minute Bundle should be set to 0, because Account hasn\'t necessary related Entitlement');
            Assert.areEqual(0, officePkgAfterUpdate.Actual_transport_MRR__c, 'Transport MRR should be set to 0, because Account hasn\'t necessary related Entitlement');
        }
    }

    @isTest
    static void testCalcMinutesBundleWithEntitlements() {
        System.runAs(testUser) {
            Order ord = createTestDataWithMinutesBundleProduct(1);
            Account accBeforeOrderUpdate = getAccount(ord.AccountId);
            Triggers.switchOff();

            List<Package__c> pkgs = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Package__c.Account__c => accBeforeOrderUpdate.Id,
                        Package__c.Enterprise_Account_ID__c => accBeforeOrderUpdate.Id,
                        Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19'}),
                        Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{
                            QuoteHelper.NGBS_OFFICE_PRODUCT,
                            QuoteHelper.NGBS_RCCC_PRODUCT
                        })
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            Triggers.switchOn();
            Assert.areEqual(null, accBeforeOrderUpdate.Minute_Bundle__c, 'Minute Bundle should be empty');

            Test.startTest();
                ord.Status = 'Provisioned';
                update ord;
            Test.stopTest();

            Account accAfterOrderUpdate = getAccount(ord.AccountId);
            Package__c officePkgAfterUpdate = getPackageByAccIdAndServiceType(accAfterOrderUpdate.Id, AccountHelper.SERVICE_TYPE_RCCC);
            Assert.areEqual(50000, accAfterOrderUpdate.Minute_Bundle__c, 'Minute Bundle should be calculate as certain Entitlement__c.Product__r.Number_of_Minutes__c');
            Assert.areEqual(1000.00, officePkgAfterUpdate.Actual_transport_MRR__c, 'Transport MRR should be set to certain related Entitlement__c.Total_Monthly_Price__c');
        }
    }

    @isTest
    static void testCalcMinutesBundleAndTransportMRRWitSeveralEntitlements() {
        System.runAs(testUser) {
            Order ord = createTestDataWithMinutesBundleProduct(2);
            Account accBeforeOrderUpdate = getAccount(ord.AccountId);
            Triggers.switchOff();

            List<Package__c> pkgs = (List<Package__c>) new SObjectBuilder(Package__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Package__c.Account__c => accBeforeOrderUpdate.Id,
                        Package__c.Enterprise_Account_ID__c => accBeforeOrderUpdate.Id,
                        Package__c.Account_Package_Id__c => ValueProviderBuilder.provideList(new List<String>{'18','19'}),
                        Package__c.Service_Type__c => ValueProviderBuilder.provideList(new List<String>{
                            QuoteHelper.NGBS_OFFICE_PRODUCT,
                            QuoteHelper.NGBS_RCCC_PRODUCT
                        })
                    }
                )
                .quantity(2)
                .create()
                .getRecords();

            Triggers.switchOn();
            Assert.areEqual(null, accBeforeOrderUpdate.Minute_Bundle__c, 'Minute Bundle should be empty');

            Test.startTest();
                ord.Status = 'Provisioned';
                update ord;
            Test.stopTest();

            Account accAfterOrderUpdate = getAccount(ord.AccountId);
            Package__c officePkgAfterUpdate = getPackageByAccIdAndServiceType(accAfterOrderUpdate.Id, AccountHelper.SERVICE_TYPE_RCCC);
            Assert.areEqual(100000, accAfterOrderUpdate.Minute_Bundle__c, 'Minute Bundle should be calculate as certain Entitlement__c.Product__r.Number_of_Minutes__c');
            Assert.areEqual(2000.00, officePkgAfterUpdate.Actual_transport_MRR__c, 'Transport MRR should be set to certain related Entitlement__c.Total_Monthly_Price__c');
        }
    }

    @isTest
    static void testSubmittedDateUpdateError() {

        List<PermissionSet> ccDeskPermSet = (List<PermissionSet>) new PermissionSetSelector()
            .selectPermissionSetByLabel(new List<Object>{CCUtils.PERM_SET_LABEL_CC_DESK_TEAM})
            .executeQuery();
        final Boolean isSandbox =
            ((Organization) new OrganizationSelector().selectOrg().setQueryCaching(true).executeQuery()[0]).isSandbox;

            System.assert(!ccDeskPermSet.isEmpty(), 'CC Desk Team permission set not found');
            if (isSandbox) {
                new SObjectBuilder(PermissionSetAssignment.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        PermissionSetAssignment.AssigneeId => testUser.Id,
                        PermissionSetAssignment.PermissionSetId => ccDeskPermSet[0].Id
                    }
                )
                .create();
            }
            System.runAs(testUser) {
                Order order = createTestDataWithMinutesBundleProduct(2);

                Test.startTest();
                    order.Submitted_Date__c = System.now().addDays(-20);
                    if (isSandbox) {
                        try {
                            update order;
                            System.assert(true, 'Exception not thrown');
                        } catch (DmlException e) {
							System.debug('ExceptionTest::: ' + e.getMessage());
                            System.assert(
                                e.getMessage().contains(isSandbox
                                    ? OrderHelper.ERROR_SUBMITTED_DATE_CHANGE_SANDBOX
                                    : OrderHelper.ERROR_SUBMITTED_DATE_CHANGE
                                ),
                                'Wrong exception thrown'
                            );
                        }
                    }
                Test.stopTest();
            }
    }

    private static Order createTestDataWithMinutesBundleProduct(Integer newEntitlements){
		Triggers.switchOff();
		Account acc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'testAcc'
				}
			)
			.create()
			.getRecord();
		Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();
		DateTime dateNow = System.now();
		Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Opportunity.Name => 'Test Opportunity 2016',
					Opportunity.Type => 'Syndicated - New',
					Opportunity.StageName => 'Planning',
					Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
					Opportunity.AccountId => acc.Id,
					Opportunity.Primary_Opportunity_Contact__c => cont.Id,
					Opportunity.EstimatedProfessionalServices12Month__c => 10
				}
			)
			.create()
			.getRecord();
		Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
			.setFields(
					new Map<SObjectField, Object>{
							Quote.Name => 'quotetest',
							Quote.OpportunityId => opp.Id,
							Quote.Total_Number_of_Digital_Lines__c => 10,
							Quote.Account__c => opp.AccountId,
							Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
							Quote.Upsell_Status__c => 'New',
							Quote.Pricebook2Id => Test.getStandardPricebookId()
					}
			)
			.create()
			.getRecord();

        Product2 prod = new Product2(
            Name = 'Test CC Minutes Bundle Product',
            Sub_Category__c = 'Contact Center',
            Family = 'Minutes Bundle',
            Charge_Term__c = 'Monthly',
            Number_of_Minutes__c = 50000,
            IsActive = true
        );
		insert prod;

		PriceBookEntry priceEntry = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					PriceBookEntry.Product2Id => prod.Id,
					PriceBookEntry.UnitPrice => 10000,
					PriceBookEntry.IsActive => true,
					PriceBookEntry.UseStandardPrice => false,
					PriceBookEntry.Pricebook2Id => Test.getStandardPricebookId()
				}
			)
			.create()
			.getRecord();

		QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					QuoteLineItem.ServiceDate => date.today(),
					QuoteLineItem.Description => 'TestLineItem',
					QuoteLineItem.UnitPrice => priceEntry.UnitPrice,
									QuoteLineItem.Quantity => 5,
									QuoteLineItem.QuoteId => quote.Id,
									QuoteLineItem.PriceBookEntryId => priceEntry.Id,
									QuoteLineItem.Product2Id => prod.Id,
									QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
									QuoteLineItem.Discount_number__c => 0,
									QuoteLineItem.NewQuantity__c => 5
				}
			)
			.create()
			.getRecord();

        Id ringCentralRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Contact Center').getRecordTypeId();
        Order ord = new Order(
            Status = 'New',
            AccountId = acc.Id,
            QuoteId = quote.Id,
            EffectiveDate = System.today(),
            Pricebook2Id = quote.Pricebook2Id,
            RecordTypeId = ringCentralRecordTypeId
        );
        insert ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = qli.PriceBookEntryId,
            UnitPrice = 100,
            Quantity = 7
        );
        insert oi;

        if(newEntitlements > 0){
            List<Entitlement__c> entitlements = new List<Entitlement__c>();
            for(Integer i=0; i<newEntitlements; i++){
                entitlements.add(new Entitlement__c(
                    Account__c = acc.Id,
                    Product__c = prod.Id,
                    Name = 'Test Ent'+i,
                    Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Price__c = 100.00,
                    Quantity__c = 10,
                    Active__c = true
                ));
            }
            insert entitlements;
        }
		Triggers.switchOn();
        return ord;
    }

    private static Account getAccount(Id accId){
        return [SELECT Id, Minute_Bundle__c FROM Account WHERE Id = :accId LIMIT 1];
    }

    private static Package__c getPackageByAccIdAndServiceType(Id accId, String serviceType){
        return [SELECT Id, Actual_transport_MRR__c FROM Package__c WHERE Account__c = :accId AND Service_Type__c = :serviceType LIMIT 1];
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testLiveReportsFields(){
        System.runAs(testUser){
			Account acc = (Account) new SObjectBuilder(Account.SObjectType)
				.setFields(
					new Map<SObjectField, Object>{
						Account.Name => 'testAcc'
					}
				)
				.create()
				.getRecord();
			Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
				.setFields(
					new Map<SObjectField, Object>{
						Contact.FirstName => 'Test1',
						Contact.LastName => 'Opty test contact',
						Contact.AccountId => acc.Id,
						Contact.Email => 'test@test.com',
						Contact.Phone => '+18885550505',
						Contact.Preferred_Language__c => 'en_US',
						Contact.CurrencyIsoCode => 'USD'
					}
				)
				.create()
				.getRecord();

			Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
				.setFields(
					new Map<SObjectField, Object>{
						Product2.Name => 'Live Reports Add-On',
						Product2.IsActive => true,
						Product2.GOA_Group__c => 'DEVICES_B_STOCK',
						Product2.Family => 'RingCentral',
						Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
						Product2.Sub_Category__c => 'Main'
					}
				)
				.create()
				.getRecord();

            Entitlement__c ent = new Entitlement__c(
                Name = 'Live Reports License',
                Active__c = true,
                Quantity__c = 28,
                Price__c = 300.00,
                Account__c = acc.Id,
                Product__c = prod.Id
            );
            insert ent;

			DateTime dateNow = System.now();
			Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
				.setFields(
					new Map<SObjectField, Object>{
						Opportunity.Name => 'Test Opportunity 2016',
						Opportunity.Type => 'Syndicated - New',
						Opportunity.StageName => 'Planning',
						Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
						Opportunity.AccountId => acc.Id,
						Opportunity.Primary_Opportunity_Contact__c => cont.Id,
						Opportunity.EstimatedProfessionalServices12Month__c => 10
					}
				)
				.create()
				.getRecord();
			Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
				.setFields(
						new Map<SObjectField, Object>{
								Quote.Name => 'quotetest',
								Quote.OpportunityId => opp.Id,
								Quote.Total_Number_of_Digital_Lines__c => 10,
								Quote.Account__c => opp.AccountId,
								Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
								Quote.Upsell_Status__c => 'New',
								Quote.Pricebook2Id => Test.getStandardPricebookId()
						}
				)
				.create()
				.getRecord();

			Test.startTest();

            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = quote.Pricebook2Id,
                IsActive = true,
                UnitPrice = 100,
                Product2Id = prod.Id
            );
            insert pbe;

            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = quote.Id,
                Product2Id = prod.Id,
                Quantity = 1,
                UnitPrice = 300.00,
                Zero_Quantity__c = true,
                Entitlement__c = ent.Id,
                PricebookEntryId = pbe.Id
            );
            insert qli;

            Id rcRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('RingCentral').getRecordTypeId();

            Order ord = new Order(
                Status = 'New',
                EffectiveDate = System.today(),
                Pricebook2Id = Test.getStandardPricebookId(),
                RecordTypeId = rcRecordTypeId,
                AccountId = acc.Id,
                QuoteId = quote.Id,
                OpportunityId = opp.Id
            );

            Order ord2 = ord.clone();

                insert ord;
                checkOrder(ord.Id, true);
                delete ord;

                qli.Zero_Quantity__c = false;
                update qli;
                insert ord2;
                checkOrder(ord2.Id, false);
            Test.stopTest();
        }
    }

    private static void checkOrder(Id orderId, Boolean isEmpty){
        Order ord = [
            SELECT Live_Reports_Sign_Up_Date__c, Number_of_Live_Reports_Licenses__c, Price_per_Live_Report_License__c
            FROM Order
            WHERE Id = :orderId LIMIT 1
        ];

        String shouldOrNot = isEmpty ? 'should' : 'shouldn\'t';

        System.assertEquals((ord.Live_Reports_Sign_Up_Date__c == null), isEmpty,
            'Live Reports Sign Up Date '+shouldOrNot+' be empty');
        System.assertEquals((ord.Number_of_Live_Reports_Licenses__c == null), isEmpty,
            'Number of Live Reports Licenses '+shouldOrNot+' be empty');
        System.assertEquals((ord.Price_per_Live_Report_License__c == null), isEmpty,
            'Price per Live Report License '+shouldOrNot+' be empty');
    }

    @IsTest
    private static void testProServOrderType() {
		Account acc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'testAcc'
				}
			)
			.create()
			.getRecord();
		Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Opty test contact',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '+18885550505',
                    Contact.Preferred_Language__c => 'en_US',
                    Contact.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();
		DateTime dateNow = System.now();
		Opportunity opportunityWithoutParent = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Opportunity.Name => 'Test Opportunity 2016',
					Opportunity.Type => 'Syndicated - New',
					Opportunity.StageName => 'Planning',
					Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
					Opportunity.AccountId => acc.Id,
					Opportunity.Primary_Opportunity_Contact__c => cont.Id,
					Opportunity.EstimatedProfessionalServices12Month__c => 10
				}
			)
			.create()
			.getRecord();

        Feature_Toggle__c featureToggle = Feature_Toggle__c.getOrgDefaults();
        featureToggle.NewChangeOrderFlow__c = true;
        insert featureToggle;

        Id ccProfServRecordTypeId =
            Schema.SObjectType.Order.getRecordTypeInfosByName().get(OrderHelper.RT_NAME_CC_PROSERV).getRecordTypeId();

        Order orderWithoutParent = new Order(
            Status = OrderHelper.STATUS_NEW,
            EffectiveDate = System.today(),
            RecordTypeId = ccProfServRecordTypeId,
            AccountId = acc.Id,
            OpportunityId = opportunityWithoutParent.Id
        );

        Order orderWithParent = new Order(
            Status = OrderHelper.STATUS_NEW,
            EffectiveDate = System.today(),
            RecordTypeId = ccProfServRecordTypeId,
            AccountId = acc.Id
        );

        Test.startTest();
        insert orderWithoutParent;

		Opportunity opportunityWithParent = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Opportunity.Name => 'Test Opportunity 2016',
					Opportunity.Type => 'Syndicated - New',
					Opportunity.StageName => 'Planning',
					Opportunity.CloseDate => Date.newinstance(dateNow.year(), dateNow.month(), dateNow.day()),
					Opportunity.AccountId => acc.Id,
					Opportunity.Primary_Opportunity_Contact__c => cont.Id,
					Opportunity.EstimatedProfessionalServices12Month__c => 10,
					Opportunity.Parent_Order__c => orderWithoutParent.Id
				}
			)
			.create()
			.getRecord();

        orderWithParent.OpportunityId = opportunityWithParent.Id;
        insert orderWithParent;
        Test.stopTest();

        orderWithoutParent = [  SELECT Id, Type
                                FROM Order
                                WHERE Id = :orderWithoutParent.Id
                                LIMIT 1];
        System.assertEquals(OrderHelper.TYPE_INITIAL_ORDER, orderWithoutParent.Type,
            'Incorrect value for Type field in Order without a parent');
        orderWithParent = [ SELECT Id, Type
                            FROM Order
                            WHERE Id = :orderWithParent.Id
                            LIMIT 1];
        System.assertEquals(OrderHelper.TYPE_CHANGE_ORDER, orderWithParent.Type,
            'Incorrect value for Type field in Order with a parent');
    }
}