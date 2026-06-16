/*       
        * Created By    : Namitha
        * Created Date  : 04-05-2020
        * Description   : Controller class for Account_Claim_Current_Owner lightning component
        * Test Class    : Test_Acc_Claim_Current_OwnerController   
        
Change History
********************************************************************************************************************
    SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Account_Claim_Current_OwnerController {
    public static CheckAccessWrapper accessWrap = new CheckAccessWrapper();
    public static ClaimAccountOwnerWrapper claimAccOwnWrapper = new ClaimAccountOwnerWrapper();
	@AuraEnabled
    public static ClaimAccountOwnerWrapper claimCurrentOwner(String recordId) {
        Id loggedInUserId = UserInfo.getUserId();
        //ClaimAccountOwnerWrapper claimAccOwnWrapper;
        Account acc = new Account();
        User usr = new User();
        String response = '';
        String approvalRecordType = '';
        checkFieldAccess();
        
        try
        {
            approvalRecordType = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Farming Claim Owner').getRecordTypeId();
            usr = [Select UserRoleId,UserRole.Name,FirstName,LastName,ManagerId,Profile.Name from User where Id = :loggedInUserId];
            acc = [Select Id,Name,Current_Owner_Name__c,OwnerId from Account where Id = :recordId];
            if(usr.Profile.Name == 'Sales Rep - Lightning' || usr.Profile.Name == 'GSP Sales Rep' || usr.Profile.Name == 'Sales Rep - Lightning - EU Restricted' || usr.UserRole.Name != null && (usr.UserRole.Name.contains('Farming') || usr.UserRole.Name.contains('UK - 10+') || usr.UserRole.Name.contains('UK - 50+') || usr.UserRole.Name.contains('UK - Farming') || usr.UserRole.Name.contains('UK - Mid Market') || usr.UserRole.Name.contains('UK - Signature Accounts') || usr.UserRole.Name.contains('UK - SOHO')))
            {
                response = 'Success';
            }
            else
            {
                response = 'You do not have permission to Claim this Account.';
            }
        }
        catch(Exception e)
        {
            response = 'Unable to claim current owner. Error during processing.';
        }
        
        claimAccOwnWrapper.response = response;
        claimAccOwnWrapper.acc = acc;
        claimAccOwnWrapper.usr = usr;
        claimAccOwnWrapper.recordTypeId = approvalRecordType;
        //claimAccOwnWrapper = new ClaimAccountOwnerWrapper(response,acc,usr,approvalRecordType);
        return claimAccOwnWrapper;
    }
    
    public static void checkFieldAccess(){
        if (Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Farming Claim Owner').isAvailable()) {
            claimAccOwnWrapper.recordType_access = true;
        }else{
            claimAccOwnWrapper.recordType_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Account__c.isAccessible()) {
            claimAccOwnWrapper.account_access = true;
        }else{
            claimAccOwnWrapper.account_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Current_Owner__c.isAccessible()) {
            claimAccOwnWrapper.CurrentOwner_access = true;
        }else{
            claimAccOwnWrapper.CurrentOwner_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Level1Approver__c.isAccessible()) {
            claimAccOwnWrapper.level1Approver_access = true;
        }else{
            claimAccOwnWrapper.level1Approver_access = false;
        }
        if (Schema.sObjectType.Approval__c.fields.Claiming_Requestor__c.isAccessible()) {
            claimAccOwnWrapper.claimingRequestor_access = true;
        }else{
            claimAccOwnWrapper.claimingRequestor_access = false;
        }
        
    }
	
    public class CheckAccessWrapper{
        @AuraEnabled public boolean recordType_access {get;set;}
        @AuraEnabled public boolean account_access {get;set;}
        @AuraEnabled public boolean claimingRequestor_access {get;set;}
        @AuraEnabled public boolean level1Approver_access {get;set;}
        @AuraEnabled public boolean CurrentOwner_access {get;set;}
    }    
    



    
    public class ClaimAccountOwnerWrapper
    {
        @AuraEnabled public String response{get;set;}
        @AuraEnabled public Account acc{get;set;}
        @AuraEnabled public User usr{get;set;}
        @AuraEnabled public String recordTypeId{get;set;}
        @AuraEnabled public boolean recordType_access {get;set;}
        @AuraEnabled public boolean account_access {get;set;}
        @AuraEnabled public boolean claimingRequestor_access {get;set;}
        @AuraEnabled public boolean level1Approver_access {get;set;}
        @AuraEnabled public boolean CurrentOwner_access {get;set;}
        
        
       /* public ClaimAccountOwnerWrapper(String response, Account acc, User usr, String recordTypeId)
        {
            this.response = response;
            this.acc = acc;
            this.usr = usr;
            this.recordTypeId = recordTypeId;
        }*/
    }
}