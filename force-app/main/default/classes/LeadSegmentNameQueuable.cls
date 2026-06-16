/*
* Description   : Apex class for populating Segment Name - Invoked from LeadTriggerHelper
* Test Class : Test_LeadSegmentNameQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class LeadSegmentNameQueuable implements Queueable{
    Set<Id> leadIds = new Set<Id>();
    Set<String> setCountryNames = new Set<String>();
    Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
    Map<Id,Lead> oldMap = new Map<Id,Lead>();
    public LeadSegmentNameQueuable(Set<Id> leadIdsParameter,Set<String> setCountryNamesParameter,Set<Decimal> setEmployeeNumbersParameter,Map<Id,Lead> oldMapParameter)
    {
        this.leadIds = leadIdsParameter;
        this.setCountryNames = setCountryNamesParameter;
        this.setEmployeeNumbers = setEmployeeNumbersParameter;
        this.oldMap = oldMapParameter;
    }
    public void execute(QueueableContext context)
    {
        List<Lead> lstLeadsToUpdate = new List<Lead>();
        String ROWCountryName = 'ROW';
        Map<String,List<Segment_Master__c>> mapCountryNameNLstSegmentMasters = new Map<String,List<Segment_Master__c>>();
        String SMCountryName = '';
        Decimal SMEmployees;
        String nonAvayaUsers = System.Label.Non_Avaya_Users;
        String [] listUsers = nonAvayaUsers.split(';');
        String leanDataUsers = System.Label.Pb_Custom_label;// 0-Events User,1-Routing Review User,2-LeanData Queue, 3- Do Not Contact VAR
        String [] listUsersLean = leanDataUsers.split(',');
        Map<Id,String> mapLeadProfiles = new Map<Id,String>();
        Set<String> leadCreatedIds = new Set<String>();
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        System.debug('LeadQueueStatoL:'+setCountryNames+setEmployeeNumbers);
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
        System.debug('LeadQueueStatoL0:'+mapCountryNameNLstSegmentMasters);
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
            System.debug('LeadQueueStatoL1:'+ld);
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
                System.debug('LeadQueueStatoL2:'+SMCountryName);
                if(ld.ZI_CDP_Account_Id__c!=null && ld.Ultimate_SM_Employees__c!=null && ld.Ultimate_SM_Employees__c > 1 && !(ld.Emp_Range_Sales_Override__c>0))//Emp_Range_Sales_Override__c will sometimes have null or 0. So always use ld.Emp_Range_Sales_Override__c>0 check if for not null and !(ld.Emp_Range_Sales_Override__c>0) for null
                {
                    SMEmployees=ld.Ultimate_SM_Employees__c;
                }
                else
                {
                    if(oldMap!=null && ld.Emp_Range_Sales_Override__c>0 && (oldMap.get(ld.Id)).Emp_Range_Sales_Override__c!= ld.Emp_Range_Sales_Override__c)
                    {
                        SMEmployees=ld.Emp_Range_Sales_Override__c;
                    }
                    else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c!=null && (oldMap.get(ld.Id)).Ultimate_SM_Employees__c!= ld.Ultimate_SM_Employees__c)
                    {
                        SMEmployees=ld.Ultimate_SM_Employees__c;
                    }
                    else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c!=null && (oldMap.get(ld.Id)).ZI_Employees__c!= ld.ZI_Employees__c)
                    {
                        SMEmployees=ld.ZI_Employees__c;
                    }
                    else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c==null && ld.LS_Company_Size__c!=null && (oldMap.get(ld.Id)).LS_Company_Size__c!= ld.LS_Company_Size__c)
                    {
                        SMEmployees=ld.LS_Company_Size__c;
                    }
                    else if(oldMap!=null && !(ld.Emp_Range_Sales_Override__c>0) && ld.Ultimate_SM_Employees__c==null && ld.ZI_Employees__c==null && ld.LS_Company_Size__c==null && ld.NumberOfEmployees!=null && (oldMap.get(ld.Id)).NumberOfEmployees!= ld.NumberOfEmployees)
                    {
                        SMEmployees=ld.NumberOfEmployees;
                    }
                    else
                    {
                        SMEmployees=ld.SM_Employees__c;
                    }
                }
                System.debug('LeadQueueStatoL3:'+SMEmployees);
                if(mapCountryNameNLstSegmentMasters.containskey(SMCountryName))
                {
                    for(Segment_Master__c sm : (List<Segment_Master__c>) mapCountryNameNLstSegmentMasters.get(SMCountryName))
                    {
                        System.debug('LeadQueueStatoL33:'+sm);
                        if(sm.Country__c != null && sm.Min__c != null && sm.Max__c!= null && SMEmployees != null && sm.Max__c >= SMEmployees && sm.Min__c <= SMEmployees)
                        {
                            System.debug('LeadQueueStatoL34:'+sm);
                            if(ld.SegmentName__c != sm.Id && processStage.Bypass_Segmentation_Process__c == false)
                            {
                                ld.SegmentName__c = sm.Id;
                            }
                            if(ld.Marketo_Segment_Name__c != sm.Name && processStage.Bypass_Segmentation_Process__c == false)
                            {
                                ld.Marketo_Segment_Name__c = sm.Name;
                            }
                            if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Segmentation_Process__c == false && ld.Systems_Process_Stage__c!='Route complete')
                            {
                                if( ((ld.CreatedById==listUsers[0] && ld.Bypass_Routing__c) || ld.OwnerId!=listUsersLean[2]) && ld.Segment_complete_date_time__c==null)
                                {
                                    ld.SystemsProcessBypass__c='Bypass Routing';
                                    ld.Systems_process_routing_bypass__c = 'Non LDQ Owner';
                                }
                                ld.Systems_Process_Stage__c='Segment complete';
                                ld.Segment_complete_date_time__c=System.now();
                            }
                            System.debug('LeadQueueStatoL35:'+ld);
                            System.debug('LeadQueueStatoL4:'+ld.OwnerId+'LeadId:'+ld.Id+ld.Systems_Process_Stage__c+'2:'+ld.Lead_Entry_Source__c+'3:'+ld.Lead_System_Source__c+'New:'+ld.SegmentName__c);
                            if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Routing_Process__c == true){
                                ld.SystemsProcessBypass__c='Bypass Routing';
                                ld.Systems_process_routing_bypass__c = 'Custom Setting Bypass';
                            }
                            if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && ((processStage.Bypass_Routing_Process__c == true) || ( ld.OwnerId!=listUsersLean[2] && (ld.Systems_Process_Stage__c=='Segment complete' || ld.SystemsProcessBypass__c=='Bypass Segmentation') && ( (ld.LeadSource=='ZoomInfo' || (ld.Lead_Created_via_Smart_Search__c && mapLeadProfiles != null && mapLeadProfiles.containsKey(ld.CreatedById) && mapLeadProfiles.get(ld.CreatedById) !='System Administrator' && ld.RecordType.Name!='Partner Leads')) || (oldMap!=null && (oldMap.get(ld.Id)).SegmentName__c!=null && (oldMap.get(ld.Id)).SegmentName__c== ld.SegmentName__c))) ) )
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
                                        ld.Systems_process_routing_bypass__c = 'Business Rule';
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
                    }
                }
                lstLeadsToUpdate.add(ld);
            }
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