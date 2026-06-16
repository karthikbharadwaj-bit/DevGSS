@IsTest
public class Test_POWrappers {
    static final String TEST_PAYMENT_TERMS = 'testPaymentTerms';
    static final String TEST_INVOICE_TERMS = 'testInvoiceTerms';
    static final String TEST_ELEMENT_ID = 'E123';
    static final String KEY_OPPORTUNITY = 'opportunity';
    static final String KEY_QUOTES = 'quotes';
    static final String KEY_PRIMARY_QUOTE = 'primaryQuote';
    static final String KEY_TARGET_QUOTE = 'targetQuote';
    static final String KEY_CC_QUOTE = 'ccQuote';
    static final String KEY_POC_QUOTE = 'pocQuote';
    static final String KEY_PS_QUOTE = 'psQuote';
    static final String KEY_MASTER_ACC = 'masterAcc';
    static final String KEY_BOUND_ACCS = 'boundAccs';
    static final String KEY_PAYMENT_METHOD = 'paymentMethod';
    static final String KEY_APPROVALS = 'approvals';
    static final String KEY_ACC_RELATIONS = 'accRelations';
    static final String KEY_AREA_CODE_LINE_ITEMS = 'areaCodeLineItems';
    static final String KEY_AREA_CODES = 'areaCodes';
    static final String KEY_ASSIGNMENT_LINE_ITEM = 'assignementLineItem';
    static final String KEY_CONTACT = 'contact';
    static final String KEY_USER = 'user';
    static final String KEY_ASSIGNMENTS_TO_SIGN_UP = 'assignmentsToSignUp';
    static final String KEY_ASSIGNMENTS_TO_MANUAL = 'assignmentsToManual';
    static final String KEY_PROMOTIONS = 'promotions';
    static final String KEY_IS_EXISTING_BUSINESS = 'isExistingBusiness';
    static final String KEY_IS_MULTI_PRODUCT_FT_ENABLED = 'isMultiProductFTEnabled';
    static final String KEY_NGBS_ACCOUNT_STATUS = 'ngbsAccountStatus';
    static final String KEY_UBRAND_ID = 'uBrandId';
    static final String KEY_TIMEZONE_ID = 'timezoneId';
    static final String KEY_IS_PRO_SERV_QUOTES_NOT_CANCELLED = 'isProServQuotesNotCancelled';


    @IsTest
    static void testApprovedPackageLimitsConstructorWithParams() {
        Decimal monthlyCreditLimit = 1000.00;
        Decimal signUpPurchaseLimit = 500.00;
        String paymentTerms = TEST_PAYMENT_TERMS;
        String invoiceTerms = TEST_INVOICE_TERMS;

        Test.startTest();
            POWrappers.ApprovedPackageLimits apl = new POWrappers.ApprovedPackageLimits(monthlyCreditLimit, signUpPurchaseLimit, paymentTerms, invoiceTerms);
        Test.stopTest();

        Assert.areEqual(monthlyCreditLimit, apl.MonthlyCreditLimitC, 'MonthlyCreditLimitC does not match');
        Assert.areEqual(signUpPurchaseLimit, apl.SignUpPurchaseLimitC, 'SignUpPurchaseLimitC does not match');
        Assert.areEqual(paymentTerms, apl.PaymentTermsC, 'PaymentTermsC does not match');
        Assert.areEqual(invoiceTerms, apl.InvoiceTermsC, 'InvoiceTermsC does not match');
    }

    @IsTest
    static void testApprovedPackageLimitsSetMonthlyCreditLimit() {
        POWrappers.ApprovedPackageLimits apl = new POWrappers.ApprovedPackageLimits();
        Decimal newMonthlyCreditLimit = 2000.00;

        Test.startTest();
            apl.setMonthlyCreditLimit(newMonthlyCreditLimit);
        Test.stopTest();

        Assert.areEqual(newMonthlyCreditLimit, apl.MonthlyCreditLimitC, 'MonthlyCreditLimitC was not set correctly');
    }

    @IsTest
    static void testApprovedPackageLimitsSetSignUpPurchaseLimit() {
        POWrappers.ApprovedPackageLimits apl = new POWrappers.ApprovedPackageLimits();
        Decimal newSignUpPurchaseLimit = 750.00;

        Test.startTest();
            apl.setSignUpPurchaseLimit(newSignUpPurchaseLimit);
        Test.stopTest();

        Assert.areEqual(newSignUpPurchaseLimit, apl.SignUpPurchaseLimitC, 'SignUpPurchaseLimitC was not set correctly');
    }

