@isTest
private class Test_PhaseService {

    @isTest
    static void testUpsertPhases() {

        Triggers.SwitchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        BillingWrappers.Phase phase1 = new BillingWrappers.Phase();
        phase1.opportunityId = testOpp.Id;
        phase1.status = 'New';
        phase1.uniqueId = 'Phase-1-uniqueID';
        phase1.quoteId = testQuote.Id;
        phase1.currencyIsoCode = 'USD';
        phase1.phaseNumber = 1;

        BillingWrappers.Phase phase2 = new BillingWrappers.Phase();
        phase2.opportunityId = testOpp.Id;
        phase2.status = 'New';
        phase2.uniqueId = 'Phase-2-uniqueID';
        phase2.quoteId = testQuote.Id;
        phase2.currencyIsoCode = 'USD';
        phase2.phaseNumber = 2;

        BillingWrappers.PhasesParams params = new BillingWrappers.PhasesParams();
        params.action = 'upsertPhases';
        params.phases = new List<BillingWrappers.Phase>{phase1, phase2};

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseService.handleRequest();
        Test.stopTest();

        String body = RestContext.response.responseBody.toString();
        Map<String, Phase__c> resultPhases = (Map<String, Phase__c>)JSON.deserialize(body, Map<String, Phase__c>.class);

        Assert.areEqual(2, resultPhases.values().size());
        Assert.areEqual(1, resultPhases.get('Phase-1-uniqueID').Phase_Number__c, 'Phases should be upserted correctly');
        Assert.areEqual(2, resultPhases.get('Phase-2-uniqueID').Phase_Number__c, 'Phases should be upserted correctly');
    }

    @isTest
    public static void testDeletePhases() {

        Triggers.SwitchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                        Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                        Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                    }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testQuote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
            .create()
            .getRecord();

        BillingWrappers.Phase phase1 = new BillingWrappers.Phase();
        phase1.opportunityId = testOpp.Id;
        phase1.status = 'New';
        phase1.uniqueId = 'Phase-1-uniqueID';
        phase1.quoteId = testQuote.Id;
        phase1.currencyIsoCode = 'USD';
        phase1.phaseNumber = 1;

        BillingWrappers.Phase phase2 = new BillingWrappers.Phase();
        phase2.opportunityId = testOpp.Id;
        phase2.status = 'New';
        phase2.uniqueId = 'Phase-2-uniqueID';
        phase2.quoteId = testQuote.Id;
        phase2.currencyIsoCode = 'USD';
        phase2.phaseNumber = 2;

        List<BillingWrappers.Phase> phases = new List<BillingWrappers.Phase>{phase1, phase2};
        List<Phase__c> resultPhases = (PhaseService.upsertPhases(phases)).values();

        Triggers.switchOn();

        BillingWrappers.PhasesParams params = new BillingWrappers.PhasesParams();
        params.action = 'deletePhases';
        params.phases = phases;
        params.selectedQuoteId = testQuote.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseService.handleRequest();
        Test.stopTest();

