@istest
public class Test_Acc_Claim_Current_OwnerController {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void  CreateAccount()
     {
          String approvalRecordType = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Farming Claim Owner').getRecordTypeId();
          User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        
           List<Account> Acct = new List<Account>();
         	Account accObj = new Account();
            accObj.Name = 'Test Account Parent ';
            accObj.Partner_ID__c = '12346';
            accObj.RC_User_ID__c = sysAdmin.id;
            accObj.Current_Owner_Name__c = sysAdmin.Name;
            accObj.OwnerId=sysAdmin.id;
           Acct.add(accObj);
            Account accObj1 = new Account();
            accObj1.Name = 'Test Account Parent ';
            accObj1.Partner_ID__c = '12222';
           Acct.add(accObj1);
         
           insert Acct;
           string txt ='0010n000016Gqp2000';
           Account_Claim_Current_OwnerController.claimCurrentOwner(accObj.Id);
           Account_Claim_Current_OwnerController.claimCurrentOwner(accObj1.Id);
           Account_Claim_Current_OwnerController.claimCurrentOwner(txt);
           Account_Unclaim_Current_OwnerController.deOwn(accObj.Id);
           Account_Unclaim_Current_OwnerController.deOwn(txt);
         
            
     }

     
}