// Batch Job for Processing the Records
global class DQ_QuoteStatusTrackingBatch implements Database.Batchable<sObject> {

	//Start Method
	global Database.QueryLocator start(Database.BatchableContext BC) {

        String query = System.Label.DQ_QuoteStatusTrackingBatchQuery;

        return Database.getQueryLocator(query);

    }

	//Execute method
	global void execute(Database.BatchableContext BC, List<Quote> scope) {
        Map<Id,DQ_Quote_Status_Tracker__c> mapOfQuoteIdTOSTatusTracker = new Map<Id,DQ_Quote_Status_Tracker__c>();
        List<DQ_Quote_Status_Tracker__c> listOfDQQuoteStatusToUpsert = new List<DQ_Quote_Status_Tracker__c>();
        
        for(DQ_Quote_Status_Tracker__c objDQQuoteStatus : [SELECT Id, Quote__c FROM DQ_Quote_Status_Tracker__c 
                                                           WHERE Quote__c IN :scope]) {
            mapOfQuoteIdTOSTatusTracker.put(objDQQuoteStatus.Quote__c,objDQQuoteStatus);
        }

        for(Quote objQuote : scope){
             String status = DQ_SubmitQuoteForApproval1.getQuoteApprovalStatus(objQuote.Id);
             if(mapOfQuoteIdTOSTatusTracker != null && mapOfQuoteIdTOSTatusTracker.containsKey(objQuote.id)) {
                 DQ_Quote_Status_Tracker__c objOldTracker = mapOfQuoteIdTOSTatusTracker.get(objQuote.id);
                 objOldTracker.Quote_Status__c = status;
                 listOfDQQuoteStatusToUpsert.add(objOldTracker);
             }
             else {
                 DQ_Quote_Status_Tracker__c objNEWTracker = new DQ_Quote_Status_Tracker__c();
                 objNEWTracker.Quote__c = objQuote.Id;
                 objNEWTracker.Quote_Status__c = status; 
                 listOfDQQuoteStatusToUpsert.add(objNEWTracker);
             }

         }

         upsert listOfDQQuoteStatusToUpsert;

    }   

    // Finish Method
    global void finish(Database.BatchableContext BC) {
    }

}