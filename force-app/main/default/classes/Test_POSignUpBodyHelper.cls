@IsTest
private class Test_POSignUpBodyHelper {
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
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        // Create NGBS Settings with billing credentials
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'https://testapi',
                NGBS_Settings__c.AccountManagerPath__c => '/restapi/account-manager/v1.0',
                NGBS_Settings__c.Login__c => 'testLogin',
                NGBS_Settings__c.Password__c => 'testPassword'
            })
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
        testQuote.ServiceName__c = OpportunityHelper.TIER_PROFESSIONAL_SERVICES;
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
        
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.endpointToBodyMap = new Map<String, BillingHttpRequestMock.MockInfo>{
            '/summary?shortView=true' => new BillingHttpRequestMock.MockInfo('{"packages":[{"id":9710001,"catalogId":"100","version":"1","offerType":"Regular"}]}')
        };
        Test.setMock(HttpCalloutMock.class, testMock);

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
}