@isTest
public class Test_OpportunityController {
	@isTest
	private static void myUnitTest() {
        Campaign camptest = new Campaign();
        camptest.Name = 'TestCampaign';
        camptest.Protected_Campaign__c = true;
        insert camptest;

        Account acctest = new Account();
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c='Sales Agents & Resellers';
        acctest.Partner_ID__c ='123';
        acctest.RecordTypeId  = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        insert acctest;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctest.id;
        contactObj.Email = 'test123@test.com';
        contactObj.LastName = 'TestLast';
        insert contactObj;

		Product2 prod = (Product2) new SobjectBuilder(Product2.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Product2.Name => 'Connect Pro - Annual Fee',
					Product2.IsActive => true,
					Product2.GOA_Group__c => 'DEVICES_B_STOCK',
					Product2.Family => 'RingCentral'
				}
			)
			.create()
			.getRecord();

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
		

        Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = OpportunityHelper.defaultOpportunityStage;
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.RecordTypeId = OpportunityHelper.RT_ID_SAVES_OPPORTUNITY;
        Oppval.Proposal_Expiration_Date__c = System.today() + 100;
        insert Oppval;

        Test.startTest(); 

        OpportunityLineItem oppLineItemObj = new OpportunityLineItem();
        oppLineItemObj.OpportunityId = Oppval.id;
        oppLineItemObj.Quantity = 10;
        oppLineItemObj.PricebookEntryId = priceEntry.Id;
        oppLineItemObj.TotalPrice = 100; 
        insert oppLineItemObj;

        ApexPages.currentPage().getParameters().put('Id',Oppval.Id);
        OpportunityController oppContObj = new OpportunityController(new ApexPages.StandardController(Oppval));

        Test.stopTest();

        System.assertNotEquals(oppContObj, null);
    }

    @isTest
    private static void myUnitTest1() {
        Campaign camptest = new Campaign();
        camptest.Name = 'TestCampaign';
        camptest.Protected_Campaign__c = true;
        insert camptest;

        Account acctest = new Account();
        acctest.Name='TestAccount';
        acctest.RC_Attribution_Channel__c='Sales Agents & Resellers';
        acctest.Partner_ID__c ='123';
        acctest.RecordTypeId  = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        acctest.RC_Brand__c = 'UK';
        insert acctest;

        Contact contactObj = new Contact();
        contactObj.AccountId =  acctest.id;
        contactObj.Email = 'test123@test.com';
        contactObj.LastName = 'TestLast';
        insert contactObj;

        Test.startTest(); 

        Opportunity Oppval = new Opportunity();
        Oppval.Name = 'Test Opp';
        Oppval.AccountId = acctest.Id;
        Oppval.Type = 'Existing Business';
        Oppval.StageName = OpportunityHelper.defaultOpportunityStage;
        Oppval.Sales_Model__c = 'Direct';
        Oppval.CloseDate = System.Today() + 10;
        Oppval.CurrencyIsoCode = 'USD';
        Oppval.Brand_Name__c= 'RingCentral';
        Oppval.RecordTypeId = OpportunityHelper.RT_ID_SAVES_OPPORTUNITY;
        Oppval.Proposal_Expiration_Date__c = System.today() + 100;
        insert Oppval;

        OpportunityContactRole oppContactRoleObj = new OpportunityContactRole();
        oppContactRoleObj.OpportunityId = Oppval.Id;
        oppContactRoleObj.ContactId = contactObj.id;
        oppContactRoleObj.IsPrimary = true;
        oppContactRoleObj.Role = 'Decision Maker';
        insert oppContactRoleObj;

		Product2 prod = (Product2) new SobjectBuilder(Product2.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Product2.Name => 'Connect Pro - Annual Fee',
					Product2.IsActive => true,
					Product2.GOA_Group__c => 'DEVICES_B_STOCK',
					Product2.Family => 'RingCentral'
				}
			)
			.create()
			.getRecord();

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

        OpportunityLineItem oppLineItemObj = new OpportunityLineItem();
        oppLineItemObj.OpportunityId = Oppval.id;
        oppLineItemObj.Quantity = 10;
        oppLineItemObj.PricebookEntryId = priceEntry.Id;
        oppLineItemObj.TotalPrice = 100; 
        insert oppLineItemObj;

        ApexPages.currentPage().getParameters().put('Id',Oppval.Id);
        OpportunityController oppContObj = new OpportunityController(new ApexPages.StandardController(Oppval));
        String formDate = oppContObj.formatDate(System.now());
        String monthName = oppContObj.getMonthName(System.now()); 
        String super10 = oppContObj.superScript('10');     
        String super11 = oppContObj.superScript('11');
        String super12 = oppContObj.superScript('12');
        String super13 = oppContObj.superScript('13');
        String super14 = oppContObj.superScript('14');
        Test.stopTest();
        String currentMonth = System.now().format('MMMMM');
        String formatedDate = currentMonth + ' ' 
                            + String.valueOf(System.now().day()) + '<sup>' 
                            + oppContObj.superScript(String.valueOf(System.now().day())) 
                            + '</sup>'+', '+ String.valueOf(System.now().year());

        System.assertEquals(formDate, formatedDate);
        System.assertEquals(monthName, currentMonth);
        System.assertEquals(super10, 'th');
        System.assertEquals(super11, 'st');
        System.assertEquals(super12, 'nd');
        System.assertEquals(super13, 'rd');
        System.assertEquals(super14, 'th');
    }
}