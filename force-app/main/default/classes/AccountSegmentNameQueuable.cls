/*
* Description   : Apex class for populating Segment Name - Invoked from AccountTriggerHandler
* Test Class : Test_AccountSegmentNameQueuable

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
public class AccountSegmentNameQueuable implements Queueable{
    public Map<Id,String> mapAccountIdNMarketoSegmentName = new Map<Id,String>();
    public Map<Id,String> mapAccountIdNSegmentId = new Map<Id,String>();
    public AccountSegmentNameQueuable(Map<Id,String> mapAccountIdNMarketoSegmentNameParameter,Map<Id,String> mapAccountIdNSegmentIdParameter)
    {
        this.mapAccountIdNMarketoSegmentName = mapAccountIdNMarketoSegmentNameParameter;
        this.mapAccountIdNSegmentId = mapAccountIdNSegmentIdParameter;
    }
    public void execute(QueueableContext context) 
    {
        Boolean isUpdate = false;
        List<Account> lstAccountsToUpdate = new List<Account>();
        Set<Id> setAccountIds = new Set<Id>();
        if(mapAccountIdNMarketoSegmentName != null && mapAccountIdNMarketoSegmentName.size() > 0 && mapAccountIdNSegmentId != null && mapAccountIdNSegmentId.size() > 0)
        {            
            setAccountIds = mapAccountIdNSegmentId.keyset();
            for(Account acc : [Select Id,Ultimate_Parent_Account_ID__c,Segment_Name__c,Marketo_Segment_Name__c,Holdout_Expiration_Date__c,Segment_Exception_Flag__c, SM_Employees__c, Parent.SM_Employees__c from Account where ParentId != null and (Holdout_Expiration_Date__c=null or Segment_Exception_Flag__c=false) and ((ParentId in :setAccountIds) or (Parent.ParentId in :setAccountIds) or (Parent.Parent.ParentId in :setAccountIds) or (Parent.Parent.Parent.ParentId in :setAccountIds) or (Parent.Parent.Parent.Parent.ParentId in :setAccountIds) or (Parent.Parent.Parent.Parent.Parent.ParentId in :setAccountIds))])
            {
                isUpdate = false;
                if (mapAccountIdNSegmentId.containsKey(acc.Ultimate_Parent_Account_ID__c) && acc.Segment_Name__c != mapAccountIdNSegmentId.get(acc.Ultimate_Parent_Account_ID__c)
                && !acc.Segment_Exception_Flag__c && acc.SM_Employees__c == acc.Parent.SM_Employees__c) {
                    acc.Segment_Name__c = mapAccountIdNSegmentId.get(acc.Ultimate_Parent_Account_ID__c);
                    isUpdate = true;
                }
                if(mapAccountIdNMarketoSegmentName.containsKey(acc.Ultimate_Parent_Account_ID__c) && acc.Marketo_Segment_Name__c != mapAccountIdNMarketoSegmentName.get(acc.Ultimate_Parent_Account_ID__c)
                && !acc.Segment_Exception_Flag__c && acc.SM_Employees__c == acc.Parent.SM_Employees__c) {
                    acc.Marketo_Segment_Name__c = mapAccountIdNMarketoSegmentName.get(acc.Ultimate_Parent_Account_ID__c);
                    isUpdate = true;
                }
                if(isUpdate)
                {
                    lstAccountsToUpdate.add(acc);
                }
            }
            if(lstAccountsToUpdate.size() > 0)
            {
                update lstAccountsToUpdate;
            }
        }
    }
}