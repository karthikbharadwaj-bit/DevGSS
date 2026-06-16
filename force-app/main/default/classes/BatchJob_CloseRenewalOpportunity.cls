public with sharing class BatchJob_CloseRenewalOpportunity implements Database.Batchable<SObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executebatch(this);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Opportunity.Type = Renewal
        // Close Date < today
        // There are no changes in quotes on the Opportunity
        return Database.getQueryLocator([
            SELECT Id, Type, Is_Billing_Opportunity__c
            FROM Opportunity
            WHERE Type = :OpportunityHelper.OPPORTUNITY_TYPE_RENEWAL
                AND CloseDate < TODAY
                AND StageName NOT IN :OpportunityHelper.STAGE_NAMES_CLOSED
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        // Close the Opportunities using the following values:
        // Stage = Stage 7 Closed/Won
        // Sub-Stage = Auto-Renewed
        Map<Id, List<Quote>> quotesByOppId = getQuotesWithQlisByOppIds(scope);

        List<Opportunity> oppsToClose = new List<Opportunity>();
        for (Opportunity opp : scope) {
            if (OpportunityHelper.isRenewalOptyWithoutChanges(opp, quotesByOppId.get(opp.Id))) {
                oppsToClose.add(opp);
            }
        }

        for (Opportunity opp : oppsToClose) {
            opp.StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
            opp.Sub_Stage__c = OpportunityHelper.SUB_STAGE_AUTO_RENEWED;
        }

        if (!oppsToClose.isEmpty()) {
            // disable order generation, cause there is no quotes for Opportunities in batch scope
            OpportunityTriggerHelperRefactored.isAutoGenerateOrders = false;
            Database.SaveResult[] saveResults = Database.update(oppsToClose, false);
            PlatformLog.logErrors('BatchJob_CloseRenewalOpportunity', saveResults, oppsToClose);
        }
    }

    public void finish(Database.BatchableContext bc) {}

    public static Map<Id, List<Quote>> getQuotesWithQlisByOppIds(List<Opportunity> opps) {
        Map<Id, List<Quote>> quotesByOppId = new Map<Id, List<Quote>>();

        for (Opportunity opp : opps) {
            quotesByOppId.put(opp.Id, new List<Quote>());
        }

        List<Quote> quotes = new QuoteSelector()
            .selectQuotes()
            .selectFields(new List<Schema.SObjectField>{
                Quote.OpportunityId, Quote.isPrimary__c, Quote.LastModifiedDate, Quote.Upsell_Status__c})
            .setCondition('OpportunityId IN :bind0')
            .setQueryBindings(new List<Object>{quotesByOppId.keySet()})
            .subselect(
                new QuoteLineItemSelector()
                .selectQuoteLineItems()
                .selectFields(new List<Schema.SObjectField>{QuoteLineItem.QuoteId,
                    QuoteLineItem.Id,
                    QuoteLineItem.Discount_number__c,
                    QuoteLineItem.Discount_type__c,
                    QuoteLineItem.NewQuantity__c,
                    QuoteLineItem.Quantity,
                    QuoteLineItem.Zero_Quantity__c
                })
                .selectFields(new List<String>{
                    'Entitlement__r.Discount__c', 'Entitlement__r.Discount_Type__c', 'Entitlement__r.DisplayQuantity__c'
                })
            )
            .executeQuery();

        for (Quote q : quotes) {
            quotesByOppId.get(q.OpportunityId).add(q);
        }

        return quotesByOppId;
    }

}