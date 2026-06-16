@isTest
private with sharing class Test_SWNProServSyncDiscountRunner {
    private static final String PACKAGE_ID = '12345';
    private static final String BILLING_ID = '54321';
    private static final String OPP_NAME = 'opp name';
    private static final String PROSERV_PRODUCT = 'RingCX Basic Training';
    private static final String PS_CCOT_EXT_ID = 'PS_CCOT_123';
    private static final String PACKAGE_INFO_QT = '[{"packageInfo":{"id":' + PACKAGE_ID + ',"catalogId":"123","version":"2"},"contract":{"extId":"Office","billingId":' + BILLING_ID + ',"status":"test"}}]';
    private static final String PACKAGE_INFO_QLI = '{"id":"1","version":"5","duration":"Monthly","categoryCode":"PS","discount":{"type":"Percent","value":"3.48"},"price":"40"}';

    private static Quote queryQuote(String oppName) {
        return (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(oppName)
            .selectField('Opportunity.isDiscountsSynced__c')
            .executeQuery()
        ).getFirst();
    }

    private static void setMock(Integer statusCode, String endpoint, String method, String response) {
        final List<BillingHttpRequestMock.MockInfo> mockInfos = new List<BillingHttpRequestMock.MockInfo> {
            new BillingHttpRequestMock.MockInfo(endpoint, 'Completed', response, statusCode, method)
        };
        BillingHttpRequestMock mock = new BillingHttpRequestMock(mockInfos);
        Test.setMock(HttpCalloutMock.class, mock);
    }

    private static Opportunity buildOpportunityWithFlag(Boolean flag) {
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.isDiscountsSynced__c, flag)
            .build()
            .getRecord();
    }

    @TestSetup
    static void makeData() {
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
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
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


        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.PackageNameNew__c => 'Test',
                Quote.PackageNameOld__c => QuoteHelper.NGBS_OFFICE_PRODUCT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO_QT,
                Quote.Initial_Term_months__c => '12',
                Quote.Term_months__c => '12',
                Quote.Start_Date__c => Date.today(),
                Quote.Credit_Amount__c => 42,
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT
            })
            .create()
            .getRecord();

        Product2 proServProduct = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => PROSERV_PRODUCT,
                Product2.ExtId__c => PS_CCOT_EXT_ID,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Entitlement__c proServEntitlement = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
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
                Entitlement__c.Product__c => proServProduct.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => proServQuote.Id
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => proServProduct.Id,
                PricebookEntry.UnitPrice => 10,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => proServQuote.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => proServProduct.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => proServEntitlement.Id,
                QuoteLineItem.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                QuoteLineItem.PackageInfo__c => PACKAGE_INFO_QLI
            })
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testSyncDiscountsWithSkippedFinalize() {
        final String dtgResponse = '[{"id":72106001,"priority":"A","target":{"catalogId":"123","version":"2"},"discountTemplates":[{"id":86266001,"applicableTo":{"type":"CatalogId","id":"LC_DID_53"},'
            + '"applicationTerms":{"startDate":"2018-05-09T00:00Z[UTC]","endDate":"2020-05-09T00:00Z[UTC]"},"values":{"Monthly":{"unit":"Money","value":1E+1,'
            + '"recurringTerms":{"unit":"Months","value":1}}}}]}]';
        setMock(200, '/discountTemplateGroup', HttpHelper.METHOD_GET, dtgResponse);

        Opportunity opp = buildOpportunityWithFlag(false);

        Quote qt = queryQuote(OPP_NAME);

        SWNDataCollector sdc = new SWNDataCollector();
        sdc.syncable = new NGBSSyncables.OpportunitySync(opp);
        sdc.billingId = BILLING_ID;
        sdc.qt = qt;

        Test.startTest();
            SWNActionRunner runner = new SWNProServSyncDiscountRunner(
                qt.Id,
                SWNStep.DISCOUNT_SYNC,
                qt.Account.Billing_ID__c,
                BILLING_ID
            );
            runner.sdc = sdc;
            runner.sync();
        Test.stopTest();

        Assert.isTrue(runner.isSkipFinalize, 'Finalize should be skipped');
    }
}