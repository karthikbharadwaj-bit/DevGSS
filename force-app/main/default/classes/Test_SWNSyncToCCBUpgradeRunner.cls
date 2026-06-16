@isTest
class Test_SWNSyncToCCBUpgradeRunner {
    static final String P_INFO = '[{"duration":"Annual","offerType":"Monthly","packageInfo":{"id":"123","catalogId": "1", "version":"2", "name":"package name"},"contract":{"extId":"Office","billingId":"234","status":"test"}}]';
    static SWNSyncToCCBUpgradeRunner generateTestData() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Package_Info__c => P_INFO
            })
            .build()
            .getRecord();
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.ngbsAcc = new BillingWrappers.NGBSAccount();
        sdc.qt = qt;
        sdc.currentStep = SWNStep.buildSyncToCcbUpgradeStep();

        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        sdc.ngbsAcc.packages = new List<BillingWrappers.NGBSAccountPackage> { ngbsPkg };
        ngbsPkg.id = '123';
        ngbsPkg.catalogId = '1';
        ngbsPkg.version = '2';
        ngbsPkg.masterDuration = QuoteLineItemHelper.CHARGE_TERM_ANNUAL;

        SWNSyncToCCBUpgradeRunner runner = new SWNSyncToCCBUpgradeRunner(qt.Id, SWNStep.SYNC_TO_NGBS_UPGRADE);
        runner.sdc = sdc;
        return runner;
    }

    @isTest
    static void testRunnerWhenCCBUpgradeSynced() {
        SWNSyncToCCBUpgradeRunner runner = generateTestData();
        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.areEqual(1, runner.res.messages.size(), 'Should have 1 message');
        Assert.areEqual(SWNMessageHelper.PKG_AND_LICENSES_QUANTITIES_SYNCED_MSG, runner.res.messages[0].messageDetails, 'Wrong message about synced charge terms');
    }

    @isTest
    static void testRunnerWhenCCBUpgradeNotSynced() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableUILessProcessOrderEngage__c => true,
                Feature_Toggle__c.EnableSimplifiedDownsellForRingCX__c => true,
                Feature_Toggle__c.EnableMultiProduct__c => true
            })
            .create();

        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.BaseEndpoint__c => 'https://fake-icb-api',
                CCB_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.ChangePath__c => '/changeCCBPath'
            })
            .create();

        List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/changeCCBPath', HttpHelper.RESPONSE_STATUS_COMPLETED, '{}', 200, HttpHelper.METHOD_POST)
        };
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock(mockInfos));

        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'OPP_NAME',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();


        Product2 productDigitalLine = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_DIGITALLINE',
                Product2.ExtId__c => 'LC_DL_75',
                Product2.Family => Product2Helper.FAMILY_COMMON_PHONE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Name => 'Test Package',
                Package__c.Package_Catalog_Id__c => '123',
                Package__c.Package_Version__c => '1',
                Package__c.Account__c => opp.AccountId,
                Package__c.Account_Package_Id__c => '1231231231'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.PackageNameNew__c => 'Test',
                Quote.BillingPackage__c => testPackage.Id,
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Package_Info__c => P_INFO
            })
            .create()
            .getRecord();

        Order testOrder = (Order) new SOBjectBuilder(Order.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Order.Name => ValueProviderBuilder.provideUniqueString('test order'),
                Order.Pricebook2Id => Test.getStandardPricebookId(),
                Order.QuoteId => qt.Id,
                Order.TechnicalQuoteId__c => qt.Id,
                Order.AccountId => opp.AccountId,
                Order.EffectiveDate => System.today(),
                Order.Status => OrderHelper.STATUS_NEW,
                Order.RecordTypeId => OrderHelper.RT_ID_ENGAGE_DIGITAL_STANDALONE
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLine.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'ENTITLEMENT_NAME',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => opp.AccountId,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 6,
                Entitlement__c.PackageCatalogId__c => '5',
                Entitlement__c.PackageVersion__c => '3',
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLine.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .create()
            .getRecord();

        QuoteLineItem qliDigitalLineUnlimited = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLine.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.ChargeTerm__c => QuoteLineItemHelper.CHARGE_TERM_MONTHLY,
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo()
            })
            .create()
            .getRecord();

        new SOBjectBuilder(OrderItem.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                OrderItem.OrderId => testOrder.Id,
                OrderItem.PricebookEntryId => currentPricebookEntry.Id,
                OrderItem.QuoteLineItemId => qliDigitalLineUnlimited.Id,
                OrderItem.Quantity => qliDigitalLineUnlimited.Quantity,
                OrderItem.UnitPrice => qliDigitalLineUnlimited.UnitPrice
            })
            .create();

        Contract__c contract = (Contract__c) new SObjectBuilder(Contract__c.SObjectType)
            .setField(Contract__c.ExtID__c, ValueProviderBuilder.provideUniqueString())
            .create()
            .getRecord();

        new SObjectBuilder(Contract_Discount__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contract_Discount__c.Contract__c => contract.Id,
                Contract_Discount__c.ApplicableTo__c => ValueProviderBuilder.provideUniqueString(),
                Contract_Discount__c.Duration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Contract_Discount__c.Discount__c => 1
            })
            .create();

        Area_Codes__c areaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Codes__c.Name => 'Test',
                Area_Codes__c.Area_Code__c => 1234,
                Area_Codes__c.City__c => 'test',
                Area_Codes__c.Country__c => 'test',
                Area_Codes__c.State__c => 'test',
                Area_Codes__c.State_Abbreviation__c => 'tes'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Area_Code__c => areaCode.Id,
                Area_Code_Line_Item__c.Quantity__c => qliDigitalLineUnlimited.Quantity,
                Area_Code_Line_Item__c.Quote_Line_Item__c => qliDigitalLineUnlimited.Id
            })
            .create();
        Triggers.switchOn();

        SWNSyncToCCBUpgradeRunner runner = generateTestData();

        qliDigitalLineUnlimited.putSObject(QuoteLineItem.Entitlement__c, ent);
        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qliDigitalLineUnlimited }
        );

        runner.sdc.qt = qt;
        runner.sdc.isMPUB = true;
        runner.sdc.costCenters = new List<Cost_Center__c> { new Cost_Center__c() };
        runner.sdc.ngbsAcc.packages[0].version = '22';

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be true');
        Assert.areEqual(1, [SELECT Id from Case where RecordTypeId =: CaseHelper.RT_ID_DEALDESK_CASE].size(), 'Case should be created');
    }
}