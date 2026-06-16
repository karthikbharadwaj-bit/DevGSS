public with sharing class ForecastNotCountedMsgController {
   public class ResponseWrapper {
        public Boolean isDisplayMessage;
        public Opportunity opp;

        public ResponseWrapper(Boolean isDisplayMessage, Opportunity opp) {
            this.isDisplayMessage = isDisplayMessage;
            this.opp = opp;
        }
    }

    @AuraEnabled
    public static String getData(Id oppId) {
        try {
            Opportunity opp = [SELECT StageName, Brand_Name__c, Type FROM Opportunity WHERE Id = :oppId];
            Boolean isDisplayMessage = !QuoteHelper.isQuotingAvailableForBrand(opp.Brand_Name__c, opp.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)
                && OpportunityHelper.STAGE_NAMES_NO_FORECASTING_REPORTS.contains(opp.StageName);

            return JSON.serialize(new ResponseWrapper(isDisplayMessage, opp));
        } catch (Exception e) {
            return null;
        }
    }
}