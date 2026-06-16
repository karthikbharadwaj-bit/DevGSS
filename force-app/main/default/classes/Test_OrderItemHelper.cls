@IsTest
private class Test_OrderItemHelper {
    @IsTest
    private static void testBuildOrderItems_singleProduct() {
        Order order = (Order) new SObjectBuilder(Order.SObjectType)
            .setField(Order.Id, ValueProviderBuilder.provideDummyId(Order.SObjectType))
            .quantity(1)
            .build()
            .getRecord();

        IValueProvider qliIdProvider = ValueProviderBuilder.provideDummyId(QuoteLineItem.sObjectType);

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Id, ValueProviderBuilder.provideList(
                new List<Id>{
                    (Id) qliIdProvider.getValue(),
                    (Id) qliIdProvider.getValue()
                }
            ))
            .setField(QuoteLineItem.Quantity, 10)
            .setField(QuoteLineItem.UnitPrice, 100)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .setField(QuoteLineItem.MasterQLI__c, (Id) qliIdProvider.getValue())
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();
        List<OrderItem> orderItems = OrderItemHelper.buildOrderItems(order, qliList);
        Test.stopTest();

        Map<Id, QuoteLineItem> quoteLineItemsByIds = new Map<Id, QuoteLineItem>(qliList);

        System.assertEquals(
            orderItems.size(),
            qliList.size(),
            'OrderItems should be created for all QuoteLineItems'
        );

