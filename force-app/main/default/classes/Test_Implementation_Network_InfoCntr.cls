@istest
public class Test_Implementation_Network_InfoCntr {
     @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
    static void  CreateRecord()
     {
          User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
         	string text='1/0';
         
            List<Account> Acct = new List<Account>();
            Account accObj = new Account();
            accObj.Name = 'Test Account Parent ';
            accObj.Partner_ID__c = '12346';
            Acct.add(accObj);
            Account accObj1 = new Account();
            accObj1.Name = 'Test Account Parent ';
            accObj1.Partner_ID__c = '12346';
            Acct.add(accObj1);
            insert Acct;
          Implementation__c imp = new Implementation__c();
          imp.Account__c=accObj.id;
          imp.Name='test imp';
          imp.Brand__c='TestBrand';
          insert imp;
         Implementation_Network_InfoController.getImplementationDetails(imp.id);
         
     }
}