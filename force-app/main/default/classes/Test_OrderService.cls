@isTest
public with sharing class Test_OrderService {

    @isTest
    private static void testGetOrderForSuborderManagement() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Service_Type__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Package__c.Account__c => acc.Id,
                Package__c.Opportunity__c => opp.Id,
                Package__c.Account_Package_Id__c => '12345'
            })
            .create()
            .getRecord();

        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => acc.Id
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.AccountId => acc.Id,
                    Order.Name => 'test',
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => opp.Id,
                    Order.EffectiveDate => Date.newInstance(2050, 11, 11),
                    Order.PackageId__c => pkg.Id,
                    Order.ProServProject__c => proservProject.Id
                }
            )
            .create()
            .getRecord();

        proservProject.Order__c = testOrder.Id;
        update proservProject;

        BillingWrappers.OrdersParams params = new BillingWrappers.OrdersParams();
        params.action = 'getOrderForSuborderManagement';
        params.orderId = testOrder.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;
        Test.startTest();
            OrderService.handleRequest();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        Order reselectedOrder = [SELECT Id, createdDate from Order WHERE Id = :testOrder.Id];

        BillingWrappers.OrderWrapper orderWrapper = (BillingWrappers.OrderWrapper)JSON.deserialize(body, BillingWrappers.OrderWrapper.class);

        Assert.areEqual(orderWrapper.status, OrderHelper.STATUS_NEW, 'Correct status should be retrieved');
        Assert.areEqual(orderWrapper.billingAccountProServPackageId, pkg.Account_Package_Id__c, 'Correct billing account proserv package id should be retrieved');
        Assert.areEqual(orderWrapper.initialOrderCreatedDateUTC, reselectedOrder.createdDate, 'Correct created date should be retrieved');
    }

    @isTest
    private static void testUpdateOrder(){

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

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_DIGITALLINE_UNLIMITED',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qliDigitalLineUnlimited = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.IsHiddenLicense__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => testPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrder.Id,
                OrderItem.Quantity => qliDigitalLineUnlimited.Quantity,
                OrderItem.UnitPrice => qliDigitalLineUnlimited.UnitPrice,
                OrderItem.PriceBookEntryId => testPbe.Id
            })
        .create()
        .getRecord();

        Triggers.switchOn();

        Test.startTest();

        RestRequest request = new RestRequest();

        BillingWrappers.OrdersParams updateOrderParams = new BillingWrappers.OrdersParams();
        updateOrderParams.action = 'updateOrder';
        updateOrderParams.orderId = testOrder.Id;
        updateOrderParams.opportunityId = testOpp.Id;

        request.requestBody = Blob.valueOf(JSON.serialize(updateOrderParams));
        RestContext.request = request;
        OrderService.handleRequest();

        Order order = (Order) new ListOptional(new OrderSelector()
            .selectOrdersByIds(new List<Object>{new List<Id>{testOrder.Id}})
            .executeQuery()
        ).getFirst();
        Test.stopTest();

        Assert.areEqual(order.RelatedChangeOpportunity__c, testOpp.Id, 'Related opportunity field should be populated');
    }

    @isTest
    private static void testUpdateOrderStatus(){

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

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_DIGITALLINE_UNLIMITED',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qliDigitalLineUnlimited = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.IsHiddenLicense__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => testPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrder.Id,
                OrderItem.Quantity => qliDigitalLineUnlimited.Quantity,
                OrderItem.UnitPrice => qliDigitalLineUnlimited.UnitPrice,
                OrderItem.PriceBookEntryId => testPbe.Id
            })
        .create()
        .getRecord();

        Triggers.switchOn();

        Test.startTest();

        RestRequest request = new RestRequest();

        BillingWrappers.OrdersParams updateOrderParams = new BillingWrappers.OrdersParams();
        updateOrderParams.action = 'updateOrderStatus';
        updateOrderParams.orderId = testOrder.Id;
        updateOrderParams.status = OrderHelper.STATUS_LOCKED;

        request.requestBody = Blob.valueOf(JSON.serialize(updateOrderParams));
        RestContext.request = request;
        OrderService.handleRequest();

        Order order = (Order) new ListOptional(new OrderSelector()
            .selectOrdersByIds(new List<Object>{new List<Id>{testOrder.Id}})
            .executeQuery()
        ).getFirst();
        Test.stopTest();

        Assert.areEqual(order.Status, OrderHelper.STATUS_LOCKED, 'Order status should be updated');
    }

    @isTest
    private static void testUpdatePackageStatus(){

        Triggers.SwitchOff();

        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi/',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '123'
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

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Service_Type__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Package__c.Account__c => testAcc.Id,
                Package__c.Opportunity__c => testOpp.Id,
                Package__c.Account_Package_Id__c => '456'
            })
            .create()
            .getRecord();
    
        Proserv_Project__c proservProject = (Proserv_Project__c) new SObjectBuilder(Proserv_Project__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Proserv_Project__c.Account__c => testAcc.Id
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
                    Order.EffectiveDate => Date.newInstance(2050, 11, 11),
                    Order.PackageId__c => pkg.Id,
                    Order.ProServProject__c => proservProject.Id,
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_DIGITALLINE_UNLIMITED',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry testPbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qliDigitalLineUnlimited = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => testQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.IsHiddenLicense__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => testPbe.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        OrderItem testOrderItem = (OrderItem) new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                OrderItem.OrderId => testOrder.Id,
                OrderItem.Quantity => qliDigitalLineUnlimited.Quantity,
                OrderItem.UnitPrice => qliDigitalLineUnlimited.UnitPrice,
                OrderItem.PriceBookEntryId => testPbe.Id
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();

        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        RestRequest request = new RestRequest();

        BillingWrappers.OrdersParams updatePackageStatusParams = new BillingWrappers.OrdersParams();
        updatePackageStatusParams.action = 'updatePackageStatus';
        updatePackageStatusParams.orderId = testOrder.Id;
        updatePackageStatusParams.status = OrderHelper.STATUS_COMPLETED;

        request.requestBody = Blob.valueOf(JSON.serialize(updatePackageStatusParams));
        RestContext.request = request;

        OrderService.handleRequest();

        List<Package__c> packages = new PackageSelector()
            .selectPackagesById(new List<Id>{pkg.Id})
            .executeQuery();
        for (Package__c p : packages) {
            Assert.areEqual(PackageHelper.PACKAGE_STATUS_DELETED, p.Package_Status__c, 'Package status should be deleted');
        }

        Test.stopTest();
    }
}