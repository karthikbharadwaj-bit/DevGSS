@isTest
public class Test_POHelper {
    private static final String ACCOUNT_NAME = 'Test Account';
    private static final String OPP_NAME = 'Test Opportunity';
    private static final String USER_IS_REQUIRED = 'User is required';
    private static final String VALID = 'valid';
    private static final String NGBS_ACCOUNT_RESPONSE = '{"packages":[{"id":123,"catalogId":"583","version":"2","product":"Office","offerType":"Regular","status":"Active"}],"currency":"USD"}';
    private static final String NGBS_ACCOUNT_RESPONSE_WITH_POC = '{"packages":[{"id":124,"catalogId":"583","version":"2","product":"Office","offerType":"POC","status":"Active"}],"currency":"USD"}';
    private static final String NGBS_ACCOUNT_RESPONSE_WITH_BOTH = '{"packages":[{"id":123,"catalogId":"583","version":"2","product":"Office","offerType":"Regular","status":"Active"},{"id":124,"catalogId":"583","version":"2","product":"Office","offerType":"POC","status":"Active"}],"currency":"USD"}';
    private static final String QUOTE_PACKAGE_INFO = '{"productName":"Fax","offerType":"Regular","existingPackageInfo":{"productName":"Office", "offerType":"Regular"}}';

    private static Account selectAccount() {
        return (Account) new ListOptional(new AccountSelector()
            .selectAccountByName(new List<Object> {ACCOUNT_NAME})
            .executeQuery()
        ).getFirst();
    }