    @IsTest
    static void testApprovedPackageLimitsSetPaymentTerms() {
        POWrappers.ApprovedPackageLimits apl = new POWrappers.ApprovedPackageLimits();
        String newPaymentTerms = TEST_PAYMENT_TERMS;

        Test.startTest();
            apl.setPaymentTerms(newPaymentTerms);
        Test.stopTest();

        Assert.areEqual(newPaymentTerms, apl.PaymentTermsC, 'PaymentTermsC was not set correctly');
    }

    @IsTest
    static void testApprovedPackageLimitsSetInvoiceTerms() {
        POWrappers.ApprovedPackageLimits apl = new POWrappers.ApprovedPackageLimits();
        String newInvoiceTerms = TEST_INVOICE_TERMS;

        Test.startTest();
            apl.setInvoiceTerms(newInvoiceTerms);
        Test.stopTest();

        Assert.areEqual(newInvoiceTerms, apl.InvoiceTermsC, 'InvoiceTermsC was not set correctly');
    }

    @IsTest
    static void testSignUpRequestBodyConstructorWithParams() {
        Map<String, Object> requestBodyMap = new Map<String, Object> {
            'email' => 'test@example.com',
            'password' => 'securePassword123'
        };

        Test.startTest();
            POWrappers.SignUpRequestBody body = new POWrappers.SignUpRequestBody(requestBodyMap);
        Test.stopTest();

        Assert.areEqual(requestBodyMap, body.requestBodyMap, 'Constructor with parameters did not set requestBodyMap correctly.');
    }

    @IsTest
    static void testSignUpRequestBodyEmptyConstructor() {
        Test.startTest();
            POWrappers.SignUpRequestBody body = new POWrappers.SignUpRequestBody();
        Test.stopTest();

        Assert.isNull(body.requestBodyMap, 'Empty constructor should not initialize requestBodyMap.');
    }

    @IsTest
    static void testLboxOverridesRequestConstructor() {
        String expectedCatalogId = '12345';
        Integer expectedMin = 1;
        Integer expectedMax = 10;

        Test.startTest();
            POWrappers.LboxOverridesRequest request = new POWrappers.LboxOverridesRequest(expectedCatalogId, expectedMin, expectedMax);
        Test.stopTest();

        Assert.areEqual(expectedCatalogId, request.catalogId, 'CatalogId does not match the expected value.');
        Assert.areEqual(expectedMin, request.min, 'Min does not match the expected value.');
        Assert.areEqual(expectedMax, request.max, 'Max does not match the expected value.');
    }

    @IsTest
    static void testLBDataConstructor() {
        BillingWrappers.LBox testLBox = new BillingWrappers.LBox();

        testLBox.elementID = TEST_ELEMENT_ID;
        testLBox.min = 1;
        testLBox.max = 5;

        Test.startTest();
            POWrappers.LBData lbData = new POWrappers.LBData(testLBox);
        Test.stopTest();

        Assert.areEqual(0, lbData.qty, 'Initial quantity should be 0.');
        Assert.areEqual(TEST_ELEMENT_ID, lbData.lboxOR.catalogId, 'CatalogId does not match.');
        Assert.areEqual(1, lbData.lboxOR.min, 'Min value does not match.');
        Assert.areEqual(5, lbData.lboxOR.max, 'Max value does not match.');
    }

    @IsTest
    static void testLBDataAddMethod() {
        BillingWrappers.LBox testLBox = new BillingWrappers.LBox();
        testLBox.elementID = TEST_ELEMENT_ID;
        testLBox.min = 1;
        testLBox.max = 5;
        POWrappers.LBData lbData = new POWrappers.LBData(testLBox);

        Test.startTest();
            lbData.add(3);
        Test.stopTest();

        Assert.areEqual(3, lbData.qty, 'Quantity after addition should be 3.');
    }

    @IsTest
    static void testGetLboxOverridesRequest() {
        BillingWrappers.LBox testLBox = new BillingWrappers.LBox(TEST_ELEMENT_ID, 1, 5);
        POWrappers.LBData lbData = new POWrappers.LBData(testLBox);
        lbData.add(6);

        Test.startTest();
            POWrappers.LboxOverridesRequest lboxOR = lbData.getLboxOverridesRequest();
        Test.stopTest();

        Assert.areEqual(6, lbData.qty, 'Quantity after addition should be 6.');
        Assert.areEqual(6, lboxOR.max, 'Max value in LboxOverridesRequest should be adjusted to 6.');
    }

