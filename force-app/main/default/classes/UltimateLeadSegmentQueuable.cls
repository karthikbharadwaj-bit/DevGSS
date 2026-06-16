/*
* Description   : Apex class for populating Ultimate Account - Invoked from AccountTriggerHandler
* Test Class : Test_UltimateLeadSegmentQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class UltimateLeadSegmentQueuable implements Queueable{
    public Set<Id> leadIds = new Set<Id>();
    Map<Id,String> mapUltimateSMCountry = new Map<Id,String>();
    Map<Id,Double> mapUltimateSMEmp = new Map<Id,Double>();
    Map<Id,String> mapUltimateSegmentName = new Map<Id,String>();
    Map<Id,String> mapUltimateMarketoSegmentName = new Map<Id,String>();
    Map<Id,Lead> oldMap = new Map<Id,Lead>();
    public UltimateLeadSegmentQueuable(Set<Id> leadIdsParameter,Map<Id,String> mapUltimateSMCountryParameter,Map<Id,Double> mapUltimateSMEmpParameter,Map<Id,String> mapUltimateSegmentNameParameter,Map<Id,String> mapUltimateMarketoSegmentNameParameter,Map<Id,Lead> oldMapParameter)
    {
        this.leadIds = leadIdsParameter;
        this.mapUltimateSMCountry = mapUltimateSMCountryParameter;
        this.mapUltimateSMEmp = mapUltimateSMEmpParameter;
        this.mapUltimateSegmentName = mapUltimateSegmentNameParameter;
        this.mapUltimateMarketoSegmentName = mapUltimateMarketoSegmentNameParameter;
        this.oldMap = oldMapParameter;
    }
    public void execute(QueueableContext context)
    {
        List<Lead> lstLeadsToUpdate = new List<Lead>();
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        String leanDataUsers = System.Label.Pb_Custom_label;// 0-Events User,1-Routing Review User,2-LeanData Queue, 3- Do Not Contact VAR
        String [] listUsersLean = leanDataUsers.split(',');
        Map<Id,String> mapLeadProfiles = new Map<Id,String>();
        Set<String> leadCreatedIds = new Set<String>();
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        for(Lead l : [select id,SM_Country__c,SM_Employees__c,isConverted,ZI_CDP_Account_Id__c,Ultimate_SM_Country__c,Ultimate_SM_Employees__c,Emp_Range_Sales_Override__c,NumberOfEmployees,ZI_Employees__c,LS_Company_Size__c,SegmentName__c,Marketo_Segment_Name__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Segment_complete_date_time__c,CreatedById,Lead_Entry_Source__c,OwnerId,Lead_System_Source__c,Status,Lead_Created_via_Smart_Search__c,RecordTypeId,RecordType.Name,SDR_Agents__c,LeadSource,ZI_CDP_Account_Id__r.Franchise__c,LeadPartnerID__c,Bypass_Routing__c,Systems_process_routing_bypass__c from Lead where Id in :leadIds])
        {
            leadCreatedIds.add(l.CreatedById);
        }
        if(leadCreatedIds.size()>0)
        {
            for(User u : [select id,name,profile.name from User where id in :leadCreatedIds])
            {
                mapLeadProfiles.put(u.id,u.profile.name);
            }
        }
        for (Lead ld : [select id,SM_Country__c,SM_Employees__c,isConverted,ZI_CDP_Account_Id__c,Ultimate_SM_Country__c,Ultimate_SM_Employees__c,Emp_Range_Sales_Override__c,NumberOfEmployees,ZI_Employees__c,LS_Company_Size__c,SegmentName__c,Marketo_Segment_Name__c,Systems_Process_Stage__c,SystemsProcessBypass__c,Segment_complete_date_time__c,CreatedById,Lead_Entry_Source__c,OwnerId,Lead_System_Source__c,Status,Lead_Created_via_Smart_Search__c,RecordTypeId,RecordType.Name,SDR_Agents__c,LeadSource,ZI_CDP_Account_Id__r.Franchise__c,LeadPartnerID__c,Bypass_Routing__c,Systems_process_routing_bypass__c from Lead where Id in :leadIds])
        {
            System.debug('UltimateQueueStatoUL1:'+ld);
            if(ld.ZI_CDP_Account_Id__c != null)
            {
                if(mapUltimateSMCountry!=null && mapUltimateSMCountry.containskey(ld.ZI_CDP_Account_Id__c) && processStage.Bypass_Segmentation_Process__c == false)
                {
                    ld.Ultimate_SM_Country__c = mapUltimateSMCountry.get(ld.ZI_CDP_Account_Id__c);
                }
                if(mapUltimateSMEmp!=null && mapUltimateSMEmp.containskey(ld.ZI_CDP_Account_Id__c) && processStage.Bypass_Segmentation_Process__c == false)
                {
                    ld.Ultimate_SM_Employees__c = mapUltimateSMEmp.get(ld.ZI_CDP_Account_Id__c);
                }
                if(mapUltimateSegmentName!=null && mapUltimateSegmentName.containskey(ld.ZI_CDP_Account_Id__c) && processStage.Bypass_Segmentation_Process__c == false)
                {
                    ld.SegmentName__c = mapUltimateSegmentName.get(ld.ZI_CDP_Account_Id__c);
                }
                if(mapUltimateMarketoSegmentName!=null && mapUltimateMarketoSegmentName.containskey(ld.ZI_CDP_Account_Id__c) && processStage.Bypass_Segmentation_Process__c == false)
                {
                    ld.Marketo_Segment_Name__c = mapUltimateMarketoSegmentName.get(ld.ZI_CDP_Account_Id__c);
                }/*CMR-224923:E2EStaging - Lead Refactoring & Customer Data Updates ends*/
                if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete'){
                    if( ((ld.CreatedById==listUsers[0] && ld.Bypass_Routing__c) || ld.OwnerId!=listUsersLean[2]) && ld.Segment_complete_date_time__c==null)
                    {
                        ld.SystemsProcessBypass__c='Bypass Routing';
                        ld.Systems_process_routing_bypass__c = 'Non LDQ Owner';
                    }
                    ld.Systems_Process_Stage__c='Segment complete';
                    ld.Segment_complete_date_time__c=System.now();
                }
                System.debug('UltimateQueueStatoUL2:'+ld.OwnerId+'LeadId:'+ld.Id+ld.Systems_Process_Stage__c+'2:'+ld.Lead_Entry_Source__c+'3:'+ld.Lead_System_Source__c+'New:'+ld.SegmentName__c);
                if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Routing_Process__c == true){
                    ld.SystemsProcessBypass__c='Bypass Routing';
                    ld.Systems_process_routing_bypass__c = 'Custom Setting Bypass'; 
                }
                if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && ( (processStage.Bypass_Routing_Process__c == true) || ( ld.OwnerId!=listUsersLean[2] && (ld.Systems_Process_Stage__c=='Segment complete' || ld.SystemsProcessBypass__c=='Bypass Segmentation') && ( (ld.LeadSource=='ZoomInfo' || (ld.Lead_Created_via_Smart_Search__c && mapLeadProfiles != null && mapLeadProfiles.containsKey(ld.CreatedById) && mapLeadProfiles.get(ld.CreatedById) !='System Administrator' && ld.RecordType.Name!='Partner Leads')) || (oldMap!=null && (oldMap.get(ld.Id)).SegmentName__c!=null && (oldMap.get(ld.Id)).SegmentName__c== ld.SegmentName__c))) ) )
                {
                    ld.SystemsProcessBypass__c='Bypass Routing';
                    if(processStage.Bypass_Routing_Process__c == false && ld.Systems_process_routing_bypass__c !='Non LDQ Owner') {
                        ld.Systems_process_routing_bypass__c = 'Business Rule';
                    }
                }
                else if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && ld.OwnerId!=listUsersLean[2] && (ld.Systems_Process_Stage__c=='Segment complete' || ld.SystemsProcessBypass__c=='Bypass Segmentation') && (oldMap!=null && (oldMap.get(ld.Id)).SegmentName__c!=null && (oldMap.get(ld.Id)).SegmentName__c!= ld.SegmentName__c))
                {
                    if(processStage != null && ld.Status != null && ld.OwnerId!=listUsersLean[2] && ( (processStage.Gating_Status_Non_Identifier_List__c.contains(ld.Status)) || (processStage.Gating_Lead_Status_Exclusion_List__c.contains(ld.Status) && ((processStage.Bypass_reassign_Sales_Smart_Search_Lead__c == true && ld.RecordType.Name=='Sales Leads' && (ld.Lead_Created_via_Smart_Search__c==true || (ld.LeadSource != null && ld.LeadSource.contains(processStage.Gating_Type_Sales_Smart_Lead__c)) )) || (processStage.Bypass_reassign_BT_API_Lead__c == true && ld.CreatedById==processStage.Gating_Type_BT_API_Lead__c) || (processStage.Bypass_reassign_Sales_Clone_Lead__c == true && ld.Lead_System_Source__c==processStage.Gating_Type_Sales_Clone_Lead__c && ld.RecordType.Name=='Sales Leads') || (processStage.Bypass_reassign_Zoominfo_Lead__c == true && ld.LeadSource==processStage.Gating_Lead_Source__c) || (processStage.Bypass_reassign_Initial_Lead__c == true && (ld.LeadSource != null && ld.LeadSource.contains(processStage.Gating_Type_Initial_Lead__c)) ) || (processStage.Bypass_reassign_ChiliPiper_Lead__c == true && ld.CreatedById==processStage.Gating_Type_Chili_Piper_Lead__c) || (processStage.Bypass_reassign_Web_Scheduler_Lead__c == true && ld.Lead_Entry_Source__c==processStage.Gating_Type_Web_Scheduler_Lead__c) || (processStage.Bypass_reassign_Shared_Lead__c == true && ld.Lead_Entry_Source__c==processStage.Gating_Type_Shared_Lead__c) || (processStage.Bypass_reassign_Referral_Lead__c == true && ( (ld.LeadSource != null && ld.LeadSource.contains(processStage.Gating_Type_Referral_Lead__c)) || (ld.Lead_Entry_Source__c != null && ld.Lead_Entry_Source__c.contains(processStage.Gating_Type_Referral_Lead__c)) )) || (processStage.Bypass_reassign_ISV_Lead__c == true && ( (ld.LeadSource != null && ld.LeadSource.contains(processStage.Gating_Type_ISV_Lead__c)) || (ld.Lead_Entry_Source__c != null && ld.Lead_Entry_Source__c.contains(processStage.Gating_Type_ISV_Lead__c)) )) || (processStage.Bypass_reassign_Alyce_Gifting_Lead__c == true && ld.CreatedById!=listUsers[0] && ld.Lead_Entry_Source__c != null && ld.Lead_Entry_Source__c.contains(processStage.Gating_Type_Alyce_Gifting_Lead__c)) || (processStage.Bypass_reassign_SIA_Lead__c == true && ld.LeadSource==processStage.Gating_Type_SIA_Lead__c) || (processStage.Bypass_reassign_Ringbot_Lead__c == true && ld.Lead_Entry_Source__c != null && ld.Lead_Entry_Source__c.contains(processStage.Gating_Type_Ringbot_Lead__c)) || (processStage.Bypass_reassign_Strategic_Marketing_Lead__c == true && ld.Lead_Entry_Source__c==processStage.Gating_Type_Strategic_Marketing__c) || (processStage.Bypass_reassign_Specific_Partner_Lead__c == true && ld.LeadPartnerID__c==processStage.Gating_Type_Specific_Partner_Lead__c) || (processStage.Bypass_reassign_Franchise_Lead__c == true && ld.ZI_CDP_Account_Id__c!=null && ld.ZI_CDP_Account_Id__r.Franchise__c==true))) ))
                    {
                        ld.SystemsProcessBypass__c='Bypass Routing';
                        if(processStage.Bypass_Routing_Process__c == false && ld.Systems_process_routing_bypass__c !='Non LDQ Owner') {
                            ld.Systems_process_routing_bypass__c='Business Rule';
                        }
                    }
                    else
                    {
                        if(processStage != null && processStage.Bypass_Gating_Email__c == false)
                        {
                            sendOwnerMail(ld.OwnerId,ld.Id);
                            ld.OwnerId=Id.valueOf(listUsersLean[2]);
                        }
                        ld.SDR_Agents__c=null;
                    }//Gating Phase II Changes ends
                }
            }
            lstLeadsToUpdate.add(ld);
        }
        if(lstLeadsToUpdate.size() > 0)
        {
            update lstLeadsToUpdate;
        }
    }
    public static void sendOwnerMail(String owner,String recId)
        {
            try
            {
            EmailTemplate template = [SELECT Id, Name, DeveloperName, Body, HtmlValue, Subject
                              FROM EmailTemplate
                              WHERE DeveloperName = 'Lead_Owner_Change_Gating' LIMIT 1];
            Messaging.SingleEmailMessage mail1 = new Messaging.SingleEmailMessage();
            User usr = [select id,email from User where id=:owner];
            String[] toAddresses = new String[] {usr.email};
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            toAddresses.addAll(processStage.Gating_Email_Addresses_List__c.split(','));
            OrgWideEmailAddress emailSender=[select Id,address,displayname From OrgWideEmailAddress where id='0D280000000TNrLCAW'];
            mail1.setTargetObjectId(recId);
            mail1.setTemplateId(template.Id);
            mail1.saveAsActivity = false;
            mail1.setOrgWideEmailAddressId(emailSender.Id);
            mail1.setToAddresses(toAddresses);
            mail1.setTreatTargetObjectAsRecipient(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail1 });
            }
            catch(Exception e) {}
        }
}