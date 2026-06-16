@isTest
private class Test_QuoteLineItemTrigger {

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

	private static Integer getRandomNumberInRange(Integer min, Integer max) {
		/**
		 * Returns a random number between min (inclusive) and max (exclusive)
		*/
		return (Math.random() * (max - min) + min).intValue();
	}

	private static Pricebook2 testPriceBook;
	private static Opportunity testOpp;

	private static void insertTestData() {
		Triggers.switchOff();
		Account testAccount = new Account(
			Name = 'Test Account',
			Permitted_Brands__c = 'RingCentral'
		);
		insert testAccount;
		Triggers.switchOn();
		schedulerConfiguration__c myBrand = new schedulerConfiguration__c(
			Name = 'RingCentral'
		);
		insert myBrand;

		testPriceBook = new Pricebook2(
			Name = 'Test Price Book',
			Brand__c = myBrand.Id,
			Description ='Test Price Book Products',
			Service__c = 'Office',
			IsActive = true,
			Line_Range_Min__c = 5,
			Line_Range_Max__c = 10,
			CurrencyIsoCode = 'USD'
		);
		insert testPriceBook;
		Triggers.switchOff();
		testOpp = new Opportunity(
			AccountId = testAccount.Id,
			Name = 'MyTestOpportunity',
			Type = 'Existing Business',
			Brand_Name__c = 'RingCentral',
			Tier_Name__c = 'Office',
			StageName = '1. Qualify',
			CloseDate = System.today(),
			CurrencyIsoCode = 'USD'
		);
		insert testOpp;
		Triggers.switchOn();
		List<Product2> prodList = new List<Product2>();

		Product2 testProduct1 = new Product2(
			Name = 'testProduct1',
			IsActive = true,
			Feature__c = 5
		);
		prodList.add(testProduct1);

		Product2 testProduct2 = new Product2(
			Name = 'testProduct2',
			IsActive = true,
			Feature__c = 4
		);
		prodList.add(testProduct2);

		Product2 testProduct3 = new Product2(
			Name = 'testProduct3',
			IsActive = true,
			Feature__c = 42
		);
		prodList.add(testProduct3);

		Product2 testProduct4 = new Product2(
			Name = 'testProduct4',
			IsActive = true,
			Feature__c = 43
		);
		prodList.add(testProduct4);

		Product2 testProduct5 = new Product2(
			Name = 'testProduct5',
			IsActive = true,
			Feature__c = 2
		);
		prodList.add(testProduct5);

		Product2 testProduct6 = new Product2(
			Name = 'SoftPhone',
			IsActive = true,
			Feature__c = 11,
			Family = 'Discounted Phones'
		);
		prodList.add(testProduct6);

		insert prodList;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();

		for(Product2 item : prodList) {

			PricebookEntry pbeStd = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				Product2Id = item.Id,
				UnitPrice = getRandomNumberInRange(200, 1000),
				IsActive = true,
				UseStandardPrice = false,
				CurrencyIsoCode = 'USD'
			);
			pbeList.add(pbeStd);

			PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = testPriceBook.Id,
				Product2Id = item.Id,
				UnitPrice = getRandomNumberInRange(200, 1000),
				IsActive = true,
				UseStandardPrice = false,
				CurrencyIsoCode = 'USD'
			);
			pbeList.add(pbe);
		}
		insert pbeList;

	}

	@isTest
	static void test_InvalidNumberVanitySetups() {

		System.runAs(testUser) {

			insertTestData();


			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = true,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;


			PricebookEntry feature5Product = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Feature__c = 5 AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature5Product.Product2Id,
				Quantity = 1,
				UnitPrice = feature5Product.UnitPrice,
				PricebookEntryId = feature5Product.Id
			);

			Test.startTest();

				insert qli;

				Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote.Invalid_Number_of_Vanity_Setups__c == true);


				qli.Quantity = 2;
				update qli;

				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote2.Invalid_Number_of_Vanity_Setups__c == false);

			Test.stopTest();
		}
	}

	@isTest
	static void test_InvalidNumberVanitySetupsOnDelete() {

		System.runAs(testUser) {

			insertTestData();


			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = true,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;


			PricebookEntry feature5Product = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Feature__c = 5 AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature5Product.Product2Id,
				Quantity = 2,
				PricebookEntryId = feature5Product.Id,
                UnitPrice = feature5Product.UnitPrice
			);
			insert qli;

			Test.startTest();

				Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote.Invalid_Number_of_Vanity_Setups__c == false);


				delete qli;

				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote2.Invalid_Number_of_Vanity_Setups__c == true);

			Test.stopTest();
		}
	}


	@isTest
	static void test_InvalidNumberIntTFSetups() {

		System.runAs(testUser) {

			insertTestData();


			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = true,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;

			List<PricebookEntry> pbeList = [SELECT Id, Product2Id, Product2.Feature__c, UnitPrice FROM PricebookEntry
											WHERE (Product2.Feature__c = 42 OR Product2.Feature__c = 43) AND
											Pricebook2Id = :testSalesQuote.Pricebook2Id];

			PricebookEntry feature42Product;
			PricebookEntry feature43Product;

			for(PricebookEntry item : pbeList) {
				if(item.Product2.Feature__c == 42) {
					feature42Product = item;
				}
				if(item.Product2.Feature__c == 43) {
					feature43Product = item;
				}
			}


			List<QuoteLineItem> qliList = new List<QuoteLineItem>();

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature42Product.Product2Id,
				Quantity = 1,
				PricebookEntryId = feature42Product.Id,
                UnitPrice = feature42Product.UnitPrice
			);
			qliList.add(qli);

			QuoteLineItem qli2 = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature43Product.Product2Id,
				Quantity = 2,
				PricebookEntryId = feature43Product.Id,
                UnitPrice = feature43Product.UnitPrice
			);
			qliList.add(qli2);


			Test.startTest();

				insert qliList;

				Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];

				System.assert(reselectedQuote.Invalid_Number_of_Int_TF_Setups__c == true);

				for(QuoteLineItem item : qliList) {
					item.Quantity = 3;
				}
				update qliList;

				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];

				System.assert(reselectedQuote2.Invalid_Number_of_Int_TF_Setups__c == false);

			Test.stopTest();
		}
	}

	@isTest
    static void test_DownsellMultipleItemsFix() {

        Triggers.switchOff();

        System.runAs(testUser) {

            Account testAccount = new Account(
                Name = 'Test Account',
                Permitted_Brands__c = 'RingCentral'
            );
            insert testAccount;

            schedulerConfiguration__c myBrand = new schedulerConfiguration__c(
                Name = 'RingCentral'
            );
            insert myBrand;

            testPriceBook = new Pricebook2(
                Name = 'Test Price Book',
                Brand__c = myBrand.Id,
                Description ='Test Price Book Products',
                Service__c = 'Office',
                IsActive = true,
                Line_Range_Min__c = 1,
                Line_Range_Max__c = 10,
                CurrencyIsoCode = 'USD'
            );
            insert testPriceBook;

            testOpp = new Opportunity(
                AccountId = testAccount.Id,
                Name = 'MyTestOpportunity',
                Type = 'Existing Business',
                Brand_Name__c = 'RingCentral',
                Tier_Name__c = 'Office',
                StageName = '1. Qualify',
                CloseDate = System.today(),
                CurrencyIsoCode = 'USD'
            );
            insert testOpp;

            Product2 product11 = new Product2(
                Name = 'SoftPhone',
                IsActive = true,
                Feature__c = 11,
                Family = 'Discounted Phones'
            );
            insert product11;

            Product2 product17 = (Product2) new SObjectBuilder(Product2.SobjectType)
                .setFields(new Map<SObjectField, Object>{
                        Product2.Name => 'SoftPhone',
                        Product2.IsActive => true,
                        Product2.Feature__c => 17, // Digital Lines
                        Product2.Family => 'Service'
                })
                .create()
                .getRecord();

            new SObjectBuilder(PricebookEntry.SobjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => product11.Id,
                    PricebookEntry.UnitPrice => getRandomNumberInRange(200, 1000),
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD',
                    PricebookEntry.Per_Line__c => true
                })
                .create()
                .getRecord();
            PricebookEntry pbe11Feature = (PricebookEntry) new SObjectBuilder(PricebookEntry.SobjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => product11.Id,
                    PricebookEntry.UnitPrice => getRandomNumberInRange(200, 1000),
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD',
                    PricebookEntry.Per_Line__c => true
                })
                .create()
                .getRecord();
            new SObjectBuilder(PricebookEntry.SobjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => product17.Id,
                    PricebookEntry.UnitPrice => getRandomNumberInRange(200, 1000),
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD',
                    PricebookEntry.Per_Line__c => true
                })
                .create()
                .getRecord();
            PricebookEntry pbe17Feature = (PricebookEntry) new SObjectBuilder(PricebookEntry.SobjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => testPriceBook.Id,
                    PricebookEntry.Product2Id => product17.Id,
                    PricebookEntry.UnitPrice => getRandomNumberInRange(200, 1000),
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => 'USD',
                    PricebookEntry.Per_Line__c => true
                })
                .create()
                .getRecord();
            Quote testSalesQuote = (Quote) new SObjectBuilder(Quote.SobjectType)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Name => 'testSalesQuote' ,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => testPriceBook.Id,
                    Quote.Upsell_status__c => 'New',
                    Quote.Fax_Vanity_Number__c => true,
                    Quote.Main_Vanity_Number__c => true,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
                })
                .create()
                .getRecord();

            List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SobjectType)
                .quantity(2)
                .setFields(new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testSalesQuote.Id,
                    QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{pbe11Feature.Product2Id, pbe17Feature.Product2Id}),
                    QuoteLineItem.Quantity => ValueProviderBuilder.provideList(new List<Integer>{10, 1}),
                    QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideList(new List<Integer>{10, 7}),
                    QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id>{pbe11Feature.Id, pbe17Feature.Id}),
                    QuoteLineItem.UnitPrice => ValueProviderBuilder.provideList(new List<Decimal>{pbe11Feature.UnitPrice, pbe17Feature.UnitPrice})
                })
                .create()
                .getRecords();

			Triggers.switchOn();

            QuoteLineItem qliToDownsell = qlis[0];
            QuoteLineItem qliDownselled = qlis[1];

            Test.startTest();

                qliToDownsell.Quantity = -6;
                update qliToDownsell;

            Test.stopTest();

            for (QuoteLineItem qli : (List<QuoteLineItem>) new QuoteLineItemSelector()
                    .selectQuoteLineItems()
                    .selectFields(new List<String>{'Quantity'})
                    .setCondition('Id IN :bind0')
                    .setQueryBindings(new List<Object>{new List<Id>{qliToDownsell.Id, qliDownselled.Id}})
                    .executeQuery()) {

                if (qli.Id == qliToDownsell.Id) {
                    System.assertEquals(-6, qli.Quantity, 'Incorrect quantity on downselled QLI');
                } else {
                    System.assertEquals(
                        1,
                        qli.Quantity,
                        'QLI downsell caused incorrect quantity on another previously downselled QLI'
                    );
                }
            }
        }
    }

	@isTest
	static void test_InvalidNumberIntTFSetupsOnDelete() {

		System.runAs(testUser) {

			insertTestData();


			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = true,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;

			List<PricebookEntry> pbeList = [SELECT Id, Product2Id, Product2.Feature__c, UnitPrice FROM PricebookEntry
											WHERE (Product2.Feature__c = 42 OR Product2.Feature__c = 43) AND
											Pricebook2Id = :testSalesQuote.Pricebook2Id];

			PricebookEntry feature42Product;
			PricebookEntry feature43Product;

			for(PricebookEntry item : pbeList) {
				if(item.Product2.Feature__c == 42) {
					feature42Product = item;
				}
				if(item.Product2.Feature__c == 43) {
					feature43Product = item;
				}
			}


			List<QuoteLineItem> qliList = new List<QuoteLineItem>();

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature42Product.Product2Id,
				Quantity = 2,
				PricebookEntryId = feature42Product.Id,
                UnitPrice = feature42Product.UnitPrice
			);
			qliList.add(qli);

			QuoteLineItem qli2 = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature43Product.Product2Id,
				Quantity = 2,
				PricebookEntryId = feature43Product.Id,
                UnitPrice = feature43Product.UnitPrice
			);
			qliList.add(qli2);
			insert qliList;

			Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote.Invalid_Number_of_Int_TF_Setups__c == false);

			Test.startTest();

				delete qli2;

				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];

				System.assert(reselectedQuote2.Invalid_Number_of_Int_TF_Setups__c == true);

			Test.stopTest();
		}
	}


	@isTest
	static void test_InvalidNumber800Setups() {

		System.runAs(testUser) {

			insertTestData();


			Area_Codes__c myAreaCode = new Area_Codes__c(
				Name = '800'
			);
			insert myAreaCode;

			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = false,
				AreaCode__c = myAreaCode.Id,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;


			List<PricebookEntry> pbeList = [SELECT Id, Product2Id, Product2.Feature__c, UnitPrice FROM PricebookEntry
											WHERE (Product2.Feature__c = 2 OR Product2.Feature__c = 4) AND
											Pricebook2Id = :testSalesQuote.Pricebook2Id];

			PricebookEntry feature2Product;
			PricebookEntry feature4Product;

			for(PricebookEntry item : pbeList) {
				if(item.Product2.Feature__c == 2) {
					feature2Product = item;
				}
				if(item.Product2.Feature__c == 4) {
					feature4Product = item;
				}
			}

			List<QuoteLineItem> qliList = new List<QuoteLineItem>();

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature4Product.Product2Id,
				Quantity = 2,
				PricebookEntryId = feature4Product.Id,
                UnitPrice = feature4Product.UnitPrice
			);
			qliList.add(qli);

			QuoteLineItem qli2 = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature2Product.Product2Id,
				Quantity = 1,
				PricebookEntryId = feature2Product.Id,
                UnitPrice = feature2Product.UnitPrice
			);
			qliList.add(qli2);

			insert qliList;

			Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote.Invalid_Number_of_800_Setups__c == true);
			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.
			Test.startTest();
				Area_Code_Line_Item__c acliForFeature2 = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 1,
					Quote_Line_Item__c = qli2.Id
				);
				insert acliForFeature2;


				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote2.Invalid_Number_of_800_Setups__c == false);

			Test.stopTest();
		}
	}

	@isTest
	static void test_InvalidNumber800SetupsOnDelete() {

		System.runAs(testUser) {

			insertTestData();
			Test.startTest();
				Area_Codes__c myAreaCode = new Area_Codes__c(
					Name = '800'
				);
				insert myAreaCode;

				Quote testSalesQuote = new Quote (
					Name = 'testSalesQuote' ,
					OpportunityId = testOpp.Id,
					Pricebook2Id = testPriceBook.Id,
					Upsell_status__c = 'New',
					Fax_Vanity_Number__c = true,
					Main_Vanity_Number__c = false,
					AreaCode__c = myAreaCode.Id,
					RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
				);
				insert testSalesQuote;


				List<PricebookEntry> pbeList = [SELECT Id, Product2Id, Product2.Feature__c, UnitPrice FROM PricebookEntry
												WHERE (Product2.Feature__c = 2 OR Product2.Feature__c = 4) AND
												Pricebook2Id = :testSalesQuote.Pricebook2Id];

				PricebookEntry feature2Product;
				PricebookEntry feature4Product;

				for(PricebookEntry item : pbeList) {
					if(item.Product2.Feature__c == 2) {
						feature2Product = item;
					}
					if(item.Product2.Feature__c == 4) {
						feature4Product = item;
					}
				}


				List<QuoteLineItem> qliList = new List<QuoteLineItem>();

				QuoteLineItem qli = new QuoteLineItem(
					QuoteId = testSalesQuote.Id,
					Product2Id = feature4Product.Product2Id,
					Quantity = 2,
                    UnitPrice = feature4Product.UnitPrice,
					PricebookEntryId = feature4Product.Id
				);
				qliList.add(qli);

				QuoteLineItem qli2 = new QuoteLineItem(
					QuoteId = testSalesQuote.Id,
					Product2Id = feature2Product.Product2Id,
					Quantity = 1,
                    UnitPrice = feature2Product.UnitPrice,
					PricebookEntryId = feature2Product.Id
				);
				qliList.add(qli2);

				insert qliList;

				QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

				Area_Code_Line_Item__c acliForFeature2 = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 1,
					Quote_Line_Item__c = qli2.Id
				);
				insert acliForFeature2;


			Test.stopTest();
			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

			Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote.Invalid_Number_of_800_Setups__c == false);
			delete acliForFeature2;
			Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c, Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c from Quote where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote2.Invalid_Number_of_800_Setups__c == true);
		}
	}


	@isTest
	static void test_RequiredAreaCodesEmptyTollFreeAreaCode() {

		System.runAs(testUser) {

			insertTestData();


			Area_Codes__c myAreaCode = new Area_Codes__c(
				Name = '322',
				Type__c = 'Toll-Free'
			);
			insert myAreaCode;

			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = false,
				AreaCode__c = myAreaCode.Id,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;

			PricebookEntry feature2Product = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Feature__c = 2 AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);
			PricebookEntry discountedPhonesProduct = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Family = 'Discounted Phones' AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);

			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

			List<QuoteLineItem> qliList = new List<QuoteLineItem>();

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = discountedPhonesProduct.Product2Id,
				Quantity = 2,
                UnitPrice = feature2Product.UnitPrice,
				PricebookEntryId = feature2Product.Id
			);
			qliList.add(qli);

			QuoteLineItem qli2 = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature2Product.Product2Id,
				Quantity = 1,
                UnitPrice = feature2Product.UnitPrice,
                PricebookEntryId = feature2Product.Id
			);
			qliList.add(qli2);

			insert qliList;

			Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c,
										Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c,
										Required_Area_Codes_are_empty__c
									from Quote
									where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote.Required_Area_Codes_are_empty__c == true);

			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

			Test.startTest();

				List<Area_Code_Line_Item__c> acliList = new List<Area_Code_Line_Item__c>();

				Area_Code_Line_Item__c acli = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 2,
					Quote_Line_Item__c = qli.Id
				);
				acliList.add(acli);

				Area_Code_Line_Item__c acli1 = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 1,
					Quote_Line_Item__c = qli2.Id
				);
				acliList.add(acli1);

				insert acliList;



				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c,
											Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c,
											Required_Area_Codes_are_empty__c
										from Quote
										where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote2.Required_Area_Codes_are_empty__c == false);

			Test.stopTest();
		}
	}

	@isTest
	static void test_RequiredAreaCodesEmptyLocalAreaCode() {

		System.runAs(testUser) {

			insertTestData();


			Area_Codes__c myAreaCode = new Area_Codes__c(
				Name = '102',
				Type__c = 'Local'
			);
			insert myAreaCode;

			Quote testSalesQuote = new Quote (
				Name = 'testSalesQuote' ,
				OpportunityId = testOpp.Id,
				Pricebook2Id = testPriceBook.Id,
				Upsell_status__c = 'New',
				Fax_Vanity_Number__c = true,
				Main_Vanity_Number__c = false,
				AreaCode__c = myAreaCode.Id,
				RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
			);
			insert testSalesQuote;

			PricebookEntry feature2Product = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Feature__c = 2 AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);

			List<QuoteLineItem> qliList = new List<QuoteLineItem>();

			QuoteLineItem qli = new QuoteLineItem(
				QuoteId = testSalesQuote.Id,
				Product2Id = feature2Product.Product2Id,
				Quantity = 1,
                UnitPrice = feature2Product.UnitPrice,
				PricebookEntryId = feature2Product.Id
			);
			qliList.add(qli);

			insert qliList;

			Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c,
										Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c,
										Required_Area_Codes_are_empty__c
									from Quote
									where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote.Required_Area_Codes_are_empty__c == true);

			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

			Test.startTest();

				List<Area_Code_Line_Item__c> acliList = new List<Area_Code_Line_Item__c>();

				Area_Code_Line_Item__c acli = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 1,
					Quote_Line_Item__c = qli.Id
				);
				acliList.add(acli);

				insert acliList;



				Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c,
											Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c,
											Required_Area_Codes_are_empty__c
										from Quote
										where Id = :testSalesQuote.Id];
				System.assert(reselectedQuote2.Required_Area_Codes_are_empty__c == false);

			Test.stopTest();
		}
	}

	@isTest
	static void test_RequiredAreaCodesEmptyOnDelete() {

		System.runAs(testUser) {

			insertTestData();

			Test.startTest();
				Area_Codes__c myAreaCode = new Area_Codes__c(
					Name = '322',
					Type__c = 'Toll-Free'
				);
				insert myAreaCode;

				Quote testSalesQuote = new Quote (
					Name = 'testSalesQuote' ,
					OpportunityId = testOpp.Id,
					Pricebook2Id = testPriceBook.Id,
					Upsell_status__c = 'New',
					Fax_Vanity_Number__c = true,
					Main_Vanity_Number__c = false,
					AreaCode__c = myAreaCode.Id,
					RecordTypeId = [select Id from RecordType where SobjectType = 'Quote' AND DeveloperName = 'Sales_Quote'].Id
				);
				insert testSalesQuote;

				PricebookEntry feature2Product = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Feature__c = 2 AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);
				PricebookEntry discountedPhonesProduct = [SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Product2.Family = 'Discounted Phones' AND Pricebook2Id = :testSalesQuote.Pricebook2Id].get(0);

				List<QuoteLineItem> qliList = new List<QuoteLineItem>();

				QuoteLineItem qli = new QuoteLineItem(
					QuoteId = testSalesQuote.Id,
					Product2Id = discountedPhonesProduct.Product2Id,
					Quantity = 2,
                    UnitPrice = discountedPhonesProduct.UnitPrice,
					PricebookEntryId = discountedPhonesProduct.Id
				);
				qliList.add(qli);

				QuoteLineItem qli2 = new QuoteLineItem(
					QuoteId = testSalesQuote.Id,
					Product2Id = feature2Product.Product2Id,
					Quantity = 1,
					PricebookEntryId = feature2Product.Id,
                    UnitPrice = feature2Product.UnitPrice
				);
				qliList.add(qli2);

				insert qliList;

				QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

				List<Area_Code_Line_Item__c> acliList = new List<Area_Code_Line_Item__c>();

				Area_Code_Line_Item__c acli = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 2,
					Quote_Line_Item__c = qli.Id
				);
				acliList.add(acli);

				Area_Code_Line_Item__c acli1 = new Area_Code_Line_Item__c(
					Area_Code__c = myAreaCode.Id,
					Quantity__c = 1,
					Quote_Line_Item__c = qli2.Id
				);
				acliList.add(acli1);

				insert acliList;

			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

			Test.stopTest();

			QuoteLineItemTriggerHelper.qliIdToAreaCodeLineItemsListMap = new Map<Id, List<Area_Code_Line_Item__c>>();//nullify the map so Area_Code_Line_Item__c will be requeried again.

			Quote reselectedQuote = [select Id, Invalid_Number_of_Vanity_Setups__c,
										Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c,
										Required_Area_Codes_are_empty__c
									from Quote
									where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote.Required_Area_Codes_are_empty__c == false);
			delete acli;

			Quote reselectedQuote2 = [select Id, Invalid_Number_of_Vanity_Setups__c,
										Invalid_Number_of_800_Setups__c, Invalid_Number_of_Int_TF_Setups__c,
										Required_Area_Codes_are_empty__c
									from Quote
									where Id = :testSalesQuote.Id];
			System.assert(reselectedQuote2.Required_Area_Codes_are_empty__c == true);
		}
	}

}