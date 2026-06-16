/*
* Description   : Apex class for populating Segment Name - Invoked from AccountTriggerHandler
* Test Class : Test_GatingAccountSegmentQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class GatingAccountSegmentQueuable implements Queueable{
    public Set<String> setCountryNames = new Set<String>();
    public Set<Decimal> setEmployeeNumbers = new Set<Decimal>();
    public Set<Id> accIds = new Set<Id>();
    Map<Id,Account> oldMap = new Map<Id,Account>();
    public GatingAccountSegmentQueuable(Set<Id> accIdsParameter,Set<String> setCountryNamesParameter,Set<Decimal> setEmployeeNumbersParameter,Map<Id,Account> oldMapParameter)
    {
        this.accIds = accIdsParameter;
        this.setCountryNames = setCountryNamesParameter;
        this.setEmployeeNumbers = setEmployeeNumbersParameter;
        this.oldMap = oldMapParameter;
    }
    public void execute(QueueableContext context) 
    {
        Boolean isUpdate = false;
        List<Account> lstAccountsToUpdate = new List<Account>();
        Set<Id> setAccountIds = new Set<Id>();
        Map<String,List<Segment_Master__c>> mapCountryNameNLstSegmentMasters = new Map<String,List<Segment_Master__c>>();
        String SMCountry = '';
        String ROWCountryName = 'ROW';
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        System.debug('GatingAccountSegmentStati1:'+setCountryNames+setEmployeeNumbers+accIds);
        if(setCountryNames != null && setCountryNames.size() > 0 && setEmployeeNumbers != null && setEmployeeNumbers.size() > 0)
        {
            List<Segment_Master__c> segmentMasterList = [SELECT Id, Country__c, Max__c, Min__c, Name, Active__c FROM Segment_Master__c where (Country__c in :setCountryNames OR Country__c =: ROWCountryName) AND Min__c <= :setEmployeeNumbers AND Max__c >= :setEmployeeNumbers AND Active__c = true];
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
            System.debug('GatingAccountSegmentStati2:'+mapCountryNameNLstSegmentMasters);
            for (Account acc : [Select Id,ParentId,SM_Country__c,SM_Employees__c,Segment_Name__c,Marketo_Segment_Name__c,Systems_process_stage__c,Segment_complete_date__c,OwnerId from Account where Id in :accIds AND IsMultiProductTechnicalAccount__c = false])
            {
                System.debug('GatingAccountSegmentStati3:'+acc);
                if(acc.SM_Country__c != null && acc.SM_Employees__c != null)
                {
                    if(mapCountryNameNLstSegmentMasters.containskey(acc.SM_Country__c))
                    {
                        SMCountry = acc.SM_Country__c;
                    }
                    else
                    {
                        SMCountry = ROWCountryName;
                    }
                    if(mapCountryNameNLstSegmentMasters.containskey(SMCountry))
                    {
                        for(Segment_Master__c sm : (List<Segment_Master__c>) mapCountryNameNLstSegmentMasters.get(SMCountry))
                        {
                            if(sm.Country__c != null && sm.Min__c != null && sm.Max__c!= null && sm.Max__c >= acc.SM_Employees__c && sm.Min__c <= acc.SM_Employees__c)
                            {
                                if(acc.Segment_Name__c != sm.Id)
                                {
                                    acc.Segment_Name__c = sm.Id;
                                }
                                if((acc.Marketo_Segment_Name__c == null) || (acc.Marketo_Segment_Name__c != null && !acc.Marketo_Segment_Name__c.equals(sm.Name)))
                                {
                                    acc.Marketo_Segment_Name__c = sm.Name;
                                }
                                acc.Systems_process_stage__c = 'Segment Complete';
                        		acc.Segment_complete_date__c = System.now();
                                
                            }                            
                            if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Account_Gating_Email__c == false && acc.Systems_process_stage__c=='Segment Complete' && (oldMap!=null && (oldMap.get(acc.Id)).Segment_Name__c!=null && (oldMap.get(acc.Id)).Segment_Name__c!= acc.Segment_Name__c))
                            {
                                sendOwnerMail(acc.OwnerId,acc.Id);
                            }                            
                        }
                    }
                    lstAccountsToUpdate.add(acc);
                }
            }
        }    
        System.debug('GatingAccountSegmentStati4:'+lstAccountsToUpdate);
        if(lstAccountsToUpdate.size() > 0)
        {
            update lstAccountsToUpdate;
        }   
    }
    
    public static void sendOwnerMail(String owner,String recId)
        {
            try
            {
            EmailTemplate template = [SELECT Id, Name, DeveloperName, Body, HtmlValue, Subject
                              FROM EmailTemplate
                              WHERE DeveloperName = 'Account_Owner_Change_Gating' LIMIT 1];
            User usr = [select id,email from User where id=:owner];
            Messaging.SingleEmailMessage mail1 = Messaging.renderStoredEmailTemplate(template.Id,usr.Id,recId);
            String[] toAddresses = new String[] {};
            Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
            toAddresses.addAll(processStage.Account_Gating_Email_List__c.split(','));    
            OrgWideEmailAddress emailSender=[select Id,address,displayname From OrgWideEmailAddress where id='0D280000000TNrLCAW'];
            mail1.setTargetObjectId(usr.Id);
            mail1.setTemplateId(template.Id);
            mail1.setSaveAsActivity(false);
            mail1.setOrgWideEmailAddressId(emailSender.Id);
            mail1.setToAddresses(toAddresses);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail1 });
            }
            catch(Exception e) {System.debug('SendEmailGatingAccountSegmentStati5:'+e);}
        }
}