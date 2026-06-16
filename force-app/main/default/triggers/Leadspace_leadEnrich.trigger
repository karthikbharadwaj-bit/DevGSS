/*
Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date           Description                                           Tag
--------------------------------------------------------------------------------------------------------------
                    Amravathi       21-Jul-21      Else block to handle enrichment of leads created in async context 
                                                   (Mainly partner leads converted via Future context from 
                                                   Deal Registration Process)                             T1                                
                    Amravathi       23-Jul-21      Check Gating fields prior to enrichment                T2
                    Amravathi       4-Aug-21       Additional domains to be excluded for automation testing T3 
                    Amravathi       6-Aug-21       Invoke enrichment logic using Queuable class
                                                   for partner leads created in future context            T4
                    Amravathi       12-Aug-21      Trigger enrichment on update of key fields (SFDC Updated) T5 
                    Amravathi       17-Aug-21      Exclude leads with specific lead source from LS enrichment T6
                    Amravathi       18-Aug-21      Prevent enrichment when bypass enrichment process setting is ON T7
                    Amravathi       30-Aug-21      Allow LS Enrichment for non-enriched marketo leads T8
                    Amravathi       01-Sep-21      Trigger LS Enrichment irrespective of Gating custom setting T9
                    Amravathi       02-Sep-21      Trigger LS Enrichment when marketo enrichment is null and created by marketo
                    Amravathi       28_Sep-21      Fix Record Read-Only error while invoking Queueable job T11
********************************************************************************************************************
*/
trigger Leadspace_leadEnrich on Lead ( after insert, /*<T2>*/ after update /*</T2>*/) {

    System.debug('StatoLd Leadspace_leadEnrich : ' + Trigger.newMap.size());      
    Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
    if (LSField != null && LSField.Bypass_Leadspace_Trigger__c == true) {
        return;
    }
    Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance(); 
    private List<String> excludedDomains= new List<String>();
    if(processStage.Gating_Excluded_Domains__c!= null) {
        excludedDomains=processStage.Gating_Excluded_Domains__c.split(',');
    } 
    String nonAvayaUsers = System.Label.Non_Avaya_Users;
    String [] listUsers = nonAvayaUsers.split(';');
  
   // Currently Trigger supports only single item
  if(Trigger.newMap.size() == 1 ) {   
      
       Lead leadToEnrich = Trigger.new[0];     
        System.debug('StatoLd Leadspace_leadEnrich2 : ' + leadToEnrich);    
       if(leadToEnrich!=null)
       {
           if (null != leadToEnrich.Email ) {//Enclusion Logic for Email Domains
           for( String excludedDomain : excludedDomains ) {
               if( leadToEnrich.Email.contains(excludedDomain) ) {
                return;
               }
           }
           }        
           if (leadToEnrich.LS_Enrichment_Date__c != null) {//Enclusion Logic for Enrichment Date more than 90 days
               Date startDate = leadToEnrich.LS_Enrichment_Date__c;
               Date endDate = Date.today();
               Integer noOfDays = startDate.daysBetween( endDate );
               System.debug('StatoLd Leadspace_leadEnrich31 : ' + noOfDays);   
           }
           if(leadToEnrich.CreatedById != null && leadToEnrich.CreatedById != listUsers[0] && leadToEnrich.Lead_Entry_Source__c!=null && processStage.Gating_eCommerce_Batch__c != null && leadToEnrich.Lead_Entry_Source__c.contains(processStage.Gating_eCommerce_Batch__c)) {
            return;
           }
       }
      
       /*<T2>*/
       
       System.debug('processStage : ' + processStage);      
       System.debug('leadToEnrich.Systems_Process_Stage__c : ' + leadToEnrich.Systems_Process_Stage__c);       
       System.debug('leadToEnrich.SFDC_updated_via_Enrichment__c : ' + leadToEnrich.SFDC_updated_via_Enrichment__c);
      
       if(Trigger.isUpdate){
          System.debug('Trigger.oldMap : ' + Trigger.oldMap.get(leadToEnrich.Id));
          System.debug('Trigger.oldMap.get(leadToEnrich.Id).Systems_Process_Stage__c : ' + Trigger.oldMap.get(leadToEnrich.Id).Systems_Process_Stage__c);
          System.debug('Trigger.oldMap.get(leadToEnrich.Id).SFDC_updated_via_Enrichment__c : ' + Trigger.oldMap.get(leadToEnrich.Id).SFDC_updated_via_Enrichment__c);
       }
      
       /*<T6>*/
       if(Trigger.isInsert && processStage!=null && processStage.Gating_Lead_Source__c!=null){/*<T9> Removed Bypass Gating check*/
          List<String> excludeLeadSources = processStage.Gating_Lead_Source__c.split(',');
          System.debug('excludeLeadSources : ' + excludeLeadSources);
          if(!excludeLeadSources.isEmpty() && excludeLeadSources.contains(leadToEnrich.LeadSource)){
               return;
          }
       }/*</T6>*/
      
       if(processStage!=null && processStage.Bypass_Enrichment_Process__c == false && /*<T9> Removed Bypass Gating check*/
                                 ((Trigger.isInsert && (processStage.Bypass_Gating_Process_Stage__c || leadToEnrich.Systems_Process_Stage__c == 'SFDC Created' || 
                                  /*<T8>*/(leadToEnrich.Marketo_created_date_time__c != null && leadToEnrich.Marketo_enriched_date_time__c == null)/*</T8>*/)) ||
                                 (Trigger.isUpdate && leadToEnrich.Systems_Process_Stage__c != Trigger.oldMap.get(leadToEnrich.Id).Systems_Process_Stage__c /*<T5>*/ && leadToEnrich.Systems_Process_Stage__c == 'SFDC Updated' && leadToEnrich.SFDC_updated_via_Enrichment__c==true) || (Trigger.isUpdate && processStage.Bypass_Gating_Process_Stage__c && (leadToEnrich.Website != Trigger.oldMap.get(leadToEnrich.Id).Website || leadToEnrich.Company != Trigger.oldMap.get(leadToEnrich.Id).Company || leadToEnrich.Email != Trigger.oldMap.get(leadToEnrich.Id).Email || leadToEnrich.Country != Trigger.oldMap.get(leadToEnrich.Id).Country)))
                                ){
                                    
          
          System.debug('System.isFuture()' + String.valueOf(System.isFuture()));
          System.debug('System.isFunctionCallback()' + String.valueOf(System.isFunctionCallback()));
          System.debug('System.isBatch()' + String.valueOf(System.isBatch()));
                                    
          System.debug(JSON.serialize( leadToEnrich ));
          if(!System.isFuture() && !System.isFunctionCallback() && !System.isBatch()){
             //return;
             system.debug('LeadHandler.sendToEnrich');
             LeadHandler.sendToEnrich( JSON.serialize( leadToEnrich ) );
          }
          /*<T1>*/
          else{
              /*<T4>*/              
              system.debug('LeadspaceEnrichmentQueueable');
              if(Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                    System.enqueueJob(new LeadspaceEnrichmentQueueable(JSON.serialize( leadToEnrich )));/*<T11>*/
              } 
          }/*</T1>*/
       }
   }
   
    
}