@isTest
public class Test_BatchJob_CloseRenewalOpportunity {

    @testSetup
    private static void setup() {

        String renType = OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL;
        String newType = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;

        String openStage = OpportunityHelper.STAGE_NAME_QUALIFY;
        String closedStage = OpportunityHelper.STAGE_NAME_CLOSED_WON;

        Date today = Date.today();
        Date past = Date.today().addDays(-2);

        Account[] testAccs = new SObjectBuilder(Account.sObjectType)
            .quantity(6)
            .build()
            .create()
            .getRecords();

        Opportunity[] testOpps = new SObjectBuilder(Opportunity.sObjectType)
            .setField(Opportunity.Name, new ValueProvider.ListProvider(new List<String>{
                'opp-1 (good)',
                'opp-2 (not a \'Renewal\' oppotrunity)',
                'opp-3 (initialy in closed stage)',
                'opp-4 (closeDate not in the past)',
                'opp-5 (has an \'Upsell\' quote without changes)',
                'opp-6 (has an \'Upsell\' quote with changes in discount)'
            }))
            .setField(Opportunity.Type, new ValueProvider.ListProvider(new List<String>
                {renType, newType, renType, renType, renType, renType}))
            .setField(Opportunity.StageName, new ValueProvider.ListProvider(new List<String>
                {openStage, openStage, closedStage, openStage, openStage, openStage}))
            .setField(Opportunity.CloseDate, new ValueProvider.ListProvider(new List<Date>
                {past, past, past, today, past, past}))
            .setField(Opportunity.AccountId, new ValueProvider.ListProvider(new List<String>
                {testAccs[0].Id, testAccs[1].Id, testAccs[2].Id, testAccs[3].Id, testAccs[4].Id, testAccs[5].Id}))
            .quantity(6)
            .create()
            .getRecords();

        // create a quotes for 'opp-5' and 'opp-6'
        Quote[] testQuotes = new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.OpportunityId, new ValueProvider.MultiParentProvider(new List<SObject>
                {testOpps[4], testOpps[5]}))
            .setField(Quote.PriceBook2Id, Test.getStandardPriceBookId())
            .setField(Quote.Upsell_Status__c, QuoteHelper.STATUS_UPSELL)
            .setField(Quote.Status, QuoteHelper.QUOTE_STATUS_DRAFT)
            .setField(Quote.QuoteType__c, QuoteHelper.QUOTE_TYPE_QUOTE)
            .quantity(2)
            .create()
            .getRecords();

        // create two quotesLineItems - without changes and with changed Quantity
        new SObjectBuilder(QuoteLineItem.sObjectType)
            .setField(QuoteLineItem.QuoteId, new ValueProvider.MultiParentProvider(testQuotes))
            .setField(QuoteLineItem.PricebookEntryId, 
                new ValueProvider.GenericParentProvider(PricebookEntry.sObjectType, new Map<SObjectField, Object>{
                    PricebookEntry.Pricebook2Id => Test.getStandardPriceBookId(),
                    PricebookEntry.Product2Id => new ValueProvider.GenericParentProvider(Product2.sObjectType),
                    PricebookEntry.UnitPrice => 345,
                    PricebookEntry.IsActive => true
                }))
            .setField(QuoteLineItem.Entitlement__c, 
                new ValueProvider.GenericParentProvider(Entitlement__c.sObjectType, new Map<SObjectField, Object>{
                    Entitlement__c.Account__c => testOpps[4].AccountId,
                    Entitlement__c.Quantity__c => 5,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0
                }))
            .setField(QuoteLineItem.UnitPrice, 345)
            .setField(QuoteLineItem.Quantity, 5)
            .setField(QuoteLineItem.Zero_Quantity__c, new ValueProvider.ListProvider(new List<Boolean>{true, false}))
            .setField(QuoteLineItem.NewQuantity__c, new ValueProvider.ListProvider(new List<Integer>{5, 15}))
            .setField(QuoteLineItem.Discount_type__c, QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY)
            .setField(QuoteLineItem.Discount_number__c, 0)
            .quantity(2)
            .create();

    }

    @isTest
    private static void testBatch() {
        QueryFactory queryFactory = new OpportunitySelector()
            .selectOpportunities()
            .selectField(Opportunity.Sub_Stage__c);

        // assert that opportunities are not closed with 'Auto-Renewed'
        for (Opportunity opp : (List<Opportunity>) queryFactory.executeQuery()) {
            if (!opp.Name.startsWith('opp-3')) {
                System.assertNotEquals(OpportunityHelper.STAGE_NAME_CLOSED_WON, opp.StageName,
                    'Opportunity \'' + opp.Name + '\' should not be closed initially.');
            }
            System.assertNotEquals(OpportunityHelper.SUB_STAGE_AUTO_RENEWED, opp.Sub_Stage__c,
                'Opportunitiy \'' + opp.Name + '\' should not be "Auto-Renewed" initially.');
        }

        Test.startTest();

            (new BatchJob_CloseRenewalOpportunity()).execute(null);

        Test.stopTest();

        // only 'opp-1' and 'opp-5' opportunities should be closed with 'Auto-Renewed'
        for (Opportunity opp : (List<Opportunity>) queryFactory.executeQuery()) {
            if (opp.Name.startsWith('opp-1') || opp.Name.startsWith('opp-5')) {
                System.assertEquals(OpportunityHelper.STAGE_NAME_CLOSED_WON, opp.StageName,
                    'Opportunity \'' + opp.Name + '\' should be closed by the batch.');
                System.assertEquals(OpportunityHelper.SUB_STAGE_AUTO_RENEWED, opp.Sub_Stage__c,
                    'The batch should update \'' + opp.Name + '\' sub-stage with "Auto-Renewed".');
            } else {
                System.assertNotEquals(OpportunityHelper.SUB_STAGE_AUTO_RENEWED, opp.Sub_Stage__c,
                    'Opportunity \'' + opp.Name + '\' should not be affected by the batch (i.e. "Auto-Renewed").');
            }
        }

    }

}