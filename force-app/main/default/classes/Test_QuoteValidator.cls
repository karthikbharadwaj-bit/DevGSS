@isTest
public class Test_QuoteValidator {

    private static String NGBS_ACCOUNT_RESPONSE = '{"id":"1","packages":[{"catalogId":"20",' +
        '"version":"1","labels":{"upgradeWizardExpiration":["Expired"]},"offerType":"Regular","id":"2","licenses":[{"id":"3","qty":5,"catalogId": "' + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}]}';
    private static String getNgbsPackageResponse() {
        return '{"catalogId":"18","version":"1","labels":{"upgradeWizardExpiration":["' + PACKAGE_LABEL_STATE + '"]},"offerType":"Regular","id":"2","licenses":[{"id":"3","qty":5,"catalogId": "' + Product2Helper.SUBSCRIPTION_LICENSE + '", "subLicenses":[]}],"masterDuration": "Monthly"}';
    }
    private static String PACKAGE_LABEL_STATE = 'Expired';

    private static final String PACKAGE_INFO =
        '[{"id":"18","version":"1","packageInfo":{"id":1389379001,"catalogId":"' +
            '18","version":"1"},"productName":"Office"' +
            ',"duration":"' + Product2Helper.CHARGE_TERM_MONTHLY + '","edition":{"id":1,"name":"Standard"},"contract":' +
            '{"id":"a8f0S0000008cxHQAQ","extId":"nib","billingId":1239' +
            '},"offerType":"Regular","globalPackageLimits":[{"value":"50000","code":"MONTHLY_AMOUNT_LIMIT","name":' +
            '"Monthly money amount limit","type":"Amount","scope":"BillingCycle","transactionType":' +
            '"Any","target":"Global","exclusions":[{"target":"LicenseCategoryId","targetId":"AP"}],' +
            '"override":false}],"permissions":null,"discountTemplates":[{"id":123,"values":{}}]}]';

    public static String FUNNEL_API_RESPONSE = '{"result":{"devices":{"LC_HD_139":{"USA":{"ruleType":1,"endOfSalesDate":"11\\/20\\/2021"}},"LC_HD_140":{"USA":{"ruleType":3,"endOfSalesDate":"11\\/20\\/2021"}}},"countries":{"USA":{"name":"United States","hasStates":true,"shippingLicenseIds":["LC_SHIPT_80","LC_SHIPT_81","LC_SHIPT_84"]}}},"SAFAS_SID":"606adf5dda75c5fdad4da91d966dd1ec24a43d8d7e3953222fc741cf75cc46eb","id":null}';

    @testSetup
    private static void test_generateData() {
        new SObjectBuilder(NGBS_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                NGBS_Settings__c.BaseEndpoint__c => 'http://test.com',
                NGBS_Settings__c.AccountManagerPath__c => 'http://test.com/test_manager',
                NGBS_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                NGBS_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        new SObjectBuilder(POC_GOA__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                POC_GOA__c.Direct_Manager__c => '0-9999',
                POC_GOA__c.Sales_Rep__c => '0-0',
                POC_GOA__c.Segment_Leader__c => '0-0',
                POC_GOA__c.SVP_WWS__c => '0-0',
                POC_GOA__c.SVP_WWS_Directs__c => '0-0'
            })
            .create()
            .getRecord();

        new SObjectBuilder(CountryCodes__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CountryCodes__c.Name => 'USA',
                CountryCodes__c.CountryName__c => 'usa;united states',
                CountryCodes__c.CountryNameFull__c => 'United States'
        })
        .create()
        .getRecord();

        new SObjectBuilder(GW_Settings__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                GW_Settings__c.BaseEndpoint__c => 'https://testfsgapi',
                GW_Settings__c.Source__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.Password__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.Login__c => ValueProviderBuilder.provideUniqueString(),
                GW_Settings__c.SignUpPath__c => '/wsx/signup/v1.0/',
                GW_Settings__c.SFAPath__c => '/api/projects/ws/saf_auxiliary_services/'
            })
            .create()
            .getRecord();

        Profile testProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object> { ProfileHelper.PROFILE_NAME_RELAYWARE })
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        new SObjectBuilder(User.SObjectType, false)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.ProfileId, testProfile.Id)
            .setField(User.LastName, 'Test_QuoteValidator_LastName')
            .setField(User.IsActive, true)
            .setField(User.CommunityNickname, 'TestCommunityName')
            .create();
        Triggers.switchOn();
    }

    @isTest
    static void testPrimaryQuoteNotApprovedValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Approved_Status__c => 'Pending L1 Approval'
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();

        Validator closePrimaryQuoteNotApprovedValidator =
                new QuoteValidator.PrimaryQuoteNotApprovedValidator(qt, reselectedOpty);
            Response respOnClose = closePrimaryQuoteNotApprovedValidator.validate(new Response());

            Validator signUp_PrimaryQuoteNotApprovedValidator =
                new QuoteValidator.SignUp_PrimaryQuoteNotApprovedValidator(qt);
            Response respOnSignUp = signUp_PrimaryQuoteNotApprovedValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respOnClose.messages.size());
        System.assert(respOnClose.messages[0].message.contains(
            Label.QW_Notification_Primary_quote_is_not_approved_text),
            'Primary quote should not be approved'
        );

        System.assertNotEquals(0, respOnSignUp.messages.size());
        System.assert(respOnSignUp.messages[0].messageDetails.contains(
            Label.QW_Notification_Primary_quote_is_not_approved_help_text),
            'Primary quote should not be approved'
        );
    }

    @isTest
    static void testNoQuoteLineItemsValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator closeNoQuoteLineItemsValidator =
                new QuoteValidator.NoQuoteLineItemsValidator(qt, opp);
            Response respOnClose = closeNoQuoteLineItemsValidator.validate(new Response());

            Validator signUpNoQuoteLineItemsValidator =
                new QuoteValidator.SignUp_NoQuoteLineItemsValidator(qt);
            Response respOnSignUp = signUpNoQuoteLineItemsValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respOnClose.messages.size());
        System.assert(respOnClose.messages[0].message.contains(Label.Empty_Cart_text), 'Empty cart error is expected');

        System.assertNotEquals(0, respOnSignUp.messages.size());
        System.assert(
            respOnSignUp.messages[0].messageDetails.contains(Label.QW_Notification_Empty_Cart_help_text),
             'Empty cart error is expected'
        );
    }

    @isTest
    static void testQuoteIsInvalidValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Quote_is_Invalid__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator quoteIsInvalidValidator =
                new QuoteValidator.QuoteIsInvalidValidator(qt);
            Response resp = quoteIsInvalidValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Quote_is_invalid_help_text),
            'Quote should be invalid'
        );
    }

    @isTest
    static void testAreaCodeLineItemValidator() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Area_Codes_Check_On_Opportunity_Close__c => true
            })
            .create()
            .getRecord();

		Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
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
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();
		Triggers.switchOn();
        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];

        Test.startTest();
            Validator areaCodeLineItemValidator =
                new QuoteValidator.AreaCodeLineItemValidator(primaryQuote, new List<Area_Code_Line_Item__c>());
            Response resp = areaCodeLineItemValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Area_codes_are_missing_help_text),
            'Missing area codes error message is expected'
        );
    }


    @isTest
    static void testChangeOrderPhaseValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'ProServ Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecord();

        List<Phase__c> phases = (List<Phase__c>) new SObjectBuilder(Phase__c.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Phase-1',
                    'Phase-2'
                }),
                Phase__c.RecordTypeId => PhaseHelper.RT_ID_PROSERV_PHASE,
                Phase__c.Estimated_Completion_Date__c => System.today().addDays(60),
                Phase__c.Quote__c => qt.Id,
                Phase__c.Initial_Payment__c => 200.0,
                Phase__c.CurrencyIsoCode => 'USD',
                Phase__c.Status__c => 'New'
            })
            .create()
            .getRecords();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();

        List<Phase__c> reselectedPhases = new PhaseSelector()
            .selectPhasesForClose(new List<Object>{new List<Quote>{qt}})
            .executeQuery();

        Test.startTest();
            Validator changeOrderEmptyPhasesValidator =
                new QuoteValidator.ChangeOrderEmptyPhasesValidator(reselectedQuotes, opp, reselectedPhases);
            Response resp = changeOrderEmptyPhasesValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Empty_phases_help_text),
            'There should no be phaselineItems under phases'
        );
    }

    @isTest
    static void testChangeOrderQliAssignementValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
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
                Quote.Name => 'ProServ Quote',
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        List<Phase__c> phases = (List<Phase__c>) new SObjectBuilder(Phase__c.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Phase-1',
                    'Phase-2'
                }),
                Phase__c.RecordTypeId => PhaseHelper.RT_ID_PROSERV_PHASE,
                Phase__c.Estimated_Completion_Date__c => System.today().addDays(60),
                Phase__c.Quote__c => qt.Id,
                Phase__c.Initial_Payment__c => 200.0,
                Phase__c.CurrencyIsoCode => 'USD',
                Phase__c.Status__c => 'New'
            })
            .create()
            .getRecords();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();

        List<Phase__c> reselectedPhases = new PhaseSelector()
            .selectPhasesForClose(new List<Object>{new List<Quote>{qt}})
            .executeQuery();
        Triggers.switchOn();

        Test.startTest();
            Quote proservQuote = reselectedQuotes[0];
            Validator changeOrderQliAssignementValidator =
                new QuoteValidator.ChangeOrderQliAssignementValidator(
                    reselectedQuotes, opp, reselectedPhases, proservQuote, null);
            Response resp = changeOrderQliAssignementValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Unassigned_PLI_help_text),
            'Unassigned phaseLineItem error should be fired'
        );
    }

    @isTest
    static void testExtendedEnterpriseSupportProductValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
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
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => Product2Helper.FEATURE_EXTENDED_ENTERPRISE_SUPPORT
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];
        Triggers.switchOn();

        Test.startTest();
            Validator extendedEnterpriseSupportProductValidator =
                new QuoteValidator.ExtendedEnterpriseSupportProductValidator(primaryQuote);
            Response resp = extendedEnterpriseSupportProductValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_PS_architect_empty_field_help_text),
            'Empty architect field validation expected'
        );
    }

    @isTest
    static void testEmptyProvisionNotesValidator() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.ProvisioningDetailsField__c => true
            })
            .create()
            .getRecord();
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();
        Triggers.switchOn();

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
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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
                Entitlement__c.Quantity__c => 300,
                Entitlement__c.Price__c => 200
            })
            .create()
            .getRecord();

        /* Qunatity is set to negative value cause it should be less then on entitltment*/
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => -3,
                QuoteLineItem.NewQuantity__c => -3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.Entitlement__c => ent.Id
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];

        Test.startTest();
            Validator emptyProvisionNotesValidator = new QuoteValidator.EmptyProvisionNotesValidator(primaryQuote, opp);
            Response resp = emptyProvisionNotesValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Provisioning_details_on_downsell_help_text),
            'Provisioned notes error is expected'
        );
    }

    @isTest
    static void testActiveAgreementValidator() {
        Triggers.switchOff();
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.OpptyActiveSalesAgreementValidation__c => true
            })
            .create()
            .getRecord();

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
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Initial_Term_months__c => '12',
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

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);
        Triggers.switchOn();

        Test.startTest();
            Validator activeAgreementValidator =
                new QuoteValidator.ActiveAgreementValidator(primaryQuote, reselectedOpty);
            Response resp = activeAgreementValidator.validate(new Response());
        Test.stopTest();

        System.assert(
            resp.messages[0].messageDetails.contains(Label.Opportunity_Error_OnClose_Active_agreement_is_needed_help_text),
            'Active agreement should be required'
        );
    }

    @isTest
    static void testProservSyncRequiredValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Sales quote',
                    'Proserv quote'
                }),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_SALES,
                    QuoteHelper.RT_ID_PROSERV
                }),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> {
                    true,
                    false
                }),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.PROSERVSTATUS_CREATED,
                    QuoteHelper.PROSERVSTATUS_CREATED
                })
            })
            .create()
            .getRecords();

        Test.startTest();
            Validator proservSyncRequiredValidator =
                new QuoteValidator.ProservSyncRequiredValidator(quotes[0], quotes[1]);
            Response resp = proservSyncRequiredValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].message.contains(
            Label.Primary_quote_not_synced_with_ProServ),
            'Expected error with not synched proserv quote'
        );
    }

    @isTest
    static void testProservSoldRequiredValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Sales quote',
                    'Proserv quote'
                }),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_SALES,
                    QuoteHelper.RT_ID_PROSERV
                }),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> {
                    true,
                    false
                }),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.PROSERVSTATUS_CREATED,
                    QuoteHelper.PROSERVSTATUS_SYNCED
                })
            })
            .create()
            .getRecords();

        Test.startTest();
            Validator proservSoldRequiredValidator =
                new QuoteValidator.ProservSoldRequiredValidator(quotes[0], quotes[1]);
            Response resp = proservSoldRequiredValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_ProServ_Quote_is_not_marked_as_Sold_help_text),
            'Expected error with not sold proserv quote'
        );
    }

    @isTest
    static void testActiveServicePlanValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Triggers.switchOff();
        Package__c testPackage = (Package__c) new SObjectBuilder(Package__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Package__c.Account__c => testAccount.Id,
                Package__c.Service_Type__c => 'Office',
                Package__c.Account_Package_Id__c => '11111111111',
                Package__c.RC_Tier__c => '1212311'
            })
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

        PriceBook2 pb = (PriceBook2) new SObjectBuilder(PriceBook2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Name => ValueProviderBuilder.provideUniqueString('test pricebook'),
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 2,
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY_CONTRACT,
                PriceBook2.BrandId__c => 1210,
                PriceBook2.Tier_ID__c => '12123112'
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE
            })
            .create()
            .getRecord();


        User testUser = createUser(ProfileHelper.PROFILE_NAME_SALES_MANAGER_BUSINESS_PROCESSING);

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];

        System.runAs(testUser) {
            Test.startTest();
                Validator activeServicePlanValidator =
                    new QuoteValidator.ActiveServicePlanValidator(
                        primaryQuote, new List<TierTypeSetting__c>(), 'prName', testPackage
                    );
                Response resp = activeServicePlanValidator.validate(new Response());
            Test.stopTest();
            System.assertNotEquals(0, resp.messages.size());
            System.assert(resp.messages[0].messageDetails.contains(
                Label.Opportunity_Error_OnClose_Inactive_service_plan_help_text),
                'Error with inactive service plan is expected'
            );
        }
    }

    @isTest
    static void testActiveAgreementForContactCenterValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
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
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY_CONTRACT,
                PriceBook2.BrandId__c => 1210,
                PriceBook2.Tier_ID__c => '12123112'
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Sales quote',
                    'CC quote'
                }),
                Quote.OpportunityId => opp.Id,
                Quote.Pricebook2Id => pb.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_SALES,
                    QuoteHelper.RT_ID_CC
                }),
                Quote.Initial_Term_months__c => '12',
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> {
                    true,
                    false
                })
            })
            .create()
            .getRecords();

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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => quotes[1].Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 4,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
            List<Quote> reselectedQuotes = new QuoteSelector()
                .selectQuotesForClose(opp.Id)
                .executeQuery();
            Quote primaryQuote = reselectedQuotes[0];

            Validator activeAgreementForContactCenterValidator =
                new QuoteValidator.ActiveAgreementForContactCenterValidator(primaryQuote,opp, reselectedQuotes);
            Response resp = activeAgreementForContactCenterValidator.validate(new Response());

            System.assertNotEquals(0, resp.messages.size());
            System.assert(resp.messages[0].messageDetails.contains(
                Label.Opportunity_Error_OnClose_Active_agreement_status_help_text),
                'Contact center require active sales agreement'
            );
        Test.stopTest();
    }

    @isTest
    static void testCCProservSyncRequiredValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Sales quote',
                    'CC Proserv quote'
                }),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_SALES,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> {
                    true,
                    false
                }),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.PROSERVSTATUS_CREATED,
                    QuoteHelper.PROSERVSTATUS_CREATED
                })
            })
            .create()
            .getRecords();

        Test.startTest();
            Validator CccProservSyncRequiredValidator =
                new QuoteValidator.CCProservSyncRequiredValidator(quotes[0], quotes[1]);
            Response resp = CccProservSyncRequiredValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        String expectedErrorMessage = String.format(
            Label.QW_Notification_Primary_quote_not_synced_with_CCProServ, new String[] {'CC Proserv'}
        );
        System.assert(
            resp.messages[0].message.contains(expectedErrorMessage),
            'Expected error with not synched cc proserv quote'
        );
    }

    @isTest
    static void testCCProservSoldRequiredValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideList(new List<String> {
                    'Sales quote',
                    'CC Proserv quote'
                }),
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    QuoteHelper.RT_ID_SALES,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> {
                    true,
                    false
                }),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String> {
                    QuoteHelper.PROSERVSTATUS_CREATED,
                    QuoteHelper.PROSERVSTATUS_SYNCED
                })
            })
            .create()
            .getRecords();

        Test.startTest();
            Validator ccProservSoldRequiredValidator =
                new QuoteValidator.CCProservSoldRequiredValidator(quotes[0], quotes[1]);
            Response resp = ccProservSoldRequiredValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Proserv_quotes_not_marked_as_sold_help_text),
            'Expected error with not sold cc proserv quote'
        );
    }

    @isTest
    static void testRentalPhoneValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
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
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();
        /* Rental phone */
        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Family => Product2Helper.FAMILY_RENTAL_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];
        Triggers.switchOn();

        Test.startTest();
            Validator rentalPhoneValidator =
                new QuoteValidator.RentalPhoneValidator(primaryQuote);
            Response resp = rentalPhoneValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Rental_phones_long_term_contract_active_agreement_text),
            'Rental phone validation is expected'
        );
    }

    @isTest
    static void testPhonesAndDlsValidator() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.AutogenerateOrders__c => true
            })
            .create()
            .getRecord();

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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.InvalidDiscountedPhonesQuantity__c => true
            })
            .create()
            .getRecord();

        Opportunity reselectedOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunityForClose(new Set<Id>{opp.Id})
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator phonesAndDlsValidator =
                new QuoteValidator.PhonesAndDlsValidator(qt, reselectedOpty);
            Response resp = phonesAndDlsValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Different_number_of_phones_and_DLs_help_text),
            'Error related with wrong discount phones quantity is expected'
        );
    }

    @isTest
    static void testQuoteErrorsValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.IsQuoteHasErrors__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator closeQuoteErrorsValidator =
                new QuoteValidator.QuoteErrorsValidator(qt);
            Response respOnClose = closeQuoteErrorsValidator.validate(new Response());

            Validator signUpQuoteErrorsValidator =
                new QuoteValidator.SignUp_QuoteHasErrorsValidator(Validator.SEVERITY_CRITICAL,qt);
            Response respOnSignUp = signUpQuoteErrorsValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respOnClose.messages.size());
        System.assert(respOnClose.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Primary_quote_has_errors_help_text),
            'Validation related with errors on quote is expected'
        );

        System.assertNotEquals(0, respOnSignUp.messages.size());
        System.assert(respOnSignUp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Primary_quote_has_errors_text),
            'Validation related with errors on quote is expected'
        );
    }

    @isTest
    static void testQuoteHasPaymentMethodValidator() {
        Quote qtWithoutPaymentMethod = new Quote(PaymentMethod__c = null);
        Quote qtWithPaymentMethod = new Quote(PaymentMethod__c = 'any payment method');

        Validator quoteHasPaymentMethodValidatorFails =
            new QuoteValidator.SignUp_QuoteHasPaymentMethodValidator(qtWithoutPaymentMethod);
        Response respOnFail = quoteHasPaymentMethodValidatorFails.validate(new Response());

        Validator quoteHasPaymentMethodValidatorSuccess =
            new QuoteValidator.SignUp_QuoteHasPaymentMethodValidator(qtWithPaymentMethod);
        Response respOnSuccess = quoteHasPaymentMethodValidatorSuccess.validate(new Response());

        System.assertNotEquals(0, respOnFail.messages.size());
        System.assert(respOnFail.messages[0].messageDetails.contains(
            Label.EmptyPaymentMethod),
            'Validation fails when Payment Method field on Quote is empty'
        );

        System.assertEquals(0, respOnSuccess.messages.size());
    }

    @isTest
    static void testProservSyncAndSoldValidatorNotSold() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
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
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                PriceBook2.AllowedRecordType__c => Pricebook2Helper.ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'ProServ Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_SYNCED,
                Quote.Pricebook2Id => pb.Id
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote proservQuote = reselectedQuotes[0];

        Test.startTest();
            Validator proservSyncAndSoldValidator =
                new QuoteValidator.ProservSyncAndSoldValidator(proservQuote);
            Response resp = proservSyncAndSoldValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_ProServ_Quote_is_not_marked_as_Sold_help_text),
            'Sold error is expected'
        );
    }

    @isTest
    static void testProservSyncAndSoldValidatorNotSynched() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
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
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                PriceBook2.AllowedRecordType__c => Pricebook2Helper.ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'ProServ Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CREATED,
                Quote.Pricebook2Id => pb.Id
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote proservQuote = reselectedQuotes[0];

        Test.startTest();
            Validator closeProservSyncAndSoldValidator =
                new QuoteValidator.ProservSyncAndSoldValidator(proservQuote);
            Response respOnClose = closeProservSyncAndSoldValidator.validate(new Response());

            Validator signUp_ProservSyncAndSoldValidator =
                new QuoteValidator.SignUp_ProservSyncAndSoldValidator(proservQuote);
            Response respOnSignUp = signUp_ProservSyncAndSoldValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respOnClose.messages.size());
        System.assert(respOnClose.messages[0].message.contains(
            Label.Primary_quote_not_synced_with_ProServ),
            'Sync error is expected'
        );

        System.assertNotEquals(0, respOnSignUp.messages.size());
        System.assert(respOnSignUp.messages[0].messageDetails.contains(
            Label.Primary_quote_not_synced_with_ProServ),
            'Sync error is expected'
        );
    }

    @isTest
    static void testProductReachedSalesEndDateValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
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

        Triggers.switchOff();
        List<Quote> qts = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Package_Info__c => ValueProviderBuilder.provideList(
                    new List<String> {
                        '[{"productId":"' + Product2Helper.SUBCATEGORY_RINGCENTRAL + '"}]',
                        '[{"productId":"' + Product2Helper.PRODUCT_ID_CONTACT_CENTER + '"}]'
                    }),
                Quote.isPrimary__c => ValueProviderBuilder.provideList(new List<Boolean> { true, false })
            })
            .quantity(2)
            .create()
            .getRecords();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .create()
            .getRecord();

        List<Entitlement__c> ents = new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => opp.AccountId,
                Entitlement__c.Quote__c => ValueProviderBuilder.provideList(new List<Id> { qts[0].Id, qts[1].Id }),
                Entitlement__c.Product__c => product.Id,
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.Price__c => 50,
                Entitlement__c.Active__c => true
            })
            .quantity(2)
            .create()
            .getRecords();

        new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create();
        Triggers.switchOn();

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
        /* Sales end date should be in the past */
        new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => ValueProviderBuilder.provideList(new List<Id> { qts[0].Id, qts[1].Id }),
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.Entitlement__c => ValueProviderBuilder.provideList(new List<Id> { ents[0].Id, ents[1].Id }),
                QuoteLineItem.SalesEndDate__c => System.now().addDays(-1)
            })
            .quantity(2)
            .create();

        Test.startTest();
        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];
        Quote ccQuote = reselectedQuotes[1];

            Validator productReachedSalesEndDateValidator =
                new QuoteValidator.ProductReachedSalesEndDateValidator(primaryQuote);
            Response resp = productReachedSalesEndDateValidator.validate(new Response());

            Validator productReachedSalesEndDateValidatorForCC =
                new QuoteValidator.ProductReachedSalesEndDateValidator(ccQuote);
            Response respCC = productReachedSalesEndDateValidatorForCC.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_Some_Products_Reached_SalesEndDate_help_text),
            'Sales end date should be reached'
        );

        System.assertEquals(0, respCC.messages.size(), 'Reached sales end date validation should be passed for Contact Center quote');
    }

    @isTest
    static void testCCQuoteRequiresCCProservValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator ccQuoteRequiresCCProservValidator =
                new QuoteValidator.CCQuoteRequiresCCProservValidator(qt, null);
            Response resp = ccQuoteRequiresCCProservValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_No_CC_close_without_engaging_CC_ProServ_help_text),
            'CC quote should require CC proserv quote'
        );
    }

    @isTest
    static void testCCProservQuoteValidatorNotSynched() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
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
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                PriceBook2.AllowedRecordType__c => Pricebook2Helper.ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'ProServ Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CREATED,
                Quote.Pricebook2Id => pb.Id
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote ccProservQuote = reselectedQuotes[0];

        Test.startTest();
            Validator ccProservQuoteValidator =
                new QuoteValidator.CCProservQuoteValidator(ccProservQuote);
            Response resp = ccProservQuoteValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        String expectedErrorMessage = String.format(
            Label.QW_Notification_Primary_quote_not_synced_with_CCProServ, new String[] {'CC Proserv'}
        );
        System.assert(resp.messages[0].message.contains(expectedErrorMessage), 'Sync error is expected');
    }

    @isTest
    static void testCCProservQuoteValidatorNotSold() {
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => false,
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
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_ANNUAL,
                PriceBook2.AllowedRecordType__c => Pricebook2Helper.ALLOWED_RECORD_TYPE_SERVICE_BILLING_PROSERV
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => 'ProServ Quote',
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_CC_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_OUT_FOR_SIGNATURE,
                Quote.Pricebook2Id => pb.Id
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote ccProservQuote = reselectedQuotes[0];

        Test.startTest();
            Validator ccProservQuoteValidator =
                new QuoteValidator.CCProservQuoteValidator(ccProservQuote);
            Response resp = ccProservQuoteValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        String expectedErrorText = String.format(
            Label.Opportunity_Error_OnClose_CC_ProServ_is_not_marked_as_sold_help_text,
                new String[] {'CC Proserv'}
            );
        System.assert(resp.messages[0].messageDetails.contains(expectedErrorText), 'Sold error is expected');
    }

    @isTest
    static void testRentalNGBSInCartValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
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
                PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Initial_Term_months__c => '12'
            })
            .create()
            .getRecord();
        /* Rental phone */
        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Family => Product2Helper.FAMILY_RENTAL_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];
        Triggers.switchOn();

        Test.startTest();
            Validator closeRentalNGBSInCartValidator =
                new QuoteValidator.RentalNGBSInCartValidator(primaryQuote);
            Response respOnClose = closeRentalNGBSInCartValidator.validate(new Response());

            Validator signUpRentalNGBSInCartValidator =
                new QuoteValidator.RentalNGBSInCartValidator(primaryQuote);
            Response respOnSignUp = signUpRentalNGBSInCartValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respOnClose.messages.size());
        System.assert(respOnClose.messages[0].messageDetails.contains(
            Label.QW_Notification_Rental_phones_long_term_contract_quote_text),
            'Billing rental phone validation is expected'
        );

        System.assertNotEquals(0, respOnSignUp.messages.size());
        System.assert(respOnSignUp.messages[0].messageDetails.contains(
            Label.QW_Notification_Rental_phones_long_term_contract_quote_text),
            'Billing rental phone validation is expected'
        );
    }

    @isTest
    static void testCostCenterAssignementValidator () {
        new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Cost_Center_Close_Validation__c => true
            })
            .create();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        Quote qt = NGBSTestDataGenerator.createQuote(opp.Id);

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('TestProduct'),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Family => ValueProviderBuilder.provideList(
                    new List<String>{
                        Product2Helper.FAMILY_SERVICE,
                        Product2Helper.FAMILY_TECHNICAL_LICENSE,
                        Product2Helper.FAMILY_PHONE,
                        Product2Helper.FAMILY_TAXES,
                        Product2Helper.FAMILY_FEE
                    }
                ),
                Product2.Feature__c => ValueProviderBuilder.provideList(
                    new List<Decimal>{
                        Product2Helper.FEATURE_SERVICE_PLAN,
                        Product2Helper.FEATURE_SERVICE_PLAN,
                        34,
                        11,
                        null,
                        null
                    }
                )
            })
            .quantity(5)
            .create()
            .getRecords();

        List<PricebookEntry> standardPricebookEntry = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .quantity(5)
            .create()
            .getRecords();

        Triggers.switchOn();
        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(products),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(standardPricebookEntry),
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{}', '{}', '{}', '{}', '{"categoryCode":"E911"}'
                    }
                ),
                QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{}', '{}', '{}', '{}', '{"categoryCode":"E911"}'
                    }
                )
            })
            .quantity(5)
            .create()
            .getRecords();

        QuoteLineItem serviceQli = qliList.get(0);
        QuoteLineItem digitalLineQli = qliList.get(1);
        QuoteLineItem phoneQli = qliList.get(2);

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Quote__c => qt.Id,
                Cost_Center__c.Name => 'testCC'
            })
            .create()
            .getRecord();

        Id rootQliId = serviceQli.Id;

        Set<Id> bundleChilds = new Set<Id>{
            digitalLineQli.Id,
            phoneQli.Id
        };
        Map<Id, Cost_Center_Line_Item__c> bundle = NGBSTestDataGenerator.buildBundle(costCenter.Id, rootQliId, bundleChilds, 15);

        Id rootCcliId = bundle.get(rootQliId).Id;

        Test.startTest();
        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery()
            .get(0);

            Set<Id> qliIds = new Set<Id>(
                new Map<Id, QuoteLineItem>(reselectedQuote.QuoteLineItems).keySet()
            );

            Map<Id, Cost_Center_Line_Item__c> ccliMap = new Map<Id, Cost_Center_Line_Item__c>(
                (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                    .selectCostCentersLineItemsForCloseValidation(qliIds)
                    .executeQuery()
            );

            Cost_Center_Line_Item__c rootCcli = ccliMap.get(rootCcliId);

            Validator costCenterAssignementValidator =
                new QuoteValidator.CostCenterAssignementValidator(reselectedQuote, ccliMap);

            Response resp = costCenterAssignementValidator.validate(new Response());

            System.assertNotEquals(0, resp.messages.size());
            System.assert(resp.messages[0].messageDetails.contains(
                Label.Oppty_Line_items_not_assigned_help_text),
                'Quote line items are not assigned to cost centers'
            );

            // set quantity equal to quantity of quoteLineitem
            rootCcli.Quantity__c = 3;
            ccliMap.put(rootCcli.Id, rootCcli);

            costCenterAssignementValidator =
                new QuoteValidator.CostCenterAssignementValidator(reselectedQuote, ccliMap);

            Response resp2 = costCenterAssignementValidator.validate(new Response());
            System.assertEquals(0, resp2.messages.size());
            System.assert(resp2.messages.isEmpty(), 'in this case there should be no errors');
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Oppty_Line_items_not_assigned_help_text),
            'Quote line items are not assigned to cost centers'
        );
    }

    @isTest
    static void testQuantityShippingValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
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

        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lboxes":[{"elementID":"LB_698","min":0,"max":99999}],"categoryPath":"HD"}';

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => ValueProviderBuilder.provideList(new List<String>{QuoteHelper.STATUS_UPSELL, QuoteHelper.STATUS_NEW_CUSTOMER})
            })
            .quantity(2)
            .create()
            .getRecords();

        List<Product2> product = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Test_Product', 'Test_Product1'}),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.ShippingType__c => Product2Helper.SHIPPING_TYPE_AUTO
            })
            .quantity(2)
            .create()
            .getRecords();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product[0].Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product[0].Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();
        /* Sales end date should be in the past */
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => quotes[0].Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {product[0].Id, product[1].Id}),
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.PackageInfo__c => packageInfoQLI,
                QuoteLineItem.Package_Info_QLI__c => packageInfoQLI,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.SalesEndDate__c => System.now().addDays(-1)
            })
            .quantity(2)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '10 Avenue Jean Médecin',
                CustomAddress__c.City__c => 'Nice',
                CustomAddress__c.Country__c => 'France',
                CustomAddress__c.State__c => 'Nice',
                CustomAddress__c.PostalCode__c => '06000'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c caa = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => 'Test France',
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.Quantity__c => 2,
                CustomAddressAssignments__c.QuoteLineItem__c => qlis[0].Id,
                CustomAddressAssignments__c.Type__c => 'Ground'})
            .create()
            .getRecord();

        List<Quote> reselectedQuote = (List<Quote>) new QuoteSelector().selectQuotes()
                .selectFields(new QuoteSelector().getFieldsForSyncWithNGBS())
                .executeQuery();
        Triggers.switchOn();

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        Validator shippingQuantityValidator =
            new QuoteValidator.QuantityShippingValidator(reselectedQuote[0], new List<QuoteLineItem>(), false, false);
        Response respInvalid = shippingQuantityValidator.validate(new Response());

        shippingQuantityValidator =
            new QuoteValidator.QuantityShippingValidator(reselectedQuote[0], new List<QuoteLineItem>(), false, true);
        Response respInvalidWithProServ = shippingQuantityValidator.validate(new Response());

        shippingQuantityValidator = new QuoteValidator.QuantityShippingValidator(reselectedQuote[1], new List<QuoteLineItem>(), false, false);
        Response respValidWithNGBScall = shippingQuantityValidator.validate(new Response());

        shippingQuantityValidator = new QuoteValidator.QuantityShippingValidator(reselectedQuote[1], new List<QuoteLineItem>(), true, false);
        Response respValidWTNGBScall = shippingQuantityValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respInvalid.messages.size(), 'Response must have messages');
        System.assert(respInvalid.messages[0].message.contains(
            Label.Opportunity_Error_OnClose_Unassigned_Shipping_Devices_text),
            'Primary quote should not be closed'
        );

        System.assertEquals(0, respInvalidWithProServ.messages.size(), 'Validation should be passed');
        System.assertEquals(0, respValidWithNGBScall.messages.size(), 'Validation should be passed');
        System.assertEquals(0, respValidWTNGBScall.messages.size(), 'Validation should be passed');
    }

    @isTest
    static void testShippingCostCenterValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS
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

        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lboxes":[{"elementID":"LB_698","min":0,"max":99999}],"categoryPath":"HD"}';

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        List<Product2> product = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Test_Product', 'Test_Product1'}),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
            })
            .quantity(2)
            .create()
            .getRecords();

        PricebookEntry standardPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => product[0].Id,
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        PricebookEntry currentPricebookEntry = (PricebookEntry) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pb.Id,
                PricebookEntry.Product2Id => product[0].Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();
        /* Sales end date should be in the past */
        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<String> {product[0].Id, product[1].Id}),
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.PackageInfo__c => packageInfoQLI,
                QuoteLineItem.Package_Info_QLI__c => packageInfoQLI,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.SalesEndDate__c => System.now().addDays(-1)
            })
            .quantity(2)
            .create()
            .getRecords();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Name => 'test cost center',
                Cost_Center__c.Quote__c => qt.Id,
                Cost_Center__c.BillingId__c => 'test billing id'
            })
            .create()
            .getRecord();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '10 Avenue Jean Médecin',
                CustomAddress__c.City__c => 'Nice',
                CustomAddress__c.Country__c => 'France',
                CustomAddress__c.State__c => 'Nice',
                CustomAddress__c.PostalCode__c => '06000'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c caa = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => 'Test France',
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.Quantity__c => 2,
                CustomAddressAssignments__c.QuoteLineItem__c => qlis[1].Id,
                CustomAddressAssignments__c.ShippingBillingCodeId__c => 'test',
                CustomAddressAssignments__c.Type__c => 'Ground'})
            .create()
            .getRecord();

        Cost_Center_Line_Item__c costCenterLineItem = (Cost_Center_Line_Item__c) new SObjectBuilder(Cost_Center_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center_Line_Item__c.Name => 'test cost center',
                Cost_Center_Line_Item__c.Cost_Center__c => costCenter.Id,
                Cost_Center_Line_Item__c.Quote_Line_Item__c => qlis[1].Id,
                Cost_Center_Line_Item__c.Quantity__c => 1
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.startTest();
        Validator shippingCostCenterValidator =
            new QuoteValidator.ShippingCostCenterValidator(qt, new List<QuoteLineItem>(), new List<Cost_Center__c>(), false);
        Response resp = shippingCostCenterValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].message.contains(
            Label.Opportunity_Error_OnClose_Unassigned_ShippingGroups_to_CostCenters_text),
            'Primary quote should not be closed'
        );
    }

    @isTest
    static void testBuildQliIdToQliQuanityMap() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote qt = NGBSTestDataGenerator.createQuote(opp.Id);

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('TestProduct'),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Family => ValueProviderBuilder.provideList(
                    new List<String>{
                        Product2Helper.FAMILY_SERVICE,
                        Product2Helper.FAMILY_TECHNICAL_LICENSE,
                        Product2Helper.FAMILY_RENTAL_PHONES,
                        Product2Helper.FAMILY_PHONE,
                        Product2Helper.FAMILY_TAXES,
                        Product2Helper.FAMILY_FEE
                    }
                ),
                Product2.Feature__c => ValueProviderBuilder.provideList(
                    new List<Decimal>{
                        Product2Helper.FEATURE_SERVICE_PLAN,
                        Product2Helper.FEATURE_SERVICE_PLAN,
                        34,
                        11,
                        null,
                        null
                    }
                )
            })
            .quantity(6)
            .create()
            .getRecords();
        Triggers.switchOn();

        List<PricebookEntry> standardPricebookEntry = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .quantity(6)
            .create()
            .getRecords();

        // create Entitlements for Service product and for DigitalLine product
        List<Entitlement__c> entitlements = (List<Entitlement__c>) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => opp.AccountId,
                Entitlement__c.Quote__c => qt.Id,
                Entitlement__c.Product__c => ValueProviderBuilder.provideList(
                    new List<Id>{
                        products.get(0).Id,
                        products.get(1).Id
                    }
                ),
                Entitlement__c.Quantity__c => 10,
                Entitlement__c.Price__c => 50,
                Entitlement__c.Active__c => true
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(products),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(standardPricebookEntry),
                QuoteLineItem.Entitlement__c => ValueProviderBuilder.provideList(
                    new List<Id>{
                        entitlements.get(0).Id,
                        entitlements.get(1).Id,
                        null,
                        null,
                        null,
                        null
                    }
                ),
                QuoteLineItem.Quantity => ValueProviderBuilder.provideList(
                    new List<Decimal>{ -3, -3, 3, 3, 3, 3 }
                ),
                QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{}', '{}', '{}', '{}', '{}', '{"categoryCode":"E911"}'
                    }
                ),
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{}', '{}', '{}', '{}', '{}', '{"categoryCode":"E911"}'
                    }
                )
            })
            .quantity(6)
            .create()
            .getRecords();

        QuoteLineItem serviceQli = qliList.get(0);
        QuoteLineItem digitalLineQli = qliList.get(1);
        QuoteLineItem rentalPhoneQli = qliList.get(2);
        QuoteLineItem phoneQli = qliList.get(3);
        QuoteLineItem taxQli = qliList.get(4);
        QuoteLineItem feeQli = qliList.get(5);

        Test.startTest();

            Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuotesForClose(opp.Id)
                .executeQuery()
                .get(0);

            QuoteValidator.CostCenterAssignementValidator costCenterValidator = new QuoteValidator.CostCenterAssignementValidator(reselectedQuote, null);

            System.assertEquals(
                new Map<Id, Decimal>(),
                costCenterValidator.buildQliIdToQliQuanityMap(null, false, new List<String>()),
                'buildQliIdToQliQuanityMap mehtod should return empty map if parameter is null'
            );

            System.assertEquals(
                new Map<Id, Decimal>(),
                costCenterValidator.buildQliIdToQliQuanityMap(new List<QuoteLineItem>(), false, new List<String>()),
                'buildQliIdToQliQuanityMap mehtod should return empty map if parameter is empty list'
            );

            Map<Id, Decimal> qliIdToQuantityMap = costCenterValidator.buildQliIdToQliQuanityMap(reselectedQuote.QuoteLineItems, false, new List<String>());
            System.debug('qliIdToQuantityMap >>> ' + qliIdToQuantityMap);

            System.assert(
                !qliIdToQuantityMap.containsKey(serviceQli.Id),
                'product with family "Service" and Feature__c == 17 should not be contained in result map'
            );

            System.assert(
                !qliIdToQuantityMap.containsKey(digitalLineQli.Id),
                'product with family "Technical License" and Feature__c == 17 should not be contained in result map'
            );

            System.assert(
                !qliIdToQuantityMap.containsKey(taxQli.Id),
                'taxes products should be filtered'
            );

            System.assert(
                !qliIdToQuantityMap.containsKey(feeQli.Id),
                'fee products should be filtered'
            );

            System.assert(
                qliIdToQuantityMap.containsKey(rentalPhoneQli.Id),
                'product with family "Rental Phones" and Feature__c == 34 must be contained in result map'
            );

            System.assert(
                qliIdToQuantityMap.containsKey(phoneQli.Id),
                'product with family "Phones" and Feature__c == 11 must be contained in result map'
            );

        Test.stopTest();
    }

    @isTest
    static void testBuildQliIdToCcliQuanityMap() {

        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote qt = NGBSTestDataGenerator.createQuote(opp.Id);

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideUniqueString('TestProduct'),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Family => ValueProviderBuilder.provideList(
                    new List<String>{
                        Product2Helper.FAMILY_SERVICE,
                        Product2Helper.FAMILY_TECHNICAL_LICENSE,
                        Product2Helper.FAMILY_RENTAL_PHONES,
                        Product2Helper.FAMILY_PHONE,
                        Product2Helper.FAMILY_TAXES,
                        Product2Helper.FAMILY_FEE
                    }
                ),
                Product2.Feature__c => ValueProviderBuilder.provideList(
                    new List<Decimal>{
                        Product2Helper.FEATURE_SERVICE_PLAN,
                        Product2Helper.FEATURE_SERVICE_PLAN,
                        34,
                        11,
                        null,
                        null
                    }
                )
            })
            .quantity(6)
            .create()
            .getRecords();

        List<PricebookEntry> standardPricebookEntry = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(products),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .quantity(6)
            .create()
            .getRecords();

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideParents(products),
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideParents(standardPricebookEntry),
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{}', '{}', '{}', '{}', '{}', '{"categoryCode":"E911"}'
                    }
                ),
                QuoteLineItem.Package_Info_QLI__c => ValueProviderBuilder.provideList(
                    new List<String>{
                        '{}', '{}', '{}', '{}', '{}', '{"categoryCode":"E911"}'
                    }
                )
            })
            .quantity(6)
            .create()
            .getRecords();
        Triggers.switchOn();

        QuoteLineItem serviceQli = qliList.get(0);
        QuoteLineItem digitalLineQli = qliList.get(1);
        QuoteLineItem rentalPhoneQli = qliList.get(2);
        QuoteLineItem phoneQli = qliList.get(3);
        QuoteLineItem taxQli = qliList.get(4);
        QuoteLineItem feeQli = qliList.get(5);

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Cost_Center__c.Quote__c => qt.Id,
                Cost_Center__c.Name => 'testCC'
            })
            .create()
            .getRecord();

        Test.startTest();
        Set<Id> bundle1Childs = new Set<Id>{
            digitalLineQli.Id,
            phoneQli.Id
        };
        Map<Id, Cost_Center_Line_Item__c> bundle1 = NGBSTestDataGenerator.buildBundle(costCenter.Id, serviceQli.Id, bundle1Childs, 15);

        Set<Id> bundle2Childs = new Set<Id>{
            digitalLineQli.Id,
            rentalPhoneQli.Id
        };
        Map<Id, Cost_Center_Line_Item__c> bundle2 = NGBSTestDataGenerator.buildBundle(costCenter.Id, serviceQli.Id, bundle2Childs, 15);

            Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuotesForClose(opp.Id)
                .executeQuery()
                .get(0);

            Set<Id> qliIds = new Set<Id>(
                new Map<Id, QuoteLineItem>(reselectedQuote.QuoteLineItems).keySet()
            );

            Map<Id, Cost_Center_Line_Item__c> ccliMap = new Map<Id, Cost_Center_Line_Item__c>(
                (List<Cost_Center_Line_Item__c>) new CostCenterLineItemSelector()
                    .selectCostCentersLineItemsForCloseValidation(qliIds)
                    .executeQuery()
            );

            QuoteValidator.CostCenterAssignementValidator costCenterValidator =
                new QuoteValidator.CostCenterAssignementValidator(reselectedQuote, ccliMap);

            System.assertEquals(
                new Map<Id, Decimal>(),
                costCenterValidator.buildQliIdToCcliQuanityMap(null),
                'buildQliIdToCcliQuanityMap mehtod should return empty map if parameter is null'
            );

            System.assertEquals(
                new Map<Id, Decimal>(),
                costCenterValidator.buildQliIdToCcliQuanityMap(new Map<Id, Cost_Center_Line_Item__c>()),
                'buildQliIdToCcliQuanityMap mehtod should return empty map if parameter is empty map'
            );

            Map<Id, Decimal> qliIdToCcliQuantityMap = costCenterValidator.buildQliIdToCcliQuanityMap(ccliMap);
            System.debug('qliIdToCcliQuantityMap >>> ' + qliIdToCcliQuantityMap);

            System.assert(
                !qliIdToCcliQuantityMap.containsKey(serviceQli.Id),
                'product with family "Service" and Feature__c == 17 should not be contained in result map'
            );

            System.assert(
                !qliIdToCcliQuantityMap.containsKey(digitalLineQli.Id),
                'product with family "Technical License" and Feature__c == 17 should not be contained in result map'
            );

            System.assert(
                !qliIdToCcliQuantityMap.containsKey(taxQli.Id),
                'taxes products should be filtered'
            );

            System.assert(
                !qliIdToCcliQuantityMap.containsKey(feeQli.Id),
                'fee products should be filtered'
            );

            System.assert(
                qliIdToCcliQuantityMap.containsKey(rentalPhoneQli.Id),
                'product with family "Rental Phones" and Feature__c == 34 must be contained in result map'
            );

            System.assert(
                qliIdToCcliQuantityMap.containsKey(phoneQli.Id),
                'product with family "Phones" and Feature__c == 11 must be contained in result map'
            );

        Test.stopTest();
    }

    @isTest
    static void testSignUp_DocusignNotCompletedValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Account__c => testAccount.Id,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Quote qtWithAcc = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(qt.Id)
            .executeQuery()
            .get(0);

        Test.startTest();
            Validator signUp_DocusignNotCompletedValidator =
                new QuoteValidator.SignUp_DocusignNotCompletedValidator(qtWithAcc);
            Response resp = signUp_DocusignNotCompletedValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Validation_SignUp_Envelop_NOT_Completed_help_text),
            'Completed Docusign Envelope is required'
        );
    }

    @isTest
    static void testSignUp_DocusignNotCompletedValidatorAvaya() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Account__c => testAccount.Id,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();
        System.assertEquals(QuoteHelper.RT_ID_POC, qt.RecordTypeId, ' Quote should be POC');

        Quote qtWithAcc = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(qt.Id)
            .executeQuery()
            .get(0);

        Test.startTest();
        Validator signUp_DocusignNotCompletedValidator =
            new QuoteValidator.SignUp_DocusignNotCompletedValidator(qtWithAcc);
        Response resp = signUp_DocusignNotCompletedValidator.validate(new Response());
        Test.stopTest();

        // Should allow POC Quotes without docusign even for AAA Partners
        System.assertEquals(0, resp.messages.size());
    }

    @isTest
    static void testSignUp_DocusignNotCompletedValidatorAtos() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATOS
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Account__c => testAccount.Id,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();
        System.assertEquals(QuoteHelper.RT_ID_POC, qt.RecordTypeId, ' Quote should be POC');

        Quote qtWithAcc = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(qt.Id)
            .executeQuery()
            .get(0);

        Test.startTest();
        Validator signUp_DocusignNotCompletedValidator =
            new QuoteValidator.SignUp_DocusignNotCompletedValidator(qtWithAcc);
        Response resp = signUp_DocusignNotCompletedValidator.validate(new Response());
        Test.stopTest();

        // Should allow POC Quotes without docusign even for AAA Partners
        System.assertEquals(0, resp.messages.size());
    }

    @isTest
    static void testSignUp_DocusignNotCompletedValidatorRainbow() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RAINBOW
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Account__c => testAccount.Id,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();
        System.assertEquals(QuoteHelper.RT_ID_POC, qt.RecordTypeId, ' Quote should be POC');

        Quote qtWithAcc = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(qt.Id)
            .executeQuery()
            .get(0);

        Test.startTest();
        Validator signUp_DocusignNotCompletedValidator =
            new QuoteValidator.SignUp_DocusignNotCompletedValidator(qtWithAcc);
        Response resp = signUp_DocusignNotCompletedValidator.validate(new Response());
        Test.stopTest();

        // Should allow POC Quotes without docusign even for AAA Partners
        System.assertEquals(0, resp.messages.size());
    }

    @isTest
    static void testSignUp_DocusignNotCompletedValidatorInvoiceOnBehalf() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Partner_ID__c => 'any',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Account__c => testAccount.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Quote myQuote = (Quote) new QuoteSelector()
        .selectQuoteForSignUp(qt.Id)
        .executeQuery()
        .get(0);
        System.debug('myQuote: ' + myQuote);

        Test.startTest();
            Validator signUp_DocusignNotCompletedValidator =
                new QuoteValidator.SignUp_DocusignNotCompletedValidator(myQuote);
            Response resp = signUp_DocusignNotCompletedValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size(), 'Invoice on Behalf Accounts should not fail SignUp even without DocuSign completed process');
        if (resp.messages.size() > 0) {
            System.debug('Validation errors: ' + resp.messages);
        }
    }

    @isTest
    static void testSignUp_DocusignNotCompletedValidatorWholesale() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Partner_ID__c => '2005',
                Account.Partner_Type__c => AccountHelper.ACCOUNT_PARTNER_BILL_ON_BEHALF
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.Account__c => testAccount.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Quote myQuote = (Quote) new QuoteSelector()
        .selectQuoteForSignUp(qt.Id)
        .executeQuery()
        .get(0);

        Test.startTest();
            Validator signUp_DocusignNotCompletedValidator =
                new QuoteValidator.SignUp_DocusignNotCompletedValidator(myQuote);
            Response resp = signUp_DocusignNotCompletedValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size(), 'Wholesale Accounts should not fail SignUp even without DocuSign completed process');
        if (resp.messages.size() > 0) {
            System.debug('Validation errors: ' + resp.messages);
        }
    }

    @isTest
    static void testSignUp_NGBSOfficeSignUpValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_NGBSOfficeSignUpValidator =
                new QuoteValidator.SignUp_NGBSOfficeSignUpValidator(qt);
            Response resp = signUp_NGBSOfficeSignUpValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_SignUp_Validation_NGBS_is_not_allowed),
            'SignUp for billing quotes should be restricted'
        );
    }

    @isTest
    static void testSignUp_ContractPricingValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => '[{"duration":"' + Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT + '"}]',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Initial_Term_months__c => '11',
                Quote.Start_Date__c => System.today().addDays(-1),
                Quote.End_Date__c => System.today()
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_ContractPricingValidator =
                new QuoteValidator.SignUp_ContractPricingValidator(qt);
            Response resp = signUp_ContractPricingValidator.validate(new Response());

            System.assertNotEquals(0, resp.messages.size());
            System.assert(resp.messages[0].messageDetails.contains(
                Label.QW_Notification_Contract_pricing_requirement_help_text),
                'Contract pricing error is expected'
            );


            new SObjectBuilder(Feature_Toggle__c.SObjectType)
                .setField(Feature_Toggle__c.Enable_new_Contract_Term_flow__c, true)
                .create();

            resp = signUp_ContractPricingValidator.validate(new Response());
            System.assert(
                resp.messages.isEmpty(),
                'validation should passed if feature toggle Enable_new_Contract_Term_flow__c is true'
            );
        Test.stopTest();
    }

    @isTest
    static void verifySignUpContractPricingValidatorReturnSuccess() {

        Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
        featureToogleSetting.Enable_new_Contract_Term_flow__c = false;
        upsert featureToogleSetting;

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper();
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.duration = 'Monthly';
        qtPInfoWrapper.setPackageInfo(pInfo);

        Quote qt = new Quote(
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
            Initial_Term_months__c = '105',
            Package_Info__c = qtPInfoWrapper.toString()
        );

        Validator signUp_ContractPricingValidator =
                new QuoteValidator.SignUp_ContractPricingValidator(qt);
        Response resp = signUp_ContractPricingValidator.validate(new Response());

        System.assert(
            resp.messages.isEmpty(),
            'Validation should be passed if Initial_Term_months__c more than 12 Months'
        );
    }

    @isTest
    static void verifySignUpContractPricingValidatorReturnError() {

        Feature_Toggle__c featureToogleSetting = Feature_Toggle__c.getInstance();
        featureToogleSetting.Enable_new_Contract_Term_flow__c = false;
        upsert featureToogleSetting;

        BillingWrappers.QuotePackageInfoWrapper qtPInfoWrapper = new BillingWrappers.QuotePackageInfoWrapper();
        BillingWrappers.QuotePackageInfo pInfo = new BillingWrappers.QuotePackageInfo();
        pInfo.duration = 'Monthly';
        qtPInfoWrapper.setPackageInfo(pInfo);

        Quote qt = new Quote(
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Status = QuoteHelper.QUOTE_STATUS_ACTIVE,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_AGREEMENT,
            Initial_Term_months__c = '10',
            Package_Info__c = qtPInfoWrapper.toString()
        );

        Validator signUp_ContractPricingValidator =
                new QuoteValidator.SignUp_ContractPricingValidator(qt);
        Response resp = signUp_ContractPricingValidator.validate(new Response());

        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Contract_pricing_requirement_help_text),
            'Validation should be failed if Initial_Term_months__c less than 12 Months'
        );
    }

    @isTest
    static void testSignUp_SpecialTermsRequireActiveAgreementValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_1,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_SpecialTermsRequireActiveAgreementValidator =
                new QuoteValidator.SignUp_SpecialTermsRequireActiveAgreementValidator(qt);
            Response resp = signUp_SpecialTermsRequireActiveAgreementValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_activeAgreementSpecialTerms_text),
            'Special terms should require active agreement'
        );
    }

    @isTest
    static void testSignUp_SpecialTermsWithoutContractValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => '[{"duration":"' + Product2Helper.CHARGE_TERM_MONTHLY_CONTRACT + '"}]',
                Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_1,
                Quote.Start_Date__c => System.today().addDays(-1),
                Quote.End_Date__c => System.today()
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_SpecialTermsWithoutContractValidator =
                new QuoteValidator.SignUp_SpecialTermsWithoutContractValidator(qt);
            Response resp = signUp_SpecialTermsWithoutContractValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Special_Terms_are_selected_without_Contract_help_text),
            'Special terms should require contract'
        );
    }

    @isTest
    static void testSignUp_AreaCodeLineItemValidator() {
        Feature_Toggle__c ft = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.BillingWizardAreaCodes__c => true
            })
            .create()
            .getRecord();

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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_ACTIVE,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => '[{"productName":"Office"}]',
                Quote.Special_Terms__c => QuoteHelper.FREE_MONTH_1,
                Quote.Start_Date__c => System.today().addDays(-1),
                Quote.End_Date__c => System.today()
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_AreaCodeLineItemValidator =
                new QuoteValidator.SignUp_AreaCodeLineItemValidator(qt);
            Response resp = signUp_AreaCodeLineItemValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Area_Code_are_missing_help_text),
            'Area codes should be required'
        );
    }

    @isTest
    static void testSignUp_ProductReachedSalesEndDateValidator() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.sObjectType)
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
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'TestProduct',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.SalesEndDate__c => System.now().addDays(-1)
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuotesForClose(opp.Id)
            .executeQuery();
        Quote primaryQuote = reselectedQuotes[0];
        Triggers.switchOn();

        Test.startTest();
            Validator signUp_ProductReachedSalesEndDateValidator =
                new QuoteValidator.SignUp_ProductReachedSalesEndDateValidator(primaryQuote);
            Response resp = signUp_ProductReachedSalesEndDateValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_Some_Products_Reached_SalesEndDate_help_text),
            'Quote line items should miss end date'
        );
    }

    @isTest
    static void testSignUp_ContractAndActiveAgreementValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c =>
                    '[{"id":"18","contract":{"id":"a8f0S0000008cxHQAQ","extId":"Office","billingId":"2"}}]',
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT,
                Quote.Start_Date__c => System.today().addDays(-1),
                Quote.End_Date__c => System.today()
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_ContractAndActiveAgreementValidator =
                new QuoteValidator.SignUp_ContractAndActiveAgreementValidator(qt);
            Response resp = signUp_ContractAndActiveAgreementValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_SignUp_Active_Agreement_Fail),
            'Active agreement require contract'
        );
    }

    @isTest
    static void testSignUp_ActiveAgreementValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_AGREEMENT
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_ActiveAgreementValidator =
                new QuoteValidator.SignUp_ActiveAgreementValidator(qt, false);
            Response resp = signUp_ActiveAgreementValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_activeAgreement_text),
            'Agreement should be in Active status'
        );
    }

    @isTest
    static void testSignUp_MissApprovedPOCApprovalValidator() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Approval__c testApp = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Approval__c.Quote__c => qt.Id,
                    Approval__c.Opportunity__c => qt.OpportunityId,
                    Approval__c.Account__c => testAccount.Id,
                    Approval__c.RecordTypeId => ApprovalHelper.RT_ID_POC_ACCOUNT,
                    Approval__c.Status__c => ApprovalHelper.STATUS_NEW,
                    Approval__c.Number_of_POC_Users__c => 1
                }
            )
            .create()
            .getRecord();

        Test.startTest();
            Validator signUp_MissApprovedPOCApprovalValidator =
                new QuoteValidator.SignUp_MissApprovedPOCApprovalValidator(qt, new List<Approval__c>{testApp});
            Response resp = signUp_MissApprovedPOCApprovalValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Sign_Up_Approved_POC_Account_Approval_is_required),
            'POC quote should require approval'
        );
    }

    @isTest
    static void testSignUp_PendingTaxExemptionApprovalValidator() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Feature_Toggle__c.Enable_Account_Based_Tax_Exemption__c => true
            })
            .create();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => testAccount.Id,
                Contact.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                Contact.FirstName => ValueProviderBuilder.provideUniqueString('FirstName'),
                Contact.Email => ValueProviderBuilder.provideUniqueString('jg@rc.test')
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                    .setField(Approval__c.Name, 'Tax Exemption Approval')
                    .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
                    .setField(Approval__c.Account__c, testAccount.Id)
                    .setField(Approval__c.Contact__c, contact.Id)
                    .create()
                    .getRecord();

            app.Status__c = ApprovalHelper.STATUS_PENDING_APPROVAL;
            update app;

            Validator signUp_PendingTaxExemptionApprovalValidator =
                new QuoteValidator.SignUp_PendingTaxExemptionApprovalValidator(qt, new List<Approval__c>{app});
            Response resp = signUp_PendingTaxExemptionApprovalValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Tax_Exempt_Approval_is_in_progress_redirect),
            'Warning about pending Tax Exemption Approval should be shown'
        );
    }

    @isTest
    static void testSignUp_InProgressTaxExemptionApprovalValidator() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => testAccount.Id,
                Contact.LastName => ValueProviderBuilder.provideUniqueString('LastName'),
                Contact.FirstName => ValueProviderBuilder.provideUniqueString('FirstName'),
                Contact.Email => ValueProviderBuilder.provideUniqueString('jg@rc.test')
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_POC,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Approval__c app = (Approval__c) new SObjectBuilder(Approval__c.SObjectType)
                    .setField(Approval__c.Name, 'Tax Exemption Approval')
                    .setField(Approval__c.RecordTypeId, ApprovalHelper.RT_ID_TAX_EXEMPT_APPROVAL)
                    .setField(Approval__c.Account__c, testAccount.Id)
                    .setField(Approval__c.Contact__c, contact.Id)
                    .create()
                    .getRecord();

            app.Status__c = ApprovalHelper.STATUS_PENDING_APPROVAL;
            update app;
            Validator SignUp_InProgressTaxExemptionApprovalValidator =
                new QuoteValidator.SignUp_InProgressTaxExemptionApprovalValidator(qt, new List<Approval__c>{app});
            Response resp = signUp_InProgressTaxExemptionApprovalValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.QW_Notification_Tax_Exempt_Approval_is_in_progress_help_text),
            'Warning about inProgress Tax Exemption Approval should be shown'
        );
    }

    @IsTest
    static void testAreaCodesAssignementValidatorLBOEnabled() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.NGBSOfficeSignUp__c, true)
            .create();

        new SObjectBuilder(Category_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Category_Codes__c.Name => 'REQUIRED_AREA_CODES',
                Category_Codes__c.Codes__c => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP'
            })
            .create();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.sObjectType),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Enabled_LBO__c => true
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo()
            })
            .build()
            .getRecord();

        Test.startTest();
            Validator areaCodesAssignementValidator = new QuoteValidator.SignUp_AreaCodesAssignementValidator(
                putQliIntoQuote(qt, new List<QuoteLineItem> {qli}),
                new List<Area_Code_Line_Item__c>()
            );
            Response resp = areaCodesAssignementValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(
            0,
            resp.messages.size(),
            'Incorrect validation (AreaCodes) on Sign Up for Primary Quote with Enabled LBO'
        );
    }

    @IsTest
    static void testAreaCodesAssignementValidatorLBODisabled() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setField(Feature_Toggle__c.NGBSOfficeSignUp__c, true)
            .create();

        new SObjectBuilder(Category_Codes__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Category_Codes__c.Name => 'REQUIRED_AREA_CODES',
                Category_Codes__c.Codes__c => 'HDRF,HDR,HD,MLN,MTN,MLFN,MTFN,ALN,ATN,SP,EP'
            })
            .create();

        Quote qt = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Id => ValueProviderBuilder.provideDummyId(Quote.sObjectType),
                Quote.Package_Info__c => NGBSTestDataGenerator.generateQuotePackageInfo(),
                Quote.Enabled_LBO__c => false
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => NGBSTestDataGenerator.generateQLIPackageInfo()
            })
            .build()
            .getRecord();

        Test.startTest();
            Validator areaCodesAssignementValidator = new QuoteValidator.SignUp_AreaCodesAssignementValidator(
                putQliIntoQuote(qt, new List<QuoteLineItem> {qli}),
                new List<Area_Code_Line_Item__c>()
            );
            Response resp = areaCodesAssignementValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Validation_SignUp_Area_Codes_are_missing_help_text),
            'Warning about missing area codes should be shown'
        );
    }

    @IsTest
    static void testQuantityShippingTabPermissionValidatorForLBO() {

        Triggers.switchOff();
        User testUser = createUser(ProfileHelper.PROFILE_NAME_PROSERV_LIGHTNING);
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                        Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.OwnerId => testUser.Id
                })
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Opportunity.CloseDate => System.today(),
                        Opportunity.AccountId => testAccount.Id,
                        Opportunity.Is_Billing_Opportunity__c => true,
                        Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                        Opportunity.OwnerId => testUser.Id
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

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => ValueProviderBuilder.provideList(new List<String>{QuoteHelper.STATUS_UPSELL, QuoteHelper.STATUS_NEW_CUSTOMER})
            })
            .quantity(2)
            .create()
            .getRecords();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Product2.Name => 'TestProduct',
                        Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                        Product2.IsActive => true,
                        Product2.Feature__c => 17,
                        Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lboxes":[{"elementID":"LB_698","min":0,"max":99999}],"categoryPath":"HD"}';
        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => quotes[0].Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 10,
                QuoteLineItem.Discount => 2,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.PackageInfo__c => packageInfoQLI,
                QuoteLineItem.Package_Info_QLI__c => packageInfoQLI
            })
            .create()
            .getRecord();

        List<Quote> reselectedQuote = (List<Quote>) new QuoteSelector().selectQuotes()
                .selectFields(new QuoteSelector().getFieldsForSyncWithNGBS())
                .subselect(new QuoteLineItemSelector().selectQuoteLineItemsForSyncWithNGBS())
                .executeQuery();
        Triggers.switchOn();

        System.runAs(testUser) {
            Test.setMock(HttpCalloutMock.class, new Mock());
            Test.startTest();
            Validator shippingTabPermissionValidator = new QuoteValidator.QuantityShippingTabPermissionValidator(reselectedQuote[0], new List<QuoteLineItem>());
            Response respInvalid = shippingTabPermissionValidator.validate(new Response());

            shippingTabPermissionValidator = new QuoteValidator.QuantityShippingTabPermissionValidator(reselectedQuote[1], new List<QuoteLineItem>());
            Response respValidWithNGBScall = shippingTabPermissionValidator.validate(new Response());

            Test.stopTest();

            System.assertNotEquals(0, respInvalid.messages.size(), 'Response must have messages');
            System.assert(respInvalid.messages[0].messageDetails.contains(
                    Label.Opportunity_Error_OnClose_ShippingTabPermissions_help_text),
                    'Warning about shipping tab permission should be shown'
            );

            System.assertEquals(0, respValidWithNGBScall.messages.size(), 'Validation must be passed');
        }
    }

    @isTest
    static void testBillingPackageExpirationValidatorWithError() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.NGBSPackagesExpirationFiltration__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc',
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .create()
            .getRecord();

        Test.startTest();
        qt = (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(opp.Name)
            .executeQuery()
            .get(0);
        Validator billingPackageExpirationValidator =
            new QuoteValidator.BillingPackageExpirationValidator('1', qt,
                QuoteValidator.BillingProcessType.CLOSE_ON_OPPORTUNITY);
        Response resp = billingPackageExpirationValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Package_has_expired_on_close_help_text),
            'Package on the quote should be expired'
        );
    }

    @isTest
    static void testPassedBillingPackageExpirationValidator() {
        Test.setMock(HttpCalloutMock.class, new Mock());
        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.NGBSPackagesExpirationFiltration__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc',
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .create()
            .getRecord();

        PACKAGE_LABEL_STATE = 'About to Expire';

        Test.startTest();
        qt = (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(opp.Name)
            .executeQuery()
            .get(0);
        Validator billingPackageExpirationValidator =
            new QuoteValidator.BillingPackageExpirationValidator('1', qt,
                QuoteValidator.BillingProcessType.SYNC_WITH_NGBS);
        Response resp = billingPackageExpirationValidator.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size(), 'Validation should be passed without errors');
    }

    @isTest
    static void testBillingPackageExpirationValidator() {

        Test.setMock(HttpCalloutMock.class, new Mock());
        Feature_Toggle__c featureToggle = (Feature_Toggle__c) new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.NGBSPackagesExpirationFiltration__c => true
            })
            .create()
            .getRecord();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'Test Acc',
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .create()
            .getRecord();

        Test.startTest();

        qt = (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(opp.Name)
            .executeQuery()
            .get(0);

        Validator billingPackageExpirationValidator =
            new QuoteValidator.BillingPackageExpirationValidator('1', qt, QuoteValidator.BillingProcessType.SYNC_WITH_NGBS);
        Response resp = billingPackageExpirationValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].message.contains(
            Label.Package_has_expired_text),
            'Warning about expired package should be shown'
        );
    }

    @IsTest
    static void testExpiredPromotionValidator() {

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.BillingStreet => '2078 Adamsville Road',
                Account.BillingCity => 'Laredo',
                Account.BillingPostalCode => '78040',
                Account.BillingState => 'Texas',
                Account.BillingCountry => 'United States'
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
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Promotion__c expiredPromo = (Promotion__c) new SObjectBuilder(Promotion__c.SObjectType)
            .setFields(new Map<SObjectField,Object> {
                Promotion__c.Name => 'testPromo',
                Promotion__c.Start_Date__c => System.today(),
                Promotion__c.End_Date__c => System.today().addDays(-2),
                Promotion__c.Quote__c => qt.Id
                })
            .create()
            .getRecord();

        List<Quote> reselectedQuotes = new QuoteSelector()
            .selectQuoteForSignUp(opp.Id)
            .executeQuery();

        Test.startTest();
        Validator expiredPromotionValidator = new QuoteValidator.ExpiredPromoValidator(new List<Promotion__c> { expiredPromo });
        Response resp = expiredPromotionValidator.validate(new Response());
        Validator expiredSignUpPromotionValidator = new QuoteValidator.SignUp_ExpiredPromoValidator(new List<Promotion__c> { expiredPromo });
        Response respForSignUp = expiredSignUpPromotionValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnClose_Applied_Promo_Is_Expired_help_text),
            'To close the opportunity, you must remove expired promotion and select an available promo in Quote Wizard'
        );

        System.assertNotEquals(0, respForSignUp.messages.size());
        System.assert(respForSignUp.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnSignUp_Applied_Promo_Is_Expired_help_text),
            'To sign up the opportunity, you must remove expired promotion and select an available promo in Quote Wizard'
        );
    }

    @IsTest
    static void testHasIndiaInvoiceRequestValidator() {

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc'
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id
            })
            .create()
            .getRecord();
        List<Approval__c> approvalsList = new List<Approval__c>();

        Test.startTest();
        Validator indiaHasInvoiceRequest = new QuoteValidator.SignUp_HasIndiaInvoiceRequestValidator(opp, approvalsList);
        Response resp = indiaHasInvoiceRequest.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assert(resp.messages[0].messageDetails.contains(
            Label.InvoicingRequestIsRequired),
            'To sigh up the opportunity, you must create approved invoice request'
        );
    }

    private static User createUser(String profileName){
        User user = new User(
            Username = UserHelper.getUniqueUserName(),
            LastName = 'testUser',
            Email = 'testUser@gmail.com',
            Alias = 'testUser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name =: profileName].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    private class Mock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();

            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody(getRequestBody(req));

            return res;
        }

        private String getRequestBody(HTTPRequest req) {
            String body = '';
            String endpoint = req.getEndpoint();

            if (req.getEndpoint().endsWith('/summary?shortView=true')) {
                body = NGBS_ACCOUNT_RESPONSE;
            } else if (req.getEndpoint().contains('/packages')) {
                body = getNgbsPackageResponse();
            } else if (req.getEndpoint().contains('saf_auxiliary_services/')) {
                body = FUNNEL_API_RESPONSE;
            }

            return body;
        }
    }

    @IsTest
    static void testPackageLabelsValidator() {

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc'
            })
            .create()
            .getRecord();

        List<Opportunity> oppList = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAccount.Id,
                Opportunity.RecordTypeId => ValueProviderBuilder.provideList(new List<Id> {
                    OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                    OpportunityHelper.RT_ID_VAR_OPPORTUNITY
                })
            })
            .create()
            .getRecords();

        BillingWrappers.BillingLabels packageLabelsActiveSales = new BillingWrappers.BillingLabels();
        packageLabelsActiveSales.signup_sfdc = new List<String>{'Active'};
        BillingWrappers.BillingLabels packageLabelsActivePartner = new BillingWrappers.BillingLabels();
        packageLabelsActivePartner.signup_sfdcvar = new List<String>{'Active'};
        BillingWrappers.BillingLabels packageLabelsExpiredSales = new BillingWrappers.BillingLabels();
        packageLabelsExpiredSales.signup_sfdc = new List<String>{'Expired'};
        BillingWrappers.BillingLabels packageLabelsExpiredPartner = new BillingWrappers.BillingLabels();
        packageLabelsExpiredPartner.signup_sfdcvar = new List<String>{'Expired'};

        Test.startTest();
            Validator packageLabelsValidatorSalesActive = new QuoteValidator.SignUp_PackageLabelsValidator(packageLabelsActiveSales, oppList[0]);
            Response resp1 = packageLabelsValidatorSalesActive.validate(new Response());
            Validator packageLabelsValidatorPartnerActive = new QuoteValidator.SignUp_PackageLabelsValidator(packageLabelsActivePartner, oppList[1]);
            Response resp2 = packageLabelsValidatorPartnerActive.validate(new Response());
            Validator packageLabelsValidatorSalesExpired = new QuoteValidator.SignUp_PackageLabelsValidator(packageLabelsExpiredSales, oppList[0]);
            Response resp3 = packageLabelsValidatorSalesExpired.validate(new Response());
            Validator packageLabelsValidatorPartnerExpired = new QuoteValidator.SignUp_PackageLabelsValidator(packageLabelsExpiredPartner, oppList[1]);
            Response resp4 = packageLabelsValidatorPartnerExpired.validate(new Response());
        Test.stopTest();
        System.assertEquals(0, resp1.messages.size());
        System.assertEquals(0, resp2.messages.size());
        System.assertNotEquals(0, resp3.messages.size());
        System.assert(resp3.messages[0].messageDetails.contains(
            Label.Wrong_package_label_help_text),
            'To sign up the opportunity, you must change package'
        );

        System.assertNotEquals(0, resp4.messages.size());
        System.assert(resp4.messages[0].messageDetails.contains(
            Label.Wrong_package_label_help_text),
            'To sign up the opportunity, you must change package'
        );
    }

    @isTest
    static void testEmptyBillingIdValidator() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO
            })
            .create()
            .getRecord();

        Quote q = (Quote) new QuoteSelector()
            .selectQuoteForSyncWithNGBSByName(opp.Name)
            .executeQuery()
            .get(0);

        Validator passedValidator = new QuoteValidator.SyncWithNGBS_EmptyBillingIdValidator(qt);
        Response resp = new Response();

        Validator failedValidator = new QuoteValidator.SyncWithNGBS_EmptyBillingIdValidator(q);
        Response respWithError = new Response();

        Test.startTest();

        resp = passedValidator.validate(resp);
        respWithError = failedValidator.validate(respWithError);

        Test.stopTest();

        System.assert(resp.messages.isEmpty(), 'Quote should have populated BillingID');
        System.assertEquals(Label.SyncEmptyBillingId, respWithError.messages.get(0).messageDetails, 'Quote should have empty BillingID');
    }

    @isTest
    static void testDuplicatedQlisValidator() {
        Triggers.switchOff();
        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.sObjectType),
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL
            })
            .create()
            .getRecord();

        Quote qt = NGBSTestDataGenerator.createQuote(opp.Id);

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                    Product2.Name => 'DigitalLine Unlimited',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.IsActive => true,
                    Product2.ExtId__c => Product2Helper.DL_UNL_ELEMENT_ID,
                    Product2.Family => Product2Helper.FAMILY_SERVICE,
                    Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL
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

        List<QuoteLineItem> qliList = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Deactivated__c => false,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => standardPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .quantity(2)
            .create()
            .getRecords();
        Triggers.switchOn();

        Test.startTest();
            qt = (Quote) new QuoteSelector()
                .selectQuoteForSyncWithNGBSByName(opp.Name)
                .executeQuery()
                .get(0);
            Validator failedValidator = new QuoteValidator.SyncWithNGBS_DuplicatedQLIsValidator(qt);
            Response respWithError = new Response();
            respWithError = failedValidator.validate(respWithError);
        Test.stopTest();

        System.assertEquals(Label.DuplicatedQlisOnPrimaryQuote, respWithError.messages.get(0).messageDetails, 'Quote should not contains duplicated QLIs');
    }

    @isTest
    static void testDeviceAvailabilityBackorderedValidator() {
        Response res = prepareDeviceAvailabilityTestData();
        Opportunity opp = (Opportunity) res.data.get('Opportunity');
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();

        Quote qt = (Quote) new QuoteSelector()
                .selectQuoteForSyncWithNGBSByName(opp.Name)
                .executeQuery()
                .get(0);
        Validator failedValidator = new QuoteValidator.DeviceAvailabilityBackorderValidator(qt);
        Response resp = new Response();
        resp = failedValidator.validate(resp);
        Test.stopTest();

        System.assertEquals(Label.Opportunity_Error_OnClose_DeviceAvailabilityBackorder_help_text, resp.messages.get(0).messageDetails, 'Message details must be "There are devices in the quote which are in Backorder so shipping will be delayed."');
        System.assertEquals(Label.Opportunity_Error_OnClose_DeviceAvailabilityBackorder_text, resp.messages.get(0).message, 'Message must be "There are devices in the quote which are in Backorder."');
        System.assertEquals(Response.SEVERITY_WARNING, resp.messages.get(0).severity, 'Severity must be "warning"');
    }

    @isTest
    static void testDeviceAvailabilityOutOfStockValidator() {
        Response res = prepareDeviceAvailabilityTestData();
        Opportunity opp = (Opportunity) res.data.get('Opportunity');
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();

        Quote qt = (Quote) new QuoteSelector()
                .selectQuoteForSyncWithNGBSByName(opp.Name)
                .executeQuery()
                .get(0);
        Validator failedValidator = new QuoteValidator.DeviceAvailabilityOutOfStockValidator(qt);
        Response resp = new Response();
        resp = failedValidator.validate(resp);
        Test.stopTest();

        System.assertEquals(Label.Opportunity_Error_OnClose_DeviceAvailabilityOutOfStock_help_text, resp.messages.get(0).messageDetails, 'Message details must be "You have selected an out of stock item, this will delay the processing of your order and may require a refund."');
        System.assertEquals(Label.Opportunity_Error_OnClose_DeviceAvailabilityOutOfStock_text, resp.messages.get(0).message, 'Message must be "You have selected an out of stock item"');
        System.assertEquals(Response.SEVERITY_WARNING, resp.messages.get(0).severity, 'Severity must be "warning"');
    }

    @isTest
    static void testDeviceAvailabilityHiddenDiscountedValidator() {
        Response res = prepareDeviceAvailabilityTestData();
        Opportunity opp = (Opportunity) res.data.get('Opportunity');
        FUNNEL_API_RESPONSE = FUNNEL_API_RESPONSE.replace('"ruleType":1', '"ruleType":0').replace('"ruleType":3', '"ruleType":2');
        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();

        Quote qt = (Quote) new QuoteSelector()
                .selectQuoteForSyncWithNGBSByName(opp.Name)
                .executeQuery()
                .get(0);
        Validator failedValidator = new QuoteValidator.DeviceAvailabilityHiddenDiscontinuedValidator(qt);
        Response resp = new Response();
        resp = failedValidator.validate(resp);
        Test.stopTest();

        System.assertEquals(Label.Opportunity_Error_OnClose_DeviceAvailabilityHiddenDiscontinued_help_text, resp.messages.get(0).messageDetails, 'Message details must be "There are some devices in the quote in "not available" and "discontinued as off in past" statuses, they can\'t be ordered. Please go to the shipping tab and replace devices in these statuses."');
        System.assertEquals(Label.Opportunity_Error_OnClose_DeviceAvailabilityHiddenDiscontinued_text, resp.messages.get(0).message, 'Message must be "There are some devices in the quote in "not available" and "discontinued as off in past" statuses."');
        System.assertEquals(Response.SEVERITY_ERROR, resp.messages.get(0).severity, 'Severity must be "error"');
    }

    public static Response prepareDeviceAvailabilityTestData() {
        Response res = new Response();
        List<String> catalogIds = new List<String>{'LC_HD_139', 'LC_HD_140'};
        String packageQLIInfo = '{"Version":"1","q":null,"Price":null,"parent":null,"lbox":null,"Id":"18","duration":"One - Time","Discount":{"Value":0,"Type":"Money"},"categoryPath":"HD","CategoryCode":"HD"}';

        Triggers.switchOff();

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.EnabledLBO__c => true
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.Name => ValueProviderBuilder.provideUniqueString('Test Billing Quote'),
                Quote.OpportunityId => opp.Id,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.Approved_Status__c => QuoteHelper.APPROVAL_STATUS_NOT_REQUIRED,
                Quote.Total_Number_of_Digital_Lines__c => 1,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(2),
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.Package_Info__c => PACKAGE_INFO,
                Quote.isPrimary__c => true,
                Quote.Enabled_LBO__c => true
            })
            .create()
            .getRecord();

        List<Product2> products = (List<Product2>) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => ValueProviderBuilder.provideList(new List<String> {'Polycom VVX501 with 1 Expansion Module', 'Polycom VVX501 with 1 Expansion Module'}),
                Product2.ExtID__c => ValueProviderBuilder.provideList(catalogIds),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.IsActive => true
            })
            .quantity(2)
            .create()
            .getRecords();

        List<PricebookEntry> pbe = (List<PricebookEntry>) new SObjectBuilder(PricebookEntry.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id}),
                PricebookEntry.UnitPrice => 100,
                PricebookEntry.IsActive => true
            })
            .quantity(2)
            .create()
            .getRecords();

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => ValueProviderBuilder.provideList(new List<Id>{products[0].Id, products[1].Id}),
                QuoteLineItem.Quantity => 10,
                QuoteLineItem.NewQuantity__c => 10,
                QuoteLineItem.PricebookEntryId => ValueProviderBuilder.provideList(new List<Id> {pbe[0].Id, pbe[1].Id}),
                QuoteLineItem.UnitPrice => 10.00,
                QuoteLineItem.PackageInfo__c => packageQLIInfo
            })
            .quantity(2)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '2078 Adamsville Road',
                CustomAddress__c.City__c => 'Laredo',
                CustomAddress__c.PostalCode__c => '78040',
                CustomAddress__c.State__c => 'Texas',
                CustomAddress__c.Country__c => 'United States'
            })
            .create()
            .getRecord();

        List<CustomAddressAssignments__c> addresses = (List<CustomAddressAssignments__c>) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'test',
                CustomAddressAssignments__c.Quantity__c => ValueProviderBuilder.provideList(new List<Integer> {8,4,7}),
                CustomAddressAssignments__c.QuoteLineItem__c => ValueProviderBuilder.provideList(new List<Id> {qlis[0].Id, qlis[0].Id, qlis[1].Id}),
                CustomAddressAssignments__c.Type__c => ValueProviderBuilder.provideList(new List<String> {'Ground', 'Ground', '2 Day'}),
                CustomAddressAssignments__c.ShippingLicenseTree__c => 'LC_SHP_86:LC_SHIP_82:LC_SHIPT_80'
            })
            .quantity(3)
            .create()
            .getRecords();
        Triggers.switchOn();
        res.setData('Account', acc);
        res.setData('Opportunity', opp);
        res.setData('Quote', qt);
        return res;
    }

    @isTest
    static void testBillingCountryMatchBIValidatorDisabledForExistingBusiness() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Account.Name => 'testAcc',
                    Account.BillingStreet => '443 Kearney Frontage',
                    Account.BillingCity => 'Fresno',
                    Account.BillingState => 'CA',
                    Account.BillingPostalCode => '93706',
                    Account.BillingCountry =>'France',
                    Account.RC_User_ID__c => '123456'
                }
            )
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '33';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => JSON.serialize(pInfo)
                }
            )
            .create()
            .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(testQuote.Id)
            .executeQuery()
            .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
            new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        Assert.areEqual(
            0,
            resp.messages.size(),
            'No validation message should be shown for Existing Business master quote'
            );
    }

    @isTest
    static void testBillingCountryMatchBIValidatorDisabledForNewBusinessTechnicalQuote() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(
            new Map<SObjectField, Object> {
                Account.Name => 'testAcc',
                Account.BillingStreet => '443 Kearney Frontage',
                Account.BillingCity => 'Fresno',
                Account.BillingState => 'CA',
                Account.BillingPostalCode => '93706',
                Account.BillingCountry =>'France'
            }
        )
        .create()
        .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                    Opportunity.CloseDate => Date.today()
                }
            )
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '33';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.Package_Info__c => JSON.serialize(pInfo),
                    Quote.IsMultiProductTechnicalQuote__c => true
                }
            )
            .create()
            .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
            .selectQuoteForSignUp(testQuote.Id)
            .executeQuery()
            .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
            new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        Assert.areEqual(
            0,
            resp.messages.size(),
            'No validation message should be shown for multiproduct technical quote'
            );
    }

    @isTest
    static void testBillingCountryMatchBIValidatorGermanyBi() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'France'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '33';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assertEquals(Label.Billing_Country_Is_Not_Match_RC_EU_Germany_BI, resp.messages[0].messageDetails, 'Country on account should be Germany or Austria for German BI(33)');
    }

    @isTest
    static void testBillingCountryMatchBIValidatorFranceBi() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '1';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assertEquals(Label.Billing_Country_Is_Not_Match_RC_EU_France_BI, resp.messages[0].messageDetails, 'Country on account can not Germany or Austria for France BI(1)');
    }

    @isTest
    static void testBillingCountryMatchBIValidatorSwissBiMVP() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL_EU,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '58';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();
        System.assertNotEquals(0, resp.messages.size());
        System.assertEquals(Label.Billing_Country_Is_Not_Match_Swiss_BI, resp.messages[0].messageDetails, 'Country on account should be Switzerland for Swiss BI(58)');
    }

    @isTest
    static void testBillingCountryMatchBIValidatorSwissBiUO() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATOS,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '59';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assertEquals(Label.Billing_Country_Is_Not_Match_Swiss_BI, resp.messages[0].messageDetails, 'Country on account should be Switzerland for Swiss BI(59)');
    }

    @isTest
    static void testBillingCountryMatchBIValidatorSwissBiACO() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'Germany'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '60';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, resp.messages.size());
        System.assertEquals(Label.Billing_Country_Is_Not_Match_Swiss_BI, resp.messages[0].messageDetails, 'Country on account should be Switzerland for Swiss BI(60)');
    }

    @isTest
    static void testBillingCountryMatchBIValidatorGermanyBiACO() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'France'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_AVAYA,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '44';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size());
    }

    @isTest
    static void testBillingCountryMatchBIValidatorGermanyBiUO() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Account.Name => 'testAcc',
                                Account.BillingStreet => '443 Kearney Frontage',
                                Account.BillingCity => 'Fresno',
                                Account.BillingState => 'CA',
                                Account.BillingPostalCode => '93706',
                                Account.BillingCountry =>'France'
                        }
                )
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
                .setFields(
                        new Map<SObjectField, Object> {
                                Opportunity.AccountId => testAcc.Id,
                                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_ATOS,
                                Opportunity.CloseDate => Date.today()
                        }
                )
                .create()
                .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfo = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
                NGBSTestDataGenerator.generateQuotePackageInfo(),
                List<BillingWrappers.QuotePackageInfo>.class
        );

        pInfo[0].packageBusinessIdentities.approvedBi.id = '25';

        Quote testQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
                .setFields(
                        new Map<SObjectField, Object>{
                                Quote.OpportunityId => opp.Id,
                                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                                Quote.Package_Info__c => JSON.serialize(pInfo)
                        }
                )
                .create()
                .getRecord();

        Quote reselectedQuote = (Quote) new QuoteSelector()
                .selectQuoteForSignUp(testQuote.Id)
                .executeQuery()
                .get(0);
        Triggers.switchOn();

        Test.startTest();
        Validator validator =
                new QuoteValidator.SignUp_BillingCountryMatchBIValidator(Validator.SEVERITY_CRITICAL, reselectedQuote);
        Response resp = validator.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size());
    }

    @isTest
    private static void testSingUp_QuantityShippingValidator() {
        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Shipping_Tab_New_Business__c => true
            })
            .create()
            .getRecord();

        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
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

        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lbox":{"elementID":"LB_698","min":0,"max":99999},"categoryPath":"HD"}';

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        List<QuoteLineItem> qlis = (List<QuoteLineItem>) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.PackageInfo__c => packageInfoQLI,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .quantity(2)
            .create()
            .getRecords();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '10 Avenue Jean Médecin',
                CustomAddress__c.City__c => 'Nice',
                CustomAddress__c.Country__c => 'France',
                CustomAddress__c.State__c => 'Nice',
                CustomAddress__c.PostalCode__c => '06000'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c caa = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.AttentionTo__c => 'Test France',
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.Quantity__c => 2,
                CustomAddressAssignments__c.QuoteLineItem__c => qlis[0].Id,
                CustomAddressAssignments__c.Type__c => 'Ground'})
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        List<QuoteLineItem> qlisForShipping = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object>{new Set<Id>{qt.Id}})
            .executeQuery();
        Validator shippingQuantityValidator = new QuoteValidator.SignUp_QuantityShippingValidator(qt, qlisForShipping, false, false);
        Response respInvalid = shippingQuantityValidator.validate(new Response());

        shippingQuantityValidator = new QuoteValidator.SignUp_QuantityShippingValidator(qt, qlisForShipping, true, false);
        Response respInvalidWithPermission = shippingQuantityValidator.validate(new Response());

        shippingQuantityValidator = new QuoteValidator.SignUp_QuantityShippingValidator(qt, qlisForShipping, false, true);
        Response respInvalidWithProServ = shippingQuantityValidator.validate(new Response());
        Test.stopTest();

        System.assertNotEquals(0, respInvalid.messages.size(), 'Response must have messages');
        System.assert(respInvalid.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnSignUp_Unassigned_Shipping_Devices_text),
            'To proceed with Process Order please move all product sets to the shipping groups.'
        );

        System.assertNotEquals(0, respInvalidWithPermission.messages.size(), 'Response must have messages');
        System.assert(respInvalidWithPermission.messages[0].messageDetails.contains(
            Label.Opportunity_Warning_OnSignUp_Unassigned_Shipping_Devices_text),
            'You have an unshipped product set.'
        );

        System.assertEquals(0, respInvalidWithProServ.messages.size(), 'Validation should be passed');
    }

    @isTest
    private static void testSignUp_QuantityLessThenShippingValidator() {

        new SObjectBuilder(Feature_Toggle__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Feature_Toggle__c.Shipping_Tab_New_Business__c => true
            })
            .create()
            .getRecord();

        Triggers.switchOff();

        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
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

        String packageInfoQLI = '{"categoryCode":"HD","discount":{"value":0,"type":"Money"},"duration":"One - Time","id":"18","version":"1","lbox":{"elementID":"LB_698","min":0,"max":99999},"categoryPath":"HD"}';

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Pricebook2Id => pb.Id,
                Quote.Enabled_LBO__c => true,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_NEW_CUSTOMER
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => qt.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.PackageInfo__c => packageInfoQLI,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false
            })
            .create()
            .getRecord();

        CustomAddress__c ca = (CustomAddress__c) new SObjectBuilder(CustomAddress__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddress__c.AddressLine__c => '10 Avenue Jean Médecin',
                CustomAddress__c.City__c => 'Nice',
                CustomAddress__c.Country__c => 'France',
                CustomAddress__c.State__c => 'Nice',
                CustomAddress__c.PostalCode__c => '06000'
            })
            .create()
            .getRecord();

        CustomAddressAssignments__c caa = (CustomAddressAssignments__c) new SObjectBuilder(CustomAddressAssignments__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                CustomAddressAssignments__c.CustomAddress__c => ca.Id,
                CustomAddressAssignments__c.AttentionTo__c => 'Test France',
                CustomAddressAssignments__c.Quantity__c => 5,
                CustomAddressAssignments__c.QuoteLineItem__c => qli.Id,
                CustomAddressAssignments__c.Type__c => 'Ground'})
            .create()
            .getRecord();
        Triggers.switchOn();

        Test.setMock(HttpCalloutMock.class, new Mock());
        Test.startTest();
        List<QuoteLineItem> qlisForShipping = (List<QuoteLineItem>) new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForShipping(new List<Object>{new Set<Id>{qt.Id}})
            .executeQuery();
        Validator quantityLessThenShippingValidator = new QuoteValidator.SignUp_QuantityLessThenShippingValidator(qt, qlisForShipping);
        Response respInvalid = quantityLessThenShippingValidator.validate(new Response());

        Test.stopTest();

        System.assertNotEquals(0, respInvalid.messages.size(), 'Response must have messages');
        System.assert(respInvalid.messages[0].message.contains(
            Label.Opportunity_Error_OnSignUp_Devices_Less_Quantity_Then_Shipping_text),
            'Shipping Assignment Info'
        );
        System.assert(respInvalid.messages[0].messageDetails.contains(
            Label.Opportunity_Error_OnSignUp_Devices_Less_Quantity_Then_Shipping_help_text),
            'The number of distributed devices on the shipping tab is greater than the number in the cart. Please remove excess devices on the shipping tab.'
        );
    }

    @isTest
    static void testNoProservQuotePass() {
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

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.isPrimary__c => true
            })
            .create()
            .getRecord();

        Test.startTest();
            Validator noProservQuote = new QuoteValidator.NoProservQuote(qt);
            Response resp = noProservQuote.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size(), 'Error message should not appear');
    }

    @isTest
    static void testNoProservQuoteFail() {
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
            Validator noProservQuote = new QuoteValidator.NoProservQuote(null);
            Response resp = noProservQuote.validate(new Response());
        Test.stopTest();

        System.assertEquals(1, resp.messages.size(), 'Error message should appear');
    }

    @isTest
    static void testProServOrCCProServNotSoldOrCancelledPass() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.RT_ID_PROSERV,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.ProServ_Status__c => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.PROSERVSTATUS_SOLD,
                    QuoteHelper.PROSERVSTATUS_CANCELLED
                })
            })
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();
        Validator proServOrCCProServNotSoldOrCancelled = new QuoteValidator.ProServOrCCProServNotSoldOrCancelled(quotes[0], quotes[1]);
        Response resp = proServOrCCProServNotSoldOrCancelled.validate(new Response());
        Test.stopTest();

        System.assertEquals(0, resp.messages.size(), 'Error message should not appear');
    }

        @isTest
    static void testProServOrCCProServNotSoldOrCancelledFail() {
        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.RecordTypeId => ValueProviderBuilder.provideList(new List<String>{
                    QuoteHelper.RT_ID_PROSERV,
                    QuoteHelper.RT_ID_CC_PROSERV
                }),
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CREATED
            })
            .quantity(2)
            .build()
            .getRecords();

        Test.startTest();
            Validator proServOrCCProServNotSoldOrCancelled = new QuoteValidator.ProServOrCCProServNotSoldOrCancelled(quotes[0], quotes[1]);
            Response resp = proServOrCCProServNotSoldOrCancelled.validate(new Response());
        Test.stopTest();

        System.assertEquals(1, resp.messages.size(), 'Error message should appear');
    }

   @isTest
    static void testNoProservOrCCProServQuoteLineItems() {
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

        Quote proServQuote = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.Name => ValueProviderBuilder.provideUniqueString(),
                Quote.IsPrimary__c => true,
                Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV,
                Quote.ProServ_Status__c => QuoteHelper.PROSERVSTATUS_CANCELLED
            })
            .build()
            .getRecord();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.QuoteId => proServQuote.Id,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Quantity => ValueProviderBuilder.provideUniqueNumber(2),
                QuoteLineItem.NewQuantity__c => ValueProviderBuilder.provideUniqueNumber(2),
                QuoteLineItem.Zero_Quantity__c => false
            })
            .build()
            .getRecord();

        Test.startTest();
            Validator noProservOrCCProServQuoteLineItems = new QuoteValidator.NoProservOrCCProServQuoteLineItems(putQliIntoQuote(proServQuote, new List<QuoteLineItem> {qli}), null, opp);
            Response resp = noProservOrCCProServQuoteLineItems.validate(new Response());
        Test.stopTest();

        Assert.areEqual(0, resp.messages.size(), 'Error message should not appear');
    }

    @isTest
    static void testSyncWithNGBSTerminationProfileValidator_positive() {
        Profile testProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object> { ProfileHelper.PROFILE_NAME_DEAL_DESK_LIGHTNING })
            .executeQuery()
            .get(0);

        User testUser = (User) new SObjectBuilder(User.SObjectType, false)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.ProfileId, testProfile.Id)
            .setField(User.LastName, 'Test LastName')
            .setField(User.IsActive, true)
            .setField(User.CommunityNickname, 'Test CommunityName')
            .create()
            .getRecord();
        addPermissionSet(testUser);

        System.runAs(testUser) {
            List<Quote> qts = buildQuotesList();
            Validator passedValidatorEngage = new QuoteValidator.SyncWithNGBS_ProfileValidator(qts[0]);
            Validator passedValidatorInContact = new QuoteValidator.SyncWithNGBS_ProfileValidator(qts[1]);
            Validator passedValidatorOffice = new QuoteValidator.SyncWithNGBS_ProfileValidator(qts[2]);

            passedValidatorEngage.setNextValidator(passedValidatorInContact);
            passedValidatorInContact.setNextValidator(passedValidatorOffice);

            Response respByPassedValidator = new Response();

            Test.startTest();
            respByPassedValidator = passedValidatorEngage.validate(respByPassedValidator);
            Test.stopTest();
            Assert.isTrue(respByPassedValidator.messages.isEmpty(), 'Validation should be passed');
        }
    }

    @isTest
    static void testSyncWithNGBSTerminationProfileValidator_negative() {
        User testUser = (User) new UserSelector(false, false)
            .selectUserByLastName(new List<Object> { 'Test_QuoteValidator_LastName' })
            .executeQuery()
            .get(0);

        System.runAs(testUser){
            List<Quote> qts = buildQuotesList();
            Validator failedValidatorEngage = new QuoteValidator.SyncWithNGBS_ProfileValidator(qts[0]);
            Validator failedValidatorInContact = new QuoteValidator.SyncWithNGBS_ProfileValidator(qts[1]);
            Validator failedValidatorOffice = new QuoteValidator.SyncWithNGBS_ProfileValidator(qts[2]);

            Response respByFailedValidatorEngage = new Response();
            Response respByFailedValidatorInContact = new Response();
            Response respByFailedValidatorOffice = new Response();

            Test.startTest();
            respByFailedValidatorEngage = failedValidatorEngage.validate(respByFailedValidatorEngage);
            respByFailedValidatorInContact = failedValidatorInContact.validate(respByFailedValidatorInContact);
            respByFailedValidatorOffice = failedValidatorOffice.validate(respByFailedValidatorOffice);
            Test.stopTest();

            SWNMessageHelper.ErrorMessagesBuilder builder = new SWNMessageHelper.ErrorMessagesBuilder();

            Assert.areEqual(Label.IsNotAvailableToSyncRINGCX, respByFailedValidatorEngage.messages[0].message, 'Wrong label for Engage Sync');

            SWNMessageHelper.SWNMessage noPermissionRingCXMsg = builder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RINGCX_ERROR);
            Assert.areEqual(
                noPermissionRingCXMsg.header + '. ' + noPermissionRingCXMsg.message,
                respByFailedValidatorEngage.messages[0].messageDetails,
                'Wrong message for Engage Sync'
            );
            Assert.areEqual(Label.IsNotAvailableToSyncRCCC, respByFailedValidatorInContact.messages[0].message, 'Wrong label for InContact Sync');

            SWNMessageHelper.SWNMessage noPermissionRCCCMsg = builder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_RCCC_ERROR);
            Assert.areEqual(
                noPermissionRCCCMsg.header + '. ' + noPermissionRCCCMsg.message,
                respByFailedValidatorInContact.messages[0].messageDetails,
                'Wrong message for InContact Sync'
            );
            Assert.areEqual(Label.IsNotAvailableToSyncWithNGBS, respByFailedValidatorOffice.messages[0].message, 'Wrong label for Sync');

            SWNMessageHelper.SWNMessage noPermissionSyncWithNGBSMsg = builder.getSWNMessage(SWNMessageHelper.LabelMessage.NO_PERMISSION_SYNC_WITH_NGBS_ERROR);
            Assert.areEqual(
                noPermissionSyncWithNGBSMsg.header + '. ' + noPermissionSyncWithNGBSMsg.message,
                respByFailedValidatorOffice.messages[0].messageDetails,
                'Wrong message for Sync'
            );
        }
    }

    @isTest
    static void testSignUpProfileValidatorParams() {
        List<Quote> qts = buildQuotesList();

        Test.startTest();
        QuoteValidator.SignUp_ProfileValidator validatorEngage = new QuoteValidator.SignUp_ProfileValidator(qts[0]);
        QuoteValidator.SignUp_ProfileValidator validatorInContact = new QuoteValidator.SignUp_ProfileValidator(qts[1]);
        QuoteValidator.SignUp_ProfileValidator validatorOffice = new QuoteValidator.SignUp_ProfileValidator(qts[2]);
        Test.stopTest();

        Assert.areEqual(OpportunityHelper.TIER_ENGAGE_SHORT, validatorEngage.shortTier[0], 'Result should be Engage');
        Assert.areEqual(CustomPermissionHelper.PERMISSION_CAN_SIGN_UP_RINGCX, validatorEngage.permissionName, 'Result should be Can_Sign_Up_RingCX');
        Assert.areEqual(OpportunityHelper.TIER_RC_CONTACT_SHORT, validatorInContact.shortTier[0], 'Result should be Contact Center');
        Assert.areEqual(CustomPermissionHelper.PERMISSION_CAN_SIGN_UP_RCCC, validatorInContact.permissionName, 'Result should be Can_Sign_Up_RCCC');
        Assert.isTrue(validatorOffice.shortTier.isEmpty(), 'shortTier for Office should be empty');
        Assert.isNull(validatorOffice.permissionName, 'permissionName for Office should be null');
    }

    @isTest
    static void testSignUpProfileValidator_positive() {
        User testUser = (User) new UserSelector(false, false)
            .selectUserByLastName(new List<Object> { 'Test_QuoteValidator_LastName' })
            .executeQuery()
            .get(0);

        addPermissionSet(testUser);

        List<Quote> qts = buildQuotesList();

        System.runAs(testUser){
            Validator passedValidatorEngage = new QuoteValidator.SignUp_ProfileValidator(qts[0]);
            Validator passedValidatorInContact = new QuoteValidator.SignUp_ProfileValidator(qts[1]);
            Validator passedValidatorOffice = new QuoteValidator.SignUp_ProfileValidator(qts[2]);

            passedValidatorEngage.setNextValidator(passedValidatorInContact);
            passedValidatorInContact.setNextValidator(passedValidatorOffice);
            Response respByPassedValidator = new Response();

            Test.startTest();
            respByPassedValidator = passedValidatorEngage.validate(respByPassedValidator);
            Test.stopTest();
            Assert.isTrue(respByPassedValidator.messages.isEmpty(), 'Validation should be passed');
        }
    }

    @isTest
    static void testSignUpProfileValidator_negative() {
        User testUser = (User) new UserSelector(false, false)
            .selectUserByLastName(new List<Object> { 'Test_QuoteValidator_LastName' })
            .executeQuery()
            .get(0);

        System.runAs(testUser){
            Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.ServiceName__c => OpportunityHelper.TIER_RC_CONTACT_CENTER
                })
                .build()
                .getRecord();

            Validator failedValidator = new QuoteValidator.SignUp_ProfileValidator(qt);
            Response respByFailedValidator = new Response();

            Test.startTest();
            respByFailedValidator = failedValidator.validate(respByFailedValidator);
            Test.stopTest();

            Assert.isFalse(respByFailedValidator.messages.isEmpty(), 'Validation shouldn\'t be passed');
        }
    }

    @isTest
    static void testProServQliToPhaseValidatorPositive() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
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

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.Pricebook2Id => pb.Id
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_PROFESSIONAL_SERVICES})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => masterQuote.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.ServiceName__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'test Phase',
                    Phase__c.Quote__c => masterQuote.Id,
                    Phase__c.Account__c => testAccount.Id
                }
            )
            .create()
            .getRecord();

        Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SObjectBuilder(Hardware_Line_Item__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Hardware_Line_Item__c.Name => 'testPhase',
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                    Hardware_Line_Item__c.Quote_Line_Item__c => qli.Id,
                    Hardware_Line_Item__c.Quantity__c => 3
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            Validator notFailedValidator = new QuoteValidator.ProServQliToPhaseValidator(new List<String>{OpportunityHelper.TIER_PROFESSIONAL_SERVICES}, techQuotes[1], false);
            Response respByNotFailedValidator = new Response();
            respByNotFailedValidator = notFailedValidator.validate(respByNotFailedValidator);
        Test.stopTest();

        System.assertEquals(true, respByNotFailedValidator.messages.isEmpty(), 'ProServQliToPhase Validation should be passed');
    }

    @isTest
    static void testProServQliToPhaseValidatorNegative() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
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

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null,
                    Quote.Pricebook2Id => pb.Id
                }
            )
            .create()
            .getRecord();

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_PROFESSIONAL_SERVICES})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'Test_Product',
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                Product2.IsActive => true,
                Product2.Feature__c => 17,
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
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

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.QuoteId => masterQuote.Id,
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.PricebookEntryId => currentPricebookEntry.Id,
                QuoteLineItem.Quantity => 3,
                QuoteLineItem.NewQuantity__c => 3,
                QuoteLineItem.UnitPrice => 50,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.ServiceName__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => 'test Phase',
                    Phase__c.Quote__c => masterQuote.Id,
                    Phase__c.Account__c => testAccount.Id
                }
            )
            .create()
            .getRecord();

        Hardware_Line_Item__c testHLI = (Hardware_Line_Item__c) new SObjectBuilder(Hardware_Line_Item__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Hardware_Line_Item__c.Name => 'testPhase',
                    Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                    Hardware_Line_Item__c.Quote_Line_Item__c => qli.Id,
                    Hardware_Line_Item__c.Quantity__c => 1
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        Test.startTest();
            Validator notFailedValidator = new QuoteValidator.ProServQliToPhaseValidator(new List<String>{OpportunityHelper.TIER_PROFESSIONAL_SERVICES}, techQuotes[1], false);
            Response respByFailedValidator = new Response();
            respByFailedValidator = notFailedValidator.validate(respByFailedValidator);
        Test.stopTest();

        System.assertEquals(false, respByFailedValidator.messages.isEmpty(), 'ProServQliToPhase Validation should not be passed');
        System.assert(respByFailedValidator.messages[0].messageDetails.contains(Label.ProServQliToPhaseAssignmentErrorMessage),'Not all ProServ QLI are assigned to the Phases');
    }

    @isTest
    static void testPsFieldsValidationNegative() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfoOffice = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        List<BillingWrappers.QuotePackageInfo> pInfoProServ = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfoProServ(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        String pInfoOfficeJson = JSON.serialize(pInfoOffice);
        String pInfoProServJson = JSON.serialize(pInfoProServ);

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_PROFESSIONAL_SERVICES}),
                    Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{pInfoOfficeJson, pInfoProServJson})
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            Validator notFailedValidator = new QuoteValidator.PSFieldsValidation(techQuotes[1], opp, false);
            Response respByFailedValidator = new Response();
            respByFailedValidator = notFailedValidator.validate(respByFailedValidator);
        Test.stopTest();

        Assert.areEqual(false, respByFailedValidator.messages.isEmpty(), 'ProServQliToPhase Validation should not be passed');
        Assert.areEqual(true, respByFailedValidator.messages[0].messageDetails.contains(Label.NoProServRequiredFields), 'PS Fields on the Quote not populated');
    }

    @isTest
    static void testPsFieldsValidationPositive() {
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.Brand_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES
            })
            .create()
            .getRecord();

        Quote masterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => false,
                    Quote.MasterQuote__c => null
                }
            )
            .create()
            .getRecord();

        List<BillingWrappers.QuotePackageInfo> pInfoOffice = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfo(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        List<BillingWrappers.QuotePackageInfo> pInfoProServ = (List<BillingWrappers.QuotePackageInfo>) JSON.deserialize(
            NGBSTestDataGenerator.generateQuotePackageInfoProServ(),
            List<BillingWrappers.QuotePackageInfo>.class
        );

        String pInfoOfficeJson = JSON.serialize(pInfoOffice);
        String pInfoProServJson = JSON.serialize(pInfoProServ);

        List<Quote> techQuotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => opp.Id,
                    Quote.IsMultiProductTechnicalQuote__c => true,
                    Quote.MasterQuote__c => masterQuote.Id,
                    Quote.ServiceName__c => ValueProviderBuilder.provideList(new List<String>{OpportunityHelper.TIER_OFFICE, OpportunityHelper.TIER_PROFESSIONAL_SERVICES}),
                    Quote.Package_Info__c => ValueProviderBuilder.provideList(new List<String>{pInfoOfficeJson, pInfoProServJson}),
                    Quote.TotalProjectHoursQuoted__c => 15,
                    Quote.PSProjectComplexity__c => 'UC-Basic',
                    Quote.ProServ_Forecasted_Close_Date__c => Date.today(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_PROSERV
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            Validator notFailedValidator = new QuoteValidator.PSFieldsValidation(techQuotes[1], opp, false);
            Response respByFailedValidator = new Response();
            respByFailedValidator = notFailedValidator.validate(respByFailedValidator);
        Test.stopTest();

        Assert.areEqual(true, respByFailedValidator.messages.isEmpty(), 'PSFieldsValidation Validation should be passed');
    }

    private static void addPermissionSet(User testUser) {
        // Create Permission Set
        PermissionSet ps = new PermissionSet(
            Name = 'Test_CustomPermissionHelper_PermissionSet1',
            Label = 'Test_CustomPermissionHelper_PermissionSet1'
        );
        insert ps;
        List<String> permissionNames = new List<String> {
            CustomPermissionHelper.PERMISSION_CAN_SIGN_UP_RCCC,
            CustomPermissionHelper.PERMISSION_CAN_SIGN_UP_RINGCX
        };
        List<CustomPermission> permissions = new CustomPermissionSelector()
            .selectCustomPermissionsByDeveloperName(new List<Object> { permissionNames })
            .executeQuery();

        // Assign Permission Sets for Users
        SetupEntityAccess sea1 = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = permissions[0].Id
        );
        SetupEntityAccess sea2 = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = permissions[1].Id
        );
        insert new List<SetupEntityAccess> { sea1, sea2 };

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;
    }

    private static List<Quote> buildQuotesList() {
        return (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.IsMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => new ValueProvider.ListProvider(new List<String> {
                    OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE,
                    OpportunityHelper.TIER_RC_CONTACT_CENTER,
                    OpportunityHelper.TIER_OFFICE
                })
            })
            .quantity(3)
            .build()
            .getRecords();
    }

    private static Quote putQliIntoQuote(Quote qt, List<QuoteLineItem> qlis) {
        Map<String, Object> queryResultMap = new Map<String, Object> {
            'totalSize' => qlis.size(),
            'done' => true,
            'records' => qlis
        };
        return putQliIntoQuote(qt, queryResultMap);
    }

    private static Quote putQliIntoQuote(Quote qt, Map<String, Object> queryResultMap) {
        Map<String, Object> qtMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(qt));
        qtMap.put('QuoteLineItems', queryResultMap);

        return (Quote) JSON.deserialize(JSON.serialize(qtMap), Quote.class);
    }


    @isTest
    static void testSignUpProserveProfileValidator() {
        User testUser = createTestUserWithProServProfile(ProfileHelper.PROFILE_NAME_PRO_SERVICES);
        
        System.runAs(testUser) {
            Quote nonProServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Quote.ServiceName__c => OpportunityHelper.TIER_OFFICE
                })
                .build()
                .getRecord();

            Validator validator = new QuoteValidator.SignUp_ProserveProfileValidator(nonProServQuote, true);
            Response resp = new Response();

            Test.startTest();
            resp = validator.validate(resp);
            Test.stopTest();

            Assert.isTrue(!resp.messages.isEmpty(), 'Validation should not pass for non-ProServ quote with ProServ profile');
        }
    }

    private static User createTestUserWithProServProfile(String profileName) {
        Profile testProfile;
        try {
            testProfile = (Profile) new ProfileSelector()
                .selectProfileByName(new List<Object> { profileName })
                .executeQuery()
                .get(0);
        } catch (Exception e) {
            // If profile doesn't exist, use system admin profile as fallback
            testProfile = (Profile) new ProfileSelector()
                .selectProfileByName(new List<Object> { ProfileHelper.PROFILE_NAME_SYSTEM_ADMINISTRATOR })
                .executeQuery()
                .get(0);
        }

        Triggers.switchOff();
        User testUser = (User) new SObjectBuilder(User.SObjectType, false)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.ProfileId, testProfile.Id)
            .setField(User.LastName, 'Test_ProServeValidator_' + profileName.replace(' ', '_').replace('-', '_'))
            .setField(User.IsActive, true)
            .setField(User.CommunityNickname, 'TestProServe' + String.valueOf(Math.random()).substring(2, 8))
            .create()
            .getRecord();
        Triggers.switchOn();
        
        return testUser;
    }
}