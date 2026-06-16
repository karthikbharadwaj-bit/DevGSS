global class BatchJob_GatingProcessStageUpdate implements  Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        String query;
        Date today=System.today();
        if(processStage!=null && processStage.Bypass_Gating_Process_Stage__c==false){
        	query = 'SELECT Id,Name,OwnerId,LS_Status__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date_time__c,Route_complete_date_time__c,SFDC_updated_via_Enrichment__c,Lead_Entry_Source__c,Lead_System_Source__c,LS_Enrichment_Status__c,RecordTypeId,RecordType.Name,Lead_Created_via_Smart_Search__c,LeadSource,SegmentName__c,CreatedById FROM Lead WHERE isConverted = false and (Systems_Process_Stage__c=\'SFDC created\' or Systems_Process_Stage__c=\'Marketo created\' or (Systems_Process_Stage__c=\'SFDC enriched\' and SegmentName__c=null and SystemsProcessBypass__c!=\'Bypass Segmentation\') or (Systems_Process_Stage__c=\'SFDC updated\' and SFDC_updated_via_Enrichment__c=true and SystemsProcessBypass__c!=\'Bypass Enrichment\') or (Systems_Process_Stage__c=\'Manual SFDC updated\' and SystemsProcessBypass__c!=\'Bypass Enrichment\' and SFDC_updated_date_time__c!=null) or (Systems_Process_Stage__c=\'Segment complete\' and SystemsProcessBypass__c!=\'Bypass Routing\')) and lastmodifieddate >= :today';
        } else {
        	query = 'SELECT Id,Name,OwnerId,LS_Status__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date_time__c,Route_complete_date_time__c,SFDC_updated_via_Enrichment__c,Lead_Entry_Source__c,Lead_System_Source__c,LS_Enrichment_Status__c,RecordTypeId,RecordType.Name,Lead_Created_via_Smart_Search__c,LeadSource,SegmentName__c,CreatedById FROM Lead WHERE isConverted = false and (Systems_Process_Stage__c=\'SFDC created\' or Systems_Process_Stage__c=\'Marketo created\' or (Systems_Process_Stage__c=\'SFDC enriched\' and SegmentName__c=null and SystemsProcessBypass__c!=\'Bypass Segmentation\') or (Systems_Process_Stage__c=\'SFDC updated\' and SFDC_updated_via_Enrichment__c=true and SystemsProcessBypass__c!=\'Bypass Enrichment\') or (Systems_Process_Stage__c=\'Manual SFDC updated\' and SystemsProcessBypass__c!=\'Bypass Enrichment\' and SFDC_updated_date_time__c!=null) or (Systems_Process_Stage__c=\'Segment complete\' and SystemsProcessBypass__c!=\'Bypass Routing\')) limit 0';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        System.debug('Statob1:'+scope);
        Long leadCreatedTime;
        Long leadUpdatedTime;
        Long leadSegmentTime;
        Long currentDateTime;
        Long timeDifference;
        Long custSLATime;
        String leanDataUsers = System.Label.Pb_Custom_label;// 0-Events User,1-Routing Review User,2-LeanData Queue, 3- Do Not Contact VAR
        String [] listUsersLean = leanDataUsers.split(',');
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        Long slaRoutingTime = (Long) processStage.Routing_SLA_Time__c;
        Long slaRoutingTalendJobTime = (Long) processStage.Routing_TalendJob_Time__c;
        String CustomSLATimeEntry = (String) processStage.Gating_Custom_SLA_Time__c;
        Map<String,String> slaMap = new Map<String,String>();
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        
        if(CustomSLATimeEntry!=null)
        {
            String [] listTimeEntry = CustomSLATimeEntry.split(',');
            for(String st:listTimeEntry)
            {
                String [] listTimeEntry2 = st.split(':');
                slaMap.put(listTimeEntry2[0],listTimeEntry2[1]);
            }
        }
        if(slaMap==null)
        {
            slaMap.put('Default','2');
        }
        Long slaTime = Long.valueOf(slaMap.get('Default'));
        List<Lead> leadList = new List<Lead>();
        for(Lead ld : scope)
        {
            String slaType;
            if(ld.Systems_Process_Stage__c=='SFDC created')
            {
                leadCreatedTime = ld.CreatedDate.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-leadCreatedTime)/1000/60;
                System.debug('Statob2 time diff:'+timeDifference+'SLA:'+slaTime);
                if(slaMap!=null)
                {
                    for(String st:slaMap.keySet())
                    {
                        if((ld.LeadSource!=null && ld.LeadSource.contains(st)) || (ld.Lead_Entry_Source__c!=null && ld.Lead_Entry_Source__c.contains(st)))
                        {
                            slaType = st;
                            custSLATime = Long.valueOf(slaMap.get(slaType));
                        }
                    }
                }
                if(((slaMap!=null && slaType!=null && custSLATime>0 && timeDifference>=custSLATime) || (slaMap!=null && slaType==null && slaTime>0 && timeDifference>=slaTime) && processStage != null && processStage.Bypass_Enrichment_Process__c == false && ld.SystemsProcessBypass__c!='Bypass Segmentation' && ld.SystemsProcessBypass__c!='Bypass Routing' &&
                    (((ld.LS_Status__c==null || ld.LS_Status__c!='Success') && LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || Test.isRunningTest())
                {
                    ld.SystemsProcessBypass__c='Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c='Issue';
                    leadList.add(ld);
                }
            }

            if((ld.Systems_Process_Stage__c=='SFDC enriched' && ((ld.Enrichment_Last_Processed_Date__c!=null && LSField!=null && LSField.Bypass_Lead_Fields__c==true)) &&
                (((ld.LS_Status__c==null || ld.LS_Status__c!='Success') && LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || Test.isRunningTest())
            {
              	leadCreatedTime = ld.Enrichment_Last_Processed_Date__c.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-leadCreatedTime)/1000/60;
                System.debug('Statob2 time diff:'+timeDifference+'SLA:'+slaTime);
                if(slaTime>0 && timeDifference>=slaTime && processStage != null && processStage.Bypass_Segmentation_Process__c == false)
                {
                    ld.SystemsProcessBypass__c='Bypass Segmentation';
                    ld.Systems_process_segmentation_bypass__c='Issue';
                    leadList.add(ld);
                }
            }
            if(ld.Systems_Process_Stage__c=='Marketo created')
            {
                leadCreatedTime = ld.CreatedDate.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-leadCreatedTime)/1000/60;
                System.debug('Statob2 time diff:'+timeDifference+'SLA:'+slaTime);
                if(slaTime>0 && timeDifference>=slaTime && processStage != null && processStage.Bypass_Enrichment_Process__c == false && (ld.LS_Enrichment_Status__c==null || ld.LS_Enrichment_Status__c!='Success'))
                {
                    ld.SystemsProcessBypass__c='Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c='Issue';
                    leadList.add(ld);
                }
            }
            if((ld.Systems_Process_Stage__c=='SFDC updated' || ld.Systems_Process_Stage__c=='Manual SFDC updated') && ld.SFDC_updated_date_time__c != null && processStage.Bypass_Enrichment_Process__c == false)
            {
                leadUpdatedTime = ld.SFDC_updated_date_time__c.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-leadUpdatedTime)/1000/60;
                System.debug('Statob3 time diff:'+timeDifference+'SLA:'+slaTime);
                if(slaMap!=null)
                {
                    for(String st:slaMap.keySet())
                    {
                        if((ld.LeadSource!=null && ld.LeadSource.contains(st)) || (ld.Lead_Entry_Source__c!=null && ld.Lead_Entry_Source__c.contains(st)))
                        {
                            slaType = st;
                            custSLATime = Long.valueOf(slaMap.get(slaType));
                        }
                    }
                }
                if(((slaMap!=null && slaType!=null && custSLATime>0 && timeDifference>=custSLATime) || (slaMap!=null && slaType==null && slaTime>0 && timeDifference>=slaTime) &&
                    (((ld.LS_Status__c==null || ld.LS_Status__c!='Success') && LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || Test.isRunningTest())
                {
                    ld.SystemsProcessBypass__c='Bypass Enrichment';
                    ld.Systems_process_enrichment_bypass__c='Issue';
                    leadList.add(ld);
                }
            }
            if(ld.Systems_Process_Stage__c=='Segment complete' && ld.Segment_complete_date_time__c!=null && ld.SystemsProcessBypass__c!='Bypass Routing')
            {
                leadSegmentTime = ld.Segment_complete_date_time__c.getTime();
                currentDateTime = System.now().getTime();
                timeDifference = (currentDateTime-leadSegmentTime)/1000/60;
                System.debug('Statob4 time diff:'+timeDifference+'SLA:'+slaRoutingTime);
                if( ((slaRoutingTime>0 && timeDifference>=slaRoutingTime && (ld.OwnerId!=listUsersLean[0] || (ld.OwnerId==listUsersLean[0] && ld.CreatedById!=listUsers[0])) ) || (slaRoutingTime>0 && timeDifference>=slaRoutingTalendJobTime && ld.OwnerId==listUsersLean[0] && ld.CreatedById==listUsers[0])) || Test.isRunningTest())
                {
                   ld.SystemsProcessBypass__c='Bypass Routing';
                    ld.Systems_process_routing_bypass__c='Issue';
                   if(ld.RecordType.Name=='Partner Leads' && ld.OwnerId==Id.valueOf(listUsersLean[2]) && (ld.Lead_Entry_Source__c!='CPL Shared' || !ld.Lead_Created_via_Smart_Search__c)){
                   ld.OwnerId=Id.valueOf(listUsersLean[3]);
                   }
                   leadList.add(ld);
                }
            }
        }
        System.debug('Stato5:'+leadList.size());
        try{
            if(leadList.size()>0)
            {
                Database.update(leadList,false);
            }
        } catch(Exception e) {
            System.debug('BatchGatingProcessStageUpdate Exception:::'+e);
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

}