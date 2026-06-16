//Ankit Sharma 	12/11/2020	Create sharing records for Integration partner quote
//included Primary_Partner_Quote__c changes for PRM-15
trigger PartnerQuoteTrigger on Partner_Quote__c (after insert,after update) {
    List<Opportunity> listOfOppToUpdate = new List<Opportunity>();
    
    if (Trigger.isInsert) {
        Set<Id> setOfIntegrationQuoteIds = new Set<Id>();        
        for(Partner_Quote__c objQuote : trigger.new) {
            if(objQuote.Integration_Quote__c) {
                setOfIntegrationQuoteIds.add(objQuote.Id);
            }
            if(objQuote.Primary__c){
                Opportunity oppToUpdate = new Opportunity();
                oppToUpdate.ID = objQuote.Opportunity__c;
                oppToUpdate.Primary_Partner_Quote__c = objQuote.Id;
                listOfOppToUpdate.add(oppToUpdate);                
            }
        }
        
        Database.update(listOfOppToUpdate);
        
        if(!setOfIntegrationQuoteIds.isEmpty()) {
            Quote_SharingHandler.handlePartnerQuoteSharing(setOfIntegrationQuoteIds);
        }
    }
    
    if (Trigger.isUpdate) {
        for(Partner_Quote__c objQuote : trigger.new) {
            Partner_Quote__c oldQuote = (Partner_Quote__c)Trigger.oldMap.get(objQuote.ID);
            if(objQuote.Primary__c != oldQuote.Primary__c){
                if(objQuote.Primary__c){
                    Opportunity oppToUpdate = new Opportunity();
                    oppToUpdate.ID = objQuote.Opportunity__c;
                    oppToUpdate.Primary_Partner_Quote__c = objQuote.Id;
                    listOfOppToUpdate.add(oppToUpdate); 
                }else if(!objQuote.Primary__c){
                    Opportunity oppToUpdate = new Opportunity();
                    oppToUpdate.ID = objQuote.Opportunity__c;
                    oppToUpdate.Primary_Partner_Quote__c = null;
                    listOfOppToUpdate.add(oppToUpdate);
                }
            }
        }
        Database.update(listOfOppToUpdate);
    }    
}