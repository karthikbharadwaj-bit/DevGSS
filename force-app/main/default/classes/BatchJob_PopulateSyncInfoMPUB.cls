public class BatchJob_PopulateSyncInfoMPUB extends BatchJob_PopulateSyncInfo {
    public BatchJob_PopulateSyncInfoMPUB() {
        super();
    }
    public BatchJob_PopulateSyncInfoMPUB(String overrideQuery) {
        super(overrideQuery);
    }

    public void execute(Database.BatchableContext BC, List<ServiceInfo__c> scope) {
        List<ServiceInfo__c> serviceInfosToUpdate = new List<SObject>();

        for (ServiceInfo__c record : scope) {
            String syncInfoStr = record.SyncInfo__c;
            if (shouldBeSkipped(syncInfoStr)) {
                continue;
            }

            record.SyncInfo__c = addStepNamesToSyncInfo(syncInfoStr, record.Quote__r);
            serviceInfosToUpdate.add(record);
        }

        if (!serviceInfosToUpdate.isEmpty()) {
            Triggers.switchOff();
            update serviceInfosToUpdate;
            Triggers.switchOn();
        }
    }

    protected override Database.QueryLocator buildQueryLocator() {
        return new ServiceInfoSelector()
            .newQueryFactory()
            .setFactoryName('selectSyncInfo')
            .withoutSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .selectFields(new Set<String> {
                'Id',
                'SyncInfo__c',
                'Quote__r.Enabled_LBO__c',
                'Quote__r.PackageNameOld__c',
                'Quote__r.IsMultiProductTechnicalQuote__c',
                'Quote__r.Account.RC_User_ID__c',
                'Quote__r.Account.Billing_ID__c',
                'Quote__r.Opportunity.Type',
                'Quote__r.Account.Offer_Type__c'
            })
            .setCondition('Quote__r.Opportunity.IsClosed = true AND Quote__r.Opportunity.StageName = \'7. Closed Won\' AND Quote__r.Opportunity.CloseDate = LAST_N_DAYS:120')
            .executeQueryLocator();
    }
}