@isTest
private class Test_ProcessBillingPackageSync {

    @isTest
    static void testExecute() {
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

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Status => QuoteHelper.QUOTE_STATUS_PRESENTED,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate(),
                    Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                    Quote.isPrimary__c => true
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
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        QuoteLineItem qli1 = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => proServQuote.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.Discount_Number__c => 10
            })
            .create()
            .getRecord();

        Package__c pckg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Package__c.Account__c => testAcc.Id,
                    Package__c.Account_Package_Id__c => '12345',
                    Package__c.Opportunity__c => testOpp.Id                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => proServQuote.Id,
                ServiceInfo__c.ICBSyncStepStatus__c => true,
                ServiceInfo__c.ICBProvisioningStepStatus__c => true,
                ServiceInfo__c.BillingPackage__c => pckg.Id

            })
            .create()
            .getRecord();
        
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://fake-billing-api',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.Login__c => 'login',
                NGBS_Settings__c.Password__c => 'password'
            })
            .create();

            Id jobId;
            String comment = 'Test';
            ProcessBillingPackageSync pbps = new ProcessBillingPackageSync(testOpp.Id, testAcc.Id, '12345', '12345');

            String accountIdString = '123';
            String body = '{"packages":[{"id":12345,"catalogId":"2","version":"1","currency": "USD", "product": "Professional Services"}]}';
            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            tstMock.body = body;
            tstMock.code = 200;
            tstMock.status = 'Complete';
            Test.setMock(HttpCalloutMock.class, tstMock);

        Test.startTest();
            jobId = System.enqueueJob(pbps);
        Test.stopTest();

        Package__c[] packages = [SELECT Id from Package__c WHERE Account__c = :testAcc.Id AND Account_Package_Id__c = '12345'];
        Assert.areEqual(1, packages.size());
    }
}