    @IsTest
    static void testOppDetailWrapper() {
        Test.startTest();
            POWrappers.OppDetailWrapper oppDetail = new POWrappers.OppDetailWrapper();
            oppDetail.opportunity = new Opportunity(Name = 'Test Opportunity');
            oppDetail.isMultiProductFTEnabled = true;
            oppDetail.isMPUB = false;
            oppDetail.masterAndTechQuotes = new List<Quote> { new Quote(Name = 'Test Quote') };
            oppDetail.ngbsAccountStatus = 'Active';
            oppDetail.message = 'Test Message';
            oppDetail.productNameToPackageIsActiveStatusMap = new Map<String, Boolean> { 'Product1' => true };
            oppDetail.qtIdToSyncInfoMap = new Map<Id, POWrappers.SyncableWrapper>();
        Test.stopTest();

        Assert.areEqual('Test Opportunity', oppDetail.opportunity.Name, 'Opportunity name should be "Test Opportunity".');
        Assert.isTrue(oppDetail.isMultiProductFTEnabled, 'isMultiProductFTEnabled should be true.');
        Assert.isFalse(oppDetail.isMPUB, 'isMPUB should be false.');
        Assert.areEqual('Test Quote', oppDetail.masterAndTechQuotes[0].Name, 'Quote name should be "Test Quote".');
        Assert.areEqual('Active', oppDetail.ngbsAccountStatus, 'NGBS account status should be "Active".');
        Assert.areEqual('Test Message', oppDetail.message, 'Message should be "Test Message".');
        Assert.isTrue(oppDetail.productNameToPackageIsActiveStatusMap.get('Product1'), 'Product1 should be active in the package.');
    }

    @IsTest
    static void testSyncableWrapper() {
        Test.startTest();
            POWrappers.SyncableWrapper syncable = new POWrappers.SyncableWrapper();
            syncable.syncInfo = 'Test Sync Info';
            syncable.isSyncedToICB = true;
            syncable.isICBProvisioningComplete = false;
        Test.stopTest();

        Assert.areEqual('Test Sync Info', syncable.syncInfo, 'Sync info should be "Test Sync Info".');
        Assert.isTrue(syncable.isSyncedToICB, 'Syncable should be synced to ICB.');
        Assert.isFalse(syncable.isICBProvisioningComplete, 'ICB provisioning should not be complete.');
    }

    @IsTest
    static void testActionRequestParams() {
        String targetId = (String) new ValueProvider.DummyIdProvider(Quote.SObjectType).getValue();
        Test.startTest();
            POWrappers.ActionRequestParams actionParams = new POWrappers.ActionRequestParams();
            actionParams.action = POWrappers.SIGNUP_ACTION.SIGNUP;
            actionParams.targetIds = new List<String> { targetId};
            actionParams.data = new POWrappers.SignUpParams();
            actionParams.dataArr = new POWrappers.SignUpParams[]{ new POWrappers.SignUpParams() };
        Test.stopTest();

        Assert.areEqual(POWrappers.SIGNUP_ACTION.SIGNUP, actionParams.action, 'Action should be SIGNUP.');
        Assert.areEqual(targetId, actionParams.targetIds[0], 'Wrong targetId.');
    }

