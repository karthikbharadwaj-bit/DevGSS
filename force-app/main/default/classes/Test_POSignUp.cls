@IsTest
private class Test_POSignUp {
    @TestSetup
    static void setup() {
        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.BaseEndpoint__c => 'https://fake-icb-api',
                CCB_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                CCB_Settings__c.SignUpPath__c => '/sign-up',
                CCB_Settings__c.TerminationPath__c => '/termination/enterprise-account-id',
                CCB_Settings__c.CountriesPath__c => '/countries',
                CCB_Settings__c.DirectBaseEndpoint__c => 'http://ext-ccb.cre-dev.lab.engage.ringcentral.com/restapi',
                CCB_Settings__c.EDPlatformsPath__c => '/engage-digital/platforms',
                CCB_Settings__c.EDSubmit__c => '/engage-digital/sign-up/opportunity',
                CCB_Settings__c.EVPlatformsPath__c => '/engage-voice/platforms',
                CCB_Settings__c.EVSubmit__c => '/engage-voice/sign-up/opportunity',
                CCB_Settings__c.ValidatePath__c => '/address/validate',
                CCB_Settings__c.APIVersion2Path__c => '/v2.0/ccb',
                CCB_Settings__c.APIVersion3Path__c => '/v3.0/ccb'
            })
            .create();

        new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.BaseEndpoint__c => 'https://fake-icb-api',
                ICB_Settings__c.ChangePath__c => '/change',
                ICB_Settings__c.ValidatePath__c => '/address/validate',
                ICB_Settings__c.CasePath__c => '/sign-up/case',
                ICB_Settings__c.SignUpPath__c => '/sign-up',
                ICB_Settings__c.DictionariesPath__c => '/dictionaries',
                ICB_Settings__c.APIVersion1Path__c => '/v1/sfdc',
                ICB_Settings__c.APIVersion2Path__c => '/v2/sfdc',
                ICB_Settings__c.ChangeCasePath__c => '/change/case'
            })
            .create();
    }

    @isTest
    static void testUILessEngageSignUpRunner_MPUB() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock(CCBAPIMock.MPFlow.MPUB));
        POHelper.isEngageUILessSettingsOn = true;
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        POSignUp.EngageSignUpRunner runner = new POSignUp.EngageSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        runner.opportunity = buildOpportunityForSignUp();

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.isTrue(resp.messages.isEmpty(), 'The response has unexpected error messages');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
    }

    @isTest
    static void testUILessEngageSignUpRunner_MPLite() {
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock(CCBAPIMock.MPFlow.MP_LITE));
        POHelper.isEngageUILessSettingsOn = true;
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .create();

        POSignUp.EngageSignUpRunner runner = new POSignUp.EngageSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        runner.opportunity = buildOpportunityForSignUp();

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.isTrue(resp.messages.isEmpty(), 'The response has unexpected error messages');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
    }

    @isTest
    static void testUILessEngageSignUpRunner_UISignUp() {
        POHelper.isEngageUILessSettingsOn = false;
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProduct__c, true)
            .create();

        POSignUp.EngageSignUpRunner runner = new POSignUp.EngageSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object> {
            'test_key' => 'test_value',
            'test_empty_key' => '',
            'LboxOverrides' => '[]'
        });
        runner.opportunity = buildOpportunityForSignUp();
        runner.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.sObjectType),
                Quote.ServiceName__c => OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                Quote.IsMultiProductTechnicalQuote__c => true
            })
            .build()
            .getRecord();

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.isTrue(resp.messages.isEmpty(), 'The response has unexpected error messages');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
        Assert.areEqual('test_key=test_value&[]', runner.getRequestBody(), 'Wrong request body');
    }

    @isTest
    static void testFaxSignUpRunner() {
        final String faxSignUpUrl = 'fax/signup';
        new SObjectBuilder(EndpointsSettings__c.sObjectType)
            .setField(EndpointsSettings__c.Fax_US_SignUp_Endpoint__c, faxSignUpUrl)
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Brand_Name__c, OpportunityHelper.BRAND_RINGCENTRAL)
            .build()
            .getRecord();
        
        POSignUp.SignUpRunner runner = new POSignUp.FaxSignUpRunner();
        runner.opportunity = opp;

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.getData('status'), 'The response status is not success');
        Assert.areEqual(faxSignUpUrl, resp.getData('redirectUrl'), 'The response redirect URL is not correct');
    }

    @isTest
    static void testMVPSignUpRunner() {
        String FSG_ID = '770fd3777c5cc6f42148f809fea34bbbf952563730a25ae661bbf5ea580f23e9_rcprod0';
        String IN_PROCESS = 'IN_PROCESS';

        FunnelApiMock testMock = new FunnelApiMock();
        testMock.response = '{"result": {"orderStatus": "' + IN_PROCESS + '"},"FSG_SID": "' + FSG_ID + '","id": null}';
        Test.setMock(HttpCalloutMock.class, testMock);

        Triggers.switchOff();
        new SObjectBuilder(GW_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                GW_Settings__c.BaseEndpoint__c => 'https://testfsgapi',
                GW_Settings__c.BaseEndpoint_EUR__c => 'https://testfsgapi',
                GW_Settings__c.Source__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.SignUpPath__c => '/wsx/signup/v1.0/',
                GW_Settings__c.SFAPath__c => '/api/projects/ws/saf_auxiliary_services/'
            })
            .create();

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.RC_Account_Status__c => AccountHelper.ACCOUNT_STATUS_SUSPENDED,
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Id => ValueProviderBuilder.provideDummyId(Opportunity.sObjectType),
                Opportunity.AccountId => acc.Id
            })
            .build()
            .getRecord();
        Triggers.switchOn();

        POSignUp.MVPSignUpRunner runner = new POSignUp.MVPSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object> { 'requestBodyMap' => '{}' });
        runner.opportunity = putAccountInOpportunity(opp, acc);

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.areEqual(IN_PROCESS, resp.getData('message'), 'Incorrect message was returned');

        acc = (Account) new ListOptional(new AccountSelector()
            .selectAccountById(acc.Id)
            .withoutSelectorFieldsIncluded()
            .selectFields(new List<SObjectField> {
                Account.Internal_Enterprise_Account_ID__c,
                Account.RC_Account_Status__c
            })
            .executeQuery()
        ).getFirst();

        Assert.areEqual(FSG_ID, acc.Internal_Enterprise_Account_ID__c, 'Internal Enterprise Account should be updated correctly');
        Assert.isNull(acc.RC_Account_Status__c, 'RC account status shoulb be null');
    }

    @isTest
    static void testRCCCSignUpRunner_MPL() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        POSignUp.RCCCSignUpRunner runner = new POSignUp.RCCCSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        runner.opportunity = buildOpportunityForSignUp();
        runner.opportunity.Account.IsMultiProductTechnicalAccount__c = true;

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.areEqual('MPL endpoint is used', resp.messages[0].messageDetails.normalizeSpace(), 'The response has unexpected error messages');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status,'Wrong status was returned');
    }

    @isTest
    static void testRCCCSignUpRunner_MPUB() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        POSignUp.RCCCSignUpRunner runner = new POSignUp.RCCCSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        runner.opportunity = buildOpportunityForSignUp();

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.areEqual('MPUB endpoint is used', resp.messages[0].messageDetails.normalizeSpace(), 'The response has unexpected error messages');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
    }

    @isTest
    static void testRCCCSyncRunner() {
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        POSignUp.RCCCSyncRunner runner = new POSignUp.RCCCSyncRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());

        Test.startTest();
            Response resp = runner.signUp();
        Test.stopTest();

        Assert.areEqual(ICBAPI.SYNC_ICB_FAILED, resp.messages[0].message, 'Wrong message was returned');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
    }

    @isTest
    static void testUISignUP_positive() {
        Triggers.switchOff();
        Profile sysAdminProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<String> {ProfileHelper.SYSTEM_ADMIN})
            .executeQuery()
            .get(0);

        User testUser = (User) new SObjectBuilder(User.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.Username => 'testDocusignCLM!user@gmail.com',
                User.LastName => 'testUser',
                User.Email => 'testUser@gmail.com',
                User.Alias => 'testUser',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LocaleSidKey => 'en_US',
                User.EmailEncodingKey => 'UTF-8',
                User.ProfileId => sysAdminProfile.Id,
                User.LanguageLocaleKey => 'en_US'
            })
            .create()
            .getRecord();

        System.runAs(testUser) {    
            Quote targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER,
                    Quote.IsMultiProductTechnicalQuote__c => true
                })
                .build()
                .getRecord();
            POSignUp.UISignUP uiSignUp = new POSignUp.UISignUP(targetQuote, '');
    
            Test.startTest();
                Response resp = uiSignUp.proceedDefaultSignUp();
            Test.stopTest();
            Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
        }
    }


    @isTest
    static void testUISignUP_negative() {
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Package_Info__c => 'broken string0',
                Quote.IsMultiProductTechnicalQuote__c => false
            })
            .build()
            .getRecord();
        POSignUp.UISignUP uiSignUp = new POSignUp.UISignUP(qt, '');

        Test.startTest();
            Response resp = uiSignUp.proceedDefaultSignUp();
        Test.stopTest();

        Assert.areEqual(Label.Opportunity_SignUp_Validation_SignUp_failed, resp.messages[0].message, 'Wrong message was returned');
        Assert.isNotNull(resp.messages[0].messageDetails, 'Message details should exist');
    }

    @isTest
    static void testBuildSignUpBody() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();
        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPriceBookId()
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(),
                    Product2.GOA_Group_V3__c => '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry pbe = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => pbe.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.Package_Info__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.Package_Info_QLI__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    QuoteLineItem.Discount => 24
                }
            )
            .create()
            .getRecord();

        User usr = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.FirstName => 'John',
                User.LastName => 'Good',
                User.PID__c => 'JohnGoodTestPID',
                User.Country__c => 'United States',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        POWrappers.SignUpParams data = new POWrappers.SignUpParams();
        testQuote = (Quote) new ListOptional(new QuoteSelector()
            .selectQuotesForMultiSignUp(new Set<Id> { testQuote.Id })
            .executeQuery()
        ).getFirst();
        testQuote.IsMultiProductTechnicalQuote__c = true;
        testQuote.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
        data.targetQuote = testQuote;

        data.opportunity = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunitiesForSignUp(new List<Object> {
                new Set<Id> { testQuote.OpportunityId }
            })
            .executeQuery()
        ).getFirst();
        data.boundAccs = new List<Account>();
        data.user = usr;
        data.promotions = new List<Promotion__c>();
        data.approvals = new List<Approval__c>();

        Test.startTest();
            POSignUpBodyHelper.SignUpBodyBuilder signUpBodyBuilder = new POSignUpBodyHelper.SignUpBodyBuilder();
            POWrappers.SignUpRequestBody body = signUpBodyBuilder.buildBody(data);
        Test.stopTest();

        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getQuotePackage(testQuote);
        Map<String, Object> expectedValuesMap = new Map<String, Object> {
            'OfferType' => QuoteHelper.OFFER_TYPE_BUY,
            'SPID' => usr.PID__c,
            'PaymentMethodType' => POWrappers.PAYMENT_METHOD_CC_FUNNEL,
            'OPPID' => testOpp.Id,
            'BC' => '0',
            'OrderId' => testQuote.Id,
            'PlanDuration' => pInfo.duration,
            'businessIdentityId' => Integer.valueOf(pInfo.packageBusinessIdentities.approvedBi.id),
            'PackageName' => pInfo.packageInfo.name,
            'PackageID' => pInfo.packageInfo.catalogId,
            'PackageVersion' => pInfo.packageInfo.version,
            'DefaultPackageLimits' => pInfo.globalPackageLimits,
            'ExemptFromStateAndLocalTaxes' => false,
            'invoiceConsolidationEnabled' => true,
            'billingAlignmentEnabled' => true,
            'RCBS' => true
        };

        for (String key : expectedValuesMap.keySet()) {
            Assert.areEqual(
                JSON.serialize(expectedValuesMap.get(key)),
                JSON.serialize(body.requestBodyMap.get(key)),
                'Incorrect ' + key + ' data'
            );
        }
    }

    @isTest
    static void testBuildSignUpProServBody() {
        Triggers.switchOff();
        
        new SObjectBuilder(NGBS_Settings__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi/',
                NGBS_Settings__c.CatalogPath__c => '/restapi/v1.0/catalog',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.InvoiceEnginePath__c => '/restapi/invoice-engine/v1.0',
                NGBS_Settings__c.Login__c => 'testLogin',
                NGBS_Settings__c.Password__c => 'testPassword'
            })
            .create();
            
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

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

        Quote testQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => testOpp.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_REQUIRED,
                Quote.isPrimary__c => true,
                Quote.Pricebook2Id => Test.getStandardPriceBookId(),
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Quote.PaymentMethod__c => QuoteHelper.PAYMENT_METHOD_CREDIT_CARD
            })
            .create()
            .getRecord();

        Product2 testProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Product2.Name => ValueProviderBuilder.provideUniqueString('test product'),
                    Product2.IsActive => true,
                    Product2.Sub_Category__c => 'Main',
                    Product2.ExtID__c => ValueProviderBuilder.provideUniqueString(),
                    Product2.GOA_Group_V3__c => '{"regular":"GOA_RC_Office","contracted":"GOA_RC_Office"}'
                }
            )
            .create()
            .getRecord();

        PriceBookEntry pbe = (PriceBookEntry) new SobjectBuilder(PriceBookEntry.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    PriceBookEntry.Product2Id => testProduct.Id,
                    PriceBookEntry.UnitPrice => 100,
                    PriceBookEntry.IsActive => true,
                    PriceBookEntry.Pricebook2Id => Test.getStandardPriceBookId()
                }
            )
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    QuoteLineItem.QuoteId => testQuote.Id,
                    QuoteLineItem.PriceBookEntryId => pbe.Id,
                    QuoteLineItem.Product2Id => testProduct.Id,
                    QuoteLineItem.UnitPrice => 100,
                    QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE,
                    QuoteLineItem.Quantity => 10,
                    QuoteLineItem.Package_Info__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.Package_Info_QLI__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo(),
                    QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    QuoteLineItem.Discount => 24
                }
            )
            .create()
            .getRecord();

        User usr = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                User.FirstName => 'John',
                User.LastName => 'Good',
                User.PID__c => 'JohnGoodTestPID',
                User.Country__c => 'United States',
                User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN
            })
            .create()
            .getRecord();

        Approval__c approval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Account__c, testAcc.Id)
            .setField(Approval__c.Opportunity__c, testOpp.Id)
            .setField(Approval__c.Status__c, 'Approved')
            .create()
            .getRecord();

        Triggers.switchOn();

        POWrappers.SignUpParams data = new POWrappers.SignUpParams();
        testQuote = (Quote) new ListOptional(new QuoteSelector()
            .selectQuotesForMultiSignUp(new Set<Id> { testQuote.Id })
            .executeQuery()
        ).getFirst();
        testQuote.IsMultiProductTechnicalQuote__c = true;
        data.targetQuote = testQuote;

        data.opportunity = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunitiesForSignUp(new List<Object> {
                new Set<Id> { testQuote.OpportunityId }
            })
            .executeQuery()
        ).getFirst();
        
        data.boundAccs = new List<Account>();
        data.user = usr;
        data.promotions = new List<Promotion__c>();
        data.approvals = new List<Approval__c>();
        data.opportunity.Account = testAcc;

        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Test.startTest();
            POSignUpBodyHelper.ProServSignUpBodyBuilder proServSignUpBodyBuilder = new POSignUpBodyHelper.ProServSignUpBodyBuilder();
            POWrappers.SignUpRequestBody body = proServSignUpBodyBuilder.buildBody(data);
        Test.stopTest();
        BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getQuotePackage(testQuote);

        Map<String, Object> serviceInfoMap = (Map<String, Object>) body.requestBodyMap.get('serviceInfo');
        Map<String, Object> packageInfoMap = (Map<String, Object>) serviceInfoMap.get('package');

        Assert.areEqual(testAcc.Billing_ID__c, body.requestBodyMap.get('billingAccountId'), 'Billing Account Id in request body should be from testAcc');
        Assert.areEqual(testOpp.Id, body.requestBodyMap.get('salesOrderId'), 'Billing Account Id in request body should be from testAcc');
        Assert.areEqual(pInfo.duration, serviceInfoMap.get('duration'), 'Duration should be from package info generated for testQuote');
        Assert.areEqual(pInfo.packageInfo.catalogId, packageInfoMap.get('id'), 'Package id should be from package info generated for testQuote');
        Assert.areEqual(pInfo.packageInfo.version, packageInfoMap.get('version'), 'Package version should be from package info generated for testQuote');
    }

    private static Opportunity buildOpportunityForSignUp() {
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Account',
                Account.Id => ValueProviderBuilder.provideDummyId(Account.sObjectType),
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .build()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Id => ValueProviderBuilder.provideDummyId(Opportunity.sObjectType),
                Opportunity.AccountId => acc.Id
            })
            .build()
            .getRecord();

        return putAccountInOpportunity(opp, acc);
    }

    private static Opportunity putAccountInOpportunity(Opportunity opp, Account acc) {
        Map<String, Object> oppRecordMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(opp));
        oppRecordMap.put('Account', acc);

        return (Opportunity) JSON.deserialize(JSON.serialize(oppRecordMap), Opportunity.class);
    }

    @isTest
    static void testProserveRunner() {
        
        new SObjectBuilder(GW_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                GW_Settings__c.BaseEndpoint__c => 'https://testfsgapi',
                    GW_Settings__c.BaseEndpoint_EUR__c => 'https://testfsgapi',
                    GW_Settings__c.Source__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.SignUpPath__c => '/wsx/signup/v1.0/',
                    GW_Settings__c.SFAPath__c => '/api/projects/ws/saf_auxiliary_services/'
                    })
            .create();
        
        FunnelApiProServMock testMock = new FunnelApiProServMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        
        POSignUp.ProServSignUpRunner runner = new POSignUp.ProServSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        
        Test.startTest();
        Response resp = runner.signUp();
        Test.stopTest();
        
        //Assert.areEqual(ICBAPI.SYNC_ICB_FAILED, resp.messages[0].message, 'Wrong message was returned');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
    }
    @isTest
    static void testEventsSignUpRunner() {
        
        new SObjectBuilder(RCSequence__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RCSequence__c.SubSequence__c => 134,
                    RCSequence__c.SandboxNumber__c => 4
                    })
            .create();
        
        new SObjectBuilder(GW_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                GW_Settings__c.BaseEndpoint__c => 'https://testfsgapi',
                    GW_Settings__c.BaseEndpoint_EUR__c => 'https://testfsgapi',
                    GW_Settings__c.Source__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.SignUpPath__c => '/wsx/signup/v1.0/',
                    GW_Settings__c.SFAPath__c => '/api/projects/ws/saf_auxiliary_services/'
                    })
            .create();
        
        FunnelApiProServMock testMock = new FunnelApiProServMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        
        POSignUp.EventsSignUpRunner runner = new POSignUp.EventsSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        
        Test.startTest();
        Response resp = runner.signUp();
        Test.stopTest();
        
        //Assert.areEqual(ICBAPI.SYNC_ICB_FAILED, resp.messages[0].message, 'Wrong message was returned');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Wrong status was returned');
    }
    @isTest
    static void testEventsSignUpRunnerError() {
        
        new SObjectBuilder(RCSequence__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                RCSequence__c.SubSequence__c => 134,
                    RCSequence__c.SandboxNumber__c => 4
                    })
            .create();
        
        new SObjectBuilder(GW_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                GW_Settings__c.BaseEndpoint__c => 'https://testfsgapi',
                    GW_Settings__c.BaseEndpoint_EUR__c => 'https://testfsgapi',
                    GW_Settings__c.Source__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                    GW_Settings__c.SignUpPath__c => '/wsx/signup/v1.0/',
                    GW_Settings__c.SFAPath__c => '/api/projects/ws/saf_auxiliary_services/'
                    })
            .create();
        
        FunnelErrorMock testMockClass = new FunnelErrorMock();
        Test.setMock(HttpCalloutMock.class, testMockClass);
        
        POSignUp.EventsSignUpRunner runner = new POSignUp.EventsSignUpRunner();
        runner.body = new POWrappers.SignUpRequestBody(new Map<String, Object>());
        
        Test.startTest();
        Response resp = runner.signUp();
        
        Test.stopTest();
        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Error from Funnel');
        
    }
}