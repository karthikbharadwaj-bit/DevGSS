global class Quote_SharingBatch implements Database.Batchable<sObject>{

	global final String query;
   	global final String objectName;
    
   	global Quote_SharingBatch(String query, String objectName){
   		this.query = query;
        this.objectName = objectName;
   	}

   	global Database.QueryLocator start(Database.BatchableContext BC){
   		return Database.getQueryLocator(query);
   	}

   	global void execute(Database.BatchableContext BC, List<SObject> listOfRecords){
        Set<Id> setOfRecordIds = new Set<Id>();
        if(objectName != 'Partner_Quote__c'){
            for(SObject eachRecord : listOfRecords){
                setOfRecordIds.add(eachRecord.Id);
            }
        }
        if(objectName == 'Account'){
            Sharing_AccountLeadHandler.handleAccountShare(setOfRecordIds);
        } 	
        else if(objectName == 'Deal_Support__c'){
            Quote_SharingHandler.handleDealSupportShare(setOfRecordIds);
        } 	
        else if(objectName == 'Partner_Quote__c'){
            //Partner quote logic handles one record at a time
            for(SObject eachRecord : listOfRecords){
     			Quote_SharingHandler.handlePartnerQuoteSharing(eachRecord.Id);
            }
        } 	
        else if(objectName == 'Deal_Registration__c '){
            Quote_SharingHandler.handleDealRegistrationShare(setOfRecordIds);
        } 	
        else if(objectName == 'Lead'){
            Sharing_AccountLeadHandler.handleLeadShare(setOfRecordIds);
        } 	
        else if(objectName == 'Existing Lead'){
            Sharing_AccountLeadHandler.handleExistingLeadShare(setOfRecordIds);
        } 	
        
    }

   	global void finish(Database.BatchableContext BC){
   	}
}