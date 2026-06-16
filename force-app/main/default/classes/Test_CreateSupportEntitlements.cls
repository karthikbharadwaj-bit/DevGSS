@isTest
private class Test_CreateSupportEntitlements {

    @isTest
    static void testCreateSupportEntitlements() {
        CreateSupportEntitlements createEntitlementsJob = new CreateSupportEntitlements();
        System.assertEquals(
            null,
            createEntitlementsJob.queryOrdersData(null),
            'queryOrdersData should return null if no order ids are passed'
        );
        System.assertEquals(
            null,
            createEntitlementsJob.queryOrdersData(new Set<Id>()),
            'queryOrdersData should return null if no order ids are passed'
        );

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'test account',
                Account.UC_ES_Service_Level__c => 'Gold',
                Account.Enterprise_Support_End_Date__c => Date.today().addDays(1)
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'test opportunity',
                Opportunity.AccountId => testAcc.Id,
                Opportunity.StageName => '7. Closed Won',
                Opportunity.CloseDate => testAcc.Enterprise_Support_End_Date__c,
                Opportunity.Tier_Name__c => 'Office'
            })
            .create()
            .getRecord();

        Pricebook2 testPriceBook = (Pricebook2) new SObjectBuilder(Pricebook2.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Pricebook2.Name => 'Test Price Book',
                    Pricebook2.Description =>'Test Price Book Products',
                    Pricebook2.IsActive => true,
                    Pricebook2.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'test quote',
                    Quote.Auto_Renewal__c => true,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Pricebook2Id => testPriceBook.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.SupportType__c => 'advanced_support',
                    Product2.ExtID__c => 'LC_EES_488'
                }
            )
            .create()
            .getRecord();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.sObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => ValueProviderBuilder.ProvideList(
                        new List<Object> {
                            Test.getStandardPricebookId(),
                            testPriceBook.Id
                        }
                    ),
                    PricebookEntry.Product2Id => testProduct.Id,
                    PricebookEntry.UnitPrice => 200,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                })
            .create()
            .getRecords();

        Test.startTest();

        for(PricebookEntry pbe : pbeList) {
            if(pbe.PriceBook2Id == testQuote.Pricebook2Id) {
                new SObjectBuilder(QuoteLineItem.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object> {
                            QuoteLineItem.QuoteId => testQuote.Id,
                            QuoteLineItem.Product2Id => pbe.Product2Id,
                            QuoteLineItem.Quantity => 1,
                            QuoteLineItem.UnitPrice => pbe.UnitPrice,
                            QuoteLineItem.Discount_number__c => 2.5,
                            QuoteLineItem.PricebookEntryId => pbe.Id
                        })
                    .create();
            }
        }

        testAcc.Billing_ID__c = '111111';
        testAcc.RC_User_ID__c = '111111';
        update testAcc;

        Test.stopTest();

        System.assert(Limits.getQueueableJobs() > 0, 'CreateSupportEntitlements Queueable job should be started');

        List<Order> reselectedOrders = (List<Order>) new OrderSelector()
            .selectOrders()
            .subselect(new OrderItemSelector('OrderItems', Order.SObjectType).selectOrderItems())
            .executeQuery();

        System.assert(!reselectedOrders.isEmpty(), 'Orders records should be created');
        System.assertEquals(
            1,
            reselectedOrders.size(),
            'Only one order should be created'
        );

        Order createdOrder = reselectedOrders.get(0);
        System.assert(!createdOrder.OrderItems.isEmpty(), 'orders item records should be created');
        System.assertEquals(1, createdOrder.OrderItems.size(), 'one order item should be created');

        List<Entitlement> supportEntitlements = (List<Entitlement>) new SupportEntitlementSelector()
            .newQueryFactory()
            .selectFields(
                new List<String>{
                    'Type',
                    'AccountId',
                    'Product__c'
                }
            )
            .executeQuery();

        System.assert(!supportEntitlements.isEmpty(), 'Support Entitlement records should be created');
        System.assertEquals(
            1,
            supportEntitlements.size(),
            'Only one Support Entitlement should be created'
        );

        Entitlement createdSupportEntitlement = supportEntitlements.get(0);
        System.assertEquals(
            testAcc.Id,
            createdSupportEntitlement.AccountId,
            'Support Entitlement should be associated with account'
        );
        System.assertEquals(
            testProduct.Id,
            createdSupportEntitlement.Product__c,
            'Support Entitlement should be associated with product'
        );
        System.assertEquals(
            'Advanced Support',
            createdSupportEntitlement.Type,
            'Support Entitlement should have type Advanced Support'
        );
    }

    @isTest
    static void testGetExistingEntitlements() {
        CreateSupportEntitlements createEntitlementsJob = new CreateSupportEntitlements();

        System.assertEquals(
            new Map<Id, Map<Id, Entitlement>>(),
            createEntitlementsJob.getExistingEntitlements(null, null),
            'getExistingEntitlements should return an empty map arguments are null or empty'
        );
        System.assertEquals(
            new Map<Id, Map<Id, Entitlement>>(),
            createEntitlementsJob.getExistingEntitlements(new Set<Id>(), new List<Product2>()),
            'getExistingEntitlements should return an empty map arguments are null or empty'
        );

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'test account'
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.SupportType__c => 'advanced_support',
                Product2.ExtID__c => 'LC_EES_488'
            })
            .create()
            .getRecord();

        Entitlement testSupportEntitlement = new Entitlement(
            Name = 'test support entitlement',
            AccountId = testAcc.Id,
            Product__c = testProduct.Id,
            StartDate = Date.today(),
            Type = 'Advanced Support'
        );
        insert testSupportEntitlement;

        Map<Id, Map<Id, Entitlement>> result = createEntitlementsJob.getExistingEntitlements(
            new Set<Id>{testAcc.Id},
            new List<Product2>{testProduct}
        );
        System.assertEquals(
            1,
            result.size(),
            'getExistingEntitlements should return a map with one key'
        );
        System.assertEquals(
            testAcc.Id,
            new List<Id>(result.keySet()).get(0),
            'getExistingEntitlements should return a map with account id as key'
        );

        Entitlement returnedSupportEntitlement = result.values().get(0).get(testProduct.Id);
        System.assertEquals(
            testSupportEntitlement.Id,
            returnedSupportEntitlement.Id,
            'getExistingEntitlements should return a map with Entitlement associated to account'
        );
    }

    @isTest
    public static void testBuildSupportEntitlement() {

        CreateSupportEntitlements createEntitlementsJob = new CreateSupportEntitlements();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Account.Name => 'test account'
            })
            .build()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.SupportType__c => CreateSupportEntitlements.MANAGED_SERVICES,
                Product2.ExtID__c => 'LC_EES_488',
                Product2.Name => 'Test Product Name'
            })
            .build()
            .getRecord();

        Date startDate = Date.today();
        Entitlement supportEntitlement = createEntitlementsJob.buildSupportEntitlement(testAcc.Id, testProduct, startDate);

        System.assertEquals(testAcc.Id, supportEntitlement.AccountId, 'created Entitlement record should have AccountId set to test account Id');
        System.assertEquals(testProduct.Id, supportEntitlement.Product__c, 'created Entitlement record should have Product__c set to test product Id');
        System.assertEquals('Managed Services', supportEntitlement.Name, 'created Entitlement record should have name equal to "Managed Services"');
        System.assertEquals('Managed Services', supportEntitlement.Type, 'created Entitlement record should have Type equal to "Managed Services"');
        System.assertEquals(startDate, supportEntitlement.StartDate, 'created Entitlement record should have StartDate equal to startDate parameter');
    }

    @isTest
    public static void testBuildSupportEntitlementForCC() {

        CreateSupportEntitlements createEntitlementsJob = new CreateSupportEntitlements();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => ValueProviderBuilder.provideDummyId(Account.SObjectType),
                Account.Name => 'test account'
            })
            .build()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.SupportType__c => 'advanced_support',
                Product2.ExtID__c => 'LC_CCES_481',
                Product2.Name => 'Test Product Name'
            })
            .build()
            .getRecord();

        Date startDate = Date.today();
        Entitlement supportEntitlement = createEntitlementsJob.buildSupportEntitlement(testAcc.Id, testProduct, startDate);

        System.assertEquals(testAcc.Id, supportEntitlement.AccountId, 'created Entitlement record should have AccountId set to test account Id');
        System.assertEquals(testProduct.Id, supportEntitlement.Product__c, 'created Entitlement record should have Product__c set to test product Id');
        System.assertEquals(testProduct.Name, supportEntitlement.Name, 'created Entitlement record should have name equal to ' + testProduct.Name);
        System.assertEquals('Advanced Support', supportEntitlement.Type, 'created Entitlement record should have Type equal to "Advanced Support"');
        System.assertEquals(startDate, supportEntitlement.StartDate, 'created Entitlement record should have StartDate equal to startDate parameter');
    }

    @isTest
    public static void testBuildEntitlementName() {
        CreateSupportEntitlements createEntitlementsJob = new CreateSupportEntitlements();
        System.assertEquals(
            'Test Product Name',
            createEntitlementsJob.buildEntitlementName(null, 'Test Product Name'),
            'buildEntitlementName should return "Test Product Name" if supportType is null and prodName is provided'
        );
        System.assertEquals(
            CreateSupportEntitlements.ADVANCED_SUPPORT,
            createEntitlementsJob.buildEntitlementName(null, null),
            'buildEntitlementName should return "Advanced Support" if supportType is null and prodName is null'
        );
        System.assertEquals(
            'Managed Services',
            createEntitlementsJob.buildEntitlementName(CreateSupportEntitlements.MANAGED_SERVICES, 'Test Product Name'),
            'buildEntitlementName should return "Managed Services" if supportType is equal to "managed_services" and prodName is provided'
        );
        System.assertEquals(
            'Managed Services',
            createEntitlementsJob.buildEntitlementName(CreateSupportEntitlements.MANAGED_SERVICES, null),
            'buildEntitlementName should return "Managed Services" if supportType is equal to "managed_services" and prodName not provided'
        );
    }
}