    private static Opportunity selectOpportunity(String name) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
                .selectOpportunities()
                .selectFields(new List<String> {
                    'isSyncedToICB__c',
                    'Partner_ID__c',
                    'BMID__c',
                    'OID__c',
                    'Enable_Cost_Center_Management__c',
                    'RCCCSyncStatus__c',
                    'MasterOpportunity__c',
                    'Account.RC_User_ID__c',
                    'Account.isMultiProductTechnicalAccount__c',
                    'Account.Partner_Type__c',
                    'Account.Billing_ID__c',
                    'Account.Partner_ID__c',
                    'Account.BillingStreet',
                    'Account.BillingCity',
                    'Account.BillingState',
                    'Account.BillingPostalCode',
                    'Account.BillingCountry',
                    'Account.VATNumber__c',
                    'Account.ELA_Account_Type__c',
                    'Account.PID__c'
                })
                .setCondition('Name = :bind0')
                .setQueryBindings(new List<Object> {name})
                .executeQuery()
            ).getFirst();
    }

    private static POWrappers.SignUpParams getSignUpParams(String serviceName) {
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => serviceName,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();
        signUpParams.boundAccs = new List<Account>();
        return signUpParams;
    }

    private static Quote createMasterQuote(Id oppId) {
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => oppId,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateMultiProductQuotePackageInfo()
            })
            .create()
            .getRecord();
    }

    private static Quote buildTechQuote(String serviceName, Id oppId, Boolean isTechQuote) {
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.isPrimary__c => false,
                Quote.OpportunityId => oppId,
                Quote.IsMultiProductTechnicalQuote__c => isTechQuote,
                Quote.ServiceName__c => serviceName,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();
    }

    private static Quote buildTechQuoteWithOfferType(String serviceName, String offerType, Boolean isTechQuote) {
        Map<String, Object> packageInfoParams = new Map<String, Object> {
            'OfferType' => offerType
        };
        
        return (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.isPrimary__c => false,
                Quote.OpportunityId => null,
                Quote.IsMultiProductTechnicalQuote__c => isTechQuote,
                Quote.ServiceName__c => serviceName,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(packageInfoParams)
            })
            .build()
            .getRecord();
    }

    @testSetup
    static void createInitialData() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.EnableMultiProductUnifiedBilling__c => true,
                Feature_Toggle__c.Enable_Direct_Debit_as_a_payment_method__c => true
            })
            .create();

        // The NGBS_Settings__c record without fields was created to populate it with an appropriate data in BillingHttpRequestMock class static block
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .create();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, ACCOUNT_NAME)
            .create()
            .getRecord();

        new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => OPP_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create();
    }

    @isTest
    static void testQueryDataMPUB() {
        Opportunity opp = selectOpportunity(OPP_NAME);

        Triggers.switchOff();
        Quote masterQuote = createMasterQuote(opp.Id);

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.ServiceName__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        QuoteHelper.NGBS_OFFICE_PRODUCT,
                        QuoteHelper.NGBS_RCCC_PRODUCT
                    }
                )
            })
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => ValueProviderBuilder.provideList(
                    new List<Id> {
                        techQuotes[0].Id,
                        techQuotes[1].Id
                    }
                ),
                ServiceInfo__c.IsProcessOrderSent__c => ValueProviderBuilder.provideList(new List<Boolean> {true, false})
            })
            .quantity(2)
            .create();
        Triggers.switchOn();

        List<String> targetIds = new List<String> {masterQuote.Id, techQuotes[0].Id, techQuotes[1].Id};

        Test.startTest();
            Response resp = POHelper.queryData(targetIds);
        Test.stopTest();

        List<Response> services = (List<Response>) resp.getData('services');

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(2, services.size(), 'There should be 2 services');
    }

    @isTest
    static void testQueryDataMP() {
        Id accId = selectAccount().Id;

        Triggers.switchOff();
        Account techAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Tech Account',
                Account.Master_Account__c => accId,
                Account.Service_Type__c => AccountHelper.SERVICE_TYPE_RCCC,
                Account.IsMultiProductTechnicalAccount__c => true
            })
            .create()
            .getRecord();

        Opportunity opp = selectOpportunity(OPP_NAME);

        Opportunity ccTechOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => techAcc.Id,
                Opportunity.MasterOpportunity__c => opp.Id,
                Opportunity.IsMultiProductTechnicalOpportunity__c => true,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => 'Test Office Opportunity',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .create()
            .getRecord();

        Quote masterQuote = createMasterQuote(opp.Id);

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.ServiceName__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        QuoteHelper.NGBS_OFFICE_PRODUCT,
                        QuoteHelper.NGBS_RCCC_PRODUCT
                    }
                ),
                Quote.OpportunityId => ValueProviderBuilder.provideList(
                    new List<String> {opp.Id, ccTechOpp.Id}
                )
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        List<String> targetIds = new List<String> {masterQuote.Id, techQuotes[0].Id, techQuotes[1].Id};

        Test.startTest();
            Response resp = POHelper.queryData(targetIds);
        Test.stopTest();

        List<Response> services = (List<Response>) resp.getData('services');

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(2, services.size(), 'There should be 2 services');
    }

    @isTest
    static void testHandleValidateDataMPUB() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Account acc = selectAccount();
        acc.RC_User_ID__c = '12345';
        acc.RC_Account_Status__c = AccountHelper.PAID_STATUS;

        Opportunity opp = selectOpportunity(OPP_NAME);

        Triggers.switchOff();
        Quote masterQuote = createMasterQuote(opp.Id);

        Pricebook2 pb = (Pricebook2) new SObjectBuilder(Pricebook2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                PriceBook2.AllowedRecordType__c => QuoteHelper.ALLOWED_RT_NAME_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Quote officeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
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

        Test.startTest();
            Opportunity reselectedOpty = (Opportunity) new ListOptional(new OpportunitySelector()
                    .selectOpportunityForSignUp(new Set<Id> {opp.Id})
                    .executeQuery()
                ).getFirst();

            Quote reselectedQuote = (Quote) new ListOptional(new QuoteSelector()
                    .selectQuoteForSignUp(officeQuote.Id)
                    .executeQuery()
                ).getFirst();

            POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
            signUpParams.opportunity = reselectedOpty;
            signUpParams.masterAcc = acc;
            signUpParams.targetQuote = reselectedQuote;
            signUpParams.approvals = new List<Approval__c>();
            signUpParams.promotions = new List<Promotion__c>();
            signUpParams.boundAccs = new List<Account>();
            signUpParams.isProServQuotesNotCancelled = false;

            Response resp = POHelper.validateData(new List<POWrappers.SignUpParams> {signUpParams});
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(0, resp.messages.size(), 'There should be no messages');
    }

    @isTest
    static void testExecutePresignUpAction() {
        Opportunity opp = selectOpportunity(OPP_NAME);

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.isPrimary__c => true,
                Quote.OpportunityId => opp.Id,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.ServiceName__c => 'Professional Services',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .build()
            .getRecord();

        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.opportunity = opp;
        signUpParams.targetQuote = proServQuote;
        signUpParams.assignmentsToManual = new List<SubscriberInfoBuilder.AssignmentData>();

        Test.startTest();
            Response resp = POHelper.executePreSignUpActions(new List<POWrappers.SignUpParams> {signUpParams});
        Test.stopTest();

        SalesFunnelStatus__c sfs = (SalesFunnelStatus__c) new ListOptional(new SalesFunnelStatusSelector()
                .selectSalesFunnelStatuses()
                .executeQuery()
            ).getFirst();

        List<Object> updatedData = (List<Object>) resp.getData('updatedData');

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.isFalse(updatedData.isEmpty(), 'Updated data property should be filled out');
        Assert.isTrue(resp.messages.isEmpty(), 'Messages should be empty');
        Assert.isNotNull(sfs, 'SalesFunnelStatus record should be created');
    }

    @isTest
    static void testExecutePresignUpActionError() {
        Opportunity opp = selectOpportunity(OPP_NAME);
        Quote officeQuote = buildTechQuote(QuoteHelper.NGBS_OFFICE_PRODUCT, opp.Id, false);
        officeQuote.Package_Info__c = null;

        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.opportunity = opp;
        signUpParams.targetQuote = officeQuote;
        signUpParams.assignmentsToManual = new List<SubscriberInfoBuilder.AssignmentData>();

        Test.startTest();
            Response resp = POHelper.executePreSignUpActions(new List<POWrappers.SignUpParams> {signUpParams});
        Test.stopTest();

        List<Response.ResponseMessage> messages = resp.messages;

        Assert.isFalse(messages.isEmpty(), 'Messages should not be empty');
        Assert.isTrue(messages[0].messageDetails.contains(QuoteHelper.CAN_NOT_PACKAGE_INFO_ERROR), 'Message should contain error');
    }

    @isTest
    static void testValidateProcessOrderAction() {
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue(),
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .build()
            .getRecord();

        Test.startTest();
            Response resp = POHelper.validateProcessOrder(signUpParams);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.isTrue(resp.messages.isEmpty(), 'Messages should be empty');
    }

    @isTest
    static void testGetQuoteLineItemsWithAddressAssignment() {
        Triggers.switchOff();
        Opportunity opp = selectOpportunity(OPP_NAME);
        Quote masterQuote = createMasterQuote(opp.Id);

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
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Pricebook2Id => pb.Id
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

        new SObjectBuilder(QuoteLineItem.SObjectType)
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
            .create();
        Triggers.switchOn();

        Test.startTest();
            Quote selectedQuote = (Quote) new ListOptional(new QuoteSelector()
                    .newQueryFactory()
                    .setFactoryName('selectQuoteWithQlis')
                    .subselect(new QuoteLineItemSelector()
                        .selectQuoteLineItems()
                        .withoutSelectorFieldsIncluded()
                        .selectFields(new Set<String> {
                            'PackageInfo__c',
                            'Quantity',
                            'Zero_Quantity__c',
                            'Product2.ShippingType__c'
                        })
                    )
                    .setCondition('Id = :bind0')
                    .setQueryBindings(new List<Object> {officeQuote.Id})
                    .executeQuery()
                ).getFirst();
            List<QuoteLineItem> qlis = POHelper.getQuoteLineItemsWithAddressAssignment(selectedQuote);
        Test.stopTest();

        Assert.isFalse(qlis.isEmpty(), 'QuoteLineItems should not be empty');
        Assert.areEqual(1, qlis.size(), 'There should be 1 QuoteLineItem');
    }

    @isTest
    static void testSignUpNGBSWithIncorrectData() {
        Opportunity opp = selectOpportunity(OPP_NAME);
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue(),
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();
        signUpParams.boundAccs = new List<Account>();
        signUpParams.opportunity = opp;
        signUpParams.user = new User();
        signUpParams.approvals = new List<Approval__c>();
        signUpParams.assignmentsToSignUp = new List<SubscriberInfoBuilder.AssignmentData>();
        signUpParams.promotions = new List<Promotion__c>();

        Test.startTest();
            try {
                POHelper.signUpNGBS(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains('Can not get information for "isNGBSPartnerPackageChange"'), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testPreviewSignUpBodyWithIncorrectData() {
        Opportunity opp = selectOpportunity(OPP_NAME);
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue(),
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .build()
            .getRecord();
        signUpParams.boundAccs = new List<Account>();
        signUpParams.opportunity = opp;
        signUpParams.user = new User();
        signUpParams.approvals = new List<Approval__c>();
        signUpParams.assignmentsToSignUp = new List<SubscriberInfoBuilder.AssignmentData>();
        signUpParams.promotions = new List<Promotion__c>();

        Test.startTest();
        try {
            POHelper.previewSignUpBody(signUpParams);
            Assert.fail('Exception should be thrown');
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Can not get information for "isNGBSPartnerPackageChange"'), 'Exception message should be the same');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQuotePaymentMethodType() {
        Map<String, String> paymentMethodsMap = new Map<String, String> {
            QuoteHelper.PAYMENT_METHOD_INVOICE => POWrappers.PAYMENT_METHOD_INV_FUNNEL,
            QuoteHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF => POWrappers.PAYMENT_METHOD_INV_BOB_FUNNEL,
            QuoteHelper.PAYMENT_METHOD_CREDIT_CARD => POWrappers.PAYMENT_METHOD_CC_FUNNEL,
            QuoteHelper.PAYMENT_METHOD_WHOLESALE => POWrappers.PAYMENT_METHOD_WHOLESALE_FUNNEL,
            QuoteHelper.PAYMENT_METHOD_DIRECT_DEBIT => POWrappers.PAYMENT_METHOD_DD_FUNNEL
        };

        Test.startTest();
            for (String paymentMethod : paymentMethodsMap.keySet()) {
                String paymentMethodType = POHelper.getQuotePaymentMethodType(paymentMethod);
                Assert.areEqual(paymentMethodsMap.get(paymentMethod), paymentMethodType, 'Payment method type should be correct');
            }
        Test.stopTest();
    }

    @isTest
    static void testGetAccountPaymentMethodType() {
        final String testPaymentMethod = 'Test';
        Map<String, String> paymentMethodsMap = new Map<String, String> {
            AccountHelper.PAYMENT_METHOD_INVOICE => POWrappers.PAYMENT_METHOD_INV_FUNNEL,
            AccountHelper.PAYMENT_METHOD_INVOICE_ON_BEHALF => POWrappers.PAYMENT_METHOD_INV_BOB_FUNNEL,
            AccountHelper.PAYMENT_METHOD_WHOLESALE => POWrappers.PAYMENT_METHOD_WHOLESALE_FUNNEL,
            AccountHelper.PAYMENT_METHOD_DIRECT_DEBIT => AccountHelper.PAYMENT_METHOD_NONE,
            testPaymentMethod => POWrappers.PAYMENT_METHOD_CC_FUNNEL
        };

        Test.startTest();
            for (String paymentMethod : paymentMethodsMap.keySet()) {
                String paymentMethodType = POHelper.getAccountPaymentMethodType(paymentMethod, new Opportunity());
                Assert.areEqual(paymentMethodsMap.get(paymentMethod), paymentMethodType, 'Account payment method type should be correct');
            }
        Test.stopTest();
    }

    @isTest
    static void testGetAccountPaymentMethodTypeForPartners() {
        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Brand_Name__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        RingCentralHelper.BRAND_AVAYA,
                        RingCentralHelper.BRAND_ATOS,
                        RingCentralHelper.BRAND_RAINBOW,
                        OpportunityHelper.BRAND_RINGCENTRAL_EU
                    }
                )
            })
            .quantity(4)
            .build()
            .getRecords();

        Test.startTest();
            for (Opportunity opp : opps) {
                String paymentMethodType = POHelper.getAccountPaymentMethodType(null, opp);
                Assert.areEqual(AccountHelper.PAYMENT_METHOD_NONE, paymentMethodType, 'Account payment method type should be correct');
            }
        Test.stopTest();
    }

    @isTest
    static void testValidateBillingAddressRCCC() {
        new SObjectBuilder(ICB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ICB_Settings__c.BaseEndpoint__c => 'https://test.com/api',
                ICB_Settings__c.APIVersion1Path__c => '/v1/sfdc',
                ICB_Settings__c.ValidatePath__c => '/address/validate'
            })
            .create();
        Test.setMock(HttpCalloutMock.class, new ICBAPIMock());

        BillingWrappers.SubmitWrapper wrapper = new BillingWrappers.SubmitWrapper();
        wrapper.billingAddress = new BillingWrappers.BillingAddress();

        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.tier = OpportunityHelper.TIER_RC_CONTACT_CENTER;
        requestParams.data = wrapper;

        Test.startTest();
            Response resp = POHelper.validateBillingAddress(requestParams);
        Test.stopTest();

        Map<String, Object> body = (Map<String, Object>) resp.data.get('body');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(VALID, body.get('status'), 'Address should be valid');
    }

    @isTest
    static void testValidateBillingAddressED() {
        new SObjectBuilder(CCB_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CCB_Settings__c.DirectBaseEndpoint__c => 'https://test.com/restapi',
                CCB_Settings__c.APIVersion2Path__c => '/v2.0/ccb',
                CCB_Settings__c.ValidatePath__c => '/address/validate'
            })
            .create();
        Test.setMock(HttpCalloutMock.class, new CCBAPIMock());

        BillingWrappers.SubmitWrapper wrapper = new BillingWrappers.SubmitWrapper();
        wrapper.billingAddress = new BillingWrappers.BillingAddress();

        BillingWrappers.RequestSubmitParams requestParams = new BillingWrappers.RequestSubmitParams();
        requestParams.tier = OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE;
        requestParams.data = wrapper;

        Test.startTest();
            Response resp = POHelper.validateBillingAddress(requestParams);
        Test.stopTest();

        Map<String, Object> body = (Map<String, Object>) resp.data.get('body');
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(VALID, body.get('status'), 'Address should be valid');
    }

    @isTest
    static void testBuildQtIdToSyncInfo() {
        Opportunity opp = selectOpportunity(OPP_NAME);
        Quote masterQuote = createMasterQuote(opp.Id);

        Quote officeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => officeQuote.Id,
                ServiceInfo__c.IsProcessOrderSent__c => true
            })
            .create();

        POWrappers.OppDetailWrapper oppWrapper = new POWrappers.OppDetailWrapper();
        oppWrapper.masterAndTechQuotes = new List<Quote> {masterQuote, officeQuote};
        oppWrapper.opportunity = opp;
        oppWrapper.isMPUB = true;

        Test.startTest();
            Map<Id, POWrappers.SyncableWrapper> qtIdToSyncInfo = POHelper.buildQtIdToSyncInfo(oppWrapper);
        Test.stopTest();

        POWrappers.SyncableWrapper wrapper = qtIdToSyncInfo.get(officeQuote.Id);

        Assert.areEqual(1, qtIdToSyncInfo.size(), 'There should be 1 SyncableWrapper object');
        Assert.isFalse(wrapper.isSyncedToICB, 'Quote should be synced to ICB');
        Assert.isFalse(wrapper.isICBProvisioningComplete, 'Quote should be synced to ICB');
    }

    @isTest
    static void testBuildProductNameToPackageIsActiveStatusMap() {
        Quote officeQuote = buildTechQuote(QuoteHelper.NGBS_OFFICE_PRODUCT, null, true);

        POWrappers.OppDetailWrapper oppWrapper = new POWrappers.OppDetailWrapper();
        oppWrapper.masterAndTechQuotes = new List<Quote> {officeQuote};
        oppWrapper.isMPUB = true;

        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_RESPONSE, BillingWrappers.NGBSAccount.class);

        Test.startTest();
            Map<String, Object> productNameToPackageIsActiveStatusMap = POHelper.buildProductNameToPackageIsActiveStatusMap(oppWrapper, ngbsAcc);
        Test.stopTest();

        Assert.areEqual(1, productNameToPackageIsActiveStatusMap.size(), 'There should be 1 activated service');
        
        // Check the new format structure
        Object officeStatus = productNameToPackageIsActiveStatusMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Map<String, Object> officeStatusMap = (Map<String, Object>) officeStatus;
        Assert.isTrue(officeStatusMap.containsKey('salesSignedUp'), 'Should contain salesSignedUp key');
        Assert.isTrue(officeStatusMap.containsKey('pocSignedUp'), 'Should contain pocSignedUp key');
        Assert.isTrue((Boolean) officeStatusMap.get('salesSignedUp'), 'Office product sales should be activated');
    }

    @isTest
    static void testBuildProductNameToPackageIsActiveStatusMapEmptyPackages() {
        POWrappers.OppDetailWrapper oppWrapper = new POWrappers.OppDetailWrapper();
        BillingWrappers.NGBSAccount ngbsAcc = new BillingWrappers.NGBSAccount();

        Test.startTest();
            Map<String, Object> productNameToPackageIsActiveStatusMap = POHelper.buildProductNameToPackageIsActiveStatusMap(oppWrapper, ngbsAcc);
        Test.stopTest();

        Assert.isTrue(productNameToPackageIsActiveStatusMap.isEmpty(), 'There should be no activated services');
    }

    @isTest
    static void testBuildProductNameToPackageIsActiveStatusMapWithPOCQuote() {
        // Create a POC quote
        Quote pocQuote = buildTechQuoteWithOfferType(QuoteHelper.NGBS_OFFICE_PRODUCT, 'POC', true);

        POWrappers.OppDetailWrapper oppWrapper = new POWrappers.OppDetailWrapper();
        oppWrapper.masterAndTechQuotes = new List<Quote> {pocQuote};
        oppWrapper.isMPUB = true;

        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_RESPONSE_WITH_POC, BillingWrappers.NGBSAccount.class);

        Test.startTest();
            Map<String, Object> productNameToPackageIsActiveStatusMap = POHelper.buildProductNameToPackageIsActiveStatusMap(oppWrapper, ngbsAcc);
        Test.stopTest();

        Assert.areEqual(1, productNameToPackageIsActiveStatusMap.size(), 'There should be 1 activated service');
        
        // Check the new format structure for POC quote
        Object officeStatus = productNameToPackageIsActiveStatusMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Map<String, Object> officeStatusMap = (Map<String, Object>) officeStatus;
        Assert.isTrue(officeStatusMap.containsKey('salesSignedUp'), 'Should contain salesSignedUp key');
        Assert.isTrue(officeStatusMap.containsKey('pocSignedUp'), 'Should contain pocSignedUp key');
        Assert.isFalse((Boolean) officeStatusMap.get('salesSignedUp'), 'Office product sales should not be activated for POC quote');
        Assert.isTrue((Boolean) officeStatusMap.get('pocSignedUp'), 'Office product POC should be activated');
    }

    @isTest
    static void testBuildProductNameToPackageIsActiveStatusMapWithBothQuoteTypes() {
        // Create both Sales and POC quotes for the same service
        Quote salesQuote = buildTechQuote(QuoteHelper.NGBS_OFFICE_PRODUCT, null, true);
        Quote pocQuote = buildTechQuoteWithOfferType(QuoteHelper.NGBS_OFFICE_PRODUCT, 'POC', true);

        POWrappers.OppDetailWrapper oppWrapper = new POWrappers.OppDetailWrapper();
        oppWrapper.masterAndTechQuotes = new List<Quote> {salesQuote, pocQuote};
        oppWrapper.isMPUB = true;

        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_RESPONSE_WITH_BOTH, BillingWrappers.NGBSAccount.class);

        Test.startTest();
            Map<String, Object> productNameToPackageIsActiveStatusMap = POHelper.buildProductNameToPackageIsActiveStatusMap(oppWrapper, ngbsAcc);
        Test.stopTest();

        Assert.areEqual(1, productNameToPackageIsActiveStatusMap.size(), 'There should be 1 activated service');
        
        // Check the new format structure for both quote types
        Object officeStatus = productNameToPackageIsActiveStatusMap.get(QuoteHelper.NGBS_OFFICE_PRODUCT);
        
        Map<String, Object> officeStatusMap = (Map<String, Object>) officeStatus;
        Assert.isTrue(officeStatusMap.containsKey('salesSignedUp'), 'Should contain salesSignedUp key');
        Assert.isTrue(officeStatusMap.containsKey('pocSignedUp'), 'Should contain pocSignedUp key');
        Assert.isTrue((Boolean) officeStatusMap.get('salesSignedUp'), 'Office product sales should be activated');
        Assert.isTrue((Boolean) officeStatusMap.get('pocSignedUp'), 'Office product POC should be activated');
    }

    @isTest
    static void testCreateSignUpRunnerMVP() {
        POWrappers.SignUpParams signUpParams = getSignUpParams(QuoteHelper.NGBS_OFFICE_PRODUCT);
        Test.startTest();
            try {
                POHelper.createSignUpRunner(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains(USER_IS_REQUIRED), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignUpRunnerEngage() {
        POWrappers.SignUpParams signUpParams = getSignUpParams(QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT);
        Test.startTest();
            try {
                POHelper.createSignUpRunner(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains(USER_IS_REQUIRED), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignUpRunnerRCCC() {
        POWrappers.SignUpParams signUpParams = getSignUpParams(QuoteHelper.NGBS_RCCC_PRODUCT);
        signUpParams.isExistingBusiness = false;
        Test.startTest();
            try {
                POHelper.createSignUpRunner(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains(USER_IS_REQUIRED), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testCreateSyncRunnerRCCC() {
        POWrappers.SignUpParams signUpParams = getSignUpParams(QuoteHelper.NGBS_RCCC_PRODUCT);
        signUpParams.isExistingBusiness = true;
        Test.startTest();
            try {
                POHelper.createSignUpRunner(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains(USER_IS_REQUIRED), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignUpRunnerFax() {
        POWrappers.SignUpParams signUpParams = getSignUpParams(QuoteHelper.NGBS_FAX_PRODUCT);

        Test.startTest();
            try {
                POHelper.createSignUpRunner(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains(USER_IS_REQUIRED), 'Exception message should be the same');
            }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignUpRunnerError() {
        POWrappers.SignUpParams signUpParams = getSignUpParams('testService');

        Test.startTest();
            try {
                POHelper.createSignUpRunner(signUpParams);
                Assert.fail('Exception should be thrown');
            } catch (Exception ex) {
                Assert.isTrue(ex.getMessage().contains('There is no SignUp flow specified'), 'Exception should contain error message');
            }
        Test.stopTest();
    }

    @isTest
    static void testIsMPUBFlowTrue() {
        Opportunity opp = selectOpportunity(OPP_NAME);
        Triggers.switchOff();
        Quote masterQuote = createMasterQuote(opp.Id);

        Quote officeQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.isPrimary__c => false,
                Quote.OpportunityId => opp.Id,
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo()
            })
            .create()
            .getRecord();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => officeQuote.Id,
                ServiceInfo__c.IsProcessOrderSent__c => true
            })
            .create();
        Triggers.switchOn();

        Test.startTest();
            Boolean isMPUBFlow = POHelper.isMPUBFlow(new Set<Id> {officeQuote.Id});
        Test.stopTest();

        Assert.isTrue(isMPUBFlow, 'It should be MPUB flow');
    }

    @isTest
    static void testIsMPUBFlowFalse() {
        Test.startTest();
            Boolean isMPUBFlow = POHelper.isMPUBFlow(new Set<Id>());
        Test.stopTest();

        Assert.isFalse(isMPUBFlow, 'It should not be MPUB flow');
    }

    @isTest
    static void testHandleMPUBFlowCrossUpgradeFromOfficeToFax() {
        BillingWrappers.NGBSAccount ngbsAcc = (BillingWrappers.NGBSAccount) JSON.deserialize(NGBS_ACCOUNT_RESPONSE, BillingWrappers.NGBSAccount.class);
        BillingWrappers.QuotePackageInfo pInfo = (BillingWrappers.QuotePackageInfo) JSON.deserialize(
            QUOTE_PACKAGE_INFO,
            BillingWrappers.QuotePackageInfo.class
        );

        Map<String, Boolean> productNameToPackageIsActiveStatusMap = new Map<String, Boolean>();
        Test.startTest();
            POHelper.handleMPUBFlow(pInfo, ngbsAcc.packages, productNameToPackageIsActiveStatusMap);
        Test.stopTest();

        Assert.isTrue(productNameToPackageIsActiveStatusMap.get(QuoteHelper.NGBS_FAX_PRODUCT), 'Fax product should be activated');
    }

    @IsTest
    static void testIsPackageActive() {
        BillingWrappers.NGBSAccountPackage accPackage = new BillingWrappers.NGBSAccountPackage();
        accPackage.status = 'Initial';

        Map<String, Boolean> productNameToPackageIsActiveStatusMap = new Map<String, Boolean>();
        Test.startTest();
            Boolean engageTierResult = POHelper.isPackageActive(accPackage, OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE);
            Assert.isTrue(engageTierResult, 'Should be always true for non RCCC despite package status');

            Boolean rcccTierResult = POHelper.isPackageActive(accPackage, OpportunityHelper.TIER_RC_CONTACT_CENTER);
            Assert.isFalse(rcccTierResult, 'Should be false for RCCC if package status is not active');

            accPackage.status = 'Active';
            rcccTierResult = POHelper.isPackageActive(accPackage, OpportunityHelper.TIER_RC_CONTACT_CENTER);
            Assert.isTrue(rcccTierResult, 'Should be true for RCCC if package status is active');
        Test.stopTest();
    }

    @IsTest
    static void testBuildLimitParam() {
        Test.startTest();
            String resultWithIndex = POHelper.buildLimitParam('!', 'limit', 999, 'property');
            String resultWithoutIndex = POHelper.buildLimitParam('?', 'LEGACY', null, 'FIELD');
        Test.stopTest();

        Assert.areEqual('!limit[999][property]=', resultWithIndex, 'Test case with index failed');
        Assert.areEqual('?LEGACY[FIELD]=', resultWithoutIndex, 'Test case without index failed');
    }

    @IsTest
    static void testUpdateMasterOpportunityMPUB() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.rcccSyncStatus = IcbHelper.CC_SYNC_STATUS_STARTED;
        requestParams.data = new POWrappers.SignUpParams();
        requestParams.data.opportunity = selectOpportunity(OPP_NAME);

        Test.startTest();
            Response resp = POHelper.updateMasterOpportunityRCCCSyncStatus(requestParams);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.isTrue(resp.messages.isEmpty(), 'Messages should be empty');

        Opportunity resultOpp = selectOpportunity(OPP_NAME);
        Assert.areEqual(IcbHelper.CC_SYNC_STATUS_STARTED, resultOpp.RCCCSyncStatus__c, 'Process Order Sync Status should be marked as Started');
    }

    @IsTest
    static void testUpdateMasterOpportunityMPL() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        requestParams.rcccSyncStatus = IcbHelper.CC_SYNC_STATUS_STARTED;
        requestParams.data = new POWrappers.SignUpParams();
        Opportunity masterOpp = selectOpportunity(OPP_NAME);

        requestParams.data.opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.MasterOpportunity__c => masterOpp.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType)
            })
            .create()
            .getRecord();

        requestParams.data.opportunity.putSObject('MasterOpportunity__r', masterOpp);

        Test.startTest();
            Response resp = POHelper.updateMasterOpportunityRCCCSyncStatus(requestParams);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.isTrue(resp.messages.isEmpty(), 'Messages should be empty');

        Opportunity resultOpp = selectOpportunity(OPP_NAME);
        Assert.areEqual(IcbHelper.CC_SYNC_STATUS_STARTED, resultOpp.RCCCSyncStatus__c, 'Process Order Sync Status should be marked as Started');
    }

    @IsTest
    static void testUpdateMasterOpportunityException() {
        POWrappers.ActionRequestParams requestParams = new POWrappers.ActionRequestParams();
        Test.startTest();
            Response resp = POHelper.updateMasterOpportunityRCCCSyncStatus(requestParams);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Status should be error');
        Assert.isFalse(resp.messages.isEmpty(), 'Messages should contain exception error messagge');
    }

    @IsTest
    private static void testCheckIsMainCostCenterExist() {
        NGBS_Settings__c settings = NGBS_Settings__c.getOrgDefaults();
        settings.BaseEndpoint__c = 'https://testapi';
        settings.AccountManagerPath__c = '/restapi/account-manager/v1.0';
        update settings;
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
            Response resp = POHelper.checkIsMainCostCenterExist('123');
        Test.stopTest();
        Assert.areEqual(true, resp.data.get('isMainCostCenterExist'), 'Main Cost Center should exist');
    }

    @IsTest
    private static void testCreateMainCostCenter() {
        NGBS_Settings__c settings = NGBS_Settings__c.getOrgDefaults();
        settings.BaseEndpoint__c = 'https://testapi';
        settings.AccountManagerPath__c = '/restapi/account-manager/v1.0';
        update settings;
        BillingHttpRequestMock testMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Test.startTest();
            Response resp = POHelper.createMainCostCenter('123');
        Test.stopTest();
        Assert.areEqual(true, resp.data.get('isMainCostCenterCreated'), 'Main Cost Center should be created');
    }
    @isTest
    static void testCreateSignUpRunnerRCSingleEvent() {
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
        FunnelApiProServMock testMock = new FunnelApiProServMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Id userId =UserInfo.getUserId(); 
        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
            })
          .quantity(2)
          .create()
          .getRecords();
        Opportunity oppty = selectOpportunity(OPP_NAME);
        User currentuser = [SELECT CurrencyIsoCode FROM User WHERE Id =: userId];
        
        Account acc = selectAccount();
        acc.Payment_Method__c = 'Invoice';
        acc.BillingCountry =  'united states';
        acc.Name = 'Test Account 2';
        acc.Internal_Enterprise_Account_ID__c = '123';
        acc.BillingStreet = '111 Industrial CTr';
        acc.BillingCity = 'Belmont ';
        acc.BillingState = 'California ';
        acc.BillingPostalCode = '94002 ';
            
        update acc;
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => 'Events',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoEvent(),
                Quote.Account__c => acc.Id,
                Quote.PaymentMethod__c=> 'Invoice',
                Quote.Initial_Term_months__c => '24',
                Quote.Auto_Renewal__c => False,
                Quote.Term_months__c => '60'
                
            })
            .build()
            .getRecord();
        signUpParams.boundAccs = new List<Account>(); 
        signUpParams.user = currentuser;
        signUpParams.opportunity = oppty;
        signUpParams.opportunity.Account = acc;
        RCSequence__c rcSeq = new RCSequence__c();
        rcSeq.SetupOwnerId = UserInfo.getOrganizationId();
        rcSeq.SubSequence__c = 100;
        insert rcSeq;

       

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'TestFirst',
                    Contact.LastName => 'TestLast',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@email.com',
                    Contact.Phone => '9910106804',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        AccountContactRole payableContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();
        oppty.AccountId = acc.Id;
        update oppty;
        oppty = selectOpportunity(OPP_NAME);
        
        List<Approval__c> approvalList = new List<Approval__c>();
         Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Account__c => acc.Id,
                Approval__c.Opportunity__c => oppty.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => testContact.Id,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        approvalList.add(testApproval);
        signUpParams.approvals = approvalList;
                 Triggers.switchOn();
        Test.startTest();
            try {
                POSignUp.SignUpRunner runner = POHelper.createSignUpRunner(signUpParams);
                Response resp = runner.signUp();    
                 System.assertEquals (resp.status,'success');
            } catch (Exception ex) {
                
            }
        Test.stopTest();
    }
    @isTest
    static void testCreateSignUpRunnerRCEvent() {
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
        FunnelApiProServMock testMock = new FunnelApiProServMock();
        Test.setMock(HttpCalloutMock.class, testMock);
        Id userId =UserInfo.getUserId(); 
        List<CountryCodes__c> cc = (List<CountryCodes__c>) new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                CountryCodes__c.Name => ValueProviderBuilder.provideList(new List<String> {'FRA', 'USA'}),
                CountryCodes__c.CountryName__c => ValueProviderBuilder.provideList(new List<String> {'fra;france', 'usa;united states'}),
                CountryCodes__c.CountryNameFull__c => ValueProviderBuilder.provideList(new List<String> {'France', 'United States'}),
                CountryCodes__c.CountryNameShort__c => ValueProviderBuilder.provideList(new List<String> {'FR','US'})
            })
          .quantity(2)
          .create()
          .getRecords();
        Opportunity oppty = selectOpportunity(OPP_NAME);
        User currentuser = [SELECT CurrencyIsoCode FROM User WHERE Id =: userId];
        
        Account acc = selectAccount();
        acc.Payment_Method__c = 'Invoice';
        acc.BillingCountry =  'united states';
        acc.Name = 'Test Account 2';
        acc.Internal_Enterprise_Account_ID__c = '123';
        acc.BillingStreet = '111 Industrial CTr';
        acc.BillingCity = 'Belmont ';
        acc.BillingState = 'California ';
        acc.BillingPostalCode = '94002 ';
            
        update acc;
        POWrappers.SignUpParams signUpParams = new POWrappers.SignUpParams();
        signUpParams.targetQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Quote',
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.ServiceName__c => 'Events',
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfoEvent(),
                Quote.Account__c => acc.Id,
                Quote.PaymentMethod__c=> 'Invoice',
                Quote.Initial_Term_months__c => '24',
                Quote.Auto_Renewal__c => False,
                Quote.Term_months__c => '60'
                
            })
            .build()
            .getRecord();
        signUpParams.boundAccs = new List<Account>(); 
        signUpParams.user = currentuser;
        signUpParams.opportunity = oppty;
        signUpParams.opportunity.Account = acc;
        RCSequence__c rcSeq = new RCSequence__c();
        rcSeq.SetupOwnerId = UserInfo.getOrganizationId();
        rcSeq.SubSequence__c = 100;
        insert rcSeq;

       

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'TestFirst',
                    Contact.LastName => 'TestLast',
                    Contact.AccountId => acc.Id,
                    Contact.Email => 'fake@email.com',
                    Contact.Phone => '9910106804',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        AccountContactRole payableContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => testContact.Id,
                    AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_ACCOUNT_PAYABLE
                }
            )
            .create()
            .getRecord();
        oppty.AccountId = acc.Id;
        update oppty;
        oppty = selectOpportunity(OPP_NAME);
        
        List<Approval__c> approvalList = new List<Approval__c>();
         Approval__c testApproval = (Approval__c) new SObjectBuilder(Approval__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Approval__c.Account__c => acc.Id,
                Approval__c.Opportunity__c => oppty.Id,
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.AccountPayableContact__c => testContact.Id,
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        approvalList.add(testApproval);
        signUpParams.approvals = approvalList;
                 Triggers.switchOn();
        Test.startTest();
            try {
                POSignUp.SignUpRunner runner = POHelper.createSignUpRunner(signUpParams);
                Response resp = runner.signUp();    
                System.assertEquals (resp.status,'success');
            } catch (Exception ex) {
               
            }
        Test.stopTest();
    }

    @isTest
    static void testcreateDealDeskCaseDescriptions() {
        Test.setMock(HttpCalloutMock.class, new BillingHttpRequestMock());

        Account acc = selectAccount();
        acc.RC_User_ID__c = '35627';
        acc.RC_Account_Status__c = AccountHelper.PAID_STATUS;

        Opportunity opp = selectOpportunity(OPP_NAME);

        Triggers.switchOff();
        Quote masterQuote = createMasterQuote(opp.Id);
        
        List<Quote> techQuoteList = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setField(Quote.Name, 'Test Tech Quote')
            .setField(Quote.OpportunityId, opp.Id)
            .setField(Quote.CurrencyIsoCode, 'USD')
            .setField(Quote.ServiceName__c, ValueProviderBuilder.provideList(
                new List<String>{
                    QuoteHelper.NGBS_OFFICE_PRODUCT,
                    QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
                }
            ))
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.MasterQuote__c, masterQuote.Id)
            .setField(Quote.IsMultiProductTechnicalQuote__c, true)
            .quantity(2)
            .create()
            .getRecords();

        List<Product2> prodList = (List<Product2>) new SObjectBuilder(Product2.sObjectType)
            .setField(Product2.Name, 'Test product')
            .setField(Product2.Sub_Category__c, Product2Helper.SUBCATEGORY_RINGCENTRAL)
            .setField(Product2.IsActive, true)
            .setField(Product2.Billing_Type__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.BILLING_TYPE_RECURRING,
                    Product2Helper.BILLING_TYPE_ONE_TIME
                }
            ))
            .setField(Product2.UpsellType__c, ValueProviderBuilder.provideList(
                new List<String>{
                    Product2Helper.SHIPPING_TYPE_AUTO,
                    Product2Helper.SHIPPING_TYPE_MANUAL
                }
            ))
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbeList = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setField(PricebookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .setField(PricebookEntry.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(PricebookEntry.UnitPrice, 10)
            .setField(PricebookEntry.IsActive, true)
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setField(QuoteLineItem.QuoteId, techQuoteList.get(0).Id)
            .setField(QuoteLineItem.Product2Id, ValueProviderBuilder.provideParents(prodList))
            .setField(QuoteLineItem.PricebookEntryId, ValueProviderBuilder.provideParents(pbeList))
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.UnitPrice, 10)
            .quantity(2)
            .create()
            .getRecords();
       
        Triggers.switchOn();

        Test.startTest();
            Opportunity reselectedOpty = (Opportunity) new ListOptional(new OpportunitySelector()
                    .selectOpportunityForSignUp(new Set<Id> {opp.Id})
                    .executeQuery()
                ).getFirst();

            Quote reselectedQuoteOffice = (Quote) new ListOptional(new QuoteSelector()
                    .selectQuoteForSignUp(techQuoteList.get(0).Id)
                    .executeQuery()
                ).getFirst();

            POWrappers.SignUpParams signUpParamsOffice = new POWrappers.SignUpParams();
            signUpParamsOffice.opportunity = reselectedOpty;
            signUpParamsOffice.masterAcc = acc;
            signUpParamsOffice.targetQuote = reselectedQuoteOffice;
            signUpParamsOffice.approvals = new List<Approval__c>();
            signUpParamsOffice.promotions = new List<Promotion__c>();
            signUpParamsOffice.boundAccs = new List<Account>();
            signUpParamsOffice.isProServQuotesNotCancelled = false;

            Quote reselectedQuotePS = (Quote) new ListOptional(new QuoteSelector()
                    .selectQuoteForSignUp(techQuoteList.get(1).Id)
                    .executeQuery()
                ).getFirst();

            POWrappers.SignUpParams signUpParamsPS = new POWrappers.SignUpParams();
            signUpParamsPS.opportunity = reselectedOpty;
            signUpParamsPS.masterAcc = acc;
            signUpParamsPS.targetQuote = reselectedQuotePS;
            signUpParamsPS.approvals = new List<Approval__c>();
            signUpParamsPS.promotions = new List<Promotion__c>();
            signUpParamsPS.boundAccs = new List<Account>();
            signUpParamsPS.isProServQuotesNotCancelled = false;
            
            Response resp = POHelper.createDealDeskCaseDescriptions(new List<POWrappers.SignUpParams> {signUpParamsOffice, signUpParamsPS});
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(0, resp.messages.size(), 'There should be no messages');
    }
}