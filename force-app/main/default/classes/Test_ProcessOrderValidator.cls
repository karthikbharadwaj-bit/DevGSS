@isTest
public with sharing class Test_ProcessOrderValidator {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String OPP_NAME = 'Test Opportunity';
    private static final String TEST_QUOTE_NAME = 'Test Office Quote';
    private static final String USER_IS_REQUIRED = 'User is required';
    private static final String ENGAGE_PACKAGE_INFO_WITH_CONTRACT = '[{"id":"5","version":"3","packageInfo":{"catalogId":"5","version":"3","name":"Engage Digital Standalone"},"productName":"Engage Digital Standalone","productId":"7","duration":"Annual","edition":{"id":1,"name":"Standard"},"contract":{"id":"a8f8K0000008OgUQAU","extId":"EV_Standalone","billingId":null},"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT","name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],"override":false}],"permissions":null,"packageBusinessIdentities":{"selectedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"defaultBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}},"approvedBi":{"name":"Avaya Cloud Office","isDefault":true,"id":20,"address":{"zip":"94002","street2":"","street1":"20 Davis Dr","state":"CA","phone":"","lastName":"","label":null,"firstName":"RingCentral, Inc.","county":"","country":"USA","city":"Belmont"}}}}]';

    @testSetup
    static void initData() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true,
                Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c => true
            })
            .create();

        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ACCOUNT_NAME,
                Account.RC_User_ID__c => '12345',
                Account.Billing_ID__c => '123456789',
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Package__c pkg = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setField(Package__c.Account__c, acc.Id)
            .setField(Package__c.Account_Package_Id__c, '1231231231')
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => OPP_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
            })
            .create()
            .getRecord();

        Pricebook2 pb = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Pricebook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                Pricebook2.IsActive => true,
                Pricebook2.Line_Range_Min__c => 2,
                Pricebook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                Pricebook2.AllowedRecordType__c => QuoteHelper.ALLOWED_RT_NAME_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Quote officeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => TEST_QUOTE_NAME,
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo(),
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(30),
                Quote.Pricebook2Id => pb.Id
            })
            .create()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'testProduct',
                Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                Product2.IsActive => true
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

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => officeQuote.Id,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.PricebookEntryId => pbe.Id,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.UnitPrice => 100,
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo()
            })
            .create();
        Triggers.switchOn();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidateMPUB() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Quote qt = selectQuote();
        Account acc = selectAccount();

        Opportunity opp = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForSignUp(new Set<Id> {qt.OpportunityId})
            .executeQuery()
        ).getFirst();

        POWrappers.SignUpParams signUpParams = buildSignUpParams(opp, acc, qt);
        signUpParams.primaryQuote = qt;
        Test.startTest();
        Response resp = ProcessOrderValidator.validate(new List<POWrappers.SignUpParams> { signUpParams });
        Test.stopTest();

        assertSuccessResponse(resp);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidateMPL_positive() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Quote qt = selectQuote();
        Account acc = selectAccount();

        Opportunity opp = new Opportunity(Id = qt.OpportunityId);

        Triggers.switchOff();
        acc.IsMultiProductTechnicalAccount__c = true;
        opp.IsMultiProductTechnicalOpportunity__c = true;
        update new List<SObject> { acc, opp };
        Triggers.switchOn();

        opp = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForSignUp(new Set<Id> { qt.OpportunityId })
            .executeQuery()
        ).getFirst();

        POWrappers.SignUpParams signUpParams = buildSignUpParams(opp, acc, qt);

        Test.startTest();
        Response resp = ProcessOrderValidator.validate(new List<POWrappers.SignUpParams> { signUpParams });
        Test.stopTest();

        assertSuccessResponse(resp);
    }

    @isTest
    static void testValidateMPL_negative() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());
        Quote qt = selectQuote();
        qt.Status = null;
        qt.QuoteType__c = null;
        qt.Package_Info__c = ENGAGE_PACKAGE_INFO_WITH_CONTRACT;

        Account acc = selectAccount();

        Opportunity opp = new Opportunity(Id = qt.OpportunityId);

        Triggers.switchOff();
        acc.IsMultiProductTechnicalAccount__c = true;
        opp.IsMultiProductTechnicalOpportunity__c = true;
        update new List<SObject> { acc, opp };
        Triggers.switchOn();

        opp = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForSignUp(new Set<Id> { qt.OpportunityId })
            .executeQuery()
        ).getFirst();

        POWrappers.SignUpParams signUpParams = buildSignUpParams(opp, acc, qt);

        Test.startTest();
        Response resp = ProcessOrderValidator.validate(new List<POWrappers.SignUpParams> { signUpParams });
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.isFalse(resp.messages.isEmpty(), 'There should be message');
        Assert.areEqual(Label.Opportunity_SignUp_Active_Agreement_Fail, resp.messages[0].messageDetails, 'There should be correct message');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidateWithEmptyData() {
        Test.startTest();
        Response resp = ProcessOrderValidator.validate(new List<POWrappers.SignUpParams>());
        Test.stopTest();

        assertInvalidResponse(resp);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidateWithNullData() {
        Test.startTest();
        Response resp = ProcessOrderValidator.validate(null, true);
        Test.stopTest();

        assertInvalidResponse(resp);
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testValidateExistingBusinessRCCC() {
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        testMock.body = '{"id":1111, "packages":[{"id":2222,"status":"Active"}]}';
        testMock.code = 200;
        testMock.status = 'Complete';
        Test.setMock(HttpCalloutMock.class, testMock);

        Account acc = selectAccount();
        Package__c pkg = selectPackage();
        Quote qt = selectQuote();
        qt.ServiceName__c = OpportunityHelper.TIER_RC_CONTACT_CENTER;
        qt.BillingPackage__c = pkg.Id;

        Opportunity opp = (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityForSignUp(new Set<Id> { qt.OpportunityId })
            .executeQuery()
        ).getFirst();

        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
        opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS;
        Triggers.switchOff();
        update new List<SObject> {opp, qt};
        Triggers.switchOn();

        POWrappers.SignUpParams signUpParams = buildSignUpParams(opp, acc, qt);

        Test.startTest();
        Response resp = ProcessOrderValidator.validate(new List<POWrappers.SignUpParams> { signUpParams });
        Test.stopTest();

        assertSuccessResponse(resp);
    }

    private static Account selectAccount() {
        return (Account) new ListOptional(new AccountSelector()
            .selectAccountByName(new List<Object> { ACCOUNT_NAME })
            .executeQuery()
        ).getFirst();
    }

    private static Package__c selectPackage() {
        return (Package__c) new ListOptional(new PackageSelector()
            .selectPackageByAccountBillingId('123456789')
            .executeQuery()
        ).getFirst();
    }

    private static Quote selectQuote() {
        QuoteSelector selector = new QuoteSelector();
        return (Quote) new ListOptional(selector
            .selectQuoteByName(TEST_QUOTE_NAME)
            .selectFields(selector.getFieldsForSignUp())
            .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSignUp())
            .executeQuery()
        ).getFirst();
    }

    private static POWrappers.SignUpParams buildSignUpParams(
        Opportunity opp,
        Account acc,
        Quote qt
    ) {
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.opportunity = opp;
        signUpParams.masterAcc = acc;
        signUpParams.targetQuote = qt;
        signUpParams.approvals = (List<Approval__c>) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    ApprovalHelper.RT_ID_INVOICING_REQUEST,
                    ApprovalHelper.RT_ID_INVOICING_REQUEST,
                    ApprovalHelper.RT_ID_KYC_APPROVAL_REQUEST,
                    ApprovalHelper.RT_ID_DIRECT_DEBIT_REQUEST,
                    ApprovalHelper.RT_ID_VAT_ID_Exemption,
                    ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL
                }),
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.Account__c => ValueProviderBuilder.provideList(new List<Id> {
                    opp.AccountId,
                    null,
                    opp.AccountId,
                    opp.AccountId,
                    opp.AccountId,
                    opp.AccountId
                }),
                Approval__c.Opportunity__c => ValueProviderBuilder.provideList(new List<Id> {
                    opp.Id,
                    null,
                    opp.Id,
                    opp.Id,
                    opp.Id,
                    opp.Id
                })
            })
            .quantity(6)
            .build()
            .getRecords();
        signUpParams.promotions = new List<Promotion__c>();
        signUpParams.boundAccs = new List<Account>();
        signUpParams.isProServQuotesNotCancelled = false;

        return signUpParams;
    }

    private static void assertSuccessResponse(Response resp) {
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.isTrue(resp.messages.isEmpty(), 'There should be no messages');
    }

    private static void assertInvalidResponse(Response resp) {
        Assert.areEqual(1, resp.messages.size(), 'There should be 1 error message');
        Assert.areEqual(Response.STATUS_ERROR, resp.messages[0].message, 'Message should be error');
        Assert.areEqual(ProcessOrderValidator.ERROR_MESSAGE, resp.messages[0].messageDetails, 'Message should contain error');
    }
}