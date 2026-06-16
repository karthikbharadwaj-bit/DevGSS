@IsTest
private class Test_ServiceInfoHandler {
    @isTest
    private static void testCreateCaseForManualProvisioningMPUB_ExistingBusiness() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Triggers.switchOff();
        Triggers.except('ServiceInfoHandler.RunProcessOrderSentAfterActions');
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Manual Provisioning Case Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Manual Provisioning Case Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Manual Provisioning Case Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPSELL)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Manual Provisioning Case Test product')
            .setField(Product2.ExtID__c, ValueProviderBuilder.provideList(new List<String>{'TEST', 'TEST_1', 'TEST_2', null}))
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
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

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
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
            .setField(QuoteLineItem.Display_Name__c, ValueProviderBuilder.provideUniqueString())
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.ChargeTerm__c, QuoteLineItemHelper.CHARGE_TERM_MONTHLY)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .setField(QuoteLineItem.Zero_Quantity__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<Order> orderList = (List<Order> ) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, qt.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, qt.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();

        List<OrderItem> orderItemList = (List<OrderItem>) new SObjectBuilder(OrderItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OrderItem.OrderId => ValueProviderBuilder.provideParents(orderList),
                OrderItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                OrderItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 10, 0),
                OrderItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                OrderItem.QuoteLineItemId => ValueProviderBuilder.provideParents(qliList)
            })
            .quantity(4)
            .create()
            .getRecords();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, qt.Id)
            .quantity(1)
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        serviceInfo.IsProcessOrderSent__c = true;
        update serviceInfo;
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();

        Assert.areEqual(1, caseList.size(), 'RunProcessOrderSentAfterActions should properly create manual provisioning cases for Existing Business Quotes');
    }

    @isTest
    private static void testCreateCaseForManualProvisioningMPUB_NewBusiness() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true
            })
            .create();
        Triggers.switchOff();
        Triggers.except('ServiceInfoHandler.RunProcessOrderSentAfterActions');
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Manual Provisioning Case Test Account')
            .quantity(1)
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Manual Provisioning Case Test Opportunity')
            .setField(Opportunity.AccountId, acc.Id)
            .setField(Opportunity.Tier_Name__c, QuoteHelper.NGBS_OFFICE_PRODUCT)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .setField(Opportunity.Type, OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS)
            .setField(Opportunity.RecordTypeId, OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY)
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today())
            .setField(Opportunity.CurrencyIsoCode, RingCentralHelper.USD)
            .quantity(1)
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Manual Provisioning Case Test Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, RingCentralHelper.USD)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.isPrimary__c, true)
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_NEW_CUSTOMER)
            .setField(Quote.BillingPackage__c, pkg.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, false)
            .setField(Quote.Package_Info__c, NGBSTestDataGenerator.generateQuotePackageInfo())
            .quantity(1)
            .create()
            .getRecord();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Manual Provisioning Case Test product')
            .setField(Product2.ExtID__c, ValueProviderBuilder.provideList(new List<String>{'TEST', 'TEST_1', 'TEST_2', null}))
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Charge_Term__c, Product2Helper.CHARGE_TERM_MONTHLY)
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

        List<PricebookEntry> pbeList = new SObjectBuilder(PricebookEntry.SObjectType)
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
            .setField(QuoteLineItem.Display_Name__c, ValueProviderBuilder.provideUniqueString())
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.ChargeTerm__c, QuoteLineItemHelper.CHARGE_TERM_MONTHLY)
            .setField(QuoteLineItem.UnitPrice, 10)
            .setField(QuoteLineItem.IsMultiProductTechnicalQLI__c, false)
            .setField(QuoteLineItem.Zero_Quantity__c, false)
            .quantity(4)
            .create()
            .getRecords();

        List<Order> orderList = (List<Order> ) new SObjectBuilder(Order.SObjectType)
            .setField(Order.AccountId, acc.Id)
            .setField(Order.QuoteId, qt.Id)
            .setField(Order.OpportunityId, opp.Id)
            .setField(Order.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Order.EffectiveDate, System.today())
            .setField(Order.Status, OrderHelper.STATUS_NEW)
            .setField(Order.NumberOfMainLicenses__c, 25)
            .setField(Order.TechnicalAccountId__c, acc.Id)
            .setField(Order.TechnicalOpportunityId__c, opp.Id)
            .setField(Order.TechnicalQuoteId__c, qt.Id)
            .setField(Order.Provisioning__c, ValueProviderBuilder.provideList(
                new List<String>{
                    OrderHelper.PROVISIONING_AUTO,
                    OrderHelper.PROVISIONING_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();

        List<OrderItem> orderItemList = (List<OrderItem>) new SObjectBuilder(OrderItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                OrderItem.OrderId => ValueProviderBuilder.provideParents(orderList),
                OrderItem.PricebookEntryId => ValueProviderBuilder.provideParents(pbeList),
                OrderItem.Quantity => ValueProviderBuilder.providerRandomDecimal(1, 10, 0),
                OrderItem.UnitPrice => ValueProviderBuilder.providerRandomDecimal(1, 1000, 2),
                OrderItem.QuoteLineItemId => ValueProviderBuilder.provideParents(qliList)
            })
            .quantity(4)
            .create()
            .getRecords();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setField(ServiceInfo__c.Quote__c, qt.Id)
            .quantity(1)
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        serviceInfo.IsProcessOrderSent__c = true;
        update serviceInfo;
        Test.stopTest();

        List<Case> caseList = (List<Case>) new CaseSelector()
            .selectCases()
            .executeQuery();

        Assert.areEqual(0, caseList.size(), 'RunProcessOrderSentAfterActions should not create manual provisioning cases for New Business Quotes');
    }
}