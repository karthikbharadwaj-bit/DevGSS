public class LeadspaceEnrichmentQueueable implements Queueable,Database.AllowsCallouts{
    
    public Lead leadToEnrich { get; set;}
    
    public LeadspaceEnrichmentQueueable(String jsonSerializedLead){
        this.leadToEnrich = (Lead)JSON.deserialize(jsonSerializedLead, Lead.class); 
        /*28/Sep/21 - Pass serialized lead record to avoid Record read only error*/
    }
    
    public void execute(QueueableContext context) { 
        
        /*New logic - 6/Aug/21 - Invoke enrichment logic for partner leads created in future context*/
        
        /*Populate Leadspace_Request_Date__c prior to enrichment - Starts*/
        /*leadToEnrich.Leadspace_Request_Date__c = Datetime.now();
        
        TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        update leadToEnrich;
        TriggerHandler.BY_PASS_LEAD_UPDATE = false;*/
        /*Populate Leadspace_Request_Date__c prior to enrichment - Ends*/
        
        /*try{
            leadspacesync.API.EnrichResults enrichResult;
            enrichResult = new leadspacesync.API.EnrichResults();
            if ( !Test.isRunningTest() ) {
                enrichResult = leadspacesync.API.getEnrichedObject(leadToEnrich);
            }        
            
            if( enrichResult.items.size() == 1 && null !=  enrichResult.items[0] ) {             
                Database.SaveResult[] updateResults = Database.update(enrichResult.items);
            }
            else {
                String enrichmentErrorMsg = enrichResult.message;
                System.debug('Enrichment Error: '+enrichmentErrorMsg );
            }
        }catch(Exception ex){
            System.debug('Error during LeadspaceEnrichmentQueueable - ' + ex.getMessage());
        }*/        
    }
}