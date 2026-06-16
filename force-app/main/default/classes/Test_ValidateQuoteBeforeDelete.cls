@isTest
private class Test_ValidateQuoteBeforeDelete {

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

	class CustomException extends Exception {}

	@isTest
	static void deletingLastSalesQuoteOnOpportunityShouldThrowError() {

		System.runAs(testUser) {

			Account testAcc = new Account(
				Name = 'testAccount'
			);
			insert testAcc;

			Opportunity testOpp = new Opportunity(
				AccountId = testAcc.Id,
				Name = 'MyTestOpportunity',
				Type = 'Existing Business',
				Brand_Name__c = 'RingCentral',
				Tier_Name__c = 'Professional',
				StageName = '1. Qualify',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert testOpp;

			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;

			Quote testProServQuote = new Quote (
				Name = 'testProServQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'ProServ_Quote'].Id
			);
			insert testProServQuote;


			Test.startTest();
				try{

					delete testSalesQuote;

					// if exception not thrown in delete trigger - we throw custom exception and compare messages in catch block
					throw new CustomException('An exception should have been thrown by the trigger (QuoteTriggerHelper.ValidateQuoteBeforeDelete) but was not.');

				}catch(Exception ex) {
					System.debug('exception catched while delete quote. ex >>> ' + ex);

					QuoteTriggerHelper.ValidateQuoteBeforeDelete handler = new QuoteTriggerHelper.ValidateQuoteBeforeDelete();

					Boolean expectedExceptionThrown = ex.getMessage().contains(handler.DELETE_QUOTE_ERROR_MESSAGE) ? true : false;

					System.assertEquals(expectedExceptionThrown, true);
				}
			Test.stopTest();
		}
	}


	@isTest
	static void deletingActiveQuoteShouldThrowError() {

		System.runAs(testUser) {

			Account testAcc = new Account(
				Name = 'testAccount'
			);
			insert testAcc;

			Opportunity testOpp = new Opportunity(
				AccountId = testAcc.Id,
				Name = 'MyTestOpportunity',
				Type = 'Existing Business',
				Brand_Name__c = 'RingCentral',
				Tier_Name__c = 'Professional',
				StageName = '1. Qualify',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert testOpp;

			Id salesQuoteRtId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id;

			Quote testSalesQuote1 = new Quote (
				Name = 'testSalesQuote_1',
				Status = 'Active',
				Start_Date__c = Date.today(),
				End_Date__c = Date.today().addDays(2),
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = salesQuoteRtId
			);
			insert testSalesQuote1;

			Quote testSalesQuote2 = new Quote (
				Name = 'testSalesQuote_2',
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = salesQuoteRtId
			);
			insert testSalesQuote2;


			Test.startTest();
				try{

					delete testSalesQuote1;

					// if exception not thrown in delete trigger - we throw custom exception and compare messages in catch block
					throw new CustomException('An exception should have been thrown by the trigger (QuoteTriggerHelper.ValidateQuoteBeforeDelete) but was not.');

				}catch(Exception ex) {
					System.debug('exception catched while delete quote. ex >>> ' + ex);

					QuoteTriggerHelper.ValidateQuoteBeforeDelete handler = new QuoteTriggerHelper.ValidateQuoteBeforeDelete();

					Boolean expectedExceptionThrown = ex.getMessage().contains(handler.DELETE_QUOTE_ERROR_MESSAGE) ? true : false;

					System.assertEquals(expectedExceptionThrown, true);
				}
			Test.stopTest();
		}
	}


	@isTest
	static void deletingQuoteInClosedWonOpportunityShouldThrowError() {

		System.runAs(testUser) {

			Account testAcc = new Account(
				Name = 'testAccount'
			);
			insert testAcc;

			Opportunity testOpp = new Opportunity(
				AccountId = testAcc.Id,
				Name = 'MyTestOpportunity',
				Type = 'Existing Business',
				Brand_Name__c = 'RingCentral',
				Tier_Name__c = 'Professional',
				StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert testOpp;

			Id salesQuoteRtId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id;

			Quote testSalesQuote1 = new Quote (
				Name = 'testSalesQuote_1',
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = salesQuoteRtId
			);
			insert testSalesQuote1;

			Quote testSalesQuote2 = new Quote (
				Name = 'testSalesQuote_2',
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = salesQuoteRtId
			);
			insert testSalesQuote2;

			Quote testProServQuote = new Quote (
				Name = 'testProServQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'ProServ_Quote'].Id
			);
			insert testProServQuote;


			Test.startTest();
				try{

					delete testSalesQuote1;

					// if exception not thrown in delete trigger - we throw custom exception and compare messages in catch block
					throw new CustomException('An exception should have been thrown by the trigger (QuoteTriggerHelper.ValidateQuoteBeforeDelete) but was not.');

				}catch(Exception ex) {
					System.debug('exception catched while delete quote. ex >>> ' + ex);

					QuoteTriggerHelper.ValidateQuoteBeforeDelete handler = new QuoteTriggerHelper.ValidateQuoteBeforeDelete();

					Boolean expectedExceptionThrown = ex.getMessage().contains(handler.DELETE_QUOTE_ERROR_MESSAGE) ? true : false;

					System.assertEquals(expectedExceptionThrown, true);
				}
			Test.stopTest();
		}
	}


	@isTest
	static void deletingProServQuoteWithFilledRCUserIdOnAccountShouldNotThrowError() {

		System.runAs(testUser) {

			Account testAcc = new Account(
				Name = 'testAccount',
				RC_User_ID__c = '123'
			);
			insert testAcc;

			Opportunity testOpp = new Opportunity(
				AccountId = testAcc.Id,
				Name = 'MyTestOpportunity',
				Type = 'Existing Business',
				Brand_Name__c = 'RingCentral',
				Tier_Name__c = 'Professional',
				StageName = '1. Qualify',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert testOpp;

			Id salesQuoteRtId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id;

			Quote testSalesQuote1 = new Quote (
				Name = 'testSalesQuote_1',
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = salesQuoteRtId
			);
			insert testSalesQuote1;

			Quote testProServQuote = new Quote (
				Name = 'testProServQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'ProServ_Quote'].Id
			);
			insert testProServQuote;


			Test.startTest();
				try{

					delete testProServQuote;

					// if exception not thrown in delete trigger - we throw custom exception and compare messages in catch block
					throw new CustomException('An exception should have been thrown by the trigger (QuoteTriggerHelper.ValidateQuoteBeforeDelete) but was not.');

				}catch(Exception ex) {
					System.debug('exception catched while delete quote. ex >>> ' + ex);

					QuoteTriggerHelper.ValidateQuoteBeforeDelete handler = new QuoteTriggerHelper.ValidateQuoteBeforeDelete();

					Boolean expectedExceptionThrown = ex.getMessage().contains(handler.DELETE_QUOTE_ERROR_MESSAGE) ? true : false;

					System.assertEquals(expectedExceptionThrown, false);
				}
			Test.stopTest();
		}
	}

	/**
	verify QLIs do not deleted from Sales Quote after deleting Proserv Quote
	if Sales Quote has Upsell status
	and entitlements for these products are exist
	**/
	@isTest
	static void syncedProServQliDoNotDeletedFromUpsellSalesQuoteAfterProservQuoteDelete() {

		System.runAs(testUser) {

			Triggers.switchOff();

			Map<String, Schema.RecordTypeInfo> quoteRTInfoByNameMap = Quote.sObjectType.getDescribe().getRecordTypeInfosByName();

			Pricebook2 testPriceBook = new Pricebook2(
				Name = 'Test Price Book',
				Description ='Test Price Book Products',
				IsActive = true,
				Line_Range_Min__c = 5,
				Line_Range_Max__c = 10,
				CurrencyIsoCode = 'USD'
			);
			insert testPriceBook;

			Account testAcc = new Account(
				Name = 'testAccount'
			);
			insert testAcc;

			Opportunity testOpp = new Opportunity(
				AccountId = testAcc.Id,
				Name = 'MyTestOpportunity',
				Type = 'Existing Business',
				Brand_Name__c = 'RingCentral',
				Tier_Name__c = 'Professional',
				StageName = '1. Qualify',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert testOpp;

			Id salesQuoteRtId = quoteRTInfoByNameMap.get('Sales Quote').getRecordTypeId();

			List<Quote> quoteList = new List<Quote>();

			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote',
				Upsell_Status__c = 'Upsell',
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = salesQuoteRtId
			);
			quoteList.add(testSalesQuote);

			Id proservQuoteRtId = quoteRTInfoByNameMap.get('ProServ Quote').getRecordTypeId();

			Quote testProServQuote = new Quote (
				Name = 'testProServQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = proservQuoteRtId
			);
			quoteList.add(testProServQuote);

			insert quoteList;

			List<Product2> prodList = new List<Product2>();

			Product2 testProduct = new Product2(
				Name = 'test product',
				IsActive = true,
				Sub_Category__c = 'Main'
			);
			prodList.add(testProduct);

			Product2 testProServProduct = new Product2(
				Name = 'test product',
				IsActive = true,
				Sub_Category__c = 'Professional Services'
			);
			prodList.add(testProServProduct);
			insert prodList;

			List<PricebookEntry> pbeList = new List<PricebookEntry>();
			PricebookEntry pbe;
			for(Product2 item : prodList) {

				pbe = new PricebookEntry(
					Pricebook2Id = Test.getStandardPricebookId(),
					Product2Id = item.Id,
					UnitPrice = 200,
					IsActive = true,
					UseStandardPrice = false,
					CurrencyIsoCode = 'USD'
				);
				pbeList.add(pbe);

				pbe = new PricebookEntry(
					Pricebook2Id = testPriceBook.Id,
					Product2Id = item.Id,
					UnitPrice = 200,
					IsActive = true,
					UseStandardPrice = false,
					Per_Line__c = false,
					CurrencyIsoCode = 'USD'
				);
				pbeList.add(pbe);
			}
			insert pbeList;

			Decimal entitlementQuantity = 2;
			Decimal entitlementDiscount = 3;
			String entitlementDiscountType = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY;

			List<Entitlement__c> entitlementList = new List<Entitlement__c>();
			for(Product2 prod : prodList) {
				entitlementList.add(
					new Entitlement__c(
						Name = prod.Name,
						Product__c = prod.Id,
						Account__c = testAcc.Id,
						Quantity__c = entitlementQuantity,
						Discount_Type__c = entitlementDiscountType,
						Discount__c = entitlementDiscount,
						Active__c = true,
						Price__c = 100
					)
				);
			}
			insert entitlementList;

			Map<Id, Entitlement__c> productIdToEntitlementMap = new Map<Id, Entitlement__c>();

			for(Entitlement__c item : entitlementList) {
				if(productIdToEntitlementMap.get(item.Product__c) == null) {
					productIdToEntitlementMap.put(item.Product__c, item);
				}
			}

			List<QuoteLineItem> qliList = new List<QuoteLineItem>();
			// create qlis for Sales Quote
			for(PricebookEntry item : pbeList) {
				if(item.Product2Id == testProduct.Id && item.Pricebook2Id == Test.getStandardPricebookId()) {

					Id entitlementId = productIdToEntitlementMap.get(item.Product2Id) == null ? null : productIdToEntitlementMap.get(item.Product2Id).Id;

					QuoteLineItem qli = new QuoteLineItem(
						QuoteId = testSalesQuote.Id,
						Product2Id = item.Product2Id,
						Entitlement__c = entitlementId,
						Quantity = 2,
						UnitPrice = 200,
						Discount_number__c = 3,
						PricebookEntryId = item.Id
					);
					qliList.add(qli);
				}
			}

			// create qlis for ProServ Quote
			for(PricebookEntry item : pbeList) {
				if(item.Product2Id == testProServProduct.Id && item.Pricebook2Id == Test.getStandardPricebookId()) {

					Id entitlementId = productIdToEntitlementMap.get(item.Product2Id) == null ? null : productIdToEntitlementMap.get(item.Product2Id).Id;

					QuoteLineItem qli = new QuoteLineItem(
						QuoteId = testProServQuote.Id,
						Product2Id = item.Product2Id,
						Entitlement__c = entitlementId,
						Quantity = 2,
						UnitPrice = 200,
						Discount_number__c = 3,
						PricebookEntryId = item.Id
					);
					qliList.add(qli);
				}
			}

			insert qliList;

            Test.startTest();

			// before sync we have only one QuoteLineItem in upsell SalesQuote
			System.assertEquals(1, [select Id from QuoteLineItem where QuoteId = :testSalesQuote.Id].size());

			// sync ProServ quote with Sales
			Map<String, String> syncResult = QuotingToolQuoteApexController.syncProServWithSales(testOpp.Id, true, 'ProServ');
			System.assertEquals('success', syncResult.get('status'));
			// after sync we have 2 QuoteLineItem in upsell SalesQuote
			// System.assertEquals(2, [select Id from QuoteLineItem where QuoteId = :testSalesQuote.Id].size());
			// delete ProServQuote
			delete testProServQuote;

            Test.stopTest();

			List<QuoteLineItem> reselectedQlis = [select Id, Quantity, Product2Id, Deactivated__c,
													Discount_type__c, Discount_number__c
												from QuoteLineItem
												where QuoteId = :testSalesQuote.Id];

			// after deleting ProServ quote we have 2 QuoteLineItems on Upsell SalesQuote
			System.assertEquals(2, reselectedQlis.size());

			// verify field values copied from Entitlement to QuoteLineItem
			for(QuoteLineItem item : reselectedQlis) {

				if(item.Product2Id == testProServProduct.Id ) {
					System.assertEquals(item.Quantity, entitlementQuantity);
					System.assertEquals(item.Deactivated__c, false);
				}
				System.assertEquals(item.Discount_type__c, entitlementDiscountType);
				System.assertEquals(item.Discount_number__c, entitlementDiscount);
			}

            Triggers.switchOn();
		}
	}

	/**
	Verify that ProServ status on synced ProServ quote not dropped to InProgress when CCProServ quote is deleted
	**/
	@isTest
	static void testDeletingCcProServQuoteShouldNotDropProservStatus() {

		System.runAs(testUser) {

			Pricebook2 testPriceBook = new Pricebook2(
				Name = 'Test Price Book',
				Description ='Test Price Book Products',
				IsActive = true,
				Line_Range_Min__c = 5,
				Line_Range_Max__c = 10,
				CurrencyIsoCode = 'USD'
			);
			insert testPriceBook;

			Account testAcc = new Account(
				Name = 'testAccount'
			);
			insert testAcc;

			Opportunity testOpp = new Opportunity(
				AccountId = testAcc.Id,
				Name = 'MyTestOpportunity',
				Type = 'Existing Business',
				Brand_Name__c = 'RingCentral',
				Tier_Name__c = 'Professional',
				StageName = '1. Qualify',
				CloseDate = System.today(),
				CurrencyIsoCode = 'USD'
			);
			insert testOpp;

			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote',
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = QuoteHelper.RT_ID_SALES
			);

			Quote testProServQuote = new Quote (
				Name = 'testProServQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = QuoteHelper.RT_ID_PROSERV
			);

			Quote testCCProServQuote = new Quote (
				Name = 'testCCProServQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = Test.getStandardPricebookId(),
				RecordTypeId = QuoteHelper.RT_ID_CC_PROSERV
			);

			insert new List<Quote>{
				testSalesQuote,
				testProServQuote,
				testCCProServQuote
			};

			List<Product2> productList = new List<Product2>();
			Product2 testProduct = new Product2(
				Name = 'test product',
				IsActive = true,
				Sub_Category__c = 'Main'
			);
			productList.add(testProduct);

			Product2 testProServProduct = new Product2(
				Name = 'test product',
				IsActive = true,
				Sub_Category__c = 'Professional Services'
			);
			productList.add(testProServProduct);

			insert productList;

			List<PricebookEntry> pbeList = new List<PricebookEntry>();
			PricebookEntry pbe;
			for(Product2 item : productList) {

				pbe = new PricebookEntry(
					Pricebook2Id = Test.getStandardPricebookId(),
					Product2Id = item.Id,
					UnitPrice = 200,
					IsActive = true,
					UseStandardPrice = false,
					CurrencyIsoCode = 'USD'
				);
				pbeList.add(pbe);

				pbe = new PricebookEntry(
					Pricebook2Id = testPriceBook.Id,
					Product2Id = item.Id,
					UnitPrice = 200,
					IsActive = true,
					UseStandardPrice = false,
					Per_Line__c = false,
					CurrencyIsoCode = 'USD'
				);
				pbeList.add(pbe);
			}
			insert pbeList;


			List<QuoteLineItem> qliList = new List<QuoteLineItem>();
			// create qlis for Sales Quote
			for(PricebookEntry item : pbeList) {
				if(item.Product2Id == testProduct.Id && item.Pricebook2Id == Test.getStandardPricebookId()) {

					QuoteLineItem qli = new QuoteLineItem(
						QuoteId = testSalesQuote.Id,
						Product2Id = item.Product2Id,
						Quantity = 1,
						UnitPrice = 200,
						PricebookEntryId = item.Id
					);
					qliList.add(qli);
				}

				if(item.Product2Id == testProServProduct.Id && item.Pricebook2Id == Test.getStandardPricebookId()) {

					QuoteLineItem qli = new QuoteLineItem(
						QuoteId = testProServQuote.Id,
						Product2Id = item.Product2Id,
						Quantity = 1,
						UnitPrice = 200,
						PricebookEntryId = item.Id
					);
					qliList.add(qli);
				}
			}


			Test.startTest();
				insert qliList;

				// sync ProServ quote with Sales
				Map<String, String> syncResult = QuotingToolQuoteApexController.syncProServWithSales(testOpp.Id, true, 'ProServ');
				System.assertEquals('success', syncResult.get('status'));

				delete testCCProServQuote;

				List<Quote> reselectedQuotes = [select Id, ProServ_Status__c from Quote where Id = :testProServQuote.Id];
				Quote reselectedProServQuote = reselectedQuotes.get(0);

				// Verify ProServ_Status__c is still 'Synced' on ProServ quote after deleting CCProServ quote
				System.assertEquals(reselectedProServQuote.ProServ_Status__c, QuoteHelper.PROSERVSTATUS_SYNCED);

			Test.stopTest();

		}
	}
}