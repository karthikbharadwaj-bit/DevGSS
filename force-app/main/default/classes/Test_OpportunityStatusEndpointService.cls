@IsTest
class Test_OpportunityStatusEndpointService {
    static final String CHILD_OPPORTUNITY_NAME = 'Test Child RCCC Opportunity';
    static final String RCCC_PACKAGE_INFO = String.join(
        NGBSTestDataGenerator.generateQuotePackageInfoRCCC().split('"contract":null'),
        '"contract":{"id":"a8f8K0000008OglQAE","extId":"RCCC","billingId":null}'
    );

    @TestSetup
    static void generateData() {
        Triggers.switchOff();
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.EnableMultiProductUnifiedBilling__c, true)
            .create();

        Account masterAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'MASTER_ACCOUNT_NAME',
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .create()
            .getRecord();

        Account childAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'CHILDR_ACCOUNT_NAME',
                Account.IsMultiProductTechnicalAccount__c => true,
                Account.Master_Account__c => masterAcc.Id
            })
            .create()
            .getRecord();

        Opportunity masterOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => masterAcc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => 'MASTER_OPPORTUNITY_NAME',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.IsMultiProductTechnicalOpportunity__c => false,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
            })
            .create()
            .getRecord();

        Opportunity childOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => childAcc.Id,
                Opportunity.MasterOpportunity__c => masterOpp.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => CHILD_OPPORTUNITY_NAME,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.IsMultiProductTechnicalOpportunity__c => true,
                Opportunity.isDiscountsSynced__c => true,
                Opportunity.isContractsSynced__c => true,
                Opportunity.isUpsellStepCompleted__c => true,
                Opportunity.isDownsellStepCompleted__c => true,
                Opportunity.isUpgradeStepCompleted__c => true,
                Opportunity.isInvoiceStepCompleted__c => true,
                Opportunity.isChargeTermSynced__c => true,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Master Quote',
                Quote.OpportunityId => masterOpp.Id,
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        Quote rcccQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test RCCC Quote',
                Quote.OpportunityId => childOpp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.MasterQuote__c => masterQt.Id,
                Quote.Package_Info__c => RCCC_PACKAGE_INFO,
                Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER
            })
            .create()
            .getRecord();

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_DIGITALLINE_UNLIMITED',
                Product2.ExtId__c => 'LC_DL-UNL_50',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
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

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'ENTITLEMENT_NAME',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => childAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => rcccQt.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => rcccQt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.PackageInfo__c => TestDataGenerator.TEST_PACKAGE_INFO
            })
            .create();
        Triggers.switchOn();
    }

    @IsTest
    static void testGetByNonExistOppId() {
        Opportunity testOpp = selectTestOpp();
        Id dummyId = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();
        List<Id> opIDs = new List<Id> { testOpp.Id, dummyId };

        Test.startTest();
            OpportunityStatusEndpointHelper.OpportunityParamsResponse params = doTest(opIDs);
        Test.stopTest();

        Assert.areEqual(1, params.data.opportunities.size(), 'Response did not return required data');
        Assert.areEqual('No opportunity with id - ' + dummyId , params.messages[0].messageDetails, 'Response did not return required data');
        Assert.areEqual('Non-existent Opportunity Id' , params.messages[0].message, 'Response did not return required data');
    }
    @IsTest
    static void testGetByInvalidOppId() {
        Opportunity testOpp = selectTestOpp();
        String invalidId = '0060x000';
        List<String> opIDs = new List<String> { String.valueOf(testOpp.Id), invalidId };

        Test.startTest();
            OpportunityStatusEndpointHelper.OpportunityParamsResponse params = doTest(opIDs);
        Test.stopTest();

        Assert.areEqual(1, params.data.opportunities.size(), 'Response did not return required data');
        Assert.areEqual('Invalid id: ' + invalidId , params.messages[0].message, 'Response did not return required data');
    }
    @IsTest
    static void testGetByEmptyOppId() {
        Test.startTest();
            OpportunityStatusEndpointHelper.OpportunityParamsResponse params = doTest(new List<String>());
        Test.stopTest();

        Assert.areEqual(0, params.data.opportunities.size(), 'Response did not return required data');
    }
    @IsTest
    static void testGetByOppId_MPL() {
        Opportunity testOpp = selectTestOpp();
        List<Id> opIDs = new List<Id> { testOpp.id };

        Test.startTest();
            OpportunityStatusEndpointHelper.OpportunityParamsResponse params = doTest(opIDs);
        Test.stopTest();

        Assert.areEqual(1, params.data.opportunities.size(), 'Response did not return required data');
        Assert.isNotNull(params.data.opportunities[0].ngbsSyncStatus, 'ngbsSyncStatus should not be empty');
    }
    @IsTest
    static void testGetByOppId_MPUB() {
        Triggers.switchOff();
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'ACCOUNT_NAME',
                Account.IsMultiProductTechnicalAccount__c => false
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => acc.Id,
                Opportunity.CloseDate => Date.today(),
                Opportunity.Name => 'OPP_NAME',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
            })
            .create()
            .getRecord();

        Quote masterQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test Master Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => true,
                Quote.IsMultiProductTechnicalQuote__c => false,
                Quote.ServiceName__c => QuoteHelper.NGBS_OFFICE_PRODUCT
            })
            .create()
            .getRecord();

        Quote rcccQt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'Test RCCC Quote',
                Quote.OpportunityId => opp.Id,
                Quote.isPrimary__c => false,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.MasterQuote__c => masterQt.Id,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => RCCC_PACKAGE_INFO,
                Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER
            })
            .create()
            .getRecord();

        Product2 productDigitalLineUnlimited = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'PRODUCT_DIGITALLINE_UNLIMITED1',
                Product2.ExtId__c => 'LC_DL-UNL_51',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
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

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Name => 'ENTITLEMENT_NAME1',
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => acc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.PackageCatalogId__c => '18',
                Entitlement__c.PackageVersion__c => '1',
                Entitlement__c.PackageDuration__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Product__c => productDigitalLineUnlimited.Id,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Entitlement__c.Quote__c => rcccQt.Id
            })
            .create()
            .getRecord();

        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => rcccQt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => productDigitalLineUnlimited.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.NewQuantity__c => 5,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Entitlement__c => ent.Id,
                QuoteLineItem.PackageInfo__c => TestDataGenerator.TEST_PACKAGE_INFO
            })
            .create();

        new SObjectBuilder(ServiceInfo__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                ServiceInfo__c.Quote__c => rcccQt.Id,
                ServiceInfo__c.IsProcessOrderSent__c => true,
                ServiceInfo__c.DiscountStepStatus__c => true,
                ServiceInfo__c.ContractStepStatus__c => true,
                ServiceInfo__c.UpsellStepStatus__c => true,
                ServiceInfo__c.DownsellStepStatus__c => true,
                ServiceInfo__c.UpgradeStepStatus__c => true,
                ServiceInfo__c.InvoiceStepStatus__c => true,
                ServiceInfo__c.ChargeTermStepStatus__c => true
            })
            .create();
        Triggers.switchOn();

        List<Id> opIds = new List<Id> { opp.Id };

        Test.startTest();
            OpportunityStatusEndpointHelper.OpportunityParamsResponse params = doTest(opIds);
        Test.stopTest();

        Assert.areEqual(1, params.data.opportunities.size(), 'Response did not return required data');
        Assert.isNotNull(params.data.opportunities[0].ngbsSyncStatus, 'ngbsSyncStatus should not be empty');
    }

    private static OpportunityStatusEndpointHelper.OpportunityParamsResponse doTest(Object oppIds) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"opportunityIds":' + JSON.serialize(oppIds) + '}');
        RestContext.request = req;

        OpportunityStatusEndpointService.getByOppId();

        String responseBody = RestContext.response.responseBody.toString();

        return (OpportunityStatusEndpointHelper.OpportunityParamsResponse) JSON.deserialize(
            responseBody,
            OpportunityStatusEndpointHelper.OpportunityParamsResponse.class
        );
    }

    private static Opportunity selectTestOpp() {
        return (Opportunity) new ListOptional(new OpportunitySelector()
            .selectOpportunityByName(CHILD_OPPORTUNITY_NAME)
            .withoutSelectorFieldsIncluded()
            .selectField(Opportunity.Id)
            .executeQuery()
        ).getFirst();
    }
}