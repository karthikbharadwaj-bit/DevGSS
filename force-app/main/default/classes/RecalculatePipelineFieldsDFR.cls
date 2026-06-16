public with sharing class RecalculatePipelineFieldsDFR implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        String currencyUSD = 'USD';
        Date lastCreatedDate;
        Date lastDate;
        List<DatedConversionRate> dcrs = new DatedConversionRateSelector()
            .selectLatestConversionsRates()
            .executeQuery();
        if (Test.IsRunningTest()) {
            lastDate = System.Today();
        } else {
            lastDate = dcrs[0].startDate;
        }   
        return Database.getQueryLocator('SELECT Id,CloseDate, Estimated_12M_Total_Pipeline__c, X12_Month_Booking__c, Amount, CurrencyIsoCode FROM Opportunity WHERE CurrencyIsoCode != :currencyUSD AND CloseDate >= :lastDate');
    }
    
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        DG_DFR_Class.DFR_OpportunityPipelineRecalculation(scope);
    }
    
    public void finish(Database.BatchableContext context) {
    }
    
}