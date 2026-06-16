@isTest
public class Test_OpportunityValidator {
    public final static String packageInfo = '[{"id":"5","version":"3","packageInfo":{"catalogId":"5"' +
        ',"version":"3"},"productName":"Office","duration":"Monthly","edition":{"id":1,"name":"Standard"}' +
        ',"contract":{"id":"' + HardcodedIdsMapper.getMatchedObjectId('a8fg00000000K9xAAE') +
        '"},"offerType":"Regular","globalPackageLimits":[{"value":"6000","code":"MONTHLY_AMOUNT_LIMIT"' +
        ',"name":"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType"' +
        ':"Any","target":"Global","override":false}],"permissions":null}]';

    @testSetup
    static void setUp() {
        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Triggers.switchOn();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
    }

    @isTest
    static void testNoQuotesValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        Test.startTest();
            Validator noQuotesValidator =
                new OpportunityValidator.NoQuotesValidator('CRITICAL', new List<Quote>(), opp);
            Response resp = noQuotesValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_No_sales_agreements_text),
            'No quotes error is expected'
        );
    }

    @isTest
    static void testBillingAddressValidatorEmptyStreet() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => '',
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingStreetValidator = new OpportunityValidator.BillingAddressValidator(reselectedOpty);
            Response resp = billingStreetValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_CC_Billing_Address_is_incomplete),
            'Billing street check failed'
        );
    }

    @isTest
    static void testBillingAddressValidatorEmptyCity() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCity => '',
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingCityValidator = new OpportunityValidator.BillingAddressValidator(reselectedOpty);
            Response resp = billingCityValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_CC_Billing_Address_is_incomplete),
            'Billing city check failed'
        );
    }

    @isTest
    static void testBillingAddressValidatorEmptyState() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => '',
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => 'canada'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingStateValidator = new OpportunityValidator.BillingAddressValidator(reselectedOpty);
            Response resp = billingStateValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_CC_Billing_Address_is_incomplete),
            'Billing state check failed'
        );
    }

    @isTest
    static void testBillingAddressValidatorEmptyPostalCode() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => '',
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingPostalCodeValidator = new OpportunityValidator.BillingAddressValidator(reselectedOpty);
            Response resp = billingPostalCodeValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_CC_Billing_Address_is_incomplete),
            'Billing postal code check failed'
        );
    }

    @isTest
    static void testBillingAddressValidatorEmptyCountry() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => ''
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingCountryValidator = new OpportunityValidator.BillingAddressValidator(reselectedOpty);
            Response resp = billingCountryValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_CC_Billing_Address_is_incomplete),
            'Billing country check failed'
        );
    }

    @isTest
    static void testActiveAgreementValidatorPriceChanged() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Package_Info__c => packageInfo,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Test.startTest();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => product.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.Quantity__c => 3,
                Entitlement__c.Price__c => 200
            })
            .create()
            .getRecord();


        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Validator billingActiveAgreementValidator =
            new OpportunityValidator.BillingActiveAgreementValidator(qt, reselectedOpty);
        Response resp = billingActiveAgreementValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size(), 'Validation should return error messages');
        System.assert(
            resp.messages[0].messageDetails.contains(Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text),
            'Active agreement should be required'
        );
    }

    @isTest
    static void testActiveAgreementValidatorUpsellForMigratedAcc() {

        /* Account.Active_Sales_Agreement__c == null */
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Package_Info__c => packageInfo,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingActiveAgreementValidator =
                new OpportunityValidator.BillingActiveAgreementValidator(qt, reselectedOpty);
            Response resp = billingActiveAgreementValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size(), 'Validation should return error messages');
        System.assert(
            resp.messages[0].messageDetails.contains(Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text),
            'Active agreement should be required'
        );
    }

    @isTest
    static void testActiveAgreementValidatorIsUpgrade() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Package_Info__c => packageInfo,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        /* Imitate that active agrement exist */
        testAccount.Active_Sales_Agreement__c = qt.Id;

            update testAccount;
        Triggers.switchOn();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => product.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.Quantity__c => 3,
                Entitlement__c.Price__c => 200
            })
            .create()
            .getRecord();

        Test.startTest();
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];
        Test.stopTest();
        System.assertNotEquals(0, reselectedQuotes.size(), 'Should have at least one quote');
        Validator billingActiveAgreementValidator =
            new OpportunityValidator.BillingActiveAgreementValidator(primaryQuote, reselectedOpty);
        Response resp = billingActiveAgreementValidator.validate(new Response());
        System.assertNotEquals(0, resp.messages.size(), 'Validation should return error messages');
        System.assert(
            resp.messages[0].messageDetails.contains(Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text),
            'Active agreement should be required'
        );
    }

    @isTest
    static void testActiveAgreementValidatorDraftAgreement() {
        /* Account.Active_Sales_Agreement__c == null */
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => '1234567'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL
            })
            .create()
            .getRecord();
        /* Agreement in draft status - is not allowed */
        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Package_Info__c => packageInfo,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator billingActiveAgreementValidator =
                new OpportunityValidator.BillingActiveAgreementValidator(qt, reselectedOpty);
            Response resp = billingActiveAgreementValidator.validate(new Response());
        Test.stopTest();

        System.assert(
            resp.messages[0].messageDetails.contains(Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text),
            'Active agreement should be required'
        );
    }

    @isTest
    static void testGetScaledValue() {
        Decimal zeroValue = OpportunityValidator.getScaledValue(null);
        System.assertEquals(0, zeroValue, 'Null should be considered as 0');

        Decimal scaledValue1 = OpportunityValidator.getScaledValue(10.162);
        System.assertEquals(10.16, scaledValue1, 'There is an error in scaling Decimal value');
    }

    @isTest
    static void testNoOpportunityValidator() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .build()
            .getRecord();

        Validator passedValidator = new OpportunityValidator.SyncWithNGBS_NoOpportunityValidator(opp);
        Validator failedValidator = new OpportunityValidator.SyncWithNGBS_NoOpportunityValidator(null);

        Response respByPassedValidator = new Response();
        Response respByFailedValidator = new Response();

        Test.startTest();

        respByPassedValidator = passedValidator.validate(respByPassedValidator);
        respByFailedValidator = failedValidator.validate(respByFailedValidator);

        Test.stopTest();

        System.assert(respByPassedValidator.messages.isEmpty(), 'Validation should be passed');
        System.assertEquals(Label.NoOpportunityForSyncWithNGBS, respByFailedValidator.messages.get(0).messageDetails,
            'Opportunity to validate should be null');
    }

    @isTest
    static void testSyncFailedValidator() {
        Opportunity oppPass = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.isSyncedToICB__c => true,
                Opportunity.isICBProvisioningComplete__c => true
            })
            .create()
            .getRecord();

        NGBSSyncables.ISyncable syncablePass = NGBSSyncables.getSyncable(false, null, oppPass);

        Opportunity oppFailed = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.isSyncedToICB__c => false,
                Opportunity.isICBProvisioningComplete__c => true
            })
            .build()
            .getRecord();

        NGBSSyncables.ISyncable syncableFailed = NGBSSyncables.getSyncable(false, null, oppFailed);

        Validator passedValidator = new OpportunityValidator.SyncWithNGBS_SyncInContactFailedValidator(syncablePass);
        Validator failedValidator = new OpportunityValidator.SyncWithNGBS_SyncInContactFailedValidator(syncableFailed);

        Response respByPassedValidator = new Response();
        Response respByFailedValidator = new Response();

        Test.startTest();

        respByPassedValidator = passedValidator.validate(respByPassedValidator);
        respByFailedValidator = failedValidator.validate(respByFailedValidator);

        Test.stopTest();

        System.assert(respByPassedValidator.messages.isEmpty(), 'Validation should be passed');
        System.assertEquals(IcbHelper.OPPORTUNITY_SYNC_WITH_NGBS_FAILED_DETAILS, respByFailedValidator.messages.get(0).messageDetails,
            'Sync to ICB should be false and ICB provisioning completed');
    }

    @isTest
    static void testClosedOpportunityValidator() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .build()
            .getRecord();
        opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;

        Validator validator = new OpportunityValidator.SyncWithNGBS_ClosedOpportunityValidator(opp);
        Response resp = new Response();

        Test.startTest();

        resp = validator.validate(resp);

        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'Opportunity should be closed');
    }

    @isTest
    static void testNotClosedOpportunityValidator() {
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .build()
            .getRecord();
        opp.StageName = OpportunityHelper.STAGE_NAME_ORDER;

        Validator validator = new OpportunityValidator.SyncWithNGBS_ClosedOpportunityValidator(opp);
        Response resp = new Response();

        Test.startTest();

        resp = validator.validate(resp);

        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size(), 'Validation shouldn\'t be passed and errors should be handled');
        System.assertEquals(Label.NotClosedOpportunity, resp.messages.get(0).messageDetails, 'Opportunity should be not closed');
    }

    @IsTest
    static void testUnsupportedBrandsValidator_syncWithNGBS_failsOnUnsupportedBrand() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .build()
                .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Opportunity.CloseDate => System.today(),
                        Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE
                })
                .build()
                .getRecord();
        opp.Account = acc;
        Validator validator = new OpportunityValidator.UnsupportedBrandValidator(
                Validator.SEVERITY_CRITICAL,
                opp,
                new Set<String> { RingCentralHelper.BRAND_VODAFONE },
                QuoteValidator.BillingProcessType.SYNC_WITH_NGBS
                );
        Response resp = new Response();
        Response.ResponseMessage[] messages = new List<Response.ResponseMessage>();
        String expectedError = String.format(Label.IsNotRequiredToSyncWithNGBS, new List<Object> { opp.Brand_Name__c });
        String expectedDetails = String.format(Label.IsNotAvailableToSyncWithNGBSDetails, new List<Object> { opp.Brand_Name__c });

        Test.startTest();
        resp = validator.validate(resp);
        messages = resp.messages;
        Test.stopTest();

        System.assertEquals(1, messages.size(), 'Validation should fail and error message must be set');
        System.assertEquals(expectedError, messages.get(0).message, 'Correct error message must be set');
        System.assertEquals(expectedDetails, messages.get(0).messageDetails, 'Correct error message details must be set');
    }

    @IsTest
    static void testUnsupportedBrandsValidator_signUp_failsOnUnsupportedBrand() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .build()
                .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Opportunity.CloseDate => System.today(),
                        Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VODAFONE
                })
                .build()
                .getRecord();
        opp.Account = acc;
        Validator validator = new OpportunityValidator.UnsupportedBrandValidator(
                Validator.SEVERITY_CRITICAL,
                opp,
                new Set<String> { RingCentralHelper.BRAND_VODAFONE },
                QuoteValidator.BillingProcessType.SIGN_UP
        );
        Response resp = new Response();
        Response.ResponseMessage[] messages = new List<Response.ResponseMessage>();
        String expectedError = String.format(Label.IsNotAvailableForSignUp, new List<Object> { opp.Brand_Name__c });
        String expectedDetails = String.format(Label.IsNotAvailableForSignUpDetails, new List<Object> { opp.Brand_Name__c });

        Test.startTest();
        resp = validator.validate(resp);
        messages = resp.messages;
        Test.stopTest();

        System.assertEquals(1, messages.size(), 'Validation should fail and error message must be set');
        System.assertEquals(expectedError, messages.get(0).message, 'Correct error message must be set');
        System.assertEquals(expectedDetails, messages.get(0).messageDetails, 'Correct error message details must be set');
    }

    @IsTest
    static void testUnsupportedBrandsValidator_passesOnNonUnsupportedBrand() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
                .build()
                .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Opportunity.CloseDate => System.today(),
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
                })
                .build()
                .getRecord();
        opp.Account = acc;
        Validator validator = new OpportunityValidator.UnsupportedBrandValidator(
                Validator.SEVERITY_CRITICAL,
                opp,
                new Set<String> { RingCentralHelper.BRAND_VODAFONE },
                QuoteValidator.BillingProcessType.SYNC_WITH_NGBS
        );
        Response resp = new Response();
        Response.ResponseMessage[] messages = new List<Response.ResponseMessage>();

        Test.startTest();
        resp = validator.validate(resp);
        messages = resp.messages;
        Test.stopTest();

        System.assertEquals(0, messages.size(), 'Validation should pass and no error messages must be set');
    }

    @isTest
    static void testSignUpNoQuotesValidator() {
        Test.startTest();
            Validator signUpNoQuotesValidator = new OpportunityValidator.SignUp_NoQuotesValidator('CRITICAL', null);
            Response resp = signUpNoQuotesValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size(), 'Validation should not pass and error messages must be set');
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_SignUp_Validation_SignUp_failed),
            'No quotes error is expected'
        );
    }

    @isTest
    static void testPrimaryQuoteWithChangedTermsNotAgreementValidator() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.OpptyActiveSalesAgreementValidation__c => true
            })
            .create()
            .getRecord();

        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{})
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY_CONTRACT
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Initial_Term_Months__c => '24',
                Quote.Term_months__c => '24',
                Quote.Auto_Renewal__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => product.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.Quantity__c => 3,
                Entitlement__c.Price__c => 200
            })
            .create()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();

        testAccount.Active_Sales_Agreement__c = qt.Id;
        testAccount.Billing_ID__c = '1234543';
        update testAccount;

        Test.startTest();

        Opportunity newOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote newQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => newOpp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Initial_Term_Months__c => '24',
                Quote.Term_months__c => '36',
                Quote.Auto_Renewal__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => packageInfo,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(newOpp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{newOpp.Id})
            .executeQuery()
            .get(0);

        Validator activeAgreementValidator =
            new OpportunityValidator.BillingActiveAgreementValidator(primaryQuote, reselectedOpty);
        Response resp = activeAgreementValidator.validate(new Response());

        Test.stopTest();

        System.assert(
            resp.messages[0].messageDetails.contains(Label.Opportunity_Error_OnClose_Active_agreement_terms_help_text),
            'Active agreement should be required when terms were changed'
        );
    }

    @isTest
    static void testVerizonValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => RingCentralHelper.BRAND_VERIZON,
                Opportunity.BusinessIdentity__c => '{"currency":"USD","biId":"47"}'
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator validator =
                new OpportunityValidator.SignUp_VerizonValidator('CRITICAL', opp);
            Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assertEquals(Label.VerizonCantBeSignedUp, resp.messages[0].messageDetails, 'Verizon validation did not fire');
    }

    @IsTest
    static void testSwissVatIdValidator() {
        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CountryCodes__c.CountryName__c => 'che;switzerland',
                CountryCodes__c.CountryNameFull__c => 'Switzerland',
                CountryCodes__c.CountryNameShort__c => 'CH',
                CountryCodes__c.Name => 'CHE'
            })
            .create()
            .getRecord();

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => '',
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => 'Switzerland'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
            })
            .create()
            .getRecord();

        Test.startTest();
            Opportunity reselectOppNewBusiness = (Opportunity) new OpportunitySelector()
                .selectOpportunityForClose(new Set<Id>{opp.Id})
                .executeQuery()
                .get(0);

            Validator validatorNewBusiness = new OpportunityValidator.SwissVatIdValidator(reselectOppNewBusiness, new List<Approval__c>());
            Response respNewBusiness = validatorNewBusiness.validate(new Response());

            acc.Billing_ID__c = '123';
            Triggers.switchOff();
            update acc;
            Triggers.switchOn();
            Opportunity reselectOppExistingBusiness = (Opportunity) new OpportunitySelector()
                .selectOpportunityForClose(new Set<Id>{opp.Id})
                .executeQuery()
                .get(0);

            Validator validatorExistingBusiness = new OpportunityValidator.SwissVatIdValidator(reselectOppExistingBusiness, new List<Approval__c>());
            Response respExistingBusiness = validatorExistingBusiness.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respNewBusiness.messages.size());
        System.assertEquals(Label.OpportunitySignUpError, respNewBusiness.messages[0].message, 'Error message must be with value "Signup can\'t be performed."');
        System.assertEquals(Label.VatNumberOrVatIdRequired, respNewBusiness.messages[0].messageDetails, 'Error message must be with value "Please, provide VAT number or submit and approve VAT ID Approval."');

        System.assertNotEquals(0, respExistingBusiness.messages.size());
        System.assertEquals(Label.OpportunityCloseError, respExistingBusiness.messages[0].message, 'Error message must be with value "Opportunity can\'t be closed."');
        System.assertEquals(Label.VatNumberOrVatIdRequired, respExistingBusiness.messages[0].messageDetails, 'Error message must be with value "Please, provide VAT number or submit and approve VAT ID Approval."');
    }

    @IsTest
    static void testTaiwanVatIdValidator() {

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingStreet => '',
                Account.BillingCity => ValueProviderBuilder.provideUniqueString(),
                Account.BillingState => ValueProviderBuilder.provideUniqueString(),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString(),
                Account.BillingCountry => 'Taiwan'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU
            })
            .create()
            .getRecord();

        Test.startTest();  
            Opportunity reselectOpp = (Opportunity) new OpportunitySelector()
                .selectOpportunityForClose(new Set<Id>{opp.Id})
                .executeQuery()
                .get(0);          
            Validator taiwanValidator = new OpportunityValidator.TaiwanVatIdValidator(new OpportunityValidator.TaiwanVatandTaxValidatorParams(
                reselectOpp,
                new List<Approval__c>(),
                true
            ));
            Response resp = taiwanValidator.validate(new Response());
        Test.stopTest();
        
        Assert.isFalse(resp.messages.size() == 0, 'Validation should fail and error messages must be set');
        Assert.areEqual(Label.VatNumberOrTaxExemptApprovalRequired, resp.messages[0].messageDetails, 'Error message must be with value "Please, provide VAT number or submit and approve VAT ID Approval."');
    }

    @isTest
    static void testNoQuotesValidatorRiseBrand() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RISE_AMERICA
            })
            .create()
            .getRecord();
        Test.startTest();
            Validator noQuotesValidator =
                new OpportunityValidator.NoQuotesValidator('CRITICAL', new List<Quote>(), opp);
            Response resp = noQuotesValidator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assert(
            resp.messages[0].message.contains(Label.Opportunity_Error_OnClose_No_sales_agreements_text),
            'No quotes error is expected'
        );
    }

    @isTest
    static void testRCEventsAdminRoleValidator_TechnicalQuote() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        String eventsPackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object> {
            'Id' => '5',
            'Version' => '3',
            'ProductName' => Constants.CONST_RC_EVENT,
            'Duration' => 'Monthly'
        });
        Quote eventsQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Name => 'Test Events Quote',
                Quote.Package_Info__c => eventsPackageInfo,
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => Constants.CONST_RC_EVENT
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();
            Validator rcEventsAdminRoleValidator = new OpportunityValidator.RCEventsAdminRoleValidator(
                Validator.SEVERITY_CRITICAL, 
                opp, 
                eventsQuote
            );
            Response resp = rcEventsAdminRoleValidator.validate(new Response());
        Test.stopTest();
        Assert.areNotEqual(0, resp.messages.size(), 'Validation should fail when Events quote has no RC Events Admin role');
        Assert.areEqual(Response.SEVERITY_ERROR, resp.messages[0].severity, 'Error severity should be ERROR');
        Assert.isTrue(
            resp.messages[0].message.contains(Label.Admin_Contact_Role_Missing) ||
            resp.messages[0].messageDetails.contains(Label.Admin_Role_Required),
            'Error message should contain expected Events admin role message'
        );
    }

    @isTest
    static void testRCEventsAdminRoleValidator_MultiplePackages() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        String mvpPackageInfo = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object> {
            'Id' => '1',
            'Version' => '1',
            'ProductName' => 'MVP',
            'Duration' => 'Monthly'
        });
        String eventsPackageInfoMulti = NGBSTestDataGenerator.generateQuotePackageInfo(new Map<String, Object> {
            'Id' => '2',
            'Version' => '2',
            'ProductName' => Constants.CONST_RC_EVENT,
            'Duration' => 'Monthly'
        });
        String multiProductPackageInfo = '[' + 
            mvpPackageInfo.substring(1, mvpPackageInfo.length() - 1) + ',' +
            eventsPackageInfoMulti.substring(1, eventsPackageInfoMulti.length() - 1) + 
            ']';
        Quote multiProductQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Name => 'Test Multi-Product Quote with Events',
                Quote.Package_Info__c => multiProductPackageInfo,
                Quote.IsMultiProductTechnicalQuote__c => false 
            })
            .create()
            .getRecord();
        Triggers.switchOn();
        Test.startTest();
            Validator rcEventsAdminRoleValidator = new OpportunityValidator.RCEventsAdminRoleValidator(
                Validator.SEVERITY_CRITICAL, 
                opp, 
                multiProductQuote
            );
            Response resp = rcEventsAdminRoleValidator.validate(new Response());
        Test.stopTest();

        Assert.areNotEqual(0, resp.messages.size(), 'Validation should fail when multiproduct quote contains Events and no RC Events Admin role exists');
        Assert.areEqual(Response.SEVERITY_ERROR, resp.messages[0].severity, 'Error severity should be ERROR');
        Assert.isTrue(
            resp.messages[0].message.contains(Label.Admin_Contact_Role_Missing) ||
            resp.messages[0].messageDetails.contains(Label.Admin_Role_Required),
            'Error message should contain expected Events admin role message'
        );
    }
}