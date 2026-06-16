/*
* Description   : Apex class for populating Ultimate Account - Invoked from AccountTriggerHandler
* Test Class : Test_UltimateAccountChildQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class UltimateAccountChildQueuable implements Queueable{
    public Map<Id,Id> mapAccountIdUltimate = new Map<Id,Id>();
    Map<Id,Account> oldMap = new Map<Id,Account>();
    public UltimateAccountChildQueuable(Map<Id,String> mapAccountIdUltimateParameter,Map<Id,Account> oldMapParameter)
    {
        this.mapAccountIdUltimate = mapAccountIdUltimateParameter;
        this.oldMap = oldMapParameter;
    }
    public void execute(QueueableContext context) 
    {
        Boolean isUpdate = false;
        List<Account> lstAccountsToUpdate = new List<Account>();
        List<Account> lstGatingAccountsToUpdate = new List<Account>();
        Set<Id> setAccountIds = new Set<Id>();
        setAccountIds = mapAccountIdUltimate.keyset();
        Gating_Process_Stage__c processStage = Gating_Process_Stage__c.getInstance();
        System.debug('GatingUltimateAccountChilStati1:'+setAccountIds+oldMap);
        List<Account> childAccounts  = [select id,Name,Ultimate_Account__c,ParentId,Parent.ParentId,Parent.Parent.ParentId,Parent.Parent.Parent.ParentId,Systems_process_stage__c,Segment_complete_date__c from Account where ParentId in :setAccountIds OR Parent.ParentId in :setAccountIds OR Parent.Parent.ParentId in :setAccountIds OR Parent.Parent.Parent.ParentId in :setAccountIds];
        for(Account acc: childAccounts)
        {
            if(mapAccountIdUltimate!=null && mapAccountIdUltimate.containsKey(acc.ParentId))
            {
                acc.Ultimate_Account__c=mapAccountIdUltimate.get(acc.ParentId);           
            }     
            else if(mapAccountIdUltimate!=null && mapAccountIdUltimate.containsKey(acc.Parent.ParentId))
            {
                acc.Ultimate_Account__c=mapAccountIdUltimate.get(acc.Parent.ParentId);
            } 
            else if(mapAccountIdUltimate!=null && mapAccountIdUltimate.containsKey(acc.Parent.Parent.ParentId))
            {
                acc.Ultimate_Account__c=mapAccountIdUltimate.get(acc.Parent.Parent.ParentId);
            } 
            else if(mapAccountIdUltimate!=null && mapAccountIdUltimate.containsKey(acc.Parent.Parent.Parent.ParentId))
            {
                acc.Ultimate_Account__c=mapAccountIdUltimate.get(acc.Parent.Parent.Parent.ParentId);
            } 
            lstAccountsToUpdate.add(acc);
        }
        if(processStage != null && processStage.Bypass_Account_Gating_Process__c == false){
        for (Account acc : [Select Id,Systems_process_stage__c,Segment_complete_date__c,OwnerId,Segment_Name__c from Account where Id in :setAccountIds])
            {
                acc.Systems_process_stage__c='Segment Complete';
                acc.Segment_complete_date__c = System.now();    
                System.debug('GatingUltimateAccountChilStati2:'+acc.Systems_process_stage__c+acc.Segment_Name__c+acc.OwnerId+acc.Id);
                if(processStage != null && processStage.Bypass_Gating_Process_Stage__c == false && processStage.Bypass_Account_Gating_Email__c == false && acc.Systems_process_stage__c=='Segment Complete' && (oldMap!=null && (oldMap.get(acc.Id)).Segment_Name__c!=null && (oldMap.get(acc.Id)).Segment_Name__c!= acc.Segment_Name__c))
                {
                    sendOwnerMail(acc.OwnerId,acc.Id);
                } 
                lstGatingAccountsToUpdate.add(acc);
            }
        }
        System.debug('GatingUltimateAccountChildStati3:'+lstAccountsToUpdate);
        System.debug('GatingUltimateAccountChildStati4:'+lstGatingAccountsToUpdate);
        if(lstAccountsToUpdate.size()>0)
        {
            update lstAccountsToUpdate;
        }
        if(lstGatingAccountsToUpdate.size()>0)
        {
            update lstGatingAccountsToUpdate;
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
            catch(Exception e) {}
        }
}