        for (OrderItem orderItem : orderItems) {
            QuoteLineItem qli = quoteLineItemsByIds.get(orderItem.QuoteLineItemId);

            System.assertEquals(
                order.Id,
                orderItem.OrderId,
                'OrderItem.OrderId should be set to Order.Id'
            );
            System.assertEquals(
                qli.Quantity,
                orderItem.Quantity,
                'OrderItem.Quantity should be set to QuoteLineItem.Quantity'
            );
            System.assertEquals(
                qli.EffectivePrice__c,
                orderItem.UnitPrice,
                'OrderItem.UnitPrice should be set to QuoteLineItem.EffectivePrice__c'
            );
            System.assertEquals(
                qli.UnitPrice,
                orderItem.UnitPriceWithoutDiscount__c,
                'OrderItem.UnitPriceWithoutDiscount__c should be set to QuoteLineItem.UnitPrice'
            );
            System.assertEquals(
                qli.PricebookEntryId,
                orderItem.PricebookEntryId,
                'OrderItem.PricebookEntryId should be set to QuoteLineItem.PricebookEntryId'
            );
            System.assertEquals(
                qli.Id,
                orderItem.QuoteLineItemId,
                'OrderItem.QuoteLineItemId should be set to QuoteLineItem.Id'
            );
        }
    }

    @IsTest
    private static void testBuildOrderItems() {
        Order order = (Order) new SObjectBuilder(Order.SObjectType)
            .setField(Order.Id, ValueProviderBuilder.provideDummyId(Order.SObjectType))
            .quantity(1)
            .build()
            .getRecord();

        IValueProvider qliIdProvider = ValueProviderBuilder.provideDummyId(QuoteLineItem.sObjectType);

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Id, ValueProviderBuilder.provideList(
                new List<Id>{
                    (Id) qliIdProvider.getValue(),
                    (Id) qliIdProvider.getValue()
                }
            ))
            .setField(QuoteLineItem.Quantity, 10)
            .setField(QuoteLineItem.UnitPrice, 100)
            .setField(QuoteLineItem.Discount, 5)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, true)
            .setField(QuoteLineItem.MasterQLI__c, ValueProviderBuilder.provideList(
                new List<Id>{
                    (Id) qliIdProvider.getValue(),
                    (Id) qliIdProvider.getValue()
                }
            ))
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();
        OpportunityTriggerHelperRefactored.skipAsyncDFR = true;
        List<OrderItem> orderItems = OrderItemHelper.buildOrderItems(order, qliList);
        Test.stopTest();

        Map<Id, QuoteLineItem> quoteLineItemByMasterIds = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli : qliList) {
            quoteLineItemByMasterIds.put(qli.MasterQLI__c, qli);
        }

        System.assertEquals(
            qliList.size(),
            orderItems.size(),
            'OrderItems should be created for all QuoteLineItems'
        );

        for (OrderItem orderItem : orderItems) {
            QuoteLineItem qli = quoteLineItemByMasterIds.get(orderItem.QuoteLineItemId);

            System.assertEquals(
                order.Id,
                orderItem.OrderId,
                'OrderItem.OrderId should be set to Order.Id'
            );
            System.assertEquals(
                qli.Quantity,
                orderItem.Quantity,
                'OrderItem.Quantity should be set to QuoteLineItem.Quantity'
            );
            System.assertEquals(
                qli.EffectivePrice__c,
                orderItem.UnitPrice,
                'OrderItem.UnitPrice should be set to QuoteLineItem.EffectivePrice__c'
            );
            System.assertEquals(
                qli.UnitPrice,
                orderItem.UnitPriceWithoutDiscount__c,
                'OrderItem.UnitPriceWithoutDiscount__c should be set to QuoteLineItem.UnitPrice'
            );
            System.assertEquals(
                qli.PricebookEntryId,
                orderItem.PricebookEntryId,
                'OrderItem.PricebookEntryId should be set to QuoteLineItem.PricebookEntryId'
            );
            System.assertEquals(
                qli.MasterQLI__c,
                orderItem.QuoteLineItemId,
                'OrderItem.QuoteLineItemId should be set to QuoteLineItem.MasterQLI__c'
            );
        }
    }

    @IsTest
    private static void testBuildOrderItemsForOrdersByProvisioning_singleProduct() {
        List<Order> orders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setField(Order.Id, ValueProviderBuilder.provideDummyId(Order.SObjectType))
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .build()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Triggers.switchOff();
        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();
        Triggers.switchOn();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, 'Monthly')
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> reselectedQLIList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForOrderCreationProcess()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{
                qliList
            })
            .executeQuery();

        Test.startTest();
        List<OrderItem> orderItems = OrderItemHelper.buildOrderItemsForOrdersByProvisioning(orders, reselectedQLIList, false);
        Test.stopTest();

        System.assertEquals(
            qliList.size(),
            orderItems.size(),
            'OrderItems should be created for all QuoteLineItems'
        );

        Map<Id, List<OrderItem>> orderIdToOrderItems = new  Map<Id, List<OrderItem>>();
        for (OrderItem orderItem : orderItems) {
            if (!orderIdToOrderItems.containsKey(orderItem.OrderId)) {
                orderIdToOrderItems.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderIdToOrderItems.get(orderItem.OrderId).add(orderItem);
        }

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orders[0].Id).size(),
            'Should be 2 OrderItem for Order with "auto" provisioning'
        );

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orders[1].Id).size(),
            'Should be 2 OrderItem for Order with "manual" provisioning'
        );

        Map<Id, QuoteLineItem> quoteLineItemsByIds = new Map<Id, QuoteLineItem>(reselectedQLIList);
        for (OrderItem orderItem : orderItems) {
            QuoteLineItem qli = quoteLineItemsByIds.get(orderItem.QuoteLineItemId);

            System.assertEquals(
                qli.Quantity,
                orderItem.Quantity,
                'OrderItem.Quantity should be set to QuoteLineItem.Quantity'
            );
            System.assertEquals(
                qli.UnitPrice,
                orderItem.UnitPrice,
                'OrderItem.UnitPrice should be set to QuoteLineItem.UnitPrice'
            );
            System.assertEquals(
                qli.PricebookEntryId,
                orderItem.PricebookEntryId,
                'OrderItem.PricebookEntryId should be set to QuoteLineItem.PricebookEntryId'
            );
            System.assertEquals(
                qli.Id,
                orderItem.QuoteLineItemId,
                'OrderItem.QuoteLineItemId should be set to QuoteLineItem.Id'
            );
        }
    }

    @IsTest
    private static void testBuildOrderItemsForOrdersByProvisioning() {
        Triggers.switchOff();
        List<Order> orders = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setField(Order.Id, ValueProviderBuilder.provideDummyId(Order.SObjectType))
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .build()
            .getRecords();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.CloseDate, Date.today().addDays(30))
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, 'Monthly')
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.PRODUCT_PROVISIONING_TYPE_AUTO_WITH_CASE,
                    'manual',
                    'testUpsellType',
                    null
                }
            ))
            .quantity(4)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = new SobjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, ValueProviderBuilder.provideList(new List<Integer>{50, 55, 60, 65}))
            .setField(PricebookEntry.IsActive, true)
            .setField(PricebookEntry.UseStandardPrice, false)
            .setField(PricebookEntry.CurrencyIsoCode, 'USD')
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> masterQLIList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.PricebookEntryId, pbeList[0].Id)
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.UnitPrice, ValueProviderBuilder.provideList(new List<Integer>{50, 55, 60, 65}))
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, ValueProviderBuilder.provideList(new List<Integer>{5, 10, 15, 20}))
            .setField(QuoteLineItem.UnitPrice, ValueProviderBuilder.provideList(new List<Integer>{50, 55, 60, 65}))
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, true)
            .setField(QuoteLineItem.MasterQLI__c, ValueProviderBuilder.provideParents(masterQLIList))
            .quantity(4)
            .create()
            .getRecords();

        List<QuoteLineItem> reselectedQLIList = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsForOrderCreationProcess()
            .setCondition('Id IN :bind0')
            .setQueryBindings(new List<Object>{
                qliList
            })
            .executeQuery();
        Triggers.switchOn();

        Test.startTest();
        List<OrderItem> orderItems = OrderItemHelper.buildOrderItemsForOrdersByProvisioning(orders, reselectedQLIList, false);
        Test.stopTest();

        System.assertEquals(
            qliList.size(),
            orderItems.size(),
            'OrderItems should be created for all QuoteLineItems'
        );

        Map<Id, List<OrderItem>> orderIdToOrderItems = new  Map<Id, List<OrderItem>>();
        for (OrderItem orderItem : orderItems) {
            if (!orderIdToOrderItems.containsKey(orderItem.OrderId)) {
                orderIdToOrderItems.put(orderItem.OrderId, new List<OrderItem>());
            }
            orderIdToOrderItems.get(orderItem.OrderId).add(orderItem);
        }

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orders[0].Id).size(),
            'Should be 2 OrderItem for Order with "auto" provisioning'
        );

        System.assertEquals(
            2,
            orderIdToOrderItems.get(orders[1].Id).size(),
            'Should be 2 OrderItem for Order with "manual" provisioning'
        );

        Map<Id, QuoteLineItem> quoteLineItemByMasterIds = new Map<Id, QuoteLineItem>();
        for (QuoteLineItem qli : reselectedQLIList) {
            quoteLineItemByMasterIds.put(qli.MasterQLI__c, qli);
        }

        for (OrderItem orderItem : orderItems) {
            QuoteLineItem qli = quoteLineItemByMasterIds.get(orderItem.QuoteLineItemId);

            System.assertEquals(
                qli.Quantity,
                orderItem.Quantity,
                'OrderItem.Quantity should be set to QuoteLineItem.Quantity'
            );
            System.assertEquals(
                qli.UnitPrice,
                orderItem.UnitPrice,
                'OrderItem.UnitPrice should be set to QuoteLineItem.UnitPrice'
            );
            System.assertEquals(
                qli.PricebookEntryId,
                orderItem.PricebookEntryId,
                'OrderItem.PricebookEntryId should be set to QuoteLineItem.PricebookEntryId'
            );
            System.assertEquals(
                qli.MasterQLI__c,
                orderItem.QuoteLineItemId,
                'OrderItem.QuoteLineItemId should be set to QuoteLineItem.Id'
            );
        }
    }
}