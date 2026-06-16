@isTest
private class Test_CloneHelper {
    private static final String TEST_QUOTE_NAME = 'TEST_QUOTE_NAME 1';

    @TestSetup
    static void makeData() {
        Triggers.switchOff();
        Account testAccount = (Account) new SobjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => testAccount.Id,
                Opportunity.Name => 'Oppty Name',
                Opportunity.CloseDate => ValueProviderBuilder.provideUniqueDate(),
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY
            })
            .create()
            .getRecord();

        Product2 product = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Product2.Name => 'testServiceProd',
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY
            })
            .create()
            .getRecord();

        PricebookEntry testPricebookentry = (PricebookEntry) new SObjectBuilder(PricebookEntry.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                PricebookEntry.Product2Id => product.Id,
                PricebookEntry.UnitPrice => 0,
                PricebookEntry.IsActive => true,
                PricebookEntry.UseStandardPrice => false
            })
            .create()
            .getRecord();

        Quote billingQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Name => TEST_QUOTE_NAME,
                Quote.QuotePosition__c => 1
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Entitlement__c.Account__c => testAccount.Id,
                Entitlement__c.Product__c => product.Id,
                Entitlement__c.Active__c => true,
                Entitlement__c.Quote__c => billingQuote.Id
            })
            .create()
            .getRecord();

        QuoteLineItem testQli = (QuoteLineItem) new SObjectBuilder(QuoteLineItem.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                QuoteLineItem.Product2Id => product.Id,
                QuoteLineItem.QuoteId => billingQuote.Id,
                QuoteLineItem.PricebookEntryId => testPricebookentry.Id,
                QuoteLineItem.Quantity => 1,
                QuoteLineItem.Zero_Quantity__c => false,
                QuoteLineItem.UnitPrice => testPricebookentry.UnitPrice,
                QuoteLineItem.Entitlement__c => ent.Id
            })
            .create()
            .getRecord();

        Area_Codes__c areaCode = (Area_Codes__c) new SObjectBuilder(Area_Codes__c.sObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Area_Codes__c.Name => 'Test Area Code',
                    Area_Codes__c.State__c => 'NY',
                    Area_Codes__c.Country__c => 'United States'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(Area_Code_Line_Item__c.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Area_Code_Line_Item__c.Quote_Line_Item__c => testQli.Id,
                Area_Code_Line_Item__c.Area_Code__c => areaCode.Id,
                Area_Code_Line_Item__c.Quantity__c => 1
            })
            .create();

        Cost_Center__c costCenter = (Cost_Center__c) new SObjectBuilder(Cost_Center__c.sObjectType)
            .setField(Cost_Center__c.Quote__c, billingQuote.Id)
            .create()
            .getRecord();

        new SObjectBuilder(Cost_Center_Line_Item__c.sObjectType)
            .setField(Cost_Center_Line_Item__c.Cost_Center__c, costCenter.Id)
            .create();

        new SObjectBuilder(Promotion__c.sObjectType)
            .setField(Promotion__c.Quote__c, billingQuote.Id)
            .create();

            Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Phase__c.Name => 'Test Phase',
                Phase__c.Phase_Number__c => 1,
                Phase__c.Status__c => 'New',
                Phase__c.Quote__c => billingQuote.Id,
                Phase__c.PhaseDescription__c => 'Test Phase Description',
                Phase__c.Phase_Type__c => 'UC'
            })
            .create()
            .getRecord();

        new SObjectBuilder(Hardware_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Hardware_Line_Item__c.Name => 'Test Hardware Line Item 1',
                Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                Hardware_Line_Item__c.Quote_Line_Item__c => testQli.Id,
                Hardware_Line_Item__c.Quantity__c => 2,
                Hardware_Line_Item__c.Total_Price__c => 100.00
            })
            .create();

        new SObjectBuilder(Hardware_Line_Item__c.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Hardware_Line_Item__c.Name => 'Test Hardware Line Item 2',
                Hardware_Line_Item__c.RingCentral_Hardware_Phase__c => testPhase.Id,
                Hardware_Line_Item__c.Quote_Line_Item__c => testQli.Id,
                Hardware_Line_Item__c.Quantity__c => 1,
                Hardware_Line_Item__c.Total_Price__c => 50.00
            })
            .create();

        Triggers.switchOn();
    }

    @isTest
    static void testCloneBillingQuote() {
        Quote billingQuote = (Quote) new ListOptional(new QuoteSelector()
            .selectQuoteByName(TEST_QUOTE_NAME)
            .selectField(Quote.QuotePosition__c)
            .executeQuery()
        ).getFirst();

        Test.startTest();
            Quote clonedQuote = CloneHelper.cloneQuote(billingQuote.Id, null);
        Test.stopTest();

        Assert.areEqual(billingQuote.QuotePosition__c + 1, clonedQuote.QuotePosition__c, 'Cloned Quote should have an incremented position');
        Assert.areEqual('TEST_QUOTE_NAME 2', clonedQuote.Name, 'Cloned Quote name should contain opty name and an incremented position');

        List<QuoteLineItem> newQuoteLineItems = new QuoteLineItemSelector()
            .selectQuoteLineItemsForCloning(new List<Object> { clonedQuote.Id })
            .executeQuery();
        Assert.areEqual(1, newQuoteLineItems.size(), 'Cloned Quote should have cloned Quote line items');

        List<Entitlement__c> clonedEntitlements = new EntitlementSelector()
            .selectEntitlementsForCloning(clonedQuote.Id)
            .executeQuery();
        Assert.areEqual(1, clonedEntitlements.size(), 'Cloned Quote Line Items should have cloned Entitlements');
        for (Entitlement__c clonedEnt: clonedEntitlements) {
            Assert.areEqual(clonedQuote.Id, clonedEnt.Quote__c, 'All cloned Entitlements should have a different Quote Id link');
        }

        List<Area_Code_Line_Item__c> clonedAreaCodesForQlis = new AreaCodeLineItemSelector()
            .selectAreaCodeLineItemsForCloning(new List<Object> { clonedQuote.Id })
            .executeQuery();
        Assert.areEqual(1, clonedAreaCodesForQlis.size(), 'Cloned Quote Line Items should have cloned Area Codes');
    }

    @IsTest
    static void testCreateCasesForClonedProServQuote() {
        Quote masterQuote = (Quote) new QuoteSelector()
            .selectQuoteByName(TEST_QUOTE_NAME)
            .selectFields(new Set<SObjectField> {
                Quote.QuotePosition__c,
                Quote.OpportunityId,
                Quote.AccountId,
                Quote.Id
            })
            .executeQuery()
            .get(0);

        Triggers.switchOff();
        Quote proServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterQuote.OpportunityId,
                Quote.Name => 'ProServ Quote',
                Quote.MasterQuote__c => masterQuote.Id,
                Quote.isMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Quote clonedMasterQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterQuote.OpportunityId,
                Quote.Name => 'Cloned Master Quote',
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Quote clonedProServQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => masterQuote.OpportunityId,
                Quote.MasterQuote__c => clonedMasterQuote.Id,
                Quote.Name => 'Cloned ProServ Quote',
                Quote.isMultiProductTechnicalQuote__c => true,
                Quote.ServiceName__c => QuoteHelper.NGBS_PROFESSIONAL_SERVICES_PRODUCT,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();

        Triggers.switchOn();
        // Create existing ProServ cases   
        List<Case> existingCases = (List<Case>) new SObjectBuilder(Case.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Case.Subject => new ValueProvider.ListProvider(new List<String>{
                    CaseHelper.SUBJECT_PS_UC_QUOTE_REQUESTED,
                    CaseHelper.SUBJECT_PS_CC_QUOTE_REQUESTED
                }),
                Case.Description => 'Test ProServ Case Description',
                Case.Quote_Approval_ID__c => masterQuote.Id,
                Case.Opportunity_Reference__c => masterQuote.OpportunityId,
                Case.AccountId => masterQuote.AccountId,
                Case.RecordTypeId => CaseHelper.RT_ID_PROFESSIONAL_SERVICES
            })
            .quantity(2)
            .create()
            .getRecords();

        Test.startTest();
            CloneHelper.processClonedQuote(clonedProServQuote, proServQuote);
        Test.stopTest();

        List<Case> newProServCases = (List<Case>) new CaseSelector()
            .selectCaseByOpportunityAndQuoteAndRecordTypeName(
                new List<Object>{
                    clonedProServQuote.OpportunityId, clonedMasterQuote.Id, CaseHelper.RT_NAME_PROFESSIONAL_SERVICES
                })
            .executeQuery();

        Assert.areEqual(2, newProServCases.size(), 'Should have created 2 new cases');
        for(Case newCase : newProServCases) {
            Assert.isTrue(newCase.Description.contains(CaseHelper.CASE_DESCRIPTION_CLONED_QUOTE),
                        'Description should indicate this is a cloned case');
        }
    }

    @isTest
    static void testClonePhasesAndLineItems() {
        Quote originalQuote = (Quote) new QuoteSelector()
            .selectQuoteByName(TEST_QUOTE_NAME)
            .selectFields(new Set<SObjectField> { Quote.OpportunityId })
            .executeQuery()
            .get(0);

        Quote clonedQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => originalQuote.OpportunityId,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Name => 'Cloned Quote for Phase Test',
                Quote.QuotePosition__c => 2
            })
            .create()
            .getRecord();

        List<Phase__c> originalPhases = new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id>{originalQuote.Id}})
            .executeQuery();

        List<Hardware_Line_Item__c> originalLineItems = new HardwareLineItemSelector()
            .selectPhaseLineItemsByPhaseIds(new List<Object>{new Set<Id>{originalPhases[0].Id}})
            .executeQuery();

        Test.startTest();
            CloneHelper.clonePhasesAndLineItems(originalQuote.Id, clonedQuote.Id);
        Test.stopTest();

        List<Phase__c> clonedPhases = new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id>{clonedQuote.Id}})
            .selectFields(new Set<SObjectField> { Phase__c.IsCloned__c })
            .executeQuery();

        Assert.areEqual(originalPhases.size(), clonedPhases.size(), 'Should have cloned the same number of phases');
        
        for (Phase__c clonedPhase : clonedPhases) {
            Assert.areEqual(clonedQuote.Id, clonedPhase.Quote__c, 'Cloned phase should be linked to the cloned quote');
            Assert.isTrue(clonedPhase.IsCloned__c, 'Cloned phase should have IsCloned__c set to true');
        }

        List<Hardware_Line_Item__c> clonedLineItems = new HardwareLineItemSelector()
            .selectPhaseLineItemsByPhaseIds(new List<Object>{new Set<Id>{clonedPhases[0].Id}})
            .executeQuery();

        Assert.areEqual(originalLineItems.size(), clonedLineItems.size(), 'Should have cloned the same number of hardware line items');
        
        for (Hardware_Line_Item__c clonedLineItem : clonedLineItems) {
            Assert.areEqual(clonedPhases[0].Id, clonedLineItem.RingCentral_Hardware_Phase__c, 'Cloned line item should be linked to the cloned phase');
        }
    }

    @isTest
    static void testClonePhasesAndLineItemsWithNoPhases() {
        Quote originalQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => new OpportunitySelector().selectOpportunities().executeQuery().get(0).Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Name => 'Quote Without Phases',
                Quote.QuotePosition__c => 3
            })
            .create()
            .getRecord();

        Quote clonedQuote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => originalQuote.OpportunityId,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.PriceBook2Id => Test.getStandardPriceBookId(),
                Quote.Name => 'Cloned Quote Without Phases',
                Quote.QuotePosition__c => 4
            })
            .create()
            .getRecord();

        Test.startTest();
            CloneHelper.clonePhasesAndLineItems(originalQuote.Id, clonedQuote.Id);
        Test.stopTest();

        List<Phase__c> clonedPhases = new PhaseSelector()
            .selectPhasesByQuoteIds(new List<Object>{new Set<Id>{clonedQuote.Id}})
            .executeQuery();

        Assert.areEqual(0, clonedPhases.size(), 'Should not create any phases when original quote has no phases');
    }
}