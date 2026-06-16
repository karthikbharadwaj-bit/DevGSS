public class BatchJob_PopulateSyncInfoMPL extends BatchJob_PopulateSyncInfo {
    public BatchJob_PopulateSyncInfoMPL() {
        super();
    }
    public BatchJob_PopulateSyncInfoMPL(String overrideQuery) {
        super(overrideQuery);
    }

    public void execute(Database.BatchableContext BC, List<Quote> scope) {
        Map<Id, Opportunity> opportunitiesToUpdate = new Map<Id, Opportunity>();

        for (Quote qt : scope) {
            Opportunity opp = qt.Opportunity;
            if (opportunitiesToUpdate.containsKey(opp.Id) || shouldBeSkipped(opp.SyncInfo__c)) {
                continue;
            }

            opp.SyncInfo__c = addStepNamesToSyncInfo(opp.SyncInfo__c, qt);
            opportunitiesToUpdate.put(opp.Id, opp);
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            Triggers.switchOff();
            update opportunitiesToUpdate.values();
            Triggers.switchOn();
        }
    }

    protected override Database.QueryLocator buildQueryLocator() {
        return new QuoteSelector()
            .newQueryFactory()
            .setFactoryName('selectSyncInfo')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String> {
                'Id',
                'Enabled_LBO__c',
                'PackageNameOld__c',
                'IsMultiProductTechnicalQuote__c',
                'OpportunityId',
                'Opportunity.Id',
                'Opportunity.SyncInfo__c',
                'Opportunity.Type',
                'Account.RC_User_ID__c',
                'Account.Billing_ID__c',
                'Account.Offer_Type__c'
            })
            .setCondition('IsPrimary__c = true AND Opportunity.IsClosed = true AND Opportunity.StageName = \'7. Closed Won\' AND Opportunity.CloseDate = LAST_N_DAYS:120')
            .executeQueryLocator();
    }
}