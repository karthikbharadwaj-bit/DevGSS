@isTest
private class Test_QuoteWizardPageController {

    @TestSetup
    static void setup() {
        upsert new NGBS_Settings__c(
            BaseEndpoint__c = 'https://testapi',
            CatalogPath__c = '/restapi/v1.0/catalog',
            AccountManagerPath__c = '/restapi/account-manager/v1.0',
            Login__c = '123',
            Password__c = '456'
        );

        Account testAcc = new Account(
            Name = 'testAcc',
            inContact_account_ID__c = '123456'
        );
        insert testAcc;

        Opportunity testOpp = new Opportunity(
            Name = 'testOpp',
            AccountId = testAcc.Id,
            StageName = '1. Qualify',
            Is_Billing_Opportunity__c = false,
            Brand_Name__c = OpportunityHelper.BRAND_AVAYA
        );
        insert testOpp;

        new SObjectBuilder(LeadConversionConfiguration__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    LeadConversionConfiguration__c.Name => OpportunityHelper.BRAND_AVAYA,
                    LeadConversionConfiguration__c.IsQuotingAvailableNewBusiness__c => true,
                    LeadConversionConfiguration__c.isNGBS__c => true
                }
            )
            .create();
    }

    @isTest
    static void testStaticMethods() {

        String testFeatureId = '11';
        String testSubFeatureId = '11';
        String testProductType = 'BtProServ';

        List<QuoteLineItemRestrictionSettings__c> restrictionsList = new List<QuoteLineItemRestrictionSettings__c>();

        QuoteLineItemRestrictionSettings__c qliTestRestriction = new QuoteLineItemRestrictionSettings__c(
            Name = 'testSetting',
            FeatureId__c = testFeatureId,
            SubFeatureId__c = testSubFeatureId,
            DiscountTypesAvailable__c = QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
        );
        restrictionsList.add(qliTestRestriction);

        QuoteLineItemRestrictionSettings__c qliRestrictionWithType = new QuoteLineItemRestrictionSettings__c(
            Name = testProductType,
            Product_Type__c = testProductType
        );
        restrictionsList.add(qliRestrictionWithType);

        insert restrictionsList;

        Map<String, QuoteLineItemRestrictionSettings__c> restrictionSettingsMap = QuoteWizardPageController.getRestrictionsMap();
        System.assertNotEquals(null, restrictionSettingsMap);
        System.assert(!restrictionSettingsMap.isEmpty());

        // if Product_Type__c is empty and QuoteLineItemRestrictionSettings__c.SubFeatureId__c is not blank -
            // QuoteLineItemRestrictionSettings__c.FeatureId__c + 'k' + QuoteLineItemRestrictionSettings__c.SubFeatureId__c will be used as key
        System.assert(restrictionSettingsMap.containsKey(testFeatureId + 'k' + testSubFeatureId));
        System.assertEquals(
            restrictionSettingsMap.get(testFeatureId + 'k' + testSubFeatureId).DiscountTypesAvailable__c,
            qliTestRestriction.DiscountTypesAvailable__c
        );

        // if Product_Type__c is not empty - it will be used as key
        System.assert(restrictionSettingsMap.containsKey(testProductType));


        String originUrl = URL.getOrgDomainUrl().toExternalForm();
        System.assertNotEquals(null, originUrl);
        System.assertNotEquals('', originUrl);
        System.assert(originUrl.contains('.my.salesforce.com'));
    }

    @isTest
    static void testInvokeController() {

        Feature_Toggle__c featureToggle = new Feature_Toggle__c(
            IsContactCenterTabVisible__c = true
        );
        insert featureToggle;

        // select test data
        Opportunity testOpp = [SELECT Id, Is_Billing_Opportunity__c, BusinessIdentity__c,
                AccountId, Account.Billing_ID__c, isFedRamp__c, Brand_Name__c, Account.inContact_account_ID__c, Account.GSP__c
            FROM Opportunity
            LIMIT 1];

        Test.startTest();

            ApexPages.StandardController sc = new ApexPages.standardController(testOpp);

            BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
            Test.setMock(HttpCalloutMock.class, tstMock);
            QuoteWizardPageController qwpc = new QuoteWizardPageController(sc);

            // check controller instance variables
            System.assertNotEquals(null, qwpc.currentOpportunity);
            System.assertNotEquals(null, qwpc.flatCurrentOpportunity);
            System.assertNotEquals(null, qwpc.settings);

            System.assertEquals(QuoteHelper.STATUS_NEW_CUSTOMER, qwpc.defaultUpsellStatus);

            // check Picklist values is initialized
            System.assertNotEquals(null, qwpc.quoteTypeValues);
            System.assertNotEquals(null, qwpc.initialTermMonthsValues);
            System.assertNotEquals(null, qwpc.specialTermsValues);
            System.assertNotEquals(null, qwpc.termMonthsValues);
            System.assertNotEquals(null, qwpc.statusValues);
            System.assertNotEquals(null, qwpc.proServStatusValues);
            System.assertNotEquals(null, qwpc.proServForecastCategoryValues);
            System.assertNotEquals(null, qwpc.proServOfferTypeValues);
            System.assertNotEquals(null, qwpc.proServProjectComplexityValues);
            System.assertNotEquals(null, qwpc.proServSOWTypeValues);

            System.assertEquals(featureToggle.IsContactCenterTabVisible__c, qwpc.IsCCTabVisible);

            System.assertNotEquals(null, qwpc.engageLegalApprovalMock);
            System.assertEquals(ApprovalHelper.RT_ID_ENGAGE_LEGAL, qwpc.engageLegalApprovalMock.RecordTypeId);
            System.assertEquals(true, qwpc.isQuotingAvailable, 'Should be true for the brand with quoting enabled');

        Test.stopTest();
    }

    @isTest
    static void testGetComponentToCreate() {
        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity testOpp = (Opportunity) oppSelector
            .selectOpportunityByName('testOpp')
            .selectFields(oppSelector.getDefaultOpptyFieldList())
            .setLimit(1)
            .executeQuery()
            .get(0);
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setField(Feature_Toggle__c.EnableLWCLandingPageOfWizard__c, true)
            .create();
        ApexPages.StandardController sc = new ApexPages.standardController(testOpp);
        Test.startTest();
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        QuoteWizardPageController qwpc = new QuoteWizardPageController(sc);
        PageReference pageRef = Page.QuoteWizard;
        qwpc.isDQGoaEnabled = false;
        Test.setCurrentPage(pageRef);

        System.assertEquals('c:QuoteWizardWrapper', qwpc.getComponentToCreate(),
        '"c:QuoteWizardWrapper" component name should be returned if DQ Goa is disabled');

        qwpc.isDQGoaEnabled = true;

        System.assertEquals('c:UQTQuoteList', qwpc.getComponentToCreate(),
        '"c:UQTQuoteList" component name should be returned if page address parameters "quoteId" or "newQuoteType" are empty, DQ Goa is enabled ' +
        'and EnableLWCLandingPageOfWizard__c is enabled in Feature Toggle');

        pageRef.getParameters().put('quoteId','123456');
        System.assertEquals('c:QuoteWizardWrapper', qwpc.getComponentToCreate(),
        '"c:QuoteWizardWrapper" component name should be returned if page address parameters "quoteId" is not empty and DQ Goa is enabled');

        qwpc.isLegacyBusinessIdentity = true;

        System.assertEquals('c:QuoteWizardWrapper', qwpc.getComponentToCreate(),
        '"c:QuoteWizardWrapper" component name should be returned if page address parameters "quoteId" or "newQuoteType" are empty, DQ Goa is enabled, ' +
        'EnableLWCLandingPageOfWizard__c is enabled in Feature Toggle but Opportunity brand name is in isLegacyBusinessIdentity custom setting ' +
        'with isNGBS__c = false (legacy brand)');

        Test.stopTest();
    }

    @isTest
    static void testGetParamsToPass() {
        OpportunitySelector oppSelector = new OpportunitySelector();
        Opportunity testOpp = (Opportunity) oppSelector
            .selectOpportunityByName('testOpp')
            .selectFields(oppSelector.getDefaultOpptyFieldList())
            .setLimit(1)
            .executeQuery()
            .get(0);
        ApexPages.StandardController sc = new ApexPages.standardController(testOpp);
        Test.startTest();
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        QuoteWizardPageController qwpc = new QuoteWizardPageController(sc);

        Map<String, Object> paramsMap = (Map<String, Object>) JSON.deserializeUntyped(qwpc.getParamsToPass());
        Test.stopTest();

        Map<String, Object> oppFromParams = (Map<String, Object>) paramsMap.get('opportunity');
        Id oppIdFromParams = (Id) oppFromParams.get('Id');
        System.assertEquals(testOpp.Id, oppIdFromParams, 'Params should contain Opportunity from Controller');
    }

    @isTest
    private static void testIsContactCenterPackagesExistInBilling() {
        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => 'TestOpportunity',
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_RINGCENTRAL,
                Opportunity.CloseDate => System.today(),
                Opportunity.BusinessIdentity__c => OpportunityHelper.businessIdentitySerialize(4, RingCentralHelper.USD),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS
            })
            .build()
            .getRecord();

        Test.startTest();
        BillingHttpRequestMock tstMock = new BillingHttpRequestMock();
        Test.setMock(HttpCalloutMock.class, tstMock);
        Boolean result = QuoteWizardPageController.isContactCenterPackagesExistInBilling(testOpp);
        Test.stopTest();

        Assert.isTrue(result, 'Conctact Center packages for RingCentral bi in NGBS must be found');
    }
}