@isTest
private class Test_PhaseLineItemService {

    @isTest
    static void testUpsertPhaseLineItems() {

        Triggers.SwitchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.IsActive => true,
                    Product2.Feature__c => 17,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            )
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => testPbe.Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.PackageInfo__c => '{"isPhoneLeasingEnabled":1}'
                }
            )
            .create()
            .getRecord();

        QuoteLineItem selectedQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(
                new Set<String>{
                    'PackageInfo__c',
                    'Product_Lic_Id__c'
                }
            )
            .executeQuery()
            .get(0);

        BillingWrappers.PhaseLineItem testPhaseLineItem1 = new BillingWrappers.PhaseLineItem();
        testPhaseLineItem1.quantity = 2;
        testPhaseLineItem1.productElementId = selectedQli.Product_Lic_Id__c;

        BillingWrappers.Phase phase1 = new BillingWrappers.Phase();
        phase1.opportunityId = testOpp.Id;
        phase1.status = 'New';
        phase1.uniqueId = 'Phase-1-uniqueID';
        phase1.quoteId = testQuote.Id;
        phase1.currencyIsoCode = 'USD';
        phase1.phaseNumber = 1;

        Map<String, List<BillingWrappers.PhaseLineItem>> phaseLineItemMap = new Map<String, List<BillingWrappers.PhaseLineItem>>{
            phase1.uniqueId => new List<BillingWrappers.PhaseLineItem>{testPhaseLineItem1}
        };

        List<BillingWrappers.Phase> phases = new List<BillingWrappers.Phase>{ phase1 };

        BillingWrappers.PhaseLineItemsParams params = new BillingWrappers.PhaseLineItemsParams();
        params.action = 'upsertPhaseLineItems';
        params.phases = phases;
        params.phaseLineItemsMap = phaseLineItemMap;
        params.selectedQuoteId = testQuote.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseLineItemService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();

        Map<String, List<BillingWrappers.PhaseLineItem>> resultPhaseLineItemsMap = ( Map<String, List<BillingWrappers.PhaseLineItem>>)JSON.deserialize(body, Map<String, List<BillingWrappers.PhaseLineItem>>.class);

        Assert.areEqual(1, resultPhaseLineItemsMap.values().size(), 'PhaseLineItem should be upserted correctly');
        Assert.areEqual(2, resultPhaseLineItemsMap.get(phase1.uniqueId)[0].quantity, 'PhaseLineItem should be upserted correctly');
        Assert.areEqual(selectedQli.Product_Lic_Id__c, resultPhaseLineItemsMap.get(phase1.uniqueId)[0].productElementId, 'PhaseLineItem should be upserted correctly');
    }

    @isTest
    static void testDeletePhaseLineItems() {

        Triggers.SwitchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                    }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testQuote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'Test_Product1',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.IsActive => true,
                    Product2.Feature__c => 17,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 1,
                    PricebookEntry.IsActive => true
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => testPbe.Id,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.UnitPrice => 1,
                    QuoteLineItem.PackageInfo__c => '{"isPhoneLeasingEnabled":1}'
                }
            )
            .create()
            .getRecord();

        BillingWrappers.Phase phase1 = new BillingWrappers.Phase();
        phase1.opportunityId = testOpp.Id;
        phase1.status = 'New';
        phase1.uniqueId = 'Phase-1-uniqueID';
        phase1.quoteId = testQuote.Id;
        phase1.currencyIsoCode = 'USD';
        phase1.phaseNumber = 1;

        Hardware_Line_Item__c testPhaseLineItem1 = (Hardware_Line_Item__c) new SOBjectBuilder(Hardware_Line_Item__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Hardware_Line_Item__c.Quantity__c => 1,
                Hardware_Line_Item__c.Quote_Line_Item__c => testQli.Id,
                Hardware_Line_Item__c.Total_Price__c => 30
            })
            .create()
            .getRecord();

        QuoteLineItem selectedQli = (QuoteLineItem) new QuoteLineItemSelector()
            .selectQuoteLineItems()
            .selectFields(
                new Set<String>{
                    'PackageInfo__c',
                    'Product_Lic_Id__c'
                }
            )
            .executeQuery()
            .get(0);

        Map<String, List<BillingWrappers.PhaseLineItem>> phaseLineItemMap = new Map<String, List<BillingWrappers.PhaseLineItem>>{};

        Triggers.switchOn();

        BillingWrappers.PhaseLineItemsParams params = new BillingWrappers.PhaseLineItemsParams();
        params.action = 'deletePhaseLineItems';
        params.phaseLineItemsMap = phaseLineItemMap;
        params.selectedQuoteId = testQuote.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseLineItemService.handleRequest();
        Test.stopTest();

        List<Hardware_Line_Item__c> phaseLineItemsForDelete = (List<Hardware_Line_Item__c>) new HardwareLineItemSelector()
            .selectPhaseLineItemsForDeleting(new List<Object>{
                new List<Id>{},
                new Set<Id>{ testQuote.Id }
            })
            .executeQuery();

        Assert.areEqual(0, phaseLineItemsForDelete.size(), 'PhaseLineItem should be deleted');
    }

    @isTest
    static void testCreatePhaseLineItemsForChangeOrder() {

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

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
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
                QuoteLineItem.QuoteId => testQuote.Id,
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
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuote.Id,
                Order.OpportunityId => opp.Id
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase'),
                Phase__c.Phase_Number__c => 1,
                Phase__c.Quote__c => testQuote.Id
            })
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1
            })
            .create()
            .getRecord();

        SuborderLineItem__c testSuborderLineItem = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c	 => testSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        BillingWrappers.PhaseLineItemsParams params = new BillingWrappers.PhaseLineItemsParams();
        params.action = 'createPhaseLineItemsForChangeOrder';
        params.orderId = testOrder.Id;
        params.selectedQuoteId = testQuote.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseLineItemService.handleRequest();

        Hardware_Line_Item__c pliResult = (Hardware_Line_Item__c)  new ListOptional(new HardwareLineItemSelector()
            .selectPhaseLineItems()
            .executeQuery())
            .getFirst();

        Test.stopTest();

        Assert.isNotNull(pliResult, 'One PhaseLineItem should be created and inserted');
        Assert.areEqual(testSuborderLineItem.Quantity__c, pliResult.Quantity__c, 'PhaseLineItem for Change Order should be created and inserted correctly');
        Assert.areEqual(testPhase.Id, pliResult.RingCentral_Hardware_Phase__c, 'PhaseLineItem for Change Order should be created and inserted correctly');
        Assert.areEqual(testSuborderLineItem.Quantity__c, pliResult.ExistingQuantity__c, 'PhaseLineItem for Change Order should be created and inserted correctly');
    }

    @isTest
    static void testGetPhaseIdToExistingQuantityMapWithSuborders() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
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

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => pb.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.ExtID__C => 'PROD_1'
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
                QuoteLineItem.QuoteId => testQuote.Id,
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

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.AccountId => testAcc.Id,
                    Order.Name => 'test',
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => testOpp.Id,
                    Order.EffectiveDate => System.today().addDays(100),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1
            })
            .create()
            .getRecord();

        SuborderLineItem__c testSuborderLineItem = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c	 => testSuborder.Id,
                SuborderLineItem__c.SalesAgreementLineItem__c => qli.Id,
                SuborderLineItem__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        List<BillingWrappers.Phase> phases = new List<BillingWrappers.Phase>();
        BillingWrappers.Phase phase = new BillingWrappers.Phase();
        phase.phaseId = null;
        phase.opportunityId = testOpp.Id;
        phase.quoteId = testQuote.Id;
        phase.suborderId = testSuborder.Id;
        phases.add(phase);

        Test.startTest();
        Map<String, Map<String, Decimal>> result = PhaseLineItemService.getPhaseIdToExistingQuantityMap(phases);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Should have one phase in the map');

        Map<String, Decimal> quantityMap = result.values()[0];
        Assert.isNotNull(quantityMap, 'Quantity map should not be null');
        Assert.areEqual(1, quantityMap.size(), 'Should have one product in the map');
    }

    @isTest
    static void testGetPhaseIdToExistingQuantityMapWithoutSuborders() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        List<BillingWrappers.Phase> phases = new List<BillingWrappers.Phase>();
        BillingWrappers.Phase phase = new BillingWrappers.Phase();
        phase.phaseId = null;
        phase.opportunityId = testOpp.Id;
        phase.quoteId = testQuote.Id;
        phase.suborderId = null;
        phases.add(phase);

        Test.startTest();
        Map<String, Map<String, Decimal>> result = PhaseLineItemService.getPhaseIdToExistingQuantityMap(phases);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Should have no phases in the map when no suborders');
    }

    @isTest
    static void testGetExistingQuantityForPhaseLineItem() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Phase phase = new BillingWrappers.Phase();
        phase.phaseId = 'phase1';
        phase.opportunityId = testOpp.Id;
        phase.quoteId = testQuote.Id;
        phase.suborderId = null;

        BillingWrappers.PhaseLineItem phaseLineItem = new BillingWrappers.PhaseLineItem();
        phaseLineItem.productElementId = 'PROD-1';

        Map<String, Map<String, Decimal>> phaseIdToExistingQuantityMap = new Map<String, Map<String, Decimal>>();
        phaseIdToExistingQuantityMap.put(phase.phaseId, new Map<String, Decimal>{phaseLineItem.productElementId => 10});

        Test.startTest();
        Decimal result = PhaseLineItemService.getExistingQuantityForPhaseLineItem(phaseLineItem, phase, phaseIdToExistingQuantityMap);
        Test.stopTest();

        Assert.areEqual(10, result, 'Should return should be 10');
    }
}