    @IsTest
    static void testSignUpParams() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, ValueProviderBuilder.provideList(
                new List<String> {
                    'primaryQuote',
                    'targetQuote',
                    'ccQuote',
                    'pocQuote',
                    'psQuote'
                }
            ))
            .quantity(5)
            .build()
            .getRecords();
        List<Account> accs = new List<Account> { new Account(Name = 'Master Acc') };
        Map<String, Object> signUpParamsMap = new Map<String, Object> {
            KEY_OPPORTUNITY => new Opportunity(),
            KEY_QUOTES => quotes,
            KEY_PRIMARY_QUOTE => quotes[0],
            KEY_TARGET_QUOTE => quotes[1],
            KEY_CC_QUOTE => quotes[2],
            KEY_POC_QUOTE => quotes[3],
            KEY_PS_QUOTE => quotes[4],
            KEY_MASTER_ACC => accs[0],
            KEY_BOUND_ACCS => accs,
            KEY_PAYMENT_METHOD => POWrappers.PAYMENT_METHOD_INV_FUNNEL,
            KEY_APPROVALS => new List<Approval__c>(),
            KEY_ACC_RELATIONS => new List<AccountRelation__c>(),
            KEY_AREA_CODE_LINE_ITEMS => new List<Area_Code_Line_Item__c>(),
            KEY_AREA_CODES => new List<Area_Codes__c>(),
            KEY_ASSIGNMENT_LINE_ITEM => new List<AssignmentLineItem__c>(),
            KEY_CONTACT => new Contact(FirstName = 'Test Contact'),
            KEY_USER => new User(FirstName = 'Test Name'),
            KEY_ASSIGNMENTS_TO_SIGN_UP => new List<SubscriberInfoBuilder.AssignmentData>(),
            KEY_ASSIGNMENTS_TO_MANUAL => new List<SubscriberInfoBuilder.AssignmentData>(),
            KEY_PROMOTIONS => new List<Promotion__c>(),
            KEY_IS_EXISTING_BUSINESS => false,
            KEY_IS_MULTI_PRODUCT_FT_ENABLED => false,
            KEY_NGBS_ACCOUNT_STATUS => 'Active',
            KEY_UBRAND_ID => '12345',
            KEY_TIMEZONE_ID => 'America/New_York',
            KEY_IS_PRO_SERV_QUOTES_NOT_CANCELLED => false
        };
        Test.startTest();
            POWrappers.SignUpParams signUpParams = (POWrappers.SignUpParams) JSON.deserialize(
                JSON.serialize(signUpParamsMap),
                POWrappers.SignUpParams.class
            );
        Test.stopTest();

        Map<String, Object> signUpParamsResultMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(signUpParams));
        Assert.areEqual(signUpParamsMap.size(), signUpParamsResultMap.size(), 'Sizes of the maps should be the same.');
        Assert.areEqual((Opportunity) signUpParamsMap.get(KEY_OPPORTUNITY), signUpParams.opportunity, 'Opportunity should be the same.');
        Assert.areEqual((List<Quote>) signUpParamsMap.get(KEY_QUOTES), signUpParams.quotes, 'Quotes should be the same.');
        Assert.areEqual((Quote) signUpParamsMap.get(KEY_PRIMARY_QUOTE), signUpParams.primaryQuote, 'primaryQuote should be the same.');
        Assert.areEqual((Quote) signUpParamsMap.get(KEY_TARGET_QUOTE), signUpParams.targetQuote, 'targetQuote should be the same.');
        Assert.areEqual((Quote) signUpParamsMap.get(KEY_CC_QUOTE), signUpParams.ccQuote, 'ccQuote should be the same.');
        Assert.areEqual((Quote) signUpParamsMap.get(KEY_POC_QUOTE), signUpParams.pocQuote, 'pocQuote should be the same.');
        Assert.areEqual((Quote) signUpParamsMap.get(KEY_PS_QUOTE), signUpParams.psQuote, 'psQuote should be the same.');
        Assert.areEqual((Account) signUpParamsMap.get(KEY_MASTER_ACC), signUpParams.masterAcc, 'masterAcc should be the same.');
        Assert.areEqual((List<Account>) signUpParamsMap.get(KEY_BOUND_ACCS), signUpParams.boundAccs, 'boundAccs should be the same.');
        Assert.areEqual((String) signUpParamsMap.get(KEY_PAYMENT_METHOD), signUpParams.paymentMethod, 'paymentMethod should be the same.');
        Assert.areEqual((List<Approval__c>) signUpParamsMap.get(KEY_APPROVALS), signUpParams.approvals, 'Approvals should be the same.');
        Assert.areEqual((List<AccountRelation__c>) signUpParamsMap.get(KEY_ACC_RELATIONS), signUpParams.accRelations, 'accRelations should be the same.');
        Assert.areEqual((List<Area_Code_Line_Item__c>) signUpParamsMap.get(KEY_AREA_CODE_LINE_ITEMS), signUpParams.areaCodeLineItems, 'areaCodeLineItems should be the same.');
        Assert.areEqual((List<Area_Codes__c>) signUpParamsMap.get(KEY_AREA_CODES), signUpParams.areaCodes, 'areaCodes should be the same.');
        Assert.areEqual((List<AssignmentLineItem__c>) signUpParamsMap.get(KEY_ASSIGNMENT_LINE_ITEM), signUpParams.assignementLineItem, 'assignementLineItem should be the same.');
        Assert.areEqual((Contact) signUpParamsMap.get(KEY_CONTACT), signUpParams.contact, 'Contact should be the same.');
        Assert.areEqual((User) signUpParamsMap.get(KEY_USER), signUpParams.user, 'User should be the same.');
        Assert.areEqual((List<SubscriberInfoBuilder.AssignmentData>) signUpParamsMap.get(KEY_ASSIGNMENTS_TO_SIGN_UP), signUpParams.assignmentsToSignUp, 'assignmentsToSignUp should be the same.');
        Assert.areEqual((List<SubscriberInfoBuilder.AssignmentData>) signUpParamsMap.get(KEY_ASSIGNMENTS_TO_MANUAL), signUpParams.assignmentsToManual, 'assignmentsToManual should be the same.');
        Assert.areEqual((List<Promotion__c>) signUpParamsMap.get(KEY_PROMOTIONS), signUpParams.promotions, 'Promotions should be the same.');
        Assert.areEqual((Boolean) signUpParamsMap.get(KEY_IS_EXISTING_BUSINESS), signUpParams.isExistingBusiness, 'isExistingBusiness should be the same.');
        Assert.areEqual((Boolean) signUpParamsMap.get(KEY_IS_MULTI_PRODUCT_FT_ENABLED), signUpParams.isMultiProductFTEnabled, 'isMultiProductFTEnabled should be the same.');
        Assert.areEqual((String) signUpParamsMap.get(KEY_NGBS_ACCOUNT_STATUS), signUpParams.ngbsAccountStatus, 'ngbsAccountStatus should be the same.');
        Assert.areEqual((String) signUpParamsMap.get(KEY_UBRAND_ID), signUpParams.uBrandId, 'uBrandId should be the same.');
        Assert.areEqual((String) signUpParamsMap.get(KEY_TIMEZONE_ID), signUpParams.timezoneId, 'timezoneId should be the same.');
        Assert.areEqual((Boolean) signUpParamsMap.get(KEY_IS_PRO_SERV_QUOTES_NOT_CANCELLED), signUpParams.isProServQuotesNotCancelled, 'isProServQuotesNotCancelled should be the same.');
    }

    @IsTest
    static void testSalesFunnelUIResponse() {
        Test.startTest();
            POWrappers.SalesFunnelUIResponse response = new POWrappers.SalesFunnelUIResponse();
            response.Status = 'Success';
            response.Message = 'Operation completed';
            response.RedirectUrl = 'http://example.com';
        Test.stopTest();

        Assert.areEqual('Success', response.Status, 'Status should be "Success".');
        Assert.areEqual('Operation completed', response.Message, 'Message should be "Operation completed".');
        Assert.areEqual('http://example.com', response.RedirectUrl, 'Redirect URL should be "http://example.com".');
    }

    @IsTest
    static void testSignUpFunnelUIRequestParamsEngage() {
        CCB_Settings__c ccbSettings = (CCB_Settings__c) new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.BaseEndpoint__c => 'base_endpoint',
                CCB_Settings__c.SignUpPath__c => '/signup_path',
                CCB_Settings__c.Login__c => '1',
                CCB_Settings__c.Password__c => '2'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .build()
            .getRecord();

        Test.startTest();
            POWrappers.SignUpFunnelUIRequestParams params = new POWrappers.SignUpFunnelUIRequestParams(qt);
        Test.stopTest();

        Assert.areEqual(HttpHelper.CONTENT_TYPE_APPLICATION_FORM, params.contentTypeValue, 'Content type should be "application/x-www-form-urlencoded" for Engage quotes.');
        Assert.areEqual(ccbSettings.BaseEndpoint__c + ccbSettings.SignUpPath__c, params.endpoint, 'Incorrect endpoint for Engage quotes.');
    }

    @IsTest
    static void testSignUpFunnelUIRequestParamsRCCC() {
        ICB_Settings__c icbSettings = (ICB_Settings__c) new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.BaseEndpoint__c => 'base_endpoint',
                ICB_Settings__c.APIVersion1Path__c => '/v1',
                ICB_Settings__c.SignUpPath__c => '/signup_path'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER
            })
            .build()
            .getRecord();

        Test.startTest();
            POWrappers.SignUpFunnelUIRequestParams params = new POWrappers.SignUpFunnelUIRequestParams(qt);
        Test.stopTest();

        Assert.areEqual(HttpHelper.CONTENT_TYPE_APPLICATION_JSON, params.contentTypeValue, 'Content type should be "application/json" for RCCC quotes.');
        Assert.areEqual(icbSettings.BaseEndpoint__c + icbSettings.APIVersion1Path__c + icbSettings.SignUpPath__c, params.endpoint, 'Incorrect endpoint for RCCC quotes.');
    }

    @IsTest
    static void testGWSignUpResponse() {
        Test.startTest();
            POWrappers.GWSignUpResponse response = new POWrappers.GWSignUpResponse();
            response.GWApiSId = 'API123';
            response.OppId = 'OPP123';
            response.SalesAgentId = 'AGENT123';
            response.Url = 'http://example.com';
        Test.stopTest();

        String expectedUrl = 'http://example.com?OPPID=OPP123&SALESAGENTID=AGENT123&GWAPISID=API123';
        Assert.areEqual(expectedUrl, response.generateUrl(), 'Generated URL should match the expected URL.');
    }
}