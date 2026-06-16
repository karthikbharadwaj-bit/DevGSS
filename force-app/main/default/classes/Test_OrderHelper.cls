@isTest
private class Test_OrderHelper {
    @IsTest
    private static void testBuildOrderForQuote_singleProduct() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .quantity(1)
            .create()
            .getRecord();
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .quantity(1)
            .create()
            .getRecord();

        qt.putSObject('Opportunity', opp);

        Test.startTest();
        Order ord = OrderHelper.buildOrderForQuote(qt);
        Test.stopTest();

        System.assertEquals(
            ord.Status,
            OrderHelper.STATUS_NEW,
            'Order status should be set to "New"'
        );
        System.assertEquals(
            ord.RecordTypeId,
            OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.Opportunity.Tier_Name__c),
            'Order record type should be set to the same as the opportunity'
        );
        System.assertEquals(
            ord.CurrencyIsoCode,
            qt.CurrencyIsoCode,
            'Order currency should be set to the same as the quote'
        );
        System.assertEquals(
            ord.AccountId,
            qt.AccountId,
            'Order account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.OpportunityId,
            qt.OpportunityId,
            'Order opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.QuoteId,
            qt.Id,
            'Order quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalAccountId__c,
            qt.AccountId,
            'Order technical account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalOpportunityId__c,
            qt.OpportunityId,
            'Order technical opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalQuoteId__c,
            qt.Id,
            'Order technical quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.Provisioning__c,
            null,
            'Order Provisioning should be null'
        );
    }

    @IsTest
    private static void testBuildOrderForQuote_singleProduct_withProvisioning() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Test Account')
            .quantity(1)
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .quantity(1)
            .create()
            .getRecord();
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .quantity(1)
            .create()
            .getRecord();

        qt.putSObject('Opportunity', opp);
        String provisioning = 'test';

        Test.startTest();
        Order ord = OrderHelper.buildOrderForQuote(qt, provisioning);
        Test.stopTest();

        System.assertEquals(
            ord.Status,
            OrderHelper.STATUS_NEW,
            'Order status should be set to "New"'
        );
        System.assertEquals(
            ord.RecordTypeId,
            OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.Opportunity.Tier_Name__c),
            'Order record type should be set to the same as the opportunity'
        );
        System.assertEquals(
            ord.CurrencyIsoCode,
            qt.CurrencyIsoCode,
            'Order currency should be set to the same as the quote'
        );
        System.assertEquals(
            ord.AccountId,
            qt.AccountId,
            'Order account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.OpportunityId,
            qt.OpportunityId,
            'Order opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.QuoteId,
            qt.Id,
            'Order quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalAccountId__c,
            qt.AccountId,
            'Order technical account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalOpportunityId__c,
            qt.OpportunityId,
            'Order technical opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalQuoteId__c,
            qt.Id,
            'Order technical quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.Provisioning__c,
            provisioning,
            'Order Provisioning should be set to "' + provisioning + '"'
        );
    }

    @IsTest
    private static void testBuildOrderForQuote() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

        Test.startTest();
        Quote qt = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Order ord = OrderHelper.buildOrderForQuote(qt);
        Test.stopTest();

        System.assertEquals(
            ord.Status,
            OrderHelper.STATUS_NEW,
            'Order status should be set to "New"'
        );
        System.assertEquals(
            ord.RecordTypeId,
            OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.ServiceName__c),
            'Order record type should be set to the same as the opportunity'
        );
        System.assertEquals(
            ord.CurrencyIsoCode,
            qt.CurrencyIsoCode,
            'Order currency should be set to the same as the quote'
        );
        System.assertEquals(
            ord.AccountId,
            qt.MasterQuote__r.AccountId,
            'Order account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.OpportunityId,
            qt.MasterQuote__r.OpportunityId,
            'Order opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.QuoteId,
            qt.MasterQuote__c,
            'Order quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalAccountId__c,
            qt.AccountId,
            'Order technical account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalOpportunityId__c,
            qt.OpportunityId,
            'Order technical opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalQuoteId__c,
            qt.Id,
            'Order technical quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.Provisioning__c,
            null,
            'Order Provisioning should be null'
        );
    }

    @IsTest
    private static void testBuildOrderForQuote_withProvisioning() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();
        String provisioning = 'test';

        Test.startTest();
        Quote qt = mpStruct.serviceQuotes.get(QuoteHelper.NGBS_RCCC_PRODUCT);
        Order ord = OrderHelper.buildOrderForQuote(qt, provisioning);
        Test.stopTest();

        System.assertEquals(
            ord.Status,
            OrderHelper.STATUS_NEW,
            'Order status should be set to "New"'
        );
        System.assertEquals(
            ord.RecordTypeId,
            OrderHelper.SERVICE_NAME_TO_RT_ID.get(qt.ServiceName__c),
            'Order record type should be set to the same as the opportunity'
        );
        System.assertEquals(
            ord.CurrencyIsoCode,
            qt.CurrencyIsoCode,
            'Order currency should be set to the same as the quote'
        );
        System.assertEquals(
            ord.AccountId,
            qt.MasterQuote__r.AccountId,
            'Order account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.OpportunityId,
            qt.MasterQuote__r.OpportunityId,
            'Order opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.QuoteId,
            qt.MasterQuote__c,
            'Order quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalAccountId__c,
            qt.AccountId,
            'Order technical account should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalOpportunityId__c,
            qt.OpportunityId,
            'Order technical opportunity should be set to the same as the quote'
        );
        System.assertEquals(
            ord.TechnicalQuoteId__c,
            qt.Id,
            'Order technical quote should be set to the same as the quote'
        );
        System.assertEquals(
            ord.Provisioning__c,
            provisioning,
            'Order Provisioning should be set to "' + provisioning + '"'
        );
    }

    @IsTest
    private static void testActivateOrderForOpportunity() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();


        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        for(List<QuoteLineItem> qliList : mpStruct.technicalQLIs.values()) {
            for (QuoteLineItem qli : qliList) {
                qli.ChargeTerm__c = QuoteLineItemHelper.CHARGE_TERM_MONTHLY;
                qliToUpdate.add(qli);
            }
        }

        Triggers.switchOff();
        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = true;
        update qliToUpdate;
        TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = false;
        Triggers.switchOn();

        List<Order> orders = new List<Order>();
        for(Quote quote : mpStruct.serviceQuotes.values()) {
            if (mpStruct.technicalQLIs.get(quote.ServiceName__c).isEmpty()) {
                continue;
            }
            if(OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(quote.ServiceName__c)) {
                orders.add(OrderHelper.buildOrderForQuote(quote));
            }
        }

        insert orders;

        Test.startTest();
        Response res = OrderHelper.activateOrderForOpportunity(mpStruct.masterQuote.Id);
        Test.stopTest();

        System.assertEquals(
            res.getData('message'),
            'Order successfully activated',
            'Order activation should be successful'
        );
        System.assertNotEquals(
            res.getData('url'),
            null,
            'Order activation should return a url'
        );
    }

    @IsTest
    private static void testActivateAlreadyActivatedOrderForOpportunity() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

        List<Order> orders = new List<Order>();
        for(Quote quote : mpStruct.serviceQuotes.values()) {
            if (mpStruct.technicalQLIs.get(quote.ServiceName__c).isEmpty()) {
                continue;
            }
            if(OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(quote.ServiceName__c)) {
                orders.add(OrderHelper.buildOrderForQuote(quote));
            }
        }
        insert orders;

        for (Order ord : orders) {
            ord.Status = OrderHelper.STATUS_ACTIVATED;
        }
        Triggers.switchOff();
        update orders;
        Triggers.switchOn();

        Test.startTest();
        Response res = OrderHelper.activateOrderForOpportunity(mpStruct.masterQuote.Id);
        Test.stopTest();

        System.assertEquals(
            res.getData('message'),
            OrderHelper.ORDER_IS_ACTIVATED,
            'Order should be already activated'
        );
    }

    @IsTest
    private static void testActivateOrdersForQuote() {
        Triggers.switchOff();
        TestDataGenerator.MultiproductStructure mpStruct = new TestDataGenerator.MultiproductStructure();
        Triggers.switchOn();

        List<Order> orders = new List<Order>();
        for(Quote quote : mpStruct.serviceQuotes.values()) {
            if (mpStruct.technicalQLIs.get(quote.ServiceName__c).isEmpty()) {
                continue;
            }
            if(OrderHelper.SERVICE_NAME_TO_RT_ID.containsKey(quote.ServiceName__c)) {
                orders.add(OrderHelper.buildOrderForQuote(quote));
            }
        }

        insert orders;

        Test.startTest();
        Response res = OrderHelper.activateOrdersList(orders);
        Test.stopTest();

        System.assertEquals(
            res.getData('message'),
            'Orders successfully activated',
            'Orders activation should be successful'
        );
        System.assertNotEquals(
            res.getData('url'),
            null,
            'Orders activation should return a url'
        );
    }

    @IsTest
    private static void testBuildOrdersForQuoteByProvisioning_singleProduct() {
        Triggers.switchOff();   
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
            .setField(Opportunity.CloseDate, System.today())
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
                    null,
                    'testUpsellType'
                }
            ))
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, qt.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .quantity(3)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
        Quote reselectedQuote = (Quote) new QuoteSelector()
            .newQueryFactory()
            .selectFields(new List<String>(QuoteSelector.FIELDS_ORDER_CREATION_PROCESS))
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectQuoteLineItemsForOrderCreationProcess()
            )
            .setCondition('(Id = :bind0)')
            .setQueryBindings(new List<Object>{
                qt.Id
            })
            .executeQuery()
            .get(0);

        List<Order> orders = OrderHelper.buildOrdersForQuoteByProvisioning(reselectedQuote, false);
        Test.stopTest();

        System.assertEquals(
            orders.size(),
            2,
            'Should be created 2 orders'
        );

        System.assertEquals(
            orders[0].Provisioning__c,
            OrderHelper.PROVISIONING_MANUAL,
            'Should be created 2 orders'
        );

        System.assertEquals(
            orders[1].Provisioning__c,
            OrderHelper.PROVISIONING_AUTO,
            'Should be created 2 orders'
        );

        for (Order ord : orders) {
            System.assertEquals(
                ord.Status,
                OrderHelper.STATUS_NEW,
                'Order status should be set to "New"'
            );
            System.assertEquals(
                ord.RecordTypeId,
                OrderHelper.SERVICE_NAME_TO_RT_ID.get(reselectedQuote.Opportunity.Tier_Name__c),
                'Order record type should be set to the same as the opportunity'
            );
            System.assertEquals(
                ord.CurrencyIsoCode,
                reselectedQuote.CurrencyIsoCode,
                'Order currency should be set to the same as the quote'
            );
            System.assertEquals(
                ord.AccountId,
                reselectedQuote.AccountId,
                'Order account should be set to the same as the quote'
            );
            System.assertEquals(
                ord.OpportunityId,
                reselectedQuote.OpportunityId,
                'Order opportunity should be set to the same as the quote'
            );
            System.assertEquals(
                ord.QuoteId,
                reselectedQuote.Id,
                'Order quote should be set to the same as the quote'
            );
            System.assertEquals(
                ord.Pricebook2Id,
                reselectedQuote.Pricebook2Id,
                'Order Pricebook2Id should be set to the same as the quote'
            );
            System.assertEquals(
                ord.TechnicalAccountId__c,
                reselectedQuote.AccountId,
                'Order technical account should be set to the same as the quote'
            );
            System.assertEquals(
                ord.TechnicalOpportunityId__c,
                reselectedQuote.OpportunityId,
                'Order technical opportunity should be set to the same as the quote'
            );
            System.assertEquals(
                ord.TechnicalQuoteId__c,
                reselectedQuote.Id,
                'Order technical quote should be set to the same as the quote'
            );
        }
    }

    @IsTest
    private static void testBuildOrdersForQuoteByProvisioning() {
        Triggers.switchOff(); 
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
            .setField(Opportunity.CloseDate, System.today())
            .quantity(1)
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .quantity(1)
            .create()
            .getRecord();

        Quote techQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .setField(Quote.ServiceName__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
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
                    null,
                    'testUpsellType'
                }
            ))
            .quantity(3)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .quantity(3)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, techQuote.Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .quantity(3)
            .create()
            .getRecords();

        Triggers.switchOn();

        Test.startTest();
        Quote reselectedQuote = (Quote) new QuoteSelector()
            .newQueryFactory()
            .selectFields(new List<String>(QuoteSelector.FIELDS_ORDER_CREATION_PROCESS))
            .subselect(
                new QuoteLineItemSelector('QuoteLineItems', Quote.SObjectType)
                    .selectQuoteLineItemsForOrderCreationProcess()
            )
            .setCondition('(Id = :bind0)')
            .setQueryBindings(new List<Object>{
                techQuote.Id
            })
            .executeQuery()
            .get(0);

        List<Order> orders = OrderHelper.buildOrdersForQuoteByProvisioning(reselectedQuote, false);
        Test.stopTest();

        System.assertEquals(
            orders.size(),
            2,
            'Should be created 2 orders'
        );

        System.assertEquals(
            orders[0].Provisioning__c,
            OrderHelper.PROVISIONING_MANUAL,
            'Should be created 2 orders'
        );

        System.assertEquals(
            orders[1].Provisioning__c,
            OrderHelper.PROVISIONING_AUTO,
            'Should be created 2 orders'
        );

        for (Order ord : orders) {
            System.assertEquals(
                ord.Status,
                OrderHelper.STATUS_NEW,
                'Order status should be set to "New"'
            );
            System.assertEquals(
                ord.RecordTypeId,
                OrderHelper.SERVICE_NAME_TO_RT_ID.get(techQuote.ServiceName__c),
                'Order record type should be set to the same as the opportunity'
            );
            System.assertEquals(
                ord.CurrencyIsoCode,
                reselectedQuote.CurrencyIsoCode,
                'Order currency should be set to the same as the quote'
            );
            System.assertEquals(
                ord.AccountId,
                reselectedQuote.MasterQuote__r.AccountId,
                'Order account should be set to the same as the master quote'
            );
            System.assertEquals(
                ord.OpportunityId,
                reselectedQuote.MasterQuote__r.OpportunityId,
                'Order opportunity should be set to the same as the master quote'
            );
            System.assertEquals(
                ord.QuoteId,
                reselectedQuote.MasterQuote__c,
                'Order quote should be set to the same as the master quote'
            );
            System.assertEquals(
                ord.Pricebook2Id,
                reselectedQuote.Pricebook2Id,
                'Order Pricebook2Id should be set to the same as the quote'
            );
            System.assertEquals(
                ord.TechnicalAccountId__c,
                reselectedQuote.AccountId,
                'Order technical account should be set to the same as the quote'
            );
            System.assertEquals(
                ord.TechnicalOpportunityId__c,
                reselectedQuote.OpportunityId,
                'Order technical opportunity should be set to the same as the quote'
            );
            System.assertEquals(
                ord.TechnicalQuoteId__c,
                reselectedQuote.Id,
                'Order technical quote should be set to the same as the quote'
            );
        }
    }

    @IsTest
    private static void testDeletePreviousOrders() {
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
                QuoteLineItem.EffectivePriceNew__c => 10,
                QuoteLineItem.Discount => 0
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
                Phase__c.Phase_Number__c => 1,
                Phase__c.Order__c => testOrder.Id
            })
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Phase__c => testPhase.Id,
                Suborder__c.Status__c => 'New',
                Suborder__c.SuborderNumber__c => testPhase.Phase_Number__c
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

        Test.startTest();
            OrderHelper.deletePreviousOrders(new Map<Id, Order> {testOrder.Id => testOrder});
        Test.stopTest();

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrders()
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{testOrder.Id})
            .executeQuery();

        List<Suborder__c> reselectedSuborders = (List<Suborder__c>) new SuborderSelector()
            .selectSuborders()
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{testSuborder.Id})
            .executeQuery();

        List<SuborderLineItem__c> reselectedSuborderLineItems = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
            .selectSuborderLineItems()
            .setCondition('Id = :bind0')
            .setQueryBindings(new List<Object>{testSuborderLineItem.Id})
            .executeQuery();

        System.assertEquals(true,reselectedOrders.isEmpty(),'Orders shoulw be deleted');
        System.assertEquals(true,reselectedSuborders.isEmpty(),'Suborders should be deleted');
        System.assertEquals(true,reselectedSuborderLineItems.isEmpty(),'SuborderLineItems should be deleted');
    }
}