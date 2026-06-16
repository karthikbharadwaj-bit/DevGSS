global class BatchJob_GatingSegmentationUpdate implements  Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        String query;
        Date today=System.today()-1;
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        String qtr = listUsers[0];
        if(processStage!=null && processStage.Bypass_Gating_Process_Stage__c==false && !Test.isRunningTest()){
        	query = 'SELECT Id,Name,LS_Status__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date_time__c,ZI_CDP_Account_Id__c,Ultimate_SM_Country__c,SM_Country__c,SM_Employees__c,SegmentName__c,Marketo_Segment_Name__c,SFDC_enriched_date_time__c,CreatedById,isConverted,Emp_Range_Sales_Override__c,SFDC_updated_via_Enrichment__c,Marketo_enriched_date_time__c FROM Lead WHERE isConverted = false and ((SystemsProcessBypass__c=\'Bypass Enrichment\' and (Systems_Process_Stage__c=\'SFDC created\' or Systems_Process_Stage__c=\'Marketo created\')) or ( LS_Status__c=\'Success\' and Systems_Process_Stage__c=\'SFDC enriched\') or (Marketo_enriched_date_time__c!=null and Systems_Process_Stage__c=\'Marketo enriched\') or (CreatedById=:qtr and SFDC_enriched_date_time__c=null and Enrichment_Last_Processed_Date__c != null) or (Systems_Process_Stage__c=\'SFDC updated\' and (SystemsProcessBypass__c=\'Bypass Enrichment\' or SFDC_updated_via_Enrichment__c=false))) and lastmodifieddate >= :today';
        } else if(processStage!=null && processStage.Bypass_Gating_Process_Stage__c==false && Test.isRunningTest()) {
        	query = 'SELECT Id,Name,LS_Status__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date_time__c,ZI_CDP_Account_Id__c,Ultimate_SM_Country__c,SM_Country__c,SM_Employees__c,SegmentName__c,Marketo_Segment_Name__c,SFDC_enriched_date_time__c,CreatedById,isConverted,Emp_Range_Sales_Override__c,SFDC_updated_via_Enrichment__c,Marketo_enriched_date_time__c FROM Lead WHERE isConverted = false and ((LS_Status__c=\'Success\' and SegmentName__c=null and Systems_Process_Stage__c=\'SFDC enriched\') or (SFDC_enriched_date_time__c=null and Enrichment_Last_Processed_Date__c != null) or (SegmentName__c=null and Systems_Process_Stage__c=\'SFDC created\' and SystemsProcessBypass__c=\'Bypass Enrichment\') or (Systems_Process_Stage__c=\'SFDC updated\' and (SystemsProcessBypass__c=\'Bypass Enrichment\' or SFDC_updated_via_Enrichment__c=false))) and lastmodifieddate >= :today';
        } else{
        	query = 'SELECT Id,Name,LS_Status__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Enrichment_Last_Processed_Date__c,CreatedDate,SFDC_updated_date_time__c,Segment_complete_date_time__c,ZI_CDP_Account_Id__c,Ultimate_SM_Country__c,SM_Country__c,SM_Employees__c,SegmentName__c,Marketo_Segment_Name__c,SFDC_enriched_date_time__c,CreatedById,isConverted,Emp_Range_Sales_Override__c,SFDC_updated_via_Enrichment__c,Marketo_enriched_date_time__c FROM Lead WHERE isConverted = false and ((SystemsProcessBypass__c=\'Bypass Enrichment\' and (Systems_Process_Stage__c=\'SFDC created\' or Systems_Process_Stage__c=\'Marketo created\')) or (LS_Status__c=\'Success\' and Systems_Process_Stage__c=\'SFDC enriched\') or (Marketo_enriched_date_time__c!=null and Systems_Process_Stage__c=\'Marketo enriched\') or (CreatedById=:qtr and SFDC_enriched_date_time__c=null and Enrichment_Last_Processed_Date__c != null) or (Systems_Process_Stage__c=\'SFDC updated\' and (SystemsProcessBypass__c=\'Bypass Enrichment\' or SFDC_updated_via_Enrichment__c=false))) limit 0';  
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        System.debug('StatoBatchSeg1:'+scope.size());
        Set<String> setCountryNames = new Set<String>();
        Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
        Map<String,List<Segment_Master__c>> mapCountryNameNLstSegmentMasters = new Map<String,List<Segment_Master__c>>();
        String ROWCountryName = 'ROW';
        String SMCountryName = '';
		Decimal SMEmployees;
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        List<Lead> leadList = new List<Lead>();
        List<Lead> leadListCdp = new List<Lead>();
        List<Lead> leadList2 = new List<Lead>();
        List<Lead> leadList3 = new List<Lead>();
        List<Lead> leadList4 = new List<Lead>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Map<Id,String> mapUltimateSMCountry = new Map<Id,String>();
        Map<Id,Double> mapUltimateSMEmp = new Map<Id,Double>();
        Map<Id,String> mapUltimateSegmentName = new Map<Id,String>();
        Map<Id,String> mapUltimateMarketoSegmentName = new Map<Id,String>();
        Leadspace_field_bypass__c LSField = Leadspace_field_bypass__c.getInstance();
        for(Lead ld : scope) 
        {
            if(( ( (ld.Systems_Process_Stage__c=='SFDC created' || ld.Systems_Process_Stage__c=='Marketo created')  && ld.SystemsProcessBypass__c=='Bypass Enrichment') || 
                (ld.Systems_Process_Stage__c=='SFDC enriched' && ((ld.LS_Status__c=='Success' && LSField!=null && LSField.Bypass_Lead_Fields__c==true))) || 
                (ld.Systems_Process_Stage__c=='Marketo enriched' && ld.Marketo_enriched_date_time__c!=null) || (ld.Systems_Process_Stage__c=='SFDC updated' && (ld.SystemsProcessBypass__c=='Bypass Enrichment' || ld.SFDC_updated_via_Enrichment__c==false) )) || Test.isRunningTest())
            {              
                if(ld.ZI_CDP_Account_Id__c == null && ld.SM_Country__c != null && ld.SM_Employees__c != null)
                {
                    setCountryNames.add(ld.SM_Country__c);
                    setEmployeeNumbers.add(ld.SM_Employees__c);
                    leadList.add(ld);
                }
                else if(ld.ZI_CDP_Account_Id__c != null && ld.Emp_Range_Sales_Override__c == null)
                {
                    accountIds.add(ld.ZI_CDP_Account_Id__c);
                    leadIds.add(ld.Id);
                    leadListCdp.add(ld);
                }                
            }
            else if(ld.CreatedById==listUsers[0] && ld.SFDC_enriched_date_time__c==null && ((ld.Enrichment_Last_Processed_Date__c!=null && LSField!=null && LSField.Bypass_Lead_Fields__c==true)) && 
                    ((ld.LS_Status__c=='Success' && LSField!=null && LSField.Bypass_Lead_Fields__c==true)))
            {
                ld.SFDC_enriched_date_time__c=ld.Enrichment_Last_Processed_Date__c;
                leadList2.add(ld);
            }
        }
        System.debug('StatoBatchSeg2:'+setCountryNames+setEmployeeNumbers);
        System.debug('StatoBatchSeg3:'+leadList.size()+leadList2.size());
        if(setCountryNames.size()>0 && setEmployeeNumbers.size()>0 && leadList.size()>0)//Logic for Segment calculation for 1.Leads without ZI CDp Account Starts
        {            
        List<Segment_Master__c> segmentMasterList = [SELECT Id, Country__c, Max__c, Min__c, Name FROM Segment_Master__c where (Country__c in :setCountryNames or Country__c =: ROWCountryName) AND Min__c <= :setEmployeeNumbers AND Max__c >= :setEmployeeNumbers AND Active__c = true];
        for(Segment_Master__c sm:segmentMasterList)
        {
            if(mapCountryNameNLstSegmentMasters.containskey(sm.country__c))
            {
                mapCountryNameNLstSegmentMasters.get(sm.country__c).add(sm);
            }
            else
            {
                mapCountryNameNLstSegmentMasters.put(sm.country__c,new List<Segment_Master__c> {sm});
            }
        }
        System.debug('StatoBatchSeg4:'+mapCountryNameNLstSegmentMasters);            
        for(Lead ld:leadList)
        {     
            System.debug('StatoBatchSeg5:'+ld);
            if(ld.SM_Country__c != null && ld.SM_Employees__c != null && ld.isConverted == false)
            {
                if(ld.ZI_CDP_Account_Id__c!=null && mapCountryNameNLstSegmentMasters.containskey(ld.Ultimate_SM_Country__c))
                {
                    SMCountryName = ld.Ultimate_SM_Country__c;
                }
                else if(mapCountryNameNLstSegmentMasters.containskey(ld.SM_Country__c))
                {
                    SMCountryName = ld.SM_Country__c;
                }
                else
                {
                    SMCountryName = ROWCountryName;
                }
                if(ld.ZI_CDP_Account_Id__c!=null && ld.Ultimate_SM_Employees__c!=null && ld.Ultimate_SM_Employees__c > 1 && ld.Emp_Range_Sales_Override__c == null)
                {
                    SMEmployees=ld.Ultimate_SM_Employees__c;
                }
                else
                {
                    SMEmployees=ld.SM_Employees__c;
                }
                if(mapCountryNameNLstSegmentMasters.containskey(SMCountryName))
                {
                    for(Segment_Master__c sm : (List<Segment_Master__c>) mapCountryNameNLstSegmentMasters.get(SMCountryName))
                    {
                        if(sm.Country__c != null && sm.Min__c != null && sm.Max__c!= null && SMEmployees != null && sm.Max__c >= SMEmployees && sm.Min__c <= SMEmployees)
                        {
                            if(ld.SegmentName__c != sm.Id)
                            {
                                ld.SegmentName__c = sm.Id;
                            }
                            if(ld.Marketo_Segment_Name__c != sm.Name)
                            {
                                ld.Marketo_Segment_Name__c = sm.Name;
                            }
                            System.debug('StatoBatchSeg3:'+ld.Systems_Process_Stage__c+ld.SystemsProcessBypass__c);
                            if((processStage != null && processStage.Bypass_Gating_Process_Stage__c == false) || (processStage != null && processStage.Bypass_Enrichment_Process__c == true && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete')){
                                ld.Systems_Process_Stage__c='Segment complete';        
                                if(ld.SystemsProcessBypass__c=='Bypass Segmentation')
                                {
                                    ld.SystemsProcessBypass__c=null;
                                }                                
                            }
                            ld.Segment_complete_date_time__c=System.now();
                        }
                    }
                }
            }
            leadList3.add(ld);
        }
        }//Logic for Segment calculation for 1.Leads without ZI CDp Account ends
        System.debug('UltimateStatoU4:'+accountIds+'LeadIds:'+leadIds);//Logic for Segment calculation for 2.Leads with ZI CDp Account starts
        if(accountIds.size()>0)
        {                    
            for(Account acc : [select id,Name,Ultimate_Account__c,Ultimate_Account__r.SM_Country__c,Ultimate_Account__r.SM_Employees__c,Ultimate_Account__r.Segment_Name__c,Ultimate_Account__r.Marketo_Segment_Name__c,SM_Country__c,SM_Employees__c,Segment_Name__c,Marketo_Segment_Name__c from account where Id in:accountIds])
            {
                if(acc.Ultimate_Account__c != null)
                {
                    mapUltimateSMCountry.put(acc.Id,acc.Ultimate_Account__r.SM_Country__c);
                    mapUltimateSMEmp.put(acc.Id,acc.Ultimate_Account__r.SM_Employees__c);
                    mapUltimateSegmentName.put(acc.Id,acc.Ultimate_Account__r.Segment_Name__c);
                    mapUltimateMarketoSegmentName.put(acc.Id,acc.Ultimate_Account__r.Marketo_Segment_Name__c);
                }
                else
                {
                    mapUltimateSMCountry.put(acc.Id,acc.SM_Country__c);
                    mapUltimateSMEmp.put(acc.Id,acc.SM_Employees__c);
                    mapUltimateSegmentName.put(acc.Id,acc.Segment_Name__c);
                    mapUltimateMarketoSegmentName.put(acc.Id,acc.Marketo_Segment_Name__c);
                }
            }
            System.debug('UltimateStatoU5:'+mapUltimateSMCountry+mapUltimateSMEmp);
            System.debug('UltimateStatoU6:'+mapUltimateSegmentName+mapUltimateMarketoSegmentName);
        }
        if(accountIds.size()>0 && mapUltimateSMCountry!=null && mapUltimateSMEmp!=null && mapUltimateSegmentName!=null && mapUltimateMarketoSegmentName!=null)
        {                    
            for (Lead ld : leadListCdp)
            {
                System.debug('UltimateStatoU8:'+ld);
                if(ld.ZI_CDP_Account_Id__c != null)
                {
                    if(mapUltimateSMCountry!=null && mapUltimateSMCountry.containskey(ld.ZI_CDP_Account_Id__c))
                    {
                        ld.Ultimate_SM_Country__c = mapUltimateSMCountry.get(ld.ZI_CDP_Account_Id__c);
                    }
                    if(mapUltimateSMEmp!=null && mapUltimateSMEmp.containskey(ld.ZI_CDP_Account_Id__c))
                    {
                        ld.Ultimate_SM_Employees__c = mapUltimateSMEmp.get(ld.ZI_CDP_Account_Id__c);
                    }
                    if(mapUltimateSegmentName!=null && mapUltimateSegmentName.containskey(ld.ZI_CDP_Account_Id__c))
                    {
                        ld.SegmentName__c = mapUltimateSegmentName.get(ld.ZI_CDP_Account_Id__c);
                    }
                    if(mapUltimateMarketoSegmentName!=null && mapUltimateMarketoSegmentName.containskey(ld.ZI_CDP_Account_Id__c))
                    {
                        ld.Marketo_Segment_Name__c = mapUltimateMarketoSegmentName.get(ld.ZI_CDP_Account_Id__c);
                    }//CMR-224923:E2EStaging - Lead Refactoring & Customer Data Updates ends
                    if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete'){
                        ld.Systems_Process_Stage__c='Segment complete';
                        if(ld.SystemsProcessBypass__c=='Bypass Segmentation')
                        {
                            ld.SystemsProcessBypass__c=null;
                        }
                    }
                    ld.Segment_complete_date_time__c=System.now();
                }
                leadList4.add(ld);
            }
        }//Logic for Segment calculation for 2.Leads with ZI CDp Account ends
        System.debug('StatoBatchSeg4:'+leadList2.size()+leadList3.size()+leadList4.size());
        try{
            if(leadList2.size()>0)
            {
                 Database.update(leadList2,false);
            }
            if(leadList3.size()>0)
            {
                 Database.update(leadList3,false);
            }
            if(leadList4.size()>0)
            {
                 Database.update(leadList4,false);
            }
        } catch(Exception e) {
            System.debug('BatchJob_GatingSegmentationUpdate Exception:::'+e);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
}