@isTest
private class Test_SWNSyncContractRunner {
    private static final String BILLING_ID = (String) ValueProviderBuilder.provideUniqueString().getValue();
    private static final String OPP_NAME = 'opp name';
    private static final String PACKAGE_PARAMS_GET_RESPONSE = '[{"id":1,"name":"StatementFormatVersion","value":2},{"id":2,"name":"VirtualTimeCycleShift","value":0},{"id":3,"name":"EnableUpgradeOnContract","value":0},{"id":4,"name":"SkipCreditCardAddressVerification","value":0},{"id":5,"name":"ForceMRSDetailsPush","value":0}]';
    private static final String PACKAGE_PARAMS_PUT_RESPONSE = '[{"id":3,"name":"EnableUpgradeOnContract","value":-1}]';
    private static final String CONTRACT_RESPONSE = '{"id":3,"extId":"123"}';
    private static final String PACKAGE_ID = '12345';
    private static final String PRODUCT_DIGITALLINE_UNLIMITED = 'DigitalLine Unlimited';
    private static final String LC_DL_UNL_50 = 'LC_DL-UNL_50';
    private static final String PACKAGE_INFO_QT = '[{"packageInfo":{"id":' + PACKAGE_ID + '},"contract":{"extId":"Office","billingId":' + BILLING_ID + ',"status":"test"}}]';
    private static final String PACKAGE_INFO_QLI = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"DL","discount":{"type":"Percent","value":"3.48"},"price":"40"}';

    private static Quote queryQuote(String oppName) {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .selectField('Opportunity.isContractsSynced__c')
            .executeQuery()
        ).getFirst();
    }

    private static Quote buildQuoteWithPkgInfo(String pkgInfo) {
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, pkgInfo)
            .build()
            .getRecord();
    }

    @testSetup
    private static void makeData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://fake-billing-api',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.Login__c => 'login',
                NGBS_Settings__c.Password__c => 'password'
            })
            .create();

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_FSC_for_Existing_Customers__c, true)
            .create();

        Triggers.switchOff();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => BILLING_ID,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, billingAcc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => OPP_NAME,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();


        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.BillingPackage__c => pkg.Id,
                Quote.IsPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_QT,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.Credit_Amount__c => 42
            })
            .create()
            .getRecord();

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => PRODUCT_DIGITALLINE_UNLIMITED,
                Product2.ExtId__c => LC_DL_UNL_50,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Entitlement__c entDigitalLineUnlimited = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'ent name',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => productDigitalLineUnlimited.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => entDigitalLineUnlimited.Id,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .create();
        Triggers.switchOn();
    }

    @isTest
    private static void testRun() {
        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO_QT);

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.isContractsSynced__c => true,
                Opportunity.isFSCSynced__c => true
            })
            .build()
            .getRecord();

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.qt = qt;
        sdc.currentStep = SWNStep.buildContractSyncStep();

        Test.startTest();
            SWNSyncContractRunner runner = new SWNSyncContractRunner(qt.Id, SWNStep.CONTRACT_SYNC);
            runner.sdc = sdc;
            runner.run();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, runner.res.status, 'Status should be success');
        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_HEADER, runner.res.messages[0].message, 'Contract should be already synced');
        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_MSG, runner.res.messages[0].messageDetails, 'Contract for this quote should be already synced');
    }

    @isTest
    private static void testProcessContractSynced() {
        final String packageInfo = '[{"contract":{"extId":"Office"}}]';
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.isContractsSynced__c, true)
            .build()
            .getRecord();

        Quote qt = buildQuoteWithPkgInfo(packageInfo);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.qt = qt;

        Test.startTest();
            SWNMessageHelper.CompositeResult result = new SWNSyncContractRunner().processContract_new(sdc);
        Test.stopTest();

        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_HEADER, result.baseMessage.header, 'Contract already synced header');
        Assert.areEqual(SWNMessageHelper.CONTRACT_SYNCED_MSG, result.baseMessage.message, 'Contracts for this quote were already synced message');
    }

    @isTest
    private static void testProcessContractSuccessCreate() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/contract', 'Completed', CONTRACT_RESPONSE, 200, HttpHelper.METHOD_PUT)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        SWNDataCollector sdc = new SWNDataCollector();
        Quote qt = queryQuote(OPP_NAME);
        qt.Package_Info__c = PACKAGE_INFO_QT.replace(BILLING_ID, 'null');
        sdc.qt = qt;

        sdc.billingId = BILLING_ID;
        sdc.packageId = PACKAGE_ID;

        Test.startTest();
            SWNMessageHelper.CompositeResult result = new SWNSyncContractRunner().processContract_new(sdc);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, result.baseMessage.status, 'Status success');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_HEADER, result.baseMessage.header, 'Contract should be synced');
        Assert.areEqual(SWNHelper.CONTRACT_STATUS_NEW, result.data.get(SWNSyncContractRunner.CONTRACT_STATUS), 'Contract status should be New');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_MSG, result.baseMessage.message, 'Contract should be synced');
        Assert.isFalse(result.data.isEmpty(), 'Response should not be empty');
    }

    @isTest
    private static void testProcessContractSuccessUpdate() {
        // Mock for GET contracts endpoint - returns a contract with the same ID as BILLING_ID
        String contractsResponse = '[{"id":' + BILLING_ID + ',"packages":[{"packageId":"' + PACKAGE_ID + '"}],"startBillingCycleNumber":1,"startDate":"2019-07-26","term":12,"renewalTerm":12,"autoRenewal":true}]';
        
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/contract', 'Completed', contractsResponse, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo('/contract/' + BILLING_ID, 'Completed', CONTRACT_RESPONSE, 200, HttpHelper.METHOD_PUT)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = queryQuote(OPP_NAME);

        sdc.billingId = BILLING_ID;
        sdc.packageId = PACKAGE_ID;

        Test.startTest();
            SWNMessageHelper.CompositeResult result = new SWNSyncContractRunner().processContract_new(sdc);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, result.baseMessage.status, 'Status success');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_HEADER, result.baseMessage.header, 'Contract should be synced');
        Assert.areEqual(SWNMessageHelper.SYNC_CONTRACT_MSG, result.baseMessage.message, 'Contract should be synced');
        Assert.areEqual(SWNHelper.CONTRACT_STATUS_UPDATED, result.data.get(SWNSyncContractRunner.CONTRACT_STATUS), 'Contract status should be Updated');
        Assert.isFalse(result.data.isEmpty(), 'Response should not be empty');
    }

    @isTest
    private static void testHandleFSCError() {
        SWNMessageHelper.CompositeResult result = new SWNMessageHelper.CompositeResult();
        result.baseMessage.status = Response.STATUS_ERROR;

        Test.startTest();
            SWNSyncContractRunner runner = new SWNSyncContractRunner();
            runner.sdc = new SWNDataCollector();
            runner.sdc.currentStep = SWNStep.buildContractSyncStep();
            runner.handleFSC(result);
        Test.stopTest();

        Assert.isFalse(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should not be completed');
    }

    @isTest
    private static void testHandleFSC() {
        final String packageInfo = '[{"contract":{"extId":"Office","billingId":"test", "status":"test"}}]';

        SWNMessageHelper.CompositeResult result = new SWNMessageHelper.CompositeResult();
        result.baseMessage.status = Response.STATUS_SUCCESS;
        result.addData(SWNSyncContractRunner.BILLING_ID, 'test');
        result.addData(SWNSyncContractRunner.CONTRACT_STATUS, 'test');

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.isFSCSynced__c, true)
            .build()
            .getRecord();

        Quote qt = buildQuoteWithPkgInfo(packageInfo);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.qt = qt;

        Test.startTest();
            SWNSyncContractRunner runner = new SWNSyncContractRunner();
            runner.sdc = sdc;
            runner.sdc.currentStep = SWNStep.buildContractSyncStep();
            runner.handleFSC(result);
        Test.stopTest();

        Boolean isQuoteUpdated = (Boolean) runner.res.data.get('isQuoteUpdated');
        Assert.isNotNull(runner.res.data.get('qt'), 'Quote should exist in data');
        Assert.isTrue(isQuoteUpdated, 'Quote should be updated');
    }

    @isTest
    private static void testProcessFSCIfSynced() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.isFSCSynced__c, true)
            .build()
            .getRecord();

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);

        Test.startTest();
            Response result = new SWNSyncContractRunner().processFSC(sdc);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Should return success status');
    }

    @isTest
    private static void testProcessFSCError() {
        Opportunity opp = new Opportunity();
        Quote qt = new Quote();

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.opp = opp;
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.billingId = BILLING_ID;
        sdc.packageId = PACKAGE_ID;

        Test.startTest();
            Response result = new SWNSyncContractRunner().processFSC(sdc);
        Test.stopTest();

        Assert.isTrue(result.isError(), 'Should return error status');
        assert.isFalse(BooleanHelper.toBoolean(sdc.syncable.getSObjFieldsToUpdate().get(Opportunity.isFSCSynced__c)), 'Should be marked as not synced');
    }

    @isTest
    private static void testProcessFSCCrossProduct() {
        SettingsHelper.FEATURE_TOGGLE.Enable_FSC_for_Existing_Customers__c = false;
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/parameters', 'Completed', PACKAGE_PARAMS_GET_RESPONSE, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo(PACKAGE_ID + '/parameters', 'Completed', '', 200, HttpHelper.METHOD_PUT),
            new BillingHttpRequestMock.MockInfo('/contract', 'Completed', '', 200, HttpHelper.METHOD_PUT)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.productName = 'Office';
        pInfo.packageInfo = new BillingWrappers.PackageInfo();
        pInfo.existingPackageInfo = new BillingWrappers.ExistingPackageInfo();
        pInfo.existingPackageInfo.productName = 'Fax';

        Opportunity opp = new Opportunity();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo> {pInfo}),
                Quote.Initial_Term_months__c => '1',
                Quote.Start_Date__c => System.today()
            })
            .build()
            .getRecord();

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = qt;
        sdc.opp = opp;
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.billingId = BILLING_ID;
        BillingWrappers.NGBSAccountPackage ngbsPkg = new BillingWrappers.NGBSAccountPackage();
        ngbsPkg.id = PACKAGE_ID;
        sdc.ngbsPackage = ngbsPkg;

        Test.startTest();
            Response result = new SWNSyncContractRunner().processFSC(sdc);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Should return success status');
        Assert.isTrue(BooleanHelper.toBoolean(sdc.syncable.getSObjFieldsToUpdate().get(Opportunity.isFSCSynced__c)), 'Should be marked as synced');
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsSuccessful() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            Decimal result = new SWNSyncContractRunner().updateFreeServiceCredit('123', '456', 100);
        Test.stopTest();

        Assert.areEqual(300, result, 'Updated amount should be 300');
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsNotRequiredOnEmptyFSC() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            Decimal result = new SWNSyncContractRunner().updateFreeServiceCredit('123', '456', null);
        Test.stopTest();

        Assert.areEqual(200, result, 'updated amount should be 200');
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsNotUpdatedWithoutFT() {
        SettingsHelper.FEATURE_TOGGLE.Enable_FSC_for_Existing_Customers__c = false;

        Test.startTest();
            Decimal result = new SWNSyncContractRunner().updateFreeServiceCredit('123', '456', 100);
        Test.stopTest();

        Assert.areEqual(0, result, 'updated amount should be 0');
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsFailedWithoutBillingId() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            try {
                new SWNSyncContractRunner().updateFreeServiceCredit('', '456', 100);
                Assert.fail('An error should be thrown');
            } catch (Exception ex) {
                Assert.areEqual(SWNSyncContractRunner.REQUIRED_PARAMS_IS_MISSING_ERROR, ex.getMessage(), 'should have thrown error without billingId');
            }
        Test.stopTest();
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsFailedWithoutPackageId() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);

        Test.startTest();
            try {
                new SWNSyncContractRunner().updateFreeServiceCredit('123', '', 100);
                Assert.fail('An error should be thrown');
            } catch (Exception ex) {
                Assert.areEqual(SWNSyncContractRunner.REQUIRED_PARAMS_IS_MISSING_ERROR, ex.getMessage(), 'should have thrown error without packageId');
            }
        Test.stopTest();
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsFailedWithoutOnIncorrectResponse() {
        Test.startTest();
            try {
                new SWNSyncContractRunner().updateFreeServiceCredit('123', '456', 100);
                Assert.fail('An error should be thrown');
            } catch (Exception ex) {
                Assert.areEqual(NGBSAPI.REQUEST_FSC_EXCEPTION_MESSAGE, ex.getMessage(), 'should have thrown on incorrect FSC response');
            }
        Test.stopTest();
    }

    @isTest
    private static void testFreeServiceCreditUpdateOnPackageIsSuccessfulOnEmptyResponse() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/freeServiceCredit', 'No Content', '{"amount": 0}', 204, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Decimal result = new SWNSyncContractRunner().updateFreeServiceCredit('123', '456', 100);
        Test.stopTest();

        Assert.areEqual(100, result, 'Updated amount should be 100');
    }

    @isTest
    private static void testUpdateContractInfoWTBillingId() {
        Test.startTest();
            String contractInfo = new SWNSyncContractRunner().updateContractInfo(new Quote(), null, null);
        Test.stopTest();

        Assert.isTrue(String.isBlank(contractInfo), 'Contract info should be null');
    }

    @isTest
    private static void testUpdateContractInfo() {
        final String contractBillingId = '1234';
        final String contractStatus = 'contractStatus';

        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO_QT);

        Test.startTest();
            String contractInfo = new SWNSyncContractRunner().updateContractInfo(qt, contractBillingId, contractStatus);
        Test.stopTest();

        Assert.isTrue(String.isNotBlank(contractInfo), 'Contract info should be updated');
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfoWrapper(contractInfo).getPackageInfo();
        Assert.areEqual(contractStatus, pInfo.contract.status, 'Status should be changed');
        Assert.areEqual(contractBillingId, pInfo.contract.billingId, 'BillingId should be changed');
    }

    @isTest
    private static void testGetEntitlementsForPOCWTPackage() {
        final String ngbsAccResponse = '{"id":"1","packages":[]}';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/summary?shortView=true', 'Completed', ngbsAccResponse, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            Map<String, Integer> ents = new SWNSyncContractRunner().getEntitlementsForPOC(BILLING_ID, new Quote());
        Test.stopTest();

        Assert.isTrue(ents.isEmpty(), 'There should not be any entitlements');
    }

    @isTest
    private static void testGetEntitlementsForPOC() {
        final String ngbsAccResponse = '{"id":"1","packages":[{"catalogId":"12345","version":"1","offerType":"Regular","id":' + PACKAGE_ID + '}]}';
        final String licensesResponse = '[{"catalogId":"LC_DL_75","qty":"5"},{"catalogId":"LC_DL-UNL_50","qty":"5"}]';
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/summary?shortView=true', 'Completed', ngbsAccResponse, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo('/billinginfo/summary/license', 'Completed', licensesResponse, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Quote qt = buildQuoteWithPkgInfo(PACKAGE_INFO_QT);

        Test.startTest();
            Map<String, Integer> ents = new SWNSyncContractRunner().getEntitlementsForPOC(BILLING_ID, qt);
        Test.stopTest();

        Assert.isFalse(ents.isEmpty(), 'There should be 2 licenses');
        Assert.areEqual(2, ents.size(), 'There should be 2 licenses');
    }

    @isTest
    private static void testIsQuantityChangedForPOC() {
        final String productExtId = 'test ExtID__c';
        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Family => ValueProviderBuilder.provideList(new List<String> {Product2Helper.FAMILY_TAXES, Product2Helper.FAMILY_TIER}),
                Product2.ExtID__c => productExtId
            })
            .quantity(2)
            .build()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.NewQuantity__c, 10)
            .quantity(2)
            .build()
            .getRecords();

        for (Integer i = 0; i < qlis.size(); i++) {
            qlis[i] = (QuoteLineItem) Test_Utils.putIntoUnwritableFields(
                qlis[i],
                QuoteLineItem.class,
                new Map<String, Object> {
                    'Product2' => products[i]
                }
            );
        }

        Map<String, Integer> extIdToAmountMap = new Map<String, Integer> {
            productExtId => 5
        };

        Test.startTest();
            Boolean isQuantityChangedForPOC = new SWNSyncContractRunner().isQuantityChangedForPOC(qlis, extIdToAmountMap);
        Test.stopTest();

        Assert.isTrue(isQuantityChangedForPOC, 'Quantity should be changed');
    }
}