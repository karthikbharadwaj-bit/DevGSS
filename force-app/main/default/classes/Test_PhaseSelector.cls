@isTest
private class Test_PhaseSelector {
    //Account feilds defined
    private static final String ACCOUNT_NAME = 'Test';
    private static final String ACCOUNT_BILLING_ID = '12345';
    
    //Opportunity fields defined 
    private static final String OPPORTUNITY_NAME = 'TestOpportunity';
    private static final String OPPORTUNITY_BRAND_NAME = 'RingCentral';
    private static final String OPPORTUNITY_TIER_NAME = 'Office';
    private static final String OPPORTUNITY_STAGE_NAME = '1. Qualify';
    private static final String OPPORTUNITY_CURRENCY_ISO_CODE = 'USD';
    
    //Quote fields defined
    private static final String QUOTE_NAME = 'testQuote';

    //Order fields defined
    private static final String ORDER_NAME = 'Test';
    private static final String ORDER_STATUS = 'Requested';

    //Phase fields defined
    private static final String PHASE_NAME = 'Test';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Phases should be selected';
	private static final String ASSERT_EQUALS_MESSAGE = 'Wrong phase selected';
    
    @testsetup
    private static void testData(){
		Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => ACCOUNT_NAME,
                        Account.Billing_ID__c => ACCOUNT_BILLING_ID
                    }
                )
                .create()
                .getRecord();
		Opportunity testOpp = (Opportunity) new SobjectBuilder(Opportunity.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Opportunity.AccountId => testAcc.Id,
                        Opportunity.Name => OPPORTUNITY_NAME,
                        Opportunity.Brand_Name__c => OPPORTUNITY_BRAND_NAME,
                        Opportunity.Tier_Name__c => OPPORTUNITY_TIER_NAME,
                        Opportunity.StageName => OPPORTUNITY_STAGE_NAME,
                        Opportunity.CurrencyIsoCode => OPPORTUNITY_CURRENCY_ISO_CODE
                        }
                )
                .create()
                .getRecord();
            
		Quote testQuote = (Quote) new SobjectBuilder(Quote.SObjectType)
			.setFields(
                    new Map<SObjectField, Object>{
                        Quote.Name => QUOTE_NAME,
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
                    Order.Name => ORDER_NAME,
                    Order.Status => ORDER_STATUS,
                    Order.EffectiveDate => Date.newInstance(2050, 11, 11)
                }
            )
            .create()
            .getRecord();
        
        Phase__c testPhase = (Phase__c) new SObjectBuilder(Phase__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Phase__c.Name => PHASE_NAME,
                    Phase__c.Quote__c => testQuote.Id,
                    Phase__c.Order__c => testOrder.Id,
                    Phase__c.Account__c => testAcc.Id
                }
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectPhases(){
        List<Phase__c> phases = (List<Phase__c>) new PhaseSelector(true, true)
            .selectPhases()
            .executeQuery();

        System.assert(phases.size() > 0, ASSERT_MESSAGE);
    }
    
    
    @isTest
    private static void testSelectPhasesByOrdersIdsExcludePhaseIds(){
        List<Phase__c> phases = (List<Phase__c>) new PhaseSelector()
            .selectPhases()
            .executeQuery();

        List<Phase__c> phasesByOrdersIdsExcludePhaseIds = (List<Phase__c>) new PhaseSelector()
            .selectPhasesByOrdersIdsExcludePhaseIds(new List<Object>{new Set<Id>{phases[0].Order__c},
                													 new Set<String>{}})
            .executeQuery();

        System.assert(phasesByOrdersIdsExcludePhaseIds.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(phases[0].Id, phasesByOrdersIdsExcludePhaseIds[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectPhaseById(){
        List<Phase__c> phases = (List<Phase__c>) new PhaseSelector()
            .selectPhases()
            .executeQuery();
            
        List<Phase__c> phaseById = (List<Phase__c>) new PhaseSelector()
            .selectPhaseById(new List<Object>{new Set<Id>{phases[0].Id}})
            .executeQuery();

        System.assert(phaseById.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(phases[0].Id, phaseById[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectPhasesForClose(){
        List<Phase__c> phases = (List<Phase__c>) new PhaseSelector()
            .selectPhases()
            .executeQuery();

        List<Phase__c> phasesForClose = (List<Phase__c>) new PhaseSelector()
            .selectPhasesForClose(new List<Object>{new Set<Id>{phases[0].Quote__c}})
            .executeQuery();

        System.assert(phasesForClose.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(phases[0].Id, phasesForClose[0].Id, ASSERT_EQUALS_MESSAGE);
    }

    @isTest
    private static void testSelectPhasesByQuoteId(){
        List<Phase__c> phases = (List<Phase__c>) new PhaseSelector()
            .selectPhases()
            .executeQuery();

        List<Phase__c> selectedPhases = (List<Phase__c>) new PhaseSelector()
            .selectPhasesByQuoteId(new List<Object>{new Set<Id>{phases[0].Quote__c}})
            .executeQuery();

        System.assert(selectedPhases.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(phases[0].Id, selectedPhases[0].Id, ASSERT_EQUALS_MESSAGE);
    }
}