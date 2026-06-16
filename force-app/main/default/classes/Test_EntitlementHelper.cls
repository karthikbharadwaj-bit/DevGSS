/**************************************************************************************************
* Project Name..........: Entitlement                                                             *
* File..................: EntitlementHelper.class                                                 *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 19-06-2014                                                              *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....: 19-06-2014                                                              *
* Description...........: Test Class for Entitlement Helper.                                      *
**************************************************************************************************/
@isTest
private class Test_EntitlementHelper {

	// Creating Test Utils object to create call method and setup test records.
	public static Test_Utils objTestUtils = new Test_Utils();

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void myUnitTest() {

		List<BusinessHours> lstBusinessHours =  new List<BusinessHours>();
		List<SlaProcess> lstSlaProcess =  new List<SlaProcess>();

		BusinessHours objBusinessHours = new BusinessHours();
		SlaProcess objSlaProcess = new SlaProcess();

		List<Entitlement_Account_Configuration__c> lstEntitlementAccount = new List<Entitlement_Account_Configuration__c>();
		List<Entitlement_Case_ReType_Configuration__c> lstEntitlementCaseReType = new List<Entitlement_Case_ReType_Configuration__c>();
		EntitlementEnable__c enableEntitlement = new EntitlementEnable__c();
		enableEntitlement.IsEntitlementsEnabled__c =  true;
		enableEntitlement.Name = 'IsEntitlementsEnabled';
		insert enableEntitlement;

		try{
	    	test.startTest();
	    	lstBusinessHours = [SELECT b.Name, b.Id FROM BusinessHours b];
			if(!lstBusinessHours.isEmpty()){
				objBusinessHours = lstBusinessHours[0];
			}

			lstSlaProcess = lstSlaProcess = EntitlementHelper.getSLAProcess();
			if(!lstSlaProcess.isEmpty()){
				objSlaProcess = lstSlaProcess[0];
			}

			// Setting up Entitlement Account Configuration record.
	    	lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Mobile', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='Web Support', Number_of_DLs__c='0-1', Service_Name__c='Mobile', Business_Hours__c=objBusinessHours.Id));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Office', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='Web Support', Number_of_DLs__c='0-1', Service_Name__c='Office', Business_Hours__c=objBusinessHours.Id));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Office 20+', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='Web Support', Number_of_DLs__c='20+', Service_Name__c='Office', Business_Hours__c=objBusinessHours.Id));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Office 2-19', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='TEST 19', Number_of_DLs__c='2-19', Service_Name__c='Office', Business_Hours__c=objBusinessHours.Id));
			/*
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Professional', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='Web Support', Number_of_DLs__c='0-1', Service_Name__c='Professional', Business_Hours__c=objBusinessHours.Id));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Fax', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='Web Support', Number_of_DLs__c='0-1', Service_Name__c='Fax', Business_Hours__c=objBusinessHours.Id));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='Test', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='ATS', Type__c='Test Type', Number_of_DLs__c='50+', Service_Name__c='Testing Service', Business_Hours__c='01mQ00000008Pco'));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='Default', SLA_Process__c=objSlaProcess.Id, Type__c='Default', Business_Hours__c=objBusinessHours.Id));
			lstEntitlementAccount.add(new Entitlement_Account_Configuration__c(Name='RingCentral Office 1 Line', SLA_Process__c=objSlaProcess.Id, RC_Brand__c='RingCentral', Type__c='Web Support', Number_of_DLs__c='0-1', Service_Name__c='Office 1 Line', Business_Hours__c=objBusinessHours.Id));
			*/
			insert lstEntitlementAccount;

    		Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
			Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();

			String recordType = '';
			for(String key : rtMapById.keySet()){
				if('Support-Case'.equalsIgnoreCase(String.valueOf(rtMapById.get(key).Name))){
					recordType = String.valueOf(key);
					break;
				}
			}

	    	// Setting up Entitlement Case Record Type configuration custom setting records.
	    	lstEntitlementCaseReType.add(new Entitlement_Case_ReType_Configuration__c(SLAProcessId__c=objSlaProcess.Id, Name='Default', Business_Hours_Name__c='Default', Business_Hours_Id__c=objBusinessHours.Id, SLAProcessName__c='Default'));
			lstEntitlementCaseReType.add(new Entitlement_Case_ReType_Configuration__c(SLAProcessId__c=objSlaProcess.Id, Name='Support-Case', Business_Hours_Name__c='Default', Business_Hours_Id__c=objBusinessHours.Id, SLAProcessName__c='TEST 19'));
			lstEntitlementCaseReType.add(new Entitlement_Case_ReType_Configuration__c(SLAProcessId__c=lstSlaProcess[1].Id, Name='Support - T1', Business_Hours_Name__c='Default', Business_Hours_Id__c=lstBusinessHours[1].Id, SLAProcessName__c='TEST 19'));
			insert lstEntitlementCaseReType;

	    	List<Account> accountList = new List<Account> ();
	    	List<Account> newAccountList = new List<Account> ();
	    	List<Entitlement> entitlementList = new List<Entitlement> ();
	    	for(Integer ii = 0;ii<3; ii++){
	    		accountList.add(new Account(Name='AccountName'+ii, Number_of_DL_s__c = 19+ii));
	    	}
        	accountList.add(new Account(Name='AccountName 4', Number_of_DL_s__c = 19+4));
	    	accountList = objTestUtils.createAccountRecord(accountList);

	    	//EntitlementHelper.createEntitlements(accountList, null);

	    	Set<Id> accountIds = new Set<Id>();
	    	Set<String> strAccountIdset = new Set<String>();
	    	for(Account objAccount1 : accountList){
	    		accountIds.add(objAccount1.Id);
	    		strAccountIdset.add(objAccount1.Id);
	    		entitlementList.add(new Entitlement(Name='Ent'+objAccount1.name, AccountId = objAccount1.Id, SlaProcessId=objSlaProcess.Id, BusinessHoursId = objBusinessHours.id));
	    		entitlementList.add(new Entitlement(Name='Ent'+objAccount1.name, AccountId = objAccount1.Id, SlaProcessId=lstSlaProcess[1].Id, BusinessHoursId = objBusinessHours.id));
            }
	    	insert entitlementList;

	    	delete new List<Entitlement>{
					entitlementList[1],entitlementList[2], entitlementList[3]
			};

	    	EntitlementHelper.getEntitlement(accountList[0].Id);

	    	Group queue = [SELECT Id FROM Group WHERE Name = 'General Support Queue' limit 1];

			Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

	        List<Case> lstCase = new List<Case>();
	        lstCase.add( new Case(Status='Work in Progress', AccountId=accountList[0].Id, EntitlementId=entitlementList[0].Id, RecordTypeId = recordType, ownerId = queue.Id));
	        lstCase.add( new Case(Status='Work in Progress', AccountId=accountList[1].Id, RecordTypeId = rtMapByName.get('Support - T1').RecordTypeId));
	        lstCase.add( new Case(Status='Work in Progress', AccountId=accountList[2].Id, RecordTypeId = rtMapByName.get('Support - T1').RecordTypeId));
        	lstCase.add( new Case(Status='Work in Progress', AccountId=accountList[3].Id, RecordTypeId = rtMapByName.get('Support - T1').RecordTypeId));
        	lstCase.add( new Case(Status='Work in Progress', AccountId=accountList[3].Id, RecordTypeId = rtMapByName.get('Support - T3').RecordTypeId));
	        lstCase.add( new Case(Status='Work in Progress', AccountId=accountList[0].Id, Callback_Contact_ID__c = '1111', RecordTypeId = rtMapByName.get('Support - T2').RecordTypeId));
			TriggerHandler.BY_PASS_CASE_ON_INSERT();
			insert lstCase;
			EntitlementHelper objEntitlementHelper = new EntitlementHelper();
	        EntitlementHelper.isPortalUser();
	        EntitlementHelper.IsEntitlementsEnabled();
	        /* Case update time get account IDs*/
	        EntitlementHelper.getSLAProcess();
	        EntitlementHelper.getSLAProcessMap();
	        EntitlementHelper.getBusinessHours();
	        EntitlementHelper.getBusinessHoursMap();
	        //EntitlementHelper.isChanged(new Account(), new Account());
	        EntitlementHelper.entitleAssignmentOncase(lstCase,null);
	        EntitlementHelper.closeCaseAssignedMilestone(lstCase, new Map<Id, Case>{lstCase[0].Id => lstCase[0]});
	        EntitlementHelper.fetchEntitlementConfiguration();
	        //EntitlementHelper.createAccountEntitlement(null,null,null);
	        test.stopTest();
        }catch(Exception ex){
    		system.debug('#### Error in Test_EntitlementHelper - Line - '+ex.getLineNumber());
    		system.debug('#### Error in Test_EntitlementHelper - Message - '+ex.getMessage());
    	}
	}

    @isTest
    private static void test_getEntitlementEffectivePricePercentage() {
        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Price__c => 575.88,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                Entitlement__c.Discount__c => 10
            })
            .build()
            .getRecord();

        Decimal result = EntitlementHelper.getEntitlementEffectivePrice(ent);
        Decimal expectedResult = 518.29;

        System.assertEquals(
            expectedResult,
            result,
            'Entitlement effective price for persentage discount type calculated incorrectly'
        );
    }

    @isTest
    private static void test_getEntitlementEffectivePriceCurrency() {
        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Price__c => 575.88,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 10
            })
            .build()
            .getRecord();

        Decimal result = EntitlementHelper.getEntitlementEffectivePrice(ent);
        Decimal expectedResult = 565.88;

        System.assertEquals(
            expectedResult,
            result,
            'Entitlement effective price for currency discount type calculated incorrectly'
        );
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void myUnitTest2() {
		try{
			//Create Account
			Account testAccount = new Account( Name = 'Test Account');
			insert testAccount;

			// Create PriceBook
			PriceBook2 testPriceBook = new Pricebook2(Name = 'Test Price Book', Description ='Test Price Book Products',
					IsActive = true, Line_Range_Min__c = 5, Service__c='Office');
			insert testPriceBook;

			// Create Opportunity
			Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = '1. Qualify',
					CloseDate = System.today(), AccountId = testAccount.Id);
			insert testOpportunity;

			// Create Quote
			Quote testQuote = new Quote (Name = 'Test Quote', OpportunityId = testOpportunity.Id,
					Pricebook2Id = testPriceBook.id,
					RecordTypeId = QuoteHelper.RT_ID_BILLING,
					Account__c = testAccount.Id);
			Quote testQuote2 = new Quote (Name = 'Test Quote2', OpportunityId = testOpportunity.Id,
					Pricebook2Id = testPriceBook.id,
					RecordTypeId = QuoteHelper.RT_ID_CC,
					Account__c = testAccount.Id);
			Quote testQuote3 = new Quote (Name = 'Test Quote2', OpportunityId = testOpportunity.Id,
					Pricebook2Id = testPriceBook.id,
					RecordTypeId = QuoteHelper.RT_ID_PROSERV,
					Account__c = testAccount.Id);
			insert new List<Quote>{testQuote,testQuote2,testQuote3};


			// Create Products
			Product2 testProduct1 = new Product2(Name = 'Test Softphone', IsActive = true, Sub_Category__c = 'Main',
					Feature__c = 12, Sub_Feature__c = -1, Family = 'Service',
					Cart_Tab_Availability__c = QuoteHelper.RT_NAME_SALES,
					Charge_Term__c = Product2Helper.CHARGE_TERM_MONTHLY);
			Product2 testProduct2 = new Product2(Name = 'Test Softphone', IsActive = true, Sub_Category__c = 'Main',
					Feature__c = 11, Sub_Feature__c = -1, Family = 'CC Service',
					Cart_Tab_Availability__c = QuoteHelper.RT_NAME_SALES);
			insert new List<Product2>{testProduct1,testProduct2};

			// Create PriceBookEntries
			PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
					Product2Id = testProduct1.Id, UnitPrice = 0, IsActive = true, UseStandardPrice = false);
			PricebookEntry testPrice1 = new PricebookEntry(Pricebook2Id = testPriceBook.Id,
					Product2Id = testProduct1.Id, UnitPrice = 0, IsActive = true, UseStandardPrice = false);
			insert new List<PricebookEntry>{
					standardPrice1, testPrice1
			};

			// Create Entitlements
			Entitlement__c testEntitlement1 = new Entitlement__c( Account__c = testAccount.Id,
					Product__c = testProduct1.Id, Active__c = true, Quantity__c = 5,
					Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,Price__c = 100, Discount__c = 10,
                    Quote__c = testQuote.id);
			Entitlement__c testEntitlement2 = new Entitlement__c( Account__c = testAccount.Id,
					Product__c = testProduct2.Id, Active__c = true, Quantity__c = 5,ChargeTerm__c = Product2Helper.CHARGE_TERM_MONTHLY,
					Discount_Type__c = QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE, Price__c = 100, Discount__c = 10,
                    Quote__c = testQuote2.id);
			insert new List<Entitlement__c>{
					testEntitlement1,testEntitlement2
			};
			test.startTest();
			EntitlementHelper.getDiscountValue(testEntitlement1);
			EntitlementHelper.getDiscountValue(testEntitlement2);
			EntitlementHelper.filterEntitlementsByChargeTerm(new List<Entitlement__c>{testEntitlement1,testEntitlement2});
			EntitlementHelper.getChargeTerm(testEntitlement1);
			EntitlementHelper.getChargeTerm(testEntitlement2);
			EntitlementHelper.getServiceEntitlement(testQuote.RecordTypeId,new List<Entitlement__c>{testEntitlement1});
			EntitlementHelper.getServiceEntitlement(testQuote2.RecordTypeId,new List<Entitlement__c>{testEntitlement1});
			EntitlementHelper.getServiceEntitlement(testQuote3.RecordTypeId,new List<Entitlement__c>{testEntitlement1});
			EntitlementHelper.isNGBSEntitlement(testEntitlement1);
			EntitlementHelper.DeleteRelatedEntitlements(new List<Quote>{testQuote});
        	EntitlementHelper.isNumberOfDLsNullOrLessEqualOne(null,null);
        	EntitlementHelper.isNumberOfDLsMidRange(5,'1-5');
			test.stopTest();
		}catch(Exception ex){
    		system.debug('#### Error in Test_EntitlementHelper - Line - '+ex.getLineNumber());
    		system.debug('#### Error in Test_EntitlementHelper - Message - '+ex.getMessage());
    	}
	}

    @isTest
    public static void nullifiedDiscountIsTakenAsZero() {
        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Price__c => 575.88,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
            })
            .build()
            .getRecord();

        Decimal valueWithDiscount = EntitlementHelper.getDiscountValue(ent);

        System.assertEquals(null, ent.Discount__c);
        System.assertEquals(0, valueWithDiscount);
    }

   	@isTest
    public static void testDeleteEntitlementsByQuoteLineItems() {
		Triggers.switchOff();
		Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .create()
            .getRecord();

		Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
					Opportunity.AccountId => acc.Id,
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity'),
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                    Opportunity.CloseDate => System.today()
                }
            )
            .create()
            .getRecord();

	    Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
					Quote.OpportunityId => opp.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                    Product2.Name => 'test'
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
			.setFields(new Map<SObjectField, Object>{
					PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
					PricebookEntry.Product2Id => prod.Id,
					PricebookEntry.IsActive => true
			})
			.create()
			.getRecord();

		Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Price__c => 575.88,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
				Entitlement__c.Quote__c => qt.Id,
				Entitlement__c.Account__c => acc.Id
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
			.setFields(new Map<SObjectField, Object>{
					QuoteLineItem.QuoteId => qt.Id,
					QuoteLineItem.Quantity => 1,
					QuoteLineItem.PricebookEntryId => standardPrice.Id,
					QuoteLineItem.UnitPrice => 10,
					QuoteLineItem.Entitlement__c => ent.Id
			})
			.create()
			.getRecord();

        Triggers.switchOn();

        Test.startTest();
        	EntitlementHelper.deleteEntitlementsByQuoteLineItems(qt.Id, new List<QuoteLineItem>{ qli });
			List<Entitlement__c> reselectedEntls = (List<Entitlement__c>) new EntitlementSelector()
				.selectEntitlementForSyncQuoteLineItemsByQuoteId(qt.Id)
				.executeQuery();
        Test.stopTest();
        Assert.areEqual(0, reselectedEntls.size(), 'Entitlements should be deleted');
    }
}