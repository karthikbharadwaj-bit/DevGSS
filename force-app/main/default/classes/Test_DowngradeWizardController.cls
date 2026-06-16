@isTest
private class Test_DowngradeWizardController {

    public static DowngradeWizardController.Source getSource() {

        DowngradeWizardController.AdditionalOptionConfig config = new DowngradeWizardController.AdditionalOptionConfig();
        config.obj = 'Opportunity';
        config.plFieldName = 'What_are_we_replacing_option__c';
        config.type = 'picklist';

        List<DowngradeWizardController.AdditionalOptionConfig> configs = new List<DowngradeWizardController.AdditionalOptionConfig>();
        configs.add(config);

        DowngradeWizardController.AdditionalOption additionalOption = new DowngradeWizardController.AdditionalOption();
        additionalOption.value = 'Call Quality';
        additionalOption.configs = configs;

        List<DowngradeWizardController.AdditionalOption> additionalOptions = new List<DowngradeWizardController.AdditionalOption>();
        additionalOptions.add(additionalOption);

        DowngradeWizardController.Source source = new DowngradeWizardController.Source();
        source.name = 'What was the negative content about?';
        source.obj = 'Opportunity';
        source.plFieldName = 'Churn_reason__c';
        source.plFieldNameDependent = 'Sub_Churn_reason__c';
        source.display = 'group';
        source.multiple = true;
        source.additionalOptions = additionalOptions;

        return source;
    }

    @isTest static void test_getPanelConfig() {

        DowngradeWizardController.Source source = getSource();
        String params = JSON.serialize(source);

        DowngradeWizardController.PanelConfig result = DowngradeWizardController.getPanelConfig(params);

        Assert.areEqual(result.name, source.name);
        Assert.areEqual(result.display, source.display);
        Assert.areEqual(result.multiple, source.multiple);

        String options = JSON.serialize(SFDescribeHelper.getDependentOptions(source.obj, source.plFieldName, source.plFieldNameDependent));
        Assert.areEqual(result.options, options);

        String optionsOrdered = JSON.serialize(SFDescribeHelper.getOptions(source.obj, source.plFieldName));
        Assert.areEqual(result.optionsOrdered, optionsOrdered);


        String value = source.additionalOptions.get(0).value;
        DowngradeWizardController.AdditionalOptionConfig config = source.additionalOptions.get(0).configs.get(0);
        String aOptions = JSON.serialize(SFDescribeHelper.getOptions(config.obj, config.plFieldName));

        Assert.areEqual(result.additionalConfigs.get(value).size(), 1);
        Assert.areEqual(result.additionalConfigs.get(value).get(0).fieldName, config.plFieldName);
        Assert.areEqual(result.additionalConfigs.get(value).get(0).type, config.type);
        Assert.areEqual(result.additionalConfigs.get(value).get(0).options, aOptions);
    }

    @isTest
    private static void test_submitForm() {
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;

        Opportunity testOpty1 = new Opportunity (Name = 'testOpty', AccountId = testAcc.Id, StageName = 'Qualify');
        Opportunity testOpty2 = new Opportunity (Name = 'testOpty', AccountId = testAcc.Id, StageName = 'Qualify');
        insert (new List<Opportunity>{testOpty1, testOpty2});

        Quote testQuote2 = new Quote(
            Account__c = testAcc.Id,
            Name = 'testQuote',
            OpportunityId = testOpty2.id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_SALES);

        Quote testQuote1 = new Quote(
            Account__c = testAcc.Id,
            Name = 'testQuote',
            OpportunityId = testOpty1.id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_SALES);
        insert (new List<Quote>{testQuote1, testQuote2});

        Map<String, String> testParams = new Map<String, String>{'Id' => testOpty1.Id, 'StageName' => OpportunityHelper.STAGE_NAME_CLOSED_WON, 'wType' => 'close'};

        Test.startTest();
            Id optyId = DowngradeWizardController.submitForm(testParams);
        Test.stopTest();

        //Check if opportunity status is updated correclty
        Opportunity checkOpty1 = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpty1.Id LIMIT 1];
        Assert.areEqual(OpportunityHelper.STAGE_NAME_CLOSED_WON, checkOpty1.StageName);

