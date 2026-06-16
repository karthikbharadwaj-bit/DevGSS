@isTest
private class Test_ProcessProServRecordsOnOppClose {

    @isTest
    static void testExecute () {
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

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => ValueProviderBuilder.provideUniqueString('testContact'),
                    Contact.AccountId => testAcc.Id
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
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.Primary_Opportunity_Contact__c => testContact.Id
                                }
            )
            .create()
            .getRecord();

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                    Quote.isPrimary__c => true
                }
            )
            .create()
            .getRecord();

        Package__c pckg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account__c => testAcc.Id,
                    Package__c.Account_Package_Id__c => '12345',
                    Package__c.Opportunity__c => testOpp.Id
                }
            )
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => testAcc.Id,
                Order.Name => 'test',
                Order.Status => OrderHelper.STATUS_LOCKED,
                Order.OpportunityId => testOpp.Id,
                Order.EffectiveDate => System.today().addDays(100),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => proServQuote.Id,
                Order.MainPointOfContact__c => testContact.Id
            })
            .create()
            .getRecord();

        Opportunity testOpp2 = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.Parent_Order__c => testOrder.Id
                }
            )
            .create()
            .getRecord();

        List<Order> newOrderList = (List<Order>) new SObjectBuilder(Order.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.AccountId => testAcc.Id,
                Order.Name => 'test',
                Order.Status => OrderHelper.STATUS_NEW,
                Order.OpportunityId => testOpp2.Id,
                Order.EffectiveDate => System.today().addDays(100),
                Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => proServQuote.Id,
                Order.PackageId__c => pckg.Id,
                Order.MainPointOfContact__c => testContact.Id
            })
            .quantity(2)
            .build()
            .getRecords();

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

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 1,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
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

        Triggers.except('SuborderTriggerHandler.PopulateOrderSubTotals');
        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => newOrderList[0].Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1
            })
            .create()
            .getRecord();

        Triggers.except('SuborderLineItemTriggerHandler.PopulateSuborderSumOfAllItems');
        Triggers.except('SuborderLineItemTriggerHandler.PopulateOrderSubTotals');
        SuborderLineItem__c testSuborderLineItem = (SuborderLineItem__c) new SOBjectBuilder(SuborderLineItem__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                SuborderLineItem__c.Suborder__c	 => testSuborder.Id,
                SuborderLineItem__c.Quantity__c => 1
            })
            .create()
            .getRecord();

        Id jobId;
        AsyncApexJob jobInfo;
        String comment = 'Test';
        ProcessProServRecordsOnOppClose pproc = new ProcessProServRecordsOnOppClose(new List<Opportunity> {testOpp2}, newOrderList);

        Test.startTest();
            jobId = System.enqueueJob(pproc);
        Test.stopTest();

        List<Suborder__c> reselectedSuborders = (List<Suborder__c>) new SuborderSelector()
            .selectSuborders()
            .executeQuery();

        List<SuborderLineItem__c> reselectedSuborderLineItems = (List<SuborderLineItem__c>) new SuborderLineItemSelector()
            .selectSuborderLineItems()
            .executeQuery();

        Assert.areEqual(3, reselectedSuborders.size(), 'New Suborders should be created');
    }
}