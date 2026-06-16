@isTest
private class Test_SuborderLineItemService {

    @isTest
    static void testUpsertSuborderLineItems() {

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

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuote.Id,
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase 1'),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        Phase__c selectedPhase = (Phase__c) new PhaseSelector()
            .selectPhaseById(new List<Object>{new Set<Id>{testPhase.Id}})
            .executeQuery()
            .get(0);

        BillingWrappers.Suborder suborder1 = new BillingWrappers.Suborder();
        suborder1.orderId = testOrder.Id;
        suborder1.status = SuborderHelper.STATUS_LOCKED;
        suborder1.uniqueId = 'Suborder-1-uniqueID';
        suborder1.currencyIsoCode = 'USD';
        suborder1.phaseNumber = 1;
        suborder1.billingMethod = 'Manual';
        suborder1.billingDate = '2020-01-23T08:00Z[UTC]';

        BillingWrappers.SuborderLineItemLocation location = new BillingWrappers.SuborderLineItemLocation();
        location.billingLocationId = 'billing-location-id';
        location.billingCodeId = 'billing-Code-Id';
        location.quantity = 1;


        BillingWrappers.SuborderLineItem suborderLineItem1 = new BillingWrappers.SuborderLineItem();
        suborderLineItem1.quantity = 3;
        suborderLineItem1.productElementId = selectedQli.Product_Lic_Id__c;
        suborderLineItem1.locations = new List<BillingWrappers.SuborderLineItemLocation>{location};

        Map<String, List<BillingWrappers.SuborderLineItem>> suborderLineItemsMap = new Map<String, List<BillingWrappers.SuborderLineItem>>{
            suborder1.uniqueId => new List<BillingWrappers.SuborderLineItem>{suborderLineItem1}
        };

        Triggers.switchOn();

        BillingWrappers.SuborderLineItemsParams params = new BillingWrappers.SuborderLineItemsParams();
        params.suborderLineItemsMap = suborderLineItemsMap;
        params.suborders = new List<BillingWrappers.Suborder>{suborder1};
        params.orderId = testOrder.Id;
        params.quoteId = testQuote.Id;
        params.accountLocations = new List<BillingWrappers.BillingAccountLocation>{};
        params.action = 'upsertSuborderLineItems';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            SuborderLineItemService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, List<BillingWrappers.SuborderLineItem>> resultSuborderLineItemsMap = (Map<String, List<BillingWrappers.SuborderLineItem>>) JSON.deserialize(body, Map<String, List<BillingWrappers.SuborderLineItem>>.class);
        Assert.areEqual(1, resultSuborderLineItemsMap.values().size(), 'SuborderLineItem should be upserted correctly');
    }

    @isTest
    static void testDeletingSuborderLineItems() {

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
                    QuoteLineItem.PackageInfo__c => '{"isPhoneLeasingEnabled":1}',
                    QuoteLineItem.EffectivePriceNew__c => 10
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

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Order.EffectiveDate => System.today(),
                Order.Status => 'New',
                Order.QuoteId => testQuote.Id,
                Order.OpportunityId => testOpp.Id
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SOBjectBuilder(Phase__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Phase__c.Name => ValueProviderBuilder.provideUniqueString('test phase 1'),
                Phase__c.Phase_Number__c => 1
            })
            .create()
            .getRecord();

        Phase__c selectedPhase = (Phase__c) new PhaseSelector()
            .selectPhaseById(new List<Object>{new Set<Id>{testPhase.Id}})
            .executeQuery()
            .get(0);


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
                SuborderLineItem__c.SalesAgreementLineItem__c => testQli1.Id,
                SuborderLineItem__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        BillingWrappers.Suborder suborder1 = new BillingWrappers.Suborder();
        suborder1.orderId = testOrder.Id;
        suborder1.status = SuborderHelper.STATUS_LOCKED;
        suborder1.uniqueId = 'Suborder-1-uniqueID';
        suborder1.currencyIsoCode = 'USD';
        suborder1.phaseNumber = 1;
        suborder1.billingMethod = 'Manual';
        suborder1.billingDate = '2020-01-23T08:00Z[UTC]';

        BillingWrappers.SuborderLineItemLocation location = new BillingWrappers.SuborderLineItemLocation();
        location.billingLocationId = 'billing-location-id';
        location.billingCodeId = 'billing-Code-Id';
        location.quantity = 1;


        BillingWrappers.SuborderLineItem suborderLineItem1 = new BillingWrappers.SuborderLineItem();
        suborderLineItem1.quantity = 3;
        suborderLineItem1.productElementId = selectedQli.Product_Lic_Id__c;
        suborderLineItem1.locations = new List<BillingWrappers.SuborderLineItemLocation>{location};

        Map<String, List<BillingWrappers.SuborderLineItem>> suborderLineItemsMap = new Map<String, List<BillingWrappers.SuborderLineItem>>{
            suborder1.uniqueId => new List<BillingWrappers.SuborderLineItem>{suborderLineItem1}
        };

        Triggers.switchOn();

        BillingWrappers.SuborderLineItemsParams params = new BillingWrappers.SuborderLineItemsParams();
        params.suborderLineItemsMap = suborderLineItemsMap;
        params.orderId = testOrder.Id;
        params.action = 'deleteSuborderLineItems';

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            SuborderLineItemService.handleRequest();
        Test.stopTest();

        List<SuborderLineItem__c> suborderLineItemsForDelete = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
            .selectSuborderLineItemsBySuborderIds(new Set<Id>{ testOrder.Id })
            .executeQuery();

        Assert.areEqual(0, suborderLineItemsForDelete.size(), 'Suborder line item should be deleted');
    }
}