        //Check if quote become invalid
        Quote checkQuote = [SELECT Quote_is_Invalid__c FROM Quote WHERE Id = :testQuote2.Id LIMIT 1];
        Assert.areEqual(false, checkQuote.Quote_is_Invalid__c);
    }

    @isTest
    private static void test_submitForm_renewalOpp_substageAutorenewed() {
        Triggers.switchOff();
        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL,
                Opportunity.CloseDate => Date.today()+2
            })
            .create()
            .getRecords();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Cisco SPA-303 Desk Phone',
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Feature__c => Product2Helper.FEATURE_DISCOUNTED_PHONES,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Entitlement__c entl = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField,Object> {
                Quote.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Quote.OpportunityId => ValueProviderBuilder.provideList(new List<Id> {
                    opps[0].Id,
                    opps[1].Id
                }),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                Quote.QuoteType__c => QuoteHelper.QUOTE_TYPE_QUOTE,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecords();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => quotes[0].Id,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.Entitlement__c => entl.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 1,
                QuoteLineItem.Discount_number__c => 0,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Zero_Quantity__c => true,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Map<String, String> testParams = new Map<String, String>{
            'Id' => opps[0].Id,
            'StageName' => OpportunityHelper.STAGE_NAME_CLOSED_WON,
            'wType' => 'close'
        };

        Test.startTest();
            Id optyId = DowngradeWizardController.submitForm(testParams);
        Test.stopTest();

        //Check if opportunity "status", "sub-stage" and "renewed on time" checkbox are updated correctly
        Opportunity checkOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{opps[0].Id})
            .selectFields(new Set<String>{ 'Sub_Stage__c', 'Renewed_On_Time__c', 'ConfirmAndClose__c' })
            .executeQuery()
            .get(0);

        Assert.areEqual(
            OpportunityHelper.STAGE_NAME_CLOSED_WON,
            checkOpty.StageName,
            'Opp Stage hasn\'t been set to "Closed Won"'
        );
        Assert.areEqual(
            OpportunityHelper.SUB_STAGE_CLOSED,
            checkOpty.Sub_Stage__c,
            'Sub Stage should be set to "'
                + OpportunityHelper.SUB_STAGE_CLOSED
                + '" for renewal Opp without changes on Primary Quote'
        );
        Assert.areEqual(
            true,
            checkOpty.Renewed_On_Time__c,
            'Opp is being closed after its CloseDate, but Renewed_On_Time__c is set to true'
        );
        Assert.areEqual(
            false,
            checkOpty.ConfirmAndClose__c,
            'Confirm&Close flow should be ignored for renewal Opty without changes on its upsell quote'
        );

        //Check if quote has become invalid
        Quote checkQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{quotes[1].Id})
            .executeQuery()
            .get(0);
        Assert.areEqual(false, checkQuote.Quote_is_Invalid__c);
    }

    @isTest
    private static void test_submitForm_renewalOpp_renewedOnTime_invalidateQuotes() {
        Triggers.switchOff();
        List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL,
                Opportunity.CloseDate => Date.today()-2
            })
            .create()
            .getRecords();

        Product2 prod = (Product2) new SObjectBuilder(Product2.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => 'Cisco SPA-303 Desk Phone',
                Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                Product2.Feature__c => Product2Helper.FEATURE_DISCOUNTED_PHONES,
                Product2.IsActive => true
            })
            .create()
            .getRecord();

        PricebookEntry standardPrice = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                PricebookEntry.Product2Id => prod.Id,
                PricebookEntry.UnitPrice => 50,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Entitlement__c entl = (Entitlement__c) new SObjectBuilder(Entitlement__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Entitlement__c.Product__c => prod.Id,
                Entitlement__c.Quantity__c => 1,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Price__c => 50,
                Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        List<Quote> quotes = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField,Object> {
                Quote.Account__c => ValueProviderBuilder.provideCommonParent(Account.sObjectType),
                Quote.OpportunityId => ValueProviderBuilder.provideList(new List<Id> {
                    opps[0].Id,
                    opps[1].Id
                }),
                Quote.Pricebook2Id => Test.getStandardPricebookId(),
                Quote.RecordTypeId => QuoteHelper.RT_ID_SALES,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPSELL
            })
            .create()
            .getRecords();

        QuoteLineItem qli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                QuoteLineItem.Product2Id => prod.Id,
                QuoteLineItem.QuoteId => quotes[0].Id,
                QuoteLineItem.PricebookEntryId => standardPrice.Id,
                QuoteLineItem.Entitlement__c => entl.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.NewQuantity__c => 2,
                QuoteLineItem.Discount_number__c => 0,
                QuoteLineItem.Discount_type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => 50
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Map<String, String> testParams = new Map<String, String>{
            'Id' => opps[0].Id,
            'StageName' => OpportunityHelper.STAGE_NAME_CLOSED_WON,
            'wType' => 'close'
        };

        Test.startTest();
            Id optyId = DowngradeWizardController.submitForm(testParams);
        Test.stopTest();

        //Check if opportunity "status", "sub-stage" and "renewed on time" checkbox are updated correctly
        Opportunity checkOpty = (Opportunity) new OpportunitySelector()
            .selectOpportunitiesByIds(new Set<Id>{opps[0].Id})
            .selectFields(new Set<String>{ 'Sub_Stage__c', 'Renewed_On_Time__c', 'ConfirmAndClose__c' })
            .executeQuery()
            .get(0);

        Assert.areEqual(
            OpportunityHelper.STAGE_NAME_CLOSED_WON,
            checkOpty.StageName,
            'Opp Stage hasn\'t been set to "Closed Won"'
        );
        Assert.areEqual(
            OpportunityHelper.SUB_STAGE_CLOSED,
            checkOpty.Sub_Stage__c,
            'Sub Stage should be set to "'
                + OpportunityHelper.SUB_STAGE_CLOSED
                + '" for renewal Opp without changes on Primary Quote'
        );
        Assert.areEqual(
            false,
            checkOpty.Renewed_On_Time__c,
            'Opp is being closed after its CloseDate, but Renewed_On_Time__c is set to true'
        );

        //Check if quote has become invalid
        Quote checkQuote = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{quotes[1].Id})
            .executeQuery()
            .get(0);
        Assert.areEqual(false, checkQuote.Quote_is_Invalid__c);
    }

    @isTest
    private static void testSetQuoteStatusPresented() {
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;

        Opportunity testOpty1 = new Opportunity(
            Name = 'testOpty',
            AccountId = testAcc.Id,
            StageName = 'Qualify',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            ConfirmAndClose__c = true
        );
        insert (new List<Opportunity>{testOpty1});

        Quote testQuote1 = new Quote(
            Account__c = testAcc.Id,
            Name = 'testQuote',
            OpportunityId = testOpty1.id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_SALES,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE
        );
        insert (new List<Quote>{testQuote1});

        Feature_Toggle__c featureToggle = new Feature_Toggle__c(
            ModifiedCloseOpportunityFlow__c = true
        );
        insert featureToggle;

        Map<String, String> testParams = new Map<String, String>{
            'Id' => testOpty1.Id,
            'StageName' => OpportunityHelper.STAGE_NAME_CLOSED_WON,
            'DGW_Downgrade_Reason__c' => 'Opportunity Lost',
            'wType' => 'close'
        };

        Test.startTest();
            Id optyId = DowngradeWizardController.submitForm(testParams);
        Test.stopTest();

        Quote checkQuote = [SELECT Status FROM Quote WHERE Id = :testQuote1.Id LIMIT 1];
        Assert.areEqual(QuoteHelper.QUOTE_STATUS_PRESENTED, checkQuote.Status);
    }

    @isTest
    private static void testSetQuoteStatusPresentedForNGBSOpps() {
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;

        Opportunity testOpty1 = new Opportunity(
            Name = 'testOpty',
            AccountId = testAcc.Id,
            StageName = 'Qualify',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            ConfirmAndClose__c = true,
            Is_Billing_Opportunity__c = true
        );
        insert (new List<Opportunity>{testOpty1});

        Quote testQuote1 = new Quote(
            Account__c = testAcc.Id,
            Name = 'testQuote',
            OpportunityId = testOpty1.id,
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = QuoteHelper.RT_ID_BILLING,
            Upsell_Status__c = QuoteHelper.STATUS_UPSELL,
            QuoteType__c = QuoteHelper.QUOTE_TYPE_QUOTE
        );
        insert (new List<Quote>{testQuote1});

        Feature_Toggle__c featureToggle = new Feature_Toggle__c(
            ModifiedCloseOpportunityFlow__c = true
        );
        insert featureToggle;

        Map<String, String> testParams = new Map<String, String>{
            'Id' => testOpty1.Id,
            'StageName' => OpportunityHelper.STAGE_NAME_CLOSED_WON,
            'DGW_Downgrade_Reason__c' => 'Opportunity Lost',
            'wType' => 'close'
        };

        Test.startTest();
            Id optyId = DowngradeWizardController.submitForm(testParams);
        Test.stopTest();

        Quote checkQuote = [SELECT Status FROM Quote WHERE Id = :testQuote1.Id LIMIT 1];
        Assert.areEqual(QuoteHelper.QUOTE_STATUS_PRESENTED, checkQuote.Status);
    }

    @isTest
    private static void testUncheckConfirmAndClose() {
        Account testAcc = new Account(Name = 'testAcc');
        insert testAcc;

        Opportunity testOpty1 = new Opportunity(
            Name = 'testOpty',
            AccountId = testAcc.Id,
            StageName = 'Qualify',
            Type = OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
            ConfirmAndClose__c = true
        );
        insert (new List<Opportunity>{testOpty1});

        Feature_Toggle__c featureToggle = new Feature_Toggle__c(
            ModifiedCloseOpportunityFlow__c = true
        );
        insert featureToggle;

        Test.startTest();
            Id optyId = DowngradeWizardController.uncheckConfirmAndClose(testOpty1.Id);
        Test.stopTest();

        Opportunity reselectedOpportunity = [SELECT ConfirmAndClose__c FROM Opportunity WHERE Id = :testOpty1.Id LIMIT 1];
        Assert.areEqual(false, reselectedOpportunity.ConfirmAndClose__c);
    }

    //For coverage. Nothing to assert.
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testDefaultConstructor() {
        DowngradeWizardController wizContr = new DowngradeWizardController();
    }

    @isTest
    private static void testUncheckConfirmAndCloseShouldReturnNull() {
        Id result;
        Test.startTest();
        result = DowngradeWizardController.uncheckConfirmAndClose(null);
        Test.stopTest();

        Assert.areEqual(
            null,
            result,
            'Method should return null for null opportunity Id'
        );
    }

    @isTest
    private static void testUncheckConfirmAndCloseShouldThrowException() {
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                Account.BillingStreet => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingCity => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingState => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingCountry => ValueProviderBuilder.provideUniqueString('test'),
                Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString('test')
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => false
            })
            .create()
            .getRecord();

        insert new Feature_Toggle__c(
            ModifiedCloseOpportunityFlow__c = true
        );

        Boolean isExceptionThrown = false;
        Test.startTest();
        try {
            Id optyId = DowngradeWizardController.uncheckConfirmAndClose(billingAcc.Id);
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(
            isExceptionThrown,
            'Exception should be thrown'
        );
    }

    @isTest
    private static void testGetPanelConfigShouldThrowException() {
        Boolean isExceptionThrown = false;
        Test.startTest();
        try {
            DowngradeWizardController.getPanelConfig('{}');
        } catch (AuraHandledException ex) {
            isExceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(
            isExceptionThrown,
            'Exception should be thrown'
        );
    }

    @isTest
    private static void testOpportunityCloseWizardData() {
        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
                        Account.RC_Account_Status__c => AccountHelper.PAID_STATUS,
                        Account.BillingStreet => ValueProviderBuilder.provideUniqueString('test'),
                        Account.BillingCity => ValueProviderBuilder.provideUniqueString('test'),
                        Account.BillingState => ValueProviderBuilder.provideUniqueString('test'),
                        Account.BillingCountry => ValueProviderBuilder.provideUniqueString('test'),
                        Account.BillingPostalCode => ValueProviderBuilder.provideUniqueString('test')
                })
                .create()
                .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                        Opportunity.CloseDate => System.today(),
                        Opportunity.AccountId => billingAcc.Id,
                        Opportunity.Is_Billing_Opportunity__c => false
                })
                .create()
                .getRecord();

        Boolean isExceptionThrown = false;
        Test.startTest();
        Opportunity oppty = DowngradeWizardController.getOpportunityCloseWizardData(opp.Id);
        Test.stopTest();
        Assert.areNotEqual(null, oppty.Id);
    }

    @isTest
    private static void testDowngradeOpportunity() {   
    	 Opportunity opp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.Name =>'Test Oppty 1',
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_PROBLEM
            })
            .create()
            .getRecord();
        
        Map<String, String> testParams = new Map<String, String> {
            'Id' => opp.Id,
            'StageName' => OpportunityHelper.STAGE_NAME_DOWNGRADED,
            'wType' => 'downgrade',
            'isInline' => 'false' 
        };
        Test.startTest();
            Id optyId = DowngradeWizardController.submitForm(testParams);
        Test.stopTest();
        
        Assert.areEqual(optyId, opp.Id);
    }
}