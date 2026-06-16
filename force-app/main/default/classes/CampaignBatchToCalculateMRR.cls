global class CampaignBatchToCalculateMRR implements Database.Batchable<sObject>,
                                                    Schedulable, Database.Stateful {
    @TestVisible protected SaveResultWrapper[] databaseResults = new SaveResultWrapper[]{};
    private Integer batchSizeLimit = null;
    protected Integer chunkSizeLimit = null;
    protected String errorEmailDistributionList = null;
    String qry = '';
    Map<Id, Campaign> campaignIdsToCampaign = new Map<Id, Campaign>();
    
    global String getBatchJobClassName(){
        return 'CampaignBatchToCalculateMRR';
    }

    global void bypassTriggers(Boolean bypass) {
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = bypass;
        if (bypass) {
            Triggers.switchOff();
        } else {
            Triggers.switchOn();
        }
    }
    
    global CampaignBatchToCalculateMRR () {
        BatchJobsConfiguration__c configForBatchJob = BatchJobsConfiguration__c.getValues(getBatchJobClassName());
        chunkSizeLimit = 200;
        if (configForBatchJob != null) {
            batchSizeLimit = (Integer) configForBatchJob.BatchSizeLimit__c;
            if (configForBatchJob.ChunkSizeLimit__c != null) {
                chunkSizeLimit = (Integer) configForBatchJob.ChunkSizeLimit__c;
            }
            errorEmailDistributionList = configForBatchJob.ErrorEmailDistributionList__c;
        }
        qry = getQuery();
    }


    global Database.QueryLocator start(Database.BatchableContext BC) {
        for (Campaign camp : [SELECT Id, Total_Actual_12_Month_Booking_hidden__c,
                              Total_Estimated_12_Month_Booking_hidden__c
                              FROM Campaign
                              WHERE ID IN (SELECT CampaignId FROM Opportunity)
                              ORDER BY Id DESC]) {
            campaignIdsToCampaign.put(camp.Id, camp);    
            camp.Total_Actual_12_Month_Booking_hidden__c = 0;
            camp.Total_Estimated_12_Month_Booking_hidden__c = 0;
        }
        return Database.getQueryLocator(qry);
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new CampaignBatchToCalculateMRR(), chunkSizeLimit);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> oppList = (List<Opportunity>) scope;
        Map<Id, List<Opportunity>> campaignIdToOpportunity = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : oppList) {
            if (campaignIdToOpportunity.get(opp.CampaignId) == null) {
                List<Opportunity> tempList = new List<Opportunity>{opp};
                campaignIdToOpportunity.put(opp.CampaignId, tempList);
            } else{
                campaignIdToOpportunity.get(opp.CampaignId).add(opp);
            }
        }
        
        for(Id campaignId : campaignIdToOpportunity.keyset()) {
            Campaign camp = campaignIdsToCampaign.get(campaignId);
            for(Opportunity opp : campaignIdToOpportunity.get(campaignId)) {
                
                camp.Total_Estimated_12_Month_Booking_hidden__c += opp.X12_Month_Booking__c == null? 0
                                                                                    : (double)opp.X12_Month_Booking__c;
            }
            
        }
    }

    global void finish(Database.BatchableContext BC) {

        try {
            bypassTriggers(true);
            Database.update(campaignIdsToCampaign.values(), false);
            bypassTriggers(false);
        } catch (Exception e) {
            PlatformLog.logException(getBatchJobClassName(), e);
            
        }
    }

    private String getQuery() {
      return 'SELECT Id, CampaignId, convertCurrency(X12_Month_Booking__c) FROM Opportunity ' +
             'WHERE CampaignId != NULL';
    }
}