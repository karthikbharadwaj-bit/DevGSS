public class BatchJob_DowngradeOpportunity implements Database.Batchable<SObject> {
    private Set<Id> oppIdsToDowngrade;
    private Integer oppsProcessed;

    public BatchJob_DowngradeOpportunity(Set<Id> oppIdsToDowngrade) {
        this.oppIdsToDowngrade = oppIdsToDowngrade;
        this.oppsProcessed = 0;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new OpportunitySelector()
            .newQueryFactory()
            .setFactoryName('selectOpenOpportunitiesByIds')
            .setCondition('Id IN :bind0 AND IsClosed = false')
            .setQueryBindings(this.oppIdsToDowngrade)
            .addOrdering(Opportunity.AccountId, QueryFactory.SortOrder.ASCENDING)
            .executeQueryLocator();
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> opportunitiesToDowngrade) {
        for (Opportunity opp : opportunitiesToDowngrade) {
            opp.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
            opp.Downgrade_Reason_Opp__c = OpportunityHelper.DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC;
            opp.Why_We_Lost__c = OpportunityHelper.DOWNGRADE_REASON_CC_MIGRATION;
            opp.Final_Competitor_we_lost_against__c = OpportunityHelper.COMPETITOR_LOST_CC_MIGRATION;
            opp.Additional_details_on_why_we_lost__c =  OpportunityHelper.DOWNGRADE_REASON_MIGRATING_THIS_ACCOUNT_FROM_LEGACY_CC;
        }

        update opportunitiesToDowngrade;
        this.oppsProcessed += opportunitiesToDowngrade.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('BatchJob_DowngradeOpportunity: amount of Opportunity records downgraded: ' + this.oppsProcessed);
    }
}