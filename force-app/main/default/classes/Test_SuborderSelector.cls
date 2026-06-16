@isTest
public with sharing class Test_SuborderSelector {

    @IsTest
    private static void testSelectSuborders() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
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

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSuborders()
                .executeQuery();
        Test.stopTest();

        System.assertEquals(1, suborders.size(), 'Should selected 1 suborder');
    }

    @IsTest
    private static void testSelectSubordersByOrdersIds() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
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

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByOrdersIds(new Set<Id>{testOrder.Id})
                .executeQuery();
        Test.stopTest();

        System.assertEquals(1, suborders.size(), 'Should selected 1 suborder');
    }

    @IsTest
    private static void testSelectSubordersByOrderId() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
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

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByOrderId(testOrder.Id)
                .executeQuery();
        Test.stopTest();

        System.assertEquals(1, suborders.size(), 'Should selected 1 suborder');
    }

    @IsTest
    private static void testSelectSubordersByOrderIdAndStatus() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW
            })
            .create();

        new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_LOCKED
            })
            .create();

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByOrderIdAndStatus(testOrder.Id, SuborderHelper.STATUS_NEW)
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(1, suborders.size(), 'Should selected 1 suborder');
    }

    @IsTest
    private static void testSelectSubordersByIdAndStatus() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        Suborder__c testSuborderNew = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW
            })
            .create()
            .getRecord();

        Suborder__c testSuborderLocked = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_LOCKED
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByIdAndStatus(new Set<Id>{testSuborderNew.Id, testSuborderLocked.Id}, SuborderHelper.STATUS_NEW)
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(1, suborders.size(), 'Should selected 1 suborder');
    }

    @IsTest
    private static void testSelectSubordersByIds() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        List<Suborder__c> testSuborders = (List<Suborder__c>) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => ValueProviderBuilder.provideList(new List<String>{ 'UC', 'CC' }),
                Suborder__c.SuborderNumber__c => ValueProviderBuilder.provideList(new List<Integer>{ 1, 2 })
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSubordersByIds(new Set<Id>{ testSuborders.get(0).Id, testSuborders.get(1).Id })
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(2, suborders.size(), 'Should return both Suborders');

        for (Suborder__c suborder : suborders) {
            Assert.isNotNull(suborder.Id, 'Id should be populated');
            Assert.isNotNull(suborder.SuborderNumber__c, 'SuborderNumber__c should be populated');
            Assert.isNotNull(suborder.CurrencyIsoCode, 'CurrencyIsoCode should be populated');
            Assert.isNotNull(suborder.Name, 'Name should be populated');
            Assert.isNotNull(suborder.Status__c, 'Status__c should be populated');
            Assert.isNotNull(suborder.Order__c, 'Order__c should be populated');
            Assert.isNotNull(suborder.Order__r.OpportunityId, 'Order__r.OpportunityId should be populated');
            Assert.isNotNull(suborder.Order__r.QuoteId, 'Order__r.QuoteId should be populated');
            Assert.isNotNull(suborder.Suborder_Type__c, 'Suborder_Type__c should be populated');
        }
    }

  @IsTest
    private static void testSelectSuborderBySuborderId() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW
            })
            .create()
            .getRecord();

        Suborder__c suborder1 = (Suborder__c) new ListOptional(new SuborderSelector()
            .selectSuborders()
            .executeQuery()
        ).getFirst();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
            suborders = (List<Suborder__c>) new SuborderSelector()
                .selectSuborderBySuborderId(suborder1.SuborderId__c)
                .executeQuery();
        Test.stopTest();

        Assert.areEqual(1, suborders.size(), 'Should selected 1 suborder');
    }

    @IsTest
    private static void testSelectSubordersAndSuborderLineItemsByIds() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ValueProviderBuilder.provideUniqueString())
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
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString(),
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
                QuoteLineItem.EffectivePriceNew__c => 10
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString(),
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
                Phase__c.Name => ValueProviderBuilder.provideUniqueString(),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        List<Suborder__c> testSuborders = (List<Suborder__c>) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => ValueProviderBuilder.provideList(new List<String>{ 'UC', 'CC' }),
                Suborder__c.SuborderNumber__c => ValueProviderBuilder.provideList(new List<Integer>{ 1, 2 })
            })
            .quantity(2)
            .create()
            .getRecords();

        List<SuborderLineItem__c> testSuborderLineItems = (List<SuborderLineItem__c>) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ValueProviderBuilder.provideList(new List<Id>{ testSuborders[0].Id, testSuborders[1].Id }),
                SuborderLineItem__c.Quantity__c => ValueProviderBuilder.provideList(new List<Decimal>{ 1, 2 }),
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id
            })
            .quantity(2)
            .create()
            .getRecords();

        Triggers.switchOn();

        List<Suborder__c> suborders = new List<Suborder__c>();
        Test.startTest();
        suborders = (List<Suborder__c>) new SuborderSelector()
            .selectSubordersAndSuborderLineItemsByIds(new Set<Id>{ testSuborders[0].Id, testSuborders[1].Id })
            .executeQuery();
        Test.stopTest();

        Assert.areEqual(2, suborders.size(), 'Should return both Suborders');

        for (Suborder__c suborder : suborders) {
            Assert.isNotNull(suborder.Id, 'Id should be populated');
            Assert.isNotNull(suborder.SuborderNumber__c, 'SuborderNumber__c should be populated');
            Assert.isNotNull(suborder.CurrencyIsoCode, 'CurrencyIsoCode should be populated');
            Assert.isNotNull(suborder.Name, 'Name should be populated');
            Assert.isNotNull(suborder.Status__c, 'Status__c should be populated');
            Assert.isNotNull(suborder.Order__c, 'Order__c should be populated');
            Assert.isNotNull(suborder.Order__r.OpportunityId, 'Order__r.OpportunityId should be populated');
            Assert.isNotNull(suborder.Order__r.QuoteId, 'Order__r.QuoteId should be populated');
            Assert.isNotNull(suborder.Suborder_Type__c, 'Suborder_Type__c should be populated');
            Assert.isNotNull(suborder.SuborderLineItems__r, 'SuborderLineItems__r should be populated');
            Assert.areEqual(1, suborder.SuborderLineItems__r.size(), 'Should have one SuborderLineItem per Suborder');
        }
    }
}