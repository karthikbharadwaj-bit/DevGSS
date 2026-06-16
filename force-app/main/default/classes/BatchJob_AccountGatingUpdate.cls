global class BatchJob_AccountGatingUpdate implements  Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        String query;
        Date today=System.today();
        if(processStage!=null && processStage.Bypass_Account_Gating_Process__c==false){
        	query = 'SELECT Id,Name,OwnerId,LS_Status__c,Systems_process_stage__c,Systems_process_enrichment_bypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date__c,RecordTypeId,RecordType.Name,Segment_Name__c,CreatedById,SFDC_Enriched_Date_time__c FROM Account WHERE (Systems_process_stage__c=\'SFDC Created\' or Systems_Process_Stage__c=\'Marketo Created\' or (Systems_process_stage__c=\'SFDC Enriched\' and Segment_Name__c=null) or (Systems_process_stage__c=\'SFDC Updated\' and SFDC_updated_date_time__c!= null) or (Systems_process_stage__c=\'Manual SFDC Updated\' and SFDC_updated_date_time__c!= null) or (Systems_process_stage__c=\'SFDC Enriched\' and Segment_Name__c!= null)) and lastmodifieddate >= :today';
        } else {
        	query = 'SELECT Id,Name,OwnerId,LS_Status__c,Systems_process_stage__c,Systems_process_enrichment_bypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date__c,RecordTypeId,RecordType.Name,Segment_Name__c,CreatedById,SFDC_Enriched_Date_time__c FROM Account WHERE (Systems_process_stage__c=\'SFDC Created\' or Systems_Process_Stage__c=\'Marketo Created\' or (Systems_process_stage__c=\'SFDC Enriched\' and Segment_Name__c=null) or (Systems_process_stage__c=\'SFDC Updated\' and SFDC_updated_date_time__c!= null) or (Systems_process_stage__c=\'Manual SFDC Updated\' and SFDC_updated_date_time__c!= null) or (Systems_process_stage__c=\'SFDC Enriched\' and Segment_Name__c!= null)) limit 0';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        System.debug('Statob1:'+scope);
        Long accountCreatedTime;
    	Long accountUpdatedTime;
    	Long accountEnrichedTime;
    	Long currentDateTime;
        Long timeDifference;
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        Long accountEnrichmentTime = (Long) processStage.Account_Gating_Enrichment_SLA__c;
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        List<Account> accList = new List<Account>();
        for(Account acc : scope)
        {
            String slaType;
            if(acc.Systems_Process_Stage__c=='SFDC Created')
            {
              	accountCreatedTime = acc.CreatedDate.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-accountCreatedTime)/1000/60;
                System.debug('Statob2 time diff:'+timeDifference+'SLA:'+accountEnrichmentTime);
                if(((accountEnrichmentTime>0 && timeDifference>=accountEnrichmentTime) && processStage != null && processStage.Bypass_Enrichment_Process__c == false &&
                    (((acc.LS_Status__c==null || acc.LS_Status__c!='Success') && LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || Test.isRunningTest())
                {
                    acc.Systems_process_enrichment_bypass__c='Issue'; 
                    accList.add(acc);
                }
            }
            if(acc.Systems_Process_Stage__c=='SFDC Updated' || acc.Systems_Process_Stage__c=='Manual SFDC Updated')
            {
              	accountUpdatedTime = acc.SFDC_updated_date_time__c.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-accountUpdatedTime)/1000/60;
                System.debug('Statob3 time diff:'+timeDifference+'SLA:'+accountEnrichmentTime);
                if(((accountEnrichmentTime>0 && timeDifference>=accountEnrichmentTime) && processStage != null && processStage.Bypass_Enrichment_Process__c == false &&
                    (((acc.LS_Status__c==null || acc.LS_Status__c!='Success') && LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || Test.isRunningTest())
                {
                    acc.Systems_process_enrichment_bypass__c='Issue'; 
                    accList.add(acc);
                }
            }
            if(acc.Systems_Process_Stage__c=='SFDC Enriched')
            {
              	accountEnrichedTime = acc.SFDC_Enriched_Date_time__c.getTime();
                System.debug('Statob4 account enriched time:'+accountEnrichedTime);
                if(((accountUpdatedTime>0) && processStage != null && processStage.Bypass_Enrichment_Process__c == false &&
                    ((LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || Test.isRunningTest())
                {
                    acc.Systems_process_stage__c = 'Segment Complete'; 
                    accList.add(acc);
                }
            }
        }
        System.debug('Stato5:'+accList.size());
        try{
            if(accList.size()>0)
            {
                Database.update(accList,false);
            }
        } catch(Exception e) {
            System.debug('BatchJob_AccountGatingUpdate Exception:::'+e);
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

}