public without sharing class UpsellInsightsProductUsageData implements IUpsellInsightsProductUsageData{
    
    public Interface IUpsellInsightsProductUsageData{
        List<Upsell_Insights_Product_Usage__c> getUpsellInsightsProductUsages(Id accountId);
    }

    public List<Upsell_Insights_Product_Usage__c> getUpsellInsightsProductUsages(Id accountId){
        List<Upsell_Insights_Product_Usage__c> insights =
            [SELECT Id, Account__c, cc_num_billed_mins__c,
            tf_mins_used__c, year_mo__c,
            cc_config_agents__c, 
            LM_Num_Hosts_Exceeded__c,
            LastModifiedDate
            FROM Upsell_Insights_Product_Usage__c
            WHERE Account__c = :accountId
            ORDER BY year_mo__c DESC];
        return insights;
    }

    public class UpsellInsightsProductUsageDataMock implements IUpsellInsightsProductUsageData {
        public List<Upsell_Insights_Product_Usage__c> insightsToReturn = new List<Upsell_Insights_Product_Usage__c>();

        public List<Upsell_Insights_Product_Usage__c> getUpsellInsightsProductUsages(Id accountId){
            return insightsToReturn;
        }
    }

}