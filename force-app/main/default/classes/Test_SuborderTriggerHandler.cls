@IsTest
private class Test_SuborderTriggerHandler {

    @IsTest
    static void testPopulateOrderSubTotalsOnUpdate() {
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
                QuoteLineItem.EffectivePriceNew__c => 50,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_ONE_TIME
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

        Suborder__c ucSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();

        SuborderLineItem__c ucLineItem = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ucSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 2
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        ucLineItem.Quantity__c = 4;
        update ucLineItem;
        Test.stopTest();

        Order updatedOrder = (Order) new ListOptional(new OrderSelector()
            .selectOrdersForSuborderManagement(new List<Object>{new List<Id>{testOrder.Id}})
            .executeQuery()
        ).getFirst();
        Assert.areEqual(200, updatedOrder.UCSubtotal__c, 'UC Subtotal should be updated to 200 (4 * 50)');
        Assert.areEqual(0, updatedOrder.CCSubtotal__c, 'CC Subtotal should be 0');
    }

    @IsTest
    static void testPopulateOrderSubTotalsOnDelete() {
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
                QuoteLineItem.EffectivePriceNew__c => 50,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_ONE_TIME
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

        Suborder__c ucSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();

        SuborderLineItem__c ucLineItem = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ucSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 2
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        delete ucLineItem;
        Test.stopTest();

        Order updatedOrder = (Order) new ListOptional(new OrderSelector()
            .selectOrdersForSuborderManagement(new List<Object>{new List<Id>{testOrder.Id}})
            .executeQuery()
        ).getFirst();
        Assert.areEqual(0, updatedOrder.UCSubtotal__c, 'UC Subtotal should be 0 after deletion');
        Assert.areEqual(0, updatedOrder.CCSubtotal__c, 'CC Subtotal should be 0');
    }