        List<Phase__c> selectedPhases = (List<Phase__c>)new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id> {testQuote.Id}})
            .executeQuery();

        Assert.areEqual(0, selectedPhases.size(), 'Phase should be deleted');
    }

    @isTest
    static void testGetPhases() {

        Triggers.SwitchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                    }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testQuote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
                )
            .create()
            .getRecord();

        Phase__c phase1 = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => testAcc.Id,
                    Phase__c.Opportunity__c => testOpp.Id,
                    Phase__c.Quote__c => testQuote.Id,
                    Phase__c.Initial_Payment__c => 10,
                    Phase__c.Phase_Number__c => 1
                }
            )
            .create()
            .getRecord();

        Phase__c phase2 = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Status__c => 'New',
                    Phase__c.RecordTypeId => PhaseHelper.RT_INFO_BY_NAME.get('ProServ Phase').getRecordTypeId(),
                    Phase__c.Account__c => testAcc.Id,
                    Phase__c.Opportunity__c => testOpp.Id,
                    Phase__c.Quote__c => testQuote.Id,
                    Phase__c.Initial_Payment__c => 10,
                    Phase__c.Phase_Number__c => 2
                }
            )
            .create()
            .getRecord();

        Triggers.switchOn();

        BillingWrappers.PhasesParams params = new BillingWrappers.PhasesParams();
        params.action = 'getPhases';
        params.selectedQuoteId = testQuote.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseService.handleRequest();
            String body = RestContext.response.responseBody.toString();
        Test.stopTest();

        Map<Id, Phase__c>  resultPhases = new Map<Id, Phase__c>((List<Phase__c>)JSON.deserialize(body, List<Phase__c>.class));
        Assert.areEqual(2, resultPhases.size(), 'Phases should be selected correctly');
        Assert.areEqual(1, resultPhases.get(phase1.Id).Phase_Number__c, 'Phases should be selected correctly');
        Assert.areEqual(2, resultPhases.get(phase2.Id).Phase_Number__c, 'Phases should be selected correctly');
    }

    @isTest
    static void testCreatePhaseForChangeOrder() {

        Triggers.SwitchOff();

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                    }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => 'testQuote',
                        Quote.OpportunityId => testOpp.Id,
                        Quote.Account__c => testOpp.AccountId,
                        Quote.isPrimary__c => true,
                        Quote.Pricebook2Id => Test.getStandardPricebookId(),
                        Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                    }
            )
            .create()
            .getRecord();

        Order testOrder = (Order) new SObjectBuilder(Order.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Order.AccountId => testAcc.Id,
                    Order.Name => 'test',
                    Order.Status => OrderHelper.STATUS_NEW,
                    Order.OpportunityId => testOpp.Id,
                    Order.EffectiveDate => System.today().addDays(100),
                    Order.RecordTypeId => OrderHelper.RT_ID_PROSERV,
                    Order.Pricebook2Id => Test.getStandardPricebookId()
                }
            )
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => testOrder.Id,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 1
            })
            .create()
            .getRecord();

        Triggers.switchOn();

        BillingWrappers.PhasesParams params = new BillingWrappers.PhasesParams();
        params.action = 'createPhaseForChangeOrder';
        params.orderId = testOrder.Id;
        params.selectedQuoteId = testQuote.Id;
        params.opportunityId = testOpp.Id;

        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(JSON.serialize(params));
        RestContext.request = request;

        Test.startTest();
            PhaseService.handleRequest();

            List<Phase__c> selectedPhases = (List<Phase__c>)new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id> {testQuote.Id}})
            .executeQuery();
        Test.stopTest();

        Assert.areEqual(1, selectedPhases.size(), 'Phases should be correctly created and inserted');
        Assert.areEqual(testSuborder.SuborderNumber__c, selectedPhases[0].Phase_Number__c, 'Phases should be correctly created and inserted');
        Assert.areEqual(testQuote.Id, selectedPhases[0].Quote__c, 'Phases should be correctly created and inserted');
        Assert.areEqual('New', selectedPhases[0].Status__c, 'Phases should be correctly created and inserted');
    }

    @isTest
    static void testBuildPhaseFromWrapper() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();

        BillingWrappers.Phase wrapper = new BillingWrappers.Phase();
        wrapper.opportunityId = testOpp.Id;
        wrapper.quoteId = testQuote.Id;
        wrapper.status = 'New';
        wrapper.currencyIsoCode = 'USD';
        wrapper.phaseNumber = 5;
        wrapper.description = 'Test phase';
        wrapper.phaseType = 'UC';

        Phase__c phase = PhaseService.buildPhase(wrapper);
        Assert.areEqual(wrapper.opportunityId, phase.Opportunity__c, 'Opportunity__c should match');
        Assert.areEqual(wrapper.quoteId, phase.Quote__c, 'Quote__c should match');
        Assert.areEqual(wrapper.status, phase.Status__c, 'Status__c should match');
        Assert.areEqual(wrapper.currencyIsoCode, phase.CurrencyIsoCode, 'CurrencyIsoCode should match');
        Assert.areEqual(wrapper.phaseNumber, phase.Phase_Number__c, 'Phase_Number__c should match');
        Assert.areEqual(wrapper.description, phase.PhaseDescription__c, 'PhaseDescription__c should match');
        Assert.areEqual(wrapper.phaseType, phase.Phase_Type__c, 'Phase_Type__c should match');
        Assert.isNull(phase.Suborder__c, 'Suborder__c should be null');
    }

    @isTest
    static void testBuildPhaseFromSuborder() {
        Triggers.switchOff();
        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => AccountHelper.RT_NAME_CUSTOMER_ACCOUNT,
                    Account.Billing_ID__c => '12345'
                }
            )
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Name => OpportunityHelper.RT_NAME_NEW_SALES_OPPORTUNITY,
                    Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                    Opportunity.Tier_Name__c => OpportunityHelper.TIER_PROFESSIONAL_SERVICES,
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CurrencyIsoCode => OpportunityHelper.CURRENCY_ISO_CODE_USD,
                    Opportunity.CloseDate => System.today().addMonths(1)
                }
            )
            .create()
            .getRecord();

        Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => 'testQuote',
                    Quote.OpportunityId => testOpp.Id,
                    Quote.Account__c => testOpp.AccountId,
                    Quote.isPrimary__c => true,
                    Quote.Pricebook2Id => Test.getStandardPricebookId(),
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                }
            )
            .create()
            .getRecord();

        Suborder__c testSuborder = (Suborder__c) new SOBjectBuilder(Suborder__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Suborder__c.Order__c => null,
                Suborder__c.Status__c => SuborderHelper.STATUS_NEW,
                Suborder__c.SuborderNumber__c => 7,
                Suborder__c.CurrencyIsoCode => 'USD',
                Suborder__c.Suborder_Type__c => 'CC'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        Phase__c phase = PhaseService.buildPhase(testOpp.Id, testQuote.Id, testSuborder);
        Assert.areEqual(testOpp.Id, phase.Opportunity__c, 'Opportunity__c should match');
        Assert.areEqual(testQuote.Id, phase.Quote__c, 'Quote__c should match');
        Assert.areEqual('New', phase.Status__c, 'Status__c should match');
        Assert.areEqual(testSuborder.CurrencyIsoCode, phase.CurrencyIsoCode, 'CurrencyIsoCode should match');
        Assert.areEqual(testSuborder.SuborderNumber__c, phase.Phase_Number__c, 'Phase_Number__c should match');
        Assert.areEqual('CC', phase.Phase_Type__c, 'Phase_Type__c should match');
        Assert.areEqual(testSuborder.Id, phase.Suborder__c, 'Suborder__c should match');
    }
}