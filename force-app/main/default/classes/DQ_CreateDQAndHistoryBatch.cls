// Batch Job for Processing the Records
global class DQ_CreateDQAndHistoryBatch implements Database.Batchable<sObject> {

// Start Method

    global Database.QueryLocator start(Database.BatchableContext BC) {

        String query = System.Label.DQ_CreateDQAndHistoryBatchQuery;
        //String quoteId = '0Q0P0000000F812';
        if(Test.isRunningTest()){
			query = 'SELECT Id FROM Quote';
        }
        return Database.getQueryLocator(query);

    }

   // Execute method

    global void execute(Database.BatchableContext BC, List<Quote> scope) {
        //System.assert(false,scope);
        List<DQ_Deal_Qualification__c> listOfDQToUpsert = new List<DQ_Deal_Qualification__c>();
        for(Quote objQuote : scope)
		{
            try{
                String dqID = DQ_SubmitQuoteForApproval1.submitQuteForApprovalBatchMethod(null,new set<Id>{objQuote.Id},false);
                if(dqID != null && dqID != '') {
                    DQ_Deal_Qualification__c objDQDeal = new DQ_Deal_Qualification__c(Id = dqID, Status__c = 'Approved');
                    listOfDQToUpsert.add(objDQDeal);
                }
            }
            catch(Exception ex) {
                system.debug('errro>>>>'+ex);
            }
         }
		 
        //System.assert(false,listOfDQToUpsert);
         upsert listOfDQToUpsert;

    }   

    // Finish Method

    global void finish(Database.BatchableContext BC) {

    }

}