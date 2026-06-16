@isTest
public with sharing class Test_SuborderLineItemHelper {

    @IsTest
    private static void testCreateSuborderLineItems() {
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

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.EffectivePriceNew__c => 30
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
                Order.Status => 'New',
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

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW
            })
            .create()
            .getRecord();

        Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SOBjectBuilder(Hardware_Line_Item__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                Hardware_Line_Item__c.Quantity__c => 1,
                Hardware_Line_Item__c.Quote_Line_Item__c => qli.Id
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Map<Id, Phase__c> phasesMap =  new Map<Id, Phase__c>((List<Phase__c>)new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id> { opp.PrimaryQuote__c }})
            .executeQuery());

        Test.startTest();
            SuborderLineItemHelper.createSuborderLineItems(new List<Suborder__c> {testSuborder}, phasesMap);
        Test.stopTest();

        SuborderLineItem__c reselectedSuborderLineItem = (SuborderLineItem__c) new ListOptional(
            new SuborderLineItemSelector()
                .selectSuborderLineItems()
                .executeQuery()
            )
            .getFirst();

        System.assertEquals(true, reselectedSuborderLineItem != null, 'reselectedSuborderLineItem should not be null');
        System.assertEquals(testHLI.Quantity__c, reselectedSuborderLineItem.Quantity__c, 'Suborder Line Item Quantity should be equal to Hardware Line Item Quantity');
        System.assertEquals(qli.Id, reselectedSuborderLineItem.SalesAgreementLineItem__c, 'Suborder Line Item should have Sales Agreement Line Item equal to Quote Line Item Id');
        System.assertEquals(testSuborder.Id, reselectedSuborderLineItem.Suborder__c, 'Suborder Line Item should have Suborder equal to Suborder Id');
    }

    @IsTest
    private static void testCreateSuborderLineItemsWithoutSuborders() {
        List<Suborder__c> suborders = new List<Suborder__c>();
        Map<Id, Phase__c> phasesMap = new Map<Id, Phase__c>();

        Test.startTest();
            SuborderLineItemHelper.createSuborderLineItems(suborders, phasesMap);
        Test.stopTest();

        List<SuborderLineItem__c> reselectedSuborderLineItems = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
            .selectSuborderLineItems()
            .executeQuery();

        System.assertEquals(true, reselectedSuborderLineItems.isEmpty(), 'Should not be created suborder lite items');
    }
}