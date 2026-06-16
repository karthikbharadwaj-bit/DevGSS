@isTest
class Test_SWNDownsellRunner {
    //Account fields defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';

    //Account fields defined
    private static final String OPPORTUNITY_NAME = 'testOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_STAGE_NAME = 'Office';
    private static final String OPPORTUNITY_TIER_NAME = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';

    //Account fields defined
    private static final String QUOTE_NAME = 'TestQuote';

    //Account fields defined
    private static final String PRODUCT2_NAME = 'Test product';
    private static final String PRODUCT2_EXTID = 'Test';
 
    //Account fields defined
    private static final String ORDER_NAME = 'Test';
    private static final String ORDER_STATUS = 'Requested';

    //Assert message defined
    private static final String ASSERT_MESSAGE = 'Pricebook entries should be selected';

    @testsetup
    private static void testData(){
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ACCOUNT_NAME,
                        Account.Billing_ID__c => ACCOUNT_BILLING_ID
                    }
                )
                .create()
                .getRecord();
            
            Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.Name => OPPORTUNITY_NAME,
                        Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
                        Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
                        Opportunity.StageName => OPPORTUNITY_STAGE_NAME,
                        Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                        }
                )
                .create()
                .getRecord();
            
            Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => QUOTE_NAME,
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
                .create()
                .getRecord();
        
    
            Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Product2.Name => PRODUCT2_NAME,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.IsActive => true,
                    Product2.ExtID__c => PRODUCT2_EXTID
                })
                .create()
                .getRecord();
    
            Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Order.AccountId => testAcc.Id,
                        Order.Name => ORDER_NAME,
                        Order.Status => ORDER_STATUS,
                        Order.OpportunityId => testOpp.Id,
                        Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                    }
                )
                .create()
                .getRecord();
        
            PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
                .setFields(new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => prod.Id,
                    PricebookEntry.UnitPrice => 0,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false,
                    PricebookEntry.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                })
                .create()
                .getRecord();
    }
    @isTest
    static void testHasNoManualDownsellType() {
        Map<String, List<QuoteLineItem>> qliTypesMap = new Map<String, List<QuoteLineItem>>();

        SWNDownsellRunner runner = new SWNDownsellRunner();

        Test.startTest();
            Boolean result = runner.hasNoManualDownsellType(qliTypesMap);
            Assert.isTrue(result, 'Expected true when map has no target keys');

            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE, new List<QuoteLineItem>());
            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_MANUAL, new List<QuoteLineItem>());
            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_EXCEPTION, new List<QuoteLineItem>());
            result = runner.hasNoManualDownsellType(qliTypesMap);
            Assert.isTrue(result, 'Expected true when all types are empty');

            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE, new List<QuoteLineItem> { new QuoteLineItem() });
            result = runner.hasNoManualDownsellType(qliTypesMap);
            Assert.isFalse(result, 'Expected false when DOWNSELL_TYPE_AUTO_WITH_CASE is not empty');

            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE, new List<QuoteLineItem>());
            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_MANUAL, new List<QuoteLineItem> { new QuoteLineItem() });
            result = runner.hasNoManualDownsellType(qliTypesMap);
            Assert.isFalse(result, 'Expected false when DOWNSELL_TYPE_MANUAL is not empty');

            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_MANUAL, new List<QuoteLineItem>());
            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_EXCEPTION, new List<QuoteLineItem> { new QuoteLineItem() });
            result = runner.hasNoManualDownsellType(qliTypesMap);
            Assert.isFalse(result, 'Expected false when DOWNSELL_TYPE_EXCEPTION is not empty');

        Test.stopTest();
    }

    @isTest
    static void testHandleDownsellResponse() {
        SWNDownsellRunner runner = new SWNDownsellRunner();
        Response mockResponse = new Response();
        mockResponse.setData('test_key', 'some data');
        Map<String, List<QuoteLineItem>> qliTypesMap = new Map<String, List<QuoteLineItem>> {
            SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE => new List<QuoteLineItem> { new QuoteLineItem() },
            SWNHelper.DOWNSELL_TYPE_MANUAL => new List<QuoteLineItem>(),
            SWNHelper.DOWNSELL_TYPE_EXCEPTION => new List<QuoteLineItem>()
        };

        Test.startTest();
            Assert.isNull(runner.res.data.get('test_key'), 'data should not be defined');
            Boolean result = runner.handleDownsellResponse(mockResponse, qliTypesMap);
            Assert.isFalse(result, 'Expected result to be false when response is successful.');
            Assert.isNull(runner.res.data.get('test_key'), 'data should not be defined');

            mockResponse.error();
            runner.res = new Response();
            qliTypesMap.put(SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE, new List<QuoteLineItem>());

            Assert.isNull(runner.res.data.get('test_key'), 'data should not be defined');
            result = runner.handleDownsellResponse(mockResponse, qliTypesMap);
            Assert.isTrue(result, 'Expected result to be true when response is not successful.');
            Assert.isNotNull(runner.res.data.get('test_key'), 'data should be defined');
        Test.stopTest();
    }

    @isTest
    static void testProcessSimplifiedLBODownsellEmptyQuoteLineItems() {
        SWNDownsellRunner runner = new SWNDownsellRunner();
        runner.sdc = new SWNDataCollector(); 
        runner.sdc.qt = (Quote) Test_Utils.putIntoUnwritableField(
            new Quote(),
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem>()
        );

        Test.startTest();
            Boolean isDownsellCompleted = runner.processSimplifiedLBODownsell();
        Test.stopTest();

        Assert.isFalse(isDownsellCompleted, 'Downsell should not be completed for empty quote line items');
        Assert.areEqual(SWNDownsellRunner.MISSING_QUOTE_ERROR, runner.res.messages[0].messageDetails, 'Wrong error message');
    }

    @isTest
    static void testProcessDownsell() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableSimplifiedLBODownsell__c, true)
            .create();

        SWNDownsellRunner runner = new SWNDownsellRunner();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.IsHiddenLicense__c => false
            })
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Product2Id, new Product2());
        qli.putSObject(QuoteLineItem.Entitlement__c, new Entitlement__c(Quantity__c = 2));

        runner.sdc = new SWNDataCollector();
        runner.sdc.costCenters = new List<Cost_Center__c> {new Cost_Center__c()};
        runner.sdc.syncable = new NGBSSyncables.OpportunitySync(new Opportunity(IsDownsellCaseCreated__c = false));
        runner.sdc.currentStep = SWNStep.buildDownSellStep();
        runner.sdc.qt = (Quote) Test_Utils.putIntoUnwritableField(
            new Quote(),
            Quote.class,
            'QuoteLineItems',
            new List<QuoteLineItem> { qli }
        );
        runner.sdc.qt.ServiceName__c= 'MVP';
        Assert.isFalse(runner.sdc.syncable.isDownsellCaseCreated(), 'Downsell case should not be created yet');
        Test.startTest();
            runner.processDownsell();
        Test.stopTest();

        Assert.isTrue(
            (Boolean) runner.sdc.syncable.getSObjFieldsToUpdate().get(Opportunity.IsDownsellCaseCreated__c),
            'Field value should be true'
        );
        Assert.isFalse(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should not be completed automatically');
    }

    @isTest
    static void testCallDownsell() {
        SWNDownsellRunner runner = new SWNDownsellRunner();
        Test.startTest();
            Boolean result = runner.callDownsell(null, null);
        Test.stopTest();

        Assert.isFalse(result, 'Expected callDownsell to return false');
        Assert.areEqual(Response.STATUS_SUCCESS, runner.res.data.get(SWNHelper.STATUS_PROP), 'Status should be success');
    }

    @isTest
    static void testFinishDownsell() {
        Boolean isDownsellCompleted = true;
        SWNDownsellRunner runner = new SWNDownsellRunner();
        runner.sdc = new SWNDataCollector();
        runner.sdc.syncable = new NGBSSyncables.OpportunitySync(new Opportunity());
        runner.sdc.qt = (Quote) Test_Utils.putIntoUnwritableField(
            new Quote(),
            Quote.class,
            'Account',
            new Account()
        );
        runner.sdc.qt.putSObject(Quote.OpportunityId, new Opportunity());
        runner.sdc.qt.ServiceName__c= 'MVP';
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Discount_number__c => 0,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.IsHiddenLicense__c => false
            })
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Product2Id, new Product2());
        qli.putSObject(QuoteLineItem.QuoteId, runner.sdc.qt);

        Map<String, List<QuoteLineItem>> qliTypesMap = new Map<String, List<QuoteLineItem>> {
            SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE => new List<QuoteLineItem> { qli },
            SWNHelper.DOWNSELL_TYPE_MANUAL => new List<QuoteLineItem>(),
            SWNHelper.DOWNSELL_TYPE_EXCEPTION => new List<QuoteLineItem>()
        };

        Test.startTest();
            Boolean result = runner.finishDownsell(isDownsellCompleted, qliTypesMap);
        Test.stopTest();

        Assert.areEqual(isDownsellCompleted, result, 'Result value should be equal to isDownsellCompleted');
        Assert.areEqual(1, [SELECT Id from Case where RecordTypeId =: CaseHelper.RT_ID_DEALDESK_CASE].size(), 'Case should be created');
    }

    @isTest
    static void testDownsellStepSkipped() {
        SWNDownsellRunner runner = new SWNDownsellRunner(null, SWNStep.DOWN_SELL);
        runner.sdc = new SWNDataCollector(null, SWNStep.DOWN_SELL);
        runner.sdc.qt = new Quote(
            ServiceName__c = 'test',
            IsMultiProductTechnicalQuote__c = true,
            package_info__c= NGBSTestDataGenerator.generateQuotePackageInfo()
        );

        Test.startTest();
            Assert.isTrue(runner.downsell(), 'Should not be executed by defaults');

            runner.sdc.qt.Enabled_LBO__c = true;
            runner.sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().withDownsellCaseCreated(true).build();
            Assert.isTrue(runner.downsell(), 'Should not be executed if case already created');

            runner.sdc.syncable = new SWNMockBuilders.NGBSSyncableBuilder().withDownsellCaseCreated(false).build();
            Assert.isTrue(runner.downsell(), 'Should not be executed if no qlis');
        Test.stopTest();
    }
    @isTest
    static void testFinishDownsellRCEvent() {
        Boolean isDownsellCompleted = true;
        ServiceInfo__c serviceInfo = new ServiceInfo__c();
        serviceInfo.Quote__c = [Select Id from quote limit 1].Id;
        serviceInfo.Opportunity__c = [Select Id from Opportunity limit 1].Id;

        insert serviceInfo;
        SWNDownsellRunner runner = new SWNDownsellRunner();
        runner.sdc = new SWNDataCollector();
        runner.sdc.syncable = new NGBSSyncables.ServiceInfoSync(serviceInfo);
        runner.sdc.qt = (Quote) Test_Utils.putIntoUnwritableField(
            new Quote(),
            Quote.class,
            'Account',
            new Account()
        );
        runner.sdc.qt.putSObject(Quote.OpportunityId, new Opportunity());
        runner.sdc.qt.ServiceName__c=Constants.CONST_RC_EVENT;
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Discount_number__c => 0,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.IsHiddenLicense__c => false
            })
            .build()
            .getRecord();

        qli.putSObject(QuoteLineItem.Product2Id, new Product2());
        qli.putSObject(QuoteLineItem.QuoteId, runner.sdc.qt);

        Map<String, List<QuoteLineItem>> qliTypesMap = new Map<String, List<QuoteLineItem>> {
            SWNHelper.DOWNSELL_TYPE_AUTO_WITH_CASE => new List<QuoteLineItem> { qli },
            SWNHelper.DOWNSELL_TYPE_MANUAL => new List<QuoteLineItem>(),
            SWNHelper.DOWNSELL_TYPE_EXCEPTION => new List<QuoteLineItem>()
        };

        Test.startTest();
            Boolean result = runner.finishDownsell(isDownsellCompleted, qliTypesMap);
        Test.stopTest();

        Assert.areEqual(isDownsellCompleted, result, 'Result value should be equal to isDownsellCompleted');
        Assert.areEqual(1, [SELECT Id from Case where RecordTypeId =: CaseHelper.RT_ID_DEALDESK_CASE].size(), 'Case should be created');
    }
}