    @IsTest
    static void testCalculateSubTotalsForOrders() {
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
                QuoteLineItem.EffectivePriceNew__c => 50,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_ONE_TIME
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

        Suborder__c ucSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();

        Suborder__c ccSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'CC'
            })
            .create()
            .getRecord();

        SuborderLineItem__c ucLineItem1 = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ucSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 2
            })
            .create()
            .getRecord();

        SuborderLineItem__c ucLineItem2 = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ucSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 3
            })
            .create()
            .getRecord();

        SuborderLineItem__c ccLineItem1 = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ccSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 4
            })
            .create()
            .getRecord();

        SuborderLineItem__c ccLineItem2 = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c => ccSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 5
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Suborder__c> subordersWithSLI = (List<Suborder__c>) new SuborderSelector()
            .selectSubordersAndSuborderLineItemsByIds(new Set<Id>{ucSuborder.Id, ccSuborder.Id})
            .executeQuery();

        Test.startTest();
        Map<Id, SuborderHelper.SubTotals> result = SuborderHelper.calculateSubTotalsForOrders(subordersWithSLI, true);
        Test.stopTest();

        Assert.isTrue(result.containsKey(testOrder.Id), 'Result should contain the test order ID');

        SuborderHelper.SubTotals subtotals = result.get(testOrder.Id);

        Assert.areEqual(250, subtotals.ucSubTotals, 'UC subtotal should be 250 (2 * 50 + 3 * 50)');
        Assert.areEqual(450, subtotals.ccSubTotals, 'CC subtotal should be 450 (4 * 50 + 5 * 50)');
    }

    @IsTest
    static void testUpdatePSIntegrationRecordsOnSuborderUpsert() {

        Triggers.switchOff();

        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        ProServ_Project__c testProject = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.sObjectType)
        .setFields(new Map<SObjectField, Object> {
            ProServ_Project__c.Account__c => testAccount.Id,
            ProServ_Project__c.Quote__c => testQuote.Id,
            ProServ_Project__c.Opportunity__c => testOpp.Id
        })
        .create()
        .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.Status => 'New',
                Order.EffectiveDate => System.today(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.ProServProject__c => testProject.Id,
                Order.CurrencyIsoCode => 'USD',
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();
        
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Name => 'test Package 1',
                Package__c.Account_Package_Id__c => '1111',
                Package__c.Offer_Type__c => '',
                Package__c.Account__c => testAccount.Id,
                Package__c.Enterprise_Account_ID__c => testAccount.Id,
                Package__c.Package_Catalog_Id__c => '1111',
                Package__c.Service_Type__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Package__c.Opportunity__c => testOpp.Id
            })
            .create()
            .getRecord();
            
        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Order__c => testOrder.Id,
                Phase__c.Phase_Number__c => 1,
                Phase__c.Phase_Type__c => 'UC',
                Phase__c.Status__c => 'Active'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Suborder__c testSuborder = (Suborder__c) new SObjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();
        Test.stopTest();

        List<PS_Integration__c> insertPSIntegrationRecord = new PSIntegrationSelector()
            .selectPSIntegrationsBySubOrderIds(new List<Object> { new List<Id> { testSuborder.Id } })
            .executeQuery();
    
        Assert.areEqual(1, insertPSIntegrationRecord.size(), 'There should be 1 PS Integration record');
        Assert.areEqual(testSuborder.Id, insertPSIntegrationRecord[0].MostRecentSuborder__c, 'Most Recent Suborder should be the test suborder');

        testSuborder.Status__c = SuborderHelper.STATUS_BILLED;
        update testSuborder;

        List<PS_Integration__c> updatePSIntegrationRecord = new PSIntegrationSelector()
            .selectPSIntegrationsBySubOrderIds(new List<Object> { new List<Id> { testSuborder.Id } })
            .executeQuery();
        Assert.areEqual(PSIntegrationHelper.STATUS_BILLED, updatePSIntegrationRecord[0].Status__c, 'Status should be Billed');
    }

    @IsTest
    static void testUpdatePSIntegrationRecordsOnSuborderDelete() {

        Triggers.switchOff();
        Account testAccount = TestDataGenerator.createAccount('Test Account');

        ProServ_Project__c testProject = (ProServ_Project__c) new SObjectBuilder(ProServ_Project__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                ProServ_Project__c.Account__c => testAccount.Id
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => 'Test Order',
                Order.AccountId => testAccount.Id,
                Order.Status => 'New',
                Order.EffectiveDate => System.today(),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.ProServProject__c => testProject.Id,
                Order.CurrencyIsoCode => 'USD'
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Order__c => testOrder.Id,
                Phase__c.Phase_Number__c => 1,
                Phase__c.Phase_Type__c => 'UC',
                Phase__c.Status__c => 'Active'
            })
            .create()
            .getRecord();
        
        Suborder__c testSuborder = (Suborder__c) new SObjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1,
                Suborder__c.Suborder_Type__c => 'UC'
            })
            .create()
            .getRecord();
        
        PS_Integration__c testPSIntegration = (PS_Integration__c) new SObjectBuilder(PS_Integration__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                PS_Integration__c.Status__c => PSIntegrationHelper.STATUS_NEW,
                PS_Integration__c.Order__c => testOrder.Id,
                PS_Integration__c.Phase__c => testPhase.Id,
                PS_Integration__c.ProServProject__c => testProject.Id,
                PS_Integration__c.MostRecentSuborder__c => testSuborder.Id,
                PS_Integration__c.PSIntegrationNumber__c => '12345 - 1'
            })
            .create()
            .getRecord();

        Triggers.SwitchOn();
            
        Test.startTest();
        delete testSuborder;
        Test.stopTest();

        List<PS_Integration__c> recordPSIntegrations = new PSIntegrationSelector()
            .selectPSIntegrationsByOrderIds(new Set<Id> { testOrder.Id })
            .executeQuery();
        Assert.areEqual(PSIntegrationHelper.STATUS_CANCELED, recordPSIntegrations[0].Status__c, 'Status should be Canceled');
    }

    @IsTest
    static void testPopulateMaxSubOrderNumberOnOrderOnInsert() {
        Triggers.switchOff();
        
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => testAccount.Id,
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuote.Id,
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        
        Suborder__c suborder1 = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'UC',
                Suborder__c.SuborderNumber__c => 5
            })
            .create()
            .getRecord();

        Suborder__c suborder2 = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'CC',
                Suborder__c.SuborderNumber__c => 3
            })
            .create()
            .getRecord();

        Test.stopTest();

        Order updatedOrder = [SELECT Id, MaxPhaseNumber__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual(5, updatedOrder.MaxPhaseNumber__c, 'MaxPhaseNumber__c should be 5');
    }

    @IsTest
    static void testPopulateMaxSubOrderNumberOnOrderOnUpdate() {
        Triggers.switchOff();
        
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => testAccount.Id,
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuote.Id,
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Suborder__c suborder1 = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'UC',
                Suborder__c.SuborderNumber__c => 5
            })
            .create()
            .getRecord();

        Suborder__c suborder2 = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'CC',
                Suborder__c.SuborderNumber__c => 3
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

        suborder2.SuborderNumber__c = 8;
        update suborder2;

        Test.stopTest();

        Order updatedOrder = [SELECT Id, MaxPhaseNumber__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual(8, updatedOrder.MaxPhaseNumber__c, 'MaxPhaseNumber__c should be 8');
    }

    @IsTest
    static void testPopulateMaxSubOrderNumberOnOrderOnDelete() {
        Triggers.switchOff();
        
        Account testAccount = TestDataGenerator.createAccount('Test Account');
        Opportunity testOpp = TestDataGenerator.createOpportunity(testAccount);
        Quote testQuote = TestDataGenerator.createQuote(testOpp);

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => testAccount.Id,
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuote.Id,
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Suborder__c suborder1 = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'UC',
                Suborder__c.SuborderNumber__c => 5
            })
            .create()
            .getRecord();

        Suborder__c suborder2 = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.Suborder_Type__c => 'CC',
                Suborder__c.SuborderNumber__c => 8
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
        delete suborder2;
        Test.stopTest();

        Order updatedOrder = [SELECT Id, MaxPhaseNumber__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual(8, updatedOrder.MaxPhaseNumber__c, 'MaxPhaseNumber__c should be 8');
    }
}