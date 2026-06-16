@isTest
private class Test_SWNUpdateLicenseLimitsRunner {
    private static final String BILLING_ID = '12345';
    private static final String LBOX_ELEMENT_ID = 'LB_702';
    private static final String LBO_MAX_LIMIT_VALUE = '100';
    private static final String PACKAGE_INFO_QLI_WITH_LBOX = '{"categoryCode":"DL-UNL", "categoryPath":"DL-UNL", "discount"' +
        ':{},"duration":"Monthly","id":"18","price":0,"version":"1","parent":"LC_DL_75","q":33,' +
        '"lboxes":[{"elementID":"' + LBOX_ELEMENT_ID + '","min":1,"max":' + LBO_MAX_LIMIT_VALUE + '}]}';
    private static final Integer EXPECTED_LBOX_OVERRIDE_LIMIT_ID = 1;
    private static final Integer EXPECTED_LBOX_OVERRIDE_LIMIT_VALUE = 1;
    private static final Integer SECOND_EXPECTED_LBOX_OVERRIDE_LIMIT_ID = 2;
    private static final Integer SECOND_EXPECTED_LBOX_OVERRIDE_LIMIT_VALUE = 2;

    static SWNUpdateLicenseLimitsRunner generateTestData() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType),
                Account.Billing_Id__c => BILLING_ID
            })
            .build()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Id => ValueProviderBuilder.provideDummyId(Opportunity.sObjectType),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .build()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => new ValueProvider.DummyIdProvider(Quote.sObjectType),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC
            })
            .build()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.newQuantity__c => 10,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI_WITH_LBOX
            })
            .quantity(2)
            .build()
            .getRecords();

        List<Entitlement__c> ents = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.sObjectType)
            .setField(Entitlement__c.PackageOfferType__c, QuoteHelper.PACKAGE_OFFER_TYPE_POC)
            .quantity(2)
            .build()
            .getRecords();

        List<Product2> prods = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.Family => Product2Helper.FAMILY_SMS
            })
            .quantity(2)
            .build()
            .getRecords();

        for (Integer i = 0; i < qlis.size(); i++) {
            qlis[i].putSObject(QuoteLineItem.Product2Id, prods[i]);
            qlis[i].putSObject(QuoteLineItem.Entitlement__c, ents[i]);
        }

        qt = (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            'QuoteLineItems',
            qlis
        );

        qt = (Quote) Test_Utils.putIntoUnwritableFields(
            qt,
            Quote.class,
            new Map<String, Object> {
                'Account' => acc,
                'AccountId' => acc.Id,
                'Opportunity' => opp,
                'OpportunityId' => opp.Id
            }
        );

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.currentStep = SWNStep.buildUpdateLicenseLimitsStep();

        SWNUpdateLicenseLimitsRunner runner = new SWNUpdateLicenseLimitsRunner(qt.Id, SWNStep.UPDATE_LICENSE_LIMITS);
        runner.sdc = sdc;
        return runner;
    }

    @TestSetup
    static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://example.com',
                NGBS_Settings__c.AccountManagerPath__c => '/api/account-manager/v1.0',
                NGBS_Settings__c.Login__c => 'testLogin',
                NGBS_Settings__c.Password__c => 'testPassword'
            })
            .create();
    }

    @isTest
    static void testRunnerWithPOCQuote() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        SWNUpdateLicenseLimitsRunner runner = generateTestData();

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed successfully');
        Assert.areEqual(1, runner.res.messages.size(), 'Should have messages');
        Assert.areEqual(Label.License_limits_override_succeeded, runner.res.messages[0].message, 'Wrong success message');
    }

    @isTest
    static void testRunnerWithNonPOCQuote() {
        SWNUpdateLicenseLimitsRunner runner = generateTestData();
        List<QuoteLineItem> qlis = runner.sdc.qt.QuotelineItems;
        for (QuoteLineItem qli : qlis) {
           qli.Entitlement__r.PackageOfferType__c = QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL;
        }

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.areEqual(1, runner.res.messages.size(), 'Should have messages');
        Assert.areEqual(Label.License_limits_override_for_non_POC_account, runner.res.messages[0].message, 'Wrong error message');
    }

    @isTest
    static void testRunnerOverrideLimits() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        SWNUpdateLicenseLimitsRunner runner = generateTestData();
        List<QuoteLineItem> qlis = runner.sdc.qt.QuotelineItems;
        for (QuoteLineItem qli : qlis) {
            qli.PackageInfo__c = PACKAGE_INFO_QLI_WITH_LBOX.replace(LBO_MAX_LIMIT_VALUE, '10000');
        }

        Test.startTest();
            runner.run();
        Test.stopTest();

        Assert.isTrue(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should be completed successfully');
        Assert.areEqual(1, runner.res.messages.size(), 'Should have messages');
        Assert.areEqual(Label.License_limits_override_succeeded, runner.res.messages[0].message, 'Wrong success message');
    }

    @isTest
    private static void testGetLBoxOverrideList() {
        List<NGBSAPI.LBox> accountLBoxList = new List<NGBSAPI.LBox>();
        Map<String,List<NGBSAPI.LBoxLimitBrief>> lBoxElementIdToLBoxLimitBriefList =
            new Map<String,List<NGBSAPI.LBoxLimitBrief>>();

        for (Integer i = 0; i < 3; i ++) {
            String catalogIdKey = 'testCatalogId' + i;
            /* Account L-boxes limit */
            NGBSAPI.LBox accLbox = new NGBSAPI.LBox();
            accLbox.id = i;
            accLbox.description = 'L-box description' + i;
            acclBox.lboxCatalogId = catalogIdKey;
            acclBox.lboxLimits = new List<NGBSAPI.LBoxLimit>();
            acclBox.lboxItems = new List<NGBSAPI.LBoxItem>();
            accountLBoxList.add(accLbox);
            /* QuoteLineItem L-boxes limit */
            NGBSAPI.LBoxLimitBrief limitBrief = new NGBSAPI.LBoxLimitBrief(SWNHelper.MAX, i);
            lBoxElementIdToLBoxLimitBriefList.put(catalogIdKey, new List<NGBSAPI.LBoxLimitBrief>{limitBrief});
        }

        Test.startTest();
            List<NGBSAPI.LBoxLimitOverride> lBoxLimitOverrideList = new SWNUpdateLicenseLimitsRunner().getLBoxLimitOverrideList(
                accountLBoxList, lBoxElementIdToLBoxLimitBriefList
            );
        Test.stopTest();

        Assert.areEqual(2, lBoxLimitOverrideList.size(), 'Wrong items are choosen for license override action');

        Assert.areEqual(EXPECTED_LBOX_OVERRIDE_LIMIT_ID, lBoxLimitOverrideList[0].id, 'Id mismatch');
        Assert.areEqual(EXPECTED_LBOX_OVERRIDE_LIMIT_VALUE, lBoxLimitOverrideList[0].lboxLimits[0].value, 'Wrong lbox override value');
        Assert.areEqual('Max', lBoxLimitOverrideList[0].lboxLimits[0].type, 'Wrong lbox override type');

        Assert.areEqual(SECOND_EXPECTED_LBOX_OVERRIDE_LIMIT_ID, lBoxLimitOverrideList[1].id, 'Id mismatch');
        Assert.areEqual(SECOND_EXPECTED_LBOX_OVERRIDE_LIMIT_VALUE, lBoxLimitOverrideList[1].lboxLimits[0].value, 'Wrong lbox override value');
        Assert.areEqual('Max', lBoxLimitOverrideList[1].lboxLimits[0].type, 'Wrong lbox override type');
    }

    @isTest
    private static void testGetLBoxesAccountLimits () {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Test.startTest();
            List<NGBSAPI.LBox> lboxesLimits = new SWNUpdateLicenseLimitsRunner().getAccountLBoxesLimits('12345', '54321');
        Test.stopTest();

        Assert.areEqual(1, lboxesLimits.size());
    }

    @isTest
    private static void testGetMaxQliLBoxLimitValue() {
        NGBSAPI.LBoxLimitBrief minLboxLimitBrief = new NGBSAPI.LBoxLimitBrief('MIN', 0);
        NGBSAPI.LBoxLimitBrief maxLboxLimitBrief = new NGBSAPI.LBoxLimitBrief('MAX', 10);

        Test.startTest();
            Integer maxValue =
                new SWNUpdateLicenseLimitsRunner().getMaxQliLBoxLimitValue(
                    new List<NGBSAPI.LBoxLimitBrief> {minLboxLimitBrief, maxLboxLimitBrief}
                );
        Test.stopTest();

        Assert.areEqual(10, maxValue, 'Incorrect lBox was found');
    }

    @isTest
    private static void testGetMaxAccountLBoxLimitValue() {
        NGBSAPI.LBoxLimit minLboxLimit = new NGBSAPI.LBoxLimit('MIN', 0, true);
        NGBSAPI.LBoxLimit maxLboxLimit = new NGBSAPI.LBoxLimit('MAX', 10, true);

        Test.startTest();
            Integer maxValue =
                new SWNUpdateLicenseLimitsRunner().getMaxAccountLBoxLimitValue(
                    new List<NGBSAPI.LBoxLimit> {
                        minLboxLimit, maxLboxLimit
                    });
        Test.stopTest();

        Assert.areEqual(10, maxValue, 'Incorrect lBox was found');
    }
}