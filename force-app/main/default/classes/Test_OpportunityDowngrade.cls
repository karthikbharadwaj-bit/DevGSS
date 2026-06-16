/*       
* Created By    : Ishwarya
* Created Date  : 24-03-2020
* Description   : Test class for Opportunity_Downgrade class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_OpportunityDowngrade {
    @isTest
    public static void opportunityDowngrade(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testCont = (Contact) new SObjectBuilder(Contact.SObjectType)
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
                    Opportunity.Primary_Opportunity_Contact__c => testCont.Id
                }
            )
            .create()
            .getRecord();
        Id recTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('ProServ Quote').getRecordTypeId();
        system.debug('recTypeId' +recTypeId);
        Quote testQuote = new Quote(
            Name = 'quotetest',
            OpportunityId = testOpp.id,
            ProServ_Status__c ='Created',
            Total_Number_of_Digital_Lines__c = 10, Account__c = testOpp.AccountId,RecordTypeId=recTypeId);
        insert testQuote;
        Test.startTest();
        Opportunity_Downgrade.downgradeOpp(testOpp.Id);
        Test.stopTest();
        String s ='1/0';
        Opportunity_Downgrade.downgradeOpp(s);
        system.assertNotEquals(testQuote.ProServ_Status__c, 'Cancelled');
    }
    
    @isTest
    public static void opportunityDowngradeMethod1(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc'
                }
            )
            .create()
            .getRecord();
        Contact testCont = (Contact) new SObjectBuilder(Contact.SObjectType)
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
                    Opportunity.Primary_Opportunity_Contact__c => testCont.Id
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
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                        Quote.Upsell_Status__c => 'New'
                    }
                )
                .create()
                .getRecord();  
        
        Test.startTest();
        Opportunity_Downgrade.downgradeOpp(testOpp.Id);
        Test.stopTest();
        system.assertNotEquals(testQuote.ProServ_Status__c, 'Cancelled');
        
    }
       
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void opportunityDowngradexception(){
    String s ='1/0';
   Opportunity_Downgrade.downgradeOpp(s);
    }

    @isTest
    public static void opportunityDowngradeWithoutError() {
        User testUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields( new Map<SObjectField, Object>{
                User.LastName => 'testtestuser',
                User.Username => 'testuser!user@gmail.com',
                User.Email => 'testuser@gmail.com',
                User.Alias => 'test',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name =: ProfileHelper.PROFILE_NAME_CHANNEL_SALES_MANAGER_LIGHTNING].Id,
                User.LanguageLocaleKey => 'en_US'
            })
            .create()
            .getRecord();
        
   		Segment_Master__c segment = (Segment_Master__c) new SobjectBuilder(Segment_Master__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Segment_Master__c.Name => UserHelper.SEGMENT_MID_MARKET,
                Segment_Master__c.Max__c => 399,
                Segment_Master__c.Min__c => 100,
                Segment_Master__c.Country__c => 'United States',
                Segment_Master__c.Start_Date__c => Date.today()
            })
            .create()
            .getRecord();
        
        System.runAs(testUser) {            
            Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.Segment_Name__c => segment.Id  
                }
            )
            .create()
            .getRecord();
            Contact testCont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.FirstName => 'Test3',
                    Contact.LastName => 'Test3',
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
                new Map<SObjectField, Object> {
                    Opportunity.Name => 'Test Opportunity 2016',
                    Opportunity.Type => 'New Business',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => testCont.Id,
                    Opportunity.Why_We_Lost__c => 'Sales Process / Relationship',
                    Opportunity.Final_Competitor_we_lost_against__c => 'No Competition',
                    Opportunity.Additional_details_on_why_we_lost__c=> 'Test',
                    Opportunity.Estimated_12M_Total_Pipeline__c => 1600
                }
            )
            .create()
            .getRecord();
        
            Test.startTest();
                Opportunity_Downgrade.DowngradeWrapper dw;
                dw = Opportunity_Downgrade.downgradeOpp(testOpp.Id);
                Assert.areEqual('Success', dw.responseMessage, 'Downgrade call unsuccessful');

                testOpp.Why_We_Lost__c = '';
                update testOpp;

                dw = Opportunity_Downgrade.downgradeOpp(testOpp.Id);
                Assert.areEqual('Redirect', dw.responseMessage, 'Downgrade call unsuccessful');
            Test.stopTest();    
        }        
    }

    @isTest
    public static void testUpdateStatusesForOrderAndRelatedSuborders() {

        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Account.Name => ValueProviderBuilder.provideUniqueString()
        })
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Opportunity.CloseDate => System.today(),
            Opportunity.AccountId => testAccount.Id,
            Opportunity.Is_Billing_Opportunity__c => true,
            Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
        })
        .create()
        .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
            PriceBook2.IsActive => true,
            PriceBook2.Line_Range_Min__c => 2,
            PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
            PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
        })
        .create()
        .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            Quote.OpportunityId => opp.Id,
            Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
            Quote.Pricebook2Id => pb.Id,
            Quote.Enabled_LBO__c => true,
            Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
            Quote.isPrimary__c => true,
            Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
        })
        .create()
        .getRecord();

        Order testLockedOrder = (Order) new SOBjectBuilder(Order.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
            Order.Pricebook2Id => Test.getStandardPricebookId(),
            Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
            Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
            Order.EffectiveDate => System.today(),
            Order.Status => 'Locked',
            Order.QuoteId => qt.Id,
            Order.OpportunityId => opp.Id
        })
        .create()
        .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
            Order.Pricebook2Id => Test.getStandardPricebookId(),
            Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
            Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
            Order.EffectiveDate => System.today(),
            Order.Status => OrderHelper.STATUS_NEW,
            Order.QuoteId => qt.Id,
            Order.OpportunityId => opp.Id
        })
        .create()
        .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
            Phase__c.Phase_Number__c => 1
        })
        .create()
        .getRecord();

        Suborder__c testLockedSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Suborder__c.Order__c => testLockedOrder.Id,
            Suborder__c.Phase__c => testPhase.Id,
            Suborder__c.Status__c => SuborderHelper.STATUS_LOCKED,
            Suborder__c.SuborderNumber__c => testPhase.Phase_Number__c
        })
        .create()
        .getRecord();

        Suborder__c testBilledSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
        .setFields(new Map<SObjectField, Object>{
            Suborder__c.Order__c => testOrder.Id,
            Suborder__c.Phase__c => testPhase.Id,
            Suborder__c.Status__c => SuborderHelper.STATUS_BILLED,
            Suborder__c.SuborderNumber__c => testPhase.Phase_Number__c
        })
        .create()
        .getRecord();

        Triggers.switchOn();

        Test.startTest();
        Opportunity_Downgrade.updateStatusesForOrderAndRelatedSuborders(testLockedOrder.Id);
        Opportunity_Downgrade.updateStatusesForOrderAndRelatedSuborders(testOrder.Id);
        Test.stopTest();

        Map<Id, Order> updatedOrders =
            new Map<Id, Order>((List<Order>) new OrderSelector()
                .selectOrdersByIdsForPhaseManagement(new Set<Id> {testLockedOrder.Id, testOrder.Id})
                .executeQuery());
        
        Map <Id, Suborder__c> updatedSuborders =
            new Map<Id, Suborder__c> ((List<Suborder__c>) new SuborderSelector()
                .selectSubordersByOrderId(testLockedOrder.Id)
                .executeQuery());


        Assert.areEqual(OrderHelper.STATUS_NEW, updatedOrders.get(testLockedOrder.Id).Status, 'Status of Order should be changed from Locked to New');
        Assert.areEqual(OrderHelper.STATUS_IN_PROGRESS, updatedOrders.get(testOrder.Id).Status, 'Status of Order should be changed from New to In Progress');
        Assert.areEqual(SuborderHelper.STATUS_NEW, updatedSuborders.get(testLockedSuborder.Id).Status__c, 'Status of Suborder should be changed from Locked to New');
    }
}