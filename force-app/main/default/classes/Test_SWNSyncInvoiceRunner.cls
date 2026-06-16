@isTest
private with sharing class Test_SWNSyncInvoiceRunner {
    private static final String BILLING_ID = (String) ValueProviderBuilder.provideUniqueString().getValue();
    private static final String OPP_NAME = 'opp name';
    private static final String PACKAGE_INFO_QT = '[{"packageInfo":{"id":"12345"},"contract":{"extId":"Office","billingId":' + BILLING_ID + ',"status":"test"}}]';
    private static final String PACKAGE_INFO_QLI_WITH_LBOX = '{"categoryCode":"DL-UNL", "categoryPath":"DL-UNL", "discount"' +
        ':{},"duration":"Monthly","id":"18","price":0,"version":"1","parent":"LC_DL_75","q":33,' +
        '"lboxes":[{"elementID":"LB_702","min":1,"max":100}]}';
    private static final String GET_PAYMENT_METHOD_RESPONSE = '[{"id":27328005,"accountId":227775005,"default":true}]';
    private static final String PKG_CONSOLIDATION_RESP = '{"billingAlignmentEnabled":false, "invoiceConsolidationEnabled":false}';
    private static final String COMPLETED = 'Completed';

    private static Account queryAccount() {
        return (Account) new ListOptional(new AccountSelector()
                .selectAccounts()
                .selectField(Account.Phone)
                .executeQuery()
            ).getFirst();
    }

    private static Opportunity queryOpportunity(String oppName) {
        return (Opportunity) new ListOptional(new OpportunitySelector()
                .selectOpportunityForSyncWithNGBSByName(oppName)
                .executeQuery()
            ).getFirst();
    }

    private static Quote queryQuote(String oppName) {
        return (Quote) new ListOptional(new QuoteSelector()
                .selectQuoteForSyncWithNGBSByName(oppName)
                .executeQuery()
            ).getFirst();
    }

    private static Account buildAccount() {
        return (Account) new SObjectBuilder(Account.sObjectType)
            .setField(Account.Billing_Id__c, BILLING_ID)
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

        Triggers.switchOff();
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => BILLING_ID,
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.Name => 'Test',
                Account.BillingState => 'CA',
                Account.BillingCity => 'Test',
                Account.BillingStreet => 'Test',
                Account.BillingPostalCode => 'Test',
                Account.BillingCountry => 'United States',
                Account.Phone => '12314235'
            })
            .create()
            .getRecord();

        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.FirstName => ValueProviderBuilder.provideUniqueString(),
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.AccountId => billingAcc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail()
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                AccountContactRole.AccountId => billingAcc.Id,
                AccountContactRole.ContactId => testContact.Id,
                AccountContactRole.IsPrimary => true,
                AccountContactRole.Role => AccountContactRoleHelper.CONTACT_ROLE_SIGNATORY
            })
            .create();

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
                Quote.IsPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO_QT,
                Quote.ContactId => testContact.Id,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'ent Name',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.PackageOfferType__c => QuoteHelper.PACKAGE_OFFER_TYPE_TRIAL
            })
            .build()
            .getRecord();

        Product2 prod = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'DigitalLine Unlimited',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI_WITH_LBOX
            })
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testConstructor() {
        final Id quoteId = (Id) new ValueProvider.DummyIdProvider(Quote.sObjectType).getValue();

        Test.startTest();
            SWNSyncInvoiceRunner runner = new SWNSyncInvoiceRunner(quoteId, SWNStep.SYNC_INVOICE);
        Test.stopTest();

        Assert.isTrue(runner.sdc != null, 'Data Collector should be initialized');
        Assert.areEqual(SWNStep.SYNC_INVOICE, runner.sdc.action, 'Action should be Invoice Sync');
        Assert.areEqual(quoteId, runner.sdc.quoteId, 'Quote Ids should be equal');
    }

    @isTest
    static void testRun() {
        SWNDataCollector sdc = new SWNDataCollector();
        sdc.qt = new Quote();
        sdc.syncable = new NGBSSyncables.OpportunitySync(new Opportunity());
        sdc.currentStep = SWNStep.buildSyncInvoiceStep();
        sdc.isMPUB = true;

        Test.startTest();
            SWNSyncInvoiceRunner runner = new SWNSyncInvoiceRunner();
            runner.sdc = sdc;
            runner.run();
        Test.stopTest();

        Assert.isFalse(runner.sdc.currentStep.isStepCompletedSuccessfully, 'Step should not be completed');
    }

    @isTest
    static void testSyncInvoice() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/contactInfo', COMPLETED, PKG_CONSOLIDATION_RESP, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo('/paymentMethod', COMPLETED, GET_PAYMENT_METHOD_RESPONSE, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo('/limits/update', COMPLETED, '{}', 200, HttpHelper.METHOD_PUT),
            new BillingHttpRequestMock.MockInfo('/packageConsolidationSettings', COMPLETED, '', 200, HttpHelper.METHOD_PUT)
        };

        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Opportunity opp = queryOpportunity(OPP_NAME);
        Quote qt = queryQuote(OPP_NAME);

        Triggers.switchOff();
        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => qt.AccountId,
                Package__c.Account_Package_Id__c => qt.Account.Billing_ID__c
            })
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.BillingPackage__c => pack.Id
            })
            .create()
            .getRecord();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Approval__c.RecordTypeId => ApprovalHelper.RT_ID_INVOICING_REQUEST,
                Approval__c.Account__c => qt.AccountId,
                Approval__c.Opportunity__c => opp.Id,
                Approval__c.Monthly_Credit_Limit__c => 100,
                Approval__c.Status__c => ApprovalHelper.STATUS_APPROVED,
                Approval__c.StatusLastModifiedDate__c => System.now(),
                Approval__c.Potential_Users__c => 1,
                Approval__c.Reason_Customer_is_Requesting_Invoicing__c => 'test'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            Response resp = new SWNSyncInvoiceRunner().syncInvoice(opp, qt, true);
        Test.stopTest();

        Assert.areEqual(SWNSyncInvoiceRunner.CONTACT_SYNC_ERROR, resp.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.PAYMENT_METHOD_SYNCED_MSG, resp.messages[1].messageDetails, 'Message details should be equal');
        Assert.areEqual(SWNMessageHelper.ACC_PACKAGE_LIMITS_SYNCED_MSG, resp.messages[2].messageDetails, 'Message details should be equal');
        Assert.areEqual(SWNSyncInvoiceRunner.PKG_CONSOLIDATION_SETTINGS_SYNC_ERROR, resp.messages[3].message, 'Messages should be equal');
    }

    @isTest
    static void testSyncAccountPaymentContactError() {
        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncAccountPaymentContact(resp, null, null);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Status should be error');
        Assert.areEqual(SWNSyncInvoiceRunner.NOT_APPROVED_APPROVAL_ERROR, resp.messages[0].message, 'Error messages should be equal');
    }

    @isTest
    static void testSyncAccountPaymentContact() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/contactInfo', COMPLETED, '', 200, HttpHelper.METHOD_PUT)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = buildAccount();

        Triggers.switchOff();
        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                Contact.FirstName => ValueProviderBuilder.provideUniqueString(),
                Contact.Email => ValueProviderBuilder.provideUniqueEmail()
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.AccountPayableContact__c, cont.Id)
            .build()
            .getRecord();

        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncAccountPaymentContact(resp, acc, lastApprovedApproval);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(SWNMessageHelper.SUCCESS_HEADER, resp.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.ACC_PAYMENT_CONTACT_SYNCED_MSG, resp.messages[0].messageDetails, 'Message details should be equal');
    }

    @isTest
    static void testSyncAccountPaymentContactRequestError() {
        Account acc = buildAccount();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.AccountPayableContact__c, (Id) ValueProviderBuilder.provideDummyId(Contact.SObjectType, 15).getValue())
            .build()
            .getRecord();

        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncAccountPaymentContact(resp, acc, lastApprovedApproval);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Status should be error');
        Assert.areEqual(SWNSyncInvoiceRunner.CONTACT_SYNC_ERROR, resp.messages[0].message, 'Messages should be equal');
    }

    @isTest
    static void testSyncAccountPaymentMethodSuccess() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/paymentMethod', COMPLETED, GET_PAYMENT_METHOD_RESPONSE, 200, HttpHelper.METHOD_GET)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
        
        Account acc = queryAccount();
        Opportunity opp = queryOpportunity(OPP_NAME);

        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncAccountPaymentMethod(resp, acc, opp);
        Test.stopTest();
        
        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be success');
        Assert.areEqual(SWNMessageHelper.SUCCESS_HEADER, resp.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.PAYMENT_METHOD_SYNCED_MSG, resp.messages[0].messageDetails, 'Message details should be equal');
        Assert.isFalse(resp.data.get(SWNSyncInvoiceRunner.INVOICE_PAYMENT) == null, 'Invoice payment data should be populated');
    }

    @isTest
    static void testHandlePaymentMethodResponseWithNullResponse() {
        Response resp = new Response();
        Test.startTest();
            new SWNSyncInvoiceRunner().handlePaymentMethodResponse(resp, null);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_INFO, resp.messages[0].severity, 'Status should be info');
        Assert.areEqual(SWNMessageHelper.INFO_HEADER, resp.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.NOTHING_TO_SYNC_MSG, resp.messages[0].messageDetails, 'Message details should be equal');
    }

    @isTest
    static void testHandlePaymentMethodResponseWithStatusCodes() {
        Response resp0 = new Response();
        Response resp403 = new Response();
        Response resp404 = new Response();
        Response resp500 = new Response();
        HttpResponse httpResp0 = new HttpResponse();
        HttpResponse httpResp403 = new HttpResponse();
        HttpResponse httpResp404 = new HttpResponse();
        HttpResponse httpResp500 = new HttpResponse();
        httpResp0.setStatusCode(0);
        httpResp403.setStatusCode(403);
        httpResp404.setStatusCode(404);
        httpResp500.setStatusCode(500);

        Test.startTest();
            new SWNSyncInvoiceRunner().handlePaymentMethodResponse(resp0, httpResp0);
            new SWNSyncInvoiceRunner().handlePaymentMethodResponse(resp403, httpResp403);
            new SWNSyncInvoiceRunner().handlePaymentMethodResponse(resp404, httpResp404);
            new SWNSyncInvoiceRunner().handlePaymentMethodResponse(resp500, httpResp500);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_INFO, resp0.messages[0].severity, 'Status should be info');
        Assert.areEqual(SWNMessageHelper.INFO_HEADER, resp0.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.NOTHING_TO_SYNC_MSG, resp0.messages[0].messageDetails, 'Message details should be equal');

        Assert.areEqual(Response.STATUS_ERROR, resp403.status, 'Status should be error');
        Assert.areEqual(SWNSyncInvoiceRunner.NGBS_ERROR + ' ' + SWNSyncInvoiceRunner.PAYMENT_METHOD_FAILED, resp403.messages[0].message, 'Messages should be equal');

        Assert.areEqual(Response.STATUS_ERROR, resp404.status, 'Status should be error');
        Assert.areEqual(SWNSyncInvoiceRunner.NGBS_ERROR + ' ' + SWNSyncInvoiceRunner.PAYMENT_METHOD_NOT_FOUND, resp404.messages[0].message, 'Messages should be equal');

        Assert.areEqual(Response.STATUS_ERROR, resp500.status, 'Status should be error');
        Assert.areEqual(SWNSyncInvoiceRunner.INVOICE_SYNC_ERROR, resp500.messages[0].message, 'Messages should be equal');
    }

    @isTest
    static void testSyncAccountPackageLimits() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/limits/update', COMPLETED, '{}', 200, HttpHelper.METHOD_PUT)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Quote qt = queryQuote(OPP_NAME);

        Package__c pack = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Package__c.Account__c => qt.AccountId,
                Package__c.Account_Package_Id__c => qt.Account.Billing_ID__c
            })
            .create()
            .getRecord();

        ServiceInfo__c serviceInfo = (ServiceInfo__c) new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => qt.Id,
                ServiceInfo__c.BillingPackage__c => pack.Id
            })
            .create()
            .getRecord();

        Approval__c lastApprovedApproval = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setField(Approval__c.Monthly_Credit_Limit__c, 100)
            .build()
            .getRecord();

        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncAccountPackageLimits(resp, qt.Account, qt, lastApprovedApproval);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be Success');
        Assert.areEqual(SWNMessageHelper.SUCCESS_HEADER, resp.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.ACC_PACKAGE_LIMITS_SYNCED_MSG, resp.messages[0].messageDetails, 'Message details should be equal');
        Assert.isFalse(resp.data.get(SWNSyncInvoiceRunner.LIMIT_OVERRIDE) == null, 'Limit override data should be populated');
    }

    @isTest
    static void testHandleAccPackageLimitsResponseError() {
        Response resp = new Response();
        HttpResponse httpResp = new HttpResponse();
        httpResp.setStatusCode(500);

        Test.startTest();
            new SWNSyncInvoiceRunner().handleAccPackageLimitsResponse(resp, httpResp);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Status should be Error');
        Assert.areEqual(SWNSyncInvoiceRunner.LIMITS_SYNC_ERROR, resp.messages[0].message, 'Messages should be equal');
    }

    @isTest
    static void testSyncPackageConsolidationSettingsSuccess() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/packageConsolidationSettings', COMPLETED, PKG_CONSOLIDATION_RESP, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo(BILLING_ID + '/packageConsolidationSettings', COMPLETED, '', 200, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = buildAccount();

        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncPackageConsolidationSettings(resp, acc, false, true);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_SUCCESS, resp.status, 'Status should be Success');
        Assert.areEqual(SWNMessageHelper.SUCCESS_HEADER, resp.messages[0].message, 'Messages should be equal');
        Assert.areEqual(SWNMessageHelper.PKG_CONSOLIDATION_SETTINGS_SYNCED_MSG, resp.messages[0].messageDetails, 'Message details should be equal');
    }

    @isTest
    static void testSyncPackageConsolidationSettingsError() {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo('/packageConsolidationSettings', COMPLETED, PKG_CONSOLIDATION_RESP, 200, HttpHelper.METHOD_GET),
            new BillingHttpRequestMock.MockInfo(BILLING_ID + '/packageConsolidationSettings', 'Not Completed', '', 204, HttpHelper.METHOD_POST)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);

        Account acc = buildAccount();

        Response resp = new Response();

        Test.startTest();
            new SWNSyncInvoiceRunner().syncPackageConsolidationSettings(resp, acc, false, true);
        Test.stopTest();

        Assert.areEqual(Response.STATUS_ERROR, resp.status, 'Status should be Error');
        Assert.areEqual(SWNSyncInvoiceRunner.PKG_CONSOLIDATION_SETTINGS_SYNC_ERROR, resp.messages[0].message, 'Messages should be equal');
    }
}