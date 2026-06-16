@isTest
public with sharing class Test_SignUpRequestBuilderManager {
    private static final String ASSERT_MSG_REQUEST_BODY_MAP_SHOULD_NOT_BE_NULL = 'Request body map should not be null';

    private static final String PACKAGE_INFO_ENGAGE = '[{"id":"19","version":"3","productName":"Engage Digital Standalone","productId":"7"}]';
    private static final String CONTRACT_INFO = '{"contractExtId":"pInfo.contract.extId","salesAgreement":"0Q0000000000000000"}';
    private static final String VALID_BUSINESS_IDENTITY = '{"currency":"USD","biId":4}';
    private static final String GET_PACKAGE_ENDPOINT = '/summary?withlboxes=false';

    private static final String INTERNAL_ENTERPRISE_ACCOUNT_ID = '12345';
    private static final String RC_USER_ID = INTERNAL_ENTERPRISE_ACCOUNT_ID + 'RC';
    private static final String MASTER_RC_USER_ID = 'master' + RC_USER_ID;
    private static final String PARTNER_ID = 'Partner123';
    private static final String PACKAGE_NAME = 'Test Package Name';
    private static final String PACKAGE_ID_FOR_ENGAGE = '19';
    private static final String PACKAGE_VERSION_FOR_ENGAGE = '3';
    private static final String DUMMY_CATALOG_ID = '2';
    private static final String MUST_THROW_AN_EXCEPTION = 'Must throw an exception';
    private static final String TEST_PAYMENT_METHOD_TYPE = 'testPaymentMethodType';
    private static final String TEST_CONTRACT_EXT_ID = 'testContractExtId';
    private static final String DUMMY_OFFER_TYPE = 'dummyOfferType';
    private static final String TEST_PACKAGE_LIMIT_CODE = 'testPackageLimitCode';
    private static final String TEST_CONTRACT_DESCRIPTION = 'Test Contract Description';
    private static final String INITIAL_TERM_MONTHS = '12';
    private static final String INITIAL_TERM_POC = '30';

    private static final Integer INITIAL_TERM_MONTHS_INTEGER = Integer.valueOf(INITIAL_TERM_MONTHS);
    private static final Decimal NGBS_PARTNER_ID = 12454563.0;
    private static final Decimal FREE_SERVICE_CREDIT_TOTAL = 95.0;
    private static final Decimal PARTNER_VERSION = 1.0;

    private static final Decimal MONTHLY_CREDIT_LIMIT = 500;
    private static final Decimal SIGN_UP_PURCHASE_LIMIT = 1000;
    private static final Decimal CUSTOM_SETTING_LIMIT = 10000;
    private static final String PAYMENT_TERMS = '12';
    private static final String INVOICE_TERMS = '24';
    private static final String OPP_NAME = 'OPP_NAME';

    private static final String DUMMY_VALUE = 'value1';
    private static final Map<String, Object> TEST_SIGNUP_PARAMETER = new Map<String, Object> {
        'key1' => DUMMY_VALUE,
        'key2' => DUMMY_VALUE
    };

    private class TestBuilder extends SignUpRequestBuilderManager.Builder {
        private Boolean isGetSignUpParameterCalled;
        private Map<String, Object> testRequestBodyMap;

        public TestBuilder() {
            super();
            this.isGetSignUpParameterCalled = false;
            this.testRequestBodyMap = TEST_SIGNUP_PARAMETER;
        }

        public override Map<String, Object> getSignUpParameter() {
            isGetSignUpParameterCalled = true;
            return this.testRequestBodyMap;
        }
    }

    @TestSetup
    static void setup() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi/',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => '123',
                NGBS_Settings__c.Password__c => '456'
            })
            .create();

            new SObjectBuilder(RCSequence__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RCSequence__c.SubSequence__c => 134,
                RCSequence__c.SandboxNumber__c => 4
            })
            .create();

            new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CountryCodes__c.CountryName__c => 'usa;united states;united states of america',
                CountryCodes__c.CountryNameFull__c => 'Uniter States of America',
                CountryCodes__c.Name => 'USA'
            })
            .create();
    }

    @isTest
    static void verifyBuilderForSingleProductEngageUBOff() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, false)
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => (Id) new ValueProvider.DummyIdProvider(Account.SObjectType).getValue(),
                Account.Internal_Enterprise_Account_ID__c => INTERNAL_ENTERPRISE_ACCOUNT_ID
            })
            .build()
            .getRecord();

        Opportunity testOpp = new Opportunity();
        testOpp.Account = testAccount;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE,
                Quote.IsMultiProductTechnicalQuote__c => false
            })
            .build()
            .getRecord();

        POWrappers.SignUpParams data = new POWrappers.SignUpParams();
        data.targetQuote = testQuote;
        data.opportunity = testOpp;
        data.boundAccs = new List<Account>();
        data.user = new User();

        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
        manager.build(new SignUpRequestBuilderManager.EnterpriseAccountIdBuilder())
            .build(new SignUpRequestBuilderManager.RCAccountIDBuilder());
        POWrappers.SignUpRequestBody body = manager.getSignUpRequestBody();

        Assert.isTrue(body.requestBodyMap.size() == 1, 'Should have size 1');
        Assert.areEqual(INTERNAL_ENTERPRISE_ACCOUNT_ID, body.requestBodyMap.get('enterpriseAccountId'), 'should be Internal_Enterprise_Account_ID__c');
    }

    @isTest
    static void verifyBuilderForSingleProductEngageUBOn() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => (Id) new ValueProvider.DummyIdProvider(Account.SObjectType).getValue(),
                Account.Internal_Enterprise_Account_ID__c => INTERNAL_ENTERPRISE_ACCOUNT_ID
            })
            .build()
            .getRecord();

        Opportunity testOpp = new Opportunity();
        testOpp.Account = testAccount;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE,
                Quote.IsMultiProductTechnicalQuote__c => false
            })
            .build()
            .getRecord();

        POWrappers.SignUpParams data = new POWrappers.SignUpParams();
        data.targetQuote = testQuote;
        data.opportunity = testOpp;
        data.boundAccs = new List<Account>();
        data.user = new User();

        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
        manager.build(new SignUpRequestBuilderManager.EnterpriseAccountIdBuilder())
            .build(new SignUpRequestBuilderManager.RCAccountIDBuilder());
        POWrappers.SignUpRequestBody body = manager.getSignUpRequestBody();

        Assert.isTrue(body.requestBodyMap.size() == 1, 'Should have size 1');
        Assert.areEqual(INTERNAL_ENTERPRISE_ACCOUNT_ID, body.requestBodyMap.get('enterpriseAccountId'), 'should be Internal_Enterprise_Account_ID__c');
    }

    @isTest
    static void verifyBuilderForMultiProductEngageUBOn() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Id => (Id) new ValueProvider.DummyIdProvider(Account.SObjectType).getValue(),
                Account.RC_User_ID__c => '54321'
            })
            .build()
            .getRecord();

        Opportunity testOpp = new Opportunity();
        testOpp.Account = testAccount;

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE,
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        POWrappers.SignUpParams data = new POWrappers.SignUpParams();
        data.targetQuote = testQuote;
        data.opportunity = testOpp;
        data.boundAccs = new List<Account>();
        data.user = new User();

        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
        manager.build(new SignUpRequestBuilderManager.EnterpriseAccountIdBuilder())
            .build(new SignUpRequestBuilderManager.RCAccountIDBuilder());
        POWrappers.SignUpRequestBody body = manager.getSignUpRequestBody();

        Assert.isTrue(body.requestBodyMap.size() == 2, 'Should have size 2');
        Assert.areEqual('54321', body.requestBodyMap.get('enterpriseAccountId'), 'should be RC_User_ID__c');
        Assert.areEqual('54321', body.requestBodyMap.get('rcAccountId'), 'should be RC_User_ID__c');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifySignUpRequestBuilderManagerInputDataValidation() {
        POWrappers.SignUpParams testData = new POWrappers.SignUpParams();
        testData.boundAccs = new List<Account>();

        Test.startTest();
            // User is null
            try {
                new SignUpRequestBuilderManager(testData);
                Assert.fail(MUST_THROW_AN_EXCEPTION);
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_USER_IS_REQUIRED, e);
            }

            // Opportunity is null
            testData.user = new User();
            try {
                new SignUpRequestBuilderManager(testData);
                Assert.fail(MUST_THROW_AN_EXCEPTION);
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_OPPORTUNITY_IS_REQUIRED, e);
            }

            // Account is null
            testData.opportunity = new Opportunity();
            try {
                new SignUpRequestBuilderManager(testData);
                Assert.fail(MUST_THROW_AN_EXCEPTION);
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_ACCOUNT_IS_REQUIRED, e);
            }

            // Quote is null
            testData.opportunity = putAccIntoOpp(testData.opportunity, new Account());
            try {
                new SignUpRequestBuilderManager(testData);
                Assert.fail(MUST_THROW_AN_EXCEPTION);
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_QUOTE_IS_REQUIRED, e);
            }

            // Package_info__c is empty
            testData.targetQuote = new Quote();
            try {
                new SignUpRequestBuilderManager(testData);
                Assert.fail(MUST_THROW_AN_EXCEPTION);
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_PACKAGE_INFO_IS_REQUIRED, e);
            }

            // All necessary records are present, thus no exception should be thrown
            testData.targetQuote.Package_Info__c = PACKAGE_INFO_ENGAGE;
            new SignUpRequestBuilderManager(testData);
        Test.stopTest();
    }

    @isTest
    static void verifyGetterForPInfo() {
        SignUpRequestBuilderManager testManager = buildEmptyManager();
        BillingWrappers.QuotePackageInfo testPackageInfo = getEngagePackageInfo();

        Test.startTest();
            // Test when pInfo is present
            testManager.pInfo = testPackageInfo;
            BillingWrappers.QuotePackageInfo resultWhenPInfoIsPresent = testManager.pInfo;

            // Test when pInfo is null and a Quote has package info
            testManager.pInfo = null;
            BillingWrappers.QuotePackageInfo resultWhenPInfoIsNullAndQuoteHasPackageInfo = testManager.pInfo;

            // Test when pInfo is null and a Quote has no package info
            testManager.pInfo = null;
            testManager.qt.Package_Info__c = null;
            BillingWrappers.QuotePackageInfo resultWhenPInfoIsNullAndQuoteHasNoPackageInfo = testManager.pInfo;
        Test.stopTest();

        Assert.areEqual(testPackageInfo, resultWhenPInfoIsPresent, 'Wrong pInfo was returned');
        // can't compare with testPackageInfo because of different hash values
        Assert.isNotNull(resultWhenPInfoIsNullAndQuoteHasPackageInfo, 'Must return a package info if a quote has it');
        Assert.isNull(resultWhenPInfoIsNullAndQuoteHasNoPackageInfo, 'Must return null if both a manager and a quote has no package info');
    }

    @isTest
    static void verifyGetterForIsNotJSONFormatRequest() {
        POHelper.isEngageUILessSettingsOn = true;
        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_ENGAGE)
            .build()
            .getRecord();
        SignUpRequestBuilderManager testManager = new SignUpRequestBuilderManager(buildSignUpParams(engageQuote));

        Test.startTest();
            Assert.isFalse(testManager.isNotJSONFormatRequest, 'isNotJSONFormatRequest must be false if engage UI less setting is off');
            POHelper.isEngageUILessSettingsOn = false;
            Assert.isTrue(testManager.isNotJSONFormatRequest, 'isNotJSONFormatRequest must be true if engage UI less setting is on');
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyGetterForPaymentMethodType() {
        Quote pocQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC
            })
            .build()
            .getRecord();
        SignUpRequestBuilderManager testManagerWithPOCQuote = new SignUpRequestBuilderManager(buildSignUpParams(pocQuote));

        Feature_Toggle__c enableSelectPackagesByBusinessIdentity = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.SelectPackagesByBusinessIdentity__c, true)
            .build()
            .getRecord();
        Quote engageQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => PACKAGE_INFO_ENGAGE,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES
            })
            .build()
            .getRecord();
        Opportunity oppWithBusinessIdentity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.BusinessIdentity__c, VALID_BUSINESS_IDENTITY)
            .build()
            .getRecord();
        POWrappers.SignUpParams signUpParamsWithPaymentMethod = buildSignUpParams(engageQuote, oppWithBusinessIdentity);
        signUpParamsWithPaymentMethod.paymentMethod = AccountHelper.PAYMENT_METHOD_INVOICE;
        SignUpRequestBuilderManager testManagerWithBusinessIdentity = new SignUpRequestBuilderManager(signUpParamsWithPaymentMethod);

        Test.startTest();
            testManagerWithPOCQuote.paymentMethodType = null;
            String whenPocQuote = testManagerWithPOCQuote.paymentMethodType;

            testManagerWithPOCQuote.paymentMethodType = TEST_PAYMENT_METHOD_TYPE;
            String whenPaymentMethodTypeIsSet = testManagerWithPOCQuote.paymentMethodType;

            testManagerWithBusinessIdentity.paymentMethodType = null;
            String whenSearchPackagesNotEnabled = testManagerWithBusinessIdentity.paymentMethodType;

            insert enableSelectPackagesByBusinessIdentity;
            testManagerWithBusinessIdentity.paymentMethodType = null;
            testManagerWithBusinessIdentity.paymentMethod = QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF;
            String whenSearchPackagesEnabled = testManagerWithBusinessIdentity.paymentMethodType;
        Test.stopTest();

        Map<String, String> expectedToActual = new Map<String, String> {
            AccountHelper.PAYMENT_METHOD_NONE => whenPocQuote,
            TEST_PAYMENT_METHOD_TYPE => whenPaymentMethodTypeIsSet,
            POWrappers.PAYMENT_METHOD_INV_FUNNEL => whenSearchPackagesNotEnabled,
            POWrappers.PAYMENT_METHOD_INV_BOB_FUNNEL => whenSearchPackagesEnabled
        };
        assertGetter(expectedToActual, 'payment method type');
    }

    @isTest
    static void verifyGetterForContractDescription() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.SObjectType).getValue();
        BillingWrappers.Contract testContract = new BillingWrappers.Contract();
        testContract.extId = TEST_CONTRACT_EXT_ID;

        SignUpRequestBuilderManager testManager = buildEmptyManager();
        testManager.qt.Id = dummyQuoteId;

        Test.startTest();
            testManager.contractDescription = CONTRACT_INFO;
            String whenContractDescriptionIsSet = testManager.contractDescription;

            testManager.contractDescription = null;
            testManager.pInfo.contract = null;
            String whenContractIsNull = testManager.contractDescription;

            testManager.contractDescription = null;
            testManager.pInfo.contract = testContract;
            String whenContractIsPresent = testManager.contractDescription;
        Test.stopTest();

        Assert.areEqual(CONTRACT_INFO, whenContractDescriptionIsSet, 'Wrong contract description was returned');
        Assert.isTrue(String.isBlank(whenContractIsNull), 'Contract description must be empty if pInfo has no contract');

        Assert.isTrue(String.isNotBlank(whenContractIsPresent), 'Contract description must not be empty if pInfo has a contract');
        Map<String, String> resultedContractInfo = (Map<String, String>) JSON.deserialize(whenContractIsPresent, Map<String, String>.class);
        Assert.areEqual(dummyQuoteId, resultedContractInfo.get('salesAgreement'), 'Contract description has wrong sales agreement');
        Assert.areEqual(TEST_CONTRACT_EXT_ID, resultedContractInfo.get('contractExtId'), 'Contract description has wrong contract ext id');
    }

    @isTest
    static void verifyGetterForIsTrial() {
        SignUpRequestBuilderManager manager = buildEmptyManager();

        Test.startTest();
            // when offerType is not a trial one
            manager.isTrial = null;
            manager.offerType = QuoteHelper.OFFER_TYPE_BUY;
            Boolean resultWhenOfferTypeIsNotTrial = manager.isTrial;

            // when offerType is a trial one
            manager.isTrial = null;
            manager.offerType = QuoteHelper.OFFER_TYPE_TRIAL;
            Boolean resultWhenOfferTypeIsTrial = manager.isTrial;

            // when isTrial is already set
            manager.isTrial = true;
            manager.offerType = QuoteHelper.OFFER_TYPE_BUY;
            Boolean resultWhenIsTrialIsSet = manager.isTrial;
        Test.stopTest();

        Assert.isFalse(resultWhenOfferTypeIsNotTrial, 'isTrial should be false when offerType is not a trial one');
        Assert.isTrue(resultWhenOfferTypeIsTrial, 'isTrial should be true when offerType is a trial one');
        Assert.isTrue(resultWhenIsTrialIsSet, 'isTrial should be the same as it was set');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyGetterForOfferType() {
        BillingWrappers.QuotePackageInfo testPackageInfo = getEngagePackageInfo();
        testPackageInfo.offerType = QuoteHelper.OFFER_TYPE_REGULAR;
        final String UNEXPECTED_OFFER_TYPE = 'unexpected' + DUMMY_OFFER_TYPE;

        SignUpRequestBuilderManager manager = buildEmptyManager();
        Test.startTest();
            // when offerType is set
            manager.offerType = DUMMY_OFFER_TYPE;
            String whenOfferTypeIsSet = manager.offerType;

            // when offerType is not set
            manager.offerType = null;
            manager.pInfo = testPackageInfo;
            String whenOfferTypeIsNotSet = manager.offerType;

            // when pInfo is with unexpected offer type
            manager.offerType = null;
            manager.pInfo.offerType = UNEXPECTED_OFFER_TYPE;
            String whenOfferTypeIsUnexpected = manager.offerType;
        Test.stopTest();

        Map<String, String> expectedToActual = new Map<String, String> {
            DUMMY_OFFER_TYPE => whenOfferTypeIsSet,
            QuoteHelper.OFFER_TYPE_BUY => whenOfferTypeIsNotSet,
            UNEXPECTED_OFFER_TYPE => whenOfferTypeIsUnexpected
        };
        assertGetter(expectedToActual, 'offer type');
    }

    @isTest
    static void verifyBuild() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        TestBuilder testBuilder = new TestBuilder();

        Test.startTest();
            manager = manager.build(testBuilder);
        Test.stopTest();

        Assert.isNotNull(manager, 'The build() method should return the manager itself');
        Assert.isTrue(testBuilder.isGetSignUpParameterCalled, 'The getSignUpParameter() method should be called');
        assertSignUpRequestBody(manager.requestBodyMap, TEST_SIGNUP_PARAMETER.keySet());
    }

    @isTest
    static void verifyGetSignUpRequestBody() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager cleanManager = buildEmptyManager();
        TestBuilder testBuilder = new TestBuilder();

        Test.startTest();
            // when no builder is added
            POWrappers.SignUpRequestBody resultWhenNoBuilderIsAdded = cleanManager.getSignUpRequestBody();

            // when a builder is added
            manager.requestBodyMap.clear();
            manager.build(testBuilder);
            POWrappers.SignUpRequestBody resultWhenBuilderIsAdded = manager.getSignUpRequestBody();
        Test.stopTest();

        List<POWrappers.SignUpRequestBody> resultedWrapppers = new List<POWrappers.SignUpRequestBody> {
            resultWhenNoBuilderIsAdded,
            resultWhenBuilderIsAdded
        };
        for (POWrappers.SignUpRequestBody wrapper : resultedWrapppers) {
            Assert.isNotNull(
                wrapper,
                'The method should return a wrapper-map regardless of whether a builder is added or not'
            );
            Assert.isNotNull(
                wrapper.requestBodyMap,
                'The requestBodyMap should not be null regardless of whether a builder is added or not'
            );
        }
        Assert.isTrue(
            resultWhenNoBuilderIsAdded.requestBodyMap.isEmpty(),
            'The requestBodyMap should be empty when no builder is added'
        );
        assertSignUpRequestBody(resultWhenBuilderIsAdded.requestBodyMap, TEST_SIGNUP_PARAMETER.keySet());
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyValidateSignUpRequestBody() {
        Set<String> requiredFields = new Set<String> {
            POWrappers.FIELD_NAME_SPID,
            POWrappers.FIELD_NAME_OPPID,
            POWrappers.FIELD_NAME_PACKAGE_NAME,
            POWrappers.FIELD_NAME_PACKAGE_ID,
            POWrappers.FIELD_NAME_PACKAGE_VERSION,
            POWrappers.FIELD_NAME_OFFER_TYPE
        };
        Set<String> requiredFieldsForTrial = new Set<String> {
            POWrappers.FIELD_NAME_TRIAL_PACKAGE_ID,
            POWrappers.FIELD_NAME_TRIAL_PACKAGE_VERSION
        };
        Map<String, Object> validRequestBodyMap = buildDummyRequestBodyMap(requiredFields);
        Map<String, Object> invalidRequestBodyMap = buildDummyRequestBodyMap(new Set<String>());

        String expectedMsgForInvalidRequestBodyMap = SignUpRequestBuilderManager.EX_MSG_FIELDS_ARE_REQUIRED + String.join(requiredFields, ', ');
        String expectedMsgWhenIsTrialIsTrue = SignUpRequestBuilderManager.EX_MSG_FIELDS_ARE_REQUIRED + String.join(requiredFieldsForTrial, ', ');

        SignUpRequestBuilderManager manager = buildEmptyManager();
        Test.startTest();
            // when request body map is valid, no exception should be thrown
            manager.requestBodyMap = validRequestBodyMap;
            manager.isTrial = false;
            manager.validateSignUpRequestBody();

            // when request body map is invalid
            manager.requestBodyMap = invalidRequestBodyMap;
            assertFailedValidateSignUpRequestBody(manager, expectedMsgForInvalidRequestBodyMap);

            // when isTrial = true and request body map is invalid
            manager.requestBodyMap = validRequestBodyMap;
            manager.isTrial = true;
            assertFailedValidateSignUpRequestBody(manager, expectedMsgWhenIsTrialIsTrue);
        Test.stopTest();
    }

    @isTest
    static void verifyOfferTypeBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.offerType = DUMMY_OFFER_TYPE;
        SignUpRequestBuilderManager.OfferTypeBuilder builder = new SignUpRequestBuilderManager.OfferTypeBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        Assert.areEqual(
            DUMMY_OFFER_TYPE,
            result.get(POWrappers.FIELD_NAME_OFFER_TYPE),
            'Wrong offer type was returned'
        );
    }

    @isTest
    static void verifyDefaultPackageLimitsBuilderFormatGlobalPackageLimits() {
        BillingWrappers.GlobalPackageLimits testLimits = buildGlobalPackageLimits();
        SignUpRequestBuilderManager.DefaultPackageLimitsBuilder builder = new SignUpRequestBuilderManager.DefaultPackageLimitsBuilder();

        Test.startTest();
            String whenLimitsAreNull = builder.formatGlobalPackageLimits(null);
            String whenLimitsArePresent = builder.formatGlobalPackageLimits(new List<BillingWrappers.GlobalPackageLimits> { testLimits });
        Test.stopTest();

        Assert.isNull(whenLimitsAreNull, 'Should return null if limits are null');
        Assert.isTrue(String.isNotBlank(whenLimitsArePresent), 'Should return a String if limits are present');
    }

    @isTest
    static void verifyDefaultPackageLimitsBuilderGetQPackageInfoLimits() {
        List<BillingWrappers.GlobalPackageLimits> testLimits = buildListOfGlobalPackageLimits();
        SignUpRequestBuilderManager.DefaultPackageLimitsBuilder builder = new SignUpRequestBuilderManager.DefaultPackageLimitsBuilder();
        SignUpRequestBuilderManager manager = buildEmptyManager();
        builder.init(manager);

        Test.startTest();
            POHelper.isEngageUILessSettingsOn = false;
            Object whenIsNotJSONFormatRequestIsTrue = builder.getQPackageInfoLimits(testLimits);

            POHelper.isEngageUILessSettingsOn = true;
            Object whenIsNotJSONFormatRequestIsFalse = builder.getQPackageInfoLimits(testLimits);
        Test.stopTest();

        assertGetPackageInfoLimits(whenIsNotJSONFormatRequestIsTrue, whenIsNotJSONFormatRequestIsFalse);
        Assert.areEqual(testLimits, whenIsNotJSONFormatRequestIsFalse, 'Wrong limits were returned');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyGetBPackageDefaultLimits() {
        BillingHttpRequestMock.MockInfo testMockInfo = new BillingHttpRequestMock.MockInfo(JSON.serialize(buildNGBSPackage()));
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap.put(GET_PACKAGE_ENDPOINT, testMockInfo);
        Test.setMock(HttpCalloutMock.class, testMock);

        BillingWrappers.QuotePackageInfo pInfo = buildEngagePackageInfo();
        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(buildSignUpParams(pInfo));
        SignUpRequestBuilderManager.DefaultPackageLimitsBuilder builder = new SignUpRequestBuilderManager.DefaultPackageLimitsBuilder();
        builder.init(manager);

        Test.startTest();
            POHelper.isEngageUILessSettingsOn = true;
            Object whenIsNotJSONFormatRequestIsFalse = builder.getBPackageDefaultLimits(pInfo);

            POHelper.isEngageUILessSettingsOn = false;
            Object whenIsNotJSONFormatRequestIsTrue = builder.getBPackageDefaultLimits(pInfo);
        Test.stopTest();

        assertGetPackageInfoLimits(whenIsNotJSONFormatRequestIsTrue, whenIsNotJSONFormatRequestIsFalse);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyDefaultPackageLimitsBuilder() {
        POHelper.isEngageUILessSettingsOn = true;

        List<BillingWrappers.GlobalPackageLimits> expectedLimits = buildListOfGlobalPackageLimits();
        SignUpRequestBuilderManager managerWithNonWholesaleAcc = buildManagerWithEngagePackageInfo();
        managerWithNonWholesaleAcc.pInfo.globalPackageLimits = expectedLimits;
        SignUpRequestBuilderManager.DefaultPackageLimitsBuilder builder = new SignUpRequestBuilderManager.DefaultPackageLimitsBuilder();
        builder.init(managerWithNonWholesaleAcc);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSignUpRequestBody(result, POWrappers.FIELD_NAME_DEFAULT_PACKAGE_LIMITS);
        assertGlobalPackageLimits(expectedLimits, (List<BillingWrappers.GlobalPackageLimits>) result.get(POWrappers.FIELD_NAME_DEFAULT_PACKAGE_LIMITS));
    }

    @isTest
    static void verifyIsTerminationOpportunityBuilder() {
        POHelper.isEngageUILessSettingsOn = true;

        BillingWrappers.QuotePackageInfo ccPackageInfo = buildPackageInfo(Product2Helper.PRODUCT_ID_CONTACT_CENTER);
        ccPackageInfo.globalPackageLimits = buildListOfGlobalPackageLimits();
        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(buildSignUpParams(ccPackageInfo));
        SignUpRequestBuilderManager.IsTerminationOpportunityBuilder builder = new SignUpRequestBuilderManager.IsTerminationOpportunityBuilder();
        builder.init(manager);

        Test.startTest();
            manager.isUpsell = true;
            manager.isTermination = true;
            Map<String, Object> whenTerminate = builder.getSignUpParameter();

            manager.isUpsell = false;
            Map<String, Object> whenNotTerminate = builder.getSignUpParameter();
        Test.stopTest();

        assertEmptySignUpRequestBody(whenNotTerminate);
        assertSignUpRequestBody(whenTerminate, POWrappers.FIELD_NAME_IS_TERMINATION_OPPORTUNITY);
        Assert.isTrue((Boolean) whenTerminate.get(POWrappers.FIELD_NAME_IS_TERMINATION_OPPORTUNITY), 'Wrong value was returned');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyUBrandIdBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.uBrandId = DUMMY_VALUE;
        SignUpRequestBuilderManager.UBrandIdBuilder builder = new SignUpRequestBuilderManager.UBrandIdBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_UBRAND_ID, DUMMY_VALUE);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPIDBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.acc.PID__c = DUMMY_VALUE;
        SignUpRequestBuilderManager.PIDBuilder builder = new SignUpRequestBuilderManager.PIDBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_PID, DUMMY_VALUE);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPaymentMethodTypeBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.paymentMethodType = TEST_PAYMENT_METHOD_TYPE;
        SignUpRequestBuilderManager.PaymentMethodTypeBuilder builder = new SignUpRequestBuilderManager.PaymentMethodTypeBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_PAYMENT_METHOD_TYPE, TEST_PAYMENT_METHOD_TYPE);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifySAFIDBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager.SAFIDBuilder builder = new SignUpRequestBuilderManager.SAFIDBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> whenEngage = builder.getSignUpParameter();

            builder.m.pInfo.productName = QuoteHelper.NGBS_OFFICE_PRODUCT;
            Map<String, Object> whenOffice = builder.getSignUpParameter();
        Test.stopTest();

        assertEmptySignUpRequestBody(whenOffice);
        assertSingleFieldInRequestBody(whenEngage, POWrappers.FIELD_NAME_SAFID, POWrappers.DEFAULT_SAF_ID);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyEnterpriseAccountIdBuilder() {
        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.acc.Internal_Enterprise_Account_ID__c = INTERNAL_ENTERPRISE_ACCOUNT_ID;
        manager.acc.RC_User_ID__c = RC_USER_ID;
        manager.qt.IsMultiProductTechnicalQuote__c = true;
        SignUpRequestBuilderManager.EnterpriseAccountIdBuilder builder = new SignUpRequestBuilderManager.EnterpriseAccountIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();

            builder.m.isMPUB = false;
            Map<String, Object> whenNotMPUB = builder.getSignUpParameter();
        Test.stopTest();

        Map<String, Map<String, Object>> expectedToActual = new Map<String, Map<String, Object>> {
            RC_USER_ID => whenMPUB,
            INTERNAL_ENTERPRISE_ACCOUNT_ID => whenNotMPUB
        };
        for (String expectedValue : expectedToActual.keySet()) {
            Map<String, Object> actualResult = expectedToActual.get(expectedValue);
            assertSingleFieldInRequestBody(actualResult, POWrappers.FIELD_NAME_ENTERPRISE_ACCOUNT_ID, expectedValue);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyEngageBillingIdBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.acc.Billing_ID__c = RC_USER_ID;
        manager.qt.ServiceName__c = OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE;
        SignUpRequestBuilderManager.BillingIdBuilder builder = new SignUpRequestBuilderManager.BillingIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.qt.IsMultiProductTechnicalQuote__c = true;
            Map<String, Object> whenTechQuote = builder.getSignUpParameter();

            builder.m.qt.IsMultiProductTechnicalQuote__c = false;
            Map<String, Object> whenMasterQuote = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenTechQuote, POWrappers.FIELD_NAME_BILLING_ID, RC_USER_ID);
        assertSingleFieldInRequestBody(whenMasterQuote, POWrappers.FIELD_NAME_BILLING_ID, RC_USER_ID);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyRCAccountIDBuilder() {
        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.acc.RC_User_ID__c = RC_USER_ID;
        manager.isMPUB = true;
        SignUpRequestBuilderManager.RCAccountIDBuilder builder = new SignUpRequestBuilderManager.RCAccountIDBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.qt.IsMultiProductTechnicalQuote__c = true;
            Map<String, Object> whenEngage = builder.getSignUpParameter();

            builder.m.qt.IsMultiProductTechnicalQuote__c = false;
            Map<String, Object> whenEngageStandalone = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenEngage, POWrappers.FIELD_NAME_RC_ACCOUNT_ID, RC_USER_ID);
        assertEmptySignUpRequestBody(whenEngageStandalone);
    }

    @isTest
    static void verifyRCAccountIDBuilderGetBoundRcAccountId() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.acc.RC_User_ID__c = RC_USER_ID;
        manager.opp = putAccIntoOpp(
            manager.opp,
            putMasterAccIntoAcc(new Account(), new Account(RC_User_ID__c = MASTER_RC_USER_ID))
        );
        SignUpRequestBuilderManager.RCAccountIDBuilder builder = new SignUpRequestBuilderManager.RCAccountIDBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            String whenMPUB = builder.getBoundRcAccountId();

            builder.m.isMPUB = false;
            String whenMPLite = builder.getBoundRcAccountId();
        Test.stopTest();

        Assert.areEqual(RC_USER_ID, whenMPUB, 'Must return Account.RC_User_ID__c when it is the MPUB flow');
        Assert.areEqual(
            MASTER_RC_USER_ID,
            whenMPLite,
            'Must return Account.Master_Account__r.RC_User_ID__c when it is the MPLite flow'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyOpportunityBuilder() {
        Id dummyOppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.SObjectType).getValue();
        final String DUMMY_BMID = 'BMID123';
        final String DUMMY_OID = 'OID123';
        final String BC_VALUE = '1';
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Id => dummyOppId,
                Opportunity.Partner_ID__c => PARTNER_ID,
                Opportunity.BMID__c => DUMMY_BMID,
                Opportunity.OID__c => DUMMY_OID,
                Opportunity.Enable_Cost_Center_Management__c => true
            })
            .build()
            .getRecord();

        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.opp = testOpp;
        SignUpRequestBuilderManager.OpportunityBuilder builder = new SignUpRequestBuilderManager.OpportunityBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        Map<String, Object> expectedResult = new Map<String, Object> {
            POWrappers.FIELD_NAME_OPPID => dummyOppId,
            POWrappers.FIELD_NAME_PARTNER_ID => PARTNER_ID,
            POWrappers.FIELD_NAME_BMID => DUMMY_BMID,
            POWrappers.FIELD_NAME_OID => POWRappers.OID_PREFIX + DUMMY_OID,
            POWrappers.FIELD_NAME_BC => BC_VALUE
        };
        assertSignUpRequestBody(result, expectedResult);
    }

    @isTest
    static void verifyOpportunityBuilderGetBC() {
        SignUpRequestBuilderManager.OpportunityBuilder builder = new SignUpRequestBuilderManager.OpportunityBuilder();
        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Enable_Cost_Center_Management__c, ValueProviderBuilder.provideList(new List<Boolean> {true, false}))
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();
            String whenEnableCostCenterManagementIsTrue = builder.getBC(opps[0]);
            String whenEnableCostCenterManagementIsFalse = builder.getBC(opps[1]);
        Test.stopTest();

        Assert.areEqual('1', whenEnableCostCenterManagementIsTrue, 'Must return "1" when Enable Cost Center Management is true');
        Assert.areEqual('0', whenEnableCostCenterManagementIsFalse, 'Must return "0" when Enable Cost Center Management is false');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyContractDescriptionBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.contractDescription = TEST_CONTRACT_DESCRIPTION;
        SignUpRequestBuilderManager.ContractDescriptionBuilder builder = new SignUpRequestBuilderManager.ContractDescriptionBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_CONTRACT_DESCRIPTION, TEST_CONTRACT_DESCRIPTION);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyContractTermBuilder() {
        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.qt.Initial_Term_months__c = INITIAL_TERM_MONTHS;
        manager.contractDescription = TEST_CONTRACT_DESCRIPTION;
        manager.pInfo.contract = new BillingWrappers.Contract();
        SignUpRequestBuilderManager.ContractTermBuilder builder = new SignUpRequestBuilderManager.ContractTermBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_CONTRACT_TERM, INITIAL_TERM_MONTHS_INTEGER);
    }

    @isTest
    static void verifyContractTermBuilderGetContractTerm() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Initial_Term_months__c, INITIAL_TERM_MONTHS)
            .build()
            .getRecord();
        BillingWrappers.Contract testContract = new BillingWrappers.Contract();
        BillingWrappers.QuotePackageInfo pInfo = buildEngagePackageInfo();
        pInfo.contract = testContract;

        SignUpRequestBuilderManager.ContractTermBuilder builder = new SignUpRequestBuilderManager.ContractTermBuilder();
        Test.startTest();
            Integer whenEverythingIsPresent = builder.getContractTerm(qt, pInfo);

            pInfo.contract = null;
            Integer whenContractIsNull = builder.getContractTerm(qt, pInfo);

            pInfo.contract = testContract;
            qt.Initial_Term_months__c = null;
            Integer whenInitialTermIsNull = builder.getContractTerm(qt, pInfo);
        Test.stopTest();

        Assert.areEqual(INITIAL_TERM_MONTHS_INTEGER, whenEverythingIsPresent, 'Must return Initial_Term_months__c when everything is present');
        Assert.isNull(whenContractIsNull, 'Must return null when pInfo has no contract');
        Assert.isNull(whenInitialTermIsNull, 'Must return null when Initial_Term_months__c is null');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyContractAutoRenewalBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.qt.Auto_Renewal__c = true;
        SignUpRequestBuilderManager.ContractAutoRenewalBuilder builder = new SignUpRequestBuilderManager.ContractAutoRenewalBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.contractDescription = TEST_CONTRACT_DESCRIPTION;
            Map<String, Object> whenContractDescriptionIsPresent = builder.getSignUpParameter();

            builder.m.contractDescription = null;
            Map<String, Object> whenContractDescriptionIsNull = builder.getSignUpParameter();
        Test.stopTest();

        assertEmptySignUpRequestBody(whenContractDescriptionIsNull);
        assertSingleFieldInRequestBody(whenContractDescriptionIsPresent, POWrappers.FIELD_NAME_CONTRACT_AUTO_RENEWAL, true);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyContractRenewalTermBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.qt.Auto_Renewal__c = true;
        manager.qt.Term_months__c = INITIAL_TERM_MONTHS;
        SignUpRequestBuilderManager.ContractRenewalTermBuilder builder = new SignUpRequestBuilderManager.ContractRenewalTermBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.contractDescription = TEST_CONTRACT_DESCRIPTION;
            Map<String, Object> whenContractDescriptionIsPresent = builder.getSignUpParameter();

            builder.m.contractDescription = null;
            Map<String, Object> whenContractDescriptionIsNull = builder.getSignUpParameter();
        Test.stopTest();

        assertEmptySignUpRequestBody(whenContractDescriptionIsNull);
        assertSingleFieldInRequestBody(whenContractDescriptionIsPresent, POWrappers.FIELD_NAME_CONTRACT_RENEWAL_TERM, INITIAL_TERM_MONTHS_INTEGER);
    }

    @isTest
    static void verifyContractRenewalTermBuilderContractRenewalTerm() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Term_months__c => INITIAL_TERM_MONTHS,
                Quote.Auto_Renewal__c => true
            })
            .build()
            .getRecord();

        SignUpRequestBuilderManager.ContractRenewalTermBuilder builder = new SignUpRequestBuilderManager.ContractRenewalTermBuilder();
        Test.startTest();
            Integer whenAutoRevewalIsTrue = builder.getContractRenewalTerm(qt);

            qt.Auto_Renewal__c = false;
            Integer whenAutoRenewalIsFalse = builder.getContractRenewalTerm(qt);
        Test.stopTest();

        Assert.areEqual(
            INITIAL_TERM_MONTHS_INTEGER,
            whenAutoRevewalIsTrue,
            'Must return Term_months__c when Auto_Renewal__c is true'
        );
        Assert.isNull(whenAutoRenewalIsFalse, 'Must return null when when Auto_Renewal__c is false');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyEnablePhoneLeasingBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.contractDescription = TEST_CONTRACT_DESCRIPTION;
        manager.opp.CurrencyIsoCode = RingCentralHelper.EUR;
        manager.opp.Brand_Name__c = OpportunityHelper.BRAND_RINGCENTRAL_EU;
        SignUpRequestBuilderManager.EnablePhoneLeasingBuilder builder = new SignUpRequestBuilderManager.EnablePhoneLeasingBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.contractDescription = TEST_CONTRACT_DESCRIPTION;
            Map<String, Object> whenContractDescriptionIsPresent = builder.getSignUpParameter();

            builder.m.contractDescription = null;
            Map<String, Object> whenContractDescriptionIsNull = builder.getSignUpParameter();
        Test.stopTest();

        assertEmptySignUpRequestBody(whenContractDescriptionIsNull);
        assertSingleFieldInRequestBody(whenContractDescriptionIsPresent, POWrappers.FIELD_NAME_ENABLE_PHONE_LEASING, true);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyOrderIdBuilder() {
        Id dummyQuoteId = (Id) new ValueProvider.DummyIdProvider(Quote.SObjectType).getValue();

        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.qt.Id = dummyQuoteId;
        SignUpRequestBuilderManager.OrderIdBuilder builder = new SignUpRequestBuilderManager.OrderIdBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_ORDER_ID, dummyQuoteId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyFSCAmountBuilder() {
        SettingsHelper.FEATURE_TOGGLE.Credit_Process_NGBS__c = true;

        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.qt = putFreeServiceCreditTotalIntoQuote(manager.qt, FREE_SERVICE_CREDIT_TOTAL);
        SignUpRequestBuilderManager.FSCAmountBuilder builder = new SignUpRequestBuilderManager.FSCAmountBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_FSC_AMOUNT, String.valueOf(FREE_SERVICE_CREDIT_TOTAL));
    }

    @isTest
    static void verifyFSCAmountBuilderGetFSCAmount() {
        SettingsHelper.FEATURE_TOGGLE.Credit_Process_NGBS__c = true;

        Quote qt = putFreeServiceCreditTotalIntoQuote(new Quote(), FREE_SERVICE_CREDIT_TOTAL);
        SignUpRequestBuilderManager.FSCAmountBuilder builder = new SignUpRequestBuilderManager.FSCAmountBuilder();

        Test.startTest();
            String whenFreeServiceCreditTotalIsPresent = builder.getFSCAmount(qt);

            qt = putFreeServiceCreditTotalIntoQuote(qt, 0);
            String whenFreeServiceCreditTotalIsZero = builder.getFSCAmount(qt);
        Test.stopTest();

        Assert.areEqual(
            String.valueOf(FREE_SERVICE_CREDIT_TOTAL),
            whenFreeServiceCreditTotalIsPresent,
            'Must return Free_Service_Credit_Total__c when it is present'
        );
        Assert.isTrue(
            String.isBlank(whenFreeServiceCreditTotalIsZero),
            'Must return blank String when Free_Service_Credit_Total__c is zero'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPlanDurationBuilder() {
        final String PINFO_DURATION = '12 months';

        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.pInfo.duration = PINFO_DURATION;
        SignUpRequestBuilderManager.PlanDurationBuilder builder = new SignUpRequestBuilderManager.PlanDurationBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_PLAN_DURATION, PINFO_DURATION);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyBusinessIdentityIdBuilder() {
        final String APPROVED_BI_ID = '12345';

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        SignUpRequestBuilderManager.BusinessIdentityIdBuilder builder = new SignUpRequestBuilderManager.BusinessIdentityIdBuilder();
        builder.init(manager);

        Test.startTest();
            manager.pInfo.packageBusinessIdentities.approvedBi = new BillingWrappers.BusinessIdentity();
            manager.pInfo.packageBusinessIdentities.approvedBi.id = APPROVED_BI_ID;
            Map<String, Object> whenApprovedBIIsPresent = builder.getSignUpParameter();

            manager.pInfo.packageBusinessIdentities.approvedBi = null;
            Map<String, Object> whenApprovedBIIsAbsent = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(
            whenApprovedBIIsPresent,
            POWrappers.FIELD_NAME_BUSINESS_IDENTITY_ID,
            Integer.valueOf(APPROVED_BI_ID)
        );
        assertEmptySignUpRequestBody(whenApprovedBIIsAbsent);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPromotionsBuilder() {
        final String PROMO_CODE = 'PROMO1';
        final String PROMO_CODES_FIELD = 'promoCodes[0]';

        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.isNotJSONFormatRequest = true;
        manager.promoList = new List<Promotion__c> { new Promotion__c(Promo_Code__c = PROMO_CODE) };
        SignUpRequestBuilderManager.PromotionsBuilder builder = new SignUpRequestBuilderManager.PromotionsBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, PROMO_CODES_FIELD, PROMO_CODE);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPackageBuilder() {
        final String POC_CATALOG_ID = 'POC' + DUMMY_CATALOG_ID;
        final String POC_VERSION = 'POC' + PACKAGE_VERSION_FOR_ENGAGE;

        BillingWrappers.POC poc = new BillingWrappers.POC();
        poc.catalogId = POC_CATALOG_ID;
        poc.version = POC_VERSION;
        BillingWrappers.QuotePackageInfo pInfo = buildEngagePackageInfo();
        pInfo.poc = poc;
        SignUpRequestBuilderManager manager = buildSignUpRequestBuilderManager(pInfo);
        SignUpRequestBuilderManager.PackageBuilder builder = new SignUpRequestBuilderManager.PackageBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isTrial = false;
            Map<String, Object> whenNotTrial = builder.getSignUpParameter();

            builder.m.isTrial = true;
            Map<String, Object> whenTrial = builder.getSignUpParameter();

            // POC catalogId is blank
            builder.m.pInfo.poc.catalogId = '';
            builder.m.pInfo.poc.version = POC_VERSION;
            try {
                builder.getSignUpParameter();
                Assert.fail(MUST_THROW_AN_EXCEPTION + ' when isTrial is true and POC catalogId is blank');
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO, e);
            }

            // POC version is blank
            builder.m.pInfo.poc.catalogId = POC_CATALOG_ID;
            builder.m.pInfo.poc.version = '';
            try {
                builder.getSignUpParameter();
                Assert.fail(MUST_THROW_AN_EXCEPTION + ' when isTrial is true and POC version is blank');
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO, e);
            }

            // POC catalogId is null
            builder.m.pInfo.poc.version = POC_VERSION;
            builder.m.pInfo.poc.catalogId = null;
            try {
                builder.getSignUpParameter();
                Assert.fail(MUST_THROW_AN_EXCEPTION + ' when isTrial is true and POC catalogId is null');
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO, e);
            }

            // POC version is null
            builder.m.pInfo.poc.catalogId = POC_CATALOG_ID;
            builder.m.pInfo.poc.version = null;
            try {
                builder.getSignUpParameter();
                Assert.fail(MUST_THROW_AN_EXCEPTION + ' when isTrial is true and POC version is null');
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO, e);
            }

            // POC is null
            builder.m.pInfo.poc = null;
            try {
                builder.getSignUpParameter();
                Assert.fail(MUST_THROW_AN_EXCEPTION + ' when isTrial is true and no POC info is present');
            } catch (AquivaHelper.AquivaException e) {
                assertException(SignUpRequestBuilderManager.EX_MSG_PACKAGE_INFO_NEEDS_POC_INFO, e);
            }

        Test.stopTest();

        Map<String, Object> expectedResult = new Map<String, Object> {
            POWrappers.FIELD_NAME_PACKAGE_NAME => PACKAGE_NAME,
            POWrappers.FIELD_NAME_PACKAGE_ID => DUMMY_CATALOG_ID,
            POWrappers.FIELD_NAME_PACKAGE_VERSION => PACKAGE_VERSION_FOR_ENGAGE
        };
        assertSignUpRequestBody(whenNotTrial, expectedResult);

        Map<String, Object> expectedResultForTrial = new Map<String, Object> {
            POWrappers.FIELD_NAME_TRIAL_PACKAGE_ID => POC_CATALOG_ID,
            POWrappers.FIELD_NAME_TRIAL_PACKAGE_VERSION => POC_VERSION
        };
        expectedResultForTrial.putAll(expectedResult);
        assertSignUpRequestBody(whenTrial, expectedResultForTrial);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPreferredLanguageIdBuilder() {
        String dummyLocaleCode = 'dummy_locale_code';
        BillingWrappers.PreferredLanguage preferredLanguage = new BillingWrappers.PreferredLanguage();
        preferredLanguage.localeCode = dummyLocaleCode;

        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager.PreferredLanguageIdBuilder builder = new SignUpRequestBuilderManager.PreferredLanguageIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.pInfo.preferredLanguage = preferredLanguage;
            Map<String, Object> whenPreferredLangIsPresent = builder.getSignUpParameter();

            builder.m.pInfo.preferredLanguage = null;
            Map<String, Object> whenPreferredLangIsAbsent = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenPreferredLangIsPresent, POWrappers.FIELD_NAME_PREFERRED_USER_LANGUAGE, dummyLocaleCode);
        assertEmptySignUpRequestBody(whenPreferredLangIsAbsent);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyBillingTimeZoneIdLanguageIdBuilder() {
        final String TIMEZONE_ID = 'America/New_York';

        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.timezoneId = TIMEZONE_ID;
        SignUpRequestBuilderManager.BillingTimeZoneIdLanguageIdBuilder builder = new SignUpRequestBuilderManager.BillingTimeZoneIdLanguageIdBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_BILLING_TIMEZONE_ID, TIMEZONE_ID);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyTrialDurationBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.qt.RecordTypeId = QuoteHelper.RT_ID_POC;
        manager.qt.Initial_Term_POC__c = INITIAL_TERM_POC;
        SignUpRequestBuilderManager.TrialDurationBuilder builder = new SignUpRequestBuilderManager.TrialDurationBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(
            result,
            POWrappers.FIELD_NAME_TRIAL_DURATION,
            POWrappers.TRIAL_DURATION_PREFIX + INITIAL_TERM_POC
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyELATypeBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager.ELATypeBuilder builder = new SignUpRequestBuilderManager.ELATypeBuilder();
        builder.init(manager);

        Test.startTest();
            manager.acc.ELA_Account_Type__c = AccountHelper.ACCOUNT_TYPE_ELA_SERVICE;
            Map<String, Object> whenElaTypeIsPresent = builder.getSignUpParameter();

            builder.m.acc.ELA_Account_Type__c = null;
            Map<String, Object> whenElaTypeIsAbsent = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(
            whenElaTypeIsPresent,
            POWrappers.FIELD_NAME_ELA_TYPE,
            AccountHelper.ACCOUNT_TYPE_ELA_MAP.get(AccountHelper.ACCOUNT_TYPE_ELA_SERVICE)
        );
        assertEmptySignUpRequestBody(whenElaTypeIsAbsent);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyExemptFromStateAndLocalTaxesBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager.ExemptFromStateAndLocalTaxesBuilder builder = new SignUpRequestBuilderManager.ExemptFromStateAndLocalTaxesBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(
            result,
            POWrappers.FIELD_NAME_EXEMPT_FROM_STATE_AND_LOCAL_TAXES,
            false
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyRCBSBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager.RCBSBuilder builder = new SignUpRequestBuilderManager.RCBSBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_RCBS, true);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyEnabledLBOBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.qt = new Quote(Enabled_LBO__c = true);
        SignUpRequestBuilderManager.EnabledLBOBuilder builder = new SignUpRequestBuilderManager.EnabledLBOBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.qt.Enabled_LBO__c = true;
            Map<String, Object> whenLBOEnabled = builder.getSignUpParameter();

            builder.m.qt.Enabled_LBO__c = false;
            Map<String, Object> whenLBODisabled = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenLBOEnabled, POWrappers.FIELD_NAME_IS_LBO, true);
        assertEmptySignUpRequestBody(whenLBODisabled);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyNGBSPartnerIdBuilder() {
        Triggers.switchOff();
        Account testPartnerAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Partner Account',
                Account.NGBS_Partner_ID__c => NGBS_PARTNER_ID
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        SignUpRequestBuilderManager manager = buildEmptyManager();
        SignUpRequestBuilderManager.NGBSPartnerIdBuilder builder = new SignUpRequestBuilderManager.NGBSPartnerIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.acc.Partner_Account__c = testPartnerAccount.Id;
            Map<String, Object> whenPartnerAcc = builder.getSignUpParameter();

            builder.m.acc.Partner_Account__c = null;
            Map<String, Object> whenNoPartnerAcc = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenPartnerAcc, POWrappers.FIELD_NAME_NGBS_PARTNER_ID, NGBS_PARTNER_ID);
        assertEmptySignUpRequestBody(whenNoPartnerAcc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPartnerPackageIdBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.acc.Partner_ID__c = PARTNER_ID;
        manager.pInfo.partnerPackage = buildPartnerPackageInfo();
        SignUpRequestBuilderManager.PartnerPackageIdBuilder builder = new SignUpRequestBuilderManager.PartnerPackageIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.acc.Partner_Type__c = AccountHelper.ACCOUNT_PARTNER_WHOLESALE;
            Map<String, Object> whenWholesaleAcc = builder.getSignUpParameter();

            builder.m.acc.Partner_Type__c = null;
            Map<String, Object> whenNotWholesaleAcc = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenWholesaleAcc, POWrappers.FIELD_NAME_PARTNER_PACKAGE_ID, PARTNER_ID);
        assertEmptySignUpRequestBody(whenNotWholesaleAcc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyPartnerPackageVersionBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.acc.Partner_ID__c = PARTNER_ID;
        manager.pInfo.partnerPackage = buildPartnerPackageInfo();
        SignUpRequestBuilderManager.PartnerPackageVersionBuilder builder = new SignUpRequestBuilderManager.PartnerPackageVersionBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.acc.Partner_Type__c = AccountHelper.ACCOUNT_PARTNER_WHOLESALE;
            Map<String, Object> whenWholesaleAcc = builder.getSignUpParameter();

            builder.m.acc.Partner_Type__c = null;
            Map<String, Object> whenNotWholesaleAcc = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenWholesaleAcc, POWrappers.FIELD_NAME_PARTNER_PACKAGE_VERSION, PARTNER_VERSION);
        assertEmptySignUpRequestBody(whenNotWholesaleAcc);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyInContactBuilder() {
        final String RC_MAIN_NUM = 'RC123';
        final String CC_NUM = 'CC123';

        SignUpRequestBuilderManager engageManager = buildManagerWithEngagePackageInfo();

        BillingWrappers.QuotePackageInfo ccPackageInfo = buildPackageInfo(Product2Helper.PRODUCT_ID_CONTACT_CENTER);
        SignUpRequestBuilderManager ccManager = new SignUpRequestBuilderManager(buildSignUpParams(ccPackageInfo));
        ccManager.opp.NumberToBeRCMainNumber__c = RC_MAIN_NUM;
        ccManager.opp.NumberToBeCCNumber__c = CC_NUM;
        SignUpRequestBuilderManager.InContactBuilder builder = new SignUpRequestBuilderManager.InContactBuilder();

        Test.startTest();
            builder.init(ccManager);
            Map<String, Object> whenRCCC = builder.getSignUpParameter();

            builder.init(engageManager);
            Map<String, Object> whenEngage = builder.getSignUpParameter();
        Test.stopTest();

        Map<String, Object> expectedResult = new Map<String, Object> {
            POWrappers.FIELD_NAME_RC_ACCOUNT_NUMBER => RC_MAIN_NUM,
            POWrappers.FIELD_NAME_CC_ACCOUNT_NUMBER => CC_NUM
        };
        assertSignUpRequestBody(whenRCCC, expectedResult);
        assertEmptySignUpRequestBody(whenEngage);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyEnterpriseCustomerIdBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.opp.Account.EnterpriseCustomerID__c = INTERNAL_ENTERPRISE_ACCOUNT_ID;
        SignUpRequestBuilderManager.EnterpriseCustomerIdBuilder builder = new SignUpRequestBuilderManager.EnterpriseCustomerIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.acc.IsMultiProductTechnicalAccount__c = true;
            Map<String, Object> whenMPLite = builder.getSignUpParameter();

            builder.m.acc.IsMultiProductTechnicalAccount__c = false;
            Map<String, Object> whenNotMPLite = builder.getSignUpParameter();

            builder.m.acc.EnterpriseCustomerID__c = null;
            builder.m.acc.IsMultiProductTechnicalAccount__c = true;
            Map<String, Object> whenNoEnterpriseCustomerId = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenMPLite, POWrappers.FIELD_NAME_ENTERPRISE_CUSTOMER_ID, INTERNAL_ENTERPRISE_ACCOUNT_ID);
        assertEmptySignUpRequestBody(whenNotMPLite);
        assertEmptySignUpRequestBody(whenNoEnterpriseCustomerId);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyBillingAlignmentEnabledBuilder() {
        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.qt.IsMultiProductTechnicalQuote__c = true;
        SignUpRequestBuilderManager.BillingAlignmentEnabledBuilder builder = new SignUpRequestBuilderManager.BillingAlignmentEnabledBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();

            builder.m.isMPUB = false;
            Map<String, Object> whenMPLite = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenMPUB, POWrappers.FIELD_NAME_BILLING_ALIGNMENT_ENABLED, true);
        assertEmptySignUpRequestBody(whenMPLite);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyInvoiceConsolidationEnabledBuilder() {
        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.qt.IsMultiProductTechnicalQuote__c = true;
        SignUpRequestBuilderManager.InvoiceConsolidationEnabledBuilder builder = new SignUpRequestBuilderManager.InvoiceConsolidationEnabledBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();

            builder.m.isMPUB = false;
            Map<String, Object> whenMPLite = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(whenMPUB, POWrappers.FIELD_NAME_INVOICE_CONSOLIDATION_ENABLED, true);
        assertEmptySignUpRequestBody(whenMPLite);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyBillingAccountIdBuilder() {
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.opp.Account.Billing_ID__c = '123456';
        SignUpRequestBuilderManager.BillingAccountIdBuilder builder = new SignUpRequestBuilderManager.BillingAccountIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();
        Test.stopTest();
        assertSingleFieldInRequestBody(whenMPUB, POWrappers.FIELD_NAME_BILLING_ACCOUNT_ID, '123456');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifySalesOrderIdBuilder() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();
        SignUpRequestBuilderManager manager = buildEmptyManager();
        manager.opp = testOpp;
        SignUpRequestBuilderManager.SalesOrderIdBuilder builder = new SignUpRequestBuilderManager.SalesOrderIdBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();
        Test.stopTest();
        assertSingleFieldInRequestBody(whenMPUB, POWrappers.FIELD_NAME_SALES_ORDER_ID, testOpp.Id);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyServiceInfoBuilder() {
        final String PROMO_CODE = 'PROMO1';
        final String PROMO_CODES_FIELD = 'promoCodes[0]';
        
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test acc',
                    Account.Billing_ID__c => '123456768'
                }
            )
            .build()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        packageInfo.packageInfo.catalogId = '5';
        packageInfo.packageInfo.version = '1';
        packageInfo.duration = 'Monthly';

        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(buildSignUpParams(packageInfo));

        manager.isNotJSONFormatRequest = true;
        manager.promoList = new List<Promotion__c> { new Promotion__c(Promo_Code__c = PROMO_CODE) };
        manager.opp = testOpp;
        
        manager.approvals = new List<Approval__c>();
        
        SignUpRequestBuilderManager.ServiceInfoBuilder builder = new SignUpRequestBuilderManager.ServiceInfoBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();
        Test.stopTest();
        Map<String,Object> expectedMap = new Map<String,Object>{
            POWrappers.FIELD_NAME_DISCOUNTS => new Map<String,Object>(),
            POWrappers.FIELD_NAME_ORDER => new Map<String,Object>(),
            POWrappers.FIELD_NAME_CONTRACT => new Map<String,Object>(),
            POWrappers.FIELD_NAME_DURATION => 'Monthly',
            POWrappers.FIELD_NAME_LIMITS => new List<Object>(),
            POWrappers.FIELD_NAME_SERVICE_ACCOUNT_ID => '1234',
            POWrappers.FIELD_NAME_PACKAGE => new Map<String,Object> {
                POWrappers.FIELD_NAME_PROSERV_PACKAGE_ID => '5',
                POWrappers.FIELD_NAME_PROSERV_PACKAGE_VERSION => '1'
            }
        };
        
        assertSignUpRequestBody(whenMPUB, POWrappers.FIELD_NAME_SERVICE_INFO);
    }

    @IsTest
    static void verifyApprovedPackageLimitsBuilderBuildJSONFormatRequest_MPL() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c, true)
            .create();

        new SObjectBuilder(DirectDebitApprovalThreshold__c.SObjectType)
            .setField(DirectDebitApprovalThreshold__c.Name, 'RC')
            .setField(DirectDebitApprovalThreshold__c.Brand__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(DirectDebitApprovalThreshold__c.Currency__c, OpportunityHelper.CURRENCY_ISO_CODE_USD)
            .setField(DirectDebitApprovalThreshold__c.ThresholdValue__c, CUSTOM_SETTING_LIMIT)
            .create();

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        populateLimitParams(manager);

        SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder builder = new SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder();
        builder.init(manager);

        Test.startTest();
            List<POWrappers.ApprovedPackageLimits> result = builder.buildJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
            Assert.areEqual(1, result.size(), '1 Approval package limit should be returned for PAYMENT_METHOD_DD_FUNNEL');
            Assert.areEqual(CUSTOM_SETTING_LIMIT, result[0].MonthlyCreditLimitC, 'Limit should match custom setting DirectDebitApprovalThreshold__c');
            Assert.areEqual(CUSTOM_SETTING_LIMIT, result[0].SignUpPurchaseLimitC, 'Limit should match custom setting DirectDebitApprovalThreshold__c');

            manager.paymentMethodType = null;
            manager.acc.Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
            manager.acc.Monthly_Credit_Limit__c = MONTHLY_CREDIT_LIMIT;
            manager.acc.Sign_up_Purchase_Limit__c = SIGN_UP_PURCHASE_LIMIT;
            manager.acc.Payment_Terms__c = PAYMENT_TERMS;
            manager.acc.Invoice_Terms__c = INVOICE_TERMS;

            result = builder.buildJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
            Assert.areEqual(1, result.size(), 'Result array should contain value');
            assertApprovedPackageLimits(result[0], 'Account');

            manager.acc.Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
            result = builder.buildJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
            Assert.areEqual(1, result.size(), '1 Approval package limit should be returned for MPL');
            assertApprovedPackageLimits(result[0], 'Account');
        Test.stopTest();
    }

    @IsTest
    static void verifyApprovedPackageLimitsBuilderBuildJSONFormatRequest_MPUB() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        populateApprovalsData(manager);

        SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder builder = new SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder();
        builder.init(manager);

        Test.startTest();
            List<POWrappers.ApprovedPackageLimits> result = builder.buildJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
        Test.stopTest();

        Assert.areEqual(1, result.size(), '1 Approval package limit should be returned for MPUB');
        assertApprovedPackageLimits(result[0], 'Approval');
    }

    @IsTest
    static void verifyApprovedPackageLimitsBuilderFormatApprovedPackageLimits() {
        POWrappers.ApprovedPackageLimits approvedPackageLimits = new POWrappers.ApprovedPackageLimits(
            MONTHLY_CREDIT_LIMIT, SIGN_UP_PURCHASE_LIMIT, PAYMENT_TERMS, INVOICE_TERMS
        );
        SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder builder = new SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder();

        Test.startTest();
            String result = builder.formatApprovedPackageLimits(approvedPackageLimits);
        Test.stopTest();

        Assert.areEqual(getApprovedPackageLimitsExpectedResult(), result, 'Limit params should match');
    }

    @IsTest
    static void verifyApprovedPackageLimitsBuilderBuildNotJSONFormatRequest() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c, true)
            .create();

        new SObjectBuilder(DirectDebitApprovalThreshold__c.SObjectType)
            .setField(DirectDebitApprovalThreshold__c.Name, 'RC')
            .setField(DirectDebitApprovalThreshold__c.Brand__c, OpportunityHelper.BRAND_RINGCENTRAL_EU)
            .setField(DirectDebitApprovalThreshold__c.Currency__c, OpportunityHelper.CURRENCY_ISO_CODE_USD)
            .setField(DirectDebitApprovalThreshold__c.ThresholdValue__c, CUSTOM_SETTING_LIMIT)
            .create();

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.acc.Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;
        populateLimitParams(manager);

        SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder builder = new SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder();
        builder.init(manager);

        Test.startTest();
            String result = builder.buildNotJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
            Assert.areEqual(getApprovedPackageLimitsShortExpectedResult(CUSTOM_SETTING_LIMIT, CUSTOM_SETTING_LIMIT), result, 'Limit params should match');

            manager.paymentMethodType = null;
            result = builder.buildNotJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
            Assert.isNull(result, 'Should be null');

            manager.paymentMethodType = POWrappers.PAYMENT_METHOD_INV_FUNNEL;
            result = builder.buildNotJSONFormatRequest(manager.acc, manager.qt, manager.paymentMethodType, manager.approvals);
            Assert.areEqual(getApprovedPackageLimitsExpectedResult(), result, 'Limit params should match');
        Test.stopTest();
    }

    @IsTest
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    static void verifyApprovedPackageLimitsBuilder() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        populateApprovalsData(manager);
        manager.acc.Payment_Method__c = AccountHelper.PAYMENT_METHOD_INVOICE;

        SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder builder = new SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        assertSingleFieldInRequestBody(result, POWrappers.FIELD_NAME_APPROVED_PACKAGE_LIMITS, getApprovedPackageLimitsExpectedResult());
    }

    @IsTest
    static void verifySubscriptionInfoBuilderRemoveMultiproductSystemNameMarker() {
        SignUpRequestBuilderManager.SubscriptionInfoBuilder manager = new SignUpRequestBuilderManager.SubscriptionInfoBuilder();
        Test.startTest();
            String inputWithMarker = 'Account Name [system:123]';
            String expectedOutputWithMarker = 'Account Name';
            String resultWithMarker = manager.removeMultiproductSystemNameMarker(inputWithMarker);

            String inputWithoutMarker = 'Account Name';
            String expectedOutputWithoutMarker = 'Account Name';
            String resultWithoutMarker = manager.removeMultiproductSystemNameMarker(inputWithoutMarker);

            String inputDifferentFormat = 'Account Name [system:abc]';
            String expectedOutputDifferentFormat = 'Account Name';
            String resultDifferentFormat = manager.removeMultiproductSystemNameMarker(inputDifferentFormat);

            String inputSimilarPattern = 'Account Name [system]';
            String expectedOutputSimilarPattern = 'Account Name [system]';
            String resultSimilarPattern = manager.removeMultiproductSystemNameMarker(inputSimilarPattern);
        Test.stopTest();

        Assert.areEqual(expectedOutputWithMarker, resultWithMarker, 'Test case with system name marker failed');
        Assert.areEqual(expectedOutputWithoutMarker, resultWithoutMarker, 'Test case without system name marker failed');
        Assert.areEqual(expectedOutputDifferentFormat, resultDifferentFormat, 'Test case with different format failed');
        Assert.areEqual(expectedOutputSimilarPattern, resultSimilarPattern, 'Test case with similar pattern failed');
    }

    @IsTest
    static void verifySubscriptionInfoBuilderGetCustomAddressAssignmentMap() {
        SignUpRequestBuilderManager.SubscriptionInfoBuilder manager = new SignUpRequestBuilderManager.SubscriptionInfoBuilder();
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Id, ValueProviderBuilder.provideDummyId(QuoteLineItem.SObjectType))
            .quantity(2)
            .build()
            .getRecords();

        Id caId = (Id) ValueProviderBuilder.provideDummyId(CustomAddress__c.SObjectType).getValue();
        List<CustomAddressAssignments__c> caa = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setField(CustomAddressAssignments__c.CustomAddress__c, caId)
            .quantity(2)
            .build()
            .getRecords();

        qlis[0] = (QuoteLineItem) Test_Utils.putIntoUnwritableField(
            qlis[0],
            QuoteLineItem.class,
            'Custom_Address_QLI__r',
            caa
        );

        Test.startTest();
            Map<Id, List<CustomAddressAssignments__c>> result = manager.getCustomAddressAssignmentMap(qlis);
        Test.stopTest();

        Assert.areEqual(1, result.size(), '1 record must be in map');
        Assert.areEqual(2, result.get(caId).size(), '2 CustomAddressAssignments__c must be returned');
    }

    @IsTest
    static void verifySubscriptionInfoBuilder() {
        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => OPP_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Pricebook2 pb = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote officeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Pricebook2Id => pb.Id,
                Quote.End_Date__c => ValueProviderBuilder.provideUniqueDate(),
                Quote.Start_Date__c => ValueProviderBuilder.provideUniqueDate()
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'testProduct',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true,
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_AUTO
            })
            .create()
            .getRecord();

        new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id
            })
            .create();

        PricebookEntry pbe = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => officeQuote.Id,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.PackageInfo__c => '{"id":"1","version":"1","labels":{"shippingReq":"auto"}}'
            })
            .quantity(1)
            .create()
            .getRecords();
        Triggers.switchOn();

        manager.qt = putFieldIntoQuote(officeQuote, 'QuoteLineItems', qlis);
        manager.qt = putFieldIntoQuote(manager.qt, 'Opportunity', opp);
        manager.user = (User) Test_Utils.putIntoUnwritableField(
            manager.user,
            User.class,
            'Name',
            'TestLastName'
        );
        SignUpRequestBuilderManager.SubscriptionInfoBuilder builder = new SignUpRequestBuilderManager.SubscriptionInfoBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        SubscriberInfoBuilder.SubscriberInfo sInfo = (SubscriberInfoBuilder.SubscriberInfo) result.get(POWrappers.FIELD_NAME_SUBSCRIPTION_INFO);
        Assert.isNotNull(sInfo, 'sInfo should be defined');
        Assert.areEqual('TestLastName', sInfo.salesAgentInfo.name, 'Name should match user name');
    }

    @IsTest
    static void verifyTaxSettingsBuilderFormatTaxSetting() {
        NGBSAPI.TaxExemption taxExemption = new NGBSAPI.TaxExemption(
            true,
            false,
            true,
            false,
            true,
            false,
            true,
            'VAT12345',
            'USA',
            'GST67890'
        );

        SignUpRequestBuilderManager.TaxSettingsBuilder manager = new SignUpRequestBuilderManager.TaxSettingsBuilder();

        Test.startTest();
            String result = (String) manager.formatTaxSetting(taxExemption);
        Test.stopTest();

        String expected = '&TAXSETTINGS[federalTaxExemption]=' + taxExemption.getFederalTaxExemption()
            + '&TAXSETTINGS[stateTaxExemption]=' + taxExemption.getStateTaxExemption()
            + '&TAXSETTINGS[countyTaxExemption]=' + taxExemption.getCountyTaxExemption()
            + '&TAXSETTINGS[localTaxExemption]=' + taxExemption.getLocalTaxExemption()
            + '&TAXSETTINGS[salesTaxExemption]=' + taxExemption.getSalesTaxExemption()
            + '&TAXSETTINGS[VATExemption]=' + taxExemption.getVatExemption()
            + '&TAXSETTINGS[VATNumber]=' + taxExemption.getVatNumber()
            + '&TAXSETTINGS[GSTNumber]=' + taxExemption.getGstNumber()
            + '&TAXSETTINGS[SEZWOPExemption]=' + taxExemption.getSezWopExemption()
            + '&TAXSETTINGS[VATExemptionCountry]=' + taxExemption.getVatCountry();

        Assert.areEqual(expected, result, 'The formatted tax setting string is incorrect.');
    }

    @IsTest
    static void verifyTaxSettingsBuilder() {
        Triggers.switchOff();
        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CountryCodes__c.CountryName__c => 'fra;france',
                CountryCodes__c.CountryNameFull__c => 'France',
                CountryCodes__c.Name => 'FRA'
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Acc name',
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'France'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => OPP_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.CurrencyIsoCode => 'EUR',
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote 1'),
                Approval__c.Account__c => acc.Id,
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.VATNumber__c => '22222',
                Approval__c.GstNo__c => '11111',
                Approval__c.SEZWOPExemption__c => TaxExemptionHelper.APPROVED,
                Approval__c.VATExemption__c => TaxExemptionHelper.APPROVED,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL,
                Approval__c.StateTaxExemption__c => TaxExemptionHelper.APPROVED,
                Approval__c.CountyTaxExemption__c => TaxExemptionHelper.APPROVED,
                Approval__c.LocalTaxExemption__c => TaxExemptionHelper.APPROVED,
                Approval__c.FederalTaxExemption__c => TaxExemptionHelper.APPROVED,
                Approval__c.SalesTaxExemption__c => TaxExemptionHelper.APPROVED
            })
            .create();
        Triggers.switchOn();

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        manager.acc = acc;
        manager.qt.ServiceName__c = OpportunityHelper.TIER_OFFICE;
        manager.qt.IsMultiProductTechnicalQuote__c = true;

        SignUpRequestBuilderManager.TaxSettingsBuilder builder = new SignUpRequestBuilderManager.TaxSettingsBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        Map<String, Object> expectedMap = new Map<String, Object> {
            'federalTaxExemption' => true,
            'stateTaxExemption' => true,
            'countyTaxExemption' => true,
            'localTaxExemption' => true,
            'salesTaxExemption' => true,
            'vatExemption' => true,
            'SEZWOPExemption' => true,
            'vatNumber' => '22222',
            'vatCountry' => 'France',
            'gstNumber' => '11111'
        };
        Assert.isNotNull(result.get(POWrappers.FIELD_NAME_TAX_SETTINGS), 'Tax settings should be defined');
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(result.get(POWrappers.FIELD_NAME_TAX_SETTINGS)));

        for (String key : expectedMap.keySet()) {
            Assert.areEqual(expectedMap.get(key), resultMap.get(key), 'Key ' + key + ' should match');
        }
    }

    @IsTest
    static void verifyLBoxOverridesBuilderGetStringLBoxOverrides() {
        List<POWrappers.LboxOverridesRequest> lboxOverridesRequests = new List<POWrappers.LboxOverridesRequest>{
            new POWrappers.LboxOverridesRequest('catalogId1', 1, 10),
            new POWrappers.LboxOverridesRequest('catalogId2', 2, 20)
        };

        SignUpRequestBuilderManager.LBoxOverridesBuilder builder = new SignUpRequestBuilderManager.LBoxOverridesBuilder();

        Test.startTest();
            String result = builder.getStringLBoxOverrides(lboxOverridesRequests);
        Test.stopTest();

        String expected = 'lboxOverrides[0][catalogId]=catalogId1'
            + '&lboxOverrides[0][min]=1'
            + '&lboxOverrides[0][max]=10'
            + '&lboxOverrides[1][catalogId]=catalogId2'
            + '&lboxOverrides[1][min]=2'
            + '&lboxOverrides[1][max]=20';
        Assert.areEqual(expected, result, 'The formatted LBox overrides string is incorrect');
    }

    @IsTest
    static void verifyLBoxOverridesBuilder() {
        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lboxes":[{"elementID":"LB_698","min":0,"max":99999}],"categoryPath":"HD"}';

        SignUpRequestBuilderManager manager = buildManagerWithEngagePackageInfo();
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.Quantity, 1)
            .setField(QuoteLineItem.PackageInfo__c, packageInfoQLI)
            .quantity(1)
            .build()
            .getRecords();

        manager.qt.RecordTypeId = QuoteHelper.RT_ID_POC;
        manager.qt.ServiceName__c = OpportunityHelper.TIER_OFFICE;
        manager.qt.IsMultiProductTechnicalQuote__c = true;
        manager.qt = putFieldIntoQuote(manager.qt, 'QuoteLineItems', qlis);

        SignUpRequestBuilderManager.LBoxOverridesBuilder builder = new SignUpRequestBuilderManager.LBoxOverridesBuilder();
        builder.init(manager);

        Test.startTest();
            Map<String, Object> result = builder.getSignUpParameter();
        Test.stopTest();

        Assert.isNotNull(result.get(POWrappers.FIELD_NAME_LBOX_OVERRIDES), 'Lbox Overrides should be defined');
        List<POWrappers.LboxOverridesRequest> resultList = (List<POWrappers.LboxOverridesRequest>) result.get(POWrappers.FIELD_NAME_LBOX_OVERRIDES);
        Assert.areEqual(1, resultList.size(), 'List should contain 1 item');

        POWrappers.LboxOverridesRequest lBox = resultList[0];
        Assert.areEqual('LB_698', lBox.catalogId, 'must be 1');
        Assert.areEqual(0, lBox.min, 'must be 1');
        Assert.areEqual(99999, lBox.max, 'must be 1');
    }

    private static void assertApprovedPackageLimits(POWrappers.ApprovedPackageLimits result, String objectName) {
        String tmp = 'Param {0} should match value from ' + objectName;
        Assert.areEqual(MONTHLY_CREDIT_LIMIT, result.MonthlyCreditLimitC, String.format(tmp, new List<String> { 'MonthlyCreditLimitC' }));
        Assert.areEqual(SIGN_UP_PURCHASE_LIMIT, result.SignUpPurchaseLimitC, String.format(tmp, new List<String> { 'SignUpPurchaseLimitC' }));
        Assert.areEqual(PAYMENT_TERMS, result.PaymentTermsC, String.format(tmp, new List<String> { 'PaymentTermsC' }));
        Assert.areEqual(INVOICE_TERMS, result.InvoiceTermsC, String.format(tmp, new List<String> { 'InvoiceTermsC' }));
    }

    private static void assertException(String expectedMessage, AquivaHelper.AquivaException actualException) {
        Assert.areEqual(expectedMessage, actualException.getMessage(), 'Unexpected exception was raised');
    }

    private static void assertGetter(Map<String, String> expectedToActual, String getterName) {
        for (String expectedValue : expectedToActual.keySet()) {
            Assert.areEqual(
                expectedValue,
                expectedToActual.get(expectedValue),
                'Wrong ' + getterName + ' was returned'
            );
        }
    }

    private static void assertEmptySignUpRequestBody(Map<String, Object> resultedRequestBodyMap) {
        Assert.isNotNull(resultedRequestBodyMap, ASSERT_MSG_REQUEST_BODY_MAP_SHOULD_NOT_BE_NULL);
        Assert.isTrue(resultedRequestBodyMap.isEmpty(), 'Request body map should be empty');
    }

    private static void assertSignUpRequestBody(Map<String, Object> resultedRequestBodyMap, String expectedField) {
        assertSignUpRequestBody(resultedRequestBodyMap, new Set<String> {expectedField});
    }

    private static void assertSignUpRequestBody(Map<String, Object> resultedRequestBodyMap, Map<String, Object> expectedRequestBodyMap) {
        assertSignUpRequestBody(resultedRequestBodyMap, expectedRequestBodyMap.keySet());
        assertValuesInSignUpRequestBody(resultedRequestBodyMap, expectedRequestBodyMap);
    }

    private static void assertSignUpRequestBody(Map<String, Object> resultedRequestBodyMap, Set<String> expectedFields) {
        Assert.isNotNull(resultedRequestBodyMap, ASSERT_MSG_REQUEST_BODY_MAP_SHOULD_NOT_BE_NULL);
        Assert.areEqual(expectedFields.size(), resultedRequestBodyMap.size(), 'Wrong number of fields was returned');
        for (String key : expectedFields) {
            Assert.isTrue(resultedRequestBodyMap.containsKey(key), 'Key ' + key + ' is missing');
        }
    }

    private static void assertSingleFieldInRequestBody(Map<String, Object> resultedRequestBodyMap, String field, Object expectedValue) {
        assertSignUpRequestBody(resultedRequestBodyMap, field);
        Assert.areEqual(expectedValue, resultedRequestBodyMap.get(field), 'Wrong value for key "' + field + '" was returned');
    }

    private static void assertValuesInSignUpRequestBody(Map<String, Object> resultedRequestBodyMap, Map<String, Object> expectedValues) {
        for (String key : expectedValues.keySet()) {
            Assert.areEqual(
                expectedValues.get(key),
                resultedRequestBodyMap.get(key),
                    'Wrong value was returned for key "' + key + '"'
            );
        }
    }

    private static void assertFailedValidateSignUpRequestBody(SignUpRequestBuilderManager manager, String expectedExceptionMessage) {
        try {
            manager.validateSignUpRequestBody();
            Assert.fail(MUST_THROW_AN_EXCEPTION);
        } catch (AquivaHelper.AquivaException e) {
            assertException(expectedExceptionMessage, e);
        }
    }

    private static void assertGetPackageInfoLimits(Object whenIsNotJSONFormatRequestIsTrue, Object whenIsNotJSONFormatRequestIsFalse) {
        Assert.isTrue(
            whenIsNotJSONFormatRequestIsTrue instanceof String,
            'Should return a String if isNotJSONFormatRequest is true'
        );
        Assert.isTrue(
            whenIsNotJSONFormatRequestIsFalse instanceof List<BillingWrappers.GlobalPackageLimits>,
            'Should return a List of BillingWrappers.GlobalPackageLimits if isNotJSONFormatRequest is false'
        );
    }

    private static void assertGlobalPackageLimits(List<BillingWrappers.GlobalPackageLimits> expectedLimits, List<BillingWrappers.GlobalPackageLimits> actualLimits) {
        Assert.areEqual(expectedLimits.size(), actualLimits.size(), 'Wrong number of limits was returned');
        for (Integer i = 0; i < expectedLimits.size(); i++) {
            BillingWrappers.GlobalPackageLimits expectedLimit = expectedLimits[i];
            BillingWrappers.GlobalPackageLimits actualLimit = actualLimits[i];
            Assert.areEqual(expectedLimit.value, actualLimit.value, 'Wrong value was returned for limit ' + i);
            Assert.areEqual(expectedLimit.code, actualLimit.code, 'Wrong code was returned for limit ' + i);
            Assert.areEqual(expectedLimit.name, actualLimit.name, 'Wrong name was returned for limit ' + i);
            Assert.areEqual(expectedLimit.limitType, actualLimit.limitType, 'Wrong limit type was returned for limit ' + i);
            Assert.areEqual(expectedLimit.scope, actualLimit.scope, 'Wrong scope was returned for limit ' + i);
            Assert.areEqual(expectedLimit.transactionType, actualLimit.transactionType, 'Wrong transaction type was returned for limit ' + i);
            Assert.areEqual(expectedLimit.target, actualLimit.target, 'Wrong target was returned for limit ' + i);
            Assert.areEqual(expectedLimit.isOverride, actualLimit.isOverride, 'Wrong isOverride was returned for limit ' + i);
        }
    }

    private static Opportunity putAccIntoOpp(Opportunity opp, Account acc) {
        return (Opportunity) Test_Utils.putIntoUnwritableField(opp, Opportunity.class, 'Account', acc);
    }

    private static Account putMasterAccIntoAcc(Account techAcc, Account masterAcc) {
        return (Account) Test_Utils.putIntoUnwritableField(techAcc, Account.class, 'Master_Account__r', masterAcc);
    }

    private static Quote putFreeServiceCreditTotalIntoQuote(Quote qt, Decimal fscTotal) {
        return putFieldIntoQuote(qt, 'Free_Service_Credit_Total__c', fscTotal);
    }

    private static Quote putFieldIntoQuote(Quote qt, String field, Object value) {
        return (Quote) Test_Utils.putIntoUnwritableField(qt, Quote.class, field, value);
    }

    private static Quote putFieldIntoQuote(Quote qt, String field, List<SObject> values) {
        return (Quote) Test_Utils.putIntoUnwritableField(
            qt,
            Quote.class,
            field,
            values
        );
    }

    private static void populateLimitParams(SignUpRequestBuilderManager manager) {
        manager.acc.Monthly_Credit_Limit__c = MONTHLY_CREDIT_LIMIT;
        manager.acc.Sign_up_Purchase_Limit__c = SIGN_UP_PURCHASE_LIMIT;
        manager.acc.Payment_Terms__c = PAYMENT_TERMS;
        manager.acc.Invoice_Terms__c = INVOICE_TERMS;

        manager.qt.Total_MRR_with_Taxes__c = MONTHLY_CREDIT_LIMIT;
        manager.qt.Total_One_Time_with_Taxes__c = SIGN_UP_PURCHASE_LIMIT;
        manager.qt.CurrencyIsoCode = OpportunityHelper.CURRENCY_ISO_CODE_USD;
        manager.qt.OpportunityId = (Id) new ValueProvider.DummyIdProvider(Opportunity.SObjectType).getValue();
        manager.qt = putFieldIntoQuote(manager.qt, 'Brand__c', OpportunityHelper.BRAND_RINGCENTRAL_EU);

        manager.paymentMethodType = POWrappers.PAYMENT_METHOD_DD_FUNNEL;
    }

    private static void populateApprovalsData(SignUpRequestBuilderManager manager) {
        Id oppId = (Id) new ValueProvider.DummyIdProvider(Opportunity.SObjectType).getValue();

        manager.qt.OpportunityId = oppId;
        manager.qt.IsMultiProductTechnicalQuote__c = false;
        manager.approvals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.Id => new ValueProvider.DummyIdProvider(Approval__c.SObjectType),
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Monthly_Credit_Limit__c => MONTHLY_CREDIT_LIMIT,
                Approval__c.Sign_Up_Purchase_Limit__c => SIGN_UP_PURCHASE_LIMIT,
                Approval__c.Payment_Terms__c => PAYMENT_TERMS,
                Approval__c.Invoice_Terms__c => INVOICE_TERMS,
                Approval__c.IsMultiProductTechnicalApproval__c => false,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.Sign_Up_Purchase_Limit_Contact_Center__c => -1,
                Approval__c.Sign_Up_Purchase_Limit_Engage_Voice__c => -1,
                Approval__c.Sign_Up_Purchase_Limit_Engage_Digital__c => -1,
                Approval__c.Sign_Up_Purchase_Limit_Office__c => -1,
                Approval__c.Sign_Up_Purchase_Limit_for_RC_Events__c => -1,
                Approval__c.Monthly_Credit_Limit_Office__c => -1,
                Approval__c.Monthly_Credit_Limit_Contact_Center__c => -1,
                Approval__c.Monthly_Credit_Limit_Engage_Voice__c => -1,
                Approval__c.Monthly_Credit_Limit_Engage_Digital__c => -1,
                Approval__c.Monthly_Credit_Limit_for_RC_Events__c  => -1,
                Approval__c.Opportunity__c =>  ValueProviderBuilder.provideList(new List<Id> { oppId, null })
            })
            .quantity(2)
            .build()
            .getRecords();
    }

    private static BillingWrappers.QuotePackageInfo getEngagePackageInfo() {
        return ((List<BillingWrappers.QuotePackageInfo>)
            JSON.deserialize(PACKAGE_INFO_ENGAGE, List<BillingWrappers.QuotePackageInfo>.class)
        )[0];
    }

    private static String getApprovedPackageLimitsShortExpectedResult(Decimal monthlyCreditLimit, Decimal signUpLimit) {
        return 'APPROVEDPACKAGELIMITS[0][MonthlyCreditLimitC]=' + NumberHelper.toNumber(monthlyCreditLimit).toPlainString()
            + '&APPROVEDPACKAGELIMITS[0][SignUpPurchaseLimitC]=' + NumberHelper.toNumber(signUpLimit).toPlainString();
    }

    private static String getApprovedPackageLimitsExpectedResult() {
        return getApprovedPackageLimitsShortExpectedResult(MONTHLY_CREDIT_LIMIT, SIGN_UP_PURCHASE_LIMIT)
            + '&APPROVEDPACKAGELIMITS[0][PaymentTermsC]=' + PAYMENT_TERMS
            + '&APPROVEDPACKAGELIMITS[0][InvoiceTermsC]=' + INVOICE_TERMS;
    }

    private static BillingWrappers.QuotePackageInfo buildEngagePackageInfo() {
        return buildPackageInfo(Product2Helper.PRODUCT_ID_ENGAGE_DIGITAL_STANDALONE);
    }

    private static BillingWrappers.QuotePackageInfo buildPackageInfo(String productId) {
        BillingWrappers.PackageInfo innerPackageInfo = new BillingWrappers.PackageInfo();
        innerPackageInfo.name = PACKAGE_NAME;
        innerPackageInfo.catalogId = DUMMY_CATALOG_ID;
        innerPackageInfo.version = PACKAGE_VERSION_FOR_ENGAGE;

        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        packageInfo.id = PACKAGE_ID_FOR_ENGAGE;
        packageInfo.version = PACKAGE_VERSION_FOR_ENGAGE;
        packageInfo.productName = QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT;
        packageInfo.productId = productId;
        packageInfo.packageInfo = innerPackageInfo;
        packageInfo.offerType = QuoteHelper.OFFER_TYPE_REGULAR;

        return packageInfo;
    }

    private static BillingWrappers.PartnerPackageInfo buildPartnerPackageInfo() {
        BillingWrappers.PartnerPackageInfo partnerPackageInfo = new BillingWrappers.PartnerPackageInfo();
        partnerPackageInfo.id = PARTNER_ID;
        partnerPackageInfo.version = PARTNER_VERSION;

        return partnerPackageInfo;
    }

    private static Map<String, Object> buildDummyRequestBodyMap(Set<String> fields) {
        Map<String, Object> requestBodyMap = new Map<String, Object>();
        for (String field : fields) {
            requestBodyMap.put(field, DUMMY_VALUE);
        }

        return requestBodyMap;
    }

    private static BillingWrappers.GlobalPackageLimits buildGlobalPackageLimits() {
        BillingWrappers.GlobalPackageLimits packageLimit = new BillingWrappers.GlobalPackageLimits();
        packageLimit.value = DUMMY_VALUE;
        packageLimit.code = TEST_PACKAGE_LIMIT_CODE;
        packageLimit.name = TEST_PACKAGE_LIMIT_CODE;
        packageLimit.limitType = null;
        packageLimit.scope = 'BillingCycle';
        packageLimit.transactionType = 'Any';
        packageLimit.target = 'Global';
        packageLimit.isOverride = null;

        return packageLimit;
    }

    private static List<BillingWrappers.GlobalPackageLimits> buildListOfGlobalPackageLimits() {
        return new List<BillingWrappers.GlobalPackageLimits> { buildGlobalPackageLimits() };
    }

    private static BillingWrappers.NGBSPackage buildNGBSPackage() {
        BillingWrappers.BillingLabels billingLabels = new BillingWrappers.BillingLabels();
        billingLabels.signup_sfdc = new List<String> {'Active'};

        BillingWrappers.NGBSPackage ngbsPackage = new BillingWrappers.NGBSPackage();
        ngbsPackage.id = PACKAGE_ID_FOR_ENGAGE;
        ngbsPackage.version = PACKAGE_VERSION_FOR_ENGAGE;
        ngbsPackage.catalogId = DUMMY_CATALOG_ID;
        ngbsPackage.labels = billingLabels;
        ngbsPackage.globalPackageLimits = buildListOfGlobalPackageLimits();

        return ngbsPackage;
    }

    private static POWrappers.SignUpParams buildSignUpParams() {
        Quote quoteWithPackageInfo = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Package_Info__c, PACKAGE_INFO_ENGAGE)
            .build()
            .getRecord();

        return buildSignUpParams(quoteWithPackageInfo);
    }

    private static POWrappers.SignUpParams buildSignUpParams(BillingWrappers.QuotePackageInfo pInfo) {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => JSON.serialize(new List<BillingWrappers.QuotePackageInfo> {pInfo}),
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE
            })
            .build()
            .getRecord();
        return buildSignUpParams(qt);
    }

    private static POWrappers.SignUpParams buildSignUpParams(Quote qt) {
        return buildSignUpParams(qt, new Opportunity());
    }

    private static POWrappers.SignUpParams buildSignUpParams(Quote qt, Opportunity opp) {
        Opportunity oppWithAcc = putAccIntoOpp(opp, new Account());

        POWrappers.SignUpParams testData = new POWrappers.SignUpParams();
        testData.user = new User();
        testData.opportunity = oppWithAcc;
        testData.targetQuote = qt;
        testData.boundAccs = new List<Account>();
        return testData;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void verifyAccountInfoBuilder() {
        final String APPROVED_BI_ID = '12345';
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'Test acc',
                    Account.Billing_ID__c => '123456768'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAcc.Id,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

            Contact testCon = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.FirstName => 'test contact',
                Contact.LastName => 'Events',
                Contact.Email => 'abc@nbg.com',
                Contact.Phone => '1234567890'
            })
            .create()
            .getRecord();

        BillingWrappers.QuotePackageInfo packageInfo = new BillingWrappers.QuotePackageInfo();
        packageInfo.packageInfo.catalogId = '5';
        packageInfo.packageInfo.version = '1';
        packageInfo.duration = 'Monthly';

        SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(buildSignUpParams(packageInfo));
        manager.pInfo.packageBusinessIdentities.approvedBi = new BillingWrappers.BusinessIdentity();
        manager.pInfo.packageBusinessIdentities.approvedBi.id = APPROVED_BI_ID;
        manager.qt.OpportunityId = testOpp.Id;
        manager.qt.ServiceName__c = Constants.CONST_RC_EVENT;
        manager.qt.IsMultiProductTechnicalQuote__c = true;    
        manager.opp = testOpp;
        manager.acc = testAcc;
        manager.acc.BillingStreet = '123 Main St';
        manager.acc.BillingCity = 'New York';
        manager.acc.BillingState = 'NY';
        manager.acc.BillingPostalCode = '10001';
        manager.acc.BillingCountry = 'United States';
        manager.acc.Internal_Enterprise_Account_ID__c = INTERNAL_ENTERPRISE_ACCOUNT_ID;
        manager.timezoneName = 'America/New_York';
        manager.qt.PaymentMethod__c = 'Credit Card';
        manager.contractDescription = 'Test contract description';
        manager.qt.Initial_Term_months__c = '12';
        manager.qt.Auto_Renewal__c = true;
        manager.qt.Term_months__c = '12';
        
        SignUpRequestBuilderManager.AccountInfoBuilder builder = new SignUpRequestBuilderManager.AccountInfoBuilder();
        builder.init(manager);

        Test.startTest();
            builder.m.isMPUB = true;
            Map<String, Object> whenMPUB = builder.getSignUpParameter();
        Test.stopTest();
        assertSignUpRequestBody(whenMPUB, POWrappers.FIELD_NAME_ACCOUNT);
    }

    private static SignUpRequestBuilderManager buildEmptyManager() {
        return new SignUpRequestBuilderManager(buildSignUpParams());
    }

    private static SignUpRequestBuilderManager buildManagerWithEngagePackageInfo() {
        return buildSignUpRequestBuilderManager(buildEngagePackageInfo());
    }

    private static SignUpRequestBuilderManager buildSignUpRequestBuilderManager(BillingWrappers.QuotePackageInfo pInfo) {
        return new SignUpRequestBuilderManager(buildSignUpParams(pInfo));
    }
}