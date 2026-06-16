public with sharing class DemandFunnelComponentController {

    @AuraEnabled
    public static List<Demand_Funnel__c> getRelatedDFRs(String objectId) {
        DemandFunnelSelector dfrSelector = new DemandFunnelSelector();
        return (List<Demand_Funnel__c>) dfrSelector.selectDFRForRelatedList(new List<Object>{ objectId }).executeQuery